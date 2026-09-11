        PAGE  60,132
        TITLE STATES -- THE GAME STATE MACHINE
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC GSTATE
        PUBLIC LITNOW
        PUBLIC NOP0
        PUBLIC RESTUSE
        PUBLIC RNDSEED
        PUBLIC ROOMDRW
        PUBLIC STTAB
        PUBLIC TTLSTEP
        EXTRN  ANIMHIT:NEAR
        EXTRN  ANIMLEN:WORD
        EXTRN  ANIMPTR:WORD
        EXTRN  ANIMTB:WORD
        EXTRN  ANIMTL:NEAR
        EXTRN  AN_STNDL:WORD
        EXTRN  AN_STNDR:WORD
        EXTRN  BLDMAP:NEAR
        EXTRN  CLRTXT:NEAR
        EXTRN  CMDBITS:WORD
        EXTRN  DARKEN:NEAR
        EXTRN  DEADBIT:BYTE
        EXTRN  DIRBIT:NEAR
        EXTRN  DRWALL:NEAR
        EXTRN  DRWALL2:NEAR
        EXTRN  ENDPTR:WORD
        EXTRN  ENEMOVE:NEAR
        EXTRN  ERSALL:NEAR
        EXTRN  FLOOR:BYTE
        EXTRN  FRAMEC:BYTE
        EXTRN  INBITS:BYTE
        EXTRN  JUMPIDX:WORD
        EXTRN  KEYPOLL:NEAR
        EXTRN  LAPTMR:BYTE
        EXTRN  LASTKEY:WORD
        EXTRN  LEVEL:BYTE
        EXTRN  LITCHK:NEAR
        EXTRN  LIVES:BYTE
        EXTRN  MENUKEY:NEAR
        EXTRN  MKOBJF:BYTE
        EXTRN  MKROOM:NEAR
        EXTRN  MKSOLD:NEAR
        EXTRN  NEWGAME:NEAR
        EXTRN  OBJTBL:WORD
        EXTRN  OBJVX:BYTE
        EXTRN  PLRHIT:NEAR
        EXTRN  PLRST:BYTE
        EXTRN  PLRSTEP:NEAR
        EXTRN  PLRTICK:NEAR
        EXTRN  PLR_ANH:BYTE
        EXTRN  PLR_X:BYTE
        EXTRN  PUTBAR:NEAR
        EXTRN  PUTHUD:NEAR
        EXTRN  PUTRCT:NEAR
        EXTRN  RCTREC:WORD
        EXTRN  RCTSHOW:NEAR
        EXTRN  RDPTR:WORD
        EXTRN  READCMD:NEAR
        EXTRN  ROOMNO:BYTE
        EXTRN  ROOMPOS:BYTE
        EXTRN  SCORE:BYTE
        EXTRN  TTLEND:BYTE
        EXTRN  TTLMAP:BYTE
        EXTRN  SCRMAP:BYTE
        EXTRN  SCRMENU:NEAR
        EXTRN  SCRTTL:NEAR
        EXTRN  SEENMAP:WORD
        EXTRN  SHOWSCR:NEAR
        EXTRN  SOLIDS:BYTE
        EXTRN  SVANIM:WORD
        EXTRN  SVIDX2:WORD
        EXTRN  SVLEN:WORD
        EXTRN  SVST:BYTE
        EXTRN  SVY:BYTE
        EXTRN  TILEDN:BYTE
        EXTRN  TILRST:NEAR
        EXTRN  VIDINI:NEAR

;=======================================================================
; STATES.ASM -- THE GAME STATE MACHINE
;
; The NOP0 stub, GSTATE, STTAB and the ten handlers: title screen,
; play, death, redraw, menu, end of game. After them comes WAITF5 --
; the key poll that runs on the GAME OVER screen.
;=======================================================================

;-----------------------------------------------------------------------
; NOP0 -- An empty routine: nothing but a RET.
;
; ALTERS : nothing
; CALLED BY: DRAWFRM, SCRTTL, SHOWSCR, ST_DRW, ST_PL1, ST_PL2, ST_PL3,
;          ST_X7
;-----------------------------------------------------------------------
NOP0:
        ret                              ; 60C0  return at once: this handler has nothing whatever to do

;-----------------------------------------------------------------------
; THE GAME STATE MACHINE  (60C1..60F3, 51 bytes)
;
; 60D0h GSTATE -- state index, 8 at startup (the menu)
; 60D3h BARRCT -- rectangle of the GAME OVER sign, for PUTRCT
; 60E0h STTAB  -- the ten handler addresses
;-----------------------------------------------------------------------
        DB    15 DUP (0)                 ; 60C1..60CF
