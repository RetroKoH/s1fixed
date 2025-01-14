; ---------------------------------------------------------------------------
; Object 48 - ball on a	chain that Eggman swings (GHZ)
; ---------------------------------------------------------------------------

BossBall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	GBall_Index(pc,d0.w),d1
		jmp		GBall_Index(pc,d1.w)
; ===========================================================================
GBall_Index:	offsetTable
		offsetTableEntry.w GBall_Main
		offsetTableEntry.w GBall_Base
		offsetTableEntry.w GBall_Display2
		offsetTableEntry.w loc_17C68
		offsetTableEntry.w GBall_ChkVanish

;swing_angle = $10		; precise rotation angle (2 bytes)
	; ^^^ We need this so that obShieldProp isn't overwritten, otherwise
	; Insta-Shield negates its collision property. Upper byte written to obAngle.
	; See Obj15 for more details.
; ===========================================================================

GBall_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$4080,swing_angle(a0)
		move.b	swing_angle(a0),obAngle(a0)
		move.w	#-$200,objoff_3E(a0)
		move.l	#Map_BossItems,obMap(a0)
		move.w	#make_art_tile(ArtTile_Eggman_Weapons,0,0),obGfx(a0)
		lea		obSubtype(a0),a2
		clr.b	(a2)+
		moveq	#5,d1
		movea.l	a0,a1
		bra.s	loc_17B60
; ===========================================================================

GBall_MakeLinks:
		jsr		(FindNextFreeObj).l
		bne.s	GBall_MakeBall
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		_move.b	#id_BossBall,obID(a1) ; load chain link object
		move.b	#6,obRoutine(a1)
		move.l	#Map_Swing_GHZ,obMap(a1)
		move.w	#make_art_tile(ArtTile_GHZ_MZ_Swing,0,0),obGfx(a1)
		move.b	#1,obFrame(a1)
		addq.b	#1,obSubtype(a0)

loc_17B60:
		move.w	a1,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#object_size_bits,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#4,obRender(a1)
		move.b	#8,obActWid(a1)
		move.w	#priority6,obPriority(a1)		; RetroKoH/Devon S3K+ Priority Manager
		move.l	objoff_34(a0),objoff_34(a1)
		dbf		d1,GBall_MakeLinks				; repeat sequence 5 more times

GBall_MakeBall:
		move.b	#8,obRoutine(a1)
		move.l	#Map_GBall,obMap(a1)			; load different mappings for final link
		move.w	#make_art_tile(ArtTile_GHZ_Giant_Ball,2,0),obGfx(a1) ; use different graphics
		move.b	#1,obFrame(a1)
		move.w	#priority5,obPriority(a1)		; RetroKoH/Devon S3K+ Priority Manager
		move.b	#(colHarmful|colSz_20x20),obColType(a1)	; make object hurt Sonic
		move.w	a0,objoff_30(a1)				; store address of head chain object to transfer angle to the ball
		rts	
; ===========================================================================

GBall_PosData:	dc.b 0,	$10, $20, $30, $40, $60	; y-position data for links and	giant ball

; ===========================================================================

GBall_Base:	; Routine 2
		lea		(GBall_PosData).l,a3
		lea		obSubtype(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

loc_17BC6:
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#object_size_bits,d4
		addi.l	#v_objspace&$FFFFFF,d4
		movea.l	d4,a1
		move.b	(a3)+,d0
		cmp.b	objoff_3C(a1),d0
		beq.s	loc_17BE0
		addq.b	#1,objoff_3C(a1)

loc_17BE0:
		dbf		d6,loc_17BC6

		cmp.b	objoff_3C(a1),d0
		bne.s	loc_17BFA
		movea.l	objoff_34(a0),a1
		cmpi.b	#6,ob2ndRout(a1)
		bne.s	loc_17BFA
		addq.b	#2,obRoutine(a0)

loc_17BFA:
		cmpi.w	#$20,objoff_32(a0)
		beq.s	GBall_Display
		addq.w	#1,objoff_32(a0)

GBall_Display:
		bsr.w	sub_17C2A
		move.b	obAngle(a0),d0
		jsr		(Swing_Move2).l
		jmp		(DisplayAndCollision).l		; S3K TouchResponse
; ===========================================================================

GBall_Display2:	; Routine 4
		bsr.w	sub_17C2A
		jsr		(Obj48_Move).l
		jmp		(DisplayAndCollision).l		; S3K TouchResponse

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_17C2A:
		movea.l	objoff_34(a0),a1
		addi.b	#$20,obAniFrame(a0)
		bcc.s	loc_17C3C
		bchg	#0,obFrame(a0)				; alternate blinking light

loc_17C3C:
		move.w	obX(a1),objoff_3A(a0)
		move.w	obY(a1),d0
		add.w	objoff_32(a0),d0
		move.w	d0,objoff_38(a0)
		move.b	obStatus(a1),obStatus(a0)
		tst.b	obStatus(a1)
		bpl.s	locret_17C66				; if bit 7 is clear, branch
		_move.b	#id_ExplosionBomb,obID(a0)
		clr.b	obRoutine(a0)

locret_17C66:
		rts	
; End of function sub_17C2A

; ===========================================================================

loc_17C68:	; Routine 6
		movea.l	objoff_34(a0),a1
		tst.b	obStatus(a1)
		bpl.s	GBall_Display3				; if bit 7 is clear, branch
		_move.b	#id_ExplosionBomb,obID(a0)
		clr.b	obRoutine(a0)

GBall_Display3:
		jmp		(DisplayAndCollision).l		; S3K TouchResponse
; ===========================================================================

GBall_ChkVanish:	; Routine 8
		moveq	#0,d0
		tst.b	obFrame(a0)				; is ball showing checkered?
		bne.s	GBall_Vanish			; if yes, branch to alt frame (frame 0)
	; RetroKoH angled ball mod
		movea.w	objoff_30(a0),a2		; store chain head address in a2
		move.b	obAngle(a2),d0			; fetch chain's current angle; store it in d0
		subq.b	#1,d0					; subtract 1, because it ranges from 1-$81
		lsr.b	#1,d0					; cut range down to 0-$40
		move.b	GBall_Angles(pc,d0.w),d0
	; angled ball mod end
;		subi.b	#$40,d0
;		bcc.s	.notnegative			; if ball is on the left side, branch
;		neg.b	d0						; negate angle
;		lsr.b	#1,d0
;		move.b	GBall_Angles2(pc,d0.w),d0
;		bra.s	GBall_Vanish

;.notnegative:
;		lsr.b	#1,d0
;		move.b	GBall_Angles(pc,d0.w),d0
	; angled ball mod end

GBall_Vanish:
		move.b	d0,obFrame(a0)
		movea.l	objoff_34(a0),a1
		tst.b	obStatus(a1)
		bpl.s	GBall_Display4				; if bit 7 is clear, branch
		clr.b	obColType(a0)
		bsr.w	BossDefeated
		subq.b	#1,objoff_3C(a0)
		bpl.s	GBall_Display4
		move.b	#id_ExplosionBomb,obID(a0)
		clr.b	obRoutine(a0)

GBall_Display4:
		jmp		(DisplayAndCollision).l		; S3K TouchResponse
; ===========================================================================

GBall_Angles:
		dc.b	1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3		; 0 - $F
		dc.b	3,3,3,3,3,3,3,3,1,1,1,1,1,1,1,1		; $10 - $1F
		dc.b	1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2		; $20 - $2F
		dc.b	2,2,2,2,3,3,3,3,3,3,3,3,1,1,1,1,1	; $30 - $40
		even
