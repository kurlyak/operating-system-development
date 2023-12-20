;Ed Kurlyak 2023 Hello World! Operating System.
;NASM source code. This code of boot sector boot.asm loads a kernel
;file kernel.bin from floppy disk root directory into memory and run it

;OS files:
;boot.asm
;kernel.asm

	BITS 16

	jmp short start_code	;skip bios parameter block, jmp short takes 2 bytes
	nop						;nop takes 1 byte
							;bios parameter block must starts from 3 byte offset

;------------------------------------------------------------------
;BIOS PARAMETER BLOCK (BPB) SECTION
;Values in bios parameter block is used for 1440 KB, 3.5-inch. floppy disk

OsVersion			db "BOOTDISK"	;disk label 8 characters
BytesPerSector		dw 512			;bytes per sector

SectorsPerCluster	db 1			;sectors per cluster 1440 KB disk
;SectorsPerCluster	db 2			;sectors per cluster 720 KB disk
;SectorsPerCluster	db 2			;sectors per cluster 360 KB disk

ReservedForBoot		dw 1			;reserved sectors for boot record
NumberOfFats		db 2			;number copies of the FAT

RootDirEntries		dw 224			;1440 KB disk max mumber of entries in root dir
									;(224 * 32 = 7168 = 14 sectors takes root dir)

;RootDirEntries		dw 70h			;720 KB disk max mumber of entries in root dir
									;(224 * 32 = 7168 = 14 sectors takes root dir)

;RootDirEntries		dw 70h			;360 KB disk max mumber of entries in root dir
									;(224 * 32 = 7168 = 14 sectors takes root dir)

TotalSectors		dw 2880			;total mumber of logical sectors 1440 KB disk
;TotalSectors		dw 5A0h			;total mumber of logical sectors 720 KB disk
;TotalSectors		dw 2D0h			;total mumber of logical sectors 720 KB disk

MediaByte			db 0F0h			;medium descriptor 1440 KB diskette
;MediaByte         	db 0F9h 		;media desctiptor 720 KB diskette
;MediaByte         	db 0FDh 		;media desctiptor 360 KB diskette
;MediaByte         	db 0F8h 		;media desctiptor for HDD

SectorsPerFat		dw 9			;sectors per FAT 1440 KB disk
;SectorsPerFat		dw 3			;sectors per FAT 720 KB disk
;SectorsPerFat		dw 2			;sectors per FAT 360 KB disk

SectorsPerTrack		dw 18			;1440 KB disk sectors per track (36/cylinder) 80 tracks
;SectorsPerTrack	dw 9			;720 KB disk sectors per track (18/cylinder) 80 tracks
;SectorsPerTrack	dw 9			;360 KB disk sectors per track (18/cylinder) 80 tracks

NumHeads			dw 2			;number number of heads/sides
HiddenSectors		dd 0			;number hidden sectors
LargeSectors		dd 0			;number LBA sectors
BootDrv				db 0			;drive No: 0 for A: floppy
;BootDrv			db 80h			;drive No: 80h for HDD
Signature			db 41			;drive signature: 41 for floppy
VolumeID			dd 00000000h	;volume ID: any number
VolumeLabel			db "BOOTDISK   ";volume label 11 characters
FileSystem			db "FAT12   "	;file system type 8 characters

;------------------------------------------------------------------
;MAIN BOOT SECTOR CODE SECTION

start_code: 				;INPUT DL = 0 for floppy, DL = 80h for HDD
	mov ax, 07C0h			;stack starts 8K after buffer
	add ax, 544				;(8192 + 512) / 16 bytes per paragraph
	cli						;disable interrupts for changing stack
	mov ss, ax
	mov sp, 4096
	sti						;restore interrupts after changing stack

	mov ax, 07C0h			;set data segment to where we're loaded
	mov ds, ax

	mov [bootdev], dl		;save boot device number

	mov si, greeting_msg
	call print_msg

;1)we load root directory from floppy disk into memory
;2)looking fro kernel.bin in the root directory
;3)for kernel.bin finding out first sector in FAT from root directory
;4)read FAT from floppy disk into memory
;5)view FAT clusters and load from disk kernel.bin into memory 2000h:0000h
;6)do jump to our kernel.bin code located at 2000h:0000h in memory

;start sector of root=ReservedForBoot + HiddenSectors + NumberOfFats * SectorsPerFat = 19
;number of root sectors=RootDirEntries * 32 (bytes/entry) / 512 (bytes/sector) = 14
;start sector of user data=(start sector of root) + (number of root sectors) = 33

