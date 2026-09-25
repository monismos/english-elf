# ENGLISH-ELF Production Plan

## Completed Foundation (v0.5.0-alpha - Linux/C)

### 1. Architecture Documentation
- `docs/GRAMMAR.md` - Complete BNF grammar specification
- `docs/ASSEMBLY_CONTRIBUTING.md` - Assembly development guide (deferred)
- `docs/TESTING.md` - Test file format
- `docs/LIMITATIONS.md` - v0.5 support matrix (new)
- `ROADMAP.md` - Development milestones (updated for Linux priority)
- `VERSION` - 0.5.0-alpha

### 2. C Interpreter (Shipped - Linux Priority)
- `src/english-elf.c` (913 lines) - Stable interpreter: Output, Set/Let, Create, Add (list+int), For-each
- Fixes: comma handling `Hello, friend.` -> `hello friend`, `Add to int` integer addition, `--help/--version`, lexicon fallback
- Build: `make` auto-detects `gcc` or `zig cc` (flatpak)
- Tests: 13/13 passing with golden files (`tests/*.expected`), 3 deferred in `tests/future/`

### 3. Assembly Compiler (Deferred - Experimental)
- `src/asm/elf_main.asm` - ELF entry point (_start) - stub
- `src/asm/lexer.asm` - Tokenizer with natural word blending - functional but with debug spam
- `src/asm/parser.asm` - AST statement parser - dispatches 30+ keywords but many stubs
- `src/asm/codegen.asm` - Machine code emitter (stub)
- `src/asm/runtime.asm` - Runtime helpers (Win32 VirtualAlloc RWX)
- `src/asm/elfgen.asm` - ELF header generator - stub
- Status: Not built by default (`make` builds C only). See `make asm` and `docs/ASSEMBLY_CONTRIBUTING.md` (deferred to v0.6+)

### 4. Lexicon
- `src/lexicon/words.tsv` - Base word categories (50+)
- `src/lexicon/ordinals.tsv` - Ordinal numbers
- `src/lexicon/slang/genz.tsv` - GenZ affirmations/negations (future)
- `src/lexicon/slang/gaming.tsv` - Gaming terminology (future)
- `src/lexicon/slang/twitter.tsv` - Twitter/X terminology (future)
- `data/words.txt` (441KB, 50692 words) - optional, auto-loaded with fallback

### 5. Natural English Features (v0.5)
- ✅ `Set greeting to Hello, friend.` (comma handled, lowercased)
- ✅ `Add 1 to total.` where total is int (integer addition)
- ⏳ GenZ slang: `Bet.`, `Facts.`, `No cap.`, `Slay.` (future)
- ⏳ Natural actions: `Greet name.`, `Welcome everyone.` (future)

## Implementation Priorities

### Phase 1: Working Assembly Compiler (2-3 weeks)
1. Fix lexer token emission (complete token structures)
2. Fix parser statement parsing (complete AST nodes)
3. Implement expression evaluation
4. Generate working ELF with syscalls

### Phase 2: Missing Language Features (1 month)
1. Conditionals: `if`, `unless`, `when`
2. Comparisons: `at most`, `at least`, `greater than`, `less than`
3. While loops: `While condition:`, `Repeat N times:`
4. Functions: `To calculate name:`, `Return value.`

### Phase 3: Self-Hosting (2 weeks)
1. Working ELF generator
2. Compile assembly to ELF
3. Bootstrap: use assembly compiler to compile English source

### Phase 4: Standard Library (Ongoing)
1. File I/O: `Read file`, `Write to file`
2. HTTP: `Get webpage`, `Post to api`, `Listen on port`
3. JSON: `Parse JSON`, `Stringify`
4. Math: `Sum of`, `Product of`, `Square root of`

## Code Statistics

| File | Lines | Purpose |
|------|-------|---------|
| src/asm/elf_main.asm | ~100 | Entry point |
| src/asm/lexer.asm | ~250 | Tokenizer |
| src/asm/parser.asm | ~200 | Parser |
| src/asm/codegen.asm | ~120 | Code generation |
| src/asm/runtime.asm | ~100 | Runtime |
| src/asm/elfgen.asm | ~150 | ELF writer |
| **Total Assembly** | ~820 | Foundation |

## Testing (v0.5)

```
tests/test_*.txt           - 13 supported tests (output, variables, lists, for-each)
tests/test_*.txt.expected  - golden files for diff harness
tests/future/*.txt         - 3 deferred tests (if/while/slang)
tests/test_simple.txt      - Basic output/variables
tests/test_natural.txt     - Natural syntax examples
```

## Build Commands (v0.5 Linux Priority)

```sh
make        # Build C interpreter (Linux, auto-detects gcc or zig cc)
make c      # same
make test   # Build + run golden-file tests (13 PASS expected)
make repl   # Run REPL
make asm    # Build ELF compiler (experimental, requires nasm)
make info   # Show project statistics
make help   # Show help
```

## Next Actions (v0.6)

1. **Add conditionals to C** - `if/unless/when` with comparisons (`is at most`, `greater than` etc)
2. **Complete lexer.asm** - Fix debug spam, add include guards
3. **Complete parser.asm** - Fix stack bugs, wire break/continue
4. **Complete codegen.asm** - Generate real machine code or remove JIT claim
5. **Add strcmp** - Already have sstr_eq_ci but remove debug prints
6. **Test assembly build** - Ensure it compiles without debug spam
7. **Implement while/repeat** - Grammar already documented

## Success Criteria

### v0.5 (Shipped - Linux/C)
- [x] C interpreter builds with gcc or zig cc
- [x] 13/13 supported tests pass (golden files)
- [x] CLI --help/--version, REPL, lexicon fallback
- [x] Docs accurate (README, LIMITATIONS, Makefile help)
- [x] No debug spam on Linux path

### Future (v0.6+)
- [ ] Add conditionals to C
- [ ] Assembly compiler builds without errors (remove debug prints)
- [ ] Outputs valid ELF binaries
- [ ] Self-hosting achieved (deferred)
- [ ] All v0.1 features working in assembly