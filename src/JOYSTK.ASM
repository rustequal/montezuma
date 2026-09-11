        PAGE  60,132
        TITLE JOYSTK -- JOYSTICK, KEYS, NEW-GAME RESET
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC INPREAD
        PUBLIC KEY_DN
        PUBLIC KEY_JLF
        PUBLIC KEY_JRT
        PUBLIC KEY_JUP
        PUBLIC KEY_LF
        PUBLIC KEY_RT
        PUBLIC KEY_UP
        PUBLIC NEWGAME
        EXTRN  INPDEV:BYTE
        EXTRN  LASTKEY:WORD

;=======================================================================
; JOYSTK.ASM -- JOYSTICK, KEYS, NEW-GAME RESET
;
; Axis thresholds, KEYTAB, reading the input device, the joystick's
; self-calibration, and the state reset for a new game.
;=======================================================================

;-----------------------------------------------------------------------
; JOYSTICK AND THE REDEFINABLE KEYS  (5DF0..5E18, 41 bytes)
;
; 5DF8h/5DFAh -- axis counts 0..63, filled in by JOYCAL off port 201h
; 5DFDh KEYTAB -- 7 records of 4 bytes: scan code and the answer in
;                 INPREAD form -- high byte direction, low byte buttons
;-----------------------------------------------------------------------
JOYYLO  DW    8                          ; 5DF0  low threshold of the Y axis, trims itself
JOYYHI  DW    9                          ; 5DF2  high threshold of the Y axis
JOYXLO  DW    5                          ; 5DF4  low threshold of the X axis
JOYXHI  DW    6                          ; 5DF6  high threshold of the X axis
JOYXRAW DW    0                          ; 5DF8  last count taken off the X axis
JOYYRAW DW    0                          ; 5DFA  last count taken off the Y axis
; direction worked out from where the stick is held
JOYBITS DB    00h                        ; 5DFC
; redefinable keys, 7 records of 4 bytes
KEYTAB  LABEL WORD                       ; 5DFD
KEY_UP  DW    4838h,210h                 ; 5DFD  Num 8: AH=DIR_UP, AL=BTN_JUMP -- up, no jump
KEY_DN  DW    5032h,110h                 ; 5E01  Num 2: AH=DIR_DN, AL=BTN_JUMP -- down, no jump
KEY_LF  DW    4B34h,410h                 ; 5E05  Num 4: AH=DIR_LF, AL=BTN_JUMP -- left, no jump
KEY_RT  DW    4D36h,810h                 ; 5E09  Num 6: AH=DIR_RT, AL=BTN_JUMP -- right, no jump
KEY_JLF DW    4737h,400h                 ; 5E0D  Num 7: AH=DIR_LF, AL=0 -- jump left
KEY_JUP DW    4C35h,0                    ; 5E11  Num 5: AH=0, AL=0 -- jump straight up
KEY_JRT DW    4939h,800h                 ; 5E15  Num 9: AH=DIR_RT, AL=0 -- jump right

;=======================================================================
; CALIBRATION HIGH MARKS AND THE NEW-GAME RESET
;=======================================================================

;-----------------------------------------------------------------------
; INPREAD -- Read the input device: with INPDEV = 0 the keyboard through
; KEYLOOK, otherwise the joystick through JOYCAL and JOYDIR.
;
; ENTRY  : INPDEV
; EXIT   : AH -- direction bits, AL -- button byte off port 201h,
;          a button reads active low
; ALTERS : BX, CX, SI
; CALLED BY: READCMD
;-----------------------------------------------------------------------
INPREAD:
        push    dx                       ; 5E19  DX comes back at 5E34
        cmp     INPDEV, 0                ; 5E1A  INPDEV -- the input device now selected
        jne     LINPRE1                  ; 5E1F  not the keyboard -- read the joystick
        jmp     KEYLOOK                  ; 5E21  keyboard: pick LASTKEY apart
LINPRE1:
        mov     bx, 102h                 ; 5E24  BH=1, BL=2 -- X and Y axis bits of port 201h
        call    JOYCAL                   ; 5E27  take a count off both axes
        in      al, dx                   ; 5E2A  AL -- the port 201h byte with the buttons
        push    ax                       ; 5E2B  AX comes back at 5E2F
        call    JOYDIR                   ; 5E2C  counts -> direction bits
        pop     ax                       ; 5E2F  AL -- the button byte
        mov     ah, JOYBITS              ; 5E30  AH -- the direction bits
        pop     dx                       ; 5E34  DX restored
        ret                              ; 5E35  return: direction in AH, buttons in AL

