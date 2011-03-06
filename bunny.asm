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

%define TIMER_MODE     0x43 ;/* I/O port for timer mode control */
%define RATE_GENERATOR 0x34 ;/* 00-11-010-0 :
%define TIMER0         0x40 ;/* I/O port for timer channel 0 */
%define TIMER_FREQ     1193180; /* clock frequency for timer in PC and AT */
%define HZ             100

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
  DTBaseEqual GDT_8,start_ldt2
  DTBaseEqual ldt1_1,start_ldt1code
  DTBaseEqual ldt1_2,start_ldt1data
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
%rep 6fh
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
%ifndef SHORTER_CODE
  times 22 dd 0
%else
  esp1      dd 0
  ss1       dd 0
  esp2      dd 0
  ss2       dd 0
  cr3_      dd 0
  eip_      dd 0
  flags     dd 0
  eax_      dd 0
  ecx_      dd 0
  edx_      dd 0
  ebx_      dd 0
  esp_      dd 0
  ebp_      dd 0
  esi_      dd 0
  edi_      dd 0
  es_      dd 0
  cs_      dd 0
  ss_      dd 0
  ds_      dd 0
  fs_      dd 0
  gs_      dd 0
  ldt_     dd 0
%endif

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

  call Init8259A
  sti

  ;*** set 10ms interrupt (8253 control register)
  mov al, 34h
  out 43h, al
  nop
  mov al, 9bh
  out 40h, al
  nop
  mov al, 2eh
  out 40h, al

  mov ax, sel_tss
  ltr ax

  ;***init PCB1
  mov dword[ds_1],sel_ldt1data
  mov dword[cs_1],sel_ldt1code
  mov dword[eflags_1],d_eflags
  mov dword[esp_1],d_proc_stacksize ;***???
  mov dword[ss_1],sel_ldt1stack
  mov word[sel_ldt1_],sel_ldt1

  ;***init PCB2
  mov dword[ds_2],sel_ldt2data
  mov dword[cs_2],sel_ldt2code
  mov dword[eflags_2],d_eflags
  mov dword[esp_2],d_proc_stacksize
  mov dword[ss_2],sel_ldt2stack
  mov word[sel_ldt2_],sel_ldt2

  ;***init PCB3
  mov dword[ds_3],sel_ldt3data
  mov dword[cs_3],sel_ldt3code
  mov dword[eflags_3],d_eflags
  mov dword[esp_3],d_proc_stacksize
  mov dword[ss_3],sel_ldt3stack
  mov word[sel_ldt3_],sel_ldt3

  ;***init PCB4 simon
  mov dword[ds_4],sel_ldt4data
  mov dword[cs_4],sel_ldt4code
  mov dword[eflags_4],d_eflags
  mov dword[esp_4],d_proc_stacksize
  mov dword[ss_4],sel_ldt4stack
  mov word[sel_ldt4_],sel_ldt4

  mov dword[curPCB],r0addr(bunny_p1)
  mov ax, sel_ldt1
  lldt ax

  ;int 90h

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
    ;PPrintLn bmsg7, 17, pos
    PRINTCHAR 0dh,'I',23,1
    PRINTCHAR 0dh,'N',23,2
    PRINTCHAR 0dh,'T',23,3
    ;jmp $
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
    %rep 10
    nop
    %endrep
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
    nop
    nop
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
	  mov al, byte [edx+ebx]
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

  ;*** push 20014a7fh,addr; call num2str
	_num2str:
	num2str equ _num2str-$$
	  push  ebp
	  mov ebp, esp
	  push  ebx
	  push  esi
	  push  edi

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

	  pop edi
	  pop esi
	  pop ebx
	  pop ebp
	  retf

  ;*** push 102; call sleep_ms
  _sleep_ms:
  sleep_ms equ _sleep_ms - $$
	  push  ebp
	  mov ebp, esp
	  push  ebx
	  push  esi
	  push  edi

    int 90h
    mov edi, eax
  .2
    int 90h
    sub eax, edi
    mov ecx, 1000/HZ
    mul ecx
    cmp eax, dword [ebp+12]
    jl .2

	  pop edi
	  pop esi
	  pop ebx
	  pop ebp
	  retf

    
