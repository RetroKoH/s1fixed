; ---------------------------------------------------------------------------
; Object 73 - Eggman (MZ)
; ---------------------------------------------------------------------------

BossMarble:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	BossMarble_Index(pc,d0.w),d1
		jmp		BossMarble_Index(pc,d1.w)
; ===========================================================================
BossMarble_Index:	offsetTable
		offsetTableEntry.w BossMarble_Main
		offsetTableEntry.w BossMarble_ShipMain
		offsetTableEntry.w BossMarble_FaceMain
		offsetTableEntry.w BossMarble_FlameMain
		offsetTableEntry.w BossMarble_TubeMain

BossMarble_ObjData:
		dc.b 2,	0			; routine number, animation
		dc.w priority4		; priority
		dc.b 4,	1
		dc.w priority4
		dc.b 6,	7
		dc.w priority4
		dc.b 8,	0
		dc.w priority3
; ===========================================================================

BossMarble_Main:	; Routine 0
		move.w	obX(a0),objoff_30(a0)
		move.w	obY(a0),objoff_38(a0)
		move.b	#(colEnemy|colSz_24x24),obColType(a0)
		move.b	#8,obColProp(a0) ; set number of hits to 8
		lea		BossMarble_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.s	BossMarble_LoadBoss
; ===========================================================================

BossMarble_Loop:
		jsr		(FindNextFreeObj).l
		bne.s	BossMarble_ShipMain
		_move.b	#id_BossMarble,obID(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

BossMarble_LoadBoss:
		bclr	#staFlipX,obStatus(a0)
		clr.b	ob2ndRout(a1)
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,obAnim(a1)
		move.w	(a2)+,obPriority(a1)	; RetroKoH/Devon S3K+ Priority Manager
		move.l	#Map_Eggman,obMap(a1)
		move.w	#make_art_tile(ArtTile_Eggman,0,0),obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$20,obActWid(a1)
		move.l	a0,objoff_34(a1)
		dbf		d1,BossMarble_Loop		; repeat sequence 3 more times

BossMarble_ShipMain:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	BossMarble_ShipIndex(pc,d0.w),d1
		jsr		BossMarble_ShipIndex(pc,d1.w)
		lea		Ani_Eggman(pc),a1
		jsr		(AnimateSprite).w
		moveq	#(maskFlipX+maskFlipY),d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp		(DisplayAndCollision).l	; S3K TouchResponse
; ===========================================================================
BossMarble_ShipIndex:	offsetTable
		offsetTableEntry.w loc_18302
		offsetTableEntry.w loc_183AA
		offsetTableEntry.w loc_184F6
		offsetTableEntry.w loc_1852C
		offsetTableEntry.w loc_18582
; ===========================================================================

loc_18302:
		move.b	objoff_3F(a0),d0
		addq.b	#2,objoff_3F(a0)
		jsr		(CalcSine).w
		asr.w	#2,d0
		move.w	d0,obVelY(a0)
		move.w	#-$100,obVelX(a0)
		bsr.w	BossMove
		cmpi.w	#boss_mz_x+$110,objoff_30(a0)
		bne.s	loc_18334
		addq.b	#2,ob2ndRout(a0)
		clr.b	obSubtype(a0)
		clr.l	obVelX(a0)

loc_18334:
		jsr		(RandomNumber).w
		move.b	d0,objoff_34(a0)

loc_1833E:
		move.w	objoff_38(a0),obY(a0)
		move.w	objoff_30(a0),obX(a0)
		cmpi.b	#4,ob2ndRout(a0)
		bhs.s	locret_18390
		tst.b	obStatus(a0)
		bmi.s	loc_18392			; if bit 7 is set, branch
		tst.b	obColType(a0)
		bne.s	locret_18390
		tst.b	objoff_3E(a0)
		bne.s	BossMarble_ShipFlash
		move.b	#$28,objoff_3E(a0)
		move.w	#sfx_HitBoss,d0
		jsr		(PlaySound_Special).w	; play boss damage sound

BossMarble_ShipFlash:
		lea		(v_palette+$22).w,a1 ; load 2nd palette, 2nd entry
		moveq	#0,d0		; move 0 (black) to d0
		tst.w	(a1)
		bne.s	loc_18382
		move.w	#cWhite,d0	; move 0EEE (white) to d0

loc_18382:
		move.w	d0,(a1)
		subq.b	#1,objoff_3E(a0)
		bne.s	locret_18390
		move.b	#(colEnemy|colSz_24x24),obColType(a0)

locret_18390:
		rts	
; ===========================================================================

loc_18392:
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#4,ob2ndRout(a0)
		move.w	#$B4,objoff_3C(a0)
		clr.w	obVelX(a0)
		rts	
; ===========================================================================

