        PAGE  60,132
        TITLE TILANI -- CYCLING THE ANIMATED TILES
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC ANIMTL
        PUBLIC DIRBIT
        PUBLIC PH70A
        PUBLIC PH71
        EXTRN  BELTFRM:WORD
        EXTRN  BLK70AT:WORD
        EXTRN  BLK70BT:WORD
        EXTRN  BLK71TB:WORD
        EXTRN  INBITS:BYTE
        EXTRN  PITFRM:WORD
        EXTRN  SCANTIL:NEAR
        EXTRN  TILE_70:NEAR
        EXTRN  TILE_71:NEAR
        EXTRN  TILE_72:NEAR
        EXTRN  TILE_78:NEAR
        EXTRN  TIL71:BYTE

;=======================================================================
; TILANI.ASM -- CYCLING THE ANIMATED TILES
;
; Flags and phases, ANIMTL, and four special cases: conveyor belts,
; pits, and two pairs of blinking floors. The pictures all of this
; cycles through live over in ANIMDAT.
;=======================================================================

;-----------------------------------------------------------------------
; TILE ANIMATION FLAGS  (3750..3762, 19 bytes)
;
; Four independent switches that ANIMTL flips with XOR ...,1:
; 3752h, 3755h, 3757h, 375Bh, 3761h.
; PST_0 and PST_5 test 3757h -- that one is the moving floor.
;-----------------------------------------------------------------------
BELTPH  DW    0                          ; 3750  belt cycling phase, modulo 4
TMR70   DB    00h                        ; 3752  frames left until PITANI steps
PH70    DW    0                          ; 3753  PITANI phase
TMR70A  DW    0                          ; 3755  frames left until BLNK70A steps
PH70A   DW    1                          ; 3757  blink phase of tile 70h, variant A
TMR71   DW    0                          ; 3759  frames left until BLNK71 steps, reload 10h
PH70B   DW    0                          ; 375B  blink phase of tile 70h, variant B
PH71C   DW    0                          ; 375D  BLNK71C phase
TMR71C  DW    0                          ; 375F  frames left until PH71 is tested, reload 2
PH71    DW    1                          ; 3761  blink phase of tile 71h

;-----------------------------------------------------------------------
; DIRBIT -- Look over the tiles around every live object in INBITS.
;
; ENTRY  : INBITS
; EXIT   : SI
; ALTERS : BX, CX, DX, DI, BP
; CALLED BY: ST_DRW, ST_PL1, ST_PL2, ST_PL3
;-----------------------------------------------------------------------
DIRBIT:
        push    ax                       ; 3763  AX comes back at 3774
        mov     al, INBITS               ; 3764  AL -- one bit per live object
        mov     si, 7                    ; 3767  eight bits: count on down to zero
LDIRBI1:
        rcl     al, 1                    ; 376A  next bit out into the carry
        jae     LDIRBI2                  ; 376C  bit clear -- the object is not live
        call    SCANTIL                  ; 376E  look over the tiles around object SI
LDIRBI2:
        dec     si                       ; 3771  object number one lower
        jge     LDIRBI1                  ; 3772  bits not used up yet
        pop     ax                       ; 3774  AX restored
        ret                              ; 3775  return: every live object has been looked over

;-----------------------------------------------------------------------
; ANIMTL -- Cycle the animated tiles (blinking floors, conveyor belts).
;
; The TMR70 and PH71 counters are decremented and tested, but the jumps
; that follow land on the very next instruction: PITANI and BLNK71C are not called from here.
;
; EXIT   : TILES
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: ST_DRW, ST_PL1, ST_PL2
;-----------------------------------------------------------------------
ANIMTL:
        call    BELTANI                  ; 3776  cycle the conveyor belts
        dec     TMR70                    ; 3779  pit timer
        jg      LANIMT1                  ; 377D  jump lands zero bytes ahead
LANIMT1:
        dec     TMR70A                   ; 377F  timer of floor 70h, first phase
        jg      LANIMT2                  ; 3783  phase is not up yet
        call    BLNK70A                  ; 3785  swap the picture of floor 70h
LANIMT2:
        cmp     PH70A, 0                 ; 3788  second phase of floor 70h
        je      LANIMT3                  ; 378D  phase is not armed
        call    BLNK70B                  ; 378F  swap the picture of floor 70h, second variant
LANIMT3:
        dec     TMR71                    ; 3792  timer of floor 71h
        jg      LANIMT4                  ; 3796  phase is not up yet
        mov     TMR71, 10h               ; 3798  10h = 16 frames to a phase
        call    BLNK71                   ; 379E  swap the picture of floor 71h
LANIMT4:
        dec     TMR71C                   ; 37A1  scroll timer of tile 71h
        jg      LANIMT5                  ; 37A5  phase is not up yet
        mov     TMR71C, 2                ; 37A7  2 frames to a phase
        cmp     PH71, 0                  ; 37AD  scroll phase
        je      LANIMT5                  ; 37B2  jump lands zero bytes ahead
