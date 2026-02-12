.model tiny
.code
org 100h

CENTRE_OFFSET	equ 160 * 7 + 80
VRAM_OFFSET	equ 0b800h
CMD_STR_PTR	equ 82h
CMD_STRLEN_PTR	equ 80h
LEN_OF_OP	equ 2


Start:
		mov ax, VRAM_OFFSET
		mov es, ax	
		
		xor ax, ax
		mov si, CMD_STR_PTR

		mov al, ds:[si]
		add si, LEN_OF_OP
		

		mov di, CENTRE_OFFSET
		mov cl, ds:[CMD_STRLEN_PTR]
		dec cl
		sub cl, LEN_OF_OP	;skip first probel

		xor dx, dx
		mov dl, cl  
		and dl, 0feh  		    
		sub di, dx     
		
		mov ah, 0ch
		sub di, 160 * 6 + 2 * 20
		mov dx, di
		mov bx, 13

print_ramka:	
	        mov cl, ds:[CMD_STRLEN_PTR]
		dec cl
		add cl, 40
		rep stosw
		add dx, 160
		mov di, dx
		dec bx
		cmp bx, 0
		jne print_ramka

		mov cl, ds:[CMD_STRLEN_PTR]
		dec cl		
		sub cl, LEN_OF_OP			;skip first probel
		
		mov di, CENTRE_OFFSET
		xor dx, dx
		mov dl, cl  
		and dl, 0feh  
		sub di, dx     
		
		mov ah, 0bh
		sub di, 160 * 3 + 2 * 16
		mov dx, di
		mov bx, 7

print_ramka2:	
	        mov cl, ds:[CMD_STRLEN_PTR]
		dec cl
		sub cl, LEN_OF_OP
		add cl, 32
		rep stosw
		add dx, 160
		mov di, dx
		dec bx
		cmp bx, 0
		jne print_ramka2


		xor di, di
		mov di, CENTRE_OFFSET
		mov cl, ds:[CMD_STRLEN_PTR]
		dec cl					;skip first probel
		sub cl, LEN_OF_OP							
		xor dx, dx
		mov dl, cl				;centriryu
		and dl, 0feh			;sdelat chetnim
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
