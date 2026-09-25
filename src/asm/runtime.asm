; ============================================================
; ENGLISH-ELF: Runtime
; Heap, console I/O, strings, values, variables, math
; Windows x86-64 NASM
; ============================================================

%include "win32.inc"

section .data
align 8
    g_stdout    dq 0
    g_stderr    dq 0
    g_stdin     dq 0
    g_heap_base dq 0
    g_heap_top  dq 0
    g_heap_end  dq 0
    g_exit_code dq 0
    g_repl_mode dq 0

    ; constants
    sz_newline  db 13, 10
    sz_yes      db "yes", 0
    sz_no       db "no", 0

section .bss
align 16
    g_tmp_buf   resb 512      ; scratch for lowercase word etc.

section .text

; ============================================================
; runtime_init(): get handles, allocate 256MB arena
; ============================================================
runtime_init:
    sub rsp, 48h
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [g_stdout], rax
    mov ecx, STD_ERROR_HANDLE
    call GetStdHandle
    mov [g_stderr], rax
    mov ecx, STD_INPUT_HANDLE
    call GetStdHandle
    mov [g_stdin], rax

    mov r9, PAGE_EXECUTE_READWRITE
    mov r8, MEM_COMMIT | MEM_RESERVE
    mov rdx, 256 * 1024 * 1024
    xor ecx, ecx
    call VirtualAlloc
    mov [g_heap_base], rax
    mov [g_heap_top], rax
    lea rcx, [rax + 256 * 1024 * 1024]
    mov [g_heap_end], rcx
    add rsp, 48h
    ret

; ============================================================
; heap_alloc(rcx=size) -> rax=ptr (16-byte aligned, zeroed)
; ============================================================
heap_alloc:
    mov rax, [g_heap_top]
    add rcx, 15
    and rcx, -16
    lea rdx, [rax + rcx]
    cmp rdx, [g_heap_end]
    ja heap_oom
    mov [g_heap_top], rdx
    ret
heap_oom:
    sub rsp, 48h
    mov rcx, [g_stderr]
    lea rdx, [rel msg_oom]
    mov r8, msg_oom_len
    xor r9, r9
    sub rsp, 20h
    mov qword [rsp + 20h], 0
    call WriteFile
    add rsp, 20h
    mov ecx, 3
    call ExitProcess

section .data
msg_oom     db "ERROR: out of memory", 13, 10
msg_oom_len equ $ - msg_oom

section .text

; ============================================================
; Console output helpers (Microsoft x64: all self-contained)
; ============================================================

; write_stdout(rcx=ptr, rdx=len)
write_stdout:
    sub rsp, 48h
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [g_stdout]
    xor r9, r9
    sub rsp, 20h
    mov qword [rsp + 20h], 0
    call WriteFile
    add rsp, 20h
    add rsp, 48h
    ret

; print_z(rcx=null-terminated string)
print_z:
    push rbx
    mov rbx, rcx
    xor eax, eax
.len:
    cmp byte [rbx + rax], 0
    je .done_len
    inc rax
    jmp .len
.done_len:
    mov rdx, rax
    mov rcx, rbx
    call write_stdout
    pop rbx
    ret

; print_len(rcx=ptr, rdx=len)
print_len:
    call write_stdout
    ret

; print_newline()
print_newline:
    sub rsp, 8
    lea rcx, [rel sz_newline]
    mov rdx, 2
    call write_stdout
    add rsp, 8
    ret

; print_int64(rcx=value)  (no newline)
print_int64:
    sub rsp, 48h
    mov rax, rcx
    lea rdi, [rsp + 8]
    mov rsi, rdi
    add rsi, 40            ; buffer end
    mov byte [rsi], 0
    dec rsi
    mov r8b, 0             ; negative flag
    test rax, rax
    jns .positive
    neg rax
    mov r8b, 1
.positive:
    test rax, rax
    jnz .digits
    mov byte [rsi], '0'
    dec rsi
    jmp .sign
.digits:
    mov rcx, 10
.div:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .div
.sign:
    test r8b, r8b
    jz .emit
    mov byte [rsi], '-'
    dec rsi
.emit:
    inc rsi
    mov rcx, rsi
    mov rdx, rdi
    add rdx, 40
    sub rdx, rsi
    call write_stdout
    add rsp, 48h
    ret

