/* ENGLISH-ELF Lexer in GAS assembly */
.text
.globl lex
.globl is_letter
.globl is_digit
.globl is_punctuation
.globl is_whitespace

.section .data
tokens_ptr: .quad 0
tokens_count: .quad 0
source_ptr: .quad 0
line_num: .quad 1
col_num: .quad 1

.section .bss
.lcomm token_buffer, 256*32

.section .text

/* is_letter - check if character is a-z or A-Z */
.type is_letter, @function
is_letter:
    cmpl $'a', %edi
    jb 1f
    cmpl $'z', %edi
    ja 1f
    movl $1, %eax
    ret
1:
    cmpl $'A', %edi
    jb 2f
    cmpl $'Z', %edi
    ja 2f
    movl $1, %eax
    ret
2:
    xorl %eax, %eax
    ret

/* is_digit */
.type is_digit, @function
is_digit:
    cmpl $'0', %edi
    jb 1f
    cmpl $'9', %edi
    ja 1f
    movl $1, %eax
    ret
1:
    xorl %eax, %eax
    ret

/* is_punctuation - . ,;:!? */
.type is_punctuation, @function
is_punctuation:
    cmpl $'.', %edi
    je 1f
    cmpl $',', %edi
    je 1f
    cmpl $';', %edi
    je 1f
    cmpl $':', %edi
    je 1f
    cmpl $'!', %edi
    je 1f
    cmpl $'?', %edi
    je 1f
    xorl %eax, %eax
    ret
1:
    movl $1, %eax
    ret

/* is_whitespace */
.type is_whitespace, @function
is_whitespace:
    cmpl $' ', %edi
    je 1f
    cmpl $9,  %edi
    je 1f
    cmpl $13, %edi
    je 1f
    cmpl $10, %edi
    je 1f
    xorl %eax, %eax
    ret
1:
    movl $1, %eax
    ret

/* lex - main lexer entry */
.type lex, @function
lex:
    push %rbp
    mov %rsp, %rbp
    push %rbx
    push %r12
    push %r13
    push %r14

    mov %rdi, %r12      /* source */
    mov %rsi, %r13      /* out_tokens */
    mov %rdx, %r14      /* out_count */

    /* Initialize */
    mov $token_buffer, %rax
    mov %rax, tokens_ptr(%rip)
    mov $0, tokens_count(%rip)
    mov %r12, source_ptr(%rip)

.Lparse_loop:
    movq source_ptr(%rip), %rax
    movsbl (%rax), %edi
    testl %edi, %edi
    jz .Lemit_eof

    call is_whitespace
    testl %eax, %eax
    jnz .Lskip_ws

    call is_punctuation
    testl %eax, %eax
    jnz .Lhandle_punct

    call is_digit
    testl %eax, %eax
    jnz .Lhandle_number

    call is_letter
    testl %eax, %eax
    jnz .Lhandle_word

    /* Skip unknown char */
    incq source_ptr(%rip)
    incq col_num(%rip)
    jmp .Lparse_loop

.Lskip_ws:
    incq source_ptr(%rip)
    movq source_ptr(%rip), %rax
    movsbq -1(%rax), %rdi
    cmpl $10, %edi
    jne .Lparse_loop
    incq line_num(%rip)
    movq $1, col_num(%rip)
    jmp .Lparse_loop

.Lemit_eof:
    movq tokens_ptr(%rip), %rax
    movq tokens_count(%rip), %rcx
    shl $5, %rcx
    movl $4, (%rax, %rcx)   /* T_EOF */
    incq tokens_count(%rip)
    jmp .Ldone

.Ldone:
    movq tokens_ptr(%rip), %rax
    mov %rax, (%r13)
    movq tokens_count(%rip), %rax
    mov %rax, (%r14)
    xorl %eax, %eax
    jmp .Lcleanup

.Lcleanup:
    pop %r14
    pop %r13
    pop %r12
    pop %rbx
    pop %rbp
    ret