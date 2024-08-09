global _start

section .text
_start: ;------------------------------------------
    ; Read MAC from args
    ; [rsp] = argc
    ; [rsp + 8] = argv[]
    cmp qword [rsp], 1
        jbe exit_error  ; exit if argc <= 1. (Arguments missing)

    ; reading argv[1]   
    mov rbx, [rsp + 16] ; argv[1] = MAC
    xor rcx, rcx
count_chars:
    mov al, [rbx + rcx] ; al = symbol
    cmp byte al, 0
        je eol              ; jump if EOL
    inc rcx
    jmp count_chars
eol:

    ; verify the length of string for MAC
    cmp rcx, 12         ; (without ":")
        je without_colon
    cmp rcx, 17         ; (with ":")
        je colon
    jne exit_user_error ; error if MAC length is invalid

colon:
    ; Write MAC to mac without colons
    mov rcx, 17
    call force_lowercase
    mov rcx, 17
    call decode_and_save_ascii_mac

without_colon:
    ; Write MAC to mac
    mov rcx, 12
    call force_lowercase

mac_ready:

    ; Create socket
    mov rax, 41     ; socket syscall
    mov rdi, 2      ; family - AF_INET
    mov rsi, 2      ; type - SOCK_DGRAM
    xor rdx, rdx    ; protocol - 0 = IP 
    syscall

    cmp rax, 0
        jl exit_error   ; failed to create socket
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
    mov     rdi, 0
    mov     rax, 60
    syscall

exit_user_error:    ; An error caused by incorrect user actions
    ; Print help-message and exit
    jmp exit_error

exit_error:
    mov     rdi, 1  ; general error
    mov     rax, 60 ; exit
    syscall
;--------------------------------------------------
;################-----FUNCTIONS-----###############
force_lowercase: ; force lowercase for MAC placed in stack still
    ; rcx = 12 or 17. should be set before calling force_lowercase
    mov rbx, [rsp + 24] ; argv[1] = MAC. '+24' instead '+16' because CALL made RSP -= 0x08
    l_fl:
        mov al, [rbx + rcx - 1]
        
        cmp al, 58              ; 58 = colon
        je  l_fl_enditer        ; skip if char is colon
        
        ; verify if number
        cmp al, 48  ; 48 = 0
        jb  exit_user_error     ; exit if symbol is wrong
        cmp al, 57  ; 57 = 9
        jbe l_fl_enditer        ; end iter if number
            
        ; verify if uppercase
        cmp al, 65  ; 65 = A
        jb  exit_user_error     ; exit if symbol is wrong
        cmp al, 70  ; 90 = F
        jbe l_fl_enditer        ; end iter if number

        ; verify if lowercase
        cmp al, 97  ; 65 = a
        jb  exit_user_error     ; exit if symbol is wrong
        mov dl, al
        add dl, 32              ; prepare lowercase if AL is uppercase
        cmp al, 102  ; 90 = f
        ja  exit_user_error     ; error if symbol is wrong hex val
        mov al, dl              ; make char lowercase 

    l_fl_enditer:
        loop l_fl
    ret

;##################################################
    ; FUNCTION:
    ;   - save decoded MAC to mac variable
    ;   - owerwrire al  (used to store high 4-bit)
    ;   - owerwrire dl  (used to store low 4-bit)
    ;   - owerwrire rdx (used to store char num)
decode_and_save_ascii_mac: 
    mov rbx, [rsp + 24]     ; MAC pointer. DONT CALL THIS FUNCTION FROM ANOTHER CALLing

    cmp al, 58  ; 58 = colon in ASCII
        je l_decode_enditer 
    cmp rcx, 17
        je l_decode_colon
    cmp rcx, 12
        je l_decode_non_colon

    l_decode_colon:
        mov [al], [rbx]
        mov [dl], [rbx + 1]

        ; [rbx + 2] = ":"

        mov [al], [rbx + 3]
        mov [dl], [rbx + 4]
    
        ; [rbx + 5]= ":'

        mov [al], [rbx + 6]
        mov [dl], [rbx + 7]

        ; [rbx + 8] = ":"

        mov [al], [rbx + 9]
        mov [dl], [rbx + 10]

        ; [rbx + 11] = ":"

        mov [al], [rbx + 12]
        mov [dl], [rbx + 13]

        ; [rbx + 14] = ":"

        mov [al], [rbx + 15]
        mov [dl], [rbx + 16]
    l_decode_non_colon:
ret

;section .data ;------------------------------------
;--------------------------------------------------

section .rodata ;----------------------------------
    ; Magic Packet. Contain six bytes of 0xFF and 16 repeats of MAC
    magic_packet db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
                 times 16 db 0x00, 0x11, 0x22, 0x33, 0x44, 0x55
    hexnum  db 'ab'
;--------------------------------------------------

section .bss ;-------------------------------------
    socket_fd   resd    1
    sockaddr_in resb    16
    mac         resb    6
;--------------------------------------------------

