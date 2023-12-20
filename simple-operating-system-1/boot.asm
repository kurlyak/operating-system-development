BITS 16

start:
	mov ax, 07C0h			;4K after this bootsector stack located
	add ax, 288				;(4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h			;we're loaded at 7C00h, set data segment
	mov ds, ax

	mov si, greeting_msg		;put string position into SI
	call print_msg				;call print message routine

	jmp reboot 					;wait for keystroke and reboot

	jmp $						;infinite loop

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

	greeting_msg db "Hello World! Operating System. Ed Kurlyak 2023", 13, 10,"Press any key when ready...", 13, 10, 0

	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature