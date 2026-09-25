; ============================================================
; ENGLISH-ELF: Lexicon
; English keyword table + word-number table + lookups
; ============================================================

%include "win32.inc"

; ---------- Keyword IDs ----------
KW_SAY       equ 1
KW_PRINT     equ 2
KW_DISPLAY   equ 3
KW_SHOW      equ 4
KW_TELL      equ 5
KW_SHOUT     equ 6
KW_WHISPER   equ 7
KW_SPEAK     equ 8
KW_ANNOUNCE  equ 9
KW_YELL      equ 10
KW_OUTPUT    equ 11
KW_MUMBLE    equ 12

KW_SET       equ 20
KW_LET       equ 21
KW_MAKE      equ 22
KW_GIVE      equ 23
KW_ASSIGN    equ 24

KW_CREATE    equ 30
KW_DEFINE    equ 31
KW_LIST      equ 32
KW_NAMED     equ 33
KW_CALLED    equ 34
KW_ADD       equ 35
KW_APPEND    equ 36
KW_PUT       equ 37
KW_INSERT    equ 38
KW_REMOVE    equ 39
KW_DELETE    equ 40
KW_CLEAR     equ 41
KW_COUNT     equ 42
KW_NEW       equ 43
KW_EMPTY     equ 44

KW_IN        equ 50
KW_INTO      equ 51
KW_FROM      equ 52
KW_TO        equ 53
KW_OF        equ 54
KW_WITH      equ 55
KW_FOR       equ 56
KW_EACH      equ 57
KW_EVERY     equ 58

KW_IF        equ 60
KW_UNLESS    equ 61
KW_WHEN      equ 62
KW_WHILE     equ 63
KW_UNTIL     equ 64
KW_REPEAT    equ 65
KW_TIMES     equ 66
KW_DONE      equ 67
KW_END       equ 68
KW_FINISH    equ 69
KW_STOP      equ 70
KW_HALT      equ 71
KW_QUIT      equ 72
KW_EXIT      equ 73
KW_BREAK     equ 74
KW_CONTINUE  equ 75
KW_RETURN    equ 76
KW_SENDBACK  equ 77
KW_THEN      equ 78
KW_ELSE      equ 79
KW_OTHERWISE equ 80

KW_IS        equ 90
KW_EQUALS    equ 91
KW_EQUAL     equ 92
KW_ISNT      equ 93
KW_NOT       equ 94
KW_ATMOST    equ 95
KW_ATLEAST   equ 96
KW_GREATER   equ 97
KW_LESS      equ 98
KW_MORE      equ 99
KW_UNDER     equ 100
KW_ABOVE     equ 101
KW_BELOW     equ 102
KW_NOMORE    equ 103
KW_NOLESS    equ 104
KW_THAN      equ 105

KW_PLUS      equ 110
KW_MINUS     equ 111
KW_TIMESK    equ 112
KW_DIVIDED   equ 113
KW_BY        equ 114

KW_AND       equ 120
KW_OR        equ 121

KW_TRUE      equ 130
KW_FALSE     equ 131

KW_YES       equ 140
KW_NAH       equ 141
KW_YEAH      equ 142
KW_BET       equ 143
KW_FACTS     equ 144
KW_SLAY      equ 145
KW_SHEESH    equ 146
KW_CAP       equ 147
KW_NOCAP     equ 148

KW_GREET     equ 160
KW_HELLO     equ 161
KW_GOODBYE   equ 162
KW_THANKS    equ 163
KW_PLEASE    equ 164
KW_WELCOME   equ 165
KW_SORRY     equ 166

KW_READ      equ 170
KW_WRITE     equ 171
KW_FILE      equ 172
KW_SLEEP     equ 173
KW_WAIT      equ 174

KW_A         equ 180
KW_AN        equ 181
KW_THE       equ 182
KW_IT        equ 183
KW_LISTK     equ 184   ; "list" used as noun (the list)

KW_CALCULATE equ 190
KW_COMPUTE   equ 191
KW_GET       equ 192
KW_FIND      equ 193
KW_CHECK     equ 194
KW_CALL      equ 195

