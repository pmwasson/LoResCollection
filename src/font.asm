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

    lda         #0
    sta         drawPage
    sta         curX
    sta         curY

    jsr         inlineDrawString
    .byte       "HELLO...!",0

    lda         #0
    sta         curX
    lda         #8
    sta         curY

    jsr         inlineDrawString
    .byte       "0123456789",0

    lda         #0
    sta         curX
    lda         #16
    sta         curY

    jsr         inlineDrawString
    .byte       "LEVEL:01",0

    lda         #0
    sta         curX
    lda         #24
    sta         curY

    jsr         inlineDrawString
    .byte       "SCORE:9999",0

    lda         #0
    sta         curX
    lda         #32
    sta         curY

    jsr         inlineDrawString
    .byte       "10% <=>;",0

    brk

.endproc


;-----------------------------------------------------------------------------
; Inline draw string
;-----------------------------------------------------------------------------

.proc inlineDrawString
    ; Pop return address to find string
    pla
    sta     stringPtr0
    pla
    sta     stringPtr1
    ldy     #0

    ; Print characters until 0 (end-of-string)
printLoop:
    iny
    tya
    pha
    lda     (stringPtr0),y
    beq     printExit
    tax
    jsr     drawChar
    bcs     printAbort   ; off of screen
    pla
    tay
    jmp     printLoop

printAbort:
    pla
    tay
:
    iny
    lda     (stringPtr0),y
    bne     :-
    pha

printExit:
    pla                 ; clean up stack
    ; calculate return address after print string
    clc
    tya
    adc     stringPtr0  ; add low-byte first
    tax                 ; save in X
    lda     stringPtr1  ; carry to high-byte
    adc     #0
    pha                 ; push return high-byte
    txa
    pha                 ; push return low-byte
    rts                 ; return
.endproc

;-----------------------------------------------------------------------------
; Draw char
;-----------------------------------------------------------------------------
.proc drawChar

    ; check on screen
    lda         curX
    cmp         #40
    bcc         :+
    rts                         ; exit if off screen
:

    cpx         #$20            ; is it a space?
    bne         :+
    inc         curX
    inc         curX
    clc
    rts
:

    lda         fontIndex,x
    sta         charIndex
    tax

loop:
    lda         font,x
    sta         charByte
    bne         :+
    inc         curX            ; add space between letters
    clc
    rts
:
    lda         curY
    lsr                         ; divide by 2
    tay
    sty         row

bitLoop:
    ldy         row
    lda         curX
    clc
    adc         lineOffset,y
    sta         screenPtr0
    lda         linePage,y
    adc         drawPage
    sta         screenPtr1

    lda         charByte
    and         #$3             ; lower 2 bits
    tax

    ldy         #0
    lda         color,x
    sta         (screenPtr0),y

    inc         row

    lda         charByte
    lsr
    lsr
    sta         charByte
    bne         bitLoop

    inc         curX
    lda         curX
    cmp         #40
    bcc         :+
    rts                         ; exit if off screen
:
    inc         charIndex
    ldx         charIndex
    jmp         loop

row:            .byte   0
charIndex:      .byte   0
charByte:       .byte   0
color:          .byte   $00,$0f,$f0,$ff
.endProc

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
    .byte       font_QM - font          ; 32  20  space ; handled special
    .byte       font_EX - font          ; 33  21  !
    .byte       font_QM - font          ; 34  22  "
    .byte       font_QM - font          ; 35  23  #
    .byte       font_QM - font          ; 36  24  $
    .byte       font_percent - font     ; 37  25  %
    .byte       font_QM - font          ; 38  26  &
    .byte       font_QM - font          ; 39  27  '
    .byte       font_QM - font          ; 40  28  (
    .byte       font_QM - font          ; 41  29  )
    .byte       font_QM - font          ; 42  2A  *
    .byte       font_QM - font          ; 43  2B  +
    .byte       font_QM - font          ; 44  2C  ,
    .byte       font_QM - font          ; 45  2D  -
    .byte       font_period - font      ; 46  2E  .
    .byte       font_QM - font          ; 47  2F  /
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
    .byte       font_QM - font          ; 91  5B  [
    .byte       font_QM - font          ; 92  5C  \
    .byte       font_QM - font          ; 93  5D  ]
    .byte       font_QM - font          ; 94  5E  ^
    .byte       font_QM - font          ; 95  5F  _
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
    .byte       font_QM - font          ; 123 7B  {
    .byte       font_QM - font          ; 124 7C  |
    .byte       font_QM - font          ; 125 7D  }
    .byte       font_QM - font          ; 126 7E  ~
    .byte       font_QM - font          ; 127 7F  DEL

.align 256
font:

font_EX:
    .byte       %01011110
    .byte       0

