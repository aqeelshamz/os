; option2.asm
[BITS 16]

; Option 2 Action - Print hai
option2_action:
    call clear_screen              ; clear the screen
    mov si, msg_hai                ; message to display (defined below)
    call print_string_at_top       ; print message at top
    call wait_for_key              ; wait for key press
    call display_menu              ; display menu again
    jmp main_loop

; Message data
msg_hai:
    db 'Hai', 0
