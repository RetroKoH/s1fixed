; ---------------------------------------------------------------------------
; Sprite mappings - rings
; RetroKoH 8-Frame Rings Change
; DeltaW/Malachi Optimized Spinning Rings
; ---------------------------------------------------------------------------
Map_Ring:	mappingsTable
	mappingsTableEntry.w	.ring
	mappingsTableEntry.w	.sparkle1
	mappingsTableEntry.w	.sparkle2
	mappingsTableEntry.w	.sparkle3
	mappingsTableEntry.w	.sparkle4
	mappingsTableEntry.w	.blank

.ring:	spriteHeader
	spritePiece	-8, -8, 2, 2, 0, 0, 0, 0, 0
.ring_End

.sparkle1:	spriteHeader
	spritePiece	-8, -8, 2, 2, 0, 0, 0, 0, 0
.sparkle1_End

.sparkle2:	spriteHeader
	spritePiece	-8, -8, 2, 2, 0, 1, 1, 0, 0
.sparkle2_End

.sparkle3:	spriteHeader
	spritePiece	-8, -8, 2, 2, 0, 1, 0, 0, 0
.sparkle3_End

.sparkle4:	spriteHeader
	spritePiece	-8, -8, 2, 2, 0, 0, 1, 0, 0
.sparkle4_End

.blank:	spriteHeader
.blank_End

	even
