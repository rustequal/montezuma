        PAGE  60,132
        TITLE ITEMS -- SCORE, ITEMS, COLLISIONS, STATUS PANEL
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC ANIMHIT
        PUBLIC DEADBIT
        PUBLIC HUDFULL
        PUBLIC INLIST
        PUBLIC ITEMCNT
        PUBLIC ITEMS
        PUBLIC MKOBJF
        PUBLIC OBJKILL
        PUBLIC OBJMOVE
        PUBLIC OBJTYPE
        PUBLIC PLRHIT
        PUBLIC PUTBAR
        PUBLIC RCTREC
        PUBLIC RCTSHOW
        PUBLIC READCMD
        PUBLIC ROOMOBN
        PUBLIC SCORE
        PUBLIC SHOWSCR
        EXTRN  ANIMIDX:WORD
        EXTRN  ANIMLEN:WORD
        EXTRN  ANIMPTR:WORD
        EXTRN  BARTIL:BYTE
        EXTRN  CMDBITS:WORD
        EXTRN  CMDOP:BYTE
        EXTRN  CMDP1:BYTE
        EXTRN  CMDX:BYTE
        EXTRN  CURSPOS:NEAR
        EXTRN  DARKF:BYTE
        EXTRN  DIGELM:BYTE
        EXTRN  ELMCUR:WORD
        EXTRN  ELMTAB:BYTE
        EXTRN  ELMTILE:NEAR
        EXTRN  ELM_AMUL:ABS
        EXTRN  ELM_AMULI:ABS
        EXTRN  ELM_GEM:ABS
        EXTRN  ELM_SWRD:ABS
        EXTRN  ELM_SWRDI:ABS
        EXTRN  FILLRC:NEAR
        EXTRN  GATETIL:BYTE
        EXTRN  HITOBJ:WORD
        EXTRN  INBITS:BYTE
        EXTRN  INPREAD:NEAR
        EXTRN  LEVEL:BYTE
        EXTRN  LITNOW:BYTE
        EXTRN  LIVES:BYTE
        EXTRN  MAPOFS:WORD
        EXTRN  NOP0:NEAR
        EXTRN  OBJBIT:BYTE
        EXTRN  OBJKND:BYTE
        EXTRN  OBJTBL:WORD
        EXTRN  OBJTMR2:BYTE
        EXTRN  OBJTYP:BYTE
        EXTRN  OBJVX:BYTE
        EXTRN  OBJVY:WORD
        EXTRN  PARMSPL:NEAR
        EXTRN  AN_DIE:WORD
        EXTRN  PH71:WORD
        EXTRN  PLAYSND:NEAR
        EXTRN  PLRST:BYTE
        EXTRN  PR_PATT:NEAR
        EXTRN  PUT2X2:NEAR
        EXTRN  PUTGRID:NEAR
        EXTRN  PUTRCT:NEAR
        EXTRN  ROOMKND:BYTE
        EXTRN  ROOMOBJ:WORD
        EXTRN  ROOMRQ:BYTE
        EXTRN  SCRMAP:BYTE
        EXTRN  SEENMAP:WORD
        EXTRN  STANDCK:NEAR
        EXTRN  TILEAT:BYTE
        EXTRN  TILEDN:BYTE
        EXTRN  TILELF:BYTE
        EXTRN  TILERT:BYTE

;=======================================================================
; ITEMS.ASM -- SCORE, ITEMS, COLLISIONS, STATUS PANEL
;
; The collision mask, the points table and the inventory; the pass over
; the live objects, the control command handler, scoring, picking items
; up, doors, the status panel and the GAME OVER sign.
;=======================================================================

;-----------------------------------------------------------------------
; SCORE, POINTS, INVENTORY  (6C60..6CB7, 88 bytes)
;
; 6C60h HITMSK  -- collision mask for the frame
; 6C61h PTSTAB  -- 7 point values in BCD: 50 100 3000 300 1000 2000 3000
; 6C6Fh ITMELM  -- 7 codes of the elements you can pick up: 4B 43 47 37 2F 2B 3F
; 6C76h ITMPTS  -- element -> offset into PTSTAB: 0 0 0 0 2 8 4
; 6C84h SCORE   -- 3 bytes of packed BCD, high byte first
; 6C87h HUDRCT  -- the two status panel rectangles for PUTRCT
; 6CA4h ITEMCNT, 6CA5h ITEMS -- a five-slot inventory, one word per slot
; 6CAFh ITMTMR  -- the amulet timer: 37h steps of PLRHIT
;-----------------------------------------------------------------------
; collision mask, built up over the frame
HITMSK  DB    00h             ; 6C60
; table of points per event, 2 BCD bytes to a record
PTSTAB  DB    50h,00h,00h,01h,00h,30h,00h,03h,00h,10h,00h,20h,00h,30h ; 6C61
; codes of the elements you can pick up; PLRHIT walks them from the end
ITMELM  DB    4Bh,43h,47h,37h,2Fh,2Bh,3Fh                             ; 6C6F
; element -> offset of its record in PTSTAB
ITMPTS  DW    0,0,0,0,2,8,4   ; 6C76
; score, 3 bytes of packed BCD, 6C84 = the high one
SCORE   DB    00h             ; 6C84
SCORE1  DB    00h             ; 6C85  SCORE, middle BCD byte
SCORE2  DB    00h             ; 6C86  SCORE, low BCD byte
; the two status panel windows: row, column, height, width
HUDRCT  DW    1,1,3,0Dh       ; 6C87  left-hand window
        DW    1,1Ah,3,0Dh     ; 6C8F  right-hand window
        DW    0FFh            ; 6C97  terminator of a PUTRCT list
; record of a dirty rectangle: row, column, height, width
RCTREC  DW    0               ; 6C99
RCTCOL  DW    0               ; 6C9B  column of the dirty rectangle
; height of the dirty rectangle in tiles
RCTH    DW    0               ; 6C9D
; width of the dirty rectangle in tiles
RCTW    DW    0,0FFh          ; 6C9F
; how many objects are in the current room
ROOMOBN DB    00h             ; 6CA3
; how many items are in the inventory
ITEMCNT DB    00h             ; 6CA4
ITEMS   DW    5 DUP (0)       ; 6CA5..6CAE  inventory: item codes, ITEMCNT slots of it in use
; ticks of amulet invulnerability left; while it is non-zero PLRHIT
; ignores collisions
ITMTMR  DB    00h             ; 6CAF
; code of the last element picked up
LASTITM DB    00h             ; 6CB0
D_6CB1  DB    00h             ; 6CB1  written with a one at 712Fh, never read back
DEADBIT DB    00h             ; 6CB2  bit of the object killed this frame, so ERSALL erases it too
MKOBJF  DB    01h             ; 6CB3  0 = rebuild the room without bringing the enemies back
ELMOFS  DW    0               ; 6CB4  offset of the element found, within SCRMAP
JMPPREV DB    00h             ; 6CB6  state of the jump button in the previous frame
HUDFULL DB    00h             ; 6CB7  1 = the panel is drawn whole

;-----------------------------------------------------------------------
; ANIMHIT -- Clear HITMSK and walk every live object by the INBITS bits,
; testing for collisions as it goes.
;
; ENTRY  : INBITS
; EXIT   : HITMSK
; ALTERS : nothing
; CALLED BY: DRAWFRM, ST_DRW, ST_PL1, ST_PL2, ST_PL3
;-----------------------------------------------------------------------
ANIMHIT:
        SAVEALL                          ; 6CB8  macro
        mov     HITMSK, 0                ; 6CBF  the frame's collision mask starts out empty
        mov     si, 7                    ; 6CC4  SI=7 -- count the slots from the top down
        mov     al, INBITS               ; 6CC7  AL -- one bit per live object
LANIMH1:
        rcl     al, 1                    ; 6CCA  next bit out into the carry
        jae     LANIMH7                  ; 6CCC  bit clear -- no object in this slot
        SAVEREG <ax,si>                  ; 6CCE  macro
        cmp     si, 0                    ; 6CD0  object 0 is the player
        jne     LANIMH3                  ; 6CD3  not the player
        xor     ah, ah                   ; 6CD5  AH=0: the whole state now sits in AX
        mov     al, PLRST                ; 6CD7  AL -- the player's state
        cmp     al, 0                    ; 6CDA  state 0 -- standing still
        je      LANIMH4                  ; 6CDC  standing -- do not change the frame
        cmp     ax, 3                    ; 6CDE  state 3 -- climbing
        je      LANIMH2                  ; 6CE1  state 3 -- climbing
        cmp     ax, 4                    ; 6CE3  state 4 -- hanging on a rope
        jne     LANIMH3                  ; 6CE6  neither one -- the frame does change
