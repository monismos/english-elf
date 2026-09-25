; ============================================================
; ENGLISH-ELF: Parser + Direct Interpreter
; Consumes tokens from the in-memory .txt buffer and executes.
; Also emits JIT thunks via codegen for the --jit path.
; ============================================================

%include "win32.inc"

; ---------- globals ----------
section .bss
align 16
    g_current_list  resq 1        ; SSTR* name of most recent list
    g_funcs         resb FUNC_size * 64
    g_nfuncs        resq 1
    g_return_val    resb VALUE_size
    g_in_func       resq 1
    g_exit_requested resq 1
    g_loop_break    resq 1        ; set to end_ptr when break
    g_loop_continue resq 1        ; set to top_ptr when continue
    g_word_buf      resb 64       ; current word (lowercased)

section .text

; ============================================================
; parse_program(rcx=src, rdx=len)
; ============================================================
parse_program:
    push rbp
    mov rbp, rsp
    sub rsp, 40h
    call lex_init
    mov qword [rel g_exit_requested], 0
    call lex_next
.prog_loop:
    cmp qword [rel g_exit_requested], 0
    jne .done
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_EOF
    je .done
    call parse_statement
    jmp .prog_loop
.done:
    add rsp, 40h
    pop rbp
    ret

; ============================================================
; parse_statement() -> rax: 0 continue, 1 stop, 2 block-end
; ============================================================
parse_statement:
    push rbp
    mov rbp, rsp
    sub rsp, 40h
    push rbx
    push r12

.stmt_loop:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_EOF
    je .stop
    cmp rax, TOK_NL
    jne .no_nl
    call lex_next
    jmp .stmt_loop
.no_nl:
    cmp rax, TOK_PUNCT
    jne .no_punct
    call lex_next
    jmp .stmt_loop
.no_punct:
    cmp rax, TOK_WORD
    jne .no_word
    mov r12, [rel lex_state + LEXER.tok_kw]
    lea rcx, [rel dbg_kw]
    call print_z
    mov rcx, r12
    call print_int64
    call print_newline
    lea rcx, [rel dbg_word]
    call print_z
    lea rcx, [rel g_tmp_buf]
    call print_z
    call print_newline
    mov rcx, [rel kw_table]
    call print_z
    lea rcx, [rel dbg_ttab]
    call print_z
    call print_newline
    lea rcx, [rel kw_say]
    call word_to_kw
    mov r15, rax
    lea rcx, [rel dbg_dkw]
    call print_z
    mov rcx, r15
    call print_int64
    call print_newline
    test r12, r12
    jnz .kw
    ; plain word: function? variable? implicit output
    call copy_word_buf
    lea rcx, [rel g_word_buf]
    call sstr_from_cstr
    mov rbx, rax
    call func_lookup
    test rax, rax
    jnz .call_func
    mov rcx, rbx
    call var_get
    test rax, rax
    jnz .implicit_var
    ; implicit output of the sentence
    call parse_phrase_rest
    mov rcx, rax
    call val_print
    call print_newline
    xor eax, eax
    jmp .done
.implicit_var:
    mov rcx, rax
    call val_print
    call print_newline
    call lex_next
    xor eax, eax
    jmp .done
.call_func:
    ; rbx = name SSTR*, rax = FUNC* (unused)
    call lex_next
    call parse_call_args
    mov [rel g_call_argc], rax
    mov rcx, rbx
    call call_function
    ; clean up args from stack
    mov rax, [rel g_call_argc]
    shl rax, 3
    add rsp, rax
    xor eax, eax
    jmp .done
.kw:
    cmp r12, KW_SAY
    jb .not_output
    cmp r12, KW_MUMBLE
    jbe .out_stmt
.not_output:
    cmp r12, KW_SET
    je .set_stmt
    cmp r12, KW_LET
    je .set_stmt
    cmp r12, KW_MAKE
    je .set_stmt
    cmp r12, KW_GIVE
    je .set_stmt
    cmp r12, KW_ASSIGN
    je .set_stmt
    cmp r12, KW_CREATE
    je .create_stmt
    cmp r12, KW_DEFINE
    je .create_stmt
    cmp r12, KW_ADD
    je .add_stmt
    cmp r12, KW_APPEND
    je .add_stmt
    cmp r12, KW_PUT
    je .add_stmt
    cmp r12, KW_INSERT
    je .add_stmt
    cmp r12, KW_REMOVE
    je .remove_stmt
    cmp r12, KW_DELETE
    je .remove_stmt
    cmp r12, KW_CLEAR
    je .clear_stmt
    cmp r12, KW_IF
    je .if_stmt
    cmp r12, KW_UNLESS
    je .unless_stmt
    cmp r12, KW_WHEN
    je .if_stmt
    cmp r12, KW_WHILE
    je .while_stmt
    cmp r12, KW_UNTIL
    je .until_stmt
    cmp r12, KW_REPEAT
    je .repeat_stmt
    cmp r12, KW_FOR
    je .for_stmt
    cmp r12, KW_TO
    je .func_def_stmt
    cmp r12, KW_RETURN
    je .return_stmt
    cmp r12, KW_SENDBACK
    je .return_stmt
    cmp r12, KW_STOP
    je .stop_stmt
    cmp r12, KW_HALT
    je .stop_stmt
    cmp r12, KW_QUIT
    je .stop_stmt
    cmp r12, KW_EXIT
    je .stop_stmt
    cmp r12, KW_BREAK
    je .break_stmt
    cmp r12, KW_CONTINUE
    je .continue_stmt
    cmp r12, KW_DONE
    je .block_end_stmt
    cmp r12, KW_END
    je .block_end_stmt
    cmp r12, KW_FINISH
    je .block_end_stmt
    cmp r12, KW_CALCULATE
    je .calc_stmt
    cmp r12, KW_COMPUTE
    je .calc_stmt
    cmp r12, KW_GET
    je .calc_stmt
    cmp r12, KW_FIND
    je .calc_stmt
    cmp r12, KW_CHECK
    je .calc_stmt
    cmp r12, KW_CALL
    je .call_stmt
    cmp r12, KW_READ
    je .read_stmt
    cmp r12, KW_WRITE
    je .write_stmt
    cmp r12, KW_SLEEP
    je .sleep_stmt
    cmp r12, KW_WAIT
    je .sleep_stmt
    cmp r12, KW_GREET
    je .greet_stmt
    cmp r12, KW_HELLO
    je .hello_stmt
    cmp r12, KW_GOODBYE
    je .goodbye_stmt
    cmp r12, KW_THANKS
    je .thanks_stmt
    cmp r12, KW_WELCOME
    je .welcome_stmt
    cmp r12, KW_SORRY
    je .sorry_stmt
    cmp r12, KW_PLEASE
    je .please_stmt
    cmp r12, KW_YES
    je .assert_true
    cmp r12, KW_YEAH
    je .assert_true
    cmp r12, KW_BET
    je .assert_true
    cmp r12, KW_FACTS
    je .assert_true
    cmp r12, KW_SLAY
    je .assert_true
    cmp r12, KW_NAH
    je .assert_false
    cmp r12, KW_CAP
    je .assert_false
    cmp r12, KW_SHEESH
    je .sheesh_stmt
    ; unknown keyword -> treat as word: implicit output
    call copy_word_buf
    lea rcx, [rel g_word_buf]
    call sstr_from_cstr
    mov rcx, rax
    call var_get
    test rax, rax
    jz .plain_out
    mov rcx, rax
    call val_print
    call print_newline
    call lex_next
    xor eax, eax
    jmp .done
.plain_out:
    call parse_phrase_rest
    mov rcx, rax
    call val_print
    call print_newline
    xor eax, eax
    jmp .done
