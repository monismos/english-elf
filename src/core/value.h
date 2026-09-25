#ifndef VALUE_H
#define VALUE_H

#include "arena.h"

typedef enum {
    V_NIL,
    V_BOOL,
    V_INT,
    V_FLOAT,
    V_STRING,
    V_LIST,
    V_DICT,
    V_FUNC
} VType;

typedef struct Value Value;

typedef struct List {
    Value** items;
    size_t len;
    size_t cap;
} List;

typedef struct Dict {
    char** keys;
    Value** values;
    size_t len;
    size_t cap;
} Dict;

typedef struct Func {
    char* name;
    char** params;
    size_t param_count;
    struct Stmt* body;
    struct Scope* closure;
} Func;

struct Value {
    VType type;
    union {
        int bool_v;
        int64_t int_v;
        double float_v;
        char* str_v;
        List* list_v;
        Dict* dict_v;
        Func* func_v;
    };
};

Value* v_nil(Arena* a);
Value* v_bool(Arena* a, int b);
Value* v_int(Arena* a, int64_t i);
Value* v_float(Arena* a, double f);
Value* v_str(Arena* a, const char* s);
Value* v_strn(Arena* a, const char* s, size_t n);
Value* v_list(Arena* a);
Value* v_dict(Arena* a);
Value* v_func(Arena* a, const char* name, char** params, size_t pc, struct Stmt* body, struct Scope* closure);

void list_push(Arena* a, List* l, Value* v);
Value* list_get(List* l, size_t i);
int list_len(List* l);

int dict_set(Arena* a, Dict* d, const char* key, Value* v);
Value* dict_get(Dict* d, const char* key);

Value* v_clone(Arena* a, Value* v);
int v_is_truthy(Value* v);
int v_equal(Value* a, Value* b);
char* v_to_str(Arena* a, Value* v);

int v_as_int(Value* v);
double v_as_float(Value* v);
const char* v_as_str(Value* v);

#endif