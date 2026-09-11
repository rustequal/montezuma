        PAGE  60,132
        TITLE SPRDRW -- SPRITE OUTPUT
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC DRWALL2
        PUBLIC ERSALL
        EXTRN  INBITS:BYTE
        EXTRN  MSKTAB:BYTE
        EXTRN  OBJTAB:BYTE
        EXTRN  OBJTBL:WORD

;=======================================================================
; SPRDRW.ASM -- SPRITE OUTPUT
;
; Four routines: erase them all, draw them all, erase one, and draw one
; while saving the background away in OBJTAB.
;=======================================================================

;-----------------------------------------------------------------------
; ERSALL -- Erase every sprite: put the background back from OBJTAB.
;
; EXIT   : B800h
; ALTERS : BX, CX, DX, SI, DI, BP, ES
; CALLED BY: ST_DRW, ST_PL1, ST_PL2, ST_PL3
;-----------------------------------------------------------------------
ERSALL:
        push    ax                       ; 5CA0  AX comes back at 5CB4
        xor     si, si                   ; 5CA1  SI -- object number, starting at zero
        mov     al, INBITS               ; 5CA3  AL -- one bit per live object
LERSAL1:
        clc                              ; 5CA6  clear the carry ahead of the RCR
        rcr     al, 1                    ; 5CA7  low bit out into the carry
        jae     LERSAL2                  ; 5CA9  bit clear -- no object in this slot
        call    ERSSPR                   ; 5CAB  erase the sprite of object SI
LERSAL2:
        inc     si                       ; 5CAE  on to the next object
        cmp     si, 8                    ; 5CAF  eight object slots in all
        jl      LERSAL1                  ; 5CB2  slots not used up yet
        pop     ax                       ; 5CB4  AX restored
        ret                              ; 5CB5  return: every sprite has been erased

;-----------------------------------------------------------------------
; DRWALL2 -- Draw every sprite, saving the background as it goes.
;
; EXIT   : B800h
; ALTERS : BX, CX, DX, SI, DI, BP, ES
; CALLED BY: DRAWFRM, ST_DRW, ST_PL1, ST_PL2, ST_PL3
;-----------------------------------------------------------------------
DRWALL2:
        push    ax                       ; 5CB6  AX comes back at 5CCB
        mov     si, 7                    ; 5CB7  SI -- object number, starting at seven
        mov     al, INBITS               ; 5CBA  AL -- one bit per live object
LDRWAL1:
        clc                              ; 5CBD  clear the carry ahead of the RCL
        rcl     al, 1                    ; 5CBE  high bit out into the carry
        jae     LDRWAL2                  ; 5CC0  bit clear -- no object in this slot
        call    DRWSPR                   ; 5CC2  draw the sprite of object SI
LDRWAL2:
        dec     si                       ; 5CC5  back to the previous object
        cmp     si, 0                    ; 5CC6  slots run from the top down
        jge     LDRWAL1                  ; 5CC9  slots not used up yet
        pop     ax                       ; 5CCB  AX restored
        ret                              ; 5CCC  return: every sprite has been drawn

;-----------------------------------------------------------------------
; ERSSPR -- Erase sprite SI: put the saved background back.
;
; ENTRY  : SI
; EXIT   : B800h
; ALTERS : nothing
; CALLED BY: ERSALL
;-----------------------------------------------------------------------
ERSSPR:
        SAVEALE                          ; 5CCD  macro
        mov     bx, VRAM_SEG             ; 5CD5  B800h -- CGA video RAM
        mov     es, bx                   ; 5CD8  ES -- video RAM
        mov     bp, OFFSET OBJTAB        ; 5CDA  BP -- table of saved background
        mov     ax, si                   ; 5CDD  AX -- object number
        mov     cl, 8                    ; 5CDF  CL=8 -- shift by eight places
        shl     ax, cl                   ; 5CE1  number * 100h: records run 256 bytes apiece
        add     bp, ax                   ; 5CE3  BP -- the object's record
        mov     si, bp                   ; 5CE5  SI -- the object's record
        add     si, BG_BITS              ; 5CE7  SI -- field holding the saved background bytes
        mov     di, ds:[bp]              ; 5CEA  DI -- sprite's offset in video RAM
        mov     al, ds:[bp+BG_FLD]       ; 5CEE  AL -- which field the top line sits in
        mov     dl, ds:[bp+BG_H]         ; 5CF2  DL -- sprite height
        mov     bl, ds:[bp+BG_W]         ; 5CF6  BL -- sprite width in bytes
        cld                              ; 5CFA  MOVSB will run forward
        xor     cx, cx                   ; 5CFB  CX=0
        xor     bh, bh                   ; 5CFD  BH=0: the whole width now sits in BX
        cmp     al, 1                    ; 5CFF  is the top line in the odd field?
        jne     LERSSP1                  ; 5D01  no -- start off in the even one
        add     di, FIELD_ODD            ; 5D03  yes -- step over into the odd field
        jmp     LERSSP2                  ; 5D07  and start off on an odd line