; index of the machine's state, starts at 8 = the menu
GSTATE  DB    00h                        ; 60D0
RNDSEED DB    00h                        ; 60D1  ROOMNO+FRAMEC: the scatter BEH_CLMB draws its decisions from
TTLSTEP DB    00h                        ; 60D2  1 = the walking figure has stopped, ST_DRW is counting down
; rectangle of the GAME OVER sign: row, column, height, width
BARRCT  DW    0Ch,0Bh,2,12h              ; 60D3
        DW    0FFh                       ; 60DB  terminator of a PUTRCT list
RESTUSE DB    00h                        ; 60DD  1 = the quick restart out of GAME OVER has been used up
; 1 = a torch was picked up this frame, redraw the room lit
LITNOW  DB    00h                        ; 60DE
TREATMR DB    00h                        ; 60DF  turns of FRAMEC left before leaving the treasure chamber
; transition table of the state machine, 10 words
STTAB   LABEL WORD                       ; 60E0
        DW    ST_INI                     ; 60E0  0 initialization
        DW    ST_TTL                     ; 60E2  1 title screen
        DW    ST_PL1                     ; 60E4  2 play
        DW    ST_PL2                     ; 60E6  3 play
        DW    ST_PL3                     ; 60E8  4 treasure chamber
        DW    ST_DRW                     ; 60EA  5 redraw
        DW    ST_X6                      ; 60EC  6 falls through to 7
        DW    ST_X7                      ; 60EE  7 end of a life
        DW    ST_TITLE                   ; 60F0  8 menu, first entry
        DW    ST_MENU                    ; 60F2  9 menu

;-----------------------------------------------------------------------
; ST_INI -- State 0: initialization once the program is up.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: STTAB[0]
;-----------------------------------------------------------------------
ST_INI:
        call    VIDINI                   ; 60F4  mode 4, palette, master tiles, the player object
        call    TTLROOM                  ; 60F7  put the title screen picture together
        inc     GSTATE                   ; 60FA  next state along is the title screen
        stc                              ; 60FE  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 60FF  return

;-----------------------------------------------------------------------
; ST_TTL -- State 1: the title screen with its walking figure.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: STTAB[1]
;-----------------------------------------------------------------------
ST_TTL:
        call    ST_DRW                   ; 6100  run one redraw frame through the state 5 handler
        cmp     GSTATE, 2                ; 6103  state 2 means play has begun
        jne     LSTTTL1                  ; 6108  not that one -- leave everything as it stands
        dec     GSTATE                   ; 610A  drop straight back into state 1
        call    AUTOCMD                  ; 610E  feed the figure its controls in the player's place
        cmp     PLR_X, 6                 ; 6111  has the figure reached byte six across?
        jl      LSTTTL1                  ; 6116  not yet -- keep walking
        mov     ax, 0                    ; 6118  AX=0
        mov     PLRST, al                ; 611B  player state 0 -- standing still
        inc     GSTATE                   ; 611E  on to the next state
LSTTTL1:
        stc                              ; 6122  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 6123  return

;-----------------------------------------------------------------------
; ST_PL1 -- State 2: play, the main frame.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: STTAB[2]
;-----------------------------------------------------------------------
ST_PL1:
        call    TILRST                   ; 6124  refill the live tiles from their master copies
        call    NOP0                     ; 6127  empty routine: one of eight such calls in the image
        call    ERSALL                   ; 612A  erase every sprite, putting the background back
        call    DIRBIT                   ; 612D  read the tiles around every live object into TILELF..TILEDN
        mov     ax, 4                    ; 6130  player state 4 -- the title screen autopilot
        cmp     al, PLRST                ; 6133  is the player in state 4?
        je      LSTPL1                   ; 6137  autopilot -- do not read the controls at all
        call    DEMOCMD                  ; 6139  autopilot command for the title screen
        jae     LSTPL2                   ; 613C  CF=0 -- a command came back, use it
LSTPL1:
        mov     ax, 1                    ; 613E  AX=1
        mov     ah, al                   ; 6141  AH=1 -- direction up
        xor     al, al                   ; 6143  AL=0 -- no buttons held
        mov     CMDBITS, ax              ; 6145  the control command for this frame
