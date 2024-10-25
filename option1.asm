; option1.asm
[BITS 16]

; Option 1 Action - Print hello
option1_action:
    call clear_screen              ; clear the screen
    mov si, msg_hello              ; message to display (defined below)
    call print_string_at_top       ; print message at top
    call wait_for_key              ; wait for key press
    call display_menu              ; display menu again
    jmp main_loop

; Message data
msg_hello:
    db 'Hello', 0
