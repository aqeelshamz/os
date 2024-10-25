; bootloader.asm
[BITS 16]
[ORG 0x7C00]

; Variables and constants
num_options EQU 3
selected_option db 0
rowsize EQU 80

kernel_load_segment EQU 0x1000
kernel_load_offset  EQU 0x0000

start:
    cli                             ; disable interrupts
    xor ax, ax
    mov ds, ax                      ; DS = 0x0000
    mov es, ax                      ; ES = 0x0000
    mov ss, ax                      ; SS = 0x0000
    mov sp, 0x7000                  ; Set SP to 0x7000 (avoid overlap with code)
    sti                             ; enable interrupts

    mov ax, 0x0003                  ; Set video mode to 80x25 text mode
    int 0x10

    call clear_screen               ; clear the screen
    call display_menu               ; display menu

main_loop:
    xor ah, ah                      ; wait for key press
    int 0x16                        ; get key code in AX

    cmp al, 0                       ; check if it is special key
    je handle_special_key           ; if zero, handle special key

    cmp al, 0x0D                    ; check if 'Enter' key (ASCII 13)
    je handle_enter_key

    jmp main_loop                   ; ignore other keys, loop back

handle_special_key:
    int 0x16                        ; get the second byte of the key code in AH
    cmp ah, 0x48                    ; up arrow
    je move_up
    cmp ah, 0x50                    ; down arrow
    je move_down

    jmp main_loop                   ; ignore other keys

move_up:
    cmp byte [selected_option], 0
    je set_to_last_option
    dec byte [selected_option]      ; move selection up
    jmp update_menu

set_to_last_option:
    mov byte [selected_option], num_options - 1  ; wrap to last option
    jmp update_menu

move_down:
    inc byte [selected_option]      ; move selection down
    cmp byte [selected_option], num_options
    jb update_menu
    mov byte [selected_option], 0   ; wrap to first option

update_menu:
    call display_menu               ; update menu display
    jmp main_loop

display_menu:
    mov dh, 0                       ; row 0
    mov dl, 0                       ; column 0
    mov si, option_ptrs             ; SI points to option_ptrs
    xor cl, cl                      ; CL = 0, will serve as the index

display_menu_loop:
    lodsw                           ; load word from [SI] into AX, SI += 2
    push si                         ; save SI
    mov si, ax                      ; SI = address of option string

    mov al, [selected_option]
    cmp al, cl                      ; compare selected_option with current index in CL
    jne normal_option_display

    mov bl, 0x70                    ; highlighted option (white text on black)
    call set_cursor                 ; set cursor position
    call print_string_colored       ; print highlighted option
    jmp after_option_display

normal_option_display:
    mov bl, 0x07                    ; normal option (gray text on black)
    call set_cursor                 ; set cursor position
    call print_string_colored       ; print normal option

after_option_display:
    inc dh                          ; move to next row
    inc cl                          ; increment index (CL)
    pop si                          ; restore SI
    cmp cl, num_options
    jne display_menu_loop
    ret

handle_enter_key:
    mov al, [selected_option]
    cmp al, 0
    je option1_action
    cmp al, 1
    je option2_action
    cmp al, 2
    je option3_action
    jmp main_loop                   ; should not happen

; Include the option files
%include "option1.asm"
%include "option2.asm"
%include "option3.asm"

; Function to load the kernel
load_kernel:
    ; Display loading message
    mov si, msg_loading_kernel
    call print_string_at_top

    ; Load the kernel into ES:BX
    mov ax, kernel_load_segment     ; ES = 0x1000
    mov es, ax
    mov bx, kernel_load_offset      ; BX = 0x0000

    ; Read sectors from disk
    mov ah, 0x02                    ; BIOS read sectors function
    mov al, 1                       ; Number of sectors to read (adjust if kernel is larger)
    mov ch, 0x00                    ; Cylinder 0
    mov cl, 0x02                    ; Sector 2 (BIOS sector numbers start at 1)
    mov dh, 0x00                    ; Head 0
    mov dl, 0x00                    ; Drive 0x00 (floppy)
    int 0x13                        ; BIOS disk interrupt
    jc disk_error                   ; Jump if carry flag set (error)

    ; Set up segment registers for the kernel
    mov ax, kernel_load_segment     ; AX = 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE                  ; Set SP near top of segment
    ; Far jump to kernel entry point
    jmp kernel_load_segment:kernel_load_offset

disk_error:
    mov si, disk_error_msg
    call print_string_at_top
    jmp .halt

.halt:
    hlt
    jmp .halt

msg_loading_kernel:
    db 'Loading kernel...', 0

disk_error_msg:
    db 'Disk read error!', 0

; Functions

clear_screen:
    mov ax, 0x0600                   ; scroll screen up
    mov bh, 0x07                     ; attribute for blank cells
    mov cx, 0x0000                   ; start at top-left
    mov dx, 0x184F                   ; end at bottom-right
    int 0x10
    ret

set_cursor:
    mov ah, 0x02                     ; set cursor position function
    mov bh, 0x00                     ; display page number
    int 0x10
    ret

print_string_colored:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds                          ; Save DS
    push es                          ; Save ES

    mov ax, 0xB800                   ; video memory segment
    mov es, ax                       ; ES = 0xB800

    mov ax, 0x0000                   ; data segment
    mov ds, ax                       ; DS = 0x0000 (where our data is)

    ; Compute offset = ((row * 80) + column) * 2
    xor ax, ax
    mov al, dh                       ; get row number
    mov cl, rowsize                  ; load 80 into CL
    mul cl                           ; AL * CL -> AX
    mov di, ax                       ; DI = row offset

    mov al, dl                       ; get column number
    add di, ax                       ; DI = (row * 80) + column

    shl di, 1                        ; multiply by 2 (character + attribute)

print_loop_colored:
    lodsb                            ; load character from DS:SI into AL
    cmp al, 0
    je print_done_colored
    mov [es:di], al                  ; write character
    inc di
    mov [es:di], bl                  ; write attribute from BL
    inc di
    jmp print_loop_colored

print_done_colored:
    pop es                           ; Restore ES
    pop ds                           ; Restore DS
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_string_at_top:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds                          ; Save DS
    push es                          ; Save ES

    mov dh, 0                        ; row 0
    mov dl, 0                        ; column 0
    call set_cursor                  ; set cursor position

    mov bl, 0x07                     ; white text on black background
    call print_string_colored        ; print string

    pop es                           ; Restore ES
    pop ds                           ; Restore DS
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

wait_for_key:
    xor ah, ah                       ; wait for key press
    int 0x16
    ret

; Data
option_ptrs:
    dw option1_str
    dw option2_str
    dw option3_str

option1_str:
    db '1. Print hello', 0
option2_str:
    db '2. Print hai', 0
option3_str:
    db '3. Boot kernel', 0

; Boot signature
times 510 - ($ - $$) db 0
dw 0xAA55