; ---------- Keyword strings ----------
section .data
align 8
kw_say       db "say",0
kw_print     db "print",0
kw_display   db "display",0
kw_show      db "show",0
kw_tell      db "tell",0
kw_shout     db "shout",0
kw_whisper   db "whisper",0
kw_speak     db "speak",0
kw_announce  db "announce",0
kw_yell      db "yell",0
kw_output    db "output",0
kw_mumble    db "mumble",0
kw_set       db "set",0
kw_let       db "let",0
kw_make      db "make",0
kw_give      db "give",0
kw_assign    db "assign",0
kw_create    db "create",0
kw_define    db "define",0
kw_list      db "list",0
kw_named     db "named",0
kw_called    db "called",0
kw_add       db "add",0
kw_append    db "append",0
kw_put       db "put",0
kw_insert    db "insert",0
kw_remove    db "remove",0
kw_delete    db "delete",0
kw_clear     db "clear",0
kw_count     db "count",0
kw_new       db "new",0
kw_empty     db "empty",0
kw_in        db "in",0
kw_into      db "into",0
kw_from      db "from",0
kw_to        db "to",0
kw_of        db "of",0
kw_with      db "with",0
kw_for       db "for",0
kw_each      db "each",0
kw_every     db "every",0
kw_if        db "if",0
kw_unless    db "unless",0
kw_when      db "when",0
kw_while     db "while",0
kw_until     db "until",0
kw_repeat    db "repeat",0
kw_times     db "times",0
kw_done      db "done",0
kw_end       db "end",0
kw_finish    db "finish",0
kw_stop      db "stop",0
kw_halt      db "halt",0
kw_quit      db "quit",0
kw_exit      db "exit",0
kw_break     db "break",0
kw_continue  db "continue",0
kw_return    db "return",0
kw_sendback  db "send back",0
kw_then      db "then",0
kw_else      db "else",0
kw_otherwise db "otherwise",0
kw_is        db "is",0
kw_equals    db "equals",0
kw_equal     db "equal",0
kw_isnt      db "isnt",0
kw_not       db "not",0
kw_atmost    db "at most",0
kw_atleast   db "at least",0
kw_greater   db "greater",0
kw_less      db "less",0
kw_more      db "more",0
kw_under     db "under",0
kw_above     db "above",0
kw_below     db "below",0
kw_nomore    db "no more",0
kw_noless    db "no less",0
kw_than      db "than",0
kw_plus      db "plus",0
kw_minus     db "minus",0
kw_timesk    db "times",0
kw_divided   db "divided",0
kw_by        db "by",0
kw_and       db "and",0
kw_or        db "or",0
kw_true      db "true",0
kw_false     db "false",0
kw_yes       db "yes",0
kw_nah       db "nah",0
kw_yeah      db "yeah",0
kw_bet       db "bet",0
kw_facts     db "facts",0
kw_slay      db "slay",0
kw_sheesh    db "sheesh",0
kw_cap       db "cap",0
kw_nocap     db "no cap",0
kw_greet     db "greet",0
kw_hello     db "hello",0
kw_goodbye   db "goodbye",0
kw_thanks    db "thanks",0
kw_please    db "please",0
kw_welcome   db "welcome",0
kw_sorry     db "sorry",0
kw_read      db "read",0
kw_write     db "write",0
kw_file      db "file",0
kw_sleep     db "sleep",0
kw_wait      db "wait",0
kw_a         db "a",0
kw_an        db "an",0
kw_the       db "the",0
kw_it        db "it",0
kw_calculate db "calculate",0
kw_compute   db "compute",0
kw_get       db "get",0
kw_find      db "find",0
kw_check     db "check",0
kw_call      db "call",0

