        PAGE  60,132
        TITLE ROOMDAT -- DESCRIPTIONS OF ALL 99 ROOMS
        INCLUDE MX4C.INC

CSEG    SEGMENT PARA PUBLIC 'CODE'
        ASSUME CS:CSEG, DS:CSEG, ES:CSEG, SS:CSEG

        PUBLIC ELMSEL
        PUBLIC ROOMPT
        PUBLIC SOLIDS
        PUBLIC TRSDRL
        PUBLIC TRSDRR
        PUBLIC TRSGEM
        PUBLIC TRSMAP
        PUBLIC TTLEND
        PUBLIC TTLMAP

;=======================================================================
; ROOMDAT.ASM -- DESCRIPTIONS OF ALL 99 ROOMS
;
; ELMSEL, the ROOMPT pointers and the byte code of 99 rooms, then the
; SOLIDS floor-span buffer. Data only, no code.
;=======================================================================

;-----------------------------------------------------------------------
; ELMSEL, ROOMPT AND THE 99 ROOM DESCRIPTIONS  (2610..369F)
;
; ELMSEL: opcode and 3Fh -> element code in ELMTAB.
; ROOMPT: 100 pointers (264D..2714, exactly 200 bytes).
; Room N takes up everything from ROOMPT[N] up to
; ROOMPT[N+1] -- there is no separate length field.
;-----------------------------------------------------------------------
ELMSEL       LABEL BYTE  ; 2610
        DB    00h,00h,01h,01h,00h,01h,01h,00h,03h,09h,0Dh,0Fh,14h,11h,17h,19h       ; 2610
        DB    0FFh,0FFh,0FFh,0FFh,00h,01h,01h,00h,03h,09h,0FFh,0FFh,29h,1Bh,1Eh,23h ; 2620
        DB    2Bh,2Fh,37h,3Fh,43h,47h,4Bh,66h,4Fh,56h,5Dh,65h,64h,0FFh,0FFh,0FFh    ; 2630
        DB    6Ah,72h,6Eh,6Ch,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh          ; 2640

ROOMPT  LABEL WORD       ; 264D
                         ; 100 words
        DW    ROOM_00    ; room  0
        DW    ROOM_01    ; room  1
        DW    ROOM_02    ; room  2
        DW    ROOM_03    ; room  3
        DW    ROOM_04    ; room  4
        DW    ROOM_05    ; room  5
        DW    ROOM_06    ; room  6
        DW    ROOM_07    ; room  7
        DW    ROOM_08    ; room  8
        DW    ROOM_09    ; room  9
        DW    ROOM_10    ; room 10
        DW    ROOM_11    ; room 11
        DW    ROOM_12    ; room 12
        DW    ROOM_13    ; room 13
        DW    ROOM_14    ; room 14
        DW    ROOM_15    ; room 15
        DW    ROOM_16    ; room 16
        DW    ROOM_17    ; room 17
        DW    ROOM_18    ; room 18
        DW    ROOM_19    ; room 19
        DW    ROOM_20    ; room 20
        DW    ROOM_21    ; room 21
        DW    ROOM_22    ; room 22
        DW    ROOM_23    ; room 23
        DW    ROOM_24    ; room 24
        DW    ROOM_25    ; room 25
        DW    ROOM_26    ; room 26
        DW    ROOM_27    ; room 27
        DW    ROOM_28    ; room 28
        DW    ROOM_29    ; room 29
        DW    ROOM_30    ; room 30
        DW    ROOM_31    ; room 31
        DW    ROOM_32    ; room 32
        DW    ROOM_33    ; room 33
        DW    ROOM_34    ; room 34
        DW    ROOM_35    ; room 35
        DW    ROOM_36    ; room 36
        DW    ROOM_37    ; room 37
        DW    ROOM_38    ; room 38
        DW    ROOM_39    ; room 39
        DW    ROOM_40    ; room 40
        DW    ROOM_41    ; room 41
        DW    ROOM_42    ; room 42
        DW    ROOM_43    ; room 43
        DW    ROOM_44    ; room 44
        DW    ROOM_45    ; room 45
        DW    ROOM_46    ; room 46
        DW    ROOM_47    ; room 47
        DW    ROOM_48    ; room 48
        DW    ROOM_49    ; room 49
        DW    ROOM_50    ; room 50
        DW    ROOM_51    ; room 51
        DW    ROOM_52    ; room 52
        DW    ROOM_53    ; room 53
        DW    ROOM_54    ; room 54
        DW    ROOM_55    ; room 55
        DW    ROOM_56    ; room 56
        DW    ROOM_57    ; room 57
        DW    ROOM_58    ; room 58
        DW    ROOM_59    ; room 59
        DW    ROOM_60    ; room 60
        DW    ROOM_61    ; room 61
        DW    ROOM_62    ; room 62
        DW    ROOM_63    ; room 63
        DW    ROOM_64    ; room 64
        DW    ROOM_65    ; room 65
        DW    ROOM_66    ; room 66
        DW    ROOM_67    ; room 67
        DW    ROOM_68    ; room 68
        DW    ROOM_69    ; room 69
        DW    ROOM_70    ; room 70
        DW    ROOM_71    ; room 71
        DW    ROOM_72    ; room 72
        DW    ROOM_73    ; room 73
        DW    ROOM_74    ; room 74
        DW    ROOM_75    ; room 75
        DW    ROOM_76    ; room 76
        DW    ROOM_77    ; room 77
        DW    ROOM_78    ; room 78
        DW    ROOM_79    ; room 79
        DW    ROOM_80    ; room 80
        DW    ROOM_81    ; room 81
        DW    ROOM_82    ; room 82
        DW    ROOM_83    ; room 83
        DW    ROOM_84    ; room 84
        DW    ROOM_85    ; room 85
        DW    ROOM_86    ; room 86
        DW    ROOM_87    ; room 87
        DW    ROOM_88    ; room 88
        DW    ROOM_89    ; room 89
        DW    ROOM_90    ; room 90
        DW    ROOM_91    ; room 91
        DW    ROOM_92    ; room 92
        DW    ROOM_93    ; room 93
        DW    ROOM_94    ; room 94
        DW    ROOM_95    ; room 95
        DW    ROOM_96    ; room 96
        DW    ROOM_97    ; room 97
        DW    ROOM_98    ; room 98
        DW    TRSMAP     ; room 99

