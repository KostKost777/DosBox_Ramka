.model tiny

.data
    amont_of_words         dw 0
    max_word_len           dw 0
    left_up                db 0         
    hor_line               db 0
    right_up               db 0
    ver_line               db 0
    right_down             db 0
    left_down              db 0   
    base_color             db 0
    str_ptr		           dw 0
    first_sym              db 0
    second_sym             db 0
    first_color            db 0
    second_color           db 0
    header_addr            dw 0
    header_len             dw 0

.code
org 100h

cmd_start                       equ 82h
centre_offset	                equ 160 * 7 + 80
video_seg                       equ 0b800h
str_len_ptr	                    equ 80h
ramka_length                    equ 22
ramka_width                     equ 6
one_line_len                    equ 160
DOS_sym                         equ 21h
DOS_sym_color                   equ 70h

Start:
                mov ax, 1003h
                mov bx, 0
                int 10h

                mov ax, video_seg       
                mov es, ax

                call SetMode


;------------------------------------------------------------------------
; определение режима программы
; Принимает:  -
; Возвращает: -
; Портит: bx
;------------------------------------------------------------------------

SetMode         proc

                mov bx, cmd_start

                cmp byte ptr [bx], '1'
                je first_mode

                cmp byte ptr [bx], '2'
                je second_mode

                ret

first_mode:
                inc bx
                call FirstMode
                ret

second_mode:
                inc bx
                call SecondMode
                ret

                endp

;------------------------------------------------------------------------
; режим 2, мой режим
; Принимает:  -
; Возвращает: -
;------------------------------------------------------------------------

SecondMode      proc

                call SetRecSyms
                call SetRecColors
                call SetStrBeginPtr
                call SetBaseSymSecondMode

                xor ax, ax
                mov si, [str_ptr]                                 ; загружаем в si указатель на строку
                call GetMaxWordLen

                mov si, [str_ptr] 
                call CountWords

                mov word ptr cx, [max_word_len]
                mov di, centre_offset
                call CalcWordBeginAddr

                push di

                mov word ptr ax, [amont_of_words]
                add ax, 2 * ramka_width
                push ax

                mov word ptr ax, [max_word_len]
                add ax, 2 * ramka_length
                push ax

                sub di, ramka_length * 2 + 2 + ramka_width * one_line_len
                push di

                mov ah, [base_color]

                call PrintBoarder
                add sp, 6

                pop di

                mov al, first_sym
                mov ah, first_color

                push di

                sub di, ramka_length * 2 + (ramka_width - 1) * one_line_len

                push di
                push ax

                mov word ptr cx, [max_word_len]                                      ; ширина 1 прямоугольника
                add cx, ramka_length * 2
                push cx

                mov word ptr cx, [amont_of_words]
                add cx, ramka_width * 2
                push cx

                call PrintRectangle
                pop di

                mov al, second_sym
                mov ah, second_color

                push di

                sub di, ramka_length * 2 - 4 + (ramka_width - 3) * one_line_len

                push di
                push ax

                mov word ptr cx, [max_word_len]                                      ; ширина 1 прямоугольника
                add cx, ramka_length * 2 - 4
                push cx

                mov word ptr cx, [amont_of_words]
                add cx, ramka_width * 2 - 4
                push cx

                call PrintRectangle
                pop di

                mov ah, base_color
                mov si, str_ptr
                mov di, centre_offset + one_line_len
                call PrintWords

                mov ax, 4c00h
                int 21h

                ret
                endp


;------------------------------------------------------------------------
; Считывает из консоли цвета
; Принимает:  -
; Возвращает: -
; Портит: bx, ax
;------------------------------------------------------------------------
SetRecColors    proc

                call SkipSpaces
                 
                push bx
                call SetSymbolColor

                mov [first_color], ah

                add bx, 2
                call SkipSpaces

                push bx
                call SetSymbolColor

                mov [second_color], ah

                add bx, 2
              
                ret
                endp

