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
;

;; 1. Read kernel.bun and load -> 7E00h ~ 9FC00 (600K)
;; 2. Jump to 7E00h and execute kernel
%include "h_macro.asm"
%include "h_const.asm"

org 07c00h
jmp short BOOTSECT
nop

;header of FAT12
;*** ----------------------------------------------------------------------
BS_OEMName      DB   'WuFuheng' ;OEM String, 必须 8 个字节
BPB_BytsPerSec  DW 512  ;每扇区字节数
BPB_SecPerClus  DB 1  ;每簇多少扇区
BPB_RsvdSecCnt  DW 1  ;Boot 记录占用多少扇区
BPB_NumFATs     DB 2  ;共有多少 FAT 表
BPB_RootEntCnt  DW 224  ;根目录文件数最大值
BPB_TotSec16    DW 2880  ;逻辑扇区总数
BPB_Media       DB 0xF0  ;媒体描述符
BPB_FATSz16     DW 9  ;每FAT扇区数
BPB_SecPerTrk   DW 18  ;每磁道扇区数
BPB_NumHeads    DW 2  ;磁头数(面数)
BPB_HiddSec     DD 0  ;隐藏扇区数
BPB_TotSec32    DD 0  ;如果 wTotalSectorCount 是 0 由这个值记录扇区数
BS_DrvNum       DB 0  ;中断 13 的驱动器号
BS_Reserved1    DB 0  ;未使用
BS_BootSig      DB 29h  ;扩展引导标记 (29h)
BS_VolID        DD 0  ;卷序列号
BS_VolLab       DB 'BunnyOS_1.0';卷标, 必须 11 个字节
BS_FileSysType  DB 'FAT12   ' ;文件系统类型, 必须 8个字节  

BITS 16
BOOTSECT:
  mov  ax, cs
  mov  ds, ax
  mov  es, ax
  mov  ss, ax
  mov  sp, 07c00h

  mc_clearscreen
  ;int  13h

  mov  word [wSectorNo], SECTORNOOFROOTDIRECTORY
 LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
  cmp  word [wRootDirSizeForLoop], 0
  jz  LABEL_NO_KERNELBIN
  dec  word [wRootDirSizeForLoop]
  mov  ax, KERNELADDR
  mov  es, ax
  mov  bx, 0
  mov  ax, [wSectorNo]
  mov  cl, 1
  call  ReadSector
  mov  si, KERNELFileName
  mov  di, 0
  cld
  mov  dx, 10h
 LABEL_SEARCH_FOR_KERNELBIN:
  cmp  dx, 0
  jz  LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
  dec  dx
  mov  cx, 11
 LABEL_CMP_FILENAME:
  cmp  cx, 0
  jz  LABEL_FILENAME_FOUND
  dec  cx
  lodsb
  cmp  al, byte [es:di]
  jz  LABEL_GO_ON
  jmp  LABEL_DIFFERENT
LABEL_GO_ON:
  inc  di
  jmp  LABEL_CMP_FILENAME
 LABEL_DIFFERENT:
  and  di, 0FFE0h
  add  di, 20h
  mov  si, KERNELFileName
  jmp  LABEL_SEARCH_FOR_KERNELBIN
 LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
  add  word [wSectorNo], 1
  jmp  LABEL_SEARCH_IN_ROOT_DIR_BEGIN
 LABEL_NO_KERNELBIN:
  mov  ax, nokernel
  mov  cx, nokernel_len
  call  DispStr
  jmp  $
 LABEL_FILENAME_FOUND:
  mov  ax, ROOTDIRSECTORS
  and  di, 0FFE0h
  add  di, 01Ah
  mov  cx, word [es:di]
  push  cx
  add  cx, ax
  add  cx, DELTASECTORNO
  mov  ax, KERNELADDR
  mov  es, ax
  mov  bx, 0
  mov  ax, cx
 LABEL_GOON_LOADING_FILE:
  push  ax
  push  bx
  mov  ah, 0Eh
  mov  al, '.'
  mov  bl, 0Fh
  int  10h
  pop  bx
  pop  ax
  mov  cl, 1
  call  ReadSector
  pop  ax
  call  GetFATEntry
  cmp  ax, 0FFFh
  jz  LABEL_FILE_LOADED
  push  ax
  mov  dx, ROOTDIRSECTORS
  add  ax, dx
  add  ax, DELTASECTORNO
  add  bx, [BPB_BytsPerSec]
  jmp  LABEL_GOON_LOADING_FILE
 LABEL_FILE_LOADED:
  mov  ax, loading
  mov  cx, loading_len
  call  DispStr
  jmp  KERNELADDR:0

wRootDirSizeForLoop   dw  ROOTDIRSECTORS
wSectorNo             dw  0
KERNELFileName        db  "KERNEL  BUN", 0
tmp0                  db  0

mc_string booting, "booting"
mc_string loading, "loading"
mc_string nokernel,"no kernel"

;INT 10 - VIDEO - WRITE STRING (AT,XT286,PS,EGA,VGA)
;AH = 13h ;AL = mode
;bit 0: set in order to move cursor after write
;bit 1: set if string contains alternating characters and attributes
;BL = attribute if AL bit 1 clear
;BH = display page number
;DH,DL = row,column of starting cursor position
;CX = length of string
;ES:BP = pointer to start of string
DispStr:
  mov  bp, ax
  mov  ax, ds
  mov  es, ax
  mov  ax, 01301h
  mov  bx, 000Ah
  mov  dx, 1
  int  10h
  ret

ReadSector:
  push  bp
  mov  bp, sp
  sub  esp, 2
  mov  byte [bp-2], cl
  push  bx
  mov  bl, [BPB_SecPerTrk]
  div  bl
  inc  ah
  mov  cl, ah
  mov  dh, al
  shr  al, 1
  mov  ch, al
  and  dh, 1
  pop  bx

  mov  dl, [BS_DrvNum]
.GoOnReading:
  mov  ah, 2
  mov  al, byte [bp-2]
  int  13h
  jc  .GoOnReading
  add  esp, 2
  pop  bp
  ret

GetFATEntry:
  push  es
  push  bx
  push  ax
  mov  ax, KERNELADDR
  sub  ax, 0100h
  mov  es, ax
  pop  ax
  mov  byte [tmp0], 0
  mov  bx, 3
  mul  bx
  mov  bx, 2
  div  bx
  cmp  dx, 0
  jz  LABEL_EVEN
  mov  byte [tmp0], 1
 LABEL_EVEN:
  xor  dx, dx
  mov  bx, [BPB_BytsPerSec]
  div  bx

  push  dx
  mov  bx, 0
  add  ax, SECTORNOOFFAT1
  mov  cl, 2
  call  ReadSector
  pop  dx
  add  bx, dx
  mov  ax, [es:bx]
  cmp  byte [tmp0], 1
  jnz  LABEL_EVEN_2
  shr  ax, 4
 LABEL_EVEN_2:
  and  ax, 0FFFh
 LABEL_GET_FAT_ENRY_OK:
  pop  bx
  pop  es
  ret

times   510-($-$$)  db  0
dw   0xaa55
