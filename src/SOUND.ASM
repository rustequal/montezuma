        PAGE  60,132
        TITLE SOUND -- TUNES AND THE SOUND DISPATCHER
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC PLAYSND

;=======================================================================
; SOUND.ASM -- TUNES AND THE SOUND DISPATCHER
;
; The twelve tunes, SNDTAB, and PLAYSND with its priority test.
;=======================================================================

;-----------------------------------------------------------------------
; SNDPRI -- NUMBER OF THE SOUND NOW PLAYING  (77B0, 2 bytes)
;
; It doubles as the priority: a higher number pushes a lower one out.
;-----------------------------------------------------------------------
SNDPRI  DW    0                          ; 77B0  number of the sound now playing, doubles as its priority

;-----------------------------------------------------------------------
; SCORES -- THE TUNES, TWELVE OF THEM
;
; A stream of records, tick = 10 ms. Frequency in hertz = 1193182 / divisor.
;-----------------------------------------------------------------------
SCORES  LABEL BYTE                       ; 77B2  twelve tunes back to back
SND_07:                                  ; 77B2
        NOTE  2612,9                     ; 77B2   456.8 Hz  A#4
        NOTE  SND_REST,9                 ; 77B5  rest
        NOTE  2612,9                     ; 77B8   456.8 Hz  A#4
        NOTE  SND_REST,9                 ; 77BB  rest
        NOTE  2612,9                     ; 77BE   456.8 Hz  A#4
        NOTE  SND_REST,9                 ; 77C1  rest
        NOTE  1956,9                     ; 77C4   610.0 Hz  D#5
        NOTE  SND_REST,14                ; 77C7  rest
        NOTE  1552,9                     ; 77CA   768.8 Hz  G5
        DW    SND_END                    ; 77CD

SND_11:                                  ; 77CF
        NOTE  2079,9                     ; 77CF   573.9 Hz  D5
        NOTE  2079,9                     ; 77D2   573.9 Hz  D5
        NOTE  1856,9                     ; 77D5   642.9 Hz  E5
        NOTE  2079,9                     ; 77D8   573.9 Hz  D5
        NOTE  2079,9                     ; 77DB   573.9 Hz  D5
        NOTE  1856,9                     ; 77DE   642.9 Hz  E5
        NOTE  2079,9                     ; 77E1   573.9 Hz  D5
        NOTE  SND_REST,14                ; 77E4  rest
        NOTE  1228,9                     ; 77E7   971.6 Hz  B5
        NOTE  SND_REST,14                ; 77EA  rest
        NOTE  1560,14                    ; 77ED   764.9 Hz  G5
        DW    SND_END                    ; 77F0

SND_02:                                  ; 77F2
        DW    SND_SWEEP,1560,7,225,1     ; 77F2  sweep: 225 steps of +7
        DW    SND_END                    ; 77FC

SND_04:                                  ; 77FE
        DW    SND_SWEEP,3279,65461,20,1  ; 77FE  sweep: 20 steps of -75
        DW    SND_END                    ; 7808

SND_01:                                  ; 780A
        NOTE  1834,2                     ; 780A   650.6 Hz  E5
        NOTE  1677,2                     ; 780D   711.5 Hz  F5
        NOTE  1559,2                     ; 7810   765.4 Hz  G5
        NOTE  1458,2                     ; 7813   818.4 Hz  G#5
        NOTE  1356,2                     ; 7816   879.9 Hz  A5
        NOTE  1268,2                     ; 7819   941.0 Hz  A#5
        NOTE  1200,2                     ; 781C   994.3 Hz  B5
        NOTE  1138,2                     ; 781F  1048.5 Hz  C6
        NOTE  1076,2                     ; 7822  1108.9 Hz  C#6
        DW    SND_END                    ; 7825

SND_00:                                  ; 7827
        NOTE  2200,1                     ; 7827   542.4 Hz  C#5
        NOTE  SND_REST,10                ; 782A  rest
        NOTE  2200,1                     ; 782D   542.4 Hz  C#5
        NOTE  SND_REST,10                ; 7830  rest
        DW    SND_END                    ; 7833

SND_08:                                  ; 7835
        NOTE  2943,8                     ; 7835   405.4 Hz  G#4
        NOTE  1856,8                     ; 7838   642.9 Hz  E5
        NOTE  1471,8                     ; 783B   811.1 Hz  G#5
        NOTE  2496,8                     ; 783E   478.0 Hz  A#4
        NOTE  1856,8                     ; 7841   642.9 Hz  E5
        NOTE  1228,8                     ; 7844   971.6 Hz  B5
        NOTE  2943,8                     ; 7847   405.4 Hz  G#4
        NOTE  1856,8                     ; 784A   642.9 Hz  E5
        NOTE  1471,8                     ; 784D   811.1 Hz  G#5
        NOTE  2496,8                     ; 7850   478.0 Hz  A#4
        NOTE  1856,8                     ; 7853   642.9 Hz  E5
        NOTE  1228,8                     ; 7856   971.6 Hz  B5
        NOTE  1856,8                     ; 7859   642.9 Hz  E5
        NOTE  1228,8                     ; 785C   971.6 Hz  B5
        NOTE  922,8                      ; 785F  1294.1 Hz  E6
        NOTE  2476,8                     ; 7862   481.9 Hz  B4
        NOTE  1856,8                     ; 7865   642.9 Hz  E5
        NOTE  1228,8                     ; 7868   971.6 Hz  B5
        NOTE  1856,8                     ; 786B   642.9 Hz  E5
        NOTE  1228,8                     ; 786E   971.6 Hz  B5
        NOTE  1098,8                     ; 7871  1086.7 Hz  C#6
        NOTE  1039,8                     ; 7874  1148.4 Hz  D6
        NOTE  992,8                      ; 7877  1202.8 Hz  D6
        DW    SND_END                    ; 787A

