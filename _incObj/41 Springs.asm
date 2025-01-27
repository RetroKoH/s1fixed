; ---------------------------------------------------------------------------
; Object 41 - springs
; ---------------------------------------------------------------------------

Springs:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Spring_Index(pc,d0.w),d1
		jsr		Spring_Index(pc,d1.w)
		offscreen.w	DeleteObject
		bra.w	DisplaySprite		; Clownacy DisplaySprite Fix	
; ===========================================================================
Spring_Index:	offsetTable
		offsetTableEntry.w Spring_Main
		offsetTableEntry.w Spring_Up
		offsetTableEntry.w Spring_AniUp
		offsetTableEntry.w Spring_ResetUp
		offsetTableEntry.w Spring_LR
		offsetTableEntry.w Spring_AniLR
		offsetTableEntry.w Spring_ResetLR
		offsetTableEntry.w Spring_Dwn
		offsetTableEntry.w Spring_AniDwn
		offsetTableEntry.w Spring_ResetDwn

spring_pow = objoff_30			; power of current spring

Spring_Powers:
		dc.w -$1000		; power	of red spring
		dc.w -$A00		; power	of yellow spring
; ===========================================================================

Spring_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Spring,obMap(a0)
		move.w	#make_art_tile(ArtTile_Spring_Horizontal,0,0),obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.w	#priority4,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	obSubtype(a0),d0
		btst	#4,d0		; does the spring face left/right?
		beq.s	Spring_NotLR	; if not, branch

		move.b	#8,obRoutine(a0) ; use "Spring_LR" routine
		move.b	#1,obAnim(a0)
		move.b	#3,obFrame(a0)
		move.w	#make_art_tile(ArtTile_Spring_Vertical,0,0),obGfx(a0)
		move.b	#8,obActWid(a0)

Spring_NotLR:
		btst	#5,d0				; does the spring face downwards?
		beq.s	Spring_NotDwn		; if not, branch

		move.b	#$E,obRoutine(a0)	; use "Spring_Dwn" routine
		bset	#staFlipY,obStatus(a0)

Spring_NotDwn:
		btst	#1,d0
		beq.s	loc_DB72
		bset	#5,obGfx(a0)

loc_DB72:
		andi.w	#$F,d0
		move.w	Spring_Powers(pc,d0.w),spring_pow(a0)
		rts	
; ===========================================================================

Spring_Up:	; Routine 2
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		btst	#staSonicOnObj,obStatus(a0)	; removed obSolid
		bne.s	Spring_BounceUp				; if Sonic is on top of the spring, branch
		rts	
; ===========================================================================

Spring_BounceUp:
		addq.b	#2,obRoutine(a0)
		addq.w	#8,obY(a1)
		move.w	spring_pow(a0),obVelY(a1)	; move Sonic upwards
		bset	#staAir,obStatus(a1)
		bclr	#staOnObj,obStatus(a1)
		clr.b	obJumping(a1)
		; Clear the spin flag?

	if SpinDashEnabled=1
		clr.b	obSpinDashFlag(a1)			; clear spin dash flag
	endif

		move.b	#aniID_Spring,obAnim(a1)	; use "bouncing" animation
		move.b	#2,obRoutine(a1)
		bclr	#staSonicOnObj,obStatus(a0)	; removed obSolid
		move.w	#sfx_Spring,d0
		jsr		(PlaySound_Special).w		; play spring sound

Spring_AniUp:	; Routine 4
		lea		Ani_Spring(pc),a1
		jmp		(AnimateSprite).w
; ===========================================================================

Spring_ResetUp:	; Routine 6
		move.b	#1,obPrevAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_Up" routine
		rts	
; ===========================================================================

Spring_LR:	; Routine 8
		move.w	#$13,d1
		move.w	#$E,d2
		move.w	#$F,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,obRoutine(a0)
		bne.s	loc_DC0C
		move.b	#8,obRoutine(a0)

loc_DC0C:
		btst	#staSonicPush,obStatus(a0)
		bne.s	Spring_BounceLR
		rts	
; ===========================================================================

Spring_BounceLR:
		addq.b	#2,obRoutine(a0)
		move.w	spring_pow(a0),obVelX(a1)	; move Sonic to the left
		addq.w	#8,obX(a1)
		bset	#staFacing,obStatus(a1)		; set Sonic facing to the left: RetroKoH Spring Direction Fix
		btst	#staFlipX,obStatus(a0)		; is object flipped?
		bne.s	Spring_Flipped				; if yes, branch
		bclr	#staFacing,obStatus(a1)		; set Sonic facing to the right: RetroKoH Spring Direction Fix
		subi.w	#$10,obX(a1)
		neg.w	obVelX(a1)					; move Sonic to	the right

Spring_Flipped:
		move.b	#$F,obLRLock(a1)
		move.w	obVelX(a1),obInertia(a1)
		;bchg	#staFacing,obStatus(a1)		; Removed: RetroKoH Spring Direction Fix
		btst	#staSpin,obStatus(a1)
		bne.s	loc_DC56
		move.b	#aniID_Walk,obAnim(a1)		; use walking animation

loc_DC56:
		bclr	#staSonicPush,obStatus(a0)
		bclr	#staPush,obStatus(a1)

	if SpinDashEnabled=1
		clr.b	(v_cameralag).w 	; clear camera lag
	endif

		move.w	#sfx_Spring,d0
		jsr		(PlaySound_Special).w	; play spring sound

Spring_AniLR:	; Routine $A
		lea		Ani_Spring(pc),a1
		jmp		(AnimateSprite).w
; ===========================================================================

Spring_ResetLR:	; Routine $C
		move.b	#2,obPrevAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_LR" routine
		rts	
; ===========================================================================

Spring_Dwn:	; Routine $E
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,obRoutine(a0)
		bne.s	loc_DCA4
		move.b	#$E,obRoutine(a0)

loc_DCA4:
		btst	#staSonicOnObj,obStatus(a0)	; removed obSolid
		bne.s	locret_DCAE
		tst.w	d4
		bmi.s	Spring_BounceDwn

locret_DCAE:
		rts	
; ===========================================================================

Spring_BounceDwn:
		addq.b	#2,obRoutine(a0)
		subq.w	#8,obY(a1)
		move.w	spring_pow(a0),obVelY(a1)
		neg.w	obVelY(a1)					; move Sonic downwards
		bset	#staAir,obStatus(a1)
		bclr	#staOnObj,obStatus(a1)
		move.b	#2,obRoutine(a1)
		bclr	#staSonicOnObj,obStatus(a0)	; removed obSolid
		move.w	#sfx_Spring,d0
		jsr		(PlaySound_Special).w		; play spring sound

Spring_AniDwn:	; Routine $10
		lea		Ani_Spring(pc),a1
		jmp		(AnimateSprite).w
; ===========================================================================

Spring_ResetDwn:
		; Routine $12
		move.b	#1,obPrevAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_Dwn" routine
		rts	
