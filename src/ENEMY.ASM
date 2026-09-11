        PAGE  60,132
        TITLE ENEMY -- OBJECT TURNS AND THE FOUR BEHAVIORS
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC ENEMOVE
        PUBLIC HITOBJ
        EXTRN  ANIMPTR:WORD
        EXTRN  AN_ENMYL:WORD
        EXTRN  AN_ENMYR:WORD
        EXTRN  FRAMEC:BYTE
        EXTRN  INBITS:BYTE
        EXTRN  INLIST:NEAR
        EXTRN  OBJKILL:NEAR
        EXTRN  OBJKND:BYTE
        EXTRN  OBJMOVE:NEAR
        EXTRN  OBJTBL:WORD
        EXTRN  OBJTMR2:BYTE
        EXTRN  OBJTYP:BYTE
        EXTRN  OBJTYPE:NEAR
        EXTRN  OBJVX:BYTE
        EXTRN  OBJVY:WORD
        EXTRN  RNDSEED:BYTE
        EXTRN  SCANTIL:NEAR
        EXTRN  TILEAT:BYTE
        EXTRN  TILEDN:BYTE
        EXTRN  TILELF:BYTE
        EXTRN  TILERT:BYTE

;=======================================================================
; ENEMY.ASM -- OBJECT TURNS AND THE FOUR BEHAVIORS
;
; HITOBJ, the jump arc, the turn-around tiles, the behavior table and
; four handlers: motionless, walking, jumping, climbing.
;=======================================================================

;-----------------------------------------------------------------------
; THE OBJECT PASS  (7490..74B1, 34 bytes)
;
; 7490  HITOBJ -- index of the object the player ran into
;-----------------------------------------------------------------------
; index of the object the player ran into
HITOBJ  DW    0                          ; 7490
; jump arc: index 0..14h, the last value already sits in VXRIGHT
JUMPARC DB    0F7h,0F8h,0FCh,0FCh,0FEh,0FEh,0FEh,0FFh,0FFh,00h,00h,01h,01h,02h,02h,02h ; 7492
        DB    04h,04h,08h,09h                                                          ; 74A2  ....
; object subtype -> speed to the right
VXRIGHT DB    01h,00h,02h,00h            ; 74A6
; object subtype -> speed to the left
VXLEFT  DB    0FFh,00h,0FEh,00h          ; 74AA
; tiles an object turns around at: floor and the three doorways
TURNTIL DB    01h,0Fh,16h,1Dh            ; 74AE

;-----------------------------------------------------------------------
; ENEMOVE -- Object turns: every other frame it walks the INBITS bits
; and calls the behavior handler out of BEHTAB.
;
; ENTRY  : FRAMEC, INBITS
; ALTERS : nothing
; CALLED BY: ST_PL1, ST_PL2
;-----------------------------------------------------------------------
ENEMOVE:
        SAVEALL                          ; 74B2  macro
        mov     al, FRAMEC               ; 74B9  AL -- the frame counter
        and     al, 1                    ; 74BC  bit 0: objects move every other frame
        je      LENEMO3                  ; 74BE  even frame -- no turn this time
        mov     al, INBITS               ; 74C0  AL -- one bit per live object
        mov     si, 7                    ; 74C3  seven bits: the player does not count here
LENEMO1:
        rcl     al, 1                    ; 74C6  next bit out into the carry
        jb      LENEMO4                  ; 74C8  bit set -- the object is live
LENEMO2:
        dec     si                       ; 74CA  on to the next object
        jg      LENEMO1                  ; 74CB  slots not used up yet
LENEMO3:
        RESTALL                          ; 74CD  macro
        ret                              ; 74D4  return: every object has had its turn
LENEMO4:
        SAVEREG <ax,si>                  ; 74D5  macro
        mov     HITOBJ, si               ; 74D7  HITOBJ -- whose turn it is, the behaviors read it
        call    OBJTYPE                  ; 74DB  OBJTYP -- type of the object in SI
        mov     al, OBJTYP               ; 74DE  AL -- object type
        xor     ah, ah                   ; 74E1  AH=0: the whole type now sits in AX
        mov     di, ax                   ; 74E3  DI -- object type
        shl     di, 1                    ; 74E5  entries run two bytes apiece
        mov     bx, OFFSET BEHTAB        ; 74E7  table of the four behaviors
        mov     cx, cs:[bx+di]           ; 74EA  CX -- address of the behavior
        call    cx                       ; 74ED  run the behavior
        RESTREG <si,ax>                  ; 74EF  macro
        jmp     short LENEMO2            ; 74F1  on to the next object

