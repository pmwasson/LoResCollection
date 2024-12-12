;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; Lander
;-----------------------------------------------------------------------------
; Low res lander game
;-----------------------------------------------------------------------------

.include "defines.asm"
.include "macros.asm"

.segment "CODE"
.org    $2000

; Reuse zero page pointers
evenPtr0                :=  screenPtr0
evenPtr1                :=  screenPtr1
oddPtr0                 :=  maskPtr0
oddPtr1                 :=  maskPtr1
tileShiftInit           :=  tempZP
tileShiftRemainder      :=  temp2ZP

MAP_SCREEN_LEFT         =  2
MAP_SCREEN_RIGHT        =  36
MAP_SCREEN_TOP          =  4        ; Must be /2
MAP_SCREEN_BOTTOM       =  22       ; Must be /2

POS_CHECK_BOTTOM        = MAP_HEIGHT*4  -2*(MAP_SCREEN_BOTTOM-MAP_SCREEN_TOP)
POS_CHECK_LEFT          = MAP_WIDTH*4   -  (MAP_SCREEN_RIGHT -MAP_SCREEN_LEFT)

THRUST_POS0             = 10
THRUST_POS1             = 0

THRUST_NEG0             = 256-THRUST_POS0
THRUST_NEG1             = 255

GRAVITY0                = 5
GRAVITY1                = 0

BG_COLOR                = $77   ; for collision detection

COLLISION_MASK          = %1111
COLLISION_TOP           = %0001
COLLISION_LEFT          = %0010
COLLISION_RIGHT         = %0100
COLLISION_BOTTOM_LEFT   = %1010
COLLISION_BOTTOM_RIGHT  = %1100

.proc main

    ;----------------------------------
    ; Init demo
    ;----------------------------------
    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    sta         MIXCLR

    lda         #0
    sta         drawPage

    lda         #$00
    jsr         clearMixedText

    lda         #4
    sta         drawPage

    lda         #0
    sta         bg0
    sta         bg1
    jsr         clearScreen

    lda         #$00
    jsr         clearMixedText

    ; set particles location
    ;lda         #34
    ;sta         curY
    ;lda         #PLAYER_XOFFSET+2
    ;sta         curX

    ldx         #SOUND_DEAD
    jsr         playSound

    ;----------------------------------
    ; Main Loop
    ;----------------------------------
loop:
    ; Flip page
    ;-----------
    lda         PAGE2           ; bit 7 = page2 displayed
    bmi         switchTo1

    ; switch page 2
    bit         HISCR           ; display high screen
    lda         #$00            ; update low screen
    sta         drawPage
    beq         :+

switchTo1:
    bit         LOWSCR          ; display low screen
    lda         #$04            ; update high screen
    sta         drawPage
:

    ; Update
    ;---------------

    jsr         updateFuel
    ;jsr         updateParticles


    ; Gravity
    lda         vecY0
    adc         #GRAVITY0
    sta         vecY0
    lda         vecY1
    adc         #GRAVITY1
    sta         vecY1

    ; update player Y
    clc
    lda         vecY0
    adc         posY
    sta         posY
    lda         vecY1
    adc         worldY
    bpl         :+
    lda         #0
    sta         vecY0
    sta         vecY1
:
    cmp         #POS_CHECK_BOTTOM
    bcc         :+
    lda         #0
    sta         vecY0
    sta         vecY1
    lda         #POS_CHECK_BOTTOM
:
    sta         worldY

    ; update player X
    clc
    lda         vecX0
    adc         posX
    sta         posX
    lda         vecX1
    adc         worldX
    bpl         :+
    lda         #0
    sta         vecX0
    sta         vecX1
:
    cmp         #POS_CHECK_LEFT
    bcc         :+
    lda         #0
    sta         vecX0
    sta         vecX1
    lda         #POS_CHECK_LEFT
:
    sta         worldX

    ; Draw screen
    ;---------------
    jsr         drawTileMap

    ; check for collision after drawing map, but before any other drawing
    lda         #PLAYER_COLOR0
    sta         shipColor0
    lda         #PLAYER_COLOR1
    sta         shipColor1
    jsr         detectCollision
    and         #COLLISION_MASK
    sta         collisionResult
    beq         :+
    lda         #PLAYER_COLLISION_COLOR0
    sta         shipColor0
    lda         #PLAYER_COLLISION_COLOR1
    sta         shipColor1
    ldx         #SOUND_BUMP
    jsr         playSound
    jsr         resolveCollision
