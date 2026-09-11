        PAGE  60,132
        TITLE SCANTIL -- NEIGHBORING TILES
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC MAPOFS
        PUBLIC SCANTIL
        PUBLIC TILEAT
        PUBLIC TILEDN
        PUBLIC TILELF
        PUBLIC TILERT
        EXTRN  OBJTBL:WORD
        EXTRN  OBJTYP:BYTE
        EXTRN  OBJTYPE:NEAR
        EXTRN  SCRMAP:BYTE

;=======================================================================
; SCANTIL.ASM -- NEIGHBORING TILES
;
; The arrays of tiles around each object, and the routine that fills
; them in from SCRMAP.
;=======================================================================

;-----------------------------------------------------------------------
; NEIGHBORING TILES  (6000..6026, 39 bytes)
;
; 6000h ROWADJ -- row correction by object type: 08 0D 0D 0D 13
; 6005h/600Dh/6015h/601Dh -- tiles at left, at the cell, right, underfoot
; 6025h MAPOFS -- offset of the player's cell within SCRMAP
;-----------------------------------------------------------------------
; row correction by object type, 5 bytes: 08 0D 0D 0D 13
ROWADJ  DB    08h,0Dh,0Dh,0Dh,13h        ; 6000
TILELF  DB    8 DUP (0)                  ; 6005..600C  per object: the tile to the left
; per object: the tile in the object's own cell
TILEAT  DB    8 DUP (0)                  ; 600D..6014
TILERT  DB    8 DUP (0)                  ; 6015..601C  per object: the tile to the right
; per object: the tile one row down, that is, underfoot
TILEDN  DB    8 DUP (0)                  ; 601D..6024
; offset of the player's cell within SCRMAP (object 0 only)
MAPOFS  DW    0                          ; 6025

;-----------------------------------------------------------------------
; SCANTIL -- Read the four tiles around object SI into TILELF/TILEAT/TILERT/TILEDN.
;
; ENTRY  : SI
; ALTERS : nothing
; CALLED BY: BEH_CLMB, DIRBIT, PST_5, PST_789
;-----------------------------------------------------------------------
SCANTIL:
        SAVEALL                          ; 6027  macro
        mov     bx, OFFSET OBJTBL        ; 602E  BX -- object table
        mov     ax, si                   ; 6031  AX -- object number
        mov     dl, OBJREC_SZ            ; 6033  DL -- length of an object record
        mul     dl                       ; 6035  number * 6: records run six bytes apiece
        add     bx, ax                   ; 6037  BX -- the object's record
        mov     al, [bx+OB_Y]            ; 6039  AL -- object's Y in scan lines
        sub     al, 4                    ; 603C  the four scan lines of the panel do not count
        call    OBJTYPE                  ; 603E  OBJTYP -- type of the object in SI
        mov     bp, OFFSET ROWADJ        ; 6041  table of row corrections by type
        xor     dh, dh                   ; 6044  DH=0: the whole type now sits in DX
        mov     dl, OBJTYP               ; 6046  DL -- object type
        add     bp, dx                   ; 604A  BP -- the correction for this type
        add     al, ds:[bp]              ; 604C  Y plus the correction: the row underfoot
        shr     al, 1                    ; 6050  shift 1 of 3
        shr     al, 1                    ; 6052  shift 2 of 3
        shr     al, 1                    ; 6054  eight scan lines to a cell
        mov     cl, MAP_W                ; 6056  cells across one map row
        mul     cl                       ; 6058  row * 40
        mov     dl, [bx+OB_X]            ; 605A  DL -- object's X in bytes
        shr     dl, 1                    ; 605D  two bytes of video RAM to a cell
        xor     dh, dh                   ; 605F  DH=0: the whole column now sits in DX
        add     ax, dx                   ; 6061  plus the column
        mov     di, ax                   ; 6063  DI -- offset of the cell within the map
        cmp     si, 0                    ; 6065  object 0 is the player
        jne     LSCANT1                  ; 6068  not the player -- do not keep the offset
        mov     MAPOFS, di               ; 606A  MAPOFS -- the player's cell, other code reads it
LSCANT1:
        mov     bp, OFFSET SCRMAP        ; 606E  BP -- the screen map
        mov     bx, OFFSET TILELF        ; 6071  table of left-hand tiles, one slot per object
        mov     al, ds:[bp+di]           ; 6074  the cell to the left
        mov     [bx+si], al              ; 6077  left-hand tile stored in the slot
        mov     bx, OFFSET TILEAT        ; 6079  table of own-cell tiles, one slot per object
        mov     al, ds:[bp+di+1]         ; 607C  the cell the object stands in
        mov     [bx+si], al              ; 6080  own-cell tile stored in the slot
        mov     bx, OFFSET TILERT        ; 6082  table of right-hand tiles, one slot per object
        mov     al, ds:[bp+di+2]         ; 6085  the cell to the right
        mov     [bx+si], al              ; 6089  right-hand tile stored in the slot
        add     di, 29h                  ; 608B  29h = 41: one row down and one cell right
        cmp     di, MAP_SZ               ; 608E  past the last cell of the map?
        jl      LSCANT2                  ; 6092  the cell is on the map
        mov     bx, OFFSET TILEAT        ; 6094  off the map: stand in the object's own cell
        mov     bp, OFFSET TILEDN        ; 6097  table of underfoot tiles, one slot per object
        mov     al, [bx+si]              ; 609A  AL -- the own-cell tile
        mov     ds:[bp+si], al           ; 609C  underfoot tile made equal to the own-cell tile
        jmp     LSCANT3                  ; 609F  off to the common exit
LSCANT2:
        mov     bx, OFFSET TILEDN        ; 60A2  table of underfoot tiles, one slot per object
        mov     al, ds:[bp+di]           ; 60A5  the cell underfoot
        mov     [bx+si], al              ; 60A8  underfoot tile stored in the slot
LSCANT3:
        RESTALL                          ; 60AA  macro
        ret                              ; 60B1  return: the four tiles have been read

CSEG    ENDS
        END
