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
BG_UPPER        = $05       ; top pixel
BG_LOWER        = $50       ; bottom pixel
BG_BOTH         = BG_UPPER | BG_LOWER
CURSOR_UPPER    = $0D
CURSOR_LOWER    = $D0
BOUNDARY_LEFT   = 2
BOUNDARY_TOP    = 3
BOUNDARY_RIGHT  = 36
BOUNDARY_BOTTOM = 37

SHAPE_PLAYER    = 0
SHAPE_2X1       = 1
SHAPE_3X1       = 2
SHAPE_1X2       = 3
SHAPE_1X3       = 4
SHAPE_2x2       = 5

SHAPE_HIGHLIGHT_SET   = $08
SHAPE_HIGHLIGHT_CLEAR = $F7

MAP_WALL        = $40
MAP_EMPTY       = $80

.proc main


;**** HACK ***

    jmp         particleDemo

;*************

    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode



    lda         #20
    sta         curX
    sta         curY

    lda         #0
    sta         levelNumber

levelLoop:
    jsr         loadLevel
    jsr         initCursor

    lda         #$00
    sta         drawPage
    jsr         drawBackground
    jsr         drawLevel

    lda         #$04
    sta         drawPage
    jsr         drawBackground
    jsr         drawLevel

gameLoop:

    inc         gameTime

    ;------------------
    ; Switch display
    ;------------------

    ; Switch page
    lda         PAGE2           ; bit 7 = page2 displayed
    bmi         switchTo1

    ; switch page 2
    bit         HISCR           ; display high screen
    lda         #$00            ; update low screen
    sta         drawPage

    ; Update X
    lda         gameTime
    and         #$1e
    bne         :+
    ldx         #0
    jsr         PREAD           ; read joystick X
    sty         paddleX
    jmp         :+

switchTo1:
    ; switch page
    bit         LOWSCR          ; display low screen
    lda         #$04            ; update high screen
    sta         drawPage

    ; Update Y
    lda         gameTime
    and         #$1e
    bne         :+
    ldx         #1
    jsr         PREAD           ; read joystick Y
    sty         paddleY
:

    ;------------------
    ; erase previous
    ;------------------

    jsr         eraseCursor

    lda         selected
    bmi         :+
    jsr         eraseSelected
:

    ;------------------
    ; Update
    ;------------------

    lda         selected
    bpl         :+
    jsr         highlightShape
:

    ;------------------
    ; draw new
    ;------------------

    ldx         drawPage
    lda         selected
    bmi         :+
    jsr         drawSelected
:

    jsr         drawCursor


    ;------------------
    ; Check input
    ;------------------

    lda         selected
    bpl         doSelected

    ; Is cursor on a shape?
    jsr         readMap
    cmp         #MAP_WALL
    bcs         :+

    ; no object selected
    lda         BUTTON0
    bpl         :+

    ; new selected
    jsr         setSelected
    jmp         :+

doSelected:
    lda         BUTTON0
    bmi         :+          ; still selected

    ; unselect
    jsr         clearSelected
    sta         SPEAKER
:


    ; joystick
    lda         gameTime
    and         #$3f
    bne         :+          ; check once every 64 loops
    lda         paddleX
    cmp         #256-60
    bcc         checkLeft
    jmp         doRight
checkLeft:
    cmp         #60
    bcs         :+
    jmp         doLeft
:
    lda         gameTime
    eor         #$20
    and         #$3f
    bne         :+          ; check once every 64 loops (out of phase with X)
    lda         paddleY
    cmp         #256-60
    bcc         checkUp
    jmp         doDown
checkUp:
    cmp         #60
    bcs         :+
    jmp         doUp
:

    ; keypress?
    ldx         #0
    stx         repeatKey
    lda         KBD
    bmi         :+

    inc         keyWait
    bne         noKey
    stx         keyWait
    stx         prevKey
noKey:
    jmp         gameLoop
:
    bit         KBDSTRB
    stx         keyWait

    cmp         #KEY_TAB
    bne         :+
    inc         levelNumber
    inc         levelNumber
    jmp         levelLoop
:

    cmp         #KEY_CTRL_C
    bne         :+
    jsr         TEXT
    jmp         monitor
:

    cmp         #KEY_ESC
    bne         :+
    jmp         quit
:

    ; check for repeat
    cmp         prevKey
    bne         :+
    inc         repeatKey
:
    sta         prevKey

    ; directions
    cmp         #KEY_LEFT
    beq         doLeft
    cmp         #KEY_RIGHT
    beq         doRight
    cmp         #KEY_UP
    beq         doUp
    cmp         #KEY_DOWN
    beq         doDown

    jsr         soundBump
    jmp         gameLoop


repeatLeft:
    lda         #0
    sta         repeatKey
