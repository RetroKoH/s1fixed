; ---------------------------------------------------------------------------
; Animation script - ring
; (Animation is actually for the sparkle, not the ring itself)
; RetroKoH 8-Frame Rings Change
; DeltaW/Malachi Optimized Spinning Rings
; ---------------------------------------------------------------------------
Ani_Ring:	dc.w .ring-Ani_Ring
.ring:		dc.b 5,	1, 2, 3, 4, afRoutine
		even