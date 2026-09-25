/*
 * ENGLISH-ELF: an x86-64 ELF binary that interprets English .txt files as programs.
 *
 * Architecture:
 *   source -> Token*  (lexer)
 *   Token* -> Stmt**  (parser, recursive descent)
 *   Stmt** -> side effects  (interpreter)
 *
 * v0.1 feature set (each works end-to-end):
 *   Output    : say / tell / print / shout / display / output <expr>
 *   Set       : set <name> to <expr>   |   let <name> be <expr>
 *   Create    : create / make / define a list named <name>
 *   Add       : add / append / put <value> to <name>
 *   For-each  : for each <var> in <list>, <body>.
 *   Articles  : "the", "a", "an" are silently skipped.
 *   Conjugate : "and" before last item in lists is silently skipped.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>
#include <stdarg.h>
#include <errno.h>

#define ENGLISH_ELF_VERSION "0.5.0-alpha (Linux/C)"

/* ========================================================================
 * VALUE
 * ====================================================================== */

typedef enum { V_NIL, V_INT, V_STRING, V_LIST } VType;

typedef struct Value {
    VType type;
    int    int_v;
    char*  str_v;
    struct Value** list_v;
    int    list_len;
    int    list_cap;
} Value;

static Value* v_nil(void) {
    Value* v = calloc(1, sizeof(Value));
    v->type = V_NIL;
    return v;
}

static Value* v_int(int x) {
    Value* v = calloc(1, sizeof(Value));
    v->type = V_INT;
    v->int_v = x;
    return v;
}

static Value* v_str(const char* s) {
    Value* v = calloc(1, sizeof(Value));
    v->type = V_STRING;
    v->str_v = strdup(s ? s : "");
    return v;
}

static Value* v_list(void) {
    Value* v = calloc(1, sizeof(Value));
    v->type = V_LIST;
    v->list_cap = 4;
    v->list_v = calloc(v->list_cap, sizeof(Value*));
    return v;
}

static void v_append(Value* list, Value* item) {
    if (list->type != V_LIST) return;
    if (list->list_len >= list->list_cap) {
        list->list_cap *= 2;
        list->list_v = realloc(list->list_v, list->list_cap * sizeof(Value*));
    }
    list->list_v[list->list_len++] = item;
}

static void v_free(Value* v) {
    if (!v) return;
    if (v->type == V_STRING) free(v->str_v);
    if (v->type == V_LIST) {
        for (int i = 0; i < v->list_len; i++) v_free(v->list_v[i]);
        free(v->list_v);
    }
    free(v);
}

static Value* v_clone(Value* v) {
    if (!v) return v_nil();
    switch (v->type) {
        case V_NIL:    return v_nil();
        case V_INT:    return v_int(v->int_v);
        case V_STRING: return v_str(v->str_v);
        case V_LIST: {
            Value* out = v_list();
            for (int i = 0; i < v->list_len; i++)
                v_append(out, v_clone(v->list_v[i]));
            return out;
        }
    }
    return v_nil();
}

static char* v_to_str(Value* v) {
    char buf[64];
    if (!v) return strdup("nil");
    switch (v->type) {
        case V_NIL:    return strdup("nil");
        case V_INT:    snprintf(buf, sizeof(buf), "%d", v->int_v); return strdup(buf);
        case V_STRING: return strdup(v->str_v);
        case V_LIST: {
            size_t cap = 64, len = 0;
            char* out = malloc(cap);
            out[len++] = '[';
            for (int i = 0; i < v->list_len; i++) {
                if (i) { out[len++] = ','; out[len++] = ' '; }
                char* es = v_to_str(v->list_v[i]);
                size_t el = strlen(es);
                while (len + el + 4 > cap) { cap *= 2; out = realloc(out, cap); }
                memcpy(out + len, es, el); len += el;
                free(es);
            }
            if (len + 2 > cap) { cap += 2; out = realloc(out, cap); }
            out[len++] = ']';
            out[len] = 0;
            return out;
        }
    }
    return strdup("nil");
}

/* ========================================================================
 * LEXER
 * ====================================================================== */

typedef enum {
    T_WORD,
    T_NUMBER,
    T_STRING,
    T_PUNCT,
    T_EOF
} TType;