:

    ; Draw foreground
    ;jsr         drawParticles
    jsr         drawPlayer
    jsr         drawFuelGauge




    ; Get input
    ;---------------

    ldx         #0
    jsr         PREAD
    sty         mapPaddleX
:
    nop
    iny
    bne         :-              ; Add delay for small values to make constant

    lda         KBD
    bmi         :+
    jmp         loop
:
    sta         KBDSTRB

    cmp         #KEY_DOWN
    bne         :+
    lda         vecY0
    adc         #THRUST_POS0
    sta         vecY0
    lda         vecY1
    adc         #THRUST_POS1
    sta         vecY1
    jmp         loop
:
    cmp         #KEY_UP
    bne         :+
    clc
    lda         vecY0
    adc         #THRUST_NEG0
    sta         vecY0
    lda         vecY1
    adc         #THRUST_NEG1
    sta         vecY1
    jmp         loop
:
    cmp         #KEY_RIGHT
    bne         :+
    lda         vecX0
    adc         #THRUST_POS0
    sta         vecX0
    lda         vecX1
    adc         #THRUST_POS1
    sta         vecX1
    jmp         loop
:
    cmp         #KEY_LEFT
    bne         :+
    lda         vecX0
    adc         #THRUST_NEG0
    sta         vecX0
    lda         vecX1
    adc         #THRUST_NEG1
    sta         vecX1
    jmp         loop
:

    cmp         #KEY_ESC
    bne         :+
    sta         KBDSTRB
    jmp         monitor
:

    jmp         loop

.endproc


.proc drawTileMap

    ;----------------------------------
    ; Setup

    lda         worldX
    lsr
    lsr                     ; / 4
    sta         mapCol

    lda         worldY
    lsr
    lsr                     ; / 4
    sta         mapRow

    asl
    asl
    asl
    asl
    asl                     ; * 32 (MAP_WIDTH)

    clc
    adc         mapCol
    sta         mapPtr0

    lda         mapRow
    lsr
    lsr
    lsr                     ; / 8 (256/MAP_WIDTH)
    clc
    adc         #>map
    sta         mapPtr1

    lda         worldX
    and         #%11
    sta         mapOffsetX

    lda         worldY
    and         #%11
    sta         mapOffsetY
    tax
    lda         nibbleShiftInit,x
    sta         tileShiftInit
    lda         nibbleShiftRemainder,x
    sta         tileShiftRemainder

    lda         #MAP_SCREEN_TOP
    sta         screenRow

    jsr         updateSound          ; call need to be equally spaced in time

    ;-------------------------------------------
    ; Copy first row of map tiles to buffer
    ; (throw away init and just use remainder)

    ldy         #MAP_SCREEN_LEFT
    sty         tileBufferIndex

    ; initial horizontal offset
    ldy         #0
    sty         mapIndex
    lda         (mapPtr0),y
    clc
    adc         mapOffsetX
    jmp         :+

tileBufferLoop1:
    ldy         mapIndex
    lda         (mapPtr0),y         ; read map
:
    sta         tileIdx
    ldy         tileBufferIndex
tileByteLoop1:
    ldx         tileIdx
    lda         mapTiles,x          ; read tile slice
    ora         tileShiftRemainder
    tax
    lda         nibbleShiftTable,x  ; shift by vertical offset
    sta         tileBuffer,y
    iny
    cpy         #MAP_SCREEN_RIGHT
    beq         tileBufferDone1
    inc         tileIdx
    lda         tileIdx
    and         #$3
    bne         tileByteLoop1       ; repeat for remaining slices
    sty         tileBufferIndex
    inc         mapIndex
    jmp         tileBufferLoop1
tileBufferDone1:

