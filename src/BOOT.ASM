        PAGE  60,132
        TITLE BOOT -- ENTRY, MAIN LOOP, SOUND DRIVER, INITIALIZATION
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC DARKEN
        PUBLIC FRAMEC
        PUBLIC LASTKEY
        PUBLIC PAD03CD
        PUBLIC TILRST
        PUBLIC VIDINI
        EXTRN  ANIMLEN:WORD
        EXTRN  ANIMPTR:WORD
        EXTRN  AN_POSE2:WORD
        EXTRN  CLRTXT:NEAR
        EXTRN  DISPAT:NEAR
        EXTRN  FLOOR:BYTE
        EXTRN  FRMWAIT:NEAR
        EXTRN  GSTATE:BYTE
        EXTRN  INBITS:BYTE
        EXTRN  ITEMCNT:BYTE
        EXTRN  ITEMS:WORD
        EXTRN  LEVEL:BYTE
        EXTRN  LIVES:BYTE
        EXTRN  OBJTBL:WORD
        EXTRN  OBJVY:WORD
        EXTRN  PLRST:BYTE
        EXTRN  PLR_ANH:BYTE
        EXTRN  PLR_H:BYTE
        EXTRN  PLR_W:BYTE
        EXTRN  PLR_X:BYTE
        EXTRN  PLR_Y:BYTE
        EXTRN  RESTUSE:BYTE
        EXTRN  ROOMPOS:BYTE
        EXTRN  SCORE:BYTE
        EXTRN  BELTWRK:BYTE
        EXTRN  PUTMAP:NEAR
        EXTRN  SEENMAP:WORD
        EXTRN  STTAB:WORD
        EXTRN  TILE_01:NEAR
        EXTRN  TILE_03:NEAR
        EXTRN  TILE_72:NEAR
        EXTRN  TILE_7E:NEAR
        EXTRN  TILE_80:NEAR
        EXTRN  TILE_B1:NEAR
        EXTRN  TILE_B7:NEAR
        EXTRN  TTLSTEP:BYTE

        ORG   100h
ENTPT:

;=======================================================================
; BOOT.ASM -- ENTRY, MAIN LOOP, SOUND DRIVER, INITIALIZATION
;
; Everything from the JMP START to the end of the graphics setup. The
; stack area lives here too, along with the sound globals, the PIT
; reprogramming and both halves of the light switch -- DARKEN and TILRST.
;=======================================================================

;-----------------------------------------------------------------------
; ENTRY POINT, THE STACK, AND THE TWO PYRAMID TABLES
;
; The first three bytes are the JMP START that DOS executes.
; 0103h..0300h -- the stack area, zeros in the file; STKTOP is its top.
; 0305h RMPOS and 0368h RMFLR -- 99 bytes each: room number -> position
; on its floor, and floor number. They are the inverse of ROOMBAS:
; ROOMBAS[RMFLR[N]] + RMPOS[N] = N for all 99 rooms. The pyramid grows
; by two rooms with every floor -- 3, 5, 7, 9, 11, 13, 15, 17, 19 --
; so the rows come out centered. No code refers to either table.
; The global variables start at 03CFh.
;-----------------------------------------------------------------------
        JMP   START       ; 0100
        DB    510 DUP (0) ; 0103..0300
STKTOP  LABEL BYTE        ; 0301  top of the stack, this is what SP holds at startup
        DB    4 DUP (0)   ; 0301..0304

RMPOS   LABEL BYTE        ; 0305  room -> its position on the floor
        DB    08h,09h,0Ah                                                                 ; floor 0,  3 rooms
        DB    07h,08h,09h,0Ah,0Bh                                                         ; floor 1,  5 rooms
        DB    06h,07h,08h,09h,0Ah,0Bh,0Ch                                                 ; floor 2,  7 rooms
        DB    05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh                                         ; floor 3,  9 rooms
        DB    04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh                                 ; floor 4, 11 rooms
        DB    03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh                         ; floor 5, 13 rooms
        DB    02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,10h                 ; floor 6, 15 rooms
        DB    01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,10h,11h         ; floor 7, 17 rooms
        DB    00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,10h,11h,12h ; floor 8, 19 rooms