typedef struct {
    TType type;
    const char* start;
    int len;
    int line;
    int col;
    int num;
} Token;

static int is_letter(int c) { return isalpha((unsigned char)c); }
static int is_digit(int c)  { return c >= '0' && c <= '9'; }

static int number_word(const char* s, int len) {
    static const char* ones[] = {
        "zero","one","two","three","four","five","six","seven","eight","nine",
        "ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen",
        "seventeen","eighteen","nineteen"
    };
    static const char* tens[] = {
        "","","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety"
    };
    for (int i = 0; i < 20; i++) {
        if (len == (int)strlen(ones[i]) && strncasecmp(s, ones[i], len) == 0)
            return i;
    }
    for (int i = 2; i < 10; i++) {
        if (len == (int)strlen(tens[i]) && strncasecmp(s, tens[i], len) == 0)
            return i * 10;
    }
    return -1;
}

static Token* lex(const char* src, int* out_count) {
    int cap = 256, n = 0;
    Token* toks = malloc(cap * sizeof(Token));
    int line = 1, col = 1;
    const char* p = src;

    while (*p) {
        while (*p == ' ' || *p == '\t' || *p == '\r') { p++; col++; }
        if (!*p) break;

        if (*p == '\n') {
            if (n >= cap) { cap *= 2; toks = realloc(toks, cap * sizeof(Token)); }
            toks[n].type = T_PUNCT; toks[n].start = p; toks[n].len = 1;
            toks[n].line = line; toks[n].col = col; toks[n].num = '.';
            n++;
            p++; line++; col = 1;
            continue;
        }

        if (*p == '#') {
            while (*p && *p != '\n') { p++; col++; }
            continue;
        }

        if (*p == '.' || *p == ',' || *p == ';' || *p == ':' || *p == '!' || *p == '?') {
            if (n >= cap) { cap *= 2; toks = realloc(toks, cap * sizeof(Token)); }
            toks[n].type = T_PUNCT; toks[n].start = p; toks[n].len = 1;
            toks[n].line = line; toks[n].col = col; toks[n].num = *p;
            n++;
            p++; col++;
            continue;
        }

        if (*p == '"') {
            const char* start = p + 1;
            p++; col++;
            while (*p && *p != '"') { if (*p == '\n') { line++; col = 1; } else col++; p++; }
            int len = (int)(p - start);
            if (*p == '"') { p++; col++; }
            if (n >= cap) { cap *= 2; toks = realloc(toks, cap * sizeof(Token)); }
            toks[n].type = T_STRING; toks[n].start = start; toks[n].len = len;
            toks[n].line = line; toks[n].col = col - len - 2; toks[n].num = 0;
            n++;
            continue;
        }

        if (is_digit(*p)) {
            const char* s = p;
            int v = 0;
            while (is_digit(*p)) { v = v * 10 + (*p - '0'); p++; col++; }
            if (n >= cap) { cap *= 2; toks = realloc(toks, cap * sizeof(Token)); }
            toks[n].type = T_NUMBER; toks[n].start = s; toks[n].len = (int)(p - s);
            toks[n].line = line; toks[n].col = col - (int)(p - s); toks[n].num = v;
            n++;
            continue;
        }

        if (is_letter(*p)) {
            const char* s = p;
            while (is_letter(*p) || *p == '-' || *p == '_' || *p == '\'') { p++; col++; }
            int len = (int)(p - s);
            int nv = number_word(s, len);
            if (n >= cap) { cap *= 2; toks = realloc(toks, cap * sizeof(Token)); }
            toks[n].type = T_WORD; toks[n].start = s; toks[n].len = len;
            toks[n].line = line; toks[n].col = col - len; toks[n].num = nv;
            n++;
            continue;
        }

        p++; col++;
    }

    if (n >= cap) { cap++; toks = realloc(toks, cap * sizeof(Token)); }
    toks[n].type = T_EOF; toks[n].start = p; toks[n].len = 0;
    toks[n].line = line; toks[n].col = col; toks[n].num = 0;
    n++;

    *out_count = n;
    return toks;
}

/* ========================================================================
 * LEXICON
 * ====================================================================== */

static char** g_lex = NULL;
static int    g_lex_n = 0;