;-----------------------------------------------------------------------
; OBJECT BEHAVIOR TABLE  (74F3..74FA, 8 bytes)
;
; Index is OBJTYP. Four entries carry meaning, past them is rubbish:
; the dispatcher at 74EDh only ever calls types 0..3.
;-----------------------------------------------------------------------
; object behavior table: 4 words indexed by OBJTYP
BEHTAB  LABEL WORD                       ; 74F3
        DW    BEH_CLMB                   ; 74F3  type 0
        DW    BEH_NONE                   ; 74F5  type 1
        DW    BEH_WALK                   ; 74F7  type 2
        DW    BEH_JUMP                   ; 74F9  type 3

;-----------------------------------------------------------------------
; BEH_NONE -- Behavior 1: the object never moves. One RET instruction.
;
; ALTERS : nothing
; CALLED BY: BEHTAB[1]
;-----------------------------------------------------------------------
BEH_NONE:
        ret                              ; 74FB  return: a motionless object takes no turn

;-----------------------------------------------------------------------
; BEH_JUMP -- Behavior 3: jumping. The OBJTMR2 timer runs an index 0..14h
; along JUMPARC, which is where the vertical speed comes from. Turns around at a wall.
;
; ENTRY  : HITOBJ
; EXIT   : OBJVY
; ALTERS : nothing
; CALLED BY: BEHTAB[3]
;-----------------------------------------------------------------------
BEH_JUMP:
        SAVEALL                          ; 74FC  macro
        mov     bx, OFFSET OBJTMR2       ; 7503  table of the objects' second timers
        mov     si, HITOBJ               ; 7506  SI -- whose turn it is
        mov     al, [bx+si]              ; 750A  AL -- phase of the jump
        inc     BYTE PTR [bx+si]         ; 750C  phase one step on
        cmp     BYTE PTR [bx+si], 15h    ; 750E  15h = 21 -- length of the jump arc
        jl      LBEHJU1                  ; 7511  the arc is not finished
        mov     BYTE PTR [bx+si], 1      ; 7513  the arc starts over, from phase 1
        xor     al, al                   ; 7516  AL=0 -- head of the arc
LBEHJU1:
        xor     ah, ah                   ; 7518  AH=0: the whole phase now sits in AX
        mov     di, ax                   ; 751A  DI -- phase of the jump
        mov     al, JUMPARC[di]          ; 751C  AL -- Y speed at this phase
        mov     BYTE PTR OBJVY[si], al   ; 7520  the slot's speed is set
        mov     al, OBJKND[si]           ; 7524  AL -- type and subtype of the slot
        and     al, 2                    ; 7528  bit 1 of the subtype -- double step along the arc
        je      LBEHJU2                  ; 752A  clear -- single step
        mov     al, [bx+si]              ; 752C  AL -- the next phase
        inc     BYTE PTR [bx+si]         ; 752E  phase one step on
        xor     ah, ah                   ; 7530  AH=0: the whole phase now sits in AX
        mov     di, ax                   ; 7532  DI -- phase of the jump
        mov     al, JUMPARC[di]          ; 7534  AL -- Y speed at this phase
        add     BYTE PTR OBJVY[si], al   ; 7538  two phases of the arc in one frame
LBEHJU2:
        cmp     di, 4                    ; 753C  phases 0..3 -- going up
        jl      LBEHJU3                  ; 753F  phases 0..3 -- going up
        cmp     di, 0Eh                  ; 7541  0Eh = 14: phases 4..13 -- in flight
        jl      LBEHJU4                  ; 7544  no turning around in mid-flight
LBEHJU3:
        push    si                       ; 7546  SI comes back at 7554
        mov     al, TILELF[si]           ; 7547  AL -- the tile to the left
        mov     si, 4                    ; 754B  four tiles in the list
        mov     bp, OFFSET TURNTIL       ; 754E  the tiles they turn around at
        call    INLIST                   ; 7551  is AL in the list
        pop     si                       ; 7554  SI -- whose turn it is
        jb      LBEHJU7                  ; 7555  CF=1 -- a wall on the left
        push    si                       ; 7557  SI comes back at 7565
        mov     al, TILERT[si]           ; 7558  AL -- the tile to the right
        mov     si, 4                    ; 755C  four tiles in the list
        mov     bp, OFFSET TURNTIL       ; 755F  the tiles they turn around at
        call    INLIST                   ; 7562  is AL in the list
        pop     si                       ; 7565  SI -- whose turn it is
        jb      LBEHJU10                 ; 7566  CF=1 -- a wall on the right