screenRowLoop:
    jsr         updateSound         ; call need to be equally spaced in time
    ldy         screenRow

    ;----------------------------------
    ; Set screen pointers for
    ; 2 aligned rows
    lda         lineOffset,y
    sta         evenPtr0
    ora         #$80
    sta         oddPtr0
    lda         linePage,y
    clc
    adc         drawPage
    sta         evenPtr1
    sta         oddPtr1

    ;----------------------------------------
    ; Copy rows and output to screen

    ldy         #MAP_SCREEN_LEFT
    sty         tileBufferIndex

    lda         mapPtr0
    clc
    adc         #MAP_WIDTH
    sta         mapPtr0
    lda         mapPtr1
    adc         #0
    sta         mapPtr1

    ; initial horizontal offset
    ldy         #0
    sty         mapIndex
    lda         (mapPtr0),y
    clc
    adc         mapOffsetX
    jmp         :+

tileBufferLoop2:
    ldy         mapIndex
    lda         (mapPtr0),y         ; read map
:
    sta         tileIdx
    ldy         tileBufferIndex
tileByteLoop2:
    ldx         tileIdx
    lda         mapTiles,x          ; read tile slice
    ora         tileShiftInit
    tax
    lda         nibbleShiftTable,x  ; shift by vertical offset
    ora         tileBuffer,y        ; combine prev remainder with new init
    tax                             ; look up colors
    lda         evenColor,x
    sta         (evenPtr0),y
    lda         oddColor,x
    sta         (oddPtr0),y

    ldx         tileIdx
    lda         mapTiles,x          ; read tile slice
    ora         tileShiftRemainder
    tax
    lda         nibbleShiftTable,x  ; shift by vertical offset
    sta         tileBuffer,y        ; store init for next loop

    iny
    cpy         #MAP_SCREEN_RIGHT
    bcs         tileBufferDone2
    inc         tileIdx
    lda         tileIdx
    and         #$3
    bne         tileByteLoop2       ; repeat for remaining slices
    sty         tileBufferIndex
    inc         mapIndex
    jmp         tileBufferLoop2
tileBufferDone2:

    inc         screenRow
    inc         screenRow
    ldy         screenRow
    cpy         #MAP_SCREEN_BOTTOM
    beq         drawMapDone
    jmp         screenRowLoop

drawMapDone:
    rts

mapRow:             .byte   0
mapCol:             .byte   0
mapIndex:           .byte   0

mapOffsetX:         .byte   0
mapOffsetY:         .byte   0

screenRow:          .byte   0
tileBufferIndex:    .byte   0

.endproc

;-----------------------------------------------------------------------------
; Draw Player
;   Uses hardcoded fixed locations for faster render
;-----------------------------------------------------------------------------

PLAYER_XOFFSET  = 16
PLAYER_ROW0_0   = $7A8 + PLAYER_XOFFSET     ; 15 (30)
PLAYER_ROW1_0   = $450 + PLAYER_XOFFSET     ; 16 (32)
PLAYER_ROW2_0   = $4D0 + PLAYER_XOFFSET     ; 17 (34)
PLAYER_ROW0_1   = $400 + PLAYER_ROW0_0
PLAYER_ROW1_1   = $400 + PLAYER_ROW1_0
PLAYER_ROW2_1   = $400 + PLAYER_ROW2_0
PLAYER_COLOR0   = $FF
PLAYER_COLOR1   = $F5
PLAYER_COLLISION_COLOR0 = $99
PLAYER_COLLISION_COLOR1 = $90

.proc drawPlayer

    lda         drawPage
    bne         draw1

    ;   ##
    ;   ##
    ;  #--#
    ;  ####
    ; #    #
    ; #    #

draw0:
    lda         shipColor0
    sta         PLAYER_ROW0_0+2
    sta         PLAYER_ROW0_0+3
    sta         PLAYER_ROW1_0+1
    sta         PLAYER_ROW1_0+4
    sta         PLAYER_ROW2_0+0
    sta         PLAYER_ROW2_0+5
    lda         shipColor1
    sta         PLAYER_ROW1_0+2
    sta         PLAYER_ROW1_0+3
    rts

draw1:
    lda         shipColor0
    sta         PLAYER_ROW0_1+2
    sta         PLAYER_ROW0_1+3
    sta         PLAYER_ROW1_1+1
    sta         PLAYER_ROW1_1+4
    sta         PLAYER_ROW2_1+0
    sta         PLAYER_ROW2_1+5
    lda         shipColor1
    sta         PLAYER_ROW1_1+2
    sta         PLAYER_ROW1_1+3
    rts