static int lex_cmp(const void* a, const void* b) {
    const char* sa = *(const char* const*)a;
    const char* sb = *(const char* const*)b;
    return strcmp(sa, sb);
}

static void lex_load(const char* path) {
    if (g_lex) return; // already loaded
    FILE* f = fopen(path, "r");
    if (!f) return;
    int cap = 65536;
    g_lex = malloc(cap * sizeof(char*));
    char buf[128];
    while (fgets(buf, sizeof(buf), f)) {
        char* s = buf;
        while (*s == ' ' || *s == '\t') s++;
        char* end = s + strlen(s);
        while (end > s && (end[-1] == '\n' || end[-1] == '\r' || end[-1] == ' ')) end--;
        *end = 0;
        if (!*s) continue;
        if (g_lex_n >= cap) { cap *= 2; g_lex = realloc(g_lex, cap * sizeof(char*)); }
        g_lex[g_lex_n++] = strdup(s);
    }
    fclose(f);
    qsort(g_lex, g_lex_n, sizeof(char*), lex_cmp);
    if (getenv("ENGLISH_ELF_VERBOSE"))
        fprintf(stderr, "Loaded %d words into lexicon from %s\n", g_lex_n, path);
}

static void lex_load_with_fallback(void) {
    const char* candidates[] = {
        "data/words.txt",
        "./data/words.txt",
        "english-elf/data/words.txt",
        "./english-elf/data/words.txt",
        "../data/words.txt",
        NULL
    };
    for (int i = 0; candidates[i]; i++) {
        lex_load(candidates[i]);
        if (g_lex_n) break;
    }
}

/* ========================================================================
 * AST
 * ====================================================================== */

typedef enum { E_NUM, E_STR, E_VAR } EType;
typedef struct Expr {
    EType type;
    int    num;
    char*  str;
} Expr;

static Expr* e_num(int n)  { Expr* e = calloc(1, sizeof(Expr)); e->type = E_NUM; e->num = n; return e; }
static Expr* e_str(const char* s) { Expr* e = calloc(1, sizeof(Expr)); e->type = E_STR; e->str = strdup(s); return e; }
static void  e_free(Expr* e) { if (e) { free(e->str); free(e); } }

typedef enum {
    S_OUTPUT,
    S_SET,
    S_CREATE,
    S_ADD,
    S_FOR_EACH,
    S_BLOCK
} SType;

typedef struct Stmt {
    SType type;
    Expr** out_exprs;     /* expressions to print (space-separated) */
    int    out_exprs_n;
    char* set_name;
    Expr* set_val;
    char* create_name;
    Expr** add_vals;     /* array of expressions to add */
    int    add_vals_n;
    char* add_list;
    char* fe_var;
    char* fe_list;
    struct Stmt* fe_body;
    struct Stmt** blk;
    int blk_n;
} Stmt;

static Stmt* s_new(SType t) { Stmt* s = calloc(1, sizeof(Stmt)); s->type = t; return s; }
static void  s_free(Stmt* s) {
    if (!s) return;
    for (int i = 0; i < s->out_exprs_n; i++) e_free(s->out_exprs[i]);
    free(s->out_exprs);
    free(s->set_name); e_free(s->set_val);
    free(s->create_name);
    for (int i = 0; i < s->add_vals_n; i++) e_free(s->add_vals[i]);
    free(s->add_vals);
    free(s->add_list);
    free(s->fe_var); free(s->fe_list);
    s_free(s->fe_body);
    for (int i = 0; i < s->blk_n; i++) s_free(s->blk[i]);
    free(s->blk);
    free(s);
}

/* ========================================================================
 * PARSER
 * ====================================================================== */

typedef struct {
    Token* toks;
    int n;
    int pos;
    int had_error;
} Parser;

#define TOK(p) ((p)->toks[(p)->pos])

static int match_word(Parser* p, const char* word) {
    if (TOK(p).type != T_WORD) return 0;
    if (TOK(p).len != (int)strlen(word)) return 0;
    if (strncasecmp(TOK(p).start, word, TOK(p).len) != 0) return 0;
    p->pos++;
    return 1;
}

