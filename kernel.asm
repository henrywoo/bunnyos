%include "pm.inc"
%include "macro.inc"
%include "proc.asm"

org KERNELADDRABS
jmp start_real

; Memory from KERNELADDRABS ~ 9FC00h
;
; 1. Enter protected mode
; GDT,IDT,Stack,
;
; 2. Start Process
; ring0<->ring1,PCB,stack,TSS
;*********************************************************************
[section GDT]
bits 32
ALIGN 32
GDT_1: Descriptor 0,0,0
GDT_2: Descriptor 0B8000h, 32*1024-1, DA_DRW+DA_DPL3;***video
GDT_3: Descriptor 0, (end_protected-start_protected-1), DA_CR+DA_32
GDT_4: Descriptor STACKBOT, (STACKTOP-STACKBOT-1), DA_DRWA+DA_32 ;***kernel stack
GDT_5: Descriptor 0, LDTLEN-1, DA_LDT ;LDT
GDT_7: Descriptor 0, (endtss-starttss-1), DA_386TSS ;TSS
GDT_8: Descriptor 0, (end_funseg-start_funseg-1), DA_CCOR+DA_32;***function segment - conforming
GDT_9: Descriptor OneMB, OneMB, DA_DRWA+DA_32 ;***1M process stack
GDT_10: Descriptor 0, (end_gate-start_gate-1), DA_CR+DA_32 ;***ring0
GDT_11: Descriptor 0, (end_data-start_data-1), DA_DRWA+DA_32;***data segment
GDT_300: Descriptor 0, (end_ring3code-start_ring3code-1), DA_CR+DA_32+ DA_DPL3;*** Ring3 code seg(90M)
GDT_301: Descriptor 10*OneMB, SEG_MAXSIZE, DA_DRWA+DA_32+DA_DPL3 ;*** Ring3 stack(1MB-1) 

GATE_1: Gate (GDT_10-GDT_1+SA_RPL3), 0, 0, DA_386CGate+DA_DPL3

GDTLEN equ $-GDT_1
gdtptr  dw (GDTLEN - 1)
        dd (GDT_1)

[section .idt]
bits 32
ALIGN 32
IDT_1:
;***0x80 = 128, INT vector start from 0
%rep 32
        Gate GDT_3-GDT_1,SpuriousHandler, 0,DA_386IGate
%endrep
.020h   Gate GDT_3-GDT_1,ClockHandler,    0,DA_386IGate
%rep 95
        Gate GDT_3-GDT_1,SpuriousHandler, 0,DA_386IGate
%endrep
.080h   Gate GDT_3-GDT_1,int80Handler,    0,DA_386IGate

IDTLEN  equ $-IDT_1
IDTPtr  dw IDTLEN-1
        dd 0

;*********************************************************************
[SECTION LDT]
BITS 32
ALIGN 32
start_ldt:
LDT_1: Descriptor 0, (end_ldtcode1-start_ldtcode1-1), DA_CR+DA_32
LDT_2: Descriptor 0, (end_ldtcode2-start_ldtcode2-1), DA_CR+DA_32

LDTLEN equ $-LDT_1

;*********************************************************************
[SECTION LPROC1]
BITS 32
ALIGN 32
start_ldtcode1:
  PRINTCHAR 0eh,'P',14,10
  PRINTCHAR 0eh,'1',14,11
  ;call proc1
  ;int 080h
  sti
  ;jmp $
  retf
  ;*** my first process in bunnyOS
	proc1:
	.1:
    PPrintLn p1data, 17, 1
    nop
	  inc byte [p1data+p1data_len-1]
	  loop .1
	  ret
BSTRING p1data, "I am proc 1 in ring 0: 0"
end_ldtcode1:

;*********************************************************************
[SECTION LPROC2]
BITS 32
ALIGN 32
start_ldtcode2:
  PRINTCHAR 0dh,'P',14,1
  PRINTCHAR 0dh,'2',14,2
  call proc2
  ;jmp (LDT_1-LDT_1+0100b):0
  ;jmp $
  retf

  ;*** my second process in bunnyOS
	proc2:
	.1:
    PPrintLn p2data, 18, 1
	  ret

