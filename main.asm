DEFAULT REL
; COMPILE & RUN WITH:
; nasm -fmacho64 main.asm && ld -macosx_version_min 10.7.0 -o main main.o && ./main

%define SYSCALL_WRITE 0x2000004
%define SYSCALL_EXIT  0x2000001
global start


section .text

start:

    call print_line_change

    ; Print the instruction message
    mov     rax, SYSCALL_WRITE
    mov     rdi, 1 ; stdout
    mov     rsi, instruction_msg
    mov     rdx, instruction_msg.len
    syscall

    ; Print the message that CPUID is being called
    call print_line_change
    mov     rax, SYSCALL_WRITE
    mov     rdi, 1 ; stdout
    mov     rsi, cpuid_called_msg
    mov     rdx, cpuid_called_msg.len
    syscall

    ; Call CPUID, fun begins
    mov eax, 0
    cpuid

    ; EAX contains:
    ; CPU Highest calling value
    ; EBX & EDX & ECX contain Vendor ID string:


    mov [cpu_vendor], ebx
	mov [cpu_vendor+4], edx
	mov [cpu_vendor+8], ecx
    mov [cpu_highest_calling_value], eax

    ; Just output the message preceding the CPU vendor information
    mov     rax, SYSCALL_WRITE
    mov     rdi, 1 ; stdout
    mov     rsi, cpu_vendor_message
    mov     rdx, cpu_vendor_message.len
    syscall

    mov     rax, SYSCALL_WRITE
    mov     rdi, 1 ; stdout
    mov     rsi, cpu_vendor
    mov     rdx, cpu_vendor.len
    syscall

    call print_line_change

    mov     rax, SYSCALL_WRITE
    mov     rdi, 1 ; stdout
    mov     rsi, cpu_highest_calling_message
    mov     rdx, cpu_highest_calling_message.len
    syscall

    mov dx, [cpu_highest_calling_value]
    call print_hex

    call print_line_change

    ; Print the message that CPUID is being called
    call print_line_change
    mov     rax, SYSCALL_WRITE
    mov     rdi, 1 ; stdout
    mov     rsi, cpuid_called_msg
    mov     rdx, cpuid_called_msg.len
    syscall

    mov eax, 1
    cpuid

    ; EAX contains:
    ; Bits 03-00: Stepping ID
    ; Bits 07-04: Model
    ; Bits 11-08: Family ID
    ; Bits 13-12: Processor Type
    ; Bits 19-16: Extended Model ID
    ; Bits 27-20: Extended Family ID

    ; Temporary register for extraction, e.g., r8
    ; Store Stepping ID (bits 0-3 of EAX)
    mov r8d, eax
    and r8b, 0x0F
    mov [stepping_id_val], r8b

    ; Store Model ID (bits 4-7 of EAX)
    mov r8d, eax
    shr r8b, 4
    and r8b, 0x0F
    mov [model_id_val], r8b

    ; Store Family ID (bits 8-11 of EAX)
    mov r8d, eax
    shr r8d, 8 ; Shift EAX so Family ID is in lower bits of R8D
    and r8b, 0x0F ; Access as byte
    mov [family_id_val], r8b

    ; Store Processor Type (bits 12-13 of EAX)
    mov r8d, eax
    shr r8d, 12
    and r8b, 0x03
    mov [processor_type_val], r8b

    ; Store Extended Model ID (bits 16-19 of EAX)
    mov r8d, eax
    shr r8d, 16
    and r8b, 0x0F
    mov [ext_model_id_val], r8b

    ; Store Extended Family ID (bits 20-27 of EAX)
    mov r8d, eax
    shr r8d, 20
    and r8b, 0xFF ; This will be a byte
    mov [ext_family_id_val], r8b

    ; --- Print Stepping ID ---
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, stepping_id_msg
    mov rdx, stepping_id_msg.len
    syscall
    movzx dx, byte [stepping_id_val] ; Load byte and zero-extend to 16-bit dx
    call print_hex
    call print_line_change

    ; --- Print Model ID ---
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, model_id_msg
    mov rdx, model_id_msg.len
    syscall
    movzx dx, byte [model_id_val]
    call print_hex
    call print_line_change

    ; --- Print Family ID ---
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, family_id_msg
    mov rdx, family_id_msg.len
    syscall
    movzx dx, byte [family_id_val]
    call print_hex
    call print_line_change

    ; --- Print Processor Type ---
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, processor_type_msg
    mov rdx, processor_type_msg.len
    syscall
    movzx dx, byte [processor_type_val]
    call print_hex
    call print_line_change

    ; --- Print Extended Model ID ---
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, ext_model_id_msg
    mov rdx, ext_model_id_msg.len
    syscall
    movzx dx, byte [ext_model_id_val]
    call print_hex
    call print_line_change

    ; --- Print Extended Family ID ---
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, ext_family_id_msg
    mov rdx, ext_family_id_msg.len
    syscall
    movzx dx, byte [ext_family_id_val]
    call print_hex
    call print_line_change

    ; Print the message that CPUID is being called
    call print_line_change
    mov     rax, SYSCALL_WRITE
    mov     rdi, 1 ; stdout
    mov     rsi, cpuid_called_msg
    mov     rdx, cpuid_called_msg.len
    syscall

    mov eax, 2
    cpuid

    cmp al, 0x01 ; Compare the lowest byte of EAX with 01h
    jne not_supported ; If CPUID with EAX=2 is not supported, we skip the rest of the code.
    
    mov [eax_2_ah], ah ; Store AH value for later use
    mov r8d, eax
    shr r8d, 16
    and r8b, 0xFF ; This will be a byte
    mov [eax_2_eax_1], r8b


    mov r8d, eax
    shr r8d, 24
    and r8b, 0xFF ; This will be a byte
    mov [eax_2_eax_2], r8b

    mov [eax_2_ebx], ebx ; Store EBX for later use
    mov [eax_2_eax], eax ; EAX for later use
    mov [eax_2_ecx], ecx ; ECX for later use

    jmp is_supported

    not_supported:

        mov     rax, SYSCALL_WRITE
        mov     rdi, 1 ; stdout
        mov     rsi, not_supported_msg
        mov     rdx, not_supported_msg.len
        syscall
        jmp eax_3

    is_supported:
    ; If we reach here, CPUID with EAX=2 is supported.
    ; Assume EAX contains the value you want to check
    test eax, 0x80000000 ; Test bit 31 of EAX

    ; Option 1: Jump if bit 31 is set (result is not zero)
    jnz bit_31_eax_is_set   ; or JS bit_31_is_set (Jump if Sign Flag is set)



    ; Code for when bit 31 is NOT set
    ; ...
    jmp eax_value_valid

