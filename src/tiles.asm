;-----------------------------------------------------------------------------
; Paul Wasson - 2024
;-----------------------------------------------------------------------------
; Game tiles
;
; Low res tiles 5 pixels across by 6 pixels high

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
.byte   $20, $20, $A0, $A0, $A0
.byte   $00

; 09 - bottom  (2 bottom rows blank)
.byte   $55, $55, $55, $55, $55
.byte 	$FF, $FF, $FF, $FF, $FF
.byte   $A0, $A0, $A0, $A0, $A0
.byte   $00

; 0A - bottom right (2 bottom rows blank, right column blank)
.byte   $55, $55, $FF, $FF, $00
.byte 	$FF, $FF, $FF, $FF, $00
.byte   $A0, $A0, $20, $20, $A0
.byte   $00

; 0B - text right
.byte   $20, $20, $A0, $A0, $A0
.byte 	$20, $20, $A0, $A0, $A0
.byte   $20, $20, $20, $20, $20
.byte   $00

; 0C - text
.byte   $A0, $A0, $A0, $A0, $A0
.byte 	$A0, $A0, $A0, $A0, $A0
.byte   $20, $20, $20, $20, $20
.byte   $00

; 0D - text left
.byte   $A0, $A0, $20, $20, $A0
.byte 	$A0, $A0, $20, $20, $A0
.byte   $20, $20, $20, $20, $A0
.byte   $00
