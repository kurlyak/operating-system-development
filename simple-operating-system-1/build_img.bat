@echo off

SET PATH="C:\hello-world-operating-system-1"

echo Compiling boot sector
nasm -O0 -f bin -o boot.bin boot.asm

echo Copying file
copy boot.bin myos.img

echo Mounting disk image...
imdisk -a -f myos.img -s 1440K -m B:

echo Dismounting disk image...
imdisk -D -m B:

echo All OK!

rem also possible create iso image for CD ROM
rem CDIMAGE.exe -l"myos" -b"myos.img" ".\dir" "myos.iso"

rem also possible create iso image for CD ROM
rem CDIMAGE.exe -l"myos" -b"boot.bin" ".\dir" "myos.iso"



pause