bit_31_eax_is_set:
    ; Code for when bit 31 IS set
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, eax_value_not_valid_msg
    mov rdx, eax_value_not_valid_msg.len
    syscall
    ; Optionally, you can print the EAX value here
    mov edx, eax
    call print_hex
    call print_line_change
    jmp eax_2_ebx_part


eax_value_valid:



    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, eax_2_instruction_msg
    mov rdx, eax_2_instruction_msg.len
    syscall

    ; ...
    mov    rax, SYSCALL_WRITE
    mov    rdi, 1 ; stdout
    mov    rsi, eax_2_ah_msg
    mov    rdx, eax_2_ah_msg.len
    syscall

    movzx dx, byte [eax_2_ah]
    call print_hex
    call print_line_change

    mov    rax, SYSCALL_WRITE
    mov    rdi, 1 ; stdout
    mov    rsi, eax_2_eax_1_msg
    mov    rdx, eax_2_eax_1_msg.len
    syscall

    mov dx, [eax_2_eax_1] ; Load the full EAX value for printing
    call print_hex
    call print_line_change

    mov    rax, SYSCALL_WRITE
    mov    rdi, 1 ; stdout
    mov    rsi, eax_2_eax_2_msg
    mov    rdx, eax_2_eax_2_msg.len
    syscall

    mov dx, [eax_2_eax_2] ; Load the full EAX value for printing
    call print_hex
    call print_line_change

    eax_2_ebx_part:

    mov ebx, [eax_2_ebx] ; Load original EBX value
    test ebx, 0x80000000
    jnz bit_31_ebx_is_set
    jmp eax_2_ebx_valid

    bit_31_ebx_is_set:
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, ebx_value_not_valid_msg
    mov rdx, ebx_value_not_valid_msg.len
    syscall
    ; Optionally, you can print the EAX value here
    mov edx, ebx
    call print_hex
    call print_line_change
    jmp eax_2_ecx_part

    eax_2_ebx_valid:
    ; If we reach here, EBX is valid
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, eax_2_bl_msg
    mov rdx, eax_2_bl_msg.len
    syscall
    ; Print the BL value (bits 0-7 of EBX)
    movzx dx, bl ; Load the BL value (bits 0-7 of EBX)
    call print_hex
    call print_line_change

    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, eax_2_bh_msg
    mov rdx, eax_2_bh_msg.len
    syscall
    movzx dx, bh ; Load the BX value (bits 8-15 of EBX)
    call print_hex
    call print_line_change


    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, eax_2_ebx1_msg
    mov rdx, eax_2_ebx1_msg.len
    syscall
    mov r8d, ebx
    shr r8d, 16
    and r8b, 0xFF ; This will be a byte
    movzx dx, r8b ; Move the byte value to DX for printing
    call print_hex
    call print_line_change

    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, eax_2_ebx2_msg
    mov rdx, eax_2_ebx2_msg.len
    syscall
    mov r8d, ebx
    shr r8d, 24
    and r8b, 0xFF ; This will be a byte
    movzx dx, r8b ; Move the byte value to DX for printing
    call print_hex
    call print_line_change


    eax_2_ecx_part:

    mov ecx, [eax_2_ecx] ; Load original ECX value
    test ecx, 0x80000000
    jnz bit_31_ecx_is_set
    jmp eax_2_ecx_valid

    bit_31_ecx_is_set:
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, ecx_value_not_valid_msg
    mov rdx, ecx_value_not_valid_msg.len
    syscall
    ; Optionally, you can print the EAX value here
    mov edx, ecx
    call print_hex
    call print_line_change
    jmp eax_2_edx_part

    eax_2_ecx_valid:
    ; If we reach here, ECX is valid
    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, eax_2_cl_msg
    mov rdx, eax_2_cl_msg.len
    syscall
    mov ecx, [eax_2_ecx] ; Load original ECX value
    movzx dx, cl ; Load the CL value (bits 0-7 of ECX)
    call print_hex
    call print_line_change

    mov rax, SYSCALL_WRITE
    mov rdi, 1 ; stdout
    mov rsi, eax_2_ch_msg
    mov rdx, eax_2_ch_msg.len
    syscall
    movzx dx, ch ; Load the CL value (bits 0-7 of ECX)
    call print_hex
    call print_line_change

    eax_2_edx_part:

    eax_3:



    ; EAX contains:


    ; ----------------------------------------------------------------------


    mov     rax, SYSCALL_EXIT ; EXIT
    mov     rdi, 0
    syscall

    ; ----------------------------------------------------------------------

    print_line_change:
		push rdi
		dec rdi
		mov rax, SYSCALL_WRITE
        mov rdi, 1 ; stdout
		mov rsi, line_change
		mov rdx, 2
		syscall
		imul rax, rdi
		pop rdi
		ret

