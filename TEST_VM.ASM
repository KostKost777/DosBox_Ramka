.model tiny
.code
org 100h

LINE		equ 23			; 0 - 24 dec
CLMN		equ 80			; 0 - 158 dec
SYM_OFFSET 	equ LINE * 160 + CLMN

Start: 
		mov ax, 0b800h
		mov es, ax
		xor bx, bx
		
		mov byte ptr es:[bx + SYM_OFFSET], 03h 
		mov byte ptr es:[bx + SYM_OFFSET + 1], 4eh + 80h

		mov ax, 4c00h 
		int 21h 
end Start