        PAGE  60,132
        TITLE ROOMBLD -- OBJECT TABLE AND THE ROOM BUILDER
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC BLDMAP
        PUBLIC CURSPOS
        PUBLIC DARKF
        PUBLIC DISPAT
        PUBLIC DRWALL
        PUBLIC ELMTILE
        PUBLIC FILLRC
        PUBLIC LITCHK
        PUBLIC MKROOM
        PUBLIC OBJBIT
        PUBLIC OBJKND
        PUBLIC OBJTBL
        PUBLIC OBJTYP
        PUBLIC PARMSPL
        PUBLIC PLR_ANH
        PUBLIC PLR_H
        PUBLIC PLR_W
        PUBLIC PLR_X
        PUBLIC PLR_Y
        PUBLIC PR_PATT
        PUBLIC PUT2X2
        PUBLIC PUTGRID
        PUBLIC PUTHUD
        EXTRN  ANIMLEN:WORD
        EXTRN  ANIMPTR:WORD
        EXTRN  ANIMTB:WORD
        EXTRN  CALLDEP:BYTE
        EXTRN  CMDLEN:WORD
        EXTRN  CMDOP:BYTE
        EXTRN  CMDP1:BYTE
        EXTRN  CMDP2:BYTE
        EXTRN  CMDX:BYTE
        EXTRN  ELMCUR:WORD
        EXTRN  ELMSEL:BYTE
        EXTRN  ELMTAB:BYTE
        EXTRN  ELM_TRCH:ABS
        EXTRN  ENDPTR:WORD
        EXTRN  FLOOR:BYTE
        EXTRN  FRAMEC:BYTE
        EXTRN  FRAME_00:NEAR
        EXTRN  FRAME_17:NEAR
        EXTRN  FRAME_18:NEAR
        EXTRN  FRAME_1F:NEAR
        EXTRN  FRAME_21:NEAR
        EXTRN  HUDFULL:BYTE
        EXTRN  HUDMAP:BYTE
        EXTRN  INBITS:BYTE
        EXTRN  ITEMCNT:BYTE
        EXTRN  ITEMS:WORD
        EXTRN  LEVEL:BYTE
        EXTRN  LITMSK:BYTE
        EXTRN  MIRDST:BYTE
        EXTRN  MIRFLAG:BYTE
        EXTRN  MIRSRC:BYTE
        EXTRN  MKOBJF:BYTE
        EXTRN  OBJTMR2:BYTE
        EXTRN  OBJVX:BYTE
        EXTRN  OBJXTAB:BYTE
        EXTRN  OBJYTAB:BYTE
        EXTRN  PATLEFT:BYTE
        EXTRN  PATLEN:BYTE
        EXTRN  PLAYSND:NEAR
        EXTRN  RDPTR:WORD
        EXTRN  ROOMKND:BYTE
        EXTRN  ROOMNO:BYTE
        EXTRN  ROOMOBJ:WORD
        EXTRN  ROOMOBN:BYTE
        EXTRN  ROOMPOS:BYTE
        EXTRN  ROOMPT:WORD
        EXTRN  ROOMRQ:BYTE
        EXTRN  ROWBUF:BYTE
        EXTRN  SCRMAP:BYTE
        EXTRN  SEENMAP:WORD
        EXTRN  SHOWSCR:NEAR
        EXTRN  SOLID_MIN:ABS
        EXTRN  SVANIM:WORD
        EXTRN  SVIDX2:WORD
        EXTRN  SVLEN:WORD
        EXTRN  SVST:BYTE
        EXTRN  SVX:BYTE
        EXTRN  SVY:BYTE
        EXTRN  TRSDRL:BYTE
        EXTRN  TRSDRR:BYTE
        EXTRN  TRSGEM:BYTE
        EXTRN  TRSMAP:BYTE
        EXTRN  TTLMAP:BYTE
        EXTRN  TILES:BYTE

;=======================================================================
; ROOMBLD.ASM -- OBJECT TABLE AND THE ROOM BUILDER
;
; OBJFRM and OBJTBL, and after them the room builder: BLDMAP, the eight
; drawing primitives, mirroring, and creating the objects.
;=======================================================================

;-----------------------------------------------------------------------
; OBJFRM -- ONE FRAME PER TYPE OF ROOM OBJECT  (06E0..06F9, 26 bytes)
;
; MKOBJ indexes the table by the word (CMDOP and 3Fh) - 30h, and the
; object opcodes stop at 33h: only the first four entries carry meaning.
; From 06E8 come four words that are not frames at all, and from 06F0
; OBJALN starts.
;-----------------------------------------------------------------------
OBJFRM  LABEL WORD                       ; 06E0
        DW    FRAME_1F                   ; 06E0  type 0: BEH_CLMB
        DW    FRAME_21                   ; 06E2  type 1: BEH_NONE
        DW    FRAME_18                   ; 06E4  type 2: BEH_WALK
        DW    FRAME_17                   ; 06E6  type 3: BEH_JUMP
        DW    38h,56h,56h,56h            ; 06E8
; object type -> last frame number of the chain
OBJALN  DW    1,1,7,0                    ; 06F0
        DB    00h,00h                    ; 06F8  ..

;-----------------------------------------------------------------------
; THE OBJECT AREA  (06FA..07C6, 205 bytes)
;
; Object 0 is the player, and his four fields carry names of their own:
; VIDINI fills them in one by one. After that OBJTBL holds the records
; of the room's objects, followed by the working tables of the same pass.
;-----------------------------------------------------------------------
OBJTBL  LABEL WORD         ; 06FA  6 bytes per object, object 0 = the player
        DB    00h          ; 06FA  object 0, field +0: pointer to the bitmap
PLR_ANH DB    00h          ; 06FB  the same pointer, high byte
PLR_X   DB    00h          ; 06FC  field +2: X in bytes of video RAM, 0..79
PLR_Y   DB    00h          ; 06FD  field +3: Y in scan lines; bit 0 = the field
PLR_W   DB    00h          ; 06FE  field +4: width in bytes
PLR_H   DB    00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h ; 06FF  field +5: height in lines
        DB    00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h ; 070F  ................
        DB    00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h ; 071F  ................
        DB    00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h ; 072F  ................
        DB    00h,00h,00h,00h,00h                                             ; 073F  .....
; object type -> Y correction in scan lines
OBJDY   DB    07h,02h,02h,02h                                                 ; 0744
OBJBIT  DB    100 DUP (0)  ; 0748  object -> bit number within SEENMAP, one byte each
OBJTYP  DB    00h          ; 07AC  type of the object being worked on, index into JMPTBL
OBJKND  DB    8 DUP (0)    ; 07AD  object -> (type shl 2) or subtype, one byte each
FARPTR  DW    0            ; 07B5  far jump address, PRIMJMP assembles it
FARPTRS DW    0            ; 07B7  FARPTR, high word: segment of the jump
VXTAB   DB    01h,0FFh,02h,00h ; 07B9  subtype -> starting OBJVX, read by PUTOBJ3
DARKF   DB    00h          ; 07BD  0F0h = dark. LITCHK sets it, PLRHIT reads it
MUSSEL  DB    00h          ; 07BE  pick of the treasure chamber tune: (AL and 3) -> MUSTAB
MUSTAB  DW    0Ah,9,8,0Ah  ; 07BF  tunes for the levels: 10, 9, 8, 10

;-----------------------------------------------------------------------
; MKROOM -- Build a room: clear SCRMAP, lay in the panel, work out the
; room number, create the objects.
;
; ENTRY  : FLOOR, ROOMPOS
; EXIT   : SCRMAP filled in
; ALTERS : AX, BX, CX, DX, SI, DI, BP
; CALLED BY: ROOMDRW
;-----------------------------------------------------------------------
MKROOM:
        push    es                       ; 07C7  ES comes back at 07D8
        mov     di, OFFSET SCRMAP        ; 07C8  DI -- start of the screen map
        mov     ax, ds                   ; 07CB  DS -- segment of the image
        mov     es, ax                   ; 07CD  ES = DS, ready for STOSW
        mov     cx, 1F4h                 ; 07CF  1F4h = 500 words = 1000 map cells
        mov     ax, 0                    ; 07D2  AX=0 -- the "empty" cell
        cld                              ; 07D5  STOSW will run forward
        rep stosw                        ; 07D6  the whole map is cleared
        pop     es                       ; 07D8  ES restored
        mov     bp, OFFSET SCRMAP        ; 07D9  BP -- map base every primitive draws against
        call    PUTHUD                   ; 07DC  top 5 rows: the panel with the score
        call    ROOMID                   ; 07DF  AL -- room number, worked out from FLOOR and ROOMPOS
        xor     ah, ah                   ; 07E2  AH=0: the whole room number now sits in AX
        mov     ROOMNO, al               ; 07E4  the number is kept
        cmp     al, 62h                  ; 07E7  62h = 98 -- an ordinary room
        je      LMKROO2                  ; 07E9  that one is built from byte code
        shr     al, 1                    ; 07EB  number halved
        cmp     al, 31h                  ; 07ED  31h = 49: AL/2 >= 49 means AL >= 98
        jb      LMKROO1                  ; 07EF  lower -- an ordinary room
        call    TREASR                   ; 07F1  99 and above -- the treasure chamber
        ret                              ; 07F4  return: the treasure chamber is built
LMKROO1:
        mov     al, ROOMNO               ; 07F5  SHR wrecked AL, so the number is fetched again
LMKROO2:
        call    CURSIN                   ; 07F8  set RDPTR and ENDPTR onto the description
        mov     al, FLOOR                ; 07FB  AL -- the floor number
        add     al, LEVEL                ; 07FE  plus the difficulty level
        mov     ROOMOBN, 0               ; 0802  no objects in the room yet
        cmp     MKOBJF, 0                ; 0807  are the objects to be created
        je      LMKROO3                  ; 080C  no -- skip over it
        mov     INBITS, 1                ; 080E  only object 0, the player, is left live
LMKROO3:
        mov     al, ROOMNO               ; 0813  AL -- number of the room just built
        mov     ROOMRQ, al               ; 0816  ROOMRQ -- which room to show

;-----------------------------------------------------------------------
; BLDMAP -- The interpreter for a room's byte code. It can call
; fragments and branch on the difficulty level.
;
; ENTRY  : RDPTR, ENDPTR
; EXIT   : SCRMAP
; ALTERS : BX, CX, DX, SI, DI, BP, ES
; CALLED BY: MKROOM (falls through), TREASR, TTLROOM
;-----------------------------------------------------------------------
BLDMAP:
        mov     ax, RDPTR                ; 0819  RDPTR -- where we are reading the byte code
        cmp     ax, ENDPTR               ; 081C  have we reached the end of the description?
        je      LBLDMA1                  ; 0820  end of the description
        jmp     LBLDMA6                  ; 0822  no -- go and sort out the next command
