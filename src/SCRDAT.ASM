        PAGE  60,132
        TITLE SCRDAT -- MAP VARIABLES, SCRMAP, TILES, ELEMENTS, STATUS PANEL
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        EXTRN  AN_ENMYL:WORD
        EXTRN  AN_ENMYR:WORD
        EXTRN  AN_OBJ1:WORD
        EXTRN  AN_OBJ2:WORD
        EXTRN  AN_OBJ3:WORD
        EXTRN  AN_OBJ4:WORD

        PUBLIC BARTIL
        PUBLIC CALLDEP
        PUBLIC CMDLEN
        PUBLIC CMDOP
        PUBLIC CMDP1
        PUBLIC CMDP2
        PUBLIC CMDX
        PUBLIC DIGELM
        PUBLIC ELMCUR
        PUBLIC ELMTAB
        PUBLIC ENDPTR
        PUBLIC FLOOR
        PUBLIC HUDMAP
        PUBLIC INBITS
        PUBLIC LEVEL
        PUBLIC LITMSK
        PUBLIC MIRDST
        PUBLIC MIRFLAG
        PUBLIC MIRSRC
        PUBLIC PATLEFT
        PUBLIC PATLEN
        PUBLIC RDPTR
        PUBLIC ROOMKND
        PUBLIC ROOMNO
        PUBLIC ROOMOBJ
        PUBLIC ROOMPOS
        PUBLIC ROOMRQ
        PUBLIC ROWBUF
        PUBLIC SCRMAP
        PUBLIC SEENMAP
        PUBLIC TILES
        PUBLIC TILE_00
        PUBLIC TILE_01
        PUBLIC TILE_03
        PUBLIC TILE_70
        PUBLIC TILE_71
        PUBLIC TILE_72
        PUBLIC TILE_78
        PUBLIC TILE_7E
        PUBLIC TILE_80
        PUBLIC TILE_B1
        PUBLIC TILE_B7

;=======================================================================
; SCRDAT.ASM -- MAP VARIABLES, SCRMAP, TILES, ELEMENTS, STATUS PANEL
;
; The room builder's working cells, ROWBUF, the SCRMAP screen map, the
; tile table, the mirror pairs, BARTIL, the ELMTAB element descriptions
; and the HUDMAP status panel template. Data only, no code.
;=======================================================================

;-----------------------------------------------------------------------
; WORKING BUFFERS OF THE MAP  (1090..15B4, 1317 bytes)
;
; 1090..11A4 -- working cells of the room builder (RDPTR, ENDPTR,
; CMDOP and the rest, see the EQUs above), 1174 ROOMOBJ and
; 1194  ROOMKND -- lists of the objects in the current room.
; 11A5  ROWBUF -- one map row held for mirroring, 40 bytes.
; 11CD  SCRMAP -- the 40x25 screen map. Zeros in the file: it is built
; as the game runs.
;-----------------------------------------------------------------------
; number of the current room, 0..98
ROOMNO  DB    00h          ; 1090
; difficulty level picked by the player, 1..3 (the F2 key)
LEVEL   DB    01h          ; 1091
; room asked for (the one being moved into)
ROOMRQ  DB    00h          ; 1092
RDPTR   DW    0            ; 1093  read pointer into the room description
; end of the description = start of the next room
ENDPTR  DW    0            ; 1095
; nesting depth of fragments
CALLDEP DB    00h          ; 1097
; the fragment goes in mirrored
MIRFLAG DB    00h          ; 1098
; opcode of the current description command
CMDOP   DB    00h          ; 1099
; offset within the map page
CMDX    DB    00h          ; 109A
; first parameter of the command
CMDP1   DB    00h          ; 109B
; second parameter of the command
CMDP2   DB    00h          ; 109C
ELMCUR  DW    0,0          ; 109D  element code for the current command
CMDLEN  LABEL WORD         ; 10A1  length of the byte-code command: FILLRC hands it back in AX
        DB    00h,00h,00h  ; 10A1  ...
; pattern tiles left before the repeat (primitive 7)
PATLEFT DB    00h          ; 10A4
PATLEN  DB    00h          ; 10A5  pattern length for primitive 7
; floor of the pyramid, 0..10, index into ROOMBAS
FLOOR   DB    00h          ; 10A6
; position of the room on its floor
ROOMPOS DB    00h          ; 10A7
; lighting mask: 0FFh lit, 0F0h dark
LITMSK  DB    00h          ; 10A8
; bit mask of the current direction
INBITS  DB    00h          ; 10A9
; what has been picked up and killed, 2 bytes (16 bits) per room
SEENMAP DW    101 DUP (0)  ; 10AA..1173
; offsets of this room's objects within SCRMAP, one word each
ROOMOBJ DW    16 DUP (0)   ; 1174..1193
; kind of each room object, one byte each, parallel to ROOMOBJ
ROOMKND DB    17 DUP (0)   ; 1194..11A4
; buffer for one map row, 40 bytes (used when mirroring)
ROWBUF  DB    40 DUP (0)   ; 11A5..11CC
; screen map 40x25 = 1000 bytes, zeros in the file
SCRMAP  DB    1000 DUP (0) ; 11CD..15B4

;-----------------------------------------------------------------------
; TILES -- THE TILE TABLE, 235 OF THEM AT 16 BYTES APIECE
;
; A tile is 8x8 pixels, 2 bits to a pixel: 8 lines of 2 bytes, lines in
; linear order. PUTMAP itself splits them into the CGA fields.
; Every tile is drawn out alongside: . background # green *
; red
; o brown. Codes 70h..7Fh are solid floor, the ones MKSOLD looks for.
;-----------------------------------------------------------------------
TILES        LABEL BYTE    ; 15B5
TILE_00:      ; 15B5  T_VOID -- empty, walk-through  [INLIST PASSTIL]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_01:      ; 15C5  T_FLOOR -- brick floor, stands on  [INLIST LANDTIL]
        DB    0AAh,0FAh    ; ****oo**
        DB    0AAh,0FAh    ; ****oo**
        DB    0AAh,0FAh    ; ****oo**
        DB    0FFh,0FFh    ; oooooooo
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0FFh,0FFh    ; oooooooo
TILE_02:      ; 15D5  T_FLOOR2 -- brick floor, second variant  [INLIST LANDTIL]
        DB    0AAh,0FAh    ; ****oo**
        DB    0AAh,0FAh    ; ****oo**
        DB    0FFh,0FFh    ; oooooooo
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0FFh,0FFh    ; oooooooo
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_03:      ; 15E5
        DB    55h,55h      ; ########
        DB    0FFh,0FFh    ; oooooooo
        DB    0AAh,0AAh    ; ********
        DB    55h,55h      ; ########
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_04:      ; 15F5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    55h,55h      ; ########
        DB    0AAh,0AAh    ; ********
        DB    0FFh,0FFh    ; oooooooo
        DB    55h,55h      ; ########
TILE_05:      ; 1605
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
TILE_06:      ; 1615  T_STEP -- ledge, stands on  [INLIST LANDTIL]
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_07:      ; 1625
        DB    0F0h,0FFh    ; oo..oooo
        DB    0Fh,0Fh      ; ..oo..oo
        DB    0F0h,0F0h    ; oo..oo..
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_08:      ; 1635
        DB    0FFh,0Fh     ; oooo..oo
        DB    0F0h,0F0h    ; oo..oo..
        DB    0Fh,0Fh      ; ..oo..oo
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_09:      ; 1645
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0AAh     ; ....****
        DB    05h,55h      ; ..######
        DB    0Ah,0AAh     ; ..******
TILE_0A:      ; 1655
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0AAh,00h     ; ****....
        DB    55h,50h      ; ######..
        DB    0AAh,0A0h    ; ******..
