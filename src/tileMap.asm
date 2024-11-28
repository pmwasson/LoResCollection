;-----------------------------------------------------------------------------
; Tile Map
;-----------------------------------------------------------------------------
; Low Res tile map
;-----------------------------------------------------------------------------

.proc drawTileMap

    ;--------
    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    lda         #0
    sta         drawPage
    ;--------

    ; setup

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
    asl                     ; * 16 (width)

    clc
    adc         mapCol
    sta         mapIndex

    lda         worldX
    and         #%11
    sta         mapOffsetX

    lda         worldY
    and         #%11
    sta         mapOffsetY

    lda         #0
    sec
    sbc         mapOffsetY
    and         #$f
    tax
    lda         nibbleShiftIndex,x
    sta         initialShift


bufferLoop:

    ldy         mapScreenLeft
    sty         rowBufferIndex

loadBufferLoop:
    ldy         mapIndex
    ldx         map,y
    ldy         rowBufferIndex
    lda         mapTiles,x
    sta         rowBuffer,y
    inx
    iny
    lda         mapTiles,x
    sta         rowBuffer,y
    inx
    iny
    lda         mapTiles,x
    sta         rowBuffer,y
    inx
    iny
    lda         mapTiles,x
    sta         rowBuffer,y

    iny
    sty         rowBufferIndex
    inc         mapIndex
    cpy         mapScreenRight
    bne         loadBufferLoop

    ;----------------

rowLoop:
    ldy         screenRow
    lda         lineOffset,y
    sta         screenPtr0
    lda         linePage,y
    clc
    adc         drawPage
    sta         screenPtr1

    ldy         mapScreenLeft
colLoop:
    lda         rowBuffer,y
    and         #3              ; 2-bit index
    tax
    lda         colorTable,x
    sta         (screenPtr0),y
    lda         rowBuffer,y
    lsr                         ; shift by 2 for next row
    lsr
    sta         rowBuffer,y
    iny
    cpy         mapScreenRight
    bne         colLoop

    inc         screenRow
    lda         screenRow
    and         #$3             ; repeat for a total of 4 rows
    bne         rowLoop

    brk



.align  128

worldX:             .byte   0
worldY:             .byte   0
mapScreenTop:       .byte   0
mapScreenBottom:    .byte   20
mapScreenLeft:      .byte   0
mapScreenRight:     .byte   40

mapRow:             .byte   0
mapCol:             .byte   0
mapIndex:           .byte   0

mapOffsetX:         .byte   0
mapOffsetY:         .byte   0
initialShift:       .byte   0

screenRow:          .byte   0
screenCol:          .byte   0

rowBufferIndex:     .byte   0
colorTable:         .byte   $ee, $e1, $1e, $11
tileBuffer:         .res    40
rowBuffer:          .res    40

.endproc

.align 256
nibbleShiftTable:
        .byte   $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F      ; shift 0
        .byte   $00, $02, $04, $06, $08, $0A, $0C, $0E, $10, $12, $14, $16, $18, $1A, $1C, $1E      ; shift 1
        .byte   $00, $04, $08, $0C, $10, $14, $18, $1C, $20, $24, $28, $2C, $30, $34, $38, $3C      ; shift 2
        .byte   $00, $08, $10, $18, $20, $28, $30, $38, $40, $48, $50, $58, $60, $68, $70, $78      ; shift 3
        .byte   $00, $10, $20, $30, $40, $50, $60, $70, $80, $90, $A0, $B0, $C0, $D0, $E0, $F0      ; shift 4
        .byte   $00, $20, $40, $60, $80, $A0, $C0, $E0, $00, $20, $40, $60, $80, $A0, $C0, $E0      ; shift 5
        .byte   $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0      ; shift 6
        .byte   $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80      ; shift 7
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00      ; shift 8 / -4
        .byte   $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01      ; shift -3
        .byte   $00, $00, $00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03      ; shift -2
        .byte   $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07      ; shift -1

nibbleShiftIndex:
        .byte   $00, $10, $20, $30, $40, $50, $60, $70, $80, $80, $80, $80, $80, $90, $A0, $B0

.align 256

mapTiles:

        ; tiles defined turned right 90 degrees
        ;
        ;  L ->  1111
        ;        1000
        ;        1000
        ;        1010

; 0
        .byte   %0000
        .byte   %0000
        .byte   %0000
        .byte   %0000

; 1
        .byte   %1111
        .byte   %1111
        .byte   %1111
        .byte   %1111

; 2 - nw
        .byte   %1111
        .byte   %0111
        .byte   %0011
        .byte   %0001

; 3 - ne
        .byte   %0001
        .byte   %0011
        .byte   %0111
        .byte   %1111

; 4 - sw
        .byte   %1111
        .byte   %1110
        .byte   %1100
        .byte   %1000

; 5 - se
        .byte   %1000
        .byte   %1100
        .byte   %1110
        .byte   %1111

.align 256

; 16x16 for testing
map:
    .byte   $04,$08,$0C,$10,$14,$00,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
    .byte   $04,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$14,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$0C,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$14,$04
    .byte   $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
