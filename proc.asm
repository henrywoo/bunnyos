
OneMB equ 1024*1024
STACKTOP equ 7C00h ; ~ 30K stack space
STACKBOT equ 500h




%macro DEFTSS 1
%1:
  backlink  dd 0
  esp0      dd 0; top of stack of ring 0
  ss0       dd 0
  esp1      dd 0
  ss1       dd 0
  esp2      dd 0
  ss2       dd 0
  cr3_      dd 0
  eip_      dd 0
  flags     dd 0
  eax_      dd 0
  ecx_      dd 0
  edx_      dd 0
  ebx_      dd 0
  esp_      dd 0
  ebp_      dd 0
  esi_      dd 0
  edi_      dd 0
  es_      dd 0
  cs_      dd 0
  ss_      dd 0
  ds_      dd 0
  fs_      dd 0
  gs_      dd 0
  ldt_     dd 0

  trap_      dw 0
  iobase_    dw $-%1+2 
  DB 0ffh
end_ %+ %1 :
%endmacro