RMFLR   LABEL BYTE        ; 0368  room -> floor of the pyramid
        DB    00h,00h,00h                                                                 ; rooms  0.. 2
        DB    01h,01h,01h,01h,01h                                                         ; rooms  3.. 7
        DB    02h,02h,02h,02h,02h,02h,02h                                                 ; rooms  8..14
        DB    03h,03h,03h,03h,03h,03h,03h,03h,03h                                         ; rooms 15..23
        DB    04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h                                 ; rooms 24..34
        DB    05h,05h,05h,05h,05h,05h,05h,05h,05h,05h,05h,05h,05h                         ; rooms 35..47
        DB    06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h                 ; rooms 48..62
        DB    07h,07h,07h,07h,07h,07h,07h,07h,07h,07h,07h,07h,07h,07h,07h,07h,07h         ; rooms 63..79
        DB    08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h,08h ; rooms 80..98

        DB    00h,00h     ; 03CB  ..
PAD03CD DW    0           ; 03CD  tail of RMFLR; SCRTTL looks at bit 3 of it
FRAMEC  DB    00h         ; 03CF  frame counter, +1 for every pass of the main loop
LASTKEY DW    0           ; 03D0  scan code of the last key pressed
SNDFRQ  DW    0           ; 03D2  current PIT divisor for channel 2
SNDTCK  DB    00h         ; 03D4  ticks until the next record of the tune
SNDPTR  DW    0           ; 03D5  read offset within the tune
SNDSEG  DW    0           ; 03D7  segment of the tune
SNDACT  DB    00h         ; 03D9  1 = a sound is playing
OLDT08O DW    0           ; 03DA  saved INT 08h vector, offset
OLDT08S DW    0           ; 03DC  saved INT 08h vector, segment
SNDRPF  DW    0           ; 03DE  1 = a frequency sweep is running
SNDRPC  DW    0           ; 03E0  how many sweep steps are left

;=======================================================================
; STARTUP AND THE SOUND SUBSYSTEM
;=======================================================================

