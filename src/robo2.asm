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

BORDER_COLOR0   = $15
BORDER_COLOR1   = $51
BG_COLOR        = $77

SCREEN_TOP      = 4
SCREEN_BOTTOM   = 44
SCREEN_LEFT     = 3
SCREEN_RIGHT    = 37

JOYSTICK_DELAY  = 10
JOYSTICK_TAP1   = SCREEN_LEFT+JOYSTICK_DELAY
JOYSTICK_TAP2   = JOYSTICK_TAP1+JOYSTICK_DELAY

.proc main

    ;----------------------------------
    ; Init
    ;----------------------------------
    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    sta         MIXCLR      ; full screen
    bit         HISCR       ; Display page2 so switch to page1

    lda         #BORDER_COLOR0
    sta         bg0
    lda         #BORDER_COLOR1
    sta         bg1
    lda         #0
    sta         drawPage
    jsr         clearScreen
    lda         #4
    sta         drawPage
    jsr         clearScreen

    ldx         #SOUND_WAKEUP
    jsr         playSound

    lda         #20
    sta         playerX
    lda         #20
    sta         playerY
    lda         #(1*2+1)*2
    sta         playerDir

loop:
    ; Timer
    inc         time0
    bne         :+
    inc         time1       ; about once every 2 seconds
:

    ; flip page
    lda         PAGE2
    bmi         :+
    bit         HISCR
    jmp         clear
:
    bit         LOWSCR

clear:
    jsr         clearPartialScreen
    jsr         updateSound

    ; Movement
checkLeft:
    lda         joystickX
    bne         checkRight
    lda         playerX
    cmp         #SCREEN_LEFT
    beq         checkUp
    dec         playerX

checkRight:
    cmp         #2
    bne         checkUp
    lda         playerX
    cmp         #SCREEN_RIGHT-3
    beq         checkUp
    inc         playerX

checkUp:
    lda         joystickY
    bne         checkDown
    lda         playerY
    cmp         #SCREEN_TOP
    beq         checkButton
    dec         playerY

checkDown:
    cmp         #2
    bne         checkButton
    lda         playerY
    cmp         #SCREEN_BOTTOM-3
    beq         checkButton
    inc         playerY

checkButton:
    lda         BUTTON0
    bmi         shoot
    ; if button not pressed let direction follow movement
    lda         joystickIndex
    asl
    sta         playerDir       ; direction set
    jmp         drawPlayer

shoot:
    ; nothing yet

drawPlayer:
    jsr         setPlayerShape
    lda         playerY
    ldy         playerX
    jsr         draw3x3

    lda         KBD
    bpl         loop
    sta         KBDSTRB

    jmp         quit


.endproc



;-----------------------------------------------------------------------------
; Clear Screen
;-----------------------------------------------------------------------------

.proc clearPartialScreen
    lda         #0
    sta         joystickX
    sta         joystickY
    lda         #JOYSTICK_TAP1
    sta         compare
    sta         GCRESET
    ldx         #SCREEN_LEFT
    lda         PAGE2           ; bit 7 = page2 displayed
    bmi         clear0          ; display high, so draw low
    jmp         clear1

clear0:
    lda         #BG_COLOR
loop0:
    ;sta         $0400,x
    ;sta         $0480,x
    sta         $0500,x
    sta         $0580,x
    sta         $0600,x
    sta         $0680,x
    sta         $0700,x
    sta         $0780,x
    sta         $0428,x
    sta         $04A8,x
    sta         $0528,x
    sta         $05A8,x
    sta         $0628,x
    sta         $06A8,x
    sta         $0728,x
    sta         $07A8,x
    sta         $0450,x
    sta         $04D0,x
    sta         $0550,x
    sta         $05D0,x
    sta         $0650,x
    sta         $06D0,x
    ;sta         $0750,x
    ;sta         $07D0,x

    inx
    cpx         compare
    bne         loop0

    jsr         update
    bne         clear0

    lda         #0
    sta         drawPage        ; draw on cleared page

    lda         joystickY
    asl
    asl
    ora         joystickX
    sta         joystickIndex
    rts

