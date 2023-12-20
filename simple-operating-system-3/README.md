# simple-operating-system-3

Operating system Hello World! #3

<img src="https://github.com/kurlyak/operating-system-development/blob/main/pics/simple-operating-system-3.png" alt="Hello World Operating System" width=600 />

The boot sector file boot.asm (compiled by NASM) is placed in the first sector of the CD ROM disk, the kernel kernel.asm (compiled by NASM) is placed in the root directory of the CD ROM disk.

In order to use these files, you need to know how a personal computer boots up after being turned on, how the ISO 9660 CD ROM file system works, and know about extended read function 042h int 13h.

To build an ISO image of the operating system Hello World! you need the CDIMAGE.exe program, or any other program that can create an iso image and write the boot sector to it.

How is the process of compiling the source code and building the ISO image of Hello World! OS:

1)files boot.asm, kernel.asm, build_iso.bat put in the directory C:\myos\

2)download the CDIMAGE.exe program from the Internet and put it in the C:\myos\ folder - this program creates the myos.iso image, writes the boot sector to the iso image, and the files that will be in the root directory of the iso image should be located in the C: \myos\dir\ - this folder will contain the kernel file kernel.bin after compilation

3)download the nasm compiler from the Internet and put the nasm.exe file in the C:\myos\ folder

4)run the build_iso.bat file (do not run with Administrator rights) and the myos.iso image will be built

5)then using VirtualBox to load this image, the boot sector code boot.bin will display "Booting from CD..." message and load the kernel code kernel.bin, then the kernel will display the message "Hello World! Kernel loaded! Press any key when ready...". Next press any key for reboot.
