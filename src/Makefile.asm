# ENGLISH-ELF Assembly Build System
# Builds ELF-binary compiler and runtime

ASM = nasm
ASMFLAGS = -f elf64
LD = ld
LDFLAGS = -static -o

# Targets
.PHONY: all clean test

all: build/compiler

# Main compiler binary
build/compiler: src/asm/main.asm src/asm/lexer.asm src/asm/parser.asm src/asm/codegen.asm src/asm/runtime.asm
	mkdir -p build
	$(ASM) $(ASMFLAGS) -o build/main.o src/asm/main.asm
	$(ASM) $(ASMFLAGS) -o build/lexer.o src/asm/lexer.asm
	$(ASM) $(ASMFLAGS) -o build/parser.o src/asm/parser.asm
	$(ASM) $(ASMFLAGS) -o build/codegen.o src/asm/codegen.asm
	$(ASM) $(ASMFLAGS) -o build/runtime.o src/asm/runtime.asm
	$(LD) $(LDFLAGS) $@ build/main.o build/lexer.o build/parser.o build/codegen.o build/runtime.o

# Runtime library for compiled programs
src/runtime.o: src/asm/runtime.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

# Test assembly build
test: build/compiler
	./build/compiler tests/test_simple.txt

clean:
	rm -f build/*.o build/compiler