%include "print_hex.asm"


section .data

instruction_msg: db "This program will call CPUID in order starting from EAX=0. It'll tell whenever CPUID was called, so the user can follow up on what the value of EAX is.", 10
instruction_msg.len: equ $ - instruction_msg

cpuid_called_msg: db "Calling CPUID!", 10
cpuid_called_msg.len: equ $ - cpuid_called_msg


cpu_vendor: db "xxxxxxxxxxxx", 0
.len:   equ     $ - cpu_vendor

cpu_vendor_message: db "The processor vendor ID is: ", 0
.len:   equ     $ - cpu_vendor_message
cpu_highest_calling_value: dd 0xFFFF, 0

cpu_highest_calling_message: db "The highest calling value is: ", 0
cpu_highest_calling_message.len: equ $ - cpu_highest_calling_message

; Storage for EAX=1 CPUID results and messages
stepping_id_msg: db "Stepping ID: ", 0
stepping_id_msg.len: equ $ - stepping_id_msg
model_id_msg: db "Model ID: ", 0
model_id_msg.len: equ $ - model_id_msg
family_id_msg: db "Family ID: ", 0
family_id_msg.len: equ $ - family_id_msg
processor_type_msg: db "Processor Type: ", 0
processor_type_msg.len: equ $ - processor_type_msg
ext_model_id_msg: db "Extended Model ID: ", 0
ext_model_id_msg.len: equ $ - ext_model_id_msg
ext_family_id_msg: db "Extended Family ID: ", 0
ext_family_id_msg.len: equ $ - ext_family_id_msg

