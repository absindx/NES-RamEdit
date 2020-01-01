;--------------------------------------------------
; Ram edit
;--------------------------------------------------

;--------------------------------------------------
; Setting
;--------------------------------------------------

PrgCount	= 1

	.inesprg PrgCount	; PRG Bank
	.ineschr 1		; CHR Bank
	.inesmir 0		; Mirror
	.inesmap 4		; Mapper

;--------------------------------------------------
; Include
;--------------------------------------------------
	.include	"Include/IOName_Standard.asm"
	.include	"Include/IOName_MMC3.asm"
	.include	"Include/Library_Macro.asm"
	.include	"RamMap.asm"

;--------------------------------------------------
; Define
;--------------------------------------------------
Palette_Black		= $0F
Palette_White		= $30

ScreenMode_MemoryEdit	= 0
ScreenMode_EditMenu	= 1

MemoryEdit_RowCount	= $08
MemoryEdit_ColCount	= $08
MemoryEdit_PageElement	= MemoryEdit_RowCount*MemoryEdit_ColCount
MemoryEdit_MaxPage	= ($800/MemoryEdit_PageElement)-1
MenuCursor_Max		= 6

;--------------------------------------------------
; Interrupt
;--------------------------------------------------
	.bank PrgCount*2-1
	.org $FFF9

NMI:
IRQ:		RTI

	;.org $FFFA
	.dw NMI
	.dw RST
	.dw IRQ

	.org $E000

;--------------------------------------------------
; Signature
;--------------------------------------------------

	;	 0123456789ABCDEF
	.db	"Ram edit ver1.00"

;--------------------------------------------------
; Software subroutine
;--------------------------------------------------

SoftwareSubroutine	= 1

MyJSR		.macro
	.if SoftwareSubroutine=0
		JSR	\1
	.else
		LDX	MyStackPointer
		LDA	#HIGH(.Origin\@)
		STA	MyStack,X
		DEX
		LDA	#LOW(.Origin\@)
		STA	MyStack,X
		DEX
		STX	MyStackPointer
		JMP	\1
.Origin\@
	.endif
	.endm

MyRTS		.macro
	.if SoftwareSubroutine=0
		RTS
	.else
		JMP	MyRTS_Main
	.endif
	.endm

MyRTS_Main:
		LDX	MyStackPointer
		INX
		LDA	MyStack,X
		STA	JumpAddress_Low
		INX
		LDA	MyStack,X
		STA	JumpAddress_High
		STX	MyStackPointer
		JMP	[JumpAddress]



;--------------------------------------------------
; Main
;--------------------------------------------------

RST:
		SEI
		CLD

		WaitVBlank

		LDA	#$00
		STA	IO_PPU_Setting
		STA	IO_PPU_Display

		STA	IO_PPU_SpriteAddress
		TAX
.ClearOam	STA	IO_PPU_SpriteAccess
		DEX
		BNE	.ClearOam

		LDA	#%10000000			;\
		STA	IO_MMC3_RAMProtect		;/  Enable SRAM

		WaitVBlank

		; X = #$00
		PPU_SetDestinationAddress	$3F00
.PaletteClear	LDA	.Palette,x
		STA	IO_PPU_VRAMAccess
		INX
		CPX	#$20
		BCC	.PaletteClear

		LDA	#$00
		TAX
.MemoryClear	STA	$6000,x
		STA	$6100,x
		;STA	$6200,x
		DEX
		BNE	.MemoryClear
		DEX
		STX	MyStackPointer
		MyJSR	Initialize

		WaitVBlank
		LDA	#%00001000			; NMI disable, SP CHR = $1000
		STA	IO_PPU_Setting
		LDA	#$40				;\
		STA	IO_Controller_Port2		;/  APU IRQ Disable
		CLI

.InfLoop	WaitVBlank
		MyJSR	GameMain
		JMP	.InfLoop

.Palette	.db	Palette_Black,	Palette_White,	$15,		$35		; BG #0
		.db	Palette_Black,	Palette_White,	$27,		Palette_Black	; BG #1
		.db	Palette_Black,	Palette_Black,	Palette_Black,	Palette_Black	; BG #2
		.db	Palette_Black,	Palette_Black,	Palette_Black,	Palette_Black	; BG #3
		.db	Palette_Black,	Palette_Black,	Palette_Black,	Palette_Black	; SP #0
		.db	Palette_Black,	Palette_Black,	Palette_Black,	Palette_Black	; SP #1
		.db	Palette_Black,	Palette_Black,	Palette_Black,	Palette_Black	; SP #2
		.db	Palette_Black,	Palette_Black,	Palette_Black,	Palette_Black	; SP #3



;--------------------------------------------------
; Initialize routine
;--------------------------------------------------

