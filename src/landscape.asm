;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------

.include "defines.asm"
.include "macros.asm"

.segment "CODE"
.org    $2000

IMAGE = image
CROSSHAIR_COLOR = $11
SCROLL_SPEED = 256-45
SCROLL_SPEED_UPPER = $ff

.proc main

    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    sta         MIXCLR      ; full screen

    ldx         #SOUND_WAKEUP
    jsr         playSound

loop:
    clc
    lda         xSubOffset
    adc         #SCROLL_SPEED
    sta         xSubOffset
    lda         xOffset
    adc         #SCROLL_SPEED_UPPER
    sta         xOffset
    jsr         drawBackground

    lda         KBD
    bpl         loop

    sta         KBDSTRB
    cmp         #KEY_ESC
    bne         loop
    jmp         quit

.endproc

.proc drawBackground
    jsr         updateSound
    lda         PAGE2               ; bit 7 = page2 displayed
    bmi         drawLow             ; display high, so draw low
    jsr         drawBackgroundHigh
    jsr         updateSound
    ;jsr         drawCrossHairsHigh
    jsr         logo_0x800
    bit         HISCR               ; display high screen
    rts
drawLow:
    jsr         drawBackgroundLow
    jsr         updateSound
    ;jsr         drawCrossHairsLow
    jsr         logo_0x400
    bit         LOWSCR              ; display low screen
    rts
.endproc


.proc drawBackgroundLow

    ldx         xOffset
    ldy         0

    ; draw low page
loopLow:
    lda         IMAGE+256*0,x
    sta         $400,y
    lda         IMAGE+256*1,x
    sta         $480,y
    lda         IMAGE+256*2,x
    sta         $500,y
    lda         IMAGE+256*3,x
    sta         $580,y
    lda         IMAGE+256*4,x
    sta         $600,y
    lda         IMAGE+256*5,x
    sta         $680,y
    lda         IMAGE+256*6,x
    sta         $700,y
    lda         IMAGE+256*7,x
    sta         $780,y
    lda         IMAGE+256*8,x
    sta         $428,y
    lda         IMAGE+256*9,x
    sta         $4a8,y
    lda         IMAGE+256*10,x
    sta         $528,y
    lda         IMAGE+256*11,x
    sta         $5a8,y
    lda         IMAGE+256*12,x
    sta         $628,y
    lda         IMAGE+256*13,x
    sta         $6a8,y
    lda         IMAGE+256*14,x
    sta         $728,y
    lda         IMAGE+256*15,x
    sta         $7a8,y
    lda         IMAGE+256*16,x
    sta         $450,y
    lda         IMAGE+256*17,x
    sta         $4d0,y
    lda         IMAGE+256*18,x
    sta         $550,y
    lda         IMAGE+256*19,x
    sta         $5d0,y
    lda         IMAGE+256*20,x
    sta         $650,y
    lda         IMAGE+256*21,x
    sta         $6d0,y
    lda         IMAGE+256*22,x
    sta         $750,y
    lda         IMAGE+256*23,x
    sta         $7d0,y
    inx
    iny
    cpy         #40
    beq         :+
    jmp         loopLow
:
    rts
.endproc

.proc drawBackgroundHigh

    ldx         xOffset
    ldy         0

    ; draw high page
loopHigh:
    lda         IMAGE+256*0,x
    sta         $800,y
    lda         IMAGE+256*1,x
    sta         $880,y
    lda         IMAGE+256*2,x
    sta         $900,y
    lda         IMAGE+256*3,x
    sta         $980,y
    lda         IMAGE+256*4,x
    sta         $a00,y
    lda         IMAGE+256*5,x
    sta         $a80,y
    lda         IMAGE+256*6,x
    sta         $b00,y
    lda         IMAGE+256*7,x
    sta         $b80,y
    lda         IMAGE+256*8,x
    sta         $828,y
    lda         IMAGE+256*9,x
    sta         $8a8,y
    lda         IMAGE+256*10,x
    sta         $928,y
    lda         IMAGE+256*11,x
    sta         $9a8,y
    lda         IMAGE+256*12,x
    sta         $a28,y
    lda         IMAGE+256*13,x
    sta         $aa8,y
    lda         IMAGE+256*14,x
    sta         $b28,y
    lda         IMAGE+256*15,x
    sta         $ba8,y
    lda         IMAGE+256*16,x
    sta         $850,y
    lda         IMAGE+256*17,x
    sta         $8d0,y
    lda         IMAGE+256*18,x
    sta         $950,y
    lda         IMAGE+256*19,x
    sta         $9d0,y
    lda         IMAGE+256*20,x
    sta         $a50,y
    lda         IMAGE+256*21,x
    sta         $ad0,y
    lda         IMAGE+256*22,x
    sta         $b50,y
    lda         IMAGE+256*23,x
    sta         $bd0,y
    inx
    iny
    cpy         #40
    beq         :+
    jmp         loopHigh
:
    rts

.endproc

.proc drawCrossHairsLow

    ; draw cross-hairs
    lda         $528+19         ; row 10, col 19 -- bottom pixel
    and         #$0f
    ora         #(CROSSHAIR_COLOR & $f0)
    sta         $528+19

    lda         $5a8+19         ; row 11, col 19 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $5a8+19

    lda         $628+16         ; row 12, col 16 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $628+16

    lda         $628+17         ; row 12, col 17 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $628+17

    lda         $628+21         ; row 12, col 21 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $628+21

    lda         $628+22         ; row 12, col 22 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $628+22

    lda         #CROSSHAIR_COLOR
    sta         $6a8+19         ; row 13, colr 19 -- both pixels

    rts
.endproc

.proc drawCrossHairsHigh

    ; draw cross-hairs
    lda         $928+19         ; row 10, col 19 -- bottom pixel
    and         #$0f
    ora         #(CROSSHAIR_COLOR & $f0)
    sta         $928+19

    lda         $9a8+19         ; row 11, col 19 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $9a8+19

    lda         $a28+16         ; row 12, col 16 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $a28+16

    lda         $a28+17         ; row 12, col 17 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $a28+17

    lda         $a28+21         ; row 12, col 21 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $a28+21

    lda         $a28+22         ; row 12, col 22 -- top pixel
    and         #$f0
    ora         #(CROSSHAIR_COLOR & $0f)
    sta         $a28+22

    lda         #CROSSHAIR_COLOR
    sta         $aa8+19         ; row 13, colr 19 -- both pixels

    rts
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

;------------------------------------------------------------------------------

xOffset:        .byte       0
xSubOffset:     .byte       0

.align 256
.include "image.asm"
.include "logo.asm"
.include "sound.asm"