LBLDMA1:
        cmp     CALLDEP, 0               ; 0825  nesting depth of fragments
        je      LBLDMA5                  ; 082A  zero -- the room is finished
        dec     CALLDEP                  ; 082C  leaving a fragment: depth one lower
        cmp     MIRFLAG, 0               ; 0830  was the fragment inserted mirrored
        je      LBLDMA2                  ; 0835  no -- nothing to flip
        call    MIRROR                   ; 0837  flip whatever the fragment drew
LBLDMA2:
        pop     ax                       ; 083A  off the stack -- the caller's mirror flag
        mov     MIRFLAG, al              ; 083B  the caller's mirror flag is back
        pop     ENDPTR                   ; 083E  off the stack -- the caller's end of description
        pop     RDPTR                    ; 0842  off the stack -- the caller's reading point
LBLDMA3:
        xor     ah, ah                   ; 0846  AH=0: the whole command length now sits in AX
        mov     al, 2                    ; 0848  AL=2 -- length of a fragment-insert command
LBLDMA4:
        clc                              ; 084A  clear the carry ahead of the ADC
        xor     ah, ah                   ; 084B  AH=0: AX holds nothing but the command length
        adc     RDPTR, ax                ; 084D  read pointer forward by the length of the command
        jmp     short BLDMAP             ; 0851  go and sort out the next command
LBLDMA5:
        ret                              ; 0853  return: the room description has been carried out
LBLDMA6:
        xor     si, si                   ; 0854  SI -- offset within the command
        mov     bx, RDPTR                ; 0856  BX -- start of the current command
        mov     al, [bx+si]              ; 085A  first byte of the command
        mov     CMDOP, al                ; 085C  CMDOP -- the opcode byte
        and     al, 3Eh                  ; 085F  bits 5..1 of the opcode
        cmp     al, 3Eh                  ; 0861  3Eh -- a fragment insert, either 3Eh or 3Fh
        je      LBLDMA10                 ; 0863  a fragment insert
        inc     si                       ; 0865  second byte of the command
        mov     al, [bx+si]              ; 0866  second byte of the command
        mov     CMDX, al                 ; 0868  CMDX -- low byte of the offset into the map
        inc     si                       ; 086B  third byte of the command
        mov     al, [bx+si]              ; 086C  third byte of the command
        mov     CMDP1, al                ; 086E  CMDP1 -- first parameter of the command
        inc     si                       ; 0871  fourth byte of the command
        mov     al, [bx+si]              ; 0872  fourth byte of the command
        mov     CMDP2, al                ; 0874  CMDP2 -- second parameter of the command
        call    ELMSET                   ; 0877  ELMCUR -- what to draw it from
        mov     al, CMDOP                ; 087A  AL -- the opcode
        xor     ah, ah                   ; 087D  AH=0: the whole command code now sits in AX
        and     al, 3Fh                  ; 087F  the command code is the low six bits
        cmp     ax, 3Dh                  ; 0881  3Dh -- the difficulty level test
        je      LBLDMA11                 ; 0884  the difficulty level test
        cmp     al, 20h                  ; 0886  codes below 20h are drawing primitives
        jb      LBLDMA9                  ; 0888  a drawing primitive
        cmp     CALLDEP, 0               ; 088A  are we inside an inserted fragment
        jne     LBLDMA3                  ; 088F  we are -- a fragment's objects are skipped
        mov     bx, OFFSET ROOMKND       ; 0891  the "object -> what it is made of" table
        xor     dh, dh                   ; 0894  DH=0: the whole object number now sits in DX
        mov     dl, ROOMOBN              ; 0896  DL -- number of the object within the room
        mov     si, dx                   ; 089A  SI -- the same number as an index
        mov     dx, ELMCUR               ; 089C  DL -- offset of the record within the ELMTAB ribbon
        mov     [bx+si], dl              ; 08A0  ROOMKND[number] -- what the object is made of
        cmp     al, 28h                  ; 08A2  codes 20h..27h are items
        jb      LBLDMA7                  ; 08A4  an item
        cmp     al, 30h                  ; 08A6  codes 28h..2Fh are doorways and ropes
        jb      LBLDMA8                  ; 08A8  a doorway or a rope
        call    PUTOBJ3                  ; 08AA  codes 30h..3Ch are enemies; they write nothing to the map
        jmp     short LBLDMA3            ; 08AD  off to step the pointer on by two bytes
LBLDMA7:
        call    PUTITEM                  ; 08AF  an item
        jmp     short LBLDMA3            ; 08B2  off to step the pointer on by two bytes
LBLDMA8:
        call    PUTROPE                  ; 08B4  a doorway or a rope
        jmp     short LBLDMA3            ; 08B7  off to step the pointer on by two bytes
LBLDMA9:
        mov     bx, OFFSET PRIMTAB       ; 08B9  table of the eight drawing primitives
        xor     ah, ah                   ; 08BC  AH=0: the whole command code now sits in AX
        mov     al, CMDOP                ; 08BE  AL -- the opcode
        shr     al, 1                    ; 08C1  opcode halved
        shr     al, 1                    ; 08C3  opcode divided by four
        and     al, 7                    ; 08C5  primitive number -- bits 4..2 of the opcode
        call    PRIMJMP                  ; 08C7  jump off to PRIMTAB[AL]
        jmp     LBLDMA4                  ; 08CA  the primitive handed the command length back in AL
LBLDMA10:
        push    RDPTR                    ; 08CD  the caller's reading point -- onto the stack
        push    ENDPTR                   ; 08D1  the caller's end of description -- onto the stack
        xor     bh, bh                   ; 08D5  BH=0: the whole mirror flag now sits in BX
        mov     bl, MIRFLAG              ; 08D7  BL -- the caller's mirror flag
        push    bx                       ; 08DB  and that goes on the stack too
        mov     bx, RDPTR                ; 08DC  BX -- start of the insert command
        inc     bx                       ; 08E0  second byte of the command
        mov     dl, [bx]                 ; 08E1  DL -- number of the room being inserted
        mov     al, CMDOP                ; 08E3  AL -- the opcode
        and     al, 1                    ; 08E6  low bit of the opcode
        mov     MIRFLAG, al              ; 08E8  3Fh -- insert it mirrored
        inc     CALLDEP                  ; 08EB  nesting depth one higher
        mov     al, dl                   ; 08EF  AL -- number of the room being inserted
        call    CURSIN                   ; 08F1  set RDPTR and ENDPTR onto its description
        jmp     BLDMAP                   ; 08F4  go read the fragment's description
LBLDMA11:
        mov     al, LEVEL                ; 08F7  AL -- the current difficulty level
        cmp     al, CMDX                 ; 08FA  match it against the threshold in the command
        jb      LBLDMA12                 ; 08FE  the level is below the threshold
        jmp     LBLDMA3                  ; 0900  threshold met: skip the command over
LBLDMA12:
        jmp     LBLDMA1                  ; 0903  below the threshold -- cut the description short

;-----------------------------------------------------------------------
; PUTHUD -- Copy the panel template into the top 5 rows of SCRMAP and
; put the score out.
;
; ALTERS : AX, BX, CX, DX, BP
; CALLED BY: MKROOM, TTLROOM
;-----------------------------------------------------------------------
PUTHUD:
        SAVEREG <si,di>                  ; 0906  macro
        mov     si, OFFSET HUDMAP        ; 0908  SI -- the panel template
        mov     di, OFFSET SCRMAP        ; 090B  DI -- start of the screen map
        mov     cx, HUD_CELLS            ; 090E  cells of the status panel
        cld                              ; 0911  MOVSB will run forward
        rep movsb                        ; 0912  the template is down in the top 5 rows of the map
        mov     HUDFULL, 1               ; 0914  put out the panel only, leave the room alone
        call    SHOWSCR                  ; 0919  the panel goes to the screen
        mov     HUDFULL, 0               ; 091C  the flag is cleared again
        RESTREG <di,si>                  ; 0921  macro
        ret                              ; 0923  return: the panel is up

;-----------------------------------------------------------------------
; MIRROR -- Flip the room left to right (rows 4..24), swapping tiles as
; it goes.
;
; EXIT   : SCRMAP
; ALTERS : BP
; CALLED BY: BLDMAP
;-----------------------------------------------------------------------
MIRROR:
        SAVEREG <ax,bx,cx,dx,si,di,es>   ; 0924  macro
        mov     dx, 4                    ; 092B  DX -- map row number, starting at 4
        mov     ax, ds                   ; 092E  DS -- segment of the image
        mov     es, ax                   ; 0930  ES = DS, ready for MOVSB
        mov     di, OFFSET SCRMAP        ; 0932  DI -- start of the screen map
        add     di, 0A0h                 ; 0935  A0h = 160: step over the 4 panel rows
        mov     si, OFFSET ROWBUF        ; 0939  SI -- the one-row buffer
LMIRRO1:
        add     si, 27h                  ; 093C  SI to the end of the buffer: 27h = 39
        mov     cx, MAP_W                ; 093F  cells across one map row
LMIRRO2:
        mov     al, [di]                 ; 0942  the cell on the left
        mov     [si], al                 ; 0944  the same cell, on the right in the buffer
        inc     di                       ; 0946  forward along the map row
        dec     si                       ; 0947  backward along the buffer
        loop    LMIRRO2                  ; 0948  the whole row is turned around
        call    MIRSUB                   ; 094A  swap the tiles for their mirror pairs
        add     si, MAP_W                ; 094D  SI to the end of the buffer
        dec     di                       ; 0950  DI to the last cell of the row
        mov     cx, MAP_W                ; 0951  cells across one map row
        std                              ; 0954  MOVSB will run backward
        rep movsb                        ; 0955  the buffer goes back into the map row
        inc     si                       ; 0957  SI to the start of the buffer
        inc     di                       ; 0958  DI to the start of the row
        add     di, MAP_W                ; 0959  DI down one row
        inc     dx                       ; 095C  one row down
        cmp     dx, 18h                  ; 095D  18h = 24 -- the last row of the room
        jle     LMIRRO1                  ; 0960  rows not used up yet
        RESTREG <es,di,si,dx,cx,bx,ax>   ; 0962  macro
        ret                              ; 0969  return: the room has been flipped