static int peek_word_is(Parser* p, const char* word) {
    if (TOK(p).type != T_WORD) return 0;
    if (TOK(p).len != (int)strlen(word)) return 0;
    return strncasecmp(TOK(p).start, word, TOK(p).len) == 0;
}

static int peek_word_in(Parser* p, int n, const char* const* words) {
    if (TOK(p).type != T_WORD) return 0;
    for (int i = 0; i < n; i++) {
        if ((int)strlen(words[i]) == TOK(p).len &&
            strncasecmp(TOK(p).start, words[i], TOK(p).len) == 0)
            return 1;
    }
    return 0;
}

static int is_article(const char* s, int len) {
    static const char* arts[] = { "the", "a", "an" };
    for (int i = 0; i < 3; i++)
        if ((int)strlen(arts[i]) == len && strncasecmp(s, arts[i], len) == 0)
            return 1;
    return 0;
}

static void skip_articles(Parser* p) {
    while (TOK(p).type == T_WORD && is_article(TOK(p).start, TOK(p).len))
        p->pos++;
}

static int stop_period_or_nl(Parser* p) {
    Token t = TOK(p);
    if (t.type == T_EOF) return 1;
    if (t.type == T_PUNCT && t.num == '.') return 1;  /* period or synthetic newline */
    return 0;
}

/* forward decls */
static Stmt* parse_stmt(Parser* p);
static char* parse_name(Parser* p);
static Expr* parse_expr_at(Parser* p, int allow_and_stop);

/* read a single bare word as a name (variable / list identifier) */
static char* parse_name(Parser* p) {
    skip_articles(p);
    if (TOK(p).type != T_WORD) {
        p->had_error = 1;
        fprintf(stderr, "Parse error: expected name at line %d col %d\n",
                TOK(p).line, TOK(p).col);
        return strdup("");
    }
    char* n = strndup(TOK(p).start, TOK(p).len);
    for (char* c = n; *c; c++) *c = tolower((unsigned char)*c);
    p->pos++;
    return n;
}

static Expr* parse_expr_at(Parser* p, int allow_and_stop) {
    skip_articles(p);
    if (TOK(p).type == T_NUMBER) {
        Expr* e = e_num(TOK(p).num);
        p->pos++;
        return e;
    }
    if (TOK(p).type == T_STRING) {
        Expr* e = e_str("");
        free(e->str);
        e->str = strndup(TOK(p).start, TOK(p).len);
        p->pos++;
        return e;
    }
    if (TOK(p).type == T_WORD) {
        char buf[1024]; buf[0] = 0;
        int first = 1;
        while (TOK(p).type == T_WORD || TOK(p).type == T_NUMBER) {
            if (TOK(p).type == T_WORD) {
                if (peek_word_is(p,"to") || peek_word_is(p,"in") ||
                    peek_word_is(p,"into") || peek_word_is(p,"from") ||
                    peek_word_is(p,"for") || peek_word_is(p,"at")  ||
                    peek_word_is(p,"with") || peek_word_is(p,"be")  ||
                    peek_word_is(p,"is")  || peek_word_is(p,"the") ||
                    peek_word_is(p,"a")   || peek_word_is(p,"an")) break;
                if (!allow_and_stop && peek_word_is(p,"and")) break;
            }
            if (!first) strncat(buf, " ", sizeof(buf)-strlen(buf)-1);
            size_t avail = sizeof(buf) - strlen(buf) - 1;
            if ((int)avail > TOK(p).len) avail = TOK(p).len;
            strncat(buf, TOK(p).start, avail);
            first = 0;
            p->pos++;
        }
        if (first) {
            p->had_error = 1;
            fprintf(stderr, "Parse error: expected expression at line %d col %d\n",
                    TOK(p).line, TOK(p).col);
            return e_num(0);
        }
        for (char* c = buf; *c; c++) *c = tolower((unsigned char)*c);
        return e_str(buf);
    }
    p->had_error = 1;
    fprintf(stderr, "Parse error: expected expression at line %d col %d\n",
            TOK(p).line, TOK(p).col);
    return e_num(0);
}

static Expr* parse_expr(Parser* p) {
    return parse_expr_at(p, 0);
}