;-----------------------------------------------------------------------
; MAIN -- The whole program: video mode, vectors, main loop.
;
; The entry point is START. It sets up its own stack, pushes PSP:0000
; onto it, turns on mode 4, points INT 62h at SNDAPI and INT 67h at
; PUTMAP, starts the game at level 1 and falls through into MAINLP. The
; far RET at 048Ah pops PSP:0000 -- that is the exit back to DOS.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, DS
;-----------------------------------------------------------------------
MAIN    PROC  FAR
START:
        mov     sp, OFFSET STKTOP        ; 03E2  own stack: SP to the top of the 0103..0300 area
        mov     ax, cs                   ; 03E5  CS -- the one and only segment of a .COM image
        mov     ds, ax                   ; 03E7  DS = CS
        mov     ss, ax                   ; 03E9  SS = CS: the stack sits inside the image itself
        mov     es, ax                   ; 03EB  ES = CS
        push    ds                       ; 03ED  segment of the PSP
        mov     ax, 0                    ; 03EE  AX=0 -- the return offset
        push    ax                       ; 03F1  offset 0 -- the RET at 048A will pop this pair
        xor     ah, ah                   ; 03F2  AH=0: the "set video mode" call
        mov     al, VMODE_CGA            ; 03F4  AL=4: 320x200, four colors
        int     10h                      ; 03F6  video BIOS
        mov     ah, 0Bh                  ; 03F8  AH=0Bh: the "set palette" call
        mov     bh, 1                    ; 03FA  BH=1: pick the color set
        mov     bl, 0                    ; 03FC  BL=0: color set 0
        int     10h                      ; 03FE  video BIOS
        mov     al, FDC_OFF              ; 0400  C0h: motor off, controller held in reset
        mov     dx, PORT3F2              ; 0402  the floppy drive control port
        out     dx, al                   ; 0405  the drive motor is shut down
        call    SNDINI                   ; 0406  take over INT 08h and run the PIT at 100 Hz
        push    es                       ; 0409  ES equals CS here, comes back at 042E
        mov     ax, 0                    ; 040A  AX=0 -- segment of the interrupt vector table
        mov     es, ax                   ; 040D  ES = 0: the interrupt vector table
        mov     ax, cs                   ; 040F  CS -- segment the handler lives in
        mov     es:[VEC62+2], ax         ; 0411  segment half of the INT 62h vector
        mov     ax, OFFSET SNDAPI        ; 0415  offset of the sound API handler
        mov     es:[VEC62], ax           ; 0418  offset half: INT 62h -> SNDAPI
        mov     ax, 0                    ; 041C  zero again for the second vector
        mov     es, ax                   ; 041F  ES = 0 a second time, though it is zero already
        mov     ax, cs                   ; 0421  CS -- segment the handler lives in
        mov     es:[VEC67+2], ax         ; 0423  segment half of the INT 67h vector
        mov     ax, OFFSET PUTMAP        ; 0427  offset of the map output handler
        mov     es:[VEC67], ax           ; 042A  offset half: INT 67h -> PUTMAP
        pop     es                       ; 042E  ES is back to CS
        mov     GSTATE, 8                ; 042F  state 8 -- the main menu
        mov     LEVEL, 1                 ; 0434  level 1

;-----------------------------------------------------------------------
; MAINLP -- The main loop: pace the frame, run the state handler, poll
; the keyboard.
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: START (falls through)
;-----------------------------------------------------------------------
MAINLP:
        call    FRMWAIT                  ; 0439  wait out the frame: this is what holds the game's pace
        inc     FRAMEC                   ; 043C  frame counter, +1 for every pass of the loop
        mov     bx, OFFSET STTAB         ; 0440  BX -- table of the ten state handlers
        mov     bp, cs                   ; 0443  BP -- segment of that table, for DISPAT
        mov     al, GSTATE               ; 0445  AL -- number of the state we are in
        call    DISPAT                   ; 0448  call the handler at STTAB[AL]
        mov     LASTKEY, 0               ; 044B  the frame's key starts out empty until one is read
        xor     al, al                   ; 0451  AL takes no part here, cleared along the way
        mov     ah, 1                    ; 0453  AH=1: is a key waiting in the buffer
        int     16h                      ; 0455  keyboard BIOS: is there one
        je      MAINLP                   ; 0457  the buffer is empty -- straight on to the next frame
        xor     ax, ax                   ; 0459  AH=0: take the key out of the buffer
        int     16h                      ; 045B  keyboard BIOS: one key per frame, no more
        mov     LASTKEY, ax              ; 045D  scan code and ASCII are handed on to the state handlers
        cmp     LASTKEY, KEY_F5          ; 0460  F5 -- back to the menu
        jne     LMAINL1                  ; 0466  not F5 -- go and test for F10
        mov     GSTATE, 8                ; 0468  state 8 -- the main menu
        call    CLRTXT                   ; 046D  wipe the text off the screen
        jmp     short MAINLP             ; 0470  the key is dealt with, on to the next frame
LMAINL1:
        cmp     ax, KEY_F10              ; 0472  F10 -- pause
        jne     MAINLP                   ; 0475  every other key is left to the state handlers