; ============================================================
; Strings: sstr_create(rcx=ptr, rdx=len) -> rax=SSTR*
; ============================================================
sstr_create:
    push rbx
    push rdi
    sub rsp, 8
    mov rbx, rcx
    mov rdi, rdx
    mov rcx, SSTR_size + 1
    call heap_alloc
    mov [rax + SSTR.len], rdi
    lea rdx, [rax + SSTR_size]
    mov [rax + SSTR.ptr], rdx
    mov rcx, rbx
    mov rdi, rdx
    mov rsi, rcx
    mov rcx, [rax + SSTR.len]
    rep movsb
    mov byte [rdi], 0
    add rsp, 8
    pop rdi
    pop rbx
    ret

; sstr_from_cstr(rcx=char*) -> rax=SSTR*
sstr_from_cstr:
    push rbx
    mov rbx, rcx
    xor eax, eax
.len:
    cmp byte [rbx + rax], 0
    je .done
    inc rax
    jmp .len
.done:
    mov rcx, rbx
    mov rdx, rax
    call sstr_create
    pop rbx
    ret

; sstr_cat(rcx=a, rdx=b) -> rax=SSTR*
sstr_cat:
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    mov rcx, [rbx + SSTR.len]
    add rcx, [r12 + SSTR.len]
    push rcx
    call heap_alloc
    pop rcx
    mov [rax + SSTR.len], rcx
    lea rdi, [rax + SSTR_size]
    mov [rax + SSTR.ptr], rdi
    mov rsi, [rbx + SSTR.ptr]
    mov rcx, [rbx + SSTR.len]
    rep movsb
    mov rsi, [r12 + SSTR.ptr]
    mov rcx, [r12 + SSTR.len]
    rep movsb
    mov byte [rdi], 0
    pop r12
    pop rbx
    ret

; sstr_eq_ci(rcx=a, rdx=b) -> rax=1 if equal case-insensitive
sstr_eq_ci:
    push rbx
    push r12
    mov rbx, [rcx + SSTR.len]
    mov r12, [rdx + SSTR.len]
    cmp rbx, r12
    jne .no
    mov rsi, [rcx + SSTR.ptr]
    mov rdi, [rdx + SSTR.ptr]
    xor rcx, rcx
.loop:
    cmp rcx, rbx
    je .yes
    mov al, [rsi + rcx]
    mov dl, [rdi + rcx]
    or al, 32
    or dl, 32
    cmp al, dl
    jne .no
    inc rcx
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

; sstr_print(rcx=SSTR*)
sstr_print:
    push rbx
    mov rbx, rcx
    mov rcx, [rbx + SSTR.ptr]
    mov rdx, [rbx + SSTR.len]
    call write_stdout
    pop rbx
    ret

; ============================================================
; Values
; ============================================================

; val_int(rcx=i64) -> rax=Value* (V_INT)
val_int:
    push rbx
    mov rbx, rcx
    mov rcx, VALUE_size
    call heap_alloc
    mov qword [rax + VALUE.type], V_INT
    mov [rax + VALUE.data], rbx
    pop rbx
    ret

; val_bool(rcx=0/1) -> rax=Value* (V_BOOL)
val_bool:
    push rbx
    mov rbx, rcx
    mov rcx, VALUE_size
    call heap_alloc
    mov qword [rax + VALUE.type], V_BOOL
    mov [rax + VALUE.data], rbx
    pop rbx
    ret

; val_str(rcx=SSTR*) -> rax=Value*
val_str:
    push rbx
    mov rbx, rcx
    mov rcx, VALUE_size
    call heap_alloc
    mov qword [rax + VALUE.type], V_STR
    mov [rax + VALUE.data], rbx
    pop rbx
    ret

; val_list(rcx=SLIST*) -> rax=Value*
val_list:
    push rbx
    mov rbx, rcx
    mov rcx, VALUE_size
    call heap_alloc
    mov qword [rax + VALUE.type], V_LIST
    mov [rax + VALUE.data], rbx
    pop rbx
    ret

