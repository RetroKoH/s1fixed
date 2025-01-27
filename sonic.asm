;  =========================================================================
; |                            Sonic 1: Fixed                               |
; |       Updated Sonic the Hedgehog Disassembly for Sega Mega Drive        |
;  =========================================================================
;
; Updated disassembly for AS by Clownacy and MarkeyJester
; Mods by RetroKoH, DeltaW, Hitaxas, Redhotsonic, and Mercury
; Additional Credits listed in README.md
;
; ===========================================================================

	cpu 68000

ZoneCount	  = 6	; discrete zones are: GHZ, MZ, SYZ, LZ, SLZ, and SBZ
zeroOffsetOptimization = 1	; if 1, makes a handful of zero-offset instructions smaller

	include "Mods.asm"			; S1Fixed Mod Variables (Sorted by Context)

	include "MacroSetup.asm"
	include	"Constants.asm"
	include	"Variables.asm"
	include	"Macros.asm"
	include	"Debugger.asm"

; ===========================================================================

StartOfRom:
Vectors:
		dc.l v_systemstack&$FFFFFF	; Initial stack pointer value
		dc.l EntryPoint			; Start of program
		dc.l BusError			; Bus error
		dc.l AddressError		; Address error (4)
		dc.l IllegalInstr		; Illegal instruction
		dc.l ZeroDivide			; Division by zero
		dc.l ChkInstr			; CHK exception
		dc.l TrapvInstr			; TRAPV exception (8)
		dc.l PrivilegeViol		; Privilege violation
		dc.l Trace				; TRACE exception
		dc.l Line1010Emu		; Line-A emulator
		dc.l Line1111Emu		; Line-F emulator (12)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (16)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (20)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (24)
		dc.l ErrorExcept		; Spurious exception
		dc.l ErrorTrap			; IRQ level 1
		dc.l ErrorTrap			; IRQ level 2
		dc.l ErrorTrap			; IRQ level 3 (28)
		dc.l HBlank				; IRQ level 4 (horizontal retrace interrupt)
		dc.l ErrorTrap			; IRQ level 5
		dc.l VBlank				; IRQ level 6 (vertical retrace interrupt)
		dc.l ErrorTrap			; IRQ level 7 (32)
		dc.l ErrorTrap			; TRAP #00 exception
		dc.l ErrorTrap			; TRAP #01 exception
		dc.l ErrorTrap			; TRAP #02 exception
		dc.l ErrorTrap			; TRAP #03 exception (36)
		dc.l ErrorTrap			; TRAP #04 exception
		dc.l ErrorTrap			; TRAP #05 exception
		dc.l ErrorTrap			; TRAP #06 exception
		dc.l ErrorTrap			; TRAP #07 exception (40)
		dc.l ErrorTrap			; TRAP #08 exception
		dc.l ErrorTrap			; TRAP #09 exception
		dc.l ErrorTrap			; TRAP #10 exception
		dc.l ErrorTrap			; TRAP #11 exception (44)
		dc.l ErrorTrap			; TRAP #12 exception
		dc.l ErrorTrap			; TRAP #13 exception
		dc.l ErrorTrap			; TRAP #14 exception
		dc.l ErrorTrap			; TRAP #15 exception (48)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)

		dc.b "SEGA MEGA DRIVE "	; Hardware system ID (Console name)
		dc.b "(C)SEGA 1991.APR"	; Copyright holder and release date (generally year)
		dc.b "SONIC THE               HEDGEHOG                "		; Domestic name
		dc.b "SONIC THE               HEDGEHOG                "		; International name
		dc.b "GM 00004049-01"	; Serial/version number (Rev non-0)

Checksum:
		dc.w $7469				; Hardcoded to make it easier to check for ROM correctness
		dc.b "J               "	; I/O support
		dc.l StartOfRom			; Start address of ROM
RomEndLoc:
		dc.l EndOfRom-1		; End address of ROM
		dc.l $FF0000		; Start address of RAM
		dc.l $FFFFFF		; End address of RAM
		if EnableSRAM=1
		dc.b $52, $41, $A0+(BackupSRAM<<6)+(AddressSRAM<<3), $20 ; SRAM support
		dc.l $00200000		; SRAM start ($200001)
		dc.l $002001FF		; SRAM end ($20xxxx)
		else
		dc.l $20202020
		dc.l $20202020		; SRAM start ($200001)
		dc.l $20202020		; SRAM end ($20xxxx)
		endif
		dc.b "                                                    " ; Notes (unused, anything can be put in this space, but it has to be 52 bytes.)
		dc.b "JUE             " ; Region (Country code)
EndOfHeader:

; ===========================================================================
; Crash/Freeze the 68000. Unlike Sonic 2, Sonic 1 uses the 68000 for playing music, so it stops too

ErrorTrap:
		nop	
		nop	
		bra.s	ErrorTrap
; ===========================================================================

EntryPoint:
		tst.l	(z80_port_1_control).l ; test port A & B control registers
		bne.s	PortA_Ok
		tst.w	(z80_expansion_control).l ; test port C control register

PortA_Ok:
		bne.s	SkipSetup ; Skip the VDP and Z80 setup code if port A, B or C is ok...?
		lea		SetupValues(pc),a5	; Load setup values array address.
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	-$10FF(a1),d0	; get hardware version (from $A10001)
		andi.b	#$F,d0
		beq.s	SkipSecurity	; If the console has no TMSS, skip the security stuff.
		move.l	#'SEGA',$2F00(a1) ; move "SEGA" to TMSS register ($A14000)

SkipSecurity:
		move.w	(a4),d0	; clear write-pending flag in VDP to prevent issues if the 68k has been reset in the middle of writing a command long word to the VDP.
		moveq	#0,d0	; clear d0
		movea.l	d0,a6	; clear a6
		move.l	a6,usp	; set usp to $0

		moveq	#$17,d1
VDPInitLoop:
		move.b	(a5)+,d5	; add $8000 to value
		move.w	d5,(a4)		; move value to	VDP register
		add.w	d7,d5		; next register
		dbf	d1,VDPInitLoop
		
		move.l	(a5)+,(a4)
		move.w	d0,(a3)		; clear	the VRAM
		move.w	d7,(a1)		; stop the Z80
		move.w	d7,(a2)		; reset	the Z80

WaitForZ80:
		btst	d0,(a1)		; has the Z80 stopped?
		bne.s	WaitForZ80	; if not, branch

		moveq	#$25,d2
Z80InitLoop:
		move.b	(a5)+,(a0)+
		dbf	d2,Z80InitLoop
		
		move.w	d0,(a2)
		move.w	d0,(a1)		; start	the Z80
		move.w	d7,(a2)		; reset	the Z80

ClrRAMLoop:
		move.l	d0,-(a6)	; clear 4 bytes of RAM
		dbf	d6,ClrRAMLoop	; repeat until the entire RAM is clear
		move.l	(a5)+,(a4)	; set VDP display mode and increment mode
		move.l	(a5)+,(a4)	; set VDP to CRAM write

		moveq	#$1F,d3	; set repeat times
ClrCRAMLoop:
		move.l	d0,(a3)	; clear 2 palettes
		dbf	d3,ClrCRAMLoop	; repeat until the entire CRAM is clear
		move.l	(a5)+,(a4)	; set VDP to VSRAM write

		moveq	#$13,d4
ClrVSRAMLoop:
		move.l	d0,(a3)	; clear 4 bytes of VSRAM.
		dbf	d4,ClrVSRAMLoop	; repeat until the entire VSRAM is clear
		moveq	#3,d5

PSGInitLoop:
		move.b	(a5)+,$11(a3)	; reset	the PSG
		dbf	d5,PSGInitLoop	; repeat for other channels
		move.w	d0,(a2)
		movem.l	(a6),d0-a6	; clear all registers
		disable_ints

SkipSetup:
		bra.s	GameProgram	; begin game

; ===========================================================================
SetupValues:	dc.w $8000		; VDP register start number
		dc.w $3FFF		; size of RAM/4
		dc.w $100		; VDP register diff

		dc.l z80_ram		; start	of Z80 RAM
		dc.l z80_bus_request	; Z80 bus request
		dc.l z80_reset		; Z80 reset
		dc.l vdp_data_port	; VDP data
		dc.l vdp_control_port	; VDP control

		dc.b 4			; VDP $80 - 8-colour mode
		dc.b $14		; VDP $81 - Megadrive mode, DMA enable
		dc.b ($C000>>10)	; VDP $82 - foreground nametable address
		dc.b ($F000>>10)	; VDP $83 - window nametable address
		dc.b ($E000>>13)	; VDP $84 - background nametable address
		dc.b ($D800>>9)		; VDP $85 - sprite table address
		dc.b 0			; VDP $86 - unused
		dc.b 0			; VDP $87 - background colour
		dc.b 0			; VDP $88 - unused
		dc.b 0			; VDP $89 - unused
		dc.b 255		; VDP $8A - HBlank register
		dc.b 0			; VDP $8B - full screen scroll
		dc.b $81		; VDP $8C - 40 cell display
		dc.b ($DC00>>10)	; VDP $8D - hscroll table address
		dc.b 0			; VDP $8E - unused
		dc.b 1			; VDP $8F - VDP increment
		dc.b 1			; VDP $90 - 64 cell hscroll size
		dc.b 0			; VDP $91 - window h position
		dc.b 0			; VDP $92 - window v position
		dc.w $FFFF		; VDP $93/94 - DMA length
		dc.w 0			; VDP $95/96 - DMA source
		dc.b $80		; VDP $97 - DMA fill VRAM
		dc.l $40000080		; VRAM address 0

	; Z80 instructions (not the sound driver; that gets loaded later)
    if (*)+$26 < $10000
    save
    CPU Z80 ; start assembling Z80 code
    phase 0 ; pretend we're at address 0
	xor	a	; clear a to 0
	ld	bc,((z80_ram_end-z80_ram)-zStartupCodeEndLoc)-1 ; prepare to loop this many times
	ld	de,zStartupCodeEndLoc+1	; initial destination address
	ld	hl,zStartupCodeEndLoc	; initial source address
	ld	sp,hl	; set the address the stack starts at
	ld	(hl),a	; set first byte of the stack to 0
	ldir		; loop to fill the stack (entire remaining available Z80 RAM) with 0
	pop	ix	; clear ix
	pop	iy	; clear iy
	ld	i,a	; clear i
	ld	r,a	; clear r
	pop	de	; clear de
	pop	hl	; clear hl
	pop	af	; clear af
	ex	af,af'	; swap af with af'
	exx		; swap bc/de/hl with their shadow registers too
	pop	bc	; clear bc
	pop	de	; clear de
	pop	hl	; clear hl
	pop	af	; clear af
	ld	sp,hl	; clear sp
	di		; clear iff1 (for interrupt handler)
	im	1	; interrupt handling mode = 1
	ld	(hl),0E9h ; replace the first instruction with a jump to itself
	jp	(hl)	  ; jump to the first instruction (to stay there forever)
zStartupCodeEndLoc:
    dephase ; stop pretending
	restore
    padding off ; unfortunately our flags got reset so we have to set them again...
    else ; due to an address range limitation I could work around but don't think is worth doing so:
	message "Warning: using pre-assembled Z80 startup code."
	dc.w $AF01,$D91F,$1127,$0021,$2600,$F977,$EDB0,$DDE1,$FDE1,$ED47,$ED4F,$D1E1,$F108,$D9C1,$D1E1,$F1F9,$F3ED,$5636,$E9E9
    endif

		dc.w $8104		; VDP display mode
		dc.w $8F02		; VDP increment
		dc.l $C0000000		; CRAM write mode
		dc.l $40000010		; VSRAM address 0

		dc.b $9F, $BF, $DF, $FF	; values for PSG channel volumes
; ===========================================================================

GameProgram:
		tst.w	(vdp_control_port).l
		btst	#6,(z80_expansion_control+1).l
		beq.s	CheckSumCheck
		cmpi.l	#'init',(v_init).w ; has checksum routine already run?
		beq.w	GameInit	; if yes, branch

CheckSumCheck: ; FASTER CHECKSUM CHECK BY MARKEYJESTER
		movea.w	#$0200,a0				; prepare start address
		move.l	(RomEndLoc).w,d7		; load size
		sub.l	a0,d7					; minus start address
		move.b	d7,d5					; copy end nybble
		andi.w	#$000F,d5				; get only the remaining nybble
		lsr.l	#$04,d7					; divide the size by 20
		move.w	d7,d6					; load lower word size
		swap	d7						; get upper word size
		moveq	#$00,d0					; clear d0

CS_MainBlock:
		add.w	(a0)+,d0				; modular checksum (8 words)
		add.w	(a0)+,d0				; ''
		add.w	(a0)+,d0				; ''
		add.w	(a0)+,d0				; ''
		add.w	(a0)+,d0				; ''
		add.w	(a0)+,d0				; ''
		add.w	(a0)+,d0				; ''
		add.w	(a0)+,d0				; ''
		dbf		d6,CS_MainBlock			; repeat until all main block sections are done
		dbf		d7,CS_MainBlock			; ''
		subq.w	#$01,d5					; decrease remaining nybble for dbf
		bpl.s	CS_Finish				; if there is no remaining nybble, branch

CS_Remains:
		add.w	(a0)+,d0				; add remaining words
		dbf		d5,CS_Remains			; repeat until the remaining words are done

CS_Finish:
;		cmp.w	(Checksum).w,d0			; does the checksum match?
;		bne.w	CheckSumError			; if not, branch

CheckSumOk:
		lea		(v_crossresetram).w,a6
		moveq	#0,d7
		move.w	#(v_ram_end-v_crossresetram)/4-1,d6
.clearRAM:
		move.l	d7,(a6)+
		dbf	d6,.clearRAM	; clear RAM ($FE00-$FFFF)

		move.b	(z80_version).l,d0
		andi.b	#$C0,d0
		move.b	d0,(v_megadrive).w ; get region setting
		move.l	#'init',(v_init).w ; set flag so checksum won't run again

GameInit:
		lea	(v_ram_start&$FFFFFF).l,a6
		moveq	#0,d7
		move.w	#(v_crossresetram-v_ram_start)/4-1,d6
.clearRAM:
		move.l	d7,(a6)+
		dbf	d6,.clearRAM					; clear RAM ($0000-$FDFF)

		jsr 	(InitDMAQueue).l			; Flamewing Ultra DMA Queue
		bsr.w	VDPSetupGame
		bsr.w	DACDriverLoad
		bsr.w	JoypadInit
		move.b	#id_Sega,(v_gamemode).w		; set Game Mode to Sega Screen

	if SaveProgressMod=1
InitSRAM:
		clr.b	(v_sram_errorcode).w		; Clear the SRAM error code
		gotoSRAM							; Enable SRAM writing
	if AddressSRAM=3
		; no need to change this by yourself anymore -- Starleaf
		lea 	($200001).l,a0				; Load SRAM memory into a0
	else
		lea		($200000).l,a0				; Load SRAM memory into a0
	endif

		; Check for SRAM signature
		movep.l 0(a0),d0					; Get the existing string at the start of SRAM
		move.l  #"SRAM",d1					; Load "SRAM" signature
		cmp.l   d0,d1						; Compare with existing data
		beq.s   .skip						; If it matches, skip initialization

		; Write and verify "SRAM" signature
		movep.l d1,0(a0)					; Write string "SRAM"
		movep.l 0(a0),d0					; Read back for verification
		cmp.l   d0,d1						; Compare written value
		bne.s   .errorHandler				; Branch if verification failed

	.skip:
		; Here is where you initialize values like lives or level.
		; If you're using word or long values, you can only use every other byte.
		; Example - 8(a0) => $A(a0)
		lea		8(a0),a0					; Base of usable SRAM

		; Check for save data initialization
		cmpi.b	#1,sram_init(a0)			; Check initialization flag
		bne.s	.newData					; If not initialized, branch to set up
		bra.s	.stopsram					; If save data exists, skip initialization

	.errorHandler:
		move.b	#1,(v_sram_errorcode).w		; Set error code

	.newData:
		moveq	#0,d0						; Clear default values
		move.b	#1,sram_init(a0)			; Mark SRAM initialized
		movep.w	d0,sram_zone(a0)			; clear saved zone and act
		movep.l	d0,sram_score(a0)			; clear saved score
		move.b	d0,sram_lastspecial(a0)		; clear saved special stage number
		movep.w	d0,sram_emeralds(a0)		; clear saved emerald count and bitfield
		move.b	d0,sram_continues(a0)		; clear saved continues
		move.b	#3,sram_lives(a0)			; reset saved lives count
		move.l	#5000,d0
		movep.l	d0,sram_scorelife(a0)		; reset saved extra life target score
;		bra.s	.finishsram

	.stopsram:
		; **load data such as options/settings here**

;	.finishsram:
        gotoROM								; Disable SRAM writing
;		bra.s	MainGameLoop				; Continue to main loop
	endif

MainGameLoop:
		moveq	#0,d0						; clear d0 before using it w/ the new Game Mode system to avoid bugs
		move.b	(v_gamemode).w,d0			; load Game Mode
	if (NewLevelSelect|SaveProgressMod)
		cmpi.b	#$24,d0						; limit Game Mode value to $24 max
		ble.s	.dontcap
		clr.b	d0
	.dontcap:
	else
		andi.w	#$1C,d0						; limit Game Mode value to $1C max
	endif
		movea.l	GameModeArray(pc,d0.w),a0	; load location of game mode to a0
		jsr		(a0)						; jump to apt location in ROM -- RetroKoH S3K Game Mode Array
		bra.s	MainGameLoop				; loop indefinitely
; ===========================================================================
; ---------------------------------------------------------------------------
; Main game mode array -- RetroKoH S3K Game Mode Array
; ---------------------------------------------------------------------------

GameModeArray:

ptr_GM_Sega:		dc.l	GM_Sega			; Sega Screen ($00)
ptr_GM_Title:		dc.l	GM_Title		; Title	Screen ($04)
ptr_GM_Demo:		dc.l	GM_Level		; Demo Mode ($08)
ptr_GM_Level:		dc.l	GM_Level		; Normal Level ($0C)
ptr_GM_Special:		dc.l	GM_Special		; Special Stage	($10)
ptr_GM_Cont:		dc.l	GM_Continue		; Continue Screen ($14)
ptr_GM_Ending:		dc.l	GM_Ending		; End of game sequence ($18)
ptr_GM_Credits:		dc.l	GM_Credits		; Credits ($1C)

	if NewLevelSelect
ptr_GM_MenuScreen:	dc.l	GM_MenuScreen	; NEW Sonic 2 style Level Select ($20)
	endif

	if SaveProgressMod
ptr_GM_SRAMError:	dc.l	GM_SRAMError	; SRAM Error Screen ($20/$24)
	endif
; ===========================================================================

CheckSumError:
		bsr.w	VDPSetupGame
		move.l	#$C0000000,(vdp_control_port).l ; set VDP to CRAM write
		moveq	#$3F,d7

.fillred:
		move.w	#cRed,(vdp_data_port).l ; fill palette with red
		dbf	d7,.fillred	; repeat $3F more times

.endlessloop:
		bra.s	.endlessloop
; ===========================================================================

; Soulless Sentinel Level Select ASCII Mod
Art_Text:		binclude	"artunc/Menu Text.bin" ; text used in level select and debug mode
Art_Text_End:	even

; ===========================================================================
; ---------------------------------------------------------------------------
; Vertical interrupt
; ---------------------------------------------------------------------------

VBlank:
		movem.l	d0-a6,-(sp)
		tst.b	(v_vbla_routine).w
		beq.s	VBla_00
		move.w	(vdp_control_port).l,d0
		move.l	#$40000010,(vdp_control_port).l
		move.l	(v_scrposy_vdp).w,(vdp_data_port).l ; send screen y-axis pos. to VSRAM
		btst	#6,(v_megadrive).w ; is Megadrive PAL?
		beq.s	.notPAL		; if not, branch

		move.w	#$700,d0
.waitPAL:
		dbf		d0,.waitPAL ; wait here in a loop doing nothing for a while...

.notPAL:
		move.b	(v_vbla_routine).w,d0
		move.b	#0,(v_vbla_routine).w
		move.w	#1,(f_hbla_pal).w
		andi.w	#$3E,d0
		move.w	VBla_Index(pc,d0.w),d0
		jsr		VBla_Index(pc,d0.w)

VBla_Music:
		jsr		(UpdateMusic).l

VBla_Exit:
		addq.l	#1,(v_vbla_count).w
		movem.l	(sp)+,d0-a6
		rte
; ===========================================================================
VBla_Index:		offsetTable
		offsetTableEntry.w	VBla_00
		offsetTableEntry.w	VBla_02
		offsetTableEntry.w	VBla_04
		offsetTableEntry.w	VBla_06
		offsetTableEntry.w	VBla_08
		offsetTableEntry.w	VBla_0A
		offsetTableEntry.w	VBla_0C
		offsetTableEntry.w	VBla_0E
		offsetTableEntry.w	VBla_10
		offsetTableEntry.w	VBla_12
		offsetTableEntry.w	VBla_14
		offsetTableEntry.w	VBla_16
		offsetTableEntry.w	VBla_0C
; ===========================================================================

VBla_00:
		cmpi.b	#$80+id_Level,(v_gamemode).w
		beq.s	.islevel
		cmpi.b	#id_Level,(v_gamemode).w ; is game on a level?
		bne.s	VBla_Music	; if not, branch

.islevel:
		cmpi.b	#id_LZ,(v_zone).w ; is level LZ ?
		bne.s	VBla_Music	; if not, branch

		move.w	(vdp_control_port).l,d0
		btst	#6,(v_megadrive).w ; is Megadrive PAL?
		beq.s	.notPAL		; if not, branch

		move.w	#$700,d0
.waitPAL:
		dbf		d0,.waitPAL

.notPAL:
		move.w	#1,(f_hbla_pal).w ; set HBlank flag
		stopZ80
		waitZ80
		tst.b	(f_wtr_state).w	; is water above top of screen?
		bne.s	.waterabove 	; if yes, branch

		writeCRAM	v_palette,0
		bra.s	.waterbelow

.waterabove:
		writeCRAM	v_palette_water,0

.waterbelow:
		move.w	(v_hbla_hreg).w,(a5)
		startZ80
		; instead of branching back to VBla_Music, call directly.
		jsr		(UpdateMusic).l
		addq.l	#1,(v_vbla_count).w
		movem.l	(sp)+,d0-a6
		rte
; ===========================================================================

VBla_02:
		bsr.w	sub_106E

VBla_14:
		tst.w	(v_demolength).w
		beq.w	.end
		subq.w	#1,(v_demolength).w

.end:
		rts	
; ===========================================================================

VBla_04:
		bsr.w	sub_106E
		bsr.w	LoadTilesAsYouMove_BGOnly
		bsr.w	sub_1642
		tst.w	(v_demolength).w
		beq.w	.end
		subq.w	#1,(v_demolength).w

.end:
		rts	
; ===========================================================================

VBla_06:
		bsr.w	sub_106E
		rts	
; ===========================================================================

VBla_10:
		cmpi.b	#id_Special,(v_gamemode).w ; is game on special stage?
		beq.w	VBla_0A		; if yes, branch

VBla_08:
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w
		bne.s	.waterabove

		writeCRAM	v_palette,0
		bra.s	.waterbelow

.waterabove:
		writeCRAM	v_palette_water,0

.waterbelow:
		move.w	(v_hbla_hreg).w,(a5)

		writeVRAM	v_hscrolltablebuffer,vram_hscroll
		writeVRAM	v_spritetablebuffer,vram_sprites

		bsr.w		ProcessDMAQueue	; Mercury Use DMA Queue

		startZ80
		movem.l	(v_screenposx).w,d0-d7
		movem.l	d0-d7,(v_screenposx_dup).w
		movem.l	(v_fg_scroll_flags).w,d0-d1
		movem.l	d0-d1,(v_fg_scroll_flags_dup).w
		cmpi.b	#96,(v_hbla_line).w
		bhs.s	Demo_Time
		move.b	#1,(f_doupdatesinhblank).w
		addq.l	#4,sp
		bra.w	VBla_Exit

; ---------------------------------------------------------------------------
; Subroutine to	run a demo for an amount of time
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Demo_Time:
		bsr.w	LoadTilesAsYouMove
	;	jsr		(AnimateLevelGfx).l
		jsr		(HUD_Update).l
		bsr.w	ProcessDPLC2
		tst.w	(v_demolength).w ; is there time left on the demo?
		beq.w	.end		; if not, branch
		subq.w	#1,(v_demolength).w ; subtract 1 from time left

.end:
		rts	
; End of function Demo_Time

; ===========================================================================

VBla_0A:
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		writeCRAM	v_palette,0
		writeVRAM	v_spritetablebuffer,vram_sprites
		writeVRAM	v_hscrolltablebuffer,vram_hscroll
		startZ80
		bsr.w	PalCycle_SS
		
		bsr.w	ProcessDMAQueue	; Mercury Use DMA Queue

	if DynamicSpecialStageWalls=1 ; Mercury Dynamic Special Stage Walls
		cmpi.b	#96,(v_hbla_line).w
		bcc.s	.update
		bra.s	.end
		
.update:
		jsr		(SS_LoadWalls).l

	if HUDInSpecialStage=1	; Mercury HUD in Special Stage
		jsr		(HUD_Update_SS).l
	endif	; HUD in Special Stage End
	endif	; Dynamic Special Stage Walls End

		tst.w	(v_demolength).w	; is there time left on the demo?
		beq.s	.end				; if not, return
		subq.w	#1,(v_demolength).w	; subtract 1 from time left in demo

.end:
		rts	
; ===========================================================================

VBla_0C:
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w
		bne.s	.waterabove

		writeCRAM	v_palette,0
		bra.s	.waterbelow

.waterabove:
		writeCRAM	v_palette_water,0

.waterbelow:
		move.w	(v_hbla_hreg).w,(a5)
		writeVRAM	v_hscrolltablebuffer,vram_hscroll
		writeVRAM	v_spritetablebuffer,vram_sprites
		
		bsr.w	ProcessDMAQueue	; Mercury Use DMA Queue

		startZ80
		movem.l	(v_screenposx).w,d0-d7
		movem.l	d0-d7,(v_screenposx_dup).w
		movem.l	(v_fg_scroll_flags).w,d0-d1
		movem.l	d0-d1,(v_fg_scroll_flags_dup).w
		bsr.w	LoadTilesAsYouMove
	;	jsr		(AnimateLevelGfx).l
		jsr		(HUD_Update).l
		bra.w	sub_1642
; ===========================================================================

VBla_0E:
		bsr.w	sub_106E
		addq.b	#1,(v_vbla_0e_counter).w ; Unused besides this one write...
		move.b	#$E,(v_vbla_routine).w
		rts	
; ===========================================================================

VBla_12:
		bsr.w	sub_106E
		move.w	(v_hbla_hreg).w,(a5)
		bra.w	sub_1642
; ===========================================================================

VBla_16:
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		writeCRAM	v_palette,0
		writeVRAM	v_spritetablebuffer,vram_sprites
		writeVRAM	v_hscrolltablebuffer,vram_hscroll
		startZ80

		bsr.w	ProcessDMAQueue	; Mercury Use DMA Queue

	if DynamicSpecialStageWalls=1 ; Mercury Dynamic Special Stage Walls
		cmpi.b	#96,(v_hbla_line).w
		bcc.s	.update
		bra.s	.end
		
.update:
		jsr		(SS_LoadWalls).l
	if HUDInSpecialStage=1	; Mercury HUD in Special Stage
		jsr		(HUD_Update_SS).l
	endif	; HUD in Special Stage End
	endif	; Dynamic Special Stage Walls End

		tst.w	(v_demolength).w
		beq.s	.end
		subq.w	#1,(v_demolength).w

.end:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_106E:
		stopZ80
		waitZ80
		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w ; is water above top of screen?
		bne.s	.waterabove	; if yes, branch
		writeCRAM	v_palette,0
		bra.s	.waterbelow

.waterabove:
		writeCRAM	v_palette_water,0

.waterbelow:
		writeVRAM	v_spritetablebuffer,vram_sprites
		writeVRAM	v_hscrolltablebuffer,vram_hscroll
		startZ80
		
		bra.w		ProcessDMAQueue	; Mercury Use DMA Queue
		
		rts	
; End of function sub_106E

; ---------------------------------------------------------------------------
; Horizontal interrupt
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


HBlank:
		disable_ints
		tst.w	(f_hbla_pal).w			; is palette set to change?
		beq.s	.nochg					; if not, branch
		move.w	#0,(f_hbla_pal).w
		movem.l	a0-a1,-(sp)
		lea		(vdp_data_port).l,a1
		lea		(v_palette_water).w,a0	; get palette from RAM
		move.l	#$C0000000,4(a1)		; set VDP to CRAM write

		rept 32
			move.l	(a0)+,(a1)			; move palette to CRAM
		endm

		move.w	#$8A00+223,4(a1)		; reset HBlank register
		movem.l	(sp)+,a0-a1
		tst.b	(f_doupdatesinhblank).w
		bne.s	loc_119E

.nochg:
		rte	
; ===========================================================================

loc_119E:
		move.b	#0,(f_doupdatesinhblank).w
		movem.l	d0-a6,-(sp)
		bsr.w	Demo_Time
		jsr		(UpdateMusic).l
		movem.l	(sp)+,d0-a6
		rte	
; End of function HBlank

; ---------------------------------------------------------------------------
; Subroutine to	initialise joypads
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


JoypadInit:
		stopZ80
		waitZ80
		moveq	#$40,d0
		move.b	d0,(z80_port_1_control+1).l		; init port 1 (joypad 1)
		move.b	d0,(z80_port_2_control+1).l		; init port 2 (joypad 2)
		move.b	d0,(z80_expansion_control+1).l	; init port 3 (expansion/extra)
		startZ80
		rts	
; End of function JoypadInit

; ---------------------------------------------------------------------------
; Subroutine to	read joypad input, and send it to the RAM
; ---------------------------------------------------------------------------
; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ReadJoypads:
		lea		(v_jpadhold1).w,a0			; address where joypad states are written
		lea		(z80_port_1_data+1).l,a1	; first	joypad port
		bsr.s	.read						; do the first joypad
		addq.w	#2,a1						; do the second	joypad

.read:
		move.b	#0,(a1)						; poll joypad data port
		nop	
		nop	
		move.b	(a1),d0						; get joypad port data (start/A)
		asl.b	#2,d0
		move.b	#$40,(a1)					; poll joypad data port again
		andi.w	#$C0,d0
		move.b	(a1),d1						; get joypad port data (B/C/Dpad)
		andi.w	#$3F,d1
		or.b	d1,d0						; fuse together into one joypad bit array
		not.b	d0
		move.b	(a0),d1						; get press button data
		eor.b	d0,d1						; toggle off buttons that are being held
		move.b	d0,(a0)+					; put raw joypad input (for held buttons) in F604/F606
		and.b	d0,d1
		move.b	d1,(a0)+					; put pressed controller input in F605/F607
		rts	
; End of function ReadJoypads


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


VDPSetupGame:
		lea		(vdp_control_port).l,a0
		lea		(vdp_data_port).l,a1
		lea		VDPSetupArray(pc),a2
		moveq	#$12,d7

.setreg:
		move.w	(a2)+,(a0)
		dbf		d7,.setreg								; set the VDP registers

		move.w	VDPSetupArray+2(pc),(v_vdp_buffer1).w	; Saves 8 cycles
		move.w	#$8A00+223,(v_hbla_hreg).w				; H-INT every 224th scanline
		moveq	#0,d0
		move.l	#$C0000000,(vdp_control_port).l			; set VDP to CRAM write
		moveq	#$1F,d7

.clrCRAM:
		move.l	d0,(a1)									; clear longwords instead of words (384 cycles vs. 512)
		dbf		d7,.clrCRAM								; clear	the CRAM

		clr.l	(v_scrposy_vdp).w
		clr.l	(v_scrposx_vdp).w
		move.l	d1,-(sp)
		fillVRAM	0,0,$10000							; clear the entirety of VRAM
		move.l	(sp)+,d1
		rts	
; End of function VDPSetupGame

; ===========================================================================
VDPSetupArray:
		dc.w $8004		; 8-colour mode
		dc.w $8134		; enable V.interrupts, enable DMA
		dc.w $8200+(vram_fg>>10) ; set foreground nametable address
		dc.w $8300+($A000>>10)	; set window nametable address
		dc.w $8400+(vram_bg>>13) ; set background nametable address
		dc.w $8500+(vram_sprites>>9) ; set sprite table address
		dc.w $8600		; unused
		dc.w $8700		; set background colour (palette entry 0)
		dc.w $8800		; unused
		dc.w $8900		; unused
		dc.w $8A00		; default H.interrupt register
		dc.w $8B00		; full-screen vertical scrolling
		dc.w $8C81		; 40-cell display mode
		dc.w $8D00+(vram_hscroll>>10) ; set background hscroll address
		dc.w $8E00		; unused
		dc.w $8F02		; set VDP increment size
		dc.w $9001		; 64-cell hscroll size
		dc.w $9100		; window horizontal position
		dc.w $9200		; window vertical position

; ---------------------------------------------------------------------------
; Subroutine to	clear the screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ClearScreen:
		fillVRAM	0, vram_fg, vram_fg+plane_size_64x32 ; clear foreground namespace
		fillVRAM	0, vram_bg, vram_bg+plane_size_64x32 ; clear background namespace

		clr.l	(v_scrposy_vdp).w
		clr.l	(v_scrposx_vdp).w

		; Fixed
		clearRAM v_spritetablebuffer
		clearRAM v_hscrolltablebuffer,v_hscrolltablebuffer_end_padded

		rts	
; End of function ClearScreen

; ---------------------------------------------------------------------------
; Subroutine to load the DAC driver
; ---------------------------------------------------------------------------
; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; SoundDriverLoad:
DACDriverLoad:
		nop	
		stopZ80
		resetZ80
		lea	(DACDriver).l,a0	; load DAC driver
		lea	(z80_ram).l,a1		; target Z80 RAM
		bsr.w	KosDec			; decompress
		resetZ80a
		nop	
		nop	
		nop	
		nop	
		resetZ80
		startZ80
		rts	
; End of function DACDriverLoad

		include	"_incObj/sub PlaySound.asm"
		include	"_inc/PauseGame.asm"

; ---------------------------------------------------------------------------
; Subroutine to	copy a tile map from RAM to VRAM namespace

; input:
;	a1 = tile map address
;	d0 = VRAM address
;	d1 = width (cells)
;	d2 = height (cells)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


TilemapToVRAM:
		lea		(vdp_data_port).l,a6
		move.l	#$800000,d4

Tilemap_Line:
		move.l	d0,4(a6)			; move d0 to VDP_control_port
		move.w	d1,d3

Tilemap_Cell:
		move.w	(a1)+,(a6)			; write value to namespace
		dbf		d3,Tilemap_Cell		; next tile
		add.l	d4,d0				; goto next line
		dbf		d2,Tilemap_Line		; next line
		rts	
; End of function TilemapToVRAM

		include	"_inc/DMA Queue.asm"
		include	"_inc/Nemesis Decompression.asm"


; ---------------------------------------------------------------
; uncompressed art to VRAM loader -- AURORA☆FIELDS Title Card Optimization
; ---------------------------------------------------------------
; INPUT:
;       a0      - Source Offset
;       d0      - length in tiles
; ---------------------------------------------------------------
LoadUncArt:
		disable_ints
		lea		$C00000.l,a6    ; get VDP data port

LoadArt_Loop:
		move.l	(a0)+,(a6)		; transfer 4 bytes
		move.l	(a0)+,(a6)		; transfer 4 more bytes
		move.l	(a0)+,(a6)		; and so on and so forth
		move.l	(a0)+,(a6)		;
		move.l	(a0)+,(a6)		;
		move.l	(a0)+,(a6)		;
		move.l	(a0)+,(a6)		; in total transfer 32 bytes
		move.l	(a0)+,(a6)		; which is 1 full tile

		dbf		d0,LoadArt_Loop	; loop until d0 = 0
		enable_ints
		rts
