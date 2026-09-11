        PAGE  60,132
        TITLE KEYSCR -- THE DEFINE-KEYS SCREEN
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC SCRKEYS
        EXTRN  CLRTXT:NEAR
        EXTRN  KEYPOLL:NEAR
        EXTRN  KEY_DN:WORD
        EXTRN  KEY_JLF:WORD
        EXTRN  KEY_JRT:WORD
        EXTRN  KEY_JUP:WORD
        EXTRN  KEY_LF:WORD
        EXTRN  KEY_RT:WORD
        EXTRN  KEY_UP:WORD
        EXTRN  PUTSTR:NEAR
        EXTRN  SCRMENU:NEAR

;=======================================================================
; KEYSCR.ASM -- THE DEFINE-KEYS SCREEN
;
; The text of the define-keys screen and its own output code: waiting
; on a key, printing a character, and the assignment line.
;=======================================================================

;-----------------------------------------------------------------------
; TEXT OF THE DEFINE-KEYS SCREEN
;
; Same rules as STRTAB: run together, no terminators, length in CX.
; The code at 7DFDh reads it: the title comes from 7DB0h, 20h long,
; then the button captions UP, DOWN, RIGHT, LEFT, JUMP UP, JUMP RIGHT,
; JUMP LEFT, DONE.
;-----------------------------------------------------------------------
DEFTTL  DB    'Define Keys for Keyboard Control' ; 7DB0
DEFUP   DB    'UP'                               ; 7DD0
DEFDN   DB    'DOWN'                             ; 7DD2
DEFRT   DB    'RIGHT'                            ; 7DD6
DEFLF   DB    'LEFT'                             ; 7DDB
DEFJUP  DB    'JUMP UP'                          ; 7DDF
DEFJRT  DB    'JUMP RIGHT'                       ; 7DE6
DEFJLF  DB    'JUMP LEFT'                        ; 7DF0
DEFDONE DB    'DONE'                             ; 7DF9  never put out

SCRKEYS:
        call    CLRTXT                   ; 7DFD  wipe the text off the screen
        mov     si, OFFSET DEFTTL        ; 7E00  SI -- title of the screen
        mov     cx, 20h                  ; 7E03  20h = 32 characters
        mov     dh, 1                    ; 7E06  row 1
        mov     dl, 2                    ; 7E08  column 2
        mov     bl, 3                    ; 7E0A  color 3
        call    PUTSTR                   ; 7E0C  title is on the screen
        add     dh, 4                    ; 7E0F  four rows down
        mov     si, OFFSET DEFUP         ; 7E12  SI -- caption of the "up" action
        mov     cx, 2                    ; 7E15  2 characters
        mov     ax, KEY_UP               ; 7E18  key now assigned to the action
        call    KEYLINE                  ; 7E1B  put out the line and wait for a key
        mov     KEY_UP, ax               ; 7E1E  new key for the "up" action
        call    PUTCHR                   ; 7E21  show it on the screen
        mov     si, OFFSET DEFDN         ; 7E24  SI -- caption of the "down" action
        mov     cx, 4                    ; 7E27  4 characters
        mov     ax, KEY_DN               ; 7E2A  key now assigned to the action
        call    KEYLINE                  ; 7E2D  put out the line and wait for a key
        mov     KEY_DN, ax               ; 7E30  new key for the "down" action
        call    PUTCHR                   ; 7E33  show it on the screen
        mov     si, OFFSET DEFRT         ; 7E36  SI -- caption of the "right" action
        mov     cx, 5                    ; 7E39  5 characters
        mov     ax, KEY_RT               ; 7E3C  key now assigned to the action
        call    KEYLINE                  ; 7E3F  put out the line and wait for a key
        mov     KEY_RT, ax               ; 7E42  new key for the "right" action
        call    PUTCHR                   ; 7E45  show it on the screen
        mov     si, OFFSET DEFLF         ; 7E48  SI -- caption of the "left" action
        mov     cx, 4                    ; 7E4B  4 characters
        mov     ax, KEY_LF               ; 7E4E  key now assigned to the action
        call    KEYLINE                  ; 7E51  put out the line and wait for a key
        mov     KEY_LF, ax               ; 7E54  new key for the "left" action
        call    PUTCHR                   ; 7E57  show it on the screen
        mov     si, OFFSET DEFJUP        ; 7E5A  SI -- caption of the jump-up action
        mov     cx, 7                    ; 7E5D  7 characters
        mov     ax, KEY_JUP              ; 7E60  key now assigned to the action
        call    KEYLINE                  ; 7E63  put out the line and wait for a key
        mov     KEY_JUP, ax              ; 7E66  new key for jump up
        call    PUTCHR                   ; 7E69  show it on the screen
        mov     si, OFFSET DEFJRT        ; 7E6C  SI -- caption of the jump-right action
        mov     cx, 0Ah                  ; 7E6F  0Ah = 10 characters
        mov     ax, KEY_JRT              ; 7E72  key now assigned to the action
        call    KEYLINE                  ; 7E75  put out the line and wait for a key
        mov     KEY_JRT, ax              ; 7E78  new key for jump right
        call    PUTCHR                   ; 7E7B  show it on the screen
        mov     si, OFFSET DEFJLF        ; 7E7E  SI -- caption of the jump-left action
        mov     cx, 9                    ; 7E81  9 characters
        mov     ax, KEY_JLF              ; 7E84  key now assigned to the action
        call    KEYLINE                  ; 7E87  put out the line and wait for a key
        mov     KEY_JLF, ax              ; 7E8A  new key for jump left
        call    PUTCHR                   ; 7E8D  show it on the screen
        call    CLRTXT                   ; 7E90  wipe the text off the screen
        call    SCRMENU                  ; 7E93  bring the menu back
        ret                              ; 7E96  return: the keys have been redefined