clear1:
    lda         #BG_COLOR

loop1:
    ;sta         $0800,x
    ;sta         $0880,x
    sta         $0900,x
    sta         $0980,x
    sta         $0A00,x
    sta         $0A80,x
    sta         $0B00,x
    sta         $0B80,x
    sta         $0828,x
    sta         $08A8,x
    sta         $0928,x
    sta         $09A8,x
    sta         $0A28,x
    sta         $0AA8,x
    sta         $0B28,x
    sta         $0BA8,x
    sta         $0850,x
    sta         $08D0,x
    sta         $0950,x
    sta         $09D0,x
    sta         $0A50,x
    sta         $0AD0,x
    ;sta         $0B50,x
    ;sta         $0BD0,x

    inx
    cpx         compare
    bne         loop1

    jsr         update
    bne         clear1

    lda         #4
    sta         drawPage        ; draw on cleared page

    lda         joystickY
    asl
    asl
    ora         joystickX
    sta         joystickIndex
    rts

update:
    ; check if done
    cpx         #SCREEN_RIGHT
    bne         :+
    lda         #0
    rts
:

    ; update joystick (two times)
    lda         GC0
    bpl         :+
    inc         joystickX
:
    lda         GC1
    bpl         :+
    inc         joystickY
:

    ; tap1 -> tap2
    cpx         #JOYSTICK_TAP1
    bne         :+
    lda         #JOYSTICK_TAP2
    sta         compare
    rts
:
    ; tap2 -> screen_right
    lda         #SCREEN_RIGHT
    sta         compare
    rts

compare:        .byte   0
.endproc


;-----------------------------------------------------------------------------
; draw3x3
;   a - line lookup
;   y - line offset
;-----------------------------------------------------------------------------

.proc draw3x3
    lsr
    tax
    lda         lineOffset,x
    sta         screenPtr0
    lda         linePage,x
    clc
    adc         drawPage
    sta         screenPtr1
    inx
    stx         row

    ldx         shape0
    lda         (screenPtr0),y
    and         colorAnd0,x
    ora         colorOr0,x
    sta         (screenPtr0),y
    iny
    ldx         shape1
    lda         (screenPtr0),y
    and         colorAnd0,x
    ora         colorOr0,x
    sta         (screenPtr0),y
    iny
    ldx         shape2
    lda         (screenPtr0),y
    and         colorAnd0,x
    ora         colorOr0,x
    sta         (screenPtr0),y
    dey
    dey

    ldx         row
    lda         lineOffset,x
    sta         screenPtr0
    lda         linePage,x
    clc
    adc         drawPage
    sta         screenPtr1
    inx
    stx         row

    ldx         shape0
    lda         (screenPtr0),y
    and         colorAnd1,x
    ora         colorOr1,x
    sta         (screenPtr0),y
    iny
    ldx         shape1
    lda         (screenPtr0),y
    and         colorAnd1,x
    ora         colorOr1,x
    sta         (screenPtr0),y
    iny
    ldx         shape2
    lda         (screenPtr0),y
    and         colorAnd1,x
    ora         colorOr1,x
    sta         (screenPtr0),y

    rts

row:        .byte   0

.endproc

;-----------------------------------------------------------------------------
; Set Player Shape
;-----------------------------------------------------------------------------
.proc setPlayerShape
    lda         playerY
    and         #1
    ora         playerDir
    tax
    lda         playerShape0,x
    sta         shape0
    lda         playerShape1,x
    sta         shape1
    lda         playerShape2,x
    sta         shape2
    rts

    ; shifted joystick directions
    ; 0000 0001 0010
    ; 0100 0101 0110
    ; 1000 1001 1010
    ;
    ; player shapes:
    ;
    ; 322 232 223
    ; 232 232 232
    ; 222 222 222
    ;
    ; 222 222 222
    ; 332 232 233
    ; 222 222 222
    ;
    ; 222 222 222
    ; 232 232 232
    ; 322 232 223

playerShape0:
    .byte   $2B,$AC,$2A,$A8,$2A,$A8,0,0
    .byte   $2E,$B8,$2A,$A8,$2A,$A8,0,0
    .byte   $3A,$E8,$2A,$A8,$2A,$A8,0,0

