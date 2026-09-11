;=======================================================================
; MX4C.INC -- macros, named constants, structures.
;=======================================================================

; Save and restore the registers listed in <regs>
; The register list comes in as one parameter in angle brackets;
; IRP unrolls it.
SAVEREG MACRO   regs
        IRP     r,<regs>
        push    r
        ENDM
        ENDM

RESTREG MACRO   regs
        IRP     r,<regs>
        pop     r
        ENDM
        ENDM

; Save and restore 7 registers
SAVEALL MACRO
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp
        ENDM

RESTALL MACRO
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ENDM

; Save and restore 7 registers plus ES
SAVEALE MACRO
        SAVEALL             ;  macro
        push    es
        ENDM

RESTALE MACRO
        pop     es
        RESTALL             ;  macro
        ENDM

; Save and restore 8 registers
SAVEAL8 MACRO
        push    ax
        push    bx
        push    cx
        push    dx
        push    es
        push    si
        push    di
        push    bp
        ENDM

RESTAL8 MACRO
        pop     bp
        pop     di
        pop     si
        pop     es
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ENDM

; Call the map window output. The PUSH order is the reverse of the
; argument order: the last PUSH lands at the lower address and is read as SS:[SP+16h].
DRAWMAP MACRO map,tiles,row,col,nrows,ncols
        mov     ax,map
        push    ax
        mov     ax,tiles
        push    ax
        mov     ax,row
        push    ax
        mov     ax,col
        push    ax
        mov     ax,nrows
        push    ax
        mov     ax,ncols
        push    ax
        int     67h
        add     sp,12
        ENDM

; One record of a tune. The stride of a note is THREE bytes: the code
; reads mov cx,[bx+2] as a word but uses only CL, so the high byte of
; the duration already belongs to the record that follows.
NOTE    MACRO div,dur
        DW    div
        DB    dur
        ENDM

;-----------------------------------------------------------------------
; NAMED CONSTANTS
;
; Only the ones the code actually refers to are declared here. Tile,
; element and key codes follow below as reference tables: name, value,
; meaning.
;-----------------------------------------------------------------------
; --- HARDWARE ---
PORT20       EQU 0020h      ; the 8259 interrupt controller
PORT21       EQU 0021h      ; IRQ mask
PORT40       EQU 0040h      ; PIT channel 0
PORT42       EQU 0042h      ; PIT channel 2, the speaker tone
PORT43       EQU 0043h      ; PIT, control register
PORT61       EQU 0061h      ; port B: bits 0-1 = the speaker gate and data
PORT201      EQU 0201h      ; joystick port: fires the one-shots and reads the axes
PORT3F2      EQU 03F2h      ; floppy drive motor control
; PIT_CLK      = 1193182    input frequency of the PIT, Hz
PIT_DIV      EQU 2E9Ch      ; divisor that gives 100 Hz
PIT_M3       EQU 36h        ; channel 0, mode 3, write both bytes
SPK_BITS     EQU 3          ; turn on the speaker gate and data together
FDC_OFF      EQU 0C0h       ; shut the floppy drive motor down
; --- VIDEO ---
VMODE_CGA    EQU 4          ; mode 4: 320x200, 4 colors
VRAM_SEG     EQU 0B800h     ; segment of CGA video RAM
FIELD_ODD    EQU 2000h      ; offset of the odd field
BYTES_ROW    EQU 50h        ; 80 bytes to a scan line
FLD_ROW      EQU 28h        ; 40 bytes to a line of one field
TILE_ROW     EQU 140h       ; 8 scan lines: one tile row in video RAM
TILE_SZ      EQU 10h        ; bytes to an 8x8 tile at 2 bits per pixel
MAP_W        EQU 28h        ; map width in tiles = 40
MAP_H        EQU 19h        ; map height in tiles = 25
MAP_SZ       EQU 3E8h       ; MAP_W*MAP_H = 1000 cells of the map
HUD_CELLS    EQU 0C8h       ; 5 panel rows of MAP_W = 200 cells
; HUD_ROWS     = 5          rows in the status panel
; --- TUNE ---
SND_REST     EQU 0          ; a rest of the stated length
SND_SWEEP    EQU 1          ; frequency sweep
SND_END      EQU 0FFFFh     ; end of the tune
; --- VECTORS OF OUR OWN INTERRUPTS ---
VEC08        EQU 8*4        ; INT 08h: the system timer tick
VEC62        EQU 62h*4      ; INT 62h: the sound API
VEC67        EQU 67h*4      ; INT 67h: tile map output
; --- THE CONTROL COMMAND ---
; CMDBITS: AH -- direction, AL -- the button byte off port 201h.
; A button reads active low: bit 4 clear -- held down, set -- released.
DIR_DN       EQU 1          ; bit 0 of AH: down
DIR_UP       EQU 2          ; bit 1 of AH: up
DIR_LF       EQU 4          ; bit 2 of AH: left
DIR_RT       EQU 8          ; bit 3 of AH: right
BTN_JUMP     EQU 10h        ; bit 4 of AL: the jump button, 0 = held down
; --- SCAN CODES ---
KEY_ENTER    EQU 0Dh        ; start the game from the menu
KEY_F1       EQU 3B00h      ; keyboard / joystick
KEY_F2       EQU 3C00h      ; game level 1-2-3
KEY_F3       EQU 3D00h      ; define keys
; KEY_F4       = 3E00h      pause (never used)
KEY_F5       EQU 3F00h      ; back to the menu
KEY_F7       EQU 4100h      ; reset game (never used)
KEY_F10      EQU 4400h      ; pause

