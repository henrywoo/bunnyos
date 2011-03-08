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
  curpos dd 0x100
  pidcount dd 0

  BSTRING bmsg1, "BunnyOS 1.0"
  BSTRING bmsg2, "Protected Mode, ring 0"
  BSTRING bmsg3, "Protected Mode, ring 3"
  BSTRING bmsg4, "Load TSS..."
  BSTRING bmsg5, "Load LDT..."
  BSTRING author, "Author: Wu Fuheng"
  BSTRING email , "Email : wufuheng@gmail.com"
  BSTRING date  , "Date  : 2010-02-13"
  strdd: times 8 db 0
  strdb: times 2 db 0
  %include "kb.asm" ;keymapdata
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
.091h:  Gate sel_pmr0code,GetPidHandler,  0,DA_386IGate+DA_DPL3

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

%include "r0code.asm"
%include "r3.asm"