doLeft:
    lda         moveHorizontal
    beq         :+
    dec         curX
    jsr         checkCollision
    beq         :+
    inc         curX            ; restore
:
    lda         repeatKey
    bne         repeatLeft
    jmp         gameLoop

repeatRight:
    lda         #0
    sta         repeatKey
doRight:
    lda         moveHorizontal
    beq         :+
    inc         curX
    jsr         checkCollision
    beq         :+
    dec         curX            ; restore
:
    lda         repeatKey
    bne         repeatRight
    jmp         gameLoop

repeatUp:
    lda         #0
    sta         repeatKey
doUp:
    lda         moveVertical
    beq         :+
    dec         curY
    jsr         checkCollision
    beq         :+
    inc         curY            ; restore
:
    lda         repeatKey
    bne         repeatUp
    jmp         gameLoop

repeatDown:
    lda         #0
    sta         repeatKey
doDown:
    lda         moveVertical
    beq         :+
    inc         curY
    jsr         checkCollision
    beq         :+
    dec         curY            ; restore
:
    lda         repeatKey
    bne         repeatDown
    jmp         gameLoop

prevKey:        .byte   0
repeatKey:      .byte   0
keyWait:        .byte   0
.endproc

.proc highlightShape
    jsr         readMap
    sta         highlight

    ; is current same as prev?
    ldx         drawPage
    cmp         prevHighlight0,x
    beq         rotateHighlight

    ; was a shape previous highlighted?
    lda         prevHighlight0,x
    cmp         #MAP_WALL
    bcs         :+

    ; multiply by 3
    clc
    sta         tempZP
    adc         tempZP
    adc         tempZP
    tay
    lda         levelData,y
    and         #SHAPE_HIGHLIGHT_CLEAR
    sta         levelData,y
    jsr         drawLevelShape
    sta         SPEAKER                     ; click when a piece is "dropped"
:

    ; is the cursor on a shape
    lda         highlight
    cmp         #MAP_WALL
    bcs         rotateHighlight
    clc
    sta         tempZP
    adc         tempZP
    adc         tempZP
    tay
    lda         levelData,y
    ora         #SHAPE_HIGHLIGHT_SET
    sta         levelData,y
    jsr         drawLevelShape

rotateHighlight:
    ldx         drawPage
    lda         highlight
    sta         prevHighlight0,x

    rts
.endproc

.proc eraseSelected
    ldy         selectedIndex
    ldx         drawPage
    lda         prevCurX0,x
    sta         levelData+1,y
    lda         prevCurY0,x
    sta         levelData+2,y
    jsr         eraseLevelShape
    rts
.endproc

.proc drawSelected
    ; update selected shape
    ldy         selectedIndex
    lda         levelData,y
    ora         #SHAPE_HIGHLIGHT_SET
    sta         levelData,y
    lda         curX
    sta         levelData+1,y
    lda         curY
    sta         levelData+2,y

    jsr         drawLevelShape
    rts
.endproc

;-----------------------------------------------------------------------------
; Set selected
;-----------------------------------------------------------------------------
.proc setSelected

    lda         highlight
    sta         selected
    clc
    adc         selected
    adc         selected        ; *3
    tay
    sty         selectedIndex

    ; set offset
    sec
    lda         curX
    sbc         levelData+1,y   ; x cord
    sta         selectedOffsetX
    sec
    lda         curY
    sbc         levelData+2,y   ; y cord
    sta         selectedOffsetY

    ; set cursor
    lda         levelData+1,y   ; x cord
    sta         curX
    lda         levelData+2,y   ; x cord
    sta         curY

    ; look up movement
    lda         levelData,y
    and         #$7             ; ignore highlight
    sta         selectedShape
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
    ldy         selectedIndex
    lda         curX
    sta         levelData+1,y
    lda         curY
    sta         levelData+2,y

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
    inc         shapeIndex      ; shapeIndex = y/3
    lda         (mapPtr0),y
    sta         levelData,y     ; shape
    bpl         :+              ; check if done
    rts                         ; done
:
    iny
    lda         (mapPtr0),y
    tax
    lda         translateX,x
    sta         levelData,y     ; x cord
    iny
    lda         (mapPtr0),y
    tax
    lda         translateY,x
    sta         levelData,y     ; y cord
    iny

    sty         tempY
    lda         shapeIndex
    jsr         setCollisionMap
    ldy         tempY
    jmp         loop

tempY:          .byte   0

.endproc

.proc setCollisionMap

    ; multiply index by 3
    clc
    sta         tempZP
    adc         tempZP
    adc         tempZP
    tay

    ; fill in collision map
    clc
    ldx         levelData+1,y   ; x
    lda         levelX,x
    ldx         levelData+2,y   ; y
    adc         levelY,x
    tax

    lda         levelData,y
    and         #$7             ; ignore highlight

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

