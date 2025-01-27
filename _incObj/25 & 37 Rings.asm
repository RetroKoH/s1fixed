; ---------------------------------------------------------------------------
; Object 25 - rings
; ---------------------------------------------------------------------------

Rings:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Ring_Index(pc,d0.w),d1
		jmp		Ring_Index(pc,d1.w)
; ===========================================================================
Ring_Index:		offsetTable
ptr_Ring_Main:		offsetTableEntry.w Ring_Main
ptr_Ring_Animate:	offsetTableEntry.w Ring_Animate
ptr_Ring_Collect:	offsetTableEntry.w Ring_Collect
ptr_Ring_Sparkle:	offsetTableEntry.w Ring_Sparkle
ptr_Ring_Delete:	offsetTableEntry.w Ring_Delete

id_Ring_Main = ptr_Ring_Main-Ring_Index	; 0
id_Ring_Animate = ptr_Ring_Animate-Ring_Index	; 2
id_Ring_Collect = ptr_Ring_Collect-Ring_Index	; 4
id_Ring_Sparkle = ptr_Ring_Sparkle-Ring_Index	; 6
id_Ring_Delete = ptr_Ring_Delete-Ring_Index	; 8
; ===========================================================================
; Placement table removed -- RetroKoH S3K Rings Manager

Ring_Main:	; Routine 0 -- Stripped down init routine -- RetroKoH S3K Rings Manager
		addq.b	#2,obRoutine(a0)
		move.w	obX(a0),objoff_32(a0)
		move.l	#Map_Ring,obMap(a0)
		move.w	#make_art_tile(ArtTile_Ring,1,0),obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	#priority2,obPriority(a0)		; RetroKoH/Devon S3K+ Priority Manager
		move.b	#(colPowerup|colSz_6x6),obColType(a0)
		move.b	#8,obActWid(a0)

Ring_Animate:	; Routine 2
	; ProjectFM S3K Objects Manager
		move.w	objoff_32(a0),d0
		bra.w	RememberState
	; S3K Objects Manager End
; ===========================================================================

RAttract_Collect:
	if PerfectBonusEnabled
		subq.w	#1,(v_perfectringsleft).w
	endif
Ring_Collect:	; Routine 4
		addq.b	#2,obRoutine(a0)
		clr.b	obColType(a0)
		move.w	#priority1,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		move.w	#make_art_tile(ArtTile_RingSparkles,1,0),obGfx(a0)
		bsr.w	CollectRing
		; Code Removed -- ProjectFM S3K Objects Manager

Ring_Sparkle:	; fallthrough / Routine 6
		lea		Ani_Ring(pc),a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ===========================================================================

Ring_Delete:	; Routine 8
		bra.w	DeleteObject

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


CollectRing:
	; RetroKoH Ring Count Cap
		move.w	#sfx_Ring,d0	 	; prepare to play ring sound
		cmpi.w	#999,(v_rings).w	; did the Sonic collect 999+ rings? < Added ring cap
		bcc.s	.playsnd         	; if yes, branch
		addq.w	#1,(v_rings).w	 	; add 1 to rings
	; Ring Count Cap End
		ori.b	#1,(f_ringcount).w	; update the rings counter
		cmpi.w	#100,(v_rings).w	; do you have < 100 rings?
		blo.s	.playsnd			; if yes, branch
		bset	#1,(v_lifecount).w	; update lives counter
		beq.s	.got100
		cmpi.w	#200,(v_rings).w	; do you have < 200 rings?
		blo.s	.playsnd			; if yes, branch
		bset	#2,(v_lifecount).w	; update lives counter
		bne.s	.playsnd

.got100:
	; Mercury Lives Over/Underflow Fix
		cmpi.b	#99,(v_lives).w		; are lives at max?
		beq.s	.playbgm
		addq.b	#1,(v_lives).w		; add 1 to number of lives
		addq.b	#1,(f_lifecount).w	; update the lives counter
.playbgm:
	; Lives Over/Underflow Fix End
		move.w	#bgm_ExtraLife,d0	; play extra life music

.playsnd:
		jmp	(PlaySound_Special).w
; End of function CollectRing

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 37 - rings flying out of Sonic	when he's hit
; ---------------------------------------------------------------------------

