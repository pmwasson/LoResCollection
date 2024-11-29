;-----------------------------------------------------------------------------
; Tile Map
;-----------------------------------------------------------------------------
; Low Res tile map
;-----------------------------------------------------------------------------

; Reuse zero page pointers
evenPtr0            :=  screenPtr0
evenPtr1            :=  screenPtr1
oddPtr0             :=  maskPtr0
oddPtr1             :=  maskPtr1
tileShiftInit       :=  tempZP
tileShiftRemainder  :=  temp2ZP

MAP_SCREEN_LEFT     =  2
MAP_SCREEN_RIGHT    =  36
MAP_SCREEN_TOP      =  4        ; Must be /2
MAP_SCREEN_BOTTOM   =  22       ; Must be /2

.proc mapDemo

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

    ; Draw screen
    ;---------------
    jsr         drawTileMap
    jsr         drawPlayer
    jsr         drawFuelGauge




    ; Get input
    ;---------------
    lda         KBD
    bpl         loop

    cmp         #KEY_DOWN
    bne         :+
    lda         worldY
    cmp         #(64-2*(MAP_SCREEN_BOTTOM-MAP_SCREEN_TOP))
    beq         loop
    inc         worldY
    jmp         loop
:
    cmp         #KEY_UP
    bne         :+
    lda         worldY
    beq         loop
    dec         worldY
    jmp         loop
:
    cmp         #KEY_RIGHT
    bne         :+
    lda         worldX
    cmp         #(64-(MAP_SCREEN_RIGHT-MAP_SCREEN_LEFT))
    beq         loop
    inc         worldX
    jmp         loop
:
    cmp         #KEY_LEFT
    bne         :+
    lda         worldX
    beq         loop
    dec         worldX
    jmp         loop
:

    cmp         #KEY_ESC
    bne         :+
    sta         KBDSTRB
    jsr         TEXT
    jsr         HOME
    jmp         MON
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
    asl                     ; * 16 (MAP_WIDTH)

    clc
    adc         mapCol
    sta         mapPtr0

    lda         #>map
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

    ldy         screenRow
screenRowLoop:
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
    ; TODO, update mapPtr1 when map get bigger

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

.proc drawPlayer

PLAYER_XOFFSET  = 16
PLAYER_ROW0_0   = $7A8 + PLAYER_XOFFSET     ; 15 (30)
PLAYER_ROW1_0   = $450 + PLAYER_XOFFSET     ; 16 (32)
PLAYER_ROW2_0   = $4D0 + PLAYER_XOFFSET     ; 17 (34)
PLAYER_ROW0_1   = $400 + PLAYER_ROW0_0
PLAYER_ROW1_1   = $400 + PLAYER_ROW1_0
PLAYER_ROW2_1   = $400 + PLAYER_ROW2_0
PLAYER_COLOR0   = $FF
PLAYER_COLOR1   = $F5

    lda         drawPage
    bne         draw1

    ;   ##
    ;   ##
    ;  #--#
    ;  ####
    ; #    #
    ; #    #

draw0:
    lda         #PLAYER_COLOR0
    sta         PLAYER_ROW0_0+2
    sta         PLAYER_ROW0_0+3
    sta         PLAYER_ROW1_0+1
    sta         PLAYER_ROW1_0+4
    sta         PLAYER_ROW2_0+0
    sta         PLAYER_ROW2_0+5
    lda         #PLAYER_COLOR1
    sta         PLAYER_ROW1_0+2
    sta         PLAYER_ROW1_0+3
    rts

draw1:
    lda         #PLAYER_COLOR0
    sta         PLAYER_ROW0_1+2
    sta         PLAYER_ROW0_1+3
    sta         PLAYER_ROW1_1+1
    sta         PLAYER_ROW1_1+4
    sta         PLAYER_ROW2_1+0
    sta         PLAYER_ROW2_1+5
    lda         #PLAYER_COLOR1
    sta         PLAYER_ROW1_1+2
    sta         PLAYER_ROW1_1+3
    rts

.endproc

;-----------------------------------------------------------------------------
; Update Fuel
;-----------------------------------------------------------------------------

FUEL_COLOR_EMPTY        = $00
FUEL_COLOR_GOOD         = $44
FUEL_COLOR_WARN         = $DD
FUEL_COLOR_LOW          = $99
FUEL_MAX_CONSUMPTION    = 15

FUEL_LEVEL_MAX          = 39

.proc updateFuel

    lda         BUTTON0
    bpl         :+
    lda         fuelLevel
    cmp         #FUEL_LEVEL_MAX
    bcs         :+
    inc         fuelLevel
    ldx         fuelLevel
    jmp         updateColors
:
    inc         consumption
    lda         consumption
    cmp         #FUEL_MAX_CONSUMPTION
    bcs         decreaseFuel
    rts

decreaseFuel:
    lda         #0
    sta         consumption
    ldx         fuelLevel
    bne         :+
    rts                                 ; already empty
:
    lda         #FUEL_COLOR_EMPTY
    sta         fuelColor,x
    dex
    bne         :+
    rts                                 ; hit empty
:
    stx         fuelLevel
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
    sta         FUEL_ROW1_0,x
    ;and         #$F0
    sta         FUEL_ROW0_0,x
    lda         fuelColor,x
    ;and         #$0F
    sta         FUEL_ROW2_0,x
    inx
    inx
    cpx         #FUEL_XRIGHT
    bne         draw0
    rts

draw1:
    lda         fuelColor,x
    sta         FUEL_ROW1_1,x
    ;and         #$F0
    sta         FUEL_ROW0_1,x
    lda         fuelColor,x
    ;and         #$0F
    sta         FUEL_ROW2_1,x
    inx
    inx
    cpx         #FUEL_XRIGHT
    bne         draw1
    rts

.endProc

; define for width of screen (40), but only read relevant ones
fuelColor:      .res    40

;-----------------------------------------------------------------------------
; Globals
;-----------------------------------------------------------------------------

worldX:             .byte   0
worldY:             .byte   0

.align 256


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

; 16x16 for testing
MAP_WIDTH = 16

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
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XSE,X__,XSW,XSE,X__,XSW,XSE,XC1,XC2,XC3,XC2,XSW,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XNE,X__,XNW,XNE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XR2,XSW,XSE,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XR1,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XXX,XSE,X__,X__,X__,XOO,X__,XOO,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,XSE,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,XOO,X__,XOO,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XXX,XXX
    .byte   XXX,XXX,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL2,XXX,XXX
    .byte   XXX,XXX,XR2,X__,X__,X__,X__,X__,X__,X__,X__,X__,X__,XL1,XXX,XXX
    .byte   XXX,XXX,XR1,X__,X__,X__,XF1,XF2,XF1,XNE,XNW,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
    .byte   XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX,XXX