LMAINL2:
        xor     al, al                   ; 0477  AL takes no part here, cleared along the way
        mov     ah, 1                    ; 0479  AH=1: is a key waiting in the buffer
        int     16h                      ; 047B  keyboard BIOS: polled while paused
        je      LMAINL2                  ; 047D  nothing there -- spin here, no frames go by
        xor     ax, ax                   ; 047F  AH=0: take the key out of the buffer
        int     16h                      ; 0481  keyboard BIOS
        cmp     ax, KEY_F10              ; 0483  only F10 lets you out of the pause again
        jne     LMAINL2                  ; 0486  not F10 -- keep waiting
        jmp     short MAINLP             ; 0488  the pause is over, on to the next frame

        ret                              ; 048A  far RET onto PSP:0000 -- that is the exit to DOS
MAIN    ENDP

;-----------------------------------------------------------------------
; SPKRON -- Turn the speaker on at the SNDFRQ frequency.
;
; ENTRY  : SNDFRQ
; EXIT   : ports 42h, 43h, 61h
; ALTERS : AX
; CALLED BY: SNDTICK
;-----------------------------------------------------------------------
SPKRON:
        mov     al, 0B6h                 ; 048B  B6h: channel 2, mode 3, both bytes of the divisor
        out     PORT43, al               ; 048D  PIT control word
        mov     ax, SNDFRQ               ; 048F  the divisor: frequency = 1193182 / SNDFRQ
        out     PORT42, al               ; 0492  low byte of the divisor out to channel 2
        mov     al, ah                   ; 0494  high byte of the divisor into AL
        out     PORT42, al               ; 0496  high byte of the divisor
        in      al, PORT61               ; 0498  port B: bits 0 and 1 are the gate and the speaker data
        and     al, 0FCh                 ; 049A  clear both bits
        or      al, SPK_BITS             ; 049C  set both: the PIT gate and the speaker output
        out     PORT61, al               ; 049E  the speaker is now sounding
        ret                              ; 04A0  return to SNDTICK

;-----------------------------------------------------------------------
; SPKROFF -- Turn the speaker off.
;
; EXIT   : port 61h
; ALTERS : AX
; CALLED BY: SNDTICK
;-----------------------------------------------------------------------
SPKROFF:
        in      al, PORT61               ; 04A1  port B
        and     al, 0FCh                 ; 04A3  clear bits 0 and 1
        out     PORT61, al               ; 04A5  the speaker has gone quiet
        ret                              ; 04A7  return to SNDTICK

;-----------------------------------------------------------------------
; SNDAPI -- INT 62h ISR. AX=1 asks whether a sound is playing; anything
; else is taken as the address of a tune to start.
; ENTRY  : AX, DS
; EXIT   : AL
; ALTERS : nothing
; CALLED BY: through the interrupt vector or through a jump table
;-----------------------------------------------------------------------
SNDAPI:
        sti                              ; 04A8  interrupts back on inside the handler
        SAVEREG <bx,es,ds>               ; 04A9  macro
        push    ax                       ; 04AC  AX is the argument, keep it out of harm's way
        mov     bx, ds                   ; 04AD  BX -- segment of the tune, taken from the caller
        pop     ax                       ; 04AF  AX is back
        cmp     ax, 1                    ; 04B0  AX=1 -- the "is it playing" query
        jne     LSNDAP1                  ; 04B3  not the query -- so a tune is being started
        mov     al, SNDACT               ; 04B5  the answer goes in AL: 1 = a sound is running
        jmp     LSNDAP2                  ; 04B8  off to the common exit
LSNDAP1:
        mov     SNDPTR, ax               ; 04BB  AX -- offset of the tune
        mov     SNDSEG, bx               ; 04BE  BX -- and its segment
        mov     SNDTCK, 1                ; 04C2  1 tick: the first record will be taken right away
        mov     SNDACT, 1                ; 04C7  the sequencer is switched on
        mov     SNDRPF, 0                ; 04CC  no sweep in progress
LSNDAP2:
        RESTREG <ds,es,bx>               ; 04D2  macro
        iret                             ; 04D5  leave the interrupt handler

