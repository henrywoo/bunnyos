%ifndef KB_ASM_
%define KB_ASM_

%define KB_IN_BYTES 32  ; size of keyboard input buffer 
%define MAP_COLS  3 ; Number of columns in keymap 
%define NR_SCAN_CODES 0x80  ; Number of scan codes (rows in keymap) 

%define FLAG_BREAK  0x0080    ; Break Code     
%define FLAG_EXT  0x0100    ; Normal function keys   
%define FLAG_SHIFT_L  0x0200    ; Shift key      
%define FLAG_SHIFT_R  0x0400    ; Shift key      
%define FLAG_CTRL_L 0x0800    ; Control key      
%define FLAG_CTRL_R 0x1000    ; Control key      
%define FLAG_ALT_L  0x2000    ; Alternate key    
%define FLAG_ALT_R  0x4000    ; Alternate key    
%define FLAG_PAD  0x8000    ; keys in num pad    

;raw key value = code passed to tty & MASK_RAW the value can 
;be found either in the keymap column 0 or in the list below 
%define MASK_RAW  0x01FF

; Special keys 
%define ESC   (0x01 + FLAG_EXT) ; Esc    
%define TAB   (0x02 + FLAG_EXT) ; Tab    
%define ENTER   (0x03 + FLAG_EXT) ; Enter  
%define BACKSPACE (0x04 + FLAG_EXT) ; BackSpace  

%define GUI_L   (0x05 + FLAG_EXT) ; L GUI  
%define GUI_R   (0x06 + FLAG_EXT) ; R GUI  
%define APPS    (0x07 + FLAG_EXT) ; APPS 

; Shift, Ctrl, Alt 
%define SHIFT_L   (0x08 + FLAG_EXT) ; L Shift  
%define SHIFT_R   (0x09 + FLAG_EXT) ; R Shift  
%define CTRL_L    (0x0A + FLAG_EXT) ; L Ctrl 
%define CTRL_R    (0x0B + FLAG_EXT) ; R Ctrl 
%define ALT_L   (0x0C + FLAG_EXT) ; L Alt  
%define ALT_R   (0x0D + FLAG_EXT) ; R Alt  

; Lock keys 
%define CAPS_LOCK (0x0E + FLAG_EXT) ; Caps Lock  
%define NUM_LOCK  (0x0F + FLAG_EXT) ; Number Lock  
%define SCROLL_LOCK (0x10 + FLAG_EXT) ; Scroll Lock  

; Function keys 
%define F1    (0x11 + FLAG_EXT) ; F1   
%define F2    (0x12 + FLAG_EXT) ; F2   
%define F3    (0x13 + FLAG_EXT) ; F3   
%define F4    (0x14 + FLAG_EXT) ; F4   
%define F5    (0x15 + FLAG_EXT) ; F5   
%define F6    (0x16 + FLAG_EXT) ; F6   
%define F7    (0x17 + FLAG_EXT) ; F7   
%define F8    (0x18 + FLAG_EXT) ; F8   
%define F9    (0x19 + FLAG_EXT) ; F9   
%define F10   (0x1A + FLAG_EXT) ; F10    
%define F11   (0x1B + FLAG_EXT) ; F11    
%define F12   (0x1C + FLAG_EXT) ; F12    

; Control Pad 
%define PRINTSCREEN (0x1D + FLAG_EXT) ; Print Screen 
%define PAUSEBREAK  (0x1E + FLAG_EXT) ; Pause/Break  
%define INSERT    (0x1F + FLAG_EXT) ; Insert 
%define DELETE    (0x20 + FLAG_EXT) ; Delete 
%define HOME    (0x21 + FLAG_EXT) ; Home   
%define END   (0x22 + FLAG_EXT) ; End    
%define PAGEUP    (0x23 + FLAG_EXT) ; Page Up  
%define PAGEDOWN  (0x24 + FLAG_EXT) ; Page Down  
%define UP    (0x25 + FLAG_EXT) ; Up   
%define DOWN    (0x26 + FLAG_EXT) ; Down   
%define LEFT    (0x27 + FLAG_EXT) ; Left   
%define RIGHT   (0x28 + FLAG_EXT) ; Right  

; ACPI keys 
%define POWER   (0x29 + FLAG_EXT) ; Power  
%define SLEEP   (0x2A + FLAG_EXT) ; Sleep  
%define WAKE    (0x2B + FLAG_EXT) ; Wake Up  