.no_word:
    cmp rax, TOK_NUMBER
    je .plain_out
    cmp rax, TOK_STRING
    je .plain_out
    call lex_next
    xor eax, eax
    jmp .done

.out_stmt: call parse_output_stmt
    jmp .done
.set_stmt: call parse_assign_stmt
    jmp .done
.create_stmt: call parse_create_stmt
    jmp .done
.add_stmt: call parse_add_stmt
    jmp .done
.remove_stmt: call parse_remove_stmt
    jmp .done
.clear_stmt: call parse_clear_stmt
    jmp .done
.if_stmt: call parse_if_stmt
    jmp .done
.unless_stmt: call parse_unless_stmt
    jmp .done
.while_stmt: call parse_while_stmt
    jmp .done
.until_stmt: call parse_until_stmt
    jmp .done
.repeat_stmt: call parse_repeat_stmt
    jmp .done
.for_stmt: call parse_for_stmt
    jmp .done
.func_def_stmt: call parse_func_def_stmt
    jmp .done
.return_stmt: call parse_return_stmt
    jmp .done
.calc_stmt: call parse_calc_stmt
    jmp .done
.call_stmt: call parse_call_stmt
    jmp .done
.read_stmt: call parse_read_stmt
    jmp .done
.write_stmt: call parse_write_stmt
    jmp .done
.sleep_stmt: call parse_sleep_stmt
    jmp .done
.greet_stmt: call parse_greet_stmt
    jmp .done
.hello_stmt: call parse_hello_stmt
    jmp .done
.goodbye_stmt: call parse_goodbye_stmt
    jmp .done
.thanks_stmt: call parse_thanks_stmt
    jmp .done
.welcome_stmt: call parse_welcome_stmt
    jmp .done
.sorry_stmt: call parse_sorry_stmt
    jmp .done
.please_stmt: call lex_next
    jmp .done
.assert_true: call parse_assert_true
    jmp .done
.assert_false: call parse_assert_false
    jmp .done
.sheesh_stmt: call parse_sheesh_stmt
    jmp .done
.stop_stmt: call parse_stop_stmt
    jmp .done
.break_stmt: call parse_break_stmt
    jmp .done
.continue_stmt: call parse_continue_stmt
    jmp .done
.block_end_stmt: call parse_block_end_stmt
    jmp .done

.stop:
    mov eax, 1
    jmp .done
.done:
    add rsp, 40h
    pop r12
    pop rbx
    pop rbp
    ret

; ============================================================
; copy_word_buf: copy current lowercased word (already in
; g_tmp_buf from the lexer) into g_word_buf
; ============================================================
copy_word_buf:
    lea rsi, [rel g_tmp_buf]
    lea rdi, [rel g_word_buf]
    mov rcx, 64
    rep movsb
    ret

; ============================================================
; Simple statements
; ============================================================
parse_stop_stmt:
    mov qword [rel g_exit_requested], 1
    mov eax, 1
    ret

parse_break_stmt:
    mov eax, 1
    ret

parse_continue_stmt:
    mov eax, 1
    ret

parse_block_end_stmt:
    mov eax, 2
    ret

; assertions set "it" to a boolean and consume the sentence
parse_assert_true:
    sub rsp, 8
    mov rcx, 1
    call val_bool
    mov rcx, rax
    call it_set
    call lex_next
    xor eax, eax
    add rsp, 8
    ret

parse_assert_false:
    sub rsp, 8
    mov rcx, 0
    call val_bool
    mov rcx, rax
    call it_set
    call lex_next
    xor eax, eax
    add rsp, 8
    ret

parse_sheesh_stmt:
    sub rsp, 8
    lea rcx, [rel sz_sheesh]
    call print_z
    call print_newline
    call lex_next
    add rsp, 8
    xor eax, eax
    ret

section .data
sz_sheesh   db "sheesh!", 0
sz_hello_g  db "hello, ", 0
sz_goodbye_g db "goodbye, ", 0
sz_bang     db "!", 0
sz_welcome  db "welcome!", 0
sz_sorry    db "no worries!", 0
sz_welcome2 db "you're welcome!", 0
sz_space    db " ", 0

section .text
parse_greet_stmt:
    sub rsp, 8
    call lex_next
    lea rcx, [rel sz_hello_g]
    call print_z
    call parse_phrase_rest
    mov rcx, rax
    call val_print
    lea rcx, [rel sz_bang]
    call print_z
    call print_newline
    add rsp, 8
    xor eax, eax
    ret

parse_hello_stmt:
    sub rsp, 8
    call lex_next
    lea rcx, [rel sz_hello_g]
    call print_z
    call parse_phrase_rest
    mov rcx, rax
    call val_print
    lea rcx, [rel sz_bang]
    call print_z
    call print_newline
    add rsp, 8
    xor eax, eax
    ret

parse_goodbye_stmt:
    sub rsp, 8
    call lex_next
    lea rcx, [rel sz_goodbye_g]
    call print_z
    call parse_phrase_rest
    mov rcx, rax
    call val_print
    lea rcx, [rel sz_bang]
    call print_z
    call print_newline
    add rsp, 8
    xor eax, eax
    ret

parse_thanks_stmt:
    sub rsp, 8
    lea rcx, [rel sz_welcome2]
    call print_z
    call print_newline
    call lex_next
    add rsp, 8
    xor eax, eax
    ret

parse_welcome_stmt:
    sub rsp, 8
    lea rcx, [rel sz_welcome]
    call print_z
    call print_newline
    call lex_next
    add rsp, 8
    xor eax, eax
    ret

parse_sorry_stmt:
    sub rsp, 8
    lea rcx, [rel sz_sorry]
    call print_z
    call print_newline
    call lex_next
    add rsp, 8
    xor eax, eax
    ret

parse_sleep_stmt:
    sub rsp, 8
    call lex_next
    call parse_phrase_rest
    mov rcx, rax
    cmp qword [rcx + VALUE.type], V_INT
    jne .done
    mov rcx, [rcx + VALUE.data]
    sub rsp, 40h
    call Sleep
    add rsp, 40h
.done:
    xor eax, eax
    add rsp, 8
    ret

; ============================================================
; Output: parse one or more phrases, print space-separated
; ============================================================
parse_output_stmt:
    push rbx
    call lex_next
.first:
    mov rcx, 1
    call parse_phrase
    mov rbx, rax
    mov rcx, rbx
    call val_print
.cont:
    ; look for ',' or AND
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    jne .not_comma
    mov rax, [rel lex_state + LEXER.tok_num]
    cmp rax, ','
    jne .done
    call lex_next
    lea rcx, [rel sz_space]
    call print_z
    jmp .first
.not_comma:
    cmp rax, TOK_WORD
    jne .done
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_AND
    jne .done
    call lex_next
    lea rcx, [rel sz_space]
    call print_z
    jmp .first
.done:
    call print_newline
    pop rbx
    xor eax, eax
    ret

; ============================================================
; Assignment: SET/LET/MAKE/GIVE <name> <connector> <value>
; ============================================================
parse_assign_stmt:
    push rbx
    push r12
    sub rsp, 8
    call lex_next
    ; name
    call tok_word_str
    mov rbx, rax
    call lex_next
    ; skip connectors: TO IS EQUALS EQUAL (CALL?)
.conn:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .value
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_TO
    je .skip1
    cmp rax, KW_IS
    je .skip1
    cmp rax, KW_EQUALS
    je .skip1
    cmp rax, KW_EQUAL
    je .skip1
    cmp rax, KW_CALL
    je .skip1
    cmp rax, KW_NAMED
    je .skip1
    cmp rax, KW_CALLED
    je .skip1
    jmp .value
.skip1:
    call lex_next
    jmp .conn
