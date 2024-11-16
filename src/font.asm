;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; Low Res Font
;
; Blocky proportional font for low res graphics.
;
; Storing the data "vertically" to help with scrolling banners
; Font in 8 pixels tall, but assumes 6 in general
; Can be any width, but will try to limit to 5.
; Assuming average of 5 pixels (including space between letters)
; can get 8x6 = 48 characters on the screen
;
; Must start on even rows, but any column.

.proc fontDemo
    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    bit         HISCR       ; display high screen (so we switch to lower)
    lda         #0
    sta         drawPage

    ;lda         #$23
    ;sta         bg0
    ;lda         #$32
    ;sta         bg1
    ;jsr         clearScreen
    ;lda         #$a0
    ;jsr         clearMixedText

    lda         #0
    sta         fontX
    sta         fontY
    jsr         inlineDrawString
    .byte       "TESTING:",0

    lda         #4
    sta         boxLeft
    lda         #35
    sta         boxRight
    lda         #4
    sta         boxTop
    lda         #8
    sta         boxBottom

repeat:
    lda         #<message
    sta         stringPtr0
    lda         #>message
    sta         stringPtr1

loop:

    ldy         #10
:
    jsr         wait
    dey
    bne         :-

    jsr         screenFlip
    jsr         bannerRotateLeft
    bne         loop
    lda         KBD
    bpl         repeat

    brk

message:        .byte   1,"NO ",3,"YES ",1," ",0

.endproc

;-----------------------------------------------------------------------------
; Get font char
;   Interpret special characters and return char
;-----------------------------------------------------------------------------
.proc getFontChar
    ldy         #0
    lda         (stringPtr0),y
    beq         done
    cmp         #5
    bcs         done
    jsr         setFontColor
    jsr         nextFontChar
    jmp         getFontChar
done:
    rts
.endproc

.proc nextFontChar
    inc         stringPtr0
    bne         :+
    inc         stringPtr1
:
    rts
.endproc

.proc getNextFontChar
    jsr         getFontChar
    pha
    jsr         nextFontChar
    pla
    rts
temp:           .byte   0
.endproc


;-----------------------------------------------------------------------------
; Inline draw string
;-----------------------------------------------------------------------------

.proc inlineDrawString
    ; Pop return address to find string
    pla
    sta         stringPtr0
    pla
    sta         stringPtr1
    jsr         nextFontChar        ; +1

    ; Print characters until 0 (end-of-string)
printLoop:
    jsr         getFontChar
    tax
    beq         printExit
    jsr         nextFontChar
    jsr         drawChar
    bcc         printLoop
    ; off screen

printAbort:
    jsr         getFontChar
    beq         printExit
    jsr         nextFontChar
    jmp         printAbort

printExit:
    ; calculate return address after print string
    lda         stringPtr1
    pha
    lda         stringPtr0
    pha
    rts
.endproc

;-----------------------------------------------------------------------------
; Draw char
;-----------------------------------------------------------------------------
.proc drawChar
    ; check on screen
    lda         fontX
    cmp         #40
    bcc         :+
    rts                         ; exit if off screen
:

    lda         #0
    sta         done
    lda         fontIndex,x
    sta         charIndex
    tax
loop:
    lda         font,x
    bpl         :+              ; check for done marker
    inc         done
    and         #$7f
:

    jsr         drawCharCol

    inc         fontX
    lda         fontX
    cmp         #40
    bcc         :+
    rts                         ; exit if off screen
:
    lda         done
    beq         :+
    inc         fontX           ; add space between letters
    clc
    rts
:
    inc         charIndex
    ldx         charIndex
    jmp         loop

done:           .byte   0
charIndex:      .byte   0

.endProc


.proc drawCharCol

    sta         charByte
    lda         #4
    sta         count
    lda         fontY
    lsr                         ; divide by 2
    tax                         ; row in X

