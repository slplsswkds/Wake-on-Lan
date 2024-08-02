global _start

section .text
_start: ;------------------------------------------
    ; Create socket
    mov rax, 41     ; socket syscall
    mov rdi, 2      ; family - AF_INET
    mov rsi, 2      ; type - SOCK_DGRAM
    xor rdx, rdx    ; protocol - 0 = IP 
    syscall

    cmp rax, 0
    jl exit_error ; failed to create socket
    mov [socket_fd], rax

    ; Set up sockaddr_in structure
    mov word [sockaddr_in], 2               ; sin_family = AF_INET
    mov word [sockaddr_in + 2], 0010h       ; sin_port
    mov dword [sockaddr_in + 4], 0x0100007F ; in_addr
    mov qword [sockaddr_in + 8], 0x00       ; sin_zero

    ; send message
    mov rax, 44             ; sendto syscall
    mov rdi, [socket_fd]    ; socket descriptor
    mov rsi, msg            ; pointer to the message
    mov rdx, 12             ; message len
    xor r10, r10            ; flags = NULL 
    mov r8, sockaddr_in     ; *dest_addr 
    mov r9, 16              ; sockaddr len
    syscall
; exit_success:
    mov rdi, 0
    mov rax, 60
    syscall

exit_error:
    mov rdi, 1  ; general error
    mov rax, 1  ; exit
    syscall
;--------------------------------------------------

section .data ;------------------------------------
    msg db "UDP test...", 0
;--------------------------------------------------

section .rodata ;----------------------------------
    ; Magic Packet. Contain six bytes of 0xFF and 16 repeats of MAC
    magic_packet db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
                 times 16 db 0x00, 0x11, 0x22, 0x33, 0x44, 0x55
;--------------------------------------------------

section .bss ;-------------------------------------
    socket_fd resd 1
    sockaddr_in resb 16
;--------------------------------------------------