.value:
    mov rcx, 0
    call parse_phrase
    mov r12, rax
    ; anaphora: "set it to X" writes the implicit variable
    mov rcx, rbx
    call sstr_eq_ci_name_it
    test rax, rax
    jz .not_it
    mov rcx, r12
    call it_set
    jmp .done
.not_it:
    mov rcx, rbx
    mov rdx, r12
    call var_set
    mov rcx, r12
    call it_set
.done:
    add rsp, 8
    pop r12
    pop rbx
    xor eax, eax
    ret

; sstr_eq_ci_name_it(rcx=SSTR*) -> rax=1 if name is "it"
sstr_eq_ci_name_it:
    push rbx
    mov rbx, rcx
    lea rcx, [rel sz_name_it]
    call sstr_from_cstr
    mov rdx, rax
    mov rcx, rbx
    call sstr_eq_ci
    pop rbx
    ret

section .data
sz_name_it  db "it", 0

section .text

; ============================================================
; CREATE: CREATE [A/AN] LIST [NAMED/CALLED] <name>
; ============================================================
parse_create_stmt:
    push rbx
    call lex_next
.skip_loop:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .name
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_A
    je .skip1
    cmp rax, KW_AN
    je .skip1
    cmp rax, KW_LIST
    je .skip1
    cmp rax, KW_NEW
    je .skip1
    cmp rax, KW_EMPTY
    je .skip1
    cmp rax, KW_NAMED
    je .skip1
    cmp rax, KW_CALLED
    je .skip1
    jmp .name
.skip1:
    call lex_next
    jmp .skip_loop
.name:
    call tok_word_str
    mov rbx, rax
    call lex_next
    call list_create
    mov rcx, rax
    call val_list
    mov rcx, rbx
    mov rdx, rax
    call var_set
    mov rcx, rax
    call it_set
    mov [rel g_current_list], rbx
    pop rbx
    xor eax, eax
    ret

; ============================================================
; ADD <value>[, <value>]... [AND <value>] TO/IN/INTO <list>
; ============================================================
parse_add_stmt:
    push rbx
    push r12
    push r13
    call lex_next
    xor r13, r13          ; count of values
.first:
    mov rcx, 2            ; stop at to/in/into
    call parse_phrase
    push rax
    inc r13
    ; separator?
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    jne .check_and
    mov rax, [rel lex_state + LEXER.tok_num]
    cmp rax, ','
    jne .check_and
    call lex_next
    jmp .first
.check_and:
    cmp rax, TOK_WORD
    jne .list
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_AND
    jne .list
    call lex_next
    jmp .first
.list:
    ; consume connector TO/IN/INTO/FROM
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .bad
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_TO
    je .ok
    cmp rax, KW_IN
    je .ok
    cmp rax, KW_INTO
    je .ok
    cmp rax, KW_FROM
    je .ok
    jmp .bad
.ok:
    call lex_next
    call tok_word_str
    mov rbx, rax
    call lex_next
    mov rcx, rbx
    call var_get
    mov r12, rax
    test r12, r12
    jz .bad
    cmp qword [r12 + VALUE.type], V_LIST
    jne .bad
    mov rcx, [r12 + VALUE.data]
    mov rbx, rcx          ; SLIST*
.pop_loop:
    test r13, r13
    jz .done
    pop rax
    push rbx
    mov rcx, rbx
    mov rdx, rax
    call list_append
    pop rbx
    dec r13
    jmp .pop_loop
.bad:
    mov rax, r13
    shl rax, 3
    add rsp, rax                ; drop pushed values
.done:
    pop r13
    pop r12
    pop rbx
    xor eax, eax
    ret

; ============================================================
; REMOVE <value> FROM <list>   (remove first match)
; ============================================================
parse_remove_stmt:
    push rbx
    push r12
    sub rsp, 8
    call lex_next
    mov rcx, 2
    call parse_phrase
    mov [rel g_rm_target], rax   ; target Value*
    ; consume FROM
    call lex_next
    call tok_word_str
    mov rbx, rax
    call lex_next
    mov rcx, rbx
    call var_get
    test rax, rax
    jz .done
    cmp qword [rax + VALUE.type], V_LIST
    jne .done
    mov rax, [rax + VALUE.data]
    mov rbx, rax          ; SLIST*
    xor r12, r12
.find:
    cmp r12, [rbx + SLIST.len]
    jae .done
    mov rax, [rbx + SLIST.items]
    mov rcx, r12
    shl rcx, 4
    add rcx, rax
    call list_match
    test rax, rax
    jnz .found
    inc r12
    jmp .find
.found:
    ; shift items down
    mov rax, [rbx + SLIST.items]
    mov rsi, r12
    inc rsi
    shl rsi, 4
    add rsi, rax
    mov rdi, r12
    shl rdi, 4
    add rdi, rax
    mov rcx, [rbx + SLIST.len]
    sub rcx, r12
    dec rcx
    imul rcx, VALUE_size
    rep movsb
    dec qword [rbx + SLIST.len]
.done:
    add rsp, 8
    pop r12
    pop rbx
    xor eax, eax
    ret

; list_match(rcx=Value* item) -> rax 1 if item equals g_rm_target
list_match:
    push rbx
    push r12
    mov rbx, rcx                ; item
    mov r12, [rel g_rm_target]
    test r12, r12
    jz .no
    mov rax, [rbx + VALUE.type]
    cmp rax, [r12 + VALUE.type]
    jne .no
    cmp rax, V_INT
    je .int
    cmp rax, V_BOOL
    je .int
    cmp rax, V_STR
    je .str
    cmp rax, V_LIST
    je .list
    jmp .no
.int:
    mov rax, [rbx + VALUE.data]
    cmp rax, [r12 + VALUE.data]
    jne .no
    jmp .yes
.str:
    mov rcx, [rbx + VALUE.data]
    mov rdx, [r12 + VALUE.data]
    call sstr_eq_ci
    test rax, rax
    jz .no
    jmp .yes
.list:
    mov rax, [rbx + VALUE.data]
    cmp rax, [r12 + VALUE.data]
    jne .no
    jmp .yes
.yes:
    mov eax, 1
    jmp .done
.no:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

section .bss
    g_rm_target resq 1

section .text

; ============================================================
; CLEAR THE LIST / CLEAR <name>
; ============================================================
parse_clear_stmt:
    push rbx
    call lex_next
    ; skip THE/A/AN/LIST words
.skip_loop:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .target
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_THE
    je .skip1
    cmp rax, KW_A
    je .skip1
    cmp rax, KW_AN
    je .skip1
    cmp rax, KW_LIST
    je .skip1
    jmp .target
.skip1:
    call lex_next
    jmp .skip_loop
.target:
    ; if word and it's a list var name, clear it; else use current list
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .use_current
    call copy_word_buf
    lea rcx, [rel g_word_buf]
    call sstr_from_cstr
    mov rbx, rax
    mov rcx, rbx
    call var_get
    test rax, rax
    jz .use_current
    cmp qword [rax + VALUE.type], V_LIST
    jne .use_current
    mov rax, [rax + VALUE.data]
    mov qword [rax + SLIST.len], 0
    call lex_next
    jmp .done
.use_current:
    mov rax, [rel g_current_list]
    test rax, rax
    jz .done
    mov rcx, rax
    call var_get
    test rax, rax
    jz .done
    mov rax, [rax + VALUE.data]
    mov qword [rax + SLIST.len], 0
.done:
    pop rbx
    xor eax, eax
    ret

; ============================================================
; IF / UNLESS / WHEN <condition> ',' <body>  or  ':' <block>
; ============================================================
parse_if_stmt:
    push rbx
    push r12
    sub rsp, 8
    call lex_next
    call parse_condition
    mov r12, rax          ; bool Value*
    ; separator: ',' or ':' or newline
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    je .consume_punct
    jmp .body_start
