;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; Apple Escape
; (Based on Binary Art's Safari Rush Hour table top puzzle game,
;  which is now out unfortunately out of print.)

;------------------------------------------------
; Constants
;------------------------------------------------

.include "defines.asm"
.include "macros.asm"

.segment "CODE"
.org    $2000

TILE_WIDTH      = 5         ; 5 bytes wide
TILE_HEIGHT     = 3         ; 3 bytes high

GRID_X          = 5
GRID_Y          = 5
GRID_HEIGHT     = 7
GRID_WIDTH      = 7

CURSOR_COLOR    = $DD

OFFSET_LEFT     = 2
OFFSET_TOP      = 3

SHAPE_PLAYER    = 0
SHAPE_2X1       = 1
SHAPE_3X1       = 2
SHAPE_1X2       = 3
SHAPE_1X3       = 4
SHAPE_2x2       = 5

MAP_WALL        = $40
MAP_EMPTY       = $80

INPUT_NONE      = $00
INPUT_RIGHT     = $01
INPUT_LEFT      = $02
INPUT_UP        = $04
INPUT_DOWN      = $08
INPUT_ACTION    = $10
INPUT_OTHER     = $40
INPUT_BUTTON    = $80

.proc main


;**** HACK ***

    ;jmp         particleDemo

;*************

    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode

    lda         #$04        ; display low screen, draw high screen
    sta         drawPage

    jsr         drawBackground

    lda         #0
    sta         levelNumber

levelLoop:
    jsr         loadLevel
    jsr         drawLevel

    ; init cursor
    lda         #20
    sta         curX
    sta         curY

    jsr         getBG
    sta         cursorBG
    lda         #CURSOR_COLOR
    jsr         drawDot

gameLoop:
    jsr         screenFlip

    ; Erase
    ;---------------------------
    lda         selected
    bmi         :+
    jmp         checkInput
:
    lda         cursorBG
    jsr         drawDot

    ; Check input
    ;---------------------------
checkInput:
    jsr         getInput
    sta         tempZP

    ; Update position
    ;---------------------------
    lda         #INPUT_UP
    bit         tempZP
    beq         :+
    dec         curY
    jsr         checkCollision
    beq         :+
    inc         curY
:
    lda         #INPUT_DOWN
    bit         tempZP
    beq         :+
    inc         curY
    jsr         checkCollision
    beq         :+
    dec         curY
:
    lda         #INPUT_LEFT
    bit         tempZP
    beq         :+
    dec         curX
    jsr         checkCollision
    beq         :+
    inc         curX
:
    lda         #INPUT_RIGHT
    bit         tempZP
    beq         :+
    inc         curX
    jsr         checkCollision
    beq         :+
    dec         curX
:

    ; Check highlight
    jsr         readMap
    sta         curMap
    cmp         highlight
    beq         doneHighlight

    ; draw previously highlighted shape as not highlighted
    ldy         highlight
    bmi         :+
    jsr         drawLevelShape
    sta         SPEAKER             ; click when "dropped"
:

    ; draw new highlighted shape
    ldy         curMap
    sty         highlight
    bmi         :+
    jsr         drawLevelShapeHighlight
:

doneHighlight:

    ; draw
    jsr         getBG
    sta         cursorBG
    lda         #$DD
    jsr         drawDot

    jmp         gameLoop

cursorBG:       .byte   0
curMap:         .byte   0

.endproc



;-----------------------------------------------------------------------------
; Get input
;   Return joystick or keyboard input
;-----------------------------------------------------------------------------

.proc getInput

    lda         #16
    sta         timeout         ; if no input after about 1/10 of a second

loop:
    ldx         #0
    jsr         PREAD           ; read joystick X
    sty         paddleX

    jsr         wait
    bmi         keypress

    ldx         #1
    jsr         PREAD           ; read joystick 1
    sty         paddleY

    jsr         wait
    bmi         keypress

    ; check if button changed state
    lda         BUTTON0
    and         #$80
    cmp         button0
    beq         :+
    sta         button0
    lda         #INPUT_BUTTON
    rts
:

    ; if no keyboard or button, return joystick direction if any

    ; quantize joystick coordinates
    lda         paddleX
    rol
    rol
    rol
    and         #$03
    sta         tempZP          ; X[7:6] -> [1:0]
    lda         paddleY
    ror
    ror
    ror
    ror
    and         #$0c            ; Y[7:6] -> [3:2]
    ora         tempZP
    tax
    lda         joystickDirection,x
    beq         :+
    rts
:
    dec         timeout
    bne         loop
    lda         #0
    rts

