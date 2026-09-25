/* ENGLISH-ELF Assembly Compiler */
.section .text
.globl _start

_start:
	movq (%rsp), %rax
	cmpq $2, %rax
	jne .Lexit_ok

	movq 8(%rsp), %rdi
	movl $2, %eax
	xorl %esi, %esi
	syscall
	movq %rax, %rbx

	movl $8, %eax
	movq %rbx, %rdi
	movl $2, %esi
	syscall
	movq %rax, %r12    /* size */

	movl $8, %eax
	movq %rbx, %rdi
	xorl %esi, %esi
	syscall

	movl $0, %eax
	movq %rbx, %rdi
	leaq src_buf(%rip), %rsi
	movq %r12, %rdx
	syscall

	movl $3, %eax
	movq %rbx, %rdi
	syscall

	leaq src_buf(%rip), %r8
	xorq %rcx, %rcx

.Lscan_loop:
	cmpq %r12, %rcx
	jge .Lexit_ok

	movb (%r8, %rcx), %al
	cmpl $'s', %eax
	je .Lcheck_a
	cmpl $'S', %eax
	je .Lcheck_a
	jmp .Lnext_char

.Lcheck_a:
	movq %rcx, %r13
	leaq 1(%r8), %r9
	movb (%r9, %rcx), %al
	orl $32, %eax
	cmpl $'a', %eax
	jne .Lnext_char
	
	leaq 2(%r8), %r9
	movb (%r9, %rcx), %al
	orl $32, %eax
	cmpl $'y', %eax
	jne .Lnext_char

	/* found "say" */
	leaq 3(%r8, %rcx), %rsi
	jmp .Lskip_spaces

.Lnext_char:
	incq %rcx
	jmp .Lscan_loop

.Lskip_spaces:
	movsbl (%rsi), %eax
	cmpl $' ', %eax
	je .Linc_skip
	cmpl $'.', %eax
	je .Lexit_ok
	cmpl $0, %eax
	je .Lexit_ok
	jmp .Lcount_len

.Linc_skip:
	incq %rsi
	jmp .Lskip_spaces

.Lcount_len:
	movq %rsi, %r9
	xorq %rdx, %rdx

.Llen_loop:
	movsbl (%r9, %rdx), %eax
	cmpl $0, %eax
	je .Ldo_print
	cmpl $'.', %eax
	je .Ldo_print
	incq %rdx
	jmp .Llen_loop

.Ldo_print:
	movl $1, %eax
	movq $1, %rdi
	movq %r9, %rsi
	movq %rdx, %rdx
	syscall

	movl $1, %eax
	movq $1, %rdi
	leaq nl(%rip), %rsi
	movq $1, %rdx
	syscall

	jmp .Lexit_ok

.Lexit_ok:
	movl $60, %eax
	xorq %rdi, %rdi
	syscall

.section .data
nl: .byte 10

.section .bss
src_buf: .skip 65536