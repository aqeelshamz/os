; option3.asm
[BITS 16]

; Option 3 Action - Boot Kernel
option3_action:
    call clear_screen              ; clear the screen
    mov si, msg_boot_kernel        ; message to display (defined below)
    call print_string_at_top       ; print message at top
    call load_kernel               ; load the kernel
    ; If load_kernel fails, it will handle the error
    jmp main_loop                  ; Should not reach here

msg_boot_kernel:
    db 'Booting kernel...', 0
