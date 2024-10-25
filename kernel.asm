; kernel.asm
[BITS 16]
[ORG 0x0000]

start:
    cli
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    sti

    ; Clear the screen
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; Display a message
    mov si, msg_kernel
    call print_string

.hang:
    hlt
    jmp .hang

; Function to print a string
print_string:
    mov ah, 0x0E
.print_char:
    lodsb
    cmp al, 0
    je .done_print
    int 0x10
    jmp .print_char
.done_print:
    ret

msg_kernel:
    db 'Welcome to the Kernel!', 0

; Padding to align to 512 bytes (if necessary)
times 512 - ($ - $$) db 0
