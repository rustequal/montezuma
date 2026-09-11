        PAGE  60,132
        TITLE TEXT -- STRINGS, MENU, SCREENS
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC CLRTXT
        PUBLIC INPDEV
        PUBLIC KEYPOLL
        PUBLIC MENUKEY
        PUBLIC PUTSTR
        PUBLIC SCRMENU
        PUBLIC SCRTTL
        EXTRN  GSTATE:BYTE
        EXTRN  SCRKEYS:NEAR
        EXTRN  LEVEL:BYTE
        EXTRN  NOP0:NEAR
        EXTRN  PAD03CD:WORD

;=======================================================================
; TEXT.ASM -- STRINGS, MENU, SCREENS
;
; INPDEV, the STRTAB interface strings and everything that puts them
; out: the title screen, the main menu, and the menu key handler.
;=======================================================================

;-----------------------------------------------------------------------
; INPDEV -- INPUT DEVICE NOW SELECTED  (7A30)
;
; 0 = keyboard, 1 = joystick. The F1 key in the menu flips it.
;-----------------------------------------------------------------------
INPDEV  DB    01h                        ; 7A30

;-----------------------------------------------------------------------
; STRTAB -- INTERFACE STRINGS
;
; The strings sit run together, with no zero terminators: PUTSTR gets
; the length in CX. Three strings in the table are never put out by
; anyone: TXTBLNK, TXTF4 and TXTF7.
;-----------------------------------------------------------------------
STRTAB  LABEL BYTE                                       ; 7A31
TXTBLNK DB    '                                        ' ; 7A31  never put out
TITLE1  DB    'Parker Brothers Presents'                 ; 7A59
TITLE2  DB    "MONTEZUMA'S REVENGE"                      ; 7A71
TITLE3  DB    'copyright 1984'                           ; 7A84
TXTMENU DB    'Main Menu'                                ; 7A92
TXTSTRT DB    'Press <return> to start'                  ; 7A9B
TXTNOTE DB    '* functions valid while game in progress' ; 7AB2
TXTF1   DB    '  F1  - Keyboard / Joystick'              ; 7ADA
TXTF2   DB    '  F2  - Game Level  1  2  3'              ; 7AF5
TXTF3   DB    '  F3  - Define Keys for Keyboard Control' ; 7B10
TXTF4   DB    'F4 - Pause'                               ; 7B38  never put out
TXTF5   DB    '* F5  - Return to Main Menu'              ; 7B42
TXTF10  DB    '* F10 - Pause'                            ; 7B5D
TXTF7   DB    'F7 - Reset Game'                          ; 7B6A  never put out
TITLE4  DB    'Press <return> for Menu Screen'           ; 7B79
DEVKEY  DB    'Keyboard'                                 ; 7B97
DEVJOY  DB    'Joystick'                                 ; 7B9F
LVL1    DB    '1'                                        ; 7BA7
LVL2    DB    '2'                                        ; 7BA8
LVL3    DB    '3'                                        ; 7BA9

;-----------------------------------------------------------------------
; MENUKEY -- Sort out the menu key just pressed: F1 -- input device,
; F2 -- game level, and so on.
;
; ENTRY  : AX
; ALTERS : AX, BX, CX, DX, SI, ES
; CALLED BY: ST_MENU
;-----------------------------------------------------------------------
MENUKEY:
        cmp     al, 0                    ; 7BAA  AL=0 -- an extended code
        jne     LMENUK3                  ; 7BAC  an ordinary character -- nothing to do
        cmp     ah, HIGH KEY_F1          ; 7BAE  F1 -- switch the input device
        jne     LMENUK1                  ; 7BB1  not F1
        jmp     LMENUK4                  ; 7BB3  F1 -- switch the input device
LMENUK1:
        cmp     ah, HIGH KEY_F2          ; 7BB6  F2 -- switch the game level
        jne     LMENUK2                  ; 7BB9  not F2
        jmp     LMENUK5                  ; 7BBB  F2 -- switch the game level
LMENUK2:
        cmp     ah, HIGH KEY_F3          ; 7BBE  F3 -- define keys
        jne     LMENUK3                  ; 7BC1  not F3
        jmp     SCRKEYS                  ; 7BC3  off to the define-keys screen
LMENUK3:
        ret                              ; 7BC6  return: the key was none of these
