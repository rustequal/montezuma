        PAGE  60,132
        TITLE PLAYER -- PLAYER STATE AND PHYSICS
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC ANIMIDX
        PUBLIC ANIMLEN
        PUBLIC ANIMPTR
        PUBLIC CMDBITS
        PUBLIC GATETIL
        PUBLIC JUMPIDX
        PUBLIC LAPTMR
        PUBLIC LIVES
        PUBLIC OBJTMR2
        PUBLIC OBJVX
        PUBLIC OBJVY
        PUBLIC PLRST
        PUBLIC PLRSTEP
        PUBLIC PLRTICK
        PUBLIC STANDCK
        PUBLIC SVANIM
        PUBLIC SVIDX2
        PUBLIC SVLEN
        PUBLIC SVST
        PUBLIC SVX
        PUBLIC SVY
        EXTRN  ANIMTB:WORD
        EXTRN  AN_FALL:WORD
        EXTRN  AN_JMP2:WORD
        EXTRN  AN_JUMP:WORD
        EXTRN  AN_POSE1:WORD
        EXTRN  AN_POSE2:WORD
        EXTRN  AN_POSE5:WORD
        EXTRN  AN_STNDL:WORD
        EXTRN  AN_STNDR:WORD
        EXTRN  AN_WALK2:WORD
        EXTRN  DISPAT:NEAR
        EXTRN  FLOOR:BYTE
        EXTRN  FRAMEC:BYTE
        EXTRN  GSTATE:BYTE
        EXTRN  INBITS:BYTE
        EXTRN  INLIST:NEAR
        EXTRN  OBJKILL:NEAR
        EXTRN  OBJMOVE:NEAR
        EXTRN  OBJTBL:WORD
        EXTRN  PH70A:WORD
        EXTRN  PLAYSND:NEAR
        EXTRN  READCMD:NEAR
        EXTRN  ROOMDRW:NEAR
        EXTRN  ROOMNO:BYTE
        EXTRN  ROOMPOS:BYTE
        EXTRN  SCANTIL:NEAR
        EXTRN  TILEAT:BYTE
        EXTRN  TILEDN:BYTE
        EXTRN  TILELF:BYTE
        EXTRN  TILERT:BYTE
        EXTRN  T_VOID:ABS

;=======================================================================
; PLAYER.ASM -- PLAYER STATE AND PHYSICS
;
; JUMPTAB, the player state and the tile lists, then PSTTAB and the ten
; state handlers, the conveyor, and carrying the player across the screen.
;=======================================================================

