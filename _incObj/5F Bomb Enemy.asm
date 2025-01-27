; ---------------------------------------------------------------------------
; Object 5F - walking bomb enemy (SLZ, SBZ)
; ---------------------------------------------------------------------------

Bomb:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bom_Index(pc,d0.w),d1
		jmp		Bom_Index(pc,d1.w)
		; Slightly altered to prevent display-and-delete bug -- Clownacy DisplaySprite Fix
; ===========================================================================
Bom_Index:	offsetTable
		offsetTableEntry.w Bom_Main
		offsetTableEntry.w Bom_Action
		offsetTableEntry.w Bom_Display
		offsetTableEntry.w Bom_End

bom_time = objoff_30		; time of fuse
bom_origY = objoff_34		; original y-axis position
bom_parent = objoff_3C		; address of parent object
; ===========================================================================

Bom_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bomb,obMap(a0)
		move.w	#make_art_tile(ArtTile_Bomb,0,0),obGfx(a0)
		ori.b	#4,obRender(a0)
		move.w	#priority3,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	#$C,obActWid(a0)
		move.b	obSubtype(a0),d0
		beq.s	loc_11A3C
		move.b	d0,obRoutine(a0)
		jmp		Add_SpriteToCollisionResponseList	
; ===========================================================================

loc_11A3C:
		move.b	#(colHarmful|colSz_12x12),obColType(a0)
		bchg	#staFlipX,obStatus(a0)

Bom_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Bom_ActIndex(pc,d0.w),d1
		jsr		Bom_ActIndex(pc,d1.w)
		lea		Ani_Bomb(pc),a1
		jsr		(AnimateSprite).w
		bra.w	RememberState
; ===========================================================================
Bom_ActIndex:	offsetTable
		offsetTableEntry.w .walk
		offsetTableEntry.w .wait
		offsetTableEntry.w .explode
; ===========================================================================

.walk:
		bsr.w	.chksonic
		subq.w	#1,bom_time(a0)	; subtract 1 from time delay
		bpl.s	.noflip		; if time remains, branch
		addq.b	#2,ob2ndRout(a0) ; goto .wait
		move.w	#1535,bom_time(a0) ; set time delay to 25 seconds
		move.w	#$10,obVelX(a0)
		move.b	#1,obAnim(a0)	; use walking animation
		bchg	#staFlipX,obStatus(a0)
		beq.s	.noflip
		neg.w	obVelX(a0)	; change direction

.noflip:
		rts	
; ===========================================================================

.wait:
		bsr.w	.chksonic
		subq.w	#1,bom_time(a0)	; subtract 1 from time delay
		bmi.s	.stopwalking	; if time expires, branch
		bra.w	SpeedToPos_XOnly
; ===========================================================================

.stopwalking:
		subq.b	#2,ob2ndRout(a0)
		move.w	#179,bom_time(a0) ; set time delay to 3 seconds
		clr.w	obVelX(a0)	; stop walking
		clr.b	obAnim(a0)	; use waiting animation
		rts	
; ===========================================================================

.explode:
		subq.w	#1,bom_time(a0)	; subtract 1 from time delay
		bpl.s	.noexplode	; if time remains, branch
		_move.b	#id_ExplosionBomb,obID(a0) ; change bomb into an explosion
		clr.b	obRoutine(a0)

.noexplode:
		rts	
; ===========================================================================

.chksonic:
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bcc.s	.isleft
		neg.w	d0

.isleft:
		cmpi.w	#$60,d0		; is Sonic within $60 pixels?
		bhs.s	.outofrange	; if not, branch
		move.w	(v_player+obY).w,d0
		sub.w	obY(a0),d0
		bcc.s	.isabove
		neg.w	d0

.isabove:
		cmpi.w	#$60,d0
		bhs.s	.outofrange
		tst.w	(v_debuguse).w
		bne.s	.outofrange

		move.b	#4,ob2ndRout(a0)
		move.w	#143,bom_time(a0) ; set fuse time
		clr.w	obVelX(a0)
		move.b	#2,obAnim(a0)	; use activated animation
		bsr.w	FindNextFreeObj
		bne.s	.outofrange
		_move.b	#id_Bomb,obID(a1)	; load fuse object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	obY(a0),bom_origY(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.b	#4,obSubtype(a1)
		move.b	#3,obAnim(a1)
		move.w	#$10,obVelY(a1)
		btst	#staFlipY,obStatus(a0)	; is bomb upside-down?
		beq.s	.normal		; if not, branch
		neg.w	obVelY(a1)	; reverse direction for fuse

.normal:
		move.w	#143,bom_time(a1) ; set fuse time
		move.l	a0,bom_parent(a1)

.outofrange:
		rts	
; ===========================================================================

Bom_Display:	; Routine 4
		bsr.s	loc_11B70
		lea		Ani_Bomb(pc),a1
		jsr		(AnimateSprite).w
		bra.w	RememberState
; ===========================================================================

loc_11B70:
		subq.w	#1,bom_time(a0)
		bmi.s	loc_11B7C
		bra.w	SpeedToPos_YOnly
; ===========================================================================

loc_11B7C:
		clr.w	bom_time(a0)
		clr.b	obRoutine(a0)
		move.w	bom_origY(a0),obY(a0)
		moveq	#3,d1
		movea.l	a0,a1
		lea		(Bom_ShrSpeed).l,a2 ; load shrapnel speed data
		bra.s	.makeshrapnel
; ===========================================================================

.loop:
		bsr.w	FindNextFreeObj
		bne.s	.fail

.makeshrapnel:
		_move.b	#id_Bomb,obID(a1)	; load shrapnel	object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#6,obSubtype(a1)
		move.b	#4,obAnim(a1)
		move.w	(a2)+,obVelX(a1)
		move.w	(a2)+,obVelY(a1)
		move.b	#(colHarmful|colSz_4x4),obColType(a1)

		bset	#shPropReflect,obShieldProp(a1)	; Reflected by Elemental Shields

		bset	#7,obRender(a1)

.fail:
		dbf		d1,.loop	; repeat 3 more	times

		move.b	#6,obRoutine(a0)

Bom_End:	; Routine 6
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
		lea		Ani_Bomb(pc),a1
		jsr		(AnimateSprite).w
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		bra.w	DisplayAndCollision
; ===========================================================================
Bom_ShrSpeed:	dc.w -$200, -$300, -$100, -$200, $200, -$300, $100, -$200
