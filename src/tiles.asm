;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; Game tiles
;
; Low res tiles 5 pixels across by 6 pixels high

TILE_WIDTH      = 5         ; 5 bytes wide
TILE_HEIGHT     = 3         ; 3 bytes high


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

.align 256

tileSheet:

;------------------------
; background tiles (5x6)
;------------------------

; 8 tiles across, 7 rows = 40x42, so last row only uses top 4 pixels

; $0 black = outside of playing field
; $f white = wall
; $5 gray  = brackground in playing field

; Map
; 0 1 1 1 1 1 1 2
; 3 4 4 4 4 4 4 5
; 3 4 4 4 4 4 4 6
; 3 4 4 4 4 4 4 7
; 3 4 4 4 4 4 4 7
; 3 4 4 4 4 4 4 7
; 8 9 9 9 9 9 9 A

; wall 2 pixels wide (vert & hort)

; 00 - upper left (top row blank, align to left)
.byte   $F0, $F0, $F0, $F0, $F0
.byte 	$FF, $FF, $5F, $5F, $5F
.byte   $FF, $FF, $55, $55, $55
.byte   $00

; 01 - top (top row blank)
.byte   $F0, $F0, $F0, $F0, $F0
.byte 	$5F, $5F, $5F, $5F, $5F
.byte 	$55, $55, $55, $55, $55
.byte   $00

; 02 - upper right (top row black, right column blank)
.byte   $F0, $F0, $F0, $F0, $00
.byte 	$5F, $5F, $FF, $FF, $00
.byte   $55, $55, $FF, $FF, $00
.byte   $00

; 03 - left (align to left)
.byte   $FF, $FF, $55, $55, $55
.byte 	$FF, $FF, $55, $55, $55
.byte   $FF, $FF, $55, $55, $55
.byte   $00

; 04 - middle
.byte   $55, $55, $55, $55, $55
.byte 	$55, $55, $55, $55, $55
.byte   $55, $55, $55, $55, $55
.byte   $00

; 05 - right door upper
.byte   $55, $55, $5F, $5F, $5F
.byte 	$55, $55, $55, $55, $55
.byte   $55, $55, $55, $55, $55
.byte   $00

; 06 - right door lower
.byte   $55, $55, $55, $55, $55
.byte 	$55, $55, $55, $55, $55
.byte   $55, $55, $F5, $F5, $F5
.byte   $00

; 07 - right (right column blank)
.byte   $55, $55, $FF, $FF, $00
.byte 	$55, $55, $FF, $FF, $00
.byte   $55, $55, $FF, $FF, $00
.byte   $00

; 08 - bottom left (2 bottom rows blank, align to left)
.byte   $FF, $FF, $55, $55, $55
.byte 	$FF, $FF, $FF, $FF, $FF
.byte   $00, $00, $00, $00, $00
.byte   $00

; 09 - bottom  (2 bottom rows blank)
.byte   $55, $55, $55, $55, $55
.byte 	$FF, $FF, $FF, $FF, $FF
.byte   $00, $00, $00, $00, $00
.byte   $00

; 0A - bottom right (2 bottom rows blank, right column blank)
.byte   $55, $55, $FF, $FF, $00
.byte 	$FF, $FF, $FF, $FF, $00
.byte   $00, $00, $00, $00, $00
.byte   $00

; 0B - blank
.byte   $00, $00, $00, $00, $00
.byte 	$00, $00, $00, $00, $00
.byte   $00, $00, $00, $00, $00
.byte   $00