SND_09:                                  ; 787C
        NOTE  4587,8                     ; 787C   260.1 Hz  C4
        NOTE  2943,8                     ; 787F   405.4 Hz  G#4
        NOTE  2327,8                     ; 7882   512.8 Hz  C5
        NOTE  3899,8                     ; 7885   306.0 Hz  D#4
        NOTE  2327,8                     ; 7888   512.8 Hz  C5
        NOTE  1850,8                     ; 788B   645.0 Hz  E5
        NOTE  2943,8                     ; 788E   405.4 Hz  G#4
        NOTE  2327,8                     ; 7891   512.8 Hz  C5
        NOTE  1471,8                     ; 7894   811.1 Hz  G#5
        NOTE  3899,8                     ; 7897   306.0 Hz  D#4
        NOTE  2327,8                     ; 789A   512.8 Hz  C5
        NOTE  1950,8                     ; 789D   611.9 Hz  D#5
        NOTE  2943,8                     ; 78A0   405.4 Hz  G#4
        NOTE  2327,8                     ; 78A3   512.8 Hz  C5
        NOTE  1471,8                     ; 78A6   811.1 Hz  G#5
        NOTE  2327,8                     ; 78A9   512.8 Hz  C5
        NOTE  1471,8                     ; 78AC   811.1 Hz  G#5
        NOTE  1164,8                     ; 78AF  1025.1 Hz  C6
        NOTE  1950,8                     ; 78B2   611.9 Hz  D#5
        NOTE  1164,8                     ; 78B5  1025.1 Hz  C6
        NOTE  981,8                      ; 78B8  1216.3 Hz  D#6
        NOTE  2327,8                     ; 78BB   512.8 Hz  C5
        NOTE  1471,8                     ; 78BE   811.1 Hz  G#5
        DW    SND_END                    ; 78C1

SND_10:                                  ; 78C3
        NOTE  3714,8                     ; 78C3   321.3 Hz  E4
        NOTE  2327,8                     ; 78C6   512.8 Hz  C5
        NOTE  1856,8                     ; 78C9   642.9 Hz  E5
        NOTE  1560,8                     ; 78CC   764.9 Hz  G5
        NOTE  4587,8                     ; 78CF   260.1 Hz  C4
        NOTE  3119,8                     ; 78D2   382.6 Hz  G4
        NOTE  2327,8                     ; 78D5   512.8 Hz  C5
        NOTE  1856,8                     ; 78D8   642.9 Hz  E5
        NOTE  3714,8                     ; 78DB   321.3 Hz  E4
        NOTE  2327,8                     ; 78DE   512.8 Hz  C5
        NOTE  1856,8                     ; 78E1   642.9 Hz  E5
        NOTE  1560,8                     ; 78E4   764.9 Hz  G5
        NOTE  4587,8                     ; 78E7   260.1 Hz  C4
        NOTE  3119,8                     ; 78EA   382.6 Hz  G4
        NOTE  2327,8                     ; 78ED   512.8 Hz  C5
        NOTE  1856,8                     ; 78F0   642.9 Hz  E5
        NOTE  3714,8                     ; 78F3   321.3 Hz  E4
        NOTE  2327,8                     ; 78F6   512.8 Hz  C5
        NOTE  1856,8                     ; 78F9   642.9 Hz  E5
        NOTE  1560,8                     ; 78FC   764.9 Hz  G5
        NOTE  3119,8                     ; 78FF   382.6 Hz  G4
        NOTE  1856,8                     ; 7902   642.9 Hz  E5
        NOTE  1560,8                     ; 7905   764.9 Hz  G5
        NOTE  1164,8                     ; 7908  1025.1 Hz  C6
        NOTE  2327,8                     ; 790B   512.8 Hz  C5
        NOTE  1560,8                     ; 790E   764.9 Hz  G5
        NOTE  1164,8                     ; 7911  1025.1 Hz  C6
        NOTE  922,8                      ; 7914  1294.1 Hz  E6
        NOTE  1856,8                     ; 7917   642.9 Hz  E5
        NOTE  1560,8                     ; 791A   764.9 Hz  G5
        NOTE  1164,8                     ; 791D  1025.1 Hz  C6
        NOTE  922,8                      ; 7920  1294.1 Hz  E6
        NOTE  775,8                      ; 7923  1539.6 Hz  G6
        DW    SND_END                    ; 7926