;-----------------------------------------------------------------------
; SNDTICK -- INT 08h ISR. The tune sequencer, a hundred times a second.
;
; It counts SNDTCK down; at zero it takes the next record of the tune
; and sets the speaker. It issues its own EOI and never chains to the
; old 08h handler.
; EXIT   : SNDFRQ, SNDTCK, SNDPTR, SNDACT, ports 20h, 42h, 43h, 61h
; ALTERS : nothing
; CALLED BY: through the interrupt vector or through a jump table
;-----------------------------------------------------------------------
SNDTICK:
        sti                              ; 04D6  interrupts back on inside the handler
        SAVEREG <ax,bx,cx,ds,es>         ; 04D7  macro
        mov     ax, SNDSEG               ; 04DC  segment of the tune, as SNDAPI left it
        mov     es, ax                   ; 04DF  ES -- segment of the tune
        cmp     SNDACT, 1                ; 04E1  sound switched off -- nothing to do but the EOI
        je      LSNDTI2                  ; 04E6  a sound is running -- carry on
LSNDTI1:
        jmp     LSNDTI9                  ; 04E8  off to the end: send the EOI and leave
LSNDTI2:
        mov     al, SNDTCK               ; 04EB  ticks left until the next record
        dec     al                       ; 04EE  one tick has gone by
        mov     SNDTCK, al               ; 04F0  the counter is down
        cmp     al, 0                    ; 04F3  have we counted down to zero?
        jne     LSNDTI1                  ; 04F5  no -- the note is still sounding
        cmp     SNDRPF, 1                ; 04F7  is a frequency sweep in progress
        jne     LSNDTI4                  ; 04FC  no -- go read the next record
        mov     ax, SNDRPC               ; 04FE  sweep steps left to do
        dec     ax                       ; 0501  one sweep step is done
        cmp     ax, 0                    ; 0502  steps all used up?
        jne     LSNDTI3                  ; 0505  still some left
        mov     cx, 6                    ; 0507  a sweep record is 10 bytes, 4 of them already stepped over
        add     SNDPTR, cx               ; 050A  pointer on to the next record
        mov     cx, 0                    ; 050E  CX=0, to clear the flag with
        mov     SNDRPF, cx               ; 0511  the sweep is over
        jmp     LSNDTI4                  ; 0515  go read the next record
LSNDTI3:
        mov     SNDRPC, ax               ; 0518  one step fewer left to do
        mov     bx, SNDPTR               ; 051B  SNDPTR is parked on the "step" field
        mov     ax, es:[bx]              ; 051F  the sweep step, signed
        add     SNDFRQ, ax               ; 0522  the divisor moves on by one step
        mov     cx, es:[bx+4]            ; 0526  how long this step lasts
        jmp     LSNDTI8                  ; 052A  set SNDTCK and turn the speaker on
LSNDTI4:
        mov     bx, SNDPTR               ; 052D  SNDPTR -- start of the next record
        mov     ax, es:[bx]              ; 0531  note divisor, or a record marker
        mov     cx, es:[bx+2]            ; 0534  only CL is wanted, but a whole word is read
        add     bx, 3                    ; 0538  a note is three bytes
        mov     SNDPTR, bx               ; 053B  pointer on to the next record
        cmp     ax, 1                    ; 053F  AX=1 -- this is a sweep record
        jne     LSNDTI5                  ; 0542  not a sweep -- sort out the three kinds of record
        inc     bx                       ; 0544  the "step" field lies one byte further on
        mov     SNDPTR, bx               ; 0545  SNDPTR is parked on the "step"
        mov     ax, 1                    ; 0549  AX=1 -- the "sweep running" marker
        mov     SNDRPF, ax               ; 054C  the sweep is switched on
        push    cx                       ; 054F  CX holds the starting divisor, it will be wanted
        mov     ax, es:[bx+2]            ; 0550  how many sweep steps there are
        mov     SNDRPC, ax               ; 0554  that is how many are left
        mov     cx, es:[bx+4]            ; 0557  how long one step lasts
        pop     ax                       ; 055B  AX -- the starting divisor
        jmp     LSNDTI7                  ; 055C  load SNDFRQ and start sounding
