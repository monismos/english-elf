# ENGLISH-ELF v0.5 Limitations (Linux/C)

This document tracks what works in the shipping Linux/C interpreter (`src/english-elf.c`) vs the full grammar spec (`docs/GRAMMAR.md`) and Windows assembly interpreter (`src/asm/`).

## Supported in v0.5 (Linux/C) - 13 tests passing

### Output (9 verbs)
`say`, `tell`, `print`, `shout`, `display`, `output`, `speak`, `announce`, `yell`
```
Say hello world.
Print x.
Display x, y, and z.
```
Test: `tests/test_hello.txt`, `test_say.txt`, `test_variations.txt`, `test_simple.txt`

### Variables
`Set <name> to <expr>.` `Let <name> be <expr>.` (also `Make/Give/Assign` mapped in assembly only)
```
Set x to 5.
Let name be Alice.
Set greeting to Hello, friend.   # comma is treated as space -> "hello friend" (new in 0.5)
```
Test: `tests/test_variables.txt`, `test_count.txt`, `test_loop.txt`
Note: `Hello, friend.` with comma now correctly joins to `hello friend` (lowercased). Previously failed with `Unknown statement starting with 'friend'`.

### Lists
`Create/Make/Define a list named <name>.` `Add/Append/Put/Insert <value> to <list>.`
```
Create a list named numbers.
Add 1, 2, 3, and 4 to numbers.
Display the list.   # -> [2, 3, 5, 7] etc
```
Test: `tests/test_create_list.txt`, `test_fib.txt`
Also: `Add 1 to total.` where `total` is an int does integer addition (v0.5 extension for `tests/test_function.txt` -> 6)

### For-each
`For each <var> in <list>, <body>.` `For every <var> in <list>, <body>.`
```
For each n in numbers, say n.
```
Test: `tests/test_for_each.txt`, `test_for_each2.txt`, `test_fib.txt`
Articles `a/an/the` are silently skipped.

## Unsupported in v0.5 (deferred to future, see `tests/future/`)

| Feature | Example | Status | Location |
|---------|---------|--------|----------|
| Conditionals | `If x is greater than 5, say big.` `Unless x is negative, say positive.` `When ...` | ⏳ | `tests/future/test_conditional.txt`, `test_conditionals.txt` |
| While/Until/Repeat | `While x is less than 10:` `Repeat 3 times:` `Done.` | ⏳ | `tests/future/test_loops.txt` |
| Functions | `To calculate double of n:` `Return n times 2.` `Finish.` `Call ...` | ⏳ | Not in tests yet, see `docs/GRAMMAR.md:142` |
| Break/Continue/Stop | `Stop.` `Break.` `Continue.` | ⏳ | Assembly only stub |
| GenZ slang | `Bet.` `Facts.` `Slay.` `Sheesh.` `No cap.` | ⏳ | Assembly parser has keywords but C lacks |
| Natural actions | `Greet name.` `Hello world.` `Goodbye.` `Welcome.` | ⏳ | Assembly only |
| File I/O | `Read file "path" into x.` `Write ... to file` | ⏳ | `docs/GRAMMAR.md:269` |
| HTTP/Math | `Get webpage`, `Sum of` | ⏳ | Future |

For these, the C interpreter prints `Unknown statement starting with 'If'` and exits 0 (not yet error). They are quarantined in `tests/future/` so `make test` stays green. Assembly parser (`src/asm/parser.asm:138-260`) dispatches 30+ keywords including these, but its runtime has debug spam and stack bugs; it is deferred for v0.6+.

## Known Quirks in v0.5

- `Print greeting name.` without comma/`and` is treated as single phrase `"greeting name"` literal, not two variables. Use `Print greeting, name.` or `Print greeting and name.` for two values, or `Print greeting.` + `Print name.` separately. See `tests/test_natural.txt.expected` -> `greeting name` literal.
- Variables are case-insensitive, lowercased. `Set greeting to Hello, friend.` stores `"hello friend"`.
- Lists: `the list` refers to most recent created list (`g_current_list`).
- `data/words.txt` is optional: if missing, interpreter runs without lexicon (only hardcoded English keywords). Set `ENGLISH_ELF_VERBOSE=1` to see loading.
- Strings: quoted `"..."` supported but not interpolated; `123` numbers supported.

## Version Matrix

- **v0.5.0-alpha (current)**: Linux/C shipping, 5 statement types, 13/13 tests pass.
- **v0.6 (planned)**: Add `if/unless/when` with comparisons (`is at most`, `greater than` etc) to C.
- **v1.0 (future)**: Windows assembly JIT, self-hosting, full grammar + slang.

See `ROADMAP.md` and `PRODUCTION_PLAN.md` for milestones.