bitLoop:
    lda         fontX
    clc
    adc         lineOffset,x
    sta         screenPtr0
    lda         linePage,x
    adc         drawPage
    sta         screenPtr1

    lda         charByte
    and         #$3             ; lower 2 bits
    tay

    lda         fontColor,y
    ldy         #0
    sta         (screenPtr0),y

    inx

    lda         charByte
    lsr
    lsr
    sta         charByte
    dec         count
    bne         bitLoop

    rts

count:          .byte   0
charByte:       .byte   0

.endProc

;-----------------------------------------------------------------------------
; Set Font Color
;-----------------------------------------------------------------------------
.proc setFontColor
    tax
    lda         fontColorSet0,x
    sta         fontColor
    lda         fontColorSet1,x
    sta         fontColor+1
    lda         fontColorSet2,x
    sta         fontColor+2
    lda         fontColorSet3,x
    sta         fontColor+3
    rts
; Background  =         black   black   black   black   yellow
; Foreground  =         white   white   red     green   gray
fontColorSet0:  .byte   $00,    $00,    $00,    $00,    $DD
fontColorSet1:  .byte   $0f,    $0f,    $01,    $0C,    $D5
fontColorSet2:  .byte   $f0,    $f0,    $10,    $C0,    $5D
fontColorSet3:  .byte   $ff,    $ff,    $11,    $CC,    $55
.endproc

;-----------------------------------------------------------------------------
; Banner Rotate
;   assume  - shift box has already been setup
;           - stringPtr0/1 is set up
;   retun non-zero if not done, 0 if done
;-----------------------------------------------------------------------------

.proc bannerRotateLeft

    jsr         shiftBox

    lda         charSpace
    beq         :+
    lda         #0
    sta         charSpace
    jsr         drawCharCol
    lda         #1                  ; 1 = not done
    rts
:
    ; set coordinate
    lda         boxRight
    sta         fontX
    lda         boxTop
    asl                             ; *2
    sta         fontY

    ; get character
    jsr         getFontChar         ; Could optimize as look for special character every time
    tax
    lda         fontIndex,x
    clc
    adc         charByte
    inc         charByte
    tax
    lda         font,x
    bmi         final
    jsr         drawCharCol
    lda         #1                  ; 1 = not done
    rts

final:
    and         #$7f                ; remove end of char flag
    jsr         drawCharCol

    lda         #0
    sta         charByte

    jsr         nextFontChar
    jsr         getFontChar
    tax                             ; Set zero flag
    sta         charSpace           ; non zero = add space
    rts                             ; 0 = done / non-zero = not done

charByte:       .byte   0
charSpace:      .byte   0

.endproc

.proc bannerReset
    lda         #0
    sta         bannerRotateLeft::charByte
    sta         bannerRotateLeft::charSpace
    jsr         setFontColor
    rts
.endproc

;-----------------------------------------------------------------------------
; Font Data
;-----------------------------------------------------------------------------

fontX:          .byte   0
fontY:          .byte   0

.align 4

fontColor:      .byte   $00,$0f,$f0,$ff

.align 128