TILE_0B:      ; 1665
        DB    05h,55h      ; ..######
        DB    07h,77h      ; ..#o#o#o
        DB    0Dh,0DDh     ; ..o#o#o#
        DB    05h,55h      ; ..######
        DB    0Ah,0AAh     ; ..******
        DB    05h,55h      ; ..######
        DB    00h,0AAh     ; ....****
        DB    00h,00h      ; ........
TILE_0C:      ; 1675
        DB    55h,50h      ; ######..
        DB    77h,70h      ; #o#o#o..
        DB    0DDh,0D0h    ; o#o#o#..
        DB    55h,50h      ; ######..
        DB    0AAh,0A0h    ; ******..
        DB    55h,50h      ; ######..
        DB    0AAh,00h     ; ****....
        DB    00h,00h      ; ........
TILE_0D:      ; 1685
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_0E:      ; 1695  T_PASS -- walk-through  [INLIST PASSTIL]
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
TILE_0F:      ; 16A5  T_GATEG -- green doorway, anchor  [INLIST GATETIL]
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
TILE_10:      ; 16B5  T_GATEG1 -- green doorway, +1  [ELMTAB 4Fh]
        DB    00h,54h      ; ....###.
        DB    05h,54h      ; ..#####.
        DB    15h,54h      ; .######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
TILE_11:      ; 16C5  T_GATEG2 -- green doorway, +2  [ELMTAB 4Fh]
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    41h,41h      ; #..##..#
        DB    41h,41h      ; #..##..#
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    41h,41h      ; #..##..#
        DB    41h,41h      ; #..##..#
TILE_12:      ; 16D5  T_GATEG3 -- green doorway, +3  [ELMTAB 4Fh]
        DB    15h,00h      ; .###....
        DB    15h,50h      ; .#####..
        DB    15h,54h      ; .######.
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
TILE_13:      ; 16E5
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
TILE_14:      ; 16F5
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
TILE_15:      ; 1705
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
TILE_16:      ; 1715  T_GATER -- red doorway, anchor  [INLIST GATETIL]
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
TILE_17:      ; 1725
        DB    00h,0A8h     ; ....***.
        DB    0Ah,0A8h     ; ..*****.
        DB    2Ah,0A8h     ; .******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
TILE_18:      ; 1735
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    82h,82h      ; *..**..*
        DB    82h,82h      ; *..**..*
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    82h,82h      ; *..**..*
        DB    82h,82h      ; *..**..*
TILE_19:      ; 1745
        DB    2Ah,00h      ; .***....
        DB    2Ah,0A0h     ; .*****..
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
TILE_1A:      ; 1755
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
TILE_1B:      ; 1765
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
TILE_1C:      ; 1775
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
TILE_1D:      ; 1785  T_GATEB -- brown doorway, anchor  [INLIST GATETIL]
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
TILE_1E:      ; 1795
        DB    00h,0FCh     ; ....ooo.
        DB    0Fh,0FCh     ; ..ooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
TILE_1F:      ; 17A5
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0C3h,0C3h    ; o..oo..o
        DB    0C3h,0C3h    ; o..oo..o
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0C3h,0C3h    ; o..oo..o
        DB    0C3h,0C3h    ; o..oo..o
TILE_20:      ; 17B5
        DB    3Fh,00h      ; .ooo....
        DB    3Fh,0F0h     ; .ooooo..
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
TILE_21:      ; 17C5
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
TILE_22:      ; 17D5
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
TILE_23:      ; 17E5
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
TILE_24:      ; 17F5  T_SWRD0 -- sword, top right  [ELMTAB 37h]
        DB    00h,0Ch      ; ......o.
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_25:      ; 1805  T_SWRD1 -- sword, top left  [ELMTAB 37h]
        DB    00h,00h      ; ........
        DB    0C0h,00h     ; o.......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_26:      ; 1815  T_SWRD2 -- sword, bottom right  [ELMTAB 37h]
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Ah      ; ......**
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Ah      ; ......**
        DB    00h,0Ah      ; ......**
        DB    00h,0Ah      ; ......**
TILE_27:      ; 1825  T_SWRD3 -- sword, bottom left  [ELMTAB 37h]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0A0h,00h     ; **......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
TILE_28:      ; 1835  T_LADTL -- ladder, top left  [MIRROR 28/29]
        DB    5Ah,0FAh     ; ##**oo**
        DB    5Ah,0FAh     ; ##**oo**
        DB    5Ah,0FAh     ; ##**oo**
        DB    5Fh,0FFh     ; ##oooooo
        DB    5Ah,0AAh     ; ##******
        DB    55h,55h      ; ########
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
TILE_29:      ; 1845  T_LADTR -- ladder, top right  [MIRROR + LADDDN]
        DB    0AAh,0F5h    ; ****oo##
        DB    0AAh,0F5h    ; ****oo##
        DB    0AAh,0F5h    ; ****oo##
        DB    0FFh,0F5h    ; oooooo##
        DB    0FAh,0A5h    ; oo****##
        DB    55h,55h      ; ########
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
TILE_2A:      ; 1855  T_LADL -- ladder, left half  [MIRROR 2A/2B]
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    55h,55h      ; ########
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
TILE_2B:      ; 1865  T_LADR -- ladder, right half  [MIRROR + LADDER]
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    55h,55h      ; ########
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
TILE_2C:      ; 1875  T_AMUL0 -- amulet, top right  [ELMTAB 2Fh]
        DB    00h,00h      ; ........
        DB    00h,0Fh      ; ......oo
        DB    00h,55h      ; ....####
        DB    00h,0FFh     ; ....oooo
        DB    00h,55h      ; ....####
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_2D:      ; 1885  T_AMUL1 -- amulet, top left  [ELMTAB 2Fh]
        DB    00h,00h      ; ........
        DB    0F0h,00h     ; oo......
        DB    55h,00h      ; ####....
        DB    0FFh,00h     ; oooo....
        DB    55h,00h      ; ####....
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_2E:      ; 1895  T_AMUL2 -- amulet, bottom right  [ELMTAB 2Fh]
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,05h      ; ......##
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,00h      ; ........
TILE_2F:      ; 18A5  T_AMUL3 -- amulet, bottom left  [ELMTAB 2Fh]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    50h,00h      ; ##......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    00h,00h      ; ........
TILE_30:      ; 18B5  T_GEM0 -- gem, top right  [ELMTAB 2Bh]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    03h,0FFh     ; ...ooooo
        DB    0Ch,3Fh      ; ..o..ooo
        DB    0Fh,0C0h     ; ..ooo...
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,3Fh      ; ..oo.ooo
TILE_31:      ; 18C5  T_GEM1 -- gem, top left  [ELMTAB 2Bh]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0FFh,0C0h    ; ooooo...
        DB    0FCh,30h     ; ooo..o..
        DB    03h,0F0h     ; ...ooo..
        DB    0FCh,0F0h    ; ooo.oo..
        DB    0FCh,0F0h    ; ooo.oo..
        DB    0FCh,0F0h    ; ooo.oo..
TILE_32:      ; 18D5  T_GEM2 -- gem, bottom right  [ELMTAB 2Bh]
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,0C0h     ; ..ooo...
        DB    0Ch,3Fh      ; ..o..ooo
        DB    03h,0FFh     ; ...ooooo
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_33:      ; 18E5  T_GEM3 -- gem, bottom left  [ELMTAB 2Bh]
        DB    0FCh,0F0h    ; ooo.oo..
        DB    0FCh,0F0h    ; ooo.oo..
        DB    0FCh,0F0h    ; ooo.oo..
        DB    03h,0F0h     ; ...ooo..
        DB    0FCh,30h     ; ooo..o..
        DB    0FFh,0C0h    ; ooooo...
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_34:      ; 18F5  T_DEAD0 -- kills on a fall  [INLIST DEADTIL]
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0FFh,0AAh    ; oooo****
        DB    0AFh,0AAh    ; **oo****
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
TILE_35:      ; 1905  T_DEAD1 -- kills on a fall  [INLIST DEADTIL]
        DB    0FAh,0AAh    ; oo******
        DB    0FFh,0AAh    ; oooo****
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AFh,0AAh    ; **oo****
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0AAh    ; ********
TILE_36:      ; 1915
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
TILE_37:      ; 1925
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0FAh    ; ****oo**
        DB    0AFh,0FAh    ; **oooo**
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AFh,0AAh    ; **oo****
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
TILE_38:      ; 1935
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Ah      ; ......**
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0AAh     ; ..oo****
        DB    0Ah,00h      ; ..**....