;1)we load root directory from floppy disk into memory
	mov ax, 19			;root dir starts at logical sector 19
	call logical2chs

	mov si, buffer		;set ES:BX to buffer (in end of the code)
	mov bx, ds 			;data segment is located 07C0h:0
	mov es, bx 			;ES point to data segment
	mov bx, si 			;BX point to buffer

	mov ah, 2			;function 13h read floppy disk sectors
	mov al, 14			;read all 14 sectors of root directory

	stc					;a few BIOSes do not set properly on error
	int 13h				;read sectors using 13h BIOS interrupt

	jnc search_kernel		;read OK go to search kernel.bin in root directory
	
	mov si, disk_error_msg	;if error reading put message on screen and reboot
	jmp print_msg_and_reboot

	jmp $ 					;from this loop no exit

;2)looking fro kernel.bin in the root directory
search_kernel:

	mov ax, ds			;root dir now located in buffer
	mov es, ax			;set ES:DI to this info
	mov di, buffer 		

	mov cx, word [RootDirEntries]	;search all 224 entries
	mov ax, 0						;start searching offset 0

next_root_entry:

	mov si, kernel_filename		;start offset searching for kernel filename
	mov cx, 11 					;filename 11 characters len
	rep cmpsb
	je found_file_to_load		;found kernel.bin now DI will be at offset 11
								;filename located in 0 offset in root dir entry

	add ax, 32					;increase search entries by 1 (32 bytes per entry)
								;1 entry in root directory is 32 bytes len

	mov di, buffer				;point to next entry
	add di, ax

	loop next_root_entry 		;not found go to next root entry

	mov si, kernel_not_found_msg	;if kernel is not found print message and reboot
	jmp print_msg_and_reboot

	jmp $

;3)for kernel.bin finding out first sector in FAT from root directory
;4)read FAT from floppy disk into memory
found_file_to_load:				;get first cluster of kernel.bin and load FAT into RAM
	mov ax, word [es:di+0Fh]	;offset 11 + 15 = 26 contains 1st cluster in FAT
	mov word [cluster], ax 		;store value

	mov ax, 1					;sector 1 on disk is first sector of first FAT
	call logical2chs 					;convert logical sector into head:track:side

	mov di, buffer				;ES:BX points to our buffer
	mov bx, di

	mov ah, 2					;int 13h function read sectors from disk
	mov al, 9					;we will read all 9 sectors (see BPB) of 1st FAT

	stc
	int 13h						;read sectors using the BIOS

	jnc read_fat_ok				;read all 9 sectors of FAT is OK

	mov si, disk_error_msg	;if error reading put message on screen and reboot
	jmp print_msg_and_reboot

	jmp $

;5)view FAT clusters and load from disk kernel.bin into memory 2000h:0000h
read_fat_ok:
	
	mov ah, 2			;int 13h floppy read function
	mov al, 1 			;read one sector per time

	push ax				;save in case we

;next we must find sectors of kernel.bin in FAT and load the kernel.bin
;from the disk. Here's how we find out where it starts:
;FAT cluster 0 = media descriptor = 0F0h
;FAT cluster 1 = filler cluster = 0FFh
;totaly 2 clusters FAT are unusable
;kerlen.bin on disk starts in sector = ((FAT cluster number) - 2) * SectorsPerCluster +
;+ (start of user data) = (cluster FAT number) + 31

load_file_sector:
	mov ax, word [cluster]		;first cluster kernel.bin in FAT
	add ax, 31 					;first sector kernel.bin in data area on disk

	call logical2chs					;convert logical sector in head:track:side

	mov ax, 2000h				;set address to load kernel.bin 2000h:0000h
	mov es, ax 					;kernel.bin will loaded using ES:BX
	mov bx, word [pointer] 		;offset pointer to load next sector

	pop ax				; Save in case we (or int calls) lose it
	push ax

	stc
	int 13h

	jnc calculate_next_cluster

	pop ax

	mov si, disk_error_msg		;if error reading put message on screen and reboot
	jmp print_msg_and_reboot

	jmp $

	;cluster values in FAT12 stored in 12 bits, so 3 bytes takes 2 clusters of FAT
	;we have figure out start offset (in bytes) for cluster in FAT 
	;start offset = cluster * 3 / 2
	;then in this offset from FAT read word (next cluster)
	;if cluster is even, for this word we do "and 0FFFh" to mask last 4 bits
	;if cluster is odd, for this word we do "shr 4" to mask first 4 bits

	;cluster 0 		  |cluster 1 		 |cluster 2 	  |cluster 3
	;1111-1111 - 1111-2222 - 2222-2222 - 3333-3333 - 3333-4444 - 4444-4444
	;byte 0      |byte 1     |byte 2     |byte 3	 |byte 4 	 |byte 5	     

	;cluster 0 * 3 / 2 = 0 / 2 = offset in bytes AX=0 = remainder DX=0 (cluster is even)
	;cluster 1 * 3 / 2 = 3 / 2 = offset in bytes AX=1 = remainder DX=1 (cluster is odd)
	;cluster 2 * 3 / 2 = 6 / 2 = offset in bytes AX=3 = remainder DX=0 (cluster is even)
	;cluster 3 * 3 / 2 = 9 / 2 = offset in bytes AX=4 = remainder DX=1 (cluster is odd)

	;[cluster] - claster number in FAT
	;after calculations (claster * 3 / 2) we know start offset
	;in bytes for cluster in buffer FAT, after calculations AX and DX is
	;AX = offset in bytes in buffer FAT
	;DX = cluster with this offset is even/odd

	;cluster in FAT has 12 bits, buts this cluster references to sector 512 bytes
	;on disk (user data)
	