; ===========================================================================


; ---------------------------------------------------------------------------
; Subroutine to load pattern load cues (aka to queue pattern load requests)
; ---------------------------------------------------------------------------

; ARGUMENTS
; d0 = index of PLC list
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; LoadPLC:
AddPLC:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1		; jump to relevant PLC
		lea	(v_plc_buffer).w,a2 ; PLC buffer space

.findspace:
		tst.l	(a2)		; is space available in RAM?
		beq.s	.copytoRAM	; if yes, branch
		addq.w	#6,a2		; if not, try next space
		bra.s	.findspace
; ===========================================================================

.copytoRAM:
		move.w	(a1)+,d0	; get length of PLC
		bmi.s	.skip

.loop:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+	; copy PLC to RAM
		dbf	d0,.loop	; repeat for length of PLC

.skip:
		movem.l	(sp)+,a1-a2 ; a1=object
		rts	
; End of function AddPLC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; Queue pattern load requests, but clear the PLQ first

; ARGUMENTS
; d0 = index of PLC list (see ArtLoadCues)

; NOTICE: This subroutine does not check for buffer overruns. The programmer
;	  (or hacker) is responsible for making sure that no more than
;	  16 load requests are copied into the buffer.
;	  _________DO NOT PUT MORE THAN 16 LOAD REQUESTS IN A LIST!__________
;         (or if you change the size of Plc_Buffer, the limit becomes (Plc_Buffer_Only_End-Plc_Buffer)/6)

