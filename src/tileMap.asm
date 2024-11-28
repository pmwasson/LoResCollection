;-----------------------------------------------------------------------------
; Tile Map
;-----------------------------------------------------------------------------
; Low Res tile map
;-----------------------------------------------------------------------------

; Reuse zero page pointers
evenPtr0        :=  screenPtr0
evenPtr1        :=  screenPtr1
oddPtr0         :=  maskPtr0
oddPtr1         :=  maskPtr1
tileShift       :=  tempZP

.proc drawTileMap

    ;----------------------------------
    ; Init demo
    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    lda         #0
    sta         drawPage

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
    asl                     ; * 16 (width)

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

    lda         #0
    sec
    sbc         mapOffsetY
    and         #$f
    tax
    lda         nibbleShiftIndex,x
    sta         tileShift

    ldy         mapScreenLeft
    sty         tileBufferIndex

    ;----------------------------------------
    ; Copy first row of map tiles to buffer

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
    ora         tileShift
    tax
    lda         nibbleShiftTable,x  ; shift by vertical offset
    sta         tileBuffer,y
    iny
    inc         tileIdx
    lda         tileIdx
    and         #$3
    bne         tileByteLoop1       ; repeat for remaining slices
    sty         tileBufferIndex
    inc         mapIndex
    cpy         mapScreenRight
    bcc         tileBufferLoop1     ; repeat for remaining tiles

    ;----------------------------------------
    ; Copy second row of map tiles to buffer

    ldy         mapScreenLeft
    sty         tileBufferIndex

    lda         mapPtr0
    clc
    adc         #MAP_WIDTH
    sta         mapPtr0

    lda         tileShift
    eor         #$40                ; shift +4 from previous
    sta         tileShift

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
    ora         tileShift
    tax
    lda         nibbleShiftTable,x  ; shift by vertical offset
    ora         tileBuffer,y
    sta         tileBuffer,y
    iny
    inc         tileIdx
    lda         tileIdx
    and         #$3
    bne         tileByteLoop2       ; repeat for remaining slices
    sty         tileBufferIndex
    inc         mapIndex
    cpy         mapScreenRight
    bcc         tileBufferLoop2     ; repeat for remaining tiles

    ;----------------------------------
    ; Set screen pointers for
    ; 2 aligned rows

    ldy         screenRow
    lda         lineOffset,y
    sta         evenPtr0
    ora         #$80
    sta         oddPtr0
    lda         linePage,y
    clc
    adc         drawPage
    sta         evenPtr1
    sta         oddPtr1

    ;----------------------------------
    ; Copy buffer to screen

    ldy         mapScreenLeft
    ; write 2 rows at a time
doubleRow:
    ldx         tileBuffer,y
    lda         evenColor,x
    sta         (evenPtr0),y
    lda         oddColor,x
    sta         (oddPtr0),y
    iny
    cpy         mapScreenRight
    bne         doubleRow

    brk



worldX:             .byte   0
worldY:             .byte   2
mapScreenTop:       .byte   0
mapScreenBottom:    .byte   20
mapScreenLeft:      .byte   0
mapScreenRight:     .byte   40

mapRow:             .byte   0
mapCol:             .byte   0
mapIndex:           .byte   0

mapOffsetX:         .byte   0
mapOffsetY:         .byte   0

screenRow:          .byte   0
screenCol:          .byte   0

tileBufferIndex:    .byte   0

.endproc

.align 256
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

; 16 bytes
nibbleShiftIndex:
        .byte   $00, $10, $20, $30, $40, $40, $40, $40, $40, $40, $40, $40, $40, $50, $60, $70

; 32 bytes
evenColor:          .byte   $ee, $e1, $1e, $11, $ee, $e1, $1e, $11, $ee, $e1, $1e, $11, $ee, $e1, $1e, $11
oddColor:           .byte   $ee, $ee, $ee, $ee, $e1, $e1, $e1, $e1, $1e, $1e, $1e, $1e, $11, $11, $11, $11

; 44 bytes
tileBuffer:         .res    44                  ; include some padding

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
MAP_WIDTH = 16
map:
;    .byte   $08,$08,$0C,$10,$14,$00,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
    .byte   $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
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
