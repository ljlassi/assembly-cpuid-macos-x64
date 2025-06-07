; print_hex.asm is literally for printing hex. It's partially linked with main.asm though as in this case
; it is used to print the hex values of various CPU features.

print_hex:
  push rax          ; Save 64-bit registers
  push rbx
  push rcx
  push rdx

  mov rcx, 4        ; Use rcx as a 64-bit counter

  mov rbx, HEX_OUT  ; Load base address of HEX_OUT into rbx. NASM handles RIP-relative addressing.
  add rbx, 2        ; rbx points to the start of "0000" part. This is done once before the loop.

char_loop:
  dec rcx           ; rcx will be 3, 2, 1, 0

  mov ax, dx        ; copy dx into ax so we can mask it for the last chars
  shr dx, 4         ; shift dx 4 bits to the right
  and ax, 0x000F    ; mask ax to get the last 4 bits (current nibble)

  ; Convert nibble in al to ASCII character (example for uppercase 'A'-'F')
  cmp al, 0x0A
  jl is_digit
  add al, 7         ; For 'A'-'F'
is_digit:
  add al, 0x30      ; Convert to '0'-'9' or 'A'-'F'

  mov byte [rbx + rcx], al  ; Store the character. rbx is base, rcx is index.

  test rcx, rcx     ; Check if rcx is 0
  je print_hex_done ; if the counter is 0, finish
  jmp char_loop     ; otherwise, loop again

print_hex_done:
  
  mov rsi, HEX_OUT  ; print the string pointed to by HEX_OUT
  mov rdx, HEX_OUT.len        ; Length of "0x0000" is 6
  call print_string

  ; Clean up the stack and return
  pop rdx
  pop rcx
  pop rbx
  pop rax
  ret               ; return the function

print_string:
    ; rsi already contains the address of the string (from caller)
    ; rdx already contains the length of the string (from caller)

    push rax          ; Preserve rax
    push rdi          ; Preserve rdi

    mov rax, 0x2000004 ; syscall number for write on macOS
    mov rdi, 1         ; 1 is stdout
    ; rsi is already the string address
    ; rdx is already the string length
    syscall            

    pop rdi            ; Restore rdi
    pop rax            ; Restore rax
    ret