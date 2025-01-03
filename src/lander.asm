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

START_PLAYER_X          =  5
START_PLAYER_Y          =  $60
MAP_SCREEN_LEFT         =  2
MAP_SCREEN_RIGHT        =  36
MAP_SCREEN_TOP          =  4        ; Must be /2
MAP_SCREEN_BOTTOM       =  22       ; Must be /2

GRAVITY                 = 5
BG_COLOR                = $77   ; for collision detection

COLLISION_MASK              =    %11111
COLLISION_TOP               =    %00001
COLLISION_LEFT              =    %00010
COLLISION_RIGHT             =    %00100
COLLISION_BOTTOM_LEFT       =    %10010
COLLISION_BOTTOM_RIGHT      =    %10100
COLLISION_BOTTOM_MID        =    %11000
COLLISION_BOTTOM_MID_MASK   = %11110111

.proc main

    ;----------------------------------
    ; Init game
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

    ldx         #SOUND_WAKEUP
    jsr         playSound

    lda         #0
    sta         fuelLevel

    lda         #0
    sta         posX
    sta         posY
    lda         #START_PLAYER_X
    sta         worldX
    lda         #START_PLAYER_Y
    sta         worldY

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

    ; Gravity
    lda         gravityVec
    bne         :+
    jsr         increaseFuel
    jmp         doneGravity
:
    clc
    lda         vecY0
    adc         gravityVec
    sta         vecY0
    lda         vecY1
    adc         #0
    sta         vecY1
doneGravity:

    ; update player Y
    clc
    lda         vecY0
    adc         posY
    sta         posY
    lda         vecY1
    adc         worldY
    sta         worldY

    ; update player X
    clc
    lda         vecX0
    adc         posX
    sta         posX
    lda         vecX1
    adc         worldX
    sta         worldX

    ; Draw screen
    ;---------------
    jsr         drawTileMap

    ; check for collision after drawing map, but before any other drawing
    lda         #PLAYER_COLOR0              ; default to normal color
    sta         shipColor0
    lda         #PLAYER_COLOR1
    sta         shipColor1
    jsr         detectCollision
    and         #COLLISION_MASK             ; this isn't really needed, just being cautious
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
    ; only read joystick once every 16 frames to speed things up
    inc         time0
    lda         time0
    and         #%1111
    bne         :+
    jsr         readJoystick        ; return value 0..107
    ; quantize joystick
    lda         paddleX
    lsr
    lsr
    lsr
    lsr                             ; 0..6
    sta         paddleX
    lda         paddleY
    lsr
    lsr
    lsr
    lsr                             ; 0..6
    sta         paddleY
:

    lda         BUTTON0
    bmi         doButton
    jmp         getKey

doButton:
    lda         fuelLevel
    bne         :+
    jmp         getKey              ; no fuel
:

    lda         #GRAVITY
    sta         gravityVec
    jsr         decreaseFuel

    ldx         paddleX
    clc
    lda         vecX0
    adc         thrustX0,x
    sta         vecX0
    lda         vecX1
    adc         thrustX1,x
    sta         vecX1
    bmi         checkVecXNeg
    beq         doPaddleY           ; if positive, upper vec must be zero
    lda         #0
    sta         vecX1
    lda         #$ff
    sta         vecX0               ; Max positive value
    jmp         doPaddleY
checkVecXNeg:
    cmp         #$FF
    beq         doPaddleY           ; if negative, upper vec must be -1
    lda         #$ff
    sta         vecX1
    lda         #$00
    sta         vecX0               ; max negative value

doPaddleY:
    ldx         paddleY
    clc
    lda         vecY0
    adc         thrustY0,x
    sta         vecY0
    lda         vecY1
    adc         thrustY1,x
    sta         vecY1
    bmi         checkVecYNeg
    beq         donePaddle          ; if positive, upper vec must be zero
    lda         #0
    sta         vecY1
    lda         #$ff
    sta         vecY0               ; Max positive value
    jmp         donePaddle
checkVecYNeg:
    cmp         #$FF
    beq         donePaddle          ; if negative, upper vec must be -1
    lda         #$ff
    sta         vecY1
    lda         #$00
    sta         vecY0               ; max negative value
donePaddle:

getKey:
    lda         KBD
    bmi         :+
    jmp         loop
:
    sta         KBDSTRB

    cmp         #KEY_ESC
    bne         :+
    sta         KBDSTRB
    jmp         monitor
:

    jmp         loop
