global main
section .text
main:
	push rbp
	mov rbp, rsp
	mov rdi, 0xffffffffffffffff
	call print_uint
	leave
	ret

exit:
	xor rax, rax
	mov al, 60
	syscall
	ret

string_length:
    xor rax, rax
	jmp .compare
	.loop_through_string:
		inc rax
	.compare:
		cmp byte [rdi+rax], 0
		jne .loop_through_string
    ret

print_string:
    xor rax, rax
	call string_length
	mov rdx, rax
	mov rsi, rdi
	mov rdi, 1		; stdout
	mov rax, 1		; write
	syscall
	ret


print_char:
	push rdi
	mov rdi, rsp
	call print_string
	pop rdi
	ret

print_newline:
    mov rdi, 0xa
	jmp print_string


print_uint:
    xor rax, rax
   	mov rax, rdi
	sub rsp, 24
	
	mov byte [rsp+20], 0
	mov rdi, rsp 

	mov r8, 19
	mov r9, 10

	.loop_through_value:
		xor rdx, rdx
		div r9
		add dl, 0x30
		mov byte [rdi+r8], dl
		dec r8
		test rax, rax
		jnz .loop_through_value

	lea rdi, [rsp+r8+1]
	call print_string
	add rsp, 24
	ret


print_int:
    test rdi, rdi
	jns print_uint
	push rdi
	mov rdi, '-'
	call print_char
	pop rdi
	neg rdi ; -1 --> 1
	call print_uint
	ret

; rdi: ptr to first string
; rsi: ptr to second string
string_equals:
    xor rax, rax
	xor rdx, rdx
	xor r8, r8
	mov dl, byte [rsi]
	jmp .compare

	.loop_through_strings:
		inc rsi
		inc rdi
    	mov dl, byte [rsi]
	.compare:
		cmp byte [rdi], dl
		jne .ret_0
	.check_for_null_byte:
		cmp byte [rdi], 0
		je .check_for_sec_str
		jmp .loop_through_strings
	.check_for_sec_str:
		test dl, dl
		jz .ret_1
	.ret_0:
		xor rax, rax
		ret
	.ret_1:
		mov rax, 1
		ret

read_char:
    xor rax, rax
	push 0
    mov rdx, 1
	mov rsi, rsp
	mov rdi, 0
	syscall
	pop rax
	ret 

read_word:
	mov r8, rsi
	dec r8
	
	mov r9, 0
	
	.first_char_must_be_typed:
		push rdi
		call read_char
		pop rdi
		cmp al, ' '
		je .first_char_must_be_typed
		cmp al, 0xa
		je .first_char_must_be_typed
		cmp al, 9
		je .first_char_must_be_typed
		cmp al, 13
		je .first_char_must_be_typed
		test al, al
		jz .correct_ret
		
	.loop_through_word:
		mov byte [rdi+r9], al
		inc r9
		push rdi
		call read_char
		pop rdi
		cmp al, ' '
		je .correct_ret
		cmp al, 0xa
		je .correct_ret
		cmp al, 9
		je .correct_ret
		cmp al, 13
		je .correct_ret
		test al, al
		jz .correct_ret
		cmp r9, r8
		ja .too_long
		jmp .loop_through_word

	.correct_ret:
		mov byte [rdi+r9], 0
		mov rax, rdi
		mov rdx, r9
		ret
	.too_long:
		xor rax, rax
		ret

; rdi points to a string
; returns rax: number, rdx : length
parse_uint:
    xor rax, rax
	xor rcx, rcx
	mov r8, 10

	.loop_through_str:
		mov r9b, byte [rdi+rcx]
		cmp r9b, '0'
		jb .end
		cmp r9b, '9'
		ja .end
		inc rcx
		and r9, 0x0f
		xor rdx, rdx
		mul r8
		add rax, r9
		jmp .loop_through_str
	.end:
		mov rdx, rcx
		ret
	

; rdi points to a string
; returns rax: number, rdx : length
parse_int:
    xor rax, rax
    xor rcx, rcx
	mov cl, byte [rdi+0]
	cmp cl, '-'
	jne .dont_increment_ptr
	inc rdi
	.dont_increment_ptr:
		push rcx
		call parse_uint
		pop rcx
		cmp cl, '-'
		jne .unsigned
		.signed:
			neg rax
			inc rdx
		.unsigned:
			ret 


string_copy:
	xor r8, r8
	call string_length
	cmp rax, rdx
	jae .too_long
	.loop_through_string:
		mov dl, [rdi+r8]
		test dl, dl
		jz .correct_ret
		mov byte [rsi+r8], dl
		inc r8
		jmp .loop_through_string
	.too_long:
		xor rax, rax
		ret
	.correct_ret:
		mov byte [rsi+r8], 0
		mov rax, rdi
		ret

section .data
word_buff times 20 db 0xca
test_str db "0", 0
