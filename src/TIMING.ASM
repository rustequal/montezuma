        PAGE  60,132
        TITLE TIMING -- FRAME LENGTH
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC FRMWAIT
        PUBLIC SOLCNT
        EXTRN  INBITS:BYTE
        EXTRN  OBJTYP:BYTE
        EXTRN  OBJTYPE:NEAR
        EXTRN  ROOMNO:BYTE

;=======================================================================
; TIMING.ASM -- FRAME LENGTH
;
; COSTTAB with the drawing cost per object type, SOLCNT, WORKSUM and
; both of the frame-pacing routines.
;=======================================================================

;-----------------------------------------------------------------------
; FRAME COST AND FLOOR-SPAN LENGTH  (79C0..79CD, 14 bytes)
;
; 79CAh SOLCNT -- total length of the floor spans in the current room.
;-----------------------------------------------------------------------
; what it costs to draw an object of each type, 8 words
COSTTAB DW    1Ch,25h,25h,25h,0          ; 79C0
SOLCNT  DW    0                          ; 79CA  total length of the floor spans in the current room
; running cost of the frame; FRMWAIT pads it out to 10Eh
WORKSUM DW    0                          ; 79CC

;-----------------------------------------------------------------------
; FRMWAIT -- Even out the frame length: total up the cost of drawing
; (SOLCNT plus the weight of every live object taken from COSTTAB) and
; burn the remainder up to 10Eh in an idle wait.
;
; ENTRY  : SOLCNT, INBITS
; EXIT   : WORKSUM
; ALTERS : nothing
; CALLED BY: MAINLP
;-----------------------------------------------------------------------
FRMWAIT:
        SAVEALL                          ; 79CE  macro
        mov     ax, SOLCNT               ; 79D5  total length of this room's floor spans
        mov     WORKSUM, ax              ; 79D8  the frame cost tally starts out from it
        cmp     ROOMNO, 14h              ; 79DB  room 14h = 20
        jne     LFRMWA1                  ; 79E0  some other room -- no correction to make
        add     WORKSUM, -44h            ; 79E2  room 20 comes out 44h units cheaper
LFRMWA1:
        mov     al, INBITS               ; 79E7  AL -- one bit per live object
        and     al, 0FEh                 ; 79EA  bit 0 is the player, he does not count here
        mov     si, 7                    ; 79EC  seven bits: count on down to zero
LFRMWA2:
        rcl     al, 1                    ; 79EF  next bit out into the carry
        jae     LFRMWA3                  ; 79F1  bit clear -- no object in this slot
        call    OBJTYPE                  ; 79F3  OBJTYP -- type of the object in SI
        mov     bl, OBJTYP               ; 79F6  BL -- object type
        xor     bh, bh                   ; 79FA  BH=0: the whole type now sits in BX
        shl     bx, 1                    ; 79FC  entries run two bytes apiece
        mov     di, bx                   ; 79FE  DI -- object type as an index
        mov     bx, COSTTAB[di]          ; 7A00  frame cost charged for this type
        clc                              ; 7A04  clear the carry ahead of the ADC
        adc     WORKSUM, bx              ; 7A05  add it into the frame cost
        jb      LFRMWA4                  ; 7A09  overflow -- nothing left to wait for
LFRMWA3:
        dec     si                       ; 7A0B  on to the next object
        jne     LFRMWA2                  ; 7A0C  slots not used up yet
        mov     ax, 10Eh                 ; 7A0E  10Eh -- a frame's full cost
        sub     ax, WORKSUM              ; 7A11  how much of the budget went unspent
        jle     LFRMWA4                  ; 7A15  frame ran long on its own
        call    DELAY                    ; 7A17  burn off the shortfall in an idle loop
LFRMWA4:
        RESTALL                          ; 7A1A  macro
        ret                              ; 7A21  return: frame has been paced out

;-----------------------------------------------------------------------
; DELAY -- Idle loop of AX*40 turns. The only way to measure out time
; when there is no frame sync to lean on.
;
; ENTRY  : AX
; ALTERS : SI, DI
; CALLED BY: FRMWAIT
;-----------------------------------------------------------------------
DELAY:
        mov     si, ax                   ; 7A22  SI -- how many times to repeat
LDELAY1:
        mov     di, 28h                  ; 7A24  28h = 40 turns of the inner loop
LDELAY2:
        dec     di                       ; 7A27  one turn
        jne     LDELAY2                  ; 7A28  turns not used up yet
        dec     si                       ; 7A2A  one repeat done
        jne     LDELAY1                  ; 7A2B  repeats not used up yet
        ret                              ; 7A2D  return: the time has been spent

CSEG    ENDS
        END
