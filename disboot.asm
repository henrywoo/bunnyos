00007C00  EB3C              jmp short 0x7c3e
00007C02  90                nop
00007C03  57                push di
00007C04  7546              jnz 0x7c4c
00007C06  7568              jnz 0x7c70
00007C08  656E              gs outsb
00007C0A  670002            add [edx],al
00007C0D  0101              add [bx+di],ax
00007C0F  0002              add [bp+si],al
00007C11  E000              loopne 0x7c13
00007C13  40                inc ax
00007C14  0BF0              or si,ax
00007C16  0900              or [bx+si],ax
00007C18  1200              adc al,[bx+si]
00007C1A  0200              add al,[bx+si]
00007C1C  0000              add [bx+si],al
00007C1E  0000              add [bx+si],al
00007C20  0000              add [bx+si],al
00007C22  0000              add [bx+si],al
00007C24  0000              add [bx+si],al
00007C26  2900              sub [bx+si],ax
00007C28  0000              add [bx+si],al
00007C2A  004275            add [bp+si+0x75],al
00007C2D  6E                outsb
00007C2E  6E                outsb
00007C2F  794F              jns 0x7c80
00007C31  53                push bx
00007C32  5F                pop di
00007C33  312E3046          xor [0x4630],bp
00007C37  41                inc cx
00007C38  54                push sp
00007C39  3132              xor [bp+si],si
00007C3B  2020              and [bx+si],ah
00007C3D  208CC88E          and [si+0x8ec8],cl
00007C41  D88EC08E          fmul dword [bp+0x8ec0]
00007C45  D0BC007C          sar byte [si+0x7c00],1
00007C49  B407              mov ah,0x7
00007C4B  B000              mov al,0x0
00007C4D  B700              mov bh,0x0
00007C4F  B90000            mov cx,0x0
00007C52  BA4F18            mov dx,0x184f
00007C55  CD10              int 0x10
00007C57  31C0              xor ax,ax
00007C59  CD13              int 0x13
00007C5B  C706147D1300      mov word [0x7d14],0x13
00007C61  813E127D0000      cmp word [0x7d12],0x0
00007C67  7450              jz 0x7cb9
00007C69  FF0E127D          dec word [0x7d12]
00007C6D  B80030            mov ax,0x3000
00007C70  8EC0              mov es,ax
00007C72  BB0000            mov bx,0x0
00007C75  A1147D            mov ax,[0x7d14]
00007C78  B101              mov cl,0x1
00007C7A  E8DD00            call 0x7d5a
00007C7D  BE177D            mov si,0x7d17
00007C80  BF0000            mov di,0x0
00007C83  FC                cld
00007C84  BA1000            mov dx,0x10
00007C87  81FA0000          cmp dx,0x0
00007C8B  7424              jz 0x7cb1
00007C8D  4A                dec dx
00007C8E  B90B00            mov cx,0xb
00007C91  81F90000          cmp cx,0x0
00007C95  7429              jz 0x7cc0
00007C97  49                dec cx
00007C98  AC                lodsb
00007C99  263A05            cmp al,[es:di]
00007C9C  7403              jz 0x7ca1
00007C9E  E90300            jmp 0x7ca4
00007CA1  47                inc di
00007CA2  EBED              jmp short 0x7c91
00007CA4  81E7E0FF          and di,0xffe0
00007CA8  81C72000          add di,0x20
00007CAC  BE177D            mov si,0x7d17
00007CAF  EBD6              jmp short 0x7c87
00007CB1  8106147D0100      add word [0x7d14],0x1
00007CB7  EBA8              jmp short 0x7c61
00007CB9  B602              mov dh,0x2
00007CBB  E88000            call 0x7d3e
00007CBE  EBFE              jmp short 0x7cbe
00007CC0  B80E00            mov ax,0xe
00007CC3  81E7E0FF          and di,0xffe0
00007CC7  81C71A00          add di,0x1a
00007CCB  268B0D            mov cx,[es:di]
00007CCE  51                push cx
00007CCF  01C1              add cx,ax
00007CD1  81C11100          add cx,0x11
00007CD5  B80030            mov ax,0x3000
00007CD8  8EC0              mov es,ax
00007CDA  BB0000            mov bx,0x0
00007CDD  89C8              mov ax,cx
00007CDF  50                push ax
00007CE0  53                push bx
00007CE1  B40E              mov ah,0xe
00007CE3  B02E              mov al,0x2e
00007CE5  B30F              mov bl,0xf
00007CE7  CD10              int 0x10
00007CE9  5B                pop bx
00007CEA  58                pop ax
00007CEB  B101              mov cl,0x1
00007CED  E86A00            call 0x7d5a
00007CF0  58                pop ax
00007CF1  E89E00            call 0x7d92
00007CF4  3DFF0F            cmp ax,0xfff
00007CF7  740F              jz 0x7d08
00007CF9  50                push ax
00007CFA  BA0E00            mov dx,0xe
00007CFD  01D0              add ax,dx
00007CFF  051100            add ax,0x11
00007D02  031E0B7C          add bx,[0x7c0b]
00007D06  EBD7              jmp short 0x7cdf
00007D08  B601              mov dh,0x1
00007D0A  E83100            call 0x7d3e
00007D0D  EA00000030        jmp 0x3000:0x0
00007D12  0E                push cs
00007D13  0000              add [bx+si],al
00007D15  0000              add [bx+si],al
00007D17  4B                dec bx
00007D18  45                inc bp
00007D19  52                push dx
00007D1A  4E                dec si
00007D1B  45                inc bp
00007D1C  4C                dec sp
00007D1D  2020              and [bx+si],ah
00007D1F  42                inc dx
00007D20  55                push bp
00007D21  4E                dec si
00007D22  00426F            add [bp+si+0x6f],al
00007D25  6F                outsw
00007D26  7469              jz 0x7d91
00007D28  6E                outsb
00007D29  672020            and [eax],ah
00007D2C  52                push dx
00007D2D  45                inc bp
00007D2E  41                inc cx
00007D2F  44                inc sp
00007D30  59                pop cx
00007D31  47                inc di
00007D32  6F                outsw
00007D33  6F                outsw
00007D34  644E              fs dec si
00007D36  6F                outsw
00007D37  204B45            and [bp+di+0x45],cl
00007D3A  52                push dx
00007D3B  4E                dec si
00007D3C  45                inc bp
00007D3D  4C                dec sp
00007D3E  B80900            mov ax,0x9
00007D41  F6E6              mul dh
00007D43  05237D            add ax,0x7d23
00007D46  89C5              mov bp,ax
00007D48  8CD8              mov ax,ds
00007D4A  8EC0              mov es,ax
00007D4C  B90900            mov cx,0x9
00007D4F  B80113            mov ax,0x1301
00007D52  BB0700            mov bx,0x7
00007D55  B200              mov dl,0x0
00007D57  CD10              int 0x10
00007D59  C3                ret
00007D5A  55                push bp
00007D5B  89E5              mov bp,sp
00007D5D  6681EC02000000    sub esp,0x2
00007D64  884EFE            mov [bp-0x2],cl
00007D67  53                push bx
00007D68  8A1E187C          mov bl,[0x7c18]
00007D6C  F6F3              div bl
00007D6E  FEC4              inc ah
00007D70  88E1              mov cl,ah
00007D72  88C6              mov dh,al
00007D74  D0E8              shr al,1
00007D76  88C5              mov ch,al
00007D78  80E601            and dh,0x1
00007D7B  5B                pop bx
00007D7C  8A16247C          mov dl,[0x7c24]
00007D80  B402              mov ah,0x2
00007D82  8A46FE            mov al,[bp-0x2]
00007D85  CD13              int 0x13
00007D87  72F7              jc 0x7d80
00007D89  6681C402000000    add esp,0x2
00007D90  5D                pop bp
00007D91  C3                ret
00007D92  06                push es
00007D93  53                push bx
00007D94  50                push ax
00007D95  B80030            mov ax,0x3000
00007D98  2D0001            sub ax,0x100
00007D9B  8EC0              mov es,ax
00007D9D  58                pop ax
00007D9E  C606167D00        mov byte [0x7d16],0x0
00007DA3  BB0300            mov bx,0x3
00007DA6  F7E3              mul bx
00007DA8  BB0200            mov bx,0x2
00007DAB  F7F3              div bx
00007DAD  81FA0000          cmp dx,0x0
00007DB1  7405              jz 0x7db8
00007DB3  C606167D01        mov byte [0x7d16],0x1
00007DB8  31D2              xor dx,dx
00007DBA  8B1E0B7C          mov bx,[0x7c0b]
00007DBE  F7F3              div bx
00007DC0  52                push dx
00007DC1  BB0000            mov bx,0x0
00007DC4  050100            add ax,0x1
00007DC7  B102              mov cl,0x2
00007DC9  E88EFF            call 0x7d5a
00007DCC  5A                pop dx
00007DCD  01D3              add bx,dx
00007DCF  268B07            mov ax,[es:bx]
00007DD2  803E167D01        cmp byte [0x7d16],0x1
00007DD7  7503              jnz 0x7ddc
00007DD9  C1E804            shr ax,0x4
00007DDC  25FF0F            and ax,0xfff
00007DDF  5B                pop bx
00007DE0  07                pop es
00007DE1  C3                ret
00007DE2  0000              add [bx+si],al
00007DE4  0000              add [bx+si],al
00007DE6  0000              add [bx+si],al
00007DE8  0000              add [bx+si],al
00007DEA  0000              add [bx+si],al
00007DEC  0000              add [bx+si],al
00007DEE  0000              add [bx+si],al
00007DF0  0000              add [bx+si],al
00007DF2  0000              add [bx+si],al
00007DF4  0000              add [bx+si],al
00007DF6  0000              add [bx+si],al
00007DF8  0000              add [bx+si],al
00007DFA  0000              add [bx+si],al
00007DFC  0000              add [bx+si],al
00007DFE  55                push bp
00007DFF  AA                stosb