;                                             --V--                 XX
thrustX0:       .byte   256-20, 256-10, 256-5,  0,      5,  10, 20, 20
thrustX1:       .byte   $ff,    $ff,    $ff,    0,      0,  0,  0,  0
thrustY0:       .byte   256-25, 256-20, 256-15, 256-10, 5, 10,  15, 15   ; center = thrust up
thrustY1:       .byte   $ff,    $ff,    $ff,    $ff,    0,  0,  0,  0

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
PLAYER_ROW3_0   = $550 + PLAYER_XOFFSET     ; 18 (36)
PLAYER_ROW0_1   = $400 + PLAYER_ROW0_0
PLAYER_ROW1_1   = $400 + PLAYER_ROW1_0
PLAYER_ROW2_1   = $400 + PLAYER_ROW2_0
PLAYER_ROW3_1   = $400 + PLAYER_ROW3_0
PLAYER_COLOR0   = $FF
PLAYER_COLOR1   = $F5
PLAYER_COLLISION_COLOR0 = $99
PLAYER_COLLISION_COLOR1 = $90

REFUEL_COLOR = $22

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
    lda         gravityVec
    bne         :+
    lda         #REFUEL_COLOR
    sta         PLAYER_ROW3_0+0
    sta         PLAYER_ROW3_0+1
    sta         PLAYER_ROW3_0+4
    sta         PLAYER_ROW3_0+5
:
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
    lda         gravityVec
    bne         :+
    lda         #REFUEL_COLOR
    sta         PLAYER_ROW3_1+0
    sta         PLAYER_ROW3_1+1
    sta         PLAYER_ROW3_1+4
    sta         PLAYER_ROW3_1+5
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
    cpy         PLAYER_ROW2_0+5
    beq         :+
    ora         #COLLISION_BOTTOM_RIGHT
:
    ; for bottom mid, should check all 4 location, but just check 2 middle are clear
    ; This is done by ORing +2 and the ANDing +3 if not set.
    ; This could result in BOTTOM being set without right/left or mid, which can
    ; still be interpreted as bottom middle
    cpy         PLAYER_ROW2_0+2
    beq         :+
    ora         #COLLISION_BOTTOM_MID
:
    cpy         PLAYER_ROW2_0+3
    bne         :+
    and         #COLLISION_BOTTOM_MID_MASK
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
    cpy         PLAYER_ROW2_1+2
    beq         :+
    ora         #COLLISION_BOTTOM_MID
:
    cpy         PLAYER_ROW2_1+3
    bne         :+
    and         #COLLISION_BOTTOM_MID_MASK
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
    ror
    bcc         :+
    ; Land
    sty         gravityVec
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
FUEL_MAX_CONSUMPTION    = 10

FUEL_LEVEL_MAX          = 39

.proc increaseFuel
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
    jmp         updateFuel
:
    ldx         #SOUND_REFUEL
    jsr         playSound
    jmp         updateFuel
.endproc

.proc decreaseFuel

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
    jmp         updateFuel

consumption:    .byte       0

.endproc

.proc updateFuel
    ldx         fuelLevel
    lda         fuelStatusColor,x
fuelLoop:
    sta         fuelColor,x
    dex
    bne         fuelLoop
    rts

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
time0:              .byte   0
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
fuelLevel:          .byte   FUEL_LEVEL_MAX
gravityVec:         .byte   GRAVITY

shipColor0:         .byte   PLAYER_COLOR0
shipColor1:         .byte   PLAYER_COLOR1

; define for width of screen (40), but only read relevant ones
fuelColor:      .res    40

.align 256

RESULT_CLEAR_VX         =   %0000001
RESULT_CLEAR_VY         =   %0000010
RESULT_MOVE_DOWN        =   %0000100
RESULT_MOVE_RIGHT       =   %0001000
RESULT_MOVE_LEFT        =   %0010000
RESULT_MOVE_UP          =   %0100000
RESULT_SET_LAND         =   %1000000

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
RESULT_LAND             = RESULT_SET_LAND | RESULT_ALL_UP

;32 bytes
; bit pattern = bottom mid right left top
collisionResultTable:                                                                   ; * = illegal
    .byte   0,              RESULT_DOWN,        RESULT_RIGHT,       RESULT_DOWN_RIGHT   ; 00000  00001  00010  00011
    .byte   RESULT_LEFT,    RESULT_DOWN_LEFT,   RESULT_ALL_UP,      RESULT_ALL_DOWN     ; 00100  00101  00110  00111
    .byte   0,              RESULT_DOWN,        RESULT_RIGHT,       RESULT_DOWN_RIGHT   ; 01000* 01001* 01010* 01011*
    .byte   RESULT_LEFT,    RESULT_DOWN_LEFT,   RESULT_ALL_UP,      RESULT_ALL_DOWN     ; 01100* 01101* 01110* 01111*
    .byte   RESULT_UP,      RESULT_ALL_STOP,    RESULT_UP_RIGHT,    RESULT_ALL_RIGHT    ; 10000  10001  10010  10011
    .byte   RESULT_UP_LEFT, RESULT_ALL_LEFT,    RESULT_UP,          RESULT_ALL_STOP     ; 10100  10101  10110  10111
    .byte   RESULT_UP,      RESULT_ALL_STOP,    RESULT_UP_RIGHT,    RESULT_ALL_RIGHT    ; 11000  11001  11010  11011
    .byte   RESULT_UP_LEFT, RESULT_ALL_LEFT,    RESULT_LAND,        RESULT_ALL_STOP     ; 11100  11101  11110  11111


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
        ;        0000

