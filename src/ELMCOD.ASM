        PAGE  60,132
        TITLE ELMCOD -- ELEMENT AND TILE CODES
        INCLUDE MX4C.INC

        PUBLIC ELM_AMUL
        PUBLIC ELM_AMULI
        PUBLIC ELM_GEM
        PUBLIC ELM_SWRD
        PUBLIC ELM_SWRDI
        PUBLIC ELM_TRCH
        PUBLIC SOLID_MIN
        PUBLIC T_VOID

;=======================================================================
; ELMCOD.ASM -- element and tile codes.
;
; A module that lays down no bytes at all: nothing but constants
; declared PUBLIC. The other modules pick them up via EXTRN ..:ABS.
;=======================================================================

ELM_AMUL     EQU 2Fh       ; amulet: 37h ticks of invulnerability, 100 pts, inventory icon 33h
ELM_AMULI    EQU 33h       ; amulet, master tiles -- the way it looks in the inventory
ELM_GEM      EQU 2Bh       ; gem, 1000 pts, never goes into the inventory
ELM_SWRD     EQU 37h       ; sword: cuts down an enemy, 50 pts, inventory icon 3Bh
ELM_SWRDI    EQU 3Bh       ; sword, master tiles -- the way it looks in the inventory
ELM_TRCH     EQU 3Fh       ; torch: lights up dark rooms, 3000 pts, inventory icon 3Fh
SOLID_MIN    EQU 70h       ; tiles at this code and above count as solid floor
T_VOID       EQU 0         ; empty, walk-through  [INLIST PASSTIL]

        END
