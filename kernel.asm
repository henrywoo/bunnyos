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
ALIGN 32
GDT_1: Descriptor 0,0,0
GDT_2: Descriptor 0B8000h, 32*1024-1, DA_DRW+DA_DPL3;***video
GDT_3: Descriptor 0, (end_start_protected-start_protected-1), DA_CR+DA_32
GDT_4: Descriptor STACKBOT, (STACKTOP-STACKBOT-1), DA_DRWA+DA_32 ;***kernel stack
GDT_5: Descriptor 0, LDTLEN-1, DA_LDT ;LDT
GDT_6: Descriptor 0, 0, DA_DRWA+DA_32 ;IDT
GDT_7: Descriptor 0, (endtss-starttss-1), DA_386TSS ;TSS
GDT_8: Descriptor 0, (end_funseg-start_funseg-1), DA_CR+DA_32;***function segment
GDT_9: Descriptor OneMB, OneMB, DA_DRWA+DA_32 ;***1M process stack
GDT_10: Descriptor 0, (end_gate-start_gate-1), DA_CR+DA_32 ;***ring0
GDT_11: Descriptor 0, (end_data-start_data-1), DA_DRWA+DA_32 ;***data segment
GDT_300: Descriptor 0, (end_ring3code-start_ring3code-1), DA_CR+DA_32+ DA_DPL3;*** Ring3 code seg(90M)
GDT_301: Descriptor 100*OneMB, OneMB, DA_DRWA+DA_32+DA_DPL3 ;*** Ring3 stack(1M)

GATE_1: Gate (GDT_10-GDT_1), 0, 0, DA_386CGate+DA_DPL3

GDTLEN equ $-GDT_1
gdtptr  dw (GDTLEN - 1)
        dd (GDT_1)

;*********************************************************************
[SECTION LDT]
BITS 32
ALIGN 32
start_ldt:
LDT_1: Descriptor 0, (end_ldtcode1-start_ldtcode1), DA_CR+DA_32
LDT_2: Descriptor 0, (end_ldtcode2-start_ldtcode2), DA_CR+DA_32

LDTLEN equ $-LDT_1

;*********************************************************************
[SECTION LPROC1]
BITS 32
ALIGN 32
start_ldtcode1:
  call proc1
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
  call proc2
  jmp (LDT_1-LDT_1 + 0100b):0
  ;jmp $

  ;*** my second process in bunnyOS
	proc2:
	.1:
    PPrintLn p2data, 18, 1
	  ret

BSTRING p2data, "proc 2 in ring 0: 0"
end_ldtcode2:


[section TSSSEG]
BITS 32
starttss:
  DEFTSS tss_ 
endtss:
;*********************************************************************
[section ProtectedMode]
BITS 32
start_protected:

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

  ; 0. set stack
  mov dx, GDT_4-GDT_1
  mov ss, dx
  mov esp, (STACKTOP-STACKBOT-1)

  ; 1. write video memory, showing i am in protected mode
  mov cx, GDT_2 - GDT_1
  mov fs, cx
  PPrintLn bmsg1, 3, pos
  PPrintLn bmsg2, 4, pos
  PPrintLn author,7, pos
  PPrintLn email, 8, pos
  PPrintLn date,  9, pos

  ; 0.5 TSS initialization, Loading TSS
  mov dword [ss0], GDT_4-GDT_1
  mov dword [esp0], (STACKTOP-STACKBOT-1)
  mov ax, GDT_7-GDT_1
  ltr ax
  PPrintLn bmsg4, 11, pos

  ;call proc1
  mov ax, (GDT_5-GDT_1)
  lldt ax
  PPrintLn bmsg5, 12, pos
  
  ;jmp (LDT_2-LDT_1 + 0100b):0 ;*** go to LDT code segment

  PPrintLn bmsg6, 13, pos
  push GDT_301-GDT_1+SA_RPL3
  push OneMB-1
  push GDT_300-GDT_1+SA_RPL3
  push 0
  retf ;***jump to -> start_ring3code

  PPrintLn bmsg6, 13, pos

  ; initialize PCB
  ;mov dword [ldt_sel_1],0
  ;...
	
  ; 2. Continued ...
  jmp $

  BSTRING bmsg1, "BunnyOS 1.0"
  BSTRING bmsg2, "Protected Mode, ring 0"
  BSTRING bmsg3, "Protected Mode, ring 3"
  BSTRING bmsg4, "Load TSS..."
  BSTRING bmsg5, "Load LDT..."
  BSTRING bmsg6, "Entering ring 3..."
  BSTRING author, "Author: Wu Fuheng"
  BSTRING email , "Email : wufuheng@gmail.com"
  BSTRING date  , "Date  : 2010-02-13"
  ;pos equ (80-bmsg1_len)/2
  pos equ 1

  ;*** PCB - process control block
	ProcFrame 1 ; bunny_p1
	ProcFrame 2 ; bunny_p2


end_start_protected:

;*********************************************************************
[section FuncSeg]
BITS 32
ALIGN 32
start_funseg:
  ;*** push 24msg, 20msg_len, 16row, 12column; call PrintLn_ 
  ;*****************
	printline:
	  push  ebp
	  mov ebp, esp
	  push  ebx
	  push  esi
	  push  edi
	
	  mov ecx, [ebp+16+4];len
	  push 0
	.1:
	  mov eax, [ebp+12+4];row=2
	  mov edx, 80
	  mul edx ; mul will affect EDX!!!
	  add eax, [ebp+8+4];column
	  shl eax, 1
	  mov edi, eax
	  mov edx, [ebp+20+4]
	  pop ebx
	  mov al, byte [edx+ebx]
	  mov ah, 0ch
	  mov [fs:edi], ax
	  inc ebx
	  push ebx
	  mov ebx, [ebp+8+4]
	  inc ebx
	  mov [ebp+8+4],ebx
	  LOOP .1
    add esp,4 ; <=> pop ebx

	  pop edi
	  pop esi
	  pop ebx
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
end_funseg:

;********************************************************
[SECTION R3Code]
BITS 32
align 32
start_ring3code:
  ;PPrintLn pdata244, 15, 1
  mov edi,(80*14+1)*2
  mov al,'R'
  mov ah,0Ah
  mov [fs:edi],ax
  mov edi,(80*14+2)*2
  mov al,'3'
  mov ah,0Ah
  mov [fs:edi],ax

  call (GATE_1-GDT_1+SA_RPL3):0
  jmp $
  BSTRING pdata244, "Enter ring 3"
end_ring3code:

;********************************************************
[SECTION MyGate]
BITS 32
align 32
start_gate:
  ;PPrintLn pdata262, 16, 1
  mov edi,(80*15+1)*2
  mov al,'R'
  mov ah,0Ah
  mov [fs:edi],ax
  mov edi,(80*15+2)*2
  mov al,'0'
  mov ah,0Ah
  mov [fs:edi],ax
  ;jmp (LDT_2-LDT_1 + 0100b):0 ;*** go to LDT code segment

  jmp $
  BSTRING pdata262, "Return to ring 0"
end_gate:

;********************************************************
BITS 16
[section RealAddressMode]
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

  ; 2. close interrupt
  cli

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
