global _start

section .text
_start: ;------------------------------------------
    ; Read MAC from args
    ; [rsp] = argc
    ; [rsp + 8] = argv[]
    cmp qword [rsp], 1
    jbe exit_error  ; exit if argc <= 1. (Arguments missing)

    ; reading argv[0]
    mov rbx, [rsp + 8]  ; 
    xor rcx, rcx
count_chars:
    xor rax, rax
    mov al, [rbx + rcx]
    cmp byte al, 0
    je eol  ; jump if EOL
    inc rcx
    jmp count_chars

eol:

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
    mov word [sockaddr_in + 2], 0900h       ; sin_port (0010h = 4096)
    mov dword [sockaddr_in + 4], 0x0100007F ; in_addr
    mov qword [sockaddr_in + 8], 0x00       ; sin_zero

    ; send message
    mov rax, 44             ; sendto syscall
    mov rdi, [socket_fd]    ; socket descriptor
    mov rsi, magic_packet   ; pointer to the message
    mov rdx, 102            ; message len
    xor r10, r10            ; flags = NULL 
    mov r8, sockaddr_in     ; *dest_addr 
    mov r9, 16              ; sockaddr len
    syscall

exit_success:
    mov rdi, 0
    mov rax, 60
    syscall

exit_error:
    mov rdi, 1  ; general error
    mov rax, 60 ; exit
    syscall
;--------------------------------------------------

;section .data ;------------------------------------
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

