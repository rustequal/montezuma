        PAGE  60,132
        TITLE ANIMDAT -- WORKING TILES AND ANIMATION TABLES
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC ANIMTB
        PUBLIC AN_DIE
        PUBLIC AN_ENMYL
        PUBLIC AN_ENMYR
        PUBLIC AN_FALL
        PUBLIC AN_JMP2
        PUBLIC AN_JUMP
        PUBLIC AN_OBJ1
        PUBLIC AN_OBJ2
        PUBLIC AN_OBJ3
        PUBLIC AN_OBJ4
        PUBLIC AN_POSE1
        PUBLIC AN_POSE2
        PUBLIC AN_POSE5
        PUBLIC AN_STNDL
        PUBLIC AN_STNDR
        PUBLIC AN_WALK2
        PUBLIC BELTFRM
        PUBLIC BELTWRK
        PUBLIC BLK70AT
        PUBLIC BLK70BT
        PUBLIC BLK71TB
        PUBLIC PITFRM
        PUBLIC TIL71
        EXTRN  FRAME_00:NEAR
        EXTRN  FRAME_01:NEAR
        EXTRN  FRAME_02:NEAR
        EXTRN  FRAME_03:NEAR
        EXTRN  FRAME_04:NEAR
        EXTRN  FRAME_05:NEAR
        EXTRN  FRAME_06:NEAR
        EXTRN  FRAME_07:NEAR
        EXTRN  FRAME_08:NEAR
        EXTRN  FRAME_09:NEAR
        EXTRN  FRAME_0A:NEAR
        EXTRN  FRAME_0B:NEAR
        EXTRN  FRAME_0C:NEAR
        EXTRN  FRAME_0D:NEAR
        EXTRN  FRAME_0E:NEAR
        EXTRN  FRAME_0F:NEAR
        EXTRN  FRAME_10:NEAR
        EXTRN  FRAME_11:NEAR
        EXTRN  FRAME_12:NEAR
        EXTRN  FRAME_13:NEAR
        EXTRN  FRAME_14:NEAR
        EXTRN  FRAME_15:NEAR
        EXTRN  FRAME_16:NEAR
        EXTRN  FRAME_17:NEAR
        EXTRN  FRAME_18:NEAR
        EXTRN  FRAME_19:NEAR
        EXTRN  FRAME_1A:NEAR
        EXTRN  FRAME_1B:NEAR
        EXTRN  FRAME_1C:NEAR
        EXTRN  FRAME_1D:NEAR
        EXTRN  FRAME_1E:NEAR
        EXTRN  FRAME_1F:NEAR
        EXTRN  FRAME_20:NEAR
        EXTRN  FRAME_21:NEAR
        EXTRN  FRAME_22:NEAR
        EXTRN  FRAME_23:NEAR
        EXTRN  FRAME_24:NEAR
        EXTRN  TILE_00:NEAR

;=======================================================================
; ANIMDAT.ASM -- WORKING TILES AND ANIMATION TABLES
;
; Pictures of the tiles the game cycles through as it runs, the short
; tables that go with them, and ANIMTB -- the sprite frame chains. Data only, no code.
;=======================================================================

;-----------------------------------------------------------------------
; BELTWRK -- CONVEYOR BELT, FOUR PHASES  (38F0..3A6F, 384 bytes)
;
; Four sets of six tiles, 72h..77h. TILRST floods the master copy
; TILE_B7 in here, BELTANI writes the chosen set over the live tiles,
; and DARKEN blanks the lot of them together. Same format as TILES:
; 8 lines of 2 bytes, . background # green * red o brown.
; The copy differs from the TILE_B7 master in two bytes -- 3956 and
; 3958, tile 72h of phase 1.
;-----------------------------------------------------------------------
BELTWRK      LABEL BYTE    ; 38F0
BELT0:        ; 38F0  phase 0, tiles 72h..77h
              ; 38F0  tile 72h
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
              ; 3900  tile 73h
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
              ; 3910  tile 74h
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
              ; 3920  tile 75h
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
              ; 3930  tile 76h
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
              ; 3940  tile 77h
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo

BELT1:        ; 3950  phase 1, tiles 72h..77h
              ; 3950  tile 72h
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    0Ah,0AAh     ; ..******
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0Ah,0AAh     ; ..******
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
              ; 3960  tile 73h
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
              ; 3970  tile 74h
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0A0h    ; ******..
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
              ; 3980  tile 75h
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
              ; 3990  tile 76h
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
              ; 39A0  tile 77h
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..

BELT2:        ; 39B0  phase 2, tiles 72h..77h
              ; 39B0  tile 72h
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
              ; 39C0  tile 73h
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
              ; 39D0  tile 74h
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
              ; 39E0  tile 75h
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
              ; 39F0  tile 76h
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
              ; 3A00  tile 77h
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....

BELT3:        ; 3A10  phase 3, tiles 72h..77h
              ; 3A10  tile 72h
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
              ; 3A20  tile 73h
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
              ; 3A30  tile 74h
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
              ; 3A40  tile 75h
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    0Ah,0AAh     ; ..******
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0Ah,0AAh     ; ..******
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
              ; 3A50  tile 76h
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
              ; 3A60  tile 77h
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0A0h    ; ******..
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......

;-----------------------------------------------------------------------
; BELTFRM -- THE BELT'S FOUR PHASES  (3A70..3A77, 8 bytes)
;
; Index is BELTPH and 3.
;-----------------------------------------------------------------------
BELTFRM      LABEL WORD    ; 3A70
        DW    BELT0        ; 3A70
        DW    BELT1        ; 3A72
        DW    BELT2        ; 3A74
        DW    BELT3        ; 3A76

;-----------------------------------------------------------------------
; EIGHT PICTURES OF THE PIT  (3A78..3AF7, 128 bytes)
;
; Out of these PITANI puts together the six tiles 78h..7Dh, cycling
; through the pointer sets in PITFRM.
;-----------------------------------------------------------------------
PIT0:         ; 3A78
        DB    00h,80h      ; ....*...
        DB    00h,28h      ; .....**.
        DB    00h,2Ah      ; .....***
        DB    00h,2Ah      ; .....***
        DB    00h,0AAh     ; ....****
        DB    02h,0AAh     ; ...*****
        DB    2Ah,0AAh     ; .*******
        DB    0AAh,0AAh    ; ********
PIT1:         ; 3A88
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    08h,20h      ; ..*..*..
        DB    28h,0Ah      ; .**...**
        DB    2Ah,02h      ; .***...*
        DB    0AAh,0A2h    ; ******.*
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
PIT2:         ; 3A98
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,02h      ; .......*
        DB    80h,02h      ; *......*
        DB    0AAh,02h     ; ****...*
        DB    0AAh,82h     ; *****..*
        DB    0AAh,8Ah     ; *****.**
        DB    0AAh,0AAh    ; ********
PIT3:         ; 3AA8
        DB    00h,00h      ; ........
        DB    80h,00h      ; *.......
        DB    00h,00h      ; ........
        DB    80h,02h      ; *......*
        DB    0A0h,08h     ; **....*.
        DB    0A8h,28h     ; ***..**.
        DB    0A8h,0AAh    ; ***.****
        DB    0AAh,0AAh    ; ********
PIT4:         ; 3AB8
        DB    00h,00h      ; ........
        DB    00h,80h      ; ....*...
        DB    00h,28h      ; .....**.
        DB    00h,2Ah      ; .....***
        DB    00h,0AAh     ; ....****
        DB    02h,0AAh     ; ...*****
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
PIT5:         ; 3AC8
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    08h,00h      ; ..*.....
        DB    08h,00h      ; ..*.....
        DB    2Ah,00h      ; .***....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
PIT6:         ; 3AD8
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,02h      ; .......*
        DB    00h,08h      ; ......*.
        DB    08h,28h      ; ..*..**.
        DB    08h,0AAh     ; ..*.****
        DB    0Ah,0AAh     ; ..******
PIT7:         ; 3AE8
        DB    00h,00h      ; ........
        DB    80h,00h      ; *.......
        DB    00h,00h      ; ........
        DB    80h,00h      ; *.......
        DB    0A0h,00h     ; **......
        DB    0A8h,20h     ; ***..*..
        DB    0A8h,0A0h    ; ***.**..
        DB    0AAh,0A0h    ; ******..