LMENUK4:
        xor     INPDEV, 1                ; 7BC7  keyboard <-> joystick
        call    MENUDEV                  ; 7BCC  redraw the F1 line
        clc                              ; 7BCF  CF=0 -- the key has been handled
        ret                              ; 7BD0  return
LMENUK5:
        inc     LEVEL                    ; 7BD1  level one step on
        and     LEVEL, 3                 ; 7BD5  the levels run around the ring 1, 2, 3
        cmp     LEVEL, 0                 ; 7BDA  did the level come out zero?
        jne     LMENUK6                  ; 7BDF  not zero
        mov     LEVEL, 1                 ; 7BE1  after the third comes the first again
LMENUK6:
        call    MENULVL                  ; 7BE6  redraw the F2 line
        clc                              ; 7BE9  CF=0 -- the key has been handled
        ret                              ; 7BEA  return

;-----------------------------------------------------------------------
; GOTTL -- Head off to the title screen. Nothing refers to it.
;
; EXIT   : GSTATE, CF
; ALTERS : nothing
;-----------------------------------------------------------------------
GOTTL:
        mov     GSTATE, 8                ; 7BEB  state 8 -- the main menu
        stc                              ; 7BF0  CF=1 -- the frame is done
        ret                              ; 7BF1  return

;-----------------------------------------------------------------------
; CLRTXT -- Clear the 40x25 character screen through the BIOS (INT 10h,
; AH=6, the whole window). The video mode is left alone.
;
; ALTERS : BX, CX, DX
; CALLED BY: MAINLP, SCRKEYS, ST_MENU, ST_X7, WAITKEY
;-----------------------------------------------------------------------
CLRTXT:
        mov     ah, 6                    ; 7BF2  AH=6: the "scroll window" call
        mov     al, 0                    ; 7BF4  AL=0: blank the whole window
        mov     cx, 0                    ; 7BF6  top left corner 0,0
        mov     dh, 19h                  ; 7BF9  bottom edge 19h = 25: one row past the last
        mov     dl, 28h                  ; 7BFB  right edge 28h = 40: one column past the last
        mov     bh, 0                    ; 7BFD  page 0
        int     10h                      ; 7BFF  video BIOS
        ret                              ; 7C01  return: the screen is clear

;-----------------------------------------------------------------------
; SCRTTL -- Title screen: Parker Brothers Presents / MONTEZUMAS REVENGE / copyright 1984.
;
; ALTERS : BX, CX, DX, SI
; CALLED BY: ST_TITLE
;-----------------------------------------------------------------------
SCRTTL:
        mov     bh, 0                    ; 7C02  page 0
        mov     si, OFFSET TITLE1        ; 7C04  SI -- the string "Parker Brothers Presents"
        mov     cx, 18h                  ; 7C07  18h = 24 characters
        mov     dh, 5                    ; 7C0A  row 5
        mov     dl, 8                    ; 7C0C  column 8
        mov     bl, 1                    ; 7C0E  color 1
        call    PUTSTR                   ; 7C10  the string is on the screen
        mov     si, OFFSET TITLE2        ; 7C13  SI -- the string "MONTEZUMAS REVENGE"
        mov     cx, 13h                  ; 7C16  13h = 19 characters
        mov     dh, 0Ah                  ; 7C19  row 0Ah = 10
        mov     dl, 0Ah                  ; 7C1B  column 0Ah = 10
        mov     bl, 2                    ; 7C1D  color 2
        call    PUTSTR                   ; 7C1F  the string is on the screen
        mov     si, OFFSET TITLE3        ; 7C22  SI -- the string "copyright 1984"
        mov     cx, 0Eh                  ; 7C25  0Eh = 14 characters
        mov     dh, 0Ch                  ; 7C28  row 0Ch = 12
        mov     dl, 0Ch                  ; 7C2A  column 0Ch = 12
        mov     bl, 3                    ; 7C2C  color 3
        call    PUTSTR                   ; 7C2E  the string is on the screen
        mov     si, OFFSET TITLE4        ; 7C31  SI -- the prompt string
        mov     cx, 1Eh                  ; 7C34  1Eh = 30 characters
        mov     dh, 17h                  ; 7C37  row 17h = 23
        mov     dl, 5                    ; 7C39  column 5
        mov     bl, 3                    ; 7C3B  color 3
        call    PUTSTR                   ; 7C3D  the string is on the screen
        mov     ax, PAD03CD              ; 7C40  AX -- a word read just as it stands
        and     ah, 8                    ; 7C43  bit 3 of the high byte
        je      LSCRTT1                  ; 7C46  clear
        call    NOP0                     ; 7C48  empty routine
