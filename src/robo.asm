;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; Robo
;-----------------------------------------------------------------------------
; Low res shooter
;-----------------------------------------------------------------------------

.include "defines.asm"
.include "macros.asm"

.segment "CODE"
.org    $2000

MOVEMENT_SPEED  = 9         ; how often you can move  (larger = slower)
SHOOT_SPEED     = 19        ; how often you can shoot (larger = slower)

BORDER_COLOR0   = $05
BORDER_COLOR1   = $50
BG_COLOR        = $77
SCREEN_TOP      = 1
SCREEN_BOTTOM   = 46
SCREEN_LEFT     = 1
SCREEN_RIGHT    = 38

.proc main

    ;----------------------------------
    ; Init
    ;----------------------------------
    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    sta         MIXCLR      ; full screen
    bit         HISCR       ; Display page2 so switch to page1

    lda         #BORDER_COLOR0
    sta         bg0
    lda         #BORDER_COLOR1
    sta         bg1
    lda         #0
    sta         drawPage
    jsr         clearScreen
    lda         #4
    sta         drawPage
    jsr         clearScreen

    ldx         #SOUND_WAKEUP
    jsr         playSound

loop:
    ; flip page
    lda         PAGE2
    bmi         :+
    bit         HISCR
    jmp         clear
:
    bit         LOWSCR

clear:
    jsr         updateSound
    ; clear screen
    jsr         clearPartialScreen
    jsr         updateSound

    ldx         #0
    stx         shapeIndex

shapeLoop:
    ldx         shapeIndex
    lda         shapeList,x
    bmi         doneShapeLoop
    sta         tileX
    lda         shapeList+1,x
    sta         tileY

    lda         shapeList+2,x
    sta         shapeWidth
    lda         shapeList+3,x
    sta         shapeHeightBytes
    lda         shapeList+4,x
    sta         shapeOffset

    lda         shapeList+5,x
    sta         tilePtr0
    lda         shapeList+6,x
    sta         tilePtr1
    lda         shapeList+7,x
    sta         maskPtr0
    lda         shapeList+8,x
    sta         maskPtr1

    jsr         drawMaskedShape

    clc
    lda         shapeIndex
    adc         #9
    sta         shapeIndex
    jmp         shapeLoop
doneShapeLoop:
    jsr         updatePlayer
    jsr         drawPlayer
    jsr         shootBullet
    jsr         updateBullet
    jsr         updateEffect

    jmp         loop

shapeIndex:     .byte   0

shapeList:

    .byte       8,10,   8,4,32
    .word       shapeSpider1,shapeSpider1Mask

    .byte       22,10,  8,4,32
    .word       shapeSpider2,shapeSpider2Mask

    .byte       255

.endproc


.proc updateEffect


    rts         ; DISABLED


    ; clear previous
    lda         #0
    ldx         prevRow
    sta         rowColor,x
    ldx         prevCol
    sta         colColor,x
    sta         colColor+40,x
    sta         colColor+80,x


    ldx         paddleX
    lda         paddleColTable,x
    sta         prevCol
    tax
    lda         #$ff
    sta         colColor,x
    sta         colColor+40,x
    sta         colColor+80,x

    ldx         paddleY
    lda         paddleRowTable,x
    lsr
    sta         prevRow
    tax
    lda         #$0f
    bcc         :+
    lda         #$f0
:
    sta         rowColor,x
    rts

prevRow:        .byte   0
prevCol:        .byte   0

.align 256

paddleRowTable:
    .byte        0, 0, 0, 0, 0, 0                                                       ; 6
    .byte        0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9,10,10,11,11 ; 24
    .byte       12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,23 ; 24
    .byte       24,24,25,25,26,26,27,27,28,28,29,29,30,30,31,31,32,32,33,33,34,34,35,35 ; 24
    .byte       36,36,37,37,38,38,39,39,40,40,41,41,42,42,43,43,44,44,45,45,46,46,47,47 ; 24
    .byte       47,47,47,47,47,47                                                       ; 6  = 108

