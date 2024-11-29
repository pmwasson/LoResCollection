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
    tax
    lda         nibbleShiftInit,x
    sta         tileShiftInit
    lda         nibbleShiftRemainder,x
    sta         tileShiftRemainder

    lda         mapScreenTop
    sta         screenRow


    ;-------------------------------------------
    ; Copy first row of map tiles to buffer
    ; (throw away init and just use remainder)

    ldy         mapScreenLeft
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
    cpy         mapScreenRight
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

    ldy         mapScreenLeft
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
    cpy         mapScreenRight
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
    cpy         mapScreenBottom
    beq         drawMapDone
    jmp         screenRowLoop

drawMapDone:
    brk

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

screenRow:          .byte   0
tileBufferIndex:    .byte   0

.endproc

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

; 32 bytes
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

; 6 - dot
        .byte   %0110
        .byte   %1001
        .byte   %1001
        .byte   %0110


.align 256

; 16x16 for testing
MAP_WIDTH = 16
map:

    .byte   $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
    .byte   $04,$08,$00,$0C,$08,$00,$0C,$08,$00,$00,$00,$00,$00,$00,$0C,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$10,$00,$14,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$08,$00,$0C,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$10,$00,$00,$00,$00,$18,$00,$18,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$18,$00,$18,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04
    .byte   $04,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$14,$04
    .byte   $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