static Stmt* parse_output(Parser* p) {
    Stmt* s = s_new(S_OUTPUT);
    p->pos++;
    int cap = 4;
    s->out_exprs = malloc(cap * sizeof(Expr*));
    s->out_exprs_n = 0;
    s->out_exprs[s->out_exprs_n++] = parse_expr(p);
    static const char* fluff[] = {
        "to","at","for","with","the","a","an",
        "world","everyone","all","of","us","them"
    };
    int nf = (int)(sizeof(fluff)/sizeof(fluff[0]));
    while (!stop_period_or_nl(p)) {
        if (TOK(p).type == T_PUNCT && TOK(p).num == ',') {
            p->pos++;
            if (s->out_exprs_n >= cap) { cap *= 2; s->out_exprs = realloc(s->out_exprs, cap * sizeof(Expr*)); }
            s->out_exprs[s->out_exprs_n++] = parse_expr_at(p, 1);
            continue;
        }
        if (peek_word_is(p, "and")) {
            p->pos++;
            if (s->out_exprs_n >= cap) { cap *= 2; s->out_exprs = realloc(s->out_exprs, cap * sizeof(Expr*)); }
            s->out_exprs[s->out_exprs_n++] = parse_expr_at(p, 1);
            continue;
        }
        if (TOK(p).type == T_WORD) {
            int matched = 0;
            for (int i = 0; i < nf; i++) {
                if (peek_word_is(p, fluff[i])) { p->pos++; matched = 1; break; }
            }
            if (!matched) {
                p->had_error = 1;
                fprintf(stderr, "Trailing word after output at line %d\n", TOK(p).line);
                p->pos++;
            }
        } else if (TOK(p).type == T_STRING) {
            /* append literal string to last expression */
            char* extra = strndup(TOK(p).start, TOK(p).len);
            Expr* last = s->out_exprs[s->out_exprs_n - 1];
            const char* old = last->str;
            size_t nl = strlen(old) + strlen(extra) + 2;
            char* cat = malloc(nl);
            snprintf(cat, nl, "%s %s", old, extra);
            free(last->str);
            last->str = cat;
            free((void*)old);
            free(extra);
            p->pos++;
        } else {
            break;
        }
    }
    return s;
}

static Stmt* parse_set(Parser* p) {
    Stmt* s = s_new(S_SET);
    p->pos++; /* consume verb */
    s->set_name = parse_name(p);
    (void)match_word(p, "to"); (void)match_word(p, "be"); (void)match_word(p, "is"); (void)match_word(p, "equals"); (void)match_word(p, "equal");
    s->set_val = parse_expr(p);
    // Handle natural comma/and continuation inside string value (e.g. "Hello, friend.")
    // Join subsequent phrases with space so "Hello, friend" becomes "hello friend" (lowercased)
    if (s->set_val && s->set_val->type == E_STR) {
        while (1) {
            int had_sep = 0;
            if (TOK(p).type == T_PUNCT && TOK(p).num == ',') { p->pos++; had_sep = 1; }
            if (peek_word_is(p, "and")) { p->pos++; had_sep = 1; }
            if (!had_sep) break;
            if (stop_period_or_nl(p)) break;
            Expr* extra = parse_expr_at(p, 1);
            if (!extra || extra->type != E_STR) { e_free(extra); break; }
            size_t nl = strlen(s->set_val->str) + strlen(extra->str) + 2;
            char* cat = malloc(nl);
            snprintf(cat, nl, "%s %s", s->set_val->str, extra->str);
            free(s->set_val->str);
            s->set_val->str = cat;
            e_free(extra);
        }
    }
    return s;
}

static Stmt* parse_create(Parser* p) {
    Stmt* s = s_new(S_CREATE);
    p->pos++; /* consume verb (create/make/define) */
    while (TOK(p).type == T_WORD && (peek_word_is(p,"a") || peek_word_is(p,"an"))) p->pos++;
    if (peek_word_is(p,"list")) p->pos++;
    (void)match_word(p, "named"); (void)match_word(p, "called");
    s->create_name = parse_name(p);
    return s;
}