LBEHJU4:
        mov     bx, OFFSET OBJTBL        ; 7568  BX -- object table
        mov     ax, si                   ; 756B  AX -- object number
        mov     cl, 6                    ; 756D  CL=6 -- length of an object record
        mul     cl                       ; 756F  number * 6: records run six bytes apiece
        mov     di, ax                   ; 7571  DI -- offset of the record
        mov     cl, [bx+di+OB_X]         ; 7573  CL -- object's X in bytes
        cmp     cl, 3                    ; 7576  left of byte three -- the edge of the room
        jle     LBEHJU9                  ; 7579  further left -- the edge of the room
        cmp     BYTE PTR [bx+di+OB_X], 4Ah  ; 757B  4Ah = 74 -- right edge of the room
        jge     LBEHJU9                  ; 757F  past the edge -- turn around
LBEHJU5:
        mov     al, OBJVX[si]            ; 7581  AL -- speed along X
LBEHJU6:
        mov     ah, 0                    ; 7585  AH=0 -- move along the X axis
        call    OBJMOVE                  ; 7587  shift the object along X
        mov     al, BYTE PTR OBJVY[si]   ; 758A  AL -- speed along Y
        mov     ah, 1                    ; 758E  AH=1 -- move along the Y axis
        call    OBJMOVE                  ; 7590  shift the object along Y
        RESTALL                          ; 7593  macro
        ret                              ; 759A  return: the object has taken its turn
LBEHJU7:
        mov     al, TILELF[si]           ; 759B  AL -- the tile to the left
        cmp     al, TILERT[si]           ; 759F  the same one on the right?
        je      LBEHJU5                  ; 75A3  walled in on both sides -- no turning around
LBEHJU8:
        mov     al, OBJKND[si]           ; 75A5  AL -- type and subtype of the slot
        and     al, 3                    ; 75A9  the low two bits are the subtype
        xor     ah, ah                   ; 75AB  AH=0: the whole subtype now sits in AX
        mov     di, ax                   ; 75AD  DI -- object subtype
        mov     al, VXRIGHT[di]          ; 75AF  AL -- rightward speed for this subtype
        mov     OBJVX[si], al            ; 75B3  the object is off to the right
        jmp     short LBEHJU6            ; 75B7  move the object
LBEHJU9:
        cmp     OBJVX[si], 0             ; 75B9  is the X speed negative?
        jl      LBEHJU8                  ; 75BE  heading left -- turn it around to the right
        jmp     LBEHJU11                 ; 75C0  heading right -- turn it around to the left
LBEHJU10:
        mov     al, TILERT[si]           ; 75C3  AL -- the tile to the right
        cmp     al, TILELF[si]           ; 75C7  the same one on the left?
        je      LBEHJU5                  ; 75CB  walled in on both sides -- no turning around
LBEHJU11:
        mov     al, OBJKND[si]           ; 75CD  AL -- type and subtype of the slot
        and     al, 3                    ; 75D1  the low two bits are the subtype
        xor     ah, ah                   ; 75D3  AH=0: the whole subtype now sits in AX
        mov     di, ax                   ; 75D5  DI -- object subtype
        mov     al, VXLEFT[di]           ; 75D7  AL -- leftward speed for this subtype
        mov     OBJVX[si], al            ; 75DB  the object is off to the left
        jmp     short LBEHJU6            ; 75DF  move the object

;-----------------------------------------------------------------------
; BEH_WALK -- Behavior 2: walks left and right. Turns around on TURNTIL
; to either side, and at the edge of a platform -- when TILEDN is empty.
;
; ENTRY  : HITOBJ
; EXIT   : OBJVX
; ALTERS : nothing
; CALLED BY: BEHTAB[2], BEH_CLMB (via JMP)
;-----------------------------------------------------------------------
BEH_WALK:
        SAVEALL                          ; 75E1  macro
