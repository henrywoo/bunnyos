
;                    The BunnyOS
;  Copyright (C) 2011 WuFuheng@gmail.com, Singapore
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <http://www.gnu.org/licenses/>.


%ifndef H_CONST_
%define H_CONST_

;基于 FAT12 头的一些常量定义，如果头信息改变，下面的常量可能也要做相应改变
;*******************************************************************
;BPB_FATSz16
FATSZ           equ 9
;根目录占用空间: 
;RootDirSectors = ((BPB_RootEntCnt * 32) + (BPB_BytsPerSec – 1)) / BPB_BytsPerSec
;但如果按照此公式代码过长
ROOTDIRSECTORS  equ 14
;Root Directory 的第一个扇区号 = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz)
SECTORNOOFROOTDIRECTORY equ 19
;FAT1 的第一个扇区号 = BPB_RsvdSecCnt
SECTORNOOFFAT1  equ 1
;DeltaSectorNo = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
;文件的开始Sector号=DIRENTRY中的开始Sector号+根目录占用Sector数目+DELTASECTORNO
DELTASECTORNO   equ 17

;GDT.........................
;*******************************************************************
DA_32                   equ 4000h 
DA_LIMIT_4K             equ 8000h
DA_DPL0                 equ 00h 
DA_DPL1                 equ 20h 
DA_DPL2                 equ 40h 
DA_DPL3                 equ 60h 
DA_DR                   equ 90h 
DA_DRW                  equ 92h 
DA_DRWA                 equ 93h 
DA_C                    equ 98h 
DA_CR                   equ 9Ah 
DA_CCO                  equ 9Ch 
DA_CCOR                 equ 9Eh 
DA_LDT                  equ 82h 
DA_Taskmc_descp_gate    equ 85h 
DA_386TSS               equ 89h 
DA_386Cmc_descp_gate    equ 8Ch 
DA_386Imc_descp_gate    equ 8Eh 
DA_386Tmc_descp_gate    equ 8Fh 
SA_RPL0                 equ 0 
SA_RPL1                 equ 1 
SA_RPL2                 equ 2 
SA_RPL3                 equ 3 
SA_TIG                  equ 0 
SA_TIL                  equ 4 
PG_P                    equ 1 
PG_RWR                  equ 0 
PG_RWW                  equ 2 
PG_USS                  equ 0 
PG_USU                  equ 4 


;Absolute Address Constants
;*******************************************************************
KERNELADDR              equ 7E0h
KERNELADDRABS           equ 7E00h ;200h = 512
STACKTOP                equ 7C00h ;~ 30K stack space
STACKBOT                equ 500h

;Others
;*******************************************************************
ONEMB                   equ 1024*1024
ONEKB                   equ 1024
SEG_MAXSIZE             equ ONEMB-1
PMR0STACK_LEN           equ (7c00h-500h-1)

; Constants and Macros related to KeyBoard
;*******************************************************************
%define KB_IN_BYTES     32  ; size of keyboard input buffer 
%define MAP_COLS        3 ; Number of columns in keymap 
%define NR_SCAN_CODES   0x80  ; Number of scan codes (rows in keymap) 

%define FLAG_BREAK      0x0080    ; Break Code     
%define FLAG_EXT        0x0100    ; Normal function keys   
%define FLAG_SHIFT_L    0x0200    ; Shift key      
%define FLAG_SHIFT_R    0x0400    ; Shift key      
%define FLAG_CTRL_L     0x0800    ; Control key      
%define FLAG_CTRL_R     0x1000    ; Control key      
%define FLAG_ALT_L      0x2000    ; Alternate key    
%define FLAG_ALT_R      0x4000    ; Alternate key    
%define FLAG_PAD        0x8000    ; keys in num pad    

;raw key value = code passed to tty & MASK_RAW the value can 
;be found either in the keymap column 0 or in the list below 
%define MASK_RAW  0x01FF

; Special keys 
%define ESC             (0x01 + FLAG_EXT) ; Esc    
%define TAB             (0x02 + FLAG_EXT) ; Tab    
%define ENTER_CHAR      (0x03 + FLAG_EXT) ; Enter  
%define BACKSPACE       (0x04 + FLAG_EXT) ; BackSpace  

%define GUI_L           (0x05 + FLAG_EXT) ; L GUI  
%define GUI_R           (0x06 + FLAG_EXT) ; R GUI  
%define APPS            (0x07 + FLAG_EXT) ; APPS 

; Shift, Ctrl, Alt 
%define SHIFT_L         (0x08 + FLAG_EXT) ; L Shift  
%define SHIFT_R         (0x09 + FLAG_EXT) ; R Shift  
%define CTRL_L          (0x0A + FLAG_EXT) ; L Ctrl 
%define CTRL_R          (0x0B + FLAG_EXT) ; R Ctrl 
%define ALT_L           (0x0C + FLAG_EXT) ; L Alt  
%define ALT_R           (0x0D + FLAG_EXT) ; R Alt  

