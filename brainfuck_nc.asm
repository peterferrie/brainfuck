;non-compliant (dialect) version, non-commands are not ignored, only 100 bytes

[bits 16]  
[org 0x100]  
; assume bp=091e used  
; assume di=fffe  
; assume si=0100  
; assume dx=cs (see here)  
; assume cx=00ff  
; assume bx=0000  
; assume ax=0000 used (ah)  
; assume sp=fffe  
start:
        mov al, code_left - start  
code_start:
        mov ch, 0x7f ; allow bigger programs  
        mov bx, cx  
        mov di, cx  
        rep stosb  
        mov bp, find_right + start - code_start ;cache loop head for smaller compiled programs  
        jmp code_start_end  
find_right:
        pop si  
        dec si  
        dec si ;point to loop head  
        cmp [bx], cl  
        jne loop_right_end  
loop_right:
        lodsb  
        cmp al, 0xD5 ; the "bp" part of "call bp" (because 0xFF is not unique, watch for additional '[')  
        jne loop_left  
        inc cx  
loop_left:
        cmp al, 0xC3 ; ret (watch for ']')  
        jne loop_right  
        loop loop_right ;all brackets matched when cx==0  
        db 0x3c ;cmp al, xx (mask push)  
loop_right_end:
        push si  
        lodsw ; skip "call" or dummy "dec" instruction, depending on context  
        push si  
code_sqright:
        ret  
code_dec:
        dec byte [bx]  
code_start_end:
        db '$' ;end DOS string, also "and al, xx"  
code_inc:
        inc byte [bx]  
        db '$'  
code_right:
        inc bx ;al -> 2  
        db '$'  
code_left:
        dec bx  
        db '$'  
code_sqleft:
        call bp  
        db '$'  
; create lookup table  
real_start:
        sub byte [bx+'>'], al ;point to code_right  
        add byte [bx+'['], al ;point to code_sqleft  
        mov byte [bx+']'], code_sqright - start  
        lea sp, [bx+45+2] ;'+' + 4 (2b='+', 2c=',', 2d='-', 2e='.')  
        push (code_dec - start) + (code_dot - start) * 256  
        push (code_inc - start) + (code_comma - start) * 256  
pre_write:
        mov ah, code_start >> 8  
        xchg dx, ax  
; write  
        mov ah, 9  
        int 0x21  
; read  
code_comma:
        mov dl, 0xff  
        db 0x3d ; cmp ax, xxxx (mask mov)  
code_dot:
        mov dl, [bx]  
        mov ah, 6  
        int 0x21  
        mov [bx], al  
        db '$'  
        db 0xff ; parameter for '$', doubles as test for zero  
; switch  
        xlatb  
        jne pre_write  
  ; next two lines can also be removed  
  ; if the program ends with extra ']'  
  ; and then we are at 96 bytes... :-)  
the_end:
        mov dl, 0xC3  
        int 0x21  
        int 0x20 