RingLoss:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	RLoss_Index(pc,d0.w),d1
		jmp		RLoss_Index(pc,d1.w)
; ===========================================================================
RLoss_Index:		offsetTable
		offsetTableEntry.w RLoss_Count
		offsetTableEntry.w RLoss_Bounce
		offsetTableEntry.w Ring_Collect
		offsetTableEntry.w Ring_Sparkle
		offsetTableEntry.w Ring_Delete

	if ShieldsMode	; Attracted Rings (By the lightning shield)
		offsetTableEntry.w RAttract_Init
		offsetTableEntry.w RAttract_Main
		offsetTableEntry.w RAttract_Collect
		offsetTableEntry.w Ring_Sparkle
		offsetTableEntry.w Ring_Delete
	endif
; ===========================================================================

RLoss_Count:	; Routine 0
		movea.l	a0,a1
		moveq	#0,d5
		move.w	(v_rings).w,d5			; check number of rings you have
		moveq	#32,d0
	; RHS Ring Loss Speedup
		lea		SpillRingData,a3		; load the address of the array in a3
		lea     (v_player).w,a2			; a2=character
		btst    #staWater,obStatus(a2)	; is Sonic underwater?
		beq.s   .abovewater				; if not, branch
		lea		SpillRingData_Water,a3	; load the address of the array in a3

.abovewater:
	; Ring Loss Speedup End
		cmp.w	d0,d5					; do you have 32 or more?
		blo.s	.belowmax				; if not, branch
		move.w	d0,d5					; if yes, set d5 to 32

.belowmax:
		subq.w	#1,d5					; decrease the counter the first time, as we are creating the first ring now.

	; Spirituinsanum Mass Object Load Optimization
	; Create the first instance, then loop create the others afterward.
		move.b	#id_RingLoss,obID(a1) 	; load bouncing ring object
		addq.b	#2,obRoutine(a1)
		move.b	#8,obHeight(a1)
		move.b	#8,obWidth(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	#Map_Ring,obMap(a1)
		move.w	#make_art_tile(ArtTile_LostRing,1,0),obGfx(a1)
		move.b	#4,obRender(a1)
		move.w	#priority3,obPriority(a1)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	#(colPowerup|colSz_6x6),obColType(a1)
		move.b	#8,obActWid(a1)
		move.w  (a3)+,obVelX(a1)	; move the data contained in the array to the x velocity and increment the address in a3
		move.w  (a3)+,obVelY(a1)	; move the data contained in the array to the y velocity and increment the address in a3
		subq	#1,d5				; decrement for the first ring created
		bmi.s	.resetcounter		; if only one ring is needed, branch and skip EVERYTHING below altogether
		; Here we begin what's replacing SingleObjLoad, in order to avoid resetting its d0 every time an object is created.
		lea		(v_lvlobjspace).w,a1
		move.w	#v_lvlobjcount,d0

.loop:
		; REMOVE FindFreeObj. It's the routine that causes such slowdown
		tst.b	obID(a1)		; is object RAM	slot empty?
		beq.s	.makerings		; Let's correct the branches. Here we can also skip the bne that was originally after bsr.w FindFreeObj because we already know there's a free object slot in memory.
		lea		object_size(a1),a1
		dbf		d0,.loop		; Branch correction again.
		bne.s	.resetcounter	; We're moving this line here.

.makerings:
		_move.b	#id_RingLoss,obID(a1)	; load bouncing ring object
		addq.b	#2,obRoutine(a1)
		move.b	#8,obHeight(a1)
		move.b	#8,obWidth(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	#Map_Ring,obMap(a1)
		move.w	#make_art_tile(ArtTile_LostRing,1,0),obGfx(a1)
		move.b	#4,obRender(a1)
		move.w	#priority3,obPriority(a1)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	#(colPowerup|colSz_6x6),obColType(a1)
		move.b	#8,obActWid(a1)
		move.w  (a3)+,obVelX(a1)	; move the data contained in the array to the x velocity and increment the address in a3
		move.w  (a3)+,obVelY(a1)	; move the data contained in the array to the y velocity and increment the address in a3
		dbf		d5,.loop			; repeat for number of rings (max 31)