; Table: dq ptr, dq kwid, ...
kw_table:
    dq kw_say, KW_SAY
    dq kw_print, KW_PRINT
    dq kw_display, KW_DISPLAY
    dq kw_show, KW_SHOW
    dq kw_tell, KW_TELL
    dq kw_shout, KW_SHOUT
    dq kw_whisper, KW_WHISPER
    dq kw_speak, KW_SPEAK
    dq kw_announce, KW_ANNOUNCE
    dq kw_yell, KW_YELL
    dq kw_output, KW_OUTPUT
    dq kw_mumble, KW_MUMBLE
    dq kw_set, KW_SET
    dq kw_let, KW_LET
    dq kw_make, KW_MAKE
    dq kw_give, KW_GIVE
    dq kw_assign, KW_ASSIGN
    dq kw_create, KW_CREATE
    dq kw_define, KW_DEFINE
    dq kw_list, KW_LIST
    dq kw_named, KW_NAMED
    dq kw_called, KW_CALLED
    dq kw_add, KW_ADD
    dq kw_append, KW_APPEND
    dq kw_put, KW_PUT
    dq kw_insert, KW_INSERT
    dq kw_remove, KW_REMOVE
    dq kw_delete, KW_DELETE
    dq kw_clear, KW_CLEAR
    dq kw_count, KW_COUNT
    dq kw_new, KW_NEW
    dq kw_empty, KW_EMPTY
    dq kw_in, KW_IN
    dq kw_into, KW_INTO
    dq kw_from, KW_FROM
    dq kw_to, KW_TO
    dq kw_of, KW_OF
    dq kw_with, KW_WITH
    dq kw_for, KW_FOR
    dq kw_each, KW_EACH
    dq kw_every, KW_EVERY
    dq kw_if, KW_IF
    dq kw_unless, KW_UNLESS
    dq kw_when, KW_WHEN
    dq kw_while, KW_WHILE
    dq kw_until, KW_UNTIL
    dq kw_repeat, KW_REPEAT
    dq kw_times, KW_TIMES
    dq kw_done, KW_DONE
    dq kw_end, KW_END
    dq kw_finish, KW_FINISH
    dq kw_stop, KW_STOP
    dq kw_halt, KW_HALT
    dq kw_quit, KW_QUIT
    dq kw_exit, KW_EXIT
    dq kw_break, KW_BREAK
    dq kw_continue, KW_CONTINUE
    dq kw_return, KW_RETURN
    dq kw_sendback, KW_SENDBACK
    dq kw_then, KW_THEN
    dq kw_else, KW_ELSE
    dq kw_otherwise, KW_OTHERWISE
    dq kw_is, KW_IS
    dq kw_equals, KW_EQUALS
    dq kw_equal, KW_EQUAL
    dq kw_isnt, KW_ISNT
    dq kw_not, KW_NOT
    dq kw_atmost, KW_ATMOST
    dq kw_atleast, KW_ATLEAST
    dq kw_greater, KW_GREATER
    dq kw_less, KW_LESS
    dq kw_more, KW_MORE
    dq kw_under, KW_UNDER
    dq kw_above, KW_ABOVE
    dq kw_below, KW_BELOW
    dq kw_nomore, KW_NOMORE
    dq kw_noless, KW_NOLESS
    dq kw_than, KW_THAN
    dq kw_plus, KW_PLUS
    dq kw_minus, KW_MINUS
    dq kw_timesk, KW_TIMESK
    dq kw_divided, KW_DIVIDED
    dq kw_by, KW_BY
    dq kw_and, KW_AND
    dq kw_or, KW_OR
    dq kw_true, KW_TRUE
    dq kw_false, KW_FALSE
    dq kw_yes, KW_YES
    dq kw_nah, KW_NAH
    dq kw_yeah, KW_YEAH
    dq kw_bet, KW_BET
    dq kw_facts, KW_FACTS
    dq kw_slay, KW_SLAY
    dq kw_sheesh, KW_SHEESH
    dq kw_cap, KW_CAP
    dq kw_nocap, KW_NOCAP
    dq kw_greet, KW_GREET
    dq kw_hello, KW_HELLO
    dq kw_goodbye, KW_GOODBYE
    dq kw_thanks, KW_THANKS
    dq kw_please, KW_PLEASE
    dq kw_welcome, KW_WELCOME
    dq kw_sorry, KW_SORRY
    dq kw_read, KW_READ
    dq kw_write, KW_WRITE
    dq kw_file, KW_FILE
    dq kw_sleep, KW_SLEEP
    dq kw_wait, KW_WAIT
    dq kw_a, KW_A
    dq kw_an, KW_AN
    dq kw_the, KW_THE
    dq kw_it, KW_IT
    dq kw_calculate, KW_CALCULATE
    dq kw_compute, KW_COMPUTE
    dq kw_get, KW_GET
    dq kw_find, KW_FIND
    dq kw_check, KW_CHECK
    dq kw_call, KW_CALL