LSNDTI5:
        cmp     ax, 0                    ; 055F  AX=0 -- a rest
        je      LSNDTI6                  ; 0562  a rest: leave the frequency alone
        cmp     ax, 0FFFFh               ; 0564  AX=FFFFh -- end of the tune
        jne     LSNDTI7                  ; 0567  otherwise AX is a note divisor
        xor     cx, cx                   ; 0569  zero the duration: it was read past the end
        xor     al, al                   ; 056B  AL=0 -- the "sound off" marker
        mov     SNDACT, al               ; 056D  the sequencer is switched off
LSNDTI6:
        mov     SNDTCK, cl               ; 0570  stay quiet for CL ticks
        call    SPKROFF                  ; 0574  the speaker goes quiet
        jmp     LSNDTI9                  ; 0577  off to the exit: EOI and return
LSNDTI7:
        mov     SNDFRQ, ax               ; 057A  divisor of the new note
LSNDTI8:
        mov     SNDTCK, cl               ; 057D  the note sounds for CL ticks
        call    SPKRON                   ; 0581  turn the speaker on at the SNDFRQ frequency
LSNDTI9:
        mov     al, 20h                  ; 0584  20h -- the EOI command
        out     PORT20, al               ; 0586  EOI to the 8259 interrupt controller
        RESTREG <es,ds,cx,bx,ax>         ; 0588  macro
        iret                             ; 058D  leave the interrupt handler

;-----------------------------------------------------------------------
; SNDINI -- Take over INT 08h, run the PIT at 100 Hz, unmask IRQ0/IRQ1.
;
; ALTERS : AX, BX, DI
; CALLED BY: START
;-----------------------------------------------------------------------
SNDINI:
        push    es                       ; 058E  ES comes back at 05C4
        cli                              ; 058F  vectors and the PIT are changed with interrupts off
        mov     ax, 0                    ; 0590  AX=0 -- segment of the interrupt vector table
        mov     es, ax                   ; 0593  ES = 0: the interrupt vector table
        mov     di, VEC08                ; 0595  DI -- the INT 08h vector, the timer tick
        mov     bx, es:[di]              ; 0598  old offset out of the vector
        mov     OLDT08O, bx              ; 059B  old offset is saved away
        mov     bx, es:[di+2]            ; 059F  old segment out of the vector
        mov     OLDT08S, bx              ; 05A3  old segment is saved away
        mov     ax, OFFSET SNDTICK       ; 05A7  AX -- offset of the new handler
        cld                              ; 05AA  STOSW will run forward
        stosw                            ; 05AB  offset half: INT 08h -> SNDTICK
        mov     ax, cs                   ; 05AC  CS -- segment the handler lives in
        stosw                            ; 05AE  segment half of the vector
        mov     al, PIT_M3               ; 05AF  36h: channel 0, mode 3, both bytes of the divisor
        out     PORT43, al               ; 05B1  PIT control word
        mov     bx, PIT_DIV              ; 05B3  divisor 2E9Ch = 11932 ticks
        mov     al, bl                   ; 05B6  low byte of the divisor into AL
        out     PORT40, al               ; 05B8  low byte of the divisor out to channel 0
        mov     al, bh                   ; 05BA  high byte of the divisor into AL
        out     PORT40, al               ; 05BC  high byte: the timer now runs a hundred times a second
        in      al, PORT21               ; 05BE  IRQ mask of the 8259 controller
        and     al, 0FCh                 ; 05C0  clear bits 0 and 1
        out     PORT21, al               ; 05C2  timer IRQ0 and keyboard IRQ1 are open
        pop     es                       ; 05C4  ES restored
        sti                              ; 05C5  interrupts back on
        ret                              ; 05C6  return to START

