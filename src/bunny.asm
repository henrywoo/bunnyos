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

%include "h_macro.asm"
%include "h_const.asm"

org KERNELADDRABS
jmp start_real

%define r0addr(X) (X-start_pmr0data)
pos equ 1 ;pos equ (80-bmsg1_len)/2

;*** default value setting ***
d_eflags equ 1202h
d_proc_stacksize equ 64*1024-1


;*********************************************************************
[SECTION PMR0DATA]
BITS 32
ALIGN 32
start_pmr0data:
 PCBSTART:
  mc_pcb_table 1
  PCB_len equ $ - PCBSTART
  mc_pcb_table 2
  mc_pcb_table 3
 PCBLAST:
  mc_pcb_table 4;***simon
 PCBEND_CHAR:
  curPCB    dd 0
  reenter   dd -1
  jiffies   dd 0
  
  pidcount  dd 0

  mc_string bmsg1, "BunnyOS 1.0"
  mc_string bmsg2, "Protected Mode, ring 0"
  mc_string bmsg3, "Protected Mode, ring 3"
  mc_string bmsg4, "Load TSS..."
  mc_string bmsg5, "Load LDT..."
  mc_string author, "Author: Wu Fuheng"
  mc_string email , "Email : wufuheng@gmail.com"
  mc_string date  , "Date  : 2010-02-13"
  strdd: times 8 db 0
  strdb: times 2 db 0
  mc_data_keyboard
  kbbuffer dd 0
  cursorpos dd 0
  curstartline dd 0
  hdbuf: times ONEKB db 0
pmr0data_len equ $ - start_pmr0data


;********************************************************
[section RealAddressMode]
BITS 16
start_real:
  mc_clearscreen

  ; 0. calculate Protected mode segment descp
  mc_assign_descp_base GDT_3,start_pmr0code
  mc_assign_descp_base GDT_4,start_pmr0data
  mc_assign_descp_base GDT_6,start_tss
  mc_assign_descp_base GDT_7,start_ldt1
  mc_assign_descp_base ldt1_1,start_ldt1code
  mc_assign_descp_base ldt1_2,start_ldt1data
  mc_assign_descp_base GDT_8,start_ldt2
  mc_assign_descp_base ldt2_1,start_ldt2code
  mc_assign_descp_base ldt2_2,start_ldt2data
  mc_assign_descp_base GDT_9,start_ldt3
  mc_assign_descp_base ldt3_1,start_ldt3code
  mc_assign_descp_base ldt3_2,start_ldt3data
  mc_assign_descp_base GDT_10,start_ldt4;***simon
  mc_assign_descp_base ldt4_1,start_ldt4code
  mc_assign_descp_base ldt4_2,start_ldt4data

  mc_assign_descp_base GDT_r3text,start_r3text
  mc_assign_descp_base GDT_r3data,start_r3data

  ; 1. load gdt
  lgdt [gdtptr]

  ; 2. load idt
  xor eax,eax
  mov ax,ds
  shl eax,4
  add eax,start_idt
  mov dword [idtptr+2], eax
  cli
  lidt [idtptr]

  ; 3. open A20
  in al, 92h
  or al, 00000010b
  out 92h, al

  ; 4. set cr0 PE
  mov eax, cr0
  or eax, 1
  mov cr0, eax

  ; 6. jump to protected mode
  jmp dword sel_pmr0code:0

;********************************************************
[section GDT]
BITS 32
ALIGN 32
GDT_1:      mc_descp 0,0,0
GDT_2:      mc_descp 0B8000h, 32*1024-1, DA_DRW+DA_DPL3;***video
GDT_3:      mc_descp 0, (pmr0code_len-1), DA_CR+DA_32;***code
GDT_4:      mc_descp 0, (pmr0data_len-1), DA_DRWA+DA_32 ;***data
GDT_5:      mc_descp STACKBOT, (STACKTOP-STACKBOT-1), DA_DRWA+DA_32 ;***stack
GDT_6:      mc_descp 0, (tss_len-1), DA_386TSS ;TSS
GDT_7:      mc_descp 0, ldt1_len-1, DA_LDT;+DA_DPL3; ldt1
GDT_8:      mc_descp 0, ldt2_len-1, DA_LDT;+DA_DPL3; ldt2
GDT_9:      mc_descp 0, ldt3_len-1, DA_LDT;+DA_DPL3; ldt3
GDT_10:     mc_descp 0, ldt4_len-1, DA_LDT;+DA_DPL3; ldt4;***simon
GDT_r3text: mc_descp 0, r3text_len-1, DA_CR+DA_32+DA_DPL3;***ring 3 code/text/function/syscall
GDT_r3data: mc_descp 0, r3data_len-1, DA_DRWA+DA_32+DA_DPL3;***ring 3 data

