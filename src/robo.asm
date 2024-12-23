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
    jsr         clearScreenWithEffect
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

    jsr         readJoystick
    jsr         updatePlayer
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
    lda         #25
    sta         cooldown

    ldx         #SOUND_BUMP
    jsr         playSound
    rts

allocateIndex:  .byte   0
cooldown:       .byte   0

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
    beq         :+                      ; if joystick centered, don't update body position (or arm)
    stx         bodyDirection
    lda         BUTTON0
    bmi         :+                      ; if button pressed, don't update arm position
    stx         armDirection
:

    ; draw player
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
    jmp         drawPlayer

faceLeft:
    lda         #<playerLeft
    sta         tilePtr0
    lda         #>playerLeft
    sta         tilePtr1
    lda         #<playerLeftMask
    sta         maskPtr0
    lda         #>playerLeftMask
    sta         maskPtr1

drawPlayer:
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

joystickActiveTable:
    .byte       1,1,1,1
    .byte       1,0,0,1
    .byte       1,0,0,1
    .byte       1,1,1,1

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
; Clear Screen (with effect)
;   Clear low res screen with single horizontal (page0) or vertical (page1)
;   line.
;-----------------------------------------------------------------------------

.proc clearScreenWithEffect

    lda         PAGE2           ; bit 7 = page2 displayed
    bmi         clear0          ; display high, so draw low
    jmp         clear1

clear0:
    ldx         #39
loop0:
    lda         rowColor+0
    sta         $0400,x
    lda         rowColor+1
    sta         $0480,x
    lda         rowColor+2
    sta         $0500,x
    lda         rowColor+3
    sta         $0580,x
    lda         rowColor+4
    sta         $0600,x
    lda         rowColor+5
    sta         $0680,x
    lda         rowColor+6
    sta         $0700,x
    lda         rowColor+7
    sta         $0780,x
    lda         rowColor+8
    sta         $0428,x
    lda         rowColor+9
    sta         $04A8,x
    lda         rowColor+10
    sta         $0528,x
    lda         rowColor+11
    sta         $05A8,x
    lda         rowColor+12
    sta         $0628,x
    lda         rowColor+13
    sta         $06A8,x
    lda         rowColor+14
    sta         $0728,x
    lda         rowColor+15
    sta         $07A8,x
    lda         rowColor+16
    sta         $0450,x
    lda         rowColor+17
    sta         $04D0,x
    lda         rowColor+18
    sta         $0550,x
    lda         rowColor+19
    sta         $05D0,x
    lda         rowColor+20
    sta         $0650,x
    lda         rowColor+21
    sta         $06D0,x
    lda         rowColor+22
    sta         $0750,x
    lda         rowColor+23
    sta         $07D0,x
    dex
    bmi         :+
    jmp         loop0
:
    lda         #0
    sta         drawPage        ; draw on cleared page
    rts

clear1:
    ldx         #40*3
loop1:
    lda         colColor,x
    sta         $800,x
    sta         $880,x
    sta         $900,x
    sta         $980,x
    sta         $A00,x
    sta         $A80,x
    sta         $B00,x
    sta         $B80,x
    dex
    bpl         loop1

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