TILE_39:      ; 1945
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    0AAh,00h     ; ****....
        DB    0FFh,0FFh    ; oooooooo
        DB    0AAh,0AAh    ; ********
        DB    00h,00h      ; ........
TILE_3A:      ; 1955  T_KEYG1 -- green key, top left  [ELMTAB 43h]
        DB    00h,00h      ; ........
        DB    00h,15h      ; .....###
        DB    01h,55h      ; ...#####
        DB    15h,40h      ; .####...
        DB    15h,40h      ; .####...
        DB    01h,55h      ; ...#####
        DB    00h,15h      ; .....###
        DB    00h,05h      ; ......##
TILE_3B:      ; 1965  T_KEYG0 -- green key, top right; USEITEM looks for this one  [ELMTAB 43h]
        DB    00h,00h      ; ........
        DB    54h,00h      ; ###.....
        DB    55h,40h      ; #####...
        DB    01h,54h      ; ...####.
        DB    01h,54h      ; ...####.
        DB    55h,40h      ; #####...
        DB    54h,00h      ; ###.....
        DB    50h,00h      ; ##......
TILE_3C:      ; 1975  T_KEYG3 -- green key, bottom left  [ELMTAB 43h]
        DB    00h,01h      ; .......#
        DB    00h,01h      ; .......#
        DB    00h,01h      ; .......#
        DB    00h,15h      ; .....###
        DB    00h,01h      ; .......#
        DB    00h,15h      ; .....###
        DB    00h,01h      ; .......#
        DB    00h,00h      ; ........
TILE_3D:      ; 1985  T_KEYG2 -- green key, bottom right  [ELMTAB 43h]
        DB    40h,00h      ; #.......
        DB    40h,00h      ; #.......
        DB    40h,00h      ; #.......
        DB    40h,00h      ; #.......
        DB    40h,00h      ; #.......
        DB    40h,00h      ; #.......
        DB    40h,00h      ; #.......
        DB    40h,00h      ; #.......
TILE_3E:      ; 1995  T_KEYR1 -- red key, top left  [ELMTAB 47h]
        DB    00h,00h      ; ........
        DB    00h,2Ah      ; .....***
        DB    02h,0AAh     ; ...*****
        DB    2Ah,80h      ; .****...
        DB    2Ah,80h      ; .****...
        DB    02h,0AAh     ; ...*****
        DB    00h,2Ah      ; .....***
        DB    00h,0Ah      ; ......**
TILE_3F:      ; 19A5  T_KEYR0 -- red key, top right; USEITEM looks for this one  [ELMTAB 47h]
        DB    00h,00h      ; ........
        DB    0A8h,00h     ; ***.....
        DB    0AAh,80h     ; *****...
        DB    02h,0A8h     ; ...****.
        DB    02h,0A8h     ; ...****.
        DB    0AAh,80h     ; *****...
        DB    0A8h,00h     ; ***.....
        DB    0A0h,00h     ; **......
TILE_40:      ; 19B5  T_KEYR3 -- red key, bottom left  [ELMTAB 47h]
        DB    00h,02h      ; .......*
        DB    00h,02h      ; .......*
        DB    00h,02h      ; .......*
        DB    00h,2Ah      ; .....***
        DB    00h,02h      ; .......*
        DB    00h,2Ah      ; .....***
        DB    00h,02h      ; .......*
        DB    00h,00h      ; ........
TILE_41:      ; 19C5  T_KEYR2 -- red key, bottom right  [ELMTAB 47h]
        DB    80h,00h      ; *.......
        DB    80h,00h      ; *.......
        DB    80h,00h      ; *.......
        DB    80h,00h      ; *.......
        DB    80h,00h      ; *.......
        DB    80h,00h      ; *.......
        DB    80h,00h      ; *.......
        DB    80h,00h      ; *.......
TILE_42:      ; 19D5  T_KEYB1 -- brown key, top left  [ELMTAB 4Bh]
        DB    00h,00h      ; ........
        DB    00h,3Fh      ; .....ooo
        DB    03h,0FFh     ; ...ooooo
        DB    3Fh,0C0h     ; .oooo...
        DB    3Fh,0C0h     ; .oooo...
        DB    03h,0FFh     ; ...ooooo
        DB    00h,3Fh      ; .....ooo
        DB    00h,0Fh      ; ......oo
TILE_43:      ; 19E5  T_KEYB0 -- brown key, top right; USEITEM looks for this one  [ELMTAB 4Bh]
        DB    00h,00h      ; ........
        DB    0FCh,00h     ; ooo.....
        DB    0FFh,0C0h    ; ooooo...
        DB    03h,0FCh     ; ...oooo.
        DB    03h,0FCh     ; ...oooo.
        DB    0FFh,0C0h    ; ooooo...
        DB    0FCh,00h     ; ooo.....
        DB    0F0h,00h     ; oo......
TILE_44:      ; 19F5  T_KEYB3 -- brown key, bottom left  [ELMTAB 4Bh]
        DB    00h,03h      ; .......o
        DB    00h,03h      ; .......o
        DB    00h,03h      ; .......o
        DB    00h,3Fh      ; .....ooo
        DB    00h,03h      ; .......o
        DB    00h,3Fh      ; .....ooo
        DB    00h,03h      ; .......o
        DB    00h,00h      ; ........
TILE_45:      ; 1A05  T_KEYB2 -- brown key, bottom right  [ELMTAB 4Bh]
        DB    0C0h,00h     ; o.......
        DB    0C0h,00h     ; o.......
        DB    0C0h,00h     ; o.......
        DB    0C0h,00h     ; o.......
        DB    0C0h,00h     ; o.......
        DB    0C0h,00h     ; o.......
        DB    0C0h,00h     ; o.......
        DB    0C0h,00h     ; o.......
TILE_46:      ; 1A15
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
TILE_47:      ; 1A25
        DB    0F0h,00h     ; oo......
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    0Fh,0F0h     ; ..oooo..
TILE_48:      ; 1A35
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0AAh     ; ....****
TILE_49:      ; 1A45
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0A0h,00h     ; **......
TILE_4A:      ; 1A55
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    00h,0FFh     ; ....oooo
        DB    00h,0FFh     ; ....oooo
TILE_4B:      ; 1A65
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_4C:      ; 1A75
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
TILE_4D:      ; 1A85
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
TILE_4E:      ; 1A95
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    00h,00h      ; ........
TILE_4F:      ; 1AA5
        DB    0F0h,00h     ; oo......
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    0FFh,0F0h    ; oooooo..
TILE_50:      ; 1AB5
        DB    00h,0Ah      ; ......**
        DB    00h,0AAh     ; ....****
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
TILE_51:      ; 1AC5
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0A0h,00h     ; **......
        DB    00h,00h      ; ........
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
TILE_52:      ; 1AD5
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,00h     ; oooo....
        DB    00h,00h      ; ........
        DB    00h,0Fh      ; ......oo
TILE_53:      ; 1AE5
        DB    0F0h,00h     ; oo......
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    0FFh,00h     ; oooo....
TILE_54:      ; 1AF5
        DB    00h,0Ah      ; ......**
        DB    00h,00h      ; ........
        DB    0AAh,00h     ; ****....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0AAh     ; ....****