; val_nil() -> rax=Value*
val_nil:
    sub rsp, 8
    mov rcx, VALUE_size
    call heap_alloc
    mov qword [rax + VALUE.type], V_NIL
    mov qword [rax + VALUE.data], 0
    add rsp, 8
    ret

; list_create() -> rax=SLIST*  (cap 4)
list_create:
    push rbx
    mov rcx, SLIST_size
    call heap_alloc
    mov rbx, rax
    mov qword [rbx + SLIST.len], 0
    mov qword [rbx + SLIST.cap], 4
    mov rcx, 4 * VALUE_size
    call heap_alloc
    mov [rbx + SLIST.items], rax
    mov rax, rbx
    pop rbx
    ret

; list_append(rcx=SLIST*, rdx=Value*)
list_append:
    push rbx
    push r12
    push r13
    mov rbx, rcx
    mov r12, rdx
    mov r13, [rbx + SLIST.len]
    cmp r13, [rbx + SLIST.cap]
    jb .room
    ; grow x2
    mov rax, [rbx + SLIST.cap]
    shl rax, 1
    mov [rbx + SLIST.cap], rax
    push rbx
    mov rbx, rax
    imul rbx, VALUE_size
    mov rcx, rbx
    call heap_alloc
    pop rbx
    ; copy old items
    push rdi
    push rsi
    mov rdi, rax
    mov rsi, [rbx + SLIST.items]
    mov rcx, [rbx + SLIST.len]
    imul rcx, VALUE_size
    rep movsb
    pop rsi
    pop rdi
    mov [rbx + SLIST.items], rax
.room:
    mov rax, [rbx + SLIST.items]
    shl r13, 4
    add rax, r13
    mov rcx, [r12 + VALUE.type]
    mov [rax + VALUE.type], rcx
    mov rcx, [r12 + VALUE.data]
    mov [rax + VALUE.data], rcx
    inc qword [rbx + SLIST.len]
    pop r13
    pop r12
    pop rbx
    ret

; ============================================================
; Variables: fixed 512-entry hash table (FNV-1a), linear probe
; ============================================================
VAR_TABLE_N equ 512
section .bss
align 16
    g_vars      resb VARENT_size * VAR_TABLE_N
    g_var_count resq 1

section .text

; fnv1a(rcx=ptr, rdx=len) -> rax=hash
fnv1a:
    mov rax, 0xCBF29CE484222325
    xor r8, r8
.loop:
    cmp r8, rdx
    je .done
    movzx r9, byte [rcx + r8]
    xor rax, r9
    imul rax, rax, 0x100000001B3
    inc r8
    jmp .loop
.done:
    ret

; var_set(rcx=SSTR* name, rdx=Value*)
var_set:
    push rbx
    push r12
    push r13
    mov rbx, rcx          ; name
    mov r12, rdx          ; value
    mov rcx, [rbx + SSTR.ptr]
    mov rdx, [rbx + SSTR.len]
    call fnv1a
    mov r13, rax
    and r13, VAR_TABLE_N - 1
    lea rsi, [rel g_vars]
    imul r13, r13, VARENT_size
    add rsi, r13
    mov rcx, VAR_TABLE_N
.probe:
    cmp qword [rsi + VARENT.hash], 0
    je .insert
    cmp qword [rsi + VARENT.hash], rax
    jne .next
    ; same hash - verify name
    mov rdx, [rsi + VARENT.name]
    mov rcx, rbx
    call sstr_eq_ci
    test rax, rax
    jnz .overwrite
.next:
    add rsi, VARENT_size
    dec rcx
    jnz .probe
    ; table full: overwrite first
    lea rsi, [rel g_vars]
.insert:
    mov [rsi + VARENT.hash], rax
    mov [rsi + VARENT.name], rbx
.overwrite:
    mov rax, [r12 + VALUE.type]
    mov [rsi + VARENT.value + VALUE.type], rax
    mov rax, [r12 + VALUE.data]
    mov [rsi + VARENT.value + VALUE.data], rax
    inc qword [g_var_count]
    pop r13
    pop r12
    pop rbx
    ret

