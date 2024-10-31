;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; Particles
;
;   Expected usage:
;   1.  erase particles -- restore background byte on current position
;           also reduces age
;   2.  allocate particles -- optional step
;   3.  update particles -- update position and capture background byte
;           also checks boundary conditions
;   4.  draw particles
;
;   Allocate should be before update to capture background.
;-----------------------------------------------------------------------------

.proc particleDemo

    jsr         HOME        ; clear screen
    jsr         GR          ; set low-res graphics mode
    bit         HISCR       ; display high screen

    lda         #0
    sta         curX
    sta         curY
    ldx         #PATTERN_LINE_LEFT
    jsr         drawPattern

    lda         #2
    sta         curX
:
    ldx         #PATTERN_LINE_MIDDLE
    jsr         drawPattern
    clc
    lda         curX
    adc         #4
    sta         curX
    cmp         #38
    bne         :-

    ldx         #PATTERN_LINE_RIGHT
    jsr         drawPattern

    lda         #2
    sta         curY
:
    lda         #0
    sta         curX
    ldx         #PATTERN_SIDE
    jsr         drawPattern
    lda         #38
    sta         curX
    ldx         #PATTERN_SIDE
    jsr         drawPattern
    clc
    lda         curY
    adc         #2
    sta         curY
    cmp         #40
    bne         :-
:
    lda         #0
    sta         curX
    ldx         #PATTERN_SIDE_TEXT
    jsr         drawPattern
    lda         #38
    sta         curX
    ldx         #PATTERN_SIDE_TEXT
    jsr         drawPattern
    clc
    lda         curY
    adc         #2
    sta         curY
    cmp         #48
    bne         :-

    lda         #16
    sta         curX
    sta         curY
    ldx         #PATTERN_GRAY_BRICK
    jsr         drawPattern
    lda         #20
    sta         curX
    ldx         #PATTERN_BLUE_BRICK
    jsr         drawPattern

    jsr         getBG
    sta         ballBG

loop:
    jsr         screenFlip      ; Set up drawing page

    jsr         eraseParticles

    lda         ballBG
    jsr         drawDot

    lda         KBD
    bpl         update
    sta         KBDSTRB

    cmp         #KEY_RIGHT
    bne         :+
    inc         curX
:

    cmp         #KEY_LEFT
    bne         :+
    dec         curX
:

    cmp         #KEY_UP
    bne         :+
    dec         curY
:

    cmp         #KEY_DOWN
    bne         :+
    inc         curY
:

    cmp         #KEY_ESC
    bne         :+
    brk
:

    jsr         allocateParticle
    ;jsr         allocateParticle
    ;jsr         allocateParticle

update:

    jsr         getBG
    sta         ballBG
    lda         #$DD
    jsr         drawDot

    jsr         updateParticles
    jsr         drawParticles

    jmp         loop

ballBG:         .byte   0
.endproc

;-----------------------------------------------------------------------------
; Erase Particles
;-----------------------------------------------------------------------------

.proc eraseParticles

    ldx         #0
loop:
    lda         particleTable_age,x
    beq         next

    lda         particleTable_y1,x
    lsr                         ; divide by 2
    tay
    lda         particleTable_x1,x
    clc
    adc         lineOffset,y
    sta         screenPtr0
    lda         linePage,y
    adc         drawPage
    sta         screenPtr1

    ldy         #0
    lda         particleTable_bg,x
    sta         (screenPtr0),y

    dec         particleTable_age,x

next:
    txa
    clc
    adc         #PARTICLE_ENTRY_SIZE
    tax
    cmp         #PARTICLE_TABLE_SIZE
    bne         loop
    rts

.endProc