LSCRTT1:
        ret                              ; 7C4B  return: the title screen is up

;-----------------------------------------------------------------------
; SCRMENU -- Main menu: heading, prompt and the list of F1, F2, F3,
; F5, F10. First thing it does is set 0040:0017 to 20h -- that turns
; NumLock on, without which the KEYTAB scan codes will not match.
;
; ALTERS : BX, CX, DX, SI
; CALLED BY: SCRKEYS, ST_MENU, WAITKEY
;-----------------------------------------------------------------------
SCRMENU:
        push    es                       ; 7C4C  ES comes back at 7C58
        mov     ax, 40h                  ; 7C4D  40h -- segment of the BIOS data area
        mov     es, ax                   ; 7C50  ES -- the BIOS data area
        mov     BYTE PTR es:[17h], 20h   ; 7C52  0040:0017 -- keyboard flags, bit 5 is NumLock
        pop     es                       ; 7C58  ES restored
        mov     si, OFFSET TITLE2        ; 7C59  SI -- the string "MONTEZUMAS REVENGE"
        mov     cx, 13h                  ; 7C5C  13h = 19 characters
        mov     dh, 2                    ; 7C5F  row 2
        mov     dl, 9                    ; 7C61  column 9
        mov     bl, 2                    ; 7C63  color 2
        call    PUTSTR                   ; 7C65  the string is on the screen
        mov     si, OFFSET TXTMENU       ; 7C68  SI -- the heading "Main Menu"
        mov     cx, 9                    ; 7C6B  9 characters
        mov     dh, 4                    ; 7C6E  row 4
        mov     dl, 0Eh                  ; 7C70  column 0Eh = 14
        mov     bl, 3                    ; 7C72  color 3
        call    PUTSTR                   ; 7C74  the string is on the screen
        mov     bl, 3                    ; 7C77  color 3
        mov     si, OFFSET TXTF1         ; 7C79  SI -- the "F1 -- input device" line
        mov     cx, 1Bh                  ; 7C7C  1Bh = 27 characters
        mov     dh, 8                    ; 7C7F  row 8
        mov     dl, 0                    ; 7C81  column 0
        call    PUTSTR                   ; 7C83  the string is on the screen
        call    MENUDEV                  ; 7C86  write the selected device in after it
        mov     si, OFFSET TXTF2         ; 7C89  SI -- the "F2 -- game level" line
        mov     cx, 1Bh                  ; 7C8C  1Bh = 27 characters
        mov     dh, 0Ah                  ; 7C8F  row 0Ah = 10
        mov     dl, 0                    ; 7C91  column 0
        call    PUTSTR                   ; 7C93  the string is on the screen
        call    MENULVL                  ; 7C96  write the selected level in after it
        mov     si, OFFSET TXTF3         ; 7C99  SI -- the "F3 -- define keys" line
        mov     cx, 28h                  ; 7C9C  28h = 40 characters
        mov     dh, 0Ch                  ; 7C9F  row 0Ch = 12
        mov     dl, 0                    ; 7CA1  column 0
        call    PUTSTR                   ; 7CA3  the string is on the screen
        mov     si, OFFSET TXTF5         ; 7CA6  SI -- the "F5 -- return to menu" line
        mov     cx, 1Bh                  ; 7CA9  1Bh = 27 characters
        mov     dh, 0Eh                  ; 7CAC  row 0Eh = 14
        mov     dl, 0                    ; 7CAE  column 0
        call    PUTSTR                   ; 7CB0  the string is on the screen
        mov     si, OFFSET TXTF10        ; 7CB3  SI -- the "F10 -- pause" line
        mov     cx, 0Dh                  ; 7CB6  0Dh = 13 characters
        mov     dh, 10h                  ; 7CB9  row 10h = 16
        mov     dl, 0                    ; 7CBB  column 0
        call    PUTSTR                   ; 7CBD  the string is on the screen
        mov     si, OFFSET TXTNOTE       ; 7CC0  SI -- the footnote about keys good only during play
        mov     cx, 28h                  ; 7CC3  28h = 40 characters
        mov     dh, 14h                  ; 7CC6  row 14h = 20
        mov     dl, 0                    ; 7CC8  column 0
        call    PUTSTR                   ; 7CCA  the string is on the screen
        mov     si, OFFSET TXTSTRT       ; 7CCD  SI -- the string "Press <return> to start"
        mov     cx, 17h                  ; 7CD0  17h = 23 characters
        mov     dh, 17h                  ; 7CD3  row 17h = 23
        mov     dl, 0Ah                  ; 7CD5  column 0Ah = 10
        call    PUTSTR                   ; 7CD7  the string is on the screen
        ret                              ; 7CDA  return: the menu is up