LANIMH2:
        cmp     OBJVY, 0                 ; 6CE8  is the player moving vertically?
        jne     LANIMH3                  ; 6CED  moving -- the frame does change
        mov     bx, OFFSET ANIMIDX       ; 6CEF  table of frame numbers, one slot per object
        shl     si, 1                    ; 6CF2  slots run a word apiece
        mov     di, [bx+si]              ; 6CF4  DI -- the frame number as it was
        jmp     LANIMH5                  ; 6CF6  the frame stays where it is
LANIMH3:
        shl     si, 1                    ; 6CF9  slots run a word apiece
        mov     bx, OFFSET ANIMIDX       ; 6CFB  table of frame numbers, one slot per object
        inc     WORD PTR [bx+si]         ; 6CFE  frame number one step on
        mov     di, [bx+si]              ; 6D00  DI -- the new frame number
        mov     bp, OFFSET ANIMLEN       ; 6D02  highest frame number, one slot per object
        cmp     di, ds:[bp+si]           ; 6D05  has the chain run out?
        jle     LANIMH5                  ; 6D08  no -- the frame will do
LANIMH4:
        mov     bx, OFFSET ANIMIDX       ; 6D0A  table of frame numbers, one slot per object
        mov     WORD PTR [bx+si], 0      ; 6D0D  the chain starts over
        mov     di, 0                    ; 6D11  DI=0 -- first frame of the chain
LANIMH5:
        mov     bx, OFFSET OBJTBL        ; 6D14  BX -- object table, object 0 is the player
        mov     bp, OFFSET ANIMPTR       ; 6D17  table of frame chains, one slot per object
        mov     bp, ds:[bp+si]           ; 6D1A  BP -- the chain this slot is running
        mov     ax, si                   ; 6D1D  AX -- slot number, already doubled
        mov     cl, 3                    ; 6D1F  CL=3: doubled number * 3 = number * 6
        mul     cl                       ; 6D21  doubled number * 3 = number * 6
        mov     si, ax                   ; 6D23  SI -- offset of the object record
        shl     di, 1                    ; 6D25  chain entries run two bytes apiece
        mov     ax, ds:[bp+di]           ; 6D27  AX -- the frame out of the chain
        inc     ax                       ; 6D2A  step 1 of two: the frame header
        inc     ax                       ; 6D2B  step over the frame header
        mov     [bx+si], ax              ; 6D2C  pointer to the object's bitmap
        pop     si                       ; 6D2E  SI -- the slot number
        cmp     si, 0                    ; 6D2F  object 0 is the player
        je      LANIMH6                  ; 6D32  he cannot collide with himself
        call    HITCHK                   ; 6D34  test for a collision with the player
LANIMH6:
        pop     ax                       ; 6D37  AL -- one bit per live object
LANIMH7:
        dec     si                       ; 6D38  on to the next slot
        jge     LANIMH1                  ; 6D39  slots not used up yet
        RESTALL                          ; 6D3B  macro
        ret                              ; 6D42  return: frames advanced, HITMSK built up

;-----------------------------------------------------------------------
; OBJMOVE -- Shift object SI along axis AH (0 = X, 1 = Y) by the signed AL.
;
; ENTRY  : AL, AH, SI
; ALTERS : nothing
; CALLED BY: BEH_CLMB, BEH_JUMP, BEH_WALK, MOVEPLR, PST_0
;-----------------------------------------------------------------------
OBJMOVE:
        SAVEALL                          ; 6D43  macro
        mov     bp, OFFSET OBJTBL        ; 6D4A  BP -- object table, object 0 is the player
        mov     dx, ax                   ; 6D4D  DL -- the signed shift
        xor     cx, cx                   ; 6D4F  CX=0
        mov     cl, ah                   ; 6D51  CL -- which axis: 0 = X, 1 = Y
        mov     ax, si                   ; 6D53  AX -- object number
        mov     bl, 6                    ; 6D55  BL=6 -- length of an object record
        mul     bl                       ; 6D57  number * 6: records run six bytes apiece
        add     ax, 2                    ; 6D59  field +2 of the record is X
        add     ax, cx                   ; 6D5C  plus the axis number: X or Y
        mov     si, ax                   ; 6D5E  SI -- offset of the field
        add     ds:[bp+si], dl           ; 6D60  the coordinate is shifted
        RESTALL                          ; 6D63  macro
        ret                              ; 6D6A  return: the object has moved

;-----------------------------------------------------------------------
; INLIST -- Look for AL in the list at DS:BP, SI long. CF = found.
;
; ENTRY  : AL, BP, SI
; EXIT   : CF
; ALTERS : nothing
; CALLED BY: BEH_JUMP, BEH_WALK, MOVEPLR, PLRHIT, PST_0, PST_34, PST_5
;-----------------------------------------------------------------------
INLIST:
        SAVEREG <cx,si>                  ; 6D6B  macro
        mov     cx, si                   ; 6D6D  on entry SI holds the length of the list
        xor     si, si                   ; 6D6F  from here on it is the index
LINLIS1:
        cmp     ds:[bp+si], al           ; 6D71  next entry of the list
        je      LINLIS2                  ; 6D74  a match
        inc     si                       ; 6D76  on to the next entry
        loop    LINLIS1                  ; 6D77  the list is not used up
        clc                              ; 6D79  CF=0: not in the list
        jmp     LINLIS3                  ; 6D7A  off to the common exit
LINLIS2:
        stc                              ; 6D7D  CF=1: it is in the list
LINLIS3:
        RESTREG <si,cx>                  ; 6D7E  macro
        ret                              ; 6D80  return: the answer is in CF

;-----------------------------------------------------------------------
; READCMD -- Poll the input device and lay the result out into CMDBITS.
;
; Bit 4 of the low byte means the button is released. If it was held in
; the previous frame as well, the bit is forced on: a jump fires on the
; press, never on the hold. The previous state lives in JMPPREV.
;
; EXIT   : CMDBITS, JMPPREV
; ALTERS : AX, BX, CX, DX, SI
; CALLED BY: PLRTICK, ST_X7
;-----------------------------------------------------------------------
READCMD:
        call    INPREAD                  ; 6D81  AH -- direction, AL -- buttons
        mov     CMDBITS, ax              ; 6D84  the control command for this frame
        and     al, BTN_JUMP             ; 6D87  bit 4 -- the jump button: 0 held, 1 released
        cmp     JMPPREV, BTN_JUMP        ; 6D89  was the button released in the previous frame
        je      LREADC1                  ; 6D8E  it was -- this press counts
        cmp     al, BTN_JUMP             ; 6D90  is it released right now
        jne     LREADC2                  ; 6D92  held, and it was held in the previous frame too
LREADC1:
        mov     JMPPREV, al              ; 6D94  the state of the button is kept
        jmp     LREADC3                  ; 6D97  off to the common exit
LREADC2:
        or      CMDBITS, BTN_JUMP        ; 6D9A  bit 4 forced on: holding the button kills the jump
LREADC3:
        ret                              ; 6DA0  return: the command has been sorted out

;-----------------------------------------------------------------------
; OBJTYPE -- Work out the behavior type of object SI (0 = the player -> 4).
;
; ENTRY  : SI
; EXIT   : OBJTYP
; ALTERS : nothing
; CALLED BY: ENEMOVE, FRMWAIT, PLRHIT, SCANTIL
;-----------------------------------------------------------------------
OBJTYPE:
        SAVEREG <ax,bx>                  ; 6DA1  macro
        cmp     si, 0                    ; 6DA3  object 0 is the player
        jne     LOBJTY1                  ; 6DA6  not the player
        mov     OBJTYP, 4                ; 6DA8  type 4 -- the player
        jmp     LOBJTY2                  ; 6DAD  off to the common exit
LOBJTY1:
        mov     bx, OFFSET OBJKND        ; 6DB0  the "slot -> type and subtype" table
        mov     al, [bx+si]              ; 6DB3  AL -- type and subtype of the slot
        shr     al, 1                    ; 6DB5  shift 1 of two
        shr     al, 1                    ; 6DB7  the low two bits are the subtype, throw them away
        mov     OBJTYP, al               ; 6DB9  OBJTYP -- the object's type
LOBJTY2:
        RESTREG <bx,ax>                  ; 6DBC  macro
        ret                              ; 6DBE  return: the type is in OBJTYP

