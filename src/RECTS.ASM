        PAGE  60,132
        TITLE RECTS -- PARTIAL REDRAW AND THE FLOOR-SPAN LIST
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC MKSOLD
        PUBLIC PUTRCT
        EXTRN  SCRMAP:BYTE
        EXTRN  SOLCNT:WORD
        EXTRN  SOLIDS:BYTE
        EXTRN  TILES:BYTE

;=======================================================================
; RECTS.ASM -- PARTIAL REDRAW AND THE FLOOR-SPAN LIST
;
; PUTRCT puts out a list of dirty rectangles; MKSOLD builds the list of
; floor spans for the current room by scanning SCRMAP.
;=======================================================================

;-----------------------------------------------------------------------
; PUTRCT -- Put out a list of dirty rectangles, terminator 00FFh.
;
; ENTRY  : DI
; EXIT   : B800h
; ALTERS : nothing
; CALLED BY: RCTSHOW, SHOWSCR, ST_DRW, ST_PL1, ST_PL2, ST_X7
;-----------------------------------------------------------------------
PUTRCT:
        SAVEALL                          ; 36A0  macro
        mov     si, OFFSET SCRMAP        ; 36A7  SI -- the screen map
        mov     bp, OFFSET TILES         ; 36AA  BP -- base of the tile table
LPUTRC1:
        cmp     WORD PTR [di], 0FFh      ; 36AD  00FFh -- end of the list
        je      LPUTRC2                  ; 36B1  list is used up
        push    si                       ; 36B3  argument: address of the map
        push    bp                       ; 36B4  argument: base of the tile table
        push    WORD PTR [di]            ; 36B5  argument: top row of the window
        push    WORD PTR [di+2]          ; 36B7  argument: left column of the window
        push    WORD PTR [di+4]          ; 36BA  argument: how many tile rows
        push    WORD PTR [di+6]          ; 36BD  argument: how many tiles across
        int     67h                      ; 36C0  OUR OWN API: put out the map
        pop     ax                       ; 36C2  word 1 of six
        pop     ax                       ; 36C3  word 2 of six
        pop     ax                       ; 36C4  word 3 of six
        pop     ax                       ; 36C5  word 4 of six
        pop     ax                       ; 36C6  word 5 of six
        pop     ax                       ; 36C7  all six argument words pulled off the stack
        add     di, 8                    ; 36C8  a list entry is eight bytes
        jmp     short LPUTRC1            ; 36CB  on to the next rectangle
LPUTRC2:
        RESTALL                          ; 36CD  macro
        ret                              ; 36D4  return: every rectangle has been put out

;-----------------------------------------------------------------------
; MKSOLD -- Build the floor-span list: runs of tiles >= 70h from row 5 on.
;
; ENTRY  : SCRMAP
; EXIT   : SOLIDS, SOLCNT
; ALTERS : nothing
; CALLED BY: DRAWFRM
;-----------------------------------------------------------------------
MKSOLD:
        SAVEALL                          ; 36D5  macro
        mov     si, OFFSET SCRMAP        ; 36DC  SI -- the screen map
        mov     di, OFFSET SOLIDS        ; 36DF  DI -- the floor-span list
        mov     SOLCNT, 0                ; 36E2  total span length starts out at zero
        mov     cx, 0                    ; 36E8  CX -- column, starting at zero
        mov     dx, 5                    ; 36EB  DX -- row, starting at five: the panel is skipped
        mov     bx, HUD_CELLS            ; 36EE  BX -- cell offset: the panel is skipped
LMKSOL1:
        mov     ax, T_SOLID              ; 36F1  lower bound of the solid tile codes
        cmp     [bx+si], al              ; 36F4  is this cell solid?
        jge     LMKSOL3                  ; 36F6  yes -- a run starts here
        inc     bx                       ; 36F8  one cell right
        inc     cx                       ; 36F9  one column right
LMKSOL2:
        cmp     cx, MAP_W                ; 36FA  columns used up?
        jl      LMKSOL1                  ; 36FD  row is not finished
        mov     cx, 0                    ; 36FF  column back to zero
        inc     dx                       ; 3702  one row down
        cmp     dx, MAP_H                ; 3703  map rows used up?
        jl      LMKSOL1                  ; 3706  rows are not finished
        mov     WORD PTR [di], 0FFh      ; 3708  00FFh -- end of the floor-span list
        jmp     LMKSOL6                  ; 370C  the list is built
LMKSOL3:
        mov     [di], dx                 ; 370F  entry field +0: row
        inc     di                       ; 3711  step 1 of two: fields run a word apiece
        inc     di                       ; 3712  DI at field +2
        mov     [di], cx                 ; 3713  entry field +2: column
        inc     di                       ; 3715  step 1 of two: fields run a word apiece
        inc     di                       ; 3716  DI at field +4
        mov     WORD PTR [di], 1         ; 3717  entry field +4: height -- one cell
        inc     di                       ; 371B  step 1 of two: fields run a word apiece
        inc     di                       ; 371C  DI at field +6
        mov     WORD PTR [di], 1         ; 371D  entry field +6: length -- one cell
LMKSOL4:
        inc     bx                       ; 3721  one cell right
        inc     cx                       ; 3722  one column right
        cmp     cx, MAP_W                ; 3723  columns used up?
        jge     LMKSOL5                  ; 3726  row ended -- the run is cut short
        mov     ax, T_SOLID              ; 3728  lower bound of the solid tile codes
        cmp     [bx+si], al              ; 372B  is this cell solid?
        jl      LMKSOL5                  ; 372D  no -- the run ends here
        inc     WORD PTR [di]            ; 372F  run grows by one cell
        jmp     short LMKSOL4            ; 3731  keep the run going
LMKSOL5:
        mov     ax, [di]                 ; 3733  AX -- length of the run
        clc                              ; 3735  clear the carry ahead of the ADC
        adc     SOLCNT, ax               ; 3736  add it into the total span length
        inc     SOLCNT                   ; 373A  the length was counted from zero
        inc     di                       ; 373E  step 1 of two: fields run a word apiece
        inc     di                       ; 373F  DI at the next entry
        jmp     short LMKSOL2            ; 3740  go look for the next run
LMKSOL6:
        RESTALL                          ; 3742  macro
        ret                              ; 3749  return: the floor-span list is built

CSEG    ENDS
        END
