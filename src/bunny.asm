%include "h_macro.asm"
%include "h_const.asm"

org KERNELADDRABS
jmp start_real


%define r0addr(X) (X-start_pmr0data)
pos equ 1 ;pos equ (80-bmsg1_len)/2

;*** default value setting ***
d_eflags equ 1202h
d_proc_stacksize equ 64*1024-1

%define TIMER_MODE     43h ;/* I/O port for timer mode control */
%define RATE_GENERATOR 34h ;/* 00-11-010-0 :
%define TIMER0         40h ;/* I/O port for timer channel 0 */
%define TIMER_FREQ     1193180; /* clock frequency for timer in PC and AT */
%define HZ             (100)

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
GDT_1: mc_descp 0,0,0
GDT_2: mc_descp 0B8000h, 32*1024-1, DA_DRW+DA_DPL3;***video
GDT_3: mc_descp 0, (pmr0code_len-1), DA_CR+DA_32;***code
GDT_4: mc_descp 0, (pmr0data_len-1), DA_DRWA+DA_32 ;***data
GDT_5: mc_descp STACKBOT, (STACKTOP-STACKBOT-1), DA_DRWA+DA_32 ;***stack
GDT_6: mc_descp 0, (tss_len-1), DA_386TSS ;TSS
GDT_7: mc_descp 0, ldt1_len-1, DA_LDT;+DA_DPL3; ldt1
GDT_8: mc_descp 0, ldt2_len-1, DA_LDT;+DA_DPL3; ldt2
GDT_9: mc_descp 0, ldt3_len-1, DA_LDT;+DA_DPL3; ldt3
GDT_10: mc_descp 0, ldt4_len-1, DA_LDT;+DA_DPL3; ldt4;***simon
GDT_r3text: mc_descp 0, r3text_len-1, DA_CR+DA_32+DA_DPL3;***ring 3 code/text/function/syscall
GDT_r3data: mc_descp 0, r3data_len-1, DA_DRWA+DA_32+DA_DPL3;***ring 3 data

gdt_len equ $-GDT_1
gdtptr  dw (gdt_len - 1)
        dd (GDT_1)

sel_video     equ GDT_2-GDT_1+011b
sel_pmr0code  equ GDT_3-GDT_1
sel_pmr0data  equ GDT_4-GDT_1
sel_pmr0stack equ GDT_5-GDT_1
sel_tss       equ GDT_6-GDT_1
sel_ldt1      equ GDT_7-GDT_1+011b
sel_ldt2      equ GDT_8-GDT_1+011b
sel_ldt3      equ GDT_9-GDT_1+011b
sel_ldt4      equ GDT_10-GDT_1+011b;***simon

sel_r3text    equ GDT_r3text-GDT_1+011b
sel_r3data    equ GDT_r3data-GDT_1+011b

;********************************************************
[section IDT]
BITS 32
ALIGN 32
start_idt:
%rep 20h
        mc_descp_gate sel_pmr0code,SpuriousHandler, 0,DA_386Imc_descp_gate
%endrep
.020h:  mc_descp_gate sel_pmr0code,ClockHandler,    0,DA_386Imc_descp_gate
.021h:  mc_descp_gate sel_pmr0code,KeyboardHandler, 0,DA_386Imc_descp_gate
%rep 6eh
        mc_descp_gate sel_pmr0code,SpuriousHandler, 0,DA_386Imc_descp_gate
%endrep
.090h:  mc_descp_gate sel_pmr0code,JiffiesHandler,  0,DA_386Imc_descp_gate+DA_DPL3
.091h:  mc_descp_gate sel_pmr0code,GetPidHandler,  0,DA_386Imc_descp_gate+DA_DPL3
.092h:  mc_descp_gate sel_pmr0code,PrintfHandler,  0,DA_386Imc_descp_gate+DA_DPL3

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

  ;*** set 10ms interrupt (8253 control register)
  push RATE_GENERATOR
  push TIMER_MODE
  call out_byte
  call io_delay

  push TIMER_FREQ/HZ
  push TIMER0
  call out_byte
  call io_delay

  push ((TIMER_FREQ/HZ) >>8)
  push TIMER0
  call out_byte
  call io_delay

  ;mov al, 34h
  ;out 43h, al
  ;nop
  ;mov al, 9bh
  ;out 40h, al
  ;nop
  ;mov al, 2eh
  ;out 40h, al

  sti

  ;***init PCB1 simon
  mov dword[ds_1],sel_ldt1data
  mov dword[cs_1],sel_ldt1code
  mov dword[eflags_1],d_eflags
  mov dword[esp_1],d_proc_stacksize
  mov dword[ss_1],sel_ldt1stack
  mov word[sel_ldt1_],sel_ldt1
  mov eax, dword [pidcount]
  mov dword[pid_1],sel_ldt1
  inc dword [pidcount]

%macro INITPBC 1
  mov dword[ds_ %+ %1],sel_ldt %+ %1 %+ data
  mov dword[cs_ %+ %1 ],sel_ldt %+ %1 %+ code
  mov dword[eflags_ %+ %1 ],d_eflags
  mov dword[esp_ %+ %1 ],d_proc_stacksize
  mov dword[ss_ %+ %1 ],sel_ldt %+ %1 %+ stack
  mov word[sel_ldt %+ %1 %+ _],sel_ldt %+ %1 
  mov eax, dword [pidcount]
  mov dword[pid_ %+ %1],sel_ldt %+ %1
  inc dword [pidcount]