;------------------------------------------------------------------------
; Считывает из консоли символы рамки
; Принимает:  -
; Возвращает: -
; Портит: ax, bx
;------------------------------------------------------------------------
SetRecSyms      proc

                call SkipSpaces
                 
                mov byte ptr al, [bx]
                mov [first_sym], al

                inc bx

                mov byte ptr al, [bx]
                mov [second_sym], al

                inc bx

                ret
                endp

;------------------------------------------------------------------------
; режим 1, вывод рамки и символов DOS
; Принимает:  -
; Возвращает: -
; Портит: 
;------------------------------------------------------------------------
FirstMode       proc

                call SetHeaderAddr
                call SetStrBeginPtr
                call SetBaseSymFisrtMode

                xor ax, ax
                mov si, [str_ptr]                                 ; загружаем в si указатель на строку
                call GetMaxWordLen

                mov si, [str_ptr] 
                call CountWords

                mov word ptr cx, [max_word_len]
                mov di, centre_offset
                call CalcWordBeginAddr

                push di                                         ; загружаем координаты центра для слов на печать

                mov  ah, DOS_sym_color 
                
                mov bx, DOS_sym
                call SetSymbol
                 
                sub di, ramka_length * 2 - 2 + ramka_width * one_line_len

                push di
                push ax

                mov word ptr cx, [max_word_len]                                 
                add cx, ramka_length * 2
                push cx

                mov word ptr cx, [amont_of_words]
                add cx, ramka_width * 2
                push cx

                call PrintRectangle
                pop di

                push di

                sub di, ramka_length * 2 - 6 + (ramka_width - 1) * one_line_len

                mov word ptr ax, [amont_of_words]
                add ax, 2 * ramka_width - 4
                push ax

                mov word ptr ax, [max_word_len]
                add ax, 2 * ramka_length - 6
                push ax

                push di

                mov ah, 70h

                call PrintBoarder
                add sp, 6
                pop di

                mov ah, [base_color]
                mov si, str_ptr
                mov di, centre_offset
                call PrintWords
                
                mov di, centre_offset
                sub di, (ramka_width - 1) * one_line_len
                mov cx, [header_len]

                call CalcWordBeginAddr
            
                mov ah, DOS_sym_color
                call PrintHeader

                mov ah, 4Ch   
                mov al, 0      
                int 21h

                ret

                endp



;------------------------------------------------------------------------
; пропускаем пробелы и устанавливаем header_addr адрес начала заголовка
; Принимает:  bx - адрес на текущую строку
; Возвращает: -
; Портит: bx, ax
;------------------------------------------------------------------------
SetHeaderAddr   proc

                call SkipSpaces

                mov [header_addr], bx
                xor cx, cx
                 
loop_skip_header:
                inc cx
                cmp byte ptr [bx], ' '
                je end_skip_header
                inc bx
                jmp loop_skip_header

end_skip_header:
                dec cx
                mov [header_len], cx
                ret
                endp


;------------------------------------------------------------------------
; пропускаем пробелы и устанавливаем str_ptr адрес начала строки
; Принимает:  bx - адрес на текущую строку
; Возвращает: -
; Портит: bx, ax
;------------------------------------------------------------------------
SetStrBeginPtr   proc

                 call SkipSpaces

                 mov [str_ptr], bx

                 ret 
                 endp


;------------------------------------------------------------------------
; пропускаем пробелы в строке до первого символа
; Принимает:  bx - адрес на текущую строку
; Возвращает: -
; Портит: bx
;------------------------------------------------------------------------
SkipSpaces      proc

loop_skip_spaces:

                cmp byte ptr[bx], ' '
                jne end_skip_spaces
                inc bx
                jmp loop_skip_spaces

end_skip_spaces:
                ret
                endp

