.model tiny
.code
org 100h

CENTRE_OFFSET	equ 160 * 7 + 80
SYM_CODE        equ 08200h + 15h
VRAM_OFFSET	equ 0b800h
NUM_OF_SYM	equ 10

Start:
		mov ax, VRAM_OFFSET
		mov es, ax
		xor bx, bx	

		mov cx, NUM_OF_SYM
Print_sym:		
		mov word ptr es:[bx + CENTRE_OFFSET], SYM_CODE
		add bx, 160  
		loop Print_sym

		mov ax, 4c00h
		int 21h
end Start