;-----------------------------------------------------------------------
; JOYDIR -- Where the stick is held -> direction bits in JOYBITS. The
; thresholds are matched against the current count and trimmed on the spot.
;
; ENTRY  : JOYXRAW, JOYYRAW
; EXIT   : JOYBITS
; ALTERS : AX, BX, CX, SI
; CALLED BY: INPREAD
;-----------------------------------------------------------------------
JOYDIR:
        mov     JOYBITS, 0               ; 5E36  direction bits start out empty
        mov     si, JOYXRAW              ; 5E3B  SI -- count off the X axis
        mov     bx, JOYXLO               ; 5E3F  BX -- low threshold of the X axis
        add     bx, 2                    ; 5E43  threshold plus two units of hysteresis
        cmp     si, bx                   ; 5E46  is the count above the threshold?
        jg      LJOYDI2                  ; 5E48  yes -- go look at the high threshold
        cmp     si, JOYXLO               ; 5E4A  is the count below the threshold itself?
        jge     LJOYDI1                  ; 5E4E  no -- leave the threshold where it is
        call    ADJXLO                   ; 5E50  trim the low threshold of the X axis
LJOYDI1:
        or      JOYBITS, DIR_LF          ; 5E53  bit 2 -- left
        jmp     LJOYDI4                  ; 5E58  the X axis is done
LJOYDI2:
        mov     ax, JOYXHI               ; 5E5B  AX -- high threshold of the X axis
        shr     ax, 1                    ; 5E5E  shift 1 of three
        shr     ax, 1                    ; 5E60  shift 2 of three
        shr     ax, 1                    ; 5E62  threshold divided by eight
        or      ax, 2                    ; 5E64  never less than two units of hysteresis
        mov     bx, JOYXHI               ; 5E67  BX -- high threshold of the X axis
        sub     bx, ax                   ; 5E6B  BX -- threshold minus the hysteresis
        cmp     si, bx                   ; 5E6D  is the count below the threshold?
        jl      LJOYDI4                  ; 5E6F  yes -- the axis is at rest
        cmp     si, JOYXHI               ; 5E71  is the count above the threshold itself?
        jle     LJOYDI3                  ; 5E75  no -- leave the threshold where it is
        call    ADJXHI                   ; 5E77  trim the high threshold of the X axis
LJOYDI3:
        or      JOYBITS, DIR_RT          ; 5E7A  bit 3 -- right
LJOYDI4:
        mov     si, JOYYRAW              ; 5E7F  SI -- count off the Y axis
        mov     bx, JOYYLO               ; 5E83  BX -- low threshold of the Y axis
        add     bx, 2                    ; 5E87  threshold plus two units of hysteresis
        cmp     si, bx                   ; 5E8A  is the count above the threshold?
        jg      LJOYDI6                  ; 5E8C  yes -- go look at the high threshold
        cmp     si, JOYYLO               ; 5E8E  is the count below the threshold itself?
        jge     LJOYDI5                  ; 5E92  no -- leave the threshold where it is
        call    ADJYLO                   ; 5E94  trim the low threshold of the Y axis
LJOYDI5:
        or      JOYBITS, DIR_UP          ; 5E97  bit 1 -- up
        jmp     LJOYDI8                  ; 5E9C  the Y axis is done
LJOYDI6:
        mov     ax, JOYYHI               ; 5E9F  AX -- high threshold of the Y axis
        shr     ax, 1                    ; 5EA2  shift 1 of three
        shr     ax, 1                    ; 5EA4  shift 2 of three
        shr     ax, 1                    ; 5EA6  threshold divided by eight
        or      ax, 2                    ; 5EA8  never less than two units of hysteresis
        mov     bx, JOYYHI               ; 5EAB  BX -- high threshold of the Y axis
        sub     bx, ax                   ; 5EAF  BX -- threshold minus the hysteresis
        cmp     si, bx                   ; 5EB1  is the count below the threshold?
        jl      LJOYDI8                  ; 5EB3  yes -- the axis is at rest
        cmp     si, JOYYHI               ; 5EB5  is the count above the threshold itself?
        jle     LJOYDI7                  ; 5EB9  no -- leave the threshold where it is
        call    ADJYHI                   ; 5EBB  trim the high threshold of the Y axis
