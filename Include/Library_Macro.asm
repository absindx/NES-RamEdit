;--------------------------------------------------
; Library macro
;--------------------------------------------------

	.include	"Include/IOName_Standard.asm"

	.ifndef	IncludeGuard_Library_Macro
IncludeGuard_Library_Macro	.macro
	.endm	; Dummy macro


;--------------------------------------------------
; Math

; Addition to accumulator without carry
;   Update A register
; Argument
;   1 Number to be added
ADD	.macro
		CLC
		ADC	\1
	.endm

; Subtraction to accumulator without carry
;   Update A register
; Argument
;   1 Number to be subbed
SUB	.macro
		SEC
		SBC	\1
	.endm

; Flip the sign of the accumulator
;   Update A register
; Argument
;   None
NEG	.macro
		EOR	#$FF
		CLC
		ADC	#$01
	.endm

; Arithmetic shift right
;   Update A register
; Argument
;   None
ASR	.macro
		CMP	#$80
		ROR	A
	.endm

; Store Zero
;   Use A register
; Argument
;   1 Address to store zero
STZ	.macro
		LDA	#$00
		STA	\1
	.endm

; Increment memory(16bit)
;   Use A register
; Argument
;   1 Address
INC16BIT	.macro
		INC	\1
		BNE	.Return\@
		INC	\1+1
.Return\@
	.endm

; Decrement memory(16bit)
;   Use A register
; Argument
;   1 Address
DEC16BIT	.macro
		LDA	\1
		BNE	.Low\@
		DEC	\1+1
.Low\@		DEC	\1
	.endm

;--------------------------------------------------
; PPU

; Set PPU VRAM address
;   Use A register
; Argument
;   1 PPU address
PPU_SetDestinationAddress	.macro
		.if	(HIGH(\1))!=(LOW(\1))
			LDA	#HIGH(\1)
			STA	IO_PPU_VRAMAddress
			LDA	#LOW(\1)
			STA	IO_PPU_VRAMAddress
		.else
			LDA	#LOW(\1)
			STA	IO_PPU_VRAMAddress
			STA	IO_PPU_VRAMAddress
		.endif
	.endm

; Wait V-Blank
; Argument
;   None
WaitVBlank	.macro
.Wait\@		BIT	IO_PPU_Status
		BPL	.Wait\@
	.endm

; Get Nametable VRAM address
; Argument
;   1 Nametable plane
;   2 Tile x position
;   3 Tile y position
NametableAddress	.func	(8192 + (\1)*1024 + (\3)*32 + (\2))

;--------------------------------------------------
; System

; Align the current position to the specified boundary
; Argument
;   1 Boundary size
Align		.macro
.Origin\@
		.if	(.Origin\@ + ((\1 - (.Origin\@ % \1)) % \1)) <= $FFFF
			.org	(.Origin\@ + ((\1 - (.Origin\@ % \1)) % \1))
		.else
.fail		"Address space exceeded!"
		.endif
	.endm

; Set bank number at start of bank
; Argument
;   1 Bank number
SetBankNumber	.macro
		.bank	\1
		.org	((\1*$2000)%$8000 + $8000)
		.db	$\1
	.endm

;--------------------------------------------------
; Utility

; Store 0 to address
;   Use A, X register
; Argument
;   1 Address
;   2 Length
ZeroMemory	.macro
		LDA	#$00
		LDX	LOW(\2)
.Loop\@		STA	\1,x
		DEX
		BNE	.Loop\@
	.endm

; Store repeated 0 to address
;   Use A, X register
; Argument
;   1 Address
;   2 Length
IOZeroMemory	.macro
		LDA	#$00
		LDX	LOW(\2)
.Loop\@		STA	\1
		DEX
		BNE	.Loop\@
	.endm

; Wait for specified cycle
;   Use X register
; Argument
;   1 wait cycle (>= 2)
WaitCycle	.macro
	.if \1=1
.fail	"1 cycle can not wait."
	.endif
	.if \1=2
		NOP			; 2
	.endif
	.if \1=3
		LDX	<$00		; 3
	.endif
	.if \1=4
		WaitCycle	2
		WaitCycle	2
	.endif
	.if \1=5
		WaitCycle	2
		WaitCycle	3
	.endif
	.if \1=6
		WaitCycle	2
		WaitCycle	2
		WaitCycle	2
	.endif
	.if \1=7
		PHA			; 3
		PLA			; 4
	.endif
	.if \1>=8
		.if (((\1-6)%5)=0)		;    11, 16, ...
			LDX	#((\1-1)/5)	; 2
.Loop\@			DEX			; 2
			BNE	.Loop\@		; 3/2
		.endif
		.if (((\1-6)%5)=1)		;    12, 17, ...
			WaitCycle	6
			WaitCycle	\1-6	; -> 6, 11, ...
		.endif
		.if (((\1-6)%5)=2)		; 8, 13, 18, ...
			WaitCycle	2
			WaitCycle	\1-2	; -> 6, 11, 16, ...
		.endif
		.if (((\1-6)%5)=3)		; 9, 14, 19, ...
			WaitCycle	3
			WaitCycle	\1-3	; -> 6, 11, 16, ...
		.endif
		.if (((\1-6)%5)=4)		; 10, 15, 20, ...
			WaitCycle	4
			WaitCycle	\1-4	; -> 6, 11, 16, ...
		.endif
	.endif
	.endm

;--------------------------------------------------

	.endif	; IncludeGuard_Library_Macro