;-----------------------------------------------------------------------
; MIRSUB -- Swap the tiles in ROWBUF through the MIRSRC -> MIRDST tables.
;
; ENTRY  : ROWBUF
; EXIT   : ROWBUF
; ALTERS : nothing
; CALLED BY: MIRROR
;-----------------------------------------------------------------------
MIRSUB:
        SAVEREG <ax,bx,cx,dx,di,si,bp>   ; 096A  macro
        mov     bp, OFFSET MIRDST        ; 0971  BP -- what to swap them for
        mov     si, OFFSET ROWBUF        ; 0974  SI -- the row buffer
        mov     dx, MAP_W                ; 0977  cells across one map row
LMIRSU1:
        mov     al, [si]                 ; 097A  a cell out of the buffer
        cmp     al, 0                    ; 097C  0 -- empty
        je      LMIRSU2                  ; 097E  nothing to swap here
        cmp     al, 1                    ; 0980  1 -- the floor
        je      LMIRSU2                  ; 0982  nothing to swap here
        mov     di, OFFSET MIRSRC        ; 0984  DI -- what gets swapped
        mov     cx, 0Ah                  ; 0987  ten entries in the table
        cld                              ; 098A  SCASB will run forward
        repne scasb                      ; 098B  look for the cell among the swappable ones
        jne     LMIRSU2                  ; 098D  not found -- leave it as it stands
        mov     di, 0Ah                  ; 098F  ten entries in the table
        sub     di, cx                   ; 0992  CX was counted down during the search
        dec     di                       ; 0994  REPNE SCASB stepped one too far
        mov     al, ds:[bp+di]           ; 0995  MIRDST[the number just found]
        mov     [si], al                 ; 0998  the cell is swapped
LMIRSU2:
        inc     si                       ; 099A  on to the next cell of the buffer
        dec     dx                       ; 099B  one cell fewer to go
        jg      LMIRSU1                  ; 099C  row is not finished
        RESTREG <bp,si,di,dx,cx,bx,ax>   ; 099E  macro
        ret                              ; 09A5  return: the tiles are swapped for their pairs

;-----------------------------------------------------------------------
; ROOMID -- Room number = ROOMBAS[FLOOR] + ROOMPOS; floor >= 9 -> room 100.
;
; EXIT   : AL
; ALTERS : nothing
; CALLED BY: MKROOM
;-----------------------------------------------------------------------
ROOMID:
        SAVEREG <si,bx>                  ; 09A6  macro
        xor     bh, bh                   ; 09A8  BX = floor of the pyramid
        mov     bl, FLOOR                ; 09AA  BL -- the floor
        cmp     bl, 9                    ; 09AE  nine floors carry rooms: 0..8
        jl      LROOMI1                  ; 09B1  an ordinary floor -- work the number out
        mov     al, 64h                  ; 09B3  floor 9 and above -- the treasure chamber
        jmp     LROOMI2                  ; 09B5  off to the common exit
LROOMI1:
        mov     si, OFFSET ROOMBAS       ; 09B8  SI -- base room numbers by floor
        mov     al, cs:[bx+si]           ; 09BB  number of the first room on the floor
        add     al, ROOMPOS              ; 09BE  plus the position along the floor
LROOMI2:
        RESTREG <bx,si>                  ; 09C2  macro
        ret                              ; 09C4  return: the room number is in AL

;-----------------------------------------------------------------------
; ROOMBAS -- BASE ROOM NUMBERS BY FLOOR OF THE PYRAMID
;
; Room number = ROOMBAS[FLOOR] + ROOMPOS. The differences between
; neighboring entries run 4, 6, 8, 10, 12, 14, 16, 18, 11 -- exactly 99
; rooms, which is how many the game has. The last entry is repeated as
; a stopper.
;-----------------------------------------------------------------------
ROOMBAS DB    0F8h,0FCh,02h,0Ah,14h,20h,2Eh,3Eh,50h,5Bh,5Bh ; 09C5  first room of the floor

;-----------------------------------------------------------------------
; CURSIN -- Park the builder's cursor at the start of a room.
;
; ALTERS : nothing
; CALLED BY: BLDMAP, MKROOM
;-----------------------------------------------------------------------
CURSIN:
        SAVEREG <si,ax,bx>               ; 09D0  macro
        xor     bh, bh                   ; 09D3  BH=0: the whole room number now sits in BX
        mov     bl, al                   ; 09D5  BL -- the room number
        shl     bl, 1                    ; 09D7  pointers run two bytes apiece
        mov     si, OFFSET ROOMPT        ; 09D9  ROOMPT -- 100 pointers
        mov     ax, [bx+si]              ; 09DC  start of the description of room N
        mov     RDPTR, ax                ; 09DE  BLDMAP will start reading from here
        inc     bx                       ; 09E1  BX on to the next pointer
        inc     bx                       ; 09E2  the next pointer is the start of room N+1
        mov     ax, [bx+si]              ; 09E3  and that is the end of description N
        mov     ENDPTR, ax               ; 09E5  BLDMAP will read up to here
        RESTREG <bx,ax,si>               ; 09E8  macro
        ret                              ; 09EB  return: the room description has been located

;-----------------------------------------------------------------------
; OBJSEEN -- Has object number ROOMOBN been collected: a bit in
; SEENMAP[ROOMRQ]. The counter goes up either way.
;
; EXIT   : CF
; ALTERS : AX, CX
; CALLED BY: PUTITEM, PUTOBJ3, PUTROPE
;-----------------------------------------------------------------------
OBJSEEN:
        SAVEREG <si,bx>                  ; 09EC  macro
        mov     si, OFFSET SEENMAP       ; 09EE  SEENMAP: two bytes to a room
        xor     bh, bh                   ; 09F1  BH=0: the whole room number now sits in BX
        mov     bl, ROOMRQ               ; 09F3  BL -- the room asked for
        shl     bx, 1                    ; 09F7  two bytes to a record
        mov     cl, ROOMOBN              ; 09F9  CL -- number of the object within the room
        mov     al, 1                    ; 09FD  the mask will walk left by the object number
        clc                              ; 09FF  clear the carry ahead of the RCL
LOBJSE1:
        dec     cl                       ; 0A00  one object fewer between us and the one we want
        jl      LOBJSE2                  ; 0A02  we have arrived at our bit
        rcl     al, 1                    ; 0A04  shift the mask; a carry means we left the byte
        jae     LOBJSE1                  ; 0A06  the bit is still inside the first byte
        inc     bx                       ; 0A08  we have crossed into the second byte of the record
        rcl     ax, 1                    ; 0A09  the carry comes back into the low bit of AH
        jae     LOBJSE1                  ; 0A0B  the bit is still inside the second byte
LOBJSE2:
        inc     ROOMOBN                  ; 0A0D  the counter grows whether the object was collected or not
        and     al, [bx+si]              ; 0A11  bit set -- the object has been picked up already
        je      LOBJSE3                  ; 0A13  not set -- the object is still in place
        stc                              ; 0A15  CF=1: the object has been collected
        jmp     LOBJSE4                  ; 0A16  off to the common exit
LOBJSE3:
        clc                              ; 0A19  CF=0: the object is still in place
LOBJSE4:
        RESTREG <bx,si>                  ; 0A1A  macro
        ret                              ; 0A1C  return: the answer is in CF

;-----------------------------------------------------------------------
; TREASR -- The treasure chamber: room 100, with its own tune from MUSTAB.
;
; ALTERS : AX, BX, CX, DX, SI, DI, BP, ES
; CALLED BY: MKROOM
;-----------------------------------------------------------------------
TREASR:
        mov     ROOMNO, 64h              ; 0A1D  64h = 100 -- number of the treasure chamber
        mov     ROOMRQ, 0C8h             ; 0A22  C8h -- its record in SEENMAP
        mov     si, 0C8h                 ; 0A27  SI -- offset of the record
        mov     ax, 0                    ; 0A2A  AX=0 -- not a single bit
        mov     SEENMAP[si], ax          ; 0A2D  nothing in the treasure chamber counts as collected
        mov     FLOOR, 9                 ; 0A31  floor 9: ROOMBAS has no such floor, so it never goes dark
        mov     ITEMCNT, 0               ; 0A36  everything you carried stays outside the door
        mov     ROOMOBN, 0               ; 0A3B  no objects in the room yet
        inc     MUSSEL                   ; 0A40  tune counter one step on
        mov     al, MUSSEL               ; 0A44  AL -- the tune counter
        and     al, 3                    ; 0A47  four tunes around the ring
        xor     ah, ah                   ; 0A49  AH=0: the whole index now sits in AX
        mov     si, ax                   ; 0A4B  SI -- index of the tune
        shl     si, 1                    ; 0A4D  entries run two bytes apiece
        mov     si, MUSTAB[si]           ; 0A4F  SI -- tune number out of MUSTAB
        call    PLAYSND                  ; 0A53  the treasure chamber tune is off and running
        mov     ax, 0                    ; 0A56  AX=0 -- the "empty" cell
        mov     di, OFFSET SCRMAP        ; 0A59  DI -- start of the screen map
        mov     cx, 1F4h                 ; 0A5C  1F4h = 500 words = 1000 cells
        rep stosw                        ; 0A5F  the whole map is cleared
        mov     ax, OFFSET TRSMAP        ; 0A61  table of treasure chamber geometry
        mov     RDPTR, ax                ; 0A64  read from here
        xor     ah, ah                   ; 0A67  AH=0: the whole number now sits in AX
        mov     al, FRAMEC               ; 0A69  the frame counter picks which chamber it is
        and     al, 7                    ; 0A6C  eight geometry variants
        shl     al, 1                    ; 0A6E  n * 2
        shl     al, 1                    ; 0A70  n * 4
        mov     bx, ax                   ; 0A72  BX = 4n
        clc                              ; 0A74  clear the carry ahead of the ADC
        adc     ax, bx                   ; 0A75  AX = 8n
        adc     ax, bx                   ; 0A77  AX = 12n: records run 12 bytes apiece
        adc     ax, RDPTR                ; 0A79  plus the start of the table
        mov     RDPTR, ax                ; 0A7D  read from here
        mov     ENDPTR, ax               ; 0A80  ENDPTR -- the same point for now, it moves on below
        adc     ENDPTR, 24h              ; 0A83  24h = 36 bytes -- a window of three records
        call    BLDMAP                   ; 0A88  build the geometry of the treasure chamber
        mov     ax, OFFSET TRSGEM        ; 0A8B  table of the gem scatter
        mov     RDPTR, ax                ; 0A8E  read from here
        xor     ah, ah                   ; 0A91  AH=0: the whole number now sits in AX
        mov     al, FRAMEC               ; 0A93  the frame counter picks which scatter it is
        and     al, 0Fh                  ; 0A96  sixteen variants
        mov     bx, ax                   ; 0A98  BX = n
        shl     ax, 1                    ; 0A9A  AX = 2n
        clc                              ; 0A9C  clear the carry ahead of the ADC
        adc     ax, bx                   ; 0A9D  AX = 3n
        shl     ax, 1                    ; 0A9F  AX = 6n: records run 6 bytes apiece
        adc     ax, RDPTR                ; 0AA1  plus the start of the table
        mov     RDPTR, ax                ; 0AA5  read from here
        mov     ENDPTR, ax               ; 0AA8  ENDPTR -- the same point for now, it moves on below
        mov     al, LEVEL                ; 0AAB  AL -- the difficulty level
        cmp     al, 5                    ; 0AAE  levels past the fourth count as the fourth
        jl      LTREAS1                  ; 0AB0  the level is below the fifth
        mov     al, 4                    ; 0AB2  past the fourth no more gems are added