; var_get(rcx=SSTR* name) -> rax=Value* or 0
var_get:
    push rbx
    push r12
    mov rbx, rcx
    mov rcx, [rbx + SSTR.ptr]
    mov rdx, [rbx + SSTR.len]
    call fnv1a
    mov r12, rax
    and r12, VAR_TABLE_N - 1
    lea rsi, [rel g_vars]
    imul r12, r12, VARENT_size
    add rsi, r12
    mov rcx, VAR_TABLE_N
.probe:
    cmp qword [rsi + VARENT.hash], 0
    je .not_found
    cmp qword [rsi + VARENT.hash], r12
    jne .next
    mov rdx, [rsi + VARENT.name]
    mov rcx, rbx
    call sstr_eq_ci
    test rax, rax
    jnz .found
.next:
    add rsi, VARENT_size
    dec rcx
    jnz .probe
.not_found:
    xor eax, eax
    jmp .done
.found:
    lea rax, [rsi + VARENT.value]
.done:
    pop r12
    pop rbx
    ret

; "it" implicit variable
section .bss
    g_it_value resb VALUE_size

section .text
it_set:
    mov rax, [rcx + VALUE.type]
    mov [rel g_it_value + VALUE.type], rax
    mov rax, [rcx + VALUE.data]
    mov [rel g_it_value + VALUE.data], rax
    ret
it_get:
    lea rax, [rel g_it_value]
    ret

; ============================================================
; Arithmetic & comparison on Values (all -> new Value* in rax)
; ============================================================

; val_add(rcx=a, rdx=b)
val_add:
    push rbx
    push r12
    push r13
    mov rbx, rcx
    mov r12, rdx
    mov rax, [rbx + VALUE.type]
    mov r13, [r12 + VALUE.type]
    cmp rax, V_INT
    jne .try_str
    cmp r13, V_INT
    jne .try_str
    mov rax, [rbx + VALUE.data]
    add rax, [r12 + VALUE.data]
    mov rcx, rax
    call val_int
    jmp .done
.try_str:
    cmp rax, V_STR
    jne .fail
    cmp r13, V_STR
    jne .fail
    mov rcx, [rbx + VALUE.data]
    mov rdx, [r12 + VALUE.data]
    call sstr_cat
    mov rcx, rax
    call val_str
    jmp .done
.fail:
    call val_nil
.done:
    pop r13
    pop r12
    pop rbx
    ret

; val_sub(rcx=a, rdx=b)
val_sub:
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    cmp qword [rbx + VALUE.type], V_INT
    jne .fail
    cmp qword [r12 + VALUE.type], V_INT
    jne .fail
    mov rax, [rbx + VALUE.data]
    sub rax, [r12 + VALUE.data]
    mov rcx, rax
    call val_int
    jmp .done
.fail:
    call val_nil
.done:
    pop r12
    pop rbx
    ret

; val_mul(rcx=a, rdx=b)
val_mul:
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    cmp qword [rbx + VALUE.type], V_INT
    jne .fail
    cmp qword [r12 + VALUE.type], V_INT
    jne .fail
    mov rax, [rbx + VALUE.data]
    imul rax, [r12 + VALUE.data]
    mov rcx, rax
    call val_int
    jmp .done
.fail:
    call val_nil
.done:
    pop r12
    pop rbx
    ret

; val_div(rcx=a, rdx=b)
val_div:
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    cmp qword [rbx + VALUE.type], V_INT
    jne .fail
    cmp qword [r12 + VALUE.type], V_INT
    jne .fail
    cmp qword [r12 + VALUE.data], 0
    je .fail
    mov rax, [rbx + VALUE.data]
    cqo
    idiv qword [r12 + VALUE.data]
    mov rcx, rax
    call val_int
    jmp .done
.fail:
    call val_nil
.done:
    pop r12
    pop rbx
    ret

; val_cmp(rcx=a, rdx=b) -> rax = -1 / 0 / 1
val_cmp:
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    mov rax, [rbx + VALUE.type]
    cmp rax, [r12 + VALUE.type]
    jne .type_cmp
    cmp rax, V_INT
    je .int_cmp
    cmp rax, V_BOOL
    je .int_cmp
    cmp rax, V_STR
    je .str_cmp
    cmp rax, V_LIST
    je .list_cmp
    xor eax, eax
    jmp .done
.type_cmp:
    ; nil < int < bool < str < list
    mov rcx, [rbx + VALUE.type]
    cmp rcx, [r12 + VALUE.type]
    jl .less
    jg .greater
    xor eax, eax
    jmp .done