;-----------------------------------------------------------------------
; PITFRM -- FOUR SETS OF PIT PICTURES  (3AF8..3B27, 48 bytes)
;
; A set is six pointers in a row, for tiles 78h..7Dh. The set number
; is PH70 and 3, stride 0Ch bytes.
;-----------------------------------------------------------------------
PITFRM       LABEL WORD    ; 3AF8
        DW    PIT0         ; 3AF8  set 0
        DW    PIT1         ; 3AFA
        DW    PIT2         ; 3AFC
        DW    PIT3         ; 3AFE
        DW    PIT4         ; 3B00
        DW    PIT5         ; 3B02
        DW    PIT2         ; 3B04  set 1
        DW    PIT1         ; 3B06
        DW    PIT3         ; 3B08
        DW    PIT0         ; 3B0A
        DW    PIT6         ; 3B0C
        DW    PIT7         ; 3B0E
        DW    PIT3         ; 3B10  set 2
        DW    PIT0         ; 3B12
        DW    PIT1         ; 3B14
        DW    PIT2         ; 3B16
        DW    PIT4         ; 3B18
        DW    PIT5         ; 3B1A
        DW    PIT0         ; 3B1C  set 3
        DW    PIT2         ; 3B1E
        DW    PIT3         ; 3B20
        DW    PIT1         ; 3B22
        DW    PIT6         ; 3B24
        DW    PIT7         ; 3B26

;-----------------------------------------------------------------------
; TIL71 -- PICTURE OF TILE 71h, LAID DOWN TWICE  (3B28..3B47, 32 bytes)
;
; BLNK71 takes the first 16 bytes from here. BLNK71C takes a window at
; offset 4*(PH71C and 3): the second copy is there to keep the window
; from running off the end, so the tile scrolls by two lines.
;-----------------------------------------------------------------------
TIL71        LABEL BYTE    ; 3B28
        DB    14h,14h      ; .##..##.
        DB    14h,14h      ; .##..##.
        DB    14h,14h      ; .##..##.
        DB    15h,54h      ; .######.
        DB    01h,40h      ; ...##...
        DB    01h,40h      ; ...##...
        DB    01h,40h      ; ...##...
        DB    15h,54h      ; .######.
              ; 3B38  the same tile once again
        DB    14h,14h      ; .##..##.
        DB    14h,14h      ; .##..##.
        DB    14h,14h      ; .##..##.
        DB    15h,54h      ; .######.
        DB    01h,40h      ; ...##...
        DB    01h,40h      ; ...##...
        DB    01h,40h      ; ...##...
        DB    15h,54h      ; .######.

;-----------------------------------------------------------------------
; BLK71TB -- TWO PHASES OF TILE 71h  (3B48..3B4B, 4 bytes)
;
; Index is PH71. The empty tile blanks the cell, TIL71 lights it up.
;-----------------------------------------------------------------------
BLK71TB      LABEL WORD    ; 3B48
        DW    TILE_00      ; 3B48
        DW    TIL71        ; 3B4A

;-----------------------------------------------------------------------
; TWO PICTURES OF TILE 70h  (3B4C..3B6B, 32 bytes)
;
; They differ by one line: the speckle moves up a line.
;-----------------------------------------------------------------------
TIL70A:       ; 3B4C
        DB    0FFh,0FFh    ; oooooooo
        DB    3Fh,3Fh      ; .ooo.ooo
        DB    0F3h,0F3h    ; oo.ooo.o
        DB    0FFh,0FFh    ; oooooooo
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TIL70B:       ; 3B5C
        DB    0FFh,0FFh    ; oooooooo
        DB    0F3h,0F3h    ; oo.ooo.o
        DB    3Fh,3Fh      ; .ooo.ooo
        DB    0FFh,0FFh    ; oooooooo
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........

;-----------------------------------------------------------------------
; PHASE TABLES FOR TILE 70h  (3B6C..3B73, 8 bytes)
;
; BLK70AT -- blinking: empty and speckled. BLK70BT -- cycling between
; the two speckle pictures. Each is indexed by its own phase, PH70A and PH70B.
;-----------------------------------------------------------------------
BLK70AT      LABEL WORD    ; 3B6C
        DW    TILE_00      ; 3B6C
        DW    TIL70A       ; 3B6E
BLK70BT      LABEL WORD    ; 3B70
        DW    TIL70A       ; 3B70
        DW    TIL70B       ; 3B72
        DB    12 DUP (0)   ; 3B74..3B7F