.consume_punct:
    call lex_next
.body_start:
    mov rcx, r12
    call val_truthy
    test rax, rax
    jz .false_branch
    ; take body: parse one statement (single-line) or block until DONE
    call parse_block_or_stmt
    jmp .done
.false_branch:
    ; skip to terminator ('.','!','?',newline, EOF) for single line,
    ; or find DONE/END/FINISH for blocks. For simplicity: scan forward.
    call skip_to_statement_end
.done:
    add rsp, 8
    pop r12
    pop rbx
    xor eax, eax
    ret

; ============================================================
; parse_block_or_stmt: if next is NL or ':' or block already
; consumed -> parse statements until DONE/END/FINISH keyword or EOF.
; Otherwise parse a single statement.
; ============================================================
parse_block_or_stmt:
    push rbx
    ; If current is newline or punct ':',';' -> block mode
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_NL
    je .block
    cmp rax, TOK_PUNCT
    jne .single
    mov rax, [rel lex_state + LEXER.tok_num]
    cmp rax, ':'
    je .block
    cmp rax, ';'
    je .block
    jmp .single
.block:
    ; consume separators, then parse statements until block end kw
.loop:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_NL
    je .adv
    cmp rax, TOK_EOF
    je .done
    cmp rax, TOK_PUNCT
    je .adv
    cmp rax, TOK_WORD
    jne .adv
    mov rbx, [rel lex_state + LEXER.tok_kw]
    cmp rbx, KW_DONE
    je .done
    cmp rbx, KW_END
    je .done
    cmp rbx, KW_FINISH
    je .done
    call parse_statement
    cmp eax, 2
    je .done
    cmp eax, 1
    je .done
    jmp .loop
.adv:
    call lex_next
    jmp .loop
.single:
    call parse_statement
.done:
    pop rbx
    ret

; skip_to_statement_end: consume tokens until '.' '!' '?' NL EOF,
; or until DONE/END/FINISH keyword (block end), whichever first.
skip_to_statement_end:
    sub rsp, 8
.skip_loop:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_EOF
    je .done
    cmp rax, TOK_NL
    je .done
    cmp rax, TOK_PUNCT
    jne .check_word
    mov rax, [rel lex_state + LEXER.tok_num]
    cmp rax, '.'
    je .adv_done
    cmp rax, '!'
    je .adv_done
    cmp rax, '?'
    je .adv_done
    call lex_next
    jmp .skip_loop
.check_word:
    cmp rax, TOK_WORD
    jne .adv2
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_DONE
    je .done
    cmp rax, KW_END
    je .done
    cmp rax, KW_FINISH
    je .done
.adv2:
    call lex_next
    jmp .skip_loop
.adv_done:
    call lex_next
.done:
    add rsp, 8
    ret

; ============================================================
; UNLESS: inverted if
; ============================================================
parse_unless_stmt:
    push rbx
    push r12
    sub rsp, 8
    call lex_next
    call parse_condition
    mov r12, rax
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    je .cp
    jmp .body
.cp:
    call lex_next
.body:
    mov rcx, r12
    call val_truthy
    xor rax, 1
    test rax, rax
    jz .false_branch
    call parse_block_or_stmt
    jmp .done
.false_branch:
    call skip_to_statement_end
.done:
    add rsp, 8
    pop r12
    pop rbx
    xor eax, eax
    ret

; ============================================================
; WHILE <condition> ':' <block until DONE>
; ============================================================
parse_while_stmt:
    push rbx
    push r12
    push r13
    call lex_next
    ; record loop top
    call lex_cur
    mov r13, rax
.top:
    call parse_condition
    mov r12, rax
    ; separator
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    je .cp
    jmp .test
.cp:
    call lex_next
.test:
    mov rcx, r12
    call val_truthy
    test rax, rax
    jz .done
    ; body block until DONE/END/FINISH/EOF
    call parse_block_until_done
    cmp eax, 1
    je .done
    ; restore to loop top
    mov rcx, r13
    call lex_seek
    jmp .top
.done:
    pop r13
    pop r12
    pop rbx
    xor eax, eax
    ret

; lex_seek(rcx=ptr): set cur to ptr, lex_next
lex_seek:
    mov [rel lex_state + LEXER.cur], rcx
    call lex_next
    ret

; ============================================================
; parse_block_until_done: parse statements until DONE/END/FINISH
; or EOF. Returns 1 if DONE-like terminator consumed, 2 if EOF.
; ============================================================
parse_block_until_done:
    push rbx
.loop:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_NL
    je .adv
    cmp rax, TOK_EOF
    je .eof
    cmp rax, TOK_PUNCT
    je .adv
    cmp rax, TOK_WORD
    jne .adv
    mov rbx, [rel lex_state + LEXER.tok_kw]
    cmp rbx, KW_DONE
    je .term
    cmp rbx, KW_END
    je .term
    cmp rbx, KW_FINISH
    je .term
    call parse_statement
    cmp eax, 1
    je .term_stop
    cmp eax, 2
    je .term_stop
    jmp .loop
.adv:
    call lex_next
    jmp .loop
.term:
    call lex_next
    mov eax, 1
    jmp .done
.term_stop:
    mov eax, 1
    jmp .done
.eof:
    mov eax, 2
.done:
    pop rbx
    ret

; ============================================================
; UNTIL: loop while condition is false
; ============================================================
parse_until_stmt:
    push rbx
    push r12
    push r13
    call lex_next
    call lex_cur
    mov r13, rax
.top:
    call parse_condition
    mov r12, rax
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    je .cp
    jmp .test
.cp:
    call lex_next
.test:
    mov rcx, r12
    call val_truthy
    test rax, rax
    jnz .done
    call parse_block_until_done
    cmp eax, 1
    je .done
    mov rcx, r13
    call lex_seek
    jmp .top
.done:
    pop r13
    pop r12
    pop rbx
    xor eax, eax
    ret

; ============================================================
; REPEAT <count> TIMES ':' <block until DONE>
; ============================================================
parse_repeat_stmt:
    push rbx
    push r12
    push r13
    call lex_next
    mov rcx, 0
    call parse_phrase
    mov r12, rax          ; count Value*
    cmp qword [r12 + VALUE.type], V_INT
    jne .done
    mov r12, [r12 + VALUE.data]
    ; skip TIMES
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .sep
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_TIMES
    jne .sep
    call lex_next
.sep:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    jne .loop
    call lex_next
.loop:
    call lex_cur
    mov r13, rax
.test:
    test r12, r12
    jle .done
    ; body
    call parse_block_until_done
    dec r12
    cmp eax, 1
    je .done
    mov rcx, r13
    call lex_seek
    jmp .test
.done:
    pop r13
    pop r12
    pop rbx
    xor eax, eax
    ret

; ============================================================
; FOR EACH <var> IN <list> ':' <block until DONE>
; ============================================================
parse_for_stmt:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    call lex_next
    ; skip EACH/EVERY
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_EACH
    je .s1
    cmp rax, KW_EVERY
    je .s1
    jmp .var
.s1:
    call lex_next
.var:
    call tok_word_str
    mov rbx, rax          ; var name SSTR*
    call lex_next
    ; skip IN/FROM/OF
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_IN
    je .s2
    cmp rax, KW_FROM
    je .s2
    cmp rax, KW_OF
    je .s2
    jmp .list
.s2:
    call lex_next
.list:
    mov rcx, 0
    call parse_phrase
    mov r12, rax          ; list Value*
    cmp qword [r12 + VALUE.type], V_LIST
    jne .done
    mov r12, [r12 + VALUE.data]  ; SLIST*
    ; separator
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    je .cp
    jmp .loop
