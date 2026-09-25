; ============================================================
; ENGLISH-ELF: English Programming Language - Windows x86-64
; Pure NASM assembly, zero libc. Source .txt files are read
; into memory and interpreted directly - no IR, no compile
; step. The English text IS the program.
;
; Build:   build.bat        (nasm -f win64 + lld-link)
; Usage:   english.exe program.txt [program2.txt ...]
;          english.exe --repl
;
; Kernel32 functions are imported via build\kernel32.lib,
; which build.bat generates from src\asm\kernel32.def with
; lld-link, so no Windows SDK is required.
; ============================================================

bits 64
default rel

%include "win32.inc"
%include "runtime.asm"
%include "lexicon.asm"
%include "lexer.asm"
%include "parser.asm"

; ---------- kernel32 imports ----------
extern CloseHandle
extern CreateFileA
extern ExitProcess
extern GetCommandLineA
extern GetFileSizeEx
extern GetStdHandle
extern ReadFile
extern Sleep
extern VirtualAlloc
extern WriteFile

section .text

; ============================================================
; Entry point
; ============================================================
global mainCRTStartup
mainCRTStartup:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48h

    call runtime_init

    call GetCommandLineA
    mov rbx, rax

    ; --repl check
    mov rcx, rbx
    lea rdx, [rel cmd_repl]
    call substr_ci
    test eax, eax
    jnz .repl
    ; parse command line into argv
    mov rcx, rbx
    call parse_command_line
    mov r12, rax                ; argc
    lea r13, [rel g_argv]       ; argv

    cmp r12, 1
    jle .usage

    xor r14, r14                ; error count
    mov r15, 1                  ; skip program name
.exec_loop:
    cmp r15, r12
    jge .done
    mov rcx, [r13 + r15 * 8]
    cmp byte [rcx], '-'
    je .next_arg
    call execute_source_file
    add r14, rax
.next_arg:
    inc r15
    jmp .exec_loop
.done:
    xor ecx, ecx
    test r14, r14
    jz .exit
    mov ecx, 1
.exit:
    call ExitProcess

.usage:
    lea rcx, [rel usage_msg]
    call print_z
    xor ecx, ecx
    call ExitProcess

.repl:
    call repl_main
    xor ecx, ecx
    call ExitProcess

; ============================================================
; parse_command_line(rcx=cmdline)
; -> rax = argc, rbx = argv (pointers into heap copies)
; Handles "quoted" args with spaces.
; ============================================================
parse_command_line:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40h
    mov rbx, rcx                ; cursor
    lea r12, [rel g_argv]
    xor r13, r13                ; argc
    xor r14, r14                ; in-quotes flag
.loop:
    mov al, [rbx]
    test al, al
    jz .finish
    cmp al, ' '
    je .skip_ws
    cmp al, 9
    je .skip_ws
    cmp al, 13
    je .skip_ws
    cmp al, 10
    je .skip_ws
    ; start of arg
    cmp al, '"'
    jne .arg_start
    inc rbx
    mov r14, 1
.arg_start:
    mov rcx, rbx                ; arg start
.len_loop:
    mov al, [rbx]
    test al, al
    jz .len_done
    test r14, r14
    jnz .q_loop
    cmp al, ' '
    je .len_done
    cmp al, 9
    je .len_done
    cmp al, 13
    je .len_done
    cmp al, 10
    je .len_done
    jmp .adv
.q_loop:
    cmp al, '"'
    je .len_done
.adv:
    inc rbx
    jmp .len_loop
.len_done:
    mov rdx, rbx
    sub rdx, rcx                ; arg length
    push rcx
    push rdx
    mov rcx, rdx
    add rcx, 1
    call heap_alloc
    mov rdi, rax
    pop rdx
    pop rcx
    mov rsi, rcx
    mov rcx, rdx
    rep movsb
    mov byte [rdi], 0
    mov [r12 + r13 * 8], rax
    inc r13
    cmp byte [rbx], '"'
    jne .no_close
    inc rbx
.no_close:
    mov r14, 0
    jmp .loop
.skip_ws:
    inc rbx
    jmp .loop