.int_cmp:
    mov rax, [rbx + VALUE.data]
    cmp rax, [r12 + VALUE.data]
    jl .less
    jg .greater
    xor eax, eax
    jmp .done
.str_cmp:
    mov rcx, [rbx + VALUE.data]
    mov rdx, [r12 + VALUE.data]
    ; compare by length then bytes
    mov r8, [rcx + SSTR.len]
    mov r9, [rdx + SSTR.len]
    cmp r8, r9
    jl .less
    jg .greater
    mov rsi, [rcx + SSTR.ptr]
    mov rdi, [rdx + SSTR.ptr]
    xor rcx, rcx
.loop:
    cmp rcx, r8
    je .eq
    mov al, [rsi + rcx]
    mov bl, [rdi + rcx]
    or al, 32
    or bl, 32
    cmp al, bl
    jl .less
    jg .greater
    inc rcx
    jmp .loop
.list_cmp:
    mov rax, [rbx + VALUE.data]
    mov rdx, [r12 + VALUE.data]
    mov rax, [rax + SLIST.len]
    cmp rax, [rdx + SLIST.len]
    jl .less
    jg .greater
    xor eax, eax
    jmp .done
.eq:
    xor eax, eax
    jmp .done
.less:
    mov eax, -1
    jmp .done
.greater:
    mov eax, 1
.done:
    pop r12
    pop rbx
    ret

; val_truthy(rcx=Value*) -> rax=0/1
val_truthy:
    mov rax, [rcx + VALUE.type]
    cmp rax, V_NIL
    je .zero
    cmp rax, V_INT
    je .int
    cmp rax, V_BOOL
    je .int
    cmp rax, V_STR
    je .str
    cmp rax, V_LIST
    je .list
    xor eax, eax
    ret
.int:
    cmp qword [rcx + VALUE.data], 0
    jne .one
.zero:
    xor eax, eax
    ret
.one:
    mov eax, 1
    ret
.str:
    mov rax, [rcx + VALUE.data]
    cmp qword [rax + SSTR.len], 0
    jne .one
    xor eax, eax
    ret
.list:
    mov rax, [rcx + VALUE.data]
    cmp qword [rax + SLIST.len], 0
    jne .one
    xor eax, eax
    ret

; val_print(rcx=Value*) with type dispatch, no newline
val_print:
    push rbx
    push r12
    push r13
    mov rbx, rcx
    mov rax, [rbx + VALUE.type]
    cmp rax, V_NIL
    je .nil
    cmp rax, V_INT
    je .int
    cmp rax, V_BOOL
    je .bool
    cmp rax, V_STR
    je .str
    cmp rax, V_LIST
    je .list
    jmp .done
.nil:
    lea rcx, [rel sz_nil]
    call print_z
    jmp .done
.int:
    mov rcx, [rbx + VALUE.data]
    call print_int64
    jmp .done
.bool:
    cmp qword [rbx + VALUE.data], 0
    je .b_false
    lea rcx, [rel sz_true]
    call print_z
    jmp .done
.b_false:
    lea rcx, [rel sz_false]
    call print_z
    jmp .done
.str:
    mov rcx, [rbx + VALUE.data]
    call sstr_print
    jmp .done
.list:
    mov r12, [rbx + VALUE.data]
    lea rcx, [rel sz_lbr]
    call print_z
    xor r13, r13
.item_loop:
    cmp r13, [r12 + SLIST.len]
    jae .list_end
    test r13, r13
    jz .no_comma
    lea rcx, [rel sz_comma]
    call print_z
.no_comma:
    mov rax, [r12 + SLIST.items]
    mov rcx, r13
    shl rcx, 4
    add rax, rcx
    mov rcx, rax
    call val_print
    inc r13
    jmp .item_loop
.list_end:
    lea rcx, [rel sz_rbr]
    call print_z
.done:
    pop r13
    pop r12
    pop rbx
    ret

section .data
sz_nil      db "nil", 0
sz_true     db "true", 0
sz_false    db "false", 0
sz_lbr      db "[", 0
sz_rbr      db "]", 0
sz_comma    db ", ", 0