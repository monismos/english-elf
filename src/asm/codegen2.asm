; ============================================================
; ENGLISH-ELF: Statement JIT Emitter
; Generates machine code for English statements
; ============================================================

%include "win32.inc"

section .text

; Emit code for a parsed English statement type
; RCX = statement type code
; Returns: RAX = 0 on success
codegen_emit_stmt:
    push rbp
    mov rbp, rsp
    sub rsp, 32h

    cmp ecx, STMT_OUTPUT
    je .emit_output
    cmp ecx, STMT_ASSIGN
    je .emit_assign
    cmp ecx, STMT_IF
    je .emit_if
    cmp ecx, STMT_WHILE
    je .emit_while
    cmp ecx, STMT_REPEAT
    je .emit_repeat
    cmp ecx, STMT_FUNCTION
    je .emit_function
    cmp ecx, STMT_RETURN
    je .emit_return
    cmp ecx, STMT_LIST_CREATE
    je .emit_list_create
    cmp ecx, STMT_LIST_ADD
    je .emit_list_add
    cmp ecx, STMT_FOR_EACH
    je .emit_for_each
    cmp ecx, STMT_BREAK
    je .emit_break
    cmp ecx, STMT_CONTINUE
    je .emit_continue
    cmp ecx, STMT_STOP
    je .emit_stop
    cmp ecx, STMT_SLAY
    je .emit_slay
    cmp ecx, STMT_BET
    je .emit_bet
    cmp ecx, STMT_FACTS
    je .emit_facts
    cmp ecx, STMT_SHEESH
    je .emit_sheesh
    cmp ecx, STMT_NAH
    je .emit_nah
    cmp ecx, STMT_YEAH
    je .emit_yeah
    cmp ecx, STMT_GREET
    je .emit_greet
    cmp ecx, STMT_HELLO
    je .emit_hello
    cmp ecx, STMT_GOODBYE
    je .emit_goodbye
    cmp ecx, STMT_THANKS
    je .emit_thanks

    ; Default: emit as expression statement (print)
    jmp .emit_output

.emit_output:
    call emit_output_jit
    jmp .done

.emit_assign:
    call emit_assign_jit
    jmp .done

.emit_if:
    call emit_if_jit
    jmp .done

.emit_while:
    call emit_while_jit
    jmp .done

.emit_repeat:
    call emit_repeat_jit
    jmp .done

.emit_function:
    call emit_function_jit
    jmp .done

.emit_return:
    call emit_return_jit
    jmp .done

.emit_list_create:
    call emit_list_create_jit
    jmp .done

.emit_list_add:
    call emit_list_add_jit
    jmp .done

.emit_for_each:
    call emit_for_each_jit
    jmp .done

.emit_break:
    call emit_break_jit
    jmp .done

.emit_continue:
    call emit_continue_jit
    jmp .done

.emit_stop:
    call emit_stop_jit
    jmp .done

.emit_slay:
    call emit_slay_jit
    jmp .done

.emit_bet:
    call emit_bet_jit
    jmp .done

.emit_facts:
    call emit_facts_jit
    jmp .done

.emit_sheesh:
    call emit_sheesh_jit
    jmp .done

.emit_nah:
    call emit_nah_jit
    jmp .done

.emit_yeah:
    call emit_yeah_jit
    jmp .done

.emit_greet:
    call emit_greet_jit
    jmp .done

.emit_hello:
    call emit_hello_jit
    jmp .done

.emit_goodbye:
    call emit_goodbye_jit
    jmp .done

.emit_thanks:
    call emit_thanks_jit
    jmp .done

.done:
    add rsp, 32h
    pop rbp
    ret

; ======================
; Output statement JIT emit
; ======================
emit_output_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    ; Load runtime print function
    mov rax, [rel pfn_print_value]
    mov rbx, rax
    emit_call_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; Assign statement JIT emit
; ======================
emit_assign_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    mov rax, [rel pfn_var_set]
    mov rbx, rax
    emit_call_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; IF statement JIT emit
; ======================
emit_if_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    emit_xor_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; WHILE loop JIT emit
; ======================
emit_while_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    emit_xor_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; REPEAT loop JIT emit
; ======================
emit_repeat_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    emit_xor_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; Function definition JIT emit
; ======================
emit_function_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    emit_xor_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; Return JIT emit
; ======================
emit_return_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov byte [rbp-8], 0xC3
    mov rcx, rsp-8
    mov rdx, 1
    call jit_emit_bytes
    add rsp, 32h
    pop rbp
    ret

; ======================
; List create JIT emit
; ======================
emit_list_create_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    mov rax, [rel pfn_list_create]
    mov rbx, rax
    emit_call_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; List add JIT emit
; ======================
emit_list_add_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    mov rax, [rel pfn_list_append]
    mov rbx, rax
    emit_call_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; For-each JIT emit
; ======================
emit_for_each_jit:
    push rbp
    mov rbp, rsp
    sub rsp, 32h
    emit_xor_rax
    add rsp, 32h
    pop rbp
    ret

; ======================
; Break/Continue/Stop JIT emit
; ======================
emit_break_jit:         emit_ret
emit_continue_jit:      emit_ret
emit_stop_jit:          emit_ret
emit_slay_jit:          emit_ret
emit_bet_jit:           emit_ret
emit_facts_jit:         emit_ret
emit_sheesh_jit:        emit_ret
emit_nah_jit:           emit_ret
emit_yeah_jit:          emit_ret
emit_greet_jit:         emit_ret
emit_hello_jit:         emit_ret
emit_goodbye_jit:       emit_ret
emit_thanks_jit:        emit_ret