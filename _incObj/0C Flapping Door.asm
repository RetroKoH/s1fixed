; ---------------------------------------------------------------------------
; Object 0C - flapping door (LZ)
; ---------------------------------------------------------------------------

flap_wait = objoff_30		; time until change
flap_time = objoff_32		; time between opening/closing

FlapDoor:
	; LavaGaming Object Routine Optimization
		tst.b	obRoutine(a0)
		bne.s	Flap_OpenClose
	; Object Routine Optimization End

Flap_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Flap,obMap(a0)
		move.w	#make_art_tile(ArtTile_LZ_Flapping_Door,2,0),obGfx(a0)
		move.w	#priority0,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		ori.b	#4,obRender(a0)
		move.b	#$28,obActWid(a0)
		moveq	#$F,d0
		and.b	obSubtype(a0),d0			; get object type (clamp at 0-F)
		add.w	d0,d0						; multiply by 60 (1 second)
		add.w	d0,d0						; Optimization from S1 in S.C.E.
		move.w	d0,d1
		lsl.w	#4,d0
		sub.w	d1,d0
		move.w	d0,flap_time(a0)			; set flap delay time

Flap_OpenClose:	; Routine 2
		subq.w	#1,flap_wait(a0)			; decrement time delay
		bpl.s	.wait						; if time remains, branch
		move.w	flap_time(a0),flap_wait(a0) ; reset time delay
		bchg	#0,obAnim(a0)				; open/close door
		tst.b	obRender(a0)
		bpl.s	.nosound
		move.w	#sfx_Door,d0
		jsr		(PlaySound_Special).w		; play door sound

.wait:
.nosound:
		lea		Ani_Flap(pc),a1
		jsr		(AnimateSprite).w
		clr.b	(f_wtunnelallow).w			; enable wind tunnel
		tst.b	obFrame(a0)					; is the door open?
		bne.w	RememberState				; if yes, branch
		move.w	(v_player+obX).w,d0
		cmp.w	obX(a0),d0					; has Sonic passed through the door?
		bhs.w	RememberState				; if yes, branch
		move.b	#1,(f_wtunnelallow).w		; disable wind tunnel
		move.w	#$13,d1
		move.w	#$20,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject					; make the door	solid
		bra.w	RememberState