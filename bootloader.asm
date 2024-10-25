[BITS 16]
[ORG 0x7C00]

num_options db 4               ; total menu options
selected_option db 0           
loop_counter db 0              
rowsize db 80                  ; no of columns per row

start:
    cli ; disable interrupts            
    xor ax, ax
    mov ds, ax           
    mov es, ax             
    mov ss, ax              
    mov sp, 0x7C00         
    sti      ; enbale interrupts              

    ; print boot message
    mov si, msg_boot
    call print_string

    call clear_screen

    ; display menu
    call display_menu

main_loop:
    xor ah, ah                 ; wait for key press
    int 0x16                   ; get key code in AX

    cmp al, 0                  ; check if it is special key
    jne main_loop              ; if not, loop back

    ; handle keysss
    int 0x16                   ; get the second byte of the key code in AH
    cmp ah, 0x48               ; up arrow
    je move_up
    cmp ah, 0x50               ; down arrow
    je move_down

    jmp main_loop             

move_up:
    cmp byte [selected_option], 0
    je set_to_last_option
    dec byte [selected_option]
    jmp update_menu

set_to_last_option:
    mov al, [num_options]
    dec al
    mov [selected_option], al
    jmp update_menu

move_down:
    inc byte [selected_option]
    cmp byte [selected_option], 4
    jb update_menu
    mov byte [selected_option], 0
    jmp update_menu

update_menu:
    call display_menu
    jmp main_loop

display_menu:
    mov byte [loop_counter], 0
    mov di, option_ptrs
    mov dh, 0
    mov dl, 0

print_menu_loop:
    mov al, [selected_option]
    mov cl, [loop_counter]
    cmp cl, al
    jne normal_print

    mov bl, 0x70               ; highlighted option
    call set_cursor
    mov si, [di]
    call print_string_colored
    jmp next_option

normal_print:
    mov bl, 0x07               ; normal option
    call set_cursor
    mov si, [di]
    call print_string_colored

next_option:
    add di, 2
    inc dh
    inc byte [loop_counter]
    cmp byte [loop_counter], 4    
    jb print_menu_loop
    ret

print_string_colored:
    push ax
    push cx
    push dx
    push si
    push di

    xor ax, ax
    mov al, dh
    mul byte [rowsize]
    mov di, ax

    mov al, dl
    add di, ax

    shl di, 1

    mov ax, 0xB800
    mov es, ax

print_loop_colored:
    lodsb
    or al, al
    jz done_print_colored
    mov [es:di], al
    inc di
    mov [es:di], bl
    inc di
    jmp print_loop_colored

done_print_colored:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

print_string:
    mov ah, 0x0E
print_loop:
    lodsb
    or al, al
    jz done_print
    int 0x10
    jmp print_loop

done_print:
    ret

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    ret

set_cursor:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    ret

; Data
option_ptrs:
    dw option1
    dw option2
    dw option3
    dw option4

option1 db 'Option 1', 0
option2 db 'Option 2', 0
option3 db 'Option 3', 0
option4 db 'Option 4', 0

msg_boot db 'Booting...', 0

times 510 - ($ - $$) db 0
dw 0xAA55