keypress:
    sta         lastKey
    sta         KBDSTRB
    cmp         #KEY_RIGHT
    bne         :+
    lda         #INPUT_RIGHT
    rts
:
    cmp         #KEY_LEFT
    bne         :+
    lda         #INPUT_LEFT
    rts
:
    cmp         #KEY_UP
    bne         :+
    lda         #INPUT_UP
    rts
:
    cmp         #KEY_DOWN
    bne         :+
    lda         #INPUT_DOWN
    rts
:
    cmp         #KEY_SPACE
    bne         :+
    lda         #INPUT_ACTION
    rts
:
    lda         #INPUT_OTHER
    rts

wait:
    ; wait at least 3 miliseconds
    ; 231 * 13 =~ 3000
    ldx         #230
:
    lda         KBD             ; 4
    bmi         doneWait        ; 2 (not taken)
    nop                         ; 2
    dex                         ; 2
    bne         :-              ; 3 (taken)
doneWait:
    rts

; 4x4 Look up table of joystick directions
joystickDirection:
                .byte   INPUT_LEFT|INPUT_UP,   INPUT_UP,   INPUT_UP,   INPUT_RIGHT|INPUT_UP
                .byte   INPUT_LEFT,            0,          0,          INPUT_RIGHT
                .byte   INPUT_LEFT,            0,          0,          INPUT_RIGHT
                .byte   INPUT_LEFT|INPUT_DOWN, INPUT_DOWN, INPUT_DOWN, INPUT_RIGHT|INPUT_DOWN

timeout:        .byte   0

.endproc

;-----------------------------------------------------------------------------
; Set selected
;-----------------------------------------------------------------------------
.proc setSelected
    sta         selected

    ; set offset
    sec
    lda         curX
    sbc         levelDataX,y   ; x cord
    sta         selectedOffsetX
    sec
    lda         curY
    sbc         levelDataY,y   ; y cord
    sta         selectedOffsetY

    ; set cursor
    lda         levelDataX,y   ; x cord
    sta         curX
    lda         levelDataY,y   ; x cord
    sta         curY

    ; look up movement
    lda         levelDataShape,y
    tay
    lda         moveHorizontalTable,y
    sta         moveHorizontal
    lda         moveVerticalTable,y
    sta         moveVertical
    lda         collisionMaskTable,y
    sta         collisionMask

    ; remove from collision map
    lda         #MAP_EMPTY
    sta         shapeIndex
    lda         selected
    jsr         setCollisionMap

    rts

.endproc

;-----------------------------------------------------------------------------
; Clear selected
;-----------------------------------------------------------------------------
.proc clearSelected

    ; snap to grid
    ldx         curX
    lda         snapX,x
    sta         curX

    ldx         curY
    lda         snapY,x
    sta         curY

    ; update data
    ldy         selected
    lda         curX
    sta         levelDataX,y
    lda         curY
    sta         levelDataY,y

    ; restore cursor
    clc
    lda         curX
    adc         selectedOffsetX
    sta         curX

    lda         curY
    adc         selectedOffsetY
    sta         curY

    ; free movement
    lda         #1
    sta         moveHorizontal
    sta         moveVertical

    ; restore collision map
    lda         selected
    sta         shapeIndex
    jsr         setCollisionMap

    ; unselect
    lda         #$ff
    sta         selected

    rts

.endproc

;-----------------------------------------------------------------------------
; draw background
;-----------------------------------------------------------------------------
.proc drawBackground

    lda         #0
    sta         index
    sta         tileY

loopY:
    lda         #0
    sta         tileX
loopX:
    ldy         index
    lda         background,y
    jsr         drawTile
    clc
    lda         tileX
    adc         #TILE_WIDTH
    sta         tileX
    inc         index
    lda         tileX
    cmp         #40
    bne         loopX

    clc
    lda         tileY
    adc         #TILE_HEIGHT
    sta         tileY

    lda         index
    cmp         #8*8
    bne         loopY
    rts

index:      .byte   0
mapX:       .byte   0

background:
    .byte   $0, $1, $1, $1, $1, $1, $1, $2
    .byte   $3, $4, $4, $4, $4, $4, $4, $7
    .byte   $3, $4, $4, $4, $4, $4, $4, $5
    .byte   $3, $4, $4, $4, $4, $4, $4, $6
    .byte   $3, $4, $4, $4, $4, $4, $4, $7
    .byte   $3, $4, $4, $4, $4, $4, $4, $7
    .byte   $8, $9, $9, $9, $9, $9, $9, $A
    .byte   $B, $C, $C, $C, $C, $C, $C, $D
.endproc

