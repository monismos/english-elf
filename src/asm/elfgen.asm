; ENGLISH-ELF ELF Generator
; Generates valid x86-64 ELF binaries

section .data
    ; ELF header constants
    ELF_MAGIC       equ 0x464C457F      ; "\x7FELF"
    ELF_CLASS_64    equ 2
    ELF_DATA_LE     equ 1               ; little endian
    ELF_VERSION     equ 1
    ELF_OS_LINUX    equ 3
    ELF_ABI_SYSV    equ 0
    
    ; ELF program header types
    PT_LOAD         equ 1
    PF_R            equ 4
    PF_W            equ 2
    PF_X            equ 1
    
    ; ELF section header types
    SHT_NULL        equ 0
    SHT_PROGBITS    equ 1
    SHT_SYMTAB      equ 2
    SHT_STRTAB      equ 3
    
    ; Machine code for common operations
    ; These are x86-64 opcodes
    
    ; Function prologue: push rbp; mov rbp, rsp
    PROLOGUE db 0x55, 0x48, 0x89, 0xE5
    PROLOGUE_LEN equ 4
    
    ; Function epilogue: pop rbp; ret
    EPILOGUE db 0x5D, 0xC3
    EPILOGUE_LEN equ 2
    
    ; mov rax, imm64
    MOV_RAX_IMM64 db 0x48, 0xB8
    MOV_RAX_IMM64_LEN equ 9
    
    ; mov rdi, rax (for output)
    MOV_RDI_RAX db 0x48, 0x89, 0xC7
    MOV_RDI_RAX_LEN equ 3
    
    ; call rbp + offset (relative call) - we'll use direct calls
    ; mov rsi, offset for function calls
    
    ; Exit syscall wrapper
    ; mov rax, 60; xor rdi, rdi; syscall
    EXIT_SYSCALL db 0x48, 0xC7, 0xC0, 0x3C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  ; mov rax, 60
                db 0x48, 0x31, 0xFF  ; xor rdi, rdi
                db 0x0F, 0x05       ; syscall
    EXIT_SYSCALL_LEN equ 14
    
    ; Write syscall: mov rax, 1; mov rdi, 1; mov rdx, len; lea rsi, [buf]; syscall
    WRITE_SYSCALL_SETUP db 0x48, 0xC7, 0xC0, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  ; mov rax, 1
                       db 0x48, 0xC7, 0xC7, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  ; mov rdi, 1 (stdout)
    WRITE_SYSCALL_SETUP_LEN equ 22

section .bss
    code_buffer resq 1
    code_pos resq 1
    code_size resq 1
    elf_buffer resq 1
    elf_size resq 1

section .text
    global emit_elf_header
    global emit_program_header
    global emit_code_section
    global emit_runtime_call
    global elf_write_file

section .text

; ============================================================
; ELF Header generation (64 bytes)
; ============================================================
emit_elf_header:
    ; rdi = buffer to write to
    ; Returns bytes written in rax
    
    push rbp
    mov rbp, rsp
    
    mov rax, rdi
    
    ; e_ident (16 bytes)
    mov dword [rax + 0], ELF_MAGIC     ; magic
    mov byte [rax + 4], ELF_CLASS_64   ; 64-bit
    mov byte [rax + 5], ELF_DATA_LE    ; little endian
    mov byte [rax + 6], ELF_VERSION
    mov byte [rax + 7], ELF_OS_LINUX
    mov byte [rax + 8], ELF_ABI_SYSV
    mov qword [rax + 9], 0             ; padding
    
    ; e_type - ET_EXEC (executable)
    mov word [rax + 16], 2
    
    ; e_machine - EM_X86_64
    mov word [rax + 18], 62
    
    ; e_version
    mov dword [rax + 20], 1
    
    ; e_entry - entry point (will be set to code start)
    lea rdx, [rdi + 0x1000]            ; after headers
    mov qword [rax + 24], rdx
    
    ; e_phoff - program header offset
    mov qword [rax + 32], 64           ; right after ELF header
    
    ; e_shoff - section header offset (0 for now)
    mov qword [rax + 40], 0
    
    ; e_flags, e_ehsize, e_phentsize, e_phnum
    mov dword [rax + 48], 0
    mov word [rax + 52], 64            ; ELF header size
    mov word [rax + 54], 56            ; program header entry size
    mov word [rax + 56], 1             ; one program header
    
    ; e_shentsize, e_shnum, e_shstrndx
    mov word [rax + 58], 64
    mov word [rax + 60], 0
    mov word [rax + 62], 0
    
    mov eax, 64
    pop rbp
    ret

