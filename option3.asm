; option3.asm
[BITS 16]

; Option 3 Action - Shutdown
option3_action:
    call clear_screen              ; clear the screen
    mov si, msg_shutdown           ; message to display (defined below)
    call print_string_at_top       ; print message at top
    call wait_for_key              ; wait for key press
    ; Send shutdown command to QEMU
    mov dx, 0x604                  ; QEMU shutdown port
    mov ax, 0x2000                 ; shutdown command
    out dx, ax                     ; send shutdown command
.halt_loop:
    hlt                            ; halt CPU
    jmp .halt_loop

; Message data
msg_shutdown:
    db 'Shutting down...', 0