fontIndex:
    .byte       font_QM - font          ; 0   00  NUL
    .byte       font_QM - font          ; 1   01  SOH
    .byte       font_QM - font          ; 2   02  STX
    .byte       font_QM - font          ; 3   03  ETX
    .byte       font_QM - font          ; 4   04  EOT
    .byte       font_QM - font          ; 5   05  ENQ
    .byte       font_QM - font          ; 6   06  ACK
    .byte       font_QM - font          ; 7   07  BEL
    .byte       font_QM - font          ; 8   08  BS
    .byte       font_QM - font          ; 9   09  HT
    .byte       font_QM - font          ; 10  0A  LF
    .byte       font_QM - font          ; 11  0B  VT
    .byte       font_QM - font          ; 12  0C  FF
    .byte       font_QM - font          ; 13  0D  CR
    .byte       font_QM - font          ; 14  0E  SO
    .byte       font_QM - font          ; 15  0F  SI
    .byte       font_QM - font          ; 16  10  DLE
    .byte       font_QM - font          ; 17  11  DC1
    .byte       font_QM - font          ; 18  12  DC2
    .byte       font_QM - font          ; 19  13  DC3
    .byte       font_QM - font          ; 20  14  DC4
    .byte       font_QM - font          ; 21  15  NAK
    .byte       font_QM - font          ; 22  16  SYN
    .byte       font_QM - font          ; 23  17  ETB
    .byte       font_QM - font          ; 24  18  CAN
    .byte       font_QM - font          ; 25  19  EM
    .byte       font_QM - font          ; 26  1A  SUB
    .byte       font_QM - font          ; 27  1B  ESC
    .byte       font_QM - font          ; 28  1C  FS
    .byte       font_QM - font          ; 29  1D  GS
    .byte       font_QM - font          ; 30  1E  RS
    .byte       font_QM - font          ; 31  1F  US
    .byte       font_space - font       ; 32  20  space
    .byte       font_EX - font          ; 33  21  !
    .byte       font_doubleq - font     ; 34  22  "
    .byte       font_hash - font        ; 35  23  #
    .byte       font_dollars- font      ; 36  24  $
    .byte       font_percent - font     ; 37  25  %
    .byte       font_QM - font          ; 38  26  &
    .byte       font_quote - font       ; 39  27  '
    .byte       font_openp - font       ; 40  28  (
    .byte       font_closep - font      ; 41  29  )
    .byte       font_asterisk - font    ; 42  2A  *
    .byte       font_plus - font        ; 43  2B  +
    .byte       font_comma - font       ; 44  2C  ,
    .byte       font_dash - font        ; 45  2D  -
    .byte       font_period - font      ; 46  2E  .
    .byte       font_slash - font       ; 47  2F  /
    .byte       font_0  - font          ; 48  30  0
    .byte       font_1  - font          ; 49  31  1
    .byte       font_2  - font          ; 50  32  2
    .byte       font_3  - font          ; 51  33  3
    .byte       font_4  - font          ; 52  34  4
    .byte       font_5  - font          ; 53  35  5
    .byte       font_6  - font          ; 54  36  6
    .byte       font_7  - font          ; 55  37  7
    .byte       font_8  - font          ; 56  38  8
    .byte       font_9  - font          ; 57  39  9
    .byte       font_colon - font       ; 58  3A  :
    .byte       font_semicolon - font   ; 59  3B  ;
    .byte       font_lessthan - font    ; 60  3C  <
    .byte       font_equal - font       ; 61  3D  =
    .byte       font_greaterthan - font ; 62  3E  >
    .byte       font_QM - font          ; 63  3F  ?
    .byte       font_QM - font          ; 64  40  @
    .byte       font_A  - font          ; 65  41  A
    .byte       font_B  - font          ; 66  42  B
    .byte       font_C  - font          ; 67  43  C
    .byte       font_D  - font          ; 68  44  D
    .byte       font_E  - font          ; 69  45  E
    .byte       font_F  - font          ; 70  46  F
    .byte       font_G  - font          ; 71  47  G
    .byte       font_H  - font          ; 72  48  H
    .byte       font_I  - font          ; 73  49  I
    .byte       font_J  - font          ; 74  4A  J
    .byte       font_K  - font          ; 75  4B  K
    .byte       font_L  - font          ; 76  4C  L
    .byte       font_M  - font          ; 77  4D  M
    .byte       font_N  - font          ; 78  4E  N
    .byte       font_O  - font          ; 79  4F  O
    .byte       font_P  - font          ; 80  50  P
    .byte       font_Q  - font          ; 81  51  Q
    .byte       font_R  - font          ; 82  52  R
    .byte       font_S  - font          ; 83  53  S
    .byte       font_T  - font          ; 84  54  T
    .byte       font_U  - font          ; 85  55  U
    .byte       font_V  - font          ; 86  56  V
    .byte       font_W  - font          ; 87  57  W
    .byte       font_X  - font          ; 88  58  X
    .byte       font_Y  - font          ; 89  59  Y
    .byte       font_Z  - font          ; 90  5A  Z
    .byte       font_openb - font       ; 91  5B  [
    .byte       font_bslash - font      ; 92  5C  \
    .byte       font_closeb - font      ; 93  5D  ]
    .byte       font_caret - font       ; 94  5E  ^
    .byte       font_underline - font   ; 95  5F  _
    .byte       font_QM - font          ; 96  60  `
    .byte       font_A  - font          ; 97  61  a
    .byte       font_B  - font          ; 98  62  b
    .byte       font_C  - font          ; 99  63  c
    .byte       font_D  - font          ; 100 64  d
    .byte       font_E  - font          ; 101 65  e
    .byte       font_F  - font          ; 102 66  f
    .byte       font_G  - font          ; 103 67  g
    .byte       font_H  - font          ; 104 68  h
    .byte       font_I  - font          ; 105 69  i
    .byte       font_J  - font          ; 106 6A  j
    .byte       font_K  - font          ; 107 6B  k
    .byte       font_L  - font          ; 108 6C  l
    .byte       font_M  - font          ; 109 6D  m
    .byte       font_N  - font          ; 110 6E  n
    .byte       font_O  - font          ; 111 6F  o
    .byte       font_P  - font          ; 112 70  p
    .byte       font_Q  - font          ; 113 71  q
    .byte       font_R  - font          ; 114 72  r
    .byte       font_S  - font          ; 115 73  s
    .byte       font_T  - font          ; 116 74  t
    .byte       font_U  - font          ; 117 75  u
    .byte       font_V  - font          ; 118 76  v
    .byte       font_W  - font          ; 119 77  w
    .byte       font_X  - font          ; 120 78  x
    .byte       font_Y  - font          ; 121 79  y
    .byte       font_Z  - font          ; 122 7A  z
    .byte       font_openb - font       ; 123 7B  {
    .byte       font_bslash - font      ; 124 7C  |
    .byte       font_closeb - font      ; 125 7D  }
    .byte       font_caret - font       ; 126 7E  ~
    .byte       font_underline - font   ; 127 7F  DEL

.align 256
font:

font_space:     .byte       %10000000

font_EX:        .byte       %11011110

font_doubleq:   .byte       %00000110
                .byte       %00000000
                .byte       %10000110

font_hash:      .byte       %00010100
                .byte       %00111110
                .byte       %00010100
                .byte       %00111110
                .byte       %10010100

font_dollars:   .byte       %00000100
                .byte       %00101010
                .byte       %01111111
                .byte       %00101010
                .byte       %10010000

font_percent:   .byte       %00010010
                .byte       %00001000
                .byte       %10100100

; &

font_quote:     .byte       %10000110

font_openp:     .byte       %00111100
                .byte       %11000010

font_closep:    .byte       %01000010
                .byte       %10111100

font_asterisk:  .byte       %00100100
                .byte       %00011000
                .byte       %01111110
                .byte       %00011000
                .byte       %10100100

font_plus:      .byte       %00001000
                .byte       %00011100
                .byte       %10001000

font_comma:     .byte       %01000000
                .byte       %10100000

font_dash:      .byte       %00001000
                .byte       %10001000

font_slash:     .byte       %01100000
                .byte       %00011000
                .byte       %10000110

font_period:    .byte       %11000000

font_0:         .byte       %01111110
                .byte       %01000010
                .byte       %11111110

font_1:         .byte       %01000100
                .byte       %01111110
                .byte       %11000000

font_2:         .byte       %01111010
                .byte       %01001010
                .byte       %11001110

font_3:         .byte       %01001010
                .byte       %01001010
                .byte       %11111110

font_4:         .byte       %00001110
                .byte       %00001000
                .byte       %11111110

font_5:         .byte       %01001110
                .byte       %01001010
                .byte       %11111010

font_6:         .byte       %01111110
                .byte       %01001010
                .byte       %11111010

font_7:         .byte       %00000010
                .byte       %00000010
                .byte       %11111110

font_8:         .byte       %01111110
                .byte       %01001010
                .byte       %11111110

font_9:         .byte       %01001110
                .byte       %01001010
                .byte       %11111110

font_colon:     .byte       %10101000

font_semicolon: .byte       %01000000
                .byte       %10101000

font_lessthan:  .byte       %00001000
                .byte       %00010100
                .byte       %10100010

font_equal:     .byte       %00010100
                .byte       %10010100

font_greaterthan:
                .byte       %00100010
                .byte       %00010100
                .byte       %10001000

font_QM:        .byte       %00000100
                .byte       %01010010
                .byte       %10001100

; @

font_A:         .byte       %01111100
                .byte       %00010010
                .byte       %11111100

font_B:         .byte       %01111110
                .byte       %01001010
                .byte       %11110100

font_C:         .byte       %00111100
                .byte       %01000010
                .byte       %11000010

font_D:         .byte       %01111110
                .byte       %01000010
                .byte       %10111100

font_E:         .byte       %01111110
                .byte       %01001010
                .byte       %11000010

font_F:         .byte       %01111110
                .byte       %00001010
                .byte       %10000010

font_G:         .byte       %00111100
                .byte       %01000010
                .byte       %01001010
                .byte       %10111000

font_H:         .byte       %01111110
                .byte       %00001000
                .byte       %11111110

; Wider I
;font_I:         .byte       %01000010
;                .byte       %01111110
;                .byte       %11000010

font_I:         .byte       %11111110

font_J:         .byte       %00100000
                .byte       %01000000
                .byte       %10111110

font_K:         .byte       %01111110
                .byte       %00010000
                .byte       %11101100

font_L:         .byte       %01111110
                .byte       %01000000
                .byte       %11000000

font_M:         .byte       %01111110
                .byte       %00000010
                .byte       %00001100
                .byte       %00000010
                .byte       %11111110

font_N:         .byte       %01111110
                .byte       %00000100
                .byte       %00001000
                .byte       %11111110

font_O:         .byte       %00111100
                .byte       %01000010
                .byte       %10111100

font_P:         .byte       %01111110
                .byte       %00010010
                .byte       %10001100

font_Q:         .byte       %00111100
                .byte       %01000010
                .byte       %01100010
                .byte       %11011100

font_R:         .byte       %01111110
                .byte       %00010010
                .byte       %11101100

font_S:         .byte       %01000100
                .byte       %01001010
                .byte       %10110010

font_T:         .byte       %00000010
                .byte       %01111110
                .byte       %10000010

font_U:         .byte       %00111110
                .byte       %01000000
                .byte       %10111110

font_V:         .byte       %00011110
                .byte       %01100000
                .byte       %10011110

font_W:         .byte       %00111110
                .byte       %01000000
                .byte       %00110000
                .byte       %01000000
                .byte       %10111110

font_X:         .byte       %01110110
                .byte       %00001000
                .byte       %11110110

font_Y:         .byte       %00001110
                .byte       %01110000
                .byte       %10001110

font_Z:         .byte       %01110010
                .byte       %01001010
                .byte       %11000110

font_openb:     .byte       %01111110
                .byte       %01000010
                .byte       %11000010

font_bslash:    .byte       %00000110
                .byte       %00011000
                .byte       %11100010

font_closeb:    .byte       %01000010
                .byte       %01000010
                .byte       %11111110

font_caret:     .byte       %00000100
                .byte       %00000010
                .byte       %10000100

font_underline: .byte       %01000000
                .byte       %01000000
                .byte       %11000000