.resetcounter:
	; Mass Object Load Optimization End
		clr.w	(v_rings).w				; reset number of rings to zero
		move.b	#$80,(f_ringcount).w	; update ring counter
		clr.b	(v_lifecount).w
		; RHS Ring Timers Fix
		moveq   #-1,d0					; Move #-1 to d0
		move.b  d0,obDelayAni(a0)		; Move d0 to new timer
		move.b  d0,(v_ani3_time).w		; Move d0 to old timer (for animated purposes)
		; Ring Timers Fix End
		move.w	#sfx_RingLoss,d0
		jsr		(PlaySound_Special).w	; play ring loss sound


RLoss_Bounce:	; Routine 2
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
	; RHS Underwater Rings Physics Fix
		tst.b	(f_water).w			; Does the level have water?
		beq.s	.skipbounceslow		; If not, branch and skip underwater checks
		move.w	(v_waterpos1).w,d6	; Move water level to d6
		cmp.w	obY(a0),d6			; Is the ring object underneath the water level?
		bgt.s	.skipbounceslow		; If not, branch and skip underwater commands
		subi.w	#$E,obVelY(a0)		; Reduce gravity by $E ($18-$E=$A), giving the underwater effect

.skipbounceslow:
	; Underwater Rings Physics Fix End
		bmi.s	.chkdel
		move.b	(v_vbla_byte).w,d0
		add.b	d7,d0
		andi.b	#3,d0
		bne.s	.chkdel
		jsr		(ObjFloorDist).l
		tst.w	d1
		bpl.s	.chkdel
		add.w	d1,obY(a0)
		move.w	obVelY(a0),d0
		asr.w	#2,d0
		sub.w	d0,obVelY(a0)
		neg.w	obVelY(a0)

.chkdel:
		; RHS Ring Timers Fix
		subq.b	#1,obDelayAni(a0)		; Subtract 1
		beq.w	DeleteObject			; If 0, delete
		; Ring Timers Fix End
		; RHS Accidental Ring Deletion Fix
		cmpi.w	#$FF00,(v_limittop2).w	; is vertical wrapping enabled?
		beq.w	.chkflash				; if so, branch
		; Accidental Ring Deletion Fix End
		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	obY(a0),d0				; has object moved below level boundary?
		blo.w	DeleteObject			; if yes, branch
		; Mercury Ring Flashing Effect
.chkflash:
	; S3K TouchResponse
	; Add to collision response list directly, then choose whether or not to display.
		lea		(v_col_response_list).w,a1
		cmpi.w	#$7E,(a1)				; Is list full?
		bhs.s	.full					; If so, return
		addq.w	#2,(a1)					; Count this new entry
		adda.w	(a1),a1					; Offset into right area of list
		move.w	a0,(a1)					; Store RAM address in list
		move.b	obDelayAni(a0),d0		; load timer to d0 (accessing d0 later saves cycles)
		btst	#0,d0					; Test the first bit of the timer, so rings flash every other frame.
		beq.w	DisplaySprite			; If the bit is 0, the ring will appear.
		cmpi.b	#80,d0					; Rings will flash during last 80 steps of their life.
		bhi.w	DisplaySprite			; If the timer is higher than 80, obviously the rings will STAY visible.
		rts								; Skip Displaying if there is no room in the collision table.
.full:
		bra.w	DisplaySprite
		; Ring Flashing Effect End
; ===========================================================================

; ---------------------------------------------------------------------------
; Ring Spawn Array -- RHS Ring Loss Speedup
; ---------------------------------------------------------------------------

SpillRingData:  dc.w    $FF3C,$FC14, $00C4,$FC14, $FDC8,$FCB0, $0238,$FCB0 ; 4
                dc.w    $FCB0,$FDC8, $0350,$FDC8, $FC14,$FF3C, $03EC,$FF3C ; 8
                dc.w    $FC14,$00C4, $03EC,$00C4, $FCB0,$0238, $0350,$0238 ; 12
                dc.w    $FDC8,$0350, $0238,$0350, $FF3C,$03EC, $00C4,$03EC ; 16
                dc.w    $FF9E,$FE0A, $0062,$FE0A, $FEE4,$FE58, $011C,$FE58 ; 20
                dc.w    $FE58,$FEE4, $01A8,$FEE4, $FE0A,$FF9E, $01F6,$FF9E ; 24
                dc.w    $FE0A,$0062, $01F6,$0062, $FE58,$011C, $01A8,$011C ; 28
                dc.w    $FEE4,$01A8, $011C,$01A8, $FF9E,$0156, $0062,$0156 ; 32
                even
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Ring Spawn Array - Underwater -- RHS Ring Loss Speedup
; ---------------------------------------------------------------------------

