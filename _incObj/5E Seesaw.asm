; ---------------------------------------------------------------------------
; Object 5E - seesaws (SLZ)
; ---------------------------------------------------------------------------

see_origX = objoff_30		; original x-axis position
see_origY = objoff_34		; original y-axis position
see_speed = objoff_38		; speed of collision
see_frame = objoff_3A		; 
see_parent = objoff_3C		; RAM address of parent object

Seesaw:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	See_Index(pc,d0.w),d1
		jsr		See_Index(pc,d1.w)
		move.w	see_origX(a0),d0
		andi.w	#$FF80,d0
		move.w	(v_screenposx).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		; Deleted first call to DeleteObject
		cmpi.w	#$280,d0
		bls.w	DisplaySprite
		move.w	obRespawnNo(a0),d0	; get address in respawn table
		beq.w	DeleteObject		; if it's zero, don't remember object
		movea.w	d0,a2				; load address into a2
		bclr	#7,(a2)				; clear respawn table entry, so object can be loaded again
		bra.w	DeleteObject		; and delete object	
; ===========================================================================
See_Index:	offsetTable
		offsetTableEntry.w See_Main
		offsetTableEntry.w See_Slope
		offsetTableEntry.w See_Slope2
		offsetTableEntry.w See_Spikeball
		offsetTableEntry.w See_MoveSpike
		offsetTableEntry.w See_SpikeFall
; ===========================================================================

See_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Seesaw,obMap(a0)
		move.w	#make_art_tile(ArtTile_SLZ_Seesaw,0,0),obGfx(a0)
		ori.b	#4,obRender(a0)
		move.w	#$200,obPriority(a0)	; RetroKoH S2 Priority Manager
		move.b	#$30,obActWid(a0)
		move.w	obX(a0),see_origX(a0)
		tst.b	obSubtype(a0)	; is object type 00 ?
		bne.s	.noball		; if not, branch

		bsr.w	FindNextFreeObj
		bne.s	.noball
		_move.b	#id_Seesaw,obID(a1) ; load spikeball object
		addq.b	#6,obRoutine(a1) ; use See_Spikeball routine
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.l	a0,see_parent(a1)

.noball:
		btst	#staFlipX,obStatus(a0)	; is seesaw flipped?
		beq.s	.noflip					; if not, branch
		move.b	#2,obFrame(a0)			; use different frame

.noflip:
		move.b	obFrame(a0),see_frame(a0)

See_Slope:	; Routine 2
		move.b	see_frame(a0),d1
		bsr.w	See_ChgFrame
		lea		(See_DataSlope).l,a2
		btst	#0,obFrame(a0)	; is seesaw flat?
		beq.s	.notflat	; if not, branch
		lea		(See_DataFlat).l,a2

.notflat:
		lea		(v_player).w,a1
		move.w	obVelY(a1),see_speed(a0)
		move.w	#$30,d1
		jmp		(SlopeObject).l	
; ===========================================================================

See_Slope2:	; Routine 4
		bsr.w	See_ChkSide
		lea		(See_DataSlope).l,a2
		btst	#0,obFrame(a0)	; is seesaw flat?
		beq.s	.notflat	; if not, branch
		lea		(See_DataFlat).l,a2

.notflat:
		move.w	#$30,d1
		jsr		(ExitPlatform).l
		move.w	#$30,d1
		move.w	obX(a0),d2
		jmp		(SlopeObject2).l
; ===========================================================================

See_ChkSide:
		moveq	#2,d1
		lea	(v_player).w,a1
		move.w	obX(a0),d0
		sub.w	obX(a1),d0	; is Sonic on the left side of the seesaw?
		bcc.s	.leftside	; if yes, branch
		neg.w	d0
		moveq	#0,d1

.leftside:
		cmpi.w	#8,d0
		bhs.s	See_ChgFrame
		moveq	#1,d1

See_ChgFrame:
		move.b	obFrame(a0),d0
		cmp.b	d1,d0		; does frame need to change?
		beq.s	.noflip		; if not, branch
		bcc.s	.loc_11772
		addq.b	#2,d0

.loc_11772:
		subq.b	#1,d0
		move.b	d0,obFrame(a0)
		move.b	d1,see_frame(a0)
		bclr	#0,obRender(a0)
		btst	#1,obFrame(a0)
		beq.s	.noflip
		bset	#0,obRender(a0)

.noflip:
		rts	
; ===========================================================================