paddleColTable:
    .byte        0, 0, 0, 0                                                                     ; 4
    .byte        0, 0, 1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5, 5, 6, 6, 7, 7, 7, 8, 8, 9, 9, 9      ; 25
    .byte       10,10,11,11,11,12,12,13,13,13,14,14,15,15,15,16,16,17,17,17,18,18,19,19,19      ; 25
    .byte       20,20,21,21,21,22,22,23,23,23,24,24,25,25,25,26,26,27,27,27,28,28,29,29,29      ; 25
    .byte       30,30,31,31,31,32,32,33,33,33,34,34,35,35,35,36,36,37,37,37,38,38,39,39,39      ; 25
    .byte       39,39,39,39                                                                     ; 4  = 108
.endproc


;-----------------------------------------------------------------------------
; Update Bullet
;
;-----------------------------------------------------------------------------
.proc updateBullet

    lda         #0
    sta         index

loop:
    tax

    lda         bulletTable+1,x         ;x1
    bmi         next

    clc
    lda         bulletTable+0,x
    adc         bulletTable+4,x
    sta         bulletTable+0,x

    lda         bulletTable+1,x
    adc         bulletTable+5,x
    sta         bulletTable+1,x
    sta         curX

    cmp         #SCREEN_LEFT
    beq         invalidate
    cmp         #SCREEN_RIGHT
    beq         invalidate

    clc
    lda         bulletTable+2,x
    adc         bulletTable+6,x
    sta         bulletTable+2,x

    lda         bulletTable+3,x
    adc         bulletTable+7,x
    sta         bulletTable+3,x
    sta         curY

    cmp         #SCREEN_TOP
    beq         invalidate
    cmp         #SCREEN_BOTTOM
    beq         invalidate

    lda         bulletTable+8,x     ;color
    jsr         drawDot

next:
    lda         index
    clc
    adc         #BULLET_ENTRY_SIZE
    sta         index
    cmp         #BULLET_TABLE_SIZE
    bne         loop
    rts

invalidate:
    lda         #$FF
    sta         bulletTable+1,x
    jmp         next

index:          .byte   0
.endproc

.proc shootBullet
    lda         cooldown
    beq         :+
    dec         cooldown
    rts
:
    lda         BUTTON0
    bmi         :+
    rts
:
    ldx         allocateIndex
    ldy         armDirection

    lda         #$80
    sta         bulletTable+0,x     ; x0
    sta         bulletTable+2,x     ; y0
    clc
    lda         playerX
    adc         bulletXOffset,y
    sta         bulletTable+1,x     ; x1
    lda         playerY
    adc         bulletYOffset,y
    sta         bulletTable+3,x     ; y1

    lda         bulletVecX0Table,y
    sta         bulletTable+4,x     ; vx0
    lda         bulletVecX1Table,y
    sta         bulletTable+5,x     ; vx1
    lda         bulletVecY0Table,y
    sta         bulletTable+6,x     ; vy0
    lda         bulletVecY1Table,y
    sta         bulletTable+7,x     ; vy1

    lda         #$dd
    sta         bulletTable+8,x     ; color

    lda         allocateIndex
    adc         #BULLET_ENTRY_SIZE
    cmp         #BULLET_TABLE_SIZE
    bne         :+
    lda         #0
:
    sta         allocateIndex
    lda         #SHOOT_SPEED
    sta         cooldown

    ldx         #SOUND_BUMP
    jsr         playSound
    rts

allocateIndex:  .byte   0
cooldown:       .byte   SHOOT_SPEED

.endproc


bulletXOffset:
    .byte       $00, $01, $01, $02
    .byte       $00, $01, $01, $02
    .byte       $00, $01, $01, $02
    .byte       $00, $01, $01, $02

bulletYOffset:
    .byte       $03, $03, $03, $03
    .byte       $04, $04, $04, $04
    .byte       $04, $04, $04, $04
    .byte       $05, $05, $05, $05

bulletVecX0Table:
    .byte       $D3, $00, $00, $2D
    .byte       $C0, $00, $00, $40
    .byte       $C0, $00, $00, $40
    .byte       $D3, $00, $00, $2D

bulletVecX1Table:
    .byte       $FF, $00, $00, $00
    .byte       $FF, $00, $00, $00
    .byte       $FF, $00, $00, $00
    .byte       $FF, $00, $00, $00

