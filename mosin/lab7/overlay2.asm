code_ segment
	assume cs:code_

address db 'overlay2 address:          ',0dh,0ah,'$'

overlay proc far
	mov ax,cs
	mov ds,ax
	mov bx,offset address+16
	mov di,bx
	mov ax,cs
	call wrd_to_hex
	mov dx,offset address
	call print
	retf
overlay endp

wrd_to_hex proc near
	push bx
	mov bh,ah
	call byte_to_hex
	mov [di],ah
	dec di
	mov [di],al
	dec di
	mov al,bh
	xor ah,ah
	call byte_to_hex
	mov [di],ah
	dec di
	mov [di],al
	pop bx
	ret
wrd_to_hex endp

byte_to_hex proc near
	push cx
	mov ah,al
	call tetr_to_hex
	xchg al,ah
	mov cl,4
	shr al,cl
	call tetr_to_hex
	pop cx
	ret
byte_to_hex endp

tetr_to_hex proc near
	and al,0fh
	cmp al,09
	jbe next
	add al,07
next:
	add al,30h
	ret
tetr_to_hex endp

print proc near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
print endp

code_ ends
end