LJOYDI7:
        or      JOYBITS, DIR_DN          ; 5EBE  bit 0 -- down
LJOYDI8:
        ret                              ; 5EC3  return: direction bits in JOYBITS

;-----------------------------------------------------------------------
; CALIBRATION HIGH MARKS  (5EC4..5ECB, 8 bytes)
;
; The extreme readings of the joystick axes, built up by NEWGAME.
;-----------------------------------------------------------------------
; running-average accumulator behind JOYXLO
ACCXLO  DW    40h                        ; 5EC4
ACCXHI  DW    48h                        ; 5EC6  accumulator behind JOYXHI
ACCYLO  DW    28h                        ; 5EC8  accumulator behind JOYYLO
ACCYHI  DW    30h                        ; 5ECA  accumulator behind JOYYHI

;-----------------------------------------------------------------------
; NEWGAME -- Reset the state for a new game.
;
; ALTERS : DX, SI
; CALLED BY: ST_TITLE
;-----------------------------------------------------------------------
NEWGAME:
        SAVEREG <cx,bx,ax>               ; 5ECC  macro
        mov     bx, 102h                 ; 5ECF  BH=1, BL=2 -- X and Y axis bits of port 201h
        call    JOYCAL                   ; 5ED2  take a count off both axes
        mov     ax, JOYXRAW              ; 5ED5  AX -- count off the X axis
        sub     ax, 3                    ; 5ED8  three units down -- that is the low threshold
        jl      LNEWGA1                  ; 5EDB  threshold went below zero -- keep the old one
        mov     JOYXLO, ax               ; 5EDD  low threshold of the X axis
LNEWGA1:
        mov     ax, JOYXRAW              ; 5EE0  AX -- count off the X axis
        mov     cl, 3                    ; 5EE3  CL=3 -- shift by three places
        shr     ax, cl                   ; 5EE5  count divided by eight
        or      ax, 2                    ; 5EE7  never less than two units
        add     ax, JOYXRAW              ; 5EEA  plus the count itself
        mov     JOYXHI, ax               ; 5EEE  high threshold of the X axis
        inc     JOYXHI                   ; 5EF1  and one more unit on top
        mov     ax, JOYYRAW              ; 5EF5  AX -- count off the Y axis
        sub     ax, 3                    ; 5EF8  three units down -- that is the low threshold
        jl      LNEWGA2                  ; 5EFB  threshold went below zero -- keep the old one
        mov     JOYYLO, ax               ; 5EFD  low threshold of the Y axis
LNEWGA2:
        mov     ax, JOYYRAW              ; 5F00  AX -- count off the Y axis
        mov     cl, 3                    ; 5F03  CL=3 -- shift by three places
        shr     ax, cl                   ; 5F05  count divided by eight
        or      ax, 2                    ; 5F07  never less than two units
        add     ax, JOYYRAW              ; 5F0A  plus the count itself
        mov     JOYYHI, ax               ; 5F0E  high threshold of the Y axis
        inc     JOYYHI                   ; 5F11  and one more unit on top
        mov     ax, JOYXLO               ; 5F15  AX -- low threshold of the X axis
        mov     cl, 3                    ; 5F18  CL=3 -- shift by three places
        shl     ax, cl                   ; 5F1A  threshold times eight: eight shares to a unit
        mov     ACCXLO, ax               ; 5F1C  accumulator of the X axis low threshold
        mov     ax, JOYXHI               ; 5F1F  AX -- high threshold of the X axis
        mov     cl, 3                    ; 5F22  CL=3 -- shift by three places
        shl     ax, cl                   ; 5F24  threshold times eight
        mov     ACCXHI, ax               ; 5F26  accumulator of the X axis high threshold
        mov     ax, JOYYLO               ; 5F29  AX -- low threshold of the Y axis
        mov     cl, 3                    ; 5F2C  CL=3 -- shift by three places
        shl     ax, cl                   ; 5F2E  threshold times eight
        mov     ACCYLO, ax               ; 5F30  accumulator of the Y axis low threshold
        mov     ax, JOYYHI               ; 5F33  AX -- high threshold of the Y axis
        mov     cl, 3                    ; 5F36  CL=3 -- shift by three places
        shl     ax, cl                   ; 5F38  threshold times eight
        mov     ACCYHI, ax               ; 5F3A  accumulator of the Y axis high threshold
        RESTREG <ax,bx,cx>               ; 5F3D  macro
        ret                              ; 5F40  return: the joystick is calibrated