static Stmt* parse_add(Parser* p) {
    Stmt* s = s_new(S_ADD);
    p->pos++; /* consume verb */
    int cap = 4;
    s->add_vals = malloc(cap * sizeof(Expr*));
    s->add_vals_n = 0;
    s->add_vals[s->add_vals_n++] = parse_expr(p);
    /* A separator is "and" or "," (or both: ", and"). After consuming any
     * separator(s), call parse_expr_at with allow_and_stop=1 so it does not
     * stop at "and" (the separator was consumed here, not there). */
    for (;;) {
        int any = 0;
        /* consume comma if present */
        if (TOK(p).type == T_PUNCT && TOK(p).num == ',') { p->pos++; any = 1; }
        if (peek_word_is(p, "and")) { p->pos++; any = 1; }
        if (!any) break;
        if (s->add_vals_n >= cap) { cap *= 2; s->add_vals = realloc(s->add_vals, cap * sizeof(Expr*)); }
        s->add_vals[s->add_vals_n++] = parse_expr_at(p, 1);
    }
    if (!(match_word(p, "to") || match_word(p, "into") || match_word(p, "in"))) {
        p->had_error = 1;
        fprintf(stderr, "Expected 'to'/'in' after add value at line %d\n", TOK(p).line);
        return s;
    }
    s->add_list = parse_name(p);
    return s;
}

static Stmt* parse_for_each(Parser* p) {
    Stmt* s = s_new(S_FOR_EACH);
    p->pos++; /* consume "for" */
    (void)match_word(p, "each"); (void)match_word(p, "every");
    s->fe_var = parse_name(p);
    if (!(match_word(p, "in") || match_word(p, "from"))) {
        p->had_error = 1;
        fprintf(stderr, "Expected 'in' after var in for-each at line %d\n", TOK(p).line);
        return s;
    }
    s->fe_list = parse_name(p);
    /* skip any leading comma (e.g. "for each x in primes, print x.") */
    while (TOK(p).type == T_PUNCT && TOK(p).num == ',') p->pos++;
    s->fe_body = parse_stmt(p);
    return s;
}

static Stmt* parse_stmt(Parser* p) {
    skip_articles(p);
    if (TOK(p).type != T_WORD) {
        while (!stop_period_or_nl(p)) p->pos++;
        return NULL;
    }

    static const char* out_v[] = {
        "say","tell","print","shout","display","output","speak","announce","yell"
    };
    static const char* set_v[] = { "set","let" };
    static const char* create_v[] = { "create","make","define" };
    static const char* add_v[] = { "add","append","put","insert" };
    static const char* for_v[] = { "for" };

    Stmt* s = NULL;
    if (peek_word_in(p, 9, out_v))              s = parse_output(p);
    else if (peek_word_in(p, 2, set_v))         s = parse_set(p);
    else if (peek_word_in(p, 3, create_v))      s = parse_create(p);
    else if (peek_word_in(p, 4, add_v))         s = parse_add(p);
    else if (peek_word_in(p, 1, for_v))         s = parse_for_each(p);
    else {
        p->had_error = 1;
        fprintf(stderr, "Unknown statement starting with '%.*s' at line %d\n",
                TOK(p).len, TOK(p).start, TOK(p).line);
        while (!stop_period_or_nl(p)) p->pos++;
        return NULL;
    }

    if (TOK(p).type == T_PUNCT) p->pos++;
    return s;
}

static Stmt** parse_program(Parser* p, int* out_n) {
    int cap = 32, n = 0;
    Stmt** prog = malloc(cap * sizeof(Stmt*));
    while (TOK(p).type != T_EOF) {
        /* skip any orphan punctuation (e.g. synthetic newlines) */
        while (TOK(p).type == T_PUNCT) p->pos++;
        if (TOK(p).type == T_EOF) break;
        Stmt* s = parse_stmt(p);
        if (s) {
            if (n >= cap) { cap *= 2; prog = realloc(prog, cap * sizeof(Stmt*)); }
            prog[n++] = s;
        }
    }
    *out_n = n;
    return prog;
}

/* ========================================================================
 * ENVIRONMENT
 * ====================================================================== */

typedef struct Binding {
    char* name;
    Value* val;
    struct Binding* next;
} Binding;

typedef struct Scope {
    Binding* head;
    struct Scope* parent;
} Scope;

static Scope* scope_new(Scope* parent) {
    Scope* s = calloc(1, sizeof(Scope));
    s->parent = parent;
    return s;
}