LTREAS1:
        xor     ah, ah                   ; 0AB4  AH=0: the whole level now sits in AX
        shl     ax, 1                    ; 0AB6  level * 2
        shl     ax, 1                    ; 0AB8  level * 4
        clc                              ; 0ABA  clear the carry ahead of the ADC
        adc     ax, 0Eh                  ; 0ABB  plus 0Eh bytes: the higher the level, the wider the window
        adc     ENDPTR, ax               ; 0ABE  read up to here
        call    BLDMAP                   ; 0AC2  scatter the gems
        mov     al, ROOMPOS              ; 0AC5  AL -- position along the floor
        cmp     al, 8                    ; 0AC8  positions 0..8 -- the left-hand exit
        jg      LTREAS2                  ; 0ACA  position 9 and further right
        mov     al, 8                    ; 0ACC  position 8 -- left edge of the treasure chamber
        mov     ROOMPOS, al              ; 0ACE  position 8 -- the left-hand door
        mov     RDPTR, OFFSET TRSDRL     ; 0AD1  description of the left-hand door
        mov     ENDPTR, OFFSET TRSDRR    ; 0AD7  up to the start of the right-hand one
        call    BLDMAP                   ; 0ADD  build the left-hand door
        ret                              ; 0AE0  return: the treasure chamber is built
LTREAS2:
        cmp     al, 0Ah                  ; 0AE1  positions 0Ah and above -- the right-hand exit
        jl      LTREAS3                  ; 0AE3  position 9 -- no doors at all
        mov     al, 0Ah                  ; 0AE5  position 0Ah -- right edge of the treasure chamber
        mov     ROOMPOS, al              ; 0AE7  position 0Ah -- the right-hand door
        mov     RDPTR, OFFSET TRSDRR     ; 0AEA  description of the right-hand door
        mov     ENDPTR, OFFSET TTLMAP    ; 0AF0  up to the start of the title screen byte code
        call    BLDMAP                   ; 0AF6  build the right-hand door
LTREAS3:
        ret                              ; 0AF9  return: the treasure chamber is built

;-----------------------------------------------------------------------
; PUTROPE -- Objects 28h..2Fh. Bits 0..2 of the opcode >= 3 mean a single
; tile, otherwise a column four cells deep: a rope.
;
; ENTRY  : CMDOP
; EXIT   : SCRMAP
; ALTERS : AX, BX, CX, DX, SI, DI
; CALLED BY: BLDMAP
;-----------------------------------------------------------------------
PUTROPE:
        call    ELMTILE                  ; 0AFA  DI -- the map cell, AL -- first tile of the element
        mov     ah, CMDOP                ; 0AFD  AH -- the opcode
        and     ah, 7                    ; 0B01  bits 2..0 of the opcode
        cmp     ah, 3                    ; 0B04  3 and above -- a single tile
        jl      LPUTRO1                  ; 0B07  below 3 -- a rope four cells deep
        mov     [di], al                 ; 0B09  the tile is down in the cell
        jmp     LPUTGR4                  ; 0B0B  off to the common exit
LPUTRO1:
        xor     ah, ah                   ; 0B0E  AH=0: the whole object number now sits in AX
        mov     al, ROOMOBN              ; 0B10  AL -- sequence number of the object within the room
        call    OBJREG                   ; 0B13  enter the object into the room's tables
        call    OBJSEEN                  ; 0B16  has it been collected already
        jae     LPUTRO2                  ; 0B19  CF=0 -- the object is still in place
        jmp     PUTGRID                  ; 0B1B  collected -- a grille goes where it was
LPUTRO2:
        mov     si, ELMCUR               ; 0B1E  SI -- offset of the element within the ribbon
        mov     al, [bx+si]              ; 0B22  first tile of the element
        mov     cx, 1                    ; 0B24  width 1 cell
        mov     dl, 3                    ; 0B27  height DL+1 = 4 cells: a rope
        call    FILLRC                   ; 0B29  the column is filled
        jmp     LPUTGR4                  ; 0B2C  off to the common exit

;-----------------------------------------------------------------------
; PUTGRID -- If the object has already been collected, a 3x3 grille out
; of the tail of ELMTAB goes where it was.
;
; EXIT   : SCRMAP
; ALTERS : AX, SI, DI
; CALLED BY: OPENDOOR, PUTROPE (via JMP)
;-----------------------------------------------------------------------
PUTGRID:
        mov     si, ELMCUR               ; 0B2F  SI -- offset of the element within the ribbon
        inc     si                       ; 0B33  step over the first tile
        add     si, bx                   ; 0B34  plus the start of the ribbon
        add     si, 2                    ; 0B36  the grille lies two tiles on from the element
        mov     cx, 3                    ; 0B39  three cells to a row
LPUTGR1:
        movsb                            ; 0B3C  the tile is down in the cell
        dec     si                       ; 0B3D  MOVSB stepped forward, put SI back
        dec     si                       ; 0B3E  MOVSB stepped forward, put SI back
        loop    LPUTGR1                  ; 0B3F  a row of the grille is done
        add     di, 25h                  ; 0B41  25h = 37: carry over to the row below
        add     si, 6                    ; 0B44  SI on to the next row of the grille
        mov     cx, 3                    ; 0B47  three rows of the grille left
LPUTGR2:
        push    cx                       ; 0B4A  the row counter onto the stack
        mov     cx, 3                    ; 0B4B  three cells to a row
LPUTGR3:
        movsb                            ; 0B4E  the tile is down in the cell
        dec     si                       ; 0B4F  MOVSB stepped forward, put SI back
        dec     si                       ; 0B50  MOVSB stepped forward, put SI back
        loop    LPUTGR3                  ; 0B51  a row of the grille is done
        add     si, 3                    ; 0B53  SI on to the next row of the grille
        add     di, 25h                  ; 0B56  25h = 37: carry over to the row below
        pop     cx                       ; 0B59  the row counter off the stack
        loop    LPUTGR2                  ; 0B5A  the 3x3 grille is laid down
LPUTGR4:
        mov     al, 2                    ; 0B5C  AL=2 -- length of an object command
        ret                              ; 0B5E  return: the command length is in AL

;-----------------------------------------------------------------------
; PRIMTAB -- THE EIGHT DRAWING PRIMITIVES  (0B5F..0B6E, 16 bytes)
;
; Index = (opcode shr 2) and 7. Entries 0 and 4, 1 and 5 are the same:
; what tells them apart are the modifier bits of the opcode itself.
;-----------------------------------------------------------------------
; table of the eight drawing primitives
PRIMTAB LABEL WORD                       ; 0B5F
        DW    PR_RECT                    ; 0B5F  0 rectangle
        DW    PR_COL                     ; 0B61  1 column
        DW    PR_DIAG                    ; 0B63  2 diagonal
        DW    PR_BAND                    ; 0B65  3 band
        DW    PR_RECT                    ; 0B67  4 rectangle
        DW    PR_COL                     ; 0B69  5 column
        DW    PR_DIAG2                   ; 0B6B  6 diagonal going down
        DW    PR_PATT                    ; 0B6D  7 pattern

;-----------------------------------------------------------------------
; PR_RECT -- Primitive 0: a rectangle of one tile.
;
; ENTRY  : CMDOP, CMDP1, CMDP2
; EXIT   : SCRMAP
; ALTERS : AX, BX, CX, DX, SI, DI
; CALLED BY: PRIMTAB[0], PRIMTAB[4]
;-----------------------------------------------------------------------
PR_RECT:
        call    ELMTILE                  ; 0B6F  DI -- the map cell, AL -- first tile of the element
        mov     bl, CMDOP                ; 0B72  BL -- the opcode
        and     bl, 1                    ; 0B76  bit 0 of the opcode -- are the parameters packed
        jne     LPRREC1                  ; 0B79  bit set -- the parameters lie separately
        jmp     PARMSPL                  ; 0B7B  bit 0 clear -- the parameters are packed into CMDP1
LPRREC1:
        xor     ch, ch                   ; 0B7E  CH=0: the whole count now sits in CX
        mov     cl, CMDP1                ; 0B80  CL -- width minus one
        inc     cx                       ; 0B84  CX -- width in cells
        mov     dl, CMDP2                ; 0B85  DL -- height minus one
        mov     CMDLEN, 4                ; 0B89  the command takes four bytes
        jmp     FILLRC                   ; 0B8F  fill the rectangle in

;-----------------------------------------------------------------------
; PARMSPL -- Unpack CMDP1: the high four bits plus one are the count,
; the low four are the column.
;
; ENTRY  : CMDP1
; EXIT   : CX, DL
; ALTERS : AX, BX, DI
; CALLED BY: PR_RECT (via JMP), SHOWSCR
;-----------------------------------------------------------------------
PARMSPL:
        mov     bl, CMDP1                ; 0B92  BL -- the packed parameters
        mov     bh, bl                   ; 0B96  BH -- a copy of the same
        shr     bl, 1                    ; 0B98  shift 1 of four
        shr     bl, 1                    ; 0B9A  shift 2 of four
        shr     bl, 1                    ; 0B9C  shift 3 of four
        shr     bl, 1                    ; 0B9E  the high four bits of BL come down
        mov     cl, bl                   ; 0BA0  CL -- width minus one
        xor     ch, ch                   ; 0BA2  CH=0: the whole count now sits in CX
        inc     cx                       ; 0BA4  CX -- width in cells
        and     bh, 0Fh                  ; 0BA5  the low four bits of BH
        mov     dl, bh                   ; 0BA8  DL -- height minus one
        mov     CMDLEN, 3                ; 0BAA  the command takes three bytes

