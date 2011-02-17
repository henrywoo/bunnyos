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
[section GDT]
GDT_1: Descriptor 0,0,0
GDT_2: Descriptor 0B8000h, 32*1024-1, DA_DRW ;***video
GDT_3: Descriptor 0, (end_start_protected-start_protected-1), DA_CR+DA_32 ;??????
GDT_4: Descriptor STACKBOT, (STACKTOP-STACKBOT-1), DA_DRWA+DA_32 ;stack

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
  PPrintLn bmsg1, 5, pos
  PPrintLn author,7, pos
  PPrintLn email, 8, pos
  PPrintLn date,  9, pos

  call proc1

  ; 2. Continued ...
  jmp $

  BSTRING bmsg1, "**********************************************************"
  BSTRING bmsg2, "******************* BunnyOS 1.0 **************************"
  BSTRING author, "Author: Wu Fuheng"
  BSTRING email , "Email : wufuheng@gmail.com"
  BSTRING date  , "Date  : 2010-02-13"
  pos equ (80-bmsg1_len)/2










  ;*** PCB - process control block
  ;*******************************
	ProcFrame 1 ; bunny_p1
	ProcFrame 2 ; bunny_p2
	
  ;*** my first process in bunnyOS
  ;*******************************
	BSTRING p1data, "0"
	proc1:
	.1
	  PPrintLn p1data, 11, 0
	  call delay
	  inc byte [p1data]
	  loop .1
	  ret
	
	delay:
	  nop
	  ret
  















  ; push 20msg, 16msg_len, 12row, 8column; call PrintLn_ 
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

end_start_protected:



;********************************************************
BITS 16
[section RealAddressMode]
start_real:

  ; 0. calculate Protected mode segment descp
  xor eax, eax
  mov eax, (start_protected)
  mov word[GDT_3+2], ax
  shr eax, 16
  mov byte [GDT_3+4], al
  mov byte [GDT_3+7], ah

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
