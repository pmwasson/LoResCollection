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

UNDO_SIZE       = 8

.proc main

    jmp         mapDemo

    ; init

    lda         #0
    sta         joystickEnable
    sta         shiftTime

    jsr         setParticleColors

    lda         #1
    sta         levelNumber
    lda         #$05
    sta         bg0
    lda         #$50
    sta         bg1
    lda         #$55
    sta         bg2

    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    bit         MIXCLR

levelLoop:
    lda         #$00        ; clear low screen
    sta         drawPage
    jsr         clearScreen
    lda         #$20        ; inverse space
    bit         LOWSCR

    ldy         #0
:
    jsr         wait
    dey
    bne         :-

    lda         #$04        ; display low screen, draw high screen
    sta         drawPage

    jsr         loadLevel
    jsr         undoReset

redrawLoop:
    jsr         drawLevelNumber
    lda         #1
    sta         bannerActive

    jsr         drawBackground
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

    clc
    lda         shiftTime
    adc         inputDelay
    sta         shiftTime
    sec
    sbc         #16
    bcc         :+
    sta         shiftTime
    lda         bannerActive
    beq         :+
    jsr         bannerRotateLeft
    bne         :+
    lda         #0
    sta         bannerActive        ; set to 0
:


    ; Erase
    ;---------------------------
    ldy         selected
    bmi         :+
    lda         selected
    jsr         eraseLevelShape
    jmp         checkInput          ; no cursor if selected shape
:
    lda         cursorBG
    jsr         drawDot

    ; Check input
    ;---------------------------
checkInput:
    jsr         getInput
    sta         inputResult

    ; Update position
    ;---------------------------
    jsr         canMoveVertical
    beq         skipVertical

    lda         #INPUT_UP
    bit         inputResult
    beq         :+
    jsr         updateLockV
    dec         curY
    jsr         checkCollision
    beq         :+
    inc         curY
:
    lda         #INPUT_DOWN
    bit         inputResult
    beq         :+
    jsr         updateLockV
    inc         curY
    jsr         checkCollision
    beq         :+
    dec         curY
:

skipVertical:
    jsr         canMoveHorizontal
    beq         skipHorizontal

    lda         #INPUT_LEFT
    bit         inputResult
    beq         :+
    jsr         updateLockH
    dec         curX
    jsr         checkCollision
    beq         :+
    inc         curX
:
    lda         #INPUT_RIGHT
    bit         inputResult
    beq         :+
    jsr         updateLockH
    inc         curX
    jsr         checkCollision
    beq         :+
    dec         curX
:

skipHorizontal:
    lda         #INPUT_OTHER
    bit         inputResult
    beq         doneOther
    lda         lastKey

    cmp         #KEY_U
    bne         :+
    jsr         undoReplay
    beq         doneOther
    jmp         redrawLoop
:
    cmp         #KEY_R
    bne         :+
    jsr         undoRedo
    beq         doneOther
    jmp         redrawLoop
:
    cmp         #KEY_ESC
    bne         :+
    jsr         TEXT
    brk
:
    cmp         #KEY_TAB
    bne         :+
    jsr         nextLevelNumber
    jmp         levelLoop
:
    cmp         #KEY_RETURN
    bne         :+
    jmp         levelLoop
:
    cmp         #KEY_D
    bne         :+
    jmp         particleDemo
:
doneOther:

    ; check map
    jsr         readMap
    sta         curMap

    ; New Selection
    jsr         isNewSelection
    beq         :+
    lda         curMap
    jsr         setSelected
    jmp         drawSelected
:

    ; Drop selection
    jsr         isDropSelection
    beq         :+
    jsr         clearSelected
    sta         SPEAKER
    ; assuming highlight will draw the dropped selection
:
    ; draw selected
    ldy         selected
    bmi         checkHighlight
    jsr         updateSelected

drawSelected:
    jsr         drawLevelShapeHighlight
    lda         winCondition
    beq         :+
    jsr         nextLevelNumber
    jsr         winner
    jmp         levelLoop
:
    jmp         gameLoop

checkHighlight:
    ; Check highlight
    lda         curMap
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

isNewSelection:
    lda         selected
    bpl         noNewSelection  ; already have selection
    lda         curMap
    bmi         noNewSelection  ; nothing under cursor

    lda         #INPUT_BUTTON
    bit         inputResult
    beq         :+              ; no button change, check keyboard
    lda         button0
    bpl         :+              ; button released (not pressed)
    lda         #1
    rts
