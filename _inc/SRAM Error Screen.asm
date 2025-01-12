; ---------------------------------------------------------------------------
; SRAM Error screen
; ---------------------------------------------------------------------------

GM_SRAMError:
		move.b	#mus_Stop,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		lea		(vdp_control_port).l,a6
		move.w	#$8004,(a6)	; use 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$8700,(a6)	; set background colour (palette entry 0)
		move.w	#$8B00,(a6)	; full-screen vertical scrolling
		clr.b	(f_wtr_state).w
		bsr.w	ClearScreen

; load menutext and tilemap with our disclaimer
		lea		(vdp_data_port).l,a6
		locVRAM	ArtTile_Level_Select_Font*tile_size,4(a6)
		lea		(Art_Text).l,a5	; load level select font
		move.w	#(Art_Text_End-Art_Text)/2-1,d1

Splash_LoadText:
		move.w	(a5)+,(a6)
		dbf		d1,Splash_LoadText	; load level select font

		moveq	#0,d1
		lea		TextData_ErrorHeading(pc),a1 ; where to fetch the lines from
		move.l	#$41060003,4(a6)	; starting screen position 
		move.w	#$A680,d3	; which palette the font should use and where it is in VRAM
		moveq	#33,d2		; number of characters to be rendered in a line -1
		bsr.w	GMSE_LineRender

		moveq	#0,d1
		lea		TextData_ErrorBody(pc),a1 ; where to fetch the lines from
		move.l	#$43060003,d4	; (CHANGE) starting screen position 
		move.w	#$A680,d3	; which palette the font should use and where it is in VRAM
		moveq	#18,d1		; number of lines of text to be displayed -1

-
		move.l	d4,4(a6)
		moveq	#33,d2		; number of characters to be rendered in a line -1
		bsr.w	GMSE_LineRender
		addi.l	#(1*$800000),d4  ; replace number to the left with desired distance between each line
		dbf	d1,-

.loadpal:
		moveq	#palid_LevelSel,d0
		bsr.w	PalLoad	; load level select palette

	; could play music here
		move.b	#$14,(v_vbla_routine).w
		bsr.w	WaitForVBla
		move.w	#180,(v_demolength).w

Splash_WaitEnd:
		move.b	#2,(v_vbla_routine).w
		bsr.w	WaitForVBla
		tst.w	(v_demolength).w
		beq.s	Splash_GotoTitle
		andi.b	#btnStart,(v_jpadpress1).w ; is Start button pressed?
		beq.s	Splash_WaitEnd	; if not, branch

Splash_GotoTitle:
		move.b	#id_Title,(v_gamemode).w ; go to title screen
		rts	
; ===========================================================================

TextData_ErrorHeading:
		dc.b	"   WARNING - NO SRAM DETECTED!!   "
		
TextData_ErrorBody:
		dc.b	"IT HAS BEEN DETECTED THAT SRAM,   "
		dc.b	"AKA THE BATTERY BACKED SAVING     "
		dc.b	"MECHANISM, ISN'T INITIALIZED.     "
		dc.b	"                                  "
		dc.b	"THIS ROM HACK RELIES ON IT TO SAVE"
		dc.b	"YOUR CURRENT PROGRESS. GIVEN THAT "
		dc.b	"IT ISN'T LOADED PROPERLY, PROGRESS"
		dc.b	"OR SETTINGS WILL NOT BE SAVED UPON"
		dc.b	"RESET.                            "
		dc.b	"                                  "
		dc.b	"PLEASE CHECK THE SETTINGS OF YOUR "
		dc.b	"EMULATOR TO SEE IF SRAM IS ENABLED"
		dc.b	"AND WORKING OR CHECK THE MANUAL OF"
		dc.b	"YOUR FLASHCART TO SEE IF IT       "
		dc.b	"SUPPORTS SRAM.                    "
		dc.b	"                                  "
		dc.b	"           0123456789             "
		dc.b	"                                  "
		dc.b	"     PRESS START TO CONTINUE      "
; ===========================================================================

; ===========================================================================
; Subroutine that renders one line of ASCII text.
; Taken from the ASCII S1 Level Select Screen.
; ===========================================================================	
	
; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

GMSE_LineRender:
GMSE_LineLoop:
		moveq	#0,d0
		move.b	(a1)+,d0			; get character
		bpl.s	GMSE_CharOk			; branch if valid
		move.w	#0,(a6)				; use blank character
		dbf		d2,GMSE_LineLoop
		rts	
; ===========================================================================

GMSE_CharOk:			; XREF: GMSE_LineLoop
		cmp.w	#$40,d0		; Check for $40 (End of ASCII number area)
		blt.s	.notText	; If this is not an ASCII text character, branch
		subq.w	#3,d0		; Subtract an extra 3 (Compensate for missing characters in the font)
    .notText:
		sub.w	#$30,d0		; Subtract #$33
		add.w	d3,d0		; combine char with VRAM setting
		move.w	d0,(a6)		; send to VRAM
		dbf		d2,GMSE_LineLoop  
		rts
; End of function GMSE_LineLoop