@echo off

SET PATH="C:\hello-world-operating-system-2"

echo Compiling boot sector and kernel
nasm -O0 -f bin -o boot.bin boot.asm
nasm -O0 -f bin -o kernel.bin kernel.asm

echo Copying file
copy boot.bin myos.img

echo Mounting disk image...
imdisk -a -f myos.img -s 1440K -m B:

echo Copying kernel and applications to disk image...
copy kernel.bin b:\

echo Dismounting disk image...
imdisk -D -m B:

echo All OK!

rem also possible create iso image for CD ROM
rem CDIMAGE.exe -l"myos2" -b"myos.img" ".\dir" "myos.iso"

pause