;-----------------------------------------------------------------------
; FILLRC -- Fill CX x (DL+1) cells with tile AL, starting from DI.
;
; ENTRY  : AL, CX, DL, DI
; EXIT   : DI
; ALTERS : AX, CX, DX
; CALLED BY: PARMSPL (falls through), PR_BAND, PR_COL, PR_DIAG,
;          PR_RECT (via JMP), PUTROPE, TAKEDRW
;-----------------------------------------------------------------------
FILLRC:
        push    bx                       ; 0BB0  BX comes back at 0BC4
        mov     bx, cx                   ; 0BB1  BX -- the width, since CX is about to lose it
        cld                              ; 0BB3  STOSB will run forward
LFILLR1:
        rep stosb                        ; 0BB4  the row is filled with tile AL
        mov     cx, bx                   ; 0BB6  CX -- the width once again
        sub     di, cx                   ; 0BB8  DI back to the start of the row just filled
        add     di, MAP_W                ; 0BBA  carry over to the row below
        dec     dl                       ; 0BBD  one row fewer to go
        jge     LFILLR1                  ; 0BBF  rows not used up yet
        mov     ax, CMDLEN               ; 0BC1  AX -- the command length, for BLDMAP
        pop     bx                       ; 0BC4  BX restored
        ret                              ; 0BC5  return: the command length is in AL

;-----------------------------------------------------------------------
; ELMTILE -- DI from CURSPOS, AL = first tile of the current element.
;
; EXIT   : AL, DI
; ALTERS : BX, CX, SI
; CALLED BY: PR_BAND, PR_COL, PR_DIAG, PR_PATT, PR_RECT, PUTITEM, PUTROPE,
;          SHOWSCR
;-----------------------------------------------------------------------
ELMTILE:
        call    CURSPOS                  ; 0BC6  DI -- the map cell, from CMDOP and CMDX
        mov     si, ELMCUR               ; 0BC9  SI -- offset of the element within the ribbon
        mov     bx, OFFSET ELMTAB        ; 0BCD  BX -- head of the element ribbon
        mov     al, [bx+si]              ; 0BD0  AL -- first tile of the element
        ret                              ; 0BD2  return: DI and AL are ready

;-----------------------------------------------------------------------
; PR_COL -- Primitive 1: a column that narrows, stepping downward.
;
; EXIT   : SCRMAP
; ALTERS : BX, CX, DX, SI, DI
; CALLED BY: PRIMTAB[1], PRIMTAB[5]
;-----------------------------------------------------------------------
PR_COL:
        call    ELMTILE                  ; 0BD3  DI -- the map cell, AL -- first tile of the element
        xor     ch, ch                   ; 0BD6  CH=0: the whole width now sits in CX
        mov     cl, CMDP1                ; 0BD8  CL -- width of the first column
        mov     dx, cx                   ; 0BDC  DX -- the same value
        mov     bl, CMDOP                ; 0BDE  BL -- the opcode
        and     bl, 10h                  ; 0BE2  bit 4 of the opcode
        je      LPRCOL1                  ; 0BE5  bit clear -- the height stands as it is
        shl     dx, 1                    ; 0BE7  bit set -- the first column is twice as tall
LPRCOL1:
        dec     dx                       ; 0BE9  DL -- height minus one
        call    FILLRC                   ; 0BEA  the first column is filled
        call    CURSPOS                  ; 0BED  DI back to the original map cell
        mov     si, ELMCUR               ; 0BF0  SI -- offset of the element within the ribbon
        inc     si                       ; 0BF4  second tile of the element
        mov     bx, OFFSET ELMTAB        ; 0BF5  BX -- head of the element ribbon
        mov     al, [bx+si]              ; 0BF8  AL -- the tile to carry on with
        xor     ah, ah                   ; 0BFA  AH=0: the whole tile now sits in AX
        cmp     ax, 0                    ; 0BFC  a zero tile -- nothing to carry on with
        jne     LPRCOL2                  ; 0BFF  there is one -- draw the step
        dec     CMDP1                    ; 0C01  one cell less across
        call    OPODD                    ; 0C05  shift DI by the low bit of the opcode
LPRCOL2:
        xor     ch, ch                   ; 0C08  CH=0: the whole width now sits in CX
        mov     cl, CMDP1                ; 0C0A  CL -- width of the current step
        mov     dl, CMDOP                ; 0C0E  DL -- the opcode
        and     dl, 10h                  ; 0C12  bit 4 of the opcode
        shr     dl, 1                    ; 0C15  shift 1 of four
        shr     dl, 1                    ; 0C17  shift 2 of four
        shr     dl, 1                    ; 0C19  shift 3 of four
        shr     dl, 1                    ; 0C1B  bit 4 comes down: DL = 0 or 1
        push    ax                       ; 0C1D  AX -- the step's tile, and FILLRC changes it
        call    FILLRC                   ; 0C1E  the step is filled
        pop     ax                       ; 0C21  AX -- the step's tile
        call    OPODD                    ; 0C22  shift DI by the low bit of the opcode
        dec     CMDP1                    ; 0C25  one cell less across
        jl      LPRCOL3                  ; 0C29  the width has run out
        jmp     short LPRCOL2            ; 0C2B  on to the next step
LPRCOL3:
        mov     al, 3                    ; 0C2D  AL=3 -- length of a column command
        ret                              ; 0C2F  return: the command length is in AL

;-----------------------------------------------------------------------
; OPODD -- If the low bit of the opcode is set, shift DI one cell to
; the right.
;
; ENTRY  : CMDOP
; EXIT   : DI
; ALTERS : nothing
; CALLED BY: PR_COL
;-----------------------------------------------------------------------
OPODD:
        push    bx                       ; 0C30  BX comes back at 0C3B
        mov     bl, CMDOP                ; 0C31  BL -- the opcode
        and     bl, 1                    ; 0C35  low bit of the opcode
        je      LOPODD1                  ; 0C38  clear -- leave the cursor where it is
        inc     di                       ; 0C3A  set -- cursor one cell right
LOPODD1:
        pop     bx                       ; 0C3B  BX restored
        ret                              ; 0C3C  return: DI has been adjusted

;-----------------------------------------------------------------------
; PR_DIAG -- Primitive 2: a diagonal staircase built from the element's tiles.
;
; EXIT   : SCRMAP
; ALTERS : AX, BX, CX, DX, SI, DI
; CALLED BY: PRIMTAB[2], PR_DIAG2, PR_DIAG2 (via JMP)
;-----------------------------------------------------------------------
PR_DIAG:
        call    ELMTILE                  ; 0C3D  DI -- the map cell, AL -- first tile of the element
        mov     dh, al                   ; 0C40  DH -- how many steps the staircase has
        inc     ELMCUR                   ; 0C42  the first tile is a count, not a picture
        mov     si, ELMCUR               ; 0C46  SI -- offset of the first picture
        mov     cl, dh                   ; 0C4A  CL -- number of steps
        xor     ch, ch                   ; 0C4C  CH=0: the whole count now sits in CX
        add     si, cx                   ; 0C4E  SI -- one past the last picture of the staircase
LPRDIA1:
        dec     dh                       ; 0C50  one step fewer to go
        jl      LPRDIA2                  ; 0C52  the staircase is finished
        dec     si                       ; 0C54  SI -- picture of this step
        mov     al, [bx+si]              ; 0C55  AL -- its tile
        xor     ch, ch                   ; 0C57  CH=0: the whole shift now sits in CX
        mov     cl, dh                   ; 0C59  CL -- number of the step
        add     di, cx                   ; 0C5B  each step sits one cell right of the one before
        mov     dl, CMDP1                ; 0C5D  DL -- height of the step minus one
        dec     dl                       ; 0C61  we will count down to zero inclusive
        mov     cl, 1                    ; 0C63  a step is one cell wide
        call    FILLRC                   ; 0C65  the step is filled
        call    CURSPOS                  ; 0C68  DI back to the original map cell
        jmp     short LPRDIA1            ; 0C6B  on to the next step
LPRDIA2:
        mov     al, 3                    ; 0C6D  AL=3 -- length of a diagonal command
        ret                              ; 0C6F  return: the command length is in AL

;-----------------------------------------------------------------------
; PR_DIAG2 -- Primitive 6: a diagonal, then a second one at an ELMCUR
; offset. This is how ladders are drawn: columns 2Ah/2Bh and top 28h.
;
; EXIT   : SCRMAP
; ALTERS : AX, BX, CX, DX, SI, DI
; CALLED BY: PRIMTAB[6]
;-----------------------------------------------------------------------
PR_DIAG2:
        call    PR_DIAG                  ; 0C70  the first diagonal is drawn
        mov     si, ELMCUR               ; 0C73  SI -- offset of the element within the ribbon
        dec     si                       ; 0C77  last byte of the first diagonal
        mov     al, [bx+si]              ; 0C78  AL -- how far to move along the ribbon
        xor     ah, ah                   ; 0C7A  AH=0: the whole shift now sits in AX
        add     ELMCUR, ax               ; 0C7C  the element of the second diagonal
        mov     CMDP1, 1                 ; 0C80  the second diagonal is one cell tall
        jmp     short PR_DIAG            ; 0C85  draw the second diagonal

;-----------------------------------------------------------------------
; PR_BAND -- Primitive 3: a band with different ends. Three rows of
; shrinking length land in the same cell, so what is left is a left end,
; a middle and a right end.
;
; EXIT   : SCRMAP
; ALTERS : AX, BX, DX, SI, DI
; CALLED BY: PRIMTAB[3]
;-----------------------------------------------------------------------
PR_BAND:
        call    ELMTILE                  ; 0C87  DI -- the map cell, AL -- first tile of the element
        xor     ch, ch                   ; 0C8A  CH=0: the whole tile now sits in CX
        mov     cl, [bx+si+1]            ; 0C8C  second tile of the element
        cmp     cx, SOLID_MIN            ; 0C8F  the marker for a solid band
        je      LPRPAT1                  ; 0C93  no ends -- a plain fill
        mov     cx, 2                    ; 0C95  three rows: left end, middle, right end
LPRBAN1:
        mov     al, [bx+si]              ; 0C98  AL -- tile of the current row
        cmp     cx, 0                    ; 0C9A  the last row?
        jne     LPRBAN2                  ; 0C9D  no -- draw it as a band
        mov     [di], al                 ; 0C9F  the right end -- a single cell
        jmp     LPRBAN3                  ; 0CA1  off to the end of the primitive