TILE_55:      ; 1B05
        DB    0AAh,00h     ; ****....
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0A0h,00h     ; **......
TILE_56:      ; 1B15
        DB    00h,0Fh      ; ......oo
        DB    00h,0FFh     ; ....oooo
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,00h     ; oooo....
TILE_57:      ; 1B25
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
        DB    0FFh,00h     ; oooo....
TILE_58:      ; 1B35
        DB    0AAh,00h     ; ****....
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Ah      ; ......**
        DB    00h,0Ah      ; ......**
TILE_59:      ; 1B45
        DB    0AAh,00h     ; ****....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
TILE_5A:      ; 1B55
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0FFh    ; oooooooo
        DB    00h,0FFh     ; ....oooo
TILE_5B:      ; 1B65
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    00h,00h      ; ........
        DB    0F0h,00h     ; oo......
        DB    0FFh,00h     ; oooo....
TILE_5C:      ; 1B75
        DB    00h,00h      ; ........
        DB    0AAh,00h     ; ****....
        DB    0AAh,00h     ; ****....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0AAh     ; ....****
TILE_5D:      ; 1B85
        DB    0AAh,00h     ; ****....
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0A0h,00h     ; **......
TILE_5E:      ; 1B95
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
TILE_5F:      ; 1BA5
        DB    0F0h,00h     ; oo......
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    00h,00h      ; ........
        DB    0F0h,00h     ; oo......
        DB    0FFh,00h     ; oooo....
TILE_60:      ; 1BB5
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0AAh     ; ....****
TILE_61:      ; 1BC5
        DB    0AAh,0A0h    ; ******..
        DB    0Ah,0A0h     ; ..****..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0A0h,00h     ; **......
TILE_62:      ; 1BD5
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0Fh      ; ......oo
TILE_63:      ; 1BE5
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
TILE_64:      ; 1BF5
        DB    00h,0Ah      ; ......**
        DB    00h,0Ah      ; ......**
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
TILE_65:      ; 1C05
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0AAh,00h     ; ****....
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_66:      ; 1C15
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0Fh,0FFh     ; ..oooooo
TILE_67:      ; 1C25
        DB    0F0h,00h     ; oo......
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,00h     ; oooo....
TILE_68:      ; 1C35
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0AAh     ; ....****
TILE_69:      ; 1C45
        DB    0AAh,0A0h    ; ******..
        DB    0Ah,0A0h     ; ..****..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0A0h,00h     ; **......
TILE_6A:      ; 1C55
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0Fh,0FFh     ; ..oooooo
TILE_6B:      ; 1C65
        DB    0F0h,00h     ; oo......
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0F0h    ; oooooo..
TILE_6C:      ; 1C75
        DB    00h,0AAh     ; ....****
        DB    00h,00h      ; ........
        DB    0AAh,00h     ; ****....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0AAh     ; ....****
TILE_6D:      ; 1C85
        DB    0AAh,0A0h    ; ******..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,00h     ; ****....
        DB    0A0h,00h     ; **......
TILE_6E:      ; 1C95  T_TRCH2 -- torch, bottom right  [ELMTAB 3Fh]
        DB    05h,55h      ; ..######
        DB    01h,55h      ; ...#####
        DB    00h,15h      ; .....###
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,00h      ; ........
TILE_6F:      ; 1CA5  T_TRCH3 -- torch, bottom left  [ELMTAB 3Fh]
        DB    55h,50h      ; ######..
        DB    55h,40h      ; #####...
        DB    54h,00h      ; ###.....
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    00h,00h      ; ........
TILE_70:      ; 1CB5  T_SOLID -- solid floor with speckle  [ELMTAB 17h]
        DB    55h,55h      ; ########
        DB    15h,15h      ; .###.###
        DB    51h,51h      ; ##.###.#
        DB    55h,55h      ; ########
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_71:      ; 1CC5  T_SOLID2 -- solid floor, second variant  [ELMTAB 0Fh]
        DB    3Ch,3Ch      ; .oo..oo.
        DB    3Ch,3Ch      ; .oo..oo.
        DB    3Ch,3Ch      ; .oo..oo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    03h,0C0h     ; ...oo...
        DB    03h,0C0h     ; ...oo...
        DB    03h,0C0h     ; ...oo...
        DB    3Fh,0FCh     ; .oooooo.
TILE_72:      ; 1CD5  T_BELT0 -- conveyor belt; mirror pair with 77h  [MIRROR + BELTPUSH]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_73:      ; 1CE5  T_BELT1 -- conveyor belt; mirror pair with 76h  [MIRROR + BELTPUSH]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_74:      ; 1CF5  T_BELT2 -- conveyor belt; mirror pair with 75h  [MIRROR + BELTPUSH]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_75:      ; 1D05  T_BELT3 -- conveyor belt; mirror pair with 74h  [MIRROR + BELTPUSH]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_76:      ; 1D15  T_BELT4 -- conveyor belt; mirror pair with 73h  [MIRROR + BELTPUSH]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_77:      ; 1D25  T_BELT5 -- conveyor belt; mirror pair with 72h  [MIRROR + BELTPUSH]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_78:      ; 1D35  T_PIT0 -- pit, top right; kills  [ELMTAB 1Fh + DEADTIL]
        DB    00h,80h      ; ....*...
        DB    00h,28h      ; .....**.
        DB    00h,2Ah      ; .....***
        DB    00h,2Ah      ; .....***
        DB    00h,0AAh     ; ....****
        DB    02h,0AAh     ; ...*****
        DB    2Ah,0AAh     ; .*******
        DB    0AAh,0AAh    ; ********
TILE_79:      ; 1D45  T_PIT1 -- pit, top left; kills  [ELMTAB 1Fh + DEADTIL]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    08h,20h      ; ..*..*..
        DB    28h,0Ah      ; .**...**
        DB    2Ah,02h      ; .***...*
        DB    0AAh,0A2h    ; ******.*
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
TILE_7A:      ; 1D55  T_PIT2 -- pit, bottom right; kills  [ELMTAB 1Fh + DEADTIL]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,02h      ; .......*
        DB    80h,02h      ; *......*
        DB    0AAh,02h     ; ****...*
        DB    0AAh,82h     ; *****..*
        DB    0AAh,8Ah     ; *****.**
        DB    0AAh,0AAh    ; ********
TILE_7B:      ; 1D65  T_PIT3 -- pit, bottom left; kills  [ELMTAB 1Fh + DEADTIL]
        DB    00h,00h      ; ........
        DB    80h,00h      ; *.......
        DB    00h,00h      ; ........
        DB    80h,02h      ; *......*
        DB    0A0h,08h     ; **....*.
        DB    0A8h,28h     ; ***..**.
        DB    0A8h,0AAh    ; ***.****
        DB    0AAh,0AAh    ; ********
TILE_7C:      ; 1D75  T_TRCH0 -- torch, top right  [ELMTAB 3Fh]
        DB    00h,00h      ; ........
        DB    00h,80h      ; ....*...
        DB    00h,28h      ; .....**.
        DB    00h,2Ah      ; .....***
        DB    00h,0AAh     ; ....****
        DB    02h,0AAh     ; ...*****
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
TILE_7D:      ; 1D85  T_TRCH1 -- torch, top left  [ELMTAB 3Fh]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    08h,00h      ; ..*.....
        DB    08h,00h      ; ..*.....
        DB    2Ah,00h      ; .***....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
