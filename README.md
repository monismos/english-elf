# ENGLISH-ELF v0.5.0-alpha (Linux/C)

English Programming Language - Natural English as Code.
Linux native via C interpreter (official). Windows NASM runtime is experimental/deferred.

## Quickstart (Linux - Recommended)

```bash
# Build C interpreter (requires gcc, or zig cc fallback is auto-detected)
make
./build/english-elf-c tests/test_simple.txt
# -> 5

# Run REPL
./build/english-elf-c --repl
# ENGLISH-ELF 0.5.0-alpha (Linux/C) - REPL mode
# > Say hello world.
# hello world

# Run all supported tests (golden-file harness)
make test
# PASS 13, FAIL 0
```

Requires `gcc` (or `zig cc` fallback at `/tmp/opencode/zig/zig` for sandboxed builds).
`data/words.txt` is optional (C runs without it; use `ENGLISH_ELF_VERBOSE=1` to see lexicon loading).

## Build - Windows (Experimental)

Windows NASM runtime is deferred for v0.5. Use at your own risk:

```bat
build.bat
```

Linux/macOS cross-compile to Windows PE:
```bash
build.sh
# requires nasm + lld-link
```

## Usage

Linux (C):
```bash
./build/english-elf-c program.txt
./build/english-elf-c --help
./build/english-elf-c --version
./build/english-elf-c --repl
```

Windows (experimental):
```bat
english.exe program.txt
english.exe --repl
```

## English Syntax

Output:
```
Say hello world.
Print greeting.
Display x, y, and z.
```

Variables:
```
Set x to 5.
Let name be Alice.
Make greeting equal Hello, friend.
```

Lists:
```
Create a list named numbers.
Add 1, 2, 3, and 4 to numbers.
```

Conditionals:
```
If x is greater than 5, say x is big.
Unless x is negative, say positive.
```

Loops:
```
While x is less than 10:
    Display x.
Done.
```

Functions:
```
To check if n is even:
    If n divided by 2 equals 0, say yeah.
    Say nah.
Finish.
```

GenZ Slang:
```
Bet.         # Confirm
Facts.       # True
No cap.      # Honestly
Slay.        # Success
```

## Architecture

```
Source .txt
    |
    v
+-----------------------+
| Lexer (word tokenizer)|
+--------+--------------+
         |
         v
+--------+--------------+
| Parser (English grammar)|
+--------+--------------+
         |
         v
+--------+--------------+
| JIT Code Generator    |
| (x86-64 machine code) |
+--------+--------------+
         |
         v
+--------+--------------+
| Executable JIT Buffer |
| (VirtualAlloc RWX)    |
+--------+--------------+
         |
         v
    [EXECUTE]
```

## Current Support (v0.5 Linux/C)

| Feature | Example | Status |
|---------|---------|--------|
| Output | `Say hello world.` `Print x.` | ✅ |
| Variables | `Set x to 5.` `Let name be Alice.` | ✅ (also `Hello, friend.` comma handling) |
| Lists | `Create a list named numbers.` `Add 1, 2, 3 to numbers.` | ✅ |
| For-each | `For each n in numbers, say n.` | ✅ |
| Add to int | `Add 1 to total.` (where total is int) | ✅ (v0.5 extension) |
| Conditionals | `If x is greater than 5, say big.` | ⏳ future (`tests/future/`) |
| While/Repeat | `While x is less than 10:` | ⏳ future |
| Functions | `To calculate double of n:` | ⏳ future |
| GenZ Slang | `Bet.` `Facts.` | ⏳ future |

See `docs/GRAMMAR.md` for full spec, `docs/LIMITATIONS.md` for v0.5 matrix, and `tests/future/` for deferred tests.

## Files

| File | Purpose |
|------|---------|
| `src/english-elf.c` | **C interpreter (Linux official, 900 lines)** |
| `src/asm/english.asm` | Windows PE entry (deferred, experimental) |
| `src/asm/runtime.asm` | Memory, string ops, I/O (Windows) |
| `src/asm/lexer.asm` | Tokenizer (Windows) |
| `src/asm/parser.asm` | English grammar parser (Windows, 2672 lines) |
| `src/asm/codegen.asm` | x86-64 opcode emitter (stub) |
| `src/asm/codegen2.asm` | Statement JIT emitter (stub) |
| `src/asm/win32.inc` | Windows constants & helpers |
| `src/lexicon/words.tsv` | 50+ English keywords |
| `tests/*.txt` | 13 supported tests + `*.expected` golden files |
| `tests/future/*.txt` | 3 deferred tests (if/while/slang) |

## Architecture

```
Source .txt
    |
    v
+-----------------------+
| Lexer (word tokenizer)|
+--------+--------------+
         |
         v
+--------+--------------+
| Parser (English grammar)|
+--------+--------------+
         |
         v (v0.5: direct interpreter)
+-----------------------+
| Interpreter (C)       |  <-- Linux official: src/english-elf.c
| Scope + Value + Exec  |
+--------+--------------+
         |
         v
      [EXECUTE] (print to stdout)

Future (Windows JIT, deferred):
  Parser -> JIT Code Generator (x86-64) -> VirtualAlloc RWX -> EXECUTE
  See PRODUCTION_PLAN.md Phase 2
```

## Philosophy

1. **Pure Natural English** - No code-like syntax
2. **Direct Execution** - Source .txt is parsed and executed (no IR in v0.5; JIT deferred)
3. **Linux First** - C interpreter is the shipping runtime (v0.5); assembly self-hosting is future
4. **Pragmatic** - Ship working subset, iterate (see ROADMAP.md)
5. **Natural** - Articles `a/an/the` skipped, `and`/`comma` handled, case-insensitive

## License
MIT