;-----------------------------------------------------------------------
; ADJXLO -- Trim the low threshold of the X axis: acc += count - threshold,
; threshold = acc/8. A running average with a coefficient of 1/8.
;
; ENTRY  : SI
; EXIT   : JOYXLO
; ALTERS : AX
; CALLED BY: JOYDIR
;-----------------------------------------------------------------------
ADJXLO:
        push    cx                       ; 5F41  CX comes back at 5F55
        mov     ax, ACCXLO               ; 5F42  AX -- accumulator of the X low threshold
        sub     ax, JOYXLO               ; 5F45  take the current threshold out
        add     ax, si                   ; 5F49  add the new count in
        mov     ACCXLO, ax               ; 5F4B  accumulator brought up to date
        mov     cl, 3                    ; 5F4E  CL=3 -- shift by three places
        shr     ax, cl                   ; 5F50  accumulator divided by eight
        mov     JOYXLO, ax               ; 5F52  new low threshold of the X axis
        pop     cx                       ; 5F55  CX restored
        ret                              ; 5F56  return: the threshold is trimmed

;-----------------------------------------------------------------------
; ADJXHI -- The same for the high threshold of the X axis.
;
; ENTRY  : SI
; EXIT   : JOYXHI
; ALTERS : AX
; CALLED BY: JOYDIR
;-----------------------------------------------------------------------
ADJXHI:
        push    cx                       ; 5F57  CX comes back at 5F6B
        mov     ax, ACCXHI               ; 5F58  AX -- accumulator of the X high threshold
        sub     ax, JOYXHI               ; 5F5B  take the current threshold out
        add     ax, si                   ; 5F5F  add the new count in
        mov     ACCXHI, ax               ; 5F61  accumulator brought up to date
        mov     cl, 3                    ; 5F64  CL=3 -- shift by three places
        shr     ax, cl                   ; 5F66  accumulator divided by eight
        mov     JOYXHI, ax               ; 5F68  new high threshold of the X axis
        pop     cx                       ; 5F6B  CX restored
        ret                              ; 5F6C  return: the threshold is trimmed

;-----------------------------------------------------------------------
; ADJYLO -- The same for the low threshold of the Y axis.
;
; ENTRY  : SI
; EXIT   : JOYYLO
; ALTERS : AX
; CALLED BY: JOYDIR
;-----------------------------------------------------------------------
ADJYLO:
        push    cx                       ; 5F6D  CX comes back at 5F81
        mov     ax, ACCYLO               ; 5F6E  AX -- accumulator of the Y low threshold
        sub     ax, JOYYLO               ; 5F71  take the current threshold out
        add     ax, si                   ; 5F75  add the new count in
        mov     ACCYLO, ax               ; 5F77  accumulator brought up to date
        mov     cl, 3                    ; 5F7A  CL=3 -- shift by three places
        shr     ax, cl                   ; 5F7C  accumulator divided by eight
        mov     JOYYLO, ax               ; 5F7E  new low threshold of the Y axis
        pop     cx                       ; 5F81  CX restored
        ret                              ; 5F82  return: the threshold is trimmed

;-----------------------------------------------------------------------
; ADJYHI -- The same for the high threshold of the Y axis.
;
; ENTRY  : SI
; EXIT   : JOYYHI
; ALTERS : AX
; CALLED BY: JOYDIR
;-----------------------------------------------------------------------
ADJYHI:
        push    cx                       ; 5F83  CX comes back at 5F97
        mov     ax, ACCYHI               ; 5F84  AX -- accumulator of the Y high threshold
        sub     ax, JOYYHI               ; 5F87  take the current threshold out
        add     ax, si                   ; 5F8B  add the new count in
        mov     ACCYHI, ax               ; 5F8D  accumulator brought up to date
        mov     cl, 3                    ; 5F90  CL=3 -- shift by three places
        shr     ax, cl                   ; 5F92  accumulator divided by eight
        mov     JOYYHI, ax               ; 5F94  new high threshold of the Y axis
        pop     cx                       ; 5F97  CX restored
        ret                              ; 5F98  return: the threshold is trimmed