static void scope_free(Scope* s) {
    Binding* b = s->head;
    while (b) { Binding* n = b->next; free(b->name); v_free(b->val); free(b); b = n; }
    free(s);
}

static Value* scope_get(Scope* s, const char* name) {
    for (Scope* cur = s; cur; cur = cur->parent) {
        for (Binding* b = cur->head; b; b = b->next)
            if (strcasecmp(b->name, name) == 0) return b->val;
    }
    return NULL;
}

static void scope_set(Scope* s, const char* name, Value* v) {
    for (Binding* b = s->head; b; b = b->next)
        if (strcasecmp(b->name, name) == 0) { v_free(b->val); b->val = v; return; }
    Binding* b = calloc(1, sizeof(Binding));
    b->name = strdup(name);
    b->val = v;
    b->next = s->head;
    s->head = b;
}

/* ========================================================================
 * INTERPRETER
 * ====================================================================== */

static int g_had_runtime_error = 0;
static char* g_current_list = NULL;  /* "the list" refers to this */

static Value* eval_expr(Expr* e, Scope* env) {
    switch (e->type) {
        case E_NUM: return v_int(e->num);
        case E_STR: {
            /* "the list" -> current_list */
            if (strcmp(e->str, "list") == 0 && g_current_list) {
                Value* v = scope_get(env, g_current_list);
                if (v) return v_clone(v);
            }
            /* bare-word fallback: if a variable with this name exists, use it; else literal */
            Value* v = scope_get(env, e->str);
            if (v) return v_clone(v);
            return v_str(e->str);
        }
        case E_VAR: {
            Value* v = scope_get(env, e->str);
            if (!v) {
                fprintf(stderr, "Runtime error: undefined variable '%s'\n", e->str);
                g_had_runtime_error = 1;
                return v_nil();
            }
            return v_clone(v);
        }
    }
    return v_nil();
}

static void exec_stmt(Stmt* s, Scope* env) {
    if (!s) return;
    switch (s->type) {
        case S_OUTPUT: {
            for (int i = 0; i < s->out_exprs_n; i++) {
                Value* v = eval_expr(s->out_exprs[i], env);
                if (i) putchar(' ');
                char* out = v_to_str(v);
                fputs(out, stdout);
                free(out);
                v_free(v);
            }
            putchar('\n');
            break;
        }
        case S_SET: {
            Value* v = eval_expr(s->set_val, env);
            scope_set(env, s->set_name, v);
            break;
        }
        case S_CREATE: {
            scope_set(env, s->create_name, v_list());
            free(g_current_list);
            g_current_list = strdup(s->create_name);
            break;
        }
        case S_ADD: {
            const char* target = s->add_list;
            if (strcmp(target, "list") == 0 && g_current_list) target = g_current_list;
            Value* target_v = scope_get(env, target);
            if (!target_v) {
                fprintf(stderr, "Runtime error: '%s' is not defined\n", s->add_list);
                g_had_runtime_error = 1;
                break;
            }
            if (target_v->type == V_LIST) {
                for (int i = 0; i < s->add_vals_n; i++) {
                    Value* item = eval_expr(s->add_vals[i], env);
                    v_append(target_v, item);
                }
            } else if (target_v->type == V_INT) {
                for (int i = 0; i < s->add_vals_n; i++) {
                    Value* item = eval_expr(s->add_vals[i], env);
                    if (item->type == V_INT) {
                        target_v->int_v += item->int_v;
                    } else if (item->type == V_STRING) {
                        // try to parse string as int
                        char* end;
                        long v = strtol(item->str_v, &end, 10);
                        if (end != item->str_v) target_v->int_v += (int)v;
                    }
                    v_free(item);
                }
            } else {
                fprintf(stderr, "Runtime error: '%s' is not a list or number\n", s->add_list);
                g_had_runtime_error = 1;
            }
            break;
        }
        case S_FOR_EACH: {
            const char* target = s->fe_list;
            if (strcmp(target, "list") == 0 && g_current_list) target = g_current_list;
            Value* list = scope_get(env, target);
            if (!list || list->type != V_LIST) {
                fprintf(stderr, "Runtime error: '%s' is not a list\n", s->fe_list);
                g_had_runtime_error = 1;
                break;
            }
            Scope* inner = scope_new(env);
            for (int i = 0; i < list->list_len; i++) {
                scope_set(inner, s->fe_var, v_clone(list->list_v[i]));
                exec_stmt(s->fe_body, inner);
            }
            scope_free(inner);
            break;
        }
        case S_BLOCK:
            for (int i = 0; i < s->blk_n; i++) exec_stmt(s->blk[i], env);
            break;
    }
}

