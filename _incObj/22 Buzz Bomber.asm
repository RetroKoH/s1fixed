; ===========================================================================
; ---------------------------------------------------------------------------
; Object 22 - Buzz Bomber enemy	(GHZ, MZ, SYZ)
; ---------------------------------------------------------------------------

buzz_timedelay = objoff_32
buzz_buzzstatus = objoff_34
buzz_parent = objoff_3C

BuzzBomber:
	; LavaGaming Object Routine Optimization
		moveq	#0,d0				; 4
		move.b	obRoutine(a0),d0	; C
		cmpi.b	#2,d0				; 8
		beq.s	Buzz_Action			; 8/A - Most common routine, and closest branch for fewer cycles = $22
		
		tst.b	d0					; 4
		bne.w	DeleteObject		; C/E ($30 on init, $32 on Destroy)
	; Object Routine Optimization End

Buzz_Main:		; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Buzz,obMap(a0)
		move.w	#make_art_tile(ArtTile_Buzz_Bomber,0,0),obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	#priority3,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	#(colEnemy|colSz_24x12),obColType(a0)
		move.b	#$18,obActWid(a0)

Buzz_Action:	; Routine 2
	; LavaGaming Object Routine Optimization		
		tst.b	ob2ndRout(a0)
		bne.w	.chknearsonic
	; Object Routine Optimization End

.move:			; Secondary Routine 0
		subq.w	#1,buzz_timedelay(a0)	; subtract 1 from time delay
		bpl.w	.animate				; if time remains, branch
		btst	#1,buzz_buzzstatus(a0)	; is Buzz Bomber near Sonic?
		bne.s	.fire					; if yes, branch
		addq.b	#2,ob2ndRout(a0)
		move.w	#127,buzz_timedelay(a0) ; set time delay to just over 2 seconds
		move.w	#$400,obVelX(a0) 		; move Buzz Bomber to the right
		move.b	#1,obAnim(a0)			; use "flying" animation
		btst	#staFlipX,obStatus(a0)	; is Buzz Bomber facing	left?
		bne.w	.animate				; if not, branch
		neg.w	obVelX(a0)				; move Buzz Bomber to the left
		bra.w	.animate
; ===========================================================================

.fire:
		bsr.w	FindFreeObj
		bne.w	.animate
		_move.b	#id_Missile,obID(a1)	; load missile object

		move.l	#$02000200,obVelX(a1)	; move missile downwards, to the right

		moveq	#28,d0
		add.w	obY(a0),d0
		move.w	d0,obY(a1)				; set missile Ypos to buzzbomber Ypos + 28

		moveq	#20,d0					; Clownacy positioning fix
		btst	#staFlipX,obStatus(a0)	; is Buzz Bomber facing	left?
		bne.s	.noflip2				; if not, branch
		neg.w	d0
		neg.w	obVelX(a1)				; move missile to the left

.noflip2:
		add.w	obX(a0),d0
		move.w	d0,obX(a1)				; set missile Xpos to buzzbomber Xpos +/- 20

		move.b	obStatus(a0),obStatus(a1)
		move.w	#14,buzz_timedelay(a1)
		move.l	a0,buzz_parent(a1)
		move.b	#1,buzz_buzzstatus(a0)	; set to "already fired" to prevent refiring
		move.w	#59,buzz_timedelay(a0)
		move.b	#2,obAnim(a0)			; use "firing" animation
		bra.w	.animate
; ===========================================================================

.chknearsonic:	; Secondary Routine 2
		subq.w	#1,buzz_timedelay(a0)	; subtract 1 from time delay
		bmi.s	.chgdirection
		bsr.w	SpeedToPos_XOnly
		tst.b	buzz_buzzstatus(a0)
		bne.s	.animate
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bpl.s	.isleft
		neg.w	d0

.isleft:
		cmpi.w	#96,d0					; is Buzz Bomber within	96 ($60) pixels of Sonic?
		bhs.s	.animate				; if not, branch
		tst.b	obRender(a0)			; is Buzz Bomber visible on-screen?
		bpl.s	.animate				; if not, branch
		move.b	#2,buzz_buzzstatus(a0)	; set Buzz Bomber to "near Sonic"
		move.w	#29,buzz_timedelay(a0)	; set time delay to half a second
		bra.s	.stop
; ===========================================================================

.chgdirection:
		clr.b	buzz_buzzstatus(a0)		; set Buzz Bomber to "normal"
		bchg	#staFlipX,obStatus(a0)	; change direction
		move.w	#59,buzz_timedelay(a0)

.stop:
		subq.b	#2,ob2ndRout(a0)
		clr.w	obVelX(a0)				; stop Buzz Bomber moving
		clr.b	obAnim(a0)				; use "hovering" animation

.animate:
		lea		Ani_Buzz(pc),a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================