.cp:
    call lex_next
.loop:
    call lex_cur
    mov r13, rax
    xor r14, r14
.iter:
    cmp r14, [r12 + SLIST.len]
    jae .done
    ; bind loop variable to item
    mov rax, [r12 + SLIST.items]
    mov rdx, r14
    shl rdx, 4
    add rdx, rax
    mov rcx, rbx
    call var_set
    ; rewind to body start and execute
    mov rcx, r13
    call lex_seek
    call parse_block_until_done
    cmp eax, 1
    je .done
    inc r14
    jmp .iter
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    xor eax, eax
    ret

; ============================================================
; Function definitions: TO [verb] <name> [OF/WITH params] ':' body
;                       ... FINISH/DONE/END
; ============================================================
parse_func_def_stmt:
    push rbx
    push r12
    push r13
    call lex_next
    ; skip optional verb (CALCULATE/COMPUTE/GET/FIND/CHECK/CREATE...)
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_CALCULATE
    je .s1
    cmp rax, KW_COMPUTE
    je .s1
    cmp rax, KW_GET
    je .s1
    cmp rax, KW_FIND
    je .s1
    cmp rax, KW_CHECK
    je .s1
    cmp rax, KW_CREATE
    je .s1
    cmp rax, KW_MAKE
    je .s1
    jmp .name
.s1:
    call lex_next
.name:
    call tok_word_str
    mov rbx, rax          ; func name
    call lex_next
    ; find entry
    mov rcx, 64
    call func_slot_alloc
    mov r12, rax          ; FUNC*
    mov [r12 + FUNC.name], rbx
    xor r13, r13          ; nparams
    ; params: optional OF/WITH then words until ':' or ','
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_OF
    je .p_start
    cmp rax, KW_WITH
    je .p_start
    jmp .body_sep
.p_start:
    call lex_next
.p_loop:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    je .body_sep
    cmp rax, TOK_NL
    je .body_sep
    cmp rax, TOK_WORD
    jne .body_sep
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_NAMED
    je .skip_pword
    cmp rax, KW_CALLED
    je .skip_pword
    cmp rax, KW_IF
    je .skip_pword
    cmp rax, KW_IS
    je .skip_pword
    call tok_word_str
    mov [r12 + r13 * 8 + FUNC.params], rax
    inc r13
.skip_pword:
    call lex_next
    jmp .p_loop
.body_sep:
    ; consume ':' or ',' or NL
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    je .bs
    cmp rax, TOK_NL
    je .bs
    jmp .body
.bs:
    call lex_next
.body:
    mov [r12 + FUNC.nparams], r13
    ; record body start
    call lex_cur
    mov [r12 + FUNC.body_start], rax
    ; scan to find FINISH/DONE/END keyword
    push rbx
    push r12
    push r13
.scan:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_EOF
    je .scan_done
    cmp rax, TOK_WORD
    jne .scan_adv
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_FINISH
    je .scan_done
    cmp rax, KW_DONE
    je .scan_done
    cmp rax, KW_END
    je .scan_done
.scan_adv:
    call lex_next
    jmp .scan
.scan_done:
    call lex_cur
    pop r13
    pop r12
    pop rbx
    mov [r12 + FUNC.body_end], rax
    ; consume terminator
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .ret
    call lex_next
.ret:
    pop r13
    pop r12
    pop rbx
    xor eax, eax
    ret

; func_slot_alloc(rcx=unused) -> rax=FUNC* new slot
func_slot_alloc:
    lea rax, [rel g_funcs]
    mov rcx, [rel g_nfuncs]
    imul rcx, rcx, FUNC_size
    add rax, rcx
    inc qword [rel g_nfuncs]
    ret

; func_lookup(rcx=SSTR* name) -> rax=FUNC* or 0
func_lookup:
    push rbx
    push r12
    push r13
    mov rbx, rcx
    lea r12, [rel g_funcs]
    mov r13, [rel g_nfuncs]
.loop:
    test r13, r13
    jz .nf
    mov rcx, [r12 + FUNC.name]
    test rcx, rcx
    jz .next
    mov rdx, rbx
    call sstr_eq_ci
    test rax, rax
    jnz .found
.next:
    add r12, FUNC_size
    dec r13
    jmp .loop
.found:
    mov rax, r12
    jmp .done
.nf:
    xor eax, eax
.done:
    pop r13
    pop r12
    pop rbx
    ret

; ============================================================
; parse_return_stmt: value into g_return_val
; ============================================================
parse_return_stmt:
    push rbx
    call lex_next
    mov rcx, 0
    call parse_phrase
    mov rbx, rax
    mov rax, [rbx + VALUE.type]
    mov [rel g_return_val + VALUE.type], rax
    mov rax, [rbx + VALUE.data]
    mov [rel g_return_val + VALUE.data], rax
    pop rbx
    mov eax, 2           ; end current block
    ret

; ============================================================
; Function calls
; ============================================================
; parse_calc_stmt: CALCULATE/COMPUTE/GET/FIND/CHECK <name> [OF <args>]
parse_calc_stmt:
    push rbx
    push r12
    sub rsp, 8
    call lex_next
    call tok_word_str
    mov rbx, rax          ; func name
    call lex_next
    call parse_call_args
    mov [rel g_call_argc], rax
    mov rcx, rbx
    call call_function
    ; clean up args from stack
    mov rax, [rel g_call_argc]
    shl rax, 3
    add rsp, rax
    add rsp, 8
    pop r12
    pop rbx
    xor eax, eax
    ret

; parse_call_stmt: CALL <name> [WITH <args>]
parse_call_stmt:
    push rbx
    push r12
    sub rsp, 8
    call lex_next
    call tok_word_str
    mov rbx, rax
    call lex_next
    call parse_call_args
    mov [rel g_call_argc], rax
    mov rcx, rbx
    call call_function
    ; clean up args from stack
    mov rax, [rel g_call_argc]
    shl rax, 3
    add rsp, rax
    add rsp, 8
    pop r12
    pop rbx
    xor eax, eax
    ret

; parse_call_args: [OF/WITH] phrase [, phrase]... ; skip keywords
parse_call_args:
    push rbx
    push r12
    push r13
    xor r12, r12          ; count
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_OF
    je .start
    cmp rax, KW_WITH
    je .start
    cmp rax, KW_FOR
    je .start
    jmp .done
.start:
    call lex_next
.loop:
    mov rcx, 1            ; stop at comma/colon
    call parse_phrase
    push rax
    inc r12
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_PUNCT
    jne .check_and
    mov rax, [rel lex_state + LEXER.tok_num]
    cmp rax, ','
    jne .done
    call lex_next
    jmp .loop
.check_and:
    cmp rax, TOK_WORD
    jne .done
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_AND
    jne .done
    call lex_next
    jmp .loop
.done:
    mov rax, r12
    pop r13
    pop r12
    pop rbx
    ret

; ============================================================
; call_function(rcx=SSTR* name)
; Args were pushed by parse_call_args (arg0 first = deepest),
; count is in g_call_argc. Args are found at [rbp+16+i*8].
; Old parameter values are saved in the local stack area
; [rbp-48-8*i] and restored after the body runs.
; ============================================================
call_function:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 0B8h
    mov rbx, rcx
    call func_lookup
    test rax, rax
    jz .nf
    mov r12, rax          ; FUNC*
    mov r13, [r12 + FUNC.nparams]
    mov r14, [rel g_call_argc]
    cmp r14, r13
    jbe .ok_count
    mov r14, r13
.ok_count:
    ; save old values: slot for param i at [rbp - 48 - i*8]
    xor r15, r15
