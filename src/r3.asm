; BunnyOS 1.0
;
; Copyright (C) 2011 Wu Fuheng.
;
; BunnyOS is free software;  you can  redistribute it and/or modify it under
; the terms of the GNU LESSER GENERAL PUBLIC LICENSE as published by the
; Free Software Foundation; either version 2.1, or (at your option)  any
; later version.
; 
; BunnyOS is distributed in the hope that it will be useful, but WITHOUT ANY
; WARRANTY; without  even  the  implied  warranty  of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the  GNU General Public License
; for more details.
; 
; You  should  have  received  a  copy of the GNU General Public License
; along  with  BunnyOS;  see the  file COPYING.  If not, please write to the
; Free Software Foundation,  51 Franklin Street, Fifth Floor, Boston, MA
; 02110-1301, USA.

;*********************************************************************
[SECTION r3data]
BITS 32
ALIGN 32
start_r3data:
  mc_string r3str,"r3 data"
r3data_len equ $-start_r3data

;*********************************************************************
[SECTION r3text]
BITS 32
ALIGN 32
start_r3text:

  _syscall_get_jiffies equ 0
  iv_get_jiffies equ 90h

  _get_jiffies:
  get_jiffies equ _get_jiffies-$$
    ;mov eax, _syscall_get_jiffies
    int iv_get_jiffies
    retf

  _getpid:
  getpid equ _getpid-$$
    int 91h
    retf

  ;printf(const char*fmt,...);
  _printf:
  printf equ _printf-$$ ; push str16,str_len12
    ;mc_func_start
    ;sub esp, ONEKB
    ;add esp, ONEKB
    ;mc_func_end
    push  ebp
    mov ebp, esp
    mov ecx,[ebp+12]
    mov ebx,[ebp+16]
    pop ebp
    int 92h
    retf

  ;*** push 24msg, 20msg_len, 16row, 12column; call printline
  _printline:
  printline equ _printline-$$
    mc_func_start
    mov ecx, [ebp+16+4];len
    mov esi,0
  .1:
    ;mov eax, edi;disregard parameter row 
    mov eax, [ebp+12+4];row=3
    mov edx, 80
    mul edx ; mul will affect EDX!!!
    add eax, [ebp+8+4];column
    shl eax, 1
    mov edi, eax
    mov edx, [ebp+20+4]
    mov ebx,esi
    mov al, byte [ds:(edx+ebx)]
    mov ah, 0ch
    mov [fs:edi], ax
    inc esi
    inc dword [ebp+8+4]
    LOOP .1
    mc_func_end

  ;*** push 20014a7fh, addr; call num2str
  _num2str:
  num2str equ _num2str-$$
    push  ebp
    mov ebp, esp
    push  esi
    push  edi
    pushad

    mov edi, dword [ebp+12];address
    add edi, 8
    mov eax, dword [ebp+16];num
    mov ebx, eax
    mov ecx, 8
  .1:
    mov ebx, eax
    and ebx,0000000fh
    cmp bl, 9
    ja .2
    add bl, 48
    jmp .3
  .2:
    add bl, 55; lower 97
  .3:
    dec edi
    mov byte [edi], bl 
    shr eax, 4
    loop .1

    popad
    pop edi
    pop esi
    pop ebp
    retf

  ;*** push 102; call sleep_ms
  _sleep_ms:
  sleep_ms equ _sleep_ms - $$
    push  ebp
    mov ebp, esp
    push  esi
    push  edi
    pushad

    int 90h
    mov edi, eax
  .2
    int 90h
    sub eax, edi
    mov ecx, 1000/HZ
    mul ecx
    cmp eax, dword [ebp+12]
    jl .2

    popad
    pop edi
    pop esi
    pop ebp
    retf
    
r3text_len equ $-start_r3text

%macro r3print 4
    push %1;msg
    push %2;len
    push %3;row
    push %4;column
    call sel_r3text:printline ;*** far call
    add esp, 16
%endmacro

%macro Sleep 1
    push %1
    call sel_r3text:sleep_ms
    add esp, 4
%endmacro

%macro _printf_ 2
  push %1;msg
  push %2;len
  call sel_r3text:printf
  add esp, 4*2