;-----------------------------------------------------------------------
; DARKEN -- Put the lights out: blank the pictures of tiles 01h..33h and
; 72h..77h, and the working copy along with them.
;
; EXIT   : TILES
; ALTERS : nothing
; CALLED BY: DRAWFRM
;-----------------------------------------------------------------------
DARKEN:
        SAVEALL                          ; 05C7  macro: save every register
        cld                              ; 05CE  STOSB will run forward
        mov     al, 0                    ; 05CF  zero = all four dots in the background color
        mov     di, OFFSET TILE_01       ; 05D1  tiles 01h..02h: the floor
        mov     cx, 20h                  ; 05D4  20h bytes
        rep stosb                        ; 05D7  20h bytes = 2 tiles
        mov     al, 0                    ; 05D9  AL is zero already: REP STOSB never touches it
        mov     di, OFFSET TILE_03       ; 05DB  tiles 03h..33h: walls, ladders, items
        mov     cx, 310h                 ; 05DE  310h bytes = 49 tiles
        rep stosb                        ; 05E1  the tile pictures are blanked
        mov     al, 0                    ; 05E3  AL is zero already: REP STOSB never touches it
        mov     di, OFFSET TILE_72       ; 05E5  tiles 72h..77h: the conveyor belts
        mov     cx, 60h                  ; 05E8  60h bytes = 6 tiles
        rep stosb                        ; 05EB  the belt pictures are blanked
        mov     al, 0                    ; 05ED  AL is zero already: REP STOSB never touches it
        mov     di, OFFSET BELTWRK       ; 05EF  working copy of the belt, all four phases
        mov     cx, 180h                 ; 05F2  180h bytes = 24 tiles
        rep stosb                        ; 05F5  the working copy of the belt is blanked
        RESTALL                          ; 05F7  macro: restore every register
        ret                              ; 05FE  return: every tile picture is now zeros

;-----------------------------------------------------------------------
; TILRST -- Put the animated tiles back from their master copies, and
; set background color 0 while it is at it.
;
; ALTERS : nothing
; CALLED BY: DRAWFRM, ST_PL1, VIDINI
;-----------------------------------------------------------------------
TILRST:
        SAVEALL                          ; 05FF  macro
        cld                              ; 0606  MOVSB will run forward
        mov     si, OFFSET TILE_7E       ; 0607  master copy of tiles 7Eh..7Fh
        mov     di, OFFSET TILE_01       ; 060A  over the live 01h..02h
        mov     cx, 20h                  ; 060D  20h bytes = 2 tiles
        rep movsb                        ; 0610  the floor is back
        mov     si, OFFSET TILE_80       ; 0612  master copy of tiles 80h..B0h
        mov     di, OFFSET TILE_03       ; 0615  over the live 03h..33h
        mov     cx, 310h                 ; 0618  310h bytes = 49 tiles
        rep movsb                        ; 061B  walls, ladders and items are back
        mov     si, OFFSET TILE_B1       ; 061D  master copy of tiles B1h..B6h
        mov     di, OFFSET TILE_72       ; 0620  over the live 72h..77h -- the conveyor belts
        mov     cx, 60h                  ; 0623  60h bytes = 6 tiles
        rep movsb                        ; 0626  the conveyor belts are back
        mov     si, OFFSET TILE_B7       ; 0628  master copy of tiles B7h..CEh
        mov     di, OFFSET BELTWRK       ; 062B  into the working copy: 4 phases of 6 tiles
        mov     cx, 180h                 ; 062E  180h bytes = 24 tiles
        rep movsb                        ; 0631  the working copy of the belt is back
        mov     bx, 0                    ; 0633  BH=0: the "background color" subcall, BL=0: black
        mov     ah, 0Bh                  ; 0636  AH=0Bh: the "set palette" call
        mov     al, 0                    ; 0638  call 0Bh never looks at AL
        int     10h                      ; 063A  video BIOS
        RESTALL                          ; 063C  macro
        ret                              ; 0643  return: the live tiles match their masters again