LANIMT5:
        ret                              ; 37B4  return: the tiles have been cycled

;-----------------------------------------------------------------------
; BELTANI -- Cycle the conveyor belts: a counter modulo 4 picks a set
; out of BELTFRM and rewrites tiles 72h..77h.
;
; EXIT   : TILES
; ALTERS : nothing
; CALLED BY: ANIMTL
;-----------------------------------------------------------------------
BELTANI:
        SAVEREG <bx,cx,si,di>            ; 37B5  macro
        mov     di, OFFSET BELTFRM       ; 37B9  table of the four phases
        inc     BELTPH                   ; 37BC  belt phase one step on
        mov     bx, BELTPH               ; 37C0  BX -- phase number
        and     bx, 3                    ; 37C4  four phases around the ring
        shl     bx, 1                    ; 37C8  entries run two bytes apiece
        mov     si, [bx+di]              ; 37CA  SI -- this phase's pictures for the six tiles
        mov     di, OFFSET TILE_72       ; 37CC  DI -- the live tiles 72h..77h
        mov     cx, 60h                  ; 37CF  60h = 96 bytes = 6 tiles
        shr     cx, 1                    ; 37D2  MOVSW carries two bytes at a time
        cld                              ; 37D4  MOVSW will run forward
        rep movsw                        ; 37D5  the belt phase is down in the live tiles
        RESTREG <di,si,cx,bx>            ; 37D7  macro
        ret                              ; 37DB  return: the belts have been cycled

;-----------------------------------------------------------------------
; PITANI -- Cycle tiles 78h..7Dh: the phase out of PITPHT picks one of
; the four pointer sets in PITFRM. Nothing refers to this routine,
; though ANIMTL keeps its TMR70 counter running.
;
; EXIT   : TILES
; ALTERS : nothing
;-----------------------------------------------------------------------
PITANI:
        SAVEALL                          ; 37DC  macro
        inc     PH70                     ; 37E3  pit phase one step on
        mov     bx, PH70                 ; 37E7  BX -- phase number
        and     bx, 7                    ; 37EB  eight phases around the ring
        mov     si, OFFSET PITPHT        ; 37EF  table of phases
        mov     al, cs:[bx+si]           ; 37F2  AL -- how many frames to hold the set
        mov     TMR70, al                ; 37F5  countdown to the next step
        and     bx, 3                    ; 37F8  four sets of frames
        mov     ax, bx                   ; 37FC  AX -- set number
        mov     bx, 0Ch                  ; 37FE  6 pointers of 2 bytes each
        mul     bx                       ; 3801  number * 12
        mov     bx, ax                   ; 3803  BX -- start of the set within PITFRM
        mov     di, OFFSET TILE_78       ; 3805  tile 78h
        mov     dl, 5                    ; 3808  six tiles: 78h..7Dh
LPITAN1:
        mov     si, OFFSET PITFRM        ; 380A  SI -- table of picture sets
        mov     si, [bx+si]              ; 380D  address of the tile picture
        mov     cx, TILE_SZ              ; 380F  bytes to a tile
        shr     cx, 1                    ; 3812  MOVSW carries two bytes at a time
        cld                              ; 3814  MOVSW will run forward
        rep movsw                        ; 3815  the picture is down in the live tile
        inc     bx                       ; 3817  step 1 of two: pointers run a word apiece
        inc     bx                       ; 3818  BX at the next pointer
        dec     dl                       ; 3819  one tile fewer to go
        jge     LPITAN1                  ; 381B  tiles not used up yet
        RESTALL                          ; 381D  macro
        ret                              ; 3824  return: the pit has been cycled

;-----------------------------------------------------------------------
; PITPHT -- HOW LONG EACH PITANI PHASE LASTS  (3825..382C, 8 bytes)
;
; Index is PH70 and 7, the value is how many frames to hold the set.
;-----------------------------------------------------------------------
PITPHT  DB    02h,01h,03h,01h,01h,03h,02h,01h ; 3825

;-----------------------------------------------------------------------
; BLNK70A -- Blinking of solid floor 70h: two phases, picture from BLK70AT.
;
; EXIT   : TILES
; ALTERS : nothing
; CALLED BY: ANIMTL
;-----------------------------------------------------------------------
BLNK70A:
        SAVEALL                          ; 382D  macro
        xor     PH70A, 1                 ; 3834  phase flipped over to the other one
        mov     bp, PH70A                ; 383A  BP -- phase number
        shl     bp, 1                    ; 383E  entries run two bytes apiece
        mov     si, OFFSET BLK70AD       ; 3840  table of the two phase durations
        mov     ax, cs:[bp+si]           ; 3843  AX -- how many frames to hold the phase
        mov     TMR70A, ax               ; 3846  countdown to the next step
        mov     si, OFFSET BLK70AT       ; 3849  table of the two phase pictures
        mov     si, ds:[bp+si]           ; 384C  SI -- picture of this phase
        mov     di, OFFSET TILE_70       ; 384F  DI -- the live tile 70h
        mov     cx, TILE_SZ              ; 3852  bytes to a tile
        shr     cx, 1                    ; 3855  MOVSW carries two bytes at a time
        cld                              ; 3857  MOVSW will run forward
        rep movsw                        ; 3858  the picture is down in the live tile
        RESTALL                          ; 385A  macro
        ret                              ; 3861  return: floor 70h has a new picture

