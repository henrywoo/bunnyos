; macro of boot


;********************
;%macro clear_screen macro colour,row1,col1
%macro clear_screen 3
  ;pusha  
  mov ah,07h
  mov al,0
  mov bh,%1
  mov cx,%2
  mov dx,%3
  int 10h
  ;popa   
%endmacro  

%macro BSTRING 2
  %1 db %2
  %1 %+ _len equ $ - %1
%endmacro

;INT 10 - VIDEO - WRITE STRING (AT,XT286,PS,EGA,VGA)
;	AH = 13h
;	AL = mode
;	    bit 0: set in order to move cursor after write
;	    bit 1: set if string contains alternating characters and attributes
;	BL = attribute if AL bit 1 clear
;	BH = display page number
;	DH,DL = row,column of starting cursor position
;	CX = length of string
;	ES:BP = pointer to start of string

; PRINTLN bmsg,bmsp_len,NO_OF_ROW, color

%macro PRINTLN 3
mov ax, %1
mov bp, ax
mov cx, %1 %+ _len ; CX = 串长度
mov ax, 1301h  ; AH = 13,  AL = 01h
mov bh, 00h
mov bl, %3  ; 页号为0(BH = 0) 黑底红字(BL = 0Ch,高亮)
mov dh, %2
mov dl, 01h
int 10h   ; 10h 号中断
%endmacro

%macro PPrintLn 3
  push %1
  push %1 %+ _len
  push %2
  push %3
  call (GDT_8-GDT_1):(printline-start_funseg) ;*** far call
  ;call PrintLn_
  add esp, 16
%endmacro

%macro DTBaseEqual 2
  xor eax, eax
  mov eax, (%2)
  mov word[%1+2], ax
  shr eax, 16
  mov byte [%1+4], al
  mov byte [%1+7], ah
%endmacro

%define STARTLINE 1