%endmacro
  INITPBC 2
  INITPBC 3
  INITPBC 4

  mov dword[curPCB],r0addr(bunny_p1)
  mov ax, sel_ldt1
  lldt ax

  push sel_ldt1stack
  push d_proc_stacksize
  push sel_ldt1code
  push 0
  retf

  jmp $
    

  ; {ebx-msg_len; ecx-msg
  _PrintfHandler:
  PrintfHandler equ _PrintfHandler - $$
    pushad  
    ; TODO
    push ds
    mov dx,sel_pmr0data
    mov ds,dx
    mov edi,dword[ds:cursorpos-start_pmr0data]
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
    add edi, 2
    jmp .3
  .2
    push eax
    push edi
    call getnextlinestart; call是看代码段,has nothing to do with DS
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
    mov dword[ds:cursorpos-start_pmr0data], edi
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
    cmp eax, 80*2
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


  ; printdd eax,ebx
  %define ROWNUM 0
  %macro printdd 2
    push %1; register name; you want to print its value
    push r0addr(strdd)
    call _r0num2str

    push r0addr(strdd)
    push 8;msg_len
    push ROWNUM;row
    push %2;cloumn
    call _r0printline
  %endmacro

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
    mov eax,dword [r0addr(cursorpos)]
    push eax
    call getnextlinestart
    add esp, 4
    mov ebx, eax
    call setcursor
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
    sub dword [r0addr(cursorpos)],2
    mov eax,dword [r0addr(cursorpos)]
    call cleartext
    mov ebx, dword [r0addr(cursorpos)]
    call setcursor
    jmp .isbreakcode

   .notleft:

    ;*** 36 B6 -> right shift;
    ;*** if al==0xB6 || al==0xAA ; upper case to lower case
    cmp al, 0xB6
    jne .2
   .3:
    mov byte [r0addr(kbbuffer)],0
    jmp .isbreakcode
   .2:
    cmp al, 0xAA
    je .3

    ;*** 2A AA -> left shift
    cmp al,0x2A
    je .isshift

    cmp al,0x36
    jne .notshift

   .isshift
    mov byte [r0addr(kbbuffer)], al
    jmp .isbreakcode

   .notshift

    cmp al, KEYMAPDATA_ROW_NUM
    ja .isbreakcode
    push eax

    add dword [r0addr(cursorpos)],2
    mov ebx, dword [r0addr(cursorpos)]

    call setcursor

    ;*** pinpoint char to print
    pop eax; for push eax
    call printkbchar

  .isbreakcode:
    mov al, 0x20 ;clear buffer
    out 0x20, al

    popad
    pop ds
    iretd

  printkbchar:
    pushad
    mov ecx, 3
    mul ecx
    add eax, r0addr(@keymapdata)
    cmp byte [r0addr(kbbuffer)],0
    je .11
    inc eax
   .11
    push eax
    push 1;8; len
    push ROWNUM;row
    push ebx;cloumn
    call _r0printline
    popad
    ret

  cleartext:
    mov edx, eax
    mov al, ' '
    mov ah, 00h
    mov [fs:edx], ax
    ret ;4

  setcursor:
    pushad
    ;*** set cursor
    push 0eh
    push 3d4h
    call out_byte

    add ebx,80*ROWNUM ; TODO
    shl ebx, 1

    mov eax,ebx
    shr ebx, 9
    and ebx, 0ffh
    push ebx ;(((ebx/2)>>8)&0ffh)
    push 3d5h
    call out_byte

    push 0fh
    push 3d4h
    call out_byte

    shr eax, 1
    and eax, 0ffh
    push eax;((20/2)&0ffh)
    push 3d5h
    call out_byte
    popad
    ;***
    ret
    

  io_delay:
    nop
    nop
    nop
    nop
    ret

  ;*** Init8259A ------------------------------------
  Init8259A:
    mov al, 011h
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
    ;mov  al, 11111111b ; 屏蔽主8259所有中断
    ;mov al, 11111110b ; 仅仅开启定时器中断
    mov al, 11111100b ;keyboard and timer
    out 021h, al  ; 主8259, OCW1.
    call  io_delay
    mov al, 11111111b ; 屏蔽从8259所有中断
    out 0A1h, al  ; 从8259, OCW1.
    call  io_delay
    ret

  ;*** push value(8), port(4); call out_byte
  out_byte:
    mov ebp,esp
    pushad
    mov dx, word [ebp + 4]    ; port
    mov al, byte [ebp + 8] ; value
    out dx, al
    call io_delay
    popad
    ret 8

  in_byte:
    mov ebp,esp
    pushad
    mov edx, [ebp + 4]    ; port
    xor eax, eax
    in  al, dx
    call io_delay
    popad
    ret 4

  ;*** push 20msg, 16msg_len, 12row, 8column; call printline
  _r0printline:
  r0printline equ _r0printline-$$
    push  ebp
    mov ebp, esp
    push  esi
    push  edi
    pushad
  
    mov ecx, [ebp+16];len
    mov esi,0
  .1:
    ;mov eax, edi;disregard parameter row 
    mov eax, [ebp+12];row=3
    mov edx, 80
    mul edx ; mul will affect EDX!!!
    add eax, [ebp+8];column
    shl eax, 1

    mov edi, eax
    mov edx, [ebp+20]
    mov ebx,esi
    mov al, byte [ds:(edx+ebx)]
    mov ah, 0Dh
    mov [fs:edi], ax
    inc esi
    inc dword [ebp+8]
    LOOP .1

    popad
    pop edi
    pop esi
    pop ebp
    ret 16

  ;*** push 20014a7fh, addr; call num2str
  _r0num2str:
  r0num2str equ _r0num2str-$$
    push  ebp
    mov ebp, esp
    push  esi
    push  edi
    pushad

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

    popad
    pop edi
    pop esi
    pop ebp
    ret 8

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