.save:
    cmp r15, r13
    jae .saved
    mov rcx, [r12 + r15 * 8 + FUNC.params]
    call var_get
    lea rcx, [rbp - 48]
    sub rcx, r15
    shl rcx, 3
    mov [rcx], rax        ; old Value* (or 0)
    inc r15
    jmp .save
.saved:
    ; bind params: param[i] = args[argc-1-i], i in [0, r14)
    xor r15, r15
.bind:
    cmp r15, r14
    jae .bound
    mov rax, r14
    dec rax
    sub rax, r15
    lea rcx, [rbp + 16]
    mov rdx, [rcx + rax * 8]    ; Value* arg
    mov rcx, [r12 + r15 * 8 + FUNC.params]
    call var_set
    inc r15
    jmp .bind
.bound:
    ; clear the return slot, then execute body
    mov qword [rel g_return_val + VALUE.type], V_NIL
    mov qword [rel g_return_val + VALUE.data], 0
    mov rcx, [r12 + FUNC.body_start]
    call lex_seek
    call parse_block_until_done
    ; restore old param values
    mov r13, [r12 + FUNC.nparams]
    xor r15, r15
.restore:
    cmp r15, r13
    jae .restored
    lea rcx, [rbp - 48]
    sub rcx, r15
    shl rcx, 3
    mov rdx, [rcx]        ; old Value* (or 0)
    mov rcx, [r12 + r15 * 8 + FUNC.params]
    test rdx, rdx
    jz .restore_next
    call var_set
.restore_next:
    inc r15
    jmp .restore
.restored:
    ; return value -> "it"
    lea rcx, [rel g_return_val]
    call it_set
    xor eax, eax
    jmp .done
.nf:
    mov eax, 1
.done:
    add rsp, 0B8h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

section .bss
    g_call_argc resq 1
    g_call_args resq 16

section .text

; ============================================================
; File I/O: READ file "path" into <name>
; ============================================================
parse_read_stmt:
    push rbx
    push r12
    sub rsp, 8
    call lex_next
    ; skip FILE keyword
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_FILE
    jne .p
    call lex_next
.p:
    ; expect string path
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_STRING
    jne .done
    call tok_str_str
    mov rbx, rax          ; path SSTR*
    call lex_next
    ; skip INTO/IN
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_INTO
    je .s
    cmp rax, KW_IN
    je .s
    jmp .var
.s:
    call lex_next
.var:
    call tok_word_str
    mov r12, rax          ; var name
    call lex_next
    ; open file
    mov rcx, [rbx + SSTR.ptr]
    mov rdx, [rbx + SSTR.len]
    call read_file_to_sstr
    test rax, rax
    jz .done
    mov rcx, rax
    call val_str
    mov rcx, r12
    mov rdx, rax
    call var_set
.done:
    add rsp, 8
    pop r12
    pop rbx
    xor eax, eax
    ret

; read_file_to_sstr(rcx=path cstr, rdx=len) -> rax=SSTR* or 0
read_file_to_sstr:
    push rbx
    push r12
    push r13
    sub rsp, 40h
    mov rbx, rcx
    ; convert to null-terminated
    mov rcx, rdx
    inc rcx
    call heap_alloc
    mov r12, rax
    ; copy path
    mov rsi, rbx
    mov rdi, r12
    mov rcx, rdx
    rep movsb
    mov byte [rdi], 0
    ; CreateFileA
    mov rcx, r12
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
    mov r13, rax
    cmp rax, INVALID_HANDLE_VALUE
    je .fail
    ; get size
    lea rdx, [rsp + 64]
    mov rcx, r13
    call GetFileSizeEx
    test rax, rax
    jz .close_fail
    mov r12, [rsp + 64]
    ; alloc
    mov rcx, r12
    inc rcx
    call heap_alloc
    mov rbx, rax
    ; read
    mov rcx, r13
    mov rdx, rbx
    mov r8, r12
    lea r9, [rsp + 72]
    sub rsp, 20h
    mov qword [rsp + 32], 0
    call ReadFile
    add rsp, 20h
    ; close
    mov rcx, r13
    sub rsp, 40h
    call CloseHandle
    add rsp, 40h
    mov byte [rbx + r12], 0
    mov rcx, rbx
    mov rdx, r12
    call sstr_create
    jmp .done
.close_fail:
    mov rcx, r13
    sub rsp, 40h
    call CloseHandle
    add rsp, 40h
.fail:
    xor eax, eax
.done:
    add rsp, 40h
    pop r13
    pop r12
    pop rbx
    ret

; WRITE <value> TO "path"
parse_write_stmt:
    push rbx
    push r12
    sub rsp, 8
    call lex_next
    mov rcx, 2            ; stop at TO
    call parse_phrase
    mov r12, rax          ; value
    ; expect string path
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_STRING
    jne .done
    call tok_str_str
    mov rbx, rax          ; path
    ; serialize value to string
    mov rcx, r12
    call val_to_sstr
    mov r12, rax
    mov rcx, [rbx + SSTR.ptr]
    mov rdx, [rbx + SSTR.len]
    mov r8, [r12 + SSTR.ptr]
    mov r9, [r12 + SSTR.len]
    call write_sstr_to_file
.done:
    pop r12
    pop rbx
    xor eax, eax
    ret

; val_to_sstr(rcx=Value*) -> rax=SSTR*
val_to_sstr:
    push rbx
    push r12
    sub rsp, 48h
    mov rbx, rcx
    mov rax, [rbx + VALUE.type]
    cmp rax, V_STR
    je .str
    cmp rax, V_INT
    je .int
    cmp rax, V_BOOL
    je .bool
    ; nil or list
    lea rcx, [rel sz_nilv]
    call sstr_from_cstr
    jmp .done
.str:
    mov rax, [rbx + VALUE.data]
    mov rcx, [rax + SSTR.ptr]
    mov rdx, [rax + SSTR.len]
    call sstr_create
    jmp .done
.int:
    ; convert to decimal string
    mov rax, [rbx + VALUE.data]
    lea r12, [rsp + 16]
    mov rdi, r12
    add rdi, 40
    mov byte [rdi], 0
    dec rdi
    test rax, rax
    jnz .digits
    mov byte [rdi], '0'
    dec rdi
    jmp .mkstr
.digits:
    mov rcx, 10
.div:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    test rax, rax
    jnz .div
.mkstr:
    inc rdi
    mov rcx, rdi
    lea rdx, [r12 + 40]
    sub rdx, rdi
    call sstr_create
    jmp .done
.bool:
    cmp qword [rbx + VALUE.data], 0
    je .bf
    lea rcx, [rel sz_true2]
    jmp .bs
.bf:
    lea rcx, [rel sz_false2]
.bs:
    call sstr_from_cstr
.done:
    add rsp, 48h
    pop r12
    pop rbx
    ret

section .data
sz_nilv     db "nil", 0
sz_true2    db "true", 0
sz_false2   db "false", 0

section .text
; write_sstr_to_file(rcx=path, rdx=pathlen, r8=data, r9=datalen)
write_sstr_to_file:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 48h
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    ; null-terminate path
    mov rcx, r12
    inc rcx
    call heap_alloc
    mov rcx, rax
    push rcx
    mov rsi, rbx
    mov rdi, rcx
    mov rcx, r12
    rep movsb
    mov byte [rdi], 0
    pop rcx
    ; CreateFileA
    mov rdx, GENERIC_WRITE
    mov r8, 0
    xor r9, r9
    sub rsp, 20h
    mov qword [rsp + 32], CREATE_ALWAYS
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    call CreateFileA
    add rsp, 20h
    mov rbx, rax
    cmp rax, INVALID_HANDLE_VALUE
    je .done
    mov rcx, rax
    mov rdx, r13
    mov r8, r14
    lea r9, [rsp + 64]
    sub rsp, 20h
    mov qword [rsp + 32], 0
    call WriteFile
    add rsp, 20h
    mov rcx, rbx
    sub rsp, 40h
    call CloseHandle
    add rsp, 40h