not_supported_msg: db "CPUID with EAX being set at the current value is not supported by this CPU.", 10
not_supported_msg.len: equ $ - not_supported_msg

eax_2_instruction_msg: db "CPUID with EAX=2 is being called now. We will just display the values byte by byte, as their function can differ wildly between CPU models.", 10
eax_2_instruction_msg.len: equ $ - eax_2_instruction_msg

eax_value_not_valid_msg: db "Value of EAX doesn't seem valid and the result below should be discarded: ", 10
eax_value_not_valid_msg.len: equ $ - eax_value_not_valid_msg

ebx_value_not_valid_msg: db "Value of EBX doesn't seem valid and the result below should be discarded: ", 10
ebx_value_not_valid_msg.len: equ $ - ebx_value_not_valid_msg

ecx_value_not_valid_msg: db "Value of ECX doesn't seem valid and the result below should be discarded: ", 10
ecx_value_not_valid_msg.len: equ $ - ecx_value_not_valid_msg

edx_value_not_valid_msg: db "Value of EDX doesn't seem valid and the result below should be discarded: ", 10
edx_value_not_valid_msg.len: equ $ - edx_value_not_valid_msg

eax_2_ah_msg: db "AH value (representing bits 8-16 for EAX): ", 0
eax_2_ah_msg.len: equ $ - eax_2_ah_msg

eax_2_eax_1_msg: db "EAX value 1 (representing bits 16-24 for EAX): ", 0
eax_2_eax_1_msg.len: equ $ - eax_2_eax_1_msg

eax_2_eax_2_msg: db "EAX value 2 (representing bits 24-32 for EAX): ", 0
eax_2_eax_2_msg.len: equ $ - eax_2_eax_2_msg

eax_2_bl_msg: db "BL value (representing bits 1-8 for EBX): ", 0
eax_2_bl_msg.len: equ $ - eax_2_bl_msg

eax_2_bh_msg: db "BH value (representing bits 8-16 for EBX): ", 0
eax_2_bh_msg.len: equ $ - eax_2_bh_msg

eax_2_ebx1_msg: db "EBX value 1 (representing bits 16-24 for EBX): ", 0
eax_2_ebx1_msg.len: equ $ - eax_2_ebx1_msg

eax_2_ebx2_msg: db "EBX value 2 (representing bits 24-32 for EBX): ", 0
eax_2_ebx2_msg.len: equ $ - eax_2_ebx2_msg

eax_2_cl_msg: db "CL value (representing bits 1-8 for ECX): ", 0
eax_2_cl_msg.len: equ $ - eax_2_cl_msg

eax_2_ch_msg: db "CH value (representing bits 8-16 for ECX): ", 0
eax_2_ch_msg.len: equ $ - eax_2_ch_msg

stepping_id_val: resb 1
model_id_val:    resb 1
family_id_val:   resb 1
processor_type_val: resb 1
ext_model_id_val: resb 1
ext_family_id_val: resb 1

eax_2_ah: dd 0xFFFF, 0

eax_2_eax_1: resb 1 ; This is the byte value of EAX after shifting
eax_2_eax_2: resb 1

eax_2_eax: dd 0xFFFFFF, 0

eax_2_ebx: resd 1

eax_2_ecx: resd 1 ; Store ECX for later use

; Line change for output
line_change: db	" ", 10

; HEX_OUT is the output buffer for hexadecimal representation
HEX_OUT: dd '0x0000',0
HEX_OUT.len: equ $ - HEX_OUT
