; ---------------------------------------------------------------------------
; Object 42 - Newtron enemy (GHZ)
; ---------------------------------------------------------------------------

Newtron:
	; LavaGaming Object Routine Optimization
		move.b	obRoutine(a0),d0
		cmpi.b	#2,d0
		beq.s	Newt_Action

		tst.b	d0
		bne.w	DeleteObject
	; Object Routine Optimization End

Newt_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Newt,obMap(a0)
		move.w	#make_art_tile(ArtTile_Newtron,0,0),obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	#priority4,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	#$14,obActWid(a0)
		move.b	#$10,obHeight(a0)
		move.b	#8,obWidth(a0)

Newt_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	.index(pc,d0.w),d1
		jsr		.index(pc,d1.w)
		lea		Ani_Newt(pc),a1
		jsr		(AnimateSprite).w
		bra.w	RememberState
; ===========================================================================
.index:
		dc.w .chkdistance-.index
		dc.w .type00-.index
		dc.w .matchfloor-.index
		dc.w .speed-.index
		dc.w .type01-.index
; ===========================================================================

.chkdistance:
		bset	#staFlipX,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bcc.s	.sonicisright
		neg.w	d0
		bclr	#staFlipX,obStatus(a0)

.sonicisright:
		cmpi.w	#$80,d0		; is Sonic within $80 pixels of	the newtron?
		bhs.s	.outofrange	; if not, branch
		addq.b	#2,ob2ndRout(a0) ; goto .type00 next
		move.b	#1,obAnim(a0)
		tst.b	obSubtype(a0)	; check	object type
		beq.s	.istype00	; if type is 00, branch

		move.w	#make_art_tile(ArtTile_Newtron,1,0),obGfx(a0)
		move.b	#8,ob2ndRout(a0) ; goto .type01 next
		move.b	#4,obAnim(a0)	; use different	animation

.outofrange:
.istype00:
		rts	
; ===========================================================================

.type00:
		cmpi.b	#4,obFrame(a0)	; has "appearing" animation finished?
		bhs.s	.fall		; is yes, branch
		bset	#staFlipX,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bcc.s	.sonicisright2
		bclr	#staFlipX,obStatus(a0)

.sonicisright2:
		rts	
; ===========================================================================

.fall:
		cmpi.b	#1,obFrame(a0)
		bne.s	.loc_DE42
		move.b	#(colEnemy|colSz_20x16),obColType(a0)

.loc_DE42:
		bsr.w	ObjectFall_YOnly
		jsr		(ObjFloorDist).l
		tst.w	d1				; has newtron hit the floor?
		bpl.s	.keepfalling	; if not, branch

		add.w	d1,obY(a0)
		clr.w	obVelY(a0)	; stop newtron falling
		addq.b	#2,ob2ndRout(a0)
		move.b	#2,obAnim(a0)
		btst	#5,obGfx(a0)
		beq.s	.pppppppp
		addq.b	#1,obAnim(a0)

.pppppppp:
		move.b	#(colEnemy|colSz_20x8),obColType(a0)
		move.w	#$200,obVelX(a0) ; move newtron horizontally
		btst	#staFlipX,obStatus(a0)
		bne.s	.keepfalling
		neg.w	obVelX(a0)

.keepfalling:
		rts	
; ===========================================================================

.matchfloor:
		bsr.w	SpeedToPos_XOnly
		jsr		(ObjFloorDist).l
		cmpi.w	#-8,d1
		blt.s	.nextroutine
		cmpi.w	#$C,d1
		bge.s	.nextroutine
		add.w	d1,obY(a0)	; match	newtron's position with floor
		rts	
; ===========================================================================

.nextroutine:
		addq.b	#2,ob2ndRout(a0) ; goto .speed next
		rts	
; ===========================================================================

.speed:
		bra.w	SpeedToPos_XOnly
; ===========================================================================

.type01:
		cmpi.b	#1,obFrame(a0)
		bne.s	.firemissile
		move.b	#(colEnemy|colSz_20x16),obColType(a0)

.firemissile:
		cmpi.b	#2,obFrame(a0)
		bne.s	.fail
		tst.b	objoff_32(a0)
		bne.s	.fail
		move.b	#1,objoff_32(a0)
		bsr.w	FindFreeObj
		bne.s	.fail
		_move.b	#id_Missile,obID(a1) ; load missile object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		subq.w	#8,obY(a1)
		move.w	#$200,obVelX(a1)
		move.w	#$14,d0
		btst	#staFlipX,obStatus(a0)
		bne.s	.noflip
		neg.w	d0
		neg.w	obVelX(a1)

.noflip:
		add.w	d0,obX(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.b	#1,obSubtype(a1)

.fail:
		rts	
; ===========================================================================