;-----------------------------------------------------------------------
; OBJKILL -- Take object SI off: clear its live flag and its bit in OBJTBL.
;
; ENTRY  : SI
; ALTERS : nothing
; CALLED BY: BEH_CLMB, PST_0
;-----------------------------------------------------------------------
OBJKILL:
        SAVEREG <ax,bx,cx,si>            ; 6DBF  macro
        mov     bx, OFFSET OBJVX         ; 6DC3  table of X speeds, one slot per object
        mov     BYTE PTR [bx+si], 0      ; 6DC6  the object is brought to a stop
        mov     bx, OFFSET OBJTBL        ; 6DC9  BX -- object table, object 0 is the player
        mov     ax, si                   ; 6DCC  AX -- object number
        mov     cl, 6                    ; 6DCE  CL=6 -- length of an object record
        mul     cl                       ; 6DD0  number * 6: records run six bytes apiece
        add     ax, 2                    ; 6DD2  field +2 of the record is X
        mov     si, ax                   ; 6DD5  SI -- offset of the field
        and     BYTE PTR [bx+si], 0FEh   ; 6DD7  bit 0 of X cleared: an even byte
        RESTREG <si,cx,bx,ax>            ; 6DDA  macro
        ret                              ; 6DDE  return: the object is off

;-----------------------------------------------------------------------
; HITCHK -- Player against object SI: |dY|/2 < 7 and |dX| < 4.
;
; ENTRY  : SI
; EXIT   : HITMSK
; ALTERS : nothing
; CALLED BY: ANIMHIT
;-----------------------------------------------------------------------
HITCHK:
        SAVEALL                          ; 6DDF  macro
        mov     bx, OFFSET OBJTBL        ; 6DE6  BX -- object 0, which is to say the player
        mov     ax, si                   ; 6DE9  AX -- object number
        mov     dl, 6                    ; 6DEB  record stride is 6 bytes
        mul     dl                       ; 6DED  number * 6
        mov     di, ax                   ; 6DEF  DI -- offset out to object SI
        mov     al, [bx+OB_Y]            ; 6DF1  the player's Y
        sub     al, [bx+di+OB_Y]         ; 6DF4  minus the object's Y
        cmp     al, 0                    ; 6DF7  is the difference negative?
        jge     LHITCH1                  ; 6DF9  no
        neg     al                       ; 6DFB  take the absolute value
LHITCH1:
        shr     al, 1                    ; 6DFD  bit 0 picks the field
        cmp     al, 7                    ; 6DFF  seven lines -- the vertical limit
        jge     LHITCH3                  ; 6E01  further off than that -- no collision
        mov     al, [bx+OB_X]            ; 6E03  the player's X
        sub     al, [bx+di+OB_X]         ; 6E06  minus the object's X
        cmp     al, 0                    ; 6E09  is the difference negative?
        jge     LHITCH2                  ; 6E0B  no
        neg     al                       ; 6E0D  take the absolute value
LHITCH2:
        cmp     al, 4                    ; 6E0F  four bytes -- the horizontal limit
        jl      LHITCH4                  ; 6E11  closer than that -- a collision
LHITCH3:
        RESTALL                          ; 6E13  macro
        ret                              ; 6E1A  return: no collision this time
LHITCH4:
        or      HITMSK, 1                ; 6E1B  bit 0 -- a collision did happen
        mov     ax, si                   ; 6E20  AX -- object number
        call    BIT                      ; 6E22  AL = 1 shl the object number
        or      HITMSK, al               ; 6E25  note down which object it was
        jmp     short LHITCH3            ; 6E29  off to the common exit

;-----------------------------------------------------------------------
; BIT -- AL = 1 shl AL. Bit number -> a mask.
;
; ENTRY  : AL
; EXIT   : AL
; ALTERS : nothing
; CALLED BY: HITCHK, MARKUSED, PLRHIT
;-----------------------------------------------------------------------
BIT:
        push    cx                       ; 6E2B  CX comes back at 6E39
        xor     ch, ch                   ; 6E2C  CH=0: the whole bit number now sits in CX
        mov     cl, al                   ; 6E2E  CL -- the bit number
        inc     cl                       ; 6E30  one shift more than the number
        xor     al, al                   ; 6E32  AL=0 -- an empty mask
        stc                              ; 6E34  CF=1 -- and that is the bit we want
LBIT1:
        rcl     al, 1                    ; 6E35  mask left, the carry into the low bit
        loop    LBIT1                    ; 6E37  the shifts are not used up
        pop     cx                       ; 6E39  CX restored
        ret                              ; 6E3A  return: the mask is in AL

;-----------------------------------------------------------------------
; ADDSCR -- Add points (BCD) and test for a bonus life.
;
; ENTRY  : DI = index into PTSTAB
; EXIT   : SCORE
; ALTERS : nothing
; CALLED BY: OPENDOOR, PLRHIT
;-----------------------------------------------------------------------
ADDSCR:
        SAVEALL                          ; 6E3B  macro
        mov     al, PTSTAB[di]           ; 6E42  low byte of the points, in BCD
        adc     al, SCORE2               ; 6E46  plus the low byte of the score
        daa                              ; 6E4A  the BCD fixup after the addition
        mov     SCORE2, al               ; 6E4B  low byte of the score
        mov     al, PTSTAB[di+1]         ; 6E4E  high byte of the points, in BCD
        adc     al, SCORE1               ; 6E52  plus the middle byte of the score, with the carry
        daa                              ; 6E56  the BCD fixup after the addition
        mov     SCORE1, al               ; 6E57  middle byte of the score
        jae     LADDSC2                  ; 6E5A  no carry out into the high byte
        mov     al, 0                    ; 6E5C  AL=0 -- only the carry gets added
        adc     al, SCORE                ; 6E5E  high byte of the score, with the carry
        daa                              ; 6E62  the BCD fixup after the addition
        mov     SCORE, al                ; 6E63  high byte of the score
        cmp     LEVEL, 5                 ; 6E66  level 5
        jl      LADDSC1                  ; 6E6B  below the fifth -- a life every time
        mov     al, SCORE                ; 6E6D  AL -- high byte of the score
        and     al, 1                    ; 6E70  the low BCD digit
        cmp     al, 0                    ; 6E72  is it even?
        jne     LADDSC2                  ; 6E74  odd -- no life this time
LADDSC1:
        call    XLIFE                    ; 6E76  the bonus life
LADDSC2:
        call    SHOWSCR                  ; 6E79  redraw the panel
        RESTALL                          ; 6E7C  macro
        ret                              ; 6E83  return: the points are credited

;-----------------------------------------------------------------------
; SHOWSCR -- Put the score out as digits into the SCRMAP status panel.
;
; ENTRY  : SCORE
; EXIT   : SCRMAP
; ALTERS : nothing
; CALLED BY: ADDSCR, AMULOFF (via JMP), DRAWFRM, PUTHUD
;-----------------------------------------------------------------------
SHOWSCR:
        SAVEALL                          ; 6E84  macro
        mov     bp, OFFSET SCRMAP        ; 6E8B  BP -- map base the primitives draw against
        mov     CMDX, 4Dh                ; 6E8E  4Dh -- cell of the score's lowest digit
        mov     CMDOP, 0                 ; 6E93  opcode 0: map page zero
        xor     si, si                   ; 6E98  SI -- index of the score's high byte
        mov     di, 2                    ; 6E9A  DI -- index of the score's low byte
LSHOWS1:
        mov     al, SCORE[si]            ; 6E9D  AL -- a byte of the score
        cmp     al, 0                    ; 6EA1  is it zero?
        jne     LSHOWS2                  ; 6EA3  not zero -- start printing from here
        inc     si                       ; 6EA5  on to the next byte
        cmp     si, 2                    ; 6EA6  the two high bytes may be skipped
        jne     LSHOWS1                  ; 6EA9  the bytes are not used up
LSHOWS2:
        mov     dx, si                   ; 6EAB  DX -- which byte to start printing from
LSHOWS3:
        push    di                       ; 6EAD  DI comes back at 6EBF
        mov     al, SCORE[di]            ; 6EAE  AL -- a byte of the score
        and     al, 0Fh                  ; 6EB2  the low BCD digit
        call    PUTITM                   ; 6EB4  the digit is out in the panel
        dec     CMDX                     ; 6EB7  shift 1 of two
        dec     CMDX                     ; 6EBB  one cell left: a digit takes two cells
        pop     di                       ; 6EBF  DI -- index of the byte
        push    di                       ; 6EC0  DI comes back at 6EDC
        mov     al, SCORE[di]            ; 6EC1  AL -- a byte of the score
        mov     cl, 4                    ; 6EC5  CL=4 -- shift by four places
        shr     al, cl                   ; 6EC7  the high BCD digit
        cmp     al, 0                    ; 6EC9  is it zero?
        jne     LSHOWS4                  ; 6ECB  not zero -- print it
        cmp     di, dx                   ; 6ECD  the most significant byte?
        je      LSHOWS5                  ; 6ECF  a leading zero is not printed
