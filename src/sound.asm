;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------

SOUND_WAKEUP =  soundWakeup - soundTablePitch
SOUND_DEAD   =  soundDead   - soundTablePitch
SOUND_ENGINE =  soundEngine - soundTablePitch
SOUND_REFUEL =  soundRefuel - soundTablePitch

;-----------------------------------------------------------------------------
; updateSound
;-----------------------------------------------------------------------------
;   Call periodically to play sound.
.proc updateSound

    lda         soundActive
    bne         :+
    rts
:
    ldx         soundIndex
    ldy         soundPitch,x
    dec         soundCounter
    bne         :+
    sta         SPEAKER
    sty         soundCounter
:
    dec         soundLength,x
    bne         done
    inc         soundIndex
    ldx         soundIndex
    ldy         soundPitch,x
    sty         soundCounter
    lda         soundLength,x
    bne         done
    sta         soundActive
done:
    rts
.endproc

;-----------------------------------------------------------------------------
; playSound
;   play sound if not already playing a previous sound
;   use playSoundOverride to always play new sound
;   pass sound in X
;-----------------------------------------------------------------------------
.proc playSound
    lda         soundActive
    beq         playSoundOverride
    rts
.endproc

.proc playSoundOverride
    ldy         #0
    sty         soundIndex
loop:
    lda         soundTablePitch,x
    sta         soundPitch,y
    lda         soundTableLength,x
    sta         soundLength,y
    beq         done
    inx
    iny
    jmp         loop
done:
    lda         #1
    sta         soundActive
    lda         soundPitch
    sta         soundCounter
    rts
.endproc

soundTablePitch:
soundWakeup:        .byte   2,    1,   3,   1,   0
soundDead:          .byte   1,    2,   4,   0
soundEngine:        .byte   4,    3,   0
soundRefuel:        .byte   1,    0,   0
soundTableLength:
                    .byte   140,  140, 140, 140, 0
                    .byte   140,  140, 140, 0
                    .byte   10,   10, 0
                    .byte   10,   20, 0

;-----------------------------------------------------------------------------
; Globals
;-----------------------------------------------------------------------------

soundActive:    .byte   0
soundIndex:     .byte   0
soundCounter:   .byte   0
soundPitch:     .res    8
soundLength:    .res    8

