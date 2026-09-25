#include "arena.h"
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

#define DEFAULT_ARENA_SIZE (1024 * 1024)

Arena* arena_new(size_t capacity) {
    if (capacity == 0) capacity = DEFAULT_ARENA_SIZE;
    Arena* a = mmap(NULL, sizeof(Arena), PROT_READ | PROT_WRITE,
                    MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (a == MAP_FAILED) return NULL;
    
    a->base = mmap(NULL, capacity, PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (a->base == MAP_FAILED) {
        munmap(a, sizeof(Arena));
        return NULL;
    }
    a->ptr = a->base;
    a->capacity = capacity;
    a->used = 0;
    a->next = NULL;
    return a;
}

void arena_free(Arena* a) {
    while (a) {
        Arena* next = a->next;
        if (a->base) munmap(a->base, a->capacity);
        munmap(a, sizeof(Arena));
        a = next;
    }
}

static void* arena_grow(Arena* a, size_t size) {
    size_t new_cap = a->capacity * 2;
    while (new_cap < a->used + size) new_cap *= 2;
    
    uint8_t* new_base = mmap(NULL, new_cap, PROT_READ | PROT_WRITE,
                             MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (new_base == MAP_FAILED) return NULL;
    
    memcpy(new_base, a->base, a->used);
    munmap(a->base, a->capacity);
    a->base = new_base;
    a->ptr = new_base + a->used;
    a->capacity = new_cap;
    return a->ptr;
}

void* arena_alloc(Arena* a, size_t size) {
    size = (size + 7) & ~7;
    if (a->used + size > a->capacity) {
        if (!arena_grow(a, size)) return NULL;
    }
    void* ptr = a->ptr;
    a->ptr += size;
    a->used += size;
    return ptr;
}

void* arena_calloc(Arena* a, size_t count, size_t size) {
    size_t total = count * size;
    void* ptr = arena_alloc(a, total);
    if (ptr) memset(ptr, 0, total);
    return ptr;
}

char* arena_strdup(Arena* a, const char* s) {
    if (!s) return NULL;
    size_t len = strlen(s);
    char* dup = arena_alloc(a, len + 1);
    if (dup) {
        memcpy(dup, s, len);
        dup[len] = '\0';
    }
    return dup;
}

char* arena_strndup(Arena* a, const char* s, size_t n) {
    if (!s) return NULL;
    char* dup = arena_alloc(a, n + 1);
    if (dup) {
        memcpy(dup, s, n);
        dup[n] = '\0';
    }
    return dup;
}

void arena_reset(Arena* a) {
    a->ptr = a->base;
    a->used = 0;
}