;-----------------------------------------------------------------------
; BLK70AD -- HOW LONG THE TWO PHASES OF TILE 70h LAST  (3862..3865, 4 bytes)
;
; Index is PH70A. The value goes into TMR70A: 6 frames speckled, 26 plain.
;-----------------------------------------------------------------------
BLK70AD DB    06h,00h,1Ah,00h            ; 3862  ....

;-----------------------------------------------------------------------
; BLNK70B -- Blinking of solid floor 70h, second variant: picture from
; BLK70BT.
;
; EXIT   : TILES
; ALTERS : nothing
; CALLED BY: ANIMTL
;-----------------------------------------------------------------------
BLNK70B:
        SAVEALL                          ; 3866  macro
        xor     PH70B, 1                 ; 386D  phase flipped over to the other one
        mov     bp, PH70B                ; 3873  BP -- phase number
        shl     bp, 1                    ; 3877  entries run two bytes apiece
        mov     si, OFFSET BLK70BT       ; 3879  table of the two phase pictures
        mov     si, ds:[bp+si]           ; 387C  SI -- picture of this phase
        mov     di, OFFSET TILE_70       ; 387F  DI -- the live tile 70h
        mov     cx, TILE_SZ              ; 3882  bytes to a tile
        shr     cx, 1                    ; 3885  MOVSW carries two bytes at a time
        cld                              ; 3887  MOVSW will run forward
        rep movsw                        ; 3888  the picture is down in the live tile
        RESTALL                          ; 388A  macro
        ret                              ; 3891  return: floor 70h has a new picture

;-----------------------------------------------------------------------
; BLNK71C -- Scroll tile 71h with a window over TIL71, phase in PH71C.
; Nothing refers to this routine.
;
; EXIT   : TILES
; ALTERS : nothing
;-----------------------------------------------------------------------
BLNK71C:
        SAVEALL                          ; 3892  macro
        inc     PH71C                    ; 3899  scroll phase one step on
        mov     ax, PH71C                ; 389D  AX -- phase number
        and     ax, 3                    ; 38A0  four phases
        mov     bx, TILE_SZ              ; 38A3  bytes to a tile
        shr     bx, 1                    ; 38A6  shift 1 of two
        shr     bx, 1                    ; 38A8  BX = 4: stride through the table
        mul     bx                       ; 38AA  phase * 4 -- window offset in bytes
        mov     si, OFFSET TIL71         ; 38AC  SI -- picture of tile 71h, the one laid down twice
        add     si, ax                   ; 38AF  window shifted by the phase
        mov     di, OFFSET TILE_71       ; 38B1  tile 71h
        mov     cx, TILE_SZ              ; 38B4  bytes to a tile
        shr     cx, 1                    ; 38B7  MOVSW carries two bytes at a time
        cld                              ; 38B9  MOVSW will run forward
        rep movsw                        ; 38BA  the window is down in the live tile
        RESTALL                          ; 38BC  macro
        ret                              ; 38C3  return: tile 71h has been scrolled

;-----------------------------------------------------------------------
; BLNK71 -- Blinking of solid floor 71h: two phases, picture from BLK71TB.
;
; EXIT   : TILES
; ALTERS : nothing
; CALLED BY: ANIMTL
;-----------------------------------------------------------------------
BLNK71:
        SAVEALL                          ; 38C4  macro
        xor     PH71, 1                  ; 38CB  phase flipped over to the other one
        mov     bp, PH71                 ; 38D1  BP -- phase number
        shl     bp, 1                    ; 38D5  entries run two bytes apiece
        mov     si, OFFSET BLK71TB       ; 38D7  table of the two phase pictures
        mov     si, ds:[bp+si]           ; 38DA  SI -- picture of this phase
        mov     di, OFFSET TILE_71       ; 38DD  DI -- the live tile 71h
        mov     cx, TILE_SZ              ; 38E0  bytes to a tile
        shr     cx, 1                    ; 38E3  MOVSW carries two bytes at a time
        cld                              ; 38E5  MOVSW will run forward
        rep movsw                        ; 38E6  the picture is down in the live tile
        RESTALL                          ; 38E8  macro
        ret                              ; 38EF  return: floor 71h has a new picture

CSEG    ENDS
        END
