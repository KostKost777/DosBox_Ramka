.model tiny
.code
org 100h

OUTPUT_OFFSET   equ 160 * 5
VRAM_OFFSET	equ 0b800h

Start:		mov bx, VRAM_OFFSET
		mov es, bx
		
		mov ax, 7003h
		mov cx, 80
		mov di, OUTPUT_OFFSET
		rep stosw

		mov ax, 4c00h
		int 21h

end		Start 		