TILE_7E:      ; 1D95  T_REF01 -- master copy of tile 01h  [TILRST]
        DB    0AAh,0FAh    ; ****oo**
        DB    0AAh,0FAh    ; ****oo**
        DB    0AAh,0FAh    ; ****oo**
        DB    0FFh,0FFh    ; oooooooo
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0FFh,0FFh    ; oooooooo
TILE_7F:      ; 1DA5  T_REF02 -- master copy of tile 02h  [TILRST]
        DB    0AAh,0FAh    ; ****oo**
        DB    0AAh,0FAh    ; ****oo**
        DB    0FFh,0FFh    ; oooooooo
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0FFh,0FFh    ; oooooooo
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_80:      ; 1DB5  T_REF03 -- master copy of tile 03h  [TILRST]
        DB    55h,55h      ; ########
        DB    0FFh,0FFh    ; oooooooo
        DB    0AAh,0AAh    ; ********
        DB    55h,55h      ; ########
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_81:      ; 1DC5  T_REF04 -- master copy of tile 04h  [TILRST]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    55h,55h      ; ########
        DB    0AAh,0AAh    ; ********
        DB    0FFh,0FFh    ; oooooooo
        DB    55h,55h      ; ########
TILE_82:      ; 1DD5  T_REF05 -- master copy of tile 05h  [TILRST]
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
        DB    5Ah,0F5h     ; ##**oo##
TILE_83:      ; 1DE5  T_REF06 -- master copy of tile 06h  [TILRST]
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_84:      ; 1DF5  T_REF07 -- master copy of tile 07h  [TILRST]
        DB    0F0h,0FFh    ; oo..oooo
        DB    0Fh,0Fh      ; ..oo..oo
        DB    0F0h,0F0h    ; oo..oo..
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_85:      ; 1E05  T_REF08 -- master copy of tile 08h  [TILRST]
        DB    0FFh,0Fh     ; oooo..oo
        DB    0F0h,0F0h    ; oo..oo..
        DB    0Fh,0Fh      ; ..oo..oo
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_86:      ; 1E15  T_REF09 -- master copy of tile 09h  [TILRST]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0AAh     ; ....****
        DB    05h,55h      ; ..######
        DB    0Ah,0AAh     ; ..******
TILE_87:      ; 1E25  T_REF0A -- master copy of tile 0Ah  [TILRST]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0AAh,00h     ; ****....
        DB    55h,50h      ; ######..
        DB    0AAh,0A0h    ; ******..
TILE_88:      ; 1E35  T_REF0B -- master copy of tile 0Bh  [TILRST]
        DB    05h,55h      ; ..######
        DB    07h,77h      ; ..#o#o#o
        DB    0Dh,0DDh     ; ..o#o#o#
        DB    05h,55h      ; ..######
        DB    0Ah,0AAh     ; ..******
        DB    05h,55h      ; ..######
        DB    00h,0AAh     ; ....****
        DB    00h,00h      ; ........
TILE_89:      ; 1E45  T_REF0C -- master copy of tile 0Ch  [TILRST]
        DB    55h,50h      ; ######..
        DB    77h,70h      ; #o#o#o..
        DB    0DDh,0D0h    ; o#o#o#..
        DB    55h,50h      ; ######..
        DB    0AAh,0A0h    ; ******..
        DB    55h,50h      ; ######..
        DB    0AAh,00h     ; ****....
        DB    00h,00h      ; ........
TILE_8A:      ; 1E55  T_REF0D -- master copy of tile 0Dh  [TILRST]
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_8B:      ; 1E65  T_REF0E -- master copy of tile 0Eh  [TILRST]
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
TILE_8C:      ; 1E75  T_REF0F -- master copy of tile 0Fh  [TILRST]
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
        DB    15h,54h      ; .######.
TILE_8D:      ; 1E85  T_REF10 -- master copy of tile 10h  [TILRST]
        DB    00h,54h      ; ....###.
        DB    05h,54h      ; ..#####.
        DB    15h,54h      ; .######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
TILE_8E:      ; 1E95  T_REF11 -- master copy of tile 11h  [TILRST]
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    41h,41h      ; #..##..#
        DB    41h,41h      ; #..##..#
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    41h,41h      ; #..##..#
        DB    41h,41h      ; #..##..#
TILE_8F:      ; 1EA5  T_REF12 -- master copy of tile 12h  [TILRST]
        DB    15h,00h      ; .###....
        DB    15h,50h      ; .#####..
        DB    15h,54h      ; .######.
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
TILE_90:      ; 1EB5  T_REF13 -- master copy of tile 13h  [TILRST]
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
        DB    55h,54h      ; #######.
TILE_91:      ; 1EC5  T_REF14 -- master copy of tile 14h  [TILRST]
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
        DB    55h,55h      ; ########
TILE_92:      ; 1ED5  T_REF15 -- master copy of tile 15h  [TILRST]
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
        DB    15h,55h      ; .#######
TILE_93:      ; 1EE5  T_REF16 -- master copy of tile 16h  [TILRST]
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0A8h     ; .******.
TILE_94:      ; 1EF5  T_REF17 -- master copy of tile 17h  [TILRST]
        DB    00h,0A8h     ; ....***.
        DB    0Ah,0A8h     ; ..*****.
        DB    2Ah,0A8h     ; .******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
TILE_95:      ; 1F05  T_REF18 -- master copy of tile 18h  [TILRST]
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    82h,82h      ; *..**..*
        DB    82h,82h      ; *..**..*
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    82h,82h      ; *..**..*
        DB    82h,82h      ; *..**..*
TILE_96:      ; 1F15  T_REF19 -- master copy of tile 19h  [TILRST]
        DB    2Ah,00h      ; .***....
        DB    2Ah,0A0h     ; .*****..
        DB    2Ah,0A8h     ; .******.
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
TILE_97:      ; 1F25  T_REF1A -- master copy of tile 1Ah  [TILRST]
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
        DB    0AAh,0A8h    ; *******.
TILE_98:      ; 1F35  T_REF1B -- master copy of tile 1Bh  [TILRST]
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
TILE_99:      ; 1F45  T_REF1C -- master copy of tile 1Ch  [TILRST]
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
        DB    2Ah,0AAh     ; .*******
TILE_9A:      ; 1F55  T_REF1D -- master copy of tile 1Dh  [TILRST]
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FCh     ; .oooooo.
TILE_9B:      ; 1F65  T_REF1E -- master copy of tile 1Eh  [TILRST]
        DB    00h,0FCh     ; ....ooo.
        DB    0Fh,0FCh     ; ..ooooo.
        DB    3Fh,0FCh     ; .oooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
TILE_9C:      ; 1F75  T_REF1F -- master copy of tile 1Fh  [TILRST]
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0C3h,0C3h    ; o..oo..o
        DB    0C3h,0C3h    ; o..oo..o
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0C3h,0C3h    ; o..oo..o
        DB    0C3h,0C3h    ; o..oo..o
TILE_9D:      ; 1F85  T_REF20 -- master copy of tile 20h  [TILRST]
        DB    3Fh,00h      ; .ooo....
        DB    3Fh,0F0h     ; .ooooo..
        DB    3Fh,0FCh     ; .oooooo.
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
TILE_9E:      ; 1F95  T_REF21 -- master copy of tile 21h  [TILRST]
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FCh    ; ooooooo.
TILE_9F:      ; 1FA5  T_REF22 -- master copy of tile 22h  [TILRST]
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
TILE_A0:      ; 1FB5  T_REF23 -- master copy of tile 23h  [TILRST]
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
        DB    3Fh,0FFh     ; .ooooooo
TILE_A1:      ; 1FC5  T_REF24 -- master copy of tile 24h  [TILRST]
        DB    00h,0Ch      ; ......o.
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_A2:      ; 1FD5  T_REF25 -- master copy of tile 25h  [TILRST]
        DB    00h,00h      ; ........
        DB    0C0h,00h     ; o.......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_A3:      ; 1FE5  T_REF26 -- master copy of tile 26h  [TILRST]
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Ah      ; ......**
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Ah      ; ......**
        DB    00h,0Ah      ; ......**
        DB    00h,0Ah      ; ......**