playerShape1:
    .byte   $2E,$B8,$2F,$BC,$2E,$B8,0,0         ; filled center
    .byte   $2E,$B8,$2E,$B8,$2E,$B8,0,0
    .byte   $2E,$B8,$3E,$F8,$2E,$B8,0,0
;    .byte   $22,$88,$23,$8C,$22,$88,0,0        ; hollow center
;    .byte   $22,$88,$2E,$B8,$22,$88,0,0
;    .byte   $22,$88,$32,$C8,$22,$88,0,0

playerShape2:
    .byte   $2A,$A8,$2A,$A8,$2B,$AC,0,0
    .byte   $2A,$A8,$2A,$A8,$2E,$B8,0,0
    .byte   $2A,$A8,$2A,$A8,$3A,$E8,0,0

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

;-----------------------------------------------------------------------------
; Globals
;-----------------------------------------------------------------------------

playerX:        .byte   0
playerY:        .byte   0
playerDir:      .byte   0       ; joystick direction *2

joystickX:      .byte   0       ; 0=left, 1=middle, 2=right
joystickY:      .byte   0       ; 0=up, 1=middle, 2=down
joystickIndex:  .byte   0       ; y*2+x
time0:          .byte   0
time1:          .byte   0

shape0:         .byte   0
shape1:         .byte   0
shape2:         .byte   0

; color lookup tables
; aabbccdd 0 = mask, 1..3 colors

COLOR_AND0      = $F
COLOR_AND1      = $0
COLOR_AND2      = $0
COLOR_AND3      = $0

COLOR_OR0       = $0
COLOR_OR1       = $1
COLOR_OR2       = $2
COLOR_OR3       = $3


COLOR_AND_00    = COLOR_AND0 << 4 | COLOR_AND0
COLOR_AND_01    = COLOR_AND0 << 4 | COLOR_AND1
COLOR_AND_02    = COLOR_AND0 << 4 | COLOR_AND2
COLOR_AND_03    = COLOR_AND0 << 4 | COLOR_AND3
COLOR_AND_10    = COLOR_AND1 << 4 | COLOR_AND0
COLOR_AND_11    = COLOR_AND1 << 4 | COLOR_AND1
COLOR_AND_12    = COLOR_AND1 << 4 | COLOR_AND2
COLOR_AND_13    = COLOR_AND1 << 4 | COLOR_AND3
COLOR_AND_20    = COLOR_AND2 << 4 | COLOR_AND0
COLOR_AND_21    = COLOR_AND2 << 4 | COLOR_AND1
COLOR_AND_22    = COLOR_AND2 << 4 | COLOR_AND2
COLOR_AND_23    = COLOR_AND2 << 4 | COLOR_AND3
COLOR_AND_30    = COLOR_AND3 << 4 | COLOR_AND0
COLOR_AND_31    = COLOR_AND3 << 4 | COLOR_AND1
COLOR_AND_32    = COLOR_AND3 << 4 | COLOR_AND2
COLOR_AND_33    = COLOR_AND3 << 4 | COLOR_AND3

COLOR_OR_00     = COLOR_OR0 << 4 | COLOR_OR0
COLOR_OR_01     = COLOR_OR0 << 4 | COLOR_OR1
COLOR_OR_02     = COLOR_OR0 << 4 | COLOR_OR2
COLOR_OR_03     = COLOR_OR0 << 4 | COLOR_OR3
COLOR_OR_10     = COLOR_OR1 << 4 | COLOR_OR0
COLOR_OR_11     = COLOR_OR1 << 4 | COLOR_OR1
COLOR_OR_12     = COLOR_OR1 << 4 | COLOR_OR2
COLOR_OR_13     = COLOR_OR1 << 4 | COLOR_OR3
COLOR_OR_20     = COLOR_OR2 << 4 | COLOR_OR0
COLOR_OR_21     = COLOR_OR2 << 4 | COLOR_OR1
COLOR_OR_22     = COLOR_OR2 << 4 | COLOR_OR2
COLOR_OR_23     = COLOR_OR2 << 4 | COLOR_OR3
COLOR_OR_30     = COLOR_OR3 << 4 | COLOR_OR0
COLOR_OR_31     = COLOR_OR3 << 4 | COLOR_OR1
COLOR_OR_32     = COLOR_OR3 << 4 | COLOR_OR2
COLOR_OR_33     = COLOR_OR3 << 4 | COLOR_OR3