%endmacro
%define bunny_printf(msg_,len_) _printf_ msg_,len_
;*********************************************************************
[SECTION ldt1]
BITS 32
ALIGN 32
start_ldt1:
ldt1_1: mc_descp 0, (ldt1code_len-1),  DA_CR+DA_32+DA_DPL3;***code
ldt1_2: mc_descp 0, (ldt1data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
ldt1_3: mc_descp 200000h, d_proc_stacksize, DA_DRWA+DA_32+DA_DPL3;***stack

sel_ldt1code equ  111b
sel_ldt1data equ  ldt1_2-ldt1_1+111b
sel_ldt1stack equ ldt1_3-ldt1_1+111b

ldt1_len equ $-start_ldt1

; harddisk process
;*********************************************************************
%define ldt1dataaddr(X) (X-start_ldt1data)
[SECTION ldt1DATA]
BITS 32
ALIGN 32
start_ldt1data:
  mc_string p1data, {"hardisk process is running",0Ah}
  ;mc_string p1strfmt, "%s %d"
  ;mc_string p1name, {"Process 1", 0Ah," +printf", 0ah, 0Ah}
  ;mc_string p1name, {"simonwoo"}
ldt1data_len equ $-start_ldt1data

;*********************************************************************
[SECTION ldt1CODE]
BITS 32
ALIGN 32
start_ldt1code:
  mov ax, sel_ldt1data
  mov ds, ax
  bunny_printf(ldt1dataaddr(p1data),p1data_len)
  ;push ldt1dataaddr(p1name)
  ;push p1name_len
  ;call sel_r3text:printf
  ;add esp, 4*2

  ;r3print ldt1dataaddr(p1data),p1data_len,1,1
  ;.1:
  ;  inc byte [fs:((80 * 1 + p1data_len) * 2)]
  ;  Sleep 1000
  ;  jmp .1
  jmp $
ldt1code_len equ $-start_ldt1code


;*********************************************************************
[SECTION ldt2]
BITS 32
ALIGN 32
start_ldt2:
ldt2_1: mc_descp 0, (ldt2code_len-1),  DA_CR+DA_32+DA_DPL3;***code
ldt2_2: mc_descp 0, (ldt2data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
ldt2_3: mc_descp 210000h, d_proc_stacksize, DA_DRWA+DA_32+DA_DPL3;***stack

sel_ldt2code equ  111b
sel_ldt2data equ  ldt2_2-ldt2_1+111b
sel_ldt2stack equ ldt2_3-ldt2_1+111b

ldt2_len equ $-start_ldt2

;*********************************************************************
%define ldt2dataaddr(X) (X-start_ldt2data)
[SECTION ldt2DATA]
BITS 32
ALIGN 32
start_ldt2data:
  mc_string p2data, {"I am proc 2 in ring 3.",0ah}
ldt2data_len equ $-start_ldt2data

;*********************************************************************
[SECTION ldt2CODE]
BITS 32
ALIGN 32
start_ldt2code:
  mov ax, sel_ldt2data
  mov ds, ax
  bunny_printf(ldt2dataaddr(p2data),p2data_len)

  ;r3print ldt2dataaddr(p2data),p2data_len,2,1
  ;.1:
  ;  inc byte [fs:((80 * 2 + p2data_len) * 2)]
  ;  Sleep 500
  ;  jmp .1
  jmp $

ldt2code_len equ $-start_ldt2code

;*********************************************************************
[SECTION ldt3]
BITS 32
ALIGN 32
start_ldt3:
ldt3_1: mc_descp 0, (ldt3code_len-1),  DA_CR+DA_32+DA_DPL3;***code
ldt3_2: mc_descp 0, (ldt3data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
ldt3_3: mc_descp 220000h, d_proc_stacksize, DA_DRWA+DA_32+DA_DPL3;***stack

sel_ldt3code equ  111b
sel_ldt3data equ  ldt3_2-ldt3_1+111b
sel_ldt3stack equ ldt3_3-ldt3_1+111b

ldt3_len equ $-start_ldt3

;*********************************************************************
%define ldt3dataaddr(X) (X-start_ldt3data)
[SECTION ldt3DATA]
BITS 32
ALIGN 32
start_ldt3data:
  mc_string p3data, {"I am proc 3 in ring 3.", 0ah}
  pid3: times 8 db 0
ldt3data_len equ $-start_ldt3data

;*********************************************************************
[SECTION ldt3CODE]
BITS 32
ALIGN 32
start_ldt3code:
  mov ax, sel_ldt3data
  mov ds, ax
  bunny_printf(ldt3dataaddr(p3data),p3data_len)
  ;r3print ldt3dataaddr(p3data),p3data_len,3,1
  ;call sel_r3text:getpid
  ;push eax
  ;push ldt3dataaddr(pid3)
  ;call sel_r3text:num2str
  ;add esp, 8
  ;r3print ldt3dataaddr(pid3),8,3,(p3data_len+6)
  ;.1:
  ;  inc byte [fs:((80 * 3 + p3data_len) * 2)]
  ;  Sleep 100
  ;  jmp .1
  jmp $
ldt3code_len equ $-start_ldt3code

;*********************************************************************
[SECTION ldt4]
BITS 32
ALIGN 32
start_ldt4:
ldt4_1: mc_descp 0, (ldt4code_len-1),  DA_CR+DA_32+DA_DPL3;***code
ldt4_2: mc_descp 0, (ldt4data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
ldt4_3: mc_descp 230000h, d_proc_stacksize, DA_DRWA+DA_32+DA_DPL3;***stack

sel_ldt4code equ  111b
sel_ldt4data equ  ldt4_2-ldt4_1+111b
sel_ldt4stack equ ldt4_3-ldt4_1+111b

ldt4_len equ $-start_ldt4

;*********************************************************************
%define ldt4dataaddr(X) (X-start_ldt4data)
[SECTION ldt4DATA]
BITS 32
ALIGN 32
start_ldt4data:
  mc_string p4data, "I am proc 4 in ring 3 - jiffies -"
  strx: times 8 db 0
ldt4data_len equ $-start_ldt4data

;*********************************************************************
[SECTION ldt4CODE]
BITS 32
ALIGN 32
start_ldt4code:
  bunny_printf(ldt4dataaddr(p4data),p4data_len)
  ;r3print ldt4dataaddr(p4data),p4data_len,4,1
  call proc4
  ;jmp $

  proc4:
  .1:
    call sel_r3text:get_jiffies
    push eax
    push ldt4dataaddr(strx)
    call sel_r3text:num2str
    add esp, 8
    ;bunny_printf(ldt4dataaddr(strx),8)
    r3print ldt4dataaddr(strx),8,3,(p4data_len+2)
    Sleep 10000
    jmp .1
    ret
  jmp $

    
    
ldt4code_len equ $-start_ldt4code
