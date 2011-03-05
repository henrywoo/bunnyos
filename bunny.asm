%include "pm.inc"
%include "macro.inc"
%include "proc.asm"

;********************************************************
org KERNELADDRABS
jmp start_real

;*********************************************************************
[SECTION PMR0DATA]
BITS 32
ALIGN 32
start_pmr0data:

  ProcFrame 1
  PCB_len equ $ - bunny_p1
  ProcFrame 2
  curPCB dd 0
  nexPCB dd 0
  reenter dd -1

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
  pos equ 1 ;pos equ (80-bmsg1_len)/2
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
  DTBaseEqual LDT1_1,start_ldt1code
  DTBaseEqual LDT1_2,start_ldt1data
  DTBaseEqual LDT2_1,start_ldt2code
  DTBaseEqual LDT2_2,start_ldt2data

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
GDT_7: Descriptor 0, ldt1_len-1, DA_LDT;+DA_DPL3; LDT1
GDT_8: Descriptor 0, ldt2_len-1, DA_LDT;+DA_DPL3; LDT2

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

;********************************************************
[section IDT]
BITS 32
ALIGN 32
start_idt:
%rep 32
        Gate GDT_3-GDT_1,SpuriousHandler, 0,DA_386IGate
%endrep
.020h:  Gate GDT_3-GDT_1,ClockHandler,    0,DA_386IGate
%rep 223
        Gate GDT_3-GDT_1,SpuriousHandler, 0,DA_386IGate
%endrep

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

  mov ax, sel_tss
  ltr ax

  ;***init PCB1
  mov dword[ds_1],sel_ldt1data
  mov dword[cs_1],sel_ldt1code
  mov dword[eflags_1],1202h
  mov dword[esp_1],stacktop_ldt1 ;***???
  mov dword[ss_1],sel_ldt1stack
  mov word[sel_ldt1_],sel_ldt1

  ;***init PCB2
  mov dword[ds_2],sel_ldt2data
  mov dword[cs_2],sel_ldt2code
  mov dword[eflags_2],1202h
  mov dword[esp_2],stacktop_ldt2
  mov dword[ss_2],sel_ldt2stack
  mov word[sel_ldt2_],sel_ldt2

  mov dword[curPCB],bunny_p1-start_pmr0data
  mov dword[nexPCB],bunny_p2-start_pmr0data

  mov ax, sel_ldt1
  lldt ax

  push sel_ldt1stack
  push stacktop_ldt1
  push sel_ldt1code
  push 0
  retf

  jmp $
    
  %define r0addr(X) (X-start_pmr0data)
  _ClockHandler:
  ClockHandler equ _ClockHandler - $$
    pushad  
    push  ds 
    push  es 
    push  fs
    push  gs

    mov dx,sel_pmr0data
    mov ds,dx

    inc dword [r0addr(reenter)]
    cmp dword [r0addr(reenter)],0
    jne .re_enter

    sti

    mov ebx,dword[r0addr(curPCB)]
    add ebx,(sel_ldt1_-gs_1);*** = 0x44 
    mov ecx,(sel_ldt1_-gs_1)/4 ;*** = 0x11
  .mmmove:
    sub ebx,4
    mov edx,[esp+ecx*4-4]
    mov dword[ebx], edx
    loop .mmmove
    ;*** save proc1 status to PCB1 end...

    ;inc byte [fs:((80 * 1 + 3) * 2)]
    ;inc byte [fs:((80 * 1 + 13) * 2)]
    mov al, 20h
    out 20h, al

    mov dx, sel_pmr0data
    mov ss, dx
    mov edx, dword[r0addr(nexPCB)]
    mov esp, edx

    add edx, (sel_ldt1_-gs_1)
    mov bx, word [edx]
    lldt bx

    mov ebx, dword[r0addr(curPCB)]
    mov edx, dword[r0addr(nexPCB)]
    mov dword[r0addr(nexPCB)],ebx
    mov dword[r0addr(curPCB)],edx
    
    cli
  .re_enter:
    dec dword [r0addr(reenter)]
    pop gs 
    pop fs
    pop es
    pop ds
    popad

    iretd

  _SpuriousHandler:
  SpuriousHandler equ _SpuriousHandler - $$
    ;PPrintLn bmsg7, 17, pos
    PRINTCHAR 0dh,'I',23,1
    PRINTCHAR 0dh,'N',23,2
    PRINTCHAR 0dh,'T',23,3
    ;jmp $
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
    mov al, 11111110b ; 仅仅开启定时器中断
    out 021h, al  ; 主8259, OCW1.
    call  io_delay
    mov al, 11111111b ; 屏蔽从8259所有中断
    out 0A1h, al  ; 从8259, OCW1.
    call  io_delay
    ret