gdt_len equ $-GDT_1
gdtptr  dw (gdt_len - 1)
        dd (GDT_1)

sel_video     equ GDT_2      -GDT_1 +011b
sel_pmr0code  equ GDT_3      -GDT_1
sel_pmr0data  equ GDT_4      -GDT_1
sel_pmr0stack equ GDT_5      -GDT_1
sel_tss       equ GDT_6      -GDT_1
sel_ldt1      equ GDT_7      -GDT_1 +011b
sel_ldt2      equ GDT_8      -GDT_1 +011b
sel_ldt3      equ GDT_9      -GDT_1 +011b
sel_ldt4      equ GDT_10     -GDT_1 +011b ;***simon
sel_r3text    equ GDT_r3text -GDT_1 +011b
sel_r3data    equ GDT_r3data -GDT_1 +011b

;********************************************************
[section IDT]
BITS 32
ALIGN 32
start_idt:
%include "idt.asm"
idt_len  equ $-start_idt
idtptr  dw idt_len-1
        dd 0

;*********************************************************************
[section TSS]
BITS 32
ALIGN 32
start_tss:
  backlink  dd 0
  esp0      dd STACKTOP-STACKBOT-1; top of stack of ring 0
  ss0       dd sel_pmr0stack
  times 22 dd 0
  trap_      dw 0
  iobase_    dw $-start_tss+2 
  DB 0ffh
tss_len equ $-start_tss

