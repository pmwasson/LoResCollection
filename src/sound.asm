;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------

SOUND_OFF    =  soundOff    - soundTable
SOUND_WAKEUP =  soundWakeup - soundTable
SOUND_DEAD   =  soundDead   - soundTable
SOUND_REFUEL =  soundRefuel - soundTable
SOUND_CHARM  =  soundCharm  - soundTable
SOUND_BUMP   =  soundBump   - soundTable
SOUND_ENGINE =  soundEngine - soundTable

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
;   play sound if not already playing a previous sound or higher priority
;   use playSoundOverride to always play new sound
;   pass sound in X
;-----------------------------------------------------------------------------
.proc playSound
    cpx         soundActive
    beq         :+
    bcs         playSoundOverride
:
    rts
.endproc

.proc playSoundOverride
    stx         soundActive
    ldy         #0
    sty         soundIndex
loop:
    lda         soundTable,x        ; length
    beq         done
    sta         soundLength,y
    inx
    lda         soundTable,x        ; pitch
    sta         soundPitch,y
    inx
    iny
    jmp         loop
done:
    lda         soundPitch
    sta         soundCounter
    rts
.endproc

; Pairs of length and pitch (length 0 = done)
; Table order by priority (first sound in table lowest priority)
soundTable:
soundOff:       .byte   0
soundEngine:    .byte   10,4,  10,3,  0
soundBump:      .byte   15,2,  0
soundRefuel:    .byte   10,1,  20,0,  0
soundCharm:     .byte   34,2,  35,1,  0
soundDead:      .byte   140,1, 140,2, 140,4, 0
soundWakeup:    .byte   140,2, 140,1, 140,3, 140,1, 0

;-----------------------------------------------------------------------------
; Globals
;-----------------------------------------------------------------------------

soundActive:    .byte   0
soundIndex:     .byte   0
soundCounter:   .byte   0
soundPitch:     .res    8
soundLength:    .res    8