;-----------------------------------------------------------------------
; GLOBAL VARIABLES -- THE DIRECTORY
;
; The variables are declared as labels where they lie. Below: name,
; address, module and what each one is for.
;-----------------------------------------------------------------------
; STKTOP    301h    BOOT.ASM     top of the stack, SP at startup
; FRAMEC    3CFh    BOOT.ASM     frame counter, +1 for every pass of the main loop
; LASTKEY   3D0h    BOOT.ASM     scan code of the last key pressed
; SNDFRQ    3D2h    BOOT.ASM     current PIT divisor for channel 2
; SNDTCK    3D4h    BOOT.ASM     ticks until the next record of the tune
; SNDPTR    3D5h    BOOT.ASM     read offset within the tune
; SNDSEG    3D7h    BOOT.ASM     segment of the tune
; SNDACT    3D9h    BOOT.ASM     1 = a sound is playing
; OLDT08O   3DAh    BOOT.ASM     saved INT 08h vector, offset
; OLDT08S   3DCh    BOOT.ASM     saved INT 08h vector, segment
; SNDRPF    3DEh    BOOT.ASM     1 = a frequency sweep is running
; SNDRPC    3E0h    BOOT.ASM     how many sweep steps are left
; OBJFRM    6E0h    ROOMBLD.ASM  frame for every type of room object, 4 words
; OBJALN    6F0h    ROOMBLD.ASM  object type -> last frame number of the chain, 4 words
; OBJTBL    6FAh    ROOMBLD.ASM  array of objects, 6 bytes per object, object 0 = the player
; PLR_X     6FCh    ROOMBLD.ASM  object 0, field +2: X in bytes of video RAM (0..79)
; PLR_Y     6FDh    ROOMBLD.ASM  object 0, field +3: Y in lines; bit 0 = field
; PLR_W     6FEh    ROOMBLD.ASM  object 0, field +4: width in bytes
; PLR_H     6FFh    ROOMBLD.ASM  object 0, field +5: height in lines
; OBJDY     744h    ROOMBLD.ASM  object type -> Y correction in lines, 4 bytes
; OBJBIT    748h    ROOMBLD.ASM  object -> bit number within SEENMAP, one byte each
; OBJTYP    7ACh    ROOMBLD.ASM  type of the object being worked on (index into JMPTBL)
; OBJKND    7ADh    ROOMBLD.ASM  the "object -> behavior type" table, one byte each
; FARPTR    7B5h    ROOMBLD.ASM  far jump address: PRIMJMP builds it, JMP DWORD PTR reads it
; FARPTRS   7B7h    ROOMBLD.ASM  high word of FARPTR: segment of the jump
; VXTAB     7B9h    ROOMBLD.ASM  object subtype -> starting OBJVX, 4 bytes
; DARKF     7BDh    ROOMBLD.ASM  0F0h = the room is dark. LITCHK sets it, PLRHIT reads it
; MUSSEL    7BEh    ROOMBLD.ASM  pick of the background tune: (AL and 3) -> MUSTAB
; MUSTAB    7BFh    ROOMBLD.ASM  tune numbers for the three levels: 10, 9, 8, 10
; PRIMTAB   B5Fh    ROOMBLD.ASM  table of the eight drawing primitives
; ROOMNO    1090h   SCRDAT.ASM   number of the current room, 0..98
; LEVEL     1091h   SCRDAT.ASM   difficulty level picked by the player, 1..3 (the F2 key)
; ROOMRQ    1092h   SCRDAT.ASM   room asked for (the one being moved into)
; RDPTR     1093h   SCRDAT.ASM   read pointer into the room description
; ENDPTR    1095h   SCRDAT.ASM   end of the description = start of the next room
; CALLDEP   1097h   SCRDAT.ASM   nesting depth of fragments
; MIRFLAG   1098h   SCRDAT.ASM   the fragment goes in mirrored
; CMDOP     1099h   SCRDAT.ASM   opcode of the current description command
; CMDX      109Ah   SCRDAT.ASM   offset within the map page
; CMDP1     109Bh   SCRDAT.ASM   first parameter of the command
; CMDP2     109Ch   SCRDAT.ASM   second parameter of the command
; ELMCUR    109Dh   SCRDAT.ASM   element code for the current command
; PATLEFT   10A4h   SCRDAT.ASM   pattern tiles left before the repeat (primitive 7)
; PATLEN    10A5h   SCRDAT.ASM   pattern length for primitive 7
; FLOOR     10A6h   SCRDAT.ASM   floor of the pyramid, 0..10, index into ROOMBAS
; ROOMPOS   10A7h   SCRDAT.ASM   position of the room on its floor
; LITMSK    10A8h   SCRDAT.ASM   lighting mask: 0FFh lit, 0F0h dark. LITCHK and PUT2X2 write it
; INBITS    10A9h   SCRDAT.ASM   one bit per object: 1 = live, bit 0 is the player
; SEENMAP   10AAh   SCRDAT.ASM   what has been picked up and killed: bit per object, 2 bytes per room
; ROOMOBJ   1174h   SCRDAT.ASM   offsets of this room's objects within SCRMAP, one word each
; ROOMKND   1194h   SCRDAT.ASM   kind of each room object, one byte each, parallel to ROOMOBJ
; ROWBUF    11A5h   SCRDAT.ASM   buffer for one map row, 40 bytes (used when mirroring)
; SCRMAP    11CDh   SCRDAT.ASM   screen map 40x25 = 1000 bytes, built while the game runs
; TILES     15B5h   SCRDAT.ASM   tile table, 235 of them at 16 bytes apiece
; MIRSRC    2465h   SCRDAT.ASM   codes of the tiles that need swapping when mirroring
; MIRDST    246Fh   SCRDAT.ASM   what to swap them for; pairs 28/29, 2A/2B, 72..77
; BARTIL    2479h   SCRDAT.ASM   "GAME OVER" spelled in tiles, 2 rows of 12h, laid down by PUTBAR
; ELMTAB    249Dh   SCRDAT.ASM   ribbon of tiles: an element code is an offset, records overlap
; DIGELM    253Eh   SCRDAT.ASM   item code -> element code of its icon in the panel
; HUDMAP    2548h   SCRDAT.ASM   status panel template, 5 rows of 40 tiles
; ELMSEL    2610h   ROOMDAT.ASM  opcode and 3Fh -> element code in ELMTAB, 61 bytes
; ROOMPT    264Dh   ROOMDAT.ASM  100 pointers: room N runs from [N] to [N+1]
; ROOMS     2715h   ROOMDAT.ASM  room descriptions, byte code for BLDMAP
; TRSMAP    3362h   ROOMDAT.ASM  byte code of the treasure chamber geometry, 8 overlapping windows
; TRSGEM    33F2h   ROOMDAT.ASM  byte code of the treasures, 16 overlapping windows
; TRSDRL    346Ah   ROOMDAT.ASM  byte code of the treasure chamber exit on the left
; TRSDRR    346Dh   ROOMDAT.ASM  byte code of the treasure chamber exit on the right
; TTLMAP    3470h   ROOMDAT.ASM  byte code of the title screen, read up to TTLEND
; TTLEND    349Ah   ROOMDAT.ASM  end of the title screen byte code
; SOLIDS    34A0h   ROOMDAT.ASM  floor-span list: {row, column, length} for every run
; BELTPH    3750h   TILANI.ASM   belt cycling phase, modulo 4
; PH70A     3757h   TILANI.ASM   blink phase of tile 70h, variant A
; PH70B     375Bh   TILANI.ASM   blink phase of tile 70h, variant B
; PH71      3761h   TILANI.ASM   blink phase of tile 71h
; PITPHT    3825h   TILANI.ASM   PH70 and 7 -> how many frames to hold a PITFRM set
; BLK70AD   3862h   TILANI.ASM   PH70A -> how many frames to hold the picture of tile 70h
; BELTWRK   38F0h   ANIMDAT.ASM  conveyor belt, four phases of six tiles
; BELTFRM   3A70h   ANIMDAT.ASM  BELTPH and 3 -> phase of the belt, 4 words
; PITFRM    3AF8h   ANIMDAT.ASM  four sets of six pit pictures
; TIL71     3B28h   ANIMDAT.ASM  picture of tile 71h, laid down twice
; BLK71TB   3B48h   ANIMDAT.ASM  PH71 -> picture of tile 71h, 2 words
; BLK70AT   3B6Ch   ANIMDAT.ASM  PH70A -> picture of tile 70h, 2 words
; BLK70BT   3B70h   ANIMDAT.ASM  PH70B -> picture of tile 70h, 2 words
; ANIMTB    3B80h   ANIMDAT.ASM  animation tables: lists of pointers to frames
; FRAMES    3BE0h   FRAMES.ASM   sprite frame bitmaps
; OBJXTAB   4B4Eh   FRAMES.ASM   column 0..0Fh -> X in pixels, 16 bytes
; OBJYTAB   4B5Eh   FRAMES.ASM   row 0..0Bh -> Y in scan lines
; PLRFRM    4B69h   FRAMES.ASM   20 pointers to the player's frames; no code refers to it
; OBJTAB    4BA0h   FRAMES.ASM   background saved from under the sprites, stride 100h, 16 objects
; MSKTAB    5BA0h   FRAMES.ASM   transparency mask table, 256 bytes
; JOYYLO    5DF0h   JOYSTK.ASM   low threshold of the Y axis, trims itself
; JOYYHI    5DF2h   JOYSTK.ASM   high threshold of the Y axis
; JOYXLO    5DF4h   JOYSTK.ASM   low threshold of the X axis
; JOYXHI    5DF6h   JOYSTK.ASM   high threshold of the X axis
; JOYXRAW   5DF8h   JOYSTK.ASM   last count taken off the X axis
; JOYYRAW   5DFAh   JOYSTK.ASM   last count taken off the Y axis
; JOYBITS   5DFCh   JOYSTK.ASM   direction worked out from where the stick is held
; KEYTAB    5DFDh   JOYSTK.ASM   redefinable keys, 7 records of 4 bytes
; ACCXLO    5EC4h   JOYSTK.ASM   running-average accumulator behind JOYXLO
; ACCXHI    5EC6h   JOYSTK.ASM   accumulator behind JOYXHI
; ACCYLO    5EC8h   JOYSTK.ASM   accumulator behind JOYYLO
; ACCYHI    5ECAh   JOYSTK.ASM   accumulator behind JOYYHI
; ROWADJ    6000h   SCANTIL.ASM  row correction by object type, 5 bytes: 08 0D 0D 0D 13
; TILELF    6005h   SCANTIL.ASM  per object: the tile to the left
; TILEAT    600Dh   SCANTIL.ASM  per object: the tile in the object's own cell
; TILERT    6015h   SCANTIL.ASM  per object: the tile to the right
; TILEDN    601Dh   SCANTIL.ASM  per object: the tile one row down, that is, underfoot
; MAPOFS    6025h   SCANTIL.ASM  offset of the player's cell within SCRMAP (object 0 only)
; GSTATE    60D0h   STATES.ASM   index of the machine's state, starts at 8 = the menu
; BARRCT    60D3h   STATES.ASM   rectangle of the GAME OVER sign, for PUTRCT
; LITNOW    60DEh   STATES.ASM   1 = a torch was picked up this frame,
;                                redraw the room lit
; STTAB     60E0h   STATES.ASM   transition table of the state machine, 10 words
; JUMPTAB   6510h   PLAYER.ASM   vertical jump speed, 13 bytes: 8 4 4 2 2 1 0 -1 -2 -2 -4 -4 -6
; CMDBITS   651Dh   PLAYER.ASM   control command: AH -- direction, AL -- modifier
; PLRST     651Fh   PLAYER.ASM   player state (standing/walking/jumping/dying)
; ANIMPTR   6520h   PLAYER.ASM   per object: pointer to its current animation table
; ANIMIDX   6530h   PLAYER.ASM   per object: number of the current frame in the chain
; ANIMLEN   6540h   PLAYER.ASM   per object: highest frame number in the chain
; FRMSAVE   6550h   PLAYER.ASM   animation frame kept across a room change
; OBJVX     6558h   PLAYER.ASM   per object: speed along X, signed
; OBJVY     6560h   PLAYER.ASM   per object: speed along Y, signed
; OBJTMR2   6568h   PLAYER.ASM   per object: countdown to the next change of state
; JUMPIDX   6570h   PLAYER.ASM   current index into JUMPTAB
; YSTART    6573h   PLAYER.ASM   the height a jump or a fall started from
; LIVES     6574h   PLAYER.ASM   lives left, starts at 5
; SVX       6575h   PLAYER.ASM   X kept across a move into another room
; SVY       6576h   PLAYER.ASM   Y kept the same way
; SVST      6577h   PLAYER.ASM   PLRST kept the same way
; SVANIM    6578h   PLAYER.ASM   ANIMPTR kept the same way
; SVIDX2    657Ah   PLAYER.ASM   ANIMIDX kept the same way
; SVLEN     657Ch   PLAYER.ASM   ANIMLEN kept the same way
; PASSTIL   657Eh   PLAYER.ASM   20 tiles you drop straight through
; DOORTIL   6592h   PLAYER.ASM   2 doorway tiles, no footing either
; LANDTIL   6594h   PLAYER.ASM   5 tiles you can stand on: 01 02 28 29 06
; DEADTIL   6599h   PLAYER.ASM   6 deadly tiles: 78 79 7A 7B 34 35
; STOPTIL   659Fh   PLAYER.ASM   tiles on which a fall turns into state 2
; GATETIL   65A1h   PLAYER.ASM   3 doorway tiles: 0F green, 16 red, 1D brown
; PSTTAB    65B6h   PLAYER.ASM   transition table of the player state, 10 words
; BELTVX    6740h   PLAYER.ASM   conveyor speed: +1 and -1
; HITMSK    6C60h   ITEMS.ASM    collision mask, built up over the frame
; PTSTAB    6C61h   ITEMS.ASM    table of points per event, 2 BCD bytes to a record
; ITMELM    6C6Fh   ITEMS.ASM    7 codes of the elements that can be picked up
; ITMPTS    6C76h   ITEMS.ASM    element -> offset of its record in PTSTAB, 7 words
; SCORE     6C84h   ITEMS.ASM    score, 3 bytes of packed BCD, 6C84 = the high one
; HUDRCT    6C87h   ITEMS.ASM    the two status panel windows for PUTRCT
; RCTREC    6C99h   ITEMS.ASM    record of a dirty rectangle:
;                                row, column, height, width
; RCTCOL    6C9Bh   ITEMS.ASM    column of the dirty rectangle
; RCTH      6C9Dh   ITEMS.ASM    height of the dirty rectangle in tiles
; RCTW      6C9Fh   ITEMS.ASM    width of the dirty rectangle in tiles
; ROOMOBN   6CA3h   ITEMS.ASM    how many objects are in the current room
; ITEMCNT   6CA4h   ITEMS.ASM    how many items are in the inventory
; ITEMS     6CA5h   ITEMS.ASM    inventory: item codes, 3Fh = empty
; ITMTMR    6CAFh   ITEMS.ASM    ticks of amulet invulnerability left
;                                while it is non-zero PLRHIT ignores collisions
; LASTITM   6CB0h   ITEMS.ASM    code of the last element picked up
; ELMOFS    6CB4h   ITEMS.ASM    offset of the element found, within SCRMAP
; HITOBJ    7490h   ENEMY.ASM    index of the object the player ran into
; JUMPARC   7492h   ENEMY.ASM    jump arc: 15h vertical speed values
; VXRIGHT   74A6h   ENEMY.ASM    object subtype -> speed to the right, 4 bytes
; VXLEFT    74AAh   ENEMY.ASM    object subtype -> speed to the left, 4 bytes
; TURNTIL   74AEh   ENEMY.ASM    tiles an object turns around at:
;                                the floor and the three doorways
; BEHTAB    74F3h   ENEMY.ASM    object behavior table: 4 words indexed by OBJTYP
; SNDPRI    77B0h   SOUND.ASM    priority of the sound now playing
; SCORES    77B2h   SOUND.ASM    the tunes, twelve of them back to back
; SNDTAB    79A5h   SOUND.ASM    table of pointers to the tunes, 12 words
; COSTTAB   79C0h   TIMING.ASM   what it costs to draw an object
;                                of each type, 8 words
; SOLCNT    79CAh   TIMING.ASM   total length of the floor spans in the current room
; WORKSUM   79CCh   TIMING.ASM   running cost of the frame; FRMWAIT pads it out to 10Eh
; INPDEV    7A30h   TEXT.ASM     0 = keyboard, 1 = joystick
; STRTAB    7A31h   TEXT.ASM     interface strings, run together, no terminators

