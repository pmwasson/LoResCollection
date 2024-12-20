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

.proc main

    ;----------------------------------
    ; Init
    ;----------------------------------
    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    sta         MIXCLR      ; full screen
    bit         HISCR       ; Display page2 so switch to page1

loop:
    ; flip page
    lda         PAGE2
    bmi         :+
    bit         HISCR
    jmp         clear
:
    bit         LOWSCR

clear:
    ; clear screen
    jsr         clearScreenWithEffect

    lda         #10
    sta         tileX
    lda         #10
    sta         tileY
    lda         #<shapeSpider1
    sta         tilePtr0
    lda         #>shapeSpider1
    sta         tilePtr1
    lda         #<shapeSpider1Mask
    sta         maskPtr0
    lda         #>shapeSpider1Mask
    sta         maskPtr1
    jsr         drawMaskedShape

    lda         #20
    sta         tileX
    lda         #10
    sta         tileY
    lda         #<shapeSpider2
    sta         tilePtr0
    lda         #>shapeSpider2
    sta         tilePtr1
    lda         #<shapeSpider2Mask
    sta         maskPtr0
    lda         #>shapeSpider2Mask
    sta         maskPtr1
    jsr         drawMaskedShape

    jsr         readJoystick
    jsr         updateEffect

:
    lda         BUTTON0
    bmi         :-

    jmp         loop

.endproc


.proc updateEffect
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
; Libraries
;-----------------------------------------------------------------------------

.include "inline_print.asm"
.include "grlib.asm"
.include "sound.asm"

;-----------------------------------------------------------------------------
; Shapes
;-----------------------------------------------------------------------------

.align 256

shapeSpider1:
    .byte   8,8,8*8/2   ; 8x8
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

shapeSpider2:
    .byte   8,8,8*8/2   ; 8x8
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