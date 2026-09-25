# ENGLISH-ELF Build System - Linux/C Priority (v0.5.0-alpha)
# Default target is the C interpreter (Linux native). Assembly/Windows targets are deferred.
# Usage:
#   make        # build C interpreter (Linux)
#   make c      # same
#   make test   # build + run golden-file tests
#   make repl   # run REPL
#   make asm    # try building ELF assembly compiler (requires nasm, will warn if missing)

VERSION ?= $(shell cat VERSION 2>/dev/null || echo "0.5.0-alpha")
C_TARGET  = build/english-elf-c
C_SRC     = src/english-elf.c
DICT      = data/words.txt

# Compiler detection: prefer gcc, fallback to zig cc (for flatpak/sandbox)
C_CC      ?= gcc
ZIG       ?= /tmp/opencode/zig/zig
ifeq ($(shell which $(C_CC) 2>/dev/null),)
  ifneq ($(shell test -x $(ZIG) && echo yes),)
    C_CC = $(ZIG) cc
    $(info gcc not found, using $(ZIG) cc)
  else
    $(warning gcc not found and zig not at $(ZIG); build may fail. Install gcc or download zig to $(ZIG))
  endif
endif
C_CFLAGS  ?= -O2 -Wall -Wextra -g
C_LDFLAGS ?=

# Assembly (deferred) - Windows/ELF
ASM       ?= nasm
ASMFLAGS  ?= -f elf64 -g -F dwarf
LD        ?= ld
LDFLAGS   ?= -static -o
ASM_TARGET = build/english-elf
ASM_OBJS   = build/elf_main.o build/lexer.o build/parser.o build/codegen.o build/runtime.o build/elfgen.o

.PHONY: all c asm clean test test-c test-asm bootstrap repl help info size docs format lint

all: c

c: $(C_TARGET)

asm: $(ASM_TARGET)

$(ASM_TARGET): $(ASM_OBJS)
	@mkdir -p build
	$(LD) $(LDFLAGS) $@ $(ASM_OBJS)
	@echo "ELF assembly compiler built: $@ (experimental, Windows runtime is still primary)"

build/lexer.o: src/asm/lexer.asm
	@mkdir -p build
	$(ASM) $(ASMFLAGS) -o $@ $<

build/parser.o: src/asm/parser.asm
	@mkdir -p build
	$(ASM) $(ASMFLAGS) -o $@ $<

build/codegen.o: src/asm/codegen.asm
	@mkdir -p build
	$(ASM) $(ASMFLAGS) -o $@ $<

build/runtime.o: src/asm/runtime.asm
	@mkdir -p build
	$(ASM) $(ASMFLAGS) -o $@ $<

build/elfgen.o: src/asm/elfgen.asm
	@mkdir -p build
	$(ASM) $(ASMFLAGS) -o $@ $<

build/elf_main.o: src/asm/elf_main.asm
	@mkdir -p build
	$(ASM) $(ASMFLAGS) -o $@ $<

# C interpreter
$(C_TARGET): $(C_SRC) $(DICT)
	@mkdir -p build
	$(C_CC) $(C_CFLAGS) -o $@ $< $(C_LDFLAGS)
	@echo "Built $(C_TARGET) ($(VERSION)) with $(C_CC)"

# Dictionary: keep committed file, only generate if missing and source dict exists
$(DICT):
	@if [ -f "$@" ]; then echo "Dictionary $@ already exists"; else \
	if [ -f /usr/share/dict/cracklib-small ]; then \
		echo "Building $@ from /usr/share/dict/cracklib-small"; \
		grep -E '^[a-zA-Z]+$$' /usr/share/dict/cracklib-small | tr 'A-Z' 'a-z' | sort -u > $@; \
	else \
		echo "No system dictionary found; creating empty lexicon at $@ (C interpreter will run without it)"; \
		mkdir -p $(dir $@); touch $@; \
	fi; fi