; LoadPLC2:
NewPLC:
		movem.l	a1-a2,-(sp)
		lea		(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea		(a1,d0.w),a1	; jump to relevant PLC
		bsr.s	ClearPLC		; erase any data in PLC buffer space
		lea		(v_plc_buffer).w,a2
		move.w	(a1)+,d0		; get length of PLC
		bmi.s	.skip			; if it's negative, skip the next loop

.loop:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+		; copy PLC to RAM
		dbf		d0,.loop		; repeat for length of PLC

.skip:
		movem.l	(sp)+,a1-a2
		rts	
; End of function NewPLC

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; ---------------------------------------------------------------------------
; Subroutine to	clear the pattern load cues
; ---------------------------------------------------------------------------

; Clear the pattern load queue ($FFF680 - $FFF700)
; RetroKoH/Devon Optimization: Clears in blocks w/ d0 instead of .clr

ClearPLC:
		lea		(v_plc_buffer).w,a2	; PLC buffer space in RAM
		moveq	#0,d0
		moveq	#(v_plc_buffer_end-v_plc_buffer)/$10-1,d1

.loop:
		move.l	d0,(a2)+
		move.l	d0,(a2)+
		move.l	d0,(a2)+
		move.l	d0,(a2)+
		dbf		d1,.loop
		rts	
; End of function ClearPLC

; ---------------------------------------------------------------------------
; Subroutine to	use graphics listed in a pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RunPLC:
		tst.l	(v_plc_buffer).w
		beq.s	Rplc_Exit
		tst.w	(v_plc_patternsleft).w
		bne.s	Rplc_Exit
		movea.l	(v_plc_buffer).w,a0
		lea		NemDec_WriteRowToVDP(pc),a3
		lea		(v_ngfx_buffer).w,a1
		move.w	(a0)+,d2
		bpl.s	loc_160E
		adda.w	#$A,a3

loc_160E:
		andi.w	#$7FFF,d2
		bsr.w	NemDec4
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6
		moveq	#0,d0
		move.l	a0,(v_plc_buffer).w
		move.l	a3,(v_plc_ptrnemcode).w
		move.l	d0,(v_plc_repeatcount).w
		move.l	d0,(v_plc_paletteindex).w
		move.l	d0,(v_plc_previousrow).w
		move.l	d5,(v_plc_dataword).w
		move.l	d6,(v_plc_shiftvalue).w
		move.w	d2,(v_plc_patternsleft).w	; FraGag Fix Race Condition w/ PLCs

Rplc_Exit:
		rts	
; End of function RunPLC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_1642:
		tst.w	(v_plc_patternsleft).w
		beq.s	Rplc_Exit
		move.w	#9,(v_plc_framepatternsleft).w
		moveq	#0,d0
		move.w	(v_plc_buffer+4).w,d0
		addi.w	#$120,(v_plc_buffer+4).w
		bra.s	loc_1676
; End of function sub_1642


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


; sub_165E:
ProcessDPLC2:
		tst.w	(v_plc_patternsleft).w
		beq.s	locret_16DA
		move.w	#3,(v_plc_framepatternsleft).w
		moveq	#0,d0
		move.w	(v_plc_buffer+4).w,d0
		addi.w	#$60,(v_plc_buffer+4).w

loc_1676:
		lea	(vdp_control_port).l,a4
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(a4)
		subq.w	#4,a4
		movea.l	(v_plc_buffer).w,a0
		movea.l	(v_plc_ptrnemcode).w,a3
		move.l	(v_plc_repeatcount).w,d0
		move.l	(v_plc_paletteindex).w,d1
		move.l	(v_plc_previousrow).w,d2
		move.l	(v_plc_dataword).w,d5
		move.l	(v_plc_shiftvalue).w,d6
		lea	(v_ngfx_buffer).w,a1

loc_16AA:
		movea.w	#8,a5
		bsr.w	NemDec3
		subq.w	#1,(v_plc_patternsleft).w
		beq.s	loc_16DC
		subq.w	#1,(v_plc_framepatternsleft).w
		bne.s	loc_16AA
		move.l	a0,(v_plc_buffer).w
		move.l	a3,(v_plc_ptrnemcode).w
		move.l	d0,(v_plc_repeatcount).w
		move.l	d1,(v_plc_paletteindex).w
		move.l	d2,(v_plc_previousrow).w
		move.l	d5,(v_plc_dataword).w
		move.l	d6,(v_plc_shiftvalue).w

locret_16DA:
		rts	
; ===========================================================================

loc_16DC:
	; Vladikcomper Pattern Load Cues Queue Shifting Bug fix
		lea		(v_plc_buffer).w,a0
		lea 	6(a0),a1
		moveq   #$E,d0		; do $F cues
 
loc_16E2:
		move.l  (a1)+,(a0)+
		move.w  (a1)+,(a0)+
		dbf 	d0,loc_16E2

		moveq   #0,d0
		move.l  d0,(a0)+	; clear the last cue to avoid overcopying it
		move.w  d0,(a0)+	;
		rts
	; Pattern Load Cues Queue Shifting Bug Fix End
; End of function ProcessDPLC2

; ---------------------------------------------------------------------------
; Subroutine to	execute	the pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


QuickPLC:
		lea	(ArtLoadCues).l,a1 ; load the PLC index
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		move.w	(a1)+,d1	; get length of PLC

Qplc_Loop:
		movea.l	(a1)+,a0	; get art pointer
		moveq	#0,d0
		move.w	(a1)+,d0	; get VRAM address
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(vdp_control_port).l ; converted VRAM address to VDP format
		bsr.w	NemDec		; decompress
		dbf	d1,Qplc_Loop	; repeat for length of PLC
		rts	
; End of function QuickPLC

		include	"_inc/Enigma Decompression.asm"
		include	"_inc/Kosinski Decompression.asm"
		include "_inc/Comper Decompression.asm"		; New format ready for use -- Vladikcomper

		include	"_inc/PaletteCycle.asm"

; Title Screen Cycling Palette Removed. Use GHZ's instead. -- RetroKoH Title Screen Adjustment
Pal_GHZCyc:		binclude	"palette/Cycle - GHZ.bin"
Pal_LZCyc1:		binclude	"palette/Cycle - LZ Waterfall.bin"
Pal_LZCyc2:		binclude	"palette/Cycle - LZ Conveyor Belt.bin"
Pal_LZCyc3:		binclude	"palette/Cycle - LZ Conveyor Belt Underwater.bin"
Pal_SBZ3Cyc:	binclude	"palette/Cycle - SBZ3 Waterfall.bin"
Pal_MZCyc:		binclude	"palette/Cycle - MZ (Unused).bin"
Pal_SLZCyc:		binclude	"palette/Cycle - SLZ.bin"
Pal_SYZCyc1:	binclude	"palette/Cycle - SYZ1.bin"
Pal_SYZCyc2:	binclude	"palette/Cycle - SYZ2.bin"

		include	"_inc/SBZ Palette Scripts.asm"

Pal_SBZCyc1:	binclude	"palette/Cycle - SBZ 1.bin"
Pal_SBZCyc2:	binclude	"palette/Cycle - SBZ 2.bin"
Pal_SBZCyc3:	binclude	"palette/Cycle - SBZ 3.bin"
Pal_SBZCyc4:	binclude	"palette/Cycle - SBZ 4.bin"
Pal_SBZCyc5:	binclude	"palette/Cycle - SBZ 5.bin"
Pal_SBZCyc6:	binclude	"palette/Cycle - SBZ 6.bin"
Pal_SBZCyc7:	binclude	"palette/Cycle - SBZ 7.bin"
Pal_SBZCyc8:	binclude	"palette/Cycle - SBZ 8.bin"
Pal_SBZCyc9:	binclude	"palette/Cycle - SBZ 9.bin"
Pal_SBZCyc10:	binclude	"palette/Cycle - SBZ 10.bin"

	; These will contain various sets of fading effects.
	; Full fade to/from black by MarkeyJester
	; Full fade to/from white by RetroKoH
	; Other fading color effects by RetroKoH
		include "_inc/PaletteFadeIn.asm"
		include "_inc/PaletteFadeOut.asm"
		include "_inc/PaletteFadeWhiteIn.asm"	; PaletteWhiteIn: (Special Stage Fade Out)
		include "_inc/PaletteFadeWhiteOut.asm"	; PaletteWhiteOut: (Special Stage Fade Out)

; ---------------------------------------------------------------------------
; Palette cycling routine - Sega logo
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_Sega:
		tst.b	(v_pcyc_time+1).w
		bne.s	loc_206A
		lea	(v_palette+$20).w,a1
		lea	(Pal_Sega1).l,a0
		moveq	#5,d1
		move.w	(v_pcyc_num).w,d0

loc_2020:
		bpl.s	loc_202A
		addq.w	#2,a0
		subq.w	#1,d1
		addq.w	#2,d0
		bra.s	loc_2020
; ===========================================================================

loc_202A:
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_2034
		addq.w	#2,d0

loc_2034:
		cmpi.w	#$60,d0
		bhs.s	loc_203E
		move.w	(a0)+,(a1,d0.w)

loc_203E:
		addq.w	#2,d0
		dbf	d1,loc_202A

		move.w	(v_pcyc_num).w,d0
		addq.w	#2,d0
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_2054
		addq.w	#2,d0

loc_2054:
		cmpi.w	#$64,d0
		blt.s	loc_2062
		move.w	#$401,(v_pcyc_time).w
		moveq	#-$C,d0

loc_2062:
		move.w	d0,(v_pcyc_num).w
		moveq	#1,d0
		rts	
; ===========================================================================

loc_206A:
		subq.b	#1,(v_pcyc_time).w
		bpl.s	loc_20BC
		move.b	#4,(v_pcyc_time).w
		move.w	(v_pcyc_num).w,d0
		addi.w	#$C,d0
		cmpi.w	#$30,d0
		blo.s	loc_2088
		moveq	#0,d0
		rts	
; ===========================================================================

loc_2088:
		move.w	d0,(v_pcyc_num).w
		lea	(Pal_Sega2).l,a0
		lea	(a0,d0.w),a0
		lea	(v_palette+$04).w,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.w	(a0)+,(a1)
		lea	(v_palette+$20).w,a1
		moveq	#0,d0
		moveq	#$2C,d1

loc_20A8:
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_20B2
		addq.w	#2,d0

loc_20B2:
		move.w	(a0),(a1,d0.w)
		addq.w	#2,d0
		dbf	d1,loc_20A8

loc_20BC:
		moveq	#1,d0
		rts	
; End of function PalCycle_Sega

; ===========================================================================

Pal_Sega1:	binclude	"palette/Sega1.bin"
Pal_Sega2:	binclude	"palette/Sega2.bin"

; ---------------------------------------------------------------------------
; Subroutines to load palettes

; input:
;	d0 = index number for palette
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; PalLoad1:
PalLoad_Fade:
		lea		(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		adda.w	#v_palette_fading-v_palette,a3		; skip to "main" RAM address
		move.w	(a1)+,d7	; get length of palette data

.loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf		d7,.loop
		rts	
; End of function PalLoad_Fade


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; PalLoad2:
PalLoad:
		lea		(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		move.w	(a1)+,d7	; get length of palette

.loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf		d7,.loop
		rts	
; End of function PalLoad

	if SuperMod=1
; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; Used to load in proper flower colors to overwrite the cyan emerald colors.

PalLoad_EndFlowers:
		lea		Pal_EndFlowers,a2		; get palette data address
		lea		v_palette_fading+$2C,a3	; get target RAM address
		move.l	(a2)+,(a3)+				; move data to RAM
		move.l	(a2)+,(a3)+				; don't need to loop for two moves
		rts	
; End of function PalLoad_EndFlowers
	endif

; ---------------------------------------------------------------------------
; Underwater palette loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; PalLoad3_Water:
PalLoad_Fade_Water:
		lea		(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		suba.w	#v_palette-v_palette_water,a3		; skip to "main" RAM address
		move.w	(a1)+,d7	; get length of palette data

.loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf		d7,.loop
		rts	
; End of function PalLoad_Fade_Water


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; PalLoad4_Water:
PalLoad_Water:
		lea		(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		suba.w	#v_palette-v_palette_water_fading,a3
		move.w	(a1)+,d7	; get length of palette data

.loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf		d7,.loop
		rts	
; End of function PalLoad_Water

; ===========================================================================

	if DynamicPalettes
		include	"_inc/Palette Pointers - Dynamic Palettes.asm"
	else
		include	"_inc/Palette Pointers.asm"
	endif

; ---------------------------------------------------------------------------
; Palette data
; ---------------------------------------------------------------------------
bincludePalette macro path,{INTLABEL},{GLOBALSYMBOLS}
__LABEL__:	binclude	path
__LABEL___end:
	endm

	if FadeInSEGA=0
Pal_SegaBG:		bincludePalette	"palette/Sega Background.bin"
	endif

Pal_Title:		bincludePalette	"palette/Title Screen.bin"

	if NewLevelSelect
Pal_LevelSel:	bincludePalette	"palette/Level Select (S2).bin"
Pal_LevSelIcons:	include "palette/S2 Level Select/Icons.asm"
Pal_LevSelIcons_end:
	else
Pal_LevelSel:	bincludePalette	"palette/Level Select.bin"
	endif

; ---------------------------------------------------------------------------
	if ProtoSonicPalette
Pal_Sonic:		bincludePalette	"palette/Sonic - Proto.bin"
	else
Pal_Sonic:		bincludePalette	"palette/Sonic.bin"
	endif

	if GHZForeverPal
Pal_GHZ:		bincludePalette	"palette/Green Hill Zone - Forever.bin"
	else
Pal_GHZ:		bincludePalette	"palette/Green Hill Zone - Original.bin"
	endif

Pal_LZ:			bincludePalette	"palette/Labyrinth Zone.bin"
Pal_LZWater:	bincludePalette	"palette/Labyrinth Zone Underwater.bin"
Pal_MZ:			bincludePalette	"palette/Marble Zone.bin"
Pal_SLZ:		bincludePalette	"palette/Star Light Zone.bin"
Pal_SYZ:		bincludePalette	"palette/Spring Yard Zone.bin"
Pal_SBZ1:		bincludePalette	"palette/SBZ Act 1.bin"
Pal_SBZ2:		bincludePalette	"palette/SBZ Act 2.bin"
Pal_Special:	bincludePalette	"palette/Special Stage.bin"

	if NewSBZ3LevelArt
Pal_SBZ3:		bincludePalette	"palette/SBZ Act 3 - New.bin"
Pal_SBZ3Water:	bincludePalette	"palette/SBZ Act 3 Underwater - New.bin"
	else
Pal_SBZ3:		bincludePalette	"palette/SBZ Act 3.bin"
Pal_SBZ3Water:	bincludePalette	"palette/SBZ Act 3 Underwater.bin"
	endif

Pal_LZSonWater:	bincludePalette	"palette/Sonic - LZ Underwater.bin"
Pal_SBZ3SonWat:	bincludePalette	"palette/Sonic - SBZ3 Underwater.bin"
; ---------------------------------------------------------------------------

Pal_SSResult:	bincludePalette	"palette/Special Stage Results.bin"
Pal_Continue:	bincludePalette	"palette/Special Stage Continue Bonus.bin"

	if SuperMod=1
Pal_Ending:		bincludePalette	"palette/Ending - SuperMod.bin"
Pal_EndFlowers:	bincludePalette	"palette/Ending - SuperMod - Flowers.bin"
	else
Pal_Ending:		bincludePalette	"palette/Ending.bin"
	endif

; ---------------------------------------------------------------------------
; Subroutine to	wait for VBlank routines to complete
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


WaitForVBla:
		enable_ints

.wait:
		tst.b	(v_vbla_routine).w ; has VBlank routine finished?
		bne.s	.wait		; if not, branch
		rts	
; End of function WaitForVBla

		include	"_incObj/sub RandomNumber.asm"
		include	"_incObj/sub CalcSine.asm"
		include	"_incObj/sub CalcAngle.asm"

; ---------------------------------------------------------------------------
; Sega screen
; ---------------------------------------------------------------------------

GM_Sega:
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special			; stop music
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		lea		(vdp_control_port).l,a6
		move.w	#$8004,(a6)					; use 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6)	; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6)	; set background nametable address
		move.w	#$8700,(a6)					; set background colour (palette entry 0)
		move.w	#$8B00,(a6)					; full-screen vertical scrolling
		clr.b	(f_wtr_state).w
		disable_ints
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	ClearScreen
		locVRAM	ArtTile_Sega_Tiles*tile_size
		lea		(Nem_SegaLogo).l,a0			; load Sega	logo patterns
		bsr.w	NemDec
		lea		(v_128x128&$FFFFFF).l,a1
		lea		(Eni_SegaLogo).l,a0			; load Sega	logo mappings
		move.w	#make_art_tile(ArtTile_Sega_Tiles,0,FALSE),d0
		bsr.w	EniDec

		copyTilemap	v_128x128&$FFFFFF,vram_bg+$510,24,8
		copyTilemap	(v_128x128+24*8*2)&$FFFFFF,vram_fg,40,28

		tst.b   (v_megadrive).w									; is console Japanese?
		bmi.s   .loadpal
		copyTilemap	(v_128x128+$A40)&$FFFFFF,vram_fg+$53A,3,2	; hide "TM" with a white rectangle

.loadpal:
	; RetroKoH Fade In SEGA background
	if FadeInSEGA=1
		lea		(v_palette_fading).l,a3
		moveq	#$3F,d7

.loop:
		move.w	#cWhite,(a3)+	; move data to RAM
		dbf		d7,.loop

		bsr.w	PaletteFadeIn
	else
		moveq	#palid_SegaBG,d0
		bsr.w	PalLoad						; load Sega logo palette
	endif
	; Fade In SEGA Background End

		move.w	#-$A,(v_pcyc_num).w
		moveq	#0,d0
		move.w	d0,(v_pcyc_time).w
		move.w	d0,(v_pal_buffer+$12).w
		move.w	d0,(v_pal_buffer+$10).w
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l

Sega_WaitPal:
		move.b	#2,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	PalCycle_Sega
		bne.s	Sega_WaitPal

		move.b	#sfx_Sega,d0
		bsr.w	PlaySound_Special				; play "SEGA" sound
		move.b	#$14,(v_vbla_routine).w
		bsr.w	WaitForVBla
		move.w	#$1E,(v_demolength).w

Sega_WaitEnd:
		move.b	#2,(v_vbla_routine).w
		bsr.w	WaitForVBla
		tst.w	(v_demolength).w
		beq.s	Sega_GotoTitle
		andi.b	#btnStart,(v_jpadpress1).w		; is Start button pressed?
		beq.s	Sega_WaitEnd					; if not, branch

	if SaveProgressMod
Sega_GotoTitle:
		tst.b	(v_sram_errorcode).w
		bne.s	.nosram
		move.b	#id_Title,(v_gamemode).w		; go to title screen
		rts

.nosram:
		move.b	#id_SRAMError,(v_gamemode).w	; go to error screen
		rts
; ===========================================================================

		include "_inc/SRAM Error Screen.asm"
	else
Sega_GotoTitle:
		move.b	#id_Title,(v_gamemode).w		; go to title screen
		rts
; ===========================================================================
	endif

; ---------------------------------------------------------------------------
; Title	screen
; ---------------------------------------------------------------------------

GM_Title:
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		disable_ints
		; Removed call to old Sound Driver (This call was redundant anyway)
		lea		(vdp_control_port).l,a6
		move.w	#$8004,(a6)					; 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6)	; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6)	; set background nametable address
		move.w	#$9001,(a6)					; 64-cell hscroll size
		move.w	#$9200,(a6)					; window vertical position
		move.w	#$8B03,(a6)
		move.w	#$8720,(a6)					; set background colour (palette line 2, entry 0)
		clr.b	(f_wtr_state).w
		bsr.w	ClearScreen

	if HUDScrolling=1
		clr.w	(f_levelstarted).w		; clear flag AND HUD scrolling byte -- RetroKoH S3K Rings Manager
	else
		clr.b	(f_levelstarted).w		; clear flag -- RetroKoH S3K Rings Manager
	endif

	if SaveProgressMod=1
		clr.b	(f_levsel_active).w
	endif

		clearRAM v_ringpos,v_ringspace_end	; clear ring RAM -- RetroKoH S3K Rings Manager
		clearRAM v_objspace					; clear object RAM

		locVRAM	ArtTile_Title_Japanese_Text*tile_size
		lea		(Nem_JapNames).l,a0			; load Japanese credits
		bsr.w	NemDec
		locVRAM	ArtTile_Sonic_Team_Font*tile_size
		lea		(Nem_CreditText).l,a0		; load alphabet
		bsr.w	NemDec
		lea		(v_128x128&$FFFFFF).l,a1
		lea		(Eni_JapNames).l,a0			; load mappings for Japanese credits
		move.w	#make_art_tile(ArtTile_Title_Japanese_Text,0,FALSE),d0
		bsr.w	EniDec

		copyTilemap	v_128x128&$FFFFFF,vram_fg,40,28

		clearRAM v_palette_fading

		moveq	#palid_Sonic,d0					; load Sonic's palette
		bsr.w	PalLoad_Fade
		move.b	#id_CreditsText,(v_sonicteam).w	; load "SONIC TEAM PRESENTS" object
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		bsr.w	PaletteFadeIn
		disable_ints
		locVRAM	ArtTile_Title_Foreground*tile_size
		lea		(Nem_TitleFg).l,a0				; load title screen patterns
		bsr.w	NemDec
		; Removed Title Sonic Decompression (now loads via DPLCs)
		locVRAM	ArtTile_Title_Trademark*tile_size
		lea		(Nem_TitleTM).l,a0				; load "TM" patterns
		bsr.w	NemDec

	if NewLevelSelect=0
		lea		(vdp_data_port).l,a6
		locVRAM	ArtTile_Level_Select_Font*tile_size,4(a6)
		lea		(Art_Text).l,a5					; load level select font
		move.w	#(Art_Text_End-Art_Text)/2-1,d1

Tit_LoadText:
		move.w	(a5)+,(a6)
		dbf		d1,Tit_LoadText				; load level select font
	endif
		
		; Due to removing part of the pattern loading process, we should
		; add a timer to wait out the SONIC TEAM PRESENTS TEXT

		moveq	#0,d0
		move.b	d0,(f_nobgscroll).w			; Mercury Game Over When Drowning Fix
		move.b	d0,(v_lastlamp).w			; clear lamppost counter
		move.w	d0,(v_debuguse).w			; disable debug item placement mode
		move.w	d0,(f_demo).w				; disable debug mode
		move.w	d0,(v_zone).w				; set zone/act to GHZ (00)
		move.w	d0,(v_pcyc_time).w			; disable palette cycling
		bsr.w	LevelSizeLoad
		bsr.w	DeformLayers

	if BlocksInROM=1	;Mercury Blocks In ROM
		move.l	#Blk16_GHZ,(v_16x16).l		; store the ROM address for the block mappings
	else
		lea		(v_16x16).w,a1				; address to load decompressed blocks to
		lea		(Blk16_GHZ).l,a0			; load GHZ 16x16 mappings
		move.w	#make_art_tile(ArtTile_Level,0,FALSE),d0
		bsr.w	EniDec
	endif

	if ChunksInROM=1	;Mercury Chunks In ROM
		move.l	#Blk128_GHZ,(v_128x128).l	; store the ROM address for the chunk mappings
	else
		lea		(Blk128_GHZ).l,a0			; load GHZ 128x128 mappings
		lea		(v_128x128&$FFFFFF).l,a1	; address to load decompressed chunks to
		bsr.w	KosDec
	endif

		bsr.w	LevelLayoutLoad
		bsr.w	PaletteFadeOut
		disable_ints
		bsr.w	ClearScreen
		lea		(vdp_control_port).l,a5
		lea		(vdp_data_port).l,a6
		lea		(v_bgscreenposx).w,a3
		lea		(v_lvllayout+$80).w,a4		; MJ: Load address of layout BG
		move.w	#$6000,d2
		bsr.w	DrawChunks

	if ChunksInROM=1	;Mercury Chunks In ROM
		copyTilemap	Eni_Title,vram_fg+$208,34,22			; RetroKoH Title Screen Adjustment
	else
		lea		(v_128x128&$FFFFFF).l,a1					; address to load decompressed chunks to
		lea		(Eni_Title).l,a0							; load title screen mappings
		clr.w	d0
		bsr.w	EniDec

		copyTilemap	v_128x128&$FFFFFF,vram_fg+$208,34,22	; RetroKoH Title Screen Adjustment
	endif

		locVRAM	ArtTile_Level*tile_size
		lea		(Nem_Title).l,a0						; load Title Screen patterns -- Clownacy S2 Level Art Loading
		bsr.w	NemDec
		moveq	#palid_GHZ,d0							; load GHZ palette first -- RetroKoH Title Screen Adjustment
		bsr.w	PalLoad_Fade
		moveq	#palid_Title,d0							; overwrite first 2 lines w/ title screen palette
		bsr.w	PalLoad_Fade
		move.b	#bgm_Title,d0
		bsr.w	PlaySound_Special						; play title screen music
		clr.b	(f_debugmode).w							; disable debug mode
		move.w	#$178,(v_demolength).w					; run title screen for $178 frames

		clearRAM v_sonicteam,v_sonicteam+object_size	; PRESS START BUTTON Fix (Quickman)
		move.b	#id_TitleSonic,(v_titlesonic).w			; load big Sonic object
		move.b	#id_PSBTM,(v_pressstart).w				; load "PRESS START BUTTON" object

		tst.b   (v_megadrive).w							; is console Japanese?
		bpl.s   .isjap									; if yes, branch
		move.b	#id_PSBTM,(v_titletm).w					; load "TM" object
		move.b	#3,(v_titletm+obFrame).w
.isjap:
		move.b	#id_PSBTM,(v_ttlsonichide).w			; load object which hides part of Sonic
		move.b	#2,(v_ttlsonichide+obFrame).w
		jsr		(ExecuteObjects).l
		bsr.w	DeformLayers
		jsr		(BuildSprites).l
		moveq	#plcid_Main,d0
		bsr.w	NewPLC
		clr.w	(v_title_dcount).w
		clr.w	(v_title_ccount).w
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	PaletteFadeIn

		include	"_inc/Title Screen Loop.asm"

	if NewLevelSelect=1
		include "_inc/Level Select (S2).asm"
	else
		include "_inc/Level Select (S1).asm"
	endif

		include "_inc/ASCII Render Text.asm"

PlayLevel:
		move.b	#id_Level,(v_gamemode).w	; set screen mode to $0C (level)
		bsr.s	ResetLevel					; Reset level variables

	if SaveProgressMod=1
		tst.b	(f_levsel_active).w
		bne.s	.nosaving

		gotoSRAM							; Enable SRAM writing
	if AddressSRAM=3
		; no need to change this by yourself anymore -- Starleaf
		lea 	($200009).l,a1				; Base of usable SRAM
	else
		lea		($200008).l,a1				; Base of usable SRAM
	endif

	; reset stored values (cannot do directly) -- d0 was zeroed out in ResetLevel
		move.b	#1,sram_init(a1) 		; init SRAM data
		movep.w	d0,sram_zone(a1)		; clear saved zone and act
		movep.l	d0,sram_score(a1)		; clear saved score
		move.b	d0,sram_lastspecial(a1)	; clear saved special stage number
		movep.w	d0,sram_emeralds(a1)	; clear saved emerald count and bitfield
		move.b	d0,sram_continues(a1)	; clear saved continues

		move.b	(v_lives).w,d0
		move.b	d0,sram_lives(a1)		; reset saved lives count
		move.l	(v_scorelife).w,d0
		movep.l	d0,sram_scorelife(a1)	; reset saved extra life target score
	
		move.b	d0,(sram_port).l		; Disable SRAM writing

	.nosaving:
	endif

		move.b	#bgm_Fade,d0
		bra.w	PlaySound_Special		; fade out music	
; ===========================================================================

ResetLevel:
		moveq	#0,d0
		move.b	#3,(v_lives).w			; set lives to 3
		move.w	d0,(v_rings).w			; clear rings
		move.l	d0,(v_time).w			; clear time
		move.l	d0,(v_score).w			; clear score
		move.b	d0,(v_lastspecial).w	; clear special stage number
		move.b	d0,(v_emeralds).w		; clear emerald count
		move.b	d0,(v_emldlist).w		; clear emerald array
		move.b	d0,(v_continues).w		; clear continues
		move.l	#5000,(v_scorelife).w	; extra life is awarded at 50000 points

	if CoolBonusEnabled
		move.b	#10,(v_hitscount).w			; set hits count for cool bonus
	endif

		rts
; ===========================================================================

	if SaveProgressMod=1
PlayLevel_Load:
		gotoSRAM							; Enable SRAM writing
	if AddressSRAM=3
		; no need to change this by yourself anymore -- Starleaf
		lea 	($200009).l,a1				; Base of usable SRAM
	else
		lea		($200008).l,a1				; Base of usable SRAM
	endif

		movep.w	sram_zone(a1),d0
		move.w	d0,(v_zone).w				; load saved zone and act
		move.b	sram_lives(a1),d0
		move.b	d0,(v_lives).w				; load saved lives count
		movep.l	sram_score(a1),d0
		move.l	d0,(v_score).w				; load score
		movep.l	sram_scorelife(a1),d0
		move.l	d0,(v_scorelife).w			; load extra life target score
		move.b	sram_lastspecial(a1),d0
		move.b	d0,(v_lastspecial).w		; load special stage number
		movep.w	sram_emeralds(a1),d0
		move.w	d0,(v_emeralds).w			; load emerald count and bitfield
		move.b	sram_continues(a1),d0
		move.b	d0,(v_continues).w			; load continues
		
		moveq	#0,d0
		move.b	d0,(sram_port).l			; Disable SRAM writing

	; everything else can be reset like normal
		move.w	d0,(v_rings).w				; clear rings
		move.l	d0,(v_time).w				; clear time
		
		move.b	#id_Level,(v_gamemode).w	; set screen mode to $0C (level)
	
	if CoolBonusEnabled
		move.b	#10,(v_hitscount).w			; set hits count for cool bonus
	endif

		move.b	#bgm_Fade,d0
		bra.w	PlaySound_Special			; fade out music
	endif

; ---------------------------------------------------------------------------
; Demo mode
; ---------------------------------------------------------------------------

GotoDemo:
		move.w	#$1E,(v_demolength).w

loc_33B6:
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	DeformLayers
		bsr.w	PaletteCycle
		bsr.w	RunPLC
		move.w	(v_player+obX).w,d0
		addq.w	#2,d0
		move.w	d0,(v_player+obX).w
		cmpi.w	#$1C00,d0
		blo.s	loc_33E4
		move.b	#id_Sega,(v_gamemode).w
		rts	
; ===========================================================================

loc_33E4:
		andi.b	#btnStart,(v_jpadpress1).w	; is Start button pressed?
		bne.w	Tit_ChkLevSel				; if yes, branch
		tst.w	(v_demolength).w
		bne.w	loc_33B6
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special			; fade out music
		move.w	(v_demonum).w,d0			; load demo number
		andi.w	#7,d0
		add.w	d0,d0
		move.w	Demo_Levels(pc,d0.w),d0		; load level number for	demo
		move.w	d0,(v_zone).w
		moveq	#0,d1						; use d1 for optimal clearing
		addq.w	#1,(v_demonum).w			; add 1 to demo number
		cmpi.w	#4,(v_demonum).w			; is demo number less than 4?
		blo.s	loc_3422					; if yes, branch
		move.w	d1,(v_demonum).w			; reset demo number to 0

loc_3422:
		move.w	#1,(f_demo).w				; turn demo mode on
		move.b	#id_Demo,(v_gamemode).w		; set screen mode to 08 (demo)
		cmpi.w	#$600,d0					; is level number 0600 (special	stage)?
		bne.s	Demo_Level					; if not, branch
		move.b	#id_Special,(v_gamemode).w	; set screen mode to $10 (Special Stage)
		move.w	d1,(v_zone).w				; clear	level number
		move.b	d1,(v_lastspecial).w		; clear special stage number

Demo_Level:
		move.b	#3,(v_lives).w				; set lives to 3
		move.w	d1,(v_rings).w				; clear rings
		move.l	d1,(v_time).w				; clear time
		move.l	d1,(v_score).w				; clear score
		move.l	#5000,(v_scorelife).w		; extra life is awarded at 50000 points
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Levels used in demos
; ---------------------------------------------------------------------------
Demo_Levels:	binclude	"misc/Demo Level Order - Intro.bin"
		even

; ---------------------------------------------------------------------------
; Music	playlist
; ---------------------------------------------------------------------------
MusicList:
		dc.b bgm_GHZ	; GHZ
		dc.b bgm_LZ		; LZ
		dc.b bgm_MZ		; MZ
		dc.b bgm_SLZ	; SLZ
		dc.b bgm_SYZ	; SYZ
		dc.b bgm_SBZ	; SBZ
		zonewarning MusicList,1
		dc.b bgm_FZ		; Final Zone (Never used w/ Ending)
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Level
; ---------------------------------------------------------------------------

GM_Level:
		bset	#7,(v_gamemode).w			; add $80 to screen mode (for pre level sequence)
		tst.w	(f_demo).w
		bmi.s	Level_NoMusicFade
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special			; fade out music

Level_NoMusicFade:
	if SaveProgressMod=1
		cmpi.b	#$8C,(v_gamemode).w			; is game mode = $0C (standard level)?
		bne.s	.noSRAM						; if not, branch
		tst.b	(f_levsel_active).w
		bne.s	.noSRAM

		gotoSRAM							; Enable SRAM writing
	if AddressSRAM=3
		; no need to change this by yourself anymore -- Starleaf
		lea 	($200009).l,a1				; Base of usable SRAM
	else
		lea		($200008).l,a1				; Base of usable SRAM
	endif

		move.w	(v_zone).w,d0				; move zone and act number to d0 (we can't do it directly)
		movep.w	d0,sram_zone(a1)			; save zone and act to SRAM	
		move.b	(v_lives).w,d0
		move.b	d0,sram_lives(a1)
		move.l	(v_score).w,d0
		movep.l	d0,sram_score(a1)
		move.l	(v_scorelife).w,d0
		movep.l	d0,sram_scorelife(a1)
		move.b	(v_lastspecial).w,d0
		move.b	d0,sram_lastspecial(a1)
		move.w	(v_emeralds).w,d0
		movep.w	d0,sram_emeralds(a1)
		move.b	(v_continues).w,d0
		move.b	d0,sram_continues(a1)

        gotoROM								; Disable SRAM writing

	.noSRAM:
	endif

		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		tst.w	(f_demo).w					; is an ending sequence demo running?
		bmi.w	Level_ClrRam				; if yes, branch
		disable_ints
		locVRAM	ArtTile_Title_Card*tile_size

	if OptimalTitleCardArt
	; RetroKoH Optimal Title Cards for VRAM/SpritePiece Reduction
		moveq	#0,d0
		move.b	(v_zone).w,d0

		cmpi.w	#(id_LZ<<8)+3,(v_zone).w	; check if level is SBZ3
		bne.s	.chkFinal
		moveq	#$28,d0						; load title card art for SBZ
		bra.s	.cont

.chkFinal:
		cmpi.w	#(id_SBZ<<8)+2,(v_zone).w	; check if level is FZ
		bne.s	.normalLoad
		lea		Art_TitCardFZ,a0									; load title card patterns
		move.l	#((Art_TitCardFZ_End-Art_TitCardFZ)/tile_size)-1,d0	; # of tiles
		bra.s	.load

.normalLoad:
		lsl.w	#3,d0						; zone * 8
.cont:
		lea		(Art_TitleCardZones).l,a2	; a2 = Art_TitleCardZones address
		lea		(a2,d0.w),a2				; a2 = Art_TitleCardZones + zone offset
		movea.l	(a2)+,a0					; a0 = zone's art file movea.l?
		move.l	(a2),d0						; # of tiles
.load:
		jsr		(LoadUncArt).w
		locVRAM	(ArtTile_Title_Card+$22)*tile_size							; if we don't call this, locVRAM will pick up where left off.
		lea		Art_TitCardZone,a0											; load title card patterns
		move.l	#((Art_TitCardZone_End-Art_TitCardZone)/tile_size)-1,d0		; # of tiles
		jsr		(LoadUncArt).w
		lea		Art_TitCardItems,a0											; load title card patterns
		move.l	#((Art_TitCardItems_End-Art_TitCardItems)/tile_size)-1,d0	; # of tiles
		jsr		(LoadUncArt).w
	; Optimal Title Cards End
	else
	; AURORA☆FIELDS Title Card Optimization
		lea		Art_TitleCard,a0									; load title card patterns
		move.l	#((Art_TitleCard_End-Art_TitleCard)/tile_size)-1,d0	; # of tiles
		jsr		(LoadUncArt).w
	; Title Card Optimization End
	endif

		enable_ints
		moveq	#0,d0
		move.b	(v_zone).w,d0

	if NewSBZ3LevelArt
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w	; is level SBZ3 (LZ4) ?
		bne.s	.notSBZ3					; if not, branch
		moveq	#SBZ3_Art,d0				; use SBZ3 art

.notSBZ3:
	endif

		lsl.w	#4,d0
		lea		(LevelHeaders).l,a2	; a2 = LevelHeaders address
		lea		(a2,d0.w),a2		; a2 = LevelHeaders + zone offset
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	loc_37FC
		bsr.w	AddPLC				; load level patterns

loc_37FC:
		moveq	#plcid_Main2,d0
		bsr.w	AddPLC				; load standard	patterns

Level_ClrRam:
		clearRAM v_ringpos,v_ringspace_end				; clear ring RAM -- RetroKoH S3K Rings Manager
		clearRAM v_objspace								; clear object RAM
		clearRAM v_misc_variables
		clearRAM v_levelvariables						; f_levelstarted should clear here
		clearRAM v_timingandscreenvariables

		disable_ints
		bsr.w	ClearScreen
		lea		(vdp_control_port).l,a6
		move.w	#$8B03,(a6)	; line scroll mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$8500+(vram_sprites>>9),(a6) ; set sprite table address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		move.w	#$8004,(a6)		; 8-colour mode
		move.w	#$8720,(a6)		; set background colour (line 3; colour 0)
		move.w	#$8A00+223,(v_hbla_hreg).w ; set palette change position (for water)
		move.w	(v_hbla_hreg).w,(a6)

		ResetDMAQueue	; Mercury Use DMA Queue

		cmpi.b	#id_LZ,(v_zone).w		; is level LZ?
		bne.s	Level_LoadPal			; if not, branch

		move.w	#$8014,(a6)				; enable H-interrupts
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		lea		(WaterHeight).l,a1		; load water height array
		move.w	(a1,d0.w),d0
		move.w	d0,(v_waterpos1).w		; set water heights
		move.w	d0,(v_waterpos2).w
		move.w	d0,(v_waterpos3).w
		moveq	#0,d0
		move.b	d0,(v_wtr_routine).w	; clear water routine counter
		move.b	d0,(f_wtr_state).w		; clear	water state
		move.b	#1,(f_water).w			; enable water

Level_LoadPal:
		move.b	#30,(v_air).w
		enable_ints
		moveq	#palid_Sonic,d0
		bsr.w	PalLoad					; load Sonic's palette
		cmpi.b	#id_LZ,(v_zone).w		; is level LZ?
		bne.s	Level_GetBgm			; if not, branch

		moveq	#palid_LZSonWater,d0	; LZ Water Sonic
	if DynamicPalettes
		add.b	(v_act).w,d0			; Adjust for act
	endif
		cmpi.b	#3,(v_act).w			; is act number 3?
		bne.s	Level_WaterPal			; if not, branch
		moveq	#palid_SBZ3SonWat,d0	; SBZ3 Water Sonic

Level_WaterPal:
		bsr.w	PalLoad_Fade_Water		; load underwater palette
		tst.b	(v_lastlamp).w
		beq.s	Level_GetBgm
		move.b	(v_lamp_wtrstat).w,(f_wtr_state).w

Level_GetBgm:
		tst.w	(f_demo).w
		bmi.s	Level_SkipTtlCard
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w		; is level SBZ3?
		bne.s	Level_BgmNotLZ4					; if not, branch
		moveq	#5,d0							; use 5th music (SBZ)

Level_BgmNotLZ4:
		cmpi.w	#(id_SBZ<<8)+2,(v_zone).w		; is level FZ?
		bne.s	Level_PlayBgm					; if not, branch
		moveq	#6,d0							; use 6th music (FZ)

Level_PlayBgm:
		lea		(MusicList).l,a1				; load music playlist
		move.b	(a1,d0.w),d0
		bsr.w	PlaySound						; play music
		move.b	d0,(v_lastbgmplayed).w			; store last played music
		move.b	#id_TitleCard,(v_titlecard).w	; load title card object

		move.b  #3,(v_carddelay).w				; set the delay timer -- Fixes bug w/ HUD elements not appearing

Level_TtlCardLoop:
		move.b	#$C,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		bsr.w	RunPLC
		move.w	(v_ttlcardact+obX).w,d0
		cmp.w	(v_ttlcardact+card_mainX).w,d0	; has title card sequence finished?
		bne.s	Level_TtlCardLoop				; if not, branch
		tst.l	(v_plc_buffer).w				; are there any items in the pattern load cue?
		bne.s	Level_TtlCardLoop				; if yes, branch
		subq.b  #1,(v_carddelay).w				; substract 1 from timer
        bne.s   Level_TtlCardLoop				; if timer is not 0, branch
		jsr		(Hud_Base).l					; load basic HUD gfx

Level_SkipTtlCard:
	if RandomMonitors
		locVRAM	(ArtTile_Monitor+$14)*tile_size
		lea		Art_Mon_Rand,a0					; load random monitor patterns
		move.l	#3,d0							; # of tiles
		jsr		(LoadUncArt).w
	endif

		bsr.w	LoadRingFrame					; DeltaW/Malachi Optimized Rings
		moveq	#palid_Sonic,d0
		bsr.w	PalLoad_Fade					; load Sonic's palette
		jsr		(AnimateLevelGfx_Init).l
		bsr.w	LevelSizeLoad
		bsr.w	DeformLayers
		bset	#2,(v_fg_scroll_flags).w
		bsr.w	LevelDataLoad					; load level art -- Clownacy Level Art Loading + load block mappings and palettes
		bsr.w	LoadTilesFromStart
		jsr		(ConvertCollisionArray).l
		bsr.w	ColIndexLoad
		bsr.w	LZWaterFeatures
		move.b	#id_SonicPlayer,(v_player).w	; load Sonic object

	if InstashieldEnabled
		move.b	#id_ShieldItem,(v_shieldobj).w	; load instashield object
		move.b	#shTypeInsta,(v_shieldobj+obSubtype).w
	endif

Level_ChkWater:
		moveq	#0,d0
		move.w	d0,(v_jpadhold2).w
		move.w	d0,(v_jpadhold1).w
		cmpi.b	#id_LZ,(v_zone).w						; is level LZ?
		bne.s	Level_LoadObj							; if not, branch
		move.b	#id_WaterSurface,(v_watersurface1).w	; load water surface object
		move.w	#$60,(v_watersurface1+obX).w
		move.b	#id_WaterSurface,(v_watersurface2).w
		move.w	#$120,(v_watersurface2+obX).w

Level_LoadObj:
		jsr		(ObjPosLoad).l
		jsr		(RingsManager).l		; RetroKoH S3K Rings Manager
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		moveq	#0,d0
		tst.b	(v_lastlamp).w			; are you starting from	a lamppost?
		bne.s	Level_SkipClr			; if yes, branch
		move.w	d0,(v_rings).w			; clear rings
		move.l	d0,(v_time).w			; clear time

	if HUDCentiseconds=1	; Mercury HUD Centiseconds
		move.b	d0,(v_centstep).w
	endif	; HUD Centiseconds end

		move.b	d0,(v_lifecount).w		; clear lives counter

Level_SkipClr:
		move.b	d0,(f_timeover).w
		move.w	d0,(v_debuguse).w
		move.b	d0,(f_restart).w
		move.w	d0,(v_framecount).w
		bsr.w	OscillateNumInit
		moveq	#1,d0
		move.b	d0,(f_scorecount).w		; update score counter
		move.b	d0,(f_ringcount).w		; update rings counter

	if HUDCentiseconds=0	; Mercury HUD Centiseconds
		move.b	d0,(f_timecount).w		; update time counter
	endif	; HUD Centiseconds end

		clr.w	(v_btnpushtime1).w
		lea		DemoDataPtr(pc),a1		; load demo data
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		tst.w	(f_demo).w				; is demo mode on?
		bpl.s	Level_Demo				; if yes, branch
		lea		DemoEndDataPtr(pc),a1	; load ending demo data
		move.w	(v_creditsnum).w,d0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1

Level_Demo:
		move.b	1(a1),(v_btnpushtime2).w ; load key press duration
		subq.b	#1,(v_btnpushtime2).w ; subtract 1 from duration
		move.w	#1800,(v_demolength).w
		tst.w	(f_demo).w
		bpl.s	Level_ChkWaterPal
		move.w	#540,(v_demolength).w
		cmpi.w	#4,(v_creditsnum).w
		bne.s	Level_ChkWaterPal
		move.w	#510,(v_demolength).w

Level_ChkWaterPal:
		cmpi.b	#id_LZ,(v_zone).w	; is level LZ/SBZ3?
		bne.s	Level_Delay			; if not, branch
		moveq	#palid_LZWater,d0	; palette: LZ underwater
	if DynamicPalettes
		add.b	(v_act).w,d0		; Adjust for act
	endif
		cmpi.b	#3,(v_act).w		; is level SBZ3?
		bne.s	Level_WtrNotSbz		; if not, branch
		moveq	#palid_SBZ3Water,d0	; palette: SBZ3 underwater

Level_WtrNotSbz:
		bsr.w	PalLoad_Water

Level_Delay:
		move.w	#3,d1

Level_DelayLoop:
		move.b	#8,(v_vbla_routine).w
		bsr.w	WaitForVBla
		dbf	d1,Level_DelayLoop

		move.w	#$202F,(v_pfade_start).w ; fade in 2nd, 3rd & 4th palette lines
		bsr.w	PalFadeIn_Alt
		tst.w	(f_demo).w	; is an ending sequence demo running?
		bmi.s	Level_ClrCardArt ; if yes, branch
		addq.b	#2,(v_ttlcardname+obRoutine).w ; make title card move
		addq.b	#4,(v_ttlcardzone+obRoutine).w
		addq.b	#4,(v_ttlcardact+obRoutine).w
		addq.b	#4,(v_ttlcardoval+obRoutine).w
		bra.s	Level_StartGame
; ===========================================================================

Level_ClrCardArt:
		moveq	#plcid_Explode,d0
		jsr		(AddPLC).w	; load explosion gfx
		moveq	#0,d0
		move.b	(v_zone).w,d0
		addi.w	#plcid_GHZAnimals,d0
		jsr		(AddPLC).w	; load animal gfx (level no. + $15)

Level_StartGame:
		; The above check is for the S2 HUD Manager (RetroKoH)
		; This also removes rings from the end demos. Need to fix this another way.
		tst.w	(f_demo).w
		bmi.s	.demo					; Branch if End Credits Demo
		move.b	#1,(f_levelstarted).w	; RetroKoH S3K Rings Manager
.demo:

	if HUDCentiseconds=1	;Mercury HUD Centiseconds
		move.b	#1,(f_timecount).w ; update time counter
	endif	;end HUD Centiseconds

		bclr	#7,(v_gamemode).w ; subtract $80 from mode to end pre-level stuff

; ---------------------------------------------------------------------------
; Main level loop (when	all title card and loading sequences are finished)
; ---------------------------------------------------------------------------

Level_MainLoop:
		bsr.w	PauseGame
		move.b	#8,(v_vbla_routine).w
		bsr.w	WaitForVBla
		addq.w	#1,(v_framecount).w			; add 1 to level timer
		bsr.w	MoveSonicInDemo
		bsr.w	LZWaterFeatures
		jsr		(ExecuteObjects).l
		tst.b	(f_restart).w
		bne.w	GM_Level
		jsr		(RingsManager).l			; RetroKoH S3K Rings Manager

	if ~~ActiveDeathSequence				; RetroKoH Active Death Sequence Mod
		cmpi.b	#6,(v_player+obRoutine).w	; has Sonic just died?
		bhs.s	Level_SkipDeform			; if yes, branch
	endif
		bsr.w	DeformLayers

Level_SkipDeform:
	if HUDScrolling=1
		cmpi.b	#128+16,(v_hudscrollpos).w
		beq.s	Level_SkipHUDScroll
		add.b	#4,(v_hudscrollpos).w

Level_SkipHUDScroll:
	endif
		jsr		(BuildSprites).l
		jsr		(ObjPosLoad).l
		bsr.w	PaletteCycle
		bsr.w	RunPLC
		bsr.w	OscillateNumDo
		bsr.w	SynchroAnimate
		bsr.w	SignpostArtLoad
		jsr		(AnimateLevelGfx).l
		clr.b	(f_gfxbigring).w

		cmpi.b	#id_Demo,(v_gamemode).w
		beq.s	Level_ChkDemo				; if mode is 8 (demo), branch
		cmpi.b	#id_Level,(v_gamemode).w
		beq.w	Level_MainLoop				; if mode is $C (level), branch
		rts	
; ===========================================================================

Level_ChkDemo:
		tst.b	(f_restart).w	; is level set to restart?
		bne.s	Level_EndDemo	; if yes, branch
		tst.w	(v_demolength).w ; is there time left on the demo?
		beq.s	Level_EndDemo	; if not, branch
		cmpi.b	#id_Demo,(v_gamemode).w
		beq.w	Level_MainLoop	; if mode is 8 (demo), branch
		move.b	#id_Sega,(v_gamemode).w ; go to Sega screen
		rts	
; ===========================================================================

Level_EndDemo:
		cmpi.b	#id_Demo,(v_gamemode).w
		bne.s	Level_FadeDemo	; if mode is 8 (demo), branch
		move.b	#id_Sega,(v_gamemode).w ; go to Sega screen
		tst.w	(f_demo).w	; is demo mode on & not ending sequence?
		bpl.s	Level_FadeDemo	; if yes, branch
		move.b	#id_Credits,(v_gamemode).w ; go to credits

Level_FadeDemo:
		move.w	#$3C,(v_demolength).w
		move.w	#$3F,(v_pfade_start).w
		clr.w	(v_palchgspeed).w

Level_FDLoop:
		move.b	#8,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	MoveSonicInDemo
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		jsr		(ObjPosLoad).l
		subq.w	#1,(v_palchgspeed).w
		bpl.s	loc_3BC8
		move.w	#2,(v_palchgspeed).w
		bsr.w	FadeOut_ToBlack

loc_3BC8:
		tst.w	(v_demolength).w
		bne.s	Level_FDLoop
		rts	
; ===========================================================================

		include	"_inc/LZWaterFeatures.asm"
		include	"_inc/MoveSonicInDemo.asm"

; ---------------------------------------------------------------------------
; Collision index pointer loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ColIndexLoad:
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#3,d0				; MJ: multiply by 8 not 4
		move.l	#v_collision1&$FFFFFF,(v_collindex).w
		move.w	d0,-(sp)
		movea.l	ColPointers(pc,d0.w),a0		; MJ: get first collision set
		lea	(v_collision1).w,a1
		bsr.w	KosDec
		move.w	(sp)+,d0
		movea.l	ColPointers+4(pc,d0.w),a0	; MJ: get second collision set
		lea	(v_collision2).w,a1
		bra.w	KosDec
; End of function ColIndexLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision index pointers
; ---------------------------------------------------------------------------
ColPointers:
		dc.l Col_GHZ_1	; MJ: each zone now has two entries
		dc.l Col_GHZ_2
		dc.l Col_LZ_1
		dc.l Col_LZ_2
		dc.l Col_MZ_1
		dc.l Col_MZ_2
		dc.l Col_SLZ_1
		dc.l Col_SLZ_2
		dc.l Col_SYZ_1
		dc.l Col_SYZ_2
		dc.l Col_SBZ_1
		dc.l Col_SBZ_2
		zonewarning ColPointers,8
;		dc.l Col_GHZ_1 ; Pointers for Ending are missing by default.
;		dc.l Col_GHZ_2
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Queue ring frame graphics loading
; ---------------------------------------------------------------------------
LoadRingFrame:
		moveq	#0,d1				; Get ring frame offset for regular rings
		move.b	(v_ani1_frame).w,d1
		cmp.b	(v_DPLCframe1_buf).w,d1
		beq.s	.chklostrings
		move.b	d1,(v_DPLCframe1_buf).w
		lsl.w	#7,d1				; Each ring frame takes $80 bytes, so multiply by $80
		add.l	#Art_Ring,d1		; Queue a DMA transfer for this ring frame
		move.w	#(ArtTile_Ring*tile_size),d2
		move.w  #$80/2,d3
		jsr		(QueueDMATransfer).w

	.chklostrings:
		moveq   #0,d1				; Get ring frame offset for lost rings
		move.b  (v_ani3_frame).w,d1
		cmp.b	(v_DPLCframe2_buf).w,d1
		beq.s	RingFrame_End
		move.b	d1,(v_DPLCframe2_buf).w
		lsl.w   #7,d1				; Each ring frame takes $80 bytes, so multiply by $80
		add.l   #Art_Ring,d1		; Queue a DMA transfer for this ring frame
		move.w  #(ArtTile_LostRing*tile_size),d2
		move.w  #$80/2,d3
		jmp		(QueueDMATransfer).w

RingFrame_End:
		rts

LoadSSRingFrame:
		moveq	#0,d1				; Get ring frame offset for rings
		move.b	(v_ani1_frame).w,d1
		cmp.b	(v_DPLCframe1_buf).w,d1
		beq.s	RingFrame_End
		move.b	d1,(v_DPLCframe1_buf).w
		lsl.w	#7,d1				; Each ring frame takes $80 bytes, so multiply by $80
		add.l	#Art_Ring,d1		; Queue a DMA transfer for this ring frame
		move.w	#(ArtTile_SS_Ring*tile_size),d2
		move.w  #$80/2,d3
		jmp		(QueueDMATransfer).w
; ===========================================================================

		include	"_inc/Oscillatory Routines.asm"

; ---------------------------------------------------------------------------
; Subroutine to	change synchronised animation variables (rings, giant rings)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SynchroAnimate:

	if ~~ActiveDeathSequence				; RetroKoH Active Death Sequence Mod
		cmpi.b	#6,(v_player+obRoutine).w	; has Sonic just died?
		bhs.s	SyncEnd						; if yes, branch
	endif

; Used for GHZ spiked log
Sync1:
		subq.b	#1,(v_ani0_time).w	; has timer reached 0?
		bpl.s	Sync2				; if not, branch
		move.b	#$B,(v_ani0_time).w	; reset timer
		subq.b	#1,(v_ani0_frame).w	; next frame
		andi.b	#7,(v_ani0_frame).w	; max frame is 7

; Used for 8-frame rings and giant rings -- RetroKoH 8-Frame Rings Change
Sync2:
		subq.b	#1,(v_ani1_time).w	; decrement timer
		bpl.s	Sync3				; if timer !=0, branch
		move.b	#3,(v_ani1_time).w	; reset timer
		addq.b	#1,(v_ani1_frame).w	; next frame
		andi.b	#7,(v_ani1_frame).w	; max frame is 7

; Used for SYZ Lights (Timing is already identical, no need for identical timers to run twice)
Sync3:
		subq.b	#1,(v_ani2_time).w
		bpl.s	Sync4
		move.b	#7,(v_ani2_time).w
		addq.b	#1,(v_ani2_frame).w
		cmpi.b	#6,(v_ani2_frame).w
		blo.s	Sync4
		clr.b	(v_ani2_frame).w

; Used for bouncing rings and rings in the special stage -- RetroKoH 8-Frame Rings Change
Sync4:
		tst.b	(v_ani3_time).w
		beq.w	LoadRingFrame
		moveq	#0,d0
		move.b	(v_ani3_time).w,d0
		add.w	(v_ani3_buf).w,d0
		move.w	d0,(v_ani3_buf).w
		rol.w	#8,d0
		andi.w	#7,d0
		move.b	d0,(v_ani3_frame).w
		subq.b	#1,(v_ani3_time).w
		bra.w	LoadRingFrame

SyncEnd:
		rts
; End of function SynchroAnimate

; ---------------------------------------------------------------------------
; End-of-act signpost pattern loading subroutine
; No longer loads signpost art. Actually loads Hidden Points and Ring Flash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SignpostArtLoad:
		tst.w	(v_debuguse).w		; is debug mode	being used?
		bne.w	.exit				; if yes, branch
		cmpi.b	#2,(v_act).w		; is act number 02 (act 3)?
		beq.s	.exit				; if yes, branch

		move.w	(v_screenposx).w,d0
		move.w	(v_limitright2).w,d1
		subi.w	#$100,d1
		cmp.w	d1,d0				; has Sonic reached the	edge of	the level?
		blt.s	.exit				; if not, branch
		tst.b	(f_timecount).w
		beq.s	.exit
		cmp.w	(v_limitleft2).w,d1
		beq.s	.exit
		move.w	d1,(v_limitleft2).w	; move left boundary to current screen position
		moveq	#plcid_Signpost,d0
		bra.w	NewPLC				; load signpost	patterns

.exit:
		rts	
; End of function SignpostArtLoad

; ===========================================================================
Demo_GHZ:	binclude	"demodata/Intro - GHZ.bin"
Demo_MZ:	binclude	"demodata/Intro - MZ.bin"
Demo_SYZ:	binclude	"demodata/Intro - SYZ.bin"
Demo_SS:	binclude	"demodata/Intro - Special Stage.bin"
; ===========================================================================

; ---------------------------------------------------------------------------
; Special Stage
; ---------------------------------------------------------------------------

GM_Special:
		move.w	#sfx_EnterSS,d0
		bsr.w	PlaySound_Special	; play special stage entry sound
		bsr.w	PaletteWhiteOut
		disable_ints
		lea		(vdp_control_port).l,a6
		move.w	#$8B03,(a6)			; line scroll mode
		move.w	#$8004,(a6)			; 8-colour mode
		move.w	#$8A00+175,(v_hbla_hreg).w
		move.w	#$9011,(a6)			; 128-cell hscroll size
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		
		ResetDMAQueue		; Flamewing Ultra DMA Queue
		
		bsr.w	ClearScreen
		enable_ints
		fillVRAM	0, ArtTile_SS_Plane_1*tile_size+plane_size_64x32, ArtTile_SS_Plane_5*tile_size
		bsr.w	SS_BGLoad
		moveq	#plcid_SpecialStage,d0
		bsr.w	QuickPLC	; load special stage patterns
		
		bsr.w	LoadSSRingFrame

		clearRAM v_objspace
		clearRAM v_levelvariables
		clearRAM v_timingvariables
		clearRAM v_ngfx_buffer

		clr.b	(f_wtr_state).w
		clr.b	(f_restart).w
		moveq	#palid_Special,d0
		bsr.w	PalLoad_Fade					; load special stage palette
		jsr		(SS_Load).l						; load SS layout data
		clr.l	(v_screenposx).w
		clr.l	(v_screenposy).w
		move.b	#id_SonicSpecial,(v_player).w		; load special stage Sonic object
		move.b	#id_SpecialCursor,(v_playerdust).w	; load new debug cursor object (RetroKoH)

	if DynamicSpecialStageWalls=1	; Mercury Dynamic Special Stage Walls
		move.b	#$FF,(v_ssangleprev).w			; fill previous angle with obviously false value to force an update

	if HUDInSpecialStage=1	; Mercury HUD in Special Stage
		move.b	#1,(f_timecount).w				; update time counter
		move.b	#1,(f_scorecount).w				; update score counter
		clr.l	(v_time).w						; reset time

	if TimeLimitInSpecialStage=1	; Mercury Time Limit In Special Stage
		move.b	#1,(v_timemin).w				; start with 1:00 on the clock
	endif	; Time Limit In Special Stage End

		jsr		(Hud_Base_SS).l					; load basic HUD gfx
	endif	; HUD in Special Stage End

	endif	; Dynamic Special Stage Walls End

		bsr.w	PalCycle_SS
		clr.w	(v_ssangle).w					; set stage angle to "upright"
	if S4SpecialStages=0
		move.w	#$40,(v_ssrotate).w				; set stage rotation speed
	else
		move.w	#$100,(v_ssrotate).w			; set stage rotation speed
	endif
		move.w	#bgm_SS,d0
		bsr.w	PlaySound						; play special stage BG	music
		clr.w	(v_btnpushtime1).w
		lea		DemoDataPtr(pc),a1
		moveq	#6,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		move.b	1(a1),(v_btnpushtime2).w
		subq.b	#1,(v_btnpushtime2).w
		clr.w	(v_rings).w
		clr.b	(v_lifecount).w
		clr.w	(v_debuguse).w
		move.w	#1800,(v_demolength).w
;		tst.b	(f_debugcheat).w				; has debug cheat been entered?
;		beq.s	SS_NoDebug						; if not, branch
;		btst	#bitA,(v_jpadhold1).w			; is A button pressed?
;		beq.s	SS_NoDebug						; if not, branch
		move.b	#1,(f_debugmode).w				; enable debug mode

SS_NoDebug:
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	PaletteWhiteIn
	if HUDInSpecialStage=1
		move.b	#2,(f_levelstarted).w			; Mercury HUD In Special Stage
	endif

; ---------------------------------------------------------------------------
; Main Special Stage loop
; ---------------------------------------------------------------------------

SS_MainLoop:
		bsr.w	PauseGame
		move.b	#$A,(v_vbla_routine).w
		bsr.w	WaitForVBla

	if HUDInSpecialStage=1	; Mercury HUD in Special Stage
		addq.w	#1,(v_framecount).w		; add 1 to level timer
	endc	; HUD in Special Stage End

		bsr.w	MoveSonicInDemo
		move.w	(v_jpadhold1).w,(v_jpadhold2).w
		jsr		(ExecuteObjects).l

		bsr.w	LoadSSRingFrame

	if (HUDInSpecialStage=1&HUDScrolling=1)
		tst.b	(f_timecount).w
		beq.s	.remove
		cmpi.b	#$90,(v_hudscrollpos).w
		beq.s	SS_SkipHUDScroll
		add.b	#4,(v_hudscrollpos).w
		bra.s	SS_SkipHUDScroll

.remove:
		tst.b	(v_hudscrollpos).w
		beq.s	SS_SkipHUDScroll
		subq.b	#2,(v_hudscrollpos).w

SS_SkipHUDScroll:
	endif

		jsr		(BuildSprites).l
		jsr		(SS_ShowLayout).l
		bsr.w	SS_BGAnimate
		tst.w	(f_demo).w	; is demo mode on?
		beq.s	SS_ChkEnd	; if not, branch
		tst.w	(v_demolength).w ; is there time left on the demo?
		beq.w	SS_ToSegaScreen	; if not, branch

SS_ChkEnd:
		cmpi.b	#id_Special,(v_gamemode).w ; is game mode $10 (special stage)?
		beq.w	SS_MainLoop	; if yes, branch

		tst.w	(f_demo).w	; is demo mode on?
		bne.w	SS_ToLevel
		move.b	#id_Level,(v_gamemode).w ; set screen mode to $0C (level)
		cmpi.w	#(id_SBZ<<8)+3,(v_zone).w ; is level number higher than FZ?
		blo.s	SS_Finish	; if not, branch
		clr.w	(v_zone).w	; set to GHZ1

SS_Finish:
		move.w	#60,(v_demolength).w ; set delay time to 1 second
		move.w	#$3F,(v_pfade_start).w
		clr.w	(v_palchgspeed).w

SS_FinLoop:
		move.b	#$16,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	MoveSonicInDemo
		move.w	(v_jpadhold1).w,(v_jpadhold2).w
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		jsr		(SS_ShowLayout).l
		bsr.w	SS_BGAnimate
		subq.w	#1,(v_palchgspeed).w
		bpl.s	loc_47D4
		move.w	#2,(v_palchgspeed).w
		bsr.w	WhiteOut_ToWhite

loc_47D4:
		tst.w	(v_demolength).w
		bne.s	SS_FinLoop

		disable_ints
		lea		(vdp_control_port).l,a6
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		bsr.w	ClearScreen
		locVRAM	ArtTile_Title_Card*tile_size

	if OptimalTitleCardArt
	; RetroKoH Optimal Title Cards for VRAM/SpritePiece Reduction
		lea		Art_TitCardSpecStage,a0												; load title card patterns
		move.l	#((Art_TitCardSpecStage_End-Art_TitCardSpecStage)/tile_size)-1,d0	; # of tiles
		move.b	(v_emeralds).w,d1	; do you have ANY chaos emeralds?
		beq.s	.load				; if not, branch
		lea		Art_TitCardChaosEmlds,a0											; load title card patterns
		move.l	#((Art_TitCardChaosEmlds_End-Art_TitCardChaosEmlds)/tile_size)-1,d0	; # of tiles
		cmpi.b	#emldCount,d1		; do you have all chaos	emeralds?
		bne.s	.load				; if not, branch
		lea		Art_TitCardSonic,a0													; load title card patterns
		move.l	#((Art_TitCardSonic_End-Art_TitCardSonic)/tile_size)-1,d0			; # of tiles
		jsr		(LoadUncArt).w
		lea		Art_TitCardGotThemAll,a0											; load title card patterns
		move.l	#((Art_TitCardGotThemAll_End-Art_TitCardGotThemAll)/tile_size)-1,d0	; # of tiles
		
.load:
		jsr		(LoadUncArt).w
		locVRAM	(ArtTile_Title_Card+$32)*tile_size									; if we don't call this, locVRAM will pick up where left off.
		lea		Art_TitCardBonuses,a0												; load title card patterns
		move.l	#((Art_TitCardBonuses_End-Art_TitCardBonuses)/tile_size)-1,d0		; # of tiles
		jsr		(LoadUncArt).w
		movea.l	#Art_TitCardOval,a0													; load title card patterns
		move.l	#Art_TitCardOvalCt,d0												; # of tiles
		jsr		(LoadUncArt).w
	
	if PerfectBonusEnabled
		locVRAM	$670*tile_size
		lea		Art_Perfect,a0									; load title card patterns
		move.l	#((Art_Perfect_End-Art_Perfect)/tile_size)-1,d0	; # of tiles
		jsr		(LoadUncArt).w									; load uncompressed art
	endif
	; Optimal Title Cards End
	else
	; AURORA☆FIELDS Title Card Optimization
		lea		Art_TitleCard,a0									; load title card patterns
		move.l	#((Art_TitleCard_End-Art_TitleCard)/tile_size)-1,d0	; # of tiles
		jsr		(LoadUncArt).w
		
	if PerfectBonusEnabled
		locVRAM	$670*tile_size
		lea		Art_Perfect,a0									; load title card patterns
		move.l	#((Art_Perfect_End-Art_Perfect)/tile_size)-1,d0	; # of tiles
		jsr		(LoadUncArt).w									; load uncompressed art
	endif
	; Title Card Optimization End
	endif
		
		jsr		(Hud_Base).l

	; Mercury Use DMA Queue
		ResetDMAQueue
	; Use DMA Queue End

		enable_ints
		moveq	#palid_SSResult,d0
		bsr.w	PalLoad					; load results screen palette
		moveq	#plcid_Main,d0
		bsr.w	NewPLC
		moveq	#plcid_SSResult,d0
		bsr.w	AddPLC					; load results screen patterns
		move.b	#1,(f_scorecount).w		; update score counter
		move.b	#1,(f_endactbonus).w	; update ring bonus counter
		move.w	(v_rings).w,d0
		add.w	d0,d0					; multiply by 10
		move.w	d0,d1					; Optimization from S1 in S.C.E.
		add.w	d0,d0
		add.w	d0,d0
		add.w	d1,d0
		move.w	d0,(v_ringbonus).w		; set rings bonus
		
	if PerfectBonusEnabled
		tst.w	(v_perfectringsleft).w					; did Sonic get all the rings?
		bne.s	.noperfect
		move.w	#PerfectScore,(v_perfectbonus).w		; set perfect bonus
	.noperfect:
	endif
		
		move.w	#bgm_GotThrough,d0
		jsr		(PlaySound_Special).w	; play end-of-level music

		clearRAM v_objspace

		move.b	#id_SSResult,(v_ssrescard).w	; load results screen object

	if HUDInSpecialStage=1
		clr.b	(f_levelstarted).w				; remove HUD
	endif

SS_NormalExit:
		bsr.w	PauseGame
		move.b	#$C,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		bsr.w	RunPLC
		tst.b	(f_restart).w
		beq.s	SS_NormalExit
		tst.l	(v_plc_buffer).w
		bne.s	SS_NormalExit
		move.w	#sfx_EnterSS,d0
		bsr.w	PlaySound_Special ; play special stage exit sound
		bra.w	PaletteWhiteOut
; ===========================================================================

SS_ToSegaScreen:
		move.b	#id_Sega,(v_gamemode).w ; goto Sega screen
		rts

SS_ToLevel:	; Check if branch to this is needed
		cmpi.b	#id_Level,(v_gamemode).w
		beq.s	SS_ToSegaScreen
		rts

; ---------------------------------------------------------------------------
; Special stage	background loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_BGLoad:
		lea		(v_ssbuffer1&$FFFFFF).l,a1
		lea		(Eni_SSBg1).l,a0	; load mappings for the birds and fish
		move.w	#make_art_tile(ArtTile_SS_Background_Fish,2,0),d0
		bsr.w	EniDec
		locVRAM	ArtTile_SS_Plane_1*tile_size+plane_size_64x32,d3
		lea		((v_ssbuffer1+$80)&$FFFFFF).l,a2
		moveq	#7-1,d7				; $5000, $6000, $7000, $8000, $9000, $A000, $B000

loc_48BE:
		move.l	d3,d0
		moveq	#3,d6
		moveq	#0,d4
		cmpi.w	#4-1,d7 ; $8000
		bhs.s	loc_48CC
		moveq	#1,d4

loc_48CC:
		moveq	#8-1,d5

loc_48CE:
		movea.l	a2,a1
		eori.b	#1,d4
		bne.s	loc_48E2
		cmpi.w	#6,d7
		bne.s	loc_48F2

		lea		(v_ssbuffer1&$FFFFFF).l,a1

loc_48E2:
		movem.l	d0-d4,-(sp)
		moveq	#8-1,d1
		moveq	#8-1,d2
		bsr.w	TilemapToVRAM
		movem.l	(sp)+,d0-d4

loc_48F2:
		addi.l	#$100000,d0
		dbf		d5,loc_48CE

		addi.l	#$3800000,d0
		eori.b	#1,d4
		dbf		d6,loc_48CC

		addi.l	#$10000000,d3
		bpl.s	loc_491C
		swap	d3
		addi.l	#$C000,d3
		swap	d3

loc_491C:
		adda.w	#$80,a2
		dbf		d7,loc_48BE

		lea		(v_ssbuffer1&$FFFFFF).l,a1
		lea		(Eni_SSBg2).l,a0			; load mappings for the clouds
		move.w	#make_art_tile(ArtTile_SS_Background_Clouds,2,0),d0
		bsr.w	EniDec
		copyTilemap	v_ssbuffer1&$FFFFFF,ArtTile_SS_Plane_5*tile_size,64,32
		copyTilemap	v_ssbuffer1&$FFFFFF,ArtTile_SS_Plane_5*tile_size+plane_size_64x32,64,64
		rts	
; End of function SS_BGLoad

; ---------------------------------------------------------------------------
; Palette cycling routine - special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_SS:
		tst.b	(f_pause).w
		bne.s	locret_49E6
		subq.w	#1,(v_palss_time).w
		bpl.s	locret_49E6

		lea		(vdp_control_port).l,a6
		move.w	(v_palss_num).w,d0
		addq.w	#1,(v_palss_num).w
		andi.w	#$1F,d0
		lsl.w	#2,d0
		lea		(byte_4A3C).l,a0
		adda.w	d0,a0

	; Time
		move.b	(a0)+,d0
		bpl.s	loc_4992
		move.w	#$1FF,d0

loc_4992:
		move.w	d0,(v_palss_time).w

	; Anim
		moveq	#0,d0
		move.b	(a0)+,d0
		move.w	d0,(v_ssbganim).w
		lea		(byte_4ABC).l,a1
		lea		(a1,d0.w),a1

	; FG VRAM
		move.w	#$8200,d0
		move.b	(a1)+,d0
		move.w	d0,(a6)
		
	; Y coordinate
		move.b	(a1),(v_scrposy_vdp).w

	; BG VRAM
		move.w	#$8400,d0
		move.b	(a0)+,d0
		move.w	d0,(a6)
		move.l	#$40000010,(vdp_control_port).l
		move.l	(v_scrposy_vdp).w,(vdp_data_port).l

	; Palette cycle index
		moveq	#0,d0
		move.b	(a0)+,d0
		bmi.s	loc_49E8
		lea		(Pal_SSCyc1).l,a1
		adda.w	d0,a1
		lea		(v_palette+$4E).w,a2
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+

locret_49E6:
		rts	
; ===========================================================================

loc_49E8:
		move.w	(v_palss_index).w,d1	; Doesn't seem to ever be modified...
		cmpi.w	#$8A,d0
		blo.s	loc_49F4
		addq.w	#1,d1

loc_49F4:
		mulu.w	#$2A,d1
		lea		(Pal_SSCyc2).l,a1
		adda.w	d1,a1
		andi.w	#$7F,d0

		bclr	#0,d0
		beq.s	loc_4A18
		lea		(v_palette+$6E).w,a2
		move.l	(a1),(a2)+
		move.l	4(a1),(a2)+
		move.l	8(a1),(a2)+

loc_4A18:
		adda.w	#$C,a1
		lea		(v_palette+$5A).w,a2
		cmpi.w	#$A,d0
		blo.s	loc_4A2E
		subi.w	#$A,d0
		lea		(v_palette+$7A).w,a2

loc_4A2E:
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		adda.w	d0,a1
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		rts	
; End of function PalCycle_SS

; ===========================================================================

SSBGData:	macro time,anim,vram,index,flag1,flag2
		dc.b	(time), (anim), ((vram)*tile_size)>>13
	if flag1
		dc.b	(index)|$80|(flag2)
	else
		dc.b	(index)*12
	endif
		endm

byte_4A3C:
		; Time, anim, BG VRAM, palette cycle index & flags
		SSBGData  3,  0, ArtTile_SS_Plane_6, 18, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_6, 16, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_6, 14, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_6, 12, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_6, 10, TRUE , TRUE

		SSBGData  3,  0, ArtTile_SS_Plane_6,  0, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_6,  2, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_6,  4, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_6,  6, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_6,  8, TRUE , FALSE


		SSBGData  7,  8, ArtTile_SS_Plane_6,  0, FALSE, FALSE
		SSBGData  7, 10, ArtTile_SS_Plane_6,  1, FALSE, FALSE
		SSBGData -1, 12, ArtTile_SS_Plane_6,  2, FALSE, FALSE
		SSBGData -1, 12, ArtTile_SS_Plane_6,  2, FALSE, FALSE
		SSBGData  7, 10, ArtTile_SS_Plane_6,  1, FALSE, FALSE
		SSBGData  7,  8, ArtTile_SS_Plane_6,  0, FALSE, FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5,  8, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5,  6, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5,  4, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5,  2, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5,  0, TRUE , TRUE

		SSBGData  3,  0, ArtTile_SS_Plane_5, 10, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5, 12, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5, 14, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5, 16, TRUE , FALSE
		SSBGData  3,  0, ArtTile_SS_Plane_5, 18, TRUE , FALSE

		SSBGData  7,  2, ArtTile_SS_Plane_5,  3, FALSE, FALSE
		SSBGData  7,  4, ArtTile_SS_Plane_5,  4, FALSE, FALSE
		SSBGData -1,  6, ArtTile_SS_Plane_5,  5, FALSE, FALSE
		SSBGData -1,  6, ArtTile_SS_Plane_5,  5, FALSE, FALSE
		SSBGData  7,  4, ArtTile_SS_Plane_5,  4, FALSE, FALSE
		SSBGData  7,  2, ArtTile_SS_Plane_5,  3, FALSE, FALSE
		even

SSFGData:	macro vram,y
		dc.b ((vram)*tile_size)>>10, (y)>>8
		endm

byte_4ABC:
		; FG VRAM, Y coordinate
		SSFGData ArtTile_SS_Plane_1, $100
		SSFGData ArtTile_SS_Plane_2,    0
		SSFGData ArtTile_SS_Plane_2, $100
		SSFGData ArtTile_SS_Plane_3,    0
		SSFGData ArtTile_SS_Plane_3, $100
		SSFGData ArtTile_SS_Plane_4,    0
		SSFGData ArtTile_SS_Plane_4, $100
		even

; ===========================================================================

Pal_SSCyc1:	binclude	"palette/Cycle - Special Stage 1.bin"
		even
Pal_SSCyc2:	binclude	"palette/Cycle - Special Stage 2.bin"
		even

; ---------------------------------------------------------------------------
; Subroutine to	make the special stage background animated
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_BGAnimate:
		move.w	(v_ssbganim).w,d0
		bne.s	loc_4BF6
		clr.w	(v_bgscreenposy).w
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w

loc_4BF6:
		cmpi.w	#8,d0
		bhs.s	loc_4C4E
		cmpi.w	#6,d0
		bne.s	loc_4C10
		addq.w	#1,(v_bg3screenposx).w
		addq.w	#1,(v_bgscreenposy).w
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w

loc_4C10:
		moveq	#0,d0
		move.w	(v_bgscreenposx).w,d0
		neg.w	d0
		swap	d0
		lea	(byte_4CCC).l,a1
		lea	(v_ngfx_buffer).w,a3
		moveq	#9,d3

loc_4C26:
		move.w	2(a3),d0
		bsr.w	CalcSine
		moveq	#0,d2
		move.b	(a1)+,d2
		muls.w	d2,d0
		asr.l	#8,d0
		move.w	d0,(a3)+
		move.b	(a1)+,d2
		ext.w	d2
		add.w	d2,(a3)+
		dbf	d3,loc_4C26
		lea	(v_ngfx_buffer).w,a3
		lea	(byte_4CB8).l,a2
		bra.s	loc_4C7E
; ===========================================================================

loc_4C4E:
		cmpi.w	#$C,d0
		bne.s	loc_4C74
		subq.w	#1,(v_bg3screenposx).w
		lea	(v_ssscroll_buffer).w,a3
		move.l	#$18000,d2
		moveq	#7-1,d1

loc_4C64:
		move.l	(a3),d0
		sub.l	d2,d0
		move.l	d0,(a3)+
		subi.l	#$2000,d2
		dbf	d1,loc_4C64

loc_4C74:
		lea	(v_ssscroll_buffer).w,a3
		lea	(byte_4CC4).l,a2

loc_4C7E:
		lea	(v_hscrolltablebuffer).w,a1
		move.w	(v_bg3screenposx).w,d0
		neg.w	d0
		swap	d0
		moveq	#0,d3
		move.b	(a2)+,d3
		move.w	(v_bgscreenposy).w,d2
		neg.w	d2
		andi.w	#$FF,d2
		lsl.w	#2,d2

loc_4C9A:
		move.w	(a3)+,d0
		addq.w	#2,a3
		moveq	#0,d1
		move.b	(a2)+,d1
		subq.w	#1,d1

loc_4CA4:
		move.l	d0,(a1,d2.w)
		addq.w	#4,d2
		andi.w	#$3FC,d2
		dbf	d1,loc_4CA4
		dbf	d3,loc_4C9A
		rts	
; End of function SS_BGAnimate

; ===========================================================================
byte_4CB8:	dc.b 9,	$28, $18, $10, $28, $18, $10, $30, $18,	8, $10,	0
		even
byte_4CC4:	dc.b 6,	$30, $30, $30, $28, $18, $18, $18
		even
byte_4CCC:	dc.b 8,	2, 4, $FF, 2, 3, 8, $FF, 4, 2, 2, 3, 8,	$FD, 4,	2, 2, 3, 2, $FF
		even

; ===========================================================================

; ---------------------------------------------------------------------------
; Continue screen
; ---------------------------------------------------------------------------

GM_Continue:
		bsr.w	PaletteFadeOut
		disable_ints
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		lea		(vdp_control_port).l,a6
		move.w	#$8004,(a6)				; 8 colour mode
		move.w	#$8700,(a6)				; background colour
		bsr.w	ClearScreen
		clr.b	(f_levelstarted).w		; RetroKoH S3K Rings Manager

		clearRAM v_objspace

		locVRAM	ArtTile_Title_Card*tile_size

	if OptimalTitleCardArt
	; RetroKoH Optimal Title Cards for VRAM/SpritePiece Reduction
		lea		Art_TitCardContinue,a0												; load title card patterns
		move.l	#((Art_TitCardContinue_End-Art_TitCardContinue)/tile_size)-1,d0		; # of tiles
		jsr		(LoadUncArt).w
	; Optimal Title Cards End
	else
	; AURORA☆FIELDS Title Card Optimization
		lea		Art_TitleCard,a0									; load title card patterns
		move.l	#((Art_TitleCard_End-Art_TitleCard)/tile_size)-1,d0	; # of tiles
		jsr		(LoadUncArt).w
	; Title Card Optimization End
	endif

		locVRAM	ArtTile_Continue_Sonic*tile_size
		lea		(Nem_ContSonic).l,a0						; load Sonic patterns
		bsr.w	NemDec
		locVRAM	ArtTile_Mini_Sonic*tile_size
		lea		(Nem_MiniSonic).l,a0						; load continue() and Mini Sonic patterns
		bsr.w	NemDec
		moveq	#10,d1
		jsr		(ContScrCounter).l							; run countdown	(start from 10)
		moveq	#palid_Continue,d0
		bsr.w	PalLoad_Fade								; load continue	screen palette
		move.b	#bgm_Continue,d0
		bsr.w	PlaySound									; play continue	music
		move.w	#659,(v_demolength).w						; set time delay to 11 seconds
		clr.l	(v_screenposx).w
		move.l	#$1000000,(v_screenposy).w
		move.b	#id_ContSonic,(v_player).w					; load Sonic object
		move.b	#id_ContScrItem,(v_continuetext).w			; load continue screen objects
		move.b	#id_ContScrItem,(v_continuelight).w
		move.b	#4,(v_continuelight+obFrame).w
		move.b	#id_ContScrItem,(v_continueicon).w
		move.b	#4,(v_continueicon+obRoutine).w
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	PaletteFadeIn

; ---------------------------------------------------------------------------
; Continue screen main loop
; ---------------------------------------------------------------------------

Cont_MainLoop:
		move.b	#$16,(v_vbla_routine).w
		bsr.w	WaitForVBla
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	loc_4DF2
		disable_ints
		move.w	(v_demolength).w,d1
		divu.w	#$3C,d1
		andi.l	#$F,d1
		jsr		(ContScrCounter).l
		enable_ints

loc_4DF2:
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		cmpi.w	#$180,(v_player+obX).w		; has Sonic run off screen?
		bhs.s	Cont_GotoLevel				; if yes, branch
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	Cont_MainLoop
		tst.w	(v_demolength).w
		bne.w	Cont_MainLoop
		move.b	#id_Sega,(v_gamemode).w		; go to Sega screen
		rts	
; ===========================================================================

Cont_GotoLevel:
		move.b	#id_Level,(v_gamemode).w	; set screen mode to $0C (level)
		move.b	#3,(v_lives).w				; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w				; clear rings
		move.l	d0,(v_time).w				; clear time

	if HUDCentiseconds=1	; Mercury HUD Centiseconds
		move.b	d0,(v_centstep).w
	endif	; HUD Centiseconds End

		move.l	d0,(v_score).w				; clear score
		move.b	d0,(v_lastlamp).w			; clear lamppost count
		subq.b	#1,(v_continues).w			; subtract 1 from continues
		rts	
; ===========================================================================

		include	"_incObj/80 Continue Screen Elements.asm"
		include	"_incObj/81 Continue Screen Sonic.asm"
		include	"_anim/Continue Screen Sonic.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Ending sequence in Green Hill	Zone
; ---------------------------------------------------------------------------

GM_Ending:
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	PaletteFadeOut

		clearRAM v_objspace
		clearRAM v_misc_variables
		clearRAM v_levelvariables
		clearRAM v_timingandscreenvariables

		disable_ints
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	ClearScreen
		lea		(vdp_control_port).l,a6
		move.w	#$8B03,(a6)	; line scroll mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$8500+(vram_sprites>>9),(a6) ; set sprite table address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		move.w	#$8004,(a6)		; 8-colour mode
		move.w	#$8720,(a6)		; set background colour (line 3; colour 0)
		move.w	#$8A00+223,(v_hbla_hreg).w ; set palette change position (for water)
		move.w	(v_hbla_hreg).w,(a6)
		move.b	#30,(v_air).w
		move.w	#id_EndZ<<8,(v_zone).w ; set level number to 0600 (extra flowers)
		cmpi.b	#emldCount,(v_emeralds).w ; do you have all emeralds?
		beq.s	End_LoadData	; if yes, branch
		move.w	#(id_EndZ<<8)+1,(v_zone).w ; set level number to 0601 (no flowers)

End_LoadData:
		jsr		(AnimateLevelGfx_Init).l
		moveq	#plcid_Ending,d0
		bsr.w	QuickPLC							; load ending sequence patterns
		bsr.w	LevelSizeLoad
		bsr.w	DeformLayers
		bset	#2,(v_fg_scroll_flags).w
		bsr.w	LevelDataLoad						; load level art -- Clownacy Level Art Loading + load block mappings and palettes
		bsr.w	LoadTilesFromStart
		lea		(Col_GHZ_1).l,a0					; MJ: Set first collision for ending
		lea		(v_collision1).w,a1
		bsr.w	KosDec
		lea		(Col_GHZ_2).l,a0					; MJ: Set second collision for ending
		lea		(v_collision2).w,a1
		bsr.w	KosDec
		enable_ints
		lea		(Kos_EndFlowers).l,a0				; load extra flower patterns
		lea		((v_128x128+$1000)&$FFFFFF).l,a1	; RAM address to buffer the patterns
		bsr.w	KosDec
		moveq	#palid_Sonic,d0
		bsr.w	PalLoad_Fade						; load Sonic's palette
		move.w	#bgm_Ending,d0
		bsr.w	PlaySound							; play ending sequence music
		move.b	d0,(v_lastbgmplayed).w				; store last played music

End_LoadSonic:
		move.b	#id_SonicPlayer,(v_player).w		; load Sonic object
		bset	#staFacing,(v_player+obStatus).w	; make Sonic face left
		move.b	#1,(f_lockctrl).w					; lock controls
		move.w	#(btnL<<8),(v_jpadhold2).w			; move Sonic to the left
		move.w	#$F800,(v_player+obInertia).w		; set Sonic's speed
		jsr		(ObjPosLoad).l
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		moveq	#0,d0
		move.w	d0,(v_rings).w
		move.l	d0,(v_time).w
		move.b	d0,(v_lifecount).w
		move.w	d0,(v_debuguse).w
		move.b	d0,(f_restart).w
		move.w	d0,(v_framecount).w
		move.w	d0,(f_debugmode).w					; disable debug mode
		bsr.w	OscillateNumInit
		move.w	#1800,(v_demolength).w
		move.b	#$18,(v_vbla_routine).w
		bsr.w	WaitForVBla
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		move.w	#$3F,(v_pfade_start).w
		bsr.w	PaletteFadeIn

; ---------------------------------------------------------------------------
; Main ending sequence loop
; ---------------------------------------------------------------------------

End_MainLoop:
		bsr.w	PauseGame
		move.b	#$18,(v_vbla_routine).w
		bsr.w	WaitForVBla
		addq.w	#1,(v_framecount).w
		bsr.w	End_MoveSonic
		jsr		(ExecuteObjects).l
		bsr.w	DeformLayers
		jsr		(BuildSprites).l
		jsr		(ObjPosLoad).l
		jsr		(AnimateLevelGfx).l
		bsr.w	PaletteCycle
		bsr.w	OscillateNumDo
		bsr.w	SynchroAnimate
		cmpi.b	#id_Ending,(v_gamemode).w	; is game mode $18 (ending)?
		beq.s	End_ChkEmerald				; if yes, branch

		move.b	#id_Credits,(v_gamemode).w	; goto credits
		clr.w	(v_creditsnum).w			; set credits index number to 0
		move.b	#bgm_Credits,d0
		bra.w	PlaySound_Special			; play credits music
; ===========================================================================

End_ChkEmerald:
		tst.b	(f_restart).w				; has Sonic released the emeralds?
		beq.w	End_MainLoop				; if not, branch

		clr.b	(f_restart).w
		move.w	#$3F,(v_pfade_start).w
		clr.w	(v_palchgspeed).w

End_AllEmlds:
		bsr.w	PauseGame
		move.b	#$18,(v_vbla_routine).w
		bsr.w	WaitForVBla
		addq.w	#1,(v_framecount).w
		bsr.w	End_MoveSonic
		jsr		(ExecuteObjects).l
		bsr.w	DeformLayers
		jsr		(BuildSprites).l
		jsr		(ObjPosLoad).l
		bsr.w	OscillateNumDo
		bsr.w	SynchroAnimate
		subq.w	#1,(v_palchgspeed).w
		bpl.s	End_SlowFade
		move.w	#2,(v_palchgspeed).w
		bsr.w	WhiteOut_ToWhite

End_SlowFade:
		tst.b	(f_restart).w
		beq.w	End_AllEmlds
		clr.b	(f_restart).w
		move.l	#$AAABAE9A,(v_lvllayout+$200).w	; MJ: modify level layout
		move.l	#$ACADAFB0,(v_lvllayout+$300).w
		lea		(vdp_control_port).l,a5
		lea		(vdp_data_port).l,a6
		lea		(v_screenposx).w,a3
		lea		(v_lvllayout).w,a4
		move.w	#$4000,d2
		bsr.w	DrawChunks
		moveq	#palid_Ending,d0
		bsr.w	PalLoad_Fade					; load ending palette
	if SuperMod=1
		bsr.w	PalLoad_EndFlowers
	endif
		bsr.w	PaletteWhiteIn
		bra.w	End_MainLoop

; ---------------------------------------------------------------------------
; Subroutine controlling Sonic on the ending sequence
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


End_MoveSonic:
		move.b	(v_sonicend).w,d0
		bne.s	End_MoveSon2
		cmpi.w	#$90,(v_player+obX).w ; has Sonic passed $90 on x-axis?
		bhs.s	End_MoveSonExit	; if not, branch

		addq.b	#2,(v_sonicend).w
		move.b	#1,(f_lockctrl).w ; lock player's controls
		move.w	#(btnR<<8),(v_jpadhold2).w ; move Sonic to the right
		rts	
; ===========================================================================

End_MoveSon2:
		subq.b	#2,d0
		bne.s	End_MoveSon3
		cmpi.w	#$A0,(v_player+obX).w ; has Sonic passed $A0 on x-axis?
		blo.s	End_MoveSonExit	; if not, branch

		addq.b	#2,(v_sonicend).w
		moveq	#0,d0
		move.b	d0,(f_lockctrl).w
		move.w	d0,(v_jpadhold2).w ; stop Sonic moving
		move.w	d0,(v_player+obInertia).w
		move.b	#$81,(v_player+obCtrlLock).w ; lock controls and disable object interaction
		move.b	#fr_SonWait2,(v_player+obFrame).w
		move.w	#(aniID_Wait<<8)+aniID_Wait,(v_player+obAnim).w ; use "standing" animation
		move.b	#3,(v_player+obTimeFrame).w
		rts	
; ===========================================================================

End_MoveSon3:
		subq.b	#2,d0
		bne.s	End_MoveSonExit
		addq.b	#2,(v_sonicend).w
		move.w	#$A0,(v_player+obX).w
		move.b	#id_EndSonic,(v_player).w ; load Sonic ending sequence object
		clr.w	(v_player+obRoutine).w

End_MoveSonExit:
		rts	
; End of function End_MoveSonic

; ===========================================================================

		include	"_incObj/87 Ending Sequence Sonic.asm"
		include "_anim/Ending Sequence Sonic.asm"
		include	"_incObj/88 Ending Sequence Emeralds.asm"
		include	"_incObj/89 Ending Sequence STH.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Credits ending sequence
; ---------------------------------------------------------------------------

GM_Credits:
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		lea		(vdp_control_port).l,a6
		move.w	#$8004,(a6)		; 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		move.w	#$9200,(a6)		; window vertical position
		move.w	#$8B03,(a6)		; line scroll mode
		move.w	#$8720,(a6)		; set background colour (line 3; colour 0)
		clr.b	(f_wtr_state).w
		bsr.w	ClearScreen
		clr.b	(f_levelstarted).w	; RetroKoH S3K Rings Manager

		clearRAM v_objspace

		locVRAM	ArtTile_Credits_Font*tile_size
		lea		(Nem_CreditText).l,a0 ;	load credits alphabet patterns
		bsr.w	NemDec

		clearRAM v_palette_fading

		moveq	#palid_Sonic,d0
		bsr.w	PalLoad_Fade						; load Sonic's palette
		move.b	#id_CreditsText,(v_credits).w	; load credits object
		jsr		(ExecuteObjects).l
		jsr		(BuildSprites).l
		bsr.w	EndingDemoLoad
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#4,d0
		lea		(LevelHeaders).l,a2		; a2 = LevelHeaders address
		lea		(a2,d0.w),a2			; a2 = LevelHeaders + zone offset
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	Cred_SkipObjGfx
		bsr.w	AddPLC					; load object graphics

Cred_SkipObjGfx:
		moveq	#plcid_Main2,d0
		bsr.w	AddPLC					; load standard	level graphics
		move.w	#120,(v_demolength).w	; display a credit for 2 seconds
		bsr.w	PaletteFadeIn

Cred_WaitLoop:
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	RunPLC
		tst.w	(v_demolength).w ; have 2 seconds elapsed?
		bne.s	Cred_WaitLoop	; if not, branch
		tst.l	(v_plc_buffer).w ; have level gfx finished decompressing?
		bne.s	Cred_WaitLoop	; if not, branch
		cmpi.w	#9,(v_creditsnum).w ; have the credits finished?
		beq.w	TryAgainEnd	; if yes, branch
		rts	

; ---------------------------------------------------------------------------
; Ending sequence demo loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


EndingDemoLoad:
		move.w	(v_creditsnum).w,d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	EndDemo_Levels(pc,d0.w),d0	; load level array
		move.w	d0,(v_zone).w				; set level from level array
		addq.w	#1,(v_creditsnum).w
		cmpi.w	#9,(v_creditsnum).w			; have credits finished?
		bhs.s	EndDemo_Exit				; if yes, branch
		move.w	#$8001,(f_demo).w			; set demo+ending mode
		move.b	#id_Demo,(v_gamemode).w		; set game mode to 8 (demo)
		move.b	#3,(v_lives).w				; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w				; clear rings
		move.l	d0,(v_time).w				; clear time
		move.l	d0,(v_score).w				; clear score
		move.b	d0,(v_lastlamp).w			; clear lamppost counter
		cmpi.w	#4,(v_creditsnum).w			; is SLZ demo running?
		bne.s	EndDemo_Exit				; if not, branch
		lea		(EndDemo_LampVar).l,a1		; load lamppost variables
		lea		(v_lastlamp).w,a2
		moveq	#8,d0

EndDemo_LampLoad:
		move.l	(a1)+,(a2)+
		dbf		d0,EndDemo_LampLoad

EndDemo_Exit:
		rts	
; End of function EndingDemoLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Levels used in the end sequence demos
; ---------------------------------------------------------------------------
EndDemo_Levels:	binclude	"misc/Demo Level Order - Ending.bin"

; ---------------------------------------------------------------------------
; Lamppost variables in the end sequence demo (Star Light Zone)
; ---------------------------------------------------------------------------
EndDemo_LampVar:
		dc.b 1,	1		; number of the last lamppost
		dc.w $A00, $62C		; x/y-axis position
		dc.w 13			; rings
		dc.l 0			; time
		dc.b 0,	0		; dynamic level event routine counter
		dc.w $800		; level bottom boundary
		dc.w $957, $5CC		; x/y axis screen position
		dc.w $4AB, $3A6, 0, $28C, 0, 0 ; scroll info
		dc.w $308		; water height
		dc.b 1,	1		; water routine and state
; ===========================================================================
; ---------------------------------------------------------------------------
; "TRY AGAIN" and "END"	screens
; ---------------------------------------------------------------------------

TryAgainEnd:
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)	; use 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$9001,(a6)	; 64-cell hscroll size
		move.w	#$9200,(a6)	; window vertical position
		move.w	#$8B03,(a6)	; line scroll mode
		move.w	#$8720,(a6)	; set background colour (line 3; colour 0)
		clr.b	(f_wtr_state).w
		bsr.w	ClearScreen

		clearRAM v_objspace

		moveq	#plcid_TryAgain,d0
		bsr.w	QuickPLC	; load "TRY AGAIN" or "END" patterns

		clearRAM v_palette_fading

		moveq	#palid_Ending,d0
		bsr.w	PalLoad_Fade	; load ending palette
		clr.w	(v_palette_fading+$40).w
		move.b	#id_EndEggman,(v_endeggman).w ; load Eggman object
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		move.w	#1800,(v_demolength).w ; show screen for 30 seconds
		bsr.w	PaletteFadeIn

; ---------------------------------------------------------------------------
; "TRY AGAIN" and "END"	screen main loop
; ---------------------------------------------------------------------------
TryAg_MainLoop:
		bsr.w	PauseGame
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		andi.b	#btnStart,(v_jpadpress1).w ; is Start button pressed?
		bne.s	TryAg_Exit	; if yes, branch
		tst.w	(v_demolength).w ; has 30 seconds elapsed?
		beq.s	TryAg_Exit	; if yes, branch
		cmpi.b	#id_Credits,(v_gamemode).w
		beq.s	TryAg_MainLoop

TryAg_Exit:
		move.b	#id_Sega,(v_gamemode).w ; goto Sega screen
		rts
; ===========================================================================

		include	"_incObj/8B Try Again & End Eggman.asm"
		include "_anim/Try Again & End Eggman.asm"
		include	"_incObj/8C Try Again Emeralds.asm"

; ---------------------------------------------------------------------------
; Ending sequence demos
; ---------------------------------------------------------------------------
Demo_EndGHZ1:	binclude	"demodata/Ending - GHZ1.bin"
		even
Demo_EndMZ:	binclude	"demodata/Ending - MZ.bin"
		even
Demo_EndSYZ:	binclude	"demodata/Ending - SYZ.bin"
		even
Demo_EndLZ:	binclude	"demodata/Ending - LZ.bin"
		even
Demo_EndSLZ:	binclude	"demodata/Ending - SLZ.bin"
		even
Demo_EndSBZ1:	binclude	"demodata/Ending - SBZ1.bin"
		even
Demo_EndSBZ2:	binclude	"demodata/Ending - SBZ2.bin"
		even
Demo_EndGHZ2:	binclude	"demodata/Ending - GHZ2.bin"
		even
; ===========================================================================

		include	"_incObj/sub AnimateSprite.asm"		; Moved here to make every jmp use ().w address mode

		include	"_inc/LevelSizeLoad & BgScrollSpeed.asm"
		include	"_inc/DeformLayers.asm"


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; sub_6886:
LoadTilesAsYouMove_BGOnly:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_bg1_scroll_flags).w,a2
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$80).w,a4		; MJ: Load address of layout BG
		move.w	#$6000,d2
		bsr.w	DrawBGScrollBlock1
		lea	(v_bg2_scroll_flags).w,a2
		lea	(v_bg2screenposx).w,a3
		bra.w	DrawBGScrollBlock2
; End of function sub_6886

; ---------------------------------------------------------------------------
; Subroutine to	display	correct	tiles as you move
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesAsYouMove:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		; First, update the background
		lea	(v_bg1_scroll_flags_dup).w,a2	; Scroll block 1 scroll flags
		lea	(v_bgscreenposx_dup).w,a3		; Scroll block 1 X coordinate
		lea	(v_lvllayout+$80).w,a4			; MJ: Load address of layout BG
		move.w	#$6000,d2					; VRAM thing for selecting Plane B
		bsr.w	DrawBGScrollBlock1
		lea	(v_bg2_scroll_flags_dup).w,a2	; Scroll block 2 scroll flags
		lea	(v_bg2screenposx_dup).w,a3		; Scroll block 2 X coordinate
		bsr.w	DrawBGScrollBlock2
		; REV01 added a third scroll block, though, technically,
		; the RAM for it was already there in REV00
		lea	(v_bg3_scroll_flags_dup).w,a2	; Scroll block 3 scroll flags
		lea	(v_bg3screenposx_dup).w,a3		; Scroll block 3 X coordinate
		bsr.w	DrawBGScrollBlock3
		; Then, update the foreground
		lea	(v_fg_scroll_flags_dup).w,a2	; Foreground scroll flags
		lea	(v_screenposx_dup).w,a3			; Foreground X coordinate
		lea	(v_lvllayout).w,a4				; MJ: Load address of layout
		move.w	#$4000,d2					; VRAM thing for selecting Plane A
		; The FG's update function is inlined here
		tst.b	(a2)
		beq.s	locret_6952					; If there are no flags set, nothing needs updating
		bclr	#0,(a2)
		beq.s	loc_6908
		; Draw new tiles at the top
		moveq	#-16,d4	; Y coordinate. Note that 16 is the size of a block in pixels
		moveq	#-16,d5 ; X coordinate
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4 ; Y coordinate
		moveq	#-16,d5 ; X coordinate
		bsr.w	DrawBlocks_LR

loc_6908:
		bclr	#1,(a2)
		beq.s	loc_6922
		; Draw new tiles at the bottom
		move.w	#224,d4	; Start at bottom of the screen. Since this draws from top to bottom, we don't need 224+16
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_6922:
		bclr	#2,(a2)
		beq.s	loc_6938
		; Draw new tiles on the left
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_TB

loc_6938:
		bclr	#3,(a2)
		beq.s	locret_6952
		; Draw new tiles on the right
		moveq	#-16,d4
		move.w	#336,d5			; Was 320 -- Spirituinsanum top-right corner reloading glitch Fix
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		move.w	#336,d5			; Was 320 -- Spirituinsanum top-right corner reloading glitch Fix
		bra.w	DrawBlocks_TB

locret_6952:
		rts	
; End of function LoadTilesAsYouMove


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; sub_6954:
DrawBGScrollBlock1:
		tst.b	(a2)
		beq.w	locret_69F2
		bclr	#0,(a2)
		beq.s	loc_6972
		; Draw new tiles at the top
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_6972:
		bclr	#1,(a2)
		beq.s	loc_698E
		; Draw new tiles at the top
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_698E:
		bclr	#2,(a2)
		beq.s	locj_6D56
		; Draw new tiles on the left
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_TB
locj_6D56:

		bclr	#3,(a2)
		beq.s	locj_6D70
		; Draw new tiles on the right
		moveq	#-16,d4
		move.w	#336,d5			; Was 320 -- Spirituinsanum top-right corner reloading glitch Fix
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		move.w	#336,d5			; Was 320 -- Spirituinsanum top-right corner reloading glitch Fix
		bsr.w	DrawBlocks_TB
locj_6D70:

		bclr	#4,(a2)
		beq.s	locj_6D88
		; Draw entire row at the top
		moveq	#-16,d4
		moveq	#0,d5
		bsr.w	Calc_VRAM_Pos_2
		moveq	#-16,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6D88:

		bclr	#5,(a2)
		beq.s	locret_69F2
		; Draw entire row at the bottom
		move.w	#224,d4
		moveq	#0,d5
		bsr.w	Calc_VRAM_Pos_2
		move.w	#224,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bra.w	DrawBlocks_LR_3

locret_69F2:
		rts	
; End of function DrawBGScrollBlock1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Essentially, this draws everything that isn't scroll block 1
; sub_69F4:
DrawBGScrollBlock2:
		tst.b	(a2)
		beq.w	locj_6DF2
		cmpi.b	#id_SBZ,(v_zone).w
		beq.w	Draw_SBz
		bclr	#0,(a2)
		beq.s	locj_6DD2
		; Draw new tiles on the left
		move.w	#224/2,d4	; Draw the bottom half of the screen
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224/2,d4
		moveq	#-16,d5
		moveq	#3-1,d6		; Draw three rows... could this be a repurposed version of the above unused code?
		bsr.w	DrawBlocks_TB_2
locj_6DD2:
		bclr	#1,(a2)
		beq.s	locj_6DF2
		; Draw new tiles on the right
		move.w	#224/2,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224/2,d4
		move.w	#320,d5
		moveq	#3-1,d6
		bra.w	DrawBlocks_TB_2
locj_6DF2:
		rts
;===============================================================================
locj_6DF4:
		dc.b $00,$00,$00,$00,$00,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$04
		dc.b $04,$04,$04,$04,$04,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$00						
;===============================================================================
Draw_SBz:
		moveq	#-16,d4
		bclr	#0,(a2)
		bne.s	locj_6E28
		bclr	#1,(a2)
		beq.s	locj_6E72
		move.w	#224,d4
locj_6E28:
		lea	(locj_6DF4+1).l,a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		lea	(locj_6FE4).l,a3
		movea.w	(a3,d0.w),a3
		beq.s	locj_6E5E
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_6E72
;===============================================================================
locj_6E5E:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6E72:
		tst.b	(a2)
		bne.s	locj_6E78
		rts
;===============================================================================			
locj_6E78:
		moveq	#-16,d4
		moveq	#-16,d5
		move.b	(a2),d0
		andi.b	#$A8,d0
		beq.s	locj_6E8C
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#320,d5
locj_6E8C:
		lea	(locj_6DF4).l,a0
		move.w	(v_bgscreenposy).w,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	locj_6FEC						
;===============================================================================


; locj_6EA4:
DrawBGScrollBlock3:
		tst.b	(a2)
		beq.w	locj_6EF0
		cmpi.b	#id_MZ,(v_zone).w
		beq.w	Draw_Mz
		bclr	#0,(a2)
		beq.s	locj_6ED0
		; Draw new tiles on the left
		move.w	#$40,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$40,d4
		moveq	#-16,d5
		moveq	#3-1,d6
		bsr.w	DrawBlocks_TB_2
locj_6ED0:
		bclr	#1,(a2)
		beq.s	locj_6EF0
		; Draw new tiles on the right
		move.w	#$40,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$40,d4
		move.w	#320,d5
		moveq	#3-1,d6
		bra.w	DrawBlocks_TB_2
locj_6EF0:
		rts
locj_6EF2:
		dc.b $00,$00,$00,$00,$00,$00,$06,$06,$04,$04,$04,$04,$04,$04,$04,$04
		dc.b $04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$00
;===============================================================================
Draw_Mz:
		moveq	#-16,d4
		bclr	#0,(a2)
		bne.s	locj_6F66
		bclr	#1,(a2)
		beq.s	locj_6FAE
		move.w	#224,d4
locj_6F66:
		lea	(locj_6EF2+1).l,a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		add.w	d4,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	locj_6FE4(pc,d0.w),a3
		beq.s	locj_6F9A
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_6FAE
;===============================================================================
locj_6F9A:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6FAE:
		tst.b	(a2)
		bne.s	locj_6FB4
		rts
;===============================================================================			
locj_6FB4:
		moveq	#-16,d4
		moveq	#-16,d5
		move.b	(a2),d0
		andi.b	#$A8,d0
		beq.s	locj_6FC8
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#320,d5
locj_6FC8:
		lea	(locj_6EF2).l,a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	locj_6FEC
;===============================================================================			
locj_6FE4:
		dc.w v_bgscreenposx_dup, v_bgscreenposx_dup, v_bg2screenposx_dup, v_bg3screenposx_dup
locj_6FEC:
		moveq	#((224+16+16)/16)-1,d6
		move.l	#$800000,d7
locj_6FF4:			
		moveq	#0,d0
		move.b	(a0)+,d0
		btst	d0,(a2)
		beq.s	locj_701C
		movea.w	locj_6FE4(pc,d0.w),a3
		movem.l	d4/d5/a0,-(sp)
		movem.l	d4/d5,-(sp)
		bsr.w	GetBlockData
		movem.l	(sp)+,d4/d5
		bsr.w	Calc_VRAM_Pos
		bsr.w	DrawBlock
		movem.l	(sp)+,d4/d5/a0
locj_701C:
		addi.w	#16,d4
		dbf	d6,locj_6FF4
		clr.b	(a2)
		rts


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Don't be fooled by the name: this function's for drawing from left to right
; when the camera's moving up or down
; DrawTiles_LR:
DrawBlocks_LR:
		; SpirituInsanum top-right corner reloading glitch fix: Removed the -1
		moveq	#((320+16+16)/16),d6	; Draw the entire width of the screen + two extra columns
; DrawTiles_LR_2:
DrawBlocks_LR_2:
		move.l	#$800000,d7	; Delta between rows of tiles
		move.l	d0,d1

.loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData
		move.l	d1,d0
		bsr.w	DrawBlock
		addq.b	#4,d1		; Two tiles ahead
		andi.b	#$7F,d1		; Wrap around row
		movem.l	(sp)+,d4-d5
		addi.w	#16,d5		; Move X coordinate one block ahead
		dbf	d6,.loop
		rts
; End of function DrawBlocks_LR

; DrawTiles_LR_3:
DrawBlocks_LR_3:
		move.l	#$800000,d7
		move.l	d0,d1

.loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData_2
		move.l	d1,d0
		bsr.w	DrawBlock
		addq.b	#4,d1
		andi.b	#$7F,d1
		movem.l	(sp)+,d4-d5
		addi.w	#16,d5
		dbf	d6,.loop
		rts	
; End of function DrawBlocks_LR_3


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Don't be fooled by the name: this function's for drawing from top to bottom
; when the camera's moving left or right
; DrawTiles_TB:
DrawBlocks_TB:
		moveq	#((224+16+16)/16)-1,d6	; Draw the entire height of the screen + two extra rows
; DrawTiles_TB_2:
DrawBlocks_TB_2:
		move.l	#$800000,d7	; Delta between rows of tiles
		move.l	d0,d1

.loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData
		move.l	d1,d0
		bsr.w	DrawBlock
		addi.w	#$100,d1	; Two rows ahead
		andi.w	#$FFF,d1	; Wrap around plane
		movem.l	(sp)+,d4-d5
		addi.w	#16,d4		; Move X coordinate one block ahead
		dbf	d6,.loop
		rts	
; End of function DrawBlocks_TB_2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Draws a block's worth of tiles
; Parameters:
; a0 = Pointer to block metadata (block index and X/Y flip)
; a1 = Pointer to block
; a5 = Pointer to VDP command port
; a6 = Pointer to VDP data port
; d0 = VRAM command to access plane
; d2 = VRAM plane A/B specifier
; d7 = Plane row delta
; DrawTiles:
DrawBlock:
		or.w	d2,d0	; OR in that plane A/B specifier to the VRAM command
		swap	d0
		btst	#3,(a0)	; Check Y-flip bit	; MJ: checking bit 3 not 4 (Flip)
		bne.s	DrawFlipY
		btst	#2,(a0)	; Check X-flip bit	; MJ: checking bit 2 not 3 (Flip)
		bne.s	DrawFlipX
		move.l	d0,(a5)
		move.l	(a1)+,(a6)	; Write top two tiles
		add.l	d7,d0		; Next row
		move.l	d0,(a5)
		move.l	(a1)+,(a6)	; Write bottom two tiles
		rts	
; ===========================================================================

DrawFlipX:
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4	; Invert X-flip bits of each tile
		swap	d4		; Swap the tiles around
		move.l	d4,(a6)		; Write top two tiles
		add.l	d7,d0		; Next row
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)		; Write bottom two tiles
		rts	
; ===========================================================================

DrawFlipY:
		btst	#2,(a0)		; MJ: checking bit 2 not 3 (Flip)
		bne.s	DrawFlipXY
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$10001000,d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$10001000,d5
		move.l	d5,(a6)
		rts	
; ===========================================================================

DrawFlipXY:
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$18001800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$18001800,d5
		swap	d5
		move.l	d5,(a6)
		rts	
; End of function DrawBlocks

; ===========================================================================


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Gets address of block at a certain coordinate
; Parameters:
; a4 = Pointer to level layout
; d4 = Relative Y coordinate
; d5 = Relative X coordinate
; Returns:
; a0 = Address of block metadata
; a1 = Address of block
; DrawBlocks:
GetBlockData:
		add.w	(a3),d5		; MJ: load X position to d5
GetBlockData_2:
		add.w	4(a3),d4	; MJ: load Y position to d4

	if BlocksInROM=1	;Mercury Blocks In ROM
		movea.l	(v_16x16).l,a1
	else
		lea	(v_16x16).w,a1	; MJ: load Block's location
	endif	;end Blocks In ROM

		; Turn Y coordinate into index into level layout
		move.w	d4,d3		; MJ: copy Y position to d3
		andi.w	#$780,d3	; MJ: get within 780 (Not 380) (E00 pixels (not 700)) in multiples of 80
		; Turn X coordinate into index into level layout
		lsr.w	#3,d5		; MJ: divide X position by 8
		move.w	d5,d0		; MJ: copy to d0
		lsr.w	#4,d0		; MJ: divide by 10 (Not 20)
		andi.w	#$7F,d0		; MJ: get within 7F
		; Get chunk from level layout
		lsl.w	#1,d3		; MJ: multiply by 2 (So it skips the BG)
		add.w	d3,d0		; MJ: add calc'd Y pos

	if ChunksInROM=1	;Mercury Chunks In ROM
		moveq	#0,d3
	else
		moveq	#-1,d3		; MJ: prepare FFFF in d3
	endif	;Chunks In ROM

		move.b	(a4,d0.w),d3	; MJ: collect correct chunk ID from layout
		; Turn chunk ID into index into chunk table
		andi.w	#$FF,d3		; MJ: keep within FF
		lsl.w	#7,d3		; MJ: multiply by 80
		; Turn Y coordinate into index into chunk
		andi.w	#$70,d4		; MJ: keep Y pos within 80 pixels
		; Turn X coordinate into index into chunk
		andi.w	#$E,d5		; MJ: keep X pos within 10
		; Get block metadata from chunk
		add.w	d4,d3		; MJ: add calc'd Y pos to ror'd d3
		add.w	d5,d3		; MJ: add calc'd X pos to ror'd d3

	if ChunksInROM=1	;Mercury Chunks In ROM
		add.l	(v_128x128).l,d3
	endif	;Chunks In ROM

		movea.l	d3,a0		; MJ: set address (Chunk to read)
		move.w	(a0),d3
		; Turn block ID into address
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		adda.w	d3,a1

locret_6C1E:
		rts	
; End of function GetBlockData


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Produces a VRAM plane access command from coordinates
; Parameters:
; d4 = Relative Y coordinate
; d5 = Relative X coordinate
; Returns VDP command in d0
Calc_VRAM_Pos:
		add.w	(a3),d5
Calc_VRAM_Pos_2:
		add.w	4(a3),d4
		; Floor the coordinates to the nearest pair of tiles (the size of a block).
		; Also note that this wraps the value to the size of the plane:
		; The plane is 64*8 wide, so wrap at $100, and it's 32*8 tall, so wrap at $200
		andi.w	#$F0,d4
		andi.w	#$1F0,d5
		; Transform the adjusted coordinates into a VDP command
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#3,d0	; Highest bits of plane VRAM address
		swap	d0
		move.w	d4,d0
		rts	
; End of function Calc_VRAM_Pos

; ---------------------------------------------------------------------------
; Subroutine to	load tiles as soon as the level	appears
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesFromStart:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_screenposx).w,a3
		lea	(v_lvllayout).w,a4
		move.w	#$4000,d2
		bsr.s	DrawChunks
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$80).w,a4		; MJ: Load address of layout BG
		move.w	#$6000,d2
		tst.b	(v_zone).w
		beq.w	Draw_GHz_Bg
		cmpi.b	#id_MZ,(v_zone).w
		beq.w	Draw_Mz_Bg
		cmpi.w	#(id_SBZ<<8)+0,(v_zone).w
		beq.w	Draw_SBz_Bg
		cmpi.b	#id_EndZ,(v_zone).w
		beq.w	Draw_GHz_Bg
