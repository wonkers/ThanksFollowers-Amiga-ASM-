ExecBase	=	4
OpenLib		=	-408
CloseLib	=	-414
InitView	=	-360
InitVPort	=	-204
InitBitMap	=	-390
InitRastPort	=	-198
GetColorMap	=	-570
LoadRGB4	=	-192
AllocRaster	=	-492
BltClear	=	-300
MrgCop		=	-210
MakeVPort	=	-216
LoadView	=	-222
SetRast		=	-234
SetDrMd		=	-354
FreeRaster	=	-498
FreeColorMap	=	-576
SetAPen		=	-342
MoveCurser	=	-240
Text		=	-60
AllocMem 	=	-198
FreeMem		=	-210
;AllocAbs	=	-$cc
WritePixel	=	-324
ChangeSprite	=	-420 	;vp, sprite,data
MoveSprite	=	-426		;p sp, x, y
GetSprite	= -408

WIDTH	=	640
HEIGHT	= 512
DEPTH	=	4
RASSIZE = WIDTH * HEIGHT / 8

SPRITES = $4000
MEMF_CLEAR = $10000
MEMF_CHIP = $0002

HIRES = $8000
LACE = $0004
 