;*********************************************************************
[section PMR0CODE]
BITS 32
ALIGN 32
start_pmr0code:

  ; 0. set stack
  mov dx, sel_pmr0stack
  mov ss, dx
  mov esp, PMR0STACK_LEN

  ; 1. write video memory, showing i am in protected mode
  mov cx, sel_video
  mov fs, cx

  mov ax, sel_tss
  ltr ax

  call Init8259A

  %define RATE_GENERATOR 34h ;/* 00-11-010-0 :
  %define TIMER_FREQ     1193180; /* clock frequency for timer in PC and AT */
  %define HZ             100
  ;set 10ms interrupt (8253 control register)
  mc_out_byte(RATE_GENERATOR,43h)
  mc_out_byte((TIMER_FREQ/HZ),40h)
  mc_out_byte(((TIMER_FREQ/HZ) >>8),40h)

  sti

  INITPBC 1
  INITPBC 2
  INITPBC 3
  INITPBC 4

  mov dword[curPCB],r0addr(bunny_p1)
  mov ax, sel_ldt1
  lldt ax

  ;{ read harddisk parameters
  mov al, byte [0x475]; the number of harddisk
  cmp al, 0
  je .noharddisk
  ; get BSY bit of status register
  mc_in_byte(1F7h)
  cmp al, 0
  jnz .HDBUSY
  ;harddisk not busy
  mc_out_byte(0,3F6h)
  mc_out_byte(0,1F1h)
  mc_out_byte(0,1F2h)
  mc_out_byte(0,1F3h)
  mc_out_byte(0,1F4h)
  mc_out_byte(0,1F5h)
  mc_out_byte((MAKE_DEVICE_REG(0,0,0)),1F6h)
  mc_out_byte(0xEC,1F7h)
  push ONEKB
  push hdbuf
  push 1f0h
  call port_read
  add esp, 4*3
 .HDBUSY
 .noharddisk;}

  push sel_ldt1stack
  push d_proc_stacksize
  push sel_ldt1code
  push 0
  retf

  jmp $

  ;{void port_read(u16 port, void* buf, int n);
  port_read:
    mc_shortfunc_start
    pushf
    mov edx, [ebp + 8]    ; port
    mov edi, [ebp + 8 + 4]  ; buf
    mov ecx, [ebp + 8 + 4 + 4]  ; n
    shr ecx, 1
    cld
    rep insw
    popf
    mc_shortfunc_end;}

  ;{push line_number
  setscreen:
    mc_shortfunc_start
    mc_out_byte(0ch,3d4h)
    
    mov eax, dword [ebp+8]
    mov ecx, 80
    mul ecx
    mov ebx, eax
    shr ebx, 8
    and ebx, 0xff ; ((80*2)>>8)&0xff; 1 - absolute value, index of line in screen!
    mc_out_byte(ebx,3d5h)

    mc_out_byte(0dh,3d4h)
    
    mov ebx, eax
    and ebx, 0xff;(80*2)&0xff
    mc_out_byte(ebx,3d5h)
    mc_shortfunc_end;}
    
  ;{push position of cursor(=cursorpos+2); call setcursor
  setcursor:
    mc_shortfunc_start
    mc_out_byte(0eh,3d4h)

    mov ebx,dword [ebp+8]

    push ebx
    call cleartext
    add esp,4*1

    mov ecx, ebx

    shr ebx, 9
    and ebx, 0ffh ;(((ebx/2)>>8)&0ffh)
    mc_out_byte(ebx,3d5h)

    mc_out_byte(0fh,3d4h)

    mov ebx,ecx
    shr ebx, 1
    and ebx, 0ffh ;((pos/2)&0ffh)
    mc_out_byte(ebx,3d5h)

    ; update currentline value
    ; note: current cursor's line
    xor edx, edx
    mov eax, ecx
    mov ebx, 80*2
    cmp eax, ebx
    jl .noscroll
    div ebx
    mov ebx, dword[r0addr(curstartline)]
    add ebx, 25
    cmp eax, ebx
    jl .noscroll
    inc dword [r0addr(curstartline)]
    push dword [r0addr(curstartline)]
    call setscreen
    add esp, 4
   .noscroll
    mc_shortfunc_end;}
    
  ; {ebx-msg_len; ecx-msg
  _PrintfHandler:
  PrintfHandler equ _PrintfHandler - $$
    pushad  
    ; TODO
    push ds ; Get current position of cursor and put it into edi
    mov dx,sel_pmr0data
    mov ds,dx
    mov edi,dword[r0addr(cursorpos)]
    pop ds

    ;push ecx;len
    ;push ebx;msg
    mov edx, 0
  .1big
    mov al, byte[ebx+edx]
    cmp al, 0Ah; \n
    je .2
    mov ah, 0Eh
    mov [fs:edi], ax
    add edi, 2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Add currentpos
    jmp .3
  .2
    push eax
    push edi
    call getnextlinestart; call是看CS,has nothing to do with DS
    add esp, 4
    mov edi, eax
    pop eax    
  .3
    inc edx
    loop .1big
    
    ; TODO
    push ds
    mov dx,sel_pmr0data
    mov ds,dx
    mov dword[r0addr(cursorpos)], edi
    push edi
    call setcursor
    add esp,4
    pop ds

    popad
    iretd;}

  ; push curpos; call ~;result in eax -> the addr of next line start
  getnextlinestart:
    push ebp
    mov ebp,esp
    push ebx
    push edx

    mov eax, dword [ebp+8]
    mov ebx, 80*2
    xor edx,edx
    cmp eax, 80*2-1
    ja .1
    mov eax,0
    jmp .2
   .1
    div ebx
   .2
    inc eax; current line number + 1
    mul ebx

    pop edx
    pop ebx
    pop ebp
    ret


  ;*** R0_Function ***
  _ClockHandler:
  ClockHandler equ _ClockHandler - $$
    pushad  
    push  ds 
    push  es 
    push  fs
    push  gs

    mov dx,sel_pmr0data
    mov ds,dx

    inc dword [r0addr(jiffies)] ;*** add jiffies
    inc dword [r0addr(reenter)]
    cmp dword [r0addr(reenter)],0
    jne .reentry
    sti

    call FillPCB

    mov al, 20h
    out 20h, al

    mov ax, sel_pmr0data
    mov ss, ax
    mov edx, dword[r0addr(curPCB)]
    add edx, PCB_len ;*** next PCB
    cmp edx, r0addr(PCBLAST)
    JA .3
    mov esp, edx
    jmp .4
  .3: 
    mov edx, r0addr(PCBSTART)
    mov esp, edx
  .4:
    add edx, (sel_ldt1_-gs_1)
    mov bx, word [edx]
    lldt bx

    ;*** Get new curPCB
    mov eax, r0addr(PCBLAST)
    cmp eax, dword[r0addr(curPCB)]
    jbe .1
    add dword[r0addr(curPCB)],PCB_len
    jmp .2
  .1:
    mov dword[r0addr(curPCB)],r0addr(PCBSTART)
  .2:
    cli
  .reentry:
    dec dword [r0addr(reenter)]
    pop gs 
    pop fs
    pop es
    pop ds
    popad
    iretd

  FillPCB:
    add esp, 4
    mov ebx,dword[r0addr(curPCB)]
    add ebx,(sel_ldt1_-gs_1);*** = 0x44 
    mov ecx,(sel_ldt1_-gs_1)/4 ;*** = 0x11
   .mmmove:
    sub ebx,4
    mov edx,[esp+ecx*4-4]
    mov dword[ebx], edx
    loop .mmmove
    sub esp, 4
    ret
 
  _SpuriousHandler:
  SpuriousHandler equ _SpuriousHandler - $$
    push  ds 
    pushad  
    mov dx,sel_pmr0data
    mov ds,dx

    mov ah, 0dh
    mov al, 'X'
    inc dword [r0addr(cursorpos)]
    mov edx, dword [r0addr(cursorpos)]
    mov [fs:edx], ax

    popad
    pop ds
    iretd

  _HWHandler:
  HWHandler equ _HWHandler - $$
    push  ds 
    pushad  
    mov dx,sel_pmr0data
    mov ds,dx

    mov ah, 0dh
    mov al, 'Y'
    inc dword [r0addr(cursorpos)]
    mov edx, dword [r0addr(cursorpos)]
    mov [fs:edx], ax

    popad
    pop ds
    iretd

  ;{
  _KeyboardHandler:
  KeyboardHandler equ _KeyboardHandler - $$
    push  ds 
    pushad  

    mov dx,sel_pmr0data
    mov ds,dx
    
   .spin:
    in  al, 0x64
    and al, 0x01
    jz  .spin

    xor eax,eax
    in al,0x60
    
    ;*** 1c 9c -> Enter
    cmp al, 0x1c
    jne .notentermake

    mov byte [r0addr(kbbuffer)+2],1
    jmp .isbreakcode

   .notentermake
    cmp byte [r0addr(kbbuffer)+2],0
    je .notenter

   .mightbeenter
    cmp al,0x9c
    jne .notenter

    ;***is enter
    ;-------------------------------
    mov ebx, dword [r0addr(cursorpos)]
    push ebx
    call getnextlinestart
    add esp, 4
    ;-------------------------------

    mov dword [r0addr(cursorpos)], eax

    push eax
    call setcursor
    add esp,4*1

    jmp .isbreakcode
    
   .notenter

    ;*** 0E 8E -> backspace 
    cmp al,0x0E
    jne .nothing2

    mov byte [r0addr(kbbuffer)+1],1
    jmp .isbreakcode

   .nothing2:
    cmp byte [r0addr(kbbuffer)+1],0
    jne .isleftornot

   .isleftornot:
    cmp al,0x8E
    jne .notleft

   .isleft:
    cmp dword [r0addr(cursorpos)],-2 ; when there is nothing in the screen
    je .isbreakcode
    sub dword [r0addr(cursorpos)],2
    mov ebx, dword [r0addr(cursorpos)]

    push ebx
    call setcursor
    add esp,4*1

    jmp .isbreakcode

   .notleft:

    ;*** if al==0xB6 || al==0xAA ; upper case to lower case
    cmp al, 0xB6
    jne .2
   .3:
    mov byte [r0addr(kbbuffer)],0;shift弹起->清零
    jmp .isbreakcode
   .2:
    cmp al, 0xAA
    je .3

    ;*** 2A AA -> left shift
    cmp al,0x2A
    je .isshift

    ;*** 36 B6 -> right shift;
    cmp al,0x36
    jne .notshift

   .isshift:
    mov byte [r0addr(kbbuffer)], al
    jmp .isbreakcode

   .notshift:
    cmp al, KEYMAPDATA_ROW_NUM
    ja .isbreakcode

   ; cmp al, 0x16;u
   ; je .pageup

   ; cmp al, 0x20;d
   ; je .pagedown

    ;*** pinpoint char to print
    push eax
    push dword [r0addr(cursorpos)]
    call printkbchar
    add esp, 4*2

    add dword [r0addr(cursorpos)],2
    push dword [r0addr(cursorpos)]
    call setcursor
    add esp, 4*1

    jmp .isbreakcode

  ;.pageup
  ;  push 0
  ;  call setscreen
  ;  add esp, 4*1
  ;  jmp .isbreakcode

  ;.pagedown
  ;  push 2
  ;  call setscreen
  ;  add esp, 4*1
  ;  jmp .isbreakcode
    
   .isbreakcode:
    mov al, 0x20 ;clear buffer
    out 0x20, al

    popad
    pop ds
    iretd;}

  ;push char12,pos8; call ~
  printkbchar:
    mc_shortfunc_start
    mov eax, dword[ebp+12]
    mov ebx, KEYMAPDATA_COLUMN_NUM
    mul ebx
    add eax, r0addr(@keymapdata)
    cmp byte [r0addr(kbbuffer)],0 ;shift on or off
    je .1
    inc eax
   .1
    push eax;msg
    push 1; len
    push dword[ebp+8];pos
    call _r0printline
    add esp,4*3
    mc_shortfunc_end

  ;push pos; call ~
  cleartext:
    mc_shortfunc_start
    mov edx, [ebp+8]
    mov al, ' '
    mov ah, 0Ah
    mov [fs:edx], ax
    mc_shortfunc_end


  io_delay:
    nop
    nop
    nop
    nop
    ret

  ;*** Init8259A ------------------------------------
  Init8259A:
    mov al, 011h; 00010001b
    out 020h, al  ; 主8259, ICW1.
    call  io_delay
    out 0A0h, al  ; 从8259, ICW1.
    call  io_delay
    mov al, 020h  ; IRQ0 对应中断向量 0x20
    out 021h, al  ; 主8259, ICW2.
    call  io_delay
    mov al, 028h  ; IRQ8 对应中断向量 0x28
    out 0A1h, al  ; 从8259, ICW2.
    call  io_delay
    mov al, 004h  ; IR2 对应从8259
    out 021h, al  ; 主8259, ICW3.
    call  io_delay
    mov al, 002h  ; 对应主8259的 IR2
    out 0A1h, al  ; 从8259, ICW3.
    call  io_delay
    mov al, 001h
    out 021h, al  ; 主8259, ICW4.
    call  io_delay
    out 0A1h, al  ; 从8259, ICW4.
    call  io_delay
    mov al, 11111000b ;keyboard and timer and cascade
    out 021h, al  ;master 8259, OCW1.
    call  io_delay
    mov al, 10111111b ;slave
    out 0A1h, al  ;slave 8259, OCW1.
    call  io_delay
    ret

  ;{ push value(12), port(8); call out_byte
  out_byte:
    push ebp
    mov ebp,esp
    mov edx, [ebp + 8]  ; port
    mov eax, [ebp + 12] ; value - get lowest 8 bits
    out dx, al
    nop
    pop ebp
    ret 8;}

  ;{ push XX; call ~
  in_byte:
    ;mov ebp,esp
    ;pushad
    mov edx, [esp+4];port
    xor eax, eax
    in  al, dx
    call io_delay
    ;popad
    ret 4;}

  ; push 16msg, 12msg_len, 8pos; call printline
  _r0printline:
  r0printline equ _r0printline-$$
    mc_shortfunc_start
    mov ecx, [ebp+12];len
    mov edi, [ebp+8];pos
    mov ebx,0
  .1:
    ;mov eax, edi;disregard parameter row 
    mov edx, [ebp+16]
    mov al, byte [ds:(edx+ebx)]
    mov ah, 0Dh
    mov [fs:edi], ax
    inc ebx
    add edi, 2
    LOOP .1
    mc_shortfunc_end

  ;*** push 20014a7fh, addr; call num2str
  _r0num2str:
  r0num2str equ _r0num2str-$$
    mc_shortfunc_start
    mov edi, dword [ebp+8];address
    add edi, 8
    mov eax, dword [ebp+12];num
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
    mc_shortfunc_end

  ;***** System Call ******
  ;************************
  _JiffiesHandler:
  JiffiesHandler equ _JiffiesHandler - $$
    push  ds 
    mov dx,sel_pmr0data
    mov ds,dx
    mov eax, dword[r0addr(jiffies)]
    pop ds
    iretd

  _GetPidHandler:
  GetPidHandler equ _GetPidHandler - $$
    mov eax, 0
    iretd
  
pmr0code_len equ $-start_pmr0code
%include "r3.asm"
