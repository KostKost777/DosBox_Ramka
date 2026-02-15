.model tiny
.code
org 100h

centre_offset	equ 160 * 7 + 80
video_seg		equ 0b800h
str_ptr			equ 82h
str_len_ptr		equ 80h
ramka_length    equ 20
ramka_width     equ 4
one_line_len    equ 160

left_up         = 0ec9h         ; ╔             символы рамки          -->
hor_line        = 0ecdh         ; ═
right_up        = 0ebbh         ; ╗
ver_line        = 0ebah         ; ║
right_down      = 0ebch         ; ╝
left_down       = 0ec8h         ; ╚             символы рамки          <--
color           = 7ch           ; цвет

Start:
		mov ax, video_seg       
		mov es, ax	
		
		xor ax, ax
		mov si, str_ptr                                 ; сохраняем в si начало строки

        call Get_size_of_word

		call Get_word_begin_offset

        
        sub di, ramka_length * 2 + ramka_width * one_line_len  ; рисуем левый верхний угол
        push di
        mov ax, left_up
        call Print_sym

        add di, 2                                               ; рисуем верхнию линию
        mov ax, hor_line
        call Print_hor_line

        mov ax, right_up                                        ; рисуем правый верхний угол
        call Print_sym

        add di, one_line_len                                    ; рисуем правую вертикальную линию
        mov ax, ver_line
        call Print_ver_line

        pop di                                                  ; вернулись в верхний правый угол 
        add di, one_line_len                                    ; рисуем левую вертикальную линию
        mov ax, ver_line
        call Print_ver_line     

        mov ax, left_down                                      ; рисуем правый нижний угол 
        call Print_sym

        add di, 2                                               ; рисуем нижнию линию
        mov ax, hor_line
        call Print_hor_line   

        mov ax, right_down                                      ; рисуем правый нижний угол 
        call Print_sym                                       



		mov ax, 4c00h
		int 21h


;-----------------------------------------------------------------------
;По адресу длины строки высчитывает длину слова и кладет ее в регистр cl
;Принимает:  str_len_ptr - адрес длины строки, относительно ds
;Возвращает: cl - длина слова
;------------------------------------------------------------------------
Get_size_of_word proc

        mov cl, ds:[str_len_ptr]                        ; в cl сохраняем длину строки
		dec cl
        ret
        endp

;-----------------------------------------------------------------------
;По длине слова высчитывает адрес начала первго символа, центрируя надпись
;Принимает:  cl - длина слова, centre_offset - смещение центра экрана
;Возвращает: di - смещение первого символа слова
;------------------------------------------------------------------------
Get_word_begin_offset proc

        push cx
        mov di, centre_offset
        and cl, 0feh			;делаем четным
        sub di, cx
        pop cx
        ret
        endp

;-----------------------------------------------------------------------
;Рисует на экране значек симвла по введенному адресу
;Принимает:  di - адрес куда поставить элемент, 
;            al - сам элемент
;            ah - цвет элемента
;Возвращает: -
;-----------------------------------------------------------------------
Print_sym proc
        mov word ptr es:[di], ax
        ret
        endp
         
;-----------------------------------------------------------------------
;Рисует на экране горизонтальную линию рамки
;Принимает:  di - адрес откуда начинать рисовать горизонтальную линию
;            ax - символ, из которого состоит линия
;Возвращает: -
;Портит:     di
;-----------------------------------------------------------------------
Print_hor_line proc

        push cx

        add cx, 2 * ramka_length
        rep stosw

        pop cx
        ret
        endp

;-----------------------------------------------------------------------
;Рисует на экране вертикальную линию рамки
;Принимает:  di - адрес откуда начинать рисовать вертикальную линию
;            ax - символ, из которого состоит линия
;Возвращает: -
;Портит:     di
;-----------------------------------------------------------------------
Print_ver_line proc

        push cx
        xor cx, cx
        mov cx, 2 * ramka_width + 1

loop_1:                                  ;while cx != 0
        
        mov word ptr es:[di], ax
        dec cx
        add di, one_line_len

        cmp cx, 0
        jne loop_1

        pop cx
        ret
        endp

end Start