TILE_A4:      ; 1FF5  T_REF27 -- master copy of tile 27h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0A0h,00h     ; **......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
        DB    0A0h,00h     ; **......
TILE_A5:      ; 2005  T_REF28 -- master copy of tile 28h  [TILRST]
        DB    5Ah,0FAh     ; ##**oo**
        DB    5Ah,0FAh     ; ##**oo**
        DB    5Ah,0FAh     ; ##**oo**
        DB    5Fh,0FFh     ; ##oooooo
        DB    5Ah,0AAh     ; ##******
        DB    55h,55h      ; ########
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
TILE_A6:      ; 2015  T_REF29 -- master copy of tile 29h  [TILRST]
        DB    0AAh,0F5h    ; ****oo##
        DB    0AAh,0F5h    ; ****oo##
        DB    0AAh,0F5h    ; ****oo##
        DB    0FFh,0F5h    ; oooooo##
        DB    0FAh,0A5h    ; oo****##
        DB    55h,55h      ; ########
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
TILE_A7:      ; 2025  T_REF2A -- master copy of tile 2Ah  [TILRST]
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    55h,55h      ; ########
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
        DB    50h,00h      ; ##......
TILE_A8:      ; 2035  T_REF2B -- master copy of tile 2Bh  [TILRST]
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    55h,55h      ; ########
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
        DB    00h,05h      ; ......##
TILE_A9:      ; 2045  T_REF2C -- master copy of tile 2Ch  [TILRST]
        DB    00h,00h      ; ........
        DB    00h,0Fh      ; ......oo
        DB    00h,55h      ; ....####
        DB    00h,0FFh     ; ....oooo
        DB    00h,55h      ; ....####
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_AA:      ; 2055  T_REF2D -- master copy of tile 2Dh  [TILRST]
        DB    00h,00h      ; ........
        DB    0F0h,00h     ; oo......
        DB    55h,00h      ; ####....
        DB    0FFh,00h     ; oooo....
        DB    55h,00h      ; ####....
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_AB:      ; 2065  T_REF2E -- master copy of tile 2Eh  [TILRST]
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,05h      ; ......##
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    00h,00h      ; ........
TILE_AC:      ; 2075  T_REF2F -- master copy of tile 2Fh  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    50h,00h      ; ##......
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    00h,00h      ; ........
TILE_AD:      ; 2085  T_REF30 -- master copy of tile 30h  [TILRST]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    03h,0FFh     ; ...ooooo
        DB    0Ch,3Fh      ; ..o..ooo
        DB    0Fh,0C0h     ; ..ooo...
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,3Fh      ; ..oo.ooo
TILE_AE:      ; 2095  T_REF31 -- master copy of tile 31h  [TILRST]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0FFh,0C0h    ; ooooo...
        DB    0FCh,30h     ; ooo..o..
        DB    03h,0F0h     ; ...ooo..
        DB    0FCh,0F0h    ; ooo.oo..
        DB    0FCh,0F0h    ; ooo.oo..
        DB    0FCh,0F0h    ; ooo.oo..
TILE_AF:      ; 20A5  T_REF32 -- master copy of tile 32h  [TILRST]
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,3Fh      ; ..oo.ooo
        DB    0Fh,0C0h     ; ..ooo...
        DB    0Ch,3Fh      ; ..o..ooo
        DB    03h,0FFh     ; ...ooooo
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_B0:      ; 20B5  T_REF33 -- master copy of tile 33h  [TILRST]
        DB    0FCh,0F0h    ; ooo.oo..
        DB    0FCh,0F0h    ; ooo.oo..
        DB    0FCh,0F0h    ; ooo.oo..
        DB    03h,0F0h     ; ...ooo..
        DB    0FCh,30h     ; ooo..o..
        DB    0FFh,0C0h    ; ooooo...
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_B1:      ; 20C5  T_REF72 -- master copy of tile 72h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_B2:      ; 20D5  T_REF73 -- master copy of tile 73h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_B3:      ; 20E5  T_REF74 -- master copy of tile 74h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_B4:      ; 20F5  T_REF75 -- master copy of tile 75h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_B5:      ; 2105  T_REF76 -- master copy of tile 76h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_B6:      ; 2115  T_REF77 -- master copy of tile 77h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_B7:      ; 2125  T_WRK00 -- BELT0 master, tile 72h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_B8:      ; 2135  T_WRK01 -- BELT0 master, tile 73h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_B9:      ; 2145  T_WRK02 -- BELT0 master, tile 74h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_BA:      ; 2155  T_WRK03 -- BELT0 master, tile 75h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_BB:      ; 2165  T_WRK04 -- BELT0 master, tile 76h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_BC:      ; 2175  T_WRK05 -- BELT0 master, tile 77h  [TILRST]
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
TILE_BD:      ; 2185  T_WRK06 -- BELT1 master, tile 72h  [TILRST]
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_BE:      ; 2195  T_WRK07 -- BELT1 master, tile 73h  [TILRST]
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_BF:      ; 21A5  T_WRK08 -- BELT1 master, tile 74h  [TILRST]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0A0h    ; ******..
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_C0:      ; 21B5  T_WRK09 -- BELT1 master, tile 75h  [TILRST]
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_C1:      ; 21C5  T_WRK0A -- BELT1 master, tile 76h  [TILRST]
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_C2:      ; 21D5  T_WRK0B -- BELT1 master, tile 77h  [TILRST]
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_C3:      ; 21E5  T_WRK0C -- BELT2 master, tile 72h  [TILRST]
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_C4:      ; 21F5  T_WRK0D -- BELT2 master, tile 73h  [TILRST]
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
TILE_C5:      ; 2205  T_WRK0E -- BELT2 master, tile 74h  [TILRST]
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
TILE_C6:      ; 2215  T_WRK0F -- BELT2 master, tile 75h  [TILRST]
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_C7:      ; 2225  T_WRK10 -- BELT2 master, tile 76h  [TILRST]
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
TILE_C8:      ; 2235  T_WRK11 -- BELT2 master, tile 77h  [TILRST]
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
TILE_C9:      ; 2245  T_WRK12 -- BELT3 master, tile 72h  [TILRST]
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0Ah,0AAh     ; ..******
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_CA:      ; 2255  T_WRK13 -- BELT3 master, tile 73h  [TILRST]
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_CB:      ; 2265  T_WRK14 -- BELT3 master, tile 74h  [TILRST]
        DB    0Fh,00h      ; ..oo....
        DB    0Fh,00h      ; ..oo....
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    00h,0F0h     ; ....oo..
        DB    00h,0F0h     ; ....oo..
TILE_CC:      ; 2275  T_WRK15 -- BELT3 master, tile 75h  [TILRST]
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    0Ah,0AAh     ; ..******
        DB    0FAh,0AAh    ; oo******
        DB    0FAh,0AAh    ; oo******
        DB    0Ah,0AAh     ; ..******
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_CD:      ; 2285  T_WRK16 -- BELT3 master, tile 76h  [TILRST]
        DB    00h,0Fh      ; ......oo
        DB    00h,0Fh      ; ......oo
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_CE:      ; 2295  T_WRK17 -- BELT3 master, tile 77h  [TILRST]
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0AFh    ; ******oo
        DB    0AAh,0A0h    ; ******..
        DB    0F0h,00h     ; oo......
        DB    0F0h,00h     ; oo......
TILE_CF:      ; 22A5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0FFh     ; ....oooo
        DB    03h,0FFh     ; ...ooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FCh     ; ..ooooo.
        DB    0Fh,0F0h     ; ..oooo..
TILE_D0:      ; 22B5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    00h,0FFh     ; ....oooo
        DB    00h,0Fh      ; ......oo
        DB    00h,00h      ; ........
TILE_D1:      ; 22C5
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0AAh     ; ..******
        DB    02h,0AAh     ; ...*****
        DB    00h,0AAh     ; ....****
