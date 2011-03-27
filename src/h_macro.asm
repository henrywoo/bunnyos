; BunnyOS 1.0
;
; Copyright (C) 2011 Wu Fuheng.
;
; BunnyOS is free software;  you can  redistribute it and/or modify it under
; the terms of the GNU LESSER GENERAL PUBLIC LICENSE as published by the
; Free Software Foundation; either version 2.1, or (at your option)  any
; later version.
; 
; BunnyOS is distributed in the hope that it will be useful, but WITHOUT ANY
; WARRANTY; without  even  the  implied  warranty  of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the  GNU General Public License
; for more details.
; 
; You  should  have  received  a  copy of the GNU General Public License
; along  with  BunnyOS;  see the  file COPYING.  If not, please write to the
; Free Software Foundation,  51 Franklin Street, Fifth Floor, Boston, MA
; 02110-1301, USA.

%ifndef H_MACRO_
%define H_MACRO_

; Data macro
;************************************************************
;{ mc_descp for code/system segment
%macro mc_descp 3
 dw %2 & 0FFFFh    
 dw %1 & 0FFFFh    
 db (%1 >> 16) & 0FFh   
 dw ((%2 >> 8) & 0F00h) | ((%3) & 0F0FFh) 
 db (%1 >> 24) & 0FFh   
%endmacro ;}

%macro mc_descp_gate 4
 dw (%2 & 0FFFFh)    
 dw %1     
 dw (%3 & 1Fh) | ((%4 << 8) & 0FF00h) 
 dw ((%2 >> 16) & 0FFFFh)   
%endmacro 

%macro mc_string 2
  %1 db %2
  %1 %+ _len equ $ - %1
%endmacro

