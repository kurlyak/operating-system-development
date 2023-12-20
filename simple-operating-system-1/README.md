# simple-operating-system-1

Operating system Hello World! #1

<img src="https://github.com/kurlyak/operating-system-development/blob/main/pics/simple-operating-system-1.png" alt="Hello World Operating System" width=600 />

To compile boot.asm code and create IMG file run build_img.bat. Created image possible open with VirtualBox as floppy disk. boot.asm should be placed in boot sector to the floppy disk (or IMG file).

After run compiled boot.asm code loads from boot sector to memory and put greeting message on screen.

In order to use boot.asm file, you need to know how a personal computer boots up after being turned on.

Dont forget set up right path in variable SET PATH in build_img.bat file.

For compile assembler source code boot.asm use NASM. To build IMG file use imdisk.exe.

imdisk.exe possible download using link:
https://sourceforge.net/projects/imdisk-toolkit/