; End of function LoadTilesFromStart


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

DrawChunks:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6

.loop:
		movem.l	d4-d6,-(sp)
		moveq	#0,d5
		move.w	d4,d1
		bsr.w	Calc_VRAM_Pos
		move.w	d1,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_2
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,.loop
		rts	
; End of function DrawChunks

Draw_GHz_Bg:
		moveq	#0,d4
		moveq	#((224+16+16)/16)-1,d6
locj_7224:			
		movem.l	d4-d6,-(sp)
		lea	(locj_724a).l,a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_7224
		rts
locj_724a:
		dc.b $00,$00,$00,$00,$06,$06,$06,$04,$04,$04,$00,$00,$00,$00,$00,$00
;-------------------------------------------------------------------------------
Draw_Mz_Bg:;locj_725a:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6
locj_725E:			
		movem.l	d4-d6,-(sp)
		lea	(locj_6EF2+1).l,a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		add.w	d4,d0
		andi.w	#$7F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_725E
		rts
;-------------------------------------------------------------------------------
Draw_SBz_Bg:;locj_7288:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6
locj_728C:			
		movem.l	d4-d6,-(sp)
		lea	(locj_6DF4+1).l,a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_728C
		rts
;-------------------------------------------------------------------------------
locj_72B2:
		dc.w v_bgscreenposx, v_bgscreenposx, v_bg2screenposx, v_bg3screenposx