;-----------------------------------------------------------------------------
; Allocate Particle
;-----------------------------------------------------------------------------
.proc allocateParticle
    ldx         particleWritePtr

    ; set age and position
    lda         #50
    sta         particleTable_age,x
    lda         #$80
    sta         particleTable_x0,x
    sta         particleTable_y0,x
    lda         curX
    sta         particleTable_x1,x
    lda         curY

    ; set vector
    ldy         particleVectorReadPtr
    sta         particleTable_y1,x
    lda         particleVectorTable+0,y
    sta         particleTable_vx0,x
    lda         particleVectorTable+1,y
    sta         particleTable_vx1,x
    lda         particleVectorTable+2,y
    sta         particleTable_vy0,x
    lda         particleVectorTable+3,y
    sta         particleTable_vy1,x
    tya
    clc
    adc         #4
    sta         particleVectorReadPtr

    ; set color
    ldy         particleColorReadPtr
    lda         particleColorTable+0,y
    sta         particleTable_color0,x
    lda         particleColorTable+1,y
    sta         particleTable_color1,x
    tya
    clc
    adc         #2
    cmp         #15*2       ; use 15 so relatively prime with 256 vectors
    bne         :+
    lda         #0
:
    sta         particleColorReadPtr

    ; Not setting background as will get set by update

    ; update write pointer
    txa
    clc
    adc         #PARTICLE_ENTRY_SIZE
    cmp         #PARTICLE_TABLE_SIZE
    bne         :+
    lda         #0
:
    sta         particleWritePtr

    rts
.endProc

;-----------------------------------------------------------------------------
; Update Particles
;-----------------------------------------------------------------------------

.proc updateParticles

    ldx         #0
loop:
    lda         particleTable_age,x
    beq         next

    ; update X
    clc
    lda         particleTable_x0,x
    adc         particleTable_vx0,x
    sta         particleTable_x0,x
    lda         particleTable_x1,x
    adc         particleTable_vx1,x
    sta         particleTable_x1,x

    ; check boundaries
    bmi         outOfBounds     ; x < 0
    cmp         #40
    bcs         outOfBounds     ; x >= 40

    ; update Y
    clc
    lda         particleTable_y0,x
    adc         particleTable_vy0,x
    sta         particleTable_y0,x
    lda         particleTable_y1,x
    adc         particleTable_vy1,x
    sta         particleTable_y1,x

    ; check boundaries
    bmi         outOfBounds     ; y < 0
    cmp         #40
    bcs         outOfBounds     ; y >= 40

    lsr                         ; divide by 2
    tay
    lda         particleTable_x1,x
    clc
    adc         lineOffset,y
    sta         screenPtr0
    lda         linePage,y
    adc         drawPage
    sta         screenPtr1

    ldy         #0
    lda         (screenPtr0),y
    sta         particleTable_bg,x

    ; gravity
    clc
    lda         particleTable_vy0,x
    adc         #3
    sta         particleTable_vy0,x
    lda         particleTable_vy1,x
    adc         #0
    sta         particleTable_vy1,x

next:
    txa
    clc
    adc         #PARTICLE_ENTRY_SIZE
    tax
    cmp         #PARTICLE_TABLE_SIZE
    bne         loop
    rts

outOfBounds:
    lda         #0
    sta         particleTable_age,x
    jmp         next

.endProc


;-----------------------------------------------------------------------------
; Draw Particles
;-----------------------------------------------------------------------------
.proc drawParticles

    ldx         #0
loop:
    lda         particleTable_age,x
    beq         next

    sta         SPEAKER

    lda         particleTable_y1,x
    lsr                         ; divide by 2
    tay

    lda         particleTable_x1,x
    clc
    adc         lineOffset,y
    sta         screenPtr0
    lda         linePage,y
    adc         drawPage
    sta         screenPtr1

    ldy         #0
    lda         particleTable_y1,x
    and         #1
    bne         odd
    ; even
    lda         (screenPtr0),y
    and         #$F0
    ora         particleTable_color0,x
    sta         (screenPtr0),y
    jmp         next
odd:
    lda         (screenPtr0),y
    and         #$0F
    ora         particleTable_color1,x
    sta         (screenPtr0),y

next:
    txa
    clc
    adc         #PARTICLE_ENTRY_SIZE
    tax

    cmp         #PARTICLE_TABLE_SIZE
    bne         loop
    rts

.endProc

;-----------------------------------------------------------------------------
; Particle table
;-----------------------------------------------------------------------------

PARTICLE_ENTRY_SIZE     = particleTable_entryEnd - particleTable
PARTICLE_TABLE_SIZE     = particleTable_tableEnd - particleTable