Initialize:
		; Initialize mapper
		LDX	#$00				;\
		LDY	#$00				; | Set Bank
		STX	IO_MMC3_BankSelect		; |   PPU[$0000](#0) = $00
		STY	IO_MMC3_BankData		;/
		INX					;\
		INY					; | Set Bank
		INY					; |   PPU[$0800](#1) = $02
		STX	IO_MMC3_BankSelect		; |
		STY	IO_MMC3_BankData		;/
		INX					;\
		INY					; | Set Bank
		INY					; |   PPU[$1000](#2) = $04(Sprite)
		STX	IO_MMC3_BankSelect		; |
		STY	IO_MMC3_BankData		;/
		INX					;\
		INY					; | Set Bank
		STX	IO_MMC3_BankSelect		; |   PPU[$1400](#3) = $05(Sprite)
		STY	IO_MMC3_BankData		;/
		INX					;\
		INY					; | Set Bank
		STX	IO_MMC3_BankSelect		; |   PPU[$1800](#4) = $06(Sprite)
		STY	IO_MMC3_BankData		;/
		INX					;\
		INY					; | Set Bank
		STX	IO_MMC3_BankSelect		; |   PPU[$1C00](#5) = $07(Sprite)
		STY	IO_MMC3_BankData		;/
		INX					;\
		LDY	#$00				; | Set Bank
		STX	IO_MMC3_BankSelect		; |   PRG[$8000](#6) = $00
		STY	IO_MMC3_BankData		;/
		INX					;\
		INY					; | Set Bank
		STX	IO_MMC3_BankSelect		; |   PRG[$A000](#7) = $01
		STY	IO_MMC3_BankData		;/
		STY	IO_MMC3_Mirroring		;\  Mirroring = Horizontal
		STY	IO_MMC3_IRQDisable		;/  IRQ Disable

		; Clear VRAM
		LDA	#$00
		TAX
		PPU_SetDestinationAddress	$2000
.Clear_2000	STA	IO_PPU_VRAMAccess		;\
		STA	IO_PPU_VRAMAccess		; |
		STA	IO_PPU_VRAMAccess		; | 256 * 4 = 0x400
		STA	IO_PPU_VRAMAccess		; | -> 0x2000 - 0x23FF
		DEX					; |
		BNE	.Clear_2000			;/
		PPU_SetDestinationAddress	$2800
.Clear_2800	STA	IO_PPU_VRAMAccess		;\
		STA	IO_PPU_VRAMAccess		; |
		STA	IO_PPU_VRAMAccess		; | 256 * 4 = 0x400
		STA	IO_PPU_VRAMAccess		; | -> 0x2800 - 0x2BFF
		DEX					; |
		BNE	.Clear_2800			;/

		MyJSR	InitializeDynamicRoutine

		MyJSR	DrawTitle
		MyJSR	DrawHexFrame
		;MyJSR	DrawHorizontalLine
		MyJSR	Screen_Goto_MemoryEdit		; Draw $0000-$007F

		LDA	#$02
		STA	MemoryCursor_Nibble		; Cursor = (0, 0, High)

		LDA	#$00
		STA	IO_PPU_Scroll
		STA	IO_PPU_Scroll

		MyRTS

;--------------------------------------------------

ReadMainMemory_Main		= DynamicCode+0
WriteMainMemory_Main		= DynamicCode+8

ReadMainMemoryAddress		= ReadMainMemory_Main + 1
ReadMainMemoryAddress_Low	= ReadMainMemoryAddress+0
ReadMainMemoryAddress_High	= ReadMainMemoryAddress+1
WriteMainMemoryAddress		= WriteMainMemory_Main + 1
WriteMainMemoryAddress_Low	= WriteMainMemoryAddress+0
WriteMainMemoryAddress_High	= WriteMainMemoryAddress+1

InitializeDynamicRoutine:
		LDX	#ReadMainMemoryLength-1
.LoopRead	LDA	.ReadMainMemory,x
		STA	ReadMainMemory_Main,x
		DEX
		BPL	.LoopRead

		LDX	#WriteMainMemoryLength-1
.LoopWrite	LDA	.WriteMainMemory,x
		STA	WriteMainMemory_Main,x
		DEX
		BPL	.LoopWrite

		MyRTS

.ReadMainMemory
		LDY	$0000	; Overwrite address
		JMP	ReadMainMemoryReturn
.ReadMainMemoryEnd
ReadMainMemoryLength		= .ReadMainMemoryEnd - .ReadMainMemory
.WriteMainMemory
		STY	$0000	; Overwrite address
		JMP	WriteMainMemoryReturn
.WriteMainMemoryEnd
WriteMainMemoryLength		= .WriteMainMemoryEnd - .WriteMainMemory

ReadMainMemory:
		JMP	ReadMainMemory_Main
ReadMainMemoryReturn:
		MyRTS

WriteMainMemory:
		JMP	WriteMainMemory_Main
WriteMainMemoryReturn:
		MyRTS



;--------------------------------------------------
; Main routine
;--------------------------------------------------

GameMain:
		LDA	#%00001000
		STA	IO_PPU_Setting
		LDA	#%00000110
		STA	IO_PPU_Display

		; FrameCounter
		INC16BIT	FrameCounter

		MyJSR	Controller_Update

		LDA	ScreenMode
		BNE	.Screen1
		MyJSR	Mode_MemoryEdit
		JMP	.Finished
.Screen1	MyJSR	Mode_EditMenu

.Finished
		LDA	#$00
		STA	IO_PPU_Scroll
		STA	IO_PPU_Scroll
		LDA	#%00011110			;\  Enable BG, SP, Display left BG, SP
		STA	IO_PPU_Display			;/
		LDA	#%00001000			;\  NMI disable, SP CHR = $1000
		STA	IO_PPU_Setting			;/

		MyRTS

;--------------------------------------------------

Screen_Goto_MemoryEdit:
		LDA	#ScreenMode_MemoryEdit
		STA	ScreenMode

		MyJSR	DrawFooter
		MyJSR	UpdateCopying
		MyJSR	DrawMemoryDump
		WaitVBlank
		MyRTS

Screen_Goto_EditMenu:
		LDA	#ScreenMode_EditMenu
		STA	ScreenMode

		MyJSR	DrawMenu
		WaitVBlank
		MyRTS

;--------------------------------------------------

Mode_MemoryEdit:
		MyJSR	DrawNormalHex
		MyJSR	UpdateCursor
		JMP	DrawHighlightHex

UpdateCursor:
		LDX	Controller_Player_Press
		LDY	Controller_Player_Input

.CheckStart	TXA					; ABsS^v<>	(press)
		AND	#Controller_Key_Start		; ABsS^v<>
		BEQ	.CheckA				; ABsS^v<>
		JMP	MemoryEdit_OpenMenu		; ABsS^v<>	6 : Start
.CheckA		TYA					; ABs ^v<>	(input)
		AND	#Controller_Key_A		; ABs ^v<>
		BNE	.InputA				; ABs ^v<>
.CheckB		TYA					;  Bs ^v<>	(input)
		AND	#Controller_Key_B		;  Bs ^v<>
		BEQ	.CheckSelect			;  Bs ^v<>
		MyJSR	MemoryEdit_Paste		;  Bs ^v<>	5 : B
.CheckSelect	LDA	Controller_Player_Input		;   s ^v<>	(input)
		AND	#Controller_Key_Select		;   s ^v<>
		BEQ	.CheckDPad			;   s ^v<>
		JMP	MemoryEdit_ChangePage		;   s ^v<>	3 : Select + D-Pad
.CheckDPad	JMP	MemoryEdit_MoveCursor		;     ^v<>	1 : D-Pad
.InputA		TYA					; ABs ^v<>	(input)
		AND	#Controller_Key_Select		; ABs ^v<>
		BNE	.Press_Select_A			; ABs ^v<>
		JMP	MemoryEdit_ChangeMemory		; AB  ^v<>	2 : A + D-Pad
.Press_Select_A	JMP	MemoryEdit_Copy			; ABs ^v<>	4 : A + Select


MemoryEdit_MoveCursor:		; 1
.CheckUp	LDA	Controller_Player_Press
		AND	#Controller_Key_Up
		BEQ	.CheckDown
		LDX	MemoryCursor_Row
		DEX
		TXA
		AND	#MemoryEdit_RowCount-1
		STA	MemoryCursor_Row

.CheckDown	LDA	Controller_Player_Press
		AND	#Controller_Key_Down
		BEQ	.CheckLeft
		LDX	MemoryCursor_Row
		INX
		TXA
		AND	#MemoryEdit_RowCount-1
		STA	MemoryCursor_Row

.CheckLeft	LDA	Controller_Player_Press
		AND	#Controller_Key_Left
		BEQ	.CheckRight
		LDA	MemoryCursor_Nibble
		AND	#$02
		BNE	.MoveLeft_HighNibble
.MoveLeft_LowNibble
		LDA	#$02
		STA	MemoryCursor_Nibble
		BNE	.CheckRight			;   BRA
.MoveLeft_HighNibble
		LDX	MemoryCursor_Col
		DEX
		TXA
		AND	#MemoryEdit_ColCount-1
		STA	MemoryCursor_Col
		LDA	#$01
		STA	MemoryCursor_Nibble

.CheckRight	LDA	Controller_Player_Press
		AND	#Controller_Key_Right
		BEQ	.Return
		LDA	MemoryCursor_Nibble
		AND	#$01
		BNE	.MoveRight_LowNibble
.MoveRight_HighNibble
		LDA	#$01
		STA	MemoryCursor_Nibble
		BNE	.Return				;   BRA
.MoveRight_LowNibble
		LDX	MemoryCursor_Col
		INX
		TXA
		AND	#MemoryEdit_ColCount-1
		STA	MemoryCursor_Col
		LDA	#$02
		STA	MemoryCursor_Nibble

.Return
		MyRTS


MemoryEdit_Delta_Low	= ScratchMemory+0
MemoryEdit_Delta_High	= ScratchMemory+1
MemoryEdit_ChangeMemory:	; 2
		MyJSR	UpdateMemoryEditAddressOfCursor
		MyJSR	ReadMainMemory

		LDX	#$00
		STX	MemoryEdit_Delta_Low
		STX	MemoryEdit_Delta_High

.CheckUp	LDA	Controller_Player_Press
		AND	#Controller_Key_Up
		BEQ	.CheckDown
		LDA	#$F0
		STA	MemoryEdit_Delta_High
		DEC	MemoryEdit_Delta_Low

.CheckDown	LDA	Controller_Player_Press
		AND	#Controller_Key_Down
		BEQ	.CheckNibble
		LDA	MemoryEdit_Delta_High
		CLC
		ADC	#$10
		STA	MemoryEdit_Delta_High
		INC	MemoryEdit_Delta_Low

.CheckNibble	LDA	MemoryCursor_Nibble
		AND	#$02
		BEQ	.LowNibble

.HighNibble	TYA
		CLC
		ADC	MemoryEdit_Delta_High
		TAY
		JMP	WriteMainMemory
		;MyRTS

.LowNibble
		TYA
		AND	#$F0
		STA	MemoryEdit_Delta_High		; temp
		TYA
		CLC
		ADC	MemoryEdit_Delta_Low
		AND	#$0F
		ORA	MemoryEdit_Delta_High
		TAY
		JMP	WriteMainMemory


MemoryEdit_ChangePage:		; 3
.CheckReturn	LDA	Controller_Player_Press
		AND	#(Controller_Key_Left | Controller_Key_Right)
		BNE	.CheckLeft
		MyRTS

.CheckLeft	LDA	Controller_Player_Press
		AND	#Controller_Key_Left
		BEQ	.CheckRight
		LDX	MemoryCursor_Page
		DEX
		TXA
		AND	#MemoryEdit_MaxPage
		STA	MemoryCursor_Page

.CheckRight	LDA	Controller_Player_Press
		AND	#Controller_Key_Right
		BEQ	.UpdateDumpStart
		LDX	MemoryCursor_Page
		INX
		TXA
		AND	#MemoryEdit_MaxPage
		STA	MemoryCursor_Page

.UpdateDumpStart
		LDA	MemoryCursor_Page		; MemoryDumpStart = page * #$40	-------- ---xxxxx -> -----xxx xx------
		LSR	A
		LSR	A
		STA	MemoryDumpStart_High
		LDA	MemoryCursor_Page
		ROR	A
		ROR	A
		ROR	A
		AND	#$C0
		STA	MemoryDumpStart_Low

		MyJSR	DrawMemoryDump
		WaitVBlank
		MyRTS


MemoryEdit_Copy:		; 4
		MyJSR	UpdateMemoryEditAddressOfCursor
		MyJSR	ReadMainMemory

		LDA	MemoryCursor_Nibble
		AND	#$02
		BEQ	.LowNibble

.HighNibble	TYA
		LSR	A
		LSR	A
		LSR	A
		LSR	A
		JMP	.Write

.LowNibble	TYA
		AND	#$0F

.Write		STA	MemoryEdit_Copying
		JMP	UpdateCopying
		;MyRTS


MemoryEdit_Paste:		; 5
		MyJSR	UpdateMemoryEditAddressOfCursor
		MyJSR	ReadMainMemory

		LDA	MemoryCursor_Nibble
		AND	#$02
		BEQ	.LowNibble

.HighNibble	LDA	MemoryEdit_Copying
		ASL	A
		ASL	A
		ASL	A
		ASL	A
		STA	ScratchMemory+0
		TYA
		AND	#$0F
		ORA	ScratchMemory+0
		TAY
		JMP	WriteMainMemory
		;MyRTS

.LowNibble	TYA
		AND	#$F0
		ORA	MemoryEdit_Copying
		TAY
		JMP	WriteMainMemory
		;MyRTS


MemoryEdit_OpenMenu:		; 6
		JMP	Screen_Goto_EditMenu
		;MyRTS

;--------------------------------------------------

EditMenu_CursorDrawCancel	= ScratchMemory+0
Mode_EditMenu:
		LDA	#$00
		STA	EditMenu_CursorDrawCancel

		MyJSR	ClearMenuCursor
		MyJSR	EditMenu_Controller
		LDA	EditMenu_CursorDrawCancel
		BNE	.Return
		MyJSR	DrawMenuCursor
.Return		MyRTS

EditMenu_Controller:
		LDX	Controller_Player_Press
		;LDY	Controller_Player_Input

.CheckStart	TXA
		AND	#(Controller_Key_Start|Controller_Key_B)
		BEQ	.CheckA				; ABsS^v<>
		JMP	EditMenu_CloseMenu		;  B S    	4 : Start or B
.CheckA		TXA					; A s ^v<>
		AND	#Controller_Key_A		; A s ^v<>
		BEQ	.CheckUp
		JMP	EditMenu_Confirm		; A       	3 : A
.CheckUp	TXA					;   s ^v<>
		AND	#Controller_Key_Up		;   s ^v<>
		BEQ	.CheckDown			;   s ^v<>
		MyJSR	EditMenu_CursorUp		;     ^   	1 : Up
.CheckDown	LDA	Controller_Player_Press		;   s ^v<>
		AND	#Controller_Key_Down		;   s ^v<>
		BEQ	.Return				;   s ^v<>
		JMP	EditMenu_CursorDown		;      v  	2 : Down
.Return		MyRTS					;   s ^ <>

EditMenu_CursorUp:		; 1
		LDA	MenuCursor
		BEQ	.SetLast
		DEC	MenuCursor
		MyRTS
.SetLast	LDA	#MenuCursor_Max-1
		STA	MenuCursor
		MyRTS

EditMenu_CursorDown:		; 2
		LDA	MenuCursor
		CMP	#MenuCursor_Max-1
		BEQ	.SetFirst
		INC	MenuCursor
		MyRTS
.SetFirst	LDA	#$00
		STA	MenuCursor
		MyRTS

EditMenu_Confirm:		; 3
		LDA	MenuCursor
		ASL	A
		TAX
		LDA	.MenuFunctions,x
		STA	JumpAddress_Low
		LDA	.MenuFunctions+1,x
		STA	JumpAddress_High
		JMP	[JumpAddress]
		;MyRTS

.MenuFunctions
		.dw	EditMenuFunc_FillAll
		.dw	EditMenuFunc_FillPage
		.dw	EditMenuFunc_UserDefine1
		.dw	EditMenuFunc_UserDefine2
		.dw	EditMenuFunc_UserDefine3
		.dw	EditMenuFunc_UserDefine4

EditMenu_CloseMenu:		; 4
		INC	EditMenu_CursorDrawCancel
		JMP	Screen_Goto_MemoryEdit

;--------------------------------------------------

EditMenuFunc_FillPage_Count	= ScratchMemory+0
EditMenuFunc_FillAll:
		MyJSR	UpdateMemoryEditAddressOfCursor
		MyJSR	ReadMainMemory

		LDX	#$00
		TYA
.Loop		STA	<$00,x
		PHA
		STA	$0200,x
		STA	$0300,x
		STA	$0400,x
		STA	$0500,x
		STA	$0600,x
		STA	$0700,x
		INX
		BNE	.Loop
		JMP	Screen_Goto_MemoryEdit

EditMenuFunc_FillPage:
		MyJSR	UpdateMemoryEditAddressOfCursor
		MyJSR	ReadMainMemory

		; Start address
		LDA	MemoryDumpStart_Low
		STA	WriteMainMemoryAddress_Low
		LDA	MemoryDumpStart_High
		STA	WriteMainMemoryAddress_High

		LDA	#MemoryEdit_PageElement
		STA	EditMenuFunc_FillPage_Count

		TYA
.Loop		MyJSR	WriteMainMemory
		INC	WriteMainMemoryAddress_Low
		DEC	EditMenuFunc_FillPage_Count
		BNE	.Loop
		JMP	Screen_Goto_MemoryEdit

EditMenuFunc_UserDefine	.macro
		LDX	#$00
.Loop\@		LDA	(\1+$0000),x
		STA	<$00,x
		LDA	(\1+$0100),x
		STA	$0100,x
		LDA	(\1+$0200),x
		STA	$0200,x
		LDA	(\1+$0300),x
		STA	$0300,x
		LDA	(\1+$0400),x
		STA	$0400,x
		LDA	(\1+$0500),x
		STA	$0500,x
		LDA	(\1+$0600),x
		STA	$0600,x
		LDA	(\1+$0700),x
		STA	$0700,x
		INX
		BNE	.Loop\@
	.endm

EditMenuFunc_UserDefine1:
		EditMenuFunc_UserDefine	$8000+($800*0)
		JMP	Screen_Goto_MemoryEdit
EditMenuFunc_UserDefine2:
		EditMenuFunc_UserDefine	$8000+($800*1)
		JMP	Screen_Goto_MemoryEdit
EditMenuFunc_UserDefine3:
		EditMenuFunc_UserDefine	$8000+($800*2)
		JMP	Screen_Goto_MemoryEdit
EditMenuFunc_UserDefine4:
		EditMenuFunc_UserDefine	$8000+($800*3)
		JMP	Screen_Goto_MemoryEdit



;--------------------------------------------------

UpdateMemoryEditAddressOfCursor:
		LDA	MemoryCursor_Row		;   addr += row * 8
		ASL	A
		ASL	A
		ASL	A
		CLC
		ADC	MemoryDumpStart_Low
		ADC	MemoryCursor_Col
		STA	ReadMainMemoryAddress_Low
		STA	WriteMainMemoryAddress_Low
		LDA	MemoryDumpStart_High
		STA	ReadMainMemoryAddress_High
		STA	WriteMainMemoryAddress_High
		MyRTS



;--------------------------------------------------
; Graphic
;--------------------------------------------------

DrawTitle:
		; Text
		LDA	#HIGH(NametableAddress(0, TitleOffset, 1))
		STA	IO_PPU_VRAMAddress
		LDA	#Low(NametableAddress(0, TitleOffset, 1))
		STA	IO_PPU_VRAMAddress
		LDX	#$00
.LoopTitle	LDA	.Title,x
		STA	IO_PPU_VRAMAccess
		INX
		CPX	#TitleLength
		BCC	.LoopTitle

		; Attribute
		PPU_SetDestinationAddress	$23C0
		LDX	#$08
		LDA	#$05
.LoopAttribute	STA	IO_PPU_VRAMAccess
		DEX
		BNE	.LoopAttribute

		MyRTS

.Title
		.db	"Ram edit "
		.db	$FF
.TitleEnd
TitleLength		= .TitleEnd - .Title
TitleOffset		= (32 - TitleLength)/2

;--------------------------------------------------

DrawHexFrame:
		; Header
		PPU_SetDestinationAddress	$2082
		LDX	#$00
.LoopHeader	LDA	.FrameHeader,x
		STA	IO_PPU_VRAMAccess
		INX
		CPX	#FrameHeaderLength
		BCC	.LoopHeader

		; Line
		PPU_SetDestinationAddress	$20A2
		LDX	#$00
.LoopLineLeft	LDA	.FrameLine,x
		STA	IO_PPU_VRAMAccess
		INX
		CPX	#FrameLineLength
		BCC	.LoopLineLeft

		LDX	#(3*8-2)
		LDY	#$91
.LoopLineRight	STY	IO_PPU_VRAMAccess
		DEX
		BNE	.LoopLineRight
		INY
		STY	IO_PPU_VRAMAccess

		PPU_SetDestinationAddress	$20C6
		LDA	#%00001100			;\  NMI disable, SP CHR = $1000, V update
		STA	IO_PPU_Setting			;/
		LDX	#(2*8-2)
		LDY	#$94
.LoopLineBottom	STY	IO_PPU_VRAMAccess
		DEX
		BNE	.LoopLineBottom
		INY
		STY	IO_PPU_VRAMAccess

		LDA	#%00001000			;\  NMI disable, SP CHR = $1000, H update
		STA	IO_PPU_Setting			;/

		MyRTS

.FrameHeader
		.db	"ADDR"
		.db	$93
		.db	"00 01 02 03 04 05 06 07"
.FrameHeaderEnd
FrameHeaderLength	= .FrameHeaderEnd - .FrameHeader
.FrameLine
		.db	$90,$91,$91,$91,$96
.FrameLineEnd
FrameLineLength		= .FrameLineEnd - .FrameLine

;--------------------------------------------------

DrawHorizontalLine:
		PPU_SetDestinationAddress	$22C2
		LDY	#$90
		STY	IO_PPU_VRAMAccess

		LDX	#$1A
		INY
.Loop		STY	IO_PPU_VRAMAccess
		DEX
		BNE	.Loop

		INY
		STY	IO_PPU_VRAMAccess

		MyRTS

DrawFooter:
		PPU_SetDestinationAddress	$22C0
		LDX	#$00
.Loop		LDA	.FooterTile,x
		STA	IO_PPU_VRAMAccess
		INX
		CPX	#FooterTileLength
		BCC	.Loop

		MyRTS

.FooterTile
	;	 00  01  02  03  04  05  06  07  08  09  0A  0B  0C  0D  0E  0F  10  11  12  13  14  15  16  17  18  19  1A  1B  1C  1D  1E  1F
	.db	$00,$00,$90,$91,$91,$91,$91,$91,$91,$91,$91,$91,$91,$9C,'E','D','I','T',$9B,$91,$91,$91,$91,$91,$91,$91,$91,$91,$91,$92,$00,$00
	.db	$00,$00,$88,$89,$89,$8B,$8B,$00,'M','o','v','e',$00,'c','u','r','s','o','r',$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db	$00,$00,$87,$89,$89,$8B,$8C,$00,'C','h','a','n','g','e',$00,'m','e','m','o','r','y',$00,$00,$84,$1A,'+',$00,$85,$1A,'-',$00,$00
	.db	$00,$00,$86,$8A,$89,$8B,$8B,$00,'C','h','a','n','g','e',$00,'p','a','g','e',$00,$00,$00,$00,$82,$1A,'+',$00,$83,$1A,'-',$00,$00
	.db	$00,$00,$81,$8A,$89,$8B,$8C,$00,'C','o','p','y',$00,'v','a','l','u','e',$00,'[',$00,']',$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db	$00,$00,$81,$89,$89,$8C,$8B,$00,'P','a','s','t','e',$00,'v','a','l','u','e',$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db	$00,$00,$81,$89,$8A,$8B,$8B,$00,'O','p','e','n',$00,'m','e','n','u';,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.FooterTileEnd
FooterTileLength	= .FooterTileEnd - .FooterTile

UpdateCopying:
		PPU_SetDestinationAddress	$2354
		LDA	MemoryEdit_Copying
		ORA	#$30
		STA	IO_PPU_VRAMAccess
		MyRTS


;--------------------------------------------------

DrawMenu:
		PPU_SetDestinationAddress	$22C0
		LDX	#$00
.Loop		LDA	.MenuTile,x
		STA	IO_PPU_VRAMAccess
		INX
		CPX	#MenuTileLength
		BCC	.Loop

		MyJSR	UpdateMemoryEditAddressOfCursor
		MyJSR	ReadMainMemory
		PPU_SetDestinationAddress	$22F6
		MyJSR	DrawHex
		PPU_SetDestinationAddress	$2316
		JMP	DrawHex

		;MyRTS

.MenuTile
	;	 00  01  02  03  04  05  06  07  08  09  0A  0B  0C  0D  0E  0F  10  11  12  13  14  15  16  17  18  19  1A  1B  1C  1D  1E  1F
	;	         >
	.db	$00,$00,$90,$91,$91,$91,$91,$91,$91,$91,$91,$91,$91,$9C,'M','E','N','U',$9B,$91,$91,$91,$91,$91,$91,$91,$91,$91,$91,$92,$00,$00
	.db	$00,$00,$00,$00,'F','i','l','l',$00,'a','l','l',$00,$00,'[','C','u','r','s','o','r',$1A,$00,$00,']',$00,$00,$00,$00,$00,$00,$00
	.db	$00,$00,$00,$00,'F','i','l','l',$00,'p','a','g','e',$00,'[','C','u','r','s','o','r',$1A,$00,$00,']',$00,$00,$00,$00,$00,$00,$00
	.db	$00,$00,$00,$00,'U','s','e','r',$00,'d','e','f','i','n','e',$00,'1',$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db	$00,$00,$00,$00,'U','s','e','r',$00,'d','e','f','i','n','e',$00,'2',$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db	$00,$00,$00,$00,'U','s','e','r',$00,'d','e','f','i','n','e',$00,'3',$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db	$00,$00,$00,$00,'U','s','e','r',$00,'d','e','f','i','n','e',$00,'4',$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
.MenuTileEnd
MenuTileLength	= .MenuTileEnd - .MenuTile

;--------------------------------------------------
MemoryDumpPpuAddress		= ScratchMemory+0
MemoryDumpPpuAddress_Low	= MemoryDumpPpuAddress+0
MemoryDumpPpuAddress_High	= MemoryDumpPpuAddress+1
MemoryDumpRowCount		= ScratchMemory+2
MemoryDumpColCount		= ScratchMemory+3

DrawMemoryDump:

		LDA	MemoryDumpStart_Low
		STA	ReadMainMemoryAddress_Low
		LDA	MemoryDumpStart_High
		STA	ReadMainMemoryAddress_High

		; PPU address
		LDA	#$20
		STA	MemoryDumpPpuAddress_High
		LDA	#$C2
		STA	MemoryDumpPpuAddress_Low

		LDA	#MemoryEdit_RowCount
		STA	MemoryDumpRowCount
.LoopRow	LDA	MemoryDumpPpuAddress_High	;\
		STA	IO_PPU_VRAMAddress		; | PPUADDR = MemoryDumpPpuAddress
		LDA	MemoryDumpPpuAddress_Low	; |
		STA	IO_PPU_VRAMAddress		;/

		LDY	ReadMainMemoryAddress_High	;\
		MyJSR	DrawHex				; | Draw address
		LDY	ReadMainMemoryAddress_Low	; |
		MyJSR	DrawHex				;/
		LDA	IO_PPU_VRAMAccess		;   Skip vertical line

		LDA	#MemoryEdit_ColCount
		STA	MemoryDumpColCount

.LoopCol	MyJSR	ReadMainMemory			;\  Draw memory value
		MyJSR	DrawHex				;/

		LDA	#$00				;\  Draw space
		STA	IO_PPU_VRAMAccess		;/

		INC16BIT	ReadMainMemoryAddress	;   Change to next address

		DEC	MemoryDumpColCount
		BNE	.LoopCol

		CLC					;\
		LDA	#$40				; |
		ADC	MemoryDumpPpuAddress_Low	; |
		STA	MemoryDumpPpuAddress_Low	; | Set next row's attribute address
		LDA	#$00				; |
		ADC	MemoryDumpPpuAddress_High	; |
		STA	MemoryDumpPpuAddress_High	;/

		DEC	MemoryDumpRowCount
		BEQ	.Return
		JMP	.LoopRow			;   Avoid brach address out of range

.Return
		MyRTS

;--------------------------------------------------

DrawHex:
		TYA
		LSR	A
		LSR	A
		LSR	A
		LSR	A
		ORA	#$30
		STA	IO_PPU_VRAMAccess

		TYA
		AND	#$0F
		ORA	#$30
		STA	IO_PPU_VRAMAccess

		MyRTS

DrawNormalHex:
		MyJSR	UpdateDrawHex
		MyJSR	DrawHex
		MyRTS

DrawHighlightHex:
		MyJSR	UpdateDrawHex

		; DrawHex
		LDX	MemoryCursor_Nibble
		TYA
		LSR	A
		LSR	A
		LSR	A
		LSR	A
		ORA	.HighlightHigh,x
		STA	IO_PPU_VRAMAccess

		TYA
		AND	#$0F
		ORA	.HighlightLow,x
		STA	IO_PPU_VRAMAccess

		MyRTS

.HighlightHigh
	.db	$30,$30,$B0,$B0
.HighlightLow
	.db	$30,$B0,$30,$B0

UpdateDrawHex:
		; PPUADDR = #$20C7 + row * #$40 + col * #$03
		LDA	MemoryCursor_Row
		ASL	A
		TAX
		LDA	#$C7
		CLC
		ADC	.RowAdd,x
		TAY					;   Y = low
		LDA	#$20				;\
		ADC	.RowAdd+1,x			; | High
		STA	IO_PPU_VRAMAddress		;/
		TYA
		LDX	MemoryCursor_Col
		CLC
		ADC	.ColAdd,x
		STA	IO_PPU_VRAMAddress

		MyJSR	UpdateMemoryEditAddressOfCursor

		JMP	ReadMainMemory

.RowAdd
	.dw	$0000,$0040,$0080,$00C0,$0100,$0140,$0180,$01C0
.ColAdd
	.db	$00,$03,$06,$09,$0C,$0F,$12,$15

;--------------------------------------------------

MenuCursorPpuAddress		= ScratchMemory+0
MenuCursorPpuAddress_Low	= MenuCursorPpuAddress+0
MenuCursorPpuAddress_High	= MenuCursorPpuAddress+1

ClearMenuCursor:
		LDA	#%00001100			;\  NMI disable, SP CHR = $1000, V update
		STA	IO_PPU_Setting			;/

		PPU_SetDestinationAddress	$22E2

		LDA	#$00
		STA	IO_PPU_VRAMAccess
		STA	IO_PPU_VRAMAccess
		STA	IO_PPU_VRAMAccess
		STA	IO_PPU_VRAMAccess
		STA	IO_PPU_VRAMAccess
		STA	IO_PPU_VRAMAccess

		LDA	#%00001000			;\  NMI disable, SP CHR = $1000, H update
		STA	IO_PPU_Setting			;/
		MyRTS

DrawMenuCursor:
		; PPUADDR = $22E2 + MenuCursor * #$20
		LDA	MenuCursor			;   ---- -xxx -> xxx- ----
		CLC
		ROR	A
		ROR	A
		ROR	A
		ROR	A
		CLC
		ADC	#$E2
		STA	MenuCursorPpuAddress_Low
		LDA	#$22
		ADC	#$00
		STA	IO_PPU_VRAMAddress
		LDA	MenuCursorPpuAddress_Low
		STA	IO_PPU_VRAMAddress

		LDA	#$80
		STA	IO_PPU_VRAMAccess

		MyRTS



;--------------------------------------------------
; Controller
;--------------------------------------------------

; Keymap
Controller_Key_A		= $80
Controller_Key_B		= $40
Controller_Key_Select		= $20
Controller_Key_Start		= $10
Controller_Key_Up		= $08
Controller_Key_Down		= $04
Controller_Key_Left		= $02
Controller_Key_Right		= $01

; RAM Map
Controller_ReadTemporary	= ScratchMemory+0


Controller_Update:
		LDY	#$01				;\
		STY	IO_Controller_Port1		; |
		DEY					; | Read preparation
		STY	IO_Controller_Port1		; |
		STY	Controller_ReadTemporary	;/
		LDY	#$07
		LDA	#$03
.Loop		BIT	IO_Controller_Port1
		BEQ	.Next				;\
		LDA	.Controller_Mask,y		; | When the controller or expansion port is input, flag is set.
		ORA	Controller_ReadTemporary	; |
		STA	Controller_ReadTemporary	;/
		LDA	#$03
.Next		DEY
		BPL	.Loop

		LDA	Controller_ReadTemporary
		EOR	Controller_Player_Input
		AND	Controller_ReadTemporary
		STA	Controller_Player_Press
		LDA	Controller_ReadTemporary
		STA	Controller_Player_Input

		MyRTS

.Controller_Mask		.db $01,$02,$04,$08,$10,$20,$40,$80



;--------------------------------------------------
; User define table
;--------------------------------------------------
	.bank	0
	.org	$8000
	.include	"UserDefine.asm"



;--------------------------------------------------
; CHR
;--------------------------------------------------
	.bank PrgCount*2
	.org $0000
	.incbin "Graphics/GFX_Font.bin"			; $00-$03
	.org $1000
	.incbin "Graphics/GFX_Blank.bin"		; $04-$05
	.incbin "Graphics/GFX_Blank.bin"		; $06-$07