.proc initLevel
    ; init cursor
    lda         #$ff
    sta         selected
    lda         #39
    sta         prevCurX0
    sta         prevCurX1
    lda         #0
    sta         prevCurY0
    sta         prevCurY1

    ; clear highlight & selected
    lda         #$ff
    sta         prevHighlight0
    sta         prevHighlight1

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
    lda         levelData,y
    bpl         :+              ; check if done
    rts                         ; done
:
    ldy         mapIndex
    jsr         drawLevelShape
    clc
    lda         mapIndex
    adc         #3
    sta         mapIndex
    tay
    jmp         loop

mapIndex:       .byte       0

.endproc


.proc drawLevelShape
    lda         levelData,y
    asl
    tax
    lda         levelData+1,y
    sta         tileX
    lda         levelData+2,y
    sta         tileY
    lda         shapeTable,x
    sta         tilePtr0
    lda         shapeTable+1,x
    sta         tilePtr1
    jsr         drawShape
    rts
.endproc

.proc eraseLevelShape
    lda         levelData,y
    asl
    tax
    lda         levelData+1,y
    sta         tileX
    lda         levelData+2,y
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
; Draw shape -- draw lores shape starting at any x,y
;
;  tileX, tileY and tilePtr must be set before calling
;
;  tileX, tileY are pixel coordinates.
;
;  Each shape is defined twice: once starting at at even row and once starting
;  at an odd row.
;
;  Draw lores shape defined by
;  0         - width (pixels)
;  1         - height (pixels)
;  2         - offset to shifted data in bytes
;  3+        - data bytes starting on even row
;  3+offset+ - data bytes starting on odd row
;
;  Total size must be <= 256 bytes and all data on same page
;-----------------------------------------------------------------------------

.proc drawShape

    ldy         #0
    lda         (tilePtr0),y
    sta         shapeWidth
    inc         tilePtr0

    lda         (tilePtr0),y
    sta         shapeHeight
    clc
    adc         #1
    lsr
    sta         shapeHeightBytes
    inc         tilePtr0

    lda         (tilePtr0),y
    sta         shapeOffset
    inc         tilePtr0

    lda         tileY
    eor         shapeHeight
    and         #1
    sta         shapeMaskLast

    ; setup even case, then overwrite if off
    lda         tileY
    lsr
    sta         tempZP
    bcc         even

    clc
    lda         shapeOffset
    adc         tilePtr0
    sta         tilePtr0

    ; first row -- mask upper pixel
    jsr         setScreenPtr

    ldy         shapeWidth
    dey

loopFirst:
    lda         (screenPtr0),y
    and         #$0F            ; keep upper pixel
    sta         tempZP
    lda         (tilePtr0),y
    and         #$F0            ; use lower pixel
    ora         tempZP
    sta         (screenPtr0),y
    dey
    bpl         loopFirst

    lda         tilePtr0
    adc         shapeWidth
    sta         tilePtr0

    lda         tileY
    lsr
    sta         tempZP
    inc         tempZP

    dec         shapeHeightBytes    ; 1 row done
    bne         :+                  ; never equal, and never -2

even:
    lda         shapeMaskLast
    beq         :+
    dec         shapeHeightBytes
:
    ldx         shapeHeightBytes

loopY:
    jsr         setScreenPtr

    ldy         shapeWidth
    dey

loopX:
    lda         (screenPtr0),y
    lda         (tilePtr0),y
    sta         (screenPtr0),y
    dey
    bpl         loopX

    lda         tilePtr0
    adc         shapeWidth
    sta         tilePtr0

    inc         tempZP          ; next line

    dex
    bne         loopY

    lda         shapeMaskLast
    bne         lastLine
    rts                         ; Done

lastLine:
    jsr         setScreenPtr

    ldy         shapeWidth
    dey

loopLast:
    lda         (screenPtr0),y
    and         #$F0            ; keep lower pixel
    sta         tempZP
    lda         (tilePtr0),y
    and         #$0F            ; use upper pixel
    ora         tempZP
    sta         (screenPtr0),y
    dey
    bpl         loopLast

    rts

shapeWidth:         .byte       0
shapeHeight:        .byte       0
shapeHeightBytes:   .byte       0
shapeOffset:        .byte       0
shapeMaskLast:      .byte       0

.endProc

;-----------------------------------------------------------------------------
; Erase shape -- fill shape size with background color at tileX, tileY
; (tilePtr not changed)
;-----------------------------------------------------------------------------