kw_table_end:
kw_table_count equ (kw_table_end - kw_table) / 16

; ---------- Word numbers ----------
section .data
nw_zero     db "zero",0
nw_one      db "one",0
nw_two      db "two",0
nw_three    db "three",0
nw_four     db "four",0
nw_five     db "five",0
nw_six      db "six",0
nw_seven    db "seven",0
nw_eight    db "eight",0
nw_nine     db "nine",0
nw_ten      db "ten",0
nw_eleven   db "eleven",0
nw_twelve   db "twelve",0
nw_thirteen db "thirteen",0
nw_fourteen db "fourteen",0
nw_fifteen  db "fifteen",0
nw_sixteen  db "sixteen",0
nw_seventeen db "seventeen",0
nw_eighteen db "eighteen",0
nw_nineteen db "nineteen",0
nw_twenty   db "twenty",0
nw_thirty   db "thirty",0
nw_forty    db "forty",0
nw_fifty    db "fifty",0
nw_sixty    db "sixty",0
nw_seventy  db "seventy",0
nw_eighty   db "eighty",0
nw_ninety   db "ninety",0
nw_hundred  db "hundred",0
nw_thousand db "thousand",0
nw_million  db "million",0

num_table:
    dq nw_zero, 0
    dq nw_one, 1
    dq nw_two, 2
    dq nw_three, 3
    dq nw_four, 4
    dq nw_five, 5
    dq nw_six, 6
    dq nw_seven, 7
    dq nw_eight, 8
    dq nw_nine, 9
    dq nw_ten, 10
    dq nw_eleven, 11
    dq nw_twelve, 12
    dq nw_thirteen, 13
    dq nw_fourteen, 14
    dq nw_fifteen, 15
    dq nw_sixteen, 16
    dq nw_seventeen, 17
    dq nw_eighteen, 18
    dq nw_nineteen, 19
    dq nw_twenty, 20
    dq nw_thirty, 30
    dq nw_forty, 40
    dq nw_fifty, 50
    dq nw_sixty, 60
    dq nw_seventy, 70
    dq nw_eighty, 80
    dq nw_ninety, 90
    dq nw_hundred, 100
    dq nw_thousand, 1000
    dq nw_million, 1000000
num_table_end:
num_table_count equ (num_table_end - num_table) / 16

; ---------- Lookups ----------
section .data
dbg_kwc    db "kwcount=", 0
dbg_kws    db " first='", 0
dbg_kwid   db "' id=", 0
dbg_cec    db "cec(", 0
dbg_cec2   db ",", 0
dbg_cec3   db "rsp16=", 0
dbg_cec4   db " ret=", 0
dbg_cec5   db " w", 0
dbg_cec6   db ",", 0
dbg_cec7   db ",", 0
dbg_cec8   db ",", 0
dbg_cec9   db ",", 0
dbg_cec10  db ",", 0
dbg_cec11  db ",", 0
dbg_cec12  db ",", 0
dbg_cec_w  db "word='", 0
dbg_cec_t  db " tbl='", 0
dbg_cec_nl db "'", 13, 10, 0

section .bss
g_dbg_once resq 1

section .text
; word_is(rcx=lowercased cstr) -> rax=kwid or 0
word_to_kw:
    push rbx
    push r12
    mov rbx, rcx
    lea r12, [rel kw_table]
    mov rcx, kw_table_count
.loop:
    test rcx, rcx
    jz .nf
    cmp r12, kw_table
    jne .dbg_none
    lea rcx, [rel dbg_kwc]
    call print_z
    mov rcx, kw_table_count
    call print_int64
    call print_newline
    mov rdx, [r12]
    lea rcx, [rel dbg_kws]
    call print_z
    mov rcx, rdx
    call print_z
    call print_newline
    mov rdx, [r12]
    lea rcx, [rel dbg_kwid]
    call print_z
    mov rcx, [r12 + 8]
    call print_int64
    call print_newline
