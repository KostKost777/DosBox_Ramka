.model tiny
.code
org 100h

CENTRE_OFFSET	equ 160 * 7 + 40
VRAM_OFFSET	equ 0b800h

Start:
		mov ax, VRAM_OFFSET
		mov es, ax	

		mov si, offset String
		mov ah, 82h

		mov di, CENTRE_OFFSET
		
begin_print_loop:

		lodsb 
		cmp al, 24h
		je end_print_loop
		stosw
		jmp begin_print_loop

end_print_loop: 

		mov ax, 4c00h
		int 21h

String		db "PRIVET EPTA$"
end Start