;-----------------------------------------------------------------------
; FIELD OFFSETS WITHIN THE RECORDS
;
; OBJREC -- an object record in OBJTBL, 6 bytes. Object 0 is the player.
; BGSAVE -- background saved from under a sprite, stride 100h from OBJTAB.
; DRWSPR fills the BGSAVE fields in, ERSSPR reads them back.
;
; OBJREC                          BGSAVE
;   +00 DW  pointer to the bitmap    +00 DW  offset into B800h
;   +02 DB  X in bytes, 0..79        +02 DB  field: 0 even, 1 odd
;   +03 DB  Y in lines, bit 0 =      +03 DB  height in lines
;           which field              +04 DB  width in bytes
;   +04 DB  width in bytes           +05 DB  the saved background bytes
;   +05 DB  height in lines
;-----------------------------------------------------------------------
OBJREC_SZ    EQU 6          ; record stride within OBJTBL
; OB_FRAME     = 0          +00 pointer to the frame bitmap (frame address + 2)
OB_X         EQU 2          ; +02 X in bytes of video RAM, 0..79
OB_Y         EQU 3          ; +03 Y in scan lines; bit 0 = the field
OB_W         EQU 4          ; +04 width in bytes (4 pixels to a byte)
OB_H         EQU 5          ; +05 height in lines