r3text_len equ $-start_r3text


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
[SECTION ldt1CODE]
BITS 32
ALIGN 32
start_ldt1code:
  PRINTCHAR 0dh,'P',1,1
  PRINTCHAR 0dh,'1',1,2
  PRINTCHAR 0dh,'0',1,3
	.1:
	  inc byte [fs:((80 * 1 + 3) * 2)]
    push 1000
    call sel_r3text:sleep_ms
    add esp, 4
	  jmp .1
  ;call proc1
  ;int 080h
  ;sti
  jmp $
  ;retf

	proc1:
	.1:
	  inc byte [fs:((80 * 1 + 3) * 2)]
	  jmp .1
	  ret
ldt1code_len equ $-start_ldt1code

;*********************************************************************
[SECTION ldt1DATA]
BITS 32
ALIGN 32
start_ldt1data:
  BSTRING p1data, "I am proc 1 in ring 3: 0"
ldt1data_len equ $-start_ldt1data


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
[SECTION ldt2CODE]
BITS 32
ALIGN 32
start_ldt2code:
  PRINTCHAR 0bh,'P',1,10
  PRINTCHAR 0bh,'2',1,11
  PRINTCHAR 0bh,'0',1,12
	.1:
	  inc byte [fs:((80 * 1 + 12) * 2)]
    push 2000
    call sel_r3text:sleep_ms
    add esp, 4
	  jmp .1
  ;call proc2
  ;int 080h
  ;sti
  jmp $
  ;retf

	proc2:
	.1:
	  inc byte [fs:((80 * 1 + 12) * 2)]
	  jmp .1
	  ret
ldt2code_len equ $-start_ldt2code

;*********************************************************************
[SECTION ldt2DATA]
BITS 32
ALIGN 32
start_ldt2data:
  BSTRING p2data, "I am proc 2 in ring 3: 0"
ldt2data_len equ $-start_ldt2data



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
[SECTION ldt3CODE]
BITS 32
ALIGN 32
start_ldt3code:
  PRINTCHAR 0ah,'P',1,20
  PRINTCHAR 0ah,'3',1,21
  PRINTCHAR 0ah,'0',1,22
	.1:
	  inc byte [fs:((80 * 1 + 22) * 2)]
    push 100
    call sel_r3text:sleep_ms
    add esp, 4
	  jmp .1
  ;call proc2
  ;int 080h
  ;sti
  jmp $
  ;retf

	proc3:
	.1:
	  inc byte [fs:((80 * 3 + 12) * 2)]
	  jmp .1
	  ret
ldt3code_len equ $-start_ldt3code

;*********************************************************************
[SECTION ldt3DATA]
BITS 32
ALIGN 32
start_ldt3data:
  BSTRING p3data, "I am proc 3 in ring 3: 0"
ldt3data_len equ $-start_ldt3data



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
  BSTRING p4data, "I am proc 4 in ring 3: 0"
  strx: times 32 db 0
ldt4data_len equ $-start_ldt4data

;*********************************************************************
[SECTION ldt4CODE]
BITS 32
ALIGN 32
start_ldt4code:
  PRINTCHAR 0ch,'P',1,30
  PRINTCHAR 0ch,'4',1,31
  PRINTCHAR 0ch,'0',1,32
  call proc4
  jmp $

	proc4:
	.1:
    call sel_r3text:get_jiffies
    push eax
    push ldt4dataaddr(strx)
    call sel_r3text:num2str
    add esp, 8
    
    push ldt4dataaddr(strx)
    push 32
    push 1
    push 34
    call sel_r3text:printline ;*** far call
    add esp, 16
	  inc byte [fs:((80 * 1 + 32) * 2)]
	  jmp .1
	  ret

    
    
ldt4code_len equ $-start_ldt4code