LBEHWA1:
        mov     si, HITOBJ               ; 75E8  SI -- whose turn it is
        mov     al, TILELF[si]           ; 75EC  AL -- the tile to the left
        push    si                       ; 75F0  SI comes back at 75FA
        mov     si, 4                    ; 75F1  four tiles in the list
        mov     bp, OFFSET TURNTIL       ; 75F4  the tiles they turn around at
        call    INLIST                   ; 75F7  is AL in the list
        pop     si                       ; 75FA  SI -- whose turn it is
        jb      LBEHWA3                  ; 75FB  CF=1 -- a wall on the left
        push    si                       ; 75FD  SI comes back at 7608
        mov     al, TILERT[si]           ; 75FE  AL -- the tile to the right
        mov     si, 4                    ; 7602  four tiles in the list
        call    INLIST                   ; 7605  BP is still good from the last call
        pop     si                       ; 7608  SI -- whose turn it is
        jb      LBEHWA6                  ; 7609  CF=1 -- a wall on the right
        mov     bx, OFFSET OBJTBL        ; 760B  BX -- object table
        mov     ax, si                   ; 760E  AX -- object number
        mov     cl, 6                    ; 7610  CL=6 -- length of an object record
        mul     cl                       ; 7612  number * 6: records run six bytes apiece
        mov     di, ax                   ; 7614  DI -- offset of the record
        mov     al, [bx+di+OB_X]         ; 7616  AL -- object's X in bytes
        cmp     al, 1                    ; 7619  left of byte two -- the edge of the room
        jle     LBEHWA5                  ; 761B  further left -- the edge of the room
        cmp     al, 4Ah                  ; 761D  4Ah = 74 -- right edge of the room
        jge     LBEHWA5                  ; 761F  past the edge -- turn around
        mov     al, TILEDN[si]           ; 7621  AL -- the tile underfoot
        xor     ah, ah                   ; 7625  AH=0: the whole tile now sits in AX
        cmp     ax, 0                    ; 7627  nothing underfoot?
        je      LBEHWA5                  ; 762A  edge of the platform -- turn around
        mov     al, OBJVX[si]            ; 762C  AL -- speed along X
LBEHWA2:
        mov     ah, 0                    ; 7630  AH=0 -- move along the X axis
        call    OBJMOVE                  ; 7632  shift the object along X
        RESTALL                          ; 7635  macro
        ret                              ; 763C  return: the object has taken its turn
LBEHWA3:
        cmp     OBJTYP, 0                ; 763D  type 0 -- a climbing object
        je      LBEHWA4                  ; 7642  it has no frame chain of its own
        mov     ax, OFFSET AN_ENMYL      ; 7644  frame chain for "walking left"
        shl     si, 1                    ; 7647  ANIMPTR slots run a word apiece
        mov     ANIMPTR[si], ax          ; 7649  the slot has its new chain
        shr     si, 1                    ; 764D  SI is the slot number once again
LBEHWA4:
        mov     al, OBJKND[si]           ; 764F  AL -- type and subtype of the slot
        and     al, 3                    ; 7653  the low two bits are the subtype
        xor     ah, ah                   ; 7655  AH=0: the whole subtype now sits in AX
        mov     di, ax                   ; 7657  DI -- object subtype
        mov     al, VXRIGHT[di]          ; 7659  AL -- rightward speed for this subtype
        mov     OBJVX[si], al            ; 765D  the object is off to the right
        jmp     short LBEHWA2            ; 7661  move the object
LBEHWA5:
        cmp     OBJVX[si], 0             ; 7663  is the X speed negative?
        jl      LBEHWA3                  ; 7668  heading left -- turn it around to the right
LBEHWA6:
        cmp     OBJTYP, 0                ; 766A  type 0 -- a climbing object
        je      LBEHWA7                  ; 766F  it has no frame chain of its own
        mov     ax, OFFSET AN_ENMYR      ; 7671  frame chain for "walking right"
        shl     si, 1                    ; 7674  ANIMPTR slots run a word apiece
        mov     ANIMPTR[si], ax          ; 7676  the slot has its new chain
        shr     si, 1                    ; 767A  SI is the slot number once again
LBEHWA7:
        mov     al, OBJKND[si]           ; 767C  AL -- type and subtype of the slot
        and     al, 3                    ; 7680  the low two bits are the subtype
        xor     ah, ah                   ; 7682  AH=0: the whole subtype now sits in AX
        mov     di, ax                   ; 7684  DI -- object subtype
        mov     al, VXLEFT[di]           ; 7686  AL -- leftward speed for this subtype
        mov     OBJVX[si], al            ; 768A  the object is off to the left
        jmp     short LBEHWA2            ; 768E  move the object

