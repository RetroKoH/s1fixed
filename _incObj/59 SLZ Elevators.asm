; ---------------------------------------------------------------------------
; Object 59 - platforms	that move when you stand on them (SLZ)
; ---------------------------------------------------------------------------

elev_origX = objoff_32		; original x-axis position
elev_origY = objoff_30		; original y-axis position
elev_dist = objoff_3C		; distance to move (2 bytes)

Elevator:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Elev_Index(pc,d0.w),d1
		jsr		Elev_Index(pc,d1.w)
		offscreen.w	DeleteObject,elev_origX(a0)	; PFM S3K Obj
		bra.w	DisplaySprite
; ===========================================================================
Elev_Index:		offsetTable
		offsetTableEntry.w Elev_Main
		offsetTableEntry.w Elev_Platform
		offsetTableEntry.w Elev_Action
		offsetTableEntry.w Elev_MakeMulti

Elev_Vars:
		dc.b $10, 1		; distance to move, action type
		dc.b $20, 1
		dc.b $34, 1
		dc.b $10, 3
		dc.b $20, 3
		dc.b $34, 3
		dc.b $14, 1
		dc.b $24, 1
		dc.b $2C, 1
		dc.b $14, 3
		dc.b $24, 3
		dc.b $2C, 3
		dc.b $20, 5
		dc.b $20, 7
		dc.b $30, 9
; ===========================================================================

Elev_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		bpl.s	.normal				; branch for types 00-7F
	; Elevator Spawners:
		addq.b	#4,obRoutine(a0)	; goto Elev_MakeMulti next
		andi.w	#$7F,d0
		add.w	d0,d0				; multiply by 6
		move.w	d0,d1				; Optimization from S1 in S.C.E.
		add.w	d0,d0
		add.w	d1,d0
		move.w	d0,elev_dist(a0)
		move.w	d0,objoff_3E(a0)
		addq.l	#4,sp
		rts	
; ===========================================================================

.normal:
		move.b	#$28,obActWid(a0)	; set width
		clr.b	obFrame(a0)			; set frame
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		andi.w	#$1E,d0
		lea		Elev_Vars(pc,d0.w),a2
		move.b	(a2)+,d0
		lsl.w	#2,d0
		move.w	d0,elev_dist(a0)		; set distance to move
		move.b	(a2)+,obSubtype(a0)		; set type
		move.l	#Map_Elev,obMap(a0)
		move.w	#make_art_tile(ArtTile_Level,2,0),obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	#priority4,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		move.w	obX(a0),elev_origX(a0)
		move.w	obY(a0),elev_origY(a0)

Elev_Platform:	; Routine 2
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(PlatformObject).l
		bra.w	Elev_Types
; ===========================================================================

Elev_Action:	; Routine 4
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(ExitPlatform).l
		move.w	obX(a0),-(sp)
		bsr.w	Elev_Types
		move.w	(sp)+,d2
		_tst.b	obID(a0)
		beq.s	.deleted
		jmp	(MvSonicOnPtfm2).l

.deleted:
		; Avoid returning to Elevator to prevent display-and-delete
		; and double-delete bugs.
		addq.l	#4,sp
		rts	
; ===========================================================================

Elev_Types:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	Elev_TypeIndex(pc,d0.w),d1
		jmp		Elev_TypeIndex(pc,d1.w)
; ===========================================================================
Elev_TypeIndex:		offsetTable
		offsetTableEntry.w .type00
		offsetTableEntry.w .type01
		offsetTableEntry.w .type02
		offsetTableEntry.w .type01
		offsetTableEntry.w .type04
		offsetTableEntry.w .type01
		offsetTableEntry.w .type06
		offsetTableEntry.w .type01
		offsetTableEntry.w .type08
		offsetTableEntry.w .type09
; ===========================================================================

.type01:
		cmpi.b	#4,obRoutine(a0) ; check if Sonic is standing on the object
		bne.s	.notstanding
		addq.b	#1,obSubtype(a0) ; if yes, add 1 to type

.type00:
.notstanding:
		rts	
; ===========================================================================

.type02:
		bsr.w	Elev_Move
		move.w	objoff_34(a0),d0
		neg.w	d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		rts	
; ===========================================================================

.type04:
		bsr.w	Elev_Move
		move.w	objoff_34(a0),d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		rts	
; ===========================================================================

.type06:
		bsr.w	Elev_Move
		move.w	objoff_34(a0),d0
		asr.w	#1,d0
		neg.w	d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		move.w	objoff_34(a0),d0
		add.w	elev_origX(a0),d0
		move.w	d0,obX(a0)
		rts	
; ===========================================================================

.type08:
		bsr.w	Elev_Move
		move.w	objoff_34(a0),d0
		asr.w	#1,d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		move.w	objoff_34(a0),d0
		neg.w	d0
		add.w	elev_origX(a0),d0
		move.w	d0,obX(a0)
		rts	
; ===========================================================================

.type09:
		bsr.w	Elev_Move
		move.w	objoff_34(a0),d0
		neg.w	d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		tst.b	obSubtype(a0)
		beq.w	.typereset
		rts	
; ===========================================================================

.typereset:
		btst	#staSonicOnObj,obStatus(a0)
		beq.w	DeleteObject
		bset	#staAir,obStatus(a1)
		bclr	#staOnObj,obStatus(a1)
		move.b	#2,obRoutine(a1)
		bra.w	DeleteObject

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Elev_Move:
		move.w	objoff_38(a0),d0
		tst.b	objoff_3A(a0)
		bne.s	loc_10CC8
		cmpi.w	#$800,d0
		bhs.s	loc_10CD0
		addi.w	#$10,d0
		bra.s	loc_10CD0
; ===========================================================================

loc_10CC8:
		tst.w	d0
		beq.s	loc_10CD0
		subi.w	#$10,d0

loc_10CD0:
		move.w	d0,objoff_38(a0)
		ext.l	d0
		asl.l	#8,d0
		add.l	objoff_34(a0),d0
		move.l	d0,objoff_34(a0)
		swap	d0
		move.w	elev_dist(a0),d2
		cmp.w	d2,d0
		bls.s	loc_10CF0
		move.b	#1,objoff_3A(a0)

loc_10CF0:
		add.w	d2,d2
		cmp.w	d2,d0
		bne.s	locret_10CFA
		clr.b	obSubtype(a0)

locret_10CFA:
		rts	
; End of function Elev_Move

; ===========================================================================

Elev_MakeMulti:	; Routine 6
		subq.w	#1,elev_dist(a0)
		bne.s	.chkdel
		move.w	objoff_3E(a0),elev_dist(a0)
		bsr.w	FindFreeObj
		bne.s	.chkdel
		_move.b	#id_Elevator,obID(a1) ; duplicate the object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#$E,obSubtype(a1)

.chkdel:
		addq.l	#4,sp
		out_of_range.w	DeleteObject
		rts	