SpillRingData_Water:
				dc.w    $FF9C,$FE08, $0064,$FE08, $FEE4,$FE58, $011C,$FE58 ; 4
                dc.w    $FE58,$FEE4, $01A8,$FEE4, $FE08,$FF9C, $01F8,$FF9C ; 8
                dc.w    $FE08,$0060, $01F8,$0060, $FE58,$011C, $01A8,$011C ; 12
                dc.w    $FEE4,$01A8, $011C,$01A8, $FF9C,$01F4, $0064,$01F4 ; 16
                dc.w    $FFCE,$FF04, $0032,$FF04, $FF72,$FF2C, $008E,$FF2C ; 20
                dc.w    $FF2C,$FF72, $00D4,$FF72, $FF04,$FFCE, $00FC,$FFCE ; 24
                dc.w    $FF04,$0030, $00FC,$0030, $FF2C,$008E, $00D4,$008E ; 28
                dc.w    $FF72,$00D4, $008E,$00D4, $FFCE,$00FA, $0032,$00FA ; 32
                even
; ===========================================================================

	if ShieldsMode
RAttract_Init:
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Ring,obMap(a0)
		move.w	#make_art_tile(ArtTile_Ring,1,0),obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	#priority2,obPriority(a0)
		move.b	#(colPowerup|colSz_6x6),obColType(a0)
		move.b	#8,obActWid(a0)
		move.b	#8,obHeight(a0)
		move.b	#8,obWidth(a0)

RAttract_Main:
		bsr.s	AttractedRing_Move
		btst	#sta2ndLShield,(v_player+obStatus2nd).w
		bne.s	.hasshield
		move.b	#2,obRoutine(a0)
		moveq   #-1,d0					; Move #-1 to d0
		move.b  d0,obDelayAni(a0)		; Move d0 to new timer
		move.b  d0,(v_ani3_time).w		; Move d0 to old timer (for animation purposes)

.hasshield:
		; Fix accidental deletion of scattered rings - REV C EDIT
		cmpi.w  #$FF00,(v_limittop2).w	; is vertical wrapping enabled?
		beq.s   .display       	; if so, branch
		; End of fix

		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	obY(a0),d0		; has object moved below level boundary?
		bcs.w	DeleteObject	; if yes, branch

.display:	
		jmp		(DisplayAndCollision).l	; S3K TouchResponse


; =============== S U B R O U T I N E =======================================


AttractedRing_Move:
		move.w	#$30,d1
		move.w	(v_player+obX).w,d0
		cmp.w	obX(a0),d0
		bcc.s	.branch1
		neg.w	d1
		tst.w	obVelX(a0)
		bmi.s	.branch2
		add.w	d1,d1
		add.w	d1,d1
		bra.s	.branch2
; ---------------------------------------------------------------------------

.branch1:
		tst.w	obVelX(a0)
		bpl.s	.branch2
		add.w	d1,d1
		add.w	d1,d1

.branch2:
		add.w	d1,obVelX(a0)
		move.w	#$30,d1
		move.w	(v_player+obY).w,d0
		cmp.w	obY(a0),d0
		bcc.s	.branch3
		neg.w	d1
		tst.w	obVelY(a0)
		bmi.s	.branch4
		add.w	d1,d1
		add.w	d1,d1
		bra.s	.branch4
; ---------------------------------------------------------------------------

.branch3:
		tst.w	obVelY(a0)
		bpl.s	.branch4
		add.w	d1,d1
		add.w	d1,d1

.branch4:
		add.w	d1,obVelY(a0)
		jmp		(SpeedToPos).l
; End of function AttractedRing_Move
	endif