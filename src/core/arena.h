#ifndef ARENA_H
#define ARENA_H

#include <stddef.h>
#include <stdint.h>

typedef struct Arena {
    uint8_t* base;
    uint8_t* ptr;
    size_t capacity;
    size_t used;
    struct Arena* next;
} Arena;

Arena* arena_new(size_t capacity);
void arena_free(Arena* a);
void* arena_alloc(Arena* a, size_t size);
void* arena_calloc(Arena* a, size_t count, size_t size);
char* arena_strdup(Arena* a, const char* s);
char* arena_strndup(Arena* a, const char* s, size_t n);
void arena_reset(Arena* a);

#endif