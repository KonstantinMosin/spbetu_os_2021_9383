stack_ segment stack
	dw 256 dup(?)
stack_ ends

data_ segment
	interruption_already_load db 'Interruption_already_load',0dh,0ah,0dh,0ah,'$'
	interruption_load db 'Interruption_load',0dh,0ah,0dh,0ah,'$'
	interruption_delete db 'Interruption_was_delete',0dh,0ah,0dh,0ah,'$'
data_ ends

code_ segment
	assume cs:code_, ds:data_, ss:stack_

rout proc far
	jmp body
	
	int_seg dw 256 dup(0)
	int_sig dw 0ffffh
	keep_ip dw 0
	keep_cs dw 0
	keep_psp dw 0
	keep_ax dw 0
	keep_ss dw 0
	keep_sp dw 0
	int_counter db 'interruption_counter: 0000$'

body:
	mov keep_ax,ax
	mov keep_sp,sp
	mov keep_ss,ss
	
	mov ax,seg int_seg
	mov ss,ax
	mov ax,offset int_seg
	add ax,256
	mov sp,ax
	
	mov ax,keep_ax
	
	in al,60h
	cmp al,10h
	je input_w
	cmp al,12h
	je input_r
	
	call dword ptr cs:[keep_ip]
	jmp rout_end_ptr
input_w:
	mov al,'w'
	jmp do_req
input_r:
	mov al,'r'

do_req:
	push ax
	in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    xchg ah, al
    out 61h, al
    mov al, 20H
    out 20h, al
	pop ax

loop_:
	mov ah, 05h
    mov cl, al
    mov ch, 00h
    int 16h
    or al, al
    jz rout_end_ptr
    mov ax, 40h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp loop_

rout_end_ptr:
	mov sp,keep_sp
	mov ax,keep_ss
	mov ss,ax
	mov ax,keep_ax
	mov al,20h
	out 20h,al
	iret
rout endp

is_interruption_load proc far
	push bx
	push si

	mov ah, 35h
	mov al, 1ch
	int 21h
	
	mov si, offset int_sig
	sub si, offset rout
	mov dx, es:[bx + si]
	cmp dx, int_sig
	jne not_loaded
	mov ax, 1h
    jmp is_loaded_exit

not_loaded:
    mov ax, 0h

is_loaded_exit:
	pop si
	pop bx

    ret
is_interruption_load endp

load_interruption proc far
	push ax
    push bx
    push cx
    push dx
    push es
    push ds



	mov ah,35h
	mov al,1ch
	int 21h
	
	mov keep_cs,es
	mov keep_ip,bx
	

	mov dx, offset rout
	mov ax, seg rout
	mov ds,ax
	
	mov ah,25h
	mov al,1ch
	int 21h
	
	pop ds

	mov dx,offset interruption_load
	call print
	
	mov dx, offset rout_end_ptr
	mov cl,4h
	shr dx,cl
	inc dx
	
	add dx,100h
	xor ax,ax
	
	mov ah,31h
	int 21h


	pop es
    pop dx
    pop cx
    pop bx
    pop ax
	ret
load_interruption endp

delete_interruption proc
	cli
    
    push ax
    push bx
    push dx
    push ds
    push es
    push si

    mov ah, 35h
    mov al, 1ch
    int 21h
    mov si, offset keep_ip
    sub si, offset rout
    mov dx, es:[bx + si]
    mov ax, es:[bx + si + 2]

    push ds
    mov ds, ax
    mov ah, 25h
    mov al, 1ch
    int 21h
    pop ds

    mov ax, es:[bx + si + 4]
    mov es, ax
    push es
    mov ax, es:[2ch]
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

    sti

	push dx
	mov dx,offset interruption_delete
	call print
	pop dx

    pop si
    pop es
    pop ds
    pop dx
    pop bx
    pop ax
	ret
delete_interruption endp

print proc near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
print endp

check_cmd proc far
	push es
	mov ax, keep_psp
    mov es, ax

	
    mov al, es:[81h+1]
	cmp al, '/'
	jne set_zero
	
	mov al, es:[81h+2]
	cmp al, 'u'
	jne set_zero
	
	mov al, es:[81h+3]
	cmp al, 'n'
	jne set_zero

    mov ax, 1h
    jmp check_cmd_exit

set_zero:
    mov ax, 0h

check_cmd_exit:
	pop es
    ret
check_cmd endp

main proc far
	mov ax,data_
	mov ds,ax
	mov keep_psp,es
	
	push es
	
	call is_interruption_load
	cmp ax,0h
	jne check_cmd_line
	
	call load_interruption
	pop es
	jmp exit
	
check_cmd_line:
	pop es
	call check_cmd
	cmp ax,0h
	je already_load
	call delete_interruption
	jmp exit

already_load:
	mov dx,offset interruption_already_load
	call print

exit:
	xor al,al
	mov ah,4ch
	int 21h
main endp

code_ ends
end main