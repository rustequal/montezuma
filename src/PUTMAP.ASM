        PAGE  60,132
        TITLE PUTMAP -- TILE MAP OUTPUT, INT 67h ISR
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC PUTMAP

;=======================================================================
; PUTMAP.ASM -- TILE MAP OUTPUT, INT 67h ISR
;
; The whole INT 67h handler: a window of the tile map out to video RAM.
; Arguments come in on the stack, read as SS:[SP+16h] and up.
;=======================================================================

;-----------------------------------------------------------------------
; PUTMAP -- INT 67h ISR. Puts out a rectangular window of the tile map.
;
; ENTRY  : stack
; EXIT   : B800h
; ALTERS : nothing
; CALLED BY: through the interrupt vector or through a jump table
;-----------------------------------------------------------------------
PUTMAP:
        sti                              ; 1000  interrupts back on: this is a long piece of output
        SAVEAL8                          ; 1001  macro: save eight registers
        mov     ax, VRAM_SEG             ; 1009  B800h -- CGA video RAM
        mov     es, ax                   ; 100C  ES = video RAM
        mov     di, sp                   ; 100E  DI -- at the arguments pushed on the stack ahead of the INT
        mov     cx, ss:[di+18h]          ; 1010  CX -- how many tile rows the window is
        mov     si, ss:[di+20h]          ; 1014  SI -- address of the tile map
        mov     ax, ss:[di+1Ch]          ; 1018  AX -- window's top row on the map
        mov     bx, MAP_W                ; 101C  map width in cells
        mul     bx                       ; 101F  row * 40 = offset to the start of the row
        add     si, ax                   ; 1021  SI = map + row*40
        add     si, ss:[di+1Ah]          ; 1023  plus the column: SI at the window's first cell
        mov     ax, ss:[di+1Ch]          ; 1027  AX -- the same window row, this time counted in bytes
        mov     bx, TILE_ROW             ; 102B  a tile row is 8 scan lines
        mul     bx                       ; 102E  row * 140h
        mov     bx, ss:[di+1Ah]          ; 1030  BX -- window's left column
        shl     bx, 1                    ; 1034  a tile takes 2 bytes of video RAM across
        add     ax, bx                   ; 1036  AX = row*140h + column*2
        mov     bp, ax                   ; 1038  BP -- offset into video RAM
        mov     dx, ss:[di+16h]          ; 103A  DX -- how many tiles across the window is
LPUTMA1:
        push    cx                       ; 103E  CX -- count of window rows left
        push    bp                       ; 103F  BP -- start of this row in video RAM
        push    si                       ; 1040  SI -- start of this row on the map
LPUTMA2:
        mov     al, [si]                 ; 1041  AL -- tile number out of the map
        mov     ah, 0                    ; 1043  AH=0: the whole tile number now sits in AX
        shl     ax, 1                    ; 1045  number * 2
        shl     ax, 1                    ; 1047  number * 4
        shl     ax, 1                    ; 1049  number * 8
        shl     ax, 1                    ; 104B  number * 16: one tile picture is that long
        add     ax, ss:[di+1Eh]          ; 104D  plus the tile table base handed over on the stack
        mov     bx, ax                   ; 1051  BX -- picture of the tile just selected
        mov     cx, 4                    ; 1053  the tile's 8 lines go in pairs: 4 passes
        push    bp                       ; 1056  BP will be wanted again for the next tile
LPUTMA3:
        mov     ax, [bx]                 ; 1057  two bytes of the tile's even line
        mov     es:[bp], ax              ; 1059  out to the even field
        inc     bx                       ; 105D  first byte of the pair is done
        inc     bx                       ; 105E  BX on to the next two bytes
        mov     ax, [bx]                 ; 105F  two bytes of the tile's odd line
        mov     es:[bp+FIELD_ODD], ax    ; 1061  out to the odd field: +2000h
        inc     bx                       ; 1066  first byte of the pair is done
        inc     bx                       ; 1067  BX on to the next two bytes
        add     bp, BYTES_ROW            ; 1068  down one scan line
        loop    LPUTMA3                  ; 106B  one more pair of tile lines
        pop     bp                       ; 106D  BP back at the start of this tile
        inc     bp                       ; 106E  first byte of the tile is done
        inc     bp                       ; 106F  BP on to the next tile: +2 bytes
        inc     si                       ; 1070  SI on to the next map cell
        dec     dx                       ; 1071  one tile fewer left in this row
        jne     LPUTMA2                  ; 1072  window row is not finished
        pop     si                       ; 1074  SI back at the start of the map row
        add     si, MAP_W                ; 1075  map: down one row
        pop     bp                       ; 1078  BP back at the start of the video RAM row
        add     bp, TILE_ROW             ; 1079  video RAM: down one tile row
        pop     cx                       ; 107D  CX -- count of window rows left
        mov     dx, ss:[di+16h]          ; 107E  DX -- window width in tiles once again
        loop    LPUTMA1                  ; 1082  one more window row
        RESTAL8                          ; 1084  macro: restore eight registers
        iret                             ; 108C  leave the interrupt handler

CSEG    ENDS
        END