LSTPL2:
        call    ANIMTL                   ; 6148  cycle the animated tiles: belts, blinking floors
        call    PLRSTEP                  ; 614B  one step of the player: physics and state
        jb      LSTPL4                   ; 614E  CF=1 -- the frame was cut short
        call    ENEMOVE                  ; 6150  give every live object its turn
        call    DIRBIT                   ; 6153  read the tiles around every live object into TILELF..TILEDN
        call    PLRSTEP                  ; 6156  second player step of the frame: the game runs at half speed
        jb      LSTPL4                   ; 6159  CF=1 -- the frame was cut short
        call    ENEMOVE                  ; 615B  second object turn of the frame
        call    ANIMHIT                  ; 615E  collisions and frame advance for every animation chain
        cmp     FLOOR, 0                 ; 6161  floor 0 -- the top of the pyramid
        jne     LSTPL3                   ; 6166  not the top
        mov     ax, 6                    ; 6168  player state 6
        cmp     al, PLRST                ; 616B  is the player in state 6?
        jne     LSTPL3                   ; 616F  not that one
        inc     GSTATE                   ; 6171  on to the next state
        mov     SVY, 2Ch                 ; 6175  saved Y -- 2Ch
        mov     SVANIM, OFFSET ANIMTB    ; 617A  frame chain -- head of ANIMTB
        add     SVANIM, 2                ; 6180  step over the first entry
        mov     ax, 0                    ; 6185  AX=0
        mov     SVST, al                 ; 6188  saved player state 0
        mov     SVIDX2, 0                ; 618B  no frames stepped through yet
        mov     SVLEN, 0                 ; 6191  chain length 0
LSTPL3:
        mov     di, OFFSET SOLIDS        ; 6197  DI -- the floor-span list, itself a list of rectangles
        call    PUTRCT                   ; 619A  redraw the tiles over every floor span
        call    DRWALL2                  ; 619D  draw every sprite, saving the background under it
LSTPL4:
        stc                              ; 61A0  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 61A1  return

;-----------------------------------------------------------------------
; DEMOCMD -- The title screen autopilot: it makes up a control command
; from the player's X coordinate.
; ENTRY  : PLR_X
; EXIT   : CMDBITS
; ALTERS : AX
; CALLED BY: AUTOCMD (via JMP), ST_PL1
;-----------------------------------------------------------------------
DEMOCMD:
        mov     al, PLR_X                ; 61A2  AL -- the player's X in bytes of video RAM
        cmp     al, 1Ah                  ; 61A5  1Ah = 26
        jl      AUTOCMD                  ; 61A7  further left -- walk right
        cmp     al, 30h                  ; 61A9  30h = 48
        jge     LAUTOC2                  ; 61AB  further right -- walk left
        cmp     al, 27h                  ; 61AD  27h = 39
        jl      LAUTOC3                  ; 61AF  further left -- walk right and jump
        mov     ax, DIR_LF               ; 61B1  AL -- direction left
LDEMOC1:
        mov     ah, al                   ; 61B4  AH -- the direction bits
        mov     al, BTN_JUMP             ; 61B6  AL=10h -- bit 4 set: the jump button is not held
        mov     CMDBITS, ax              ; 61B8  the control command for this frame
        mov     al, TILEDN               ; 61BB  AL -- the tile under the player's feet
        xor     ah, ah                   ; 61BE  AH=0: the whole tile now sits in AX
        cmp     ax, 6                    ; 61C0  tile 6
        jne     LDEMOC2                  ; 61C3  not that one
        stc                              ; 61C5  CF=1 -- no command this time
        ret                              ; 61C6  return
LDEMOC2:
        clc                              ; 61C7  CF=0 -- the command has been made up
        ret                              ; 61C8  return

;-----------------------------------------------------------------------
; AUTOCMD -- Feed the figure its controls: direction 8 or 4 into CMDBITS.
; This is how the figure walks across the title screen.
;
; EXIT   : CMDBITS
; ALTERS : AX, BX
; CALLED BY: ST_TTL
;-----------------------------------------------------------------------
AUTOCMD:
        mov     ax, DIR_RT               ; 61C9  AL -- direction right
LAUTOC1:
        mov     ah, al                   ; 61CC  AH -- the direction bits
        mov     bx, BTN_JUMP             ; 61CE  BL=10h -- the jump button bit
        xor     bl, 0FFh                 ; 61D1  EFh: bit 4 cleared -- the button reads as held
        mov     al, bl                   ; 61D4  AL -- the button byte
        mov     CMDBITS, ax              ; 61D6  the control command for this frame
        jmp     short LDEMOC2            ; 61D9  CF=0 and return
LAUTOC2:
        mov     ax, DIR_LF               ; 61DB  AL -- direction left
        jmp     short LAUTOC1            ; 61DE  build the command with the jump held