; --- room byte code ---
ROOMS   LABEL BYTE       ; 2715  room descriptions, byte code for BLDMAP
ROOM_00:                 ; 2715, 14 bytes
        DB    3Eh,36h,03h,0A0h,10h,14h,21h,0E8h,31h,0B0h,3Dh,04h,32h,0A0h
ROOM_01:                 ; 2723, 139 bytes
        DB    1Ch,0A0h,04h,1Ch,0A5h,1Fh,1Ch,0C5h,03h,04h,0Fh,05h,09h,14h,06h,07h
        DB    15h,05h,2Ah,0CCh,02h,0ACh,31h,02h,0B9h,31h,2Ah,0ECh,42h,68h,0E7h,42h
        DB    77h,00h,40h,0BAh,73h,66h,0BCh,84h,13h,04h,80h,85h,40h,98h,5Fh,08h
        DB    82h,0A8h,67h,85h,84h,03h,0C2h,9Fh,41h,0C6h,2Ch,02h,0C4h,7Bh,02h,0C3h
        DB    0CCh,14h,00h,0C3h,2Eh,10h,00h,0C7h,64h,03h,0C2h,3Fh,13h,42h,89h,6Fh
        DB    42h,80h,80h,42h,0AAh,10h,42h,0D3h,05h,58h,86h,0Bh,42h,7Ah,30h,58h
        DB    7Bh,08h,8Dh,0B8h,08h,0DEh,7Fh,0Bh,0DEh,0A5h,0Fh,0DFh,0A7h,0Bh,32h,67h
        DB    40h,0B1h,31h,67h,0B1h,67h,0B3h,2Ch,3Bh,2Bh,66h,2Bh,0B8h,2Ch,0B0h,6Ch
        DB    0BAh,6Ch,0ACh,6Bh,0D2h,3Dh,04h,32h,20h,32h,0D0h
ROOM_02:                 ; 27AE, 74 bytes
        DB    07h,0BCh,06h,02h,0C2h,5Fh,46h,0FFh,03h,87h,77h,03h,0C3h,20h,27h,04h
        DB    0D8h,33h,05h,9Ch,3Bh,14h,98h,3Ch,06h,43h,68h,19h,00h,5Ch,71h,11h
        DB    58h,7Ch,05h,42h,90h,69h,44h,97h,02h,85h,0D7h,02h,42h,71h,00h,82h
        DB    4Eh,00h,60h,9Dh,60h,0A0h,60h,0AAh,6Bh,36h,0ABh,76h,6Bh,5Fh,6Bh,88h
        DB    6Ch,99h,0ABh,9Fh,0ABh,0C8h,6Ch,0E7h,31h,50h
ROOM_03:                 ; 27F8, 9 bytes
        DB    3Eh,36h,02h,0AAh,04h,20h,0E4h,30h,0D0h
ROOM_04:                 ; 2801, 203 bytes
        DB    08h,13h,09h,5Ch,7Ah,03h,42h,68h,0DAh,40h,91h,28h,40h,95h,19h,40h
        DB    98h,18h,40h,9Bh,18h,4Eh,91h,03h,4Eh,0B9h,03h,4Eh,0E1h,03h,8Eh,09h
        DB    03h,8Eh,59h,03h,8Eh,81h,03h,8Eh,0A9h,03h,8Eh,0D1h,03h,4Eh,6Dh,02h
        DB    4Eh,70h,02h,4Eh,73h,02h,0A2h,0Dh,0A2h,6Ch,0A4h,6Eh,0A5h,70h,9Eh,88h
        DB    02h,9Eh,8Bh,02h,9Fh,0B0h,02h,9Fh,0D8h,02h,9Fh,0B3h,02h,9Fh,0DBh,02h
        DB    5Eh,0C6h,03h,5Eh,0CBh,03h,5Eh,0D0h,03h,5Fh,0EEh,0Eh,9Fh,16h,0Eh,5Eh
        DB    0FBh,01h,9Eh,24h,01h,5Eh,0F1h,02h,5Eh,0F6h,02h,82h,3Eh,35h,82h,42h
        DB    0A0h,0C2h,0Ah,10h,0CCh,0Ch,0Ah,0A8h,73h,0C3h,20h,27h,04h,0C1h,22h,23h
        DB    03h,0CEh,22h,01h,0CEh,4Ah,01h,0CEh,72h,01h,0CEh,9Ah,01h,0DEh,9Dh,02h
        DB    0E0h,2Bh,0E0h,31h,0CBh,2Fh,04h,42h,87h,80h,42h,0B3h,48h,0C2h,1Eh,11h
        DB    87h,0A3h,03h,5Ch,69h,03h,9Ch,0FAh,03h,9Ch,0FFh,08h,0DCh,08h,04h,59h
        DB    88h,0Ch,80h,03h,22h,80h,67h,12h,0A7h,8Fh,0ACh,6Ah,0ABh,05h,0A7h,2Bh
        DB    32h,0A6h,32h,3Ah,3Dh,04h,0Bh,0CCh,04h,31h,0F0h
ROOM_05:                 ; 28CC, 16 bytes
        DB    3Eh,36h,02h,0ECh,03h,31h,30h,31h,0C0h,3Dh,02h,25h,0E8h,00h,0ECh,03h
ROOM_06:                 ; 28DC, 131 bytes
        DB    02h,0C5h,04h,43h,68h,27h,0Fh,40h,70h,41h,40h,79h,51h,40h,83h,41h
        DB    40h,0C1h,41h,40h,0C9h,11h,40h,0CDh,11h,40h,0D2h,41h,80h,12h,41h,80h
        DB    21h,41h,80h,63h,41h,80h,70h,41h,80h,0B4h,0F1h,0C0h,05h,0D1h,0C0h,56h
        DB    20h,0C0h,5Fh,20h,80h,0EFh,64h,08h,13h,0Bh,58h,8Bh,0Eh,0A6h,0BBh,0E5h
        DB    18h,40h,0F1h,10h,40h,0F5h,10h,5Eh,0F1h,02h,5Eh,0F5h,02h,9Fh,19h,02h
        DB    9Fh,1Dh,02h,0DEh,7Eh,03h,0DEh,87h,03h,9Fh,41h,02h,9Fh,45h,02h,0DFh
        DB    0A6h,03h,0DFh,0AFh,03h,0ACh,0EFh,3Dh,02h,00h,0EDh,03h,02h,0CAh,03h,0C0h
        DB    18h,11h,0E6h,18h,20h,0CCh,0D8h,5Bh,04h,3Dh,03h,00h,0CAh,03h,3Dh,04h
        DB    0Bh,0E8h,04h