.done:
    add rsp, 48h
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ============================================================
; Conditions
; ============================================================
; parse_condition() -> rax Value* (boolean result)
parse_condition:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40h
    mov rcx, 4            ; stop at comparison keywords
    call parse_phrase
    mov rbx, rax          ; left
    ; peek comparison
    mov r14, 0            ; op: 0 none,1 eq,2 ne,3 lt,4 gt,5 le,6 ge
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_WORD
    jne .no_cmp
    mov r13, [rel lex_state + LEXER.tok_kw]
    cmp r13, KW_IS
    je .cmp_is
    cmp r13, KW_EQUALS
    je .cmp_eq
    cmp r13, KW_EQUAL
    je .cmp_eq
    cmp r13, KW_ISNT
    je .cmp_ne
    cmp r13, KW_ATMOST
    je .cmp_le
    cmp r13, KW_ATLEAST
    je .cmp_ge
    cmp r13, KW_GREATER
    je .cmp_gt
    cmp r13, KW_LESS
    je .cmp_lt
    cmp r13, KW_MORE
    je .cmp_gt
    cmp r13, KW_UNDER
    je .cmp_lt
    cmp r13, KW_ABOVE
    je .cmp_gt
    cmp r13, KW_BELOW
    je .cmp_lt
    cmp r13, KW_NOMORE
    je .cmp_le
    cmp r13, KW_NOLESS
    je .cmp_ge
    cmp r13, KW_NOT
    je .cmp_not
    jmp .no_cmp
.cmp_is:
    call lex_next
    ; check next: NOT? GREATER THAN? LESS THAN? AT MOST? AT LEAST?
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_NOT
    je .is_ne
    cmp rax, KW_GREATER
    je .is_gt
    cmp rax, KW_LESS
    je .is_lt
    cmp rax, KW_MORE
    je .is_gt
    cmp rax, KW_ATMOST
    je .is_le
    cmp rax, KW_ATLEAST
    je .is_ge
    cmp rax, KW_UNDER
    je .is_lt
    cmp rax, KW_ABOVE
    je .is_gt
    cmp rax, KW_BELOW
    je .is_lt
    cmp rax, KW_NOMORE
    je .is_le
    cmp rax, KW_NOLESS
    je .is_ge
    mov r14, 1            ; plain equality
    jmp .right
.is_ne:  mov r14, 2
    call lex_next
    jmp .right
.is_gt:  mov r14, 4
    jmp .skip_than
.is_lt:  mov r14, 3
    jmp .skip_than
.is_le:  mov r14, 5
    jmp .skip_than
.is_ge:  mov r14, 6
    jmp .skip_than
.skip_than:
    call lex_next
    ; skip THAN
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_THAN
    jne .right
    call lex_next
    jmp .right
.cmp_eq:
    mov r14, 1
    call lex_next
    jmp .right
.cmp_ne:
    mov r14, 2
    call lex_next
    jmp .right
.cmp_le:
    mov r14, 5
    call lex_next
    jmp .right
.cmp_ge:
    mov r14, 6
    call lex_next
    jmp .right
.cmp_gt:
    mov r14, 4
    call lex_next
    jmp .skip_than
.cmp_lt:
    mov r14, 3
    call lex_next
    jmp .skip_than
.cmp_not:
    ; "not empty" / "not equal"
    call lex_next
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_EMPTY
    je .not_empty
    cmp rax, KW_EQUAL
    je .ne2
    cmp rax, KW_EQUALS
    je .ne2
    mov r14, 1
    jmp .right
.ne2:
    mov r14, 2
    call lex_next
    jmp .right
.not_empty:
    ; "the list is not empty" - left should be "list"
    call lex_next
    mov rcx, rbx
    call val_truthy
    xor rax, 1
    mov rcx, rax
    call val_bool
    jmp .done
.no_cmp:
    ; return left as truthiness
    mov rcx, rbx
    call val_truthy
    mov rcx, rax
    call val_bool
    jmp .done
.right:
    mov rcx, 4
    call parse_phrase
    mov r13, rax          ; right
    ; special: "the list is empty"
    ; compare
    mov rcx, rbx
    mov rdx, r13
    call val_cmp
    mov rcx, rax          ; -1/0/1
    ; apply op
    mov rdx, r14
    cmp rdx, 1
    je .op_eq
    cmp rdx, 2
    je .op_ne
    cmp rdx, 3
    je .op_lt
    cmp rdx, 4
    je .op_gt
    cmp rdx, 5
    je .op_le
    cmp rdx, 6
    je .op_ge
    ; fallback: truthiness
    mov rcx, rbx
    call val_truthy
    mov rcx, rax
    call val_bool
    jmp .done
.op_eq:
    test rcx, rcx
    jne .f
    jmp .t
.op_ne:
    test rcx, rcx
    je .f
    jmp .t
.op_lt:
    cmp rcx, -1
    jne .f
    jmp .t
.op_gt:
    cmp rcx, 1
    jne .f
    jmp .t
.op_le:
    cmp rcx, 1
    je .f
    jmp .t
.op_ge:
    cmp rcx, -1
    je .f
.t:
    mov rcx, 1
    call val_bool
    jmp .done
.f:
    mov rcx, 0
    call val_bool
.done:
    add rsp, 40h
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ============================================================
; Phrase evaluation - the "natural interpolation" engine.
; rcx = flags: bit0 stop at ',' ':' ; bit1 stop at TO/IN/INTO;
;              bit2 stop at comparison keywords
; Returns rax = Value*
; ============================================================
parse_phrase:
    push rbp
    mov rbp, rsp
    sub rsp, 68h
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r14, rcx          ; flags
    xor r12, r12          ; result Value* (0 = none)
    xor r13, r13          ; pending op (0 none, 110 plus,111 minus,112 times,113 div)
    xor r15, r15          ; word-number accumulation flag

.phrase_loop:
    mov rax, [rel lex_state + LEXER.tok_type]
    cmp rax, TOK_EOF
    je .finish
    cmp rax, TOK_NL
    je .finish
    cmp rax, TOK_NUMBER
    je .num
    cmp rax, TOK_STRING
    je .str
    cmp rax, TOK_PUNCT
    je .punct
    ; WORD
    mov rbx, [rel lex_state + LEXER.tok_kw]
    test rbx, rbx
    jz .plain
    ; keyword
    cmp rbx, KW_A
    je .silent
    cmp rbx, KW_AN
    je .silent
    cmp rbx, KW_THE
    je .silent
    cmp rbx, KW_THAN
    je .silent
    cmp rbx, KW_AND
    je .silent
    cmp rbx, KW_OR
    je .silent
    cmp rbx, KW_PLUS
    je .op_plus
    cmp rbx, KW_MINUS
    je .op_minus
    cmp rbx, KW_TIMES
    je .op_times
    cmp rbx, KW_TIMESK
    je .op_times
    cmp rbx, KW_DIVIDED
    je .op_div
    cmp rbx, KW_BY
    je .silent
    ; comparison keywords
    cmp rbx, KW_IS
    je .stop_flag2
    cmp rbx, KW_EQUALS
    je .stop_flag2
    cmp rbx, KW_EQUAL
    je .stop_flag2
    cmp rbx, KW_ISNT
    je .stop_flag2
    cmp rbx, KW_NOT
    je .stop_flag2
    cmp rbx, KW_ATMOST
    je .stop_flag2
    cmp rbx, KW_ATLEAST
    je .stop_flag2
    cmp rbx, KW_GREATER
    je .stop_flag2
    cmp rbx, KW_LESS
    je .stop_flag2
    cmp rbx, KW_MORE
    je .stop_flag2
    cmp rbx, KW_UNDER
    je .stop_flag2
    cmp rbx, KW_ABOVE
    je .stop_flag2
    cmp rbx, KW_BELOW
    je .stop_flag2
    cmp rbx, KW_NOMORE
    je .stop_flag2
    cmp rbx, KW_NOLESS
    je .stop_flag2
    ; connectors
    cmp rbx, KW_TO
    je .stop_flag1
    cmp rbx, KW_IN
    je .stop_flag1
    cmp rbx, KW_INTO
    je .stop_flag1
    cmp rbx, KW_FROM
    je .stop_flag1
    cmp rbx, KW_OF
    je .stop_flag1
    cmp rbx, KW_WITH
    je .stop_flag1
    cmp rbx, KW_NAMED
    je .stop_flag1
    cmp rbx, KW_CALLED
    je .stop_flag1
    ; time/other keywords: treat as words
    jmp .plain