See_Spikeball:	; Routine 6
		addq.b	#2,obRoutine(a0)
		move.l	#Map_SSawBall,obMap(a0)
		move.w	#make_art_tile(ArtTile_SLZ_Spikeball,0,0),obGfx(a0)
		ori.b	#4,obRender(a0)
		move.w	#$200,obPriority(a0)	; RetroKoH S2 Priority Manager
		move.b	#$8B,obColType(a0)
		move.b	#$C,obActWid(a0)
		move.w	obX(a0),see_origX(a0)
		addi.w	#$28,obX(a0)
		move.w	obY(a0),see_origY(a0)
		move.b	#1,obFrame(a0)
		btst	#staFlipX,obStatus(a0)	; is seesaw flipped?
		beq.s	See_MoveSpike	; if not, branch
		subi.w	#$50,obX(a0)	; move spikeball to the other side
		move.b	#2,see_frame(a0)

See_MoveSpike:	; Routine 8
		movea.l	see_parent(a0),a1
		moveq	#0,d0
		move.b	see_frame(a0),d0
		sub.b	see_frame(a1),d0
		beq.s	loc_1183E
		bcc.s	loc_117FC
		neg.b	d0

loc_117FC:
		move.w	#-$818,d1
		move.w	#-$114,d2
		cmpi.b	#1,d0
		beq.s	loc_11822
		move.w	#-$AF0,d1
		move.w	#-$CC,d2
		cmpi.w	#$A00,objoff_38(a1)
		blt.s	loc_11822
		move.w	#-$E00,d1
		move.w	#-$A0,d2

loc_11822:
		move.w	d1,obVelY(a0)
		move.w	d2,obVelX(a0)
		move.w	obX(a0),d0
		sub.w	see_origX(a0),d0
		bcc.s	loc_11838
		neg.w	obVelX(a0)

loc_11838:
		addq.b	#2,obRoutine(a0)
		bra.s	See_SpikeFall
; ===========================================================================

loc_1183E:
		lea	(See_Speeds).l,a2
		moveq	#0,d0
		move.b	obFrame(a1),d0
		move.w	#$28,d2
		move.w	obX(a0),d1
		sub.w	see_origX(a0),d1
		bcc.s	loc_1185C
		neg.w	d2
		addq.w	#2,d0

loc_1185C:
		add.w	d0,d0
		move.w	see_origY(a0),d1
		add.w	(a2,d0.w),d1
		move.w	d1,obY(a0)
		add.w	see_origX(a0),d2
		move.w	d2,obX(a0)
		clr.w	obY+2(a0)
		clr.w	obX+2(a0)
		rts	
; ===========================================================================

See_SpikeFall:	; Routine $A
		tst.w	obVelY(a0)	; is spikeball falling down?
		bpl.s	loc_1189A	; if yes, branch
		bsr.w	ObjectFall
		move.w	see_origY(a0),d0
		subi.w	#$2F,d0
		cmp.w	obY(a0),d0
		bgt.s	locret_11898
		bra.w	ObjectFall

locret_11898:
		rts	
; ===========================================================================

loc_1189A:
		bsr.w	ObjectFall
		movea.l	see_parent(a0),a1
		lea	(See_Speeds).l,a2
		moveq	#0,d0
		move.b	obFrame(a1),d0
		move.w	obX(a0),d1
		sub.w	see_origX(a0),d1
		bcc.s	loc_118BA
		addq.w	#2,d0

loc_118BA:
		add.w	d0,d0
		move.w	see_origY(a0),d1
		add.w	(a2,d0.w),d1
		cmp.w	obY(a0),d1
		bgt.s	locret_11938
		movea.l	see_parent(a0),a1
		moveq	#2,d1
		tst.w	obVelX(a0)
		bmi.s	See_Spring
		moveq	#0,d1

See_Spring:
		move.b	d1,objoff_3A(a1)
		move.b	d1,see_frame(a0)
		cmp.b	obFrame(a1),d1
		beq.s	loc_1192C
		bclr	#staSonicOnObj,obStatus(a1)
		beq.s	loc_1192C
		clr.b	ob2ndRout(a1)
		move.b	#2,obRoutine(a1)
		lea		(v_player).w,a2
		
	if SpinDashEnabled=1
		clr.b	obSpinDashFlag(a2)
	endif

		move.w	obVelY(a0),obVelY(a2)
		neg.w	obVelY(a2)
		bset	#staAir,obStatus(a2)
		bclr	#staOnObj,obStatus(a2)
		clr.b	obJumping(a2)
		move.b	#aniID_Spring,obAnim(a2) ; change Sonic's animation to "spring"
		move.b	#2,obRoutine(a2)
		move.w	#sfx_Spring,d0
		jsr		(PlaySound_Special).l	; play spring sound

loc_1192C:
		clr.w	obVelX(a0)
		clr.w	obVelY(a0)
		subq.b	#2,obRoutine(a0)

locret_11938:
		rts	
; ===========================================================================
See_Speeds:	dc.w -8, -$1C, -$2F, -$1C, -8

See_DataSlope:	binclude	"misc/slzssaw1.bin"
		even
See_DataFlat:	binclude	"misc/slzssaw2.bin"
		even
