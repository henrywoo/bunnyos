%include "pm.inc"
%include "macro.inc"
%include "proc.asm"

;********************************************************
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
  ProcFrame 1
  PCB_len equ $ - PCBSTART
  ProcFrame 2
  ProcFrame 3
PCBLAST:
  ProcFrame 4;***simon
PCBEND:
  curPCB dd 0
  reenter dd -1
  jiffies dd 0
  
  kbcount dd 0

  BSTRING bmsg1, "BunnyOS 1.0"
  BSTRING bmsg2, "Protected Mode, ring 0"
  BSTRING bmsg3, "Protected Mode, ring 3"
  BSTRING bmsg4, "Load TSS..."
  BSTRING bmsg5, "Load LDT..."
  BSTRING bmsg6, "Entering ring 3..."
  BSTRING bmsg7, "Interrupt happens!!!"
  BSTRING bmsg8, "This is TestAAAAAAAAAAAAAAAAAAAAAAA!"
  BSTRING author, "Author: Wu Fuheng"
  BSTRING email , "Email : wufuheng@gmail.com"
  BSTRING date  , "Date  : 2010-02-13"
  strdd: times 8 db 0
  strdb: times 2 db 0
pmr0data_len equ $ - start_pmr0data


;********************************************************
[section RealAddressMode]
BITS 16
start_real:
  ; 0. calculate Protected mode segment descp
  DTBaseEqual GDT_3,start_pmr0code
  DTBaseEqual GDT_4,start_pmr0data
  DTBaseEqual GDT_6,start_tss
  DTBaseEqual GDT_7,start_ldt1
  DTBaseEqual ldt1_1,start_ldt1code
  DTBaseEqual ldt1_2,start_ldt1data
  DTBaseEqual GDT_8,start_ldt2
  DTBaseEqual ldt2_1,start_ldt2code
  DTBaseEqual ldt2_2,start_ldt2data
  DTBaseEqual GDT_9,start_ldt3
  DTBaseEqual ldt3_1,start_ldt3code
  DTBaseEqual ldt3_2,start_ldt3data
  DTBaseEqual GDT_10,start_ldt4;***simon
  DTBaseEqual ldt4_1,start_ldt4code
  DTBaseEqual ldt4_2,start_ldt4data

  DTBaseEqual GDT_r3text,start_r3text

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
GDT_1: Descriptor 0,0,0
GDT_2: Descriptor 0B8000h, 32*1024-1, DA_DRW+DA_DPL3;***video
GDT_3: Descriptor 0, (pmr0code_len-1), DA_CR+DA_32;***code
GDT_4: Descriptor 0, (pmr0data_len-1), DA_DRWA+DA_32 ;***data
GDT_5: Descriptor STACKBOT, (STACKTOP-STACKBOT-1), DA_DRWA+DA_32 ;***stack
GDT_6: Descriptor 0, (tss_len-1), DA_386TSS ;TSS
GDT_7: Descriptor 0, ldt1_len-1, DA_LDT;+DA_DPL3; ldt1
GDT_8: Descriptor 0, ldt2_len-1, DA_LDT;+DA_DPL3; ldt2
GDT_9: Descriptor 0, ldt3_len-1, DA_LDT;+DA_DPL3; ldt3
GDT_10: Descriptor 0, ldt4_len-1, DA_LDT;+DA_DPL3; ldt4;***simon
GDT_r3text: Descriptor 0, r3text_len-1, DA_CR+DA_32+DA_DPL3;***ring 3 code/text/function/syscall

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

;********************************************************
[section IDT]
BITS 32
ALIGN 32
start_idt:
%rep 20h
        Gate sel_pmr0code,SpuriousHandler, 0,DA_386IGate
%endrep
.020h:  Gate sel_pmr0code,ClockHandler,    0,DA_386IGate
.021h:  Gate sel_pmr0code,KeyboardHandler, 0,DA_386IGate
%rep 6eh
        Gate sel_pmr0code,SpuriousHandler, 0,DA_386IGate