:
    lda         #INPUT_ACTION
    bit         inputResult
    beq         noNewSelection
    lda         #1
    rts
noNewSelection:
    lda         #0
    rts

isDropSelection:
    lda         selected
    bmi         noDropSelection ; nothing selected

    lda         #INPUT_BUTTON
    bit         inputResult
    beq         :+              ; no button change, check keyboard
    lda         button0
    bmi         :+              ; button pressed (not released)
    lda         #1
    rts
:
    lda         #INPUT_ACTION
    bit         inputResult
    beq         noDropSelection
    lda         #1
    rts
noDropSelection:
    lda         #0
    rts

updateLockV:
    lda         moveBoth
    bne         :+
    rts
:
    ; make sure aligned
    lda         curX
    tax
    lda         snapX,x
    sta         curX

    lda         #1
    sta         moveVertical
    lda         #0
    sta         moveHorizontal
    rts

updateLockH:
    lda         moveBoth
    bne         :+
    rts
:

    ; make sure aligned
    lda         curY
    tax
    lda         snapY,x
    sta         curY

    lda         #0
    sta         moveVertical
    lda         #1
    sta         moveHorizontal
    rts

canMoveVertical:
    lda         moveVertical
    beq         :+
    lda         #1
    rts
:
    lda         moveBoth
    bne         :+
    lda         #0
    rts
:
    ; if move both, but not vertical, snap to grid
    lda         #1
    sta         moveVertical
    rts

canMoveHorizontal:
    lda         moveHorizontal
    beq         :+
    lda         #1
    rts
:
    lda         moveBoth
    bne         :+
    lda         #0
    rts
:
    ; if move both, but not horizontal, snap to grid
    lda         #1
    sta         moveHorizontal
    rts

setParticleColors:
    ldx         #15*2-1
:
    lda         winnerColors,x
    sta         particleColorTable,x
    dex
    bpl         :-
    rts

shiftTime:      .byte   0
cursorBG:       .byte   0
curMap:         .byte   0
inputResult:    .byte   0
bannerActive:   .byte   0

winnerColors:
    .byte   $0e, $e0        ; aqua
    .byte   $0e, $e0        ; aqua
    .byte   $0d, $d0        ; yellow
    .byte   $0e, $e0        ; aqua
    .byte   $0e, $e0        ; aqua

    .byte   $09, $90        ; orange
    .byte   $0e, $e0        ; aqua
    .byte   $0d, $d0        ; yellow
    .byte   $0e, $e0        ; aqua
    .byte   $09, $90        ; orange

    .byte   $0e, $e0        ; aqua
    .byte   $0e, $e0        ; aqua
    .byte   $0d, $d0        ; yellow
    .byte   $0e, $e0        ; aqua
    .byte   $0e, $e0        ; aqua

.endproc

;-----------------------------------------------------------------------------
; Get input
;   Return joystick or keyboard input
;-----------------------------------------------------------------------------

.proc getInput

    lda         #1
    sta         inputDelay

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
    ldy         joystickEnable
    beq         ignoreJoystick
    rts
:
    lda         #1
    sta         joystickEnable  ; joystick is centered
ignoreJoystick:
    inc         inputDelay
    lda         inputDelay
    cmp         #16+1           ; timeout
    bne         loop
    dec         inputDelay
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
    cmp         #KEY_A
    bne         :+
    lda         #INPUT_UP
    rts
:
    cmp         #KEY_DOWN
    bne         :+
    lda         #INPUT_DOWN
    rts
:
    cmp         #KEY_Z
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

; 4x4 Look up table of joystick directions
joystickDirection:
                .byte   INPUT_LEFT|INPUT_UP,   INPUT_UP,   INPUT_UP,   INPUT_RIGHT|INPUT_UP
                .byte   INPUT_LEFT,            0,          0,          INPUT_RIGHT
                .byte   INPUT_LEFT,            0,          0,          INPUT_RIGHT
                .byte   INPUT_LEFT|INPUT_DOWN, INPUT_DOWN, INPUT_DOWN, INPUT_RIGHT|INPUT_DOWN

timeout:        .byte   0

.endproc