pmr0code_len equ $-start_pmr0code




;*********************************************************************
[SECTION LDT1]
BITS 32
ALIGN 32
start_ldt1:
LDT1_1: Descriptor 0, (ldt1code_len-1),  DA_CR+DA_32+DA_DPL3;***code
LDT1_2: Descriptor 0, (ldt1data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
LDT1_3: Descriptor 200000h, stacktop_ldt1, DA_DRWA+DA_32+DA_DPL3;***stack

sel_ldt1code equ  111b
sel_ldt1data equ  LDT1_2-LDT1_1+111b
sel_ldt1stack equ LDT1_3-LDT1_1+111b
stacktop_ldt1 equ 64*1024-1

ldt1_len equ $-start_ldt1

;*********************************************************************
[SECTION LDT2]
BITS 32
ALIGN 32
start_ldt2:
LDT2_1: Descriptor 0, (ldt2code_len-1),  DA_CR+DA_32+DA_DPL3;***code
LDT2_2: Descriptor 0, (ldt2data_len-1),  DA_DRWA+DA_32+DA_DPL3;***data
LDT2_3: Descriptor 300000h, stacktop_ldt2, DA_DRWA+DA_32+DA_DPL3;***stack

sel_ldt2code equ  111b
sel_ldt2data equ  LDT2_2-LDT2_1+111b
sel_ldt2stack equ LDT2_3-LDT2_1+111b
stacktop_ldt2 equ 64*1024-1

ldt2_len equ $-start_ldt2

;*********************************************************************
[SECTION LDT1CODE]
BITS 32
ALIGN 32
start_ldt1code:
  PRINTCHAR 0eh,'P',1,1
  PRINTCHAR 0eh,'1',1,2
  PRINTCHAR 0eh,'0',1,3
	.1:
	  inc byte [fs:((80 * 1 + 3) * 2)]
    nop
	  jmp .1
  ;call proc1
  ;int 080h
  ;sti
  jmp $
  ;retf

	proc1:
	.1:
	  inc byte [fs:((80 * 1 + 3) * 2)]
    %rep 100
    nop
    %endrep
	  jmp .1
	  ret
ldt1code_len equ $-start_ldt1code

;*********************************************************************
[SECTION LDT1DATA]
BITS 32
ALIGN 32
start_ldt1data:
  BSTRING p1data, "I am proc 1 in ring 3: 0"
ldt1data_len equ $-start_ldt1data


;*********************************************************************
[SECTION LDT2CODE]
BITS 32
ALIGN 32
start_ldt2code:
  PRINTCHAR 0eh,'P',1,10
  PRINTCHAR 0eh,'2',1,11
  PRINTCHAR 0eh,'0',1,12
	.1:
	  inc byte [fs:((80 * 1 + 12) * 2)]
    nop
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
[SECTION LDT2DATA]
BITS 32
ALIGN 32
start_ldt2data:
  BSTRING p2data, "I am proc 2 in ring 3: 0"
ldt2data_len equ $-start_ldt2data