LAUTOC3:
        mov     ax, DIR_RT               ; 61E0  AL -- direction right
        jmp     short LDEMOC1            ; 61E3  build the command with the jump held

;-----------------------------------------------------------------------
; ST_PL2 -- State 3: play, movement and collisions worked through.
;
; ALTERS : CX, DX, SI, DI, BP, ES
; CALLED BY: STTAB[3]
;-----------------------------------------------------------------------
ST_PL2:
        push    bx                       ; 61E5  BX comes back at 61F6
        mov     bx, OFFSET OBJTBL        ; 61E6  BX -- object table, object 0 is the player
        mov     al, [bx+OB_X]            ; 61E9  AL -- the player's X
        add     al, [bx+OB_Y]            ; 61EC  plus the player's Y
        add     al, FRAMEC               ; 61EF  plus the frame counter
        mov     RNDSEED, al              ; 61F3  random number seed, stirred once a frame
        pop     bx                       ; 61F6  BX restored
        call    NOP0                     ; 61F7  empty routine: one of eight such calls in the image
        call    ANIMTL                   ; 61FA  cycle the animated tiles: belts, blinking floors
        call    DIRBIT                   ; 61FD  read the tiles around every live object into TILELF..TILEDN
        call    PLRTICK                  ; 6200  one player step, collisions checked along the way
        jb      LSTPL7                   ; 6203  CF=1 -- the frame was cut short
        call    ENEMOVE                  ; 6205  give every live object its turn
        call    DIRBIT                   ; 6208  read the tiles around every live object into TILELF..TILEDN
        call    PLRTICK                  ; 620B  second player step of the frame
        jb      LSTPL7                   ; 620E  CF=1 -- the frame was cut short
        call    ENEMOVE                  ; 6210  second object turn of the frame
        call    ANIMHIT                  ; 6213  collisions and frame advance for every animation chain
        xor     ah, ah                   ; 6216  AH=0
        mov     al, INBITS               ; 6218  AL -- one bit per live object
        push    ax                       ; 621B  AX comes back at 6226
        or      al, DEADBIT              ; 621C  fold in the bit of the object just killed
        mov     INBITS, al               ; 6220  so that its sprite gets erased along with the rest
        call    ERSALL                   ; 6223  erase every sprite, putting the background back
        pop     ax                       ; 6226  AL -- the live-object bits as they were
        mov     INBITS, al               ; 6227  the bits are back the way they were
        mov     DEADBIT, 0               ; 622A  the killed-object bit is cleared again
        mov     ax, RCTREC               ; 622F  the dirty rectangles built up this frame
        cmp     ax, 0                    ; 6232  is there anything to show
        je      LSTPL5                   ; 6235  nothing at all
        call    RCTSHOW                  ; 6237  put out every rectangle that was built up
        mov     RCTREC, 0                ; 623A  the list is emptied again
LSTPL5:
        mov     di, OFFSET SOLIDS        ; 6240  DI -- the floor-span list, itself a list of rectangles
        call    PUTRCT                   ; 6243  redraw the tiles over every floor span
        call    PLRHIT                   ; 6246  the player against every object: hits and pickups
        call    DRWALL2                  ; 6249  draw every sprite, saving the background under it
        cmp     LITNOW, 0                ; 624C  did the lighting just change?
        je      LSTPL6                   ; 6251  no
        mov     MKOBJF, 0                ; 6253  do not create the objects over again
        call    ROOMDRW                  ; 6258  rebuild the room map and redraw the whole frame
        mov     MKOBJF, 1                ; 625B  objects are created as usual from here on
LSTPL6:
        stc                              ; 6260  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 6261  return
LSTPL7:
        cmp     ROOMNO, 64h              ; 6262  64h = 100 -- the treasure chamber
        jne     LSTPL8                   ; 6267  some other room
        mov     FRAMEC, 1                ; 6269  frame counter starts over at one
        mov     TREATMR, 1               ; 626E  treasure chamber timer
        inc     GSTATE                   ; 6273  on to the next state
LSTPL8:
        stc                              ; 6277  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 6278  return

;-----------------------------------------------------------------------
; ROOMDRW -- Build the room and redraw the frame right away: MKROOM,
; then fall straight through into DRAWFRM.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: MOVEPLR, PST_789, ST_PL2, ST_X7
;-----------------------------------------------------------------------
ROOMDRW:
        call    MKROOM                   ; 6279  build the room map out of its byte code