;-----------------------------------------------------------------------
; PLAYER STATE AND THE MOVEMENT LOOKUP TABLES  (6510..65A3, 148 bytes)
;
; 6510  JUMPTAB -- 13 bytes of vertical jump speed
; 651D  CMDBITS -- the control command, 651F PLRST -- the state
; 6520/6530/6540 -- animation: chain, index within it, frame
; 6558  OBJVX, 6560h OBJVY -- the speeds, both signed
; 6575..657D -- player state held across a change of room
; 657E  PASSTIL, 6592 DOORTIL, 6594 LANDTIL, 6599 DEADTIL,
; 65A1  GATETIL -- the tile lists INLIST searches
;-----------------------------------------------------------------------
; vertical jump speed, 13 bytes: 8 4 4 2 2 1 0 -1 -2 -2 -4 -4 -6
JUMPTAB DB    08h,04h,04h,02h,02h,01h,00h,0FFh,0FEh,0FEh,0FCh,0FCh,0FAh ; 6510
; control command: AH -- direction, AL -- modifier
CMDBITS DW    0          ; 651D
; player state (standing/walking/jumping/dying)
PLRST   DB    00h        ; 651F
; per object: pointer to its current animation table
ANIMPTR DW    8 DUP (0)  ; 6520..652F
; per object: number of the current frame in the chain
ANIMIDX DW    8 DUP (0)  ; 6530..653F
; per object: highest frame number in the chain
ANIMLEN DW    8 DUP (0)  ; 6540..654F
; animation frame kept across a room change
FRMSAVE DB    8 DUP (0)  ; 6550..6557
OBJVX   DB    8 DUP (0)  ; 6558..655F  per object: speed along X, signed
OBJVY   DW    4 DUP (0)  ; 6560..6567  per object: speed along Y, signed
; per object: countdown to the next change of state
OBJTMR2 DB    8 DUP (0)  ; 6568..656F
JUMPIDX DW    0          ; 6570  current index into JUMPTAB
LAPTMR  DB    00h        ; 6572  frames of the walk out of the treasure chamber, loaded with two
; the height a jump or a fall started from
YSTART  DB    00h        ; 6573
LIVES   DB    05h        ; 6574  lives left, starts at 5
; X kept across a move into another room
SVX     DB    00h        ; 6575
SVY     DB    00h        ; 6576  Y kept the same way
SVST    DB    00h        ; 6577  PLRST kept the same way
SVANIM  DW    0          ; 6578  ANIMPTR kept the same way
SVIDX2  DW    0          ; 657A  ANIMIDX kept the same way
SVLEN   DW    0          ; 657C  ANIMLEN kept the same way
; 20 tiles you drop straight through
PASSTIL DB    00h,2Ah,2Bh,0Eh,0Fh,13h,14h,15h,16h,1Ah,1Bh,1Ch,1Dh,21h,22h,23h ; 657E
        DB    78h,79h,7Ah,7Bh                                                 ; 658E  xyz{
; 2 doorway tiles, no footing on those either
DOORTIL DB    16h,1Dh    ; 6592
LANDTIL DB    01h,02h,28h,29h,06h        ; 6594  5 tiles you can stand on: 01 02 28 29 06
; 6 deadly tiles: 78 79 7A 7B 34 35
DEADTIL DB    78h,79h,7Ah,7Bh,34h,35h    ; 6599
; tiles on which a fall turns into state 2
STOPTIL DB    0Dh,2Bh                    ; 659F
; 3 doorway tiles: 0F green, 16 red, 1D brown
GATETIL DB    0Fh,16h,1Dh                ; 65A1

;-----------------------------------------------------------------------
; PLRTICK -- Read the controls and take one player step: READCMD, then
; fall straight through into PLRSTEP.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: ST_PL2, ST_PL3
;-----------------------------------------------------------------------
PLRTICK:
        call    READCMD                  ; 65A4  read the input device into CMDBITS

;-----------------------------------------------------------------------
; PLRSTEP -- One player step: dispatch on PLRST through PSTTAB, then MOVEPLR.
;
; ENTRY  : PLRST
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: PLRTICK (falls through), ST_DRW, ST_PL1
;-----------------------------------------------------------------------
PLRSTEP:
        mov     bx, OFFSET PSTTAB        ; 65A7  BX -- table of the ten player states
        mov     bp, cs                   ; 65AA  BP -- segment of that table, for DISPAT
        mov     al, PLRST                ; 65AC  AL -- number of the player's state
        call    DISPAT                   ; 65AF  call the handler at PSTTAB[AL]
        call    MOVEPLR                  ; 65B2  apply the speeds to the coordinates
        ret                              ; 65B5  return: the player step is done

;-----------------------------------------------------------------------
; PSTTAB -- THE TEN PLAYER STATES  (65B6..65C9, 20 bytes)
;
; Index is PLRST. Entries 3 and 4 lead to one handler, and so do 7..9.
;-----------------------------------------------------------------------
; transition table of the player state, 10 words
PSTTAB  LABEL WORD                       ; 65B6
        DW    PST_0                      ; 65B6  0 the common fork
        DW    PST_1                      ; 65B8  1 run-up
        DW    PST_2                      ; 65BA  2 jumping
        DW    PST_34                     ; 65BC  3 climbing up
        DW    PST_34                     ; 65BE  4 climbing down
        DW    PST_5                      ; 65C0  5 falling after a landing
        DW    PST_6                      ; 65C2  6 lost footing, dropping
        DW    PST_789                    ; 65C4  7 death
        DW    PST_789                    ; 65C6  8 death
        DW    PST_789                    ; 65C8  9 death

;-----------------------------------------------------------------------
; PST_1 -- State 1: the run-up. Sound 0, then on to the common fork PST_0.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: PSTTAB[1]
;-----------------------------------------------------------------------
PST_1:
        mov     si, 0                    ; 65CA  SI=0 -- the run-up sound
        call    PLAYSND                  ; 65CD  play it if the priority lets it through
        jmp     LPST1                    ; 65D0  on to the common fork

;-----------------------------------------------------------------------
; PST_0 -- State 0: standing or walking. The main fork on CMDBITS.
;
; ENTRY  : CMDBITS
; EXIT   : PLRST
; ALTERS : BX, CX, DX, SI, DI, BP
; CALLED BY: BELTPUSH (via JMP), PSTTAB[0], PST_1 (via JMP),
;          PST_34 (via JMP), PST_5 (via JMP), PST_6 (via JMP)
;-----------------------------------------------------------------------
PST_0:
        mov     ANIMIDX, 0               ; 65D3  no frames of the chain stepped through yet
        mov     ANIMLEN, 0               ; 65D9  one frame in the chain
LPST1:
        mov     ax, CMDBITS              ; 65DF  AX -- the control command
        and     ah, DIR_UP               ; 65E2  bit 1 of AH -- up
        je      LPST4                    ; 65E5  not up
        mov     si, 0                    ; 65E7  SI=0 -- the player
        call    LADDER                   ; 65EA  is there a ladder to climb
        jae     LPST7                    ; 65ED  CF=0 -- no ladder here
        mov     BYTE PTR OBJVY, 0FEh     ; 65EF  FEh = -2: speed upward
        call    OBJKILL                  ; 65F4  take the player off the screen
        mov     ax, OFFSET AN_JUMP       ; 65F7  frame chain for climbing
        mov     ANIMPTR, ax              ; 65FA  the player's frame chain is set
        mov     ANIMLEN, 1               ; 65FD  two frames in the chain
LPST2:
        mov     al, 3                    ; 6603  AL=3 -- the "climbing" state
LPST3:
        mov     PLRST, al                ; 6605  the player's new state
        jmp     LPST29                   ; 6608  go and test for the deadly tiles

;-----------------------------------------------------------------------
; A LONE RET  (660B..660B, 1 byte)
;
; Nothing in the image refers to 660Bh.
;-----------------------------------------------------------------------
        ret                              ; 660B  return

LPST4:
        mov     ax, CMDBITS              ; 660C  AX -- the control command
        and     ah, DIR_DN               ; 660F  bit 0 of AH -- down
        je      LPST7                    ; 6612  not down
        mov     si, 0                    ; 6614  SI=0 -- the player
        call    LADDDN                   ; 6617  is there a ladder to climb down
        jae     LPST5                    ; 661A  CF=0 -- no ladder here
        call    OBJKILL                  ; 661C  take the player off the screen
        mov     al, 5                    ; 661F  AL=5 -- shift down by five lines
        mov     ah, 1                    ; 6621  AH=1 -- move along the Y axis
        call    OBJMOVE                  ; 6623  shift the player down
        mov     ax, OFFSET AN_FALL       ; 6626  frame chain for falling
        mov     ANIMPTR, ax              ; 6629  the player's frame chain is set
        mov     ANIMIDX, 0               ; 662C  no frames of the chain stepped through yet
        mov     ANIMLEN, 0               ; 6632  one frame in the chain
        jmp     short LPST2              ; 6638  over to the "climbing" state
LPST5:
        xor     ah, ah                   ; 663A  AH=0: the whole tile now sits in AX
        mov     al, TILEDN               ; 663C  AL -- the tile underfoot
        cmp     ax, 6                    ; 663F  tile 6 -- a rope
        jne     LPST7                    ; 6642  not a rope
LPST6:
        mov     OBJVX, 0                 ; 6644  the player comes to a stop
        mov     bx, OFFSET OBJTBL        ; 6649  BX -- object table, object 0 is the player
        or      BYTE PTR [bx+OB_X], 1    ; 664C  player's X onto an odd byte: the center of the rope
        mov     ax, OFFSET AN_POSE1      ; 6650  frame chain for the pose on the rope
        mov     ANIMPTR, ax              ; 6653  the player's frame chain is set
        mov     ANIMLEN, 1               ; 6656  two frames in the chain
        mov     ANIMIDX, 0               ; 665C  no frames of the chain stepped through yet
        mov     al, 4                    ; 6662  AL=4 -- the "hanging on a rope" state
        jmp     short LPST3              ; 6664  the player's new state
LPST7:
        mov     ax, CMDBITS              ; 6666  AX -- the control command
        and     ah, DIR_LF               ; 6669  bit 2 of AH -- left
        jne     LPST8                    ; 666C  left it is
        jmp     LBELTP2                  ; 666E  not left -- go and look at right
LPST8:
        mov     ax, OFFSET AN_WALK2      ; 6671  frame chain for walking left
        mov     ANIMPTR, ax              ; 6674  the player's frame chain is set
        mov     ANIMLEN, 3               ; 6677  four frames in the chain
        mov     OBJVX, 0FFh              ; 667D  FFh = -1: speed to the left
        mov     BYTE PTR OBJVY, 0        ; 6682  the player is not moving vertically
        mov     ax, CMDBITS              ; 6687  AX -- the control command
        and     al, BTN_JUMP             ; 668A  bit 4 of AL -- the jump button
        jne     LPST13                   ; 668C  not held -- go and look for footing
LPST9:
        mov     ax, OFFSET AN_STNDL      ; 668E  frame chain "standing, facing left"
        mov     ANIMPTR, ax              ; 6691  the player's frame chain is set
LPST10:
        mov     si, 1                    ; 6694  SI=1 -- the jump sound
        call    PLAYSND                  ; 6697  play it if the priority lets it through
        mov     al, TILEAT               ; 669A  AL -- the tile in the player's own cell
        xor     ah, ah                   ; 669D  AH=0: the whole tile now sits in AX
        cmp     ax, T_PASS               ; 669F  a walk-through tile: nothing to stand on
        jne     LPST11                   ; 66A2  not that one
        mov     OBJTMR2, 3               ; 66A4  timer of 3 frames: the floor has time to vanish
LPST11:
        mov     si, 0Ch                  ; 66A9  SI=0Ch = 12 -- head of the jump arc
LPST12:
        mov     JUMPIDX, si              ; 66AC  the jump phase
        mov     bx, OFFSET JUMPTAB       ; 66B0  BX -- table of jump speeds
        mov     al, [bx+si]              ; 66B3  AL -- Y speed at this phase
        mov     BYTE PTR OBJVY, al       ; 66B5  the vertical speed is set
        mov     ANIMLEN, 0               ; 66B8  one frame in the chain
        mov     bx, OFFSET OBJTBL        ; 66BE  BX -- object table, object 0 is the player
        mov     al, [bx+OB_Y]            ; 66C1  AL -- the player's Y
        shr     al, 1                    ; 66C4  bit 0 picks the field
        mov     YSTART, al               ; 66C6  YSTART -- the height the jump started from
        mov     al, 2                    ; 66C9  AL=2 -- the "jumping" state
        jmp     LPST3                    ; 66CB  the player's new state
LPST13:
        mov     al, TILEDN               ; 66CE  AL -- the tile underfoot
        mov     si, 14h                  ; 66D1  14h = 20 tiles in the list
        mov     bp, OFFSET PASSTIL       ; 66D4  the tiles you drop straight through
        call    INLIST                   ; 66D7  is AL in the list
        jb      LPST17                   ; 66DA  CF=1 -- nothing to stand on
        mov     si, 2                    ; 66DC  two tiles in the list
        mov     bp, OFFSET DOORTIL       ; 66DF  the door tiles
        call    INLIST                   ; 66E2  is AL in the list
        jb      LPST17                   ; 66E5  CF=1 -- a door underfoot
        xor     ah, ah                   ; 66E7  AH=0: the whole tile now sits in AX
        cmp     ax, T_SOLID              ; 66E9  solid floor with speckle
        je      LPST16                   ; 66EC  that one -- go and check the blink phase
        cmp     al, 0                    ; 66EE  nothing underfoot?
        je      LPST16                   ; 66F0  nothing -- go and check the blink phase
LPST14:
        mov     al, 0                    ; 66F2  AL=0 -- the "standing" state
        cmp     OBJVX, 0                 ; 66F4  is the player moving horizontally?
        je      LPST15                   ; 66F9  standing still
        mov     al, 1                    ; 66FB  AL=1 -- the "walking" state
LPST15:
        push    ax                       ; 66FD  AX comes back at 6701
        call    BELTPUSH                 ; 66FE  a conveyor underfoot carries the player along
        pop     ax                       ; 6701  AL -- the new state
        jmp     LPST3                    ; 6702  the player's new state
LPST16:
        cmp     BYTE PTR PH70A, 0        ; 6705  blink phase of floor 70h
        jne     LPST14                   ; 670A  the floor is there -- the player stands on it
LPST17:
        mov     OBJVX, 0                 ; 670C  the player comes to a stop
        mov     al, 8                    ; 6711  AL=8 -- speed downward
LPST18:
        mov     BYTE PTR OBJVY, al       ; 6713  the vertical speed is set
        mov     bx, OFFSET OBJTBL        ; 6716  BX -- object table, object 0 is the player
        mov     al, [bx+OB_Y]            ; 6719  AL -- the player's Y
        shr     al, 1                    ; 671C  bit 0 picks the field
        mov     YSTART, al               ; 671E  YSTART -- the height the fall started from
        mov     al, 6                    ; 6721  AL=6 -- the "losing footing" state
        jmp     LPST3                    ; 6723  the player's new state

;-----------------------------------------------------------------------
; BELTPUSH -- The conveyor: if tile 72h..77h is underfoot, shove the
; player along. It works every other frame and adds to OBJVX rather
; than replacing it.
; EXIT   : OBJVX
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: PST_0, PST_0 (via JMP), PST_34 (via JMP)
;-----------------------------------------------------------------------
BELTPUSH:
        mov     al, TILEDN               ; 6726  AL -- the tile underfoot
        call    DOORSID                  ; 6729  is it a belt underfoot, and which way does it run
        jae     LBELTP1                  ; 672C  CF=0 -- not a belt
        mov     al, FRAMEC               ; 672E  the belt only works every other frame
        and     al, 1                    ; 6731  bit 0 of the frame counter
        je      LBELTP1                  ; 6733  even frame -- the belt stands still
        mov     bx, OFFSET BELTVX        ; 6735  the two belt speeds: left and right
        mov     al, cs:[bx+si]           ; 6738  AL -- speed of this belt
        add     OBJVX, al                ; 673B  the belt has added its speed to the player
LBELTP1:
        ret                              ; 673F  return: the belt has had its say

;-----------------------------------------------------------------------
; BELTVX -- CONVEYOR SPEED  (6740..6741, 2 bytes)
;
; Two bytes: +1 and -1. DOORSID picks the side from the tile code.
;-----------------------------------------------------------------------
; conveyor speed: +1 and -1
BELTVX  DB    01h,0FFh                   ; 6740

LBELTP2:
        mov     ax, CMDBITS              ; 6742  AX -- the control command
        and     ah, DIR_RT               ; 6745  bit 3 of AH -- right
        je      LBELTP4                  ; 6748  not right
        mov     ax, OFFSET ANIMTB        ; 674A  frame chain for walking right
        mov     ANIMPTR, ax              ; 674D  the player's frame chain is set
        mov     ANIMLEN, 3               ; 6750  four frames in the chain
        mov     OBJVX, 1                 ; 6756  speed to the right
        mov     BYTE PTR OBJVY, 0        ; 675B  the player is not moving vertically
        mov     ax, CMDBITS              ; 6760  AX -- the control command
        and     al, BTN_JUMP             ; 6763  bit 4 of AL -- the jump button
        je      LBELTP3                  ; 6765  held down -- jump
        jmp     LPST13                   ; 6767  not held -- go and look for footing
LBELTP3:
        mov     ax, OFFSET AN_STNDR      ; 676A  frame chain "standing, facing right"
        mov     ANIMPTR, ax              ; 676D  the player's frame chain is set
        jmp     LPST10                   ; 6770  sort out the jump and the footing
LBELTP4:
        mov     OBJVX, 0                 ; 6773  the player comes to a stop
        mov     BYTE PTR OBJVY, 0        ; 6778  the player is not moving vertically
        mov     ax, CMDBITS              ; 677D  AX -- the control command
        and     al, BTN_JUMP             ; 6780  bit 4 of AL -- the jump button
        je      LBELTP5                  ; 6782  held down -- jump
        jmp     LPST13                   ; 6784  not held -- go and look for footing
LBELTP5:
        call    STANDCK                  ; 6787  is the player standing and facing right
        jae     LBELTP3                  ; 678A  CF=0 -- facing right
        jmp     LPST9                    ; 678C  facing left

;-----------------------------------------------------------------------
; PST_2 -- State 2: the jump. It takes the next vertical speed out of
; JUMPTAB by JUMPIDX and kills it at the ceiling. It never reads the
; controls: a jump cannot be broken off. Ends by falling into PST_6.
;
; ENTRY  : JUMPIDX
; EXIT   : OBJVY
; ALTERS : BX, CX, DX, SI, DI
; CALLED BY: PSTTAB[2]
;-----------------------------------------------------------------------
PST_2:
        dec     JUMPIDX                  ; 678F  jump phase one step back
        jge     LPST19                   ; 6793  the arc is not finished
        mov     JUMPIDX, 0               ; 6795  the arc is finished: sit at zero from here on
LPST19:
        mov     si, JUMPIDX              ; 679B  SI -- the jump phase
        mov     bx, OFFSET JUMPTAB       ; 679F  BX -- table of jump speeds
        mov     al, [bx+si]              ; 67A2  AL -- Y speed at this phase
        push    ax                       ; 67A4  AX comes back at 67C5
        push    bp                       ; 67A5  BP comes back at 67C4
        mov     bp, OFFSET OBJTBL        ; 67A6  BP -- object table, object 0 is the player
        mov     ah, ds:[bp+OB_Y]         ; 67A9  AH -- the player's Y
        cmp     ah, 0Ah                  ; 67AD  0Ah = 10 -- top of the playfield
        ja      LPST20                   ; 67B0  lower down -- take the speed as it stands
        add     ah, al                   ; 67B2  where the player would end up
        cmp     ah, 0                    ; 67B4  above line zero?
        jge     LPST20                   ; 67B7  no
        mov     BYTE PTR OBJVY, 0        ; 67B9  do not let him up into the panel
        jmp     LPST21                   ; 67BE  the speed is set
LPST20:
        mov     BYTE PTR OBJVY, al       ; 67C1  the vertical speed is set
LPST21:
        pop     bp                       ; 67C4  BP restored
        pop     ax                       ; 67C5  AX restored

;-----------------------------------------------------------------------
; PST_6 -- State 6: losing footing and dropping, with a chance to catch
; hold. It waits on OBJTMR2, looks at the tile underfoot (0Dh, 06h,
; 0Eh) and decides whether to fall or to stand. PST_2 falls in here too.
;
; ENTRY  : OBJVX, TILEAT
; EXIT   : OBJVY, PLRST
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: PSTTAB[6], PST_2 (falls through)
;-----------------------------------------------------------------------
PST_6:
        dec     OBJTMR2                  ; 67C6  the catch-hold timer
        jge     LPST22                   ; 67CA  the timer is still running
        inc     OBJTMR2                  ; 67CC  put the timer back at zero
        cmp     OBJVX, 0                 ; 67D0  is the player moving horizontally?
        je      LPST22                   ; 67D5  standing still -- nothing to catch hold of
        mov     al, TILEAT               ; 67D7  AL -- the tile in the player's own cell
        xor     ah, ah                   ; 67DA  AH=0: the whole tile now sits in AX
        cmp     ax, 0Dh                  ; 67DC  0Dh -- edge of a platform
        je      LPST23                   ; 67DF  catch hold
        cmp     ax, 6                    ; 67E1  tile 6 -- a rope
        je      LPST23                   ; 67E4  catch hold
        cmp     ax, T_PASS               ; 67E6  a walk-through tile: nothing to stand on
        je      LPST24                   ; 67E9  drop through
LPST22:
        cmp     BYTE PTR OBJVY, 0        ; 67EB  is the Y speed negative?
        jge     LPST25                   ; 67F0  on the way down
        ret                              ; 67F2  return: the player is still going up
LPST23:
        cmp     LAPTMR, 0                ; 67F3  room-change timer
        jne     LPST22                   ; 67F8  a change is under way -- no catching hold now
        mov     BYTE PTR OBJVY, 0        ; 67FA  the fall is stopped
        jmp     LPST6                    ; 67FF  hang on the rope
LPST24:
        jmp     LPST30                   ; 6802  drop straight through the floor

;-----------------------------------------------------------------------
; PST_5 -- State 5: falling. Footing -> a landing, DEADTIL -> death.
;
; EXIT   : PLRST
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: PSTTAB[5], PST_0 (via JMP), PST_6 (via JMP)
;-----------------------------------------------------------------------
PST_5:
        mov     bx, OFFSET OBJTBL        ; 6805  BX -- object table, object 0 is the player
        mov     al, [bx+OB_Y]            ; 6808  AL -- the player's Y
        shr     al, 1                    ; 680B  bit 0 picks the field
        mov     YSTART, al               ; 680D  YSTART -- the height the fall started from
LPST25:
        mov     al, TILEDN               ; 6810  AL -- the tile underfoot
        xor     ah, ah                   ; 6813  AH=0: the whole tile now sits in AX
        cmp     ax, 0                    ; 6815  nothing underfoot?
        je      LPST27                   ; 6818  nothing -- keep falling
        cmp     ax, T_PASS               ; 681A  a walk-through tile: nothing to stand on
        je      LPST27                   ; 681D  keep falling
        mov     si, 5                    ; 681F  five tiles in the list
        mov     bp, OFFSET LANDTIL       ; 6822  the tiles you land on
        call    INLIST                   ; 6825  is AL in the list
        jb      LPST28                   ; 6828  CF=1 -- a landing
        call    DOORSID                  ; 682A  a belt is footing too
        jb      LPST28                   ; 682D  CF=1 -- landing on a belt
        xor     ah, ah                   ; 682F  AH=0: the whole tile now sits in AX
        cmp     ax, T_SOLID              ; 6831  solid floor with speckle
        je      LPST26                   ; 6834  that one -- go and check the blink phase
        cmp     ax, 0                    ; 6836  nothing underfoot?
        jne     LPST29                   ; 6839  something there -- go and test the deadly tiles
LPST26:
        cmp     BYTE PTR PH70A, 0        ; 683B  blink phase of floor 70h
        jne     LPST28                   ; 6840  the floor is there -- a landing
LPST27:
        ret                              ; 6842  return: the player keeps falling
LPST28:
        jmp     LPST31                   ; 6843  land
LPST29:
        mov     al, TILEAT               ; 6846  AL -- the tile in the player's own cell
        mov     si, 6                    ; 6849  six tiles in the list
        mov     bp, OFFSET DEADTIL       ; 684C  the deadly tiles
        call    INLIST                   ; 684F  is AL in the list
        jae     LPST27                   ; 6852  CF=0 -- the tile is harmless
        mov     ax, OFFSET AN_POSE5      ; 6854  frame chain for the death pose
        mov     ANIMPTR, ax              ; 6857  the player's frame chain is set
        mov     ANIMLEN, 0               ; 685A  one frame in the chain
        mov     si, 6                    ; 6860  SI=6 -- the death sound
        call    PLAYSND                  ; 6863  play it if the priority lets it through
        mov     OBJVX, 0                 ; 6866  the player comes to a stop
        mov     BYTE PTR OBJVY, 0        ; 686B  the vertical speed is zeroed
        dec     BYTE PTR OBJVY           ; 6870  FFh = -1: the body is tossed upward
        mov     OBJTMR2, 3Fh             ; 6874  3Fh = 63 frames until the animation ends
        mov     PLRST, 9                 ; 6879  state 9 -- death
        ret                              ; 687E  return: the player is dead
LPST30:
        mov     OBJVX, 0                 ; 687F  the player comes to a stop
        mov     bx, OFFSET OBJTBL        ; 6884  BX -- object table, object 0 is the player
        or      BYTE PTR [bx+OB_X], 1    ; 6887  player's X onto an odd byte: the center of the rope
        mov     ax, OFFSET AN_POSE2      ; 688B  frame chain for the pose on the rope
        mov     ANIMPTR, ax              ; 688E  the player's frame chain is set
        mov     ANIMLEN, 0               ; 6891  one frame in the chain
        mov     BYTE PTR OBJVY, 4        ; 6897  speed downward 4
        mov     si, 2                    ; 689C  SI=2 -- the losing-footing sound
        call    PLAYSND                  ; 689F  play it if the priority lets it through
        mov     al, 5                    ; 68A2  AL=5 -- the "falling" state
        jmp     LPST3                    ; 68A4  the player's new state
LPST31:
        mov     OBJVX, 0                 ; 68A7  the player comes to a stop
        mov     BYTE PTR OBJVY, 0        ; 68AC  the fall is stopped
        mov     si, 3                    ; 68B1  SI=3 -- the landing sound
        call    PLAYSND                  ; 68B4  play it if the priority lets it through
        mov     bx, OFFSET OBJTBL        ; 68B7  BX -- object table, object 0 is the player
        mov     al, [bx+OB_Y]            ; 68BA  AL -- the player's Y
        dec     al                       ; 68BD  one line up
        and     al, 0F8h                 ; 68BF  round down to the cell
        or      al, 4                    ; 68C1  and stand on its fourth line
        mov     bx, OFFSET OBJTBL        ; 68C3  BX -- object table, object 0 is the player
        mov     [bx+OB_Y], al            ; 68C6  Y is lined up with the cell
        mov     si, 0                    ; 68C9  SI=0 -- the player
        call    SCANTIL                  ; 68CC  read the tiles around the player into TILELF..TILEDN
        mov     al, [bx+OB_Y]            ; 68CF  AL -- the player's Y
        mov     cl, TILEDN               ; 68D2  CL -- the tile underfoot
        xor     ch, ch                   ; 68D6  CH=0: the whole tile now sits in CX
        cmp     cx, T_VOID               ; 68D8  nothing underfoot?
        jne     LPST32                   ; 68DC  something is there
        add     al, 8                    ; 68DE  nothing -- drop him a cell lower
LPST32:
        mov     [bx+OB_Y], al            ; 68E0  Y is stored
        shr     al, 1                    ; 68E3  bit 0 picks the field
        sub     al, YSTART               ; 68E5  how many lines he fell through
        cmp     al, 0Fh                  ; 68E9  0Fh = 15 lines -- the limit
        jg      LPST39                   ; 68EB  further than that -- the fall is fatal
        call    STANDCK                  ; 68ED  is the player standing and facing right
        jae     LPST34                   ; 68F0  CF=0 -- facing right
        xor     ah, ah                   ; 68F2  AH=0
        mov     ax, 1                    ; 68F4  AX=1 -- the floor tile
        cmp     al, TILEAT               ; 68F7  floor in the player's own cell?
        jne     LPST33                   ; 68FB  no
        cmp     al, TILEDN               ; 68FD  and floor underfoot as well?
        je      LPST37                   ; 6901  slide to the left
LPST33:
        mov     ax, OFFSET AN_WALK2      ; 6903  frame chain for walking left
        mov     ANIMPTR, ax              ; 6906  the player's frame chain is set
        jmp     LPST36                   ; 6909  off to the common tail
LPST34:
        mov     ax, 1                    ; 690C  AX=1 -- the floor tile
        cmp     al, TILEAT               ; 690F  floor in the player's own cell?
        jne     LPST35                   ; 6913  no
        cmp     al, TILEDN               ; 6915  and floor underfoot as well?
        je      LPST38                   ; 6919  slide to the right
LPST35:
        mov     ax, OFFSET ANIMTB        ; 691B  frame chain for walking right
        mov     ANIMPTR, ax              ; 691E  the player's frame chain is set
LPST36:
        mov     ANIMLEN, 0               ; 6921  one frame in the chain
        mov     al, 0                    ; 6927  AL=0 -- the "standing" state
        jmp     LPST3                    ; 6929  the player's new state
LPST37:
        mov     OBJVX, 2                 ; 692C  speed to the right 2
        mov     al, 0                    ; 6931  AL=0 -- the "standing" state
        jmp     LPST3                    ; 6933  the player's new state
LPST38:
        mov     OBJVX, 0FEh              ; 6936  FEh = -2: speed to the left
        mov     al, 0                    ; 693B  AL=0 -- the "standing" state
        jmp     LPST3                    ; 693D  the player's new state
LPST39:
        mov     ax, OFFSET AN_JMP2       ; 6940  frame chain for a fatal fall
        mov     ANIMPTR, ax              ; 6943  the player's frame chain is set
        mov     ANIMLEN, 1               ; 6946  two frames in the chain
        mov     ANIMIDX, 1               ; 694C  start from the second frame
        mov     OBJTMR2, 3Fh             ; 6952  3Fh = 63 frames until the animation ends
        mov     al, 8                    ; 6957  AL=8 -- the "crashed" state
        jmp     LPST3                    ; 6959  the player's new state

;-----------------------------------------------------------------------
; PST_34 -- States 3 and 4: ladder and rope. Reads CMDBITS, switches the
; animation over to AN_FALL on tile 29h; in room 64h dropping is barred.
;
; ENTRY  : CMDBITS, TILEAT
; EXIT   : OBJVY, ANIMPTR
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: PSTTAB[3], PSTTAB[4]
;-----------------------------------------------------------------------
PST_34:
        mov     ax, CMDBITS              ; 695C  AX -- the control command
        and     ah, 0Ch                  ; 695F  bits 3..2 of AH -- left or right
        jne     LPST47                   ; 6962  either one -- step off the ladder
LPST40:
        mov     ax, CMDBITS              ; 6964  AX -- the control command
        xor     al, al                   ; 6967  AL is not wanted here
        and     ah, 3                    ; 6969  bits 1..0 of AH -- up or down
        je      LPST44                   ; 696C  neither up nor down -- stay put
        and     ah, DIR_UP               ; 696E  bit 1 of AH -- up
        je      LPST49                   ; 6971  not up -- so it is down
        mov     al, TILEAT               ; 6973  AL -- the tile in the player's own cell
        xor     ah, ah                   ; 6976  AH=0: the whole tile now sits in AX
        cmp     ax, 0                    ; 6978  is the cell empty?
        jne     LPST41                   ; 697B  not empty
        cmp     ROOMNO, 64h              ; 697D  64h = 100 -- the treasure chamber
        jne     LPST42                   ; 6982  some other room
        mov     BYTE PTR OBJVY, 0        ; 6984  the treasure chamber does not let you climb up
        ret                              ; 6989  return
LPST41:
        cmp     ax, 29h                  ; 698A  29h -- top of a ladder
        jne     LPST42                   ; 698D  not that one
        mov     ax, OFFSET AN_FALL       ; 698F  frame chain for climbing
        mov     ANIMPTR, ax              ; 6992  the player's frame chain is set
        mov     ANIMIDX, 0               ; 6995  no frames of the chain stepped through yet
        mov     ANIMLEN, 0               ; 699B  one frame in the chain
LPST42:
        mov     al, TILEDN               ; 69A1  AL -- the tile underfoot
        xor     ah, ah                   ; 69A4  AH=0: the whole tile now sits in AX
        cmp     ax, 29h                  ; 69A6  29h -- top of a ladder
        je      LPST45                   ; 69A9  that one -- he may jump off
        cmp     ax, 6                    ; 69AB  tile 6 -- a rope
        je      LPST46                   ; 69AE  off a rope -- that is a jump
LPST43:
        mov     al, 0FEh                 ; 69B0  FEh = -2: speed upward
LPST44:
        mov     BYTE PTR OBJVY, al       ; 69B2  the vertical speed is set
        ret                              ; 69B5  return: one step along the ladder is done
LPST45:
        cmp     ANIMLEN, 0               ; 69B6  is the highest frame number zero?
        jne     LPST43                   ; 69BB  no -- keep climbing
LPST46:
        mov     si, 8                    ; 69BD  SI=8 -- head of the jump arc off a ladder
        jmp     LPST12                   ; 69C0  jump
LPST47:
        cmp     PLRST, 4                 ; 69C3  state 4 -- hanging on a rope
        jne     LPST40                   ; 69C8  not the rope -- a ladder then
        mov     ax, CMDBITS              ; 69CA  AX -- the control command
        and     al, BTN_JUMP             ; 69CD  bit 4 of AL -- the jump button
        jne     LPST40                   ; 69CF  not held -- go on hanging
        mov     OBJTMR2, 3               ; 69D1  timer of 3 frames before catching hold again
        mov     ax, CMDBITS              ; 69D6  AX -- the control command
        and     ah, DIR_RT               ; 69D9  bit 3 of AH -- right
        je      LPST48                   ; 69DC  not right
        mov     OBJVX, 1                 ; 69DE  speed to the right 1
        jmp     LBELTP3                  ; 69E3  jump off to the right
LPST48:
        mov     OBJVX, 0FFh              ; 69E6  FFh = -1: speed to the left
        jmp     LPST9                    ; 69EB  jump off to the left
LPST49:
        mov     al, TILEAT               ; 69EE  AL -- the tile in the player's own cell
        xor     ah, ah                   ; 69F1  AH=0: the whole tile now sits in AX
        cmp     ax, 2Bh                  ; 69F3  2Bh -- a ladder
        je      LPST50                   ; 69F6  you can go down that one
        cmp     ax, 0Dh                  ; 69F8  0Dh -- edge of a platform
        jne     LPST52                   ; 69FB  no ladder -- come to a stop
LPST50:
        cmp     PLRST, 3                 ; 69FD  state 3 -- climbing
        jne     LPST51                   ; 6A02  not climbing
        mov     ax, OFFSET AN_FALL       ; 6A04  frame chain for falling
        cmp     ax, ANIMPTR              ; 6A07  is that the one in place now?
        jne     LPST51                   ; 6A0B  some other chain
        mov     al, TILEDN               ; 6A0D  AL -- the tile underfoot
        xor     ah, ah                   ; 6A10  AH=0: the whole tile now sits in AX
        cmp     ax, 29h                  ; 6A12  29h -- top of a ladder
        je      LPST52                   ; 6A15  on that one you are not let down
        mov     ax, OFFSET AN_JUMP       ; 6A17  frame chain for climbing
        mov     ANIMPTR, ax              ; 6A1A  the player's frame chain is set
        mov     ANIMLEN, 1               ; 6A1D  two frames in the chain
LPST51:
        mov     al, TILEDN               ; 6A23  AL -- the tile underfoot
        mov     si, 2                    ; 6A26  two tiles in the list
        mov     bp, OFFSET STOPTIL       ; 6A29  the tiles at which the descent ends
        call    INLIST                   ; 6A2C  is AL in the list
        jae     LPST53                   ; 6A2F  CF=0 -- climbing down is allowed
LPST52:
        mov     al, 2                    ; 6A31  AL=2 -- speed downward
        jmp     LPST44                   ; 6A33  the vertical speed is set
LPST53:
        cmp     ROOMNO, 64h              ; 6A36  64h = 100 -- the treasure chamber
        je      LPST54                   ; 6A3B  the treasure chamber does not let you climb down
        mov     al, 3                    ; 6A3D  AL=3 -- speed downward
        jmp     LPST18                   ; 6A3F  drop away downward
LPST54:
        mov     BYTE PTR OBJVY, 0        ; 6A42  the player is brought to a halt
        ret                              ; 6A47  return: one step along the ladder is done

;-----------------------------------------------------------------------
; SETANIM -- Put chain AN_FALL on object 0 from its head. Nothing refers to it.
;
; EXIT   : ANIMPTR, ANIMIDX, ANIMLEN
; ALTERS : nothing
;-----------------------------------------------------------------------
SETANIM:
        mov     ax, OFFSET AN_FALL       ; 6A48  frame chain for falling
        mov     ANIMPTR, ax              ; 6A4B  the player's frame chain is set
        mov     ANIMIDX, 0               ; 6A4E  no frames of the chain stepped through yet
        mov     ANIMLEN, 0               ; 6A54  one frame in the chain
        ret                              ; 6A5A  return: the chain is in place

;-----------------------------------------------------------------------
; PST_789 -- States 7..9: death. Once OBJTMR2 runs out it takes a life
; and puts the player back from the saved SVX, SVY, SVST, SVANIM, SVIDX2.
;
; ENTRY  : OBJTMR2
; EXIT   : LIVES, OBJTBL, PLRST
; ALTERS : BX, CX, DX, SI, DI, BP, ES
; CALLED BY: PSTTAB[7], PSTTAB[8], PSTTAB[9]
;-----------------------------------------------------------------------
PST_789:
        dec     OBJTMR2                  ; 6A5B  timer of the death animation
        jne     LPST55                   ; 6A5F  still running
        and     INBITS, 0FEh             ; 6A61  bit 0 cleared: the player is off the screen
        dec     LIVES                    ; 6A66  one life fewer
        jl      LPST56                   ; 6A6A  out of lives -- the game is over
        mov     bx, OFFSET OBJTBL        ; 6A6C  BX -- object table, object 0 is the player
        mov     al, SVX                  ; 6A6F  AL -- the saved X
        mov     [bx+OB_X], al            ; 6A72  the player is back at his X
        mov     al, SVY                  ; 6A75  AL -- the saved Y
        mov     [bx+OB_Y], al            ; 6A78  the player is back at his Y
        mov     al, SVST                 ; 6A7B  AL -- the saved state
        mov     PLRST, al                ; 6A7E  the state is back
        mov     ax, SVANIM               ; 6A81  AX -- the saved frame chain
        mov     ANIMPTR, ax              ; 6A84  the chain is back
        mov     bx, ax                   ; 6A87  BX -- head of the chain
        mov     ax, SVIDX2               ; 6A89  AX -- the saved frame number
        mov     ANIMIDX, ax              ; 6A8C  the frame number is back
        shl     ax, 1                    ; 6A8F  chain entries run two bytes apiece
        add     bx, ax                   ; 6A91  BX -- the entry we want in the chain
        mov     ax, [bx]                 ; 6A93  AX -- address of the frame
        add     ax, 2                    ; 6A95  step over the frame header
        mov     OBJTBL, ax               ; 6A98  pointer to the player's bitmap
        mov     ax, SVLEN                ; 6A9B  AX -- the saved chain length
        mov     ANIMLEN, ax              ; 6A9E  the highest frame number is back
        mov     OBJVX, 0                 ; 6AA1  the player stands still
        mov     BYTE PTR OBJVY, 0        ; 6AA6  the vertical speed is zeroed
        or      INBITS, 1                ; 6AAB  bit 0 set: the player is on the screen
        call    ROOMDRW                  ; 6AB0  rebuild the room map and redraw the whole frame
        mov     si, 0                    ; 6AB3  SI=0 -- the player
        call    SCANTIL                  ; 6AB6  read the tiles around the player into TILELF..TILEDN
        pop     ax                       ; 6AB9  the return address is dropped: the frame is cut short
        stc                              ; 6ABA  CF=1 -- the frame was cut short
LPST55:
        ret                              ; 6ABB  return
LPST56:
        inc     LIVES                    ; 6ABC  put the life counter back at zero
        mov     bx, OFFSET OBJTBL        ; 6AC0  BX -- object table, object 0 is the player
        mov     al, SVX                  ; 6AC3  AL -- the saved X
        mov     [bx+OB_X], al            ; 6AC6  the player is back at his X
        mov     al, SVY                  ; 6AC9  AL -- the saved Y
        mov     [bx+OB_Y], al            ; 6ACC  the player is back at his Y
        mov     al, SVST                 ; 6ACF  AL -- the saved state
        mov     PLRST, al                ; 6AD2  the state is back
        mov     ax, SVANIM               ; 6AD5  AX -- the saved frame chain
        mov     ANIMPTR, ax              ; 6AD8  the chain is back
        mov     bx, ax                   ; 6ADB  BX -- head of the chain
        mov     ax, SVIDX2               ; 6ADD  AX -- the saved frame number
        mov     ANIMIDX, ax              ; 6AE0  the frame number is back
        shl     ax, 1                    ; 6AE3  chain entries run two bytes apiece
        add     bx, ax                   ; 6AE5  BX -- the entry we want in the chain
        mov     ax, [bx]                 ; 6AE7  AX -- address of the frame
        add     ax, 2                    ; 6AE9  step over the frame header
        mov     OBJTBL, ax               ; 6AEC  pointer to the player's bitmap
        mov     ax, SVLEN                ; 6AEF  AX -- the saved chain length
        mov     ANIMLEN, ax              ; 6AF2  the highest frame number is back
        mov     OBJVX, 0                 ; 6AF5  the player stands still
        mov     BYTE PTR OBJVY, 0        ; 6AFA  the vertical speed is zeroed
        or      INBITS, 1                ; 6AFF  bit 0 set: the player is on the screen
        mov     GSTATE, 7                ; 6B04  state 7 -- the game is over
        stc                              ; 6B09  CF=1 -- the frame was cut short
        ret                              ; 6B0A  return

;-----------------------------------------------------------------------
; MOVEPLR -- Apply OBJVX/OBJVY, test the screen edges, and change rooms
; when the player walks off one.
;
; EXIT   : CF
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: PLRSTEP
;-----------------------------------------------------------------------
MOVEPLR:
        cmp     OBJVX, 0                 ; 6B0B  is the player heading left?
        jl      LMOVEP3                  ; 6B10  left -- look at the tile on that side
        mov     al, TILERT               ; 6B12  AL -- the tile to the right
LMOVEP1:
        mov     si, 3                    ; 6B15  three tiles in the list
        mov     bp, OFFSET GATETIL       ; 6B18  the tiles you cannot walk through
        call    INLIST                   ; 6B1B  is AL in the list
        jb      LMOVEP2                  ; 6B1E  CF=1 -- something in the way
        xor     ah, ah                   ; 6B20  AH=0: the whole tile now sits in AX
        cmp     ax, 1                    ; 6B22  tile 1 -- the floor
        jne     LMOVEP4                  ; 6B25  not the floor -- he may walk on
LMOVEP2:
        mov     al, 0                    ; 6B27  AL=0
        cmp     al, BYTE PTR OBJVY       ; 6B29  is the player moving upward?
        jg      LMOVEP5                  ; 6B2D  he is -- leave the speed alone
        mov     OBJVX, al                ; 6B2F  the horizontal speed is killed
        jmp     LMOVEP5                  ; 6B32  move the player
LMOVEP3:
        mov     al, TILELF               ; 6B35  AL -- the tile to the left
        jmp     short LMOVEP1            ; 6B38  go and test for an obstacle
LMOVEP4:
        mov     al, OBJVX                ; 6B3A  AL -- the horizontal speed
LMOVEP5:
        mov     si, 0                    ; 6B3D  SI=0 -- the player
        mov     ah, 0                    ; 6B40  AH=0 -- move along the X axis
        call    OBJMOVE                  ; 6B42  shift the player along X
        mov     al, BYTE PTR OBJVY       ; 6B45  AL -- the vertical speed
        cmp     al, 0                    ; 6B48  is the player still vertically?
        je      LMOVEP6                  ; 6B4A  still
        mov     si, 0                    ; 6B4C  SI=0 -- the player
        mov     ah, 1                    ; 6B4F  AH=1 -- move along the Y axis
        call    OBJMOVE                  ; 6B51  shift the player along Y
LMOVEP6:
        mov     bx, OFFSET OBJTBL        ; 6B54  BX -- object table, object 0 is the player
        cmp     BYTE PTR [bx+OB_X], 4Ch  ; 6B57  4Ch = 76 -- right edge of the room
        jl      LMOVEP7                  ; 6B5B  not the edge
        jmp     LMOVEP14                 ; 6B5D  past the edge -- off to the next room
LMOVEP7:
        cmp     BYTE PTR [bx+OB_X], 1    ; 6B60  byte one -- left edge of the room
        jge     LMOVEP8                  ; 6B64  not the edge
        jmp     LMOVEP15                 ; 6B66  past the edge -- off to the next room
LMOVEP8:
        mov     al, [bx+OB_Y]            ; 6B69  AL -- the player's Y
        shr     al, 1                    ; 6B6C  bit 0 picks the field
        cmp     al, 0                    ; 6B6E  the topmost line?
        jne     LMOVEP9                  ; 6B70  no
        jmp     LMOVEP12                 ; 6B72  walked off the top -- one floor up
LMOVEP9:
        mov     al, [bx+OB_Y]            ; 6B75  AL -- the player's Y
        shr     al, 1                    ; 6B78  bit 0 picks the field
        cmp     al, 58h                  ; 6B7A  58h = 88 -- bottom of the room
        jg      LMOVEP10                 ; 6B7C  below it -- one floor down
        clc                              ; 6B7E  CF=0 -- the player is still inside the room
        ret                              ; 6B7F  return
LMOVEP10:
        inc     FLOOR                    ; 6B80  one floor further down the pyramid
        mov     BYTE PTR [bx+OB_Y], 2    ; 6B84  the player will come in near the top of the room
LMOVEP11:
        mov     al, [bx+OB_Y]            ; 6B88  AL -- the player's Y
        mov     SVY, al                  ; 6B8B  keep Y for the new room
        mov     al, [bx+OB_X]            ; 6B8E  AL -- the player's X
        mov     SVX, al                  ; 6B91  keep X as well
        mov     al, PLRST                ; 6B94  AL -- the player's state
        mov     SVST, al                 ; 6B97  keep the state
        mov     ax, ANIMPTR              ; 6B9A  AX -- the frame chain
        mov     SVANIM, ax               ; 6B9D  keep the chain
        mov     bp, ax                   ; 6BA0  BP -- head of the chain
        mov     ax, ANIMIDX              ; 6BA2  AX -- frame number within the chain
        mov     SVIDX2, ax               ; 6BA5  keep the number
        mov     si, ax                   ; 6BA8  SI -- the same number as an index
        mov     al, ds:[bp+si]           ; 6BAA  AL -- the frame
        mov     FRMSAVE, al              ; 6BAD  keep the frame
        mov     ax, ANIMLEN              ; 6BB0  AX -- highest frame number in the chain
        mov     SVLEN, ax                ; 6BB3  keep the length
        call    ROOMDRW                  ; 6BB6  build the new room and redraw it
        stc                              ; 6BB9  CF=1 -- the frame was cut short
        ret                              ; 6BBA  return
LMOVEP12:
        cmp     PLRST, 2                 ; 6BBB  state 2 -- jumping
        je      LMOVEP13                 ; 6BC0  no room change while in mid-jump
        dec     FLOOR                    ; 6BC2  one floor further up the pyramid
        mov     BYTE PTR [bx+OB_Y], 0B1h ; 6BC6  B1h -- the player will come in near the bottom of the room
        jmp     short LMOVEP11           ; 6BCA  move into the new room
LMOVEP13:
        mov     BYTE PTR [bx+OB_Y], 2    ; 6BCC  the player is stopped against line two
        clc                              ; 6BD0  CF=0 -- the same room as before
        ret                              ; 6BD1  return
LMOVEP14:
        inc     ROOMPOS                  ; 6BD2  one position right along the floor
        mov     BYTE PTR [bx+OB_X], 1    ; 6BD6  the player will come in at the left edge
        jmp     short LMOVEP11           ; 6BDA  move into the new room
LMOVEP15:
        dec     ROOMPOS                  ; 6BDC  one position left along the floor
        mov     BYTE PTR [bx+OB_X], 4Bh  ; 6BE0  4Bh = 75 -- right edge of the room
        jmp     short LMOVEP11           ; 6BE4  move into the new room

;-----------------------------------------------------------------------
; LADDER -- Tile in object SI's own cell equals 2Bh -> CF (it can climb up).
;
; ENTRY  : SI
; EXIT   : CF
; ALTERS : nothing
; CALLED BY: PST_0
;-----------------------------------------------------------------------
LADDER:
        SAVEREG <ax,bx>                  ; 6BE6  macro
        mov     bx, OFFSET TILEAT        ; 6BE8  table of own-cell tiles, one slot per object
        mov     al, [bx+si]              ; 6BEB  AL -- tile in the cell of object SI
        xor     ah, ah                   ; 6BED  AH=0: the whole tile now sits in AX
        cmp     ax, 2Bh                  ; 6BEF  2Bh -- a ladder
        je      LLADDE1                  ; 6BF2  that one -- climbing is allowed
        clc                              ; 6BF4  CF=0 -- no ladder here
        jmp     LLADDE2                  ; 6BF5  off to the common exit
LLADDE1:
        stc                              ; 6BF8  CF=1 -- there is a ladder
LLADDE2:
        RESTREG <bx,ax>                  ; 6BF9  macro
        ret                              ; 6BFB  return: the answer is in CF

;-----------------------------------------------------------------------
; LADDDN -- Tile underfoot of object SI equals 29h -> CF (it can climb down).
;
; ENTRY  : SI
; EXIT   : CF
; ALTERS : nothing
; CALLED BY: PST_0
;-----------------------------------------------------------------------
LADDDN:
        SAVEREG <ax,bx>                  ; 6BFC  macro
        mov     bx, OFFSET TILEDN        ; 6BFE  table of underfoot tiles, one slot per object
        mov     al, [bx+si]              ; 6C01  AL -- tile underfoot of object SI
        xor     ah, ah                   ; 6C03  AH=0: the whole tile now sits in AX
        cmp     ax, 29h                  ; 6C05  29h -- top of a ladder
        je      LLADDD1                  ; 6C08  that one -- going down is allowed
        clc                              ; 6C0A  CF=0 -- no way down here
        jmp     LLADDD2                  ; 6C0B  off to the common exit
LLADDD1:
        stc                              ; 6C0E  CF=1 -- there is a way down
LLADDD2:
        RESTREG <bx,ax>                  ; 6C0F  macro
        ret                              ; 6C11  return: the answer is in CF

;-----------------------------------------------------------------------
; STANDCK -- Is the player standing: ANIMPTR = ANIMTB or AN_STNDR -> CF=0.
;
; EXIT   : CF
; ALTERS : nothing
; CALLED BY: BELTPUSH, PLRHIT, PST_5
;-----------------------------------------------------------------------
STANDCK:
        push    ax                       ; 6C12  AX comes back at 6C25
        mov     ax, ANIMPTR              ; 6C13  AX -- the player's frame chain
        cmp     ax, OFFSET ANIMTB        ; 6C16  the "standing, facing right" chain
        je      LSTAND1                  ; 6C19  that one
        cmp     ax, OFFSET AN_STNDR      ; 6C1B  the second standing chain
        je      LSTAND1                  ; 6C1E  that one
        stc                              ; 6C20  CF=1 -- the player is not standing
        jmp     LSTAND2                  ; 6C21  off to the common exit
LSTAND1:
        clc                              ; 6C24  CF=0 -- the player is standing
LSTAND2:
        pop     ax                       ; 6C25  AX restored
        ret                              ; 6C26  return: the answer is in CF

;-----------------------------------------------------------------------
; DOORSID -- Which way the belt runs, by TILEDN: 75..77 -> SI=0, 72..74 -> SI=1.
;
; ENTRY  : TILEDN
; EXIT   : SI, CF
; ALTERS : nothing
; CALLED BY: BELTPUSH, PST_5
;-----------------------------------------------------------------------
DOORSID:
        push    ax                       ; 6C27  AX comes back at 6C5A
        mov     al, TILEDN               ; 6C28  AL -- the tile underfoot
        xor     ah, ah                   ; 6C2B  AH=0: the whole tile now sits in AX
        cmp     ax, 75h                  ; 6C2D  75h -- belt, first tile
        je      LDOORS1                  ; 6C30  that one
        cmp     ax, 76h                  ; 6C32  76h -- belt, second tile
        je      LDOORS1                  ; 6C35  that one
        cmp     ax, 77h                  ; 6C37  77h -- belt, third tile
        je      LDOORS1                  ; 6C3A  that one
        cmp     ax, 72h                  ; 6C3C  72h -- belt the other way, first tile
        je      LDOORS2                  ; 6C3F  that one
        cmp     ax, 73h                  ; 6C41  73h -- belt the other way, second tile
        je      LDOORS2                  ; 6C44  that one
        cmp     ax, 74h                  ; 6C46  74h -- belt the other way, third tile
        je      LDOORS2                  ; 6C49  that one
        clc                              ; 6C4B  CF=0 -- no belt underfoot
        jmp     LDOORS3                  ; 6C4C  off to the common exit
LDOORS1:
        mov     si, 0                    ; 6C4F  SI=0 -- belt running the first way
        stc                              ; 6C52  CF=1 -- there is a belt
        jmp     LDOORS3                  ; 6C53  off to the common exit
LDOORS2:
        mov     si, 1                    ; 6C56  SI=1 -- belt running the second way
        stc                              ; 6C59  CF=1 -- there is a belt
LDOORS3:
        pop     ax                       ; 6C5A  AX restored
        ret                              ; 6C5B  return: the side in SI, the answer in CF

CSEG    ENDS
        END