bulletVecY0Table:
    .byte       $D3, $C0, $C0, $C0
    .byte       $00, $00, $00, $00
    .byte       $00, $00, $00, $00
    .byte       $2D, $40, $40, $2D

bulletVecY1Table:
    .byte       $FF, $FF, $FF, $FF
    .byte       $00, $00, $00, $00
    .byte       $00, $00, $00, $00
    .byte       $00, $00, $00, $00

; Bullet Data
; 0: x0
; 1: x1
; 2: y0
; 3: y1
; 4: vx0
; 5: vx1
; 6: vy0
; 7: vy1
; 8: color
BULLET_ENTRY_SIZE = 9
BULLET_TABLE_SIZE = 8*BULLET_ENTRY_SIZE
bulletTable:
;    .byte   0,20,  0,23,  $40,$00,  $00,$00,  $dd   ; right
;    .byte   0,20,  0,23,  $00,$00,  $40,$00,  $dd   ; down
;    .byte   0,20,  0,23,  $C0,$FF,  $00,$00,  $dd   ; left
;    .byte   0,20,  0,23,  $00,$00,  $C0,$FF,  $dd   ; up
;    .byte   0,20,  0,23,  $2D,$00,  $2D,$00,  $dd   ; down-right
;    .byte   0,20,  0,23,  $D3,$FF,  $2D,$00,  $dd   ; down-left
;    .byte   0,20,  0,23,  $2D,$00,  $D3,$FF,  $dd   ; up-right
;    .byte   0,20,  0,23,  $D3,$FF,  $D3,$FF,  $dd   ; up-left
   .res    BULLET_TABLE_SIZE,255




;-----------------------------------------------------------------------------
; Update Player
;
;   Use joystick result to set player direction and arm
;
;-----------------------------------------------------------------------------
.proc updatePlayer
    lda         cooldown
    beq         update
    dec         cooldown
    beq         read
    rts
read:
    jsr         readJoystick
    rts

update:
    lda         #MOVEMENT_SPEED
    sta         cooldown        ; reset cooldown

    ; calculate direction
    lda         paddleX
    clc
    adc         #10
    and         #%01100000
    lsr
    lsr
    lsr
    lsr
    lsr
    sta         tempZP

    lda         paddleY
    adc         #10
    and         #%01100000
    lsr
    lsr
    lsr
    adc         tempZP
    tax
    lda         joystickActiveTable,x
    bne         :+                      ; if joystick centered, don't update body position (or arm)
    rts
:
    stx         bodyDirection
    lda         BUTTON0
    bmi         :+                      ; if button pressed, don't update arm position
    stx         armDirection
:

    sta         SPEAKER

    clc
    lda         playerX
    adc         moveX,x
    sta         playerX

    cmp         #SCREEN_LEFT
    bne         :+
    inc         playerX
:
    cmp         #SCREEN_RIGHT-2
    bne         :+
    dec         playerX
:

    clc
    lda         playerY
    adc         moveY,x
    sta         playerY

    cmp         #SCREEN_TOP-1
    bne         :+
    inc         playerY
:
    cmp         #SCREEN_BOTTOM-7
    bne         :+
    dec         playerY
:


    rts


cooldown:           .byte       MOVEMENT_SPEED

joystickActiveTable:
    .byte       1,1,1,1
    .byte       1,0,0,1
    .byte       1,0,0,1
    .byte       1,1,1,1

moveX:
    .byte       $FF,$00,$00,$01
    .byte       $FF,$00,$00,$01
    .byte       $FF,$00,$00,$01
    .byte       $FF,$00,$00,$01

moveY:
    .byte       $FF,$FF,$FF,$FF
    .byte       $00,$00,$00,$00
    .byte       $00,$00,$00,$00
    .byte       $01,$01,$01,$01

.endproc

;-----------------------------------------------------------------------------
; Draw Player
;
;   Draw player on screen
;
;-----------------------------------------------------------------------------
.proc drawPlayer
    lda         playerX
    sta         tileX
    lda         playerY
    sta         tileY
    lda         #playerWidth
    sta         shapeWidth
    lda         #playerHeightBytes
    sta         shapeHeightBytes
    lda         #playerWidth*playerHeightBytes
    sta         shapeOffset

    lda         bodyDirection
    and         #%10
    beq         faceLeft

