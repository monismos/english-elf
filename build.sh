#!/bin/bash
# ENGLISH-ELF Cross-Compile Script (Linux/macOS -> Windows x86-64)
# Requires NASM and lld-link (or mingw-w64) to be installed

NASM=nasm
LINK=lld-link
CC=gcc  # for creating stub .lib files if needed

OUTDIR=build
TARGET=english.exe
OBJS="$OUTDIR/english.obj"

mkdir -p "$OUTDIR"

echo "========================================"
echo " ENGLISH-ELF Windows Cross-Compile"
echo "========================================"
echo ""

echo "[1/3] Assembling english.asm..."
$NASM -f win64 -g -o "$OUTDIR/english.obj" src/asm/english.asm
if [ $? -ne 0 ]; then
    echo "FATAL: Assembly failed"
    exit 1
fi

echo "[2/3] Linking..."
$LINK /entry:mainCRTStartup /subsystem:console \
    /out:"$OUTDIR/$TARGET" \
    "$OUTDIR/english.obj" \
    kernel32.lib user32.lib \
    /defaultlib:kernel32.lib

if [ $? -ne 0 ]; then
    echo "FATAL: Link failed"
    exit 1
fi

echo ""
echo "========================================"
echo " BUILD SUCCESSFUL!"
echo " Output: $OUTDIR/$TARGET"
echo "========================================"
echo ""
echo "Test it with:"
echo "  wine $OUTDIR/$TARGET tests/test_hello.txt"
echo "  $OUTDIR/$TARGET --repl"