; Num Pad 
%define PAD_SLASH (0x2C + FLAG_EXT) ; /    
%define PAD_STAR  (0x2D + FLAG_EXT) ; *    
%define PAD_MINUS (0x2E + FLAG_EXT) ; -    
%define PAD_PLUS  (0x2F + FLAG_EXT) ; +    
%define PAD_ENTER (0x30 + FLAG_EXT) ; Enter  
%define PAD_DOT   (0x31 + FLAG_EXT) ; .    
%define PAD_0   (0x32 + FLAG_EXT) ; 0    
%define PAD_1   (0x33 + FLAG_EXT) ; 1    
%define PAD_2   (0x34 + FLAG_EXT) ; 2    
%define PAD_3   (0x35 + FLAG_EXT) ; 3    
%define PAD_4   (0x36 + FLAG_EXT) ; 4    
%define PAD_5   (0x37 + FLAG_EXT) ; 5    
%define PAD_6   (0x38 + FLAG_EXT) ; 6    
%define PAD_7   (0x39 + FLAG_EXT) ; 7    
%define PAD_8   (0x3A + FLAG_EXT) ; 8    
%define PAD_9   (0x3B + FLAG_EXT) ; 9    
%define PAD_UP    PAD_8     ; Up   
%define PAD_DOWN  PAD_2     ; Down   
%define PAD_LEFT  PAD_4     ; Left   
%define PAD_RIGHT PAD_6     ; Right  
%define PAD_HOME  PAD_7     ; Home   
%define PAD_END   PAD_1     ; End    
%define PAD_PAGEUP  PAD_9     ; Page Up  
%define PAD_PAGEDOWN  PAD_3     ; Page Down  
%define PAD_INS   PAD_0     ; Ins    
%define PAD_MID   PAD_5     ; Middle key 
%define PAD_DEL   PAD_DOT     ; Del    