faceRight:
    lda         #<playerRight
    sta         tilePtr0
    lda         #>playerRight
    sta         tilePtr1
    lda         #<playerRightMask
    sta         maskPtr0
    lda         #>playerRightMask
    sta         maskPtr1
    jmp         draw

faceLeft:
    lda         #<playerLeft
    sta         tilePtr0
    lda         #>playerLeft
    sta         tilePtr1
    lda         #<playerLeftMask
    sta         maskPtr0
    lda         #>playerLeftMask
    sta         maskPtr1

draw:
    jsr         drawMaskedShape

    ; draw arm
    lda         playerX
    sta         tileX
    lda         playerY
    clc
    adc         #3
    sta         tileY
    lda         #armWidth
    sta         shapeWidth
    lda         #armHeightBytes
    sta         shapeHeightBytes
    lda         #armWidth*armHeightBytes
    sta         shapeOffset

    ldx         armDirection
    lda         armShapeTable0,x
    sta         tilePtr0
    lda         armShapeTable1,x
    sta         tilePtr1
    lda         armShapeMaskTable0,x
    sta         maskPtr0
    lda         armShapeMaskTable1,x
    sta         maskPtr1
    jsr         drawMaskedShape
    rts

armShapeTable0:
    .byte       <armUpL, <armUp, <armUp, <armUpR
    .byte       <armL,   <armL,  <armR,  <armR
    .byte       <armL,   <armL,  <armR,  <armR
    .byte       <armDnL, <armDn, <armDn, <armDnR

armShapeTable1:
    .byte       >armUpL, >armUp, >armUp, >armUpR
    .byte       >armL,   >armL,  >armR,  >armR
    .byte       >armL,   >armL,  >armR,  >armR
    .byte       >armDnL, >armDn, >armDn, >armDnR

armShapeMaskTable0:
    .byte       <armUpLMask, <armUpMask, <armUpMask, <armUpRMask
    .byte       <armLMask,   <armLMask,  <armRMask,  <armRMask
    .byte       <armLMask,   <armLMask,  <armRMask,  <armRMask
    .byte       <armDnLMask, <armDnMask, <armDnMask, <armDnRMask

armShapeMaskTable1:
    .byte       >armUpLMask, >armUpMask, >armUpMask, >armUpRMask
    .byte       >armLMask,   >armLMask,  >armRMask,  >armRMask
    .byte       >armLMask,   >armLMask,  >armRMask,  >armRMask
    .byte       >armDnLMask, >armDnMask, >armDnMask, >armDnRMask

.endproc

;-----------------------------------------------------------------------------
; Clear Screen
;-----------------------------------------------------------------------------

.proc clearPartialScreen

    lda         PAGE2           ; bit 7 = page2 displayed
    bmi         clear0          ; display high, so draw low
    jmp         clear1

clear0:
    lda         #BG_COLOR
    ldx         #SCREEN_LEFT+1
loop0:
    ;sta         $0400,x
    sta         $0480,x
    sta         $0500,x
    sta         $0580,x
    sta         $0600,x
    sta         $0680,x
    sta         $0700,x
    sta         $0780,x
    sta         $0428,x
    sta         $04A8,x
    sta         $0528,x
    sta         $05A8,x
    sta         $0628,x
    sta         $06A8,x
    sta         $0728,x
    sta         $07A8,x
    sta         $0450,x
    sta         $04D0,x
    sta         $0550,x
    sta         $05D0,x
    sta         $0650,x
    sta         $06D0,x
    sta         $0750,x
    ;sta         $07D0,x

    inx
    cpx         #SCREEN_RIGHT
    bne         loop0

    lda         #0
    sta         drawPage        ; draw on cleared page
    rts

clear1:
    lda         #BG_COLOR
    ldx         #SCREEN_LEFT+1
loop1:
    ;sta         $0800,x
    sta         $0880,x
    sta         $0900,x
    sta         $0980,x
    sta         $0A00,x
    sta         $0A80,x
    sta         $0B00,x
    sta         $0B80,x
    sta         $0828,x
    sta         $08A8,x
    sta         $0928,x
    sta         $09A8,x
    sta         $0A28,x
    sta         $0AA8,x
    sta         $0B28,x
    sta         $0BA8,x
    sta         $0850,x
    sta         $08D0,x
    sta         $0950,x
    sta         $09D0,x
    sta         $0A50,x
    sta         $0AD0,x
    sta         $0B50,x
    ;sta         $0BD0,x

    inx
    cpx         #SCREEN_RIGHT
    bne         loop1

    lda         #4
    sta         drawPage        ; draw on cleared page

    rts