;-------------------------Cdecl------------------------------------------
; печать обрамления рамки
; Принимает:  1 - адрес левого верхнего угла 
;            2 - ширина рамки
;            3 - высота рамки
; Возвращает: 
; Портит: bx
;------------------------------------------------------------------------
PrintBoarder    proc

                push bp
                mov bp, sp

                push di
                push cx

                mov di, ss:[bp + 4]

                push di

                mov al, [left_up]
                call PrintSymbol

                add di, 2                                               ; перейти к горизонтальной линии
                mov al, [hor_line]
                
                mov cx, ss:[bp + 6]
                call PrintHorLine

                mov al, [right_up]                                        ; перейти к правому верхнему углу
                call PrintSymbol

                add di, one_line_len                                    ; перейти к следующей строке экрана
                mov al, [ver_line]
                mov cx, ss:[bp + 8]
                call PrintVerLine

                pop di                                                  ; возвращаемся к левому верхнему углу

                add di, one_line_len                                    ; перейти к следующей строке экрана
                mov al, [ver_line]
                mov cx, ss:[bp + 8]
                call PrintVerLine     

                mov al, [left_down]                                      ; перейти к левому нижнему углу 
                call PrintSymbol

                add di, 2                                               ; перейти к нижней линии
                mov al, [hor_line]
                mov cx, ss:[bp + 6]
                call PrintHorLine   

                mov al, [right_down]                                      ; перейти к правому нижнему углу 
                call PrintSymbol

                pop cx
                pop di
                pop bp

                ret
                endp

;-----------------------------------------------------------------------
; проход строки и запоминание максимальной длины
; Принимает:  si - адрес начала строки
; Возвращает: запоминает координаты и устанавливает max_word_len
; Портит: si
;------------------------------------------------------------------------
GetMaxWordLen   proc

                push ax
loop_3:
                call Strlen

                cmp word ptr [max_word_len], ax

                jae not_new_max_word
                mov word ptr [max_word_len], ax

not_new_max_word:

                add si, ax
                inc si
                cmp byte ptr ds:[si - 1], 23h
                je loop_3
                
                pop ax

                ret
                endp

;-----------------------------------------------------------------------
; считает длину слова, слова ограничиваются # или \r
; Принимает:  si - адрес начала слова
; Возвращает: ax - длина слова
;------------------------------------------------------------------------
Strlen          proc

                push si
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

                pop si
                ret
                endp

;-----------------------------------------------------------------------
; считает кол-во слов ограниченных в строке # или \r
; Принимает:  si - адрес начала строки
; Возвращает: amont_of_words - количество найденных слов
; Портит: si
;------------------------------------------------------------------------
CountWords      proc
        
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
; выводит строку длиной cx из источника ds:si, в видеопамять по адресу es:di, с ah в качестве цвета
; Принимает:  si - адрес источника
;            di - адрес в видеопамяти
;            ah - цвет символа
; Возвращает: -
; Портит:     si, cx
;------------------------------------------------------------------------

PrintHeader     proc

                push di
                push bx

                mov si, [header_addr]
                mov cx, [header_len]

                sub di, 2
                mov byte ptr es:[di], 0h
                inc di
                mov byte ptr es:[di], 70h
                inc di

print_header:

                lodsb 
                stosw

                loop print_header


                mov byte ptr es:[di], 0h
                inc di
                mov byte ptr es:[di], 70h

                pop bx
                pop di

                ret
                endp




;-----------------------------------------------------------------------
; выводит строку длиной cx из источника ds:si, в видеопамять по адресу es:di, с ah в качестве цвета
; Принимает:  si - адрес начала строки
;            di - адрес в видеопамяти
;            ah - цвет символа
; Возвращает: -
; Портит:     si, cx
;------------------------------------------------------------------------
PrintWords      proc

                push di
                push bx

loop_6:

                push di
                push ax

                call Strlen

                mov cx, ax
                
                pop ax

                call CalcWordBeginAddr

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
; получаем символ по указанному адресу и записываем в al
; Принимает:  ah - цвет символа
;            bx - адрес символа
; Возвращает: al - символ
; Портит:     di
;------------------------------------------------------------------------
SetSymbol       proc

                mov al, ds:[bx]

                ret
                endp

;-----------------------------------------------------------------------
; стиль Pascal
; печать прямоугольника по координатам, ширина, высота и цветом по умолчанию
; параметры: 1 - адрес левого верхнего угла прямоугольника
;           2 - символ, на который закрашивается прямоугольник
;           3 - ширина прямоугольника
;           4 - высота прямоугольника
; Портит: ax, dx
;------------------------------------------------------------------------
PrintRectangle  proc

                push bp
                mov bp, sp

                push di
                push cx

                mov di, ss:[bp + 10]
                mov ax, ss:[bp + 08]
                mov dx, ss:[bp + 04]