font_doubleq:
    .byte       %00000110
    .byte       %00000000
    .byte       %00000110
    .byte       0

    .byte       font_QM - font          ; 34  22  "
    .byte       font_QM - font          ; 35  23  #
    .byte       font_QM - font          ; 36  24  $
    .byte       font_percent - font     ; 37  25  %
    .byte       font_QM - font          ; 38  26  &
    .byte       font_QM - font          ; 39  27  '
    .byte       font_QM - font          ; 40  28  (
    .byte       font_QM - font          ; 41  29  )
    .byte       font_QM - font          ; 42  2A  *
    .byte       font_QM - font          ; 43  2B  +
    .byte       font_QM - font          ; 44  2C  ,
    .byte       font_QM - font          ; 45  2D  -

font_percent:
    .byte       %00010010
    .byte       %00001000
    .byte       %00100100
    .byte       0

font_period:
    .byte       %01000000
    .byte       0

font_0:
    .byte       %01111110
    .byte       %01000010
    .byte       %01111110
    .byte       0

font_1:
    .byte       %01000100
    .byte       %01111110
    .byte       %01000000
    .byte       0

font_2:
    .byte       %01111010
    .byte       %01001010
    .byte       %01001110
    .byte       0

font_3:
    .byte       %01001010
    .byte       %01001010
    .byte       %01111110
    .byte       0

font_4:
    .byte       %00001110
    .byte       %00001000
    .byte       %01111110
    .byte       0

font_5:
    .byte       %01001110
    .byte       %01001010
    .byte       %01111010
    .byte       0

font_6:
    .byte       %01111110
    .byte       %01001010
    .byte       %01111010
    .byte       0

font_7:
    .byte       %00000010
    .byte       %00000010
    .byte       %01111110
    .byte       0

font_8:
    .byte       %01111110
    .byte       %01001010
    .byte       %01111110
    .byte       0

font_9:
    .byte       %01001110
    .byte       %01001010
    .byte       %01111110
    .byte       0


font_colon:
    .byte       %00101000
    .byte       0

font_semicolon:
    .byte       %01000000
    .byte       %00101000
    .byte       0

font_lessthan:
    .byte       %00001000
    .byte       %00010100
    .byte       %00100010
    .byte       0

font_equal:
    .byte       %00010100
    .byte       %00010100
    .byte       0

font_greaterthan:
    .byte       %00100010
    .byte       %00010100
    .byte       %00001000
    .byte       0

font_QM:
    .byte       %00000100
    .byte       %01010010
    .byte       %00001100
    .byte       0

; @ -- using ?

font_A:
    .byte       %01111100
    .byte       %00010010
    .byte       %01111100
    .byte       0

font_B:
    .byte       %01111110
    .byte       %01001010
    .byte       %01110100
    .byte       0

font_C:
    .byte       %00111100
    .byte       %01000010
    .byte       %01000010
    .byte       0

font_D:
    .byte       %01111110
    .byte       %01000010
    .byte       %00111100
    .byte       0

font_E:
    .byte       %01111110
    .byte       %01001010
    .byte       %01000010
    .byte       0

font_F:
    .byte       %01111110
    .byte       %00001010
    .byte       %00000010
    .byte       0

font_G:
    .byte       %00111100
    .byte       %01000010
    .byte       %01001010
    .byte       %00111000
    .byte       0

font_H:
    .byte       %01111110
    .byte       %00001000
    .byte       %01111110
    .byte       0

font_I:
    .byte       %01000010
    .byte       %01111110
    .byte       %01000010
    .byte       0

font_J:
    .byte       %00100000
    .byte       %01000000
    .byte       %00111110
    .byte       0

font_K:
    .byte       %01111110
    .byte       %00010000
    .byte       %01101100
    .byte       0

font_L:
    .byte       %01111110
    .byte       %01000000
    .byte       %01000000
    .byte       0

font_M:
    .byte       %01111110
    .byte       %00000010
    .byte       %00001100
    .byte       %00000010
    .byte       %01111110
    .byte       0

font_N:
    .byte       %01111110
    .byte       %00000100
    .byte       %00001000
    .byte       %01111110
    .byte       0

font_O:
    .byte       %00111100
    .byte       %01000010
    .byte       %00111100
    .byte       0

font_P:
    .byte       %01111110
    .byte       %00010010
    .byte       %00001100
    .byte       0

font_Q:
    .byte       %00111100
    .byte       %01000010
    .byte       %01100010
    .byte       %01011100
    .byte       0

font_R:
    .byte       %01111110
    .byte       %00010010
    .byte       %01101100
    .byte       0

font_S:
    .byte       %01000100
    .byte       %01001010
    .byte       %00110010
    .byte       0

font_T:
    .byte       %00000010
    .byte       %01111110
    .byte       %00000010
    .byte       0

font_U:
    .byte       %00111110
    .byte       %01000000
    .byte       %00111110
    .byte       0

font_V:
    .byte       %00011110
    .byte       %01100000
    .byte       %00011110
    .byte       0

font_W:
    .byte       %00111110
    .byte       %01000000
    .byte       %00110000
    .byte       %01000000
    .byte       %00111110
    .byte       0

font_X:
    .byte       %01110110
    .byte       %00001000
    .byte       %01110110
    .byte       0

font_Y:
    .byte       %00001110
    .byte       %01110000
    .byte       %00001110
    .byte       0

font_Z:
    .byte       %01110010
    .byte       %01001010
    .byte       %01000110
    .byte       0