loc_183AA:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		move.w	off_183C2(pc,d0.w),d0
		jsr		off_183C2(pc,d0.w)
		andi.b	#6,obSubtype(a0)
		bra.w	loc_1833E
; ===========================================================================
off_183C2:	offsetTable
		offsetTableEntry.w loc_183CA
		offsetTableEntry.w BossMarble_MakeLava2
		offsetTableEntry.w loc_183CA
		offsetTableEntry.w BossMarble_MakeLava2
; ===========================================================================

loc_183CA:
		tst.w	obVelX(a0)
		bne.s	loc_183FE
		moveq	#$40,d0
		cmpi.w	#boss_mz_y+$1C,objoff_38(a0)
		beq.s	loc_183E6
		bcs.s	loc_183DE
		neg.w	d0

loc_183DE:
		move.w	d0,obVelY(a0)
		bra.w	BossMove
; ===========================================================================

loc_183E6:
		move.w	#$200,obVelX(a0)
		move.w	#$100,obVelY(a0)
		btst	#staFlipX,obStatus(a0)
		bne.s	loc_183FE
		neg.w	obVelX(a0)

loc_183FE:
		cmpi.b	#$18,objoff_3E(a0)
		bhs.s	BossMarble_MakeLava
		bsr.w	BossMove
		subq.w	#4,obVelY(a0)

BossMarble_MakeLava:
		subq.b	#1,objoff_34(a0)
		bcc.s	loc_1845C
		jsr		(FindFreeObj).l
		bne.s	loc_1844A
		_move.b	#id_LavaBall,obID(a1) ; load lava ball object
		move.w	#boss_mz_y+$D8,obY(a1)	; set Y	position
		jsr		(RandomNumber).w
		andi.l	#$FFFF,d0
		divu.w	#$50,d0
		swap	d0
		addi.w	#boss_mz_x+$78,d0
		move.w	d0,obX(a1)
		lsr.b	#7,d1
		move.w	#$FF,obSubtype(a1)

loc_1844A:
		jsr		(RandomNumber).w
		andi.b	#$1F,d0
		addi.b	#$40,d0
		move.b	d0,objoff_34(a0)

loc_1845C:
		btst	#staFlipX,obStatus(a0)
		beq.s	loc_18474
		cmpi.w	#boss_mz_x+$110,objoff_30(a0)
		blt.s	locret_1849C
		move.w	#boss_mz_x+$110,objoff_30(a0)
		bra.s	loc_18482
; ===========================================================================

loc_18474:
		cmpi.w	#boss_mz_x+$30,objoff_30(a0)
		bgt.s	locret_1849C
		move.w	#boss_mz_x+$30,objoff_30(a0)

loc_18482:
		clr.w	obVelX(a0)
		move.w	#-$180,obVelY(a0)
		cmpi.w	#boss_mz_y+$1C,objoff_38(a0)
		bhs.s	loc_18498
		neg.w	obVelY(a0)

loc_18498:
		addq.b	#2,obSubtype(a0)

locret_1849C:
		rts	
; ===========================================================================

BossMarble_MakeLava2:
		bsr.w	BossMove
		move.w	objoff_38(a0),d0
		subi.w	#boss_mz_y+$1C,d0
		bgt.s	locret_184F4
		move.w	#boss_mz_y+$1C,d0
		tst.w	obVelY(a0)
		beq.s	loc_184EA
		clr.w	obVelY(a0)
		move.w	#$50,objoff_3C(a0)
		bchg	#staFlipX,obStatus(a0)
		jsr		(FindFreeObj).l
		bne.s	loc_184EA
		move.w	objoff_30(a0),obX(a1)
		move.w	objoff_38(a0),obY(a1)
		addi.w	#$18,obY(a1)
		move.b	#id_BossFire,obID(a1)	; load lava ball object
		move.b	#1,obSubtype(a1)

loc_184EA:
		subq.w	#1,objoff_3C(a0)
		bne.s	locret_184F4
		addq.b	#2,obSubtype(a0)

locret_184F4:
		rts	
; ===========================================================================

loc_184F6:
		subq.w	#1,objoff_3C(a0)
		bmi.s	loc_18500
		bra.w	BossDefeated
; ===========================================================================

loc_18500:
		bset	#staFlipX,obStatus(a0)
		bclr	#7,obStatus(a0)
		clr.w	obVelX(a0)
		addq.b	#2,ob2ndRout(a0)
		move.w	#-$26,objoff_3C(a0)
		tst.b	(v_bossstatus).w
		bne.s	locret_1852A
		move.b	#1,(v_bossstatus).w
		clr.w	obVelY(a0)

locret_1852A:
		rts	
; ===========================================================================

loc_1852C:
		addq.w	#1,objoff_3C(a0)
		beq.s	loc_18544
		bpl.s	loc_1854E
		cmpi.w	#boss_mz_y+$60,objoff_38(a0)
		bhs.s	loc_18544
		addi.w	#$18,obVelY(a0)
		bra.s	loc_1857A
; ===========================================================================

loc_18544:
		clr.w	obVelY(a0)
		clr.w	objoff_3C(a0)
		bra.s	loc_1857A
; ===========================================================================

loc_1854E:
		cmpi.w	#$30,objoff_3C(a0)
		blo.s	loc_18566
		beq.s	loc_1856C
		cmpi.w	#$38,objoff_3C(a0)
		blo.s	loc_1857A
		addq.b	#2,ob2ndRout(a0)
		bra.s	loc_1857A
; ===========================================================================

loc_18566:
		subq.w	#8,obVelY(a0)
		bra.s	loc_1857A
; ===========================================================================

loc_1856C:
		clr.w	obVelY(a0)
		move.w	#bgm_MZ,d0
		jsr		(PlaySound).w			; play MZ music
		move.b	d0,(v_lastbgmplayed).w	; store last played music

loc_1857A:
		bsr.w	BossMove
		bra.w	loc_1833E
; ===========================================================================

loc_18582:
		move.w	#$500,obVelX(a0)
		move.w	#-$40,obVelY(a0)
		cmpi.w	#boss_mz_end,(v_limitright2).w
		bhs.s	loc_1859C
		addq.w	#2,(v_limitright2).w
		bra.s	loc_185A2
; ===========================================================================

loc_1859C:
		tst.b	obRender(a0)
		bpl.s	BossMarble_ShipDel

loc_185A2:
		bsr.w	BossMove
		bra.w	loc_1833E
; ===========================================================================

BossMarble_ShipDel:
		; Objects should not queue themselves for display
		; while also being deleted.
		addq.l	#4,sp			; Clownacy DisplaySprites Fix
		jmp		(DeleteObject).l
; ===========================================================================

BossMarble_FaceMain:	; Routine 4
		moveq	#0,d0
		moveq	#1,d1
		movea.l	objoff_34(a0),a1
		move.b	ob2ndRout(a1),d0
		subq.w	#2,d0
		bne.s	loc_185D2
		btst	#1,obSubtype(a1)
		beq.s	loc_185DA
		tst.w	obVelY(a1)
		bne.s	loc_185DA
		moveq	#4,d1
		bra.s	loc_185EE
; ===========================================================================

loc_185D2:
		subq.b	#2,d0
		bmi.s	loc_185DA
		moveq	#$A,d1
		bra.s	loc_185EE
; ===========================================================================

loc_185DA:
		tst.b	obColType(a1)
		bne.s	loc_185E4
		moveq	#5,d1
		bra.s	loc_185EE
; ===========================================================================

loc_185E4:
		cmpi.b	#4,(v_player+obRoutine).w
		blo.s	loc_185EE
		moveq	#4,d1

loc_185EE:
		move.b	d1,obAnim(a0)
		subq.b	#4,d0
		bne.s	BossMarble_Display
		move.b	#6,obAnim(a0)
		tst.b	obRender(a0)
		bpl.s	BossMarble_FaceDel
		bra.s	BossMarble_Display
; ===========================================================================

BossMarble_FaceDel:
		jmp		(DeleteObject).l
; ===========================================================================

BossMarble_FlameMain:; Routine 6
		move.b	#7,obAnim(a0)
		movea.l	objoff_34(a0),a1
		cmpi.b	#8,ob2ndRout(a1)
		blt.s	loc_1862A
		move.b	#$B,obAnim(a0)
		tst.b	obRender(a0)
		bpl.s	BossMarble_FlameDel
		bra.s	BossMarble_Display
; ===========================================================================

loc_1862A:
		tst.w	obVelX(a1)
		beq.s	BossMarble_Display
		move.b	#8,obAnim(a0)
		bra.s	BossMarble_Display
; ===========================================================================

BossMarble_FlameDel:
		jmp		(DeleteObject).l
; ===========================================================================

BossMarble_Display:
		lea		Ani_Eggman(pc),a1
		jsr		(AnimateSprite).w

loc_1864A:
		movea.l	objoff_34(a0),a1
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)
		move.b	obStatus(a1),obStatus(a0)
		moveq	#(maskFlipX+maskFlipY),d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp		(DisplaySprite).l
; ===========================================================================

BossMarble_TubeMain:	; Routine 8
		movea.l	objoff_34(a0),a1
		cmpi.b	#8,ob2ndRout(a1)
		bne.s	loc_18688
		tst.b	obRender(a0)
		bpl.s	BossMarble_TubeDel

loc_18688:
		move.l	#Map_BossItems,obMap(a0)
		move.w	#make_art_tile(ArtTile_Eggman_Weapons,1,0),obGfx(a0)
		move.b	#4,obFrame(a0)
		bra.s	loc_1864A
; ===========================================================================

BossMarble_TubeDel:
		jmp	(DeleteObject).l
