.model tiny
.code
org 100h

CENTRE_OFFSET	equ 160 * 7 + 40
VRAM_OFFSET	equ 0b800h
CMD_STR_PTR	equ 81h
CMD_STRLEN_PTR	equ 80h

Start:
		mov ax, VRAM_OFFSET
		mov es, ax	

		mov si, CMD_STR_PTR
		mov ah, 4eh

		mov di, CENTRE_OFFSET
		mov cl, ds:[CMD_STRLEN_PTR]

begin_print:
		lodsb 
		stosw
		loop begin_print

		mov ax, 4c00h
		int 21h

end Start