; Lock keys 
%define CAPS_LOCK       (0x0E + FLAG_EXT) ; Caps Lock  
%define NUM_LOCK        (0x0F + FLAG_EXT) ; Number Lock  
%define SCROLL_LOCK     (0x10 + FLAG_EXT) ; Scroll Lock  

; Function keys 
%define F1              (0x11 + FLAG_EXT) ; F1   
%define F2              (0x12 + FLAG_EXT) ; F2   
%define F3              (0x13 + FLAG_EXT) ; F3   
%define F4              (0x14 + FLAG_EXT) ; F4   
%define F5              (0x15 + FLAG_EXT) ; F5   
%define F6              (0x16 + FLAG_EXT) ; F6   
%define F7              (0x17 + FLAG_EXT) ; F7   
%define F8              (0x18 + FLAG_EXT) ; F8   
%define F9              (0x19 + FLAG_EXT) ; F9   
%define F10             (0x1A + FLAG_EXT) ; F10    
%define F11             (0x1B + FLAG_EXT) ; F11    
%define F12             (0x1C + FLAG_EXT) ; F12    

; Control Pad 
%define PRINTSCREEN     (0x1D + FLAG_EXT) ; Print Screen 
%define PAUSEBREAK      (0x1E + FLAG_EXT) ; Pause/Break  
%define INSERT          (0x1F + FLAG_EXT) ; Insert 
%define DELETE          (0x20 + FLAG_EXT) ; Delete 
%define HOME            (0x21 + FLAG_EXT) ; Home   
%define END_CHAR        (0x22 + FLAG_EXT) ; End    
%define PAGEUP          (0x23 + FLAG_EXT) ; Page Up  
%define PAGEDOWN        (0x24 + FLAG_EXT) ; Page Down  
%define UP              (0x25 + FLAG_EXT) ; Up   
%define DOWN            (0x26 + FLAG_EXT) ; Down   
%define LEFT            (0x27 + FLAG_EXT) ; Left   
%define RIGHT           (0x28 + FLAG_EXT) ; Right  

; ACPI keys 
%define POWER           (0x29 + FLAG_EXT) ; Power  
%define SLEEP           (0x2A + FLAG_EXT) ; Sleep  
%define WAKE            (0x2B + FLAG_EXT) ; Wake Up  

; Num Pad 
%define PAD_SLASH       (0x2C + FLAG_EXT) ; /    
%define PAD_STAR        (0x2D + FLAG_EXT) ; *    
%define PAD_MINUS       (0x2E + FLAG_EXT) ; -    
%define PAD_PLUS        (0x2F + FLAG_EXT) ; +    
%define PAD_ENTER_CHAR  (0x30 + FLAG_EXT) ; Enter  
%define PAD_DOT         (0x31 + FLAG_EXT) ; .    
%define PAD_0           (0x32 + FLAG_EXT) ; 0    
%define PAD_1           (0x33 + FLAG_EXT) ; 1    
%define PAD_2           (0x34 + FLAG_EXT) ; 2    
%define PAD_3           (0x35 + FLAG_EXT) ; 3    
%define PAD_4           (0x36 + FLAG_EXT) ; 4    
%define PAD_5           (0x37 + FLAG_EXT) ; 5    
%define PAD_6           (0x38 + FLAG_EXT) ; 6    
%define PAD_7           (0x39 + FLAG_EXT) ; 7    
%define PAD_8           (0x3A + FLAG_EXT) ; 8    
%define PAD_9           (0x3B + FLAG_EXT) ; 9    
%define PAD_UP          PAD_8     ; Up   
%define PAD_DOWN        PAD_2     ; Down   
%define PAD_LEFT        PAD_4     ; Left   
%define PAD_RIGHT       PAD_6     ; Right  
%define PAD_HOME        PAD_7     ; Home   
%define PAD_END_CHAR    PAD_1     ; End    
%define PAD_PAGEUP      PAD_9     ; Page Up  
%define PAD_PAGEDOWN    PAD_3     ; Page Down  
%define PAD_INS         PAD_0     ; Ins    
%define PAD_MID         PAD_5     ; Middle key 
%define PAD_DEL         PAD_DOT     ; Del    

;IPC constants
%define INT_SYS_CALL    0x99
%define _NR_PRINTX      0
%define _NR_SENDREC     1

%define SEND            1
%define RECEIVE         2
%define BOTH            3 ; BOTH = (SEND | RECEIVE) 

%define SENDING         0010B  ;/* set when proc trying to send */
%define RECEIVING       0100B  ;/* set when proc trying to recv */

;* when hard interrupt occurs, a msg (with type==HARD_INT) will
;* be sent to some tasks
%define HARD_INT        1
%define GET_TICKS       2 ;   /* SYS task */
%define DEV_OPEN        1001,
%define DEV_CLOSE       1002
%define DEV_READ        1003
%define DEV_WRITE       1004
%define DEV_IOCTL       1005   /* message type for drivers */

%define TASK_SYS        1

%define ANY_PROC        10000000b
%define NO_TASK         10000001b

%define PCB_len (bunny_p2-bunny_p1)

%endif
   