;{ struct for keyboard mapping data
%macro mc_data_keyboard 0
@keymapdata:
  db 0,      0,      0                    ; 0x00 - none    
  db ESC,    ESC,    0                    ; 0x01 - ESC   
  db '1',    '!',    0                    ; 0x02 - '1'   
  db '2',    '@',    0                    ; 0x03 - '2'   
  db '3',    '#',    0                    ; 0x04 - '3'   
  db '4',    '$',    0                    ; 0x05 - '4'   
  db '5',    '%',    0                    ; 0x06 - '5'   
  db '6',    '^',    0                    ; 0x07 - '6'   
  db '7',    '&',    0                    ; 0x08 - '7'   
  db '8',    '*',    0                    ; 0x09 - '8'   
  db '9',    '(',    0                    ; 0x0A - '9'   
  db '0',    ')',    0                    ; 0x0B - '0'   
  db '-',    '_',    0                    ; 0x0C - '-'   
  db '=',    '+',    0                    ; 0x0D - '='   
  db BACKSPACE,  BACKSPACE,  0            ; 0x0E - BS    
  db TAB,    TAB,    0                    ; 0x0F - TAB   
  db 'q',    'Q',    0                    ; 0x10 - 'q'   
  db 'w',    'W',    0                    ; 0x11 - 'w'   
  db 'e',    'E',    0                    ; 0x12 - 'e'   
  db 'r',    'R',    0                    ; 0x13 - 'r'   
  db 't',    'T',    0                    ; 0x14 - 't'   
  db 'y',    'Y',    0                    ; 0x15 - 'y'   
  db 'u',    'U',    0                    ; 0x16 - 'u'   
  db 'i',    'I',    0                    ; 0x17 - 'i'   
  db 'o',    'O',    0                    ; 0x18 - 'o'   
  db 'p',    'P',    0                    ; 0x19 - 'p'   
  db '[',    '{',    0                    ; 0x1A - '['   
  db ']',    '}',    0                    ; 0x1B - ']'   
  db ENTER_CHAR,    ENTER_CHAR,    PAD_ENTER_CHAR,       ; 0x1C - CR/LF   
  db CTRL_L,   CTRL_L,   CTRL_R,          ; 0x1D - l. Ctrl 
  db 'a',    'A',    0                    ; 0x1E - 'a'   
  db 's',    'S',    0                    ; 0x1F - 's'   
  db 'd',    'D',    0                    ; 0x20 - 'd'   
  db 'f',    'F',    0                    ; 0x21 - 'f'   
  db 'g',    'G',    0                    ; 0x22 - 'g'   
  db 'h',    'H',    0                    ; 0x23 - 'h'   
  db 'j',    'J',    0                    ; 0x24 - 'j'   
  db 'k',    'K',    0                    ; 0x25 - 'k'   
  db 'l',    'L',    0                    ; 0x26 - 'l'   
  db ';',    ':',    0                    ; 0x27 - ';'   
  db 0x27,   0x22,    0 ;                 ; 0x28 - '\''    ;db "\'",   '\"',    0
  db '`',    '~',    0                    ; 0x29 - '`'   
  db SHIFT_L,  SHIFT_L,  0                ; 0x2A - l. SHIFT  
  db 5ch,   7ch,    0                     ; 0x2B - '\'   ;db '\\',   '|',    0;hex(ord("|"))=0x7c
  db 'z',    'Z',    0                    ; 0x2C - 'z'   
  db 'x',    'X',    0                    ; 0x2D - 'x'   
  db 'c',    'C',    0                    ; 0x2E - 'c'   
  db 'v',    'V',    0                    ; 0x2F - 'v'   
  db 'b',    'B',    0                    ; 0x30 - 'b'   
  db 'n',    'N',    0                    ; 0x31 - 'n'   
  db 'm',    'M',    0                    ; 0x32 - 'm'   
  db ',',    '<',    0                    ; 0x33 - ','   
  db '.',    '>',    0                    ; 0x34 - '.'   
  db '/',    '?',    PAD_SLASH,           ; 0x35 - '/'   
  db SHIFT_R,  SHIFT_R,  0                ; 0x36 - r. SHIFT  
  db '*',    '*',      0                  ; 0x37 - '*'   
  db ALT_L,    ALT_L,    ALT_R,           ; 0x38 - ALT   
  db ' ',    ' ',    0                    ; 0x39 - ' '   
  db CAPS_LOCK,  CAPS_LOCK,  0            ; 0x3A - CapsLock  
  db F1,   F1,   0                        ; 0x3B - F1    
  db F2,   F2,   0                        ; 0x3C - F2    
  db F3,   F3,   0                        ; 0x3D - F3    
  db F4,   F4,   0                        ; 0x3E - F4    
  db F5,   F5,   0                        ; 0x3F - F5    
  db F6,   F6,   0                        ; 0x40 - F6    
  db F7,   F7,   0                        ; 0x41 - F7    
  db F8,   F8,   0                        ; 0x42 - F8    
  db F9,   F9,   0                        ; 0x43 - F9    
  db F10,    F10,    0                    ; 0x44 - F10   
  db NUM_LOCK, NUM_LOCK, 0                ; 0x45 - NumLock 
  db SCROLL_LOCK,  SCROLL_LOCK,  0        ; 0x46 - ScrLock 
  db PAD_HOME, '7',    HOME,              ; 0x47 - Home    
  db PAD_UP,   '8',    UP,                ; 0x48 - CurUp   
  db PAD_PAGEUP, '9',    PAGEUP,          ; 0x49 - PgUp    
  db PAD_MINUS,  '-',    0                ; 0x4A - '-'   
  db PAD_LEFT, '4',    LEFT,              ; 0x4B - Left    
  db PAD_MID,  '5',    0                  ; 0x4C - MID   
  db PAD_RIGHT,  '6',    RIGHT,           ; 0x4D - Right   
  db PAD_PLUS, '+',    0                  ; 0x4E - '+'   
  db PAD_END_CHAR,  '1',    END_CHAR,               ; 0x4F - End   
  db PAD_DOWN, '2',    DOWN,              ; 0x50 - Down    
  db PAD_PAGEDOWN, '3',    PAGEDOWN,      ; 0x51 - PgDown  
  db PAD_INS,  '0',    INSERT,            ; 0x52 - Insert  
  db PAD_DOT,  '.',    DELETE,            ; 0x53 - Delete  
  db 0,    0,    0                        ; 0x54 - Enter   
  db 0,    0,    0                        ; 0x55 - ???   
  db 0,    0,    0                        ; 0x56 - ???   
  db F11,    F11,    0                    ; 0x57 - F11   
  db F12,    F12,    0                    ; 0x58 - F12   
  db 0,    0,    0                        ; 0x59 - ???   
  db 0,    0,    0                        ; 0x5A - ???   
  db 0,    0,    GUI_L,                   ; 0x5B - ???   
  db 0,    0,    GUI_R,                   ; 0x5C - ???   
  db 0,    0,    APPS,                    ; 0x5D - ???   
  db 0,    0,    0                        ; 0x5E - ???   
  db 0,    0,    0                        ; 0x5F - ???   
  db 0,    0,    0                        ; 0x60 - ???   
  db 0,    0,    0                        ; 0x61 - ???   
  db 0,    0,    0                        ; 0x62 - ???   
  db 0,    0,    0                        ; 0x63 - ???   
  db 0,    0,    0                        ; 0x64 - ???   
  db 0,    0,    0                        ; 0x65 - ???   
  db 0,    0,    0                        ; 0x66 - ???   
  db 0,    0,    0                        ; 0x67 - ???   
  db 0,    0,    0                        ; 0x68 - ???   
  db 0,    0,    0                        ; 0x69 - ???   
  db 0,    0,    0                        ; 0x6A - ???   
  db 0,    0,    0                        ; 0x6B - ???   
  db 0,    0,    0                        ; 0x6C - ???   
  db 0,    0,    0                        ; 0x6D - ???   
  db 0,    0,    0                        ; 0x6E - ???   
  db 0,    0,    0                        ; 0x6F - ???   
  db 0,    0,    0                        ; 0x70 - ???   
  db 0,    0,    0                        ; 0x71 - ???   
  db 0,    0,    0                        ; 0x72 - ???   
  db 0,    0,    0                        ; 0x73 - ???   
  db 0,    0,    0                        ; 0x74 - ???   
  db 0,    0,    0                        ; 0x75 - ???   
  db 0,    0,    0                        ; 0x76 - ???   
  db 0,    0,    0                        ; 0x77 - ???   
  db 0,    0,    0                        ; 0x78 - ???   
  db 0,    0,    0                        ; 0x78 - ???   
  db 0,    0,    0                        ; 0x7A - ???   
  db 0,    0,    0                        ; 0x7B - ???   
  db 0,    0,    0                        ; 0x7C - ???   
  db 0,    0,    0                        ; 0x7D - ???   
  db 0,    0,    0                        ; 0x7E - ???   
  db 0,    0,    0                        ; 0x7F - ???   

  KEYMAPDATA_SIZE equ $ - @keymapdata
  KEYMAPDATA_COLUMN_NUM equ 3
  KEYMAPDATA_ROW_NUM equ KEYMAPDATA_SIZE/3
%endmacro;}