LPRBAN2:
        push    cx                       ; 0CA4  the row counter onto the stack
        xor     ch, ch                   ; 0CA5  CH=0: the whole width now sits in CX
        mov     cl, CMDP1                ; 0CA7  CL -- length of the band
        mov     dl, 0                    ; 0CAB  DL=0 -- one cell tall
        call    FILLRC                   ; 0CAD  the row is filled
        pop     cx                       ; 0CB0  the row counter off the stack
        dec     CMDP1                    ; 0CB1  every row after this one is a cell shorter
        call    CURSPOS                  ; 0CB5  DI back to the original map cell
        inc     si                       ; 0CB8  SI -- tile of the next row
        dec     cl                       ; 0CB9  one row fewer to go
        jge     LPRBAN1                  ; 0CBB  rows not used up yet
LPRBAN3:
        mov     al, 3                    ; 0CBD  AL=3 -- length of a band command
        ret                              ; 0CBF  return: the command length is in AL

;-----------------------------------------------------------------------
; PR_PATT -- Primitive 7: a band P1 long, tiled with a repeating pattern.
; The commonest of the lot: 626 calls across the 99 rooms.
;
; EXIT   : SCRMAP
; ALTERS : AX, BX, CX, SI, DI
; CALLED BY: PRIMTAB[7], SHOWSCR
;-----------------------------------------------------------------------
PR_PATT:
        call    ELMTILE                  ; 0CC0  DI -- the map cell, AL -- first tile of the element
LPRPAT1:
        mov     PATLEFT, al              ; 0CC3  AL -- length of the pattern, and the remainder too
        mov     PATLEN, al               ; 0CC6  and the whole length is kept as well
        mov     cl, CMDP1                ; 0CC9  CL -- length of the band
        dec     cl                       ; 0CCD  we will count down to zero inclusive
LPRPAT2:
        dec     PATLEFT                  ; 0CCF  one pattern cell fewer to go
        jge     LPRPAT3                  ; 0CD3  the pattern is not used up
        mov     al, PATLEN               ; 0CD5  AL -- the full length of the pattern
        mov     PATLEFT, al              ; 0CD8  the remainder is loaded afresh
        xor     ah, ah                   ; 0CDB  AH=0: the whole length now sits in AX
        sub     ELMCUR, ax               ; 0CDD  the ribbon winds back to the head of the pattern
        dec     PATLEFT                  ; 0CE1  the first cell of the new round is already counted
LPRPAT3:
        mov     si, ELMCUR               ; 0CE5  SI -- offset of the element within the ribbon
        inc     si                       ; 0CE9  the first tile is the length, the pictures come after
        mov     al, [bx+si]              ; 0CEA  AL -- a tile of the pattern
        mov     [di], al                 ; 0CEC  the tile is down in the cell
        inc     di                       ; 0CEE  DI one cell right
        inc     ELMCUR                   ; 0CEF  the ribbon one tile on
        dec     cl                       ; 0CF3  one cell of the band fewer to go
        jge     LPRPAT2                  ; 0CF5  the band is not finished
        mov     al, 3                    ; 0CF7  AL=3 -- length of a pattern command
        ret                              ; 0CF9  return: the command length is in AL

;-----------------------------------------------------------------------
; PUTITEM -- Objects 20h..27h: an item as a 2x2 square, if it has not
; been collected yet.
; ENTRY  : CMDOP
; EXIT   : SCRMAP
; ALTERS : AX, BX, CX, DX, SI, DI
; CALLED BY: BLDMAP
;-----------------------------------------------------------------------
PUTITEM:
        call    OBJSEEN                  ; 0CFA  has the item been collected
        jb      LPUTXE3                  ; 0CFD  collected -- write nothing to the map
        call    ELMTILE                  ; 0CFF  DI -- the map cell, AL -- first tile of the element
        xor     ah, ah                   ; 0D02  AH=0: the whole object number now sits in AX
        mov     al, ROOMOBN              ; 0D04  AL -- sequence number of the object
        dec     ax                       ; 0D07  OBJSEEN has already bumped the counter
        call    OBJREG                   ; 0D08  record the item's offset in ROOMOBJ
        jmp     PUT2X2E                  ; 0D0B  lay the item down as a 2x2 square

;-----------------------------------------------------------------------
; PUT2X2 -- Lay a 2x2 down out of the element's four tiles. The anchor is
; the cell left of DI+1. Two entries: 0D0E clears LITMSK, 0D13 (PUT2X2E)
; goes straight to laying it down.
;
; ENTRY  : DI, SI
; EXIT   : SCRMAP
; ALTERS : AX, CX, DX, SI, DI
; CALLED BY: PUTITM, SHOWSCR
;-----------------------------------------------------------------------
PUT2X2:
        mov     LITMSK, 0FFh             ; 0D0E  lighting mask: every dot is lit
PUT2X2E:        ; second entry to PUT2X2: no LITMSK reset, PUTITEM jumps here
        mov     cx, 2                    ; 0D13  two rows to the square
LPUTXE1:
        mov     dx, 2                    ; 0D16  two cells to a row
        inc     di                       ; 0D19  DI to the right-hand cell of the row
LPUTXE2:
        mov     al, [bx+si]              ; 0D1A  AL -- a tile out of the element
        mov     [di], al                 ; 0D1C  the tile is down in the cell
        inc     si                       ; 0D1E  the ribbon one tile on
        dec     di                       ; 0D1F  along the row from right to left
        dec     dx                       ; 0D20  one cell of the row fewer to go
        jg      LPUTXE2                  ; 0D21  the row is not finished
        dec     cx                       ; 0D23  one row fewer to go
        je      LPUTXE3                  ; 0D24  the square is laid down
        add     di, MAP_W                ; 0D26  carry over to the row below
        inc     di                       ; 0D29  and one cell right
        jmp     short LPUTXE1            ; 0D2A  the second row of the square
LPUTXE3:
        mov     al, 2                    ; 0D2C  AL=2 -- length of an object command
        ret                              ; 0D2E  return: the command length is in AL

;-----------------------------------------------------------------------
; OBJREG -- Record the offset of object AX in ROOMOBJ: ROOMOBJ[AX*2] = DI - BP.
;
; ENTRY  : AX, DI
; EXIT   : ROOMOBJ
; ALTERS : nothing
; CALLED BY: PUTITEM, PUTROPE
;-----------------------------------------------------------------------
OBJREG:
        SAVEREG <si,bx>                  ; 0D2F  macro
        mov     si, ax                   ; 0D31  SI -- the object number
        shl     si, 1                    ; 0D33  entries run two bytes apiece
        mov     bx, OFFSET ROOMOBJ       ; 0D35  BX -- table of the room objects' offsets
        mov     [bx+si], di              ; 0D38  DI -- absolute offset of the cell
        sub     [bx+si], bp              ; 0D3A  minus the map base: the offset within it
        RESTREG <bx,si>                  ; 0D3C  macro
        ret                              ; 0D3E  return: the object is recorded

;-----------------------------------------------------------------------
; CURSPOS -- DI = SCRMAP + (CMDOP shr 6)*256 + CMDX.
;
; ENTRY  : CMDOP, CMDX
; EXIT   : DI
; ALTERS : nothing
; CALLED BY: ELMTILE, PR_BAND, PR_COL, PR_DIAG, PUTITM, SHOWSCR
;-----------------------------------------------------------------------
CURSPOS:
        SAVEREG <ax,cx>                  ; 0D3F  macro
        mov     di, bp                   ; 0D41  DI -- the map base
        mov     ah, CMDOP                ; 0D43  AH -- the opcode
        mov     cl, 6                    ; 0D47  shift by six places
        shr     ah, cl                   ; 0D49  bits 7..6 of the opcode -- high byte of the offset
        mov     al, CMDX                 ; 0D4B  AL -- low byte of the offset
        add     di, ax                   ; 0D4E  DI -- the map cell
        RESTREG <cx,ax>                  ; 0D50  macro
        ret                              ; 0D52  return: DI is on the cell

;-----------------------------------------------------------------------
; ELMSET -- ELMCUR = ELMSEL[CMDOP and 3Fh].
;
; ENTRY  : CMDOP
; EXIT   : ELMCUR
; ALTERS : nothing
; CALLED BY: BLDMAP
;-----------------------------------------------------------------------
ELMSET:
        SAVEREG <bx,si,ax>               ; 0D53  macro
        mov     bx, OFFSET ELMSEL        ; 0D56  BX -- the "command code -> element" table
        mov     al, CMDOP                ; 0D59  AL -- the opcode
        and     al, 3Fh                  ; 0D5C  the command code is the low six bits
        xor     ah, ah                   ; 0D5E  AH=0: the whole code now sits in AX
        mov     si, ax                   ; 0D60  SI -- the same code as an index
        mov     al, [bx+si]              ; 0D62  AL -- offset of the element within the ribbon
        mov     ELMCUR, ax               ; 0D64  ELMCUR -- what to draw it from
        RESTREG <ax,si,bx>               ; 0D67  macro
        ret                              ; 0D6A  return: the element is chosen

;-----------------------------------------------------------------------
; DISPAT -- The dispatcher: BX = table base, AL = index, jump to the address.
;
; ENTRY  : AL, BX
; EXIT   : jmp
; ALTERS : AX, BX, CX
; CALLED BY: MAINLP, PLRSTEP
;-----------------------------------------------------------------------
DISPAT:
        xor     ah, ah                   ; 0D6B  AH=0: the whole index now sits in AX
        shl     ax, 1                    ; 0D6D  entries run two bytes apiece
        add     bx, ax                   ; 0D6F  BX -- the table entry
        mov     cx, cs:[bx]              ; 0D71  CX -- address of the handler
        jmp     cx                       ; 0D74  off into the handler; its return goes to whoever called us

;-----------------------------------------------------------------------
; DISPATF -- A dispatcher over a table in another segment: BP:BX, index
; AL. The address goes into FARPTR and the jump is far. Nothing refers to it.
; ALTERS : AX, BX, SI
;-----------------------------------------------------------------------
DISPATF:
        xor     ah, ah                   ; 0D76  AH=0: the whole index now sits in AX
        shl     ax, 1                    ; 0D78  number -> word offset
        add     bx, ax                   ; 0D7A  BX -- the table entry
        push    es                       ; 0D7C  ES comes back at 0D82
        mov     es, bp                   ; 0D7D  BP -- segment of the table
        mov     ax, es:[bx]              ; 0D7F  AX -- offset of the handler
        pop     es                       ; 0D82  ES restored
        mov     FARPTR, ax               ; 0D83  offset of the far jump
        mov     FARPTRS, bp              ; 0D86  its segment -- the same as the table's
        jmp     DWORD PTR FARPTR         ; 0D8A  off to the address just assembled