; 00 - empty
        .byte   %0000       ; ____
        .byte   %0000       ; ____
        .byte   %0000       ; ____
        .byte   %0000       ; ____

; 04 - solid
        .byte   %1111       ; ####
        .byte   %1111       ; ####
        .byte   %1111       ; ####
        .byte   %1111       ; ####

; 08 - se
        .byte   %1111       ; ####
        .byte   %0111       ; ###_
        .byte   %0011       ; ##__
        .byte   %0001       ; #___

; 0C - sw
        .byte   %0001       ; ####
        .byte   %0011       ; _###
        .byte   %0111       ; __##
        .byte   %1111       ; ___#

; 10 - ne
        .byte   %1111       ; #___
        .byte   %1110       ; ##__
        .byte   %1100       ; ###_
        .byte   %1000       ; ####

; 14 - nw
        .byte   %1000       ; ___#
        .byte   %1100       ; __##
        .byte   %1110       ; _###
        .byte   %1111       ; ####

; 18 - dot
        .byte   %0110       ; _##_
        .byte   %1111       ; ####
        .byte   %1111       ; ####
        .byte   %0110       ; _##_

; 1c - rough floor 1
        .byte   %1000       ; ____
        .byte   %1110       ; _#__
        .byte   %0000       ; _#_#
        .byte   %1100       ; ##_#

; 20 - rough floor 2
        .byte   %1000       ; ____
        .byte   %1100       ; __#_
        .byte   %1110       ; ###_
        .byte   %1000       ; ####

; 24 - rough floor 3
        .byte   %0000       ; ____
        .byte   %1000       ; ____
        .byte   %0000       ; ____
        .byte   %1000       ; _#_#

; 28 - steep rise 1 left
        .byte   %1100       ; _###
        .byte   %1111       ; _###
        .byte   %1111       ; ####
        .byte   %1111       ; ####

; 2c - steep rise 2 left
        .byte   %0000       ; ___#
        .byte   %0000       ; ___#
        .byte   %1100       ; __##
        .byte   %1111       ; __##

; 30 - steep rise 1 right
        .byte   %1111       ; ###_
        .byte   %1111       ; ###_
        .byte   %1111       ; ####
        .byte   %1100       ; ####

; 34 - steep rise 2 right
        .byte   %1111       ; #___
        .byte   %1100       ; #___
        .byte   %0000       ; ##__
        .byte   %0000       ; ##__

; 38 - rough ceiling 1
        .byte   %0001       ; ####
        .byte   %1111       ; _##_
        .byte   %0011       ; _#__
        .byte   %0001       ; _#__

; 3c - rough ceiling 2
        .byte   %0000       ; _###
        .byte   %0001       ; __#_
        .byte   %0011       ; ____
        .byte   %0001       ; ____

; 40 - rough ceiling 3
        .byte   %0011       ; #_##
        .byte   %0000       ; #_#_
        .byte   %0111       ; __#_
        .byte   %0001       ; ____

; 41 - rough left wall
        .byte   %1111       ; ####
        .byte   %1111       ; ###_
        .byte   %1111       ; ####
        .byte   %0101       ; ###_

; 42 - rough right wall
        .byte   %0101       ; ####
        .byte   %1111       ; _###
        .byte   %1111       ; ####
        .byte   %1111       ; _###

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
XWL = $44
XWR = $48

map:
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,XSW,XSE,X__,XSW,XC1,XC2,XC3,XC2,XSW,XXX,XXX,XXX,XXX,XXX,XSW,XSE,X__,XSW,XSE,XC1,XC2,XC3,XC2,XSW,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XNE,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XXX,XXX,XR1,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XWR,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,XOO,XOO,X__,X__,X__,X__,X__,XSW,XXX,XXX,XSE,X__,X__,X__,XOO,X__,XOO,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XWL,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XOO,X__,XOO,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XF1,XF2,XF3,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,XF3,XF2,XL1,XXX,XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL1,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XR1,XF2,XF3,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XWL,X__,X__,X__,X__,X__,X__,X__,XC3,XC2,XSW,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,XWR,XXX,XXX
    .byte   XXX,XXX,XXX,XWL,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XWL,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XXX,XXX,XR1,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XSW,XXX,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XWR,XXX,XXX
    .byte   XXX,XXX,XXX,XWL,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XWR,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XWR,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XF1,XF2,XF3,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,X__,X__,X__,X__,X__,X__,X__,XF3,XF2,XL1,XXX,XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL1,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XF1,XF2,XNE,XNW,XXX,XXX,XXX,XXX,XXX,XXX,XR1,XF2,XF3,XF1,XF1,XF2,XF1,XNW,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX

