.model tiny

.data
    amont_of_words dw 0
    max_word_len   dw 0
    
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
        call Get_max_word_len

        mov si, str_ptr 
        call CountWords

        mov word ptr cx, [max_word_len]
        mov di, centre_offset
        call Get_word_begin_offset

        push ax

        mov word ptr ax, [amont_of_words]
        add ax, 2 * ramka_width
        push ax

        mov word ptr ax, [max_word_len]
        add ax, 2 * ramka_length
        push ax

        push di

        call Print_boarder
        add sp, 8

        pop ax

        push first_color_addr
        call Get_sym_color

        mov bx, first_sym_addr
        call Set_sym

        push di

        sub di, ramka_length * 2 - 2 + ramka_width * one_line_len

        push di
        push ax

        mov word ptr cx, [max_word_len]                                      ; рисуем 1 прямогольник
        add cx, ramka_length * 2
        push cx

        mov word ptr cx, [amont_of_words]
        add cx, ramka_width * 2
        push cx

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

        mov word ptr cx, [max_word_len]                                      ; рисуем 2 прямогольник
        add cx, ramka_length * 2 - 4
        push cx

        mov word ptr cx, [amont_of_words]
        add cx, ramka_width * 2 - 4
        push cx

        call Print_rectangle
        pop di

        mov ah, text_color
        mov si, str_ptr
        mov di, centre_offset
        call Print_words

        mov ax, 4c00h
        int 21h

;-------------------------Cdecl------------------------------------------
;Рисует красивую рамку
;Принимает:  1 - адрес начала центрированной строки 
;            2 - длина рамки
;            3 - ширина рамки
;Возвращает: 
;Портит: bx
;------------------------------------------------------------------------
Print_boarder proc

        push bp
        mov bp, sp

        push di
        push cx

        mov di, ss:[bp + 4]

        mov bx, ramka_length
        shl bx, 1

        sub di, bx
        mov bl, ramka_width
        inc bl
        
        push ax

        mov al, 10
        mul bl
        shl ax, 4
        sub di, ax

        pop ax

        push di
        mov ax, left_up
        call Print_sym

        add di, 2                                               ; рисуем верхнию линию
        mov ax, hor_line
        
        mov cx, ss:[bp + 6]
        call Print_hor_line

        mov ax, right_up                                        ; рисуем правый верхний угол
        call Print_sym

        add di, one_line_len                                    ; рисуем правую вертикальную линию
        mov ax, ver_line
        mov cx, ss:[bp + 8]
        call Print_ver_line

        pop di                                                  ; вернулись в верхний правый угол

        add di, one_line_len                                    ; рисуем левую вертикальную линию
        mov ax, ver_line
        mov cx, ss:[bp + 8]
        call Print_ver_line     

        mov ax, left_down                                      ; рисуем левый нижний угол 
        call Print_sym

        add di, 2                                               ; рисуем нижнию линию
        mov ax, hor_line
        mov cx, ss:[bp + 6]
        call Print_hor_line   

        mov ax, right_down                                      ; рисуем правый нижний угол 
        call Print_sym

        pop cx
        pop di
        pop bp

        ret
        endp

;-----------------------------------------------------------------------
;Ищет строку с максимальной длины
;Принимает:  si - адрес начала строки
;Возвращает: сохраняет значение в переменной max_word_len
;Портит: si
;------------------------------------------------------------------------
Get_max_word_len proc

        push ax
loop_3:
        call Strlen

        cmp word ptr [max_word_len], ax

        jae not_new_max_word
        mov word ptr [max_word_len], ax

not_new_max_word:

        cmp byte ptr ds:[si - 1], 23h
        je loop_3
        
        pop ax

        ret
        endp

;-----------------------------------------------------------------------
;Считает длину строки, которая оканчивается символом # или \r
;Принимает:  si - адрес начала строки
;Возвращает: ax - длина слова
;Портит: si
;------------------------------------------------------------------------
Strlen proc

        xor ax, ax

loop_4:
        inc ax
        inc si

        cmp byte ptr ds:[si], 23h
        je end_loop_4

        cmp byte ptr ds:[si], 0Dh
        je end_loop_4

        jmp loop_4

end_loop_4:

        inc si
        ret
        endp

;-----------------------------------------------------------------------
;Считает кол-во слов оканчивающихся в строке # или \r
;Принимает:  si - адрес начала строки
;Возвращает: amont_of_words - сохраняет туда значение
;Портит: si
;------------------------------------------------------------------------
CountWords proc
        
        push ax
        xor ax, ax

loop_5:
        inc si
        cmp byte ptr ds:[si], 23h
        jne not_new_word
        inc ax

        not_new_word:

        cmp byte ptr ds:[si], 0Dh
        jne loop_5
        
        inc ax

        mov word ptr [amont_of_words], ax

        pop ax
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
;Портит:     si, cx
;------------------------------------------------------------------------
Print_words proc

        push di
        push bx

loop_6:

        push di
        push ax
        push si

        call Strlen

        mov cx, ax
        
        pop si
        pop ax

        call Get_word_begin_offset

        print_string:

		lodsb 
		stosw

		loop print_string

        pop di
        cmp byte ptr ds:[si], 0Dh
        je end_loop_6

        inc si

        add di, one_line_len

        jmp loop_6


end_loop_6:

        pop bx
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

;------------------------------------------------------------------------
;Преобразует символ из командной строки в 16 - ричный цифру
;Принимает: dh - ascii код 16-ричной цифры из командной строки
;Возвращает: dh - 16-ричную цифру
;Портит: dh
;------------------------------------------------------------------------
Parse_input_sym proc

        sub dh, 30h

        cmp dh, 31h
        jae parse_little_verb

        cmp dh, 11h
        jae parse_big_verb

        ret

        parse_big_verb:
        sub dh, 07h
        ret

        parse_little_verb:
        sub dh, 27h
        ret

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

        call Parse_input_sym
        shl dh, 4
        mov ah, dh

        inc bx
        mov dh, ds:[bx]

        call Parse_input_sym
        add ah, dh

        pop dx
        pop bx
        pop bp

        ret 2
        endp

;-----------------------------------------------------------------------
;По длине слова высчитывает адрес начала первго символа, центрируя надпись
;Принимает:  cl - длина слова
;Возвращает: di - смещение первого символа слова
;------------------------------------------------------------------------
Get_word_begin_offset proc

        push cx
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
         
;--------------------------------Pascal---------------------------------
;Рисует на экране горизонтальную линию рамки
;Принимает:  di - адрес откуда начинать рисовать горизонтальную линию
;            ax - символ, из которого состоит линия
;            cx - длина линии
;Возвращает: -
;Портит:     di, cx
;-----------------------------------------------------------------------
Print_hor_line proc

        rep stosw

        ret
        endp

;-----------------------------------------------------------------------
;Рисует на экране вертикальную линию рамки
;Принимает:  di - адрес откуда начинать рисовать вертикальную линию
;            ax - символ, из которого состоит линия
;            cx - высота линии
;Возвращает: -
;Портит:     di, cx
;-----------------------------------------------------------------------
Print_ver_line proc

loop_1:                                  ;while cx != 0
        
        mov word ptr es:[di], ax
        dec cx
        add di, one_line_len

        cmp cx, 0
        jne loop_1

        ret
        endp

end Start