;-----------------------------------------------------------------------------
; load level
;-----------------------------------------------------------------------------
.proc loadLevel

    jsr         initLevel

    lda         #$FF
    sta         shapeIndex
    ldx         levelNumber
    lda         levelTable,x
    sta         mapPtr0
    lda         levelTable+1,x
    sta         mapPtr1

    ldy         #0
loop:
    inc         shapeIndex          ; shapeIndex = y/3
    ldx         shapeIndex
    lda         (mapPtr0),y
    sta         levelDataShape,x    ; shape
    bpl         :+                  ; check if done
    rts                             ; done
:
    iny
    lda         (mapPtr0),y
    tax
    lda         translateX,x
    ldx         shapeIndex
    sta         levelDataX,x        ; x cord
    iny
    lda         (mapPtr0),y
    tax
    lda         translateY,x
    ldx         shapeIndex
    sta         levelDataY,x        ; y cord
    iny

    sty         tempY
    lda         shapeIndex
    jsr         setCollisionMap
    ldy         tempY

    jmp         loop

tempY:          .byte   0

.endproc

;-----------------------------------------------------------------------------
; Set collision map
;-----------------------------------------------------------------------------
.proc setCollisionMap
    tay

    ; fill in collision map
    clc
    ldx         levelDataX,y   ; x
    lda         levelX,x
    ldx         levelDataY,y   ; y
    adc         levelY,x
    tax

    lda         levelDataShape,y

    cmp         #SHAPE_2X1
    bne         :+
    lda         shapeIndex
    sta         levelMap,x
    sta         levelMap+1,x
    rts
:
    cmp         #SHAPE_3X1
    bne         :+
    lda         shapeIndex
    sta         levelMap,x
    sta         levelMap+1,x
    sta         levelMap+2,x
    rts
:
    cmp         #SHAPE_1X2
    bne         :+
    lda         shapeIndex
    sta         levelMap,x
    sta         levelMap+9,x
    rts
:
    cmp         #SHAPE_1X3
    bne         :+
    lda         shapeIndex
    sta         levelMap,x
    sta         levelMap+9,x
    sta         levelMap+18,x
    rts
:
    ; must be 2x2
    lda         shapeIndex
    sta         levelMap,x
    sta         levelMap+1,x
    sta         levelMap+9,x
    sta         levelMap+10,x
    rts

.endproc

;-----------------------------------------------------------------------------
; Init level
;-----------------------------------------------------------------------------

.proc initLevel
    ; clear selection
    lda         #MAP_EMPTY
    sta         highlight
    sta         selected

    ; clear collision map
    ldy         #0
loop:
    lda         emptyMap,y
    sta         levelMap,y
    iny
    cpy         #9*9
    bne         loop
    rts
.endproc

;-----------------------------------------------------------------------------
; read map
;   return level map data at curX,curY (Should this be tileX,tileY?)
;-----------------------------------------------------------------------------

.proc readMap
    clc
    ldx         curX
    lda         levelX,x
    ldx         curY
    adc         levelY,x
    tax
    lda         levelMap,x
    rts
.endproc

;-----------------------------------------------------------------------------
; check collision
;
;   Return 0 if no collision
;-----------------------------------------------------------------------------

.proc checkCollision
    lda         selected
    bpl         checkShape

    ; for cursor, only check wall
    jsr         readMap
    cmp         #MAP_WALL
    beq         cursorCollision
    lda         #0
    rts

collision:
    lda         tempX
    sta         curX
    lda         tempY
    sta         curY
cursorCollision:
    lda         #1
    rts

checkShape:
    ;                           ; Collision 0
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         cursorCollision

    lda         curX
    sta         tempX
    lda         curY
    sta         tempY

    lda         collisionMask
    and         #%000010        ; Collision 1: x+9
    beq         :+
    clc
    lda         tempX
    adc         #9
    sta         curX
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         collision
    lda         tempX
    sta         curX
:
    lda         collisionMask
    and         #%000100        ; Collision 2: x+14
    beq         :+
    clc
    lda         tempX
    adc         #14
    sta         curX
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         collision
    lda         tempX
    sta         curX
:
    lda         collisionMask
    and         #%001000        ; Collision 3: y+9
    beq         :+
    clc
    lda         tempY
    adc         #9
    sta         curY
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         collision
    lda         tempY
    sta         curY
:
    lda         collisionMask
    and         #%010000        ; Collision 4: x+9,y+9
    beq         :+
    clc
    lda         tempX
    adc         #9
    sta         curX
    lda         tempY
    adc         #9
    sta         curY
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         fail
    lda         tempX
    sta         curX
    lda         tempY
    sta         curY