ROOM_07:                 ; 295F, 9 bytes
        DB    3Eh,36h,02h,0ECh,03h,30h,50h,30h,0E0h
ROOM_08:                 ; 2968, 63 bytes
        DB    59h,6Bh,0Bh,29h,0D4h,29h,0DEh,26h,0D8h,28h,0E6h,28h,0EAh,03h,0A0h,00h
        DB    11h,0C3h,70h,27h,02h,0D8h,83h,03h,43h,71h,1Eh,00h,43h,0A0h,17h,0Bh
        DB    80h,0E0h,53h,47h,99h,08h,0ABh,0E5h,6Bh,0C1h,6Bh,0EAh,0ABh,13h,0ABh,3Ch
        DB    3Dh,02h,0C2h,83h,12h,26h,0D0h,00h,0D8h,11h,3Dh,03h,0D8h,83h,03h
ROOM_09:                 ; 29A7, 14 bytes
        DB    3Eh,4Ah,22h,0DEh,0Bh,0E6h,04h,0B2h,20h,3Dh,04h,0Bh,0D0h,04h
ROOM_10:                 ; 29B5, 12 bytes
        DB    43h,68h,27h,0Fh,20h,0D0h,20h,0E8h,33h,50h,31h,0C0h
ROOM_11:                 ; 29C1, 148 bytes
        DB    42h,68h,8Fh,40h,92h,6Ch,44h,92h,04h,8Ah,0Bh,0Ah,82h,87h,51h,82h
        DB    0D7h,40h,86h,87h,03h,9Ch,8Ah,02h,9Ch,0B1h,02h,9Ch,0D8h,02h,02h,0D5h
        DB    0Bh,0Ah,0D3h,0Bh,19h,0FFh,0Bh,03h,0ABh,1Ch,00h,0C3h,0A1h,1Eh,01h,0CCh
        DB    0A1h,16h,00h,37h,82h,08h,13h,04h,03h,0D9h,16h,05h,42h,0C9h,60h,41h
        DB    2Ah,14h,03h,47h,3Ch,03h,4Bh,2Fh,04h,24h,37h,64h,83h,42h,0F1h,36h
        DB    80h,19h,04h,58h,0CAh,07h,42h,0DFh,0Dh,80h,0A2h,42h,9Ch,7Bh,04h,82h
        DB    7Ah,00h,8Bh,0A2h,03h,0DCh,1Ah,05h,0D8h,1Bh,04h,4Dh,0FAh,05h,8Ch,51h
        DB    06h,8Dh,6Eh,07h,8Ch,0BFh,04h,0CDh,11h,04h,82h,6Dh,00h,5Ch,6Fh,02h
        DB    0ACh,0DBh,6Ch,96h,6Ch,0BDh,0ACh,95h,6Bh,3Bh,6Bh,64h,0B2h,24h,0B2h,09h
        DB    3Dh,04h,0B2h,0A3h
ROOM_12:                 ; 2A55, 28 bytes
        DB    43h,68h,27h,0Fh,02h,0A0h,34h,02h,0C3h,44h,04h,0A4h,03h,07h,0C0h,03h
        DB    08h,13h,09h,58h,7Bh,10h,20h,0CEh,20h,0E7h,0B2h,80h
ROOM_13:                 ; 2A71, 9 bytes
        DB    3Fh,02h,08h,13h,09h,3Dh,04h,30h,52h
ROOM_14:                 ; 2A7A, 6 bytes
        DB    3Eh,07h,30h,20h,30h,0A0h
ROOM_15:                 ; 2A80, 34 bytes
        DB    3Fh,29h,60h,0B0h,0A0h,03h,02h,13h,14h,00h,0DBh,13h,2Ch,0D0h,2Ch,0F7h
        DB    6Ch,1Eh,6Ch,45h,6Ch,0A3h,0ACh,6Bh,6Bh,0B3h,6Bh,0DCh,32h,0A0h,32h,0A2h
        DB    32h,18h
ROOM_16:                 ; 2AA2, 22 bytes
        DB    3Eh,06h,0A0h,0BBh,0E0h,18h,00h,0EDh,03h,3Dh,02h,0C2h,5Bh,13h,00h,0CAh
        DB    03h,3Dh,04h,0Bh,0E8h,04h
ROOM_17:                 ; 2AB8, 4 bytes
        DB    3Eh,0Ah,0B2h,0A0h
ROOM_18:                 ; 2ABC, 80 bytes
        DB    43h,68h,27h,0Fh,4Eh,70h,18h,41h,95h,1Dh,01h,5Eh,0E5h,1Eh,9Fh,0Dh
        DB    1Eh,9Fh,35h,1Eh,9Fh,5Eh,1Ch,9Fh,87h,1Ah,9Fh,0B0h,18h,9Fh,0DAh,13h
        DB    0DFh,05h,0Ch,0DFh,30h,08h,0DFh,5Ch,02h,82h,42h,50h,82h,6Ch,00h,82h
        DB    8Ch,20h,82h,99h,10h,82h,0DEh,20h,82h,0E7h,10h,0C2h,31h,00h,0C2h,36h
        DB    00h,1Ch,0A0h,28h,5Ch,6Dh,03h,5Ch,88h,03h,31h,10h,3Dh,04h,31h,0E0h
ROOM_19:                 ; 2B0C, 13 bytes
        DB    3Eh,07h,20h,0DCh,0Bh,0D6h,04h,21h,0D1h,24h,0CFh,32h,0D0h