TILE_D2:      ; 22D5
        DB    00h,00h      ; ........
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0A0h,2Ah     ; **...***
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
TILE_D3:      ; 22E5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0Fh      ; ......oo
        DB    00h,3Fh      ; .....ooo
        DB    00h,0FFh     ; ....oooo
        DB    03h,0FFh     ; ...ooooo
        DB    0Fh,0FCh     ; ..ooooo.
        DB    0Fh,0FFh     ; ..oooooo
TILE_D4:      ; 22F5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0FFh,00h     ; oooo....
        DB    0FFh,0C0h    ; ooooo...
        DB    0FFh,0F0h    ; oooooo..
        DB    03h,0FCh     ; ...oooo.
        DB    00h,0FFh     ; ....oooo
        DB    03h,0FFh     ; ...ooooo
TILE_D5:      ; 2305
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0A8h     ; ..*****.
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
TILE_D6:      ; 2315
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    02h,0AAh     ; ...*****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
TILE_D7:      ; 2325
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    03h,0F0h     ; ...ooo..
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
TILE_D8:      ; 2335
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0FCh     ; ....ooo.
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
TILE_D9:      ; 2345
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
TILE_DA:      ; 2355
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0A0h,0AAh    ; **..****
        DB    0A0h,0AAh    ; **..****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
TILE_DB:      ; 2365
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0FFh     ; ....oooo
        DB    03h,0FFh     ; ...ooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
TILE_DC:      ; 2375
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0FFh,0FCh    ; ooooooo.
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0C0h,0Fh     ; o.....oo
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
TILE_DD:      ; 2385
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    02h,0AAh     ; ...*****
        DB    00h,0AAh     ; ....****
TILE_DE:      ; 2395
        DB    0AAh,00h     ; ****....
        DB    0AAh,00h     ; ****....
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    80h,0Ah      ; *.....**
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A8h    ; *******.
TILE_DF:      ; 23A5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0Fh      ; ......oo
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    0Fh,0F0h     ; ..oooo..
TILE_E0:      ; 23B5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0FCh,00h     ; ooo.....
        DB    0FFh,0F0h    ; oooooo..
        DB    0FFh,0FFh    ; oooooooo
        DB    0FFh,0FFh    ; oooooooo
        DB    0Fh,0FFh     ; ..oooooo
        DB    00h,0FFh     ; ....oooo
TILE_E1:      ; 23C5
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    0Ah,0AAh     ; ..******
        DB    00h,0AAh     ; ....****
        DB    00h,00h      ; ........
TILE_E2:      ; 23D5
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    0Ah,0AAh     ; ..******
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0AAh    ; ********
        DB    0AAh,0A0h    ; ******..
        DB    0A0h,00h     ; **......
TILE_E3:      ; 23E5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0Fh,0C0h     ; ..ooo...
        DB    0Fh,0F0h     ; ..oooo..
        DB    0Fh,0F0h     ; ..oooo..
        DB    03h,0FCh     ; ...oooo.
        DB    00h,0FFh     ; ....oooo
        DB    00h,0FFh     ; ....oooo
TILE_E4:      ; 23F5
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,3Fh      ; .....ooo
        DB    00h,0FFh     ; ....oooo
        DB    00h,0FFh     ; ....oooo
        DB    03h,0FCh     ; ...oooo.
        DB    0Fh,0F0h     ; ..oooo..
        DB    0Fh,0F0h     ; ..oooo..
TILE_E5:      ; 2405
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,0AAh     ; ....****
        DB    00h,2Ah      ; .....***
        DB    00h,0Ah      ; ......**
        DB    00h,0Ah      ; ......**
        DB    00h,0Ah      ; ......**
        DB    00h,02h      ; .......*
TILE_E6:      ; 2415
        DB    0Ah,0A0h     ; ..****..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,0A0h    ; ******..
        DB    0AAh,80h     ; *****...
        DB    0AAh,00h     ; ****....
        DB    0AAh,00h     ; ****....
        DB    0A8h,00h     ; ***.....
        DB    0A8h,00h     ; ***.....
TILE_E7:      ; 2425
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    00h,0Fh      ; ......oo
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FCh     ; ..ooooo.
        DB    0Fh,0F0h     ; ..oooo..
        DB    0Fh,0FCh     ; ..ooooo.
        DB    0Fh,0FFh     ; ..oooooo
TILE_E8:      ; 2435
        DB    00h,00h      ; ........
        DB    00h,00h      ; ........
        DB    0FFh,0C0h    ; ooooo...
        DB    0FFh,0FCh    ; ooooooo.
        DB    0Fh,0FFh     ; ..oooooo
        DB    00h,0FFh     ; ....oooo
        DB    0Fh,0FCh     ; ..ooooo.
        DB    0FFh,0C0h    ; ooooo...
TILE_E9:      ; 2445
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
        DB    0Ah,0A0h     ; ..****..
TILE_EA:      ; 2455
        DB    0A0h,00h     ; **......
        DB    0A8h,00h     ; ***.....
        DB    0AAh,00h     ; ****....
        DB    0AAh,80h     ; *****...
        DB    2Ah,0A0h     ; .*****..
        DB    0Ah,0A8h     ; ..*****.
        DB    02h,0AAh     ; ...*****
        DB    00h,0AAh     ; ....****

;-----------------------------------------------------------------------
; MIRSRC / MIRDST -- MIRROR PAIRS OF TILES
;
; MIRROR flips a room left to right; tiles that come in a left-hand and
; a right-hand variant have to be swapped over while it does.
; The pairs: 28/29, 2A/2B, 72/77, 73/76, 74/75.
;-----------------------------------------------------------------------
MIRSRC       LABEL BYTE    ; 2465
        DB    28h,29h,2Ah,2Bh,72h,73h,74h,75h,76h,77h
MIRDST       LABEL BYTE    ; 246F
        DB    29h,28h,2Bh,2Ah,77h,76h,75h,74h,73h,72h

;-----------------------------------------------------------------------
; BARTIL -- THE "GAME OVER" SIGN BUILT OUT OF TILES  (2479..249C, 36 bytes)
;
; Nine character cells, each two tiles wide and two tiles tall:
; G A M E, blank, O V E R. The fifth pair is all zeros -- that is the
; blank; the eighth repeats the fourth, because the letter E is one and
; the same (DBh DCh / DDh DEh).
; A row takes 12h (18) bytes, the two of them 24h (36), exactly this block.
; PUTBAR lays them into SCRMAP+1EBh, that is, map rows 12 and 13 starting
; at column 11; the ADD DI,16h between the rows carries the pointer out
; to the width of the map: 12h + 16h = 28h.
;-----------------------------------------------------------------------
BARTIL  DB    0CFh,0D0h,0D3h,0D4h,0D7h,0D8h,0DBh,0DCh,00h,00h,0DFh,0E0h,0E3h,0E4h,0DBh,0DCh,0E7h,0E8h ; 2479 top
        DB    0D1h,0D2h,0D5h,0D6h,0D9h,0DAh,0DDh,0DEh,00h,00h,0E1h,0E2h,0E5h,0E6h,0DDh,0DEh,0E9h,0EAh ; 248B bottom

