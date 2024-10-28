;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; GR Lib
; Collection of lo-res graphic routines


.proc particleDemo


loop:
	;sta 		SPEAKER 		; buzz!

	jsr 		screenFlip		; Set up drawing page

	jsr 		eraseParticles
	jsr 		updateParticles
	jsr 		drawParticles

;:
;	lda 		KBD
;	bpl 		:-
;	sta 		KBDSTRB

	jmp 		loop

.endproc


;-----------------------------------------------------------------------------
; Screen flip
; 	Performs the following
; 		swaps the current displaying page
; 		set drawPage
;		copies the newly displaying page to other page for updating
;-----------------------------------------------------------------------------
.proc screenFlip

    ; Switch page
	ldx 		#120-1
    lda         PAGE2           ; bit 7 = page2 displayed
    bmi         switchTo1

    ; switch page 2
    bit         HISCR           ; display high screen
    lda         #$00            ; update low screen
    sta         drawPage

    ; copy page 2 to page 1
:
	lda 		$800,x
	sta 		$400,x
	lda 		$880,x
	sta 		$480,x
	lda 		$900,x
	sta 		$500,x
	lda 		$980,x
	sta 		$580,x
	lda 		$A00,x
	sta 		$600,x
	lda 		$A80,x
	sta 		$680,x
	lda 		$B00,x
	sta 		$700,x
	lda 		$B80,x
	sta 		$780,x
	dex
	bpl 		:-
	rts

switchTo1:
    bit         LOWSCR          ; display low screen
    lda         #$04            ; update high screen
    sta         drawPage

    ; copy page 1 to page 2
:
	lda 		$400,x
	sta 		$800,x
	lda 		$480,x
	sta 		$880,x
	lda 		$500,x
	sta 		$900,x
	lda 		$580,x
	sta 		$980,x
	lda 		$600,x
	sta 		$A00,x
	lda 		$680,x
	sta 		$A80,x
	lda 		$700,x
	sta 		$B00,x
	lda 		$780,x
	sta 		$B80,x
	dex
	bpl 		:-
	rts

.endproc

;-----------------------------------------------------------------------------
; Draw Particle
; 	Draw particles on screen
;
;   Need to erase all before capturing background
;   Need to capture all backgrounds before drawing
;
;	Loop
; 		erase
; 		reduce age
;	Loop
;		update position
; 			check boundaries
; 		capture background
; 	Loop
; 		draw
;
;-----------------------------------------------------------------------------

.proc eraseParticles

	ldx 		#0
loop:
	lda 		particleTable_age,x
	beq 		next

	lda 		particleTable_y1,x
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
    lda 		particleTable_bg,x
    sta         (screenPtr0),y

    dec			particleTable_age,x

next:
	txa
	clc
	adc 		#PARTICLE_ENTRY_SIZE
	tax
	cmp 		#PARTICLE_TABLE_SIZE
	bne 		loop
	rts

.endProc

.proc updateParticles

	ldx 		#0
loop:
	lda 		particleTable_age,x
	beq 		next

	; update X
	clc
	lda 		particleTable_x0,x
	adc 		particleTable_vx0,x
	sta 		particleTable_x0,x
	lda 		particleTable_x1,x
	adc 		particleTable_vx1,x
	sta 		particleTable_x1,x

	; check boundaries
	bmi 		outOfBounds 	; x < 0
	cmp 		#40
	bcs 		outOfBounds		; x >= 40

	; update Y
	clc
	lda 		particleTable_y0,x
	adc 		particleTable_vy0,x
	sta 		particleTable_y0,x
	lda 		particleTable_y1,x
	adc 		particleTable_vy1,x
	sta 		particleTable_y1,x

	; check boundaries
	bmi 		outOfBounds 	; y < 0
	cmp 		#40
	bcs 		outOfBounds 	; y >= 40

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
    sta 		particleTable_bg,x

next:
	txa
	clc
	adc 		#PARTICLE_ENTRY_SIZE
	tax
	cmp 		#PARTICLE_TABLE_SIZE
	bne 		loop
	rts

outOfBounds:
	lda 		#0
	sta 		particleTable_age,x
	jmp 		next

.endProc

.proc drawParticles

	ldx 		#0
loop:
	lda 		particleTable_age,x
	beq 		next

	lda 		particleTable_y1,x
    lsr                         ; divide by 2
    tay

    lda         particleTable_x1,x
    clc
    adc         lineOffset,y
    sta         screenPtr0
    lda         linePage,y
    adc         drawPage
    sta         screenPtr1

    ldy 		#0
    lda         particleTable_y1,x
    and         #1
    bne         odd
    ; even
    lda         (screenPtr0),y
    and         #$F0
    ora         particleTable_color0,x
    sta         (screenPtr0),y
    jmp 		next
odd:
    lda         (screenPtr0),y
    and         #$0F
    ora         particleTable_color1,x
    sta         (screenPtr0),y

next:
	txa
	clc
	adc 		#PARTICLE_ENTRY_SIZE
	tax

	cmp 		#PARTICLE_TABLE_SIZE
	bne 		loop
	rts

.endProc

;-----------------------------------------------------------------------------
; Particle table
;-----------------------------------------------------------------------------

PARTICLE_ENTRY_SIZE 	= particleTable_entryEnd - particleTable
PARTICLE_TABLE_SIZE 	= particleTable_tableEnd - particleTable

.align 256
particleTable:
particleTable_age: 		.byte 	$ff 		; 0 = none
particleTable_x0: 		.byte 	$80
particleTable_x1: 		.byte 	$14
particleTable_y0: 		.byte 	$80
particleTable_y1: 		.byte 	$12
particleTable_vx0: 		.byte 	$FF
particleTable_vx1: 		.byte 	$00
particleTable_vy0: 		.byte 	$FF
particleTable_vy1: 		.byte 	$00
particleTable_color0: 	.byte 	$0B 		; even row color (lower nibble)
particleTable_color1: 	.byte 	$B0			; odd row color (upper nibble)
particleTable_bg:    	.byte 	$55 		; saved background byte
particleTable_entryEnd:
						.byte	$ff,  $00,$18,  $00,$0F,  $00,$FF,  $00,$FF,  $0C,$C0,$55
; remaining particles
						.res 	PARTICLE_ENTRY_SIZE*(16-2)
particleTable_tableEnd:
allocateParticle: 		.byte 	0

;-----------------------------------------------------------------------------
; Lookup Tables
;-----------------------------------------------------------------------------
.align 256

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