.endproc

;-----------------------------------------------------------------------------
; detectCollision
;   Try to make non-collision quick as is the normal case
;-----------------------------------------------------------------------------

.proc detectCollision

    lda         #0              ; result
    ldy         #BG_COLOR
    ldx         drawPage
    bne         collision1

collision0:
    cpy         PLAYER_ROW0_0+2
    beq         :+
    ora         #COLLISION_TOP
:
    cpy         PLAYER_ROW0_0+3
    beq         :+
    ora         #COLLISION_TOP
:
    cpy         PLAYER_ROW1_0+1
    beq         :+
    ora         #COLLISION_LEFT
:
    ; skipping middle of ship
    cpy         PLAYER_ROW1_0+4
    beq         :+
    ora         #COLLISION_RIGHT
:
    cpy         PLAYER_ROW2_0+0
    beq         :+
    ora         #COLLISION_BOTTOM_LEFT
:
    cpy         PLAYER_ROW2_0+5
    beq         :+
    ora         #COLLISION_BOTTOM_RIGHT
:
    rts

collision1:
    cpy         PLAYER_ROW0_1+2
    beq         :+
    ora         #COLLISION_TOP
:
    cpy         PLAYER_ROW0_1+3
    beq         :+
    ora         #COLLISION_TOP
:
    cpy         PLAYER_ROW1_1+1
    beq         :+
    ora         #COLLISION_LEFT
:
    ; skipping middle of ship
    cpy         PLAYER_ROW1_1+4
    beq         :+
    ora         #COLLISION_RIGHT
:
    cpy         PLAYER_ROW2_1+0
    beq         :+
    ora         #COLLISION_BOTTOM_LEFT
:
    cpy         PLAYER_ROW2_1+5
    beq         :+
    ora         #COLLISION_BOTTOM_RIGHT
:
    rts

.endproc

;-----------------------------------------------------------------------------
; Resolve Collision
;-----------------------------------------------------------------------------

.proc resolveCollision
    ldy         #0
    ldx         collisionResult
    lda         collisionResultTable,x
    ror
    bcc         :+
    ; Clear VX
    sty         vecX0
    sty         vecX1
:
    ror
    bcc         :+
    ; Clear VY
    sty         vecY0
    sty         vecY1
:
    ror
    bcc         :+
    ; Move down
    inc         worldY
    sty         posY
:
    ror
    bcc         :+
    ; Move right
    inc         worldX
    sty         posX
:
    ror
    bcc         :+
    ; Move left
    dec         worldX
    sty         posX
:
    ror
    bcc         :+
    ; Move up
    dec         worldY
    sty         posY
:
    rts

.endproc


;-----------------------------------------------------------------------------
; Update Fuel
;-----------------------------------------------------------------------------

FUEL_COLOR_EMPTY        = $00
FUEL_COLOR_GOOD         = $44
FUEL_COLOR_WARN         = $DD
FUEL_COLOR_LOW          = $99
FUEL_MAX_CONSUMPTION    = 9

FUEL_LEVEL_MAX          = 39

.proc updateFuel

    lda         BUTTON0
    bmi         decreaseFuel

increaseFuel:
    lda         fuelLevel
    cmp         #FUEL_LEVEL_MAX
    bcc         :+
    rts
:
    inc         fuelLevel
    lda         fuelLevel
    cmp         #FUEL_LEVEL_MAX
    bne         :+
    ldx         #SOUND_CHARM
    jsr         playSound
    ldx         fuelLevel
    jmp         updateColors
:
    ldx         #SOUND_REFUEL
    jsr         playSound
    ldx         fuelLevel
    jmp         updateColors

decreaseFuel:

    lda         fuelLevel
    bne         :+
    rts                                 ; already empty
:

    ldx         #SOUND_ENGINE
    jsr         playSound

    inc         consumption
    lda         consumption
    cmp         #FUEL_MAX_CONSUMPTION
    bcs         :+
    rts
:

    lda         #0
    sta         consumption
    ldx         fuelLevel
    lda         #FUEL_COLOR_EMPTY
    sta         fuelColor,x
    dex
    stx         fuelLevel
    bne         :+

    ldx         #SOUND_DEAD
    jsr         playSound
    rts                                 ; hit empty