; BGSAVE_SZ    = 100h       record stride within OBJTAB
; BG_VRAM      = 0          +00 offset into B800h: (Y and 0FEh)*28h + X
BG_FLD       EQU 2          ; +02 field: 0 = even, 1 = odd
BG_H         EQU 3          ; +03 height in lines
BG_W         EQU 4          ; +04 width in bytes
BG_BITS      EQU 5          ; +05 the saved background bytes, line by line

;-----------------------------------------------------------------------
; TILE CODES -- REFERENCE TABLE
;
; The image holds no properties for tiles: what a tile means is settled
; by which list it is named in and which element description it belongs
; to. That source is given in brackets. The other tiles have no names.
;-----------------------------------------------------------------------
; T_FLOOR      = 1          brick floor, stands on  [INLIST LANDTIL]
; T_FLOOR2     = 2          brick floor, second variant  [INLIST LANDTIL]
; T_STEP       = 6          ledge, stands on  [INLIST LANDTIL]
T_PASS       EQU 0Eh        ; walk-through  [INLIST PASSTIL]
; T_GATEG      = 0Fh        green doorway, anchor; the green key opens it [INLIST GATETIL]
; T_GATEG1     = 10h        green doorway, +1  [ELMTAB 4Fh]
; T_GATEG2     = 11h        green doorway, +2  [ELMTAB 4Fh]
; T_GATEG3     = 12h        green doorway, +3  [ELMTAB 4Fh]
; T_GATER      = 16h        red doorway, anchor; the red key opens it [INLIST GATETIL]
; T_GATEB      = 1Dh        brown doorway, anchor; the brown key [INLIST GATETIL]
; T_SWRD0      = 24h        sword, top right  [ELMTAB 37h]
; T_SWRD1      = 25h        sword, top left  [ELMTAB 37h]
; T_SWRD2      = 26h        sword, bottom right  [ELMTAB 37h]
; T_SWRD3      = 27h        sword, bottom left  [ELMTAB 37h]
T_LADTL      EQU 28h        ; ladder, top left  [MIRROR 28/29]
; T_LADTR      = 29h        ladder, top right; they climb down it [MIRROR + LADDDN]
T_LADL       EQU 2Ah        ; ladder, left half  [MIRROR 2A/2B]
; T_LADR       = 2Bh        ladder, right half; they climb up it [MIRROR + LADDER]
; T_AMUL0      = 2Ch        amulet, top right  [ELMTAB 2Fh]
; T_AMUL1      = 2Dh        amulet, top left  [ELMTAB 2Fh]
; T_AMUL2      = 2Eh        amulet, bottom right  [ELMTAB 2Fh]
; T_AMUL3      = 2Fh        amulet, bottom left  [ELMTAB 2Fh]
; T_GEM0       = 30h        gem, top right  [ELMTAB 2Bh]
; T_GEM1       = 31h        gem, top left  [ELMTAB 2Bh]
; T_GEM2       = 32h        gem, bottom right  [ELMTAB 2Bh]
; T_GEM3       = 33h        gem, bottom left  [ELMTAB 2Bh]
; T_DEAD0      = 34h        kills on a fall  [INLIST DEADTIL]
; T_DEAD1      = 35h        kills on a fall  [INLIST DEADTIL]
; T_KEYG1      = 3Ah        green key, top left  [ELMTAB 43h]
; T_KEYG0      = 3Bh        green key, top right; USEITEM looks for this one  [ELMTAB 43h]
; T_KEYG3      = 3Ch        green key, bottom left  [ELMTAB 43h]
; T_KEYG2      = 3Dh        green key, bottom right  [ELMTAB 43h]
; T_KEYR1      = 3Eh        red key, top left  [ELMTAB 47h]
; T_KEYR0      = 3Fh        red key, top right; USEITEM looks for this one  [ELMTAB 47h]
; T_KEYR3      = 40h        red key, bottom left  [ELMTAB 47h]
; T_KEYR2      = 41h        red key, bottom right  [ELMTAB 47h]
; T_KEYB1      = 42h        brown key, top left  [ELMTAB 4Bh]
; T_KEYB0      = 43h        brown key, top right; USEITEM looks for this one [ELMTAB 4Bh]
; T_KEYB3      = 44h        brown key, bottom left  [ELMTAB 4Bh]
; T_KEYB2      = 45h        brown key, bottom right  [ELMTAB 4Bh]
; T_TRCH2      = 6Eh        torch, bottom right  [ELMTAB 3Fh]
; T_TRCH3      = 6Fh        torch, bottom left  [ELMTAB 3Fh]
T_SOLID      EQU 70h        ; solid floor with speckle  [ELMTAB 17h]
; T_SOLID2     = 71h        solid floor, second variant  [ELMTAB 0Fh]
; T_BELT0      = 72h        conveyor belt; mirror pair with 77h  [MIRROR + BELTPUSH]
; T_BELT1      = 73h        conveyor belt; mirror pair with 76h  [MIRROR + BELTPUSH]
; T_BELT2      = 74h        conveyor belt; mirror pair with 75h  [MIRROR + BELTPUSH]
; T_BELT3      = 75h        conveyor belt; mirror pair with 74h  [MIRROR + BELTPUSH]
; T_BELT4      = 76h        conveyor belt; mirror pair with 73h  [MIRROR + BELTPUSH]
; T_BELT5      = 77h        conveyor belt; mirror pair with 72h  [MIRROR + BELTPUSH]
; T_PIT0       = 78h        pit, top right; kills  [ELMTAB 1Fh + DEADTIL]
; T_PIT1       = 79h        pit, top left; kills  [ELMTAB 1Fh + DEADTIL]
; T_PIT2       = 7Ah        pit, bottom right; kills  [ELMTAB 1Fh + DEADTIL]
; T_PIT3       = 7Bh        pit, bottom left; kills  [ELMTAB 1Fh + DEADTIL]
; T_TRCH0      = 7Ch        torch, top right  [ELMTAB 3Fh]
; T_TRCH1      = 7Dh        torch, top left  [ELMTAB 3Fh]
;
; Master copies. DARKEN blanks the live tiles so the room goes black;
; TILRST writes them back from here. Items drawn out of the copies
; (sword 3Bh, amulet 33h) stay visible in the dark.
; T_REF01      = 7Eh        master copy of tiles 01h..02h (2 of them)
; T_REF03      = 80h        master copy of tiles 03h..33h (49 of them)
; T_REF72      = 0B1h       master copy of tiles 72h..77h (6 of them)
; T_WRK00      = 0B7h       master copy of BELTWRK, 24 tiles

;-----------------------------------------------------------------------
; ELEMENT CODES -- REFERENCE TABLE
;
; An element is a 2x2 square of tiles; the element code is the OFFSET of
; its description within ELMTAB, so the stride between codes is four.
;-----------------------------------------------------------------------
; ELM_LADD     = 3          ladder against brick
; ELM_LADT     = 7          top of a ladder
; ELM_STEP     = 0Bh        ledge
; ELM_BELTL    = 0Fh        conveyor, left half
; ELM_BELTR    = 13h        conveyor, right half
; ELM_SOLID    = 17h        solid floor
; ELM_BRICK    = 1Bh        brick
; ELM_PIT      = 1Fh        pit: the fall kills
; ELM_DEAD     = 23h        deadly floor
; ELM_DEAD2    = 27h        deadly floor, variant
; ELM_KEYG     = 43h        green key, 50 pts, inventory icon 43h
; ELM_KEYR     = 47h        red key, 50 pts, inventory icon 47h
; ELM_KEYB     = 4Bh        brown key, 50 pts, inventory icon 4Bh
; ELM_GATEG    = 4Fh        green doorway
