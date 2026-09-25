; ============================================================
; ENGLISH-ELF: Lexer
; Reads English source directly from the in-memory .txt buffer.
; No token array is built - the parser consumes the lexer
; state on demand, so the source text IS the program.
; ============================================================

%include "win32.inc"

section .bss
alignb 16
    lex_state resb LEXER_size

section .text

; lex_init(rcx=src, rdx=len)
lex_init:
    mov [rel lex_state + LEXER.src], rcx
    lea rax, [rcx + rdx]
    mov [rel lex_state + LEXER.end], rax
    mov [rel lex_state + LEXER.cur], rcx
    mov qword [rel lex_state + LEXER.line], 1
    mov qword [rel lex_state + LEXER.col], 1
    mov qword [rel lex_state + LEXER.tok_type], TOK_EOF
    ret

; lex_cur() -> rax = current pointer
lex_cur:
    mov rax, [rel lex_state + LEXER.cur]
    ret

; lex_next() : advance to next token
lex_next:
    sub rsp, 48h
.skip_ws:
    mov rcx, [rel lex_state + LEXER.cur]
    cmp rcx, [rel lex_state + LEXER.end]
    jae .eof
    mov al, [rcx]
    cmp al, ' '
    je .ws
    cmp al, 9
    je .ws
    cmp al, 13
    je .ws
    cmp al, 10
    je .nl
    cmp al, '#'
    je .comment
    jmp .classify
.ws:
    inc qword [rel lex_state + LEXER.cur]
    inc qword [rel lex_state + LEXER.col]
    jmp .skip_ws
.nl:
    mov qword [rel lex_state + LEXER.tok_type], TOK_NL
    inc qword [rel lex_state + LEXER.cur]
    mov qword [rel lex_state + LEXER.col], 1
    inc qword [rel lex_state + LEXER.line]
    add rsp, 48h
    ret
.comment:
    inc qword [rel lex_state + LEXER.cur]
    mov rcx, [rel lex_state + LEXER.cur]
    cmp rcx, [rel lex_state + LEXER.end]
    jae .eof
    cmp byte [rcx], 10
    je .skip_ws
    inc qword [rel lex_state + LEXER.col]
    jmp .comment
.classify:
    ; al = first char
    cmp al, '.'
    je .punct
    cmp al, '!'
    je .punct
    cmp al, '?'
    je .punct
    cmp al, ':'
    je .punct
    cmp al, ','
    je .punct
    cmp al, ';'
    je .punct
    cmp al, '('
    je .punct
    cmp al, ')'
    je .punct
    cmp al, '['
    je .punct
    cmp al, ']'
    je .punct
    cmp al, '"'
    je .string
    cmp al, '0'
    jb .word
    cmp al, '9'
    jbe .number
    jmp .word
.punct:
    mov qword [rel lex_state + LEXER.tok_type], TOK_PUNCT
    mov rcx, [rel lex_state + LEXER.cur]
    mov [rel lex_state + LEXER.tok_start], rcx
    mov qword [rel lex_state + LEXER.tok_len], 1
    movsx rax, al
    mov [rel lex_state + LEXER.tok_num], rax
    movzx eax, al
    mov qword [rel lex_state + LEXER.tok_kw], 0
    inc qword [rel lex_state + LEXER.cur]
    inc qword [rel lex_state + LEXER.col]
    add rsp, 48h
    ret
.string:
    ; parse until closing quote
    inc qword [rel lex_state + LEXER.cur]
    inc qword [rel lex_state + LEXER.col]
    mov rcx, [rel lex_state + LEXER.cur]
    mov [rel lex_state + LEXER.tok_start], rcx
    xor rdx, rdx
.s_loop:
    cmp rcx, [rel lex_state + LEXER.end]
    jae .s_done
    mov al, [rcx]
    cmp al, '"'
    je .s_done
    cmp al, 10
    je .s_done
    inc rcx
    inc rdx
    jmp .s_loop
.s_done:
    mov [rel lex_state + LEXER.tok_len], rdx
    mov [rel lex_state + LEXER.tok_num], 0
    mov [rel lex_state + LEXER.tok_kw], 0
    mov qword [rel lex_state + LEXER.tok_type], TOK_STRING
    mov [rel lex_state + LEXER.cur], rcx
    add qword [rel lex_state + LEXER.col], rdx
    ; skip closing quote if present
    cmp rcx, [rel lex_state + LEXER.end]
    jae .s_ret
    cmp byte [rcx], '"'
    jne .s_ret
    inc qword [rel lex_state + LEXER.cur]
    inc qword [rel lex_state + LEXER.col]
.s_ret:
    add rsp, 48h
    ret
.number:
    mov rcx, [rel lex_state + LEXER.cur]
    mov [rel lex_state + LEXER.tok_start], rcx
    xor rdx, rdx
    xor r8, r8