;-----------------------------------------------------------------------------
; Update selected
;-----------------------------------------------------------------------------
.proc updateSelected
    ldy         selected
    lda         curX
    sta         levelDataX,y
    lda         curY
    sta         levelDataY,y

    ; check for win condition!
    lda         levelDataShape,y
    cmp         #SHAPE_PLAYER
    bne         :+                  ; check if player shape

    lda         curX
    cmp         #40-10
    bcc         :+                  ; check if over the left edge
    inc         winCondition        ; Winner!
:
    rts
.endproc

;-----------------------------------------------------------------------------
; Set selected
;-----------------------------------------------------------------------------
.proc setSelected
    sta         selected
    tay

    lda         levelDataX,y
    sta         selectedPrevX
    lda         levelDataY,y
    sta         selectedPrevY

    ; set offset
    sec
    lda         curX
    sbc         levelDataX,y   ; x cord
    sta         selectedOffsetX
    sec
    lda         curY
    sbc         levelDataY,y   ; y cord
    sta         selectedOffsetY

    ; set position
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
    lda         moveBothTable,y
    sta         moveBoth
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
    lda         #0
    sta         moveBoth

    ; restore collision map
    lda         selected
    sta         shapeIndex
    jsr         setCollisionMap

    ; record movement
    jsr         undoRecord

    ; unselect
    lda         #MAP_EMPTY
    sta         selected

    rts

.endproc

;-----------------------------------------------------------------------------
; draw background
;-----------------------------------------------------------------------------
.proc drawBackground

    lda         #0
    sta         index
    lda         #0
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
    .byte   $B, $B, $B, $B, $B, $B, $B, $B
.endproc

;-----------------------------------------------------------------------------
; load level
;-----------------------------------------------------------------------------
.proc loadLevel

    jsr         initLevel

    lda         #$FF
    sta         shapeIndex
    lda         levelNumber
    asl
    tax
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
    lda         #1
    sta         moveHorizontal
    sta         moveVertical
    lda         #0
    sta         moveBoth

    ; clear win condition
    lda         #0
    sta         winCondition

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

c1:
    lda         collisionMask
    and         #%000010        ; Collision 1: x+9
    beq         c2
    clc
    lda         tempX
    adc         #9
    sta         curX
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         collision
    ; check if at exit
    lda         selected
    beq         :+
    ldx         curX
    lda         levelX,x
    cmp         #8
    beq         collision       ; can't exit
:
    lda         tempX
    sta         curX
c2:
    lda         collisionMask
    and         #%000100        ; Collision 2: x+14
    beq         c3
    clc
    lda         tempX
    adc         #14
    sta         curX
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         collision
    ; check if at exit
    lda         selected
    beq         :+
    ldx         curX
    lda         levelX,x
    cmp         #8
    beq         collision       ; can't exit
:
    lda         tempX
    sta         curX
c3:
    lda         collisionMask
    and         #%001000        ; Collision 3: y+9
    beq         c4
    clc
    lda         tempY
    adc         #9
    sta         curY
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         fail
    lda         tempY
    sta         curY
c4:
    lda         collisionMask
    and         #%010000        ; Collision 4: x+9,y+9
    beq         c5
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
c5:
    lda         collisionMask
    and         #%100000        ; Collision 5: y+14
    beq         good
    clc
    lda         tempY
    adc         #14
    sta         curY
    jsr         readMap
    cmp         #MAP_EMPTY
    bne         fail
    lda         tempY
    sta         curY
good:
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
; Winner
;-----------------------------------------------------------------------------
.proc winner

    jsr         bannerReset
    lda         #<winnerString
    sta         stringPtr0
    lda         #>winnerString
    sta         stringPtr1

    lda         #1
    sta         bannerActive

    jsr         resetParticles

    lda         #0
    sta         index
    sta         time0
    sta         time1

loop:
    jsr         screenFlip
    jsr         eraseParticles

    lda         time0
    and         #$7
    bne         :+

    ldy         index
    lda         random5to35,y
    sta         curX
    lda         random5to35+1,y
    sta         curY
    jsr         allocateParticle
    jsr         allocateParticle
    jsr         allocateParticle
    inc         index
    inc         index

    lda         bannerActive
    beq         :+
    jsr         bannerRotateLeft
    bne         :+
    sta         bannerActive
:
    jsr         updateParticles
    jsr         drawParticles

    inc         time0
    bne         :+
    inc         time1
    lda         time1
    cmp         #3
    bne         :+
    rts
:
    lda         KBD
    bpl         loop
    sta         KBDSTRB
    rts