:
updateColors:
    lda         fuelStatusColor,x
fuelLoop:
    sta         fuelColor,x
    dex
    bne         fuelLoop
    rts

fuelLevel:          .byte       0
consumption:        .byte       0

; 40 values
fuelStatusColor:
    .byte       FUEL_COLOR_LOW,  FUEL_COLOR_LOW,  FUEL_COLOR_LOW,  FUEL_COLOR_LOW,  FUEL_COLOR_LOW,  FUEL_COLOR_LOW,  FUEL_COLOR_LOW
    .byte       FUEL_COLOR_WARN, FUEL_COLOR_WARN, FUEL_COLOR_WARN, FUEL_COLOR_WARN, FUEL_COLOR_WARN, FUEL_COLOR_WARN, FUEL_COLOR_WARN, FUEL_COLOR_WARN
    .byte       FUEL_COLOR_WARN, FUEL_COLOR_WARN
    .byte       FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD
    .byte       FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD
    .byte       FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD, FUEL_COLOR_GOOD

.endProc

;-----------------------------------------------------------------------------
; Draw Fuel Gauge
;   Uses hardcoded fixed locations for faster render
;-----------------------------------------------------------------------------

.proc drawFuelGauge

FUEL_XLEFT      = 1
FUEL_XRIGHT     = 39    ; increment by 2
FUEL_ROW0_0     = $400                      ; 0 (0)
FUEL_ROW1_0     = $480                      ; 1 (2)
FUEL_ROW2_0     = $500                      ; 2 (4)
FUEL_ROW0_1     = $400 + FUEL_ROW0_0
FUEL_ROW1_1     = $400 + FUEL_ROW1_0
FUEL_ROW2_1     = $400 + FUEL_ROW2_0

    ldx         #FUEL_XLEFT
    lda         drawPage
    bne         draw1

draw0:
    lda         fuelColor,x
    sta         FUEL_ROW0_0,x
    sta         FUEL_ROW1_0,x
    sta         FUEL_ROW2_0,x
    inx
    inx
    cpx         #FUEL_XRIGHT
    bne         draw0
    rts

draw1:
    lda         fuelColor,x
    sta         FUEL_ROW0_1,x
    sta         FUEL_ROW1_1,x
    sta         FUEL_ROW2_1,x
    inx
    inx
    cpx         #FUEL_XRIGHT
    bne         draw1
    rts

.endProc


;-----------------------------------------------------------------------------
; Monitor
;
;  Exit to monitor
;-----------------------------------------------------------------------------
.proc monitor
    jsr         TEXT

    ; Set ctrl-y vector
    lda         #$4c        ; JMP
    sta         $3f8
    lda         #<quit
    sta         $3f9
    lda         #>quit
    sta         $3fa

    jsr    inlinePrint
    .byte       13
    StringCR "Enter ctrl-y to quit to ProDos"

    ;bit     TXTSET
    jmp     MONZ        ; enter monitor

.endproc

;-----------------------------------------------------------------------------
; Quit
;
;   Exit to ProDos
;-----------------------------------------------------------------------------
.proc quit

    sta         LOWSCR          ; page 1
    sta         TXTSET          ; text mode

    jsr         MLI
    .byte       CMD_QUIT
    .word       quitParams


quitParams:
    .byte       4               ; 4 parameters
    .byte       0               ; 0 is the only quit type
    .word       0               ; Reserved pointer for future use (what future?)
    .byte       0               ; Reserved byte for future use (what future?)
    .word       0               ; Reserved pointer for future use (what future?)

.endproc

;-----------------------------------------------------------------------------
; Libraries
;-----------------------------------------------------------------------------

.include "inline_print.asm"
.include "grlib.asm"
.include "sound.asm"

;-----------------------------------------------------------------------------
; Globals
;-----------------------------------------------------------------------------

worldX:             .byte   0
worldY:             .byte   0
mapPaddleX:         .byte   0
posX:               .byte   0   ; sub pixel
posY:               .byte   0   ; sub pixel
vecX0:              .byte   0
vecX1:              .byte   0   ; should only be 00 or FF (max value +/-1)
vecY0:              .byte   0
vecY1:              .byte   0
collisionResult:    .byte   0