locj_72Ba:
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	locj_72B2(pc,d0.w),a3
		beq.s	locj_72da
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_72EE
locj_72da:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bra.w	DrawBlocks_LR_3
locj_72EE:
		rts

; ---------------------------------------------------------------------------
; Subroutine to load level art and data
; Clownacy Level Art Loading + Filter's Optimized Level Data Loader
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

LevelDataLoad:
		moveq	#0,d0						; Clear d0
		move.b	(v_zone).w,d0				; d0 = zone ID

	if NewSBZ3LevelArt
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w	; is level SBZ3 (LZ4) ?
		bne.s	.notSBZ3Art					; if not, branch
		moveq	#SBZ3_Art,d0				; use SBZ3 art

.notSBZ3Art:
	endif

		lsl.w	#4,d0						; Multiply by $10, converting the zone ID into an offset
		lea		(LevelHeaders).l,a2			; a2 = LevelHeaders address
		lea		(a2,d0.w),a2				; a2 = LevelHeaders + zone offset
		move.l	a2,-(sp)					; store LevelHeader location for future use (Data Load)

		move.l	(a2)+,d0					; d0 = 1st longword of data that a2 points to, (zone's first PLC ID and art address).
	; The auto increment was pointless as a2 is overwritten later, and nothing reads from a2 before then
		andi.l	#$FFFFFF,d0					; Filter out the high byte, which contains the first PLC ID, leaving the address of the zone's art in d0
		movea.l	d0,a0						; a0 = address of the zone's art (SOURCE)
		lea		(v_ram_start).l,a1			; a1 = StartOfRAM (in this context, an art buffer) (DESTINATION)
		bsr.w	KosDec						; Decompress a0 to a1 (Switch to Comper compression??)

	; Move a word of a1 to d3, note that a1 doesn't exactly contain the address of v_128x128/StartOfRAM anymore, after KosDec, a1 now contains v_128x128/StartOfRAM + the size of the file decompressed to it, d3 now contains the length of the file that was decompressed
		move.w	a1,d3
		move.w	d3,d7						; Move d3 to d7, for use in seperate calculations
		andi.w	#$FFF,d3					; Remove the high nibble of the high byte of the length of decompressed file, this nibble is how many $1000 bytes the decompressed art is
		lsr.w	#1,d3						; Half the value of 'length of decompressed file', d3 becomes the 'DMA transfer length'
		rol.w	#4,d7						; Rotate (left) length of decompressed file by one nibble
		andi.w	#$F,d7						; Only keep the low nibble of low byte (the same one filtered out of d3 above), this nibble is how many $1000 bytes the decompressed art is
 
.loop:
		move.w	d7,d2						; Move d7 to d2, note that the ahead dbf removes 1 byte from d7 each time it loops, meaning that the following calculations will have different results each time
		moveq	#12,d0
		lsl.w	d0,d2						; Shift (left) d2 by $C, making it high nibble of the high byte, d2 is now the size of the decompressed file rounded down to the nearest $1000 bytes, d2 becomes the 'destination address'
		move.l	#$FFFFFF,d1					; Fill d1 with $FF
		move.w	d2,d1						; Move d2 to d1, overwriting the last word of $FF's with d2, this turns d1 into 'StartOfRAM'+'However many $1000 bytes the decompressed art is', d1 becomes the 'source address'
		jsr		(QueueDMATransfer).w		; Use d1, d2, and d3 to locate the decompressed art and ready for transfer to VRAM
		move.w	d7,-(sp)					; Store d7 in the Stack
		move.b	#$C,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	RunPLC
		move.w	(sp)+,d7					; Restore d7 from the Stack
		move.w	#$800,d3					; Force the DMA transfer length to be $1000/2 (the first cycle is dynamic because the art's DMA'd backwards)
		dbf		d7,.loop					; Loop for each $1000 bytes the decompressed art is

;LevelDataLoad:
	if BlocksInROM=1	;Mercury Blocks In ROM
		move.l	(a2)+,(v_16x16).l			; store the ROM address for the block mappings
		andi.l	#$FFFFFF,(v_16x16).l
	else
		movea.l	(a2)+,a0
		lea		(v_16x16).w,a1				; RAM address for 16x16 mappings
		clr.w	d0
		bsr.w	EniDec
	endif

	if ChunksInROM=1	;Mercury Chunks In ROM
		move.l	(a2)+,(v_128x128).l			; store the ROM address for the chunk mappings
	else
		movea.l	(a2)+,a0
		lea		(v_128x128&$FFFFFF).l,a1	; RAM address for 128x128 mappings
		bsr.w	KosDec
	endif

		bsr.w	LevelLayoutLoad

	; Load Level Palette
		move.b	(a2),d0				; load palette ID byte
	
; We won't use the NewSBZ3LevelArt toggle here, because the LZ Palette
; is always overwritten in Scrap Brain 3
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w	; is level SBZ3 (LZ4) ?
		bne.s	.notSBZ3Pal					; if not, branch
		moveq	#palid_SBZ3,d0				; use SBZ3 palette

.notSBZ3Pal:
		cmpi.b	#id_SBZ,(v_zone).w			; is this Scrap Brain?
		bne.s	.normalpal					; if not, branch
		cmpi.w	#(id_SBZ<<8)+1,(v_zone).w	; is level SBZ2?
		beq.s	.isSBZorFZ					; if yes, branch
		cmpi.w	#(id_SBZ<<8)+2,(v_zone).w	; is level FZ?
		bne.s	.normalpal					; if not, branch

.isSBZorFZ:

	if DynamicPalettes
		moveq	#palid_SBZ2,d0				; use SBZ2/FZ palette
		bra.s	.nodynamic

.normalpal:
		add.b	(v_act).w,d0				; set palette based on act

.nodynamic:
	else
		moveq	#palid_SBZ2,d0				; use SBZ2/FZ palette
.normalpal:
	endif

		bsr.w	PalLoad_Fade	; load palette (based on d0)
		movea.l	(sp)+,a2
		addq.w	#4,a2			; read number for 2nd PLC
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	.skipPLC		; if 2nd PLC is 0 (i.e. the ending sequence), branch
		bra.w	AddPLC			; load pattern load cues

.skipPLC:
		rts	
; End of function LevelDataLoad

; ---------------------------------------------------------------------------
; Level	layout loading subroutine -- Modified to use longword pointers
; ---------------------------------------------------------------------------


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

LevelLayoutLoad:
		move.w	(v_zone).w,d0
		ror.b	#2,d0				; lsl.b	#6,d0 > Filter Optimized Shifting
		lsr.w	#4,d0
		lea		(Level_Index).l,a0
		movea.l	(a0,d0.w),a0		; for longword pointers - RetroKoH
		;adda.w	(a0,d0.w),a0		; for wordlength pointers
		lea		(v_lvllayout).w,a1
		bra.w	KosDec				; MJ: decompress layout
; End of function LevelLayoutLoad

		include	"_inc/DynamicLevelEvents.asm"

		include	"_incObj/11 Bridge.asm"

; ---------------------------------------------------------------------------
; Platform subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

PlatformObject:
		lea		(v_player).w,a1
		tst.w	obVelY(a1)	; is Sonic moving up/jumping?
		bmi.w	Plat_Exit	; if yes, branch

;		perform x-axis range check
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.w	Plat_Exit

Plat_NoXCheck:
		move.w	obY(a0),d0
		subq.w	#8,d0

Platform3:
;		perform y-axis range check
		move.w	obY(a1),d2
		move.b	obHeight(a1),d1
		ext.w	d1
		add.w	d2,d1
		addq.w	#4,d1
		sub.w	d1,d0
		bhi.w	Plat_Exit
		cmpi.w	#-$10,d0
		blo.w	Plat_Exit

		tst.b	obCtrlLock(a1)		; are collisions disabled for Sonic?
		bmi.w	Plat_Exit			; if yes, branch
		cmpi.b	#6,obRoutine(a1)	; is Sonic dead?
		bhs.w	Plat_Exit			; If yes, branch
		tst.w	(v_debuguse).w		; is debug mode being used?
		bne.w	Plat_Exit			; if yes, branch
		add.w	d0,d2
		addq.w	#3,d2
		move.w	d2,obY(a1)
		addq.b	#2,obRoutine(a0)

loc_74AE:
		btst	#staOnObj,obStatus(a1)
		beq.s	loc_74DC
	; RetroKoH obPlatform SST mod
		movea.w	obPlatformAddr(a1),a2
		adda.l	#v_ram_start,a2		; a2 = object being stood upon 
	; obPlatform SST mod end
		bclr	#staSonicOnObj,obStatus(a2)
		clr.b	ob2ndRout(a2)
		cmpi.b	#4,obRoutine(a2)
		bne.s	loc_74DC
		subq.b	#2,obRoutine(a2)

loc_74DC:
	; RetroKoH obPlatform SST mod
		move.w	a0,obPlatformAddr(a1)
	; obPlatform SST mod end
		clr.b	obAngle(a1)
		clr.w	obVelY(a1)
		move.w	obVelX(a1),obInertia(a1)
		btst	#staAir,obStatus(a1)
		beq.s	loc_7512
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr		(Sonic_ResetOnFloor).l
		movea.l	(sp)+,a0

loc_7512:
		bset	#staOnObj,obStatus(a1)
		bset	#staSonicOnObj,obStatus(a0)

Plat_Exit:
		rts	
; End of function PlatformObject

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	SLZ seesaws)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject:
		lea	(v_player).w,a1
		tst.w	obVelY(a1)
		bmi.w	Plat_Exit
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.s	Plat_Exit
		btst	#0,obRender(a0)
		beq.s	loc_754A
		not.w	d0
		add.w	d1,d0

loc_754A:
		lsr.w	#1,d0
		moveq	#0,d3
		move.b	(a2,d0.w),d3
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function SlopeObject


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Swing_Solid:
		lea	(v_player).w,a1
		tst.w	obVelY(a1)
		bmi.w	Plat_Exit
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.w	Plat_Exit
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function Obj15_Solid

; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk or jump off	a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ExitPlatform:
		move.w	d1,d2

ExitPlatform2:
		add.w	d2,d2
		lea		(v_player).w,a1
		btst	#staAir,obStatus(a1)		; Is Sonic in the air?
		bne.s	loc_75E0					; if yes, branch and clear bits
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	loc_75E0
		cmp.w	d2,d0
		blo.s	locret_75F2

loc_75E0:
		bclr	#staOnObj,obStatus(a1)		; Clear Sonic's obObj bit
		move.b	#2,obRoutine(a0)
		bclr	#staSonicOnObj,obStatus(a0)	; Clear the object's standing bit

locret_75F2:
		rts	
; End of function ExitPlatform

		include	"_incObj/15 Swinging Platforms (part 1).asm"
;		include	"_incObj/15 Swinging Platforms S2.asm"

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm:
		lea		(v_player).w,a1
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.s	MvSonic2
; End of function MvSonicOnPtfm

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm2:
		lea		(v_player).w,a1
		move.w	obY(a0),d0
		subi.w	#9,d0				; Sonic 2 uses a value stored to d3 instead of #9 (likely to account for Tails)

MvSonic2:
		tst.b	obCtrlLock(a1)		; are collisions disabled for Sonic?
		bmi.s	locret_7B62			; if yes, branch
		cmpi.b	#6,obRoutine(a1)	; is Sonic dead?
		bhs.s	locret_7B62			; if yes, branch
		tst.w	(v_debuguse).w		; is debug mode being used?
		bne.s	locret_7B62			; if yes, branch
		moveq	#0,d1
		move.b	obHeight(a1),d1
		sub.w	d1,d0
		move.w	d0,obY(a1)
		sub.w	obX(a0),d2
		sub.w	d2,obX(a1)
		move.w	obX(a1),d2			; copy for below

	; RetroKoH Move Shields with Sonic
; NOTE: I don't apply this to invincibiliity for two reasons:
; 1. It'd be a bit too complicated to apply to the main position, AND all of its subsprites.
; 2. With the trailing effect, it's not any sort of noticeable issue to have it lag behind slightly.
		lea		(v_shieldobj).w,a2
		tst.b	obID(a2)
		beq.s	.noShield
	; First, check to adjust for balancing
		move.w	d2,d3				; copy x-pos to d3 for later
		move.w	#$A,d1
		move.b	obStatus(a2),d4		; copy shield's status bit
	if CDBalancing=1
		cmpi.b	#aniID_Balance2,obAnim(a1)
		beq.s	.shift
		cmpi.b	#aniID_Balance3,obAnim(a1)
		bne.s	.noshift
		bchg	#staFacing,d4
		move.w	#4,d1
	else	
		cmpi.b	#aniID_Balance,obAnim(a1)
		bne.s	.noshift
	endif
	.shift:
		sub.w	d1,d2
		btst	#staFlipX,d4	; X-Flip sprite bit
		beq.s	.noshift
		add.w	d1,d1
		add.w	d1,d2
	.noshift:

	; Finally, apply position
		move.w	d2,obX(a2)
		move.w	d0,obY(a2)
		move.w	d3,d2		; return original x-pos to d2
	; Move Shields with Sonic End
	
.noShield:
	if (SpinDashEnabled|SkidDustEnabled)=1
	; RetroKoH Move Spindash dust with Sonic
		lea		(v_playerdust).w,a2
		cmpi.b	#1,obAnim(a2)
		bne.s	locret_7B62
		move.w	d2,obX(a2)
		move.w	d0,obY(a2)
	endif


locret_7B62:
		rts	
; End of function MvSonicOnPtfm2

		include	"_incObj/15 Swinging Platforms (part 2).asm"
		
		include	"_incObj/17 Spiked Pole Helix.asm"

		include	"_incObj/18 Platforms.asm"

		include	"_incObj/19 Giant Ball.asm"

		include	"_incObj/1A Collapsing Ledge (part 1).asm"
		include	"_incObj/53 Collapsing Floors.asm"

; ===========================================================================

; Obj1A calls this
Ledge_Fragment:
		clr.b	ledge_collapse_flag(a0)

loc_847A:
		lea		CFlo_Data1(pc),a4
		moveq	#$18,d1
		addq.b	#2,obFrame(a0)

; Used by Obj1A and Obj53
loc_8486:
		moveq	#0,d0
		move.b	obFrame(a0),d0
		add.w	d0,d0
		movea.l	obMap(a0),a3
		adda.w	(a3,d0.w),a3
		; S2 BuildSprites
		move.w	(a3)+,d1
		subq.w	#1,d1
		; S2 BuildSprites end
		bset	#5,obRender(a0)
		_move.b	obID(a0),d2			; Wooloo change
		move.b	obRender(a0),d3		; Wooloo change
		move.w	obGfx(a0),d4		; Wooloo addition
		move.w	obPriority(a0),d5	; Wooloo addition
		move.b	obActWid(a0),d6		; Wooloo addition
		movea.l	a0,a1
	; Spirituinsanum Mass Object Load Optimization
	; Create the first instance, then loop create the others afterward.
		move.b	#6,obRoutine(a1)
		_move.b	d2,obID(a1)			; Obj1A or Obj53
		move.l	a3,obMap(a1)		; Set appropriate mapping
		move.b	d3,obRender(a1)		; Set render flags accordingly
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	d4,obGfx(a1)
		move.w	d5,obPriority(a1)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	d6,obActWid(a1)
		move.b	(a4)+,ledge_timedelay(a1)
		subq.w	#1,d1				; decrement for the first ring created
	; Here we begin what's replacing SingleObjLoad, in order to avoid resetting its d0 every time an object is created.
		lea		(v_lvlobjspace).w,a1
		move.w	#v_lvlobjcount,d0

	; REMOVE FindFreeObj. It's the routine that causes such slowdown
.loop:
		tst.b	obID(a1)	; is object RAM	slot empty?
		beq.s	.cont		; Let's correct the branches. Here we can also skip the bne that was originally after bsr.w SingleObjLoad because we already know there's a free object slot in memory.
		lea		object_size(a1),a1
		dbf		d0,.loop	; Branch correction again.
		bne.s	.endloop	; We're moving this line here.

.cont:
		addq.w	#8,a3				; Set to next mapping. ; S2 BuildSprites Change 5 -> 8
	; Create fragment object
		move.b	#6,obRoutine(a1)
		_move.b	d2,obID(a1)			; Obj1A or Obj53
		move.l	a3,obMap(a1)		; Set appropriate mapping
		move.b	d3,obRender(a1)		; Set render flags accordingly
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	d4,obGfx(a1)
		move.w	d5,obPriority(a1)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	d6,obActWid(a1)
		move.b	(a4)+,ledge_timedelay(a1)
		bsr.w	DisplaySprite1
		dbf		d1,.loop	; repeat for number of fragments (space permitting)

.endloop:
	; Mass Object Load Optimization End
		bsr.w	DisplaySprite
		move.w	#sfx_Collapse,d0
		jmp		(PlaySound_Special).w	; play collapsing sound
; ===========================================================================
; ---------------------------------------------------------------------------
; Disintegration data for collapsing ledges (MZ, SLZ, SBZ)
; ---------------------------------------------------------------------------
CFlo_Data1:
		dc.b $1C, $18, $14, $10, $1A, $16, $12,	$E, $A,	6, $18,	$14, $10, $C, 8, 4
		dc.b $16, $12, $E, $A, 6, 2, $14, $10, $C, 0
CFlo_Data2:
		dc.b $1E, $16, $E, 6, $1A, $12,	$A, 2
CFlo_Data3:
		dc.b $16, $1E, $1A, $12, 6, $E,	$A, 2

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	MZ platforms)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject2:
		lea		(v_player).w,a1
		btst	#staOnObj,obStatus(a1)
		beq.s	locret_856E
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		lsr.w	#1,d0
		btst	#0,obRender(a0)
		beq.s	loc_854E
		not.w	d0
		add.w	d1,d0

loc_854E:
		moveq	#0,d1
		move.b	(a2,d0.w),d1
		move.w	obY(a0),d0
		sub.w	d1,d0
		moveq	#0,d1
		move.b	obHeight(a1),d1
		sub.w	d1,d0
		move.w	d0,obY(a1)
		sub.w	obX(a0),d2
		sub.w	d2,obX(a1)

locret_856E:
		rts	
; End of function SlopeObject2

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision data for GHZ collapsing ledge
; ---------------------------------------------------------------------------
Ledge_SlopeData:
		binclude	"misc/GHZ Collapsing Ledge Heightmap.bin"
		even

		include	"_incObj/1C Scenery.asm"

		include	"_incObj/1D Unused Switch.asm"

		include	"_incObj/2A SBZ Small Door.asm"
		include	"_anim/SBZ Small Door.asm"


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj44_SolidWall:
		bsr.w	Obj44_SolidWall2
		beq.s	loc_8AA8
		bmi.w	loc_8AC4
		tst.w	d0
		beq.w	loc_8A92
		bmi.s	loc_8A7C
		tst.w	obVelX(a1)
		bmi.s	loc_8A92
		bra.s	loc_8A82
; ===========================================================================

loc_8A7C:
		tst.w	obVelX(a1)
		bpl.s	loc_8A92

loc_8A82:
		sub.w	d0,obX(a1)
		clr.w	obInertia(a1)
		clr.w	obVelX(a1)

loc_8A92:
		btst	#staAir,obStatus(a1)
		bne.s	loc_8AB6
		bset	#staPush,obStatus(a1)
		bset	#staSonicPush,obStatus(a0)
		rts	
; ===========================================================================

loc_8AA8:
		btst	#staSonicPush,obStatus(a0)
		beq.s	locret_8AC2
		; Removed line -- Mercury Walking In Air Fix

loc_8AB6:
		bclr	#staSonicPush,obStatus(a0)
		bclr	#staPush,obStatus(a1)

locret_8AC2:
		rts	
; ===========================================================================

loc_8AC4:
		tst.w	obVelY(a1)
		bpl.s	locret_8AD8
		tst.w	d3
		bpl.s	locret_8AD8
		sub.w	d3,obY(a1)
		clr.w	obVelY(a1)

locret_8AD8:
		rts	