;-----------------------------------------------------------------------
; VIDINI -- Mode 4, palette, master tiles, and the player's starting
; values.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: ST_INI
;-----------------------------------------------------------------------
VIDINI:
        mov     ah, 0                    ; 0644  AH=0: the "set video mode" call
        mov     al, VMODE_CGA            ; 0646  AL=4: 320x200, four colors
        int     10h                      ; 0648  video BIOS
        mov     ah, 0Bh                  ; 064A  AH=0Bh: the "set palette" call
        mov     bh, 1                    ; 064C  BH=1: pick the color set
        mov     bl, 0                    ; 064E  BL=0: color set 0
        int     10h                      ; 0650  video BIOS
        call    TILRST                   ; 0652  refill the live tiles from their master copies
        mov     PLRST, 5                 ; 0655  player state 5 -- falling
        mov     ax, OFFSET AN_POSE2      ; 065A  frame chain: the standing pose
        mov     ANIMPTR, ax              ; 065D  the player's frame chain is chosen
        mov     ax, AN_POSE2             ; 0660  first word of the chain -- address of the frame
        add     ax, 2                    ; 0663  step over the frame header
        mov     BYTE PTR OBJTBL, al      ; 0666  low byte of the player's frame address
        mov     PLR_ANH, ah              ; 0669  high byte of the frame address
        mov     ANIMLEN, 0               ; 066D  one frame in the chain: highest number is 0
        mov     PLR_X, 1                 ; 0673  X = 1: the left edge of the room
        mov     PLR_Y, 0Eh               ; 0678  Y = 0Eh: the fourteenth scan line
        mov     PLR_W, 6                 ; 067D  the player's sprite is 6 bytes wide
        mov     PLR_H, 14h               ; 0682  the player's sprite is 14h = 20 lines tall
        mov     BYTE PTR OBJVY, 3        ; 0687  speed along Y = 3
        mov     FLOOR, 0FFh              ; 068C  floor FFh -- no room of the pyramid picked yet
        mov     ROOMPOS, 9               ; 0691  position 9 on the floor -- where play begins
        mov     INBITS, 1                ; 0696  only object 0, the player, is left live
        mov     LIVES, 5                 ; 069B  five lives
        mov     RESTUSE, 0               ; 06A0  the treasure chamber has not been cleared yet
        mov     TTLSTEP, 1               ; 06A5  title screen step 1
        mov     ITEMCNT, 0               ; 06AA  nothing in the inventory
        push    es                       ; 06AF  ES comes back at 06D3
        mov     ax, ds                   ; 06B0  DS -- segment of the image
        mov     es, ax                   ; 06B2  ES = DS, ready for STOSB
        cld                              ; 06B4  STOSB will run forward
        mov     al, 0                    ; 06B5  AL=0 -- what to fill with
        mov     cx, 5                    ; 06B7  CX=5 -- that many bytes
        mov     di, OFFSET ITEMS         ; 06BA  DI -- start of the inventory
        rep stosb                        ; 06BD  clears 5 bytes out of the 10
        mov     al, 0                    ; 06BF  AL=0 -- what to fill with
        mov     cx, 0CAh                 ; 06C1  CAh = 202 bytes of the seen map
        mov     di, OFFSET SEENMAP       ; 06C4  DI -- start of the seen map
        rep stosb                        ; 06C7  not one room has been seen yet
        mov     al, 0                    ; 06C9  AL=0 -- what to fill with
        mov     cx, 3                    ; 06CB  the score is three bytes of packed BCD
        mov     di, OFFSET SCORE         ; 06CE  DI -- start of the score
        rep stosb                        ; 06D1  the score is zeroed
        pop     es                       ; 06D3  ES restored
        ret                              ; 06D4  return to ST_INI

CSEG    ENDS
        END   ENTPT