.align 256

colorAnd0:
.repeat(16)
    .byte   COLOR_AND_00,   COLOR_AND_01,   COLOR_AND_02,   COLOR_AND_03
    .byte   COLOR_AND_10,   COLOR_AND_11,   COLOR_AND_12,   COLOR_AND_13
    .byte   COLOR_AND_20,   COLOR_AND_21,   COLOR_AND_22,   COLOR_AND_23
    .byte   COLOR_AND_30,   COLOR_AND_31,   COLOR_AND_32,   COLOR_AND_33
.endrepeat

colorOr0:
.repeat(16)
    .byte   COLOR_OR_00,    COLOR_OR_01,    COLOR_OR_02,    COLOR_OR_03
    .byte   COLOR_OR_10,    COLOR_OR_11,    COLOR_OR_12,    COLOR_OR_13
    .byte   COLOR_OR_20,    COLOR_OR_21,    COLOR_OR_22,    COLOR_OR_23
    .byte   COLOR_OR_30,    COLOR_OR_31,    COLOR_OR_32,    COLOR_OR_33
.endrepeat

colorAnd1:
.repeat(16)
    .byte   COLOR_AND_00
.endrepeat
.repeat(16)
    .byte   COLOR_AND_01
.endrepeat
.repeat(16)
    .byte   COLOR_AND_02
.endrepeat
.repeat(16)
    .byte   COLOR_AND_03
.endrepeat
.repeat(16)
    .byte   COLOR_AND_10
.endrepeat
.repeat(16)
    .byte   COLOR_AND_11
.endrepeat
.repeat(16)
    .byte   COLOR_AND_12
.endrepeat
.repeat(16)
    .byte   COLOR_AND_13
.endrepeat
.repeat(16)
    .byte   COLOR_AND_20
.endrepeat
.repeat(16)
    .byte   COLOR_AND_21
.endrepeat
.repeat(16)
    .byte   COLOR_AND_22
.endrepeat
.repeat(16)
    .byte   COLOR_AND_23
.endrepeat
.repeat(16)
    .byte   COLOR_AND_30
.endrepeat
.repeat(16)
    .byte   COLOR_AND_31
.endrepeat
.repeat(16)
    .byte   COLOR_AND_32
.endrepeat
.repeat(16)
    .byte   COLOR_AND_33
.endrepeat

colorOr1:
.repeat(16)
    .byte   COLOR_OR_00
.endrepeat
.repeat(16)
    .byte   COLOR_OR_01
.endrepeat
.repeat(16)
    .byte   COLOR_OR_02
.endrepeat
.repeat(16)
    .byte   COLOR_OR_03
.endrepeat
.repeat(16)
    .byte   COLOR_OR_10
.endrepeat
.repeat(16)
    .byte   COLOR_OR_11
.endrepeat
.repeat(16)
    .byte   COLOR_OR_12
.endrepeat
.repeat(16)
    .byte   COLOR_OR_13
.endrepeat
.repeat(16)
    .byte   COLOR_OR_20
.endrepeat
.repeat(16)
    .byte   COLOR_OR_21
.endrepeat
.repeat(16)
    .byte   COLOR_OR_22
.endrepeat
.repeat(16)
    .byte   COLOR_OR_23
.endrepeat
.repeat(16)
    .byte   COLOR_OR_30
.endrepeat
.repeat(16)
    .byte   COLOR_OR_31
.endrepeat
.repeat(16)
    .byte   COLOR_OR_32
.endrepeat
.repeat(16)
    .byte   COLOR_OR_33
.endrepeat


;-----------------------------------------------------------------------------
; Libraries
;-----------------------------------------------------------------------------

.include "inline_print.asm"
.include "grlib.asm"
.include "sound.asm"