LSHOWS4:
        call    PUTITM                   ; 6ED1  the digit is out in the panel
        dec     CMDX                     ; 6ED4  shift 1 of two
        dec     CMDX                     ; 6ED8  one cell left: a digit takes two cells
LSHOWS5:
        pop     di                       ; 6EDC  DI -- index of the byte
        dec     di                       ; 6EDD  one byte to the left
        cmp     di, dx                   ; 6EDE  have we reached the most significant one?
        jge     LSHOWS3                  ; 6EE0  no -- keep printing
        mov     bp, OFFSET SCRMAP        ; 6EE2  BP -- map base the primitives draw against
        mov     CMDX, 34h                ; 6EE5  34h -- cell of the level number
        mov     al, LEVEL                ; 6EEA  AL -- the difficulty level
        call    PUTITM                   ; 6EED  the level digit is out in the panel
LSHOWS6:
        mov     CMDX, 29h                ; 6EF0  29h -- first cell of the inventory
        mov     di, 0                    ; 6EF5  DI -- inventory slot number
LSHOWS7:
        mov     dl, ITEMCNT              ; 6EF8  DL -- how many items are in the inventory
        xor     dh, dh                   ; 6EFC  DH=0: the whole count now sits in DX
        cmp     di, dx                   ; 6EFE  are they all out?
        je      LSHOWS8                  ; 6F00  they are
        shl     di, 1                    ; 6F02  slots run a word apiece
        mov     si, ITEMS[di]            ; 6F04  SI -- element code held in the slot
        mov     ELMCUR, si               ; 6F08  what to draw it from
        push    di                       ; 6F0C  DI comes back at 6F13
        call    ELMTILE                  ; 6F0D  DI -- the cell, AL -- the first tile
        call    PUT2X2                   ; 6F10  the icon is laid down as a 2x2 square
        pop     di                       ; 6F13  DI -- slot number, still doubled
        inc     CMDX                     ; 6F14  shift 1 of two
        inc     CMDX                     ; 6F18  one cell right: an icon takes two cells
        shr     di, 1                    ; 6F1C  DI -- the slot number
        inc     di                       ; 6F1E  on to the next slot
        jmp     short LSHOWS7            ; 6F1F  go and put the next icon out
LSHOWS8:
        cmp     di, 5                    ; 6F21  is the inventory full?
        je      LSHOWS9                  ; 6F24  full -- nothing left to blank
        mov     ax, di                   ; 6F26  AX -- how many slots are in use
        xor     al, 0FFh                 ; 6F28  two's complement...
        clc                              ; 6F2A  clear the carry ahead of the ADC
        adc     al, 6                    ; 6F2B  ...giving 6 minus the used ones: the free slots
        shl     al, 1                    ; 6F2D  two cells to a slot
        mov     di, ax                   ; 6F2F  DI -- width of the empty space
        dec     di                       ; 6F31  one cell less
        mov     ax, di                   ; 6F32  AX -- width of the empty space
        clc                              ; 6F34  clear the carry
        mov     cl, 4                    ; 6F35  CL=4 -- shift by four places
        rol     al, cl                   ; 6F37  width into the high four bits
        or      al, 1                    ; 6F39  column 1 into the low four
        mov     CMDP1, al                ; 6F3B  the packed rectangle parameters
        mov     al, 0                    ; 6F3E  AL=0 -- the "empty" tile
        call    CURSPOS                  ; 6F40  DI -- the cell, from CMDOP and CMDX
        call    PARMSPL                  ; 6F43  unpack the parameters and fill
LSHOWS9:
        mov     CMDX, 79h                ; 6F46  79h -- cell of the first row of lives
        mov     ax, 76h                  ; 6F4B  76h -- element of the life icon
        mov     ELMCUR, ax               ; 6F4E  what to draw it from
        mov     al, LIVES                ; 6F51  AL -- how many lives there are
        cmp     al, 0                    ; 6F54  none at all?
        je      LSHOWS12                 ; 6F56  nothing to draw
        shl     al, 1                    ; 6F58  two cells to an icon
        cmp     al, 0Bh                  ; 6F5A  0Bh = 11 cells -- the limit of the row
        jb      LSHOWS10                 ; 6F5C  it fits
        mov     al, 0Ah                  ; 6F5E  0Ah = 10 cells -- five icons
LSHOWS10:
        mov     CMDP1, al                ; 6F60  length of the icon strip
        call    PR_PATT                  ; 6F63  the first row of lives is out
        mov     al, LIVES                ; 6F66  AL -- how many lives there are
        cmp     al, 6                    ; 6F69  six or more -- a second row is needed
        jb      LSHOWS12                 ; 6F6B  one row was enough
        sub     al, 5                    ; 6F6D  five icons are drawn already
        cmp     al, 7                    ; 6F6F  seven or more in the second row
        jb      LSHOWS11                 ; 6F71  it fits
        mov     al, 6                    ; 6F73  six icons -- the limit of the second row
LSHOWS11:
        shl     al, 1                    ; 6F75  two cells to an icon
        mov     CMDP1, al                ; 6F77  length of the icon strip
        mov     CMDX, 93h                ; 6F7A  93h -- cell of the second row of lives
        mov     ax, 76h                  ; 6F7F  76h -- element of the life icon
        mov     ELMCUR, ax               ; 6F82  what to draw it from
        call    PR_PATT                  ; 6F85  the second row of lives is out
LSHOWS12:
        cmp     HUDFULL, 1               ; 6F88  is the panel being drawn whole?
        je      LSHOWS14                 ; 6F8D  whole -- the rectangles are not needed
        mov     cx, 2                    ; 6F8F  the two panel rectangles
LSHOWS13:
        push    cx                       ; 6F92  CX comes back at 6F9C
        mov     di, OFFSET HUDRCT        ; 6F93  DI -- the panel rectangles
        call    PUTRCT                   ; 6F96  put them out
        call    NOP0                     ; 6F99  empty routine: one of eight such calls in the image
        pop     cx                       ; 6F9C  CX -- how many are left
        loop    LSHOWS13                 ; 6F9D  put them out once again
LSHOWS14:
        RESTALL                          ; 6F9F  macro
        ret                              ; 6FA6  return: the panel has been redrawn

;-----------------------------------------------------------------------
; PUTITM -- Lay an item icon into the panel: code AL -> index into DIGELM
; -> element out of ELMTAB -> PUT2X2.
;
; ENTRY  : AL
; EXIT   : SCRMAP
; ALTERS : nothing
; CALLED BY: SHOWSCR
;-----------------------------------------------------------------------
PUTITM:
        SAVEALL                          ; 6FA7  macro
        xor     ah, ah                   ; 6FAE  AH=0: the whole code now sits in AX
        mov     si, ax                   ; 6FB0  SI -- the same code as an index
        mov     al, DIGELM[si]           ; 6FB2  AL -- offset of the digit's element
        mov     si, ax                   ; 6FB6  SI -- offset of the element within the ribbon
        mov     bx, OFFSET ELMTAB        ; 6FB8  BX -- head of the element ribbon
        call    CURSPOS                  ; 6FBB  DI -- the cell, from CMDOP and CMDX
        call    PUT2X2                   ; 6FBE  the icon is laid down as a 2x2 square
        RESTALL                          ; 6FC1  macro
        ret                              ; 6FC8  return: the icon is out

;-----------------------------------------------------------------------
; XLIFE -- A bonus life: LIVES+1 and sound 11.
;
; EXIT   : LIVES
; ALTERS : AX, BX, SI
; CALLED BY: ADDSCR
;-----------------------------------------------------------------------
XLIFE:
        inc     LIVES                    ; 6FC9  one more life
        mov     si, 0Bh                  ; 6FCD  SI=0Bh -- the bonus life sound
        call    PLAYSND                  ; 6FD0  play it if the priority lets it through
        ret                              ; 6FD3  return: the life is credited

;-----------------------------------------------------------------------
; PLRHIT -- Everything the player interacts with this frame: items,
; doors, enemies, death.
;
; ALTERS : nothing
; CALLED BY: ST_PL2, ST_PL3
;-----------------------------------------------------------------------
PLRHIT:
        SAVEALL                          ; 6FD4  macro
        mov     LITNOW, 0                ; 6FDB  the lighting-changed flag is cleared
        mov     al, PLRST                ; 6FE0  AL -- the player's state
        cmp     al, 7                    ; 6FE3  states 7..9 -- death
        jl      LPLRHI1                  ; 6FE5  still alive
        jmp     LPLRHI14                 ; 6FE7  state 7 or above -- no interactions at all