# Test: golden-file diff harness (13 supported tests, 3 future skipped)
test-c: $(C_TARGET)
	@echo "=== Testing C interpreter against golden files ==="
	@PASS=0; FAIL=0; SKIP=0; \
	for t in tests/test_*.txt; do \
		base=$$(basename $$t .txt); \
		expected="$$t.expected"; \
		if [ ! -f "$$expected" ]; then echo "SKIP $$t (no expected)"; SKIP=$$((SKIP+1)); continue; fi; \
		out=$$(./$(C_TARGET) $$t 2>&1); status=$$?; \
		expected_out=$$(cat "$$expected"); \
		if [ "$$out" = "$$expected_out" ] && [ $$status -eq 0 ]; then \
			echo "PASS $$t"; PASS=$$((PASS+1)); \
		else \
			echo "FAIL $$t (exit $$status)"; \
			echo "  expected:"; cat "$$expected" | sed 's/^/    /'; \
			echo "  got:"; echo "$$out" | sed 's/^/    /'; \
			FAIL=$$((FAIL+1)); \
		fi; \
	done; \
	echo "---"; echo "Results: $$PASS passed, $$FAIL failed, $$SKIP skipped"; \
	if [ -d tests/future ]; then echo "Note: $$(ls tests/future/*.txt 2>/dev/null | wc -l) future tests skipped in tests/future/ (unsupported: if/while/slang)"; fi; \
	test $$FAIL -eq 0

test-asm: $(ASM_TARGET)
	@echo "=== Testing Assembly compiler (deferred) ==="
	@./$(ASM_TARGET) tests/test_simple.txt 2>&1 || echo "Assembly compiler stub - not fully implemented (expected for v0.5 Linux/C priority)"
	@echo "See PRODUCTION_PLAN.md Phase 2 for assembly roadmap"

test: c
	@$(MAKE) test-c

# Also run quick sanity for future tests (expected to fail, just show)
test-future: $(C_TARGET)
	@echo "=== Future tests (expected failures) ==="
	@for t in tests/future/*.txt; do [ -f "$$t" ] || continue; echo "--- $$t (future, expect Unknown) ---"; ./$(C_TARGET) $$t 2>&1 | head -20; echo; done

repl: $(C_TARGET) $(DICT)
	./$(C_TARGET) --repl

help:
	@echo "ENGLISH-ELF $(VERSION) - Linux/C Build System"
	@echo "  make          Build C interpreter (Linux native, recommended)"
	@echo "  make c        Same"
	@echo "  make test     Build and run golden-file tests (13 supported)"
	@echo "  make test-c   Run C tests only"
	@echo "  make test-future Show future tests (if/while/slang - not yet implemented)"
	@echo "  make repl     Run REPL"
	@echo "  make clean    Remove build artifacts"
	@echo "  make asm      Build ELF assembly compiler (experimental, requires nasm)"
	@echo "  make info     Show project info"
	@echo "  make help     This help"

clean:
	rm -f $(C_TARGET) $(ASM_TARGET) $(ASM_OBJS)
	rm -f build/*.o build/*.obj build/*.lib
	rm -rf build

format:
	@echo "Formatting English source files..."
	@ls tests/*.txt examples/*.txt 2>&1 | head -20
	@echo "No auto-formatter configured (English is natural language)"

lint:
	@echo "Linting C source..."
	@if which clang-tidy >/dev/null 2>&1; then clang-tidy $(C_SRC) -- $(C_CFLAGS); else echo "clang-tidy not found, running basic checks"; $(C_CC) -fsyntax-only $(C_CFLAGS) $(C_SRC) && echo "Syntax OK"; fi
	@echo "Linting assembly (basic)..."
	@ls src/asm/*.asm 2>&1 | head -20

size: c
	@ls -lh $(C_TARGET) 2>&1
	@size $(C_TARGET) 2>&1 || wc -c $(C_TARGET)

info:
	@echo "ENGLISH-ELF Build Info ($(VERSION))"
	@echo "==================="
	@echo "Version: $(VERSION) (see VERSION file)"
	@echo "C compiler: $(C_CC) ($(shell $(C_CC) --version 2>&1 | head -1))"
	@echo "Assembly: $(ASM) ($(shell $(ASM) -v 2>&1 | head -1 || echo 'not found'))"
	@echo "Source files: $$(ls src/asm/*.asm 2>/dev/null | wc -l) asm, $$(wc -l < $(C_SRC)) lines C"
	@echo "Lexicon files: $$(ls src/lexicon/*.tsv src/lexicon/*/*.tsv 2>/dev/null | wc -l)"
	@echo "Test files: $$(ls tests/test_*.txt 2>/dev/null | wc -l) supported, $$(ls tests/future/*.txt 2>/dev/null | wc -l) future"
	@echo "Build target: $(C_TARGET)"
	@echo "Dictionary: $(DICT) ($$(wc -l < $(DICT) 2>/dev/null || echo 0) words)"
	@echo "Docs: docs/GRAMMAR.md, docs/ASSEMBLY_CONTRIBUTING.md (assembly deferred)"