ROOM_20:                 ; 2B19, 140 bytes
        DB    08h,13h,09h,03h,0A0h,00h,14h,43h,69h,01h,0Fh,40h,91h,13h,80h,59h
        DB    13h,43h,8Dh,02h,0Fh,40h,0B5h,13h,80h,7Dh,13h,0C3h,23h,21h,04h,5Ch
        DB    6Ah,01h,5Ch,8Dh,01h,9Ch,32h,01h,9Ch,55h,01h,0DEh,23h,22h,0DFh,4Bh
        DB    22h,0DFh,75h,1Eh,0DFh,0A0h,18h,0A5h,85h,0A4h,0A1h,60h,0C7h,60h,0CFh,4Eh
        DB    0C2h,02h,4Eh,0EAh,02h,4Eh,0D4h,02h,4Eh,0FCh,02h,4Eh,7Bh,02h,8Eh,43h
        DB    02h,8Eh,8Ah,02h,8Eh,0B2h,02h,0CEh,0Bh,02h,8Eh,9Ch,02h,8Eh,0C4h,02h
        DB    4Dh,6Bh,07h,8Dh,33h,07h,8Dh,0FBh,07h,4Ch,74h,07h,8Ch,3Ch,07h,0CCh
        DB    04h,07h,4Dh,7Dh,07h,8Dh,45h,07h,0CDh,0Dh,07h,4Ch,86h,07h,8Ch,4Eh
        DB    07h,0CCh,16h,07h,3Dh,03h,0B2h,60h,3Dh,04h,32h,0E0h
ROOM_21:                 ; 2BA5, 137 bytes
        DB    1Ch,0A0h,28h,5Ch,72h,0Dh,04h,60h,03h,07h,65h,03h,08h,13h,09h,42h
        DB    68h,2Fh,44h,6Bh,03h,02h,0A6h,20h,0Ah,0CFh,0Dh,82h,15h,0E0h,9Ch,15h
        DB    03h,9Ch,1Eh,04h,82h,41h,13h,0C2h,9Bh,0D1h,82h,0D6h,24h,82h,0B4h,25h
        DB    9Eh,0FBh,03h,0DEh,07h,02h,0DFh,23h,03h,0DFh,2Fh,02h,0C2h,73h,20h,0DFh
        DB    4Bh,03h,0DFh,57h,02h,0DFh,7Fh,02h,8Eh,61h,03h,82h,0E1h,56h,98h,0E3h
        DB    07h,82h,0E7h,40h,0C3h,0D7h,10h,00h,42h,87h,8Eh,40h,0AFh,5Bh,5Ch,87h
        DB    06h,0DEh,87h,0Eh,0DFh,0AFh,0Eh,59h,88h,0Bh,59h,8Bh,0Ah,0A8h,4Ah,0A9h
        DB    45h,0A2h,51h,22h,0CAh,60h,9Eh,60h,0A2h,6Ch,95h,6Ch,0BCh,0ACh,43h,0B2h
        DB    80h,32h,81h,30h,0A5h,3Dh,04h,30h,0F0h
ROOM_22:                 ; 2C2E, 83 bytes
        DB    03h,0A0h,27h,14h,1Ch,0A0h,28h,01h,0C8h,27h,03h,41h,91h,25h,03h,9Ch
        DB    32h,24h,80h,3Fh,70h,81h,59h,25h,03h,0C1h,21h,10h,00h,0C1h,36h,10h
        DB    00h,5Ch,71h,16h,08h,13h,09h,58h,6Fh,05h,58h,87h,05h,0D8h,0Bh,06h
        DB    59h,0CAh,07h,0DEh,4Ah,0Fh,0DEh,5Eh,10h,0DFh,73h,0Dh,0DFh,9Ch,0Bh,0DFh
        DB    88h,0Dh,0DFh,0B1h,0Bh,6Ch,91h,0ACh,59h,6Bh,0B6h,0ABh,7Eh,30h,0C6h,3Dh
        DB    04h,0B0h,0C0h
ROOM_23:                 ; 2C81, 20 bytes
        DB    3Eh,02h,6Ch,99h,6Bh,36h,0ABh,76h,6Bh,5Fh,6Bh,88h,71h,82h,31h,87h
        DB    3Dh,04h,30h,62h
ROOM_24:                 ; 2C95, 21 bytes
        DB    03h,0A0h,27h,14h,00h,0D8h,73h,1Dh,0B0h,08h,58h,7Bh,10h,22h,0D9h,22h
        DB    0DBh,22h,0DDh,32h,90h
ROOM_25:                 ; 2CAA, 10 bytes
        DB    3Eh,1Eh,08h,13h,09h,3Dh,03h,02h,0D6h,03h
ROOM_26:                 ; 2CB4, 166 bytes
        DB    23h,0CCh,5Ch,69h,09h,03h,0C8h,00h,13h,5Ch,8Bh,05h,5Ch,7Bh,02h,42h
        DB    8Fh,0Fh,83h,0F9h,25h,05h,0D8h,0Bh,06h,80h,0FBh,0D0h,0DEh,23h,02h,0DEh
        DB    26h,02h,0DEh,29h,02h,0DEh,2Ch,02h,0DEh,2Fh,02h,0DFh,4Ch,01h,0DFh,4Eh
        DB    02h,0DFh,51h,02h,0DFh,54h,02h,0DFh,57h,01h,0DFh,76h,02h,0DFh,79h,02h
        DB    0DFh,7Ch,02h,0DFh,9Eh,02h,0DFh,0A1h,02h,0DFh,0A4h,02h,0DEh,0Fh,04h,0DEh
        DB    15h,01h,0DEh,18h,02h,0DEh,1Ch,01h,0DFh,37h,04h,0DFh,3Dh,01h,0DFh,40h
        DB    02h,0DFh,44h,01h,0DFh,5Fh,04h,0DFh,65h,01h,0DFh,68h,02h,0DFh,6Ch,01h
        DB    0DFh,8Dh,01h,0DFh,90h,02h,0DFh,94h,01h,0DFh,0B8h,02h,5Ch,0BCh,01h,5Ch
        DB    0CFh,02h,5Ch,0ADh,02h,5Ch,0EAh,02h,5Ch,0FEh,01h,9Ch,16h,01h,9Ch,38h
        DB    02h,9Ch,38h,01h,9Ch,49h,02h,9Ch,7Bh,02h,9Ch,83h,02h,9Ch,9Eh,01h
        DB    9Ch,0B2h,01h,9Ch,0C6h,01h
ROOM_27:                 ; 2D5A, 12 bytes
        DB    3Eh,12h,02h,0BFh,00h,0Bh,0E7h,04h,21h,0E9h,32h,0A0h
ROOM_28:                 ; 2D66, 19 bytes
        DB    3Eh,0Ah,20h,0DDh,20h,0D5h,0Bh,0D2h,04h,0Bh,0DAh,04h,0Bh,0E2h,04h,33h
        DB    20h,33h,60h
