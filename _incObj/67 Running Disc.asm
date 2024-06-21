; ---------------------------------------------------------------------------
; Object 67 - disc that	you run	around (SBZ)
; ---------------------------------------------------------------------------

RunningDisc:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Disc_Index(pc,d0.w),d1
		jmp	Disc_Index(pc,d1.w)
; ===========================================================================
Disc_Index:	dc.w Disc_Main-Disc_Index
		dc.w Disc_Action-Disc_Index

disc_origX = objoff_32		; original x-axis position
disc_origY = objoff_30		; original y-axis position
disc_spot_distance = objoff_34
disc_radius = objoff_38
disc_sonic_attached = objoff_3A
; ===========================================================================

Disc_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Disc,obMap(a0)
		move.w	#make_art_tile(ArtTile_SBZ_Disc,2,1),obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	#$200,obPriority(a0)	; RetroKoH S2 Priority Manager
		move.b	#8,obActWid(a0)
		move.w	obX(a0),disc_origX(a0)
		move.w	obY(a0),disc_origY(a0)
		move.b	#$18,disc_spot_distance(a0)
		move.b	#$48,disc_radius(a0)
		move.b	obSubtype(a0),d1 ; get object type
		andi.b	#$F,d1		; read only the	2nd digit
		beq.s	.typeis0	; branch if 0
		move.b	#$10,disc_spot_distance(a0)
		move.b	#$38,disc_radius(a0)

.typeis0:
		move.b	obSubtype(a0),d1 ; get object type
		andi.b	#$F0,d1		; read only the	1st digit
		ext.w	d1
		asl.w	#3,d1
		move.w	d1,objoff_36(a0)
		move.b	obStatus(a0),d0
		ror.b	#2,d0
		andi.b	#$C0,d0
		move.b	d0,obAngle(a0)

Disc_Action:	; Routine 2
		bsr.w	Disc_MoveSonic
		bsr.w	Disc_MoveSpot
		bra.w	Disc_ChkDel
; ===========================================================================

Disc_MoveSonic:
		moveq	#0,d2
		move.b	disc_radius(a0),d2
		move.w	d2,d3
		add.w	d3,d3
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	disc_origX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bhs.s	.detach
		move.w	obY(a1),d1
		sub.w	disc_origY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bhs.s	.detach
		btst	#1,obStatus(a1)
		beq.s	.attach
		clr.b	disc_sonic_attached(a0)
		rts	
; ===========================================================================
; loc_155A8:
.detach:
		tst.b	disc_sonic_attached(a0)
		beq.s	.return
		clr.b	obOnWheel(a1)
		clr.b	disc_sonic_attached(a0)
; locret_155B6:
.return:
		rts	
; ===========================================================================
; loc_155B8:
.attach:
		tst.b	disc_sonic_attached(a0)
		bne.s	loc_155E2
		move.b	#1,disc_sonic_attached(a0)
		btst	#2,obStatus(a1)
		bne.s	loc_155D0
		move.b	#aniID_Walk,obAnim(a1)

loc_155D0:
		bclr	#5,obStatus(a1)
		move.b	#aniID_Run,obPrevAni(a1) ; restart Sonic's animation
		move.b	#1,obOnWheel(a1)

loc_155E2:
		move.w	obInertia(a1),d0
		tst.w	objoff_36(a0)
		bpl.s	loc_15608
		cmpi.w	#-$400,d0
		ble.s	loc_155FA
		move.w	#-$400,obInertia(a1)
		rts	
; ===========================================================================

loc_155FA:
		cmpi.w	#-$F00,d0
		bge.s	locret_15606
		move.w	#-$F00,obInertia(a1)

locret_15606:
		rts	
; ===========================================================================

loc_15608:
		cmpi.w	#$400,d0
		bge.s	loc_15616
		move.w	#$400,obInertia(a1)
		rts	
; ===========================================================================

loc_15616:
		cmpi.w	#$F00,d0
		ble.s	locret_15622
		move.w	#$F00,obInertia(a1)

locret_15622:
		rts	
; ===========================================================================

Disc_MoveSpot:
		move.w	objoff_36(a0),d0
		add.w	d0,obAngle(a0)
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		move.w	disc_origY(a0),d2
		move.w	disc_origX(a0),d3
		moveq	#0,d4
		move.b	disc_spot_distance(a0),d4
		lsl.w	#8,d4
		move.l	d4,d5
		muls.w	d0,d4
		swap	d4
		muls.w	d1,d5
		swap	d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,obY(a0)
		move.w	d5,obX(a0)
		rts	
; ===========================================================================

Disc_ChkDel:
		out_of_range.s	.delete,disc_origX(a0)
		jmp	(DisplaySprite).l

.delete:
		jmp	(DeleteObject).l