;-----------------------------------------------------------------------
; GOKEYS -- Head off to the define-keys screen. Nothing refers to it.
;
; EXIT   : control does not come back
; ALTERS : AX, BX, CX, DX, SI, ES
;-----------------------------------------------------------------------
GOKEYS:
        jmp     SCRKEYS                  ; 7E97  off to the define-keys screen

;-----------------------------------------------------------------------
; CURS30 -- Park the cursor in column 1Eh of the current row DH.
;
; ENTRY  : DH
; ALTERS : BX, DX
; CALLED BY: KEYLINE
;-----------------------------------------------------------------------
CURS30:
        mov     dl, 1Eh                  ; 7E9A  column 1Eh = 30
        mov     bh, 0                    ; 7E9C  page 0
        mov     ah, 2                    ; 7E9E  AH=2: the "set cursor position" call
        int     10h                      ; 7EA0  video BIOS
        ret                              ; 7EA2  return: the cursor is parked

;-----------------------------------------------------------------------
; WAITKEY -- Wait on a key. On F5 (scan code 3Fh) it clears the screen,
; draws the menu and drops two return addresses -- leaving a nested
; screen goes straight back to the menu.
;
; EXIT   : AX
; ALTERS : BX, CX, DX, ES
; CALLED BY: KEYLINE
;-----------------------------------------------------------------------
WAITKEY:
        call    KEYPOLL                  ; 7EA3  poll the input device
        jae     WAITKEY                  ; 7EA6  CF=0 -- nothing pressed
        cmp     al, 0                    ; 7EA8  AL=0 -- an extended code
        jne     LWAITK1                  ; 7EAA  an ordinary character -- hand it back
        cmp     ah, HIGH KEY_F5          ; 7EAC  3Fh -- high byte of the F5 code
        jne     LWAITK1                  ; 7EAF  not F5 -- hand the key back
        call    CLRTXT                   ; 7EB1  wipe the text off the screen
        call    SCRMENU                  ; 7EB4  bring the menu back
        pop     si                       ; 7EB7  return address 1 of two
        pop     si                       ; 7EB8  two levels of return pulled off the stack
LWAITK1:
        ret                              ; 7EB9  return: the key is in AX

;-----------------------------------------------------------------------
; PUTCHR -- Put out one character. If AL = 0 the character is taken
; from AH and trimmed down to 3Fh.
;
; ENTRY  : AX
; ALTERS : AX, CX
; CALLED BY: KEYLINE, SCRKEYS
;-----------------------------------------------------------------------
PUTCHR:
        cmp     al, 0                    ; 7EBA  AL=0 -- an extended code
        jne     LPUTCH1                  ; 7EBC  an ordinary character -- put it out as it stands
        and     ah, 3Fh                  ; 7EBE  low six bits of the scan code
        mov     al, ah                   ; 7EC1  AL -- the character to put out
LPUTCH1:
        mov     ah, 0Eh                  ; 7EC3  AH=0Eh: the "write character" call
        mov     cx, 1                    ; 7EC5  call 0Eh never looks at CX
        int     10h                      ; 7EC8  video BIOS
        ret                              ; 7ECA  return: the character is out

;-----------------------------------------------------------------------
; KEYLINE -- One line of the define-keys menu: the action caption, then
; the key now assigned. Drops two rows once it is done.
;
; EXIT   : DH
; ALTERS : BX, CX, SI, ES
; CALLED BY: SCRKEYS
;-----------------------------------------------------------------------
KEYLINE:
        push    ax                       ; 7ECB  AX comes back at 7ED6
        mov     bl, 3                    ; 7ECC  color 3
        mov     dl, 2                    ; 7ECE  column 2
        call    PUTSTR                   ; 7ED0  action caption is on the screen
        call    CURS30                   ; 7ED3  cursor to column 30
        pop     ax                       ; 7ED6  AX -- key now assigned to the action
        call    PUTCHR                   ; 7ED7  show it on the screen
        call    CURS30                   ; 7EDA  cursor to column 30
        call    WAITKEY                  ; 7EDD  wait for the new key
        add     dh, 2                    ; 7EE0  two rows down
        ret                              ; 7EE3  return: key in AX, row in DH

CSEG    ENDS
        END