time0:          .byte   0
time1:          .byte   0
index:          .byte   0
bannerActive:   .byte   0
winnerString:   .byte   "COMPLETE   ",0
.endproc

;-----------------------------------------------------------------------------
; draw level number
;-----------------------------------------------------------------------------
.proc drawLevelNumber

    jsr         bannerReset
    lda         #<levelString
    sta         stringPtr0
    lda         #>levelString
    sta         stringPtr1

    lda         levelNumber

    cmp         #40
    bcc         :+
    ldx         #'4'
    stx         levelStringNumber
    lda         levelNumber
    sec
    sbc         #40
    jmp         remainder
:
    cmp         #30
    bcc         :+
    ldx         #'3'
    stx         levelStringNumber
    lda         levelNumber
    sec
    sbc         #30
    jmp         remainder
:
    cmp         #20
    bcc         :+
    ldx         #'2'
    stx         levelStringNumber
    lda         levelNumber
    sec
    sbc         #20
    jmp         remainder
:
    cmp         #10
    bcc         :+
    ldx         #'1'
    stx         levelStringNumber
    lda         levelNumber
    sec
    sbc         #10
    jmp         remainder
:
    ldx         #'0'
    stx         levelStringNumber
    lda         levelNumber
remainder:
    clc
    adc         #'0'
    sta         levelStringNumber+1
    rts

.endproc

levelString:        .byte   "LEVEL:",2
levelStringNumber:  .byte   "01"
                    .byte   1,"     ",0
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
; undoRecord
;-----------------------------------------------------------------------------
.proc undoRecord

    ; check if there was movement
    ldy         selected
    lda         levelDataX,y
    cmp         selectedPrevX
    bne         different
    lda         levelDataY,y
    cmp         selectedPrevY
    bne         different
    rts                         ; no change

different:
    ldx         undoPtr

    ; store transaction
    tya
    sta         undoTable+0,x   ; index
    lda         selectedPrevX
    sta         undoTable+1,x   ; prev X
    lda         selectedPrevY
    sta         undoTable+2,x   ; prev Y
    lda         levelDataX,y
    sta         undoTable+3,x   ; next X
    lda         levelDataY,y
    sta         undoTable+4,x   ; next Y

    ; point to next entry
    clc
    lda         undoPtr
    adc         #UNDO_SIZE
    sta         undoPtr
    tax

    ; mark end of history
    lda         #$ff
    sta         undoTable+0,x
    rts
.endProc

;-----------------------------------------------------------------------------
; undoReplay
;   return 0 if no change
;          1 if level data updated
;-----------------------------------------------------------------------------
.proc undoReplay

    lda         undoPtr
    sec
    sbc         #UNDO_SIZE
    sta         newUndoPtr
    tax

    lda         undoTable+0,x   ; index
    bpl         valid
    jsr         soundBump
    lda         #0
    rts

valid:
    ; remove from collision map
    lda         #MAP_EMPTY
    sta         shapeIndex
    lda         undoTable+0,x   ; index
    jsr         setCollisionMap

    ; update position
    ldx         newUndoPtr
    stx         undoPtr
    ldy         undoTable+0,x   ; index
    lda         undoTable+1,x   ; prev x
    sta         levelDataX,y
    lda         undoTable+2,x   ; prev x
    sta         levelDataY,y

    ; set from collision map
    tya
    sta         shapeIndex
    jsr         setCollisionMap

    lda         #1
    rts

newUndoPtr:     .byte       0

.endProc

;-----------------------------------------------------------------------------
; undoRedo
;   return 0 if no change
;          1 if level data updated
;-----------------------------------------------------------------------------
.proc undoRedo
    ldx         undoPtr
    lda         undoTable+0,x   ; index
    bpl         valid
    jsr         soundBump
    lda         #0
    rts

valid:
    ; remove from collision map
    lda         #MAP_EMPTY
    sta         shapeIndex
    lda         undoTable+0,x   ; index
    jsr         setCollisionMap

    ; update position
    ldx         undoPtr
    stx         undoPtr
    ldy         undoTable+0,x   ; index
    lda         undoTable+3,x   ; next x
    sta         levelDataX,y
    lda         undoTable+4,x   ; next y
    sta         levelDataY,y

    ; set from collision map
    tya
    sta         shapeIndex
    jsr         setCollisionMap

    clc
    lda         undoPtr
    adc         #UNDO_SIZE
    sta         undoPtr
    rts

.endproc