; End of function Obj44_SolidWall


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj44_SolidWall2:
		lea		(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	loc_8B48
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.s	loc_8B48
		move.b	obHeight(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	obY(a1),d3

	; Mercury Ducking Size Fix	
	if SpinDashEnabled=1
		cmpi.b	#aniID_SpinDash,obAnim(a1)
		beq.s	.short
	endif
		cmpi.b	#aniID_Duck,obAnim(a1)
		bne.s	.skip
		
.short:
		subi.w	#5,d2
		addi.w	#5,d3

.skip:
	; Ducking Size Fix end

		sub.w	obY(a0),d3
		add.w	d2,d3
		bmi.s	loc_8B48
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bhs.s	loc_8B48
		tst.b	obCtrlLock(a1)		; are collisions disabled for Sonic?
		bmi.s	loc_8B48			; if yes, branch
		cmpi.b	#6,obRoutine(a1)	; is Sonic dead?
		bhs.s	loc_8B48			; if yes, branch
		tst.w	(v_debuguse).w		; is debug mode being used?	
		bne.s	loc_8B48			; if yes, branch
		move.w	d0,d5
		cmp.w	d0,d1
		bhs.s	loc_8B30
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_8B30:
		move.w	d3,d1
		cmp.w	d3,d2
		bhs.s	loc_8B3C
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_8B3C:
		cmp.w	d1,d5
		bhi.s	loc_8B44
		moveq	#1,d4
		rts	
; ===========================================================================

loc_8B44:
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_8B48:
		moveq	#0,d4
		rts	
; End of function Obj44_SolidWall2

; ===========================================================================

		include	"_anim/Ball Hog.asm"
		include	"_incObj/1E Ball Hog.asm"
		include	"_incObj/20 Cannonball.asm"

		include	"_incObj/24, 27 & 3F Explosions.asm"

		include	"_incObj/28 Animals.asm"
		include	"_incObj/29 Points.asm"

		include	"_incObj/1F Crabmeat.asm"
		include	"_anim/Crabmeat.asm"

		include	"_incObj/22 Buzz Bomber.asm"
		include	"_incObj/23 Buzz Bomber Missile.asm"
		include	"_anim/Buzz Bomber.asm"
		include	"_anim/Buzz Bomber Missile.asm"


		include	"_incObj/25 & 37 Rings.asm"
		include	"_incObj/4B Giant Ring.asm"
		include	"_incObj/7C Ring Flash.asm"		; No longer used

		include	"_anim/Rings.asm"
dplcTiles := Art_BigRing		; MainMemory 128k Boundary Check for DPLCs
		include "_maps/Giant Ring - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End

		include	"_incObj/26 Monitor.asm"
		include	"_incObj/2E Monitor Content Power-Up.asm"
		include	"_incObj/26 Monitor (SolidSides subroutine).asm"
		include	"_anim/Monitor.asm"

dplcTiles := Art_TitleSonic		; MainMemory 128k Boundary Check for DPLCs
		include	"_maps/Title Screen Sonic - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End

		include	"_incObj/0E Title Screen Sonic.asm"
		include	"_incObj/0F Press Start and TM.asm"

		include	"_anim/Title Screen Sonic.asm"
		include	"_anim/Press Start and TM.asm"

		include	"_incObj/2B Chopper.asm"
		include	"_anim/Chopper.asm"

		include	"_incObj/2C Jaws.asm"
		include	"_anim/Jaws.asm"

		include	"_incObj/2D Burrobot.asm"
		include	"_anim/Burrobot.asm"


		include	"_incObj/2F MZ Large Grassy Platforms.asm"
		include	"_incObj/35 Burning Grass.asm"
		include	"_anim/Burning Grass.asm"

		include	"_incObj/30 MZ Large Green Glass Blocks.asm"

		include	"_incObj/31 Chained Stompers.asm"
		include	"_incObj/45 Sideways Stomper.asm"

		include	"_incObj/32 Button.asm"

		include	"_incObj/33 Pushable Blocks.asm"

		include	"_incObj/34 Title Cards.asm"
		include	"_incObj/39 Game Over.asm"
		include	"_incObj/3A Got Through Card.asm"
		include	"_incObj/7E Special Stage Results.asm"
		include	"_incObj/7F SS Result Chaos Emeralds.asm"

		include	"_incObj/36 Spikes.asm"

		include	"_incObj/3B Purple Rock.asm"
		include	"_incObj/49 Waterfall Sound.asm"

		include	"_incObj/3C Smashable Wall.asm"

		include	"_incObj/sub SmashObject.asm"

; ===========================================================================
; Smashed block	fragment speeds
;
Smash_FragSpd1:	dc.w $400, -$500	; x-move speed,	y-move speed
		dc.w $600, -$100
		dc.w $600, $100
		dc.w $400, $500
		dc.w $600, -$600
		dc.w $800, -$200
		dc.w $800, $200
		dc.w $600, $600

Smash_FragSpd2:	dc.w -$600, -$600
		dc.w -$800, -$200
		dc.w -$800, $200
		dc.w -$600, $600
		dc.w -$400, -$500
		dc.w -$600, -$100
		dc.w -$600, $100
		dc.w -$400, $500

; ---------------------------------------------------------------------------
; Object code execution subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ExecuteObjects:
		lea		(v_objspace).w,a0			; set address for object RAM
		moveq	#v_allobjcount,d7
		moveq	#0,d0
	if ~~ActiveDeathSequence				; RetroKoH Active Death Sequence Mod
		cmpi.b	#6,(v_player+obRoutine).w	; has Sonic just died?
		bhs.s	ObjectsDisplayOnly			; if yes, branch
	endif

loc_D348:
		move.b	obID(a0),d0					; load object number from RAM
		beq.s	loc_D358
		add.w	d0,d0
		add.w	d0,d0
		movea.l	Obj_Index-4(pc,d0.w),a1
		jsr		(a1)						; run the object's code
		moveq	#0,d0

loc_D358:
		lea		object_size(a0),a0			; next object
		dbf		d7,loc_D348
		rts	
; ===========================================================================

; The following only runs if objects are meant to freeze when Sonic dies.
	if ~~ActiveDeathSequence				; RetroKoH Active Death Sequence Mod
ObjectsDisplayOnly:
	; RHS Drowning Fix
		cmpi.b	#$A,(v_player+obRoutine).w	; Has Sonic drowned?
		beq.s	loc_D348					; If so, run objects a little longer
	; Drowning Fix End
		moveq	#v_rsvobjcount,d7			; Run through reserved obj space (before level objects)
		bsr.s	loc_D348
		moveq	#v_lvlobjcount,d7			; Run through level obj space

loc_D368:
		tst.b	obID(a0)					; get the object's ID
		beq.s	loc_D378					; if there's no object, branch
		tst.b	obRender(a0)				; was the object displayed on the previous frame?
		bpl.s	loc_D378					; if not, skip it

	; If this is a multi-sprite object, then we cannot use its 'priority'
	; value to display it as it's being used for coordinate data.
	; This fix is applied from s2disasm.
		pea		loc_D378(pc)				; This is an optimisation to avoid the need for extra branches: it makes it so loc_D378 will be executed after a return
		btst	#6,obRender(a0)				; Is this a multi-sprite object?
		beq.w	DisplaySprite				; If not, display using the object's 'priority' value.
		move.w	#priority4,d0				; If not, display using a hardcoded priority of 4.
		bra.w	DisplaySprite2

loc_D378:
		lea		object_size(a0),a0

loc_D37C:
		dbf		d7,loc_D368
		rts
	endif
; End of function ExecuteObjects

; ===========================================================================
; ---------------------------------------------------------------------------
; Object pointers
; ---------------------------------------------------------------------------
Obj_Index:
		include	"_inc/Object Pointers.asm"

		include	"_incObj/sub SpeedToPos.asm"
		include	"_incObj/sub DisplaySprite.asm"
		include	"_incObj/sub DeleteObject.asm"

		include "_inc/BuildSprites.asm"

		include "_inc/Rings Manager.asm"
		include "_inc/BuildHUD.asm"
		include	"_incObj/sub ChkObjectVisible.asm"

		include "_inc/Object Manager.asm"

		include	"_incObj/sub FindFreeObj.asm"
		include	"_incObj/41 Springs.asm"
		include	"_anim/Springs.asm"

		include	"_incObj/42 Newtron.asm"
		include	"_anim/Newtron.asm"

		include	"_incObj/43 Roller.asm"
		include	"_anim/Roller.asm"

		include	"_incObj/44 GHZ Edge Walls.asm"

		include	"_incObj/13 Lava Ball Maker.asm"
		include	"_incObj/14 Lava Ball.asm"
		include	"_anim/Fireballs.asm"
		include	"_incObj/74 MZ Boss Fire.asm"		; Moved to enable short addressing w/ animation

		include	"_incObj/6D Flamethrower.asm"
		include	"_anim/Flamethrower.asm"

		include	"_incObj/46 MZ Bricks.asm"

		include	"_incObj/12 Light.asm"

		include	"_incObj/47 Bumper.asm"
		include	"_anim/Bumper.asm"

		include	"_incObj/0D Signpost.asm" ; includes "GotThroughAct" subroutine
		include	"_anim/Signpost.asm"

dplcTiles := Art_Signpost		; MainMemory 128k Boundary Check for DPLCs
	switch UpdatedSignposts
	case 2
		include	"_maps/Signpost - Hybrid - DPLCs.asm"
	case 1
		include	"_maps/Signpost - CD - DPLCs.asm"
	elsecase
		include	"_maps/Signpost - DPLCs.asm"
	endcase
dplcTiles := 0					; 128k Boundary Check for DPLCs End

		include	"_incObj/4C & 4D Lava Geyser Maker.asm"
		include	"_incObj/4E Wall of Lava.asm"
		include	"_incObj/54 Lava Tag.asm"

		include	"_anim/Lava Geyser.asm"
		include	"_anim/Wall of Lava.asm"

		include "_incObj/4F Splats.asm"

		include	"_incObj/40 Moto Bug.asm" ; includes "_incObj/sub RememberState.asm"
		include	"_anim/Moto Bug.asm"

		include	"_incObj/50 Yadrin.asm"
		include	"_anim/Yadrin.asm"

		include	"_incObj/sub SolidObject.asm"

		include	"_incObj/51 Smashable Green Block.asm"

		include	"_incObj/52 Moving Blocks.asm"


		include	"_incObj/55 Basaran.asm"
		include	"_anim/Basaran.asm"


		include	"_incObj/56 Floating Blocks and Doors.asm"

		include	"_incObj/57 Spiked Ball and Chain.asm"

		include	"_incObj/58 Big Spiked Ball.asm"

		include	"_incObj/59 SLZ Elevators.asm"

		include	"_incObj/5A SLZ Circling Platform.asm"

		include	"_incObj/5B Staircase.asm"

		include	"_incObj/5C Pylon.asm"


		include	"_incObj/1B Water Surface.asm"

		include	"_incObj/0B Pole that Breaks.asm"

		include	"_incObj/0C Flapping Door.asm"
		include	"_anim/Flapping Door.asm"


		include	"_incObj/71 Invisible Barriers.asm"


		include	"_incObj/5D Fan.asm"

		include	"_incObj/5E Seesaw.asm"

		include	"_incObj/5F Bomb Enemy.asm"
		include	"_anim/Bomb Enemy.asm"


		include	"_incObj/60 Orbinaut.asm"
		include	"_anim/Orbinaut.asm"


		include	"_incObj/16 Harpoon.asm"
		include	"_anim/Harpoon.asm"

		include	"_incObj/61 LZ Blocks.asm"
		include	"_incObj/62 Gargoyle.asm"
		include	"_incObj/63 LZ Conveyor.asm"
		include	"_incObj/64 Bubbles.asm"
		include	"_anim/Bubbles.asm"
		include	"_incObj/65 Waterfalls.asm"
		include	"_anim/Waterfalls.asm"

	if SuperMod
		include "_incObj/8D Super Sonic Stars.asm"
	endif

	if (SpinDashEnabled|SkidDustEnabled)=1
		include "_incObj/07 Effects.asm"	; Skid Dust and/or Spindash Dust

dplcTiles := Art_Effects		; MainMemory 128k Boundary Check for DPLCs
		include	"_maps/Effects - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End

		include "_anim/Effects.asm"
	endif

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 01 - Sonic
; ---------------------------------------------------------------------------

SonicPlayer:
		tst.w	(v_debuguse).w	; is debug mode	being used?
		beq.s	Sonic_Normal	; if not, branch
		jmp		(DebugMode).l
; ===========================================================================

Sonic_Normal:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Sonic_Index(pc,d0.w),d1
		jsr		Sonic_Index(pc,d1.w)
		clr.w	(v_col_response_list).w		; reset collsion response list
		rts
; ===========================================================================
Sonic_Index:	offsetTable
		offsetTableEntry.w	Sonic_Main
		offsetTableEntry.w	Sonic_Control
		offsetTableEntry.w	Sonic_Hurt
		offsetTableEntry.w	Sonic_Death
		offsetTableEntry.w	Sonic_ResetLevel
		offsetTableEntry.w	Sonic_Drowned		; RHS Drowning Fix
; ===========================================================================

Sonic_Main:	; Routine 0
		move.b	#$C,(v_top_solid_bit).w	; MJ: set collision to 1st
		move.b	#$D,(v_lrb_solid_bit).w	; MJ: set collision to 1st
		addq.b	#2,obRoutine(a0)
		move.b	#$13,obHeight(a0)
		move.b	#9,obWidth(a0)
		move.l	#Map_Sonic,obMap(a0)
		move.w	#make_art_tile(ArtTile_Sonic,0,0),obGfx(a0)
		move.w	#priority2,obPriority(a0)	; RetroKoH/Devon S3K+ Priority Manager
		move.b	#$18,obActWid(a0)
		move.b	#4,obRender(a0)
		lea     (v_sonspeedmax).w,a2		; Load Sonic_top_speed into a2
		bsr.w   ApplySpeedSettings			; Fetch Speed settings

	if (SpinDashEnabled|SkidDustEnabled)=1
		move.b	#id_Effects,(v_playerdust).w
	endif

Sonic_Control:	; Routine 2
	if CDCamera=1
		bsr.w	Sonic_PanCamera
	endif
		tst.w	(f_debugmode).w			; is debug cheat enabled?
		beq.s	loc_12C58				; if not, branch
		btst	#bitB,(v_jpadpress1).w	; is button B pressed?
		beq.s	loc_12C58				; if not, branch
		move.w	#1,(v_debuguse).w		; change Sonic into a ring/item
		clr.b	(f_lockctrl).w
		rts	
; ===========================================================================

loc_12C58:
		tst.b	(f_lockctrl).w					; are controls locked?
		bne.s	loc_12C64						; if yes, branch
		move.w	(v_jpadhold1).w,(v_jpadhold2).w	; enable joypad control

loc_12C64:
		btst	#0,obCtrlLock(a0)				; are controls locked somehow?
		bne.s	loc_12C7E						; if yes, branch
		moveq	#0,d0
		move.b	obStatus(a0),d0
		andi.w	#(maskAir+maskSpin),d0			; Use current air and spin states to determine Control Mode
		move.w	Sonic_Modes(pc,d0.w),d1
		jsr		Sonic_Modes(pc,d1.w)

loc_12C7E:
	if SuperMod=1
		bsr.w	Sonic_Display
		bsr.s	Sonic_Super
	else
		bsr.s	Sonic_Display
	endif
		bsr.w	Sonic_RecordPosition
		bsr.w	Sonic_Water
		move.b	(v_anglebuffer).w,obFrontAngle(a0)
		move.b	(v_anglebuffer2).w,obRearAngle(a0)
		tst.b	(f_wtunnelmode).w
		beq.s	loc_12CA6
		cmpi.b	#aniID_Walk,obAnim(a0)			; changed instruction because Walk is no longer #0
		bne.s	loc_12CA6
		move.b	obPrevAni(a0),obAnim(a0)

loc_12CA6:
		bsr.w	Sonic_Animate
		tst.b	obCtrlLock(a0)
		bmi.s	loc_12CB6
		jsr		(ReactToItem).l

loc_12CB6:
		bsr.w	Sonic_Loops
		bra.w	Sonic_LoadGfx	
; ===========================================================================
Sonic_Modes:
		dc.w Sonic_MdNormal-Sonic_Modes
		dc.w Sonic_MdAir-Sonic_Modes
		dc.w Sonic_MdRoll-Sonic_Modes
		dc.w Sonic_MdJump-Sonic_Modes

	if SuperMod=1
		include	"_incObj/Sonic Super.asm"
	endif
		include	"_incObj/Sonic Display.asm"
		include	"_incObj/Sonic RecordPosition.asm"
		include	"_incObj/Sonic Water.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Modes	for controlling	Sonic
; ---------------------------------------------------------------------------

Sonic_MdNormal:
	; Neither in air or rolling
	if PeeloutEnabled=1
		bsr.w	Sonic_ChkPeelout
	endif
	
	if SpinDashEnabled=1
		bsr.w	Sonic_ChkSpinDash
	endif

		bsr.w	Sonic_Jump
		bsr.w	Sonic_SlopeResist
		bsr.w	Sonic_Move
		bsr.w	Sonic_Roll
		bsr.w	Sonic_LevelBound
		jsr		(SpeedToPos).l
		bsr.w	Sonic_AnglePos
		bra.w	Sonic_SlopeRepel
; ===========================================================================

Sonic_MdAir:
	; in the air, not in a ball (thus, not jumping)
	if AirRollEnabled=1
		bsr.w	Sonic_ChkAirRoll		; Contains truncated JumpHeight code
	else
		bsr.w	Sonic_JumpHeight
	endif
		bsr.w	Sonic_JumpDirection
		bsr.w	Sonic_LevelBound
		jsr		(ObjectFall).l
		btst	#staWater,obStatus(a0)
		beq.s	loc_12E5C
		subi.w	#$28,obVelY(a0)

loc_12E5C:
		bsr.w	Sonic_JumpAngle
		bra.w	Sonic_Floor
; ===========================================================================

Sonic_MdRoll:
	; in a ball, not in the air
	if SpinDashEnabled=1
		tst.b	obSpinDashFlag(a0)
		bne.s	.skip
		bsr.w	Sonic_Jump

.skip:
	else
		bsr.w	Sonic_Jump
	endif
		bsr.w	Sonic_RollRepel
		bsr.w	Sonic_RollSpeed
		bsr.w	Sonic_LevelBound
		jsr		(SpeedToPos).l
		bsr.w	Sonic_AnglePos
		bra.w	Sonic_SlopeRepel
; ===========================================================================

Sonic_MdJump:
	; in the air, in a ball (jumping or falling mid-roll)
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_JumpDirection
		bsr.w	Sonic_LevelBound
		jsr		(ObjectFall).l
		btst	#staWater,obStatus(a0)
		beq.s	loc_12EA6
		subi.w	#$28,obVelY(a0)

loc_12EA6:
		bsr.w	Sonic_JumpAngle
		bra.w	Sonic_Floor

		include	"_incObj/Sonic Move.asm"
		include	"_incObj/Sonic RollSpeed.asm"
		include	"_incObj/Sonic JumpDirection.asm"
		include	"_incObj/Sonic LevelBound.asm"
		include	"_incObj/Sonic Roll.asm"
		include	"_incObj/Sonic Jump.asm"
		include	"_incObj/Sonic JumpHeight.asm"
		
	if AirRollEnabled=1
		include "_incObj/Sonic AirRoll.asm"
	endif
	
	if PeeloutEnabled=1
		include	"_incObj/Sonic Peelout.asm"
	endif
	
	if SpinDashEnabled=1
		include	"_incObj/Sonic SpinDash.asm"
	endif

		include	"_incObj/Sonic SlopeResist.asm"
		include	"_incObj/Sonic RollRepel.asm"
		include	"_incObj/Sonic SlopeRepel.asm"
		include	"_incObj/Sonic JumpAngle.asm"
		include	"_incObj/Sonic Floor.asm"
	if CDCamera=1
		include	"_incObj/Sonic PanCamera.asm"
	endif
		include	"_incObj/Sonic ResetOnFloor.asm"
		include	"_incObj/Sonic (part 2).asm"
		include	"_incObj/Sonic Loops.asm"
		include	"_incObj/Sonic Animate.asm"
		include	"_anim/Sonic.asm"
		include	"_incObj/Sonic LoadGfx.asm"

dplcTiles := Art_Sonic			; MainMemory 128k Boundary Check for DPLCs
		include	"_maps/Sonic - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End

		include "_incObj/sub ApplySpeedSettings.asm"

		include	"_anim/Drowning Countdown.asm"
		include	"_incObj/0A Drowning Countdown.asm"


; ---------------------------------------------------------------------------
; Subroutine to	play music for LZ/SBZ3 after a countdown
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ResumeMusic:
		cmpi.b	#12,(v_air).w				; more than 12 seconds of air left?
		bhi.s	.over12						; if yes, branch
		move.w	#bgm_LZ,d0					; play LZ music
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w	; check if level is 0103 (SBZ3)
		bne.s	.notsbz
		move.w	#bgm_SBZ,d0					; play SBZ music

.notsbz:
	if SuperMod=1
		btst	#sta2ndSuper,(v_player+obStatus2nd).w	; is player in Super Form?
		bne.s	.playinvinc								; if yes, branch
	endif

		btst	#sta2ndInvinc,(v_player+obStatus2nd).w	; is Sonic invincible?
		beq.s	.notinvinc								; if not, branch

.playinvinc:
		move.w	#bgm_Invincible,d0

.notinvinc:
		tst.b	(f_lockscreen).w			; is Sonic at a boss?
		beq.s	.playselected				; if not, branch
		move.w	#bgm_Boss,d0

.playselected:
		jsr		(PlaySound).w				; restore music
		move.b	d0,(v_lastbgmplayed).w		; store last played music

.over12:
		move.b	#30,(v_air).w				; reset air to 30 seconds
		clr.b	(v_sonicbubbles+$32).w
		rts	
; End of function ResumeMusic

; ===========================================================================

		include	"_incObj/38 Shield.asm"
		include	"_incObj/21 Invincibility.asm"						; Split from Shields (RetroKoH)
		include	"_incObj/03 Collision Switcher.asm"
		include	"_incObj/08 Water Splash.asm"
		include	"_anim/Water Splash.asm"

		include	"_anim/Shields.asm"
dplcTiles := Art_Shield			; MainMemory 128k Boundary Check for DPLCs
	; Ensure that this check works w/ both art files
		include "_maps/Shield and Invincibility - DPLCs.asm"		; RetroKoH VRAM Overhaul
dplcTiles := 0					; 128k Boundary Check for DPLCs End

	if InstashieldEnabled
			include "_maps/Shield - Insta.asm"
dplcTiles := Art_Insta			; MainMemory 128k Boundary Check for DPLCs
			include "_maps/Shield - Insta - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End
	endif

	if ShieldsMode

			include "_maps/Shield - Flame.asm"
dplcTiles := Art_Shield_F		; MainMemory 128k Boundary Check for DPLCs
			include "_maps/Shield - Flame - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End

			include "_maps/Shield - Bubble.asm"
dplcTiles := Art_Shield_B		; MainMemory 128k Boundary Check for DPLCs
			include "_maps/Shield - Bubble - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End

			include "_maps/Shield - Lightning.asm"
dplcTiles := Art_Shield_L		; MainMemory 128k Boundary Check for DPLCs
	; Ensure that this check works w/ both art files
			include "_maps/Shield - Lightning - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End

	endif

		include	"_incObj/4A Special Stage Entry (Unused).asm"
		include	"_anim/Special Stage Entry (Unused).asm"

		include	"_incObj/Sonic AnglePos.asm"

		include	"_incObj/sub FindNearestTile.asm"
		include	"_incObj/sub FindFloor.asm"
		include	"_incObj/sub FindWall.asm"
		
		include "_incObj/8F Goggles.asm"
dplcTiles := Art_Goggles		; MainMemory 128k Boundary Check for DPLCs
		include "_maps/Goggles - DPLCs.asm"
dplcTiles := 0					; 128k Boundary Check for DPLCs End

; ---------------------------------------------------------------------------
; This subroutine takes 'raw' bitmap-like collision block data as input and
; converts it into the proper collision arrays (ColArray and ColArray2).
; Pointers to said raw data are dummied out.
; Curiously, an example of the original 'raw' data that this was intended
; to process can be found in the J2ME version, in a file called 'blkcol.bct'.
; ---------------------------------------------------------------------------

RawColBlocks		equ CollArray1
ConvRowColBlocks	equ CollArray1

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ConvertCollisionArray:
		rts	
; ---------------------------------------------------------------------------
		; The raw format stores the collision data column by column for the normal collision array.
		; This makes a copy of the data, but stored row by row, for the rotated collision array.
		lea	(RawColBlocks).l,a1	; Source location of raw collision block data
		lea	(ConvRowColBlocks).l,a2	; Destinatation location for row-converted collision block data

		move.w	#$100-1,d3		; Number of blocks in collision data

.blockLoop:
		moveq	#16,d5			; Start on the 16th bit (the leftmost pixel)

		move.w	#16-1,d2		; Width of a block in pixels

.columnLoop:
		moveq	#0,d4

		move.w	#16-1,d1		; Height of a block in pixels

.rowLoop:
		move.w	(a1)+,d0		; Get row of collision bits
		lsr.l	d5,d0			; Push the selected bit of this row into the 'eXtend' flag
		addx.w	d4,d4			; Shift d4 to the left, and insert the selected bit into bit 0
		dbf	d1,.rowLoop		; Loop for each row of pixels in a block

		move.w	d4,(a2)+		; Store column of collision bits
		suba.w	#2*16,a1		; Back to the start of the block
		subq.w	#1,d5			; Get next bit in the row
		dbf	d2,.columnLoop		; Loop for each column of pixels in a block

		adda.w	#2*16,a1		; Next block
		dbf	d3,.blockLoop		; Loop for each block in the raw collision block data

		; This then converts the collision data into the final collision arrays
		lea	(ConvRowColBlocks).l,a1
		lea	(CollArray2).l,a2	; Convert the row-converted collision block data into final rotated collision array
		bsr.s	.convertArray
		lea	(RawColBlocks).l,a1
		lea	(CollArray1).l,a2	; Convert the raw collision block data into final normal collision array


.convertArray:
		move.w	#$1000-1,d3		; Size of the collision array

.processLoop:
		moveq	#0,d2
		move.w	#$F,d1
		move.w	(a1)+,d0		; Get current column of collision pixels
		beq.s	.noCollision		; Branch if there's no collision in this column
		bmi.s	.topPixelSolid		; Branch if top pixel of collision is solid

	; Here we count, starting from the bottom, how many pixels tall
	; the collision in this column is.
.processColumnLoop1:
		lsr.w	#1,d0
		bhs.s	.pixelNotSolid1
		addq.b	#1,d2

.pixelNotSolid1:
		dbf	d1,.processColumnLoop1

		bra.s	.columnProcessed
; ===========================================================================

.topPixelSolid:
		cmpi.w	#$FFFF,d0		; Is entire column solid?
		beq.s	.entireColumnSolid	; Branch if so

	; Here we count, starting from the top, how many pixels tall
	; the collision in this column is (the resulting number is negative).
.processColumnLoop2:
		lsl.w	#1,d0
		bhs.s	.pixelNotSolid2
		subq.b	#1,d2

.pixelNotSolid2:
		dbf	d1,.processColumnLoop2

		bra.s	.columnProcessed
; ===========================================================================

.entireColumnSolid:
		move.w	#$10,d0

.noCollision:
		move.w	d0,d2

.columnProcessed:
		move.b	d2,(a2)+		; Store column collision height
		dbf	d3,.processLoop

		rts	

; End of function ConvertCollisionArray


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkSpeed:
		move.l	#v_collision1&$FFFFFF,(v_collindex).w	; MJ: load first collision data location
		cmpi.b	#$C,(v_top_solid_bit).w					; MJ: is second collision set to be used?
		beq.s	.first									; MJ: if not, branch
		move.l	#v_collision2&$FFFFFF,(v_collindex).w	; MJ: load second collision data location
.first:
		move.b	(v_lrb_solid_bit).w,d5					; MJ: load L/R/B soldity bit
		move.l	obX(a0),d3
		move.l	obY(a0),d2
		move.w	obVelX(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d3
		move.w	obVelY(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d2
		swap	d2
		swap	d3
		move.b	d0,(v_anglebuffer).w
		move.b	d0,(v_anglebuffer2).w
		move.b	d0,d1
		addi.b	#$20,d0
		bpl.s	loc_14D1A
		move.b	d1,d0
		bpl.s	loc_14D14
		subq.b	#1,d0

loc_14D14:
		addi.b	#$20,d0
		bra.s	loc_14D24
; ===========================================================================

loc_14D1A:
		move.b	d1,d0
		bpl.s	loc_14D20
		addq.b	#1,d0

loc_14D20:
		addi.b	#$1F,d0

loc_14D24:
		andi.b	#$C0,d0
		beq.w	loc_14DF0
		cmpi.b	#$80,d0
		beq.w	loc_14F7C
		andi.b	#$38,d1
		bne.s	loc_14D3C
		addq.w	#8,d2
	; Ralakimus Rolling Push Sensor Fix
		btst	#staSpin,obStatus(a0)	; Is Sonic rolling?
		beq.s	loc_14D3C				; If not, branch
		subq.w	#5,d2					; If so, move push sensor up a bit
	; Rolling Push Sensor Fix End

loc_14D3C:
		cmpi.b	#$40,d0
		beq.w	loc_1504A
		bra.w	loc_14EBC
; End of function Sonic_WalkSpeed


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14D48:
		move.l	#v_collision1&$FFFFFF,(v_collindex).w	; MJ: load first collision data location
		cmpi.b	#$C,(v_top_solid_bit).w					; MJ: is second collision set to be used?
		beq.s	.first									; MJ: if not, branch
		move.l	#v_collision2&$FFFFFF,(v_collindex).w	; MJ: load second collision data location
.first:
		move.b	(v_lrb_solid_bit).w,d5					; MJ: load L/R/B soldity bit
		move.b	d0,(v_anglebuffer).w
		move.b	d0,(v_anglebuffer2).w
		addi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	loc_14FD6
		cmpi.b	#$80,d0
		beq.w	Sonic_CheckCeilingDist
		cmpi.b	#$C0,d0
		beq.w	sub_14E50

; End of function sub_14D48

; ---------------------------------------------------------------------------
; Subroutine to	make Sonic land	on the floor after jumping
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitFloor:
		move.l	#v_collision1&$FFFFFF,(v_collindex).w	; MJ: load first collision data location
		cmpi.b	#$C,(v_top_solid_bit).w					; MJ: is second collision set to be used?
		beq.s	.first									; MJ: if not, branch
		move.l	#v_collision2&$FFFFFF,(v_collindex).w	; MJ: load second collision data location
.first:
		move.b	(v_top_solid_bit).w,d5					; MJ: load L/R/B soldity bit
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea		(v_anglebuffer).w,a4
		movea.w	#$10,a3
		clr.w	d6
		bsr.w	FindFloor	; MJ: check solidity
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea		(v_anglebuffer2).w,a4
		movea.w	#$10,a3
		clr.w	d6
		bsr.w	FindFloor	; MJ: check solidity
		move.w	(sp)+,d0
		clr.b	d2

loc_14DD0:
		move.b	(v_anglebuffer2).w,d3
		cmp.w	d0,d1
		ble.s	loc_14DDE
		move.b	(v_anglebuffer).w,d3
		exg		d0,d1

loc_14DDE:
		btst	#0,d3
		beq.s	locret_14DE6
		move.b	d2,d3

locret_14DE6:
		rts	

; End of function Sonic_HitFloor

; ===========================================================================

loc_14DF0:
		addi.w	#$A,d2
		lea		(v_anglebuffer).w,a4
		movea.w	#$10,a3
		clr.w	d6
		bsr.w	FindFloor	; MJ: check solidity
		clr.b	d2

loc_14E0A:
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14E16
		move.b	d2,d3

locret_14E16:
		rts	

		include	"_incObj/sub ObjFloorDist.asm"


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14E50:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		clr.w	d6
		bsr.w	FindWall	; MJ: check solidity
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#$10,a3
		clr.w	d6
		bsr.w	FindWall	; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#-$40,d2
		bra.w	loc_14DD0

; End of function sub_14E50

; ---------------------------------------------------------------------------
; Subroutine to	stop Sonic when	he jumps at a wall to his right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_CheckRightWallDist: ;sub_14EB4:
		move.w	obY(a0),d2
		move.w	obX(a0),d3

loc_14EBC:
		addi.w	#$A,d3
		lea		(v_anglebuffer).w,a4
		movea.w	#$10,a3
		clr.w	d6
		bsr.w	FindWall	; MJ: check solidity
		move.b	#-$40,d2
		bra.w	loc_14E0A

; End of function Sonic_CheckRightWallDist

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallRight:
		add.w	obX(a0),d3
		move.w	obY(a0),d2
		lea	(v_anglebuffer).w,a4
		clr.b	(a4)
		movea.w	#$10,a3
		clr.w	d6
		moveq	#$D,d5		; MJ: set solid type to check
		bsr.w	FindWall	; MJ: check solidity
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14F06
		move.b	#-$40,d3

locret_14F06:
		rts	

; End of function ObjHitWallRight

; ---------------------------------------------------------------------------
; Subroutine preventing	Sonic from running on walls and	ceilings when he
; touches them
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_CheckCeilingDist: ;Sonic_DontRunOnWalls:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea		(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6	; MJ: $1000/2
		bsr.w	FindFloor	; MJ: check solidity
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea		(v_anglebuffer2).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6	; MJ: $1000/2
		bsr.w	FindFloor	; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#-$80,d2
		bra.w	loc_14DD0
; End of function Sonic_DontRunOnWalls

; ===========================================================================

loc_14F7C:
		subi.w	#$A,d2
		eori.w	#$F,d2
		lea		(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6	; MJ: $1000/2
		bsr.w	FindFloor	; MJ: check solidity
		move.b	#-$80,d2
		bra.w	loc_14E0A

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitCeiling:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea		(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6	; MJ: $1000/2
		moveq	#$D,d5		; MJ: set solid type to check
		bsr.w	FindFloor	; MJ: check solidity
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14FD4
		move.b	#-$80,d3

locret_14FD4:
		rts	
; End of function ObjHitCeiling

; ===========================================================================

loc_14FD6:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6	; MJ: $800/2
		bsr.w	FindWall	; MJ: check solidity
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6	; MJ: $800/2
		bsr.w	FindWall	; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#$40,d2
		bra.w	loc_14DD0

; ---------------------------------------------------------------------------
; Subroutine to	stop Sonic when	he jumps at a wall to his left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_CheckLeftWallDist:	;Sonic_HitWall:
		move.w	obY(a0),d2
		move.w	obX(a0),d3

loc_1504A:
		subi.w	#$A,d3
		eori.w	#$F,d3
		lea		(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6	; MJ: $800/2
		bsr.w	FindWall	; MJ: check solidity
		move.b	#$40,d2
		bra.w	loc_14E0A
; End of function Sonic_HitWall

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallLeft:
		add.w	obX(a0),d3
		move.w	obY(a0),d2
		eori.w	#$F,d3		; added instruction to fix engine bug
		lea		(v_anglebuffer).w,a4
		clr.b	(a4)
		movea.w	#-$10,a3
		move.w	#$400,d6	; MJ: $800/2
		moveq	#$D,d5		; MJ: set solid type to check
		bsr.w	FindWall	; MJ: check solidity
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_15098
		move.b	#$40,d3

locret_15098:
		rts	
; End of function ObjHitWallLeft

; ===========================================================================

		include	"_incObj/66 Rotating Junction.asm"

		include	"_incObj/67 Running Disc.asm"

		include	"_incObj/68 Conveyor Belt.asm"
		include	"_incObj/69 SBZ Spinning Platforms.asm"
		include	"_anim/SBZ Spinning Platforms.asm"

		include	"_incObj/6A Saws and Pizza Cutters.asm"

		include	"_incObj/6B SBZ Stomper and Door.asm"

		include	"_incObj/6C SBZ Vanishing Platforms.asm"
		include	"_anim/SBZ Vanishing Platforms.asm"

		include	"_incObj/6E Electrocuter.asm"
		include	"_anim/Electrocuter.asm"

		include	"_incObj/6F SBZ Spin Platform Conveyor.asm"
		include	"_anim/SBZ Spin Platform Conveyor.asm"

		include	"_incObj/70 Girder Block.asm"

		include	"_incObj/72 Teleporter.asm"

		include	"_incObj/78 Caterkiller.asm"
		include	"_anim/Caterkiller.asm"

		include	"_incObj/79 Lamppost.asm"

		include	"_incObj/7D Hidden Bonuses.asm"


		include	"_incObj/8A Credits.asm"


		include	"_incObj/3D Boss - Green Hill (part 1).asm"

; ---------------------------------------------------------------------------
; Defeated boss	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BossDefeated:
		move.b	(v_vbla_byte).w,d0
		andi.b	#7,d0
		bne.s	locret_178A2
		jsr		(FindFreeObj).l
		bne.s	locret_178A2
		_move.b	#id_ExplosionBomb,obID(a1)	; load explosion object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		jsr		(RandomNumber).w
		move.w	d0,d1
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,obX(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,obY(a1)

locret_178A2:
		rts	
; End of function BossDefeated

; ---------------------------------------------------------------------------
; Subroutine to	move a boss
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BossMove:
	; DeltaW Optimized Object Movement
		movem.w	obVelX(a0),d0/d2	; load horizontal speed (d0) and vertical speed (d2)
		lsl.l	#8,d0				; multiply by $100 (combine ext and asl to become lsl)
		add.l	d0,objoff_30(a0)	; apply to stored x-axis position
		lsl.l	#8,d2				; multiply by $100 (combine ext and asl to become lsl)
		add.l	d2,objoff_38(a0)	; apply to stored y-axis position
		rts
; End of function BossMove

; ===========================================================================

		include	"_incObj/3D Boss - Green Hill (part 2).asm"
		include	"_incObj/48 Eggman's Swinging Ball.asm"
		include	"_anim/Eggman.asm"

		include	"_incObj/77 Boss - Labyrinth.asm"
		include	"_incObj/73 Boss - Marble.asm"

		include	"_incObj/7A Boss - Star Light.asm"
		include	"_incObj/7B SLZ Boss Spikeball.asm"

		include	"_incObj/75 Boss - Spring Yard.asm"
		include	"_incObj/76 SYZ Boss Blocks.asm"

		include	"_incObj/82 Eggman - Scrap Brain 2.asm"
		include	"_anim/Eggman - Scrap Brain 2 & Final.asm"

		include	"_incObj/83 SBZ Eggman's Crumbling Floor.asm"

		include	"_incObj/85 Boss - Final.asm"
		include	"_anim/FZ Eggman in Ship.asm"

		include	"_incObj/84 FZ Eggman's Cylinders.asm"

		include	"_incObj/86 FZ Plasma Ball Launcher.asm"
		include	"_anim/Plasma Ball Launcher.asm"

		include	"_anim/Plasma Balls.asm"

		include	"_incObj/3E Prison Capsule.asm"
		include	"_anim/Prison Capsule.asm"

		include	"_incObj/sub ReactToItem.asm"

; ---------------------------------------------------------------------------
; Subroutine to	show the special stage layout
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_ShowLayout:
		bsr.w	SS_AniWallsRings
		bsr.w	SS_AniItems
		move.w	d5,-(sp)
		lea		(v_ssbuffer3&$FFFFFF).l,a1
		move.b	(v_ssangle).w,d0

	if SmoothSpecialStages=0	; Cinossu Smooth Special Stages
		andi.b	#$FC,d0
	endif						; Smooth Special Stages End

		jsr		(CalcSine).w
		move.w	d0,d4
		move.w	d1,d5
		muls.w	#$18,d4
		muls.w	#$18,d5
		moveq	#0,d2
		move.w	(v_screenposx).w,d2
		divu.w	#$18,d2
		swap	d2
		neg.w	d2
		addi.w	#-$B4,d2
		moveq	#0,d3
		move.w	(v_screenposy).w,d3
		divu.w	#$18,d3
		swap	d3
		neg.w	d3
		addi.w	#-$B4,d3
		move.w	#$10-1,d7

loc_1B19E:
		movem.w	d0-d2,-(sp)
		movem.w	d0-d1,-(sp)
		neg.w	d0
		muls.w	d2,d1
		muls.w	d3,d0
		move.l	d0,d6
		add.l	d1,d6
		movem.w	(sp)+,d0-d1
		muls.w	d2,d0
		muls.w	d3,d1
		add.l	d0,d1
		move.l	d6,d2
		move.w	#$F,d6

loc_1B1C0:
		move.l	d2,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		move.l	d1,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		add.l	d5,d2
		add.l	d4,d1
		dbf		d6,loc_1B1C0

		movem.w	(sp)+,d0-d2
		addi.w	#$18,d3
		dbf		d7,loc_1B19E

		move.w	(sp)+,d5
		lea		(v_ssbuffer1&$FFFFFF).l,a0
		moveq	#0,d0
		move.w	(v_screenposy).w,d0
		divu.w	#$18,d0
		mulu.w	#$80,d0
		adda.l	d0,a0
		moveq	#0,d0
		move.w	(v_screenposx).w,d0
		divu.w	#$18,d0
		adda.w	d0,a0
		lea		(v_ssbuffer3&$FFFFFF).l,a4
		move.w	#$10-1,d7

loc_1B20C:
		move.w	#$F,d6

loc_1B210:
		moveq	#0,d0
		move.b	(a0)+,d0
		beq.s	loc_1B268
		cmpi.b	#SSBlock_GlassAni4,d0	; is the block ID higher than the last valid ID?
		bhi.s	loc_1B268				; if yes, branch
		move.w	(a4),d3
		addi.w	#$120,d3
		cmpi.w	#$70,d3
		blo.s	loc_1B268
		cmpi.w	#$1D0,d3
		bhs.s	loc_1B268
		move.w	2(a4),d2
		addi.w	#$F0,d2
		cmpi.w	#$70,d2
		blo.s	loc_1B268
		cmpi.w	#$170,d2
		bhs.s	loc_1B268
		lea		(v_ssblocktypes&$FFFFFF).l,a5
		lsl.w	#3,d0
		lea		(a5,d0.w),a5
		movea.l	(a5)+,a1
		move.w	(a5)+,d1
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		movea.w	(a5)+,a3
		; S2 BuildSprites Change
		move.w	(a1)+,d1
		subq.w	#1,d1
		; S2 BuildSprites End
		bmi.s	loc_1B268
		jsr	(BuildSpr_Normal).l

loc_1B268:
		addq.w	#4,a4
		dbf		d6,loc_1B210

		lea		$70(a0),a0
		dbf		d7,loc_1B20C

		move.b	d5,(v_spritecount).w
		cmpi.b	#$50,d5
		beq.s	loc_1B288
		clr.l	(a2)
		rts	
; ===========================================================================

loc_1B288:
		clr.b	-5(a2)
		rts	
; End of function SS_ShowLayout

; ---------------------------------------------------------------------------
; Subroutine to	animate	walls and rings	in the special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_AniWallsRings:
	if DynamicSpecialStageWalls=0	; Mercury Dynamic Special Stage Walls
		lea		((v_ssblocktypes+$C)&$FFFFFF).l,a1
		moveq	#0,d0
		move.b	(v_ssangle).w,d0
		lsr.b	#2,d0
		andi.w	#$F,d0
		moveq	#$24-1,d1

loc_1B2A4:
		move.w	d0,(a1)
		addq.w	#8,a1
		dbf		d1,loc_1B2A4
	endif	; Dynamic Special Stage Walls End

		lea		((v_ssblocktypes+5)&$FFFFFF).l,a1
		subq.b	#1,(v_ani1_time).w
		bpl.s	loc_1B2C8
		move.b	#3,(v_ani1_time).w		; Smooth Rings
		addq.b	#1,(v_ani1_frame).w
		andi.b	#7,(v_ani1_frame).w		; Smooth Rings
	; $1D0(a1) no longer gets set. We only use one frame for spinning rings (LoadSSRingFrame).

loc_1B2C8:
		subq.b	#1,(v_ani2_time).w
		bpl.s	loc_1B2E4
		move.b	#7,(v_ani2_time).w
		addq.b	#1,(v_ani2_frame).w
		andi.b	#1,(v_ani2_frame).w

loc_1B2E4:
		move.b	(v_ani2_frame).w,d0
		move.b	d0,$138(a1)
		move.b	d0,$160(a1)
		move.b	d0,$148(a1)
		move.b	d0,$150(a1)
		move.b	d0,$1D8(a1)
		move.b	d0,$1E0(a1)
		move.b	d0,$1E8(a1)
		move.b	d0,$1F0(a1)
		move.b	d0,$1F8(a1)
		move.b	d0,$200(a1)
	if SuperMod=1
		move.b	d0,$208(a1)
	endif
		subq.b	#1,(v_ani3_time).w
		bpl.s	loc_1B326
		move.b	#4,(v_ani3_time).w
		addq.b	#1,(v_ani3_frame).w
		andi.b	#3,(v_ani3_frame).w

loc_1B326:
		move.b	(v_ani3_frame).w,d0
		move.b	d0,$168(a1)
		move.b	d0,$170(a1)
		move.b	d0,$178(a1)
		move.b	d0,$180(a1)
		subq.b	#1,(v_ani0_time).w
		bpl.s	loc_1B350
		move.b	#7,(v_ani0_time).w
		subq.b	#1,(v_ani0_frame).w
		andi.b	#7,(v_ani0_frame).w

loc_1B350:
		lea		((v_ssblocktypes+$16)&$FFFFFF).l,a1
		lea		SS_WaRiVramSet(pc),a0
		moveq	#0,d0
		move.b	(v_ani0_frame).w,d0
		add.w	d0,d0
		lea		(a0,d0.w),a0
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		rts	
; End of function SS_AniWallsRings

; ===========================================================================
SS_WaRiVramSet:
		dc.w $142, $6142, $142,	$142, $142, $142, $142,	$6142
		dc.w $142, $6142, $142,	$142, $142, $142, $142,	$6142
		dc.w $2142, $142, $2142, $2142,	$2142, $2142, $2142, $142
		dc.w $2142, $142, $2142, $2142,	$2142, $2142, $2142, $142
		dc.w $4142, $2142, $4142, $4142, $4142,	$4142, $4142, $2142
		dc.w $4142, $2142, $4142, $4142, $4142,	$4142, $4142, $2142
		dc.w $6142, $4142, $6142, $6142, $6142,	$6142, $6142, $4142
		dc.w $6142, $4142, $6142, $6142, $6142,	$6142, $6142, $4142
; ===========================================================================


	if DynamicSpecialStageWalls=1	; Mercury Dynamic Special Stage Walls
SS_LoadWalls:
		moveq	#0,d0
		move.b	(v_ssangle).w,d0		; get the Special Stage angle
		lsr.b	#2,d0					; modify so it can be used as a frame ID
		andi.w	#$F,d0
		cmp.b	(v_ssangleprev).w,d0	; does the modified angle match the recorded value?
		beq.s	.return					; if so, branch
	
		lea		(vdp_data_port).l,a6
		lea		(Nem_SSWalls).l,a1		; load wall art
		move.w	d0,d1
		lsl.w	#8,d1
		add.w	d1,d1
		add.w	d1,a1
		
		locVRAM	$2840					; VRAM address
		
		move.w	#$F,d1					; number of 8x8 tiles
		bsr.s	LoadTiles
		move.b	d0,(v_ssangleprev).w	; record the modified angle for comparison
		
.return:
		rts

; ---------------------------------------------------------------------------
; Subroutine to	transfer graphics to VRAM

; input:
;	a1 = source address
;	a6 = vdp_data_port ($C00000)
;	d1 = number of tiles to load (minus one)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTiles:
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		dbf		d1,LoadTiles
		rts	
; End of function LoadTiles
; ===========================================================================
	endif	; Dynamic Special Stage Walls End

; ---------------------------------------------------------------------------
; Subroutine to	remove items when you collect them in the special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_RemoveCollectedItem:
		lea		(v_ssitembuffer&$FFFFFF).l,a2
		move.w	#(v_ssitembuffer_end-v_ssitembuffer)/8-1,d0

loc_1B4C4:
		tst.b	(a2)
		beq.s	locret_1B4CE
		addq.w	#8,a2
		dbf		d0,loc_1B4C4

locret_1B4CE:
		rts	
; End of function SS_RemoveCollectedItem

; ---------------------------------------------------------------------------
; Subroutine to	animate	special	stage items when you touch them
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_AniItems:
		lea		(v_ssitembuffer&$FFFFFF).l,a0
		move.w	#(v_ssitembuffer_end-v_ssitembuffer)/8-1,d7

loc_1B4DA:
		moveq	#0,d0
		move.b	(a0),d0
		beq.s	loc_1B4E8
		lsl.w	#2,d0
		movea.l	SS_AniIndex-4(pc,d0.w),a1
		jsr		(a1)

loc_1B4E8:
		addq.w	#8,a0

loc_1B4EA:
		dbf		d7,loc_1B4DA

		rts	
; End of function SS_AniItems

; ===========================================================================
SS_AniIndex:
		dc.l SS_AniRingSparks
		dc.l SS_AniBumper
		dc.l SS_Ani1Up
		dc.l SS_AniReverse
		dc.l SS_AniEmeraldSparks
		dc.l SS_AniGlassBlock
; ===========================================================================

SS_AniRingSparks:
		subq.b	#1,2(a0)
		bpl.s	locret_1B530
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniRingData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B530
		clr.l	(a0)
		clr.l	4(a0)

locret_1B530:
		rts	
; ===========================================================================
SS_AniRingData:	dc.b SSBlock_RingSparkle1, SSBlock_RingSparkle2, SSBlock_RingSparkle3, SSBlock_RingSparkle4, 0, 0
; ===========================================================================

SS_AniBumper:
		subq.b	#1,2(a0)
		bpl.s	locret_1B566
		move.b	#7,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniBumpData(pc,d0.w),d0
		bne.s	loc_1B564
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#SSBlock_Bumper,(a1)	; Revert to the original bumper block
		rts	
; ===========================================================================

loc_1B564:
		move.b	d0,(a1)					; set animation frame

locret_1B566:
		rts	
; ===========================================================================
SS_AniBumpData:	dc.b SSBlock_BumperHit1, SSBlock_BumperHit2, SSBlock_BumperHit1, SSBlock_BumperHit2, 0, 0
; ===========================================================================

SS_Ani1Up:
		subq.b	#1,2(a0)
		bpl.s	locret_1B596
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_Ani1UpData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B596
		clr.l	(a0)
		clr.l	4(a0)

	if SpecialStagesWithAllEmeralds=1	; Mercury Special Stages Still Appear With All Emeralds
		move.b	#4,($FFFFD024).w
	endc	; Special Stages Still Appear With All Emeralds End

locret_1B596:
		rts	
; ===========================================================================
SS_Ani1UpData:	dc.b SSBlock_ItemSparkle1, SSBlock_ItemSparkle2, SSBlock_ItemSparkle3, SSBlock_ItemSparkle4, 0, 0
; ===========================================================================

SS_AniReverse:
		subq.b	#1,2(a0)
		bpl.s	locret_1B5CC
		move.b	#7,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniRevData(pc,d0.w),d0
		bne.s	loc_1B5CA
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#$2B,(a1)
		rts	
; ===========================================================================

loc_1B5CA:
		move.b	d0,(a1)

locret_1B5CC:
		rts	
; ===========================================================================
SS_AniRevData:	dc.b SSBlock_R, SSBlock_R2, SSBlock_R, SSBlock_R2, 0, 0
; ===========================================================================

SS_AniEmeraldSparks:
		subq.b	#1,2(a0)
		bpl.s	locret_1B60C
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniEmerData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B60C
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#4,(v_player+obRoutine).w
		move.w	#sfx_SSGoal,d0
		jsr		(PlaySound_Special).w	; play special stage GOAL sound

locret_1B60C:
		rts	
; ===========================================================================
SS_AniEmerData:	dc.b SSBlock_ItemSparkle1, SSBlock_ItemSparkle2, SSBlock_ItemSparkle3, SSBlock_ItemSparkle4, 0, 0
; ===========================================================================

SS_AniGlassBlock:
		subq.b	#1,2(a0)
		bpl.s	locret_1B640
		move.b	#1,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniGlassData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B640
		move.b	4(a0),(a1)
		clr.l	(a0)
		clr.l	4(a0)

locret_1B640:
		rts	
; ===========================================================================
SS_AniGlassData:
		dc.b SSBlock_GlassAni1, SSBlock_GlassAni2, SSBlock_GlassAni3, SSBlock_GlassAni4
		dc.b SSBlock_GlassAni1, SSBlock_GlassAni2, SSBlock_GlassAni3, SSBlock_GlassAni4, 0,	0
; ===========================================================================

; ---------------------------------------------------------------------------
; Special stage	layout pointers
; ---------------------------------------------------------------------------
SS_LayoutIndex:
		dc.l SS_1
		dc.l SS_2
		dc.l SS_3
		dc.l SS_4
		dc.l SS_5
		dc.l SS_6
	if SuperMod=1
		dc.l SS_7
	endif
		even

; ---------------------------------------------------------------------------
; Special stage start locations
; ---------------------------------------------------------------------------
SS_StartLoc:	include	"_inc/Start Location Array - Special Stages.asm"

; ---------------------------------------------------------------------------
; Subroutine to	load special stage layout
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

	if SuperMod=1
emldCount: = 7
	else
emldCount: = 6
	endif

SS_Load:
		moveq	#0,d0

	if PerfectBonusEnabled
		move.w	d0,(v_perfectringsleft).w		; clear perfect rings counter
	endif

		move.b	(v_lastspecial).w,d0			; load number of last special stage entered

	if SpecialStageAdvancementMod	; Mercury Special Stage Index Increases Only If Won
		cmpi.b	#emldCount,d0
		bcs.s	SS_ChkEmldNum					; We don't increment here (This will instead be done in Obj09)
		move.b	#0,d0
		move.b	d0,(v_lastspecial).w			; reset if higher than 6/7 (emldCount)
	else
		addq.b	#1,(v_lastspecial).w			; increment, as we are entering a special stage
		cmpi.b	#emldCount,(v_lastspecial).w
		blo.s	SS_ChkEmldNum
		clr.b	(v_lastspecial).w				; reset if higher than 6/7 (emldCount)
	endif

SS_ChkEmldNum:
		cmpi.b	#emldCount,(v_emeralds).w		; do you have all emeralds?
		beq.s	SS_LoadData						; if yes, branch
		moveq	#0,d1
		tst.b	(v_emeralds).w					; check total # of emeralds
		beq.s	SS_LoadData						; if no emeralds, skip emerald check
		move.b	(v_emldlist).w,d1				; d1 = bit field that tells which emeralds we do/don't have

		btst	d0,d1							; Did you get this emerald?
		beq.s	SS_LoadData						; if not, branch
		bra.s	SS_Load							; infinite loop if emerald is already obtained
; ===========================================================================

SS_LoadData:
		; Load player position data
		lsl.w	#2,d0
		lea		SS_StartLoc(pc,d0.w),a1
		move.w	(a1)+,(v_player+obX).w
		move.w	(a1)+,(v_player+obY).w

		; Load layout data
		movea.l	SS_LayoutIndex(pc,d0.w),a0
		lea		(v_ssbuffer2&$FFFFFF).l,a1
		move.w	#make_art_tile(ArtTile_SS_Background_Clouds,0,FALSE),d0
		jsr		(EniDec).l

		; Clear everything from v_ssbuffer1 to v_ssbuffer2
		lea		(v_ssbuffer1&$FFFFFF).l,a1
		move.w	#(v_ssbuffer2-v_ssbuffer1)/4-1,d0

SS_ClrRAM3:
		clr.l	(a1)+
		dbf		d0,SS_ClrRAM3

		; Copy $1000 of data from v_ssbuffer2 to v_ssblockbuffer,
		; inserting $40 bytes of padding for every $40 bytes copied.
		lea		(v_ssblockbuffer&$FFFFFF).l,a1
		lea		(v_ssbuffer2&$FFFFFF).l,a0
		moveq	#(v_ssblockbuffer_end-v_ssblockbuffer)/$80-1,d1

loc_1B6F6:
		moveq	#$40-1,d2

loc_1B6F8:
	; Real-time layout altering and handling
	if AlteredSpecialStages
		move.b	(a0)+,d0				; load the layout item into d0
		
		if PerfectBonusEnabled
			cmpi.b	#SSBlock_Ring,d0			; is this item a ring?
			bne.s	.notring					; if not, branch
			addq.w	#1,(v_perfectringsleft).w	; increment perfect rings counter
	
	.notring:
		endif

		if S4SpecialStages
		; S4 Special Stage Mode removes UP, DOWN, and R blocks
			cmpi.b	#SSBlock_UP,d0				; is the item an UP Block?
			bcs.s	.dontchange
			cmpi.b	#SSBlock_R,d0				; is the item an R or DOWN Block?
			bhi.s	.dontchange					; if not any of these items, branch
			move.b	#SSBlock_GhostSolid,d0		; else, make a solid mint block
			bra.s	.loaditem					; if the next mod is disabled, this will become a nop instead
	
	.dontchange:
		endif
		
		if SpecialStagesWithAllEmeralds
		; Emeralds are replaced with 1-Ups if already collected
			cmpi.b	#SSBlock_Emld1,d0			; is the item an emerald?
			bcs.s	.loaditem
			cmpi.b	#SSBlock_EmldLast,d0
			bhi.s	.loaditem
			cmpi.b	#emldCount,(v_emeralds).w	; do you have all the emeralds?
			bne.s	.loaditem					; if not, branch
			move.b	#SSBlock_1Up,d0				; else, make a 1up
		endif
		
	.loaditem:
		move.b	d0,(a1)+				; load the item into memory
	else
		move.b	(a0)+,(a1)+				; load the item into memory (called if we aren't counting rings or altering blocks)
	endif

		dbf		d2,loc_1B6F8

		lea		$40(a1),a1
		dbf		d1,loc_1B6F6

		lea		((v_ssblocktypes+8)&$FFFFFF).l,a1
		lea		(SS_MapIndex).l,a0
		moveq	#(SS_MapIndex_End-SS_MapIndex)/6-1,d1

loc_1B714:
		move.l	(a0)+,(a1)+
		clr.w	(a1)+
		move.b	-4(a0),-1(a1)
		move.w	(a0)+,(a1)+
		dbf		d1,loc_1B714

		lea		(v_ssitembuffer&$FFFFFF).l,a1
		move.w	#(v_ssitembuffer_end-v_ssitembuffer)/4-1,d1

loc_1B730:
		clr.l	(a1)+
		dbf		d1,loc_1B730

		rts	
; End of function SS_Load

; ===========================================================================

SS_MapIndex:
		include	"_inc/Special Stage Mappings & VRAM Pointers.asm"
SS_MapIndex_End:

		include	"_incObj/09 Sonic in Special Stage.asm"
		include "_incObj/06 SS Debug Cursor.asm"

		include	"_incObj/10.asm"

		include	"_inc/AnimateLevelGfx.asm"

		include	"_incObj/8E AfterImages.asm"

; ---------------------------------------------------------------------------
; Add points subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


AddPoints:
		move.b	#1,(f_scorecount).w		; set score counter to update
		lea     (v_score).w,a3
		add.l   d0,(a3)
		move.l  #999999,d1
		cmp.l   (a3),d1					; is score below 999999?
		bhi.s   .belowmax				; if yes, branch
		move.l  d1,(a3)					; reset score to 999999
.belowmax:
		move.l  (a3),d0
		cmp.l   (v_scorelife).w,d0		; has Sonic got 50000+ points?
		blo.s   .noextralife			; if not, branch

		addi.l  #5000,(v_scorelife).w	; increase requirement by 50000
		
	; Mercury Lives Over/Underflow Fix
		cmpi.b	#99,(v_lives).w			; are lives at max?
		beq.s	.playbgm
		addq.b	#1,(v_lives).w			; add 1 to number of lives
		addq.b	#1,(f_lifecount).w		; update the lives counter
.playbgm:
	; Lives Over/Underflow Fix end
		
		move.w	#bgm_ExtraLife,d0
		jmp		(PlaySound).w			; play extra life bgm

.noextralife:
		rts	
; End of function AddPoints

		include	"_inc/HUD Update.asm"

	if HUDInSpecialStage=1	; Mercury HUD In Special Stage
		include	"_inc/HUD Update SS.asm"
	endif	; HUD In Special Stage End

; ---------------------------------------------------------------------------
; Subroutine to	load countdown numbers on the continue screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ContScrCounter:
		locVRAM	ArtTile_Continue_Number*tile_size
		lea		(vdp_data_port).l,a6
		lea		(Hud_10).l,a2
		moveq	#2-1,d6
		moveq	#0,d4
		lea		Art_Hud(pc),a1		; load numbers patterns

ContScr_Loop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C95A:
		sub.l	d3,d1
		blo.s	loc_1C962
		addq.w	#1,d2
		bra.s	loc_1C95A
; ===========================================================================

loc_1C962:
		add.l	d3,d1
		lsl.w	#6,d2
		lea		(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		dbf		d6,ContScr_Loop	; repeat 1 more	time

		rts	
; End of function ContScrCounter

; ===========================================================================

		include	"_inc/HUD (part 2).asm"

	if HUDCentiseconds=1	; Mercury HUD Centiseconds
Art_Hud:	binclude	"artunc/HUD Numbers (centiseconds).bin" ; 8x16 pixel numbers on HUD
		even
	else
Art_Hud:	binclude	"artunc/HUD Numbers.bin" ; 8x16 pixel numbers on HUD
		even
	endif	; HUD Centiseconds End


Art_LivesNums:	binclude	"artunc/Lives Counter Numbers.bin" ; 8x8 pixel numbers on lives counter
		even

		include	"_incObj/DebugMode.asm"
		include	"_inc/DebugList.asm"
		include "_inc/DebugList - Special.asm"
		include	"_inc/LevelHeaders.asm"
		include	"_inc/Pattern Load Cues.asm"

		align	$200

		rept $300
			dc.b	$FF
		endm

Nem_SegaLogo:	binclude	"artnem/Sega Logo.nem" ; large Sega logo
			even
Eni_SegaLogo:	binclude	"tilemaps/Sega Logo.eni" ; large Sega logo (mappings)
			even

	if ChunksInROM=1	;Mercury Chunks In ROM
Eni_Title:	binclude	"tilemaps_u/Title Screen.bin" ; title screen foreground (mappings)
		even
	else
Eni_Title:	binclude	"tilemaps/Title Screen.eni" ; title screen foreground (mappings)
		even
	endif	;Chunks In ROM


	if SaveProgressMod=1
Nem_TitleFg:	binclude	"artnem/Title Screen Foreground (Menu).nem"
	else
Nem_TitleFg:	binclude	"artnem/Title Screen Foreground.nem"
	endif
		even


Nem_TitleTM:	binclude	"artnem/Title Screen TM.nem"
		even
Eni_JapNames:	binclude	"tilemaps/Hidden Japanese Credits.eni" ; Japanese credits (mappings)
		even
Nem_JapNames:	binclude	"artnem/Hidden Japanese Credits.nem"
		even

	if NewLevelSelect
Eni_MenuBack:		binclude	"tilemaps/SONIC MILES background.eni"
		even
Art_MenuBack:		binclude	"artunc/SONIC MILES background art.bin"
		even
Nem_MenuStuff:		binclude	"artnem/S2 Level Select Font.nem"
		even

	if BetaLevelOrder
Eni_LevSel:			binclude	"tilemaps/S2 Level Select (Beta Order).eni"
		even
	else
Eni_LevSel:			binclude	"tilemaps/S2 Level Select.eni"
		even
	endif


Eni_LevSelIcons:	binclude	"tilemaps/S2 Level Select Icons.eni"
		even
Nem_LevSelIcons:	binclude	"artnem/S2 Level Select Icons.nem"
		even
	endif

; ---------------------------------------------------------------------------
; Uncompressed graphics	- Sonic
; ---------------------------------------------------------------------------
Art_Sonic:		binclude	"artunc/Sonic.bin"					; Sonic
		even
Art_Shield:		binclude	"artunc/Shield - Blue.bin"			; Blue Shield -- RetroKoH VRAM Overhaul
		even
Art_Stars:		binclude	"artunc/Invincibility Stars.bin"	; Invincibility Stars -- RetroKoH VRAM Overhaul
		even
Art_Goggles:	binclude	"artunc/Goggles.bin"				; Goggles
		even

	if InstashieldEnabled
Art_Insta:		binclude	"artunc/Shield - Insta.bin"
		even
	endif

	if ShieldsMode
Art_Shield_F:	binclude	"artunc/Shield - Flame.bin"
		even
Art_Shield_B:	binclude	"artunc/Shield - Bubble.bin"
		even
Art_Shield_L:	binclude	"artunc/Shield - Lightning.bin"
		even
Art_Shield_L2:	binclude	"artunc/Shield - Lightning Sparks.bin"
		even
	endif

	if SuperMod
Art_SuperStars:	binclude	"artunc/Super Sonic Stars.bin"
Art_SuperStars_End:	even
	endif

	switch UpdatedSignposts
	case 2
Art_Signpost:	binclude	"artunc/Signpost - Hybrid.bin"	; End-of-level Signpost -- RetroKoH VRAM Overhaul
	case 1
Art_Signpost:	binclude	"artunc/Signpost - CD.bin"		; End-of-level Signpost -- RetroKoH VRAM Overhaul
	elsecase
Art_Signpost:	binclude	"artunc/Signpost.bin"			; End-of-level Signpost -- RetroKoH VRAM Overhaul
	endcase
		even

Art_BigRing:	binclude	"artunc/Giant Ring.bin"				; Giant Ring -- RetroKoH VRAM Overhaul
		even

	if (SpinDashEnabled|SkidDustEnabled)=1
Art_Effects:	binclude	"artunc/Dust Effects.bin"			; Spindash/Skid Dust
		even
				include "_maps/Effects.asm"
	endif

	if RandomMonitors
Art_Mon_Rand:	binclude	"artunc/Monitors - Random.bin"		; Monitor Art Mod
		even
	endif

	if OptimalTitleCardArt
	; RetroKoH Optimal Title Cards for VRAM/SpritePiece Reduction
	
	include "artunc/Title and End Cards/Art Includes.asm"
	
	else

; AURORA☆FIELDS Title Card Optimization
	if CoolBonusEnabled
Art_TitleCard:	binclude	"artunc/Title Cards - COOL.bin"		; Title Card patterns
	else
Art_TitleCard:	binclude	"artunc/Title Cards.bin"			; Title Card patterns
	endif
Art_TitleCard_End:	even

	endif

; RetroKoH Perfect Bonus Mod
	if PerfectBonusEnabled
Art_Perfect:	binclude	"artunc/Perfect Text.bin"			; Result Perfect Bonus Text
Art_Perfect_End:
	endif
	

Art_TimeOver:	binclude	"artunc/Time Over.bin"				; time over (TI) -- RetroKoH VRAM Overhaul
Art_TimeOver_End:	even


; We only need to add an 'align $20000' at any point where art that is used by DPLCs crosses a 128k boundary
	align $20000
Art_TitleSonic:	binclude	"artunc/Title Screen Sonic.bin"		; Title Sonic -- RetroKoH VRAM Overhaul
		even

				include	"_maps/SS Walls.asm"	; Now includes dynamic mappings -- Mercury Dynamic Special Stage Walls

; ---------------------------------------------------------------------------
; Compressed graphics - special stage
; ---------------------------------------------------------------------------

	if DynamicSpecialStageWalls=1	; Mercury Dynamic Special Stage Walls
Nem_SSWalls:	binclude	"artunc/Special Walls (dynamic).bin"
	else
Nem_SSWalls:	binclude	"artnem/Special Walls.nem"
	endif	; Dynamic Special Stage Walls End
		even

Eni_SSBg1:	binclude	"tilemaps/SS Background 1.eni" ; special stage background (mappings)
		even
Nem_SSBgFish:	binclude	"artnem/Special Birds & Fish.nem" ; special stage birds and fish background
		even
Eni_SSBg2:	binclude	"tilemaps/SS Background 2.eni" ; special stage background (mappings)
		even
Nem_SSBgCloud:	binclude	"artnem/Special Clouds.nem" ; special stage clouds background
		even
Nem_SSGOAL:	binclude	"artnem/Special GOAL.nem" ; special stage GOAL block
		even
Nem_SSRBlock:	binclude	"artnem/Special R.nem"	; special stage R block
		even
Nem_SS1UpBlock:	binclude	"artnem/Special 1UP.nem" ; special stage 1UP block
		even
Nem_SSEmStars:	binclude	"artnem/Special Emerald Twinkle.nem" ; special stage stars from a collected emerald
		even
Nem_SSRedWhite:	binclude	"artnem/Special Red-White.nem" ; special stage red/white block
		even
Nem_SSUpDown:	binclude	"artnem/Special UP-DOWN.nem" ; special stage UP/DOWN block
		even
Nem_SSEmerald:	binclude	"artnem/Special Emeralds.nem" ; special stage chaos emeralds
		even
Nem_SSGhost:	binclude	"artnem/Special Ghost.nem" ; special stage ghost block
		even
Nem_SSWBlock:	binclude	"artnem/Special W.nem"	; special stage W block
		even
Nem_SSGlass:	binclude	"artnem/Special Glass.nem" ; special stage destroyable glass block
		even
Nem_SSCursor:	binclude	"artnem/Special Cursor.nem" ; special stage debug cursor (RetroKoH: imported from Sonic 1 (2013))
		even
Nem_SSDelete:	binclude	"artnem/Special Delete.nem" ; special stage debug delete icon (RetroKoH: imported from Sonic 1 (2013))
		even
Nem_ResultEm:	binclude	"artnem/Special Result Emeralds.nem" ; chaos emeralds on special stage results screen
		even
; ---------------------------------------------------------------------------
; Compressed graphics - GHZ stuff
; ---------------------------------------------------------------------------
Nem_Stalk:	binclude	"artnem/GHZ Flower Stalk.nem"
		even
Nem_Swing:	binclude	"artnem/GHZ Swinging Platform.nem"
		even
Nem_Bridge:	binclude	"artnem/GHZ Bridge.nem"
		even
Nem_GhzUnkBlock:binclude	"artnem/Unused - GHZ Block.nem"
		even
Nem_Ball:	binclude	"artnem/GHZ Giant Ball.nem"
		even
Nem_Spikes:	binclude	"artnem/Spikes.nem"
		even
Nem_GhzLog:	binclude	"artnem/Unused - GHZ Log.nem"
		even
Nem_SpikePole:	binclude	"artnem/GHZ Spiked Log.nem"
		even
Nem_PplRock:	binclude	"artnem/GHZ Purple Rock.nem"
		even
Nem_GhzWall1:	binclude	"artnem/GHZ Breakable Wall.nem"
		even
Nem_GhzWall2:	binclude	"artnem/GHZ Edge Wall.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - LZ stuff
; ---------------------------------------------------------------------------
Nem_Water:		binclude	"artnem/LZ Water Surface.nem"
		even
Nem_Waterfall:	binclude	"artnem/LZ Waterfall.nem"	; Split Waterfall and Splash -- RetroKoH VRAM Reshuffle
		even
Nem_Splash:		binclude	"artnem/Water Splash.nem"	; To-Do: Make uncompressed and load in dash dust spot -- RetroKoH VRAM Reshuffle
		even
Nem_LzSpikeBall:binclude	"artnem/LZ Spiked Ball & Chain.nem"
		even
Nem_FlapDoor:	binclude	"artnem/LZ Flapping Door.nem"
		even
Nem_Bubbles:	binclude	"artnem/LZ Bubbles & Countdown.nem"
		even
Nem_LzBlock3:	binclude	"artnem/LZ 32x16 Block.nem"
		even
Nem_LzDoor1:	binclude	"artnem/LZ Vertical Door.nem"
		even
Nem_Harpoon:	binclude	"artnem/LZ Harpoon.nem"
		even
Nem_LzPole:		binclude	"artnem/LZ Breakable Pole.nem"
		even
Nem_LzDoor2:	binclude	"artnem/LZ Horizontal Door.nem"
		even
Nem_LzConvPtfm:	binclude	"artnem/LZ Conveyor Platform.nem"
		even
Nem_Gargoyle:	binclude	"artnem/LZ Gargoyle & Fireball.nem"
		even
Nem_LzBlock2:	binclude	"artnem/LZ Blocks.nem"
		even
Nem_LzPlatfm:	binclude	"artnem/LZ Rising Platform.nem"
		even
Nem_Cork:		binclude	"artnem/LZ Cork.nem"
		even
Nem_LzBlock1:	binclude	"artnem/LZ 32x32 Block.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - MZ stuff
; ---------------------------------------------------------------------------
Nem_MzMetal:	binclude	"artnem/MZ Metal Blocks.nem"
		even
Nem_MzSwitch:	binclude	"artnem/MZ Switch.nem"
		even
Nem_MzGlass:	binclude	"artnem/MZ Green Glass Block.nem"
		even
Nem_UnkGrass:	binclude	"artnem/Unused - Grass.nem"
		even
Nem_Fireball:	binclude	"artnem/Fireballs.nem"
		even
Nem_Lava:	binclude	"artnem/MZ Lava.nem"
		even
Nem_MzBlock:	binclude	"artnem/MZ Green Pushable Block.nem"
		even
Nem_MzUnkBlock:	binclude	"artnem/Unused - MZ Background.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SLZ stuff
; ---------------------------------------------------------------------------
Nem_Seesaw:	binclude	"artnem/SLZ Seesaw.nem"
		even
Nem_SlzSpike:	binclude	"artnem/SLZ Little Spikeball.nem"
		even
Nem_Fan:	binclude	"artnem/SLZ Fan.nem"
		even
Nem_SlzWall:	binclude	"artnem/SLZ Breakable Wall.nem"
		even
Nem_Pylon:	binclude	"artnem/SLZ Pylon.nem"
		even
Nem_SlzSwing:	binclude	"artnem/SLZ Swinging Platform.nem"
		even
Nem_SlzBlock:	binclude	"artnem/SLZ 32x32 Block.nem"
		even
Nem_SlzCannon:	binclude	"artnem/SLZ Cannon.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SYZ stuff
; ---------------------------------------------------------------------------
Nem_Bumper:	binclude	"artnem/SYZ Bumper.nem"
		even
Nem_SyzSpike2:	binclude	"artnem/SYZ Small Spikeball.nem"
		even
Nem_LzSwitch:	binclude	"artnem/Switch.nem"
		even
Nem_SyzSpike1:	binclude	"artnem/SYZ Large Spikeball.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SBZ stuff
; ---------------------------------------------------------------------------
Nem_SbzWheel1:	binclude	"artnem/SBZ Running Disc.nem"
		even
Nem_SbzWheel2:	binclude	"artnem/SBZ Junction Wheel.nem"
		even
Nem_Cutter:	binclude	"artnem/SBZ Pizza Cutter.nem"
		even
Nem_Stomper:	binclude	"artnem/SBZ Stomper.nem"
		even
Nem_SpinPform:	binclude	"artnem/SBZ Spinning Platform.nem"
		even
Nem_TrapDoor:	binclude	"artnem/SBZ Trapdoor.nem"
		even
Nem_SbzFloor:	binclude	"artnem/SBZ Collapsing Floor.nem"
		even
Nem_Electric:	binclude	"artnem/SBZ Electrocuter.nem"
		even
Nem_SbzBlock:	binclude	"artnem/SBZ Vanishing Block.nem"
		even
Nem_FlamePipe:	binclude	"artnem/SBZ Flaming Pipe.nem"
		even
Nem_SbzDoor1:	binclude	"artnem/SBZ Small Vertical Door.nem"
		even
Nem_SlideFloor:	binclude	"artnem/SBZ Sliding Floor Trap.nem"
		even
Nem_SbzDoor2:	binclude	"artnem/SBZ Large Horizontal Door.nem"
		even
Nem_Girder:	binclude	"artnem/SBZ Crushing Girder.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - enemies
; ---------------------------------------------------------------------------
Nem_BallHog:	binclude	"artnem/Enemy Ball Hog.nem"
		even
Nem_Crabmeat:	binclude	"artnem/Enemy Crabmeat.nem"
		even
Nem_Buzz:	binclude	"artnem/Enemy Buzz Bomber.nem"
		even
Nem_UnkExplode:	binclude	"artnem/Unused - Explosion.nem"
		even
Nem_Burrobot:	binclude	"artnem/Enemy Burrobot.nem"
		even
Nem_Chopper:	binclude	"artnem/Enemy Chopper.nem"
		even
Nem_Jaws:	binclude	"artnem/Enemy Jaws.nem"
		even
Nem_Roller:	binclude	"artnem/Enemy Roller.nem"
		even
Nem_Motobug:	binclude	"artnem/Enemy Motobug.nem"
		even
Nem_Newtron:	binclude	"artnem/Enemy Newtron.nem"
		even
Nem_Yadrin:	binclude	"artnem/Enemy Yadrin.nem"
		even
Nem_Basaran:	binclude	"artnem/Enemy Basaran.nem"
		even
Nem_Splats:	binclude	"artnem/Enemy Splats.nem"
		even
Nem_Bomb:	binclude	"artnem/Enemy Bomb.nem"
		even

	if SLZOrbinautBehaviourMod=1	;Mercury SLZ Orbinaut Behaviour Mod
Nem_Orbinaut_SLZ:	binclude	"artnem/Enemy Orbinaut (SLZ).nem"
		even

Nem_Orbinaut:	binclude	"artnem/Enemy Orbinaut.nem"
		even
	else	; SLZ Orbinaut Behaviour Mod End
Nem_Orbinaut_SLZ:
Nem_Orbinaut:	binclude	"artnem/Enemy Orbinaut.nem"
		even
	endif

Nem_Cater:	binclude	"artnem/Enemy Caterkiller.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_Hud:		binclude	"artnem/HUD.nem"	; HUD (rings, time, score)
		even
Nem_Lives:		binclude	"artnem/HUD - Life Counter Icon.nem"
		even

Art_Ring:		binclude	"artunc/Rings.bin"
		even
Nem_Sparkles:	binclude	"artnem/Ring Sparkles.nem"
		even

	if ShieldsMode
Nem_Monitors:	binclude	"artnem/Monitors - S3K.nem"
		even
	else
Nem_Monitors:	binclude	"artnem/Monitors.nem"
		even
	endif

Nem_Explode:	binclude	"artnem/Explosion.nem"
		even
Nem_Points:		binclude	"artnem/Points.nem"	; points from destroyed enemy or object
		even
Nem_GameOver:	binclude	"artnem/Game Over.nem"	; game over (Time Over now dynamically loads in)
		even
Nem_HSpring:	binclude	"artnem/Spring Horizontal.nem"
		even
Nem_VSpring:	binclude	"artnem/Spring Vertical.nem"
		even
Nem_Lamp:		binclude	"artnem/Lamppost.nem"
		even
Nem_Bonus:		binclude	"artnem/Hidden Bonuses.nem" ; hidden bonuses at end of a level
		even
; ---------------------------------------------------------------------------
; Compressed graphics - continue screen
; ---------------------------------------------------------------------------
Nem_ContSonic:	binclude	"artnem/Continue Screen Sonic.nem"
		even
Nem_MiniSonic:	binclude	"artnem/Continue Screen Stuff.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - animals
; ---------------------------------------------------------------------------
Nem_Rabbit:	binclude	"artnem/Animal Rabbit.nem"
		even
Nem_Chicken:	binclude	"artnem/Animal Chicken.nem"
		even
Nem_Penguin:	binclude	"artnem/Animal Penguin.nem"
		even
Nem_Seal:	binclude	"artnem/Animal Seal.nem"
		even
Nem_Pig:	binclude	"artnem/Animal Pig.nem"
		even
Nem_Flicky:	binclude	"artnem/Animal Flicky.nem"
		even
Nem_Squirrel:	binclude	"artnem/Animal Squirrel.nem"
		even

	if NewSBZ3LevelArt
; ---------------------------------------------------------------------------
; Compressed graphics - SBZ3 Exclusive (RetroKoH)
; ---------------------------------------------------------------------------

Nem_Burrobot_SBZ3:	binclude	"artnem/Enemy SBZ3 Burrobot.nem"
		even
Nem_Orbinaut_SBZ3:	binclude	"artnem/Enemy SBZ3 Orbinaut.nem"
		even
Nem_Jaws_SBZ3:		binclude	"artnem/Enemy SBZ3 Jaws.nem"
		even
Nem_FlapDoor_SBZ3:	binclude	"artnem/SBZ3 Flapping Door.nem"
		even
	endif

; ---------------------------------------------------------------------------
; Block mappings
; ---------------------------------------------------------------------------
	if BlocksInROM=1	;Mercury Blocks In ROM
Blk16_GHZ:	binclude	"map16_u/GHZ.bin"
		even
Blk16_LZ:	binclude	"map16_u/LZ.bin"
		even
Blk16_MZ:	binclude	"map16_u/MZ.bin"
		even
Blk16_SLZ:	binclude	"map16_u/SLZ.bin"
		even
Blk16_SYZ:	binclude	"map16_u/SYZ.bin"
		even
Blk16_SBZ:	binclude	"map16_u/SBZ.bin"
		even

	if NewSBZ3LevelArt
Blk16_SBZ3:	binclude	"map16_u/SBZ3.bin"
		even
	endif

	else

Blk16_GHZ:	binclude	"map16/GHZ.eni"
		even
Blk16_LZ:	binclude	"map16/LZ.eni"
		even
Blk16_MZ:	binclude	"map16/MZ.eni"
		even
Blk16_SLZ:	binclude	"map16/SLZ.eni"
		even
Blk16_SYZ:	binclude	"map16/SYZ.eni"
		even
Blk16_SBZ:	binclude	"map16/SBZ.eni"
		even

	if NewSBZ3LevelArt
Blk16_SBZ3:	binclude	"map16/SBZ3.eni"
		even
	endif

	endif	;end Blocks In ROM

; ---------------------------------------------------------------------------
; Chunk data
; ---------------------------------------------------------------------------
	if ChunksInROM=1	;Mercury Chunks In ROM
Blk128_GHZ:	binclude	"map128_u/GHZ.bin"
		even
Blk128_LZ:	binclude	"map128_u/LZ.bin"
		even
Blk128_MZ:	binclude	"map128_u/MZ.bin"
		even
Blk128_SLZ:	binclude	"map128_u/SLZ.bin"
		even
Blk128_SYZ:	binclude	"map128_u/SYZ.bin"
		even
Blk128_SBZ:	binclude	"map128_u/SBZ.bin"
		even

	if NewSBZ3LevelArt
Blk128_SBZ3:	binclude	"map128_u/SBZ3.bin"
		even
	endif

	else

Blk128_GHZ:	binclude	"map128/GHZ.kos"
		even
Blk128_LZ:	binclude	"map128/LZ.kos"
		even
Blk128_MZ:	binclude	"map128/MZ.kos"
		even
Blk128_SLZ:	binclude	"map128/SLZ.kos"
		even
Blk128_SYZ:	binclude	"map128/SYZ.kos"
		even
Blk128_SBZ:	binclude	"map128/SBZ.kos"
		even

	if NewSBZ3LevelArt
Blk128_SBZ3:	binclude	"map128/SBZ3.kos"
		even
	endif

	endif	;end Chunks In ROM

; ---------------------------------------------------------------------------
; Compressed level graphics
; ---------------------------------------------------------------------------
Nem_Title:		binclude	"artnem/8x8 - Title.nem"	; Title Screen GHZ patterns -- Clownacy S2 Level Art Loading
		even
ArtKos_GHZ:		binclude	"artkos/8x8 - GHZ.kos"		; GHZ patterns -- Clownacy S2 Level Art Loading
		even
ArtKos_LZ:		binclude	"artkos/8x8 - LZ.kos"		; LZ primary patterns -- Clownacy S2 Level Art Loading
		even
ArtKos_MZ:		binclude	"artkos/8x8 - MZ.kos"		; MZ primary patterns -- Clownacy S2 Level Art Loading
		even
ArtKos_SLZ:		binclude	"artkos/8x8 - SLZ.kos"		; SLZ primary patterns -- Clownacy S2 Level Art Loading
		even
ArtKos_SYZ:		binclude	"artkos/8x8 - SYZ.kos"		; SYZ primary patterns -- Clownacy S2 Level Art Loading
		even
ArtKos_SBZ:		binclude	"artkos/8x8 - SBZ.kos"		; SBZ primary patterns -- Clownacy S2 Level Art Loading
		even

	if NewSBZ3LevelArt
ArtKos_SBZ3:	binclude	"artkos/8x8 - SBZ3.kos"		; SBZ3 primary patterns -- Clownacy S2 Level Art Loading
		even
	endif

; ---------------------------------------------------------------------------
; Compressed graphics - bosses and ending sequence
; ---------------------------------------------------------------------------
Nem_Eggman:	binclude	"artnem/Boss - Main.nem"
		even
Nem_Weapons_GHZ:	binclude	"artnem/Boss - Weapons - GHZ.nem"
		even
Nem_Weapons_MZ:	binclude	"artnem/Boss - Weapons - MZ.nem"
		even
Nem_Weapons_SYZ:	binclude	"artnem/Boss - Weapons - SYZ.nem"	; Removed 1 unneeded tile
		even
Nem_Weapons_SLZ:	binclude	"artnem/Boss - Weapons - SLZ.nem"	; Add Spikeball to this set
		even
Nem_Weapons:	binclude	"artnem/Boss - Weapons.nem"
		even
Nem_Prison:	binclude	"artnem/Prison Capsule.nem"
		even
Nem_Sbz2Eggman:	binclude	"artnem/Boss - Eggman in SBZ2 & FZ.nem"
		even
Nem_FzBoss:	binclude	"artnem/Boss - Final Zone.nem"
		even
Nem_FzEggman:	binclude	"artnem/Boss - Eggman after FZ Fight.nem"
		even
Nem_Exhaust:	binclude	"artnem/Boss - Exhaust Flame.nem"
		even
Nem_EndEm:	binclude	"artnem/Ending - Emeralds.nem"
		even
Nem_EndSonic:	binclude	"artnem/Ending - Sonic.nem"
		even
Nem_TryAgain:	binclude	"artnem/Ending - Try Again.nem"
		even
Kos_EndFlowers:	binclude	"artkos/Flowers at Ending.kos" ; ending sequence animated flowers
		even
Nem_EndFlower:	binclude	"artnem/Ending - Flowers.nem"
		even
Nem_CreditText:	binclude	"artnem/Ending - Credits.nem"
		even
Nem_EndStH:	binclude	"artnem/Ending - StH Logo.nem"
		even

		rept $40
		dc.b $FF
		endm

; ---------------------------------------------------------------------------
; Collision data
; ---------------------------------------------------------------------------
AngleMap:	binclude	"collide/Angle Map.bin"
		even
CollArray1:	binclude	"collide/Collision Array (Normal).bin"
		even
CollArray2:	binclude	"collide/Collision Array (Rotated).bin"
		even
Col_GHZ_1:	binclude	"collide/GHZ1.kos"	; GHZ index 1
		even
Col_GHZ_2:	binclude	"collide/GHZ2.kos"	; GHZ index 2
		even
Col_LZ_1:	binclude	"collide/LZ1.kos"	; LZ index 1
		even
Col_LZ_2:	binclude	"collide/LZ2.kos"	; LZ index 2
		even
Col_MZ_1:	binclude	"collide/MZ1.kos"	; MZ index 1
		even
Col_MZ_2:	binclude	"collide/MZ2.kos"	; MZ index 2
		even
Col_SLZ_1:	binclude	"collide/SLZ1.kos"	; SLZ index 1
		even
Col_SLZ_2:	binclude	"collide/SLZ2.kos"	; SLZ index 2
		even
Col_SYZ_1:	binclude	"collide/SYZ1.kos"	; SYZ index 1
		even
Col_SYZ_2:	binclude	"collide/SYZ2.kos"	; SYZ index 2
		even
Col_SBZ_1:	binclude	"collide/SBZ1.kos"	; SBZ index 1
		even
Col_SBZ_2:	binclude	"collide/SBZ2.kos"	; SBZ index 2
		even
; ---------------------------------------------------------------------------
; Special Stage layouts
; ---------------------------------------------------------------------------
	if SuperMod=1
SS_1:		binclude	"sslayout/Super Mod/1.eni"
		even
SS_2:		binclude	"sslayout/Super Mod/2.eni"
		even
SS_3:		binclude	"sslayout/Super Mod/3.eni"
		even
SS_4:		binclude	"sslayout/Super Mod/4.eni"
		even
SS_5:		binclude	"sslayout/Super Mod/5.eni"
		even
SS_6:		binclude	"sslayout/Super Mod/6.eni"
		even
SS_7:		binclude	"sslayout/Super Mod/7.eni"
		even
	
	else

SS_1:		binclude	"sslayout/1.eni"
		even
SS_2:		binclude	"sslayout/2.eni"
		even
SS_3:		binclude	"sslayout/3.eni"
		even
SS_4:		binclude	"sslayout/4.eni"
		even
SS_5:		binclude	"sslayout/5.eni"
		even
SS_6:		binclude	"sslayout/6.eni"
		even
	endif
; ---------------------------------------------------------------------------
; Animated uncompressed graphics
; ---------------------------------------------------------------------------
Art_GhzWater:	binclude	"artunc/GHZ Waterfall.bin"
		even
Art_GhzFlower1:	binclude	"artunc/GHZ Flower Large.bin"
		even
Art_GhzFlower2:	binclude	"artunc/GHZ Flower Small.bin"
		even
Art_MzLava1:	binclude	"artunc/MZ Lava Surface.bin"
		even
Art_MzLava2:	binclude	"artunc/MZ Lava.bin"
		even
Art_MzTorch:	binclude	"artunc/MZ Background Torch.bin"
		even
Art_LzWheel:	binclude	"artunc/LZ Wheel.bin"				; Formerly compressed art as part of the Conveyor object (63).
		even
Art_SbzSmoke:	binclude	"artunc/SBZ Background Smoke.bin"
		even


; ---------------------------------------------------------------------------
; Sprite mappings
; Moved out of the way of code and data
; ---------------------------------------------------------------------------
		include	"_maps/Sonic.asm"

		include	"_maps/Ending Sequence Sonic.asm"
		include	"_maps/Ending Sequence Emeralds.asm"
		include	"_maps/Ending Sequence STH.asm"
		include	"_maps/Try Again & End Eggman.asm"
		include	"_maps/Bridge.asm"
		include	"_maps/Swinging Platforms (GHZ).asm"
		include	"_maps/Swinging Platforms (SLZ).asm"
		include	"_maps/Spiked Pole Helix.asm"
		include	"_maps/Platforms (unused).asm"
		include	"_maps/Platforms (GHZ).asm"
		include	"_maps/Platforms (SYZ).asm"
		include	"_maps/Platforms (SLZ).asm"
		include	"_maps/GHZ Ball.asm"
		include	"_maps/Collapsing Ledge.asm"
		include	"_maps/Collapsing Floors.asm"
		include	"_maps/Scenery.asm"
		include	"_maps/Unused Switch.asm"
		include	"_maps/SBZ Small Door.asm"
		include	"_maps/Ball Hog.asm"
		include	"_maps/Buzz Bomber Missile Dissolve.asm"
		include	"_maps/Explosions.asm"
		include	"_maps/Animals 1.asm"
		include	"_maps/Animals 2.asm"
		include	"_maps/Animals 3.asm"
		include	"_maps/Points.asm"
		include	"_maps/Crabmeat.asm"
		include	"_maps/Buzz Bomber.asm"
		include	"_maps/Buzz Bomber Missile.asm"
		include	"_maps/Rings.asm"		; debug rings, lost rings, and SS rings
		include	"_maps/Giant Ring.asm"	; Now includes the ring flash

; Split these into seperate files so SonLVL can render monitors properly	
	if ShieldsMode
		include	"_maps/Monitor - S3K.asm"
	else
		include	"_maps/Monitor.asm"
	endif

	if SaveProgressMod
		include	"_maps/Press Start and TM (Menu).asm"
	else
		include	"_maps/Press Start and TM.asm"
	endif

		include	"_maps/Title Screen Sonic.asm"
		include	"_maps/Chopper.asm"
		include	"_maps/Jaws.asm"
		include	"_maps/Burrobot.asm"
		include	"_maps/MZ Large Grassy Platforms.asm"
		include	"_maps/Fireballs.asm"
		include	"_maps/MZ Large Green Glass Blocks.asm"
		include	"_maps/Chained Stompers.asm"
		include	"_maps/Sideways Stomper.asm"
		include	"_maps/Button.asm"
		include	"_maps/Pushable Blocks.asm"
		
		include	"_maps/Game Over.asm"
		
	if OptimalTitleCardArt	; RetroKoH Optimal Title Card Art
		include "_maps/Zone Title Cards - Optimal.asm"
		include	"_maps/Continue Screen - Optimal.asm"

		if PerfectBonusEnabled
			if CoolBonusEnabled
				include "_maps/Got Through Card_BOTH - Optimal.asm"
			else
				include "_maps/Got Through Card_PERFECT - Optimal.asm"
			endif
		elseif CoolBonusEnabled
			include "_maps/Got Through Card_COOL - Optimal.asm"
		else
			include "_maps/Got Through Card - Optimal.asm"
		endif
		
		if PerfectBonusEnabled
			include "_maps/SS Results Card_PERFECT - Optimal.asm"
		else
			include "_maps/SS Results Card - Optimal.asm"
		endif

	else

		include "_maps/Zone Title Cards.asm"
		include	"_maps/Continue Screen.asm"

		if PerfectBonusEnabled
			if CoolBonusEnabled
				include "_maps/Got Through Card_BOTH.asm"
			else
				include "_maps/Got Through Card_PERFECT.asm"
			endif
		elseif CoolBonusEnabled
			include "_maps/Got Through Card_COOL.asm"
		else
			include "_maps/Got Through Card.asm"
		endif
		
		if PerfectBonusEnabled
			include "_maps/SS Results Card_PERFECT.asm"
		else
			include "_maps/SS Results Card.asm"
		endif
	endif	; Optimal Title Card Art End

		include	"_maps/SS Result Chaos Emeralds.asm"
		include	"_maps/Spikes.asm"
		include	"_maps/Purple Rock.asm"
		include	"_maps/Smashable Walls.asm"

		include	"_maps/Springs.asm"
		include	"_maps/Newtron.asm"
		include	"_maps/Roller.asm"
		include	"_maps/GHZ Edge Walls.asm"
		include	"_maps/Flamethrower.asm"
		include	"_maps/MZ Bricks.asm"
		include	"_maps/Light.asm"
		include	"_maps/Bumper.asm"

	switch UpdatedSignposts
	case 2
		include	"_maps/Signpost - Hybrid.asm"
	case 1
		include	"_maps/Signpost - CD.asm"
	elsecase
		include	"_maps/Signpost.asm"
	endcase

		include	"_maps/Lava Tag.asm"
		include	"_maps/Lava Geyser.asm"
		include	"_maps/Wall of Lava.asm"
		include "_maps/Splats.asm"
		include	"_maps/Moto Bug.asm"
		include	"_maps/Yadrin.asm"
		include	"_maps/Smashable Green Block.asm"
		include	"_maps/Moving Blocks (MZ and SBZ).asm"
		include	"_maps/Moving Blocks (LZ).asm"
		include	"_maps/Basaran.asm"
		include	"_maps/Floating Blocks and Doors.asm"
		include	"_maps/Spiked Ball and Chain (SYZ).asm"
		include	"_maps/Spiked Ball and Chain (LZ).asm"
		include	"_maps/Big Spiked Ball.asm"
		include	"_maps/SLZ Elevators.asm"
		include	"_maps/SLZ Circling Platform.asm"
		include	"_maps/Staircase.asm"
		include	"_maps/Pylon.asm"
		include	"_maps/Water Surface.asm"
		include	"_maps/Pole that Breaks.asm"
		include	"_maps/Flapping Door.asm"
		include	"_maps/Invisible Barriers.asm"
		include	"_maps/Fan.asm"
		include	"_maps/Seesaw.asm"
		include	"_maps/Seesaw Ball.asm"
		include	"_maps/Bomb Enemy.asm"
		include	"_maps/Orbinaut.asm"
		include	"_maps/Harpoon.asm"
		include	"_maps/LZ Blocks.asm"
		include	"_maps/Gargoyle.asm"
		include	"_maps/LZ Conveyor.asm"
		include	"_maps/Bubbles.asm"
		include	"_maps/Waterfalls.asm"

	if SuperMod
		include	"_maps/Super Stars.asm"
	endif

		include	"_maps/Drowning Countdown.asm"
		include	"_maps/Shield and Invincibility.asm"
		include	"_maps/Special Stage Entry (Unused).asm"
		include "_maps/Collision Switcher.asm"
		include	"_maps/Water Splash.asm"
		include "_maps/Goggles.asm"
		include	"_maps/Rotating Junction.asm"
		include	"_maps/Running Disc.asm"
		include	"_maps/Trapdoor.asm"
		include	"_maps/SBZ Spinning Platforms.asm"
		include	"_maps/Saws and Pizza Cutters.asm"
		include	"_maps/SBZ Stomper and Door.asm"
		include	"_maps/SBZ Vanishing Platforms.asm"
		include	"_maps/Electrocuter.asm"
		include	"_maps/Girder Block.asm"
		include	"_maps/Caterkiller.asm"
		include	"_maps/Lamppost.asm"
		include	"_maps/Hidden Bonuses.asm"
		include	"_maps/Credits.asm"
		include	"_maps/Eggman.asm"
		include	"_maps/Boss Items.asm"
		include	"_maps/SLZ Boss Spikeball.asm"
		include	"_maps/SYZ Boss Blocks.asm"
		include	"_maps/Eggman - Scrap Brain 2.asm"
		include	"_maps/SBZ Eggman's Crumbling Floor.asm"
		include	"_maps/FZ Damaged Eggmobile.asm"
		include	"_maps/FZ Eggmobile Legs.asm"
		include	"_maps/FZ Eggman's Cylinders.asm"
		include	"_maps/Plasma Ball Launcher.asm"
		include	"_maps/Plasma Balls.asm"
		include	"_maps/Prison Capsule.asm"

	if HUDCentiseconds=1	;Mercury HUD Centiseconds

		include	"_maps/HUD (centiseconds).asm"

	if HUDInSpecialStage=1	; Mercury HUD in Special Stage
		include	"_maps/HUD SS (centiseconds).asm"
	endif	; HUD in Special Stage End
	
	else
	
		include	"_maps/HUD.asm"

	if HUDInSpecialStage=1	; Mercury HUD in Special Stage
		include	"_maps/HUD SS.asm"
	endif	; HUD in Special Stage End
	
	endif	; HUD Centiseconds End
	
		include	"_maps/SS R Block.asm"
		include	"_maps/SS Glass Block.asm"
		include	"_maps/SS UP Block.asm"
		include	"_maps/SS DOWN Block.asm"
		include	"_maps/SS Chaos Emeralds.asm"
		include "_maps/SS Cursor.asm"				; Also used for the Delete Block

; ---------------------------------------------------------------------------
; Level	layout index -- MJ: unused data and BG data have been stripped out
; Offsets are now long-length to allow for more efficient loading - RetroKoH
; If you add a TON of entries and NEED word-length offsets, use the alternate
; loading method commented out in LevelLayoutLoad (Credit: Vladikcomper)
; ---------------------------------------------------------------------------
Level_Index:
		; GHZ
		dc.l Level_GHZ1
		dc.l Level_GHZ2
		dc.l Level_GHZ3
		dc.l Level_Null
		; LZ
		dc.l Level_LZ1
		dc.l Level_LZ2
		dc.l Level_LZ3
		dc.l Level_SBZ3
		; MZ
		dc.l Level_MZ1
		dc.l Level_MZ2
		dc.l Level_MZ3
		dc.l Level_Null
		; SLZ
		dc.l Level_SLZ1
		dc.l Level_SLZ2
		dc.l Level_SLZ3
		dc.l Level_Null
		; SYZ
		dc.l Level_SYZ1
		dc.l Level_SYZ2
		dc.l Level_SYZ3
		dc.l Level_Null
		; SBZ
		dc.l Level_SBZ1
		dc.l Level_SBZ2
		dc.l Level_SBZ2
		dc.l Level_Null
		zonewarning Level_Index,16
		; Ending
		dc.l Level_End
		dc.l Level_End
		dc.l Level_Null
		dc.l Level_Null

Level_Null:

Level_GHZ1:	binclude	"levels/ghz1.kos"
		even
Level_GHZ2:	binclude	"levels/ghz2.kos"
		even
Level_GHZ3:	binclude	"levels/ghz3.kos"
		even

Level_LZ1:	binclude	"levels/lz1.kos"
		even
Level_LZ2:	binclude	"levels/lz2.kos"
		even
Level_LZ3:	binclude	"levels/lz3.kos"
		even
Level_SBZ3:	binclude	"levels/sbz3.kos"
		even

Level_MZ1:	binclude	"levels/mz1.kos"
		even
Level_MZ2:	binclude	"levels/mz2.kos"
		even
Level_MZ3:	binclude	"levels/mz3.kos"
		even

Level_SLZ1:	binclude	"levels/slz1.kos"
		even
Level_SLZ2:	binclude	"levels/slz2.kos"
		even
Level_SLZ3:	binclude	"levels/slz3.kos"
		even

Level_SYZ1:	binclude	"levels/syz1.kos"
		even
Level_SYZ2:	binclude	"levels/syz2.kos"
		even
Level_SYZ3:	binclude	"levels/syz3.kos"
		even

Level_SBZ1:	binclude	"levels/sbz1.kos"
		even
Level_SBZ2:	binclude	"levels/sbz2.kos"
		even

Level_End:	binclude	"levels/ending.kos"
		even

		align	$100

; ---------------------------------------------------------------------------
; Sprite locations index
; Offsets are now long-length to allow for more efficient loading - RetroKoH
; If you add a TON of entries and NEED word-length offsets, use the alternate
; loading method commented out in Object Manager.asm (Credit: Vladikcomper)
; ---------------------------------------------------------------------------
ObjPos_Index:
		; GHZ
		dc.l ObjPos_GHZ1
		dc.l ObjPos_GHZ2
		dc.l ObjPos_GHZ3
		dc.l ObjPos_Null
		; LZ
		dc.l ObjPos_LZ1
		dc.l ObjPos_LZ2
		dc.l ObjPos_LZ3
		dc.l ObjPos_SBZ3
		; MZ
		dc.l ObjPos_MZ1
		dc.l ObjPos_MZ2
		dc.l ObjPos_MZ3
		dc.l ObjPos_Null
		; SLZ
		dc.l ObjPos_SLZ1
		dc.l ObjPos_SLZ2
		dc.l ObjPos_SLZ3
		dc.l ObjPos_Null
		; SYZ
		dc.l ObjPos_SYZ1
		dc.l ObjPos_SYZ2
		dc.l ObjPos_SYZ3
		dc.l ObjPos_Null
		; SBZ
		dc.l ObjPos_SBZ1
		dc.l ObjPos_SBZ2
		dc.l ObjPos_FZ
		dc.l ObjPos_Null
		zonewarning ObjPos_Index,$10
		; Ending
		dc.l ObjPos_End
		dc.l ObjPos_End
		dc.l ObjPos_End
		dc.l ObjPos_End
		; --- Put extra object data here. ---
ObjPosLZPlatform_Index:
		dc.l ObjPos_LZ1pf1, ObjPos_LZ1pf2
		dc.l ObjPos_LZ2pf1, ObjPos_LZ2pf2
		dc.l ObjPos_LZ3pf1, ObjPos_LZ3pf2
		dc.l ObjPos_LZ1pf1, ObjPos_LZ1pf2
ObjPosSBZPlatform_Index:
		dc.l ObjPos_SBZ1pf1, ObjPos_SBZ1pf2
		dc.l ObjPos_SBZ1pf3, ObjPos_SBZ1pf4
		dc.l ObjPos_SBZ1pf5, ObjPos_SBZ1pf6
		dc.l ObjPos_SBZ1pf1, ObjPos_SBZ1pf2

		dc.b $FF, $FF, 0, 0, 0,	0

	if ShieldsMode
ObjPos_GHZ1:	binclude	"objpos/S3K Monitors/ghz1.bin"
		even
ObjPos_GHZ2:	binclude	"objpos/S3K Monitors/ghz2.bin"
		even
ObjPos_GHZ3:	binclude	"objpos/S3K Monitors/ghz3.bin"
		even
ObjPos_LZ1:		binclude	"objpos/S3K Monitors/lz1.bin"
		even
ObjPos_LZ2:		binclude	"objpos/S3K Monitors/lz2.bin"
		even
ObjPos_LZ3:		binclude	"objpos/S3K Monitors/lz3.bin"
		even
ObjPos_MZ1:		binclude	"objpos/S3K Monitors/mz1.bin"
		even
ObjPos_MZ2:		binclude	"objpos/S3K Monitors/mz2.bin"
		even
ObjPos_MZ3:		binclude	"objpos/S3K Monitors/mz3.bin"
		even
ObjPos_SLZ1:	binclude	"objpos/S3K Monitors/slz1.bin"
		even
ObjPos_SLZ2:	binclude	"objpos/S3K Monitors/slz2.bin"
		even
ObjPos_SLZ3:	binclude	"objpos/S3K Monitors/slz3.bin"
		even
ObjPos_SYZ1:	binclude	"objpos/S3K Monitors/syz1.bin"
		even
ObjPos_SYZ2:	binclude	"objpos/S3K Monitors/syz2.bin"
		even
ObjPos_SYZ3:	binclude	"objpos/S3K Monitors/syz3.bin"
		even
ObjPos_SBZ1:	binclude	"objpos/S3K Monitors/sbz1.bin"
		even
ObjPos_SBZ2:	binclude	"objpos/S3K Monitors/sbz2.bin"
		even

	else
ObjPos_GHZ1:	binclude	"objpos/ghz1.bin"
		even
ObjPos_GHZ2:	binclude	"objpos/ghz2.bin"
		even
ObjPos_GHZ3:	binclude	"objpos/ghz3.bin"
		even
ObjPos_LZ1:		binclude	"objpos/lz1.bin"
		even
ObjPos_LZ2:		binclude	"objpos/lz2.bin"
		even
ObjPos_LZ3:		binclude	"objpos/lz3.bin"
		even
ObjPos_MZ1:		binclude	"objpos/mz1.bin"
		even
ObjPos_MZ2:		binclude	"objpos/mz2.bin"
		even
ObjPos_MZ3:		binclude	"objpos/mz3.bin"
		even
ObjPos_SLZ1:	binclude	"objpos/slz1.bin"
		even
ObjPos_SLZ2:	binclude	"objpos/slz2.bin"
		even
ObjPos_SLZ3:	binclude	"objpos/slz3.bin"
		even
ObjPos_SYZ1:	binclude	"objpos/syz1.bin"
		even
ObjPos_SYZ2:	binclude	"objpos/syz2.bin"
		even
ObjPos_SYZ3:	binclude	"objpos/syz3.bin"
		even
ObjPos_SBZ1:	binclude	"objpos/sbz1.bin"
		even
ObjPos_SBZ2:	binclude	"objpos/sbz2.bin"
		even
	endif

ObjPos_SBZ3:	binclude	"objpos/sbz3.bin"
		even
ObjPos_FZ:		binclude	"objpos/fz.bin"
		even
ObjPos_LZ1pf1:	binclude	"objpos/lz1pf1.bin"
		even
ObjPos_LZ1pf2:	binclude	"objpos/lz1pf2.bin"
		even
ObjPos_LZ2pf1:	binclude	"objpos/lz2pf1.bin"
		even
ObjPos_LZ2pf2:	binclude	"objpos/lz2pf2.bin"
		even
ObjPos_LZ3pf1:	binclude	"objpos/lz3pf1.bin"
		even
ObjPos_LZ3pf2:	binclude	"objpos/lz3pf2.bin"
		even
ObjPos_SBZ1pf1:	binclude	"objpos/sbz1pf1.bin"
		even
ObjPos_SBZ1pf2:	binclude	"objpos/sbz1pf2.bin"
		even
ObjPos_SBZ1pf3:	binclude	"objpos/sbz1pf3.bin"
		even
ObjPos_SBZ1pf4:	binclude	"objpos/sbz1pf4.bin"
		even
ObjPos_SBZ1pf5:	binclude	"objpos/sbz1pf5.bin"
		even
ObjPos_SBZ1pf6:	binclude	"objpos/sbz1pf6.bin"
		even
ObjPos_End:		binclude	"objpos/ending.bin"
		even
ObjPos_Null:	dc.b $FF, $FF, 0, 0, 0, 0

		rept $63C
		dc.b $FF
		endm

; --------------------------------------------------------------------------------------
; Offset index of ring locations - RetroKoH S3K Rings Manager
; Offsets are now long-length to allow for more efficient loading - RetroKoH
; If you add a TON of entries and NEED word-length offsets, use the alternate
; loading method commented out in RingsManager.asm (Credit: Vladikcomper)
; --------------------------------------------------------------------------------------
RingPos_Index:
		; GHZ
		dc.l RingPos_GHZ1
		dc.l RingPos_GHZ2
		dc.l RingPos_GHZ3
		dc.l RingPos_Null
		; LZ
		dc.l RingPos_LZ1
		dc.l RingPos_LZ2
		dc.l RingPos_LZ3
		dc.l RingPos_SBZ3
		; MZ
		dc.l RingPos_MZ1
		dc.l RingPos_MZ2
		dc.l RingPos_MZ3
		dc.l RingPos_Null
		; SLZ
		dc.l RingPos_SLZ1
		dc.l RingPos_SLZ2
		dc.l RingPos_SLZ3
		dc.l RingPos_Null
		; SYZ
		dc.l RingPos_SYZ1
		dc.l RingPos_SYZ2
		dc.l RingPos_SYZ3
		dc.l RingPos_Null
		; SBZ
		dc.l RingPos_SBZ1
		dc.l RingPos_SBZ2
		dc.l RingPos_Null
		dc.l RingPos_Null
		; Ending
		dc.l RingPos_Null
		dc.l RingPos_Null
		dc.l RingPos_Null
		dc.l RingPos_Null

		; --- Put extra ring data here. ---
		dc.b $FF, $FF, 0, 0, 0,	0

RingPos_GHZ1:	binclude	"ringpos/ghz1.bin"
		even
RingPos_GHZ2:	binclude	"ringpos/ghz2.bin"
		even
RingPos_GHZ3:	binclude	"ringpos/ghz3.bin"
		even
RingPos_LZ1:	binclude	"ringpos/lz1.bin"
		even
RingPos_LZ2:	binclude	"ringpos/lz2.bin"
		even
RingPos_LZ3:	binclude	"ringpos/lz3.bin"
		even
RingPos_SBZ3:	binclude	"ringpos/sbz3.bin"
		even
RingPos_MZ1:	binclude	"ringpos/mz1.bin"
		even
RingPos_MZ2:	binclude	"ringpos/mz2.bin"
		even
RingPos_MZ3:	binclude	"ringpos/mz3.bin"
		even
RingPos_SLZ1:	binclude	"ringpos/slz1.bin"
		even
RingPos_SLZ2:	binclude	"ringpos/slz2.bin"
		even
RingPos_SLZ3:	binclude	"ringpos/slz3.bin"
		even
RingPos_SYZ1:	binclude	"ringpos/syz1.bin"
		even
RingPos_SYZ2:	binclude	"ringpos/syz2.bin"
		even
RingPos_SYZ3:	binclude	"ringpos/syz3.bin"
		even
RingPos_SBZ1:	binclude	"ringpos/sbz1.bin"
		even
RingPos_SBZ2:	binclude	"ringpos/sbz2.bin"
		even
RingPos_Null:	dc.b $FF, $FF, 0, 0, 0, 0

		rept $63C
		dc.b $FF
		endm

SoundDriver:	include "s1.sounddriver.asm"

; end of 'ROM'
		even

; ==============================================================
; --------------------------------------------------------------
; Debugging modules
; --------------------------------------------------------------

   include   "ErrorHandler.asm"

; --------------------------------------------------------------
; WARNING!
;	DO NOT put any data from now on! DO NOT use ROM padding!
;	Symbol data should be appended here after ROM is compiled
;	by ConvSym utility, otherwise debugger modules won't be able
;	to resolve symbol names.
; --------------------------------------------------------------
EndOfRom:

		END