loop_2:                                          ;while dx != 0, в dx хранится высота прямоугольника
                mov cx, ss:[bp + 06]                     ; в cx хранится ширина прямоугольника
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
; конвертация символа из командной строки в 16 - ричное число
; Принимает: dh - ascii код 16-ричной цифры из командной строки
; Возвращает: dh - 16-ричное число
; Портит: dh
;------------------------------------------------------------------------
ParseInputSymbol proc

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
; получение из командной строки цвета для символов 
; параметры: 1 - адрес в строке, где записан цвет в 16-ричном виде
; Возвращает: ah - цвет символов
;------------------------------------------------------------------------
SetSymbolColor  proc 

                push bp
                mov bp, sp

                push bx
                push dx

                mov bx, ss:[bp + 4]
                mov dh, ds:[bx]

                call ParseInputSymbol
                shl dh, 4
                mov ah, dh

                inc bx
                mov dh, ds:[bx]

                call ParseInputSymbol
                add ah, dh

                pop dx
                pop bx
                pop bp

                ret 2
                endp

;-----------------------------------------------------------------------
; по номеру символа получаем адрес центра символа, делая выравнивание
; Принимает:  cl - номер символа
; Возвращает: di - результирующий адрес символа
;------------------------------------------------------------------------
CalcWordBeginAddr proc

                push cx
                and cl, 0feh			; четное число
                sub di, cx
                pop cx

                ret
                endp

;-----------------------------------------------------------------------
; печать по адресу одного символа в видеопамять
; Принимает:  di - адрес куда печатать символ, 
;            al - код символа
;            ah - цвет символа
; Возвращает: -
;-----------------------------------------------------------------------
PrintSymbol     proc

                mov word ptr es:[di], ax

                ret
                endp
         
;--------------------------------Pascal---------------------------------
; печать по адресу горизонтальной линии символов
; Принимает:  di - адрес куда печатать первый символ горизонтальной линии
;            ax - символ, на который закрашивается линия
;            cx - длина линии
; Возвращает: -
; Портит:     di, cx
;-----------------------------------------------------------------------
PrintHorLine    proc

                rep stosw

                ret
                endp

;-----------------------------------------------------------------------
; печать по адресу вертикальной линии символов
; Принимает:  di - адрес куда печатать первый символ вертикальной линии
;            ax - символ, на который закрашивается линия
;            cx - число линий
; Возвращает: -
; Портит:     di, cx
;-----------------------------------------------------------------------
PrintVerLine    proc

loop_1:                                  ;while cx != 0
        
                mov word ptr es:[di], ax
                dec cx
                add di, one_line_len

                cmp cx, 0
                jne loop_1

                ret
                endp


                ;------------------------------------------------------------------------
; Установка символов рамки для режима DOS
; Принимает:  -
; Возвращает: -
;------------------------------------------------------------------------

SetBaseSymFisrtMode  proc
                
                mov byte ptr [left_up],    0c9h 
                mov byte ptr [hor_line],   0cdh
                mov byte ptr [right_up],   0bbh
                mov byte ptr [ver_line],   0bah
                mov byte ptr [right_down], 0bch
                mov byte ptr [left_down],  0c8h 
                mov byte ptr [base_color], 30h

                ret
                endp

;------------------------------------------------------------------------
; установка символов рамки для режима 2
; Принимает:  -
; Возвращает: -
;------------------------------------------------------------------------

SetBaseSymSecondMode  proc
                
                mov byte ptr [left_up],    0c9h 
                mov byte ptr [hor_line],   0cdh
                mov byte ptr [right_up],   0bbh
                mov byte ptr [ver_line],   0bah
                mov byte ptr [right_down], 0bch
                mov byte ptr [left_down],  0c8h
                mov byte ptr [base_color], 0Fh 

                ret
                endp

end Start