;-----------------------------------------------------------------------
; ELMTAB -- DESCRIPTIONS OF THE 2x2 ELEMENTS
;
; This is not an array of records but ONE SOLID RIBBON of bytes: an
; element code is an arbitrary offset into it, and how many bytes to
; read from there is up to whoever is reading:
;    ELMTILE            1 byte    tile for primitives 0..7
;    PR_COL             2 bytes   tile, and what to carry on with below
;    PUT2X2, ELMFIND    4 bytes   the 2x2 square
;    PUTROPE + PUTGRID  7 bytes   doorway: shut and swung open
;    PUTOBJ3            2 words   pointers into ANIMTB for an enemy
; So the records OVERLAP: codes 00h, 01h, 03h share bytes, and so do
; 64h, 65h, 66h or 6Ah, 6Ch, 6Eh. The stride of 4 holds only over the
; stretch 03h..4Bh, where the 2x2 squares live.
; How a square sits on the screen (the anchor is the top right tile):
;       +1  +0
;       +3  +2
; ELMFIND matches the tile under the player against all four and works
; the anchor offset out from which one hit: +0, +1, -28h, -27h.
;-----------------------------------------------------------------------
ELMTAB       LABEL BYTE            ; 249D
ELM_00   DB    00h,01h,00h         ; 249D  codes 00h and 01h: the single tiles 00h and 01h
ELM_03   DB    02h,2Ah,2Bh,02h     ; 24A0  tiles 2A 02 / 02 2B  -- ladder against brick
ELM_07   DB    28h,29h,01h,0Dh     ; 24A4  tiles 29 28 / 0D 01  -- top of a ladder
ELM_0B   DB    01h,06h,01h,0Eh     ; 24A8  tiles 06 01 / 0E 01  -- ledge
ELM_0F   DB    01h,71h,74h,73h     ; 24AC  tiles 71 01 / 73 74  -- conveyor, left half
ELM_13   DB    72h,77h,76h,75h     ; 24B0  tiles 77 72 / 75 76  -- conveyor, right half
ELM_17   DB    01h,70h,01h,70h     ; 24B4  tiles 70 01 / 70 01  -- solid floor
ELM_1B   DB    02h,02h,01h,04h     ; 24B8  tiles 02 02 / 04 01  -- brick
ELM_1F   DB    78h,79h,7Ah,7Bh     ; 24BC  tiles 79 78 / 7B 7A  -- pit: the fall kills
ELM_23   DB    05h,34h,35h,35h     ; 24C0  tiles 34 05 / 35 35  -- deadly floor
ELM_27   DB    34h,35h,01h,02h     ; 24C4  tiles 35 34 / 02 01  -- deadly floor, variant
ELM_2B   DB    31h,30h,33h,32h     ; 24C8  tiles 30 31 / 32 33  -- gem
; tiles 2C 2D / 2E 2F -- amulet: 37h ticks of invulnerability
ELM_2F   DB    2Dh,2Ch,2Fh,2Eh     ; 24CC
; tiles A9 AA / AB AC -- amulet, master tiles -- the way it looks in the inventory
ELM_33   DB    0AAh,0A9h,0ACh,0ABh ; 24D0
ELM_37   DB    25h,24h,27h,26h     ; 24D4  tiles 24 25 / 26 27  -- sword: cuts down an enemy
; tiles A1 A2 / A3 A4 -- sword, master tiles -- the way it looks in the inventory
ELM_3B   DB    0A2h,0A1h,0A4h,0A3h ; 24D8
; tiles 7C 7D / 6E 6F -- torch: lights up dark rooms
ELM_3F   DB    7Dh,7Ch,6Fh,6Eh     ; 24DC
ELM_43   DB    3Bh,3Ah,3Dh,3Ch     ; 24E0  tiles 3A 3B / 3C 3D  -- green key
ELM_47   DB    3Fh,3Eh,41h,40h     ; 24E4  tiles 3E 3F / 40 41  -- red key
ELM_4B   DB    43h,42h,45h,44h     ; 24E8  tiles 42 43 / 44 45  -- brown key

;-----------------------------------------------------------------------
; ELMTAB, CONTINUED  (24EC..253D)
;
; Past here the stride of 4 runs out and the ribbon carries records of
; other lengths.
; DOORWAYS, 7 bytes each: +0 -- tile of the shut door, which PUTROPE
; lays down as a column four cells deep; +1..+6 -- the doorway swung
; open, 3 wide and 4 tall, which PUTGRID lays out reading the bytes
; right to left (top row +3 +2 +1, the three lower ones +6 +5 +4).
; ROPES 64h and 65h are single tiles, 66h laid over them is a square.
; ENEMIES 6Ah, 6Ch, 6Eh, 72h are not tiles at all but pairs of WORDS:
; pointers into ANIMTB. PUTOBJ3 takes the word at the code into ANIMPTR
; and hands the word at code+2 to whoever walks the other way. Again the
; records overlap: six chain heads for four kinds of object.
; ICONS 79h..9Dh are ten 2x2 squares with a stride of 4 for the panel;
; DIGELM points at them.
ELM_4F  DB    0Fh,12h,11h,10h,15h,14h,13h  ; 24EC  green doorway: 0F shut, 10..15 swung open
ELM_56  DB    16h,19h,18h,17h,1Ch,1Bh,1Ah  ; 24F3  red doorway: 16 shut, 17..1C swung open
ELM_5D  DB    1Dh,20h,1Fh,1Eh,23h,22h,21h  ; 24FA  brown doorway: 1D shut, 1E..23 swung open
ELM_64  DB    07h,08h                      ; 2501  codes 64h and 65h: the rope tiles 07 and 08
ELM_66  DB    0Ah,09h,0Ch,0Bh              ; 2503  tiles 09 0A / 0B 0C -- chain ladder
ELM_6A  DW    AN_OBJ4,AN_OBJ1,AN_ENMYL,AN_ENMYR ; 2507  enemies 6Ah, 6Ch, 6Eh: overlapping pairs
ELM_72  DW    AN_OBJ2,AN_OBJ3              ; 250F  enemy 72h
ELM_76  DB    02h,38h,39h                  ; 2513  code 76h: 2-tile pattern, the life icon
DIGITS  DB    47h,46h,49h,48h              ; 2516  code 79h  digit 0
        DB    4Bh,4Ah,4Dh,4Ch              ; 251A  code 7Dh  digit 1
        DB    4Fh,4Eh,51h,50h              ; 251E  code 81h  digit 2
        DB    53h,52h,55h,54h              ; 2522  code 85h  digit 3
        DB    57h,56h,59h,58h              ; 2526  code 89h  digit 4
        DB    5Bh,5Ah,5Dh,5Ch              ; 252A  code 8Dh  digit 5
        DB    5Fh,5Eh,61h,60h              ; 252E  code 91h  digit 6
        DB    63h,62h,65h,64h              ; 2532  code 95h  digit 7
        DB    67h,66h,69h,68h              ; 2536  code 99h  digit 8
        DB    6Bh,6Ah,6Dh,6Ch              ; 253A  code 9Dh  digit 9
; decimal digit 0..9 -> code of its 2x2 picture in DIGITS
DIGELM  DB    79h,7Dh,81h,85h,89h,8Dh,91h,95h,99h,9Dh ; 253E

;-----------------------------------------------------------------------
; HUDMAP -- STATUS PANEL TEMPLATE, 5 x 40 TILES
;
; PUTHUD copies these 200 bytes into the top five rows of SCRMAP: the
; score frame on the left, brick wall down the middle, and the lives
; frame with Panama Joe's heads on the right.
;-----------------------------------------------------------------------
HUDMAP       LABEL BYTE                    ; 2548
        ; row 0
        DB    05h,03h,03h,03h,03h,03h,03h,03h,03h,03h,03h,05h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
        DB    01h,05h,03h,03h,03h,03h,03h,03h,03h,03h,03h,03h,03h,03h,05h
        ; row 1
        DB    05h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,05h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
        DB    01h,05h,00h,00h,00h,00h,00h,00h,00h,00h,46h,47h,46h,47h,05h
        ; row 2
        DB    05h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,05h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
        DB    01h,05h,00h,00h,00h,00h,00h,00h,00h,00h,48h,49h,48h,49h,05h
        ; row 3
        DB    05h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,05h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h,01h
        DB    01h,05h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,05h
        ; row 4
        DB    01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h
        DB    02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h,01h,02h

CSEG    ENDS
        END