.finish:
    mov [rel g_argc], r13
    mov rax, r13
    add rsp, 40h
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================
; execute_source_file(rcx=path cstr)
; -> rax = 0 ok, 1 error
; ============================================================
execute_source_file:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    sub rsp, 48h
    mov rbx, rcx                ; path

    mov rcx, rbx
    mov rdx, GENERIC_READ
    mov r8, FILE_SHARE_READ
    xor r9, r9
    sub rsp, 20h
    mov qword [rsp + 32], OPEN_EXISTING
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    call CreateFileA
    add rsp, 20h
    mov r12, rax
    cmp r12, INVALID_HANDLE_VALUE
    je .open_fail

    mov rcx, r12
    lea rdx, [rbp - 40h]        ; LARGE_INTEGER size
    sub rsp, 40h
    call GetFileSizeEx
    add rsp, 40h
    test rax, rax
    jz .close_fail

    mov r13, [rbp - 40h]        ; file size

    mov rcx, r13
    add rcx, 1
    call heap_alloc
    mov rbx, rax                ; buffer

    mov rcx, r12
    mov rdx, rbx
    mov r8, r13
    lea r9, [rbp - 48h]         ; bytes read
    sub rsp, 20h
    mov qword [rsp + 32], 0
    call ReadFile
    add rsp, 20h

    mov rcx, r12
    sub rsp, 40h
    call CloseHandle
    add rsp, 40h

    mov byte [rbx + r13], 0     ; null-terminate

    ; empty check
    mov rcx, rbx
    mov rdx, r13
    call lex_init
    call lex_next
    cmp qword [rel lex_state + LEXER.tok_type], TOK_EOF
    je .empty

    ; parse + interpret (parse_program re-inits the lexer)
    mov rcx, rbx
    mov rdx, r13
    call parse_program
    xor eax, eax
    jmp .done

.empty:
    lea rcx, [rel msg_empty]
    call print_z
    mov eax, 1
    jmp .done

.open_fail:
    lea rcx, [rel msg_open_fail]
    call print_z
    mov rcx, rbx
    call print_z
    call print_newline
    mov eax, 1
    jmp .done

.close_fail:
    mov rcx, r12
    sub rsp, 40h
    call CloseHandle
    add rsp, 40h
    mov eax, 1

.done:
    add rsp, 48h
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================
; repl_main: interactive English interpreter
; ============================================================
repl_main:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    sub rsp, 40h

    lea rcx, [rel repl_welcome]
    call print_z

.loop:
    lea rcx, [rel repl_prompt]
    call print_z

    mov rcx, [rel g_stdin]
    lea rdx, [rel g_repl_buf]
    mov r8d, REPL_BUF_LEN
    lea r9, [rel g_repl_n]
    sub rsp, 20h
    mov qword [rsp + 32], 0
    call ReadFile
    add rsp, 20h
    test rax, rax
    jz .exit

    mov r12, [rel g_repl_n]
    test r12, r12
    jz .exit

    lea rbx, [rel g_repl_buf]
    mov byte [rbx + r12], 0

    ; exit command?
    mov rcx, rbx
    lea rdx, [rel cmd_exit]
    call substr_ci_prefix
    test eax, eax
    jnz .exit

    ; blank line?
    cmp r12, 2
    jbe .loop

    mov rcx, rbx
    mov rdx, r12
    call parse_program
    jmp .loop

.exit:
    add rsp, 40h
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================
; String helpers (leaf, no calls)
; ============================================================

; substr_ci(rcx=hay cstr, rdx=needle cstr) -> eax = 1 if contained
substr_ci:
    push rbx
    push r12
    push r13
    push r14
    mov rbx, rcx                ; hay
    mov r12, rdx                ; needle
    xor r13, r13                ; needle len
.nlen:
    mov al, [r12 + r13]
    test al, al
    jz .nlen_done
    inc r13
    jmp .nlen
.nlen_done:
    test r13, r13
    jz .no
    xor r14, r14                ; hay position
.scan:
    mov al, [rbx + r14]
    test al, al
    jz .no
    xor r9, r9
.inner:
    cmp r9, r13
    je .yes
    mov al, [rbx + r14]
    or al, 32
    cmp al, [r12 + r9]
    jne .next_pos
    inc r9
    inc r14
    jmp .inner
.next_pos:
    inc r14
    jmp .scan
.yes:
    mov eax, 1
    jmp .done
.no:
    xor eax, eax
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; substr_ci_prefix(rcx=text, rdx=prefix) -> eax = 1 if text starts with prefix
substr_ci_prefix:
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    xor r8, r8
.loop:
    mov al, [r12 + r8]
    test al, al
    jz .yes
    mov dl, [rbx + r8]
    or al, 32
    or dl, 32
    cmp al, dl
    jne .no
    inc r8
    jmp .loop
.yes:
    mov eax, 1
    jmp .done
.no:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

section .data
cmd_repl        db "--repl", 0
cmd_exit        db "exit", 0
repl_welcome    db "ENGLISH-ELF v1.0 - English Programming Runtime", 13, 10
                db "Type English programs. 'exit' quits.", 13, 10, 0
repl_prompt     db "> ", 0
usage_msg       db "ENGLISH-ELF v1.0 - English Programming Language (x86-64, pure NASM)", 13, 10
                db "  Usage: english.exe program.txt [program2.txt ...]", 13, 10
                db "         english.exe --repl", 13, 10
                db "  The .txt source is the program - read into memory and run directly.", 13, 10, 0
msg_empty       db "ERROR: source file is empty", 13, 10, 0
msg_open_fail   db "ERROR: cannot open file: ", 0

section .bss
align 16
g_argc          resq 1
g_argv          resq 64
g_repl_buf      resb 8192
g_repl_n        resq 1
REPL_BUF_LEN    equ 8192