/* ========================================================================
 * MAIN
 * ====================================================================== */

static char* slurp_file(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "Cannot open %s: %s\n", path, strerror(errno)); return NULL; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    char* buf = malloc(n + 1);
    fread(buf, 1, n, f);
    buf[n] = 0;
    fclose(f);
    return buf;
}

static void run_source(const char* src, Scope* env) {
    int tc;
    Token* toks = lex(src, &tc);
    Parser p = { toks, tc, 0, 0 };
    int n = 0;
    Stmt** prog = parse_program(&p, &n);
    g_had_runtime_error = 0;
    for (int i = 0; i < n; i++) exec_stmt(prog[i], env);
    for (int i = 0; i < n; i++) s_free(prog[i]);
    free(prog);
    free(toks);
}

static void run_repl(void) {
    printf("ENGLISH-ELF %s - REPL mode (type 'exit' to quit)\n", ENGLISH_ELF_VERSION);
    Scope* env = scope_new(NULL);
    char line[4096];
    char accum[65536];
    accum[0] = 0;
    for (;;) {
        if (accum[0]) printf("... "); else printf("> ");
        fflush(stdout);
        if (!fgets(line, sizeof(line), stdin)) break;
        if (accum[0] == 0 && strncasecmp(line, "exit", 4) == 0) break;
        strncat(accum, line, sizeof(accum) - strlen(accum) - 1);
        int l = (int)strlen(accum);
        while (l > 0 && (accum[l-1] == ' ' || accum[l-1] == '\n' || accum[l-1] == '\r')) l--;
        if (l > 0 && accum[l-1] == '.') {
            run_source(accum, env);
            accum[0] = 0;
        }
    }
    scope_free(env);
}

static void print_usage(const char* prog) {
    fprintf(stderr, "ENGLISH-ELF %s - English Programming Language (Linux/C)\n", ENGLISH_ELF_VERSION);
    fprintf(stderr, "Usage: %s [options] <file.txt> [file2.txt ...]\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  --help, -h     Show this help\n");
    fprintf(stderr, "  --version, -v  Show version\n");
    fprintf(stderr, "  --repl, -i     Interactive REPL\n");
    fprintf(stderr, "  --verbose      Enable verbose lexicon loading\n");
    fprintf(stderr, "\nExamples:\n");
    fprintf(stderr, "  %s tests/test_simple.txt\n", prog);
    fprintf(stderr, "  %s --repl\n", prog);
    fprintf(stderr, "  %s examples/natural_examples.txt\n", prog);
}

int main(int argc, char** argv) {
    lex_load_with_fallback();

    int repl = 0;
    const char* file = NULL;
    int verbose = 0;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--repl") == 0 || strcmp(argv[i], "-i") == 0) repl = 1;
        else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) { print_usage(argv[0]); return 0; }
        else if (strcmp(argv[i], "--version") == 0 || strcmp(argv[i], "-v") == 0) { printf("ENGLISH-ELF %s\n", ENGLISH_ELF_VERSION); return 0; }
        else if (strcmp(argv[i], "--verbose") == 0) { verbose = 1; setenv("ENGLISH_ELF_VERBOSE", "1", 1); }
        else if (argv[i][0] != '-') file = argv[i];
        else if (argv[i][0] == '-') { fprintf(stderr, "Unknown option: %s\n", argv[i]); print_usage(argv[0]); return 1; }
    }
    (void)verbose;
    if (repl && !file) {
        run_repl();
        return 0;
    }
    if (!file) {
        print_usage(argv[0]);
        return 1;
    }
    char* src = slurp_file(file);
    if (!src) return 1;
    Scope* env = scope_new(NULL);
    run_source(src, env);
    scope_free(env);
    free(src);
    return g_had_runtime_error ? 1 : 0;
}
