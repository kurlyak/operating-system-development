@echo off

SET PATH="C:\hello-world-operating-system-3"

echo Create CD ROM directory
mkdir .\dir

echo Compiling bootloader and kernel
nasm.exe -O0 -f bin -o boot.bin boot.asm
nasm.exe -O0 -f bin -o .\dir\kernel.bin kernel.asm

echo Build CD ROM image iso file
CDIMAGE.exe -l"myos" -b"boot.bin" ".\dir" "myos.iso"

echo Done!

pause
