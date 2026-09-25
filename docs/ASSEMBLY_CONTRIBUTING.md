# Contributing to ENGLISH-ELF Assembly (Deferred for v0.5)

> **Note for v0.5**: Assembly (Windows NASM, `src/asm/`) is **deferred**. Linux/C (`src/english-elf.c`) is the official shipping runtime. This doc is kept for future work (v0.6+). Expect debug spam and stack bugs if you build `make asm` today; use `make c` instead.

# Contributing to ENGLISH-ELF Assembly

## Assembly Structure

```
src/asm/
├── elf_main.asm      # ELF entry point (_start)
├── lexer.asm         # Tokenization (WORD, NUMBER, STRING, PUNCT, EOF)
├── parser.asm        # AST parsing
├── codegen.asm       # Machine code generation
├── runtime.asm       # Runtime helpers (print, malloc, etc.)
├── elfgen.asm        # ELF binary writer
└── lexicon.asm       # Word lookup and semantic categories
```

## Writing Assembly for ENGLISH-ELF

### Calling Convention
- Linux x86-64 syscall convention
- Use `rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9` for args
- Return values in `rax`
- Caller-saved registers: rax, rcx, rdx, rsi, rdi, r8-r11
- Callee-saved: rbx, rbp, r12-r15

### Memory Layout
- Use malloc/free for dynamic allocation (from libc)
- Token buffer: 32 bytes per token
- Statement buffer: 64 bytes header + variable data

### Code Generation
- Emit machine code to code_buffer
- Use x86-64 opcodes directly
- For output: use sys_write (1) syscall

## Testing Assembly

```bash
make asm
./build/english-elf tests/test_simple.txt
```

## Self-Hosting Goal

The assembly compiler compiles itself:
1. Write `src/asm/*.asm` in assembly
2. Compile tests with C interpreter
3. Compile assembly to ELF binary
4. Later: use compiled assembly to compile itself

## Lexicon Format

TSV format: `word|pos|category|notes`

Categories: OUTPUT, SET, LIST, LOOP, CONTROL, FUNCTION, COMPARE, etc.

## Debugging

Use `objdump -d build/english-elf` to see generated assembly.
Use `readelf -a build/english-elf` to see ELF structure.