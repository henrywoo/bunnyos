; 1. Read kernel.bun and load -> 7E00h ~ 9FC00 (600K)
; 2. Jump to 7E00h and execute kernel

org 07c00h
jmp short BOOTSECT
nop

%include "fat12hdr.inc"
%include "macro.inc"
%include "pm.inc"


BITS 16
BOOTSECT:
  mov  ax, cs
  mov  ds, ax
  mov  es, ax
  mov  ss, ax
  mov  sp, 07c00h

  clear_screen 0,0,184fh
  int  13h

  mov  word [wSectorNo], SectorNoOfRootDirectory
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
  mov  dh, 2
  call  DispStr
  jmp  $
LABEL_FILENAME_FOUND:
  mov  ax, RootDirSectors
  and  di, 0FFE0h
  add  di, 01Ah
  mov  cx, word [es:di]
  push  cx
  add  cx, ax
  add  cx, DeltaSectorNo
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
  mov  dx, RootDirSectors
  add  ax, dx
  add  ax, DeltaSectorNo
  add  bx, [BPB_BytsPerSec]
  jmp  LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
  mov  dh, 1
  call  DispStr
  jmp  KERNELADDR:0

wRootDirSizeForLoop  dw  RootDirSectors
wSectorNo            dw  0
KERNELFileName       db  "KERNEL  BUN", 0
MessageLength        equ  0ah
BootMessage          db  "Booting..."
Message1             db  "Loading..."
Message2             db  "No KERNEL."

DispStr:
  mov  ax, MessageLength
  mul  dh
  add  ax, BootMessage
  mov  bp, ax
  mov  ax, ds
  mov  es, ax
  mov  cx, MessageLength
  mov  ax, 01301h
  mov  bx, 000Ah
  mov  dx, 0
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

bOdd                 db  0
GetFATEntry:
  push  es
  push  bx
  push  ax
  mov  ax, KERNELADDR
  sub  ax, 0100h
  mov  es, ax
  pop  ax
  mov  byte [bOdd], 0
  mov  bx, 3
  mul  bx
  mov  bx, 2
  div  bx
  cmp  dx, 0
  jz  LABEL_EVEN
  mov  byte [bOdd], 1
LABEL_EVEN:
  xor  dx, dx
  mov  bx, [BPB_BytsPerSec]
  div  bx

  push  dx
  mov  bx, 0
  add  ax, SectorNoOfFAT1
  mov  cl, 2
  call  ReadSector
  pop  dx
  add  bx, dx
  mov  ax, [es:bx]
  cmp  byte [bOdd], 1
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