;-----------------------------------------------------------------------
; PUTSTR -- Park the cursor at DH,DL and put out CX characters from [SI] through the BIOS.
;
; ENTRY  : SI, CX, DH, DL
; ALTERS : SI
; CALLED BY: KEYLINE, MENUDEV, MENULVL, SCRKEYS, SCRMENU, SCRTTL
;-----------------------------------------------------------------------
PUTSTR:
        mov     ah, 2                    ; 7CDB  AH=2: the "set cursor position" call
        int     10h                      ; 7CDD  video BIOS
LPUTST1:
        push    cx                       ; 7CDF  CX comes back at 7CEA
        mov     cx, 1                    ; 7CE0  put out one character at a time
        mov     ah, 0Eh                  ; 7CE3  AH=0Eh: the "write character" call
        mov     al, [si]                 ; 7CE5  AL -- next character of the string
        int     10h                      ; 7CE7  video BIOS
        inc     si                       ; 7CE9  on to the next character
        pop     cx                       ; 7CEA  CX -- how many are left
        loop    LPUTST1                  ; 7CEB  string is not finished
        ret                              ; 7CED  return: the string is out

;-----------------------------------------------------------------------
; KEYPOLL -- Is a key waiting (INT 16h, AH=1)? CF=0 -- none; otherwise
; it reads the key through KEYREAD.
;
; EXIT   : CF, AX
; ALTERS : nothing
; CALLED BY: ST_MENU, ST_TITLE, WAITKEY
;-----------------------------------------------------------------------
KEYPOLL:
        xor     al, al                   ; 7CEE  AL takes no part here, cleared along the way
        mov     ah, 1                    ; 7CF0  AH=1: is a key in the buffer
        int     16h                      ; 7CF2  keyboard BIOS
        je      LKEYPO1                  ; 7CF4  the buffer is empty
        xor     ax, ax                   ; 7CF6  AH=0: take the key out of the buffer
        int     16h                      ; 7CF8  keyboard BIOS
        stc                              ; 7CFA  CF=1: a key has been read
        ret                              ; 7CFB  return
LKEYPO1:
        clc                              ; 7CFC  CF=0: no key
        ret                              ; 7CFD  return

;-----------------------------------------------------------------------
; MENUDEV -- The F1 line of the menu: Keyboard or Joystick, the chosen
; one highlighted. Looks at INPDEV.
;
; ENTRY  : INPDEV
; ALTERS : AX, CX, DX, SI
; CALLED BY: MENUKEY, SCRMENU
;-----------------------------------------------------------------------
MENUDEV:
        push    bx                       ; 7CFE  BX comes back at 7D2F
        mov     bl, 3                    ; 7CFF  color 3 -- the chosen one
        cmp     INPDEV, 1                ; 7D01  is the joystick chosen
        je      LMENUD1                  ; 7D06  yes -- "Keyboard" will not come out bright
        mov     bl, 2                    ; 7D08  color 2 -- not chosen
LMENUD1:
        mov     si, OFFSET DEVKEY        ; 7D0A  SI -- the word "Keyboard"
        mov     cx, 8                    ; 7D0D  8 characters
        mov     dh, 8                    ; 7D10  row 8
        mov     dl, 8                    ; 7D12  column 8
        call    PUTSTR                   ; 7D14  the word is on the screen
        mov     bl, 3                    ; 7D17  color 3 -- the chosen one
        cmp     INPDEV, 0                ; 7D19  is the keyboard chosen
        je      LMENUD2                  ; 7D1E  yes -- "Joystick" will not come out bright
        mov     bl, 2                    ; 7D20  color 2 -- not chosen
