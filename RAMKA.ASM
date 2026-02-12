.model tiny
.code
org 100h

CENTRE_OFFSET	equ 160 * 5 + 80
VRAM_OFFSET	equ 0b800h
CMD_STR_PTR	equ 82h
CMD_STRLEN_PTR	equ 80h

Start:
		mov ax, VRAM_OFFSET
		mov es, ax	

		mov si, CMD_STR_PTR        ; skip first probel

		mov di, CENTRE_OFFSET
		mov cl, ds:[CMD_STRLEN_PTR]
		dec cl					;skip first probel

		xor dx, dx
		mov dl, cl  
		and dl, 0feh  
		shl dx, 1		    
		sub di, dx     
		
		mov ax, 0c03h
		sub di, 160 * 3 + 2 * 6
		mov dx, di
		mov bx, 7

print_ramka:	
	        mov cl, ds:[CMD_STRLEN_PTR]
		dec cl
		add cl, 12
		rep stosw
		add dx, 160
		mov di, dx
		dec bx
		cmp bx, 0
		jne print_ramka


		xor di, di
		mov di, CENTRE_OFFSET
		mov cl, ds:[CMD_STRLEN_PTR]
		dec cl					;skip first probel							
		xor dx, dx
		mov dl, cl				;centriryu
		and dl, 0feh			;sdelat chetnim
		shl dx, 1
		sub di, dx 
		mov dx, di
		mov ah, 4eh

print_string:
		lodsb 
		stosw
		loop print_string	
		
		
		mov ax, 4c00h
		int 21h

end Start
