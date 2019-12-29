assume cs:code,ds:data
 
data segment
	dw 200 dup(0)	;--蛇身坐标
	dw 0,0,0		;--存储原始9号中断
data ends
 
stack segment 
	db 100 dup(0)
stack ends
 
code segment
 
start:
;;-----------------将原始的9号中断存在data断的最后，再把9号地址换掉到offset int9
	mov ax,0
	mov es,ax
 
	mov ax,data
	mov ds,ax
 
	push es:[9*4]
	pop ds:[400]
 
	push es:[9*4+2]
	pop ds:[402]
	
	mov word ptr es:[9*4],offset int9
	mov word ptr es:[9*4+2],cs
 
;;------------------
	mov ax,stack
	mov ss,ax
	mov sp,100
 
        mov ax,0b800h
        mov es,ax
;;-----------------snake的初始化
        mov bx,0
 
        mov cx,10
s:      mov ds:[bx],cx
        add bx,2
        loop s
	mov word ptr ds:[404],9
 
	call putfood
	mov  bx,0001h
	mov cx,60000
s1:
	call movnext
	call delay
 
        loop s1
 
;;------------恢复中断向量,程序结束
end_snake:
	mov ax,0
	mov es,ax
 
	push ds:[400]
	pop es:[9*4]
	push ds:[402]
	pop es:[9*4+2]
 
	mov ax,4c00h
        int 21h
;------------------------------壁障=遇到墙壁或者咬到自己就退出
die_or_not:
	cmp dl,-1
	je die
 
	cmp dl,80
	je die
 
	cmp dh,-1
	je die
 
	cmp dh,50
	je die
 
	call putchar
	cmp byte ptr es:[di],0fh
	je die
 
	jmp no_die
die:
 	jmp end_snake
 
no_die:
	ret
;------------------------------移动蛇身的
movnext:
        push dx
        push cx
        push ax
 
        mov si,0
        mov dx,ds:[si]
	mov ax,dx
cli
	add dh,bh
	add dl,bl
sti
	call die_or_not
        mov  ds:[si],dx
 
	call putchar
	cmp word ptr es:[di],0403h
	mov word ptr es:[di],0A0fh
	jne pc_go
 
	mov di,ds:[404]
	add di,di
 
	push ds:[di]
	pop ds:[di+2]
	inc word ptr ds:[404]
	call putfood
pc_go:
 
mn1:	
	add si,2
	cmp word ptr ds:[si],0
	je mn_ok
 
	mov dx,ds:[si]
	call putchar
	mov word ptr es:[di],0
 
        mov dx,ax
	call putchar
	mov word ptr es:[di],0A0fh
 
	mov ax,ds:[si]
        mov ds:[si],dx
	jmp mn1
 
mn_ok:  pop ax
        pop cx
        pop dx
ret
;;----------int9-----------------上48 下50  左4B   右4D
int9:
	push ax
	push es
	push cx
 
	in al,60h
	pushf
	
	call dword ptr ds:[400]
	cmp bl,0
	je zy
	
sx:
	cmp al,48h
	jne int9x1
	mov bx,0ff00h	
int9x1:
	cmp al,50h
	jne int9x2
	mov bx,0100h
 
int9x2:	jmp int9ok
 
zy:
	cmp al,4bh
	jne int9x3
	mov bx,00ffh	
int9x3:	
	cmp al,4Dh
	jne int9x4
	mov bx,0001h
int9x4:
 
int9ok:
	pop cx
	pop es
	pop ax
 
	iret
int9_end:nop
;--------------------------------
putchar:
	push dx
	push ax
 
	mov ax,00a0h
	mul dh
	mov dh,0
	add dl,dl
	add ax,dx
	mov di,ax
 
	pop ax
	pop dx
ret
;---------------------------------
delay:
	push cx
 
	mov ch,0bh
 
	cmp word ptr ds:[404],24
	ja level4
        cmp word ptr ds:[404],20
	ja level3
	cmp word ptr ds:[404],15
	ja level2
	cmp word ptr ds:[404],12
	ja level1
 
	jmp normal
 
level4:
	shr ch,1
	shr ch,1
level3:
	shr ch,1
 
level2:
	shr ch,1
 
level1: shr ch,1
 
normal:	
 
	mov cl,0ffh
	dn1:
	push cx
	mov cx,0ffffh 
	dn2:loop dn2
	
	pop cx 
	loop dn1
	pop cx
ret
;;-----------------------------------根据时间变化随机产生食物
 
putfood:
        push ax
        push dx
	push cx
 	push bx
put_again:
 
	mov al,0
	out 70h,al
	in al,71h
	
	mov ah,al
	mov cl,4
	shr ah,cl	 ;秒数十位在ah  个位在al
 
	and al,00001111b
	push ax
	
	mov ah,0
	
	mov dh,8
	mul dh
	mov dl,al
	
	pop ax
 
	sub al,al
	mov al,ah
	add al,dl
 
	mov cl,23
	div cl
 
	mov dh,ah
;;-------------------防止随机产生的食物，在蛇身上
	mov cx,ds:[404]
	mov bx,0
pt1:	cmp word ptr ds:[bx],dx
	je put_again
	add bx,2
	loop pt1
;;-------------------
	call putchar
	mov word ptr es:[di],0403h
 
pf_end: pop bx
	pop cx
        pop dx
        pop ax
ret
 
code ends
end start