;-----------------------------------------------------------------------
; PRIMJMP -- The primitive dispatcher: take the address by number AL out
; of table BX and go there by a far jump through FARPTR.
;
; ENTRY  : AL, BX
; ALTERS : AX, BX, SI
; CALLED BY: BLDMAP, DISPATF (falls through)
;-----------------------------------------------------------------------
PRIMJMP:
        xor     ah, ah                   ; 0D8E  AH=0: the whole number now sits in AX
        shl     ax, 1                    ; 0D90  entries run two bytes apiece
        add     bx, ax                   ; 0D92  BX -- the table entry
        mov     ax, cs:[bx]              ; 0D94  AX -- address of the primitive
        mov     FARPTR, ax               ; 0D97  offset of the far jump
        mov     FARPTRS, cs              ; 0D9A  segment of the image
        jmp     DWORD PTR FARPTR         ; 0D9E  off into the primitive; its return goes back to BLDMAP

;-----------------------------------------------------------------------
; LITCHK -- Is the room lit. It is dark when FLOOR < 9, FLOOR+LEVEL >= 9
; and there is no torch (3Fh) in the inventory.
;
; ENTRY  : FLOOR, LEVEL, ITEMS
; EXIT   : CF = dark, DARKF, LITMSK
; ALTERS : nothing
; CALLED BY: DRAWFRM, PRIMJMP (falls through)
;-----------------------------------------------------------------------
LITCHK:
        SAVEREG <bx,si,ax>               ; 0DA2  macro
        mov     al, FLOOR                ; 0DA5  floor of the pyramid
        cmp     al, 9                    ; 0DA8  floor 9 -- the treasure chamber, always lit
        jge     LLITCH2                  ; 0DAA  floor 9 and above -- lit
        clc                              ; 0DAC  clear the carry ahead of the ADC
        adc     al, LEVEL                ; 0DAD  depth plus difficulty
        cmp     al, 9                    ; 0DB1  nine -- the threshold of darkness
        jl      LLITCH2                  ; 0DB3  shallow or easy -- lit
        mov     bx, OFFSET ITEMS         ; 0DB5  go looking for a torch in the inventory
        xor     ah, ah                   ; 0DB8  AH=0: the whole count now sits in AX
        mov     al, ITEMCNT              ; 0DBA  how many items are being carried
        mov     si, ax                   ; 0DBD  SI -- the same count as an index
        shl     si, 1                    ; 0DBF  slots run a word apiece
LLITCH1:
        dec     si                       ; 0DC1  step 1 of two: slots run a word apiece
        dec     si                       ; 0DC2  SI on to the previous slot
        jl      LLITCH3                  ; 0DC3  slots used up -- there is no torch
        cmp     WORD PTR [bx+si], ELM_TRCH ; 0DC5  3Fh -- element code of the torch
        jne     LLITCH1                  ; 0DC9  not the torch -- look at the previous slot
LLITCH2:
        mov     LITMSK, 0FFh             ; 0DCB  lit: the masks go back to their default
        mov     DARKF, 0                 ; 0DD0  the darkness flag is cleared
        clc                              ; 0DD5  CF = 0
        jmp     LLITCH4                  ; 0DD6  off to the common exit
LLITCH3:
        mov     LITMSK, 0F0h             ; 0DD9  dark: the lighting masks
        mov     DARKF, 0F0h              ; 0DDE  the darkness flag is set
        stc                              ; 0DE3  CF = 1 -- the caller will go on to call DARKEN
LLITCH4:
        RESTREG <ax,si,bx>               ; 0DE4  macro
        ret                              ; 0DE7  return: the answer is in CF

;-----------------------------------------------------------------------
; DRWALL -- Full screen draw: 40x25 tiles through INT 67h.
;
; ENTRY  : SCRMAP
; EXIT   : B800h
; ALTERS : nothing
; CALLED BY: DRAWFRM
;-----------------------------------------------------------------------
DRWALL:
        push    ax                       ; 0DE8  AX comes back at 0E03
        mov     ax, OFFSET SCRMAP        ; 0DE9  AX -- address of the map
        push    ax                       ; 0DEC  argument: address of the map
        mov     ax, OFFSET TILES         ; 0DED  AX -- base of the tile table
        push    ax                       ; 0DF0  argument: base of the tile table
        mov     ax, 0                    ; 0DF1  AX=0 -- top row of the window
        push    ax                       ; 0DF4  argument: top row of the window -- zero
        mov     ax, 0                    ; 0DF5  AX=0 -- left column of the window
        push    ax                       ; 0DF8  argument: left column of the window -- zero
        mov     ax, MAP_H                ; 0DF9  AX -- rows of tiles
        push    ax                       ; 0DFC  argument: 19h = 25 tile rows
        mov     ax, MAP_W                ; 0DFD  AX -- tiles across
        push    ax                       ; 0E00  argument: 28h = 40 tiles across
        int     67h                      ; 0E01  OUR OWN API: put out the map
        pop     ax                       ; 0E03  word 1 of seven
        pop     ax                       ; 0E04  word 2 of seven
        pop     ax                       ; 0E05  word 3 of seven
        pop     ax                       ; 0E06  word 4 of seven
        pop     ax                       ; 0E07  word 5 of seven
        pop     ax                       ; 0E08  word 6 of seven
        pop     ax                       ; 0E09  all seven argument words pulled off the stack
        ret                              ; 0E0A  return: the whole screen has been redrawn

;-----------------------------------------------------------------------
; PUTOBJ3 -- Objects 30h and above. It writes nothing to SCRMAP.
;
; ENTRY  : CMDOP
; ALTERS : nothing
; CALLED BY: BLDMAP
;-----------------------------------------------------------------------
PUTOBJ3:
        SAVEALL                          ; 0E0B  macro
        call    OBJSEEN                  ; 0E12  has the object been collected
        jae     LPUTOB1                  ; 0E15  CF=0 -- the object is still in place
        jmp     LPUTOB8                  ; 0E17  collected -- do not bring the enemy in
LPUTOB1:
        cmp     MKOBJF, 0                ; 0E1A  are the objects to be created
        jne     LPUTOB2                  ; 0E1F  they are
        jmp     LPUTOB8                  ; 0E21  no -- do not bring the enemy in
LPUTOB2:
        call    DIRGET                   ; 0E24  SI -- a free object slot
        jae     LPUTOB3                  ; 0E27  CF=0 -- a slot was found
        jmp     LPUTOB8                  ; 0E29  no slots -- do not bring the enemy in
LPUTOB3:
        mov     bx, OFFSET OBJBIT        ; 0E2C  the "slot -> bit number within SEENMAP" table
        mov     al, ROOMOBN              ; 0E2F  AL -- sequence number of the object
        dec     al                       ; 0E32  OBJSEEN has already bumped the counter
        mov     [bx+si], al              ; 0E34  the slot remembers its own bit
        mov     bx, OFFSET ROOMOBJ       ; 0E36  table of the room objects' offsets
        xor     ah, ah                   ; 0E39  AH=0: the whole number now sits in AX
        mov     di, ax                   ; 0E3B  DI -- the object number
        shl     di, 1                    ; 0E3D  entries run two bytes apiece
        mov     WORD PTR [bx+di], 0      ; 0E3F  the enemy is not on the map: its offset is zero
        mov     di, ELMCUR               ; 0E43  DI -- offset of the element within the ribbon
        mov     bx, OFFSET ELMTAB        ; 0E47  BX -- head of the element ribbon
        mov     bx, [bx+di]              ; 0E4A  BX -- address of the enemy's frame chain
        shl     si, 1                    ; 0E4C  ANIMPTR slots run a word apiece
        mov     bp, OFFSET ANIMPTR       ; 0E4E  table of frame chains, one slot per object
        mov     ds:[bp+si], bx           ; 0E51  the slot has its frame chain
        shr     si, 1                    ; 0E54  SI is the slot number once again
        call    MKOBJ                    ; 0E56  enter the object into OBJTBL
        mov     al, CMDOP                ; 0E59  AL -- the opcode
        and     al, 7                    ; 0E5C  bits 2..0 of the opcode -- the enemy type
        mov     OBJTYP, al               ; 0E5E  OBJTYP -- type of the enemy at hand
        shl     al, 1                    ; 0E61  type times two
        shl     al, 1                    ; 0E63  type times four: room made for the subtype
        mov     bx, OFFSET OBJKND        ; 0E65  the "slot -> type and subtype" table
        mov     [bx+si], al              ; 0E68  the type is stored
        mov     al, CMDOP                ; 0E6A  AL -- the opcode
        rcl     al, 1                    ; 0E6D  shift 1 of three
        rcl     al, 1                    ; 0E6F  shift 2 of three
        rcl     al, 1                    ; 0E71  bits 7..5 of the opcode come around through the carry
        and     al, 3                    ; 0E73  the low two bits are the subtype
        or      [bx+si], al              ; 0E75  the subtype goes in beside the type
        xor     ah, ah                   ; 0E77  AH=0: the whole type now sits in AX
        mov     al, OBJTYP               ; 0E79  AL -- type of the enemy
        mov     di, ax                   ; 0E7C  DI -- the same type as an index
        shl     di, 1                    ; 0E7E  entries run two bytes apiece
        mov     bx, OFFSET OBJALN        ; 0E80  type -> last frame of the chain
        mov     ax, [bx+di]              ; 0E83  AX -- number of the last frame
        mov     bx, OFFSET ANIMLEN       ; 0E85  highest frame number, one slot per object
        shl     si, 1                    ; 0E88  ANIMLEN slots run a word apiece
        mov     [bx+si], ax              ; 0E8A  the slot remembers the length of its chain
        shr     si, 1                    ; 0E8C  SI is the slot number once again
        mov     bx, OFFSET OBJKND        ; 0E8E  the "slot -> type and subtype" table
        mov     al, [bx+si]              ; 0E91  AL -- type and subtype of the slot
        and     al, 3                    ; 0E93  the low two bits are the subtype
        xor     ah, ah                   ; 0E95  AH=0: the whole subtype now sits in AX
        mov     di, ax                   ; 0E97  DI -- the subtype as an index
        mov     bx, OFFSET VXTAB         ; 0E99  subtype -> starting speed along X
        mov     al, [bx+di]              ; 0E9C  AL -- the speed, signed
        mov     bx, OFFSET OBJVX         ; 0E9E  table of X speeds, one slot per object
        mov     [bx+si], al              ; 0EA1  the slot has its speed
        cmp     al, 0                    ; 0EA3  is the speed zero?
        jne     LPUTOB4                  ; 0EA5  no -- the enemy walks
        mov     bx, OFFSET ANIMLEN       ; 0EA7  highest frame number, one slot per object
        shl     si, 1                    ; 0EAA  ANIMLEN slots run a word apiece
        xor     ah, ah                   ; 0EAC  AH=0: chain length of zero
        mov     [bx+si], ax              ; 0EAE  a standing enemy: a chain of one frame
        shr     si, 1                    ; 0EB0  SI is the slot number once again
