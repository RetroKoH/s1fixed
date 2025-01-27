; ---------------------------------------------------------------------------
; Object 3C - smashable	wall (GHZ, SLZ)
; ---------------------------------------------------------------------------

SmashWall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		jsr		Smash_Index(pc,d0.w)
		bra.w	RememberState
; ===========================================================================
Smash_Index:
		bra.s	Smash_Main
		bra.s	Smash_Solid
		bra.w	Smash_FragMove
; ===========================================================================

Smash_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Smash,obMap(a0)
		move.w	#make_art_tile(ArtTile_GHZ_Smashable_Wall,2,0),obGfx(a0)
		cmpi.b	#id_GHZ,(v_zone).w
		beq.s	.isGHZ
		move.w	#make_art_tile(ArtTile_SLZ_Smashable_Wall,2,0),obGfx(a0)

.isGHZ:
		move.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.w	#priority4,obPriority(a0)			; RetroKoH/Devon S3K+ Priority Manager
		move.b	obSubtype(a0),obFrame(a0)

Smash_Solid:	; Routine 2
		move.w	(v_player+obVelX).w,d6				; store Sonic's horizontal speed
		moveq	#$1B,d1								; save 4 cycles - Filter
		moveq	#$20,d2								; save 4 cycles - Filter
		move.w	d2,d3								; save 4 cycles - Filter
		move.w	obX(a0),d4
		bsr.w	SolidObject

	if ShieldsMode
		beq.s	.donothing

;		tst.b	obCharID(a1)							; is the player Sonic?
;		bne.s	.chkPush								; if not, skip and check if player is rolling on the ground
		btst	#sta2ndFShield,obStatus2nd(a1)			; does Sonic have the Flame Shield
		beq.s	.chkPush								; if not, skip and check if player is rolling on the ground
		cmpi.b	#aniID_FlameDash,(v_shieldobj+obAnim).w	; is Sonic using his ability? (Check Flame Shield's animation)
		beq.s	.cont									; if yes, branch. ABILITY TIME

	.chkPush:
	endif

		btst	#staSonicPush,obStatus(a0)			; is Sonic pushing against the wall?
		bne.s	.chkroll							; if yes, branch

.donothing:
		rts	
; ===========================================================================

.chkroll:
	if SuperMod=1
		btst	#sta2ndSuper,obStatus2nd(a1)	; is Sonic Super?
		bne.s	.cont							; if yes, break wall
	endif
		cmpi.b	#aniID_Roll,obAnim(a1)			; is Sonic rolling?
		bne.s	.donothing						; if not, branch
		move.w	d6,d0							; load Sonic's stored speed
		bpl.s	.chkspeed
		neg.w	d0								; get absolute value if Sonic was moving left

.chkspeed:
		cmpi.w	#$480,d0						; is Sonic's speed 4.5 or higher?
		blo.s	.donothing						; if not, branch

.cont:
		move.w	d6,obVelX(a1)					; restore Sonic's x-speed to what it was prior to colliding with the wall
		addq.w	#4,obX(a1)
		lea		Smash_FragSpd1(pc),a4			; use fragments that move right -- save 4 cycles - Filter
		move.w	obX(a0),d0
		cmp.w	obX(a1),d0						; is Sonic to the right	of the block?
		blo.s	.smash							; if yes, branch
		subq.w	#8,obX(a1)
		lea		Smash_FragSpd2(pc),a4			; use fragments that move left -- save 4 cycles - Filter

.smash:
		move.w	obVelX(a1),obInertia(a1)
		bclr	#staSonicPush,obStatus(a0)
		bclr	#staPush,obStatus(a1)
		moveq	#7,d1							; load 8 fragments
		move.w	#$70,d2
		bsr.s	SmashObject

Smash_FragMove:	; Routine 4
		bsr.w	SpeedToPos
		addi.w	#$70,obVelY(a0)					; make fragment	fall faster
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite					; Clownacy DisplaySprite Fix