BSTRING p2data, "proc 2 in ring 0: 0"
end_ldtcode2:

;*********************************************************************
[section TSSSEG]
BITS 32
ALIGN 32
starttss:
  DEFTSS tss_ 
endtss:


%macro ProcFrame 1
bunny_p %+ %1:

   gs_ %+ %1    dd 0
   fs_ %+ %1    dd 0
   es_ %+ %1    dd 0
   ds_ %+ %1    dd 0
   edi_ %+ %1   dd 0
   esi_ %+ %1   dd 0
   ebp_ %+ %1   dd 0
   k_esp_ %+ %1 dd 0
   ebx_ %+ %1   dd 0
   edx_ %+ %1   dd 0
   ecx_ %+ %1   dd 0
   eax_ %+ %1   dd 0

   retaddr_ %+ %1 dd 0

   eip_ %+ %1     dd 0
   cs_ %+ %1      dd 0
   eflags_ %+ %1  dd 0
   esp_ %+ %1     dd 0
   ss_ %+ %1      dd 0

   ldt_sel_ %+ %1  dw 0
   pid_ %+ %1      dd 0
   pname_ %+ %1 times 16 db 0

bunny_p %+ %1 %+ _end:
%endmacro


;*********************************************************************
[section ProtectedMode]
BITS 32
align 32
start_protected:


  ; 0. set stack
  mov dx, GDT_4-GDT_1
  mov ss, dx
  mov esp, (STACKTOP-STACKBOT-1)

  ; 1. write video memory, showing i am in protected mode
  mov cx, GDT_2-GDT_1
  mov fs, cx
  PPrintLn bmsg1, 3, pos
  PPrintLn bmsg2, 4, pos
  PPrintLn author,7, pos
  PPrintLn email, 8, pos
  PPrintLn date,  9, pos

  ; 3. load LTD
  mov ax, (GDT_5-GDT_1)
  lldt ax
  PPrintLn bmsg5, 12, pos
  
  call Init8259A

  ;jmp (LDT_2-LDT_1 + 0100b):0 ;*** go to LDT2
  call (LDT_2-LDT_1 + 0100b):0 ;*** go to LDT2
  ;jmp (LDT_1-LDT_1 + 0100b):0 ;*** go to LDT1
  call (LDT_1-LDT_1 + 0100b):0 ;*** go to LDT1

  jmp $

  ; 4. init Interrupt
  ;call Init8259A
  ;int 080h
  ;sti; start interrupt
  ;call io_delay
  ;jmp $

  ; 5. *** init PCB *** - > jmp to ???
  mov dword [gs_1],(LDT_2-LDT_1+0100b)
  mov dword [fs_1],(LDT_2-LDT_1+0100b)
  mov dword [es_1],(GDT_2-GDT_1)
  mov dword [ds_1],(LDT_2-LDT_1+0100b)
  ;edi_1
  ;esi_1
  ;ebp_1
  ;k_esp_1
  ;ebx_1
  ;edx_1
  ;ecx_1
  ;eax_1
  ;retaddr_1

  mov eax, dword [TestA]
  mov dword [eip_1],eax ;***???
  mov dword [cs_1],(LDT_1-LDT_1+0100b)
  mov dword [eflags_1],1202h
  mov dword [esp_1],esp ;***????
  mov dword [ss_1],(LDT_2-LDT_1+0100b)

  mov word [ldt_sel_1],(GDT_5-GDT_1);*** LDT Selector
  mov dword [pid_1],1
  mov dword [pname_1],'Proc1';memcpy

  ; 6. ring0 -> ring3
  ; 6.1 TSS initialization, Loading TSS
  ;inc byte [p2data_]
  ;PPrintLn p2data_, 0, 20
  mov dword [ss0], GDT_4-GDT_1
  mov dword [esp0], (STACKTOP-STACKBOT-1) ;***??????????
  mov ax, GDT_7-GDT_1
  ltr ax
  ;PPrintLn bmsg4, 11, pos


  ;PPrintLn bmsg6, 13, pos
  push GDT_301-GDT_1+SA_RPL3  ;ss
  push SEG_MAXSIZE                ;esp
  push GDT_300-GDT_1+SA_RPL3  ;cs
  push 0                      ;eip
  retf ;***jump to -> start_ring3code


  ;call restart
  ; ... Continued ...
  jmp $


  _SpuriousHandler:
  SpuriousHandler equ _SpuriousHandler - $$
    ;PPrintLn bmsg7, 17, pos
    PRINTCHAR 0dh,'I',23,1
    PRINTCHAR 0dh,'N',23,2
    PRINTCHAR 0dh,'T',23,3
    jmp $
    iretd

  _int80Handler:
  int80Handler equ _int80Handler - $$
    PRINTCHAR 0dh,'8',22,1
    PRINTCHAR 0dh,'0',22,2
    PRINTCHAR 0dh,':',22,3
    PRINTCHAR 0dh,'0',22,4
    iretd
    
  ;*** CPU process scheduling here
  ;*** stack will change
  _ClockHandler:
  ClockHandler equ _ClockHandler - $$
    pushad  
    push  ds 
    push  es 
    push  fs
    push  gs
    ;inc dword [reint]

    ;call (LDT_2-LDT_1 + 0100b):0 ;*** go to LDT2
    inc byte [fs:((80 * 0 + 10) * 2)]

    mov al, 20h
    out 20h, al

    pop gs 
    pop fs
    pop es
    pop ds
    popad

    ;dec dword [reint]
    .1:
    iretd

  reint dd 0