;-----------------------------------------------------------------------
; ANIMTB -- FRAME CHAINS  (3B80..3BDF, 96 bytes)
;
; A chain is a run of consecutive pointers to frames. An object's
; ANIMPTR points at the head of the chain, ANIMIDX at a position
; inside it, ANIMLEN at its last number. Only the heads that the code
; refers to carry a name.
;-----------------------------------------------------------------------
ANIMTB       LABEL WORD    ; 3B80  walking right, 4 frames
        DW    FRAME_00     ; 3B80
        DW    FRAME_01     ; 3B82
        DW    FRAME_00     ; 3B84
        DW    FRAME_02     ; 3B86
AN_WALK2     LABEL WORD    ; 3B88  walking left, 4 frames
        DW    FRAME_0A     ; 3B88
        DW    FRAME_0B     ; 3B8A
        DW    FRAME_0A     ; 3B8C
        DW    FRAME_0C     ; 3B8E
AN_STNDL     LABEL WORD    ; 3B90  standing, facing left, one frame
        DW    FRAME_0F     ; 3B90
AN_STNDR     LABEL WORD    ; 3B92  standing, facing right, one frame
        DW    FRAME_08     ; 3B92
AN_POSE2     LABEL WORD    ; 3B94  pose, one frame
        DW    FRAME_07     ; 3B94
AN_POSE1     LABEL WORD    ; 3B96  pose, one frame
        DW    FRAME_04     ; 3B96
        DW    FRAME_0E     ; 3B98
AN_POSE5     LABEL WORD    ; 3B9A  pose, one frame
        DW    FRAME_16     ; 3B9A
AN_DIE       LABEL WORD    ; 3B9C  death, 6 frames
        DW    FRAME_10     ; 3B9C
        DW    FRAME_11     ; 3B9E
        DW    FRAME_12     ; 3BA0
        DW    FRAME_13     ; 3BA2
        DW    FRAME_14     ; 3BA4
        DW    FRAME_15     ; 3BA6
AN_JUMP      LABEL WORD    ; 3BA8  jump and fall, 6 frames
        DW    FRAME_03     ; 3BA8
        DW    FRAME_0D     ; 3BAA
AN_JMP2      LABEL WORD    ; 3BAC  entry into the jump chain at the third frame
        DW    FRAME_05     ; 3BAC
        DW    FRAME_06     ; 3BAE
AN_FALL      LABEL WORD    ; 3BB0  falling: the last two frames of the jump
        DW    FRAME_09     ; 3BB0
AN_ENMYL     LABEL WORD    ; 3BB2  enemy walking left, 7 frames
        DW    FRAME_17     ; 3BB2
        DW    FRAME_1E     ; 3BB4
        DW    FRAME_1D     ; 3BB6
        DW    FRAME_1C     ; 3BB8
        DW    FRAME_1B     ; 3BBA
        DW    FRAME_1A     ; 3BBC
        DW    FRAME_19     ; 3BBE
        DW    FRAME_18     ; 3BC0
AN_ENMYR     LABEL WORD    ; 3BC2  enemy walking right, 8 frames
        DW    FRAME_17     ; 3BC2
        DW    FRAME_18     ; 3BC4
        DW    FRAME_19     ; 3BC6
        DW    FRAME_1A     ; 3BC8
        DW    FRAME_1B     ; 3BCA
        DW    FRAME_1C     ; 3BCC
        DW    FRAME_1D     ; 3BCE
        DW    FRAME_1E     ; 3BD0
AN_OBJ1      LABEL WORD    ; 3BD2  room object, 7 frames
        DW    FRAME_17     ; 3BD2
AN_OBJ2      LABEL WORD    ; 3BD4  room object, 6 frames
        DW    FRAME_21     ; 3BD4
        DW    FRAME_22     ; 3BD6
AN_OBJ3      LABEL WORD    ; 3BD8  room object, 4 frames
        DW    FRAME_23     ; 3BD8
        DW    FRAME_24     ; 3BDA
AN_OBJ4      LABEL WORD    ; 3BDC  room object, 2 frames
        DW    FRAME_1F     ; 3BDC
        DW    FRAME_20     ; 3BDE

CSEG    ENDS
        END