ROOM_29:                 ; 2D79, 32 bytes
        DB    3Fh,15h,82h,16h,00h,4Eh,71h,08h,60h,0A3h,60h,0A6h,0A2h,35h,0A8h,3Eh
        DB    0ABh,44h,6Bh,0B2h,6Bh,0DBh,32h,0A1h,30h,95h,3Dh,04h,0B2h,10h,30h,70h
ROOM_30:                 ; 2D99, 15 bytes
        DB    3Eh,36h,02h,0D6h,03h,02h,0E2h,03h,23h,0DBh,3Dh,03h,00h,0D6h,03h
ROOM_31:                 ; 2DA8, 16 bytes
        DB    3Eh,1Ah,02h,0C7h,04h,08h,13h,09h,20h,0CAh,20h,0CDh,22h,0EBh,22h,0EDh
ROOM_32:                 ; 2DB8, 6 bytes
        DB    3Eh,0Dh,30h,70h,32h,62h
ROOM_33:                 ; 2DBE, 86 bytes
        DB    43h,68h,27h,00h,5Ch,6Bh,20h,42h,90h,09h,42h,0B7h,09h,44h,91h,02h
        DB    47h,0B4h,03h,9Ch,64h,10h,8Dh,67h,04h,8Dh,6Dh,04h,08h,13h,09h,58h
        DB    74h,06h,58h,82h,06h,98h,6Bh,03h,8Fh,0D1h,06h,8Fh,0F0h,07h,8Eh,0D2h
        DB    04h,8Eh,0F1h,05h,9Ch,0D7h,19h,82h,0DBh,00h,82h,0EBh,00h,0C3h,20h,27h
        DB    04h,0C1h,23h,21h,00h,0C1h,4Dh,1Dh,01h,0D8h,0ABh,02h,64h,0C8h,64h,0CEh
        DB    0E8h,03h,0E8h,13h,0B2h,00h
ROOM_34:                 ; 2E14, 2 bytes
        DB    3Eh,07h
ROOM_35:                 ; 2E16, 8 bytes
        DB    3Eh,18h,30h,0A0h,20h,0D9h,20h,0DEh
ROOM_36:                 ; 2E1E, 71 bytes
        DB    03h,0A0h,27h,14h,01h,0CEh,1Bh,03h,41h,91h,25h,03h,81h,59h,25h,03h
        DB    0C1h,21h,25h,03h,0C2h,0AAh,31h,5Ch,69h,26h,9Ch,31h,26h,9Ch,0F9h,26h
        DB    08h,13h,09h,58h,6Fh,05h,58h,86h,05h,98h,42h,05h,98h,0FFh,05h,0D8h
        DB    16h,05h,0D8h,0ABh,02h,0A0h,70h,31h,30h,71h,42h,31h,0C6h,71h,0CAh,3Dh
        DB    04h,0Bh,0D8h,04h,0Bh,0DEh,04h
ROOM_37:                 ; 2E65, 14 bytes
        DB    3Eh,16h,02h,0A0h,04h,02h,0C7h,04h,33h,80h,33h,86h,33h,0D6h
ROOM_38:                 ; 2E73, 13 bytes
        DB    3Eh,25h,00h,0EFh,03h,0B2h,80h,0B2h,32h,0B2h,0D2h,0B2h,0D6h
ROOM_39:                 ; 2E80, 6 bytes
        DB    3Eh,12h,30h,20h,30h,0C0h
ROOM_40:                 ; 2E86, 6 bytes
        DB    3Eh,0Ah,33h,00h,33h,0E0h
ROOM_41:                 ; 2E8C, 198 bytes
        DB    1Ch,0A0h,1Fh,42h,68h,4Fh,80h,09h,36h,44h,69h,04h,99h,5Ch,03h,99h
        DB    0Fh,03h,0C3h,75h,22h,02h,0D8h,83h,03h,08h,13h,09h,0DEh,4Dh,02h,0DEh
        DB    78h,02h,0DEh,7Bh,02h,0DEh,56h,02h,0DFh,75h,02h,0DFh,0A0h,02h,0DFh,0A3h
        DB    02h,0DFh,7Eh,02h,82h,0FFh,02h,82h,0DAh,03h,0C2h,05h,02h,0CEh,50h,02h
        DB    0CEh,53h,02h,42h,73h,98h,5Ch,74h,09h,4Ch,6Dh,07h,0CDh,30h,03h,40h
        DB    9Bh,0A3h,9Ch,3Bh,0Ah,80h,63h,92h,58h,77h,05h,07h,0BFh,09h,82h,2Fh
        DB    08h,82h,52h,41h,98h,53h,06h,82h,79h,01h,82h,45h,0B3h,9Eh,4Ah,08h
        DB    9Fh,46h,04h,9Fh,6Fh,0Ah,9Fh,98h,08h,42h,7Dh,34h,40h,0A6h,10h,40h
        DB    0D0h,00h,5Eh,0CEh,02h,5Eh,0F8h,01h,5Fh,0F6h,02h,9Fh,1Eh,03h,42h,0A9h
        DB    01h,42h,0D2h,01h,42h,0FBh,01h,82h,24h,10h,40h,0F9h,00h,80h,22h,00h
        DB    9Eh,21h,01h,42h,7Ch,00h,82h,44h,00h,0A0h,0Ch,60h,0BFh,6Ch,94h,6Ch
        DB    0BBh,6Bh,39h,6Bh,62h,6Bh,0A4h,0ABh,6Ch,6Bh,8Bh,32h,70h,30h,72h,30h
        DB    0F8h,3Dh,04h,02h,0B5h,04h
ROOM_42:                 ; 2F52, 9 bytes
        DB    3Eh,4Ah,02h,0C8h,03h,32h,00h,33h,0D0h
ROOM_43:                 ; 2F5B, 6 bytes
        DB    3Fh,2Ah,0B2h,0D0h,71h,50h
ROOM_44:                 ; 2F61, 20 bytes
        DB    3Fh,15h,03h,0B7h,10h,14h,00h,0DFh,02h,02h,0A0h,24h,30h,00h,32h,65h
        DB    3Dh,04h,32h,91h
ROOM_45:                 ; 2F75, 19 bytes
        DB    3Eh,2Eh,02h,0A0h,0A4h,28h,0D6h,28h,0E0h,0E8h,07h,0E8h,10h,65h,0C8h,65h
        DB    0CEh,0B2h,83h