LMENUD2:
        mov     si, OFFSET DEVJOY        ; 7D22  SI -- the word "Joystick"
        mov     cx, 8                    ; 7D25  8 characters
        mov     dh, 8                    ; 7D28  row 8
        mov     dl, 13h                  ; 7D2A  column 13h = 19
        call    PUTSTR                   ; 7D2C  the word is on the screen
        pop     bx                       ; 7D2F  BX restored
        ret                              ; 7D30  return: the F1 line is up

;-----------------------------------------------------------------------
; MENULVL -- The F2 line of the menu: Game Level 1 2 3, the chosen one
; highlighted. Looks at LEVEL.
;
; ENTRY  : LEVEL
; ALTERS : AX, CX, DX, SI, ES
; CALLED BY: MENUKEY, SCRMENU
;-----------------------------------------------------------------------
MENULVL:
        push    bx                       ; 7D31  BX comes back at 7DA7
        cmp     LEVEL, 1                 ; 7D32  level 1
        jne     LMENUL1                  ; 7D37  not the first
        mov     bl, 2                    ; 7D39  color 2 -- the chosen one
        mov     si, OFFSET LVL1          ; 7D3B  SI -- the digit 1
        mov     cx, 1                    ; 7D3E  one character
        mov     dh, 0Ah                  ; 7D41  row 0Ah = 10
        mov     dl, 14h                  ; 7D43  column 14h = 20
        call    PUTSTR                   ; 7D45  the digit is on the screen
        mov     bl, 3                    ; 7D48  color 3 -- not chosen
        mov     si, OFFSET LVL3          ; 7D4A  SI -- the digit 3
        mov     cx, 1                    ; 7D4D  one character
        mov     dh, 0Ah                  ; 7D50  row 0Ah = 10
        mov     dl, 1Ah                  ; 7D52  column 1Ah = 26
        call    PUTSTR                   ; 7D54  the digit is on the screen
        jmp     LMENUL3                  ; 7D57  off to the common exit
LMENUL1:
        cmp     LEVEL, 2                 ; 7D5A  level 2
        jne     LMENUL2                  ; 7D5F  not the second
        mov     bl, 2                    ; 7D61  color 2 -- the chosen one
        mov     si, OFFSET LVL2          ; 7D63  SI -- the digit 2
        mov     cx, 1                    ; 7D66  one character
        mov     dh, 0Ah                  ; 7D69  row 0Ah = 10
        mov     dl, 17h                  ; 7D6B  column 17h = 23
        call    PUTSTR                   ; 7D6D  the digit is on the screen
        mov     bl, 3                    ; 7D70  color 3 -- not chosen
        mov     si, OFFSET LVL1          ; 7D72  SI -- the digit 1
        mov     cx, 1                    ; 7D75  one character
        mov     dh, 0Ah                  ; 7D78  row 0Ah = 10
        mov     dl, 14h                  ; 7D7A  column 14h = 20
        call    PUTSTR                   ; 7D7C  the digit is on the screen
        jmp     LMENUL3                  ; 7D7F  off to the common exit
LMENUL2:
        cmp     LEVEL, 3                 ; 7D82  level 3
        jne     LMENUL3                  ; 7D87  not the third
        mov     bl, 2                    ; 7D89  color 2 -- the chosen one
        mov     si, OFFSET LVL3          ; 7D8B  SI -- the digit 3
        mov     cx, 1                    ; 7D8E  one character
        mov     dh, 0Ah                  ; 7D91  row 0Ah = 10
        mov     dl, 1Ah                  ; 7D93  column 1Ah = 26
        call    PUTSTR                   ; 7D95  the digit is on the screen
        mov     bl, 3                    ; 7D98  color 3 -- not chosen
        mov     si, OFFSET LVL2          ; 7D9A  SI -- the digit 2
        mov     cx, 1                    ; 7D9D  one character
        mov     dh, 0Ah                  ; 7DA0  row 0Ah = 10
        mov     dl, 17h                  ; 7DA2  column 17h = 23
        call    PUTSTR                   ; 7DA4  the digit is on the screen
LMENUL3:
        pop     bx                       ; 7DA7  BX restored
        clc                              ; 7DA8  CF=0 -- the line has been handled
        ret                              ; 7DA9  return: the F2 line is up

CSEG    ENDS
        END