.endproc

.align 32
rowColor:       .res    24

.align 128
colColor:       .res    40*3


;-----------------------------------------------------------------------------
; Globals
;-----------------------------------------------------------------------------

playerX:        .byte   20
playerY:        .byte   20
bodyDirection:  .byte   7
armDirection:   .byte   7

;-----------------------------------------------------------------------------
; Libraries
;-----------------------------------------------------------------------------

.include "inline_print.asm"
.include "grlib.asm"
.include "sound.asm"

;-----------------------------------------------------------------------------
; Shapes
;-----------------------------------------------------------------------------

.align 256

playerWidth         = 3
playerHeightBytes   = 5

playerRight:     ; 3x5
    ; even
    .byte   $00, $F0, $F0
    .byte   $00, $FF, $0F
    .byte   $00, $FF, $00
    .byte   $00, $FF, $F0
    .byte   $00, $00, $00
    ; odd
    .byte   $00, $00, $00
    .byte   $00, $FF, $FF
    .byte   $00, $FF, $00
    .byte   $00, $FF, $00
    .byte   $00, $0F, $0F
playerRightMask:
    ; mask even
    .byte   $FF, $0F, $0F
    .byte   $FF, $00, $F0
    .byte   $FF, $00, $FF
    .byte   $FF, $00, $0F
    .byte   $FF, $FF, $FF
    ; mask odd
    .byte   $FF, $FF, $FF
    .byte   $FF, $00, $00
    .byte   $FF, $00, $FF
    .byte   $FF, $00, $FF
    .byte   $FF, $F0, $F0

playerLeft:     ; 3x5
    ; even
    .byte   $F0, $F0, $00
    .byte   $0F, $FF, $00
    .byte   $00, $FF, $00
    .byte   $F0, $FF, $00
    .byte   $00, $00, $00
    ; odd
    .byte   $00, $00, $00
    .byte   $FF, $FF, $00
    .byte   $00, $FF, $00
    .byte   $00, $FF, $00
    .byte   $0F, $0F, $00
playerLeftMask:
    ; mask even
    .byte   $0F, $0F, $FF
    .byte   $F0, $00, $FF
    .byte   $FF, $00, $FF
    .byte   $0F, $00, $FF
    .byte   $FF, $FF, $FF
    ; mask odd
    .byte   $FF, $FF, $FF
    .byte   $00, $00, $FF
    .byte   $FF, $00, $FF
    .byte   $FF, $00, $FF
    .byte   $F0, $F0, $FF

.align 256

armWidth            = 3
armHeightBytes      = 2

armUp:      ; even
            .byte   $00, $55, $00
            .byte   $00, $00, $00
            ; odd
            .byte   $00, $50, $00
            .byte   $00, $05, $00

armUpR:     ; even
            .byte   $00, $50, $05
            .byte   $00, $00, $00
            ; odd
            .byte   $00, $00, $50
            .byte   $00, $05, $00

armR:       ; even
            .byte   $00, $50, $50
            .byte   $00, $00, $00
            ; odd
            .byte   $00, $00, $00
            .byte   $00, $05, $05

armDnR:     ; even
            .byte   $00, $50, $00
            .byte   $00, $00, $05
            ; odd
            .byte   $00, $00, $00
            .byte   $00, $05, $50

armDn:      ; even
            .byte   $00, $50, $00
            .byte   $00, $05, $00
            ; odd
            .byte   $00, $00, $00
            .byte   $00, $55, $00

armDnL:     ; even
            .byte   $00, $50, $00
            .byte   $05, $00, $00
            ; odd
            .byte   $00, $00, $00
            .byte   $50, $05, $00

armL:       ; even
            .byte   $50, $50, $00
            .byte   $00, $00, $00
            ; odd
            .byte   $00, $00, $00
            .byte   $05, $05, $00