;-----------------------------------------------------------------------
; BEH_CLMB -- Behavior 0: the same walking, but the object can climb a
; ladder -- it checks for tile 2Bh underneath. From there it drops into
; the shared BEH_WALK code.
;
; ENTRY  : HITOBJ
; EXIT   : OBJVX, OBJVY
; ALTERS : nothing
; CALLED BY: BEHTAB[0]
;-----------------------------------------------------------------------
BEH_CLMB:
        SAVEALL                          ; 7690  macro
        mov     si, HITOBJ               ; 7697  SI -- whose turn it is
        mov     bp, OFFSET OBJTBL        ; 769B  BP -- object table
        mov     ax, si                   ; 769E  AX -- object number
        mov     cl, 6                    ; 76A0  CL=6 -- length of an object record
        mul     cl                       ; 76A2  number * 6: records run six bytes apiece
        mov     di, ax                   ; 76A4  DI -- offset of the record
        mov     bx, OFFSET OBJTMR2       ; 76A6  table of the objects' second timers
        cmp     BYTE PTR [bx+si], 0      ; 76A9  is the timer negative?
        jl      LBEHCL1                  ; 76AC  the lockout after stepping off a ladder is running
        jne     LBEHCL10                 ; 76AE  not zero -- the object is climbing already
        mov     al, OBJVX[si]            ; 76B0  AL -- speed along X
        cmp     al, 0                    ; 76B4  is the object standing still?
        je      LBEHCL6                  ; 76B6  standing -- no turn this time
        mov     al, TILEAT[si]           ; 76B8  AL -- the tile in the object's cell
        xor     ah, ah                   ; 76BC  AH=0: the whole tile now sits in AX
        cmp     ax, 2Bh                  ; 76BE  2Bh -- a ladder
        jne     LBEHCL7                  ; 76C1  not a ladder -- go look underfoot
        mov     al, RNDSEED              ; 76C3  AL -- random number seed
        and     al, 24h                  ; 76C6  bits 2 and 5 of the seed
        cmp     al, 0                    ; 76C8  are both bits clear?
        je      LBEHCL2                  ; 76CA  both clear -- start up the ladder
        jmp     LBEHWA1                  ; 76CC  otherwise carry on walking as usual
LBEHCL1:
        inc     BYTE PTR [bx+si]         ; 76CF  lockout one frame shorter
        jmp     LBEHWA1                  ; 76D1  carry on walking as usual
LBEHCL2:
        mov     al, OBJVX[si]            ; 76D4  AL -- speed along X
        push    ax                       ; 76D8  AX comes back at 76EE
        cmp     al, 0                    ; 76D9  is the speed negative?
        jl      LBEHCL4                  ; 76DB  negative -- the sign is right already
LBEHCL3:
        xor     al, 0FFh                 ; 76DD  two's complement: flip the sign
        add     al, 1                    ; 76DF  two's complement: add one
LBEHCL4:
        shl     al, 1                    ; 76E1  Y speed is twice the horizontal one
        mov     BYTE PTR OBJVY[si], al   ; 76E3  the object is on its way up
        call    OBJKILL                  ; 76E7  take the object off the screen
        dec     BYTE PTR ds:[bp+di+OB_X] ; 76EA  object's X one byte left: center of the ladder
        pop     ax                       ; 76EE  AL -- the old speed along X
        mov     OBJVX[si], al            ; 76EF  it is kept while the object climbs
LBEHCL5:
        mov     BYTE PTR [bx+si], 1      ; 76F3  timer 1: the object is climbing
        mov     al, BYTE PTR OBJVY[si]   ; 76F6  AL -- speed along Y
        mov     ah, 1                    ; 76FA  AH=1 -- move along the Y axis
        call    OBJMOVE                  ; 76FC  shift the object along Y
LBEHCL6:
        RESTALL                          ; 76FF  macro
        ret                              ; 7706  return: the object has taken its turn
LBEHCL7:
        mov     al, TILEDN[si]           ; 7707  AL -- the tile underfoot
        xor     ah, ah                   ; 770B  AH=0: the whole tile now sits in AX
        cmp     ax, 29h                  ; 770D  29h -- top of a ladder
        je      LBEHCL8                  ; 7710  that is it -- climbing down is allowed
        jmp     LBEHWA1                  ; 7712  otherwise carry on walking as usual
