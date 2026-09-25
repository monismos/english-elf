; ENGLISH-ELF Main - ELF Binary Compiler
; Entry point for self-hosted compiler

section .data
    welcome_msg db "ENGLISH-ELF Assembler v1.0"
    welcome_len equ 26
    newline db 10
    prompt db "> "
    prompt_len equ 2

section .bss
    tokens_out resq 1
    tokens_count resq 1
    source_content resq 1

section .text
    global _start
    extern lex
    extern parse_program
    extern compile_to_elf

_start:
    ; Linux x86-64 entry - no libc, pure syscalls
    
    ; Print welcome
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, welcome_msg
    mov rdx, welcome_len
    syscall
    
    ; Print newline
    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall
    
    ; Check arguments
    mov rax, [rsp]      ; argc
    cmp rax, 2
    jb .no_args
    
    ; Get source file path
    mov rdi, [rsp + 8]  ; argv[0] = program name
    mov r12, rdi
    
    ; Open source file
    mov rdi, [rsp + 16]  ; argv[1] = source path
    mov rax, 2           ; sys_open
    mov esi, 0           ; O_RDONLY
    syscall
    
    cmp rax, 0
    jl .file_error
    mov r13, rax         ; fd
    
    ; Read file (simple: read up to 64KB)
    mov rax, 0           ; sys_read
    mov rdi, r13         ; fd
    mov rsi, source_buffer
    mov rdx, 65536
    syscall
    
    mov r14, rax         ; bytes read
    
    ; Close file
    mov rax, 3
    mov rdi, r13
    syscall
    
    ; Null terminate
    mov byte [source_buffer + r14], 0
    
    ; Lex source
    mov rdi, source_buffer
    lea rsi, [tokens_out]
    lea rdx, [tokens_count]
    call lex
    test eax, eax
    jnz .lex_error
    
    ; Compile to ELF
    mov rdi, [rsp + 16]  ; source path
    mov rsi, source_buffer
    call compile_to_elf
    
    ; Exit success
    mov rax, 60
    mov rdi, 0
    syscall

.no_args:
    mov rax, 60
    mov rdi, 0
    syscall

.file_error:
    mov rax, 60
    mov rdi, 1
    syscall

.lex_error:
    mov rax, 60
    mov rdi, 2
    syscall

section .bss
    source_buffer resb 65536