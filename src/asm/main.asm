; ENGLISH-ELF Compiler Main Assembly
; Entry point for the ELF-binary compiler

section .data
    welcome_msg db "ENGLISH-ELF Compiler v1.0", 10, 0
    compile_msg db "Compiling: ", 0
    done_msg db "Compilation complete.", 10, 0
    error_msg db "Compilation error.", 10, 0

section .text
    global main
    extern lex
    extern parse_program
    extern compile_to_elf
    extern free_tokens

main:
    ; Linux x86-64 entry point
    ; Arguments: argc (rdi), argv (rsi)
    
    push rbp
    mov rbp, rsp
    
    ; Print welcome
    mov rdi, welcome_msg
    call printf
    
    ; Check arguments
    cmp edi, 2          ; need at least file argument
    jl .usage_error
    
    ; Get file path (argv[1])
    mov rax, [rsi + 8]  ; argv[1]
    mov r12, rax        ; r12 = file path
    
    ; Read file contents
    mov rdi, rax
    call read_file
    test rax, rax
    jz .file_error
    
    mov r13, rax        ; r13 = source string
    
    ; Lex source
    mov rdi, rax
    lea rsi, [rel tokens_out]
    lea rdx, [rel count_out]
    call lex
    test eax, eax
    jnz .lex_error
    
    ; Parse tokens
    mov rdi, [tokens_out]
    mov rsi, [count_out]
    call parse_program
    mov r14, rax        ; r14 = parsed program
    
    ; Compile to ELF
    mov rdi, rax
    mov rsi, r12        ; file path for output name
    call compile_to_elf
    test eax, eax
    jnz .compile_error
    
    ; Cleanup
    mov rdi, [tokens_out]
    call free_tokens
    mov rdi, r13
    call free
    
    mov rdi, done_msg
    call printf
    
    xor eax, eax        ; return 0
    jmp .cleanup

.usage_error:
    mov rdi, usage_msg
    call printf
    mov eax, 1
    jmp .cleanup

.file_error:
    mov rdi, file_error_msg
    call printf
    mov eax, 1
    jmp .cleanup

.lex_error:
    mov rdi, lex_error_msg
    call printf
    mov eax, 1
    jmp .cleanup

.compile_error:
    mov rdi, error_msg
    call printf
    mov eax, 1
    jmp .cleanup

.cleanup:
    pop rbp
    ret

; ============================================================
; System call wrappers and helpers
; ============================================================

read_file:
    ; rdi = file path
    ; returns: file contents string in rax, or NULL on error
    
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Open file
    mov rax, 2          ; sys_open
    mov rbx, rdi        ; save path
    mov rdi, rdi
    mov esi, 0          ; O_RDONLY
    mov edx, 0          ; mode
    syscall
    
    cmp rax, 0
    jl .error
    
    mov r15, rax        ; r15 = file descriptor
    
    ; Get file size (lseek to end)
    mov rax, 8          ; sys_lseek
    mov rdi, r15
    xor esi, esi
    mov edx, 2          ; SEEK_END
    syscall
    
    mov r14, rax        ; r14 = file size
    
    ; Allocate buffer
    mov rdi, rax
    inc rdi             ; +1 for null terminator
    call malloc
    mov r13, rax        ; r13 = buffer
    
    ; Seek back to start
    mov rax, 8          ; sys_lseek
    mov rdi, r15
    xor esi, esi
    xor edx, edx        ; SEEK_SET
    syscall
    
    ; Read file
    mov rax, 0          ; sys_read
    mov rdi, r15
    mov rsi, r13
    mov rdx, r14
    syscall
    
    ; Close file
    mov rax, 3          ; sys_close
    mov rdi, r15
    syscall
    
    ; Null terminate
    mov byte [r13 + r14], 0
    
    mov rax, r13        ; return buffer
    jmp .done
    
.error:
    xor eax, eax
    
.done:
    pop rbx
    pop rbp
    ret

section .data
    usage_msg db "Usage: english-elf <source.txt>", 10, 0
    file_error_msg db "Error opening file", 10, 0
    lex_error_msg db "Lexical error", 10, 0

section .bss
    tokens_out resq 1
    count_out resq 1