;{ struct for Process Control Table(PCB)
%macro mc_pcb_table 1
bunny_p %+ %1:
   gs_ %+ %1    dd 0
   fs_ %+ %1    dd sel_video;***0
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
   ;etaddr_ %+ %1 dd 13
   eip_ %+ %1     dd 0
   cs_ %+ %1      dd 0
   eflags_ %+ %1  dd 0
   esp_ %+ %1     dd 0
   ss_ %+ %1      dd 0

   sel_ldt %+ %1 %+ _  dw 0
   pid_ %+ %1      dd 0
   pname_ %+ %1 times 16 db 0
%endmacro;}



;************************************************************
; Text/Code macro - function like macro
;************************************************************
%macro mc_clearscreen 0 ;{ @param macro colour,row1,col1
  mov ah,07h
  mov al,0
  mov bh,0;color
  mov cx,0;row
  mov dx,184fh
  int 10h
%endmacro;}

;PRINTLN bmsg,bmsp_len,NO_OF_ROW, color
%macro mc_printstr_realmode 3
  mov ax, %1
  mov bp, ax
  mov cx, %1 %+ _len ;CX = 串长度
  mov ax, 1301h  ;AH = 13,  AL = 01h
  mov bh, 00h
  mov bl, %3  ;页号为0(BH = 0) 黑底红字(BL = 0Ch,高亮)
  mov dh, %2
  mov dl, 01h
  int 10h   ;10h 号中断
%endmacro

%macro mc_assign_descp_base 2
  xor eax, eax
  mov eax, (%2)
  mov word[%1+2], ax
  shr eax, 16
  mov byte [%1+4], al
  mov byte [%1+7], ah
%endmacro

%macro mc_func_start 0
    push  ebp
    mov ebp, esp
    push  ebx
    push  esi
    push  edi
%endmacro

%macro mc_func_end 0
    pop edi
    pop esi
    pop ebx
    pop ebp
    retf
%endmacro

%macro mc_shortfunc_start 0
    push  ebp
    mov ebp, esp
    pushad
%endmacro

%macro mc_shortfunc_end 0
    popad
    pop ebp
    ret
%endmacro

%macro _mc_out_byte 2
  push %1
  push %2
  call out_byte
%endmacro
%define mc_out_byte(X,Y) _mc_out_byte X,Y

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

%define MAKE_DEVICE_REG(lba,drv,lba_highest) (((lba) << 6)|((drv) << 4)|(lba_highest & 0xF)|0xA0)

%endif
