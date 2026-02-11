.model tiny
.code
org 100h

SYM_OFFSET	equ 160 * 5 + 80

Start:
		mov ax, 0b800h
		mov es, ax
		xor bx, bx

		mov byte ptr es:[bx + SYM_OFFSET], 03h
		mov byte ptr es:[bx + SYM_OFFSET + 1], 70h 
		mov byte ptr es:[bx + SYM_OFFSET + 160], 03h
		mov byte ptr es:[bx + SYM_OFFSET + 160 + 1], 70h 

		mov ax, 4c00h
		int 21h
end Start