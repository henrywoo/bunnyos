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
   decp1_ %+ %1    dd 0
                   dd 0 
   decp2_ %+ %1    dd 0
                   dd 0 
   pid_ %+ %1      dd 0
   pname_ %+ %1 times 16 db 0
bunny_p %+ %1 %+ _end:
%endmacro

%macro DEFTSS 1
%1:
  backlink  dd 0
  esp0      dd 0
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
  iobase_    dw 0
%endmacro