;-----------------------------------------------------------------------
; JOYCAL -- Count the joystick axes: fire the one-shots with a write to
; port 201h and count the reads until the bit drops. Scale 0..63; if it
; never drops in time, the count stays zero.
;
; ENTRY  : BH, BL -- bit masks of the X and Y axes
; EXIT   : JOYXRAW, JOYYRAW
; ALTERS : AX, CX, DX, SI
; CALLED BY: INPREAD, NEWGAME
;-----------------------------------------------------------------------
JOYCAL:
        cli                              ; 5F99  the count is taken with interrupts off
        mov     JOYXRAW, 0               ; 5F9A  X axis count starts out empty
        mov     JOYYRAW, 0               ; 5FA0  Y axis count starts out empty
        mov     cx, 40h                  ; 5FA6  40h = 64 -- top of the scale
        xor     si, si                   ; 5FA9  SI -- count of reads
        mov     ax, si                   ; 5FAB  AX=0 -- what goes out to the port
        mov     dx, PORT201              ; 5FAD  the joystick port
        out     dx, al                   ; 5FB0  the write fires the one-shots
LJOYCA1:
        in      al, dx                   ; 5FB1  AL -- status byte of the axes and buttons
        cmp     JOYXRAW, 0               ; 5FB2  has the X axis been counted already?
        jne     LJOYCA2                  ; 5FB7  yes -- leave it alone
        test    al, bh                   ; 5FB9  is the X axis bit still up?
        jne     LJOYCA2                  ; 5FBB  still up -- keep counting
        mov     JOYXRAW, si              ; 5FBD  it dropped: the X axis count is in
LJOYCA2:
        cmp     JOYYRAW, 0               ; 5FC1  has the Y axis been counted already?
        jne     LJOYCA3                  ; 5FC6  yes -- leave it alone
        test    al, bl                   ; 5FC8  is the Y axis bit still up?
        jne     LJOYCA3                  ; 5FCA  still up -- keep counting
        mov     JOYYRAW, si              ; 5FCC  it dropped: the Y axis count is in
LJOYCA3:
        test    al, bl                   ; 5FD0  is the Y axis bit still up?
        jne     LJOYCA4                  ; 5FD2  still up -- keep counting
        test    al, bh                   ; 5FD4  is the X axis bit still up?
        jne     LJOYCA4                  ; 5FD6  still up -- keep counting
        je      LJOYCA5                  ; 5FD8  both dropped -- nothing left to count
LJOYCA4:
        inc     si                       ; 5FDA  read counter one step on
        loop    LJOYCA1                  ; 5FDB  the scale is not used up
LJOYCA5:
        cmp     si, 40h                  ; 5FDD  did we run all the way to the top of the scale
        sti                              ; 5FE0  interrupts back on
        ret                              ; 5FE1  return: the counts are in JOYXRAW and JOYYRAW

;-----------------------------------------------------------------------
; KEYLOOK -- Find the scan code in KEYTAB and hand back the action code.
;
; ENTRY  : LASTKEY
; EXIT   : AX
; ALTERS : BX, CX
; CALLED BY: INPREAD (via JMP)
;-----------------------------------------------------------------------
KEYLOOK:
        mov     ax, LASTKEY              ; 5FE2  AX -- scan code of the last key
        mov     bx, OFFSET KEYTAB        ; 5FE5  BX -- table of the redefinable keys
        mov     cx, 7                    ; 5FE8  seven records
LKEYLO1:
        cmp     ax, [bx]                 ; 5FEB  scan code of this record
        je      LKEYLO3                  ; 5FED  found it
        add     bx, 4                    ; 5FEF  records run four bytes apiece
        loop    LKEYLO1                  ; 5FF2  records not used up yet
        mov     ax, 10h                  ; 5FF4  10h -- no direction and no buttons
LKEYLO2:
        pop     dx                       ; 5FF7  DX off the stack, pushed back in INPREAD
        ret                              ; 5FF8  return: the answer is in AX
LKEYLO3:
        mov     ax, [bx+2]               ; 5FF9  second word of the record -- the answer
        jmp     short LKEYLO2            ; 5FFC  off to the common exit

CSEG    ENDS
        END
