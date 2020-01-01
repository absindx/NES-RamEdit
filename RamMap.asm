;--------------------------------------------------
; RAM Map
;--------------------------------------------------

ScratchMemory			= $6000

FrameCounter			= $6010
FrameCounter_Animate		= $6012
Controller_Player1_Input	= $6013
Controller_Player1_Press	= $6014
Controller_Player_Input		= Controller_Player1_Input
Controller_Player_Press		= Controller_Player1_Press

JumpAddress			= $60FD
JumpAddress_Low			= JumpAddress+0
JumpAddress_High		= JumpAddress+1
MyStackPointer			= $60FF
MyStack				= $6100

ScreenMode			= $6015

MemoryDumpStart			= $6020
MemoryDumpStart_Low		= MemoryDumpStart+0
MemoryDumpStart_High		= MemoryDumpStart+1

MemoryCursor			= $6022
MemoryCursor_Page		= MemoryCursor+0
MemoryCursor_Row		= MemoryCursor+1
MemoryCursor_Col		= MemoryCursor+2
MemoryCursor_Nibble		= MemoryCursor+3
MemoryEdit_Copying		= MemoryCursor+4

MenuCursor			= $6027


DynamicCode			= $6080


