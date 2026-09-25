@echo off
REM ENGLISH-ELF Windows Build Script
REM Builds english.exe from pure NASM assembly for x86-64.
REM Uses NASM + LLVM lld-link only - no Windows SDK required.

set OUTDIR=build
set TARGET=english.exe
set NASM=nasm
set LLD=lld-link

if not exist %OUTDIR% mkdir %OUTDIR%

echo ========================================
echo  ENGLISH-ELF Windows Build
echo ========================================

echo.
echo [1/4] Assembling english.asm with NASM...
%NASM% -f win64 -g -o %OUTDIR%\english.obj src\asm\english.asm
if errorlevel 1 (
    echo FATAL: Assembly failed. Is NASM installed and in PATH?
    echo Download from: https://www.nasm.us/pub/nasm/releasebuilds/
    exit /b 1
)

echo.
echo [2/4] Generating import library from kernel32.def...
%LLD% /def:src\asm\kernel32.def /out:%OUTDIR%\kernel32.lib /machine:x64 /nodefaultlib
if errorlevel 1 (
    echo FATAL: Import library generation failed. Is lld-link in PATH?
    echo Install LLVM: https://github.com/llvm/llvm-project/releases
    exit /b 1
)

echo.
echo [3/4] Linking with lld-link...
%LLD% /entry:mainCRTStartup /subsystem:console /nodefaultlib /out:%OUTDIR%\%TARGET% %OUTDIR%\english.obj %OUTDIR%\kernel32.lib
if errorlevel 1 (
    echo FATAL: Link failed.
    exit /b 1
)

echo.
echo [4/4] Verifying build...
if exist %OUTDIR%\%TARGET% (
    echo ========================================
    echo  BUILD SUCCESSFUL!
    echo  Output: %OUTDIR%\%TARGET%
    echo ========================================
    echo.
    echo Run:     %OUTDIR%\%TARGET% tests\test_hello.txt
    echo Repl:    %OUTDIR%\%TARGET% --repl
    echo Bootstrap: %OUTDIR%\%TARGET% bootstrap\english.txt
) else (
    echo FATAL: Build succeeded but output not found.
    exit /b 1
)