ROOM_46:                 ; 2F88, 24 bytes
        DB    3Eh,32h,29h,0D6h,29h,0E0h,0E9h,07h,0E9h,10h,64h,0C8h,64h,0CEh,82h,0DFh
        DB    00h,82h,0E8h,00h,32h,00h,32h,89h
ROOM_47:                 ; 2FA0, 11 bytes
        DB    3Eh,0Ah,02h,0B8h,0F4h,22h,0D9h,20h,0DCh,0B2h,20h
ROOM_48:                 ; 2FAB, 11 bytes
        DB    3Eh,36h,02h,0A0h,04h,29h,0E6h,3Dh,04h,30h,40h
ROOM_49:                 ; 2FB6, 7 bytes
        DB    3Eh,3Dh,08h,13h,09h,0B0h,50h
ROOM_50:                 ; 2FBD, 15 bytes
        DB    3Eh,21h,66h,0CBh,9Ch,0D7h,19h,32h,55h,0B2h,83h,3Dh,04h,30h,59h
ROOM_51:                 ; 2FCC, 9 bytes
        DB    3Eh,2Ch,00h,0C8h,23h,3Dh,04h,30h,10h
ROOM_52:                 ; 2FD5, 26 bytes
        DB    3Fh,29h,60h,0CCh,32h,0A0h,32h,0A2h,32h,08h,2Ch,0D0h,2Ch,0F7h,6Ch,1Eh
        DB    6Ch,45h,6Ch,0A3h,0ACh,6Bh,6Bh,0B3h,6Bh,0DCh
ROOM_53:                 ; 2FEF, 4 bytes
        DB    3Eh,12h,30h,50h
ROOM_54:                 ; 2FF3, 9 bytes
        DB    3Eh,0Ah,58h,7Bh,10h,32h,70h,32h,60h
ROOM_55:                 ; 2FFC, 9 bytes
        DB    3Eh,4Ah,02h,0E2h,03h,0B0h,40h,30h,90h
ROOM_56:                 ; 3005, 4 bytes
        DB    3Eh,30h,0B0h,50h
ROOM_57:                 ; 3009, 4 bytes
        DB    3Eh,0Ah,30h,50h
ROOM_58:                 ; 300D, 18 bytes
        DB    3Eh,32h,64h,0C8h,64h,0CEh,0E8h,00h,0E8h,16h,82h,0D8h,00h,82h,0EEh,00h
        DB    32h,59h
ROOM_59:                 ; 301F, 26 bytes
        DB    3Eh,32h,28h,0D6h,28h,0E0h,25h,0D9h,25h,0DDh,0E5h,09h,0E5h,0Dh,65h,0C8h
        DB    65h,0CEh,32h,0D0h,0B2h,55h,32h,83h,32h,0D9h
ROOM_60:                 ; 3039, 18 bytes
        DB    3Eh,3Ah,29h,0D6h,29h,0E0h,0E9h,00h,0E9h,16h,64h,0C8h,64h,0CEh,0B2h,83h
        DB    32h,59h
ROOM_61:                 ; 304B, 25 bytes
        DB    43h,68h,27h,0Fh,40h,9Fh,93h,5Ch,77h,0Ah,58h,78h,05h,58h,7Eh,05h
        DB    98h,43h,0Bh,31h,0C0h,3Dh,04h,0B0h,50h
ROOM_62:                 ; 3064, 14 bytes
        DB    3Eh,07h,3Dh,04h,0Bh,0D0h,04h,0Bh,0D4h,04h,31h,30h,30h,0D0h
ROOM_63:                 ; 3072, 15 bytes
        DB    3Eh,12h,02h,0A0h,14h,23h,0CBh,21h,0E9h,21h,0CEh,32h,0A0h,33h,0A0h
ROOM_64:                 ; 3081, 10 bytes
        DB    3Fh,26h,0B2h,40h,0B2h,12h,0B2h,0C2h,0B2h,46h
ROOM_65:                 ; 308B, 23 bytes
        DB    3Eh,15h,02h,0DFh,04h,0A2h,51h,60h,9Eh,60h,0A2h,6Ch,95h,6Ch,0BCh,0ACh
        DB    43h,0B2h,80h,32h,81h,30h,0A5h
ROOM_66:                 ; 30A2, 39 bytes
        DB    3Eh,04h,0C0h,2Fh,03h,0C2h,0Fh,20h,0A5h,6Ah,32h,10h,30h,3Ah,0E0h,3Bh
        DB    0CBh,37h,04h,0CBh,38h,04h,0CBh,39h,04h,80h,03h,22h,80h,67h,12h,0A7h
        DB    8Fh,32h,0F3h,3Dh,04h,30h,0F0h
ROOM_67:                 ; 30C9, 12 bytes
        DB    3Eh,16h,0B2h,10h,3Dh,04h,0B2h,32h,0B2h,0D2h,0B2h,0D6h
ROOM_68:                 ; 30D5, 17 bytes
        DB    3Eh,4Ah,0Bh,0D8h,04h,0Bh,0D4h,04h,30h,10h,30h,30h,3Dh,04h,02h,0C4h
        DB    14h
ROOM_69:                 ; 30E6, 6 bytes
        DB    3Eh,36h,0B3h,0A0h,33h,30h
ROOM_70:                 ; 30EC, 32 bytes
        DB    3Eh,01h,08h,13h,06h,66h,0BCh,40h,0B1h,31h,67h,0B1h,67h,0B3h,2Bh,66h
        DB    2Bh,0B8h,2Ch,0B0h,6Ch,0BAh,6Ch,0ACh,6Bh,0D2h,30h,10h,3Dh,04h,30h,0D0h
ROOM_71:                 ; 310C, 36 bytes
        DB    3Eh,62h,02h,0EEh,03h,20h,0E2h,20h,0E6h,23h,0EAh,0B0h,0A0h,32h,50h,3Dh
        DB    02h,02h,0A0h,24h,00h,0E2h,0D3h,23h,0DAh,20h,0CCh,20h,0D0h,20h,0D4h,3Dh
        DB    03h,00h,0C8h,0D3h
ROOM_72:                 ; 3130, 28 bytes
        DB    3Eh,0Ah,08h,13h,09h,41h,6Bh,21h,04h,4Eh,6Bh,22h,5Eh,0BBh,22h,5Fh
        DB    0E3h,22h,9Fh,0Bh,22h,42h,7Ah,34h,32h,30h,32h,0A0h
