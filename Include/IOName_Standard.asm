;--------------------------------------------------
; IO name - Standard(PPU, APU)
;--------------------------------------------------

IO_PPU_Setting		= $2000	; npsbsimm
IO_PPU_Display		= $2001	; rgbsbsbc
IO_PPU_Status		= $2002	; v0cs----
IO_PPU_SpriteAddress	= $2003	; dddddddd
IO_PPU_SpriteAccess	= $2004	; dddddddd
IO_PPU_Scroll		= $2005	; dddddddd
IO_PPU_VRAMAddress	= $2006	; dddddddd
IO_PPU_VRAMAccess	= $2007	; dddddddd

IO_APU_Square1_1	= $4000	; ddlerrrr
IO_APU_Square1_2	= $4001	; fssshrrr
IO_APU_Square1_3	= $4002	; ffffffff
IO_APU_Square1_4	= $4003	; cccccfff
IO_APU_Square2_1	= $4004	; ddlerrrr
IO_APU_Square2_2	= $4005	; fssshrrr
IO_APU_Square2_3	= $4006	; ffffffff
IO_APU_Square2_4	= $4007	; cccccfff
IO_APU_Triangle_1	= $4008	; flllllll
;IO_APU_Triangle_2	= $4009	; --------
IO_APU_Triangle_3	= $400A	; ffffffff
IO_APU_Triangle_4	= $400B	; cccccfff
IO_APU_Noise_1		= $400C	; --lerrrr
;IO_APU_Noise_2		= $400D	; --------
IO_APU_Noise_3		= $400E	; r---ffff
IO_APU_Noise_4		= $400F	; ccccc---
IO_APU_DPCM_1		= $4010	; ir--ffff
IO_APU_DPCM_2		= $4011	; -fffffff
IO_APU_DPCM_3		= $4012	; aaaaaaaa
IO_APU_DPCM_4		= $4013	; llllllll
IO_Sprite_DMA		= $4014	; aaaaaaaa
IO_APU_KeyonFlag	= $4015	; ii-dntss
IO_Controller_Port1	= $4016	; ---ccccc
IO_Controller_Port2	= $4017	; u--ccccc