;-----------------------------------------------------------------------
; DRAWFRM -- Full frame redraw: collisions, objects, floor spans, the
; lighting and the map output. On the way out it drains the BIOS
; keyboard buffer dry.
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: ROOMDRW (falls through), TTLROOM
;-----------------------------------------------------------------------
DRAWFRM:
        call    ANIMHIT                  ; 627C  collisions and frame advance for every animation chain
        call    DRWALL                   ; 627F  redraw the whole screen from the map
        call    MKSOLD                   ; 6282  build the floor-span list by scanning SCRMAP
        call    DRWALL2                  ; 6285  draw every sprite, saving the background under it
        call    NOP0                     ; 6288  empty routine: one of eight such calls in the image
        cmp     LITNOW, 0                ; 628B  did the lighting just change?
        jne     LDRAWF1                  ; 6290  yes -- put the master tiles back
        call    LITCHK                   ; 6292  is the room dark
        jae     LDRAWF1                  ; 6295  CF=0 -- the room is lit
        call    DARKEN                   ; 6297  dark -- blank the tiles out
        jmp     LDRAWF2                  ; 629A  the lighting did not change
LDRAWF1:
        call    TILRST                   ; 629D  refill the live tiles from their master copies
LDRAWF2:
        call    DRWALL                   ; 62A0  redraw the whole screen from the map
        call    DRWALL2                  ; 62A3  draw every sprite, saving the background under it
        call    SHOWSCR                  ; 62A6  push the finished map out to video RAM
LDRAWF3:
        xor     al, al                   ; 62A9  AL takes no part here, cleared along the way
        mov     ah, 1                    ; 62AB  AH=1: is a key waiting in the buffer
        int     16h                      ; 62AD  keyboard BIOS
        je      LDRAWF4                  ; 62AF  the buffer is empty
        xor     ax, ax                   ; 62B1  AH=0: take the key out of the buffer
        int     16h                      ; 62B3  keyboard BIOS
        jmp     short LDRAWF3            ; 62B5  keep draining until the buffer is dry
LDRAWF4:
        ret                              ; 62B7  return: the frame has been redrawn

;-----------------------------------------------------------------------
; ST_PL3 -- State 4: play, the death animation and the room change.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: STTAB[4]
;-----------------------------------------------------------------------
ST_PL3:
        call    NOP0                     ; 62B8  empty routine: one of eight such calls in the image
        cmp     FRAMEC, 0                ; 62BB  has the frame counter come around to zero?
        jne     LSTPL9                   ; 62C0  no
        dec     TREATMR                  ; 62C2  treasure chamber timer
        jl      LSTPL14                  ; 62C6  timer ran out -- the level is over
LSTPL9:
        call    DIRBIT                   ; 62C8  read the tiles around every live object into TILELF..TILEDN
        call    PLRTICK                  ; 62CB  one player step, collisions checked along the way
        jb      LSTPL10                  ; 62CE  CF=1 -- the frame was cut short
        call    DIRBIT                   ; 62D0  read the tiles around every live object into TILELF..TILEDN
        call    PLRTICK                  ; 62D3  second player step of the frame
        jae     LSTPL11                  ; 62D6  CF=0 -- the frame was not cut short
LSTPL10:
        mov     ax, 5                    ; 62D8  player state 5 -- dying
        cmp     al, PLRST                ; 62DB  is the player in state 5?
        je      LSTPL14                  ; 62DF  dying -- wind the level up
LSTPL11:
        call    ANIMHIT                  ; 62E1  collisions and frame advance for every animation chain
        call    ERSALL                   ; 62E4  erase every sprite, putting the background back
        mov     ax, RCTREC               ; 62E7  the dirty rectangles built up this frame
        cmp     ax, 0                    ; 62EA  is there anything to show
        je      LSTPL12                  ; 62ED  nothing at all
        call    RCTSHOW                  ; 62EF  put out every rectangle that was built up
        mov     RCTREC, 0                ; 62F2  the list is emptied again
LSTPL12:
        cmp     LAPTMR, 0                ; 62F8  room-change timer
        jne     LSTPL13                  ; 62FD  a change is under way -- no collisions during it
        call    PLRHIT                   ; 62FF  the player against every object: hits and pickups
LSTPL13:
        call    DRWALL2                  ; 6302  draw every sprite, saving the background under it
        stc                              ; 6305  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 6306  return
LSTPL14:
        inc     LEVEL                    ; 6307  difficulty level one step on
        cmp     LEVEL, 0Ah               ; 630B  0Ah = 10 -- the ceiling
        jl      LSTPL15                  ; 6310  not reached
        mov     LEVEL, 9                 ; 6312  it never climbs past the ninth