LPLRHI1:
        xor     ah, ah                   ; 6FEA  AH=0: the whole timer now sits in AX
        mov     al, ITMTMR               ; 6FEC  AL -- the amulet timer
        mov     si, ax                   ; 6FEF  SI -- the same value
        cmp     si, 0                    ; 6FF1  no amulet taken?
        je      LPLRHI2                  ; 6FF4  none taken
        dec     si                       ; 6FF6  SI -- the timer after decrementing
        dec     ITMTMR                   ; 6FF7  the amulet timer runs one step shorter
        cmp     si, 0                    ; 6FFB  has it run out?
        jne     LPLRHI2                  ; 6FFE  not yet
        call    AMULOFF                  ; 7000  the amulet's effect is over
LPLRHI2:
        mov     ax, PH71                 ; 7003  blink phase of floor 71h
        cmp     ax, 0                    ; 7006  is the floor there?
        je      LPLRHI3                  ; 7009  the floor is in place
        mov     al, TILEAT               ; 700B  AL -- the tile in the player's own cell
        xor     ah, ah                   ; 700E  AH=0: the whole tile now sits in AX
        cmp     ax, 71h                  ; 7010  71h -- the blinking floor
        jne     LPLRHI3                  ; 7013  not that one
        call    KILLPLR                  ; 7015  the floor blinked out under him -- death
        jmp     LPLRHI14                 ; 7018  the interactions are done
LPLRHI3:
        mov     di, 6                    ; 701B  DI=6 -- walk the elements from the end
LPLRHI4:
        xor     bh, bh                   ; 701E  BH=0: the whole code now sits in BX
        mov     bl, ITMELM[di]           ; 7020  BL -- code of an element that can be picked up
        mov     si, bx                   ; 7024  SI -- the same code
        call    ELMFIND                  ; 7026  is that element under the player
        jae     LPLRHI5                  ; 7029  CF=0 -- it is not
        jmp     LPLRHI19                 ; 702B  it is -- pick it up
LPLRHI5:
        dec     di                       ; 702E  on to the next code
        cmp     di, 0                    ; 702F  are the codes used up?
        jge     LPLRHI4                  ; 7032  not used up
LPLRHI6:
        mov     al, PLRST                ; 7034  AL -- the player's state
        and     al, 0Eh                  ; 7037  bits 3..1: states 0 and 1 mean he is on his feet
        cmp     al, 0                    ; 7039  no collisions took place
        jne     LPLRHI8                  ; 703B  not on his feet -- he cannot open a door
        mov     al, TILEDN               ; 703D  AL -- the tile underfoot
        xor     ah, ah                   ; 7040  AH=0: the whole tile now sits in AX
        cmp     ax, 0                    ; 7042  nothing underfoot?
        je      LPLRHI8                  ; 7045  nothing -- he cannot open a door
        mov     al, TILELF               ; 7047  AL -- the tile to the left
        mov     si, 3                    ; 704A  three tiles in the list
        mov     bp, OFFSET GATETIL       ; 704D  the door tiles
        call    INLIST                   ; 7050  is AL in the list
        jb      LPLRHI7                  ; 7053  CF=1 -- a door on the left
        mov     al, TILERT               ; 7055  AL -- the tile to the right
        mov     si, 3                    ; 7058  three tiles in the list
        mov     bp, OFFSET GATETIL       ; 705B  the door tiles
        call    INLIST                   ; 705E  is AL in the list
        jae     LPLRHI8                  ; 7061  CF=0 -- no door here
        push    ax                       ; 7063  AX comes back at 7067
        call    STANDCK                  ; 7064  is the player standing and facing right
        pop     ax                       ; 7067  AL -- the door tile
        jb      LPLRHI8                  ; 7068  CF=1 -- facing left, his back to the door
        call    USEITEM                  ; 706A  find a key and spend it
        jae     LPLRHI8                  ; 706D  CF=0 -- no key for it
        mov     al, 76h                  ; 706F  76h -- element of the door opened on the right
        call    OPENDOOR                 ; 7071  open the door
        jmp     LPLRHI14                 ; 7074  the interactions are done
LPLRHI7:
        push    ax                       ; 7077  AX comes back at 707B
        call    STANDCK                  ; 7078  is the player standing and facing right
        pop     ax                       ; 707B  AL -- the door tile
        jae     LPLRHI8                  ; 707C  CF=0 -- facing right, his back to the door
        call    USEITEM                  ; 707E  find a key and spend it
        jae     LPLRHI8                  ; 7081  CF=0 -- no key for it
        mov     al, 78h                  ; 7083  78h -- element of the door opened on the left
        call    OPENDOOR                 ; 7085  open the door
        jmp     LPLRHI14                 ; 7088  the interactions are done
LPLRHI8:
        mov     al, HITMSK               ; 708B  AL -- the frame's collision mask
        and     al, 1                    ; 708E  bit 0 -- was there a collision at all
        cmp     al, 0                    ; 7090  were there collisions?
        je      LPLRHI14                 ; 7092  there were none
        mov     al, ITMTMR               ; 7094  AL -- the amulet timer
        cmp     al, 0                    ; 7097  is the amulet still in force?
        jne     LPLRHI14                 ; 7099  in force -- the enemies cannot touch him
        mov     al, HITMSK               ; 709B  AL -- the frame's collision mask
        and     al, 0FEh                 ; 709E  clear bit 0: it is not about any one object
        mov     si, 7                    ; 70A0  SI=7 -- count the slots from the top down
        clc                              ; 70A3  clear the carry ahead of the RCL
LPLRHI9:
        rcl     al, 1                    ; 70A4  next bit out into the carry
        jb      LPLRHI11                 ; 70A6  bit set -- this is the one he ran into
LPLRHI10:
        dec     si                       ; 70A8  on to the next slot
        cmp     si, 0                    ; 70A9  are the slots used up?
        jge     LPLRHI9                  ; 70AC  slots not used up yet
        RESTALL                          ; 70AE  macro
        ret                              ; 70B5  return: there were no interactions
LPLRHI11:
        cmp     al, 0                    ; 70B6  are there no other collisions?
        je      LPLRHI12                 ; 70B8  none -- deal with this one
        call    NEARCHK                  ; 70BA  is the player close to object SI?
        jae     LPLRHI10                 ; 70BD  CF=0 -- too far off
LPLRHI12:
        mov     HITOBJ, si               ; 70BF  HITOBJ -- who he ran into
        call    OBJTYPE                  ; 70C3  OBJTYP -- the object's type
        mov     al, OBJTYP               ; 70C6  AL -- the object's type
        cmp     al, 1                    ; 70C9  type 1 -- the skull
        je      LPLRHI13                 ; 70CB  a skull is not taken with the sword
        call    USESWRD                  ; 70CD  try the sword
        jb      LPLRHI15                 ; 70D0  CF=1 -- the enemy went down to the sword
LPLRHI13:
        call    KILLPLR                  ; 70D2  no sword -- the player is the one killed
        jae     LPLRHI14                 ; 70D5  CF=0 -- the state was already 7 or above
        cmp     LEVEL, 5                 ; 70D7  level 5
        jl      LPLRHI17                 ; 70DC  below the fifth -- the dead enemy stays put
LPLRHI14:
        RESTALL                          ; 70DE  macro
        ret                              ; 70E5  return: the interactions are done
LPLRHI15:
        mov     si, 4                    ; 70E6  SI=4 -- the enemy-killed sound
        call    PLAYSND                  ; 70E9  play it if the priority lets it through
        mov     di, 0Ch                  ; 70EC  DI=0Ch -- points for a type 0 enemy
        mov     al, OBJTYP               ; 70EF  AL -- the object's type
        cmp     al, 0                    ; 70F2  type 0
        je      LPLRHI16                 ; 70F4  that is the one
        mov     di, 0Ah                  ; 70F6  DI=0Ah -- points for all the other enemies
LPLRHI16:
        call    ADDSCR                   ; 70F9  credit the points
LPLRHI17:
        mov     bp, OFFSET SEENMAP       ; 70FC  BP -- the seen map
        mov     si, HITOBJ               ; 70FF  SI -- who he ran into
        mov     al, OBJBIT[si]           ; 7103  AL -- bit number of the object
        cmp     al, 8                    ; 7107  bits 8 and up live in the second byte
        jl      LPLRHI18                 ; 7109  in the first
        inc     bp                       ; 710B  BP on to the second byte of the record
LPLRHI18:
        and     al, 7                    ; 710C  bit number within the byte
        call    BIT                      ; 710E  AL = 1 shl the bit number
        mov     si, HITOBJ               ; 7111  SI -- who he ran into
        mov     dl, ROOMRQ               ; 7115  DL -- number of the room on show
        xor     dh, dh                   ; 7119  DH=0: the whole number now sits in DX
        mov     di, dx                   ; 711B  DI -- the room number
        shl     di, 1                    ; 711D  entries run two bytes apiece
        or      ds:[bp+di], al           ; 711F  bit set: the object will not come back
        mov     ax, HITOBJ               ; 7122  AX -- object number
        call    BIT                      ; 7125  AL = 1 shl the object number
        mov     DEADBIT, al              ; 7128  bit of the killed object: its sprite still gets erased
        xor     INBITS, al               ; 712B  the object is taken off the screen
        mov     D_6CB1, 1                ; 712F  the flag is carried over from the image as it stands
        jmp     short LPLRHI14           ; 7134  the interactions are done