.n_loop:
    cmp rcx, [rel lex_state + LEXER.end]
    jae .n_done
    mov al, [rcx]
    cmp al, '0'
    jb .n_done
    cmp al, '9'
    ja .n_done
    imul r8, r8, 10
    movzx rax, al
    sub rax, '0'
    add r8, rax
    inc rcx
    inc rdx
    jmp .n_loop
.n_done:
    mov [rel lex_state + LEXER.tok_len], rdx
    mov [rel lex_state + LEXER.tok_num], r8
    mov [rel lex_state + LEXER.tok_kw], 0
    mov qword [rel lex_state + LEXER.tok_type], TOK_NUMBER
    mov [rel lex_state + LEXER.cur], rcx
    add qword [rel lex_state + LEXER.col], rdx
    add rsp, 48h
    ret
.word:
    ; read [A-Za-z0-9_'-] ; lowercase into g_tmp_buf
    mov rcx, [rel lex_state + LEXER.cur]
    mov [rel lex_state + LEXER.tok_start], rcx
    lea rdi, [rel g_tmp_buf]
    xor rdx, rdx
.w_loop:
    cmp rcx, [rel lex_state + LEXER.end]
    jae .w_done
    mov al, [rcx]
    cmp al, 'A'
    jb .w_check2
    cmp al, 'Z'
    jbe .w_keep
    cmp al, 'a'
    jb .w_check2
    cmp al, 'z'
    jbe .w_keep
    jmp .w_check2
.w_check2:
    cmp al, '0'
    jb .w_check3
    cmp al, '9'
    jbe .w_keep
    jmp .w_check3
.w_check3:
    cmp al, '_'
    je .w_keep
    cmp al, '-'
    je .w_keep
    cmp al, 39      ; '
    je .w_keep
    jmp .w_done
.w_keep:
    cmp al, 'A'
    jb .w_store
    cmp al, 'Z'
    ja .w_store
    add al, 32
.w_store:
    mov [rdi + rdx], al
    inc rcx
    inc rdx
    cmp rdx, 63
    jb .w_loop
.w_done:
    mov byte [rdi + rdx], 0
    mov [rel lex_state + LEXER.tok_len], rdx
    mov [rel lex_state + LEXER.tok_num], 0
    mov [rel lex_state + LEXER.cur], rcx
    add qword [rel lex_state + LEXER.col], rdx
    mov qword [rel lex_state + LEXER.tok_type], TOK_WORD
    ; keyword lookup on lowercased word
    lea rcx, [rel g_tmp_buf]
    call word_to_kw
    mov [rel lex_state + LEXER.tok_kw], rax
    add rsp, 48h
    ret
.eof:
    mov qword [rel lex_state + LEXER.tok_type], TOK_EOF
    mov rcx, [rel lex_state + LEXER.cur]
    mov [rel lex_state + LEXER.tok_start], rcx
    mov qword [rel lex_state + LEXER.tok_len], 0
    add rsp, 48h
    ret

; ============================================================
; Lexer state save/restore (for loops / function bodies)
; ============================================================
; lex_save(rdi=dest LEXER*) : copy current state
lex_save:
    lea rsi, [rel lex_state]
    mov rcx, LEXER_size
    rep movsb
    ret

; lex_restore(rcx=src LEXER*)
lex_restore:
    lea rdi, [rel lex_state]
    mov rsi, rcx
    mov rcx, LEXER_size
    rep movsb
    ret

; ============================================================
; Token accessors
; ============================================================
tok_is_word:    ; -> rax = kwid if current is WORD, else 0
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .no
    mov rax, [rel lex_state + LEXER.tok_kw]
    ret
.no:
    xor eax, eax
    ret

tok_is_punct_char:   ; rcx = char -> rax = 1 if current punct equals char
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    jne .no
    mov rax, [rel lex_state + LEXER.tok_num]
    cmp rax, rcx
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

tok_is_number:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_NUMBER
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

tok_is_string:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_STRING
    jne .no
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

; tok_word_str() -> rax = SSTR* of current word (lowercased)
tok_word_str:
    sub rsp, 48h
    mov rcx, [rel lex_state + LEXER.tok_start]
    mov rdx, [rel lex_state + LEXER.tok_len]
    call sstr_create
    ; lowercase copy
    mov rcx, rax
    mov rdx, [rcx + SSTR.ptr]
    mov r8, [rcx + SSTR.len]
    xor r9, r9
.loop:
    cmp r9, r8
    je .done
    mov al, [rdx + r9]
    cmp al, 'A'
    jb .next
    cmp al, 'Z'
    ja .next
    add al, 32
    mov [rdx + r9], al
.next:
    inc r9
    jmp .loop
.done:
    mov rax, rcx
    add rsp, 48h
    ret

; tok_str_str() -> rax = SSTR* of current string literal
tok_str_str:
    sub rsp, 48h
    mov rcx, [rel lex_state + LEXER.tok_start]
    mov rdx, [rel lex_state + LEXER.tok_len]
    call sstr_create
    add rsp, 48h
    ret