LPUTOB4:
        mov     bx, OFFSET OBJTMR2       ; 0EB2  table of the objects' second timers
        mov     BYTE PTR [bx+si], 0      ; 0EB5  the slot's timer is cleared
        mov     dl, CMDX                 ; 0EB8  DL -- low byte of the offset into the map
        mov     cl, 4                    ; 0EBC  shift by four places
        shr     dl, cl                   ; 0EBE  the high four bits are the row within the room
        cmp     OBJTYP, 1                ; 0EC0  type 1 -- the skull
        jne     LPUTOB5                  ; 0EC5  not the skull
        mov     bx, OFFSET OBJKND        ; 0EC7  the "slot -> type and subtype" table
        mov     al, [bx+si]              ; 0ECA  AL -- type and subtype of the slot
        and     al, 3                    ; 0ECC  the low two bits are the subtype
        je      LPUTOB7                  ; 0ECE  subtype 0 -- the jumping skull
        jne     LPUTOB6                  ; 0ED0  subtypes 1..3 -- the rolling skull
LPUTOB5:
        cmp     dl, 0Ah                  ; 0ED2  rows 0Ah and lower -- the upper half
        jl      LPUTOB7                  ; 0ED5  top of the room -- change nothing
        mov     bx, OFFSET OBJVX         ; 0ED7  table of X speeds, one slot per object
        neg     BYTE PTR [bx+si]         ; 0EDA  bottom of the room -- the enemy heads the other way
        cmp     OBJTYP, 2                ; 0EDC  type 2 -- the spider
        jne     LPUTOB7                  ; 0EE1  not the spider
LPUTOB6:
        mov     bx, OFFSET ELMTAB        ; 0EE3  BX -- head of the element ribbon
        mov     di, ELMCUR               ; 0EE6  DI -- offset of the element within the ribbon
        mov     ax, [bx+di+2]            ; 0EEA  third word of the element -- the second chain
        mov     bx, OFFSET ANIMPTR       ; 0EED  table of frame chains, one slot per object
        shl     si, 1                    ; 0EF0  ANIMPTR slots run a word apiece
        mov     [bx+si], ax              ; 0EF2  the slot has the second frame chain
        shr     si, 1                    ; 0EF4  SI is the slot number once again
LPUTOB7:
        call    OBJON                    ; 0EF6  switch the object on: set its bit
LPUTOB8:
        RESTALL                          ; 0EF9  macro
        mov     al, 2                    ; 0F00  AL=2 -- length of an object command
        ret                              ; 0F02  return: the command length is in AL

;-----------------------------------------------------------------------
; MKOBJ -- Create a room object: take the frame out of OBJFRM by the
; opcode's code and fill in OB_W, OB_H and OB_FRAME. This is the one
; place that reads a frame header.
;
; ENTRY  : SI, CMDOP
; EXIT   : OBJTBL
; ALTERS : nothing
; CALLED BY: PUTOBJ3
;-----------------------------------------------------------------------
MKOBJ:
        SAVEALL                          ; 0F03  macro
        mov     bp, OFFSET OBJTBL        ; 0F0A  BP -- head of the object table
        mov     ax, si                   ; 0F0D  AX -- the slot number
        mov     bl, 6                    ; 0F0F  OBJTBL records run six bytes apiece
        mul     bl                       ; 0F11  number * 6
        add     bp, ax                   ; 0F13  BP -- the slot's record
        mov     al, CMDOP                ; 0F15  AL -- the opcode
        and     al, 3Fh                  ; 0F18  the command code is the low six bits
        xor     ah, ah                   ; 0F1A  AH=0: the whole code now sits in AX
        sub     al, 30h                  ; 0F1C  object codes start at 30h
        mov     si, ax                   ; 0F1E  SI -- number of the object type
        mov     bx, OFFSET OBJDY         ; 0F20  type -> Y correction in scan lines
        mov     dl, [bx+si]              ; 0F23  DL -- the Y correction
        shl     si, 1                    ; 0F25  entries run two bytes apiece
        mov     bx, OFFSET OBJFRM        ; 0F27  type -> frame of the object
        mov     bx, [bx+si]              ; 0F2A  BX -- the frame header
        mov     al, [bx]                 ; 0F2C  first byte of the header -- the width
        mov     ds:[bp+OB_W], al         ; 0F2E  record field +4: width
        inc     bx                       ; 0F32  BX on to the second byte of the header
        mov     al, [bx]                 ; 0F33  second byte of the header -- the height
        mov     ds:[bp+OB_H], al         ; 0F35  record field +5: height
        inc     bx                       ; 0F39  BX -- the frame's dots, past the header
        mov     ds:[bp], bx              ; 0F3A  record field +0: pointer to the bitmap
        xor     ah, ah                   ; 0F3E  AH=0
        mov     bx, OFFSET OBJXTAB       ; 0F40  column -> X in bytes
        xor     ah, ah                   ; 0F43  AH=0: the whole column now sits in AX
        mov     al, CMDX                 ; 0F45  AL -- low byte of the offset into the map
        shr     ax, 1                    ; 0F48  shift 1 of four
        shr     ax, 1                    ; 0F4A  shift 2 of four
        shr     ax, 1                    ; 0F4C  shift 3 of four
        shr     ax, 1                    ; 0F4E  the high four bits are the column
        mov     si, ax                   ; 0F50  SI -- the same column as an index
        mov     cl, [bx+si]              ; 0F52  CL -- X in dots
        shr     cl, 1                    ; 0F54  halved: X in bytes of video RAM
        mov     ds:[bp+OB_X], cl         ; 0F56  record field +2: X
        xor     ch, ch                   ; 0F5A  CH=0: the whole X now sits in CX
        xor     ah, ah                   ; 0F5C  AH=0: the whole row now sits in AX
        mov     al, CMDX                 ; 0F5E  AL -- low byte of the offset into the map
        and     ax, 0Fh                  ; 0F61  the low four bits are the row
        mov     si, ax                   ; 0F64  SI -- the same row as an index
        mov     bx, OFFSET OBJYTAB       ; 0F66  row -> Y in scan lines
        mov     al, [bx+si]              ; 0F69  AL -- the Y
        add     al, dl                   ; 0F6B  plus the correction for this object type
        mov     ds:[bp+OB_Y], al         ; 0F6D  record field +3: Y
        RESTALL                          ; 0F71  macro
        ret                              ; 0F78  return: the object is created

;-----------------------------------------------------------------------
; PLRHOME -- Put the player at the room's starting point and keep it in
; SVX..SVLEN. Nothing refers to this routine.
;
; EXIT   : OBJTBL, SVX, SVY, SVST, SVANIM, SVIDX2, SVLEN
; ALTERS : nothing
;-----------------------------------------------------------------------
PLRHOME:
        SAVEALL                          ; 0F79  macro
        mov     bp, OFFSET OBJTBL        ; 0F80  BP -- the player's record: slot 0
        mov     bx, OFFSET FRAME_00      ; 0F83  the standing frame
        mov     ds:[bp], bx              ; 0F86  record field +0: pointer to the bitmap
        inc     BYTE PTR ds:[bp]         ; 0F8A  byte 1 of two: the frame header
        inc     BYTE PTR ds:[bp]         ; 0F8E  step over the frame header
        mov     BYTE PTR ds:[bp+OB_X], 23h  ; 0F92  X
        mov     SVX, 23h                 ; 0F97  and the same value in the saved point
        mov     BYTE PTR ds:[bp+OB_Y], 34h  ; 0F9C  Y
        mov     SVY, 34h                 ; 0FA1  and the same value in the saved point
        mov     al, [bx]                 ; 0FA6  width out of the frame header
        mov     ds:[bp+OB_W], al         ; 0FA8  record field +4: width
        mov     al, [bx+1]               ; 0FAC  the height
        mov     ds:[bp+OB_H], al         ; 0FAF  record field +5: height
        mov     SVST, 0                  ; 0FB3  player state 0
        mov     SVANIM, OFFSET ANIMTB    ; 0FB8  frame chain -- head of ANIMTB
        mov     SVIDX2, 0                ; 0FBE  no frames stepped through yet
        mov     SVLEN, 3                 ; 0FC4  three frames in the chain
        RESTALL                          ; 0FCA  macro
        ret                              ; 0FD1  return: the player is placed

;-----------------------------------------------------------------------
; DIRGET -- Find a free object slot: the highest clear bit of INBITS.
;
; EXIT   : AL
; ALTERS : SI
; CALLED BY: PUTOBJ3
;-----------------------------------------------------------------------
DIRGET:
        push    ax                       ; 0FD2  AX comes back at 0FE0
        mov     al, INBITS               ; 0FD3  AL -- one bit per live object
        mov     si, 7                    ; 0FD6  eight bits: count on down to zero
LDIRGE1:
        rcl     al, 1                    ; 0FD9  next bit out into the carry
        jae     LDIRGE2                  ; 0FDB  bit clear -- this is the one
        dec     si                       ; 0FDD  that bit is done
        jg      LDIRGE1                  ; 0FDE  bits not used up yet
LDIRGE2:
        pop     ax                       ; 0FE0  AX restored
        ret                              ; 0FE1  return: the bit number is in SI

;-----------------------------------------------------------------------
; OBJON -- Mark object SI live: set its bit in INBITS.
;
; ENTRY  : SI
; EXIT   : INBITS
; ALTERS : nothing
; CALLED BY: PUTOBJ3
;-----------------------------------------------------------------------
OBJON:
        SAVEREG <ax,si>                  ; 0FE2  macro
        inc     si                       ; 0FE4  one shift more than the slot number
        xor     al, al                   ; 0FE5  AL=0 -- an empty mask
        stc                              ; 0FE7  CF=1 -- and that becomes the slot's bit
LOBJON1:
        rcl     al, 1                    ; 0FE8  mask left, the carry into the low bit
        dec     si                       ; 0FEA  one shift done
        jg      LOBJON1                  ; 0FEB  the shifts are not used up
        or      INBITS, al               ; 0FED  the slot's bit is set in INBITS
        RESTREG <si,ax>                  ; 0FF1  macro
        ret                              ; 0FF3  return: the object is marked live

CSEG    ENDS
        END
