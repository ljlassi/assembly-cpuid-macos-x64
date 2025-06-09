; print_hex.asm is literally for printing hex. It's partially linked with main.asm though as in this case
; it is used to print the hex values of various CPU features.

section .data
hex_zero_val: db "0x0" ; String for value 0
; No .len needed as length 3 is hardcoded

section .text

print_hex:
  push rax          ; Save 64-bit registers
  push rbx
  push rcx
  push rdx
  push rsi          ; Save rsi
  push rdi          ; Save rdi
  push r8           ; Save r8
  push r9           ; Save r9
  push r10          ; Save r10

  ; Input value is in dx (16-bit)

  ; Handle dx == 0 case: print "0x0"
  test dx, dx
  jnz .process_non_zero_val

  ; Value is 0
  mov rsi, hex_zero_val ; Address of "0x0"
  mov rdx, 3              ; Length of "0x0"
  call print_string
  jmp .print_hex_cleanup

.process_non_zero_val:
  ; HEX_OUT is defined in main.asm, e.g., db "0x0000",0. We use it as a buffer.
  ; HEX_OUT structure: '0' 'x' H1 H2 H3 H4
  ; H1 is Most Significant Nibble, H4 is Least Significant Nibble.

  mov r10w, dx      ; Copy dx to r10w for manipulation
  mov rbx, HEX_OUT  ; Base address of HEX_OUT
  add rbx, 2        ; rbx now points to where H1 (MSN) should go (HEX_OUT[2])
  mov rcx, 4        ; Loop 4 times for 4 nibbles

.conversion_loop:
  dec rcx           ; rcx will be 3, 2, 1, 0 (used as index from right to left for storing)
                    ; Iteration 1 (rcx=3): processes LSN, stores at HEX_OUT[2+3] = HEX_OUT[5]
                    ; Iteration 4 (rcx=0): processes MSN, stores at HEX_OUT[2+0] = HEX_OUT[2]

  mov ax, r10w      ; Copy current r10w to ax
  shr r10w, 4       ; Shift r10w right by 4 bits for the next nibble
  and al, 0x0F      ; Isolate the LSB nibble of ax (which is current LSN of r10w before shift)

  ; Convert nibble in al to ASCII character
  cmp al, 0x0A
  jl .is_digit_convert
  add al, 7         ; For 'A'-'F' (ASCII 'A' - ASCII '9' - 1 = 65 - 57 - 1 = 7)
.is_digit_convert:
  add al, '0'       ; Convert to '0'-'9' or 'A'-'F'

  mov byte [rbx + rcx], al  ; Store the character.
                            ; MSN at [rbx+0], LSN at [rbx+3]

  test rcx, rcx     ; Check if rcx is 0
  jnz .conversion_loop ; If not zero, loop again

  ; At this point, HEX_OUT[2] to HEX_OUT[5] contain the 4 hex digits.
  ; e.g., if dx=0xAF, HEX_OUT is "0x00AF"
  ; e.g., if dx=0xF,  HEX_OUT is "0x000F"

  ; Find the first significant digit and number of significant digits
  mov r8, HEX_OUT + 2 ; r8 points to the first hex digit (H1)
  mov r9, 4           ; r9 is the count of hex digits to consider

.skip_leading_zeros_loop:
  cmp r9, 1           ; If only one digit left, don't skip it (e.g. for "0x000F", we print "F")
  jle .found_significant_digits_info

  cmp byte [r8], '0'  ; Check if current digit is '0'
  jne .found_significant_digits_info ; If not '0', we found the start

  ; It's a leading zero, and not the last potential digit
  inc r8              ; Move pointer to the next digit
  dec r9              ; Decrement count of significant digits
  jmp .skip_leading_zeros_loop

.found_significant_digits_info:
  ; r8 points to the first significant hex digit.
  ; r9 contains the number of significant hex digits.

  ; Move the significant digits to start right after "0x" in HEX_OUT buffer
  mov rdi, HEX_OUT + 2 ; Destination: HEX_OUT[2]
  mov rsi, r8          ; Source: first significant digit
  mov rcx, r9          ; Count: number of significant digits

.copy_significant_digits_loop:
  test rcx, rcx
  jz .prepare_to_print
  mov al, byte [rsi]
  mov byte [rdi], al
  inc rsi
  inc rdi
  dec rcx
  jmp .copy_significant_digits_loop

.prepare_to_print:
  ; Now HEX_OUT contains "0x" followed by the significant digits.
  ; Calculate final length to print: 2 (for "0x") + r9 (num_significant_digits)
  add r9, 2           ; r9 now holds the total length
  mov rsi, HEX_OUT
  mov rdx, r9         ; Length of the string to print
  call print_string

.print_hex_cleanup:
  ; Clean up the stack and return
  pop r10
  pop r9
  pop r8
  pop rdi
  pop rsi
  pop rdx
  pop rcx
  pop rbx
  pop rax
  ret               ; return from the function

print_string:
    ; rsi already contains the address of the string (from caller)
    ; rdx already contains the length of the string (from caller)

    push rax          ; Preserve rax
    push rdi          ; Preserve rdi
    ; SYSCALL_WRITE is defined in main.asm
    mov rax, 0x2000004 ; syscall number for write on macOS
    mov rdi, 1         ; 1 is stdout
    ; rsi is already the string address
    ; rdx is already the string length
    syscall

    pop rdi            ; Restore rdi
    pop rax            ; Restore rax
    ret
