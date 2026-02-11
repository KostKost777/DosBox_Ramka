.model tiny
.code
org 100h

CENTRE_OFFSET	equ 160 * 15 + 80
VRAM_OFFSET	equ 0b800h
CMD_STR_PTR	equ 81h
CMD_STRLEN_PTR	equ 80h

Start:
		mov ax, VRAM_OFFSET
		mov es, ax	

		mov si, CMD_STR_PTR + 1         ; skip first probel
		mov ah, 4eh

		mov di, CENTRE_OFFSET
		mov cl, ds:[CMD_STRLEN_PTR]
		dec cl				;skip first probel							

		mov dl, cl			;centriryu
		and dl, 0feh			;sdelat chetnim
		sub di, dx 
		mov dx, di
print_string:
		lodsb 
		stosw
		loop print_string				

		sub dx, 10 			;risuem ramku
		sub dx, 160 * 5
		mov ax, 0c03h
		mov di, dx
		
		mov bx, 3
print_ramka:	
	        mov cl, ds:[CMD_STRLEN_PTR]
		dec cl
		add cl, 10
		rep stosw
		add dx, 160
		mov di, dx
		dec bx
		cmp bx, 0
		jne print_ramka

		mov ax, 4c00h
		int 21h
		
end Start