LPLRHI19:
        mov     dx, si                   ; 7136  DX -- code of the element found
        mov     LASTITM, dl              ; 7138  LASTITM -- what was picked up
        call    TAKEITM                  ; 713C  put the item into the inventory
        jb      LPLRHI20                 ; 713F  CF=1 -- it fitted
        jmp     LPLRHI6                  ; 7141  it did not fit -- go and deal with doors
LPLRHI20:
        cmp     si, ELM_AMUL             ; 7144  the amulet
        jne     LPLRHI21                 ; 7148  not the amulet
        mov     ITMTMR, 37h              ; 714A  37h = 55 steps of amulet protection
LPLRHI21:
        push    di                       ; 714F  DI comes back at 7157
        mov     di, ELMOFS               ; 7150  DI -- where the item was lying
        call    TAKEDRW                  ; 7154  wipe it off the map
        pop     di                       ; 7157  DI -- number of the element code
        shl     di, 1                    ; 7158  entries run two bytes apiece
        mov     di, ITMPTS[di]           ; 715A  DI -- offset of the points in PTSTAB
        call    ADDSCR                   ; 715E  credit the points
        mov     si, 7                    ; 7161  SI=7 -- the item pickup sound
        call    PLAYSND                  ; 7164  play it if the priority lets it through
        cmp     DARKF, 0                 ; 7167  is the room dark
        je      LPLRHI22                 ; 716C  it is lit
        mov     al, LASTITM              ; 716E  AL -- what was picked up
        xor     ah, ah                   ; 7171  AH=0: the whole code now sits in AX
        cmp     ax, 3Fh                  ; 7173  3Fh -- the torch
        jne     LPLRHI22                 ; 7176  not the torch
        mov     LITNOW, 1                ; 7178  a torch in the dark -- the lighting has changed
LPLRHI22:
        RESTALL                          ; 717D  macro
        ret                              ; 7184  return: the interactions are done

;-----------------------------------------------------------------------
; KILLPLR -- Kill the player: PLRST=7, animation AN_DIE, sound 6, timer 1Fh.
;
; EXIT   : CF
; ALTERS : nothing
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
KILLPLR:
        SAVEALL                          ; 7185  macro
        mov     al, PLRST                ; 718C  AL -- the player's state
        xor     ah, ah                   ; 718F  AH=0: the whole state now sits in AX
        cmp     ax, 7                    ; 7191  states 7..9 -- death
        jge     LKILLP1                  ; 7194  the state is already 7 or above
        mov     si, 6                    ; 7196  SI=6 -- the death sound
        call    PLAYSND                  ; 7199  play it if the priority lets it through
        mov     ax, 7                    ; 719C  AX=7
        mov     PLRST, al                ; 719F  state 7 -- death
        mov     OBJVX, 0                 ; 71A2  the player is brought to a stop
        mov     BYTE PTR OBJVY, 0        ; 71A7  the vertical speed is zeroed
        mov     ax, OFFSET AN_DIE        ; 71AC  frame chain for the death sequence
        mov     ANIMPTR, ax              ; 71AF  the player's frame chain is set
        mov     ax, 5                    ; 71B2  AX=5
        mov     ANIMLEN, ax              ; 71B5  six frames in the chain
        mov     OBJTMR2, 1Fh             ; 71B8  1Fh = 31 frames until the animation ends
        stc                              ; 71BD  CF=1 -- the player has been killed
        RESTALL                          ; 71BE  macro
        ret                              ; 71C5  return
LKILLP1:
        clc                              ; 71C6  CF=0 -- the state was already 7 or above
        RESTALL                          ; 71C7  macro
        ret                              ; 71CE  return

;-----------------------------------------------------------------------
; NEARCHK -- Is the player close to object SI: abs(dY)/2 < 12 and abs(dX) < 5.
;
; ENTRY  : SI
; EXIT   : CF
; ALTERS : CX, DX, DI
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
NEARCHK:
        SAVEREG <ax,si,bx>               ; 71CF  macro
        mov     bx, OFFSET OBJTBL        ; 71D2  BX -- object table, object 0 is the player
        mov     ax, si                   ; 71D5  AX -- object number
        mov     cl, 6                    ; 71D7  CL=6 -- length of an object record
        mul     cl                       ; 71D9  number * 6: records run six bytes apiece
        mov     di, ax                   ; 71DB  DI -- offset of the object record
        mov     al, [bx+di+OB_Y]         ; 71DD  AL -- the object's Y
        shr     al, 1                    ; 71E0  bit 0 picks the field
        mov     dl, al                   ; 71E2  DL -- row the object is on
        mov     al, [bx+OB_Y]            ; 71E4  AL -- the player's Y
        shr     al, 1                    ; 71E7  bit 0 picks the field
        sub     al, dl                   ; 71E9  difference of the rows
        jge     LNEARC1                  ; 71EB  not negative
        neg     al                       ; 71ED  take the absolute value
LNEARC1:
        cmp     al, 0Ch                  ; 71EF  0Ch = 12 rows -- the vertical limit
        jge     LNEARC3                  ; 71F1  further off than that -- not close
        mov     al, [bx+OB_X]            ; 71F3  AL -- the player's X
        mov     dl, al                   ; 71F6  DL -- the same value
        mov     al, [bx+di+OB_X]         ; 71F8  AL -- the object's X
        sub     al, dl                   ; 71FB  difference of the bytes
        jge     LNEARC2                  ; 71FD  not negative
        neg     al                       ; 71FF  take the absolute value
LNEARC2:
        cmp     al, 5                    ; 7201  five bytes -- the horizontal limit
        jge     LNEARC3                  ; 7203  further off than that -- not close
        stc                              ; 7205  CF=1 -- close enough
        jb      LNEARC4                  ; 7206  off to the common exit
LNEARC3:
        clc                              ; 7208  CF=0 -- not close
LNEARC4:
        RESTREG <bx,si,ax>               ; 7209  macro
        ret                              ; 720C  return: the answer is in CF

;-----------------------------------------------------------------------
; ELMFIND -- Find element SI under the player through ELMTAB; the offset
; goes into ELMOFS.
; ENTRY  : SI
; EXIT   : CF, ELMOFS
; ALTERS : nothing
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
ELMFIND:
        SAVEALL                          ; 720D  macro
        mov     di, MAPOFS               ; 7214  DI -- the player's cell within the map
        mov     al, TILEAT               ; 7218  AL -- the tile in the player's own cell
        cmp     al, ELMTAB[si]           ; 721B  first tile of the element
        je      LELMFI5                  ; 721F  that one -- the element is found
        cmp     al, ELMTAB[si+1]         ; 7221  second tile of the element
        je      LELMFI1                  ; 7225  that one -- he stands one cell to the right
        cmp     al, ELMTAB[si+2]         ; 7227  third tile of the element
        je      LELMFI4                  ; 722B  that one -- he stands one row lower
        cmp     al, ELMTAB[si+3]         ; 722D  fourth tile of the element
        je      LELMFI2                  ; 7231  that one -- he stands diagonally off it
        clc                              ; 7233  CF=0 -- no such element under the player
        RESTALL                          ; 7234  macro
        ret                              ; 723B  return
LELMFI1:
        inc     di                       ; 723C  DI one cell left -- back to the element's anchor
        jmp     LELMFI5                  ; 723D  off to the common exit
LELMFI2:
        mov     ax, 0FFD9h               ; 7240  FFD9h = -39: one row up and one cell left
LELMFI3:
        clc                              ; 7243  clear the carry ahead of the ADC
        adc     ax, di                   ; 7244  add it to the player's cell
        mov     di, ax                   ; 7246  DI -- the element's anchor
        jmp     LELMFI5                  ; 7248  off to the common exit
LELMFI4:
        mov     ax, 0FFD8h               ; 724B  FFD8h = -40: one row up
        jmp     short LELMFI3            ; 724E  add the offset and leave
LELMFI5:
        stc                              ; 7250  CF=1 -- the element is found
        mov     ELMOFS, di               ; 7251  ELMOFS -- where it lies
        RESTALL                          ; 7255  macro
        ret                              ; 725C  return