.dbg_none:
    mov rdx, [r12]            ; cstr
    push rcx
    mov rcx, rbx
    call cstr_eq_ci
    pop rcx
    test rax, rax
    jnz .found
    add r12, 16
    dec rcx
    jmp .loop
.found:
    mov rax, [r12 + 8]
    jmp .done
.nf:
    xor eax, eax
.done:
    pop r12
    pop rbx
    ret

; cstr_eq_ci(rcx=a, rdx=b) -> rax=1 if equal (both null-terminated)
cstr_eq_ci:
    push rbx
    cmp qword [rel g_dbg_once], 0
    jae .probe_done
    inc qword [rel g_dbg_once]
    sub rsp, 24
    mov [rsp], rcx
    mov [rsp + 8], rdx
    mov rax, rsp
    add rax, 8
    and rax, 15
    lea rcx, [rel dbg_cec3]
    call print_z
    mov rcx, rax
    call print_int64
    call print_newline
    lea rcx, [rel dbg_cec4]
    call print_z
    mov rcx, [rsp + 32]
    call print_int64
    call print_newline
    lea rcx, [rel dbg_cec5]
    call print_z
    mov rcx, [rsp + 40]
    call print_int64
    lea rcx, [rel dbg_cec6]
    call print_z
    mov rcx, [rsp + 48]
    call print_int64
    lea rcx, [rel dbg_cec7]
    call print_z
    mov rcx, [rsp + 56]
    call print_int64
    lea rcx, [rel dbg_cec8]
    call print_z
    mov rcx, [rsp + 64]
    call print_int64
    call print_newline
    lea rcx, [rel dbg_cec9]
    call print_z
    mov rcx, [rsp + 72]
    call print_int64
    lea rcx, [rel dbg_cec10]
    call print_z
    mov rcx, [rsp + 80]
    call print_int64
    lea rcx, [rel dbg_cec11]
    call print_z
    mov rcx, [rsp + 88]
    call print_int64
    lea rcx, [rel dbg_cec12]
    call print_z
    mov rcx, [rsp + 96]
    call print_int64
    call print_newline
    lea rcx, [rel dbg_cec]
    call print_z
    mov rcx, [rsp]
    call print_int64
    lea rcx, [rel dbg_cec2]
    call print_z
    mov rcx, [rsp + 8]
    call print_int64
    call print_newline
    ; print word string content
    lea rcx, [rel dbg_cec_w]
    call print_z
    mov rcx, [rsp]
    call print_z
    lea rcx, [rel dbg_cec_nl]
    call print_z
    ; print table entry string content
    lea rcx, [rel dbg_cec_t]
    call print_z
    mov rcx, [rsp + 8]
    call print_z
    lea rcx, [rel dbg_cec_nl]
    call print_z
    mov rcx, [rsp]
    mov rdx, [rsp + 8]
    add rsp, 24
.probe_done:
.loop:
    mov al, [rcx]
    mov bl, [rdx]
    test al, al
    jz .at_end
    or al, 32
    or bl, 32
    cmp al, bl
    jne .no
    inc rcx
    inc rdx
    jmp .loop
.at_end:
    test bl, bl
    jnz .no
    mov eax, 1
    jmp .done
.no:
    xor eax, eax
.done:
    pop rbx
    ret

; number_word_lookup(rcx=lowercased cstr) -> rax=value or -1
number_word_lookup:
    push rbx
    push r12
    mov rbx, rcx
    lea r12, [rel num_table]
    mov rcx, num_table_count
.loop:
    test rcx, rcx
    jz .nf
    mov rdx, [r12]
    push rcx
    mov rcx, rbx
    call cstr_eq_ci
    pop rcx
    test rax, rax
    jnz .found
    add r12, 16
    dec rcx
    jmp .loop
.found:
    mov rax, [r12 + 8]
    jmp .done
.nf:
    mov rax, -1
.done:
    pop r12
    pop rbx
    ret

; is_number_word(rcx=cstr) -> rax=1/0
is_number_word:
    push rbx
    mov rbx, rcx
    call number_word_lookup
    cmp rax, -1
    je .no
    mov eax, 1
    jmp .done
.no:
    xor eax, eax
.done:
    pop rbx
    ret