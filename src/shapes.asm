;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; Game shapes
;

.align 256

; 83 bytes
shape_1x3:                  ; green
    .byte       5           ; 5 pixels wide
    .byte       15          ; 15 pixels high
    .byte       5*8         ; offset
    ; even - 40 bytes
    .byte       $55, $C5, $C5, $C5, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $C4, $CC, $55
    .byte       $55, $55, $55, $55, $55
    ; odd - 40 bytes
    .byte       $55, $55, $55, $55, $55
    .byte       $55, $CC, $4C, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $CC, $44, $CC, $55
    .byte       $55, $5C, $5C, $5C, $55

; 93 bytes
shape_3x1:                  ; orange
    .byte       15          ; 15 pixels wide
    .byte       5           ; 5 pixels high
    .byte       15*3        ; offset (bytes)
    ; even
    .byte       $55, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $55
    .byte       $55, $99, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $99, $55
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    ; odd
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .byte       $55, $99, $89, $89, $89, $89, $89, $89, $89, $89, $89, $89, $89, $99, $55
    .byte       $55, $59, $59, $59, $59, $59, $59, $59, $59, $59, $59, $59, $59, $59, $55

; 58 bytes
shape_1x2:                  ; blue
    .byte       5           ; 5 pixels wide
    .byte       10          ; 10 pixels high
    .byte       5*5         ; offset
    ; even - 25 bytes
    .byte       $55, $65, $65, $65, $55
    .byte       $55, $66, $22, $66, $55
    .byte       $55, $66, $22, $66, $55
    .byte       $55, $66, $22, $66, $55
    .byte       $55, $56, $56, $56, $55
    ; odd - 30 bytes
    .byte       $55, $55, $55, $55, $55
    .byte       $55, $66, $26, $66, $55
    .byte       $55, $66, $22, $66, $55
    .byte       $55, $66, $22, $66, $55
    .byte       $55, $66, $62, $66, $55
    .byte       $55, $55, $55, $55, $55

.align 256

; 113 bytes
shape_2x2:                  ; red
    .byte       10          ; 10 pixels wide
    .byte       10          ; 10 pixels high
    .byte       10*5        ; offset (bytes)
    ; even - 50 bytes
    .byte       $55, $75, $75, $75, $75, $75, $75, $75, $75, $55
    .byte       $55, $77, $11, $11, $11, $11, $11, $11, $77, $55
    .byte       $55, $77, $11, $11, $11, $11, $11, $11, $77, $55
    .byte       $55, $77, $11, $11, $11, $11, $11, $11, $77, $55
    .byte       $55, $57, $57, $57, $57, $57, $57, $57, $57, $55
    ; odd - 60 bytes
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .byte       $55, $77, $17, $17, $17, $17, $17, $17, $77, $55
    .byte       $55, $77, $11, $11, $11, $11, $11, $11, $77, $55
    .byte       $55, $77, $11, $11, $11, $11, $11, $11, $77, $55
    .byte       $55, $77, $71, $71, $71, $71, $71, $71, $77, $55
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55

; 113 bytes
shape_player:               ; red
    .byte       10          ; 10 pixels wide
    .byte       10          ; 10 pixels high
    .byte       10*5        ; offset (bytes)
    ; even - 50 bytes
    .byte       $55, $55, $E5, $E5, $E5, $E5, $E5, $E5, $55, $55
    .byte       $55, $EE, $EE, $0E, $EE, $EE, $0E, $EE, $EE, $55
    .byte       $55, $EE, $EE, $EE, $EE, $EE, $EE, $EE, $EE, $55
    .byte       $55, $EE, $E0, $0E, $0E, $0E, $0E, $E0, $EE, $55
    .byte       $55, $55, $5E, $5E, $5E, $5E, $5E, $5E, $55, $55
    ; odd - 60 bytes
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .byte       $55, $E5, $EE, $EE, $EE, $EE, $EE, $EE, $E5, $55
    .byte       $55, $EE, $EE, $E0, $EE, $EE, $E0, $EE, $EE, $55
    .byte       $55, $EE, $0E, $EE, $EE, $EE, $EE, $0E, $EE, $55
    .byte       $55, $5E, $EE, $E0, $E0, $E0, $E0, $EE, $5E, $55
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55

.align 256

; 63 bytes
shape_2x1:                  ; purple
    .byte       10          ; 10 pixels wide
    .byte       5           ; 5 pixels high
    .byte       10*3        ; offset (bytes)
    ; even
    .byte       $55, $B5, $B5, $B5, $B5, $B5, $B5, $B5, $B5, $55
    .byte       $55, $BB, $B3, $B3, $B3, $B3, $B3, $B3, $BB, $55
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    ; odd
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .byte       $55, $BB, $3B, $3B, $3B, $3B, $3B, $3B, $BB, $55
    .byte       $55, $5B, $5B, $5B, $5B, $5B, $5B, $5B, $5B, $55

;-----------------------------------------------------------------------------

; 63 bytes
shape_2x1_selected:         ; purple
    .byte       10          ; 10 pixels wide
    .byte       5           ; 5 pixels high
    .byte       10*3        ; offset (bytes)
    ; even
    .byte       $BB, $3B, $3B, $3B, $3B, $3B, $3B, $BB, $55, $55
    .byte       $5B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $00, $55
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    ; odd
    .byte       $B5, $B5, $B5, $B5, $B5, $B5, $B5, $B5, $55, $55
    .byte       $BB, $B3, $B3, $B3, $B3, $B3, $B3, $BB, $00, $55
    .byte       $55, $50, $50, $50, $50, $50, $50, $50, $50, $55


.align 256