%endrep
.090h:  Gate sel_pmr0code,JiffiesHandler,  0,DA_386IGate+DA_DPL3

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
  mov esp, pmr0stack_len

  ; 1. write video memory, showing i am in protected mode
  mov cx, sel_video
  mov fs, cx

  mov ax, sel_tss
  ltr ax

  call Init8259A

  ;*** set 10ms interrupt (8253 control register)
  ;push RATE_GENERATOR
  ;push TIMER_MODE
  ;call out_byte
  ;call io_delay

  ;push TIMER_FREQ/HZ
  ;push TIMER0
  ;call out_byte
  ;call io_delay

  ;push ((TIMER_FREQ/HZ) >>8)
  ;push TIMER0
  ;call out_byte
  ;call io_delay

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

%macro INITPBC 1
  mov dword[ds_ %+ %1],sel_ldt %+ %1 %+ data
  mov dword[cs_ %+ %1 ],sel_ldt %+ %1 %+ code
  mov dword[eflags_ %+ %1 ],d_eflags
  mov dword[esp_ %+ %1 ],d_proc_stacksize
  mov dword[ss_ %+ %1 ],sel_ldt %+ %1 %+ stack
  mov word[sel_ldt %+ %1 %+ _],sel_ldt %+ %1 
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
    PRINTCHAR 0dh,'I',23,1
    PRINTCHAR 0dh,'N',23,2
    PRINTCHAR 0dh,'T',23,3
    iretd

  _KeyboardHandler:
  KeyboardHandler equ _KeyboardHandler - $$
    push  ds 
    pushad  

  .spin:
    in  al, 0x64
    and al, 0x01
    jz  .spin

    xor eax,eax
    in al,0x60

    mov dx,sel_pmr0data
    mov ds,dx
    
    cmp dword [r0addr(kbcount)],0
    je .1
    add dword [r0addr(kbcount)],8
   .1:
    inc dword [r0addr(kbcount)]
    mov ebx, dword [r0addr(kbcount)]
    ;PRINTCHAR 0dh,'k',16,ebx

    ;***
    push eax
    push r0addr(strdd)
    call _r0num2str

    push r0addr(strdd)
    push 8
    push 7
    push ebx
    call _r0printline
    call io_delay

    mov al, 0x20 ;clear buffer
    out 0x20, al

    popad
    pop ds
    iretd

  _JiffiesHandler:
  JiffiesHandler equ _JiffiesHandler - $$
    push  ds 
    mov dx,sel_pmr0data
    mov ds,dx
    mov eax, dword[r0addr(jiffies)]
    pop ds
    iretd

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

  ;*** void out_byte(u16 port, u8 value);
  out_byte:
    mov edx, [esp + 4]    ; port
    mov al, [esp + 8] ; value
    out dx, al
    call io_delay
    ret 8

  in_byte:
    mov edx, [esp + 4]    ; port
    xor eax, eax
    in  al, dx
    call io_delay
    ret 4

  ;*** push 24msg, 20msg_len, 16row, 12column; call printline
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
    mov ah, 0ch
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