calculate_next_cluster:
	mov dx, 0
	mov ax, [cluster]
	mov bx, 3
	mul bx
	mov bx, 2
	div bx		;after div AX = offset in bytes from start of FAT for this cluster
				;after div DX = ([cluster] * 3) mod 2 (cluster in FAT is even/odd)

	mov si, buffer 			;SI = start of FAT
	add si, ax 				;offset in bytes from start of FAT stored in AX
	mov ax, word [ds:si]	;read word from offset in FAT

	or dx, dx			;if DX = 0 cluster is even, if DX = 1 cluster odd

	jz even				;if cluster is even, get rid last 4 bits of word
						;with next cluster, if odd, get rid first 4 bits

odd:
	shr ax, 4			;shift out first 4 bits (they belong to another cluster)
	jmp short next_cluster_cont


even:
	and ax, 0FFFh		;mask final 4 bits


next_cluster_cont:
	mov word [cluster], ax		;store cluster number for next calculations

	cmp ax, 0FF8h				;FF8h is end of file marker in FAT12
	jae end 					;we loaded all sectors of kernel.bin jump to run it

	add word [pointer], 512		;increase buffer pointer 1 sector length
	jmp load_file_sector

;6)do jump to our kernel.bin code located at 2000h:0000h in memory
end:					; We've got the file to load!
	pop ax				; Clean up the stack (AX was pushed earlier)
	mov dl, byte [bootdev]		; Provide kernel with boot device info

	jmp 2000h:0000h			; Jump to entry point of loaded kernel!


;------------------------------------------------------------------
;BOOT SECTOR SUBROUTINES

print_msg_and_reboot:

	call print_msg
	jmp reboot

; ------------------------------------------------------------------	

reboot:
	mov ax, 0
	int 16h				; Wait for keystroke
	mov ax, 0
	int 19h				; Reboot the system

; ------------------------------------------------------------------

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

;------------------------------------------------------------------

	;DISK - READ SECTORS INTO MEMORY
	;int     13h             

	;AH = 2 function read disk
	;AL = number of sectors to read
	;CH = track
	;CL = sector
	;DH = head
	;DL = drive
	;ES:BX -> buffer to fill

logical2chs:	;calculate head, track and sector settings for int 13h
				;INPUT: logical sector in AX
				;OUTPUT: registers for int 13h
	push bx
	push ax

	;sector CL = start logical sector % SectorsPerTrack
	;head DH = (start logical sector / SectorsPerTrack) % NumHeads
	;track CH = (start logical sector / SectorsPerTrack) / NumHeads

	;first calculate which start phisical sector on disk
	;start phisical sector CL = start logical sector % SectorsPerTrack

	mov bx, ax			;start logical sector for reading in AX

	mov dx, 0			;first the sector
	div word [SectorsPerTrack] ;AX = AX div SectorsPerTrack
	add dl, 01h			;physical sectors start at 1
	mov cl, dl			;physical sector in CL for int 13h

	;next calculate which head and track

	mov ax, bx 	;AX = start logical sector for reading

	mov dx, 0			
	div word [SectorsPerTrack] 	;AX = AX div SectorsPerTrack
	mov dx, 0
	div word [NumHeads]			;AX = AX div NumHeads
	mov dh, dl					;which head/side
	mov ch, al					;which track

	pop ax
	pop bx

	mov dl, byte [bootdev]		; Set correct device

	ret

;------------------------------------------------------------------
;STRINGS AND VARIABLES

	kernel_filename	db "KERNEL  BIN"	;kernel filename 11 characters len
	disk_error_msg	db "Floppy error! Press any key...", 13, 10, 0
	kernel_not_found_msg	db "KERNEL.BIN not found!", 13, 10, 0
	greeting_msg	db "Booting from floppy disk...", 13, 10, 0

	bootdev		db 0 	;boot device number
	cluster		dw 0 	;first cluster in FAT of the file we want to load
	pointer		dw 0 	;pointer into buffer for loading kernel

;------------------------------------------------------------------
;END OF BOOT SECTOR AND BUFFER START

	times 510-($-$$) db 0	;boot sector len must be 512 bytes
	dw 0AA55h				;boot sector signature

buffer:				; Disk buffer begins (8k after this, stack starts)