shipColor0:         .byte   PLAYER_COLOR0
shipColor1:         .byte   PLAYER_COLOR1

; define for width of screen (40), but only read relevant ones
fuelColor:      .res    40

.align 256

RESULT_CLEAR_VX         =   %000001
RESULT_CLEAR_VY         =   %000010
RESULT_MOVE_DOWN        =   %000100
RESULT_MOVE_RIGHT       =   %001000
RESULT_MOVE_LEFT        =   %010000
RESULT_MOVE_UP          =   %100000

RESULT_LEFT             = RESULT_CLEAR_VX | RESULT_MOVE_LEFT
RESULT_RIGHT            = RESULT_CLEAR_VX | RESULT_MOVE_RIGHT
RESULT_DOWN             = RESULT_CLEAR_VY | RESULT_MOVE_DOWN
RESULT_UP               = RESULT_CLEAR_VY | RESULT_MOVE_UP
RESULT_DOWN_RIGHT       = RESULT_DOWN     | RESULT_RIGHT
RESULT_DOWN_LEFT        = RESULT_DOWN     | RESULT_LEFT
RESULT_UP_RIGHT         = RESULT_UP       | RESULT_RIGHT
RESULT_UP_LEFT          = RESULT_UP       | RESULT_LEFT
RESULT_ALL_LEFT         = RESULT_CLEAR_VY | RESULT_LEFT
RESULT_ALL_RIGHT        = RESULT_CLEAR_VY | RESULT_RIGHT
RESULT_ALL_DOWN         = RESULT_CLEAR_VX | RESULT_DOWN
RESULT_ALL_UP           = RESULT_CLEAR_VX | RESULT_UP
RESULT_ALL_STOP         = RESULT_CLEAR_VX | RESULT_CLEAR_VY

;16 bytes
collisionResultTable:                                                                   ; * = illegal
    .byte   0,              RESULT_DOWN,        RESULT_RIGHT,       RESULT_DOWN_RIGHT   ; 0000  0001  0010 0011
    .byte   RESULT_LEFT,    RESULT_DOWN_LEFT,   RESULT_ALL_UP,      RESULT_ALL_DOWN     ; 0100  0101  0110 0111
    .byte   RESULT_UP,      RESULT_ALL_STOP,    RESULT_UP_RIGHT,    RESULT_ALL_RIGHT    ; 1000* 1001* 1010 1011
    .byte   RESULT_UP_LEFT, RESULT_ALL_LEFT,    RESULT_ALL_UP,      RESULT_ALL_STOP     ; 1100  1101  1110 1111


; 44 bytes
tileBuffer:         .res    44                  ; include some padding

; 128 bytes
nibbleShiftTable:
        .byte   $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $A, $B, $C, $D, $E, $F      ; shift 0
        .byte   $0, $2, $4, $6, $8, $A, $C, $E, $0, $2, $4, $6, $8, $A, $C, $E      ; shift 1
        .byte   $0, $4, $8, $C, $0, $4, $8, $C, $0, $4, $8, $C, $0, $4, $8, $C      ; shift 2
        .byte   $0, $8, $0, $8, $0, $8, $0, $8, $0, $8, $0, $8, $0, $8, $0, $8      ; shift 3
        .byte   $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0      ; shift -4.. or +4...
        .byte   $0, $0, $0, $0, $0, $0, $0, $0, $1, $1, $1, $1, $1, $1, $1, $1      ; shift -3
        .byte   $0, $0, $0, $0, $1, $1, $1, $1, $2, $2, $2, $2, $3, $3, $3, $3      ; shift -2
        .byte   $0, $0, $1, $1, $2, $2, $3, $3, $4, $4, $5, $5, $6, $6, $7, $7      ; shift -1

; 8 bytes
                                                    ; Offset 0   1   2   3
nibbleShiftInit:        .byte   $40, $30, $20, $10  ;        4,  3,  2,  1
nibbleShiftRemainder:   .byte   $00, $70, $60, $50  ;        0, -1, -2, -3

; 16x2 (32) bytes
evenColor:          .byte   $77, $71, $17, $11, $77, $71, $17, $11, $77, $71, $17, $11, $77, $71, $17, $11
oddColor:           .byte   $77, $77, $77, $77, $71, $71, $71, $71, $17, $17, $17, $17, $11, $11, $11, $11