pmr0code_len equ $-start_pmr0code


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

  ;*** push 24msg, 20msg_len, 16row, 12column; call printline
  _printline:
  printline equ _printline-$$
    push  ebp
    mov ebp, esp
    push  ebx
    push  esi
    push  edi
  
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

    pop edi
    pop esi
    pop ebx
    pop ebp
    retf

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
;*********************************************************************
[SECTION ldt1]
BITS 32
ALIGN 32
start_ldt1:
ldt1_1: Descriptor 0, (ldt1code_len-1),  DA_CR+DA_32+DA_DPL3;***code
ldt1_2: Descriptor 0, (ldt1data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
ldt1_3: Descriptor 200000h, d_proc_stacksize, DA_DRWA+DA_32+DA_DPL3;***stack

sel_ldt1code equ  111b
sel_ldt1data equ  ldt1_2-ldt1_1+111b
sel_ldt1stack equ ldt1_3-ldt1_1+111b

ldt1_len equ $-start_ldt1

;*********************************************************************
%define ldt1dataaddr(X) (X-start_ldt1data)
[SECTION ldt1DATA]
BITS 32
ALIGN 32
start_ldt1data:
  BSTRING p1data, "I am proc 1 in ring 3 - sleep 10s -  "
ldt1data_len equ $-start_ldt1data

;*********************************************************************
[SECTION ldt1CODE]
BITS 32
ALIGN 32
start_ldt1code:
  mov ax, sel_ldt1data
  mov ds, ax
  r3print ldt1dataaddr(p1data),p1data_len,1,1
  .1:
    inc byte [fs:((80 * 1 + p1data_len) * 2)]
    Sleep 1000
    jmp .1
  jmp $
ldt1code_len equ $-start_ldt1code


;*********************************************************************
[SECTION ldt2]
BITS 32
ALIGN 32
start_ldt2:
ldt2_1: Descriptor 0, (ldt2code_len-1),  DA_CR+DA_32+DA_DPL3;***code
ldt2_2: Descriptor 0, (ldt2data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
ldt2_3: Descriptor 210000h, d_proc_stacksize, DA_DRWA+DA_32+DA_DPL3;***stack

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
  BSTRING p2data, "I am proc 2 in ring 3 - sleep 5s -  "
ldt2data_len equ $-start_ldt2data

;*********************************************************************
[SECTION ldt2CODE]
BITS 32
ALIGN 32
start_ldt2code:
  r3print ldt2dataaddr(p2data),p2data_len,2,1
  .1:
    inc byte [fs:((80 * 2 + p2data_len) * 2)]
    Sleep 500
    jmp .1
  jmp $

ldt2code_len equ $-start_ldt2code

;*********************************************************************
[SECTION ldt3]
BITS 32
ALIGN 32
start_ldt3:
ldt3_1: Descriptor 0, (ldt3code_len-1),  DA_CR+DA_32+DA_DPL3;***code
ldt3_2: Descriptor 0, (ldt3data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
ldt3_3: Descriptor 220000h, d_proc_stacksize, DA_DRWA+DA_32+DA_DPL3;***stack

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
  BSTRING p3data, "I am proc 3 in ring 3 - sleep 1s -  "
ldt3data_len equ $-start_ldt3data

;*********************************************************************
[SECTION ldt3CODE]
BITS 32
ALIGN 32
start_ldt3code:
  r3print ldt3dataaddr(p3data),p3data_len,3,1
  .1:
    inc byte [fs:((80 * 3 + p3data_len) * 2)]
    Sleep 100
    jmp .1
  jmp $
ldt3code_len equ $-start_ldt3code

;*********************************************************************
[SECTION ldt4]
BITS 32
ALIGN 32
start_ldt4:
ldt4_1: Descriptor 0, (ldt4code_len-1),  DA_CR+DA_32+DA_DPL3;***code
ldt4_2: Descriptor 0, (ldt4data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
ldt4_3: Descriptor 230000h, d_proc_stacksize, DA_DRWA+DA_32+DA_DPL3;***stack

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
  BSTRING p4data, "I am proc 4 in ring 3 - jiffies -"
  strx: times 8 db 0
ldt4data_len equ $-start_ldt4data

;*********************************************************************
[SECTION ldt4CODE]
BITS 32
ALIGN 32
start_ldt4code:
  r3print ldt4dataaddr(p4data),p4data_len,4,1
  call proc4
  jmp $

  proc4:
  .1:
    call sel_r3text:get_jiffies
    push eax
    push ldt4dataaddr(strx)
    call sel_r3text:num2str
    add esp, 8
    
    r3print ldt4dataaddr(strx),8,4,(p4data_len+2)
    jmp .1
    ret

    
    
ldt4code_len equ $-start_ldt4code
