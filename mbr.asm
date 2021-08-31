; x86
;
; Switch to protected mode
;
; 08/31/2021
;
; Author: github.com/edsonphx

[ORG 0x7c00]                        

; constants
CODE_SEG equ code_descriptor - GDT_start
DATA_SEG equ data_descriptor - GDT_start

NEW_LINE equ 0x0a0d
NULL_CHAR equ 0x00

VIDEO_MEM_ADDRESS equ 0xb8000
COLOR_WHITE equ 0x0F;

start_real_mode:
    mov bx, rm_welcome_message          ; bx = str_address
    call rm_print                       ; rm_print()

    mov bx, rm_continue_message
    call rm_print

    mov ah, 0x00                        ; read key
    int 0x16

    cli                                 ; switch to protected mode
    lgdt [GDT_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:start_protected_mode

jmp $

; void rm_print(char* str_address)
rm_print:
    ; while (true)

    mov al, [bx]        ; al = *str_address
    cmp al, 0x00        ; if (al == '\0') return
    je rm_exit_print

    mov ah, 0x0e        ; printf ("%c", *str_address)
    int 0x10 

    inc bx              ; str_address++
    jmp rm_print
rm_exit_print:
    ret

; real mode data
rm_welcome_message:
    db NEW_LINE, "Welcome to real mode!", NULL_CHAR
rm_continue_message:
    db NEW_LINE, "Press any key to switch to protected mode...", NULL_CHAR

;struct GDT
;{
;	GDT_entry_descriptor null_descriptor;
;   GDT_entry_descriptor code_descriptor;
;   GDT_entry_descriptor data_descriptor;
;}
GDT_start:
;   struct GDT_entry_descriptor
;   {
;       uint16_t    limit0;
;       uint16_t    base0;
;       uint8_t     base1;
;       uint8_t	    access_byte;
;       uint8_t	    limit1 : 4;
;       uint8_t	    flags  : 4;
;       uint8_t	    base2;
;   }
    null_descriptor:
        dd 0x0
        dd 0x0

    code_descriptor:
        dw 0xffff       ; limit 0-15
        dw 0x0          ; base 0-15
        db 0x0          ; base 16-23
        db 0b10011010   ; access byte
        db 0b11001111   ; flags and limit 16 - 23
        db 0x0          ; base 24-31

    data_descriptor:
        dw 0xffff       ; limit 0-15
        dw 0x0          ; base 0-15
        db 0x0          ; base 16-23
        db 0b10010010   ; access byte
        db 0b11001111   ; flags and limit 16 - 23
        db 0x0          ; base 24-31
GDT_end:

;struct GDT_descriptor
;{
;   uint16_t size;
;   GDT* GDT_memory_address; 
;}
GDT_descriptor:
    dw GDT_end - GDT_start - 1  ; sizeof(GDT)
    dd GDT_start                ; GDT_memory_address

[bits 32]
start_protected_mode:
    call pm_clear_screen
    
    mov ebx, pm_welcome_message ; ebx = str_address
    mov ah, COLOR_WHITE         ; set color
    call pm_print

    jmp $

; void pm_clear()
pm_clear_screen: 
    xor ebx, ebx    ; ebx = counter
    mov al, 0x20    ; al = ' '

pm_clear_screen_loop:
    cmp ebx, 80 * 25    ; 80 characters per line
    je pm_clear_screen_exit
    
    mov ecx, ebx 
    imul ecx, 2
    add ecx, VIDEO_MEM_ADDRESS
    
    mov [ecx], ax   ; VIDEO_MEM_ADDRESS + (counter * 2)
    inc ebx         ; counter++
    jmp pm_clear_screen_loop
    
pm_clear_screen_exit:
    ret

; void pm_print(char* str_address)
pm_print:           
    ; edx = counter, ebx = str_address, ecx = video_memory_address

    xor edx, edx  
pm_print_loop:
    ; while (true)

    mov al, [ebx]       ; al = *str_address
    cmp al, 0           ; if (al == '\0') return
    je pm_exit_print

    mov ecx, edx 
    imul ecx, 2
    add ecx, VIDEO_MEM_ADDRESS

    mov [ecx], ax       ; VIDEO_MEM_ADDRESS + (counter * 2)

    inc ebx             ; counter++
    inc edx             ; str_address++
    jmp pm_print_loop
pm_exit_print:
    ret

; protected mode data
pm_welcome_message:
    db "Welcome to protected mode!", NULL_CHAR

times 510-($-$$) db 0              
dw 0xaa55
