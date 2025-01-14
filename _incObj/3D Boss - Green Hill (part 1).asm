; ---------------------------------------------------------------------------
; Object 3D - Eggman (GHZ)
; ---------------------------------------------------------------------------

BossGreenHill:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	BGHZ_Index(pc,d0.w),d1
		jmp		BGHZ_Index(pc,d1.w)
; ===========================================================================
BGHZ_Index:		offsetTable
		offsetTableEntry.w BGHZ_Main
		offsetTableEntry.w BGHZ_ShipMain
		offsetTableEntry.w BGHZ_FaceMain
		offsetTableEntry.w BGHZ_FlameMain

BGHZ_ObjData:
		dc.b 2,	0		; routine counter, animation
		dc.b 4,	1
		dc.b 6,	7
; ===========================================================================

BGHZ_Main:	; Routine 0
		lea		(BGHZ_ObjData).l,a2
		movea.l	a0,a1
		moveq	#2,d1
		bra.s	BGHZ_LoadBoss
; ===========================================================================

BGHZ_Loop:
		jsr		(FindNextFreeObj).l
		bne.s	loc_17772

BGHZ_LoadBoss:
		move.b	(a2)+,obRoutine(a1)
		_move.b	#id_BossGreenHill,obID(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	#Map_Eggman,obMap(a1)
		move.w	#make_art_tile(ArtTile_Eggman,0,0),obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$20,obActWid(a1)
		move.w	#priority3,obPriority(a1)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	(a2)+,obAnim(a1)
		move.l	a0,objoff_34(a1)
		dbf		d1,BGHZ_Loop	; repeat sequence 2 more times

loc_17772:
		move.w	obX(a0),objoff_30(a0)
		move.w	obY(a0),objoff_38(a0)
		move.b	#(colEnemy|colSz_24x24),obColType(a0)
		move.b	#8,obColProp(a0) ; set number of hits to 8

BGHZ_ShipMain:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	BGHZ_ShipIndex(pc,d0.w),d1
		jsr		BGHZ_ShipIndex(pc,d1.w)
		lea		Ani_Eggman(pc),a1
		jsr		(AnimateSprite).w
		move.b	obStatus(a0),d0
		andi.b	#(maskFlipX+maskFlipY),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp		(DisplayAndCollision).l	; S3K TouchResponse
; ===========================================================================
BGHZ_ShipIndex:		offsetTable
		offsetTableEntry.w BGHZ_ShipStart
		offsetTableEntry.w BGHZ_MakeBall
		offsetTableEntry.w BGHZ_ShipMove
		offsetTableEntry.w loc_17954
		offsetTableEntry.w loc_1797A
		offsetTableEntry.w loc_179AC
		offsetTableEntry.w loc_179F6
; ===========================================================================

BGHZ_ShipStart:
		move.w	#$100,obVelY(a0) ; move ship down
		bsr.w	BossMove
		cmpi.w	#boss_ghz_y+$38,objoff_38(a0)
		bne.s	loc_177E6
		clr.w	obVelY(a0)	; stop ship
		addq.b	#2,ob2ndRout(a0) ; goto next routine

loc_177E6:
		move.b	objoff_3F(a0),d0
		jsr		(CalcSine).w
		asr.w	#6,d0
		add.w	objoff_38(a0),d0
		move.w	d0,obY(a0)
		move.w	objoff_30(a0),obX(a0)
		addq.b	#2,objoff_3F(a0)
		cmpi.b	#8,ob2ndRout(a0)
		bhs.s	locret_1784A
		tst.b	obStatus(a0)
		bmi.s	loc_1784C			; if bit 7 is set, branch
		tst.b	obColType(a0)
		bne.s	locret_1784A
		tst.b	objoff_3E(a0)
		bne.s	BGHZ_ShipFlash
		move.b	#$20,objoff_3E(a0)	; set number of	times for ship to flash
		move.w	#sfx_HitBoss,d0
		jsr		(PlaySound_Special).w	; play boss damage sound

BGHZ_ShipFlash:
		lea		(v_palette+$22).w,a1 ; load 2nd palette, 2nd entry
		moveq	#0,d0		; move 0 (black) to d0
		tst.w	(a1)
		bne.s	loc_1783C
		move.w	#cWhite,d0	; move 0EEE (white) to d0

loc_1783C:
		move.w	d0,(a1)		; load colour stored in	d0
		subq.b	#1,objoff_3E(a0)
		bne.s	locret_1784A
		move.b	#(colEnemy|colSz_24x24),obColType(a0)

locret_1784A:
		rts	
; ===========================================================================

loc_1784C:
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#8,ob2ndRout(a0)
		move.w	#$B3,objoff_3C(a0)
		rts	
