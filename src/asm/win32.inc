; ============================================================
; ENGLISH-ELF: Windows x86-64 Constants and Structures
; Pure NASM - no external dependencies
; ============================================================

; ---------- Console ----------
STD_INPUT_HANDLE    equ -10
STD_OUTPUT_HANDLE   equ -11
STD_ERROR_HANDLE    equ -12

; ---------- File ----------
GENERIC_READ        equ 0x80000000
GENERIC_WRITE       equ 0x40000000
FILE_SHARE_READ     equ 1
FILE_SHARE_WRITE    equ 2
OPEN_EXISTING       equ 3
CREATE_ALWAYS       equ 2
OPEN_ALWAYS         equ 4
FILE_ATTRIBUTE_NORMAL equ 0x80
FILE_BEGIN          equ 0
INVALID_HANDLE_VALUE equ 0xFFFFFFFFFFFFFFFF

; ---------- Memory ----------
MEM_COMMIT          equ 0x1000
MEM_RESERVE         equ 0x2000
MEM_RELEASE         equ 0x8000
PAGE_READWRITE      equ 0x04
PAGE_EXECUTE_READ   equ 0x20
PAGE_EXECUTE_READWRITE equ 0x40

; ---------- Token types ----------
TOK_EOF             equ 0
TOK_WORD            equ 1
TOK_NUMBER          equ 2
TOK_STRING          equ 3
TOK_PUNCT           equ 4
TOK_NL              equ 5

; ---------- Value types ----------
V_NIL               equ 0
V_INT               equ 1
V_STR               equ 2
V_LIST              equ 3
V_BOOL              equ 4

struc VALUE
    .type   resq 1
    .data   resq 1
endstruc

struc SSTR
    .len    resq 1
    .ptr    resq 1
endstruc

struc SLIST
    .len    resq 1
    .cap    resq 1
    .items  resq 1
endstruc

; ---------- Lexer state ----------
struc LEXER
    .src        resq 1   ; start of source
    .end        resq 1   ; end of source
    .cur        resq 1   ; current position
    .line       resq 1
    .col        resq 1
    .tok_type   resq 1
    .tok_start  resq 1
    .tok_len    resq 1
    .tok_num    resq 1   ; numeric value for NUMBER
    .tok_kw     resq 1   ; keyword id for WORD
endstruc
LEXER_SIZE equ LEXER_size

; ---------- Function table entry ----------
struc FUNC
    .name       resq 1   ; SSTR*
    .body_start resq 1   ; source offset
    .body_end   resq 1   ; source offset
    .nparams    resq 1
    .params     resq 16  ; SSTR* param names
endstruc
FUNC_SIZE equ FUNC_size

; ---------- Var table entry ----------
struc VARENT
    .hash   resq 1
    .name   resq 1   ; SSTR*
    .value  resb 16  ; VALUE
endstruc
VARENT_SIZE equ VARENT_size

; ---------- JIT buffer ----------
struc JITBUF
    .base   resq 1
    .cur    resq 1
    .limit  resq 1
endstruc