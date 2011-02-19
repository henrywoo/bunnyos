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
BITS 32
[SECTION LDT]
ALIGN 32
start_ldt:
LDT_1: Descriptor 0, (end_ldtcode1-start_ldtcode1), DA_C+DA_32
LDT_2: Descriptor 0, (end_ldtcode2-start_ldtcode2), DA_C+DA_32

LDTLEN equ $-LDT_1

[SECTION LPROC1]
ALIGN 32
start_ldtcode1:
  call proc1
  ;*** my first process in bunnyOS
  BSTRING p1data, "I am proc 1 in ring 0: 0"
	proc1:
	.1:
    push p1data
    push p1data_len
    push 13
    push 1
    call (GDT_3-GDT_1):(PrintLn_Far-start_protected) ;*** far call
    add esp, 4*4
    nop
	  inc byte [p1data+p1data_len-1]
	  loop .1
	  ret
end_ldtcode1:

[SECTION LPROC2]
ALIGN 32
start_ldtcode2:
  call proc2
  jmp (LDT_1-LDT_1 + 0100b):0
  ;jmp $

  ;*** my second process in bunnyOS
	proc2:
	.1:
	  ;PPrintLn p2data, 12, 1 ;***call function in different segment XX
    push p2data
    push p2data_len
    push 12
    push 1
    call (GDT_3-GDT_1):(PrintLn_Far-start_protected) ;*** far call
    ;call far PrintLn_ ;binary output format does not support segment base references
    add esp, 16
    nop
	  ;inc byte [p2data+p2data_len-1]
	  ;loop .1
	  ret

BSTRING p2data, "I am proc 2 in ring 0: 0"
end_ldtcode2:

[section GDT]
ALIGN 32
GDT_1: Descriptor 0,0,0
GDT_2: Descriptor 0B8000h, 32*1024-1, DA_DRW ;***video
GDT_3: Descriptor 0, (end_start_protected-start_protected-1), DA_CR+DA_32
GDT_4: Descriptor STACKBOT, (STACKTOP-STACKBOT-1), DA_DRWA+DA_32 ;stack
GDT_5: Descriptor 0, LDTLEN-1, DA_LDT ;LDT
GDT_6: Descriptor 0, 0, DA_DRWA+DA_32 ;IDT
GDT_7: Descriptor 0, 0, DA_DRWA+DA_32 ;TSS

GDTLEN equ $-GDT_1
STACKTOP equ 7C00h ; ~ 30K stack space
STACKBOT equ 500h

gdtptr  dw (GDTLEN - 1)
        dd (GDT_1)

;*********************************************************************
[section ProtectedMode]
start_protected:

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

  ;call proc1
  mov ax, (GDT_5-GDT_1)
  lldt ax
  
  jmp (LDT_2-LDT_1 + 0100b):0

  ; 2. Continued ...
  jmp $

  BSTRING bmsg1, "BunnyOS 1.0"
  BSTRING bmsg2, "Protected Mode"
  BSTRING author, "Author: Wu Fuheng"
  BSTRING email , "Email : wufuheng@gmail.com"
  BSTRING date  , "Date  : 2010-02-13"
  ;pos equ (80-bmsg1_len)/2
  pos equ 1

  ;*** PCB - process control block
  ;*******************************
	ProcFrame 1 ; bunny_p1
	ProcFrame 2 ; bunny_p2

  ; initialize PCB
  ;*******************************
  mov dword [ldt_sel_1],0
	
	
  ;*** push 20msg, 16msg_len, 12row, 8column; call PrintLn_ 
  ;*****************
	PrintLn_:
	  push  ebp
	  mov ebp, esp
	  push  ebx
	  push  esi
	  push  edi
	
	  mov ecx, [ebp+16];len
	  push 0
	.1:
	  mov eax, [ebp+12];row=2
	  mov edx, 80
	  mul edx ; mul will affect EDX!!!
	  add eax, [ebp+8];column
	  shl eax, 1
	  mov edi, eax
	  mov edx, [ebp + 20]
	  pop ebx
	  mov al, byte [edx + ebx]
	  mov ah, 0Ah
	  mov [fs:edi], ax
	  inc ebx
	  push ebx
	  mov ebx, [ebp+8]
	  inc ebx
	  mov [ebp+8],ebx
	  LOOP .1
	
	  pop ebx
	  pop edi
	  pop esi
	  pop ebx
	  pop ebp
	  ret

	PrintLn_Far:
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
	  mov al, byte [edx + ebx]
	  mov ah, 0ch
	  mov [fs:edi], ax
	  inc ebx
	  push ebx
	  mov ebx, [ebp+8+4]
	  inc ebx
	  mov [ebp+8+4],ebx
	  LOOP .1
	
	  pop ebx; 
	  pop edi
	  pop esi
	  pop ebx
	  pop ebp
	  retf


end_start_protected:


;********************************************************
BITS 16
[section RealAddressMode]
start_real:

  ; 0. calculate Protected mode segment descp
  DTBaseEqual GDT_3,start_protected
  DTBaseEqual GDT_5,start_ldt
  DTBaseEqual LDT_1,start_ldtcode1
  DTBaseEqual LDT_2,start_ldtcode2

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