restart:
  mov esp, bunny_p1
  lea eax, [ss_1]
  mov dword [ss0],eax
  dec dword [reint]
 
  pop gs
  pop fs
  pop es
  pop ds
  popad
  add esp,4

  iretd

TestA:
  PPrintLn bmsg8, 13, pos
  
    

  ;*** PCB - process control block
	ProcFrame 1 ; bunny_p1
	ProcFrame 2 ; bunny_p2

  io_delay:
  %rep 1024
   nop
  %endrep
    ret

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
  ;pos equ (80-bmsg1_len)/2
  pos equ 1


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


end_protected:

;*********************************************************************
[section FuncSeg]
BITS 32
ALIGN 32
start_funseg:
  ;*** push 24msg, 20msg_len, 16row, 12column; call printline
  ;*****************
  tmp_ dd 0
  line_ dd 5; starting from line 5
	printline:
	  push  ebp
	  mov ebp, esp
	  ;push  ebx
	  push  esi
	  push  edi
	
	  mov ecx, [ebp+16+4];len
    mov dword [tmp_],0 ;***XXX
    ;mov dword [line_],[ebp+12+4]
    inc dword [line_]
	.1:
	  ;mov eax, [ebp+12+4];row=2
	  mov eax, dword [line_];disregard parameter row 
	  mov edx, 80
	  mul edx ; mul will affect EDX!!!
	  add eax, [ebp+8+4];column
	  shl eax, 1
	  mov edi, eax
	  mov edx, [ebp+20+4]
    mov ebx,[tmp_]
	  mov al, byte [edx+ebx];*** access byte [edx+ebx] error
	  mov ah, 0ch
	  mov [fs:edi], ax
    inc dword [tmp_]
    inc dword [ebp+8+4]
	  LOOP .1
    mov dword [tmp_],0

	  pop edi
	  pop esi
	  ;pop ebx
	  pop ebp
	  retf

  ;*** push 9; call printdigit
  ;push 9
  ;call printdigit
  ;add esp, 4*1
  printdigit: ;***near
	  push  ebp
	  mov ebp, esp
	  push  ebx
	  push  esi
	  push  edi

    mov al,byte[ebp+8]
    add al,48
    mov ah,0ch
    mov edi,(80*1+1)*2
    mov [fs:edi],ax
 
	  pop edi
	  pop esi
	  pop ebx
	  pop ebp
	  ret

  ;*** void* MemCpy(void* es:pDest, void* ds:pSrc, int iSize);
  memcpy:
    push  ebp
    mov ebp, esp
    push  esi
    push  edi
    push  ecx
  
    mov edi, [ebp + 8]  ; Destination
    mov esi, [ebp + 12] ; Source
    mov ecx, [ebp + 16] ; Counter
  .1:
    cmp ecx, 0    ; 判断计数器
    jz  .2    ; 计数器为零时跳出
    mov al, [ds:esi]      ; ┓
    inc esi               ; ┃
                          ; ┣ 逐字节移动
    mov byte [es:edi], al ; ┃
    inc edi               ; ┛
  
    dec ecx   ; 计数器减一
    jmp .1    ; 循环
  .2:
    mov eax, [ebp + 8]  ; 返回值
  
    pop ecx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret


