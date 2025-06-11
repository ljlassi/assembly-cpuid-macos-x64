section .data
binary_print_buffer: times 32 db ' ' ; Buffer for 32 binary digits
binary_print_buffer_len: equ 32      ; Length of the buffer (32 characters)
binary_zero_string:  db "0"          ; String for value 0
binary_zero_string_len: equ $ - binary_zero_string

section .text
; NOTE: This is mainly for USE IN main.asm.
; Prints the 32-bit value in EDX as a binary string, without leading zeros.
; Prints "0" if EDX is 0.
; Assumes SYSCALL_WRITE is defined externally (e.g., in main.asm).
;
; Input:
;   EDX - The 32-bit value to print.
;
; Registers used internally: RAX, RBX, RCX, RDX, RSI, RDI, R8, R9, R10, AL.
; All these are preserved for the caller via push/pop.
print_binary:
    push rax
    push rbx
    push rcx
    push rdx ; Save original RDX (which contains the input EDX)
    push rsi
    push rdi
    push r8
    push r9  ; Used for finding first significant bit
    push r10 ; Used for finding first significant bit

    mov r8d, edx            ; Copy the input 32-bit value (edx) to r8d for manipulation.

    ; Handle input 0 separately
    test r8d, r8d
    jnz .process_non_zero_binary

.print_zero_val:
    mov rsi, binary_zero_string
    mov rdx, binary_zero_string_len
    jmp .do_print_binary

.process_non_zero_binary:
    ; --- Convert to 32-bit binary string in buffer ---
    mov rdi, binary_print_buffer ; RDI points to the start of our output buffer.
    mov rcx, 32             ; Loop 32 times for 32 bits.
    ; r8d (copy of original edx) is used for conversion.

.conversion_loop_binary:
    mov al, '0'             ; Assume current bit is '0'.
    test r8d, 0x80000000    ; Test the MSB of r8d.
    jz .store_char_binary   ; If the MSB was 0 (Zero Flag is set), jump to store '0'.

    mov al, '1'             ; Else, the MSB was 1.

.store_char_binary:
    mov [rdi], al           ; Store the character ('0' or '1') into the buffer.
    inc rdi                 ; Move to the next position in the buffer.
    shl r8d, 1              ; Shift r8d left by 1. The next bit to check is now at the MSB position.

    dec rcx                 ; Decrement loop counter.
    jnz .conversion_loop_binary ; If rcx is not zero, loop again.

    ; --- Find first significant '1' in the buffer ---
    ; binary_print_buffer now contains the 32-bit string.
    ; r9 will be the pointer to the first significant digit.
    ; r10 will be the length of the significant part.
    mov r9, binary_print_buffer      ; Start scanning from the beginning of the buffer.
    mov r10, binary_print_buffer_len ; Initial length is 32.

.skip_leading_zeros_binary_loop:
    cmp r10, 1              ; If only one digit left, don't skip it.
                            ; This ensures "1" is printed for 0b0...01.
    jle .found_significant_binary_digits ; Length is 1 or less, we're done.

    cmp byte [r9], '0'
    jne .found_significant_binary_digits ; Found a '1'. r9 points to it. r10 is current length from this point.

    ; It's a leading '0', and we have more than 1 digit left.
    inc r9                  ; Move scan pointer to the next char.
    dec r10                 ; Reduce the length of the significant part.
    jmp .skip_leading_zeros_binary_loop

.found_significant_binary_digits:
    ; r9 points to the first significant binary digit.
    ; r10 contains the number of significant binary digits.
    mov rsi, r9             ; Set RSI for syscall (address of string).
    mov rdx, r10            ; Set RDX for syscall (length of string).

.do_print_binary:
    ; rsi points to the string to print.
    ; rdx contains the length of the string.
    mov rax, SYSCALL_WRITE  ; syscall number for write (defined in main.asm).
    mov rdi, 1              ; stdout file descriptor.
    syscall

    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx ; Restore original RDX.
    pop rcx
    pop rbx
    pop rax
    ret
