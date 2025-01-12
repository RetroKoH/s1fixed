; ===========================================================================
; Subroutine that renders one line of ASCII text.
; Input:
; d2 = number of characters per line
; ===========================================================================


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

ASCText_RenderLine:
	.loop:
		moveq	#0,d0
		move.b	(a1)+,d0		; get character
		bpl.s	.isvalid		; branch if valid
		move.w	#0,(a6)			; use blank character
		dbf		d2,.loop		; repeat for number of characters
		rts	

; Soulless Sentinel Level Select ASCII Mod
	.isvalid:
		subi.w	#$21,d0		; Subtract #$21
		add.w	d3,d0		; combine char with VRAM setting
		move.w	d0,(a6)		; send to VRAM
		dbf		d2,.loop
		rts
; End of function ASCText_RenderLine