LBEHCL8:
        mov     al, RNDSEED              ; 7715  AL -- random number seed
        and     al, 24h                  ; 7718  bits 2 and 5 of the seed
        je      LBEHCL9                  ; 771A  both clear -- start down the ladder
        jmp     LBEHWA1                  ; 771C  otherwise carry on walking as usual
LBEHCL9:
        mov     al, OBJVX[si]            ; 771F  AL -- speed along X
        push    ax                       ; 7723  AX comes back at 76EE
        cmp     al, 0                    ; 7724  is the speed non-negative?
        jge     LBEHCL4                  ; 7726  no need to flip the sign
        jmp     short LBEHCL3            ; 7728  negative -- flip the sign
LBEHCL10:
        mov     al, BYTE PTR OBJVY[si]   ; 772A  AL -- speed along Y
        cmp     al, 0                    ; 772E  which way it is climbing
        jl      LBEHCL13                 ; 7730  negative -- the object is climbing up
        mov     al, ds:[bp+di+OB_Y]      ; 7732  AL -- the object's Y
        shr     al, 1                    ; 7736  bit 0 picks the field
        cmp     al, 4Eh                  ; 7738  4Eh = 78 -- bottom of the room
        jge     LBEHCL11                 ; 773A  no further down to go
        mov     al, TILEDN[si]           ; 773C  AL -- the tile underfoot
        xor     ah, ah                   ; 7740  AH=0: the whole tile now sits in AX
        cmp     ax, 0                    ; 7742  nothing underfoot?
        je      LBEHCL11                 ; 7745  the ladder has run out
        cmp     ax, T_LADL               ; 7747  ladder, left half
        je      LBEHCL5                  ; 774A  keep climbing
        cmp     ax, T_LADTL              ; 774C  ladder, top left
        je      LBEHCL5                  ; 774F  keep climbing
        mov     al, ds:[bp+di+OB_Y]      ; 7751  AL -- the object's Y
        and     al, 0F8h                 ; 7755  round down to the cell
        add     al, 7                    ; 7757  and stand on its bottom line
        mov     ds:[bp+di+OB_Y], al      ; 7759  Y is lined up with the cell
        xor     al, al                   ; 775D  AL=0 -- the timer is cleared
        jmp     LBEHCL14                 ; 775F  look around and carry on
LBEHCL11:
        mov     al, BYTE PTR OBJVY[si]   ; 7762  AL -- speed along Y
        neg     al                       ; 7766  flip the sign: climb the other way
        mov     BYTE PTR OBJVY[si], al   ; 7768  the climbing direction is reversed
LBEHCL12:
        jmp     short LBEHCL5            ; 776C  move the object along Y
LBEHCL13:
        mov     al, ds:[bp+di+OB_Y]      ; 776E  AL -- the object's Y
        shr     al, 1                    ; 7772  bit 0 picks the field
        cmp     al, 9                    ; 7774  row 9 -- top of the room
        jl      LBEHCL11                 ; 7776  no higher to go
        mov     al, TILEAT[si]           ; 7778  AL -- the tile in the object's cell
        xor     ah, ah                   ; 777C  AH=0: the whole tile now sits in AX
        cmp     ax, T_LADL               ; 777E  ladder, left half
        je      LBEHCL12                 ; 7781  keep climbing
        cmp     ax, T_LADTL              ; 7783  ladder, top left
        je      LBEHCL12                 ; 7786  keep climbing
        inc     BYTE PTR ds:[bp+di+OB_Y] ; 7788  Y one line down
        mov     al, ds:[bp+di+OB_Y]      ; 778C  AL -- the object's Y
        add     al, 0F8h                 ; 7790  F8h = -8: one cell up
        or      al, 7                    ; 7792  and stand on its bottom line
        mov     ds:[bp+di+OB_Y], al      ; 7794  Y is lined up with the cell
        mov     al, 0F8h                 ; 7798  F8h = -8: an eight-frame lockout
LBEHCL14:
        mov     [bx+si], al              ; 779A  the slot's timer is stored
        call    SCANTIL                  ; 779C  look over the tiles around the object
        jmp     LBEHWA1                  ; 779F  carry on walking as usual

CSEG    ENDS
        END