:
    lda         collisionMask
    and         #%100000        ; Collision 5: y+14
    beq         :+
    clc
    lda         tempY
    adc         #14
    sta         curY
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         fail
    lda         tempY
    sta         curY
:
    ; no collisions
    lda         #0
    rts
fail:
    lda         tempX
    sta         curX
    lda         tempY
    sta         curY
    lda         #1
    rts

tempX:          .byte   0
tempY:          .byte   0

.endproc

;-----------------------------------------------------------------------------
; draw level
;-----------------------------------------------------------------------------
.proc drawLevel

    lda         #0
    sta         mapIndex
    tay

loop:
    ldy         mapIndex
    lda         levelDataShape,y
    bpl         :+              ; check if done
    rts                         ; done
:
    ldy         mapIndex
    jsr         drawLevelShape
    inc         mapIndex
    jmp         loop

mapIndex:       .byte       0

.endproc

.proc drawLevelShape
    lda         levelDataShape,y
    asl
    tax
    lda         levelDataX,y
    sta         tileX
    lda         levelDataY,y
    sta         tileY
    lda         shapeTable,x
    sta         tilePtr0
    lda         shapeTable+1,x
    sta         tilePtr1
    jsr         drawShape
    rts
.endproc

.proc drawLevelShapeHighlight
    lda         levelDataShape,y
    asl
    tax
    lda         levelDataX,y
    sta         tileX
    lda         levelDataY,y
    sta         tileY
    lda         shapeTable+16,x
    sta         tilePtr0
    lda         shapeTable+17,x
    sta         tilePtr1
    jsr         drawShape
    rts
.endproc

.proc eraseLevelShape
    lda         levelDataShape,y
    asl
    tax
    lda         levelDataX,y
    sta         tileX
    lda         levelDataY,y
    sta         tileY
    lda         shapeTable,x
    sta         tilePtr0
    lda         shapeTable+1,x
    sta         tilePtr1
    jsr         eraseShape
    rts
.endproc

;-----------------------------------------------------------------------------
; soundTone
;-----------------------------------------------------------------------------
; A = tone
; X = duration
.proc soundTone
loop1:
    sta         SPEAKER
    tay
loop2:
    nop
    nop
    nop
    nop                     ; add some delay for lower notes
    dey
    bne         loop2
    dex
    bne         loop1
    rts

.endproc

;-----------------------------------------------------------------------------
; soundWalk
;-----------------------------------------------------------------------------
.proc soundWalk
    lda         #50         ; tone
    ldx         #5          ; duration
    jsr         soundTone
    lda         #190        ; tone
    ldx         #3          ; duration
    jmp         soundTone   ; link returns
.endproc

;-----------------------------------------------------------------------------
; soundBump
;-----------------------------------------------------------------------------
.proc soundBump
    lda         #100        ; tone
    ldx         #20         ; duration
    jsr         soundTone
    lda         #90         ; tone
    ldx         #10         ; duration
    jmp         soundTone   ; link returns
.endproc

;-----------------------------------------------------------------------------
; drawTile      - draw 5x6 tile (tileY = pixel row/2)
;-----------------------------------------------------------------------------

;-----------------
.proc setTilePtr
;-----------------
    ; calculate tile pointer
    sta         tileIdx         ; Save a copy of A
    asl
    asl
    asl
    asl                         ; multiple by 16
    clc
    adc         #<tileSheet
    sta         tilePtr0

    lda         #0
    adc         #>tileSheet
    sta         tilePtr1
    lda         tileIdx
    lsr
    lsr
    lsr
    lsr                         ; Divide by 16
    clc
    adc         tilePtr1
    sta         tilePtr1
    rts
.endproc

;-------------------
.proc setScreenPtr
;-------------------
    ; calculate screen pointer
    ldy         tempZP          ; copy of tileY
    lda         tileX
    clc
    adc         lineOffset,y    ; + lineOffset
    sta         screenPtr0
    lda         linePage,y
    adc         drawPage        ; previous carry should be clear
    sta         screenPtr1
    rts
.endproc

;--------------
.proc drawTile
;--------------

    jsr         setTilePtr

    ; copy tileY
    lda         tileY
    sta         tempZP

    ; 3 rows
    ldx         #TILE_HEIGHT

loopy:
    jsr         setScreenPtr
    ; set 5 bytes
    ldy         #TILE_WIDTH-1
loopx:
    lda         (screenPtr0),y
    lda         (tilePtr0),y
    sta         (screenPtr0),y
    dey
    bpl         loopx

    lda         tilePtr0
    adc         #TILE_WIDTH
    sta         tilePtr0

    inc         tempZP      ; next line

    dex
    bne         loopy

    rts