;-----------------------------------------------------------------------
; TAKEITM -- Put item SI into the inventory. More than 5 will not fit.
;
; ENTRY  : SI
; EXIT   : CF
; ALTERS : nothing
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
TAKEITM:
        SAVEREG <ax,si,di>               ; 725D  macro
        mov     al, ITEMCNT              ; 7260  how many we carry already
        cmp     al, 5                    ; 7263  the inventory holds five slots
        jge     LTAKEI5                  ; 7265  full -- it will not fit
        cmp     si, ELM_GEM              ; 7267  the gem
        je      LTAKEI3                  ; 726B  never goes in, only the points do
        cmp     si, ELM_SWRD             ; 726D  the sword
        jne     LTAKEI1                  ; 7271  not the sword
        mov     si, 3Bh                  ; 7273  3Bh -- code of the sword in the inventory
        jmp     LTAKEI2                  ; 7276  write the code into the slot
LTAKEI1:
        cmp     si, ELM_AMUL             ; 7279  the amulet
        jne     LTAKEI2                  ; 727D  not the amulet
        mov     si, 33h                  ; 727F  33h -- code of the amulet in the inventory
LTAKEI2:
        xor     ah, ah                   ; 7282  AH=0: the whole count now sits in AX
        mov     di, ax                   ; 7284  DI -- number of the free slot
        shl     di, 1                    ; 7286  slots run a word apiece
        mov     ITEMS[di], si            ; 7288  write the code into the slot
        inc     ITEMCNT                  ; 728C  one item more
LTAKEI3:
        stc                              ; 7290  CF = 1: taken
LTAKEI4:
        RESTREG <di,si,ax>               ; 7291  macro
        ret                              ; 7294  return
LTAKEI5:
        clc                              ; 7295  CF = 0: it did not fit
        jmp     short LTAKEI4            ; 7296  off to the common exit

;-----------------------------------------------------------------------
; USEITEM -- Find the item in the inventory that unlocks tile AL, and
; spend it.
;
; ENTRY  : AL
; EXIT   : CF
; ALTERS : nothing
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
USEITEM:
        SAVEALL                          ; 7298  macro
        xor     ah, ah                   ; 729F  AL -- tile code of the doorway
        cmp     ax, 0Fh                  ; 72A1  the green doorway
        jne     LUSEIT1                  ; 72A4  not the green one
        mov     ax, 3Bh                  ; 72A6  3Bh -- code of the sword, which is also the green key
        jmp     LUSEIT3                  ; 72A9  walk the inventory
LUSEIT1:
        cmp     ax, 16h                  ; 72AC  the red doorway
        jne     LUSEIT2                  ; 72AF  not the red one
        mov     ax, 3Fh                  ; 72B1  3Fh -- code of the torch, which is also the red key
        jmp     LUSEIT3                  ; 72B4  walk the inventory
LUSEIT2:
        mov     ax, 43h                  ; 72B7  otherwise the brown one: tile 43h
LUSEIT3:
        mov     bl, ITEMCNT              ; 72BA  walk the inventory
LUSEIT4:
        dec     bl                       ; 72BE  one slot fewer left
        jge     LUSEIT5                  ; 72C0  slots not used up yet
        clc                              ; 72C2  CF=0 -- no key that fits
        RESTALL                          ; 72C3  macro
        ret                              ; 72CA  return
LUSEIT5:
        xor     bh, bh                   ; 72CB  BH=0: the whole slot number now sits in BX
        mov     di, bx                   ; 72CD  DI -- the slot number
        shl     di, 1                    ; 72CF  slots run a word apiece
        mov     si, ITEMS[di]            ; 72D1  element code out of the slot
        shr     di, 1                    ; 72D5  DI -- the slot number
        mov     cl, ELMTAB[si]           ; 72D7  CL -- first tile of the element
        xor     ch, ch                   ; 72DB  CH=0: the whole tile now sits in CX
        cmp     ax, cx                   ; 72DD  does the key match the doorway
        jne     LUSEIT4                  ; 72DF  not this one -- look at the next slot
        call    DROPITM                  ; 72E1  the key is spent
        RESTALL                          ; 72E4  macro
        ret                              ; 72EB  return: CF=1 -- the doorway is open

;-----------------------------------------------------------------------
; DROPITM -- Remove the item at index DI, closing the inventory up behind it.
;
; ENTRY  : DI
; EXIT   : ITEMS
; ALTERS : nothing
; CALLED BY: AMULOFF, USEITEM, USESWRD
;-----------------------------------------------------------------------
DROPITM:
        SAVEALL                          ; 72EC  macro
        dec     ITEMCNT                  ; 72F3  one item fewer
        mov     bl, ITEMCNT              ; 72F7  BL -- how many are left
        xor     bh, bh                   ; 72FB  BH=0: the whole count now sits in BX
LDROPI1:
        cmp     di, bx                   ; 72FD  have we reached the last slot?
        je      LDROPI2                  ; 72FF  we have -- nothing left to close up
        shl     di, 1                    ; 7301  slots run a word apiece
        mov     ax, ITEMS[di+2]          ; 7303  code out of the next slot
        mov     ITEMS[di], ax            ; 7307  move it down into the current one
        shr     di, 1                    ; 730B  DI -- the slot number
        inc     di                       ; 730D  on to the next slot
        jmp     short LDROPI1            ; 730E  keep closing up
LDROPI2:
        stc                              ; 7310  CF=1 -- the item is gone
        RESTALL                          ; 7311  macro
        ret                              ; 7318  return

;-----------------------------------------------------------------------
; USESWRD -- Is there a sword (3Bh)? If so, spend it.
;
; EXIT   : CF
; ALTERS : BX, CX, DX, BP
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
USESWRD:
        SAVEREG <ax,si,di>               ; 7319  macro
        mov     al, ITEMCNT              ; 731C  AL -- how many we carry
        xor     ah, ah                   ; 731F  AH=0: the whole count now sits in AX
        mov     di, ax                   ; 7321  DI -- the slot number
LUSESW1:
        dec     di                       ; 7323  one slot fewer left
        jl      LUSESW2                  ; 7324  slots used up -- there is no sword
        shl     di, 1                    ; 7326  slots run a word apiece
        mov     si, ITEMS[di]            ; 7328  SI -- element code out of the slot
        shr     di, 1                    ; 732C  DI -- the slot number
        cmp     si, ELM_SWRDI            ; 732E  3Bh -- code of the sword in the inventory
        jne     LUSESW1                  ; 7332  not the sword -- look at the next slot
        stc                              ; 7334  CF=1 -- there is a sword
        call    DROPITM                  ; 7335  the sword is spent
        jmp     LUSESW3                  ; 7338  off to the common exit
LUSESW2:
        clc                              ; 733B  CF=0 -- no sword
LUSESW3:
        RESTREG <di,si,ax>               ; 733C  macro
        ret                              ; 733F  return: the answer is in CF

;-----------------------------------------------------------------------
; AMULOFF -- The invulnerability is over: throw every amulet (33h) out
; of the inventory and redraw.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
AMULOFF:
        SAVEALL                          ; 7340  macro
LAMULO1:
        mov     al, ITEMCNT              ; 7347  AL -- how many we carry
        xor     ah, ah                   ; 734A  AH=0: the whole count now sits in AX
        mov     di, ax                   ; 734C  DI -- the slot number
LAMULO2:
        dec     di                       ; 734E  one slot fewer left
        jl      LAMULO3                  ; 734F  slots used up -- no amulets left
        shl     di, 1                    ; 7351  slots run a word apiece
        mov     si, ITEMS[di]            ; 7353  SI -- element code out of the slot
        shr     di, 1                    ; 7357  DI -- the slot number
        cmp     si, ELM_AMULI            ; 7359  33h -- code of the amulet in the inventory
        jne     LAMULO2                  ; 735D  not the amulet -- look at the next slot
        call    DROPITM                  ; 735F  the amulet is thrown out
        jmp     short LAMULO1            ; 7362  go and look for the next amulet
LAMULO3:
        mov     bp, OFFSET SCRMAP        ; 7364  BP -- map base the primitives draw against
        jmp     LSHOWS6                  ; 7367  redraw the inventory in the panel

;-----------------------------------------------------------------------
; RETALL -- Restore the registers and return. Nothing refers to it.
; ALTERS : nothing
;-----------------------------------------------------------------------
RETALL:
        RESTALL                          ; 736A  macro
        ret                              ; 7371  return