.proc eraseShape

    ldy         #0
    lda         (tilePtr0),y
    sta         shapeWidth
    iny
    lda         (tilePtr0),y
    sta         shapeHeight

    lda         tileY
    lsr
    sta         tempZP
    bcc         even

    ; first row -- mask upper pixel
    jsr         setScreenPtr

    ldy         shapeWidth
    dey

loopFirst:
    lda         (screenPtr0),y
    and         #$0F            ; keep upper pixel
    ora         #BG_LOWER       ; background
    sta         (screenPtr0),y
    dey
    bpl         loopFirst
    dec         shapeHeight     ; 1 pixel row done
    inc         tempZP          ; next row

even:

loopY:
    jsr         setScreenPtr

    ldy         shapeWidth
    dey

loopX:
    lda         #BG_BOTH        ; background
    sta         (screenPtr0),y
    dey
    bpl         loopX
    inc         tempZP          ; next line

    dec         shapeHeight
    dec         shapeHeight     ; 2 pixel rows done
    lda         shapeHeight
    beq         done
    cmp         #1
    bne         loopY

    ; 1 row left
lastLine:
    jsr         setScreenPtr

    ldy         shapeWidth
    dey

loopLast:
    lda         (screenPtr0),y
    and         #$F0            ; keep lower pixel
    ora         #BG_UPPER       ; background
    sta         (screenPtr0),y
    dey
    bpl         loopLast
done:
    rts

shapeWidth:         .byte       0
shapeHeight:        .byte       0

.endProc

;-----------------------------------------------------------------------------
; Erase Cursor
;
;   1) Erase cursor from 2 calls before (2 because of page flipping)
;
; Draw Cursor
;
;   2) Rotate data
;   3) Save background
;   4) Draw updated cursor
;-----------------------------------------------------------------------------

.proc initCursor
    lda         #39
    sta         prevCurX0
    sta         prevCurX1
    lda         #0
    sta         prevCurY0
    sta         prevCurY1
    sta         prevBG0
    sta         prevBG1
    lda         #1
    sta         moveHorizontal
    sta         moveVertical
.endproc

.proc eraseCursor

    ; erase previous
    ldx         drawPage
    lda         prevCurY0,x
    lsr
    tay
    lda         prevCurX0,x
    clc
    adc         lineOffset,y
    sta         screenPtr0
    lda         linePage,y
    adc         drawPage
    sta         screenPtr1
    ldy         #0
    lda         prevBG0,x
    sta         (screenPtr0),y

    rts
.endproc

.proc drawCursor

    ; grab current
    ldx         drawPage
    lda         curY
    lsr                         ; divide by 2
    tay
    lda         curX
    clc
    adc         lineOffset,y
    sta         screenPtr0
    lda         linePage,y
    adc         drawPage
    sta         screenPtr1
    ldy         #0
    lda         (screenPtr0),y
    sta         tempZP

    lda         curY
    and         #1
    bne         odd
    ; even
    lda         tempZP
    and         #$F0
    ora         #CURSOR_UPPER
    sta         (screenPtr0),y
done:
    lda         tempZP
    sta         prevBG0,x
    lda         curX
    sta         prevCurX0,x
    lda         curY
    sta         prevCurY0,x
    rts
odd:
    lda         tempZP
    and         #$0F
    ora         #CURSOR_LOWER
    sta         (screenPtr0),y
    lda         tempZP
    sta         prevBG0,x
    lda         curX
    sta         prevCurX0,x
    lda         curY
    sta         prevCurY0,x
    rts
.endProc


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

gameTime:           .byte   0
selected:           .byte   $ff         ; Negative = none
selectedIndex:      .byte   0
selectedShape:      .byte   0
selectedOffsetX:    .byte   0
selectedOffsetY:    .byte   0
paddleX:            .byte   $80
paddleY:            .byte   $80
levelNumber:        .byte   0

moveHorizontal:     .byte   1
moveVertical:       .byte   1
collisionMask:      .byte   0

; Cursor data
; Assuming (39,0) is black when starting

; offset by 4 for page index
prevCurX0:          .byte   39
prevCurY0:          .byte   0
prevBG0:            .byte   0
prevHighlight0:     .byte   $ff          ; Negative = none

prevCurX1:          .byte   39
prevCurY1:          .byte   0
prevBG1:            .byte   0
prevHighlight1:     .byte   $ff         ; Negative = none

; Movement
highlight:          .byte   0



shapeIndex:         .byte   0

.align 256

levelData:          .res    3*20

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
     .byte   I*GRID_X+BOUNDARY_LEFT
.endrepeat

translateY:
.repeat 7, I
     .byte   I*GRID_Y+BOUNDARY_TOP
.endrepeat

;-----------------------------------------------------------------------------
; Graphic shapes
;-----------------------------------------------------------------------------

.include "tiles.asm"
.include "shapes.asm"
.include "levels.asm"