.stop_flag2:
    test r14, 4
    jz .as_word
    jmp .finish
.stop_flag1:
    test r14, 2
    jz .as_word
    jmp .finish
.as_word:
    jmp .plain

.silent:
    call lex_next
    jmp .phrase_loop

.op_plus:   mov r13, KW_PLUS
    jmp .op_adv
.op_minus:  mov r13, KW_MINUS
    jmp .op_adv
.op_times:  mov r13, KW_TIMESK
    jmp .op_adv
.op_div:    mov r13, KW_DIVIDED
.op_adv:
    call lex_next
    ; for divided, expect BY
    cmp r13, KW_DIVIDED
    jne .phrase_loop
    mov rax, [rel lex_state + LEXER.tok_kw]
    cmp rax, KW_BY
    jne .phrase_loop
    call lex_next
    jmp .phrase_loop

.num:
    mov rax, [rel lex_state + LEXER.tok_num]
    mov rcx, rax
    call val_int
    mov rbx, rax
    call lex_next
    mov r15, 0
    call merge_value
    jmp .phrase_loop

.str:
    call tok_str_str
    mov rcx, rax
    call val_str
    mov rbx, rax
    call lex_next
    mov r15, 0
    call merge_value
    jmp .phrase_loop

.punct:
    mov rax, [rel lex_state + LEXER.tok_num]
    cmp rax, ','
    je .comma
    cmp rax, '.'
    je .term_adv
    cmp rax, '!'
    je .term_adv
    cmp rax, '?'
    je .term_adv
    cmp rax, ':'
    je .colon
    cmp rax, ';'
    je .term_adv
    call lex_next
    jmp .phrase_loop
.comma:
    test r14, 1
    jnz .finish
    ; append ", " to result
    push r13
    call append_comma
    pop r13
    call lex_next
    jmp .phrase_loop
.colon:
    test r14, 1
    jnz .finish
    jmp .term_adv
.term_adv:
    call lex_next
    jmp .finish

.plain:
    ; plain word: number word? variable? literal
    call copy_word_buf
    lea rcx, [rel g_word_buf]
    call is_number_word
    test rax, rax
    jz .not_numword
    lea rcx, [rel g_word_buf]
    call number_word_lookup
    mov rcx, rax
    call val_int
    mov rbx, rax
    call lex_next
    mov r15, 1
    call merge_value
    jmp .phrase_loop
.not_numword:
    lea rcx, [rel g_word_buf]
    call sstr_from_cstr
    mov rbx, rax
    ; anaphora: "it" resolves to the implicit variable
    lea rcx, [rel sz_name_it]
    call cstr_eq_ci
    test rax, rax
    jz .var_lookup
    call it_get
    mov rbx, rax
    call lex_next
    mov r15, 0
    call merge_value
    jmp .phrase_loop
.var_lookup:
    mov rcx, rbx
    call var_get
    test rax, rax
    jnz .var_val
    ; literal string
    mov rcx, rbx
    call val_str
    mov rbx, rax
    call lex_next
    mov r15, 0
    call merge_value
    jmp .phrase_loop
.var_val:
    ; use variable value (clone reference is fine, immutable-ish)
    mov rbx, rax
    call lex_next
    mov r15, 0
    call merge_value
    jmp .phrase_loop

.finish:
    ; no result -> nil
    test r12, r12
    jnz .out
    call val_nil
    jmp .done
.out:
    mov rax, r12
.done:
    add rsp, 68h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; merge_value: merge rbx (new Value*) into r12 using r13 op
merge_value:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40h
    test r12, r12
    jz .first
    ; word-number merge: if r15 and result is INT and no pending op
    cmp r15, 1
    jne .normal
    cmp qword [r12 + VALUE.type], V_INT
    jne .normal
    cmp qword [rbx + VALUE.type], V_INT
    jne .normal
    test r13, r13
    jnz .normal
    ; scale logic
    mov rax, [rbx + VALUE.data]
    cmp rax, 100
    jb .add_small
    ; result = result * cur (if result < cur) else result + cur
    mov rcx, [r12 + VALUE.data]
    test rcx, rcx
    jz .set_first
    cmp rcx, rax
    jb .mul_big
    add rcx, rax
    jmp .set
.mul_big:
    imul rcx, rax
    jmp .set
.add_small:
    mov rcx, [r12 + VALUE.data]
    add rcx, rax
    jmp .set
.set:
    push rcx
    call val_int
    pop rcx
    mov r12, rax
    jmp .done
.set_first:
    mov rcx, rax
    call val_int
    mov r12, rax
    jmp .done
.first:
    mov r12, rbx
    jmp .done
.normal:
    test r13, r13
    jz .concat
    ; apply op: r12 op rbx
    mov rcx, r12
    mov rdx, rbx
    cmp r13, KW_PLUS
    je .op_add
    cmp r13, KW_MINUS
    je .op_sub
    cmp r13, KW_TIMESK
    je .op_mul
    cmp r13, KW_DIVIDED
    je .op_div
    jmp .concat
.op_add:
    call val_add
    mov r12, rax
    xor r13, r13
    jmp .done
.op_sub:
    call val_sub
    mov r12, rax
    xor r13, r13
    jmp .done
.op_mul:
    call val_mul
    mov r12, rax
    xor r13, r13
    jmp .done
.op_div:
    call val_div
    mov r12, rax
    xor r13, r13
    jmp .done
.concat:
    ; string concat with space
    mov rcx, r12
    call val_to_sstr
    mov [rsp + 8], rax          ; s1
    mov rcx, rbx
    call val_to_sstr
    mov [rsp + 16], rax         ; s2
    mov rcx, [rsp + 8]
    lea rdx, [rel sz_space]
    call sstr_cat
    mov rcx, rax
    mov rdx, [rsp + 16]
    call sstr_cat
    mov rcx, rax
    call val_str
    mov r12, rax
.done:
    add rsp, 40h
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; append_comma: append ", " to result (stringifies)
append_comma:
    push rbx
    push r12
    push r13
    test r12, r12
    jz .done
    mov rcx, r12
    call val_to_sstr
    mov rbx, rax
    lea rcx, [rel sz_comma2]
    call sstr_from_cstr
    mov rdx, rax
    mov rcx, rbx
    call sstr_cat
    mov rcx, rax
    call val_str
    mov r12, rax
.done:
    pop r13
    pop r12
    pop rbx
    ret

section .data
sz_comma2   db ", ", 0
dbg_kw      db "kw=", 0
dbg_word    db " word='", 0
dbg_ttab    db " tbl='", 0
dbg_dkw     db "' w2k=", 0

section .text

; parse_phrase_rest: convenience - parse phrase with default flags
; (used for implicit output)
parse_phrase_rest:
    mov rcx, 0
    jmp parse_phrase