LSTPL15:
        mov     LAPTMR, 2                ; 6317  room-change timer
        mov     ax, 0                    ; 631C  AX=0 -- not a single bit
        mov     cx, 65h                  ; 631F  65h = 101 words in the seen map
        mov     di, OFFSET SEENMAP       ; 6322  DI -- the seen map
        rep stosw                        ; 6325  everything picked up is forgotten again
        mov     ax, 5                    ; 6327  player state 5 -- dying
        cmp     al, PLRST                ; 632A  is the player in state 5?
        je      LSTPL18                  ; 632E  dying -- do not move the player about
        cmp     ROOMPOS, 9               ; 6330  positions 0..8 -- the left half
        jge     LSTPL16                  ; 6335  the right half
        mov     ax, OFFSET AN_STNDL      ; 6337  frame chain "standing, facing left"
        mov     ANIMPTR, ax              ; 633A  the player's frame chain is set
        mov     ax, AN_STNDL             ; 633D  first word of the chain -- the frame address
        add     ax, 2                    ; 6340  step over the frame header
        mov     BYTE PTR OBJTBL, al      ; 6343  low byte of the player's frame address
        mov     PLR_ANH, ah              ; 6346  high byte of the frame address
        mov     al, 0FFh                 ; 634A  AL=FFh -- speed to the left
        jmp     LSTPL17                  ; 634C  set speed and state in the shared code below
LSTPL16:
        mov     ax, OFFSET AN_STNDR      ; 634F  frame chain "standing, facing right"
        mov     ANIMPTR, ax              ; 6352  the player's frame chain is set
        mov     ax, AN_STNDR             ; 6355  first word of the chain -- the frame address
        add     ax, 2                    ; 6358  step over the frame header
        mov     BYTE PTR OBJTBL, al      ; 635B  low byte of the player's frame address
        mov     PLR_ANH, ah              ; 635E  high byte of the frame address
        mov     al, 2                    ; 6362  AL=2 -- speed to the right
LSTPL17:
        mov     OBJVX, al                ; 6364  the player's speed along X
        mov     ax, 2                    ; 6367  AX=2
        mov     PLRST, al                ; 636A  player state 2 -- walking
        mov     JUMPIDX, 7               ; 636D  jump phase 7
        mov     ANIMLEN, 0               ; 6373  one frame in the chain: highest number is 0
LSTPL18:
        inc     GSTATE                   ; 6379  on to the next state
        stc                              ; 637D  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 637E  return

;-----------------------------------------------------------------------
; ST_DRW -- State 5: redraw the screen.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: STTAB[5], ST_TTL
;-----------------------------------------------------------------------
ST_DRW:
        call    NOP0                     ; 637F  empty routine: one of eight such calls in the image
        call    ANIMTL                   ; 6382  cycle the animated tiles: belts, blinking floors
        call    ERSALL                   ; 6385  erase every sprite, putting the background back
        call    DIRBIT                   ; 6388  read the tiles around every live object into TILELF..TILEDN
        call    PLRSTEP                  ; 638B  one step of the player: physics and state
        jb      LSTDRW3                  ; 638E  CF=1 -- the frame was cut short
        call    DIRBIT                   ; 6390  read the tiles around every live object into TILELF..TILEDN
        call    PLRSTEP                  ; 6393  second player step of the frame
        jb      LSTDRW3                  ; 6396  CF=1 -- the frame was cut short
        call    ANIMHIT                  ; 6398  collisions and frame advance for every animation chain
        mov     di, OFFSET SOLIDS        ; 639B  DI -- the floor-span list, itself a list of rectangles
        call    PUTRCT                   ; 639E  redraw the tiles over every floor span
        cmp     TTLSTEP, 0               ; 63A1  is the title screen running
        jne     LSTDRW1                  ; 63A6  it is
        mov     ax, 5                    ; 63A8  player state 5 -- dying
        cmp     al, PLRST                ; 63AB  is the player in state 5?
        jne     LSTDRW1                  ; 63AF  not dying
        mov     TTLSTEP, 1               ; 63B1  the title screen sequence has begun
LSTDRW1:
        cmp     LAPTMR, 0                ; 63B6  room-change timer
        jne     LSTDRW2                  ; 63BB  a change is under way
        mov     ax, 5                    ; 63BD  player state 5 -- dying
        cmp     al, PLRST                ; 63C0  is the player in state 5?
        je      LSTDRW2                  ; 63C4  dying -- leave the state alone
        mov     GSTATE, 2                ; 63C6  state 2 -- play
        mov     TTLSTEP, 0               ; 63CB  the title screen sequence is over
