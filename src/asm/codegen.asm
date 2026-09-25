; ============================================================
; ENGLISH-ELF: JIT Code Generator
; x86-64 machine code emitter for Windows
; ============================================================

%include "win32.inc"

section .text

; Get current JIT write pointer
jit_pos:
    mov rax, [runtime_jit_buffer + JIT_BUFFER.current]
    ret

; Emit single byte to JIT buffer
; AL = byte
jit_emit_byte:
    mov rcx, [runtime_jit_buffer + JIT_BUFFER.current]
    mov [rcx], al
    inc qword [runtime_jit_buffer + JIT_BUFFER.current]
    ret

; Emit byte sequence to JIT buffer
; RCX = source, RDX = length
jit_emit_bytes:
    push rsi
    mov rsi, rcx
    mov rcx, rdx
    mov rdi, [runtime_jit_buffer + JIT_BUFFER.current]
    rep movsb
    mov [runtime_jit_buffer + JIT_BUFFER.current], rdi
    pop rsi
    ret

; Emit 64-bit immediate
; RAX = value
jit_emit_imm64:
    push rbp
    mov rbp, rsp
    sub rsp, 10
    mov [rbp-10], al        ; opcode + reg (will be filled by caller)
    mov [rbp-1], rax        ; 8-byte immediate
    mov rcx, rbp-10
    mov rdx, 10
    call jit_emit_bytes
    add rsp, 10
    pop rbp
    ret

; Emit MOV RAX, imm64
emit_mov_rax_imm64:
    push rbp
    mov rbp, rsp
    sub rsp, 10
    mov byte [rbp-10], 0x48
    mov byte [rbp-9], 0xB8
    mov [rbp-1], rax
    mov rcx, rbp-10
    mov rdx, 10
    call jit_emit_bytes
    add rsp, 10
    pop rbp
    ret

; Emit MOV RCX, imm64
emit_mov_rcx_imm64:
    push rbp
    mov rbp, rsp
    sub rsp, 10
    mov byte [rbp-10], 0x48
    mov byte [rbp-9], 0xB9
    mov [rbp-1], rax
    mov rcx, rbp-10
    mov rdx, 10
    call jit_emit_bytes
    add rsp, 10
    pop rbp
    ret

; Emit XOR RAX, RAX
emit_xor_rax:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov byte [rbp-8], 0x48
    mov byte [rbp-7], 0x31
    mov byte [rbp-6], 0xC0
    mov rcx, rsp-8
    mov rdx, 3
    call jit_emit_bytes
    add rsp, 8
    pop rbp
    ret

; Emit RET
emit_ret:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov byte [rbp-8], 0xC3
    mov rcx, rsp-8
    mov rdx, 1
    call jit_emit_bytes
    add rsp, 8
    pop rbp
    ret

; Emit CALL RAX
emit_call_rax:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov byte [rbp-8], 0xFF
    mov byte [rbp-7], 0xD0
    mov rcx, rsp-8
    mov rdx, 2
    call jit_emit_bytes
    add rsp, 8
    pop rbp
    ret

; Emit JMP RAX
emit_jmp_rax:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov byte [rbp-8], 0xFF
    mov byte [rbp-7], 0xE0
    mov rcx, rsp-8
    mov rdx, 2
    call jit_emit_bytes
    add rsp, 8
    pop rbp
    ret

; Emit JMP rel32 (placeholder, returns offset of rel32 field for patching)
emit_jmp_rel32:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov byte [rbp-8], 0xE9
    mov dword [rbp-4], 0
    mov rcx, rsp-8
    mov rdx, 5
    call jit_emit_bytes
    mov eax, 1
    add rsp, 8
    pop rbp
    ret

; Emit NOPs for padding
; RCX = count
emit_nops:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov byte [rbp-8], 0x90
.loop:
    mov rcx, rsp-8
    mov rdx, 1
    call jit_emit_bytes
    dec rcx
    jnz .loop
    add rsp, 8
    pop rbp
    ret

; Emit MOV RAX, [RAX+offset]
; RCX = offset
emit_mov_rax_memb_rax_off:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov byte [rbp-16], 0x48
    mov byte [rbp-15], 0x8B
    mov byte [rbp-14], 0x40
    mov dword [rbp-10], ecx
    mov rcx, rsp-16
    mov rdx, 8
    call jit_emit_bytes
    add rsp, 16
    pop rbp
    ret

; Emit MOV [RAX+offset], RBX
; RCX = offset
emit_mov_memb_rax_off_rbx:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov byte [rbp-16], 0x48
    mov byte [rbp-15], 0x89
    mov byte [rbp-14], 0x58
    mov dword [rbp-10], ecx
    mov rcx, rsp-16
    mov rdx, 8
    call jit_emit_bytes
    add rsp, 16
    pop rbp
    ret

; Emit ADD RAX, [RBX+offset]
; RCX = offset
emit_add_rax_memb_rbx_off:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov byte [rbp-16], 0x48
    mov byte [rbp-15], 0x03
    mov byte [rbp-14], 0x43
    mov dword [rbp-10], ecx
    mov rcx, rsp-16
    mov rdx, 8
    call jit_emit_bytes
    add rsp, 16
    pop rbp
    ret