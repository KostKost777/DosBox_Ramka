.model tiny
.code
org 100h

centre_offset	                equ 160 * 7 + 80
video_seg                       equ 0b800h
str_ptr		                equ 8bh
first_sym_addr                  equ 82h
second_sym_addr                 equ 83h
first_color_addr                equ 85h
second_color_addr               equ 88h
str_len_ptr	                equ 80h
ramka_length                    equ 20
ramka_width                     equ 4
one_line_len                    equ 160
num_of_vars                     equ 10
          
left_up          = 0ec9h         ; ╔            
hor_line         = 0ecdh         ; ═
right_up         = 0ebbh         ; ╗
ver_line         = 0ebah         ; ║
right_down       = 0ebch         ; ╝
left_down        = 0ec8h         ; ╚     
text_color       = 09h           ; цвет

Start:
        mov ax, video_seg       
        mov es, ax	
        
        xor ax, ax
        mov si, str_ptr                                 ; сохраняем в si начало строки

        call Get_size_of_word

        call Get_word_begin_offset

        call Print_boarder

        push first_color_addr
        call Get_sym_color

        mov bx, first_sym_addr
        call Set_sym

        push di
        sub di, ramka_length * 2 - 2 + ramka_width * one_line_len

        push di
        push ax

        mov dx, cx                                       ; рисуем 1 прямогольник
        add dx, ramka_length * 2
        push dx

        push ramka_width * 2 + 1

        call Print_rectangle
        pop di

        push second_color_addr
        call Get_sym_color

        mov bx, second_sym_addr
        call Set_sym

        push di
        sub di, ramka_length * 2 - 6 + (ramka_width - 2) * one_line_len

        push di
        push ax

        mov dx, cx                                       ; рисуем 2 прямогольник
        add dx, ramka_length * 2 - 4
        push dx

        push ramka_width * 2 + 1 - 4

        call Print_rectangle
        pop di

        mov ah, text_color
        call Print_word

        mov ax, 4c00h
        int 21h

;-----------------------------------------------------------------------
;Рисует красивую рамку
;Принимает:  di - адрес начала центрированной строки
;            cx - длина слова
;Возвращает: -
;------------------------------------------------------------------------
Print_boarder proc

        push di

        sub di, ramka_length * 2 + (ramka_width + 1) * one_line_len  ; рисуем левый верхний угол
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

        mov ax, left_down                                      ; рисуем левый нижний угол 
        call Print_sym

        add di, 2                                               ; рисуем нижнию линию
        mov ax, hor_line
        call Print_hor_line   

        mov ax, right_down                                      ; рисуем правый нижний угол 
        call Print_sym

        pop di
        ret
        endp


;-----------------------------------------------------------------------
;По адресу длины строки высчитывает длину слова и кладет ее в регистр cl
;Принимает:  str_len_ptr - адрес длины строки, относительно ds
;Возвращает: cl - длина слова
;------------------------------------------------------------------------
Get_size_of_word proc

        mov cl, ds:[str_len_ptr]                        ; в cl сохраняем длину строки
	sub cl, num_of_vars
        ret
        endp

;-----------------------------------------------------------------------
;Выводит строку длинны cx по адресу ds:si, в видео память по адресу es:di, в ah находится цвет
;Принимает:  si - адрес начала строки
;            di - адрес начала в видео памяти
;            ah - цвет слова
;Возвращает: -
;------------------------------------------------------------------------
Print_word proc

        push di
        push si
        push cx

        print_string:
		lodsb 
		stosw
		loop print_string

        pop cx
        pop si
        pop di

        ret
        endp

;-----------------------------------------------------------------------
;Задает первый символ прямоугольника и сохраняет в al
;Принимает:  ah - цвет слова
;            bx - адрес символа
;Возвращает: al - символ
;Портит:     di
;------------------------------------------------------------------------
Set_sym proc

        sub si, dx
        mov al, ds:[bx]
        add si, dx

        ret
        endp

;-----------------------------------------------------------------------
;Функция типа Pascal
;Рисует прямоугольник из символа, верхний левый угол, ширина и длина передаетс по стеку
;Параметры: 1 - адрес верхнего левого угла прямоугольника
;           2 - символ, из которого будет состоять прямоугольник
;           3 - длина прямоугольника
;           4 - ширина прямоугольника
;Портит: ax, dx
;------------------------------------------------------------------------
Print_rectangle proc

        push bp
        mov bp, sp

        push di
        push cx

        mov di, ss:[bp + 10]
        mov ax, ss:[bp + 08]
        mov dx, ss:[bp + 04]

loop_2:                                          ;while dx != 0, в dx записываем ширину прямоугольнка
        mov cx, ss:[bp + 06]                     ; в cx записывае длину прямогольника
        push di
        rep stosw
        pop di
        add di, one_line_len
        dec dx
        cmp dx, 0
        jne loop_2

        pop cx
        pop di

        pop bp
        ret 8
        endp

;------------------------------Pascal------------------------------------
;Считывает из командной строки цвета для символов 
;Параметры: 1 - адрес в памяти, где начинается цвет в 16-ричной записи
;Возвращает: ah - цвет элемента
;------------------------------------------------------------------------
Get_sym_color proc 

        push bp
        mov bp, sp

        push bx
        push dx

        mov bx, ss:[bp + 4]
        mov dh, ds:[bx]

        sub dh, 30h
        shl dh, 4
        mov ah, dh

        inc bx
        mov dh, ds:[bx]

        sub dh, 30h
        add ah, dh

        pop dx
        pop bx
        pop bp

        ret 2
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
;Рисует на экране значек символа по введенному адресу
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