LSTDRW2:
        call    DRWALL2                  ; 63D0  draw every sprite, saving the background under it
        stc                              ; 63D3  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 63D4  return
LSTDRW3:
        cmp     TTLSTEP, 0               ; 63D5  is the title screen running
        je      LSTDRW4                  ; 63DA  it is not
        dec     LAPTMR                   ; 63DC  room-change timer
        cmp     LAPTMR, 0                ; 63E0  has it run out?
        jne     LSTDRW4                  ; 63E5  the timer has not run out
        jmp     TTLROOM                  ; 63E7  build the title screen picture over again
LSTDRW4:
        stc                              ; 63EA  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 63EB  return

;-----------------------------------------------------------------------
; TTLROOM -- Put the title screen picture together: clear SCRMAP, lay
; the panel in, then BLDMAP over the TTLMAP byte code. FLOOR = 0FFh --
; this does not count as an ordinary room.
;
; EXIT   : SCRMAP
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: ST_DRW (via JMP), ST_INI
;-----------------------------------------------------------------------
TTLROOM:
        mov     di, OFFSET SCRMAP        ; 63EC  DI -- start of the screen map
        mov     cx, 1F4h                 ; 63EF  1F4h = 500 words = 1000 cells
        mov     ax, 0                    ; 63F2  AX=0 -- the "empty" cell
        rep stosw                        ; 63F5  the whole map is cleared
        call    PUTHUD                   ; 63F7  top 5 rows: the panel with the score
        mov     RDPTR, OFFSET TTLMAP     ; 63FA  byte code of the title screen
        mov     ENDPTR, OFFSET TTLEND    ; 6400  and where it ends
        mov     bp, OFFSET SCRMAP        ; 6406  BP -- map base the primitives draw against
        call    BLDMAP                   ; 6409  build the title screen picture
        mov     FLOOR, 0FFh              ; 640C  FFh -- the title screen sits on no floor at all
        mov     ROOMPOS, 9               ; 6411  position 9 on the floor
        call    DRAWFRM                  ; 6416  redraw the whole frame from scratch
        stc                              ; 6419  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 641A  return

;-----------------------------------------------------------------------
; ST_X6 -- State 6: falls straight on to 7. The address turns up in
; STTAB and nowhere else.
; ALTERS : nothing
; CALLED BY: STTAB[6]
;-----------------------------------------------------------------------
ST_X6:
        inc     GSTATE                   ; 641B  on to the next state
        stc                              ; 641F  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 6420  return

;-----------------------------------------------------------------------
; ST_X7 -- State 7: end of a life, the room is reset.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: STTAB[7]
;-----------------------------------------------------------------------
ST_X7:
        call    PUTBAR                   ; 6421  lay the GAME OVER sign into the map
        mov     di, OFFSET BARRCT        ; 6424  DI -- rectangle of the sign
        call    PUTRCT                   ; 6427  put it out
        call    NOP0                     ; 642A  empty routine: one of eight such calls in the image
        mov     di, OFFSET BARRCT        ; 642D  DI -- rectangle of the sign
        call    PUTRCT                   ; 6430  put it out a second time
LSTX1:
        cmp     LEVEL, 1                 ; 6433  level 1
        jne     LSTX2                    ; 6438  past the first -- no continue is offered
        cmp     RESTUSE, 0               ; 643A  has the continue been used already?
        jne     LSTX2                    ; 643F  yes -- there is no second one
        call    READCMD                  ; 6441  read the input device into CMDBITS
        mov     ax, CMDBITS              ; 6444  AX -- the control command
        and     ax, BTN_JUMP             ; 6447  bit 4 -- the button
        jne     LSTX2                    ; 644A  not held -- no continue
        inc     RESTUSE                  ; 644C  the continue is spent
        mov     LIVES, 5                 ; 6450  five lives all over again
        mov     al, 0                    ; 6455  AL=0 -- what to fill with
        mov     cx, 3                    ; 6457  the score is three bytes of packed BCD
        mov     di, OFFSET SCORE         ; 645A  DI -- start of the score
        rep stosb                        ; 645D  the score is zeroed
        mov     GSTATE, 3                ; 645F  state 3 -- play
        call    ROOMDRW                  ; 6464  rebuild the room map and redraw the whole frame
        ret                              ; 6467  return: the game carries on