armUpL:     ; even
            .byte   $05, $50, $00
            .byte   $00, $00, $00
            ; odd
            .byte   $50, $00, $00
            .byte   $00, $05, $00

armUpMask:  ; even
            .byte   $FF, $00, $FF
            .byte   $FF, $FF, $FF
            ; odd
            .byte   $FF, $0F, $FF
            .byte   $FF, $F0, $FF

armUpRMask: ; even
            .byte   $FF, $0F, $F0
            .byte   $FF, $FF, $FF
            ; odd
            .byte   $FF, $FF, $0F
            .byte   $FF, $F0, $FF

armRMask:   ; even
            .byte   $FF, $0F, $0F
            .byte   $FF, $FF, $FF
            ; odd
            .byte   $FF, $FF, $FF
            .byte   $FF, $F0, $F0

armDnRMask: ; even
            .byte   $FF, $0F, $FF
            .byte   $FF, $FF, $F0
            ; odd
            .byte   $FF, $FF, $FF
            .byte   $FF, $F0, $0F

armDnMask:  ; even
            .byte   $FF, $0F, $FF
            .byte   $FF, $F0, $FF
            ; odd
            .byte   $FF, $FF, $FF
            .byte   $FF, $00, $FF

armDnLMask: ; even
            .byte   $FF, $0F, $FF
            .byte   $F0, $FF, $FF
            ; odd
            .byte   $FF, $FF, $FF
            .byte   $0F, $F0, $FF

armLMask:   ; even
            .byte   $0F, $0F, $FF
            .byte   $FF, $FF, $FF
            ; odd
            .byte   $FF, $FF, $FF
            .byte   $F0, $F0, $FF

armUpLMask: ; even
            .byte   $F0, $0F, $FF
            .byte   $FF, $FF, $FF
            ; odd
            .byte   $0F, $FF, $FF
            .byte   $FF, $F0, $FF

.align 256
shapeSpider1:   ; 8x8
    ; even
    .byte   $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $90, $33, $33, $90, $00, $00
    .byte   $88, $08, $89, $93, $93, $89, $08, $88
    .byte   $08, $00, $08, $00, $00, $08, $00, $08
    ; odd
    .byte   $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $30, $30, $00, $00, $00
    .byte   $80, $80, $99, $33, $33, $99, $80, $80
    .byte   $88, $00, $88, $09, $09, $88, $00, $88
shapeSpider1Mask:
    ; mask even
    .byte   $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte   $FF, $FF, $0F, $00, $00, $0F, $FF, $FF
    .byte   $00, $F0, $00, $00, $00, $00, $F0, $00
    .byte   $F0, $FF, $F0, $FF, $FF, $F0, $FF, $F0
    ; mask odd
    .byte   $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte   $FF, $FF, $FF, $0F, $0F, $FF, $FF, $FF
    .byte   $0F, $0F, $00, $00, $00, $00, $0F, $0F
    .byte   $00, $FF, $00, $F0, $F0, $00, $FF, $00

shapeSpider2:   ; 8x8
    ; even
    .byte   $00, $00, $00, $30, $30, $00, $00, $00
    .byte   $00, $80, $99, $33, $33, $99, $80, $00
    .byte   $88, $00, $80, $09, $09, $80, $00, $88
    .byte   $08, $00, $08, $00, $00, $08, $00, $08
    ; odd
    .byte   $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $90, $33, $33, $90, $00, $00
    .byte   $80, $08, $09, $93, $93, $09, $08, $80
    .byte   $88, $00, $88, $00, $00, $88, $00, $88
shapeSpider2Mask:
    ; mask even
    .byte   $FF, $FF, $FF, $0F, $0F, $FF, $FF, $FF
    .byte   $FF, $0F, $00, $00, $00, $00, $0F, $FF
    .byte   $00, $FF, $0F, $F0, $F0, $0F, $FF, $00
    .byte   $F0, $FF, $F0, $FF, $FF, $F0, $FF, $F0
    ; mask odd
    .byte   $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte   $FF, $FF, $0F, $00, $00, $0F, $FF, $FF
    .byte   $0F, $F0, $F0, $00, $00, $F0, $F0, $0F
    .byte   $00, $FF, $00, $FF, $FF, $00, $FF, $00