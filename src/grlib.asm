;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; GR Lib
; Collection of lo-res graphic routines

;-----------------------------------------------------------------------------
; Screen flip
;   Performs the following
;       swaps the current displaying page
;       set drawPage
;       copies the newly displaying page to other page for updating
;-----------------------------------------------------------------------------
.proc screenFlip

    ; Switch page
    ldx         #120-1
    lda         PAGE2           ; bit 7 = page2 displayed
    bmi         switchTo1

    ; switch page 2
    bit         HISCR           ; display high screen
    lda         #$00            ; update low screen
    sta         drawPage

    ; copy page 2 to page 1
:
    lda         $800,x
    sta         $400,x
    lda         $880,x
    sta         $480,x
    lda         $900,x
    sta         $500,x
    lda         $980,x
    sta         $580,x
    lda         $A00,x
    sta         $600,x
    lda         $A80,x
    sta         $680,x
    lda         $B00,x
    sta         $700,x
    lda         $B80,x
    sta         $780,x
    dex
    bpl         :-
    rts

switchTo1:
    bit         LOWSCR          ; display low screen
    lda         #$04            ; update high screen
    sta         drawPage

    ; copy page 1 to page 2
:
    lda         $400,x
    sta         $800,x
    lda         $480,x
    sta         $880,x
    lda         $500,x
    sta         $900,x
    lda         $580,x
    sta         $980,x
    lda         $600,x
    sta         $A00,x
    lda         $680,x
    sta         $A80,x
    lda         $700,x
    sta         $B00,x
    lda         $780,x
    sta         $B80,x
    dex
    bpl         :-
    rts

.endproc


;-----------------------------------------------------------------------------
; drawPattern
;   Draw a horizontal pattern starting at curX,curY
;       Y rounded to nearest row/2
;
;   Pass pre-define pattern in X
;-----------------------------------------------------------------------------
.proc drawPattern
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
loop:
    lda         patternTable,x
    bne         :+
    rts                         ; all done
:
    sta         (screenPtr0),y
    inx
    iny
    bne         loop

.endproc

;-----------------------------------------------------------------------------
; drawDot
;-----------------------------------------------------------------------------
.proc drawDot
    sta         tempZP
    and         #$0f
    sta         color+0
    lda         tempZP
    and         #$f0
    sta         color+1
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
    lda         curY
    and         #1
    tax
    lda         (screenPtr0),y
    and         mask,x
    ora         color,x
    sta         (screenPtr0),y
    rts

mask:           .byte   $f0,$0f
color:          .byte   $0e,$e0
.endProc

;-----------------------------------------------------------------------------
; getBG
;   return background byte at curX,curY
;-----------------------------------------------------------------------------
.proc getBG
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
    rts
.endProc

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

BG_UPPER        = $05       ; top pixel
BG_LOWER        = $50       ; bottom pixel
BG_BOTH         = BG_UPPER | BG_LOWER

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
; Lookup Tables
;-----------------------------------------------------------------------------
.align 256

PATTERN_LINE_LEFT       = patternTable0 - patternTable
PATTERN_LINE_MIDDLE     = patternTable1 - patternTable
PATTERN_LINE_RIGHT      = patternTable2 - patternTable
PATTERN_SIDE            = patternTable3 - patternTable
PATTERN_SIDE_TEXT       = patternTable4 - patternTable
PATTERN_GRAY_BRICK      = patternTable5 - patternTable
PATTERN_BLUE_BRICK      = patternTable6 - patternTable

patternTable:
patternTable0:  .byte   $f5,$ff,$00                 ; line left
patternTable1:  .byte   $ff,$ff,$ff,$ff,$00         ; line middle
patternTable2:  .byte   $ff,$f5,$00                 ; line right
patternTable3:  .byte   $ff,$ff,$00                 ; side
patternTable4:  .byte   $20,$20,$00                 ; side (text)
patternTable5:  .byte   $88,$58,$58,$58,$00         ; gray brick
patternTable6:  .byte   $26,$62,$26,$62,$00         ; blue brick

lineOffset:
    .byte   <$0400
    .byte   <$0480
    .byte   <$0500
    .byte   <$0580
    .byte   <$0600
    .byte   <$0680
    .byte   <$0700
    .byte   <$0780
    .byte   <$0428
    .byte   <$04A8
    .byte   <$0528
    .byte   <$05A8
    .byte   <$0628
    .byte   <$06A8
    .byte   <$0728
    .byte   <$07A8
    .byte   <$0450
    .byte   <$04D0
    .byte   <$0550
    .byte   <$05D0
    .byte   <$0650
    .byte   <$06D0
    .byte   <$0750
    .byte   <$07D0

linePage:
    .byte   >$0400
    .byte   >$0480
    .byte   >$0500
    .byte   >$0580
    .byte   >$0600
    .byte   >$0680
    .byte   >$0700
    .byte   >$0780
    .byte   >$0428
    .byte   >$04A8
    .byte   >$0528
    .byte   >$05A8
    .byte   >$0628
    .byte   >$06A8
    .byte   >$0728
    .byte   >$07A8
    .byte   >$0450
    .byte   >$04D0
    .byte   >$0550
    .byte   >$05D0
    .byte   >$0650
    .byte   >$06D0
    .byte   >$0750
    .byte   >$07D0