keymapdata:
  ; 0x00 - none    
  db 0,    0,    0
  ; 0x01 - ESC   
  db ESC,    ESC,    0
  ; 0x02 - '1'   
  db '1',    '!',    0
  ; 0x03 - '2'   
  db '2',    '@',    0
  ; 0x04 - '3'   
  db '3',    '#',    0
  ; 0x05 - '4'   
  db '4',    '$',    0
  ; 0x06 - '5'   
  db '5',    '%',    0
  ; 0x07 - '6'   
  db '6',    '^',    0
  ; 0x08 - '7'   
  db '7',    '&',    0
  ; 0x09 - '8'   
  db '8',    '*',    0
  ; 0x0A - '9'   
  db '9',    '(',    0
  ; 0x0B - '0'   
  db '0',    ')',    0
  ; 0x0C - '-'   
  db '-',    '_',    0
  ; 0x0D - '='   
  db '=',    '+',    0
  ; 0x0E - BS    
  db BACKSPACE,  BACKSPACE,  0
  ; 0x0F - TAB   
  db TAB,    TAB,    0
  ; 0x10 - 'q'   
  db 'q',    'Q',    0
  ; 0x11 - 'w'   
  db 'w',    'W',    0
  ; 0x12 - 'e'   
  db 'e',    'E',    0
  ; 0x13 - 'r'   
  db 'r',    'R',    0
  ; 0x14 - 't'   
  db 't',    'T',    0
  ; 0x15 - 'y'   
  db 'y',    'Y',    0
  ; 0x16 - 'u'   
  db 'u',    'U',    0
  ; 0x17 - 'i'   
  db 'i',    'I',    0
  ; 0x18 - 'o'   
  db 'o',    'O',    0
  ; 0x19 - 'p'   
  db 'p',    'P',    0
  ; 0x1A - '['   
  db '[',    '{',    0
  ; 0x1B - ']'   
  db ']',    '}',    0
  ; 0x1C - CR/LF   
  db ENTER,    ENTER,    PAD_ENTER,
  ; 0x1D - l. Ctrl 
  db CTRL_L,   CTRL_L,   CTRL_R,
  ; 0x1E - 'a'   
  db 'a',    'A',    0
  ; 0x1F - 's'   
  db 's',    'S',    0
  ; 0x20 - 'd'   
  db 'd',    'D',    0
  ; 0x21 - 'f'   
  db 'f',    'F',    0
  ; 0x22 - 'g'   
  db 'g',    'G',    0
  ; 0x23 - 'h'   
  db 'h',    'H',    0
  ; 0x24 - 'j'   
  db 'j',    'J',    0
  ; 0x25 - 'k'   
  db 'k',    'K',    0
  ; 0x26 - 'l'   
  db 'l',    'L',    0
  ; 0x27 - ';'   
  db ';',    ':',    0
  ; 0x28 - '\''    
  db "\'",   '\"',    0
  ; 0x29 - '`'   
  db '`',    '~',    0
  ; 0x2A - l. SHIFT  
  db SHIFT_L,  SHIFT_L,  0
  ; 0x2B - '\'   
  db '\\',   '|',    0
  ; 0x2C - 'z'   
  db 'z',    'Z',    0
  ; 0x2D - 'x'   
  db 'x',    'X',    0
  ; 0x2E - 'c'   
  db 'c',    'C',    0
  ; 0x2F - 'v'   
  db 'v',    'V',    0
  ; 0x30 - 'b'   
  db 'b',    'B',    0
  ; 0x31 - 'n'   
  db 'n',    'N',    0
  ; 0x32 - 'm'   
  db 'm',    'M',    0
  ; 0x33 - ','   
  db ',',    '<',    0
  ; 0x34 - '.'   
  db '.',    '>',    0
  ; 0x35 - '/'   
  db '/',    '?',    PAD_SLASH,
  ; 0x36 - r. SHIFT  
  db SHIFT_R,  SHIFT_R,  0
  ; 0x37 - '*'   
  db '*',    '*',      0
  ; 0x38 - ALT   
  db ALT_L,    ALT_L,    ALT_R,
  ; 0x39 - ' '   
  db ' ',    ' ',    0
  ; 0x3A - CapsLock  
  db CAPS_LOCK,  CAPS_LOCK,  0
  ; 0x3B - F1    
  db F1,   F1,   0
  ; 0x3C - F2    
  db F2,   F2,   0
  ; 0x3D - F3    
  db F3,   F3,   0
  ; 0x3E - F4    
  db F4,   F4,   0
  ; 0x3F - F5    
  db F5,   F5,   0
  ; 0x40 - F6    
  db F6,   F6,   0
  ; 0x41 - F7    
  db F7,   F7,   0
  ; 0x42 - F8    
  db F8,   F8,   0
  ; 0x43 - F9    
  db F9,   F9,   0
  ; 0x44 - F10   
  db F10,    F10,    0
  ; 0x45 - NumLock 
  db NUM_LOCK, NUM_LOCK, 0
  ; 0x46 - ScrLock 
  db SCROLL_LOCK,  SCROLL_LOCK,  0
  ; 0x47 - Home    
  db PAD_HOME, '7',    HOME,
  ; 0x48 - CurUp   
  db PAD_UP,   '8',    UP,
  ; 0x49 - PgUp    
  db PAD_PAGEUP, '9',    PAGEUP,
  ; 0x4A - '-'   
  db PAD_MINUS,  '-',    0
  ; 0x4B - Left    
  db PAD_LEFT, '4',    LEFT,
  ; 0x4C - MID   
  db PAD_MID,  '5',    0
  ; 0x4D - Right   
  db PAD_RIGHT,  '6',    RIGHT,
  ; 0x4E - '+'   
  db PAD_PLUS, '+',    0
  ; 0x4F - End   
  db PAD_END,  '1',    END,
  ; 0x50 - Down    
  db PAD_DOWN, '2',    DOWN,
  ; 0x51 - PgDown  
  db PAD_PAGEDOWN, '3',    PAGEDOWN,
  ; 0x52 - Insert  
  db PAD_INS,  '0',    INSERT,
  ; 0x53 - Delete  
  db PAD_DOT,  '.',    DELETE,
  ; 0x54 - Enter   
  db 0,    0,    0
  ; 0x55 - ???   
  db 0,    0,    0
  ; 0x56 - ???   
  db 0,    0,    0
  ; 0x57 - F11   
  db F11,    F11,    0
  ; 0x58 - F12   
  db F12,    F12,    0
  ; 0x59 - ???   
  db 0,    0,    0
  ; 0x5A - ???   
  db 0,    0,    0
  ; 0x5B - ???   
  db 0,    0,    GUI_L,
  ; 0x5C - ???   
  db 0,    0,    GUI_R,
  ; 0x5D - ???   
  db 0,    0,    APPS,
  ; 0x5E - ???   
  db 0,    0,    0
  ; 0x5F - ???   
  db 0,    0,    0
  ; 0x60 - ???   
  db 0,    0,    0
  ; 0x61 - ???   
  db 0,    0,    0
  ; 0x62 - ???   
  db 0,    0,    0
  ; 0x63 - ???   
  db 0,    0,    0
  ; 0x64 - ???   
  db 0,    0,    0
  ; 0x65 - ???   
  db 0,    0,    0
  ; 0x66 - ???   
  db 0,    0,    0
  ; 0x67 - ???   
  db 0,    0,    0
  ; 0x68 - ???   
  db 0,    0,    0
  ; 0x69 - ???   
  db 0,    0,    0
  ; 0x6A - ???   
  db 0,    0,    0
  ; 0x6B - ???   
  db 0,    0,    0
  ; 0x6C - ???   
  db 0,    0,    0
  ; 0x6D - ???   
  db 0,    0,    0
  ; 0x6E - ???   
  db 0,    0,    0
  ; 0x6F - ???   
  db 0,    0,    0
  ; 0x70 - ???   
  db 0,    0,    0
  ; 0x71 - ???   
  db 0,    0,    0
  ; 0x72 - ???   
  db 0,    0,    0
  ; 0x73 - ???   
  db 0,    0,    0
  ; 0x74 - ???   
  db 0,    0,    0
  ; 0x75 - ???   
  db 0,    0,    0
  ; 0x76 - ???   
  db 0,    0,    0
  ; 0x77 - ???   
  db 0,    0,    0
  ; 0x78 - ???   
  db 0,    0,    0
  ; 0x78 - ???   
  db 0,    0,    0
  ; 0x7A - ???   
  db 0,    0,    0
  ; 0x7B - ???   
  db 0,    0,    0
  ; 0x7C - ???   
  db 0,    0,    0
  ; 0x7D - ???   
  db 0,    0,    0
  ; 0x7E - ???   
  db 0,    0,    0
  ; 0x7F - ???   
  db 0,    0,    0

keymapdata_len equ $-keymapdata


%endif
