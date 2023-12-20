;Ed Kurlyak 2023 Hello World! Operating System.
;NASM source code. This code of boot sector loads a kernel file kernel.bin
;directly from CD root directory without performing floppy/hard disk emulation
;as described by the El Torito specification

;OS files:
;boot.asm
;kernel.asm

BITS 16

start:
	mov ax, 07C0h		;space after this bootloader set up 8K stack 
	add ax, 544			;(8192 + 512) / 16 bytes per paragraph

	cli					;changing stack, disable interrupts

	mov ss, ax
	mov sp, 4096

	sti					;finished changing stack, enable interrupts

	mov ax, 07C0h		;Set data segment to where we're load boot code
	mov ds, ax

	mov si, load_cd_msg		;put string position into SI
	call print_msg			;call string printing subroutine

	mov ax, 16				;start sector read CD ROM for Primary Volume Descriptor
	mov	[boot_drive], dl 	;dl now contains boot drive No.

next_block:

	mov	dh, 01h				;Number of sectors to read
	mov	bx, buffer 			;buffer to read sectors from CD ROM
	mov	[edd_segment], ds

	call read_sectors 		;read sectors from CD ROM subroutine
	cmp	byte [bx], 1		;is sector Primary Volume Descriptor?
	jz	pvd_found 			;PVD found jump to pvd_founc
	inc		ax 				;increase start sector number for read from CD ROM
	cmp	byte [bx], 255 		;this is Volume Descriptor Set Terminator
	jnz	next_block 			;if not read next sector of CD ROM
	
	jmp $					;jump here is infinite loop
	
;Read of root directory CD ROM
pvd_found:
	mov		bx, buffer + 156	;offset in PVD 156 is Directory record for Root Directory
	mov		eax, [bx + 2] 		;LBA of the root directory - start sector
	mov		edx, [bx + 10]	 	;data length of the root directory
	add	 	edx, 2047			;Convert data length to number of sectors
	shr		edx, 11 			;
	mov		dh, dl				;load number of sectors to dh
	;mov		dh, 1 			
	mov		bx, buffer + 2048 	;buffer to read Root Directory from CD ROM
								;size of one sector ISO 9660 is 2048 bytes
	mov	[edd_segment], ds 		;segment to read
	call	read_sectors 		;read sectros from CD ROM subroutine
	
next_entry:
	cmp	 byte[bx], 0 			;length of directory Record for current filename
	jz	last_entry 				;if length is 0 jump to end

	mov  	si, bx 				;buffer directory Record address
	add 	si, 33 				;offset for filename 33
	mov		cl, [bx + 32] 		;length of filename kernel.bin offset 32
	mov 	di, kern_filename	;offset kernel.bin string

label1:
						;next step comparing strings filename kernel.bin
	mov		al, [si] 	;si kernel filename from directory record
	cmp		[di], al 	;di kernel filename from data section
	jnz	fail 			;comparizion failed goto next directory record
	inc		si
	inc		di
	dec		cl
	jnz	label1 			;continue comparing goto label1
	jmp	load_loader 	;filename found, load kernel.bin file

fail:
	add	bx, [bx] 	;add to buffer Length of directory Record for current filename
	jmp	next_entry 	;jump to next filename

last_entry:
	mov	si, kernel_not_found_msg
	call	print_msg

	jmp $			;jump here is infinite loop


;now we found kernel and read contents to 0x4000:0
load_loader:
	mov 	ax, [bx + 2] 	;number of first sector of file kernel.bin on disk
	mov		dx, [bx + 10] 	;file size kernel.bin
	add	 	dx, 2047		;Convert file length to number of sectors
	shr 	dx, 11			
	;mov 	dx, 1 			
	mov 	dh, dl 			;number sector to read
	mov 	bx , 0 			;offset to read is 0
	mov	 word [edd_segment], 0x4000 	;segment to read

	call	read_sectors 	;read sectros from CD ROM subroutine

	jmp 4000h:0000h			;after read jump to our kernel

;---------------------------------------------------
;SUBROUTINES SECTION
	
read_sectors:
	pusha
	mov	[edd_lba], ax 		;start sector
	mov	[edd_offset], bx 	;buffer address where to read

	mov	[edd_nsecs], dh 		;numbers of sectors for read
    cmp dh, 32 					;read not more 32 sectors from CD ROM
    jle label2					;16 bit real mode, possible read 32 sectors only
    							;32 * 2048 = 65536 (64 Kilobytes)
    mov word [edd_nsecs], 32 	;number of sectors for read

label2:
	mov	dl, [boot_drive] 		;boot drive No.

	mov	si, edd_packet 			;disk address packet address
	mov	ah, 042h 				;function 13h read CD ROM sectors
	int	13h

	jc	read_fail

	popa
	ret

read_fail:
	mov si, error_msg		;string position into si
	call print_msg			;call string printing routine
	ret

;---------------------------------------------------

print_msg:			;output string in si to screen
	mov ah, 0Eh		;int 10h function print character

.put_char:
	lodsb			;get character from string
	cmp al, 0 		;this is end of string?
	je .done		;if char is zero mu to label
	int 10h			;print character
	jmp .put_char

.done:
	ret

;---------------------------------------------------
;DATA SECTION

	load_cd_msg db 'Booting from CD...', 13, 10, 0
	error_msg db 'Error Reading CD', 13, 10, 0
	kernel_not_found_msg	db "KERNEL.BIN not found!", 13, 10, 0
	kern_filename	db "KERNEL.BIN", 0

edd_packet:
	edd_len:	dw	16 	;16 bit mode - size of this packet
	edd_nsecs:	dw	0	;number of sectors to transfer
	edd_offset:	dw	0   ;buffer where to read address
	edd_segment:dw	0   ;register ds value here
	edd_lba:	dq	0   ;number of start sector on disk to read
	
	boot_drive:	db	0E0h	;boot drive for CD

	times 510-($-$$) db 0	;pad remainder of boot sector with 0s
	dw 0xAA55				;the standard PC boot signature

buffer:						;disk buffer begins (stack starts 8k after this)