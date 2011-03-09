
;*********************************************************************
[section PMR0CODE]
BITS 32
ALIGN 32
start_pmr0code:

  ; 0. set stack
  mov dx, sel_pmr0stack
  mov ss, dx
  mov esp, pmr0stack_len

  ; 1. write video memory, showing i am in protected mode
  mov cx, sel_video
  mov fs, cx

  mov ax, sel_tss
  ltr ax

  call Init8259A

  ;*** set 10ms interrupt (8253 control register)
  push RATE_GENERATOR
  push TIMER_MODE
  call out_byte
  call io_delay

  push TIMER_FREQ/HZ
  push TIMER0
  call out_byte
  call io_delay

  push ((TIMER_FREQ/HZ) >>8)
  push TIMER0
  call out_byte
  call io_delay

  ;mov al, 34h
  ;out 43h, al
  ;nop
  ;mov al, 9bh
  ;out 40h, al
  ;nop
  ;mov al, 2eh
  ;out 40h, al

  sti

  ;***init PCB1 simon
  mov dword[ds_1],sel_ldt1data
  mov dword[cs_1],sel_ldt1code
  mov dword[eflags_1],d_eflags
  mov dword[esp_1],d_proc_stacksize
  mov dword[ss_1],sel_ldt1stack
  mov word[sel_ldt1_],sel_ldt1
  mov eax, dword [pidcount]
  mov dword[pid_1],sel_ldt1
  inc dword [pidcount]

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
  INITPBC 2
  INITPBC 3
  INITPBC 4

  mov dword[curPCB],r0addr(bunny_p1)
  mov ax, sel_ldt1
  lldt ax

  push sel_ldt1stack
  push d_proc_stacksize
  push sel_ldt1code
  push 0
  retf

  jmp $
    





  ;*** R0_Function ***
  _ClockHandler:
  ClockHandler equ _ClockHandler - $$
    pushad  
    push  ds 
    push  es 
    push  fs
    push  gs

    mov dx,sel_pmr0data
    mov ds,dx

    inc dword [r0addr(jiffies)] ;*** add jiffies
    inc dword [r0addr(reenter)]
    cmp dword [r0addr(reenter)],0
    jne .reentry
    sti

    call FillPCB

    mov al, 20h
    out 20h, al

    mov ax, sel_pmr0data
    mov ss, ax
    mov edx, dword[r0addr(curPCB)]
    add edx, PCB_len ;*** next PCB
    cmp edx, r0addr(PCBLAST)
    JA .3
    mov esp, edx
    jmp .4
  .3: 
    mov edx, r0addr(PCBSTART)
    mov esp, edx
  .4:
    add edx, (sel_ldt1_-gs_1)
    mov bx, word [edx]
    lldt bx

    ;*** Get new curPCB
    mov eax, r0addr(PCBLAST)
    cmp eax, dword[r0addr(curPCB)]
    jbe .1
    add dword[r0addr(curPCB)],PCB_len
    jmp .2
  .1:
    mov dword[r0addr(curPCB)],r0addr(PCBSTART)
  .2:
    cli
  .reentry:
    dec dword [r0addr(reenter)]
    pop gs 
    pop fs
    pop es
    pop ds
    popad
    iretd

  FillPCB:
    add esp, 4
    mov ebx,dword[r0addr(curPCB)]
    add ebx,(sel_ldt1_-gs_1);*** = 0x44 
    mov ecx,(sel_ldt1_-gs_1)/4 ;*** = 0x11
  .mmmove:
    sub ebx,4
    mov edx,[esp+ecx*4-4]
    mov dword[ebx], edx
    loop .mmmove
    sub esp, 4
    ret
 
  _SpuriousHandler:
  SpuriousHandler equ _SpuriousHandler - $$
    PRINTCHAR 0dh,'I',23,1
    PRINTCHAR 0dh,'N',23,2
    PRINTCHAR 0dh,'T',23,3
    iretd

  ; printdd eax,ebx
  %define ROWNUM 5
  %macro printdd 2
    push %1; register name; you want to print its value
    push r0addr(strdd)
    call _r0num2str

    push r0addr(strdd)
    push 8
    push ROWNUM;row
    push %2;cloumn
    call _r0printline
  %endmacro

  _KeyboardHandler:
  KeyboardHandler equ _KeyboardHandler - $$
    push  ds 
    pushad  

    mov dx,sel_pmr0data
    mov ds,dx
    
   .spin:
    in  al, 0x64
    and al, 0x01
    jz  .spin

    xor eax,eax
    in al,0x60
    
    ;cmp al,0xE1
    ;je nothing

    cmp al,0x0E
    jne .nothing2

    mov byte [r0addr(kbbuffer)+1],1
    jmp .isbreakcode

   .nothing2:
    cmp byte [r0addr(kbbuffer)+1],0
    jne .isleftornot

   .isleftornot:
    cmp al,0x8E
    jne .notleft

   .isleft:
    dec dword [r0addr(kbcount)]
    mov eax,dword [r0addr(kbcount)]
    add eax, 80*ROWNUM+1
    shl eax, 1
    call cleartext
    mov ebx, dword [r0addr(kbcount)]
    call setcursor
    jmp .isbreakcode

   .notleft:

    ; if al==0xB6 || al==0xAA ; upper case to lower case
    cmp al, 0xB6
    jne .2
   .3:
    mov byte [r0addr(kbbuffer)],0
    jmp .isbreakcode
   .2:
    cmp al, 0xAA
    je .3

    cmp al,0x2A
    je .isshift

    cmp al,0x36
    jne .notshift

   .isshift
    mov byte [r0addr(kbbuffer)], al
    jmp .isbreakcode

   .notshift

    cmp al, keymapdata_len/3
    ja .isbreakcode
    push eax

    inc dword [r0addr(kbcount)]
    mov ebx, dword [r0addr(kbcount)]

    call setcursor

    ;*** pinpoint char to print
    pop eax; for push eax
    call printkbchar

  .isbreakcode:
    mov al, 0x20 ;clear buffer
    out 0x20, al

    popad
    pop ds
    iretd

  printkbchar:
    pushad
    mov ecx, 3
    mul ecx
    add eax, r0addr(keymapdata)
    cmp byte [r0addr(kbbuffer)],0
    je .11
    inc eax
   .11
    push eax
    push 1;8; len
    push ROWNUM;row
    push ebx;cloumn
    call _r0printline
    popad
    ret

  cleartext:
    mov edx, eax
    mov al, ' '
    mov ah, 00h
    mov [fs:edx], ax
    ret ;4

  setcursor:
    pushad
    ;*** set cursor
    push 0eh
    push 3d4h
    call out_byte

    add ebx,80*ROWNUM ; TODO
    shl ebx, 1

    mov eax,ebx
    shr ebx, 9
    and ebx, 0ffh
    push ebx ;(((ebx/2)>>8)&0ffh)
    push 3d5h
    call out_byte

    push 0fh
    push 3d4h
    call out_byte

    shr eax, 1
    and eax, 0ffh
    push eax;((20/2)&0ffh)
    push 3d5h
    call out_byte
    popad
    ;***
    ret
    

  io_delay:
    nop
    nop
    nop
    nop
    ret

  ;*** Init8259A ------------------------------------
  Init8259A:
    mov al, 011h
    out 020h, al  ; 主8259, ICW1.
    call  io_delay
    out 0A0h, al  ; 从8259, ICW1.
    call  io_delay
    mov al, 020h  ; IRQ0 对应中断向量 0x20
    out 021h, al  ; 主8259, ICW2.
    call  io_delay
    mov al, 028h  ; IRQ8 对应中断向量 0x28
    out 0A1h, al  ; 从8259, ICW2.
    call  io_delay
    mov al, 004h  ; IR2 对应从8259
    out 021h, al  ; 主8259, ICW3.
    call  io_delay
    mov al, 002h  ; 对应主8259的 IR2
    out 0A1h, al  ; 从8259, ICW3.
    call  io_delay
    mov al, 001h
    out 021h, al  ; 主8259, ICW4.
    call  io_delay
    out 0A1h, al  ; 从8259, ICW4.
    call  io_delay
    ;mov  al, 11111111b ; 屏蔽主8259所有中断
    ;mov al, 11111110b ; 仅仅开启定时器中断
    mov al, 11111100b ;keyboard and timer
    out 021h, al  ; 主8259, OCW1.
    call  io_delay
    mov al, 11111111b ; 屏蔽从8259所有中断
    out 0A1h, al  ; 从8259, OCW1.
    call  io_delay
    ret

  ;*** push value(8), port(4); call out_byte
  out_byte:
    mov ebp,esp
    pushad
    mov dx, word [ebp + 4]    ; port
    mov al, byte [ebp + 8] ; value
    out dx, al
    call io_delay
    popad
    ret 8

  in_byte:
    mov ebp,esp
    pushad
    mov edx, [ebp + 4]    ; port
    xor eax, eax
    in  al, dx
    call io_delay
    popad
    ret 4

  ;*** push 20msg, 16msg_len, 12row, 8column; call printline
  _r0printline:
  r0printline equ _r0printline-$$
    push  ebp
    mov ebp, esp
    push  esi
    push  edi
    pushad
  
    mov ecx, [ebp+16];len
    mov esi,0
  .1:
    ;mov eax, edi;disregard parameter row 
    mov eax, [ebp+12];row=3
    mov edx, 80
    mul edx ; mul will affect EDX!!!
    add eax, [ebp+8];column
    shl eax, 1
    mov edi, eax
    mov edx, [ebp+20]
    mov ebx,esi
    mov al, byte [ds:(edx+ebx)]
    mov ah, 0Dh
    mov [fs:edi], ax
    inc esi
    inc dword [ebp+8]
    LOOP .1

    popad
    pop edi
    pop esi
    pop ebp
    ret 16

  ;*** push 20014a7fh, addr; call num2str
  _r0num2str:
  r0num2str equ _r0num2str-$$
    push  ebp
    mov ebp, esp
    push  esi
    push  edi
    pushad

    mov edi, dword [ebp+8];address
    add edi, 8
    mov eax, dword [ebp+12];num
    mov ebx, eax
    mov ecx, 8
  .1:
    mov ebx, eax
    and ebx,0000000fh
    cmp bl, 9
    ja .2
    add bl, 48
    jmp .3
  .2:
    add bl, 55; lower 97
  .3:
    dec edi
    mov byte [edi], bl 
    shr eax, 4
    loop .1

    popad
    pop edi
    pop esi
    pop ebp
    ret 8

  ;***** System Call ******
  ;************************
  _JiffiesHandler:
  JiffiesHandler equ _JiffiesHandler - $$
    push  ds 
    mov dx,sel_pmr0data
    mov ds,dx
    mov eax, dword[r0addr(jiffies)]
    pop ds
    iretd

  _GetPidHandler:
  GetPidHandler equ _GetPidHandler - $$
    mov eax, 0
    iretd
  
pmr0code_len equ $-start_pmr0code