LERSSP1:
        mov     cl, bl                   ; 5D0A  CL -- width of the line
        rep movsb                        ; 5D0C  a line of background is back in video RAM
        dec     dl                       ; 5D0E  one line fewer to go
        je      LERSSP3                  ; 5D10  the sprite is erased
        sub     di, bx                   ; 5D12  DI back at the start of the line
        add     di, FIELD_ODD            ; 5D14  over to the odd field: +2000h
LERSSP2:
        mov     cl, bl                   ; 5D18  CL -- width of the line
        rep movsb                        ; 5D1A  a line of background is back in video RAM
        dec     dl                       ; 5D1C  one line fewer to go
        je      LERSSP3                  ; 5D1E  the sprite is erased
        sub     di, bx                   ; 5D20  DI back at the start of the line
        sub     di, FIELD_ODD-BYTES_ROW  ; 5D22  back to the even field and 50h further down
        jmp     short LERSSP1            ; 5D26  on to the next pair of lines
LERSSP3:
        RESTALE                          ; 5D28  macro
        ret                              ; 5D30  return: the sprite is erased

;-----------------------------------------------------------------------
; DRWSPR -- Draw sprite SI through the mask, saving background in OBJTAB.
;
; ENTRY  : SI
; EXIT   : B800h, OBJTAB
; ALTERS : nothing
; CALLED BY: DRWALL2
;-----------------------------------------------------------------------
DRWSPR:
        SAVEALE                          ; 5D31  macro
        mov     bx, VRAM_SEG             ; 5D39  B800h -- CGA video RAM
        mov     es, bx                   ; 5D3C  ES -- video RAM
        mov     di, OFFSET OBJTAB        ; 5D3E  DI -- table of saved background
        mov     ax, si                   ; 5D41  AX -- object number
        mov     cl, 8                    ; 5D43  CL=8 -- shift by eight places
        shl     ax, cl                   ; 5D45  number * 100h: records run 256 bytes apiece
        add     di, ax                   ; 5D47  DI -- the object's record
        xor     ax, ax                   ; 5D49  AX=0
        xor     cx, cx                   ; 5D4B  CX=0
        mov     bx, OFFSET OBJTBL        ; 5D4D  BX -- object table
        mov     ax, si                   ; 5D50  AX -- object number
        mov     cl, OBJREC_SZ            ; 5D52  CL -- length of an object record
        mul     cl                       ; 5D54  number * 6: records run six bytes apiece
        add     bx, ax                   ; 5D56  BX -- the object's record
        xor     ax, ax                   ; 5D58  AX=0
        mov     al, [bx+OB_Y]            ; 5D5A  the object's Y
        and     al, 0FEh                 ; 5D5D  even line: bit 0 picks the field
        mov     cl, FLD_ROW              ; 5D5F  bytes to a field line
        mul     cl                       ; 5D61  line * 40
        mov     cl, [bx+OB_X]            ; 5D63  plus X in bytes
        add     ax, cx                   ; 5D66  AX = line*40 + X
        mov     si, ax                   ; 5D68  SI -- sprite's offset in video RAM
        mov     [di], ax                 ; 5D6A  and the same value saved for ERSSPR
        mov     dh, [bx+OB_H]            ; 5D6C  keep the height
        mov     [di+BG_H], dh            ; 5D6F  saved for ERSSPR as well
        mov     dl, [bx+OB_W]            ; 5D72  keep the width
        mov     [di+BG_W], dl            ; 5D75  saved for ERSSPR as well
        mov     al, [bx+OB_Y]            ; 5D78  AL -- the object's Y
        and     al, 1                    ; 5D7B  bit 0 of Y picks the field
        mov     [di+BG_FLD], al          ; 5D7D  and it is saved too
        mov     bx, [bx]                 ; 5D80  BX -- bitmap of the frame
        add     di, BG_BITS              ; 5D82  DI -- where the background bytes go
        mov     bp, OFFSET MSKTAB        ; 5D85  BP -- the mask table
        cmp     al, 1                    ; 5D88  is the top line in the odd field?
        je      LDRWSP3                  ; 5D8A  yes -- start off on an odd line