SND_05:                                  ; 7928
        NOTE  3200,1                     ; 7928   372.9 Hz  F#4
        NOTE  SND_REST,5                 ; 792B  rest
        NOTE  3200,1                     ; 792E   372.9 Hz  F#4
        NOTE  SND_REST,10                ; 7931  rest
        NOTE  3200,1                     ; 7934   372.9 Hz  F#4
        NOTE  SND_REST,5                 ; 7937  rest
        NOTE  3200,1                     ; 793A   372.9 Hz  F#4
        NOTE  SND_REST,2                 ; 793D  rest
        NOTE  1200,1                     ; 7940   994.3 Hz  B5
        DW    SND_END                    ; 7943

SND_06:                                  ; 7945
        NOTE  2200,1                     ; 7945   542.4 Hz  C#5
        NOTE  SND_REST,1                 ; 7948  rest
        NOTE  2300,1                     ; 794B   518.8 Hz  C5
        NOTE  SND_REST,1                 ; 794E  rest
        NOTE  2400,1                     ; 7951   497.2 Hz  B4
        NOTE  SND_REST,1                 ; 7954  rest
        NOTE  2200,1                     ; 7957   542.4 Hz  C#5
        NOTE  SND_REST,1                 ; 795A  rest
        NOTE  2300,1                     ; 795D   518.8 Hz  C5
        NOTE  SND_REST,1                 ; 7960  rest
        NOTE  2400,1                     ; 7963   497.2 Hz  B4
        NOTE  SND_REST,1                 ; 7966  rest
        DW    SND_END                    ; 7969

SND_03:                                  ; 796B
        NOTE  3200,1                     ; 796B   372.9 Hz  F#4
        NOTE  SND_REST,5                 ; 796E  rest
        NOTE  3200,1                     ; 7971   372.9 Hz  F#4
        NOTE  SND_REST,10                ; 7974  rest
        DW    SND_END                    ; 7977

;-----------------------------------------------------------------------
; PLAYSND -- Play sound SI if the priority lets it through.
;
; ENTRY  : SI
; EXIT   : SNDPRI
; ALTERS : nothing
; CALLED BY: KILLPLR, OPENDOOR, PLRHIT, PST_0, PST_1, PST_5, TREASR, XLIFE
;-----------------------------------------------------------------------
PLAYSND:
        mov     ax, si                   ; 7979  AX -- sound number
        SAVEREG <ax,si,bx>               ; 797B  macro
        push    ax                       ; 797E  AX comes back at 7986
        mov     ax, 1                    ; 797F  AX=1 -- the "is it playing" query
        int     62h                      ; 7982  OUR OWN API: sound
        cmp     al, 1                    ; 7984  AL=1 -- a sound is running
        pop     ax                       ; 7986  AX -- sound number
        jne     LPLAYS1                  ; 7987  silence -- play it, no questions asked
        cmp     SNDPRI, ax               ; 7989  number of the sound now playing
        jb      LPLAYS1                  ; 798D  the new one outranks it
        jmp     LPLAYS2                  ; 798F  the one playing outranks it -- leave it alone
LPLAYS1:
        mov     SNDPRI, ax               ; 7992  number of the new sound is kept
        shl     ax, 1                    ; 7995  entries run two bytes apiece
        mov     si, ax                   ; 7997  SI -- the same number as an index
        mov     bx, OFFSET SNDTAB        ; 7999  table of pointers to the tunes
        mov     ax, cs:[bx+si]           ; 799C  AX -- address of the tune
        int     62h                      ; 799F  OUR OWN API: sound
LPLAYS2:
        RESTREG <bx,si,ax>               ; 79A1  macro
        ret                              ; 79A4  return: sound started, or passed over

;-----------------------------------------------------------------------
; SNDTAB -- POINTERS TO THE TUNES
;
; PLAYSND takes the sound number in SI and comes here for the address.
; The number is the priority too: a higher one pushes a lower one out.
; 0 run-up (PST_1), 1 jump (PST_0), 2 losing footing and 3 landing (PST_5),
; 4 enemy killed and 7 item picked up (PLRHIT), 5 doorway opened (OPENDOOR),
; 6 death (PST_5 and KILLPLR),
; 8, 9, 10 -- treasure chamber tunes through MUSTAB, 11 -- extra life.
;-----------------------------------------------------------------------
SNDTAB  LABEL WORD                       ; 79A5
        DW    SND_00                     ; 79A5   0 run-up
        DW    SND_01                     ; 79A7   1 jump
        DW    SND_02                     ; 79A9   2 losing footing
        DW    SND_03                     ; 79AB   3 landing
        DW    SND_04                     ; 79AD   4 enemy killed
        DW    SND_05                     ; 79AF   5 doorway opened
        DW    SND_06                     ; 79B1   6 death
        DW    SND_07                     ; 79B3   7 item picked up
        DW    SND_08                     ; 79B5   8 treasure chamber tune
        DW    SND_09                     ; 79B7   9 treasure chamber tune
        DW    SND_10                     ; 79B9  10 treasure chamber tune
        DW    SND_11                     ; 79BB  11 extra life

CSEG    ENDS
        END
