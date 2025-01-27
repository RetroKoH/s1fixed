; ---------------------------------------------------------------------------
; Object 35 - fireball that sits on the	floor (MZ)
; (appears when	you walk on sinking platforms)
; ---------------------------------------------------------------------------

GrassFire:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	GFire_Index(pc,d0.w),d1
		jmp		GFire_Index(pc,d1.w)
; ===========================================================================
GFire_Index:	offsetTable
		offsetTableEntry.w GFire_Main
		offsetTableEntry.w loc_B238
		offsetTableEntry.w GFire_Move

gfire_origX = objoff_2A
; ===========================================================================

GFire_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Fire,obMap(a0)
		move.w	#make_art_tile(ArtTile_Fireball,0,0),obGfx(a0)
		move.w	obX(a0),gfire_origX(a0)
		move.b	#4,obRender(a0)
		move.w	#priority1,obPriority(a0)		; RetroKoH/Devon S3K+ Priority Manager
		move.b	#(colHarmful|colSz_8x8),obColType(a0)

		bset	#shPropFlame,obShieldProp(a0)	; Negated by Flame Shield

		move.b	#8,obActWid(a0)
		move.w	#sfx_Burning,d0
		jsr		(PlaySound_Special).w	 		; play burning sound
		tst.b	obSubtype(a0)
		beq.s	loc_B238
		addq.b	#2,obRoutine(a0)
		bra.w	GFire_Move
; ===========================================================================

loc_B238:	; Routine 2
		movea.l	objoff_30(a0),a1
		move.w	obX(a0),d1
		sub.w	gfire_origX(a0),d1
		addi.w	#$C,d1
		move.w	d1,d0
		lsr.w	#1,d0
		move.b	(a1,d0.w),d0
		neg.w	d0
		add.w	objoff_2C(a0),d0
		move.w	d0,d2
		add.w	objoff_3C(a0),d0
		move.w	d0,obY(a0)
		cmpi.w	#$84,d1
		bhs.s	loc_B2B0
		addi.l	#$10000,obX(a0)
		cmpi.w	#$80,d1
		bhs.s	loc_B2B0
		move.l	obX(a0),d0
		addi.l	#$80000,d0
		andi.l	#$FFFFF,d0
		bne.s	loc_B2B0
		bsr.w	FindNextFreeObj
		bne.s	loc_B2B0
		_move.b	#id_GrassFire,obID(a1)
		move.w	obX(a0),obX(a1)
		move.w	d2,objoff_2C(a1)
		move.w	objoff_3C(a0),objoff_3C(a1)
		move.b	#1,obSubtype(a1)
		movea.l	objoff_38(a0),a2
		bsr.w	sub_B09C

loc_B2B0:
		bra.s	GFire_Animate
; ===========================================================================

GFire_Move:	; Routine 4
		move.w	objoff_2C(a0),d0
		add.w	objoff_3C(a0),d0
		move.w	d0,obY(a0)

GFire_Animate:
		lea		Ani_GFire(pc),a1
		bsr.w	AnimateSprite
		jmp		(DisplayAndCollision).l