LDRWSP1:
        mov     cl, dl                   ; 5D8C  CL -- width of the line
        push    si                       ; 5D8E  SI comes back at 5DAB
LDRWSP2:
        mov     al, es:[si]              ; 5D8F  read a byte of background
        mov     [di], al                 ; 5D92  and keep it for ERSSPR
        SAVEREG <si,cx>                  ; 5D94  macro
        xor     ch, ch                   ; 5D96  CH=0: the whole bitmap byte now sits in CX
        mov     cl, [bx]                 ; 5D98  CL = byte of the bitmap
        mov     si, cx                   ; 5D9A  SI -- the same byte as an index into the mask table
        and     al, ds:[bp+si]           ; 5D9C  punch out the background dots under the sprite
        or      al, cl                   ; 5D9F  lay the sprite pixels in
        RESTREG <cx,si>                  ; 5DA1  macro
        mov     es:[si], al              ; 5DA3  write it out to video RAM
        inc     si                       ; 5DA6  next byte across the line
        inc     di                       ; 5DA7  next byte of saved background
        inc     bx                       ; 5DA8  next byte of the bitmap
        loop    LDRWSP2                  ; 5DA9  line is not finished
        pop     si                       ; 5DAB  SI back at the start of the line
        dec     dh                       ; 5DAC  one line fewer to go
        je      LDRWSP5                  ; 5DAE  the sprite is drawn
LDRWSP3:
        mov     cl, dl                   ; 5DB0  CL -- width of the line
        push    si                       ; 5DB2  SI comes back at 5DD3
LDRWSP4:
        mov     al, es:[si+FIELD_ODD]    ; 5DB3  background byte out of the odd field
        mov     [di], al                 ; 5DB8  keep it for ERSSPR
        SAVEREG <si,cx>                  ; 5DBA  macro
        xor     ch, ch                   ; 5DBC  CH=0: the whole bitmap byte now sits in CX
        mov     cl, [bx]                 ; 5DBE  CL = byte of the bitmap
        mov     si, cx                   ; 5DC0  SI -- the same byte as an index into the mask table
        and     al, ds:[bp+si]           ; 5DC2  punch out the background dots under the sprite
        or      al, cl                   ; 5DC5  lay the sprite pixels in
        RESTREG <cx,si>                  ; 5DC7  macro
        mov     es:[si+FIELD_ODD], al    ; 5DC9  write it out to the odd field
        inc     si                       ; 5DCE  next byte across the line
        inc     di                       ; 5DCF  next byte of saved background
        inc     bx                       ; 5DD0  next byte of the bitmap
        loop    LDRWSP4                  ; 5DD1  line is not finished
        pop     si                       ; 5DD3  SI back at the start of the line
        dec     dh                       ; 5DD4  one line fewer to go
        je      LDRWSP5                  ; 5DD6  the sprite is drawn
        add     si, BYTES_ROW            ; 5DD8  down one scan line
        jmp     short LDRWSP1            ; 5DDB  on to the next pair of lines
LDRWSP5:
        RESTALE                          ; 5DDD  macro
        ret                              ; 5DE5  return: sprite drawn, background saved

CSEG    ENDS
        END