.align 256
particleTable:
particleTable_age:      .byte   $00         ; 0 = none
particleTable_x0:       .byte   $00
particleTable_x1:       .byte   $00
particleTable_y0:       .byte   $00
particleTable_y1:       .byte   $00
particleTable_vx0:      .byte   $00
particleTable_vx1:      .byte   $00
particleTable_vy0:      .byte   $00
particleTable_vy1:      .byte   $00
particleTable_color0:   .byte   $00         ; even row color (lower nibble)
particleTable_color1:   .byte   $00         ; odd row color (upper nibble)
particleTable_bg:       .byte   $00         ; saved background byte
particleTable_entryEnd:
                        .res    PARTICLE_ENTRY_SIZE*20  ; 21 total (21*12 < 256)
particleTable_tableEnd:
particleWritePtr:       .byte   0
particleVectorReadPtr:  .byte   0
particleColorReadPtr:   .byte   0

;-----------------------------------------------------------------------------
; Lookup Tables
;-----------------------------------------------------------------------------

; Following is random points on the unit circle randomly scaled between
; 0.25 and 0.75 with 8-bit fraction scaled to 16 bit fixed point.
; There are 64 vectors to fill a page of memory such that a pointer
; can freely wrap.

.align 256

particleVectorTable:
;       vx0, vx1, vy0, vy1
;       ---- ---- ---- ---
  .byte $2c, $0 , $a3, $ff    ; scale=   0.4      0.17,   -0.36
  .byte $5b, $ff, $5d, $0     ; scale=  0.74     -0.64,    0.37
  .byte $a2, $0 , $4d, $0     ; scale=  0.71      0.64,    0.31
  .byte $b4, $ff, $9e, $ff    ; scale=  0.48     -0.29,   -0.38
  .byte $db, $ff, $b1, $ff    ; scale=  0.33     -0.14,    -0.3
  .byte $90, $0 , $b1, $ff    ; scale=  0.64      0.57,    -0.3
  .byte $63, $ff, $e7, $ff    ; scale=  0.62     -0.61,  -0.092
  .byte $97, $ff, $74, $0     ; scale=  0.61      -0.4,    0.46
  .byte $43, $0 , $f9, $ff    ; scale=  0.27      0.26,  -0.023
  .byte $24, $0 , $9c, $0     ; scale=  0.63      0.14,    0.61
  .byte $dc, $ff, $b2, $ff    ; scale=  0.33     -0.14,    -0.3
  .byte $59, $0 , $a0, $0     ; scale=  0.72      0.35,    0.63
  .byte $50, $ff, $da, $ff    ; scale=   0.7     -0.69,   -0.14
  .byte $6b, $ff, $ee, $ff    ; scale=  0.58     -0.58,  -0.064
  .byte $7e, $ff, $72, $ff    ; scale=  0.75      -0.5,   -0.55
  .byte $aa, $ff, $9c, $ff    ; scale=  0.51     -0.33,   -0.39
  .byte $35, $0 , $ce, $ff    ; scale=  0.28      0.21,   -0.19
  .byte $e2, $ff, $a6, $ff    ; scale=  0.36     -0.11,   -0.35
  .byte $ad, $ff, $68, $0     ; scale=  0.52     -0.32,    0.41
  .byte $73, $0 , $c6, $ff    ; scale=   0.5      0.45,   -0.22
  .byte $26, $0 , $9f, $ff    ; scale=   0.4      0.15,   -0.38
  .byte $66, $0 , $2f, $0     ; scale=  0.44       0.4,    0.19
  .byte $b7, $ff, $10, $0     ; scale=  0.29     -0.28,   0.064
  .byte $df, $ff, $a5, $0     ; scale=  0.66     -0.12,    0.65
  .byte $60, $0 , $90, $ff    ; scale=  0.57      0.38,   -0.43
  .byte $6e, $ff, $5e, $0     ; scale=  0.68     -0.57,    0.37
  .byte $d5, $ff, $3d, $0     ; scale=  0.29     -0.16,    0.24
  .byte $35, $0 , $d5, $ff    ; scale=  0.26      0.21,   -0.16
  .byte $83, $ff, $80, $0     ; scale=   0.7     -0.49,     0.5
  .byte $26, $0 , $82, $0     ; scale=  0.53      0.15,    0.51
  .byte $4a, $ff, $f1, $ff    ; scale=  0.71     -0.71,  -0.053
  .byte $6c, $0 , $6f, $ff    ; scale=  0.71      0.43,   -0.56
  .byte $a0, $ff, $13, $0     ; scale=  0.38     -0.37,   0.075
  .byte $56, $0 , $ce, $ff    ; scale=  0.39      0.34,   -0.19
  .byte $6d, $ff, $33, $0     ; scale=  0.61     -0.57,     0.2
  .byte $ac, $0 , $e6, $ff    ; scale=  0.68      0.68,  -0.097
  .byte $a7, $ff, $71, $ff    ; scale=  0.65     -0.34,   -0.55
  .byte $3d, $0 , $19, $0     ; scale=  0.26      0.24,     0.1
  .byte $8b, $ff, $a7, $ff    ; scale=  0.57     -0.45,   -0.34
  .byte $2a, $0 , $31, $0     ; scale=  0.26      0.17,    0.19
  .byte $db, $ff, $66, $0     ; scale=  0.43     -0.14,     0.4
  .byte $83, $0 , $13, $0     ; scale=  0.52      0.52,   0.077
  .byte $c3, $ff, $66, $0     ; scale=  0.46     -0.23,     0.4
  .byte $41, $ff, $eb, $ff    ; scale=  0.75     -0.74,  -0.075
  .byte $89, $ff, $84, $0     ; scale=   0.7     -0.46,    0.52
  .byte $8f, $ff, $ed, $ff    ; scale=  0.44     -0.44,  -0.068
  .byte $a3, $ff, $f8, $ff    ; scale=  0.36     -0.36,  -0.024
  .byte $c4, $ff, $98, $ff    ; scale=  0.46     -0.23,    -0.4
  .byte $3 , $0 , $7b, $0     ; scale=  0.48     0.016,    0.48
  .byte $4b, $0 , $ef, $ff    ; scale=   0.3       0.3,  -0.061
  .byte $3d, $0 , $dc, $ff    ; scale=  0.28      0.24,   -0.13
  .byte $98, $ff, $e7, $ff    ; scale=  0.41      -0.4,  -0.093
  .byte $d1, $ff, $50, $0     ; scale=  0.36     -0.18,    0.32
  .byte $b3, $0 , $27, $0     ; scale=  0.72      0.71,    0.16
  .byte $b1, $0 , $11, $0     ; scale=   0.7       0.7,   0.068
  .byte $8a, $ff, $83, $ff    ; scale=  0.66     -0.46,   -0.48
  .byte $4d, $ff, $37, $0     ; scale=  0.73      -0.7,    0.22
  .byte $d6, $ff, $49, $0     ; scale=  0.33     -0.16,    0.29
  .byte $57, $ff, $af, $ff    ; scale=  0.73     -0.66,   -0.31
  .byte $d4, $ff, $73, $ff    ; scale=  0.57     -0.17,   -0.55
  .byte $c2, $ff, $a3, $ff    ; scale=  0.43     -0.24,   -0.36
  .byte $3e, $0 , $c , $0     ; scale=  0.25      0.25,   0.049
  .byte $26, $0 , $a7, $ff    ; scale=  0.37      0.15,   -0.34
  .byte $4d, $0 , $9f, $ff    ; scale=  0.48       0.3,   -0.38

.align 256

particleColorTable:

    .byte   $0b, $b0        ; pink
    .byte   $0b, $b0        ; pink
    .byte   $01, $10        ; red
    .byte   $0b, $b0        ; pink
    .byte   $0b, $b0        ; pink

    .byte   $09, $90        ; orange
    .byte   $0b, $b0        ; pink
    .byte   $01, $10        ; red
    .byte   $0b, $b0        ; pink
    .byte   $09, $90        ; orange

    .byte   $0b, $b0        ; pink
    .byte   $0b, $b0        ; pink
    .byte   $01, $10        ; red
    .byte   $0b, $b0        ; pink
    .byte   $0b, $b0        ; pink