; ============================================================
; Program Header generation (56 bytes)
; ============================================================
emit_program_header:
    ; rdi = buffer to write to
    ; rsi = code size
    ; Returns bytes written in rax
    
    push rbp
    mov rbp, rsp
    
    mov rax, rdi
    
    ; p_type
    mov dword [rax + 0], PT_LOAD
    
    ; p_offset
    mov qword [rax + 8], 0x1000       ; code starts at page boundary
    
    ; p_vaddr
    mov qword [rax + 16], 0x400000
    
    ; p_paddr
    mov qword [rax + 24], 0x400000
    
    ; p_filesz
    mov [rax + 32], rsi
    
    ; p_memsz
    mov [rax + 40], rsi
    
    ; p_flags
    mov dword [rax + 48], PF_R | PF_W | PF_X
    
    ; p_align
    mov qword [rax + 52], 0x1000
    
    mov eax, 56
    pop rbp
    ret

; ============================================================
; Runtime call generation
; ============================================================
emit_runtime_call:
    ; Emit a call to a runtime function
    ; rdi = buffer
    ; rsi = function offset (or 0 for stub)
    
    push rbp
    mov rbp, rsp
    
    mov rax, rdi
    
    ; For now, just put a ret (stub)
    mov byte [rax + 0], 0xC3          ; ret
    
    mov eax, 1
    pop rbp
    ret

; ============================================================
; Print integer (using syscall)
; Generates: write(1, &buffer, 20) then print number
; ============================================================
emit_print_int:
    ; This is complex - we need to:
    ; 1. Convert integer to string
    ; 2. Write to stdout
    ; For now, emit a simple syscall
    
    ret

; ============================================================
; ELF file writer
; ============================================================
elf_write_file:
    ; rdi = file path
    ; rsi = code buffer
    ; rdx = code size
    ; Returns 0 on success
    
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rdi        ; file path
    mov r13, rsi        ; code buffer
    mov r14, rdx        ; code size
    
    ; Allocate ELF buffer (code size + headers + padding)
    mov rax, rdx
    add rax, 64         ; ELF header
    add rax, 56         ; program header
    add rax, 4096       ; page alignment padding
    and rax, -4096       ; round to page boundary
    add rax, 4096        ; ensure space
    
    mov rdi, rax
    call malloc
    mov rbx, rax        ; ELF buffer
    
    ; Write ELF header at offset 0
    mov rdi, rax
    call emit_elf_header
    
    ; Write program header at offset 64
    lea rdi, [rbx + 64]
    mov rsi, r14        ; code size
    call emit_program_header
    
    ; Write code at offset 0x1000
    lea rdi, [rbx + 4096]
    mov rsi, r13        ; code source
    mov rcx, r14        ; code size
    call memcpy
    
    ; Write file
    mov rax, 2          ; sys_open
    mov rdi, r12        ; path
    mov esi, 0x41       ; O_WRONLY | O_CREAT
    mov edx, 0x1A4      ; 0755 permissions
    syscall
    
    mov r15, rax        ; file descriptor
    
    ; Write ELF content
    mov rax, 1          ; sys_write
    mov rdi, r15        ; fd
    mov rsi, rbx        ; buffer
    ; Calculate total size
    mov rdx, [rbx + 32] ; p_filesz from program header
    mov rax, 4096       ; at least one page
    add rax, rdx
    mov rdx, rax
    mov rsi, rbx
    mov rax, 1
    syscall
    
    ; Close file
    mov rax, 3
    mov rdi, r15
    syscall
    
    ; Cleanup
    mov rdi, rbx
    call free
    
    xor eax, eax
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================
; Simple ELF stub writer (for testing)
; ============================================================
write_elf_stub:
    ; Create minimal executable that prints "Hello" and exits
    ; This is a proof-of-concept
    
    ; For now return error to indicate stub
    mov eax, 1
    ret