end_funseg:

;********************************************************
[SECTION R3Code]
BITS 32
align 32
start_ring3code:
  PRINTCHAR 0ah,'R',1,1
  PRINTCHAR 0ah,'3',1,2
  call (GATE_1-GDT_1+SA_RPL3):0
  jmp $
BSTRING pdata244, "I am under ring 3 now!"
end_ring3code:

;%macro PPrintLn 3
;  push %1
;  push %1 %+ _len
;  push %2
;  push %3
;  call (GDT_8-GDT_1):(printline-start_funseg) ;*** far call
;  add esp, 16
;%endmacro
;********************************************************
[SECTION MyGate]
BITS 32
ALIGN 32
start_gate:
  ;mov al, byte [p2data_]
  ;PPrintLn pdata262, 0, 10 ;*************??????????
  PRINTCHAR 0eh,'R',1,10
  PRINTCHAR 0eh,'0',1,11
  ;jmp (LDT_2-LDT_1+0100b):0 ;*** go to LDT code segment

  jmp $
BSTRING pdata262, "Return to ring 0..."
end_gate:

;********************************************************
[section RealAddressMode]
BITS 16
start_real:

  ;*** Get Memory from int 15
  mov ebx, 0
  mov di, _MemChkBuf
.loop:
  mov eax, 0E820h
  mov ecx, 20
  mov edx, 0534D4150h;'SMAP'
  int 15h
  jc  LABEL_MEM_CHK_FAIL
  add di, 20
  inc dword [_dwMCRNumber]
  cmp ebx, 0
  jne .loop
  jmp LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAIL:
  mov dword [_dwMCRNumber], 0
LABEL_MEM_CHK_OK:
    
  ; 0. calculate Protected mode segment descp
  DTBaseEqual GDT_3,start_protected
  DTBaseEqual GDT_5,start_ldt
  DTBaseEqual GDT_7,starttss
  DTBaseEqual GDT_8,start_funseg
  DTBaseEqual GDT_10,start_gate
  DTBaseEqual GDT_11,start_data
  DTBaseEqual LDT_1,start_ldtcode1
  DTBaseEqual LDT_2,start_ldtcode2
  DTBaseEqual GDT_300,start_ring3code

  ; 1. load gdt to gdtr
  lgdt [gdtptr]

  xor eax,eax
  mov ax,ds
  shl eax,4
  add eax,IDT_1
  mov dword [IDTPtr+2], eax

  ; 2. close interrupt
  cli

  lidt [IDTPtr]

  ; 3. open A20
  in al, 92h
  or al, 00000010b
  out 92h, al

  ; 4. set cr0 PE
  mov eax, cr0
  or eax, 1
  mov cr0, eax

  ; 6. jump to protected mode
  jmp dword (GDT_3-GDT_1):0


_dwMCRNumber:     dd  0
_MemChkBuf: times 256 db  0

[section .text]
bits 32
align 32
start_data:
  BSTRING p2data_, "I am proc 2 in ring 0: 0"
end_data:







  ;num2str:
  ;  mov edx, 20014a7fh
  ;  mov ebx, 10000000h
  ;  mov ecx, 32
  ;.1:
  ;  mov eax, edx
  ;  xor edx, edx
  ;  div ebx; residual is in edx, eax is result
  ;  and eax, 0fh
  ;  mov byte[num_+32-ecx],al;***????????????????
  ;  shr ebx, 4
  ;  loop .1
  ;num_ times 32 db 0