;-----------------------------------------------------------------------------
; undoReset
;   reset undo history
;-----------------------------------------------------------------------------
.proc undoReset
    lda         #0
    sta         undoPtr
    clc
loop:
    tay
    lda         #$ff
    sta         undoTable,y
    tya
    adc         #UNDO_SIZE
    bne         loop
    rts
.endproc

;-----------------------------------------------------------------------------
; next level number
;-----------------------------------------------------------------------------
.proc nextLevelNumber
    lda         levelNumber
    cmp         #LEVEL_COUNT
    beq         reset
    inc         levelNumber
    rts
reset:
    lda         #1
    sta         levelNumber
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
.include "font.asm"


; Globals
;-----------------------------------------------------------------------------

; input values
joystickEnable:     .byte   0
paddleX:            .byte   0
paddleY:            .byte   0
button0:            .byte   0
lastKey:            .byte   0
inputDelay:         .byte   0

highlight:          .byte   0
selected:           .byte   $ff         ; Negative = none
selectedOffsetX:    .byte   0
selectedOffsetY:    .byte   0
levelNumber:        .byte   0           ; level
winCondition:       .byte   0

moveHorizontal:     .byte   1
moveVertical:       .byte   1
moveBoth:           .byte   0           ; when set, lock in horizontal or veritcal
collisionMask:      .byte   0
shapeIndex:         .byte   0

; Undo info
undoPtr:            .byte   0
selectedPrevX:      .byte   0
selectedPrevY:      .byte   0

.align 256

;levelData:          .res    3*20
levelDataShape:      .res   20
levelDataX:          .res   20
levelDataY:          .res   20

; 9x9 map for collisions
; $80 = free space
; $40 = wall
;                            -1    0    1    2    3    4    5    6    7
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

random5to35:
                    .byte   14,  35,  29,  34,  21,  6 ,  10,  15
                    .byte   17,  14,  34,  18,  33,  10,  5 ,  28
                    .byte   5 ,  7 ,  23,  16,  15,  27,  22,  8
                    .byte   6 ,  35,  14,  8 ,  7 ,  27,  24,  34
                    .byte   30,  20,  35,  33,  18,  16,  7 ,  30
                    .byte   6 ,  30,  27,  24,  17,  11,  27,  31
                    .byte   32,  28,  31,  7 ,  30,  35,  27,  32
                    .byte   25,  13,  21,  18,  26,  27,  21,  7
                    .byte   32,  8 ,  10,  18,  5 ,  33,  8 ,  7
                    .byte   15,  31,  14,  6 ,  31,  21,  8 ,  13
                    .byte   10,  22,  19,  16,  30,  31,  21,  29
                    .byte   32,  14,  9 ,  18,  11,  24,  17,  13
                    .byte   35,  26,  24,  8 ,  34,  29,  26,  11
                    .byte   25,  28,  25,  24,  35,  8 ,  31,  31
                    .byte   25,  32,  10,  13,  14,  21,  6 ,  6
                    .byte   15,  27,  32,  10,  14,  19,  16,  31
                    .byte   27,  10,  7 ,  18,  27,  15,  5 ,  5
                    .byte   12,  19,  13,  24,  33,  8 ,  20,  7
                    .byte   33,  15,  13,  16,  27,  8 ,  20,  19
                    .byte   9 ,  32,  31,  5 ,  8 ,  21,  25,  9
                    .byte   13,  26,  21,  21,  7 ,  6 ,  32,  10
                    .byte   25,  32,  22,  15,  6 ,  28,  27,  15
                    .byte   20,  20,  17,  19,  16,  21,  17,  27
                    .byte   6 ,  12,  11,  6 ,  8 ,  11,  15,  30
                    .byte   27,  21,  28,  23,  15,  25,  12,  19
                    .byte   21,  20,  16,  14,  28,  27,  21,  12
                    .byte   21,  28,  31,  7 ,  5 ,  35,  6 ,  32
                    .byte   30,  31,  20,  9 ,  31,  11,  18,  32
                    .byte   18,  8 ,  19,  31,  10,  22,  21,  7
                    .byte   6 ,  10,  6 ,  31,  13,  5 ,  20,  8
                    .byte   13,  16,  19,  27,  11,  10,  7 ,  32
                    .byte   27,  5 ,  35,  17,  23,  11,  10,  31

.align 256

undoTable:          .res    256

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
.include "tileMap.asm"