;-----------------------------------------------------------------------
; OPENDOOR -- Open doorway AL: mark it used up, wipe it off the map,
; credit 300 points and play sound 5.
;
; ENTRY  : AL
; ALTERS : nothing
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
OPENDOOR:
        SAVEALL                          ; 7372  macro
        mov     di, MAPOFS               ; 7379  DI -- the player's cell within the map
        sub     di, ax                   ; 737D  minus the offset back to the doorway's anchor
        mov     ELMOFS, di               ; 737F  ELMOFS -- where the doorway lies
        call    MARKUSED                 ; 7383  mark the doorway as used up
        call    OFS2RC                   ; 7386  offset -> row and column
        mov     RCTH, 4                  ; 7389  the rectangle is 4 cells tall
        mov     RCTW, 3                  ; 738F  the rectangle is 3 cells wide
        mov     al, ROOMKND[si]          ; 7395  AL -- what the object is made of
        xor     ah, ah                   ; 7399  AH=0: the whole offset now sits in AX
        mov     ELMCUR, ax               ; 739B  what to draw it from
        mov     ax, ELMOFS               ; 739E  AX -- offset of the doorway within the map
        mov     CMDX, al                 ; 73A1  the low byte is the column
        clc                              ; 73A4  clear the carry ahead of the RCR
        rcr     ah, 1                    ; 73A5  shift 1 of three
        rcr     ah, 1                    ; 73A7  shift 2 of three
        rcr     ah, 1                    ; 73A9  high byte down by three places
        mov     CMDOP, ah                ; 73AB  opcode: bits 7..6 are the map page
        mov     di, OFFSET SCRMAP        ; 73AF  DI -- start of the screen map
        add     di, ELMOFS               ; 73B2  DI -- the doorway's cell within the map
        mov     bx, OFFSET ELMTAB        ; 73B6  BX -- head of the element ribbon
        call    PUTGRID                  ; 73B9  a 3x3 grille goes where the doorway was
        mov     di, 6                    ; 73BC  DI=6 -- points for an opened door
        call    ADDSCR                   ; 73BF  credit the points
        mov     si, 5                    ; 73C2  SI=5 -- the door-opened sound
        call    PLAYSND                  ; 73C5  play it if the priority lets it through
        call    RCTSHOW                  ; 73C8  redraw the doorway's rectangle
        RESTALL                          ; 73CB  macro
        ret                              ; 73D2  return: the door is open

;-----------------------------------------------------------------------
; TAKEDRW -- Wipe the item just picked up off the map and redraw the 2x2.
;
; ENTRY  : DI
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: PLRHIT
;-----------------------------------------------------------------------
TAKEDRW:
        call    MARKUSED                 ; 73D3  mark the item as used up
        call    OFS2RC                   ; 73D6  offset -> row and column
        mov     RCTH, 2                  ; 73D9  the rectangle is 2 cells tall
        mov     RCTW, 2                  ; 73DF  the rectangle is 2 cells wide
        mov     ax, 0                    ; 73E5  AX=0 -- the "empty" tile
        mov     cx, 2                    ; 73E8  width 2 cells
        mov     dl, 1                    ; 73EB  height DL+1 = 2 cells
        mov     di, ELMOFS               ; 73ED  DI -- where the item was lying
        add     di, OFFSET SCRMAP        ; 73F1  plus the start of the map
        call    FILLRC                   ; 73F5  the item's place is flooded with emptiness

;-----------------------------------------------------------------------
; RCTSHOW -- Send RCTREC off to PUTRCT.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: OPENDOOR, ST_PL2, ST_PL3, TAKEDRW (falls through)
;-----------------------------------------------------------------------
RCTSHOW:
        mov     di, OFFSET RCTREC        ; 73F8  DI -- the rectangle built up so far
        call    PUTRCT                   ; 73FB  put it out
LRCTSH1:
        ret                              ; 73FE  return

;-----------------------------------------------------------------------
; MARKUSED -- Mark the object as used up in the SEENMAP of the current
; room.
;
; ENTRY  : DI
; EXIT   : SEENMAP
; ALTERS : AX, CX, SI, DI
; CALLED BY: OPENDOOR, TAKEDRW
;-----------------------------------------------------------------------
MARKUSED:
        mov     al, ROOMOBN              ; 73FF  AL -- how many objects are in the room
        xor     ah, ah                   ; 7402  AH=0: the whole count now sits in AX
        mov     si, ax                   ; 7404  SI -- the same value
        shl     si, 1                    ; 7406  entries run two bytes apiece
LMARKU1:
        dec     si                       ; 7408  step 1 of two: entries run a word apiece
        dec     si                       ; 7409  SI on to the previous entry
        jl      LRCTSH1                  ; 740A  entries used up -- the object was not found
        mov     ax, ROOMOBJ[si]          ; 740C  AX -- offset of the object within the map
        cmp     di, ax                   ; 7410  is this the very place?
        jne     LMARKU1                  ; 7412  no -- look at the previous one
        shr     si, 1                    ; 7414  SI -- the object number
        mov     al, ROOMRQ               ; 7416  AL -- number of the room on show
        xor     ah, ah                   ; 7419  AH=0: the whole number now sits in AX
        mov     di, ax                   ; 741B  DI -- the room number
        shl     di, 1                    ; 741D  entries run two bytes apiece
        mov     ax, si                   ; 741F  AX -- the object number
        cmp     si, 8                    ; 7421  bits 8 and up live in the second byte
        jl      LMARKU2                  ; 7424  in the first
        inc     di                       ; 7426  DI on to the second byte of the record
        and     al, 7                    ; 7427  bit number within the byte
LMARKU2:
        call    BIT                      ; 7429  AL = 1 shl the bit number
        or      al, BYTE PTR SEENMAP[di] ; 742C  fold it in with what was collected before
        mov     BYTE PTR SEENMAP[di], al ; 7430  bit set: the object will not come back
        shl     si, 1                    ; 7434  entries run two bytes apiece
        xor     ax, ax                   ; 7436  AX=0
        mov     ROOMOBJ[si], ax          ; 7438  the object's offset within the map is cleared
        shr     si, 1                    ; 743C  SI -- the object number
        ret                              ; 743E  return: the object is marked

;-----------------------------------------------------------------------
; OFS2RC -- Offset within SCRMAP -> row and column in RCTREC.
;
; ENTRY  : ELMOFS
; EXIT   : RCTREC
; ALTERS : AX, BX
; CALLED BY: OPENDOOR, TAKEDRW
;-----------------------------------------------------------------------
OFS2RC:
        mov     ax, ELMOFS               ; 743F  AX -- the offset within the map
        mov     bl, MAP_W                ; 7442  the divisor: columns in one map row
        div     bl                       ; 7444  AL -- the row, AH -- the column
        xor     bh, bh                   ; 7446  BH=0
        mov     bl, ah                   ; 7448  BL -- the column
        xor     ah, ah                   ; 744A  AH=0: the whole row now sits in AX
        mov     RCTREC, ax               ; 744C  entry field +0: row
        mov     RCTCOL, bx               ; 744F  entry field +2: column
        ret                              ; 7453  return: the rectangle is set up

;-----------------------------------------------------------------------
; SETBKGD -- Background and border color from BL, through the BIOS. Nothing refers to it.
;
; ENTRY  : BL
; ALTERS : nothing
;-----------------------------------------------------------------------
SETBKGD:
        push    ax                       ; 7454  AX comes back at 745D
        push    bx                       ; 7455  BX comes back at 745C
        mov     ah, 0Bh                  ; 7456  AH=0Bh: the "set palette" call
        mov     bh, 0                    ; 7458  BH=0: the background and border color
        int     10h                      ; 745A  video BIOS
        pop     bx                       ; 745C  BX restored
        pop     ax                       ; 745D  AX restored
        ret                              ; 745E  return: the background color is set

;-----------------------------------------------------------------------
; PUTBAR -- Lay the "GAME OVER" sign down: two rows of 12h bytes out of
; BARTIL into SCRMAP+1EBh, that is, map rows 12 and 13 from column 11.
; The ADD DI,16h between the rows carries the pointer out to the map width.
;
; EXIT   : SCRMAP
; ALTERS : nothing
; CALLED BY: ST_X7
;-----------------------------------------------------------------------
PUTBAR:
        SAVEALL                          ; 745F  macro
        mov     di, OFFSET SCRMAP        ; 7466  DI -- start of the screen map
        add     di, 1EBh                 ; 7469  1EBh = row 12, column 11
        mov     si, OFFSET BARTIL        ; 746D  SI -- the tiles of the GAME OVER sign
        cld                              ; 7470  MOVSB will run forward
        mov     cx, 12h                  ; 7471  12h = 18 cells
        rep movsb                        ; 7474  the top row of the sign is down in the map
        add     di, 16h                  ; 7476  16h = 22: carry over to the row below
        mov     cx, 12h                  ; 7479  12h = 18 cells
        rep movsb                        ; 747C  the bottom row of the sign is down in the map
        RESTALL                          ; 747E  macro
        ret                              ; 7485  return: the sign is laid down

CSEG    ENDS
        END
