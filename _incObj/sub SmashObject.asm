; ---------------------------------------------------------------------------
; Subroutine to	smash a	block (GHZ walls and MZ	blocks)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SmashObject:
		moveq	#0,d0
		move.b	obFrame(a0),d0
		add.w	d0,d0
		movea.l	obMap(a0),a3
		adda.w	(a3,d0.w),a3
	; S2 BuildSprites
		move.w	(a3)+,d1		; amount of pieces the frame consists of
		subq.w	#1,d1
	; S2 BuildSprites End
		bset	#5,obRender(a0)
		_move.b	obID(a0),d4
		move.b	obRender(a0),d5
		movea.l	a0,a1
		bra.s	.loadfrag
; ===========================================================================

.loop:
		bsr.w	FindFreeObj
		bne.s	.playsnd
		addq.w	#8,a3			; S2 BuildSprites Change: 5 > 8

.loadfrag:
		move.b	#4,obRoutine(a1)
		_move.b	d4,obID(a1)
		move.l	a3,obMap(a1)
		move.b	d5,obRender(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	obGfx(a0),obGfx(a1)
		move.w	obPriority(a0),obPriority(a1)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	obActWid(a0),obActWid(a1)
		move.w	(a4)+,obVelX(a1)
		move.w	(a4)+,obVelY(a1)
		cmpa.l	a0,a1
		bhs.s	.loc_D268
		move.l	a0,-(sp)
		movea.l	a1,a0
		bsr.w	SpeedToPos
		add.w	d2,obVelY(a0)
		movea.l	(sp)+,a0
		bsr.w	DisplaySprite1

.loc_D268:
		dbf		d1,.loop

.playsnd:
		move.w	#sfx_WallSmash,d0
		jmp		(PlaySound_Special).w ; play smashing sound

; End of function SmashObject