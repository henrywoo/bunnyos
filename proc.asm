
OneMB equ 1024*1024
SEG_MAXSIZE equ OneMB-1
OneK equ 1024
STACKTOP equ 7C00h ; ~ 30K stack space
STACKBOT equ 500h
pmr0stack_len equ (7c00h-500h-1)


%macro ProcFrame 1
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

%endmacro