ROOM_73:                 ; 314C, 6 bytes
        DB    3Eh,0Ah,33h,30h,33h,0A0h
ROOM_74:                 ; 3152, 9 bytes
        DB    3Eh,0Ah,08h,13h,09h,31h,70h,71h,0A0h
ROOM_75:                 ; 315B, 15 bytes
        DB    3Eh,32h,0C2h,0ABh,11h,28h,0D6h,28h,0E0h,66h,0C9h,64h,0CDh,0B2h,55h
ROOM_76:                 ; 316A, 24 bytes
        DB    3Eh,32h,28h,0D6h,28h,0E0h,64h,0C9h,65h,0CDh,0A9h,0FFh,0E9h,17h,82h,0D7h
        DB    00h,82h,0EFh,00h,32h,00h,0B2h,83h
ROOM_77:                 ; 3182, 6 bytes
        DB    3Eh,44h,30h,10h,30h,40h
ROOM_78:                 ; 3188, 9 bytes
        DB    3Eh,31h,0B0h,50h,3Dh,04h,0Bh,0D2h,04h
ROOM_79:                 ; 3191, 2 bytes
        DB    3Eh,07h
ROOM_80:                 ; 3193, 21 bytes
        DB    3Fh,62h,20h,0CBh,20h,0CEh,20h,0D1h,0B2h,0A0h,3Dh,04h,0Bh,0D4h,04h,0Bh
        DB    0D6h,04h,0Bh,0D8h,04h
ROOM_81:                 ; 31A8, 6 bytes
        DB    3Eh,0Ah,30h,80h,71h,0C0h
ROOM_82:                 ; 31AE, 29 bytes
        DB    3Eh,29h,0A0h,0E8h,0A2h,0ECh,0C2h,83h,12h,6Ch,94h,6Ch,0BBh,6Bh,39h,6Bh
        DB    62h,6Bh,8Bh,6Bh,0A4h,0ABh,6Ch,30h,0A8h,3Dh,04h,30h,72h
ROOM_83:                 ; 31CB, 6 bytes
        DB    3Eh,2Ah,32h,20h,32h,30h
ROOM_84:                 ; 31D1, 14 bytes
        DB    3Eh,12h,71h,0E0h,3Dh,04h,02h,0B3h,00h,0Bh,0DBh,04h,31h,10h
ROOM_85:                 ; 31DF, 4 bytes
        DB    3Eh,4Ah,0B2h,30h
ROOM_86:                 ; 31E3, 68 bytes
        DB    43h,68h,27h,0Fh,02h,0A8h,40h,02h,0AEh,0A0h,02h,0BAh,40h,0Bh,0D0h,04h
        DB    0Bh,0D1h,04h,0Bh,0D2h,04h,0Bh,0D3h,04h,0Bh,0D7h,04h,0Bh,0D8h,04h,0Bh
        DB    0D9h,04h,0Bh,0DAh,04h,0Bh,0DBh,04h,0Bh,0DCh,04h,0Bh,0DDh,04h,0Bh,0DEh
        DB    04h,0Bh,0DFh,04h,0Bh,0E3h,04h,0Bh,0E4h,04h,0Bh,0E5h,04h,0Bh,0E6h,04h
        DB    3Dh,04h,32h,50h
ROOM_87:                 ; 3227, 15 bytes
        DB    3Eh,12h,08h,13h,09h,02h,0AEh,00h,02h,0B9h,00h,2Ah,0D6h,2Ah,0E1h
ROOM_88:                 ; 3236, 21 bytes
        DB    3Fh,5Ah,42h,8Bh,00h,2Ah,0EBh,6Ah,0B3h,0A6h,6Fh,3Dh,03h,32h,50h,32h
        DB    36h,3Dh,04h,0B0h,0C2h
ROOM_89:                 ; 324B, 91 bytes
        DB    0C2h,17h,80h,82h,0F8h,80h,82h,50h,70h,82h,30h,70h,42h,8Ch,30h,42h
        DB    68h,30h,07h,0A9h,0Bh,04h,0B4h,0Bh,0DEh,20h,09h,0DEh,3Fh,09h,0DEh,51h
        DB    01h,0DEh,7Ah,01h,0DEh,0A3h,01h,0DEh,0CCh,01h,0DEh,66h,01h,0DEh,8Dh,01h
        DB    0DEh,0B4h,01h,0DEh,0DBh,01h,0DFh,48h,09h,0DFh,67h,13h,0DFh,8Eh,15h,0DFh
        DB    0B5h,17h,0DFh,0DCh,0Ch,0A0h,6Bh,0A0h,0BBh,0E0h,0Bh,0E0h,5Bh,0E0h,0ABh,0A0h
        DB    0B5h,0A0h,0C1h,0E0h,07h,0E0h,0Fh,0E0h,59h,0E0h,5Dh
ROOM_90:                 ; 32A6, 81 bytes
        DB    03h,0C8h,27h,13h,01h,0C8h,27h,03h,41h,90h,23h,03h,81h,58h,22h,03h
        DB    5Ch,6Bh,1Fh,9Ch,33h,1Dh,9Ch,0FBh,1Bh,0DEh,20h,1Fh,0C7h,40h,03h,0DFh
        DB    48h,21h,0DFh,70h,22h,0DFh,98h,23h,58h,72h,05h,98h,4Ch,05h,47h,0B3h
        DB    02h,87h,7Ah,02h,82h,58h,23h,82h,48h,00h,8Bh,70h,04h,8Eh,0FEh,13h
        DB    0A6h,67h,2Ah,0CCh,42h,6Ch,00h,6Ah,94h,28h,0EAh,29h,0E4h,3Dh,03h,0B0h
        DB    50h
ROOM_91:                 ; 32F7, 8 bytes
        DB    3Eh,12h,71h,90h,3Dh,04h,0B0h,30h
ROOM_92:                 ; 32FF, 12 bytes
        DB    3Eh,12h,71h,90h,20h,0D8h,20h,0DCh,3Dh,04h,0B0h,0C0h
ROOM_93:                 ; 330B, 6 bytes
        DB    3Eh,56h,3Dh,04h,30h,50h
ROOM_94:                 ; 3311, 6 bytes
        DB    3Eh,09h,2Ah,0D6h,2Ah,0E0h