LSTX2:
        call    WAITF5                   ; 6468  wait on a key; CF=1 if it was F5
        jae     LSTX1                    ; 646B  CF=0 -- F5 was not pressed
        mov     GSTATE, 8                ; 646D  state 8 -- the main menu
        call    CLRTXT                   ; 6472  wipe the text off the screen
        clc                              ; 6475  CF=0 -- the frame is not done
        ret                              ; 6476  return

;-----------------------------------------------------------------------
; ST_TITLE -- State 8: the main menu. This is the startup state.
;
; ALTERS : nothing
; CALLED BY: STTAB[8]
;-----------------------------------------------------------------------
ST_TITLE:
        SAVEALL                          ; 6477  macro
        cmp     LEVEL, 3                 ; 647E  level 3
        jle     LSTTIT1                  ; 6483  no higher than the third
        mov     LEVEL, 3                 ; 6485  the menu never lets you pick past the third
LSTTIT1:
        call    SCRTTL                   ; 648A  put the title screen and the menu up
LSTTIT2:
        call    KEYPOLL                  ; 648D  poll the input device
        jae     LSTTIT2                  ; 6490  CF=0 -- nothing pressed
        cmp     al, KEY_ENTER            ; 6492  Enter -- start the game
        jne     LSTTIT2                  ; 6494  some other key -- keep waiting
        call    NEWGAME                  ; 6496  reset the state for a new game
        inc     GSTATE                   ; 6499  on to the next state
        RESTALL                          ; 649D  macro
        stc                              ; 64A4  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 64A5  return

;-----------------------------------------------------------------------
; ST_MENU -- State 9: the menu once a game has ended.
;
; ALTERS : nothing
; CALLED BY: STTAB[9]
;-----------------------------------------------------------------------
ST_MENU:
        SAVEALL                          ; 64A6  macro
        call    CLRTXT                   ; 64AD  wipe the text off the screen
        call    SCRMENU                  ; 64B0  put the menu up
LSTMEN1:
        call    KEYPOLL                  ; 64B3  poll the input device
        jae     LSTMEN1                  ; 64B6  CF=0 -- nothing pressed
        cmp     al, KEY_ENTER            ; 64B8  Enter -- start the game
        jne     LSTMEN2                  ; 64BA  not Enter
        mov     GSTATE, 0                ; 64BC  state 0 -- initialization
        jmp     LSTMEN3                  ; 64C1  off to the common exit
LSTMEN2:
        cmp     al, 0                    ; 64C4  AL=0 -- an extended code
        jne     LSTMEN1                  ; 64C6  an ordinary character -- keep waiting
        cmp     ah, HIGH KEY_F1          ; 64C8  F1 -- bottom of the function key range
        jl      LSTMEN1                  ; 64CB  below F1 -- keep waiting
        cmp     ah, HIGH KEY_F7          ; 64CD  F7 -- top of the range
        jg      LSTMEN1                  ; 64D0  above F7 -- keep waiting
        call    MENUKEY                  ; 64D2  deal with the function key
        jae     LSTMEN1                  ; 64D5  CF=0 -- the key was none of the menu's
LSTMEN3:
        RESTALL                          ; 64D7  macro
        stc                              ; 64DE  CF=1 -- the frame is done, nothing more this pass
        ret                              ; 64DF  return

;-----------------------------------------------------------------------
; WAITF5 -- Wait on a key; CF = 1 if it was F5.
;
; ALTERS : AX
; CALLED BY: ST_X7
;-----------------------------------------------------------------------
WAITF5:
        mov     LASTKEY, 0               ; 64E0  the frame's key starts out empty
        xor     al, al                   ; 64E6  AL takes no part here, cleared along the way
        mov     ah, 1                    ; 64E8  AH=1: is a key waiting in the buffer
        int     16h                      ; 64EA  keyboard BIOS
        je      LWAITF1                  ; 64EC  the buffer is empty
        xor     ax, ax                   ; 64EE  AH=0: take the key out of the buffer
        int     16h                      ; 64F0  keyboard BIOS
        mov     LASTKEY, ax              ; 64F2  the scan code is kept
        cmp     al, 0                    ; 64F5  AL=0 -- an extended code
        jne     LWAITF1                  ; 64F7  an ordinary character
        cmp     ah, HIGH KEY_F5          ; 64F9  3Fh -- high byte of the F5 code
        jne     LWAITF1                  ; 64FC  not F5
        stc                              ; 64FE  CF=1 -- F5 was pressed
        jmp     LWAITF2                  ; 64FF  off to the common return
LWAITF1:
        clc                              ; 6502  CF=0 -- F5 was not pressed
LWAITF2:
        ret                              ; 6503  return: the answer is in CF

CSEG    ENDS
        END
