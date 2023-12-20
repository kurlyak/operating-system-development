;Ed Kurlyak 2023 Hello World! Operating System.
;NASM source code. boot.asm is boot sector loader, and kernel.asm
;is kernel code for Hello World! OS. This kernel only put message on screen.

;OS files:
;boot.asm
;kernel.asm

BITS 16

os_main:
	cli					;disable interrupts while changing stack
	mov ax, 0
	mov ss, ax			;set stack
	mov sp, 0FFFFh
	sti					;enable interrupts

	cld					;the default direction for string operations
						;is 'up' - incrementing address in RAM

	mov ax, 4000h		;set all segments where kernel is loaded
	mov ds, ax			
	mov es, ax			
	mov fs, ax			
	mov gs, ax


	mov si, greeting_msg		;put string offset into si
	call print_msg				;call print string subroutine

	jmp reboot

	jmp $					;jump here is infinite loop!

;---------------------------------------------------
;SUBROUTINES SECTION

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

reboot:
	mov ax, 0
	int 16h				;wait for any key press
	mov ax, 0
	int 19h				;reboot system


;---------------------------------------------------
;DATA SECTION

	greeting_msg db "Hello World! Operating System. Ed Kurlyak 2023", 13, 10, "Kernel loaded!", 13, 10,"Press any key when ready...", 13, 10, 0