.align 256

mapTiles:

        ; tiles defined turned right 90 degrees
        ;
        ;  L ->  1111
        ;        1000
        ;        1000
        ;        1010

; 00 - empty
        .byte   %0000
        .byte   %0000
        .byte   %0000
        .byte   %0000

; 04 - solid
        .byte   %1111
        .byte   %1111
        .byte   %1111
        .byte   %1111

; 08 - se
        .byte   %1111
        .byte   %0111
        .byte   %0011
        .byte   %0001

; 0C - sw
        .byte   %0001
        .byte   %0011
        .byte   %0111
        .byte   %1111

; 10 - ne
        .byte   %1111
        .byte   %1110
        .byte   %1100
        .byte   %1000

; 14 - nw
        .byte   %1000
        .byte   %1100
        .byte   %1110
        .byte   %1111

; 18 - dot
        .byte   %0110
        .byte   %1111
        .byte   %1111
        .byte   %0110

; 1c - rough floor 1
        .byte   %1000
        .byte   %1110
        .byte   %0000
        .byte   %1100

; 20 - rough floor 2
        .byte   %1000
        .byte   %1100
        .byte   %1110
        .byte   %1000

; 24 - rough floor 3
        .byte   %0000
        .byte   %1000
        .byte   %0000
        .byte   %1000

; 28 - steep rise 1 left
        .byte   %1100
        .byte   %1111
        .byte   %1111
        .byte   %1111

; 2c - steep rise 2 left
        .byte   %0000
        .byte   %0000
        .byte   %1100
        .byte   %1111

; 30 - steep rise 1 right
        .byte   %1111
        .byte   %1111
        .byte   %1111
        .byte   %1100

; 34 - steep rise 2 right
        .byte   %1111
        .byte   %1100
        .byte   %0000
        .byte   %0000

; 38 - rough ceiling 1
        .byte   %0001
        .byte   %1111
        .byte   %0011
        .byte   %0001

; 3c - rough ceiling 2
        .byte   %0000
        .byte   %0001
        .byte   %0011
        .byte   %0001

; 40 - rough ceiling 3
        .byte   %0011
        .byte   %0000
        .byte   %0111
        .byte   %0001

.align 256

MAP_WIDTH = 32
MAP_HEIGHT = 32

X__ = $00
XXX = $04
XSE = $08
XSW = $0C
XNE = $10
XNW = $14
XOO = $18
XF1 = $1C
XF2 = $20
XF3 = $24
XL1 = $28
XL2 = $2C
XR1 = $30
XR2 = $34
XC1 = $38
XC2 = $3C
XC3 = $40

map:
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XSE,X__,XSW,XSE,X__,XSW,XSE,XC1,XC2,XC3,XC2,XSW,XXX,XXX,XXX,XXX,XSE,X__,XSW,XSE,X__,XSW,XSE,XC1,XC2,XC3,XC2,XSW,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XNE,X__,XNW,XNE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XNE,X__,XNW,XNE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XR2,XSW,XSE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XR2,XSW,XSE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XR1,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XXX,XXX,XXX,XR1,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XSE,X__,X__,X__,XOO,X__,XOO,X__,X__,X__,X__,X__,XSW,XXX,XXX,XXX,XSE,X__,X__,X__,XOO,X__,XOO,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,XOO,X__,XOO,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XOO,X__,XOO,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XF1,XF2,XF1,XF3,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XXX,XXX
    .byte   XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,XF3,XF2,XL1,XXX,XXX,XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL1,XXX,XXX
    .byte   XXX,XXX,XR1,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XR1,XF2,XF3,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,XC3,XC2,XSW,XXX,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XXX
    .byte   XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XNE,XXX,XNW,XNE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XNW,XNE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XR2,XSW,XSE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XR2,XSW,XSE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XR1,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XXX,XXX,XXX,XR1,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XXX,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XF1,XF2,XF1,XF3,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XXX,XXX
    .byte   XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,XF3,XF2,XL1,XXX,XXX,XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL1,XXX,XXX
    .byte   XXX,XXX,XR1,X__,X__,X__,XF1,XF2,XF1,XNE,XNW,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XR1,XF2,XF3,XF1,XF1,XF2,XF1,XNW,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