.endproc


;-----------------------------------------------------------------------------
; Monitor
;
;  Exit to monitor
;-----------------------------------------------------------------------------
.proc monitor
    bit         LOWSCR          ; display low screen

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


; Libraries
;-----------------------------------------------------------------------------

; add utilies
.include "inline_print.asm"
.include "grlib.asm"
.include "particles.asm"


; Globals
;-----------------------------------------------------------------------------

; input values
paddleX:            .byte   0
paddleY:            .byte   0
button0:            .byte   0
lastKey:            .byte   0

highlight:          .byte   0
selected:           .byte   $ff         ; Negative = none
selectedOffsetX:    .byte   0
selectedOffsetY:    .byte   0
levelNumber:        .byte   0

moveHorizontal:     .byte   1
moveVertical:       .byte   1
collisionMask:      .byte   0

shapeIndex:         .byte   0

.align 256

;levelData:          .res    3*20
levelDataShape:      .res   20
levelDataX:          .res   20
levelDataY:          .res   20

; 9x9 map for collisions
; $80 = free space
; $40 = wall
;                        -1    0    1    2    3    4    5    6    7
emptyMap:           .byte   $40, $40, $40, $40, $40, $40, $40, $40, $40     ; -1
                    .byte   $40, $80, $80, $80, $80, $80, $80, $80, $40     ; 0
                    .byte   $40, $80, $80, $80, $80, $80, $80, $80, $40     ; 1
                    .byte   $40, $80, $80, $80, $80, $80, $80, $80, $80     ; 2
                    .byte   $40, $80, $80, $80, $80, $80, $80, $80, $80     ; 3
                    .byte   $40, $80, $80, $80, $80, $80, $80, $80, $40     ; 4
                    .byte   $40, $80, $80, $80, $80, $80, $80, $80, $40     ; 5
                    .byte   $40, $80, $80, $80, $80, $80, $80, $80, $40     ; 6
                    .byte   $40, $40, $40, $40, $40, $40, $40, $40, $40     ; 7

levelMap:           .res    9*9

; translate screen position to level map

levelX:             .byte   0, 0                ;  0..1
                    .byte   1, 1, 1, 1, 1       ;  2..6
                    .byte   2, 2, 2, 2, 2       ;  7..11
                    .byte   3, 3, 3, 3, 3       ; 12..16
                    .byte   4, 4, 4, 4, 4       ; 17..21
                    .byte   5, 5, 5, 5, 5       ; 22..26
                    .byte   6, 6, 6, 6, 6       ; 27..31
                    .byte   7, 7, 7, 7, 7       ; 32..36
                    .byte   8, 8, 8             ; 37..39

levelY:             .byte   0,  0,  0           ;  0..2
                    .byte   9,  9,  9,  9, 9    ;  3..7
                    .byte   18, 18, 18, 18, 18  ;  8..12
                    .byte   27, 27, 27, 27, 27  ; 13..17
                    .byte   36, 36, 36, 36, 36  ; 18..22
                    .byte   45, 45, 45, 45, 45  ; 23..27
                    .byte   54, 54, 54, 54, 54  ; 28..32
                    .byte   63, 63, 63, 63, 63  ; 33..37
                    .byte   72, 72              ; 38..39

; Snap to screen position
snapX:              .byte    2,  2,  2,  2,  2
                    .byte    7,  7,  7,  7,  7
                    .byte   12, 12, 12, 12, 12
                    .byte   17, 17, 17, 17, 17
                    .byte   22, 22, 22, 22, 22
                    .byte   27, 27, 27, 27, 27
                    .byte   32, 32, 32, 32, 32
                    .byte   37, 37, 37, 37, 37

snapY:              .byte    3
                    .byte    3,  3,  3,  3,  3
                    .byte    8,  8,  8,  8,  8
                    .byte   13, 13, 13, 13, 13
                    .byte   18, 18, 18, 18, 18
                    .byte   23, 23, 23, 23, 23
                    .byte   28, 28, 28, 28, 28
                    .byte   33, 33, 33, 33, 33
                    .byte   33, 33, 33, 33

; Lookup tables
;-----------------------------------------------------------------------------

.align 256

translateX:
.repeat 7, I
     .byte   I*GRID_X+OFFSET_LEFT
.endrepeat

translateY:
.repeat 7, I
     .byte   I*GRID_Y+OFFSET_TOP
.endrepeat

;-----------------------------------------------------------------------------
; Graphic shapes
;-----------------------------------------------------------------------------

.include "tiles.asm"
.include "shapes.asm"
.include "levels.asm"

