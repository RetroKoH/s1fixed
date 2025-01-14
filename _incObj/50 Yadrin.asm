; ---------------------------------------------------------------------------
; Object 50 - Yadrin enemy (SYZ)
; ---------------------------------------------------------------------------

yad_timedelay = objoff_30

Yadrin:
	; LavaGaming Object Routine Optimization
		tst.b	obRoutine(a0)
		bne.s	Yad_Action
	; Object Routine Optimization End

Yad_Main:	; Routine 0
		move.l	#Map_Yad,obMap(a0)
		move.w	#make_art_tile(ArtTile_Yadrin,1,0),obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	#priority4,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	#$14,obActWid(a0)
		move.b	#$11,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.b	#(colSpecial|colSz_20x16),obColType(a0)
		bsr.w	ObjectFall_YOnly
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.s	locret_F89E
		add.w	d1,obY(a0)	; match	object's position with the floor
		clr.w	obVelY(a0)
		addq.b	#2,obRoutine(a0)
		bchg	#staFlipX,obStatus(a0)

locret_F89E:
		rts	
; ===========================================================================

Yad_Action:	; Routine 2
	; LavaGaming Object Routine Optimization
		tst.b	ob2ndRout(a0)
		bne.s	Yad_FixToFloor
	; Object Routine Optimization End

Yad_Move:
		subq.w	#1,yad_timedelay(a0)	; subtract 1 from pause time
		bpl.s	Yad_Animate				; if time remains, branch
		addq.b	#2,ob2ndRout(a0)
		move.w	#-$100,obVelX(a0)		; move object
		move.b	#1,obAnim(a0)
		bchg	#staFlipX,obStatus(a0)
		bne.s	Yad_Animate
		neg.w	obVelX(a0)				; change direction

Yad_Animate:
		lea		Ani_Yad(pc),a1
		jsr		(AnimateSprite).w
		bra.w	RememberState	
; ===========================================================================

Yad_FixToFloor:
		bsr.w	SpeedToPos_XOnly
		bsr.w	ObjFloorDist
		cmpi.w	#-8,d1
		blt.s	Yad_Pause
		cmpi.w	#$C,d1
		bge.s	Yad_Pause
		add.w	d1,obY(a0)	; match	object's position to the floor
		bsr.s	Yad_ChkWall
		bne.s	Yad_Pause
	; Animate
		lea		Ani_Yad(pc),a1
		jsr		(AnimateSprite).w
		bra.w	RememberState	
; ===========================================================================

Yad_Pause:
		subq.b	#2,ob2ndRout(a0)
		move.w	#59,yad_timedelay(a0) ; set pause time to 1 second
		clr.w	obVelX(a0)
		clr.b	obAnim(a0)
	; Animate
		lea		Ani_Yad(pc),a1
		jsr		(AnimateSprite).w
		bra.w	RememberState
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to have Yadrin check for a wall
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Yad_ChkWall:
		move.w	(v_framecount).w,d0
		add.w	d7,d0
		andi.w	#3,d0
		bne.s	loc_F836
		moveq	#0,d3
		move.b	obActWid(a0),d3
		tst.w	obVelX(a0)
		bmi.s	loc_F82C
		bsr.w	ObjHitWallRight
		tst.w	d1
		bpl.s	loc_F836

loc_F828:
		moveq	#1,d0
		rts	
; ===========================================================================

loc_F82C:
		not.w	d3
		bsr.w	ObjHitWallLeft
		tst.w	d1
		bmi.s	loc_F828

loc_F836:
		moveq	#0,d0
		rts	
; End of function Yad_ChkWall
; ===========================================================================