; 83 bytes
shape_1x3_selected:         ; green
    .byte       5           ; 5 pixels wide
    .byte       15          ; 15 pixels high
    .byte       5*8         ; offset
    ; even - 40 bytes
    .byte       $CC, $4C, $CC, $05, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $5C, $0C, $0C, $00, $55
    .byte       $55, $55, $55, $55, $55
    ; odd - 40 bytes
    .byte       $C5, $C5, $C5, $55, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $44, $CC, $00, $55
    .byte       $CC, $C4, $CC, $00, $55
    .byte       $55, $50, $50, $50, $55


; 93 bytes
shape_3x1_selected:         ; orange
    .byte       15          ; 15 pixels wide
    .byte       5           ; 5 pixels high
    .byte       15*3        ; offset (bytes)
    ; even
    .byte       $99, $89, $89, $89, $89, $89, $89, $89, $89, $89, $89, $89, $99, $05, $55
    .byte       $59, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $00, $55
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    ; odd
    .byte       $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $95, $55, $55
    .byte       $99, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $99, $00, $55
    .byte       $55, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $55

; 58 bytes
shape_1x2_selected:         ; blue
    .byte       5           ; 5 pixels wide
    .byte       10          ; 10 pixels high
    .byte       5*5         ; offset
    ; even - 25 bytes
    .byte       $66, $26, $66, $05, $55
    .byte       $66, $22, $66, $00, $55
    .byte       $66, $22, $66, $00, $55
    .byte       $66, $62, $66, $00, $55
    .byte       $55, $50, $50, $50, $55
    ; odd - 30 bytes
    .byte       $65, $65, $65, $55, $55
    .byte       $66, $22, $66, $00, $55
    .byte       $66, $22, $66, $00, $55
    .byte       $66, $22, $66, $00, $55
    .byte       $56, $06, $06, $00, $55
    .byte       $55, $55, $55, $55, $55

.align 256

; 113 bytes
shape_2x2_selected:         ; red
    .byte       10          ; 10 pixels wide
    .byte       10          ; 10 pixels high
    .byte       10*5        ; offset (bytes)
    ; even - 50 bytes
    .byte       $77, $17, $17, $17, $17, $17, $17, $77, $05, $55
    .byte       $77, $11, $11, $11, $11, $11, $11, $77, $00, $55
    .byte       $77, $11, $11, $11, $11, $11, $11, $77, $00, $55
    .byte       $77, $71, $71, $71, $71, $71, $71, $77, $00, $55
    .byte       $55, $50, $50, $50, $50, $50, $50, $50, $50, $55
    ; odd - 60 bytes
    .byte       $75, $75, $75, $75, $75, $75, $75, $75, $55, $55
    .byte       $77, $11, $11, $11, $11, $11, $11, $77, $00, $55
    .byte       $77, $11, $11, $11, $11, $11, $11, $77, $00, $55
    .byte       $77, $11, $11, $11, $11, $11, $11, $77, $00, $55
    .byte       $57, $07, $07, $07, $07, $07, $07, $07, $00, $55
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55

; 113 bytes
shape_player_selected:      ; red
    .byte       10          ; 10 pixels wide
    .byte       10          ; 10 pixels high
    .byte       10*5        ; offset (bytes)
    ; even - 50 bytes
    .byte       $E5, $EE, $EE, $EE, $EE, $EE, $EE, $E5, $55, $55
    .byte       $EE, $EE, $E0, $EE, $EE, $E0, $EE, $EE, $00, $55
    .byte       $EE, $0E, $EE, $EE, $EE, $EE, $0E, $EE, $00, $55
    .byte       $5E, $EE, $E0, $E0, $E0, $E0, $EE, $0E, $50, $55
    .byte       $55, $55, $50, $50, $50, $50, $50, $55, $55, $55
    ; odd - 60 bytes
    .byte       $55, $E5, $E5, $E5, $E5, $E5, $E5, $55, $55, $55
    .byte       $EE, $EE, $0E, $EE, $EE, $0E, $EE, $EE, $05, $55
    .byte       $EE, $EE, $EE, $EE, $EE, $EE, $EE, $EE, $00, $55
    .byte       $EE, $E0, $0E, $0E, $0E, $0E, $E0, $EE, $00, $55
    .byte       $55, $5E, $0E, $0E, $0E, $0E, $0E, $50, $55, $55
    .byte       $55, $55, $55, $55, $55, $55, $55, $55, $55, $55

;32 bytes
shapeTable:     .word       shape_player                ; 0
                .word       shape_2x1                   ; 1
                .word       shape_3x1                   ; 2
                .word       shape_1x2                   ; 3
                .word       shape_1x3                   ; 4
                .word       shape_2x2                   ; 5
                .word       0                           ; 6
                .word       0                           ; 7
                .word       shape_player_selected
                .word       shape_2x1_selected
                .word       shape_3x1_selected
                .word       shape_1x2_selected
                .word       shape_1x3_selected
                .word       shape_2x2_selected

;                       -----------------------------------
;                       shape:      0  1  2  3  4  5  x  x
;                       -----------------------------------
moveHorizontalTable:    .byte       1, 1, 1, 0, 0, 1, 0, 0
moveVerticalTable:      .byte       1, 0, 0, 1, 1, 1, 0, 0
moveBothTable:          .byte       1, 0, 0, 0, 0, 1, 0, 0

; Collision checks:
;   0 1 2
;   3 4
;   5
;                                  543210
;                                  ------
collisionMaskTable:     .byte   %00011011   ; player
                        .byte   %00000011   ; 2x1
                        .byte   %00000101   ; 3x1
                        .byte   %00001001   ; 1x2
                        .byte   %00100001   ; 1x3
                        .byte   %00011011   ; 2x2
                        .byte   0
                        .byte   0

