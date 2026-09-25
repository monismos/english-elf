# ENGLISH-ELF Production Roadmap

## Status: v0.5.0-alpha Shipped (Linux/C) ✅ | Assembly Deferred ⏳

### Completed Architecture (Sept 2026 - Linux/C Priority)

| Component | File | Status |
|-----------|------|--------|
| Grammar Spec | docs/GRAMMAR.md | ✅ v1.0 Natural English (spec) |
| C Interpreter | src/english-elf.c | ✅ **Shipped** (Linux, 13/13 tests) |
| Limitations | docs/LIMITATIONS.md | ✅ v0.5 support matrix |
| Build | Makefile | ✅ gcc or zig cc auto-detect |
| Tests | tests/test_*.txt + *.expected | ✅ 13 supported, 3 future |
| Lexer (C) | src/english-elf.c:lex | ✅ |
| Parser (C) | src/english-elf.c:parse | ✅ (5 stmt types) |
| Lexer (ASM) | src/asm/lexer.asm | ⏳ functional but debug spam |
| Parser (ASM) | src/asm/parser.asm | ⏳ 30+ keywords, stubs |
| Codegen | src/asm/codegen.asm | ⏳ Stub |
| Runtime | src/asm/runtime.asm | ⏳ Windows VirtualAlloc |
| ELF Gen | src/asm/elfgen.asm | ⏳ Stub |
| Main Entry | src/asm/elf_main.asm | ⏳ Stub |
| GenZ Lexicon | src/lexicon/slang/genz.tsv | ⏳ Future |
| Gaming Lexicon | src/lexicon/slang/gaming.tsv | ⏳ Future |
| Twitter Lexicon | src/lexicon/slang/twitter.tsv | ⏳ Future |
| Examples | examples/natural_examples.txt | ⏳ Mix of supported/future |
| Version | VERSION | ✅ 0.5.0-alpha |

## Next Steps (v0.5 Onwards)

### Milestone 1: Working Interpreter (Shipped v0.5 - Linux/C)
- [x] Complete lexer token emission (C)
- [x] Complete parser statement parsing (C)
- [x] Add expression evaluation (C)
- [x] Implement output statement (C)
- [x] Implement set statement (C, with comma handling)
- [x] Implement create/add/list statements (C, with int addition)

### Milestone 2: Conditionals & Loops (1 month)
- [ ] Natural conditionals (`if`, `unless`, `when`)
- [ ] Comparison operators (at most, at least, etc.)
- [ ] While loops
- [ ] For loops

### Milestone 3: Functions (2 weeks)
- [ ] Function definition syntax
- [ ] Function calls
- [ ] Return statements
- [ ] Nested scopes

### Milestone 4: Self-Hosting (2 weeks)
- [ ] Working ELF generator
- [ ] Compile C interpreter to assembly
- [ ] Bootstrap: compile compiler with itself

### Milestone 5: Standard Library (Ongoing)
- [ ] File I/O (`read file`, `write to file`)
- [ ] HTTP (`get web page`, `post to api`)
- [ ] Math (`sum of`, `product of`)
- [ ] Collections (`filter`, `transform`)

## Language Features Implemented (v0.5)

### Output ✅ (C)
```
Say hello.
Print greeting.
Shout result.
```
Test: `test_hello.txt`, `test_variations.txt`

### Variables ✅ (C)
```
Set x to 5.
Let name be Alice.
Set greeting to Hello, friend.  # -> "hello friend" (comma handled)
```
Test: `test_variables.txt`

### Lists ✅ (C)
```
Create a list named items.
Add one, two, and three to items.
For each item in items, say item.
Add 1 to total.  # if total is int, does integer addition
```
Test: `test_create_list.txt`, `test_fib.txt`, `test_function.txt`

### Natural Interpolation ⏳ Future
```
Set greeting to Hello, name.  # "Hello, " + variable name (not yet interpolated, stored as literal)
```
Planned for v0.6

### GenZ Slang ⏳ Future
```
Bet.        # confirm (future)
Facts.      # true
No cap.     # honestly
Slay.       # success
```
In `tests/future/test_loops.txt`, assembly has keywords

## Assembly Instructions (x86-64)

The compiler emits these opcodes:
- `0x48 0xB8` - mov rax, imm64
- `0xFF 0xD0` - call rax
- `0xC3` - ret
- `0x0F 0x05` - syscall

## Build Commands (v0.5)

```bash
make            # Build C interpreter (Linux, gcc or zig cc)
make c          # same
make test       # Run golden-file tests (13 supported)
make test-future # Show future tests (if/while/slang)
make repl       # REPL
make asm        # Build ELF assembly compiler (deferred, requires nasm)
make info       # Project info
make help       # Help
```

## File Extensions

- Source: `.txt` (always)
- Assembly: `.asm` (Windows, deferred)
- C: `src/english-elf.c` (Linux official)
- Binary: `build/english-elf-c` (ELF, no extension) or `build/english.exe` (Windows PE)

## Philosophy (v0.5)

ENGLISH-ELF v0.5 ships the C interpreter on Linux (pragmatic, working subset). Assembly JIT/self-hosting remains the long-term vision but is deferred to v0.6+ (see PRODUCTION_PLAN.md Phase 2). The C path proves the language design; the assembly path will later compile it to native ELF.