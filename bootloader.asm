[BITS 16]
[ORG 0x7C00]

num_options db 3               ; total menu options
selected_option db 0           
loop_counter db 0             
rowsize db 80                  ; number of columns per row

start:
    cli                        ; disable interrupts
    xor ax, ax
    mov ds, ax                 
    mov es, ax                 
    mov ss, ax                 
    mov sp, 0x7C00             
    sti                        ; enable interrupts

    call clear_screen          

    call display_menu          ; display menu

main_loop:
    xor ah, ah                 ; wait for key press
    int 0x16                   ; get key code in AX

    cmp al, 0                  ; check if it is special key
    je handle_special_key      ; if zero, handle special key

    cmp al, 0x0D               ; check if 'Enter' key (ASCII 13)
    je handle_enter_key

    jmp main_loop              ; ignore other keys, loop back

handle_special_key:
    int 0x16                   ; get the second byte of the key code in AH
    cmp ah, 0x48               ; up arrow
    je move_up
    cmp ah, 0x50               ; down arrow
    je move_down

    jmp main_loop              ; ignore other keys

move_up:
    cmp byte [selected_option], 0
    je set_to_last_option
    dec byte [selected_option] ; move selection up
    jmp update_menu

set_to_last_option:
    mov byte [selected_option], 2  ; wrap to last option (2 for 0-based index)
    jmp update_menu

move_down:
    inc byte [selected_option]     ; move selection down
    cmp byte [selected_option], 3  ; total options
    jb update_menu
    mov byte [selected_option], 0  ; wrap to first option
    jmp update_menu

update_menu:
    call display_menu              ; update menu display
    jmp main_loop

display_menu:
    mov byte [loop_counter], 0     ; reset loop counter
    mov di, option_ptrs            ; start of option pointers
    mov dh, 0                      ; row 0
    mov dl, 0                      ; column 0

print_menu_loop:
    mov al, [selected_option]      ; get selected option
    mov cl, [loop_counter]         ; get current option index
    cmp cl, al
    jne normal_print

    mov bl, 0x70                   ; highlighted option
    call set_cursor                ; set cursor position
    mov si, [di]                   ; load option string pointer
    call print_string_colored      ; print highlighted option
    jmp next_option

normal_print:
    mov bl, 0x07                   ; normal option
    call set_cursor                ; set cursor position
    mov si, [di]                   ; load option string pointer
    call print_string_colored      ; print normal option

next_option:
    add di, 2                      ; move to next option pointer
    inc dh                         ; move to next row
    inc byte [loop_counter]        ; increment loop counter
    cmp byte [loop_counter], 3     ; total options
    jb print_menu_loop
    ret

handle_enter_key:
    mov al, [selected_option]      ; get selected option
    cmp al, 0
    je option1_action
    cmp al, 1
    je option2_action
    cmp al, 2
    je option3_action
    jmp main_loop                  ; should not happen

option1_action:
    call clear_screen
    mov si, msg_hello
    call print_string_at_top       ; print message at top
    call wait_for_key              ; wait for key press
    call display_menu              ; display menu again
    jmp main_loop

option2_action:
    call clear_screen
    mov si, msg_hai
    call print_string_at_top       ; print message at top
    call wait_for_key              ; wait for key press
    call display_menu              ; display menu again
    jmp main_loop

option3_action:
    call clear_screen
    mov si, msg_shutdown
    call print_string_at_top       ; print message at top
    call wait_for_key              ; wait for key press
    mov dx, 0x604                  ; QEMU shutdown port
    mov ax, 0x2000                 ; shutdown command
    out dx, ax                     ; send shutdown command
halt_loop:
    hlt                            ; halt CPU
    jmp halt_loop

print_string_at_top:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov dh, 0                      ; row 0
    mov dl, 0                      ; column 0
    call set_cursor                ; set cursor position

    mov bl, 0x07                   ; white text on black background
    call print_string_colored      ; print string

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

wait_for_key:
    xor ah, ah                     ; wait for key press
    int 0x16
    ret

print_string_colored:
    push ax
    push cx
    push dx
    push si
    push di

    xor ax, ax
    mov al, dh                     ; get row number
    mul byte [rowsize]             ; row * 80
    mov di, ax                     ; DI = row offset

    mov al, dl                     ; get column number
    add di, ax                     ; DI = (row * 80) + column

    shl di, 1                      ; multiply by 2 (character + attribute)

    mov ax, 0xB800                 ; video memory segment
    mov es, ax

print_loop_colored:
    lodsb                          ; load character from SI into AL
    or al, al
    jz done_print_colored
    mov [es:di], al                ; write character
    inc di
    mov [es:di], bl                ; write attribute from BL
    inc di
    jmp print_loop_colored

done_print_colored:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

clear_screen:
    mov ax, 0x0600                 ; scroll screen up
    mov bh, 0x07                   ; attribute for blank cells
    mov cx, 0x0000                 ; start at top-left
    mov dx, 0x184F                 ; end at bottom-right
    int 0x10
    ret

set_cursor:
    mov ah, 0x02                   ; set cursor position function
    mov bh, 0x00                   ; display page number
    int 0x10
    ret

; Data
option_ptrs:
    dw option1
    dw option2
    dw option3

option1 db '1. Print hello', 0
option2 db '2. Print hai', 0
option3 db '3. Shutdown', 0

msg_hello db 'Hello', 0
msg_hai db 'Hai', 0
msg_shutdown db 'Shutting down...', 0

; Boot signature
times 510 - ($ - $$) db 0
dw 0xAA55