ROOM_95:                 ; 3317, 4 bytes
        DB    3Eh,12h,0B2h,40h
ROOM_96:                 ; 331B, 48 bytes
        DB    3Eh,12h,08h,13h,09h,03h,0B8h,0Fh,0Fh,02h,0AEh,00h,82h,6Dh,26h,82h
        DB    0E4h,00h,0C2h,0Bh,10h,0C2h,2Fh,51h,0C2h,06h,20h,82h,0B4h,20h,9Fh,8Ch
        DB    03h,9Fh,0DEh,03h,0DFh,2Dh,02h,0B2h,20h,0B2h,30h,3Dh,04h,0Bh,0D6h,04h
ROOM_97:                 ; 334B, 6 bytes
        DB    3Fh,60h,0F0h,0A0h,30h,0F0h
ROOM_98:                 ; 3351, 17 bytes
        DB    3Eh,0Ah,02h,0C7h,04h,20h,0E6h,20h,0E9h,20h,0ECh,22h,0DDh,22h,0E0h,22h
        DB    0E3h
;-----------------------------------------------------------------------
; TREASURE, TITLE-SCREEN BYTE CODE AND THE FLOOR-SPAN BUFFER  (3362..369F, 830 bytes)
;
; TREASR reads three pieces out of here: the TRSMAP geometry through a
; 36-byte window with a stride of 12, the TRSGEM treasures through a
; window of varying length with a stride of 6, and one of two exit commands.
; TTLROOM builds the title screen from TTLMAP; after that comes SOLIDS, the current room's floor-span list, built by MKSOLD.
;-----------------------------------------------------------------------
; treasure chamber geometry: 8 windows of 12 entries, overlapping
TRSMAP  DB    09h,0AAh,03h,49h,6Dh,05h,49h,0EAh,04h,0C9h,4Fh,04h,09h,0B0h,10h,49h       ; 3362  ...Im.I...O....I
        DB    58h,05h,89h,99h,04h,0C9h,86h,02h,0C9h,40h,03h,09h,0E4h,06h,49h,60h        ; 3372  X........@....I`
        DB    07h,49h,64h,0Ch,09h,0CDh,05h,09h,0F4h,0Ah,49h,21h,05h,89h,0FCh,04h        ; 3382  .Id.......I!....
        DB    49h,74h,03h,09h,0B2h,06h,49h,0F4h,07h,89h,48h,07h,09h,0BCh,08h,0C9h       ; 3392  It....I...H.....
        DB    14h,05h,09h,0E9h,0Fh,49h,3Eh,0Bh,09h,0CBh,0Ah,09h,0F8h,09h,49h,4Bh        ; 33A2  .....I>.......IK
        DB    0Ch,0C9h,50h,03h,49h,26h,10h,0C9h,0Ah,05h,49h,0F8h,0Ch,49h,0ABh,0Bh       ; 33B2  ..P.I&....I..I..
        DB    49h,5Fh,07h,09h,0E8h,06h,0C9h,42h,04h,09h,0ECh,07h,89h,31h,0Ah,49h        ; 33C2  I_.....B.....1.I
        DB    1Eh,09h,49h,21h,04h,89h,89h,08h,09h,0D4h,07h,09h,0B1h,10h,0C9h,0Ch        ; 33D2  ..I!............
        DB    05h,49h,59h,09h,49h,0Fh,06h,89h,9Fh,08h,89h,02h,0Ch,49h,8Eh,0Dh           ; 33E2  .IY.I........I..
; treasures: 16 windows, window length depends on the level
TRSGEM  DB    20h,0F5h,0A0h,0D4h,20h,0A8h,60h,72h,0A0h,0D8h,60h,0F2h,0A0h,0E2h,0E0h,2Ch ; 33F2   ... .`r..`....,
        DB    0E0h,89h,20h,0B3h,0A0h,9Eh,60h,0B2h,0E0h,42h,60h,5Eh,20h,0C2h,0A0h,0Fh    ; 3402  .. ...`..B`^ ...
        DB    0A0h,0FEh,20h,0D2h,0E0h,0A0h,0A0h,8Ah,60h,4Dh,0A0h,0DFh,60h,0F8h,0E0h,11h ; 3412  .. .....`M..`...
        DB    60h,08h,0E0h,90h,60h,89h,0A0h,0A1h,60h,34h,0A0h,4Eh,60h,93h,60h,45h       ; 3422  `...`...`4.N`.`E
        DB    0A0h,0D6h,60h,0C2h,0E0h,9Dh,0A0h,3Ch,60h,0CBh,20h,0DCh,0E0h,0Fh,0E0h,30h  ; 3432  ..`....<`. ....0
        DB    60h,84h,60h,0FCh,60h,62h,0A0h,0A3h,20h,0E9h,0A0h,5Bh,20h,0CDh,0A0h,0FFh   ; 3442  `.`.`b.. ..[ ...
        DB    0A0h,38h,0E0h,74h,0A0h,40h,60h,0A3h,0A0h,44h,0A0h,0E4h,20h,0DCh,60h,5Eh   ; 3452  .8.t.@`..D.. .`^
        DB    0E0h,8Fh,60h,3Bh,0A0h,7Bh,0A0h,0EFh                                       ; 3462  ..`;.{..
; exit from the treasure chamber on the left
TRSDRL  DB    0Ah,01h,19h                                                               ; 346A  ...
; exit from the treasure chamber on the right
TRSDRR  DB    0Ah,26h,19h                                                               ; 346D  .&.
; title screen byte code: BLDMAP runs from TTLMAP to TTLEND
TTLMAP  DB    0Ah,01h,17h,0Ah,26h,17h,82h,58h,07h,82h,7Fh,07h,82h,0DEh,0C1h,0C3h        ; 3470  ....&..X........
        DB    2Ch,10h,01h,0C3h,75h,1Dh,00h,0C3h,98h,27h,01h,80h,0E3h,26h,9Ch,0E3h       ; 3480  ,...u....'...&..
        DB    03h,99h,0E4h,07h,0CDh,3Dh,08h,0CEh,23h,09h                                ; 3490  .....=..#.
TTLEND  DB    00h,00h,00h,00h,00h,00h                                                   ; 349A  ......
; floor-span list: {row, column, height, width} for every run
SOLIDS  DB    512 DUP (0)                                                               ; 34A0..369F
CSEG    ENDS
        END
