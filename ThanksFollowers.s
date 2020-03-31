

	INCLUDE "Offsets.i"
fire	=	$bfe001

run:
	bsr	OpenLibrary
	
	bsr CreateViewPort
	
	bsr	DrawSomething
	
loop:
	
	tst.b	fire
	bpl	TheEnd
	bra loop

CreateViewPort:
	;create View
	move.l	GfxBase,a6	
	lea	View,a1
	jsr	InitView(a6)
	lea 	ViewPort,a0
	jsr 	InitVPort(a6)
	lea	View,a0
	move.l 	#ViewPort,(a0)	;View->ViewPort = &ViewPort
	
	;initBitMap
	lea BitMap,a0
	move.b	#DEPTH,d0
	move.w	#WIDTH,d1
	move.w	#HEIGHT,d2
	jsr	InitBitMap(a6)		
	
	;initRastPort
	lea	RastPort,a1
	jsr	InitRastPort(a6)	
	lea	RastPort,a0
	lea	4(a0),a0			;move to Bitmap pointer
	move.l	#BitMap,(a0)	;RastPort->Bitmap = &BitMap
	
	lea RasInfo,a0
	lea	4(a0),a0
	move.l	#BitMap,(a0)	;RasInfo->BitMap = &Bitmap
	
	;create View Port
	lea 	ViewPort,a0			
	lea 	24(a0),a1
	move.w	#WIDTH,(a1)+
	move.w	#HEIGHT,(a1)
	lea 	ViewPort,a0
	lea		32(a0),a1
	move.w	#HIRES+LACE,(a1)
	lea		36(a0),a1
	move.l	#RasInfo,(a1)	;ViewPort->RasInfo = RasInfo
	
	
	;having problems with creating a custom ColorMap
	;move.w	#16,d0
	;jsr	GetColorMap(a6)
	;move.l	d0,ColorMap
	
	;lea 	ViewPort,a0
	;lea	4(a0),a0
	;move.l	#ColorMap,(a0)	;ViewPort->ColorMap = colormap
	
	;loadRGB4
	;lea	ViewPort,a0
	;move.l	Colours,a1
	;move.w	#16,d0
	;jsr	LoadRGB4(a6)
	
	
	
	;prepare to loop through planes on bitmap
	move.b	#0,d6		
	move.b	#DEPTH,d5	;number of planes
Plane:
	move.w	#WIDTH,d0
	move.w	#HEIGHT,d1
	jsr	AllocRaster(a6)
	beq	error
	
	lea	BitMap,a0		
	lea 	8(a0,d6),a0		;find plane, increment to next plane.  0-3
	move.l	d0,(a0)		;bitmap.plane[i] = allocatedraster
	
	move.l	#RASSIZE,d0	;size  width*height/8
	move.w	#0,d1		;flags
	jsr	BltClear(a6)	;clear memory to 0s
	
	add	#4,d6
	sub	#1,d5
	bne	Plane			;loop back if d5 != 0
;end Plane loop

	
	;MakeVPort
	lea 	View,a0
	lea	ViewPort,a1
	jsr	MakeVPort(a6)
	
	;MrgCop
	lea 	View,a1
	jsr	MrgCop(a6)

	;LoadView
	lea 	View,a1
	jsr	LoadView(a6)
	
	;setDrMd
	lea 	RastPort,a1
	move.l	#$0,d0
	jsr	SetDrMd(a6)
	
	;setRast
	lea 	RastPort,a1
	move.l	#0,d0
	jsr	SetRast(a6)	
	rts
TheEnd:
	bsr	FreeMemory
	
	move.l	GfxBase,a6
	move.l	OldView,a1
	
	jsr	LoadView(a6)
	
	bsr	CloseLibrary
	rts

error:
;need some error logic here
;probably should open a console and advise
	rts
	
DrawSomething:
	move.l	GfxBase,a6
	
	lea	StringOffsets,a2

	move.w	#10,d4
	move.w 	#4,d3	;columns
	move.w	#1,d5
	
NextColumn:	
	
	move.w	#25,d6	;rows
	move.w	#10,d7
	
DrawColumn:
	and	#$F,d5
	beq AddOne
	
	move.w	d5,d0
	lea	RastPort,a1
	jsr	SetAPen(a6)

	lea 	RastPort,a1
	move.w	d4,d0
	move.w	d7,d1
	jsr	MoveCurser(a6)
	
	lea	RastPort,a1
	lea	TheStrings,a0	

	move.w	(a2),d0		;stringOffsets 	
	lea	(a0,d0),a0		;get the start of string
	
	move.w	(a2)+,d1	
	move.w	(a2),d2		
	sub d0,d2			
	move.w	d2,d0		

	jsr	Text(a6)	
	
	add	#1,d5
	add	#10,d7
	sub	#1,d6
	bne	DrawColumn
	
	add	#140,d4
	sub #1,d3
	bne NextColumn

	rts
AddOne:
	add #1,d5
	bra DrawColumn
	
OpenLibrary:
	move.l	ExecBase,a6
	lea	GfxName,a1
	jsr	OpenLib(a6)
	move.l	d0,GfxBase
	
	add	#7976,d0
	move.l	d0,OldView		;save the old view 
	rts

FreeMemory:
	moveq	#0,d6		
	moveq	#DEPTH,d5		;number of planes

Free:	
	move.w	#WIDTH,d0
	move.w	#HEIGHT,d1
	move.l	#BitMap,a1
	move.l 	8(a1,d6),d2
	move.l	d2,a0
	jsr	FreeRaster(a6)
	add	#4,d6
	sub	#1,d5
	bne	Free			;loop back if d5 != 0
	
	rts
	
CloseLibrary:
	move.l	ExecBase,a6
	move.l	GfxBase,a1
	jsr	CloseLib(a6)
	rts
	
;structs and declarations
View:
	dc.l	0				;ViewPort:
	dc.l	ColorMap
	dc.l	0				
	dc.w	0,0,0
	
ViewPort:	
	dc.l	0				;next Viewport
	dc.l	0				;ColorMap
	dc.l	0,0,0,0
	dc.w	0,0,0,0,0,0		;width,height, x, y, MODE
	dc.l	0;				;RasInfo

RasInfo:	dc.l	0
		dc.l	0		;bitmap
		dc.w	0,0
	
BitMap:	
	dc.w	0,0
	dc.b	0,0
	dc.w	0
	dc.l	0,0,0,0,0,0,0,0
	
RastPort:
	dc.l	0,0,0,0,0,0
	dc.b 	0,0,0,0,0,0,0,0
	dc.w	0,0,0,0
	dc.b	0,0,0,0,0,0,0,0
	dc.w	0,0
	dc.l	0
	dc.b	0,0
	dc.w	0,0,0,0
	dc.l	0
	dc.w	0
	dc.l	0
	dc.b	0
	even
	

Colours:
	dc.w	$000,$fff,$f00,$0f0
	dc.w	$00f,$f0f,$ff0,$0ff
	dc.w	$f8f,$8ff,$ff8,$f88
	dc.w	$8f8,$88f,$888,$444

Ball_HD:	dc.l	0	
Ball_Data:
	dc.w	0,0
	dc.w	$0ff0,$0000
	dc.w	$0ff0,$0000
	dc.w	$0ff0,$0000
	dc.w	$0ff0,$0000
	dc.w	$0ff0,$0000
	dc.w	$0ff0,$0000
	dc.w	0,0
	
Ball: dc.l	0

Simple_Sprite:
	dc.l	0
	dc.w	0,0,0,0
	
OldView:	dc.l	0

GfxName dc.b	"graphics.library"
	even
GfxBase	dc.l	0

ColorMap:		dc.l	0

StringOffsets:
	dc.w	0,9,18,31,42,54,62,74,85,101,114,125,134,144,158
	dc.w	173,186,200,209,217,225,237,247,254,267
	
	dc.w	281,294,303,319,333,343,352,367,379,386,394,406,418,426
	dc.w	437,446,457,464,475,485,497,502,511,518
	
	dc.w 	530,539,547,562,574,583,592,604,620,626,638,646,660,668
	dc.w 	681,688,703,717,729,743,757,766,777,785,799,810
	
	dc.w 	821,831,846,860,868,882,894,903,915,925,934,943,953,963
	dc.w 	972,987,995,1005,1013,1025,1036,1051,1065,1070
	
	dc.w 	1081,1092,1099,1107;,1119,1129,1143,1154,1164,1180
	;dc.w 	1189,1203,1212,1223,1239,1249
	
TheString:
	dc.b	"The String"
StringEnd:
	even

TheStrings:
	dc.b	"@johnmdow"				;9
	dc.b	"@8bitGrrl"				;18
	dc.b	"@Alex04833605"			;31
	dc.b	"@mohicankid"			;42
	dc.b	"@benjamincpu"			;54
	dc.b	"@slaine_"				;62
	dc.b	"@Pixel_Chris"			;74
	dc.b	"@msbalioglu"			;85
	dc.b	"@CoalheartUlbale"		;101
	dc.b	"@joel_mr_rage"			;114
	dc.b	"@GreyAreaUK"			;125
	dc.b	"@@S4L0Mon"				;134
	dc.b	"@CodexoOrg"			;144
	dc.b	"@Sindrelausund"		;158
	dc.b	"@ajdlivestreams"		;173
	dc.b	"@alloyvincent"			;186
	dc.b	"@gamecontinuum"		;200
	dc.b	"@Solyant1"				;209
	dc.b	"@fresxcd"				;217
	dc.b	"@sjewkes"				;225
	dc.b	"@YeahStephan"			;237
	dc.b	"@mlundblad"			;247
	dc.b	"@cout64"				;254
	dc.b	"@davidbbarber"			;267
	
	dc.b	"@DataAugmented"		;281
	dc.b	"@ozgur_karter"			;294
	dc.b	"@bareeves"				;303
	dc.b	"@BudgetNostalgia"		;319
	dc.b	"@northgiddings"		;333
	dc.b	"@vigobronx"			;343
	dc.b	"@hlgb1984"				;352
	dc.b	"@JackBlackadder"		;367
	dc.b	"@JoeSkeeRock"			;379
	dc.b	"@ukusmr"				;386
	dc.b	"@krutten"				;394
	dc.b	"@tw1sted1981"			;406
	dc.b	"@kneehighspy"			;418
	dc.b	"@coolrob"				;426
	dc.b	"@rich_lloyd"			;437
	dc.b	"@sound_fx"				;446
	dc.b	"@adricompos"			;457
	dc.b	"@cndycc"				;464
	dc.b	"@favaditopo"			;475
	dc.b	"@tirnablog"			;485
	dc.b	"@StuartBate3"			;497
	dc.b	"@crod"					;502
	dc.b	"@gino_tam"				;511
	dc.b	"@gonche"				;518
	
	dc.b	"@theretroapp"			;530
	dc.b	"@KaIEI_64"				;539
	dc.b	"@ptb2012"				;547
	dc.b	"@p_budziszewski"		;562
	dc.b	"@techstepper"			;574
	dc.b	"@hdavidf1"				;583
	dc.b	"@carlom74"				;592
	dc.b	"@AmProfiteur"			;604
	dc.b	"@kermit_thrasher"		;620
	dc.b	"@d1p51"				;626
	dc.b	"@_busdevpeep"			;638
	dc.b	"@lip7494"				;646
	dc.b	"@Spookysoft_Hi"		;660
	dc.b	"@hacknet"				;668
	dc.b	"@LaunchpadMQ1"			;681
	dc.b	"@mrkola"				;688
	dc.b	"@RetrolBrothers"		;703
	dc.b	"@Officeboy1969"		;717
	dc.b	"@CanuckInEns"			;729
	dc.b	"@DigitalStefan"		;743
	dc.b	"@Nickshardware"		;757
	dc.b	"@BatteMan"				;766
	dc.b	"@cmosscmiss"			;777
	dc.b	"@danjmcs"				;785
	dc.b	"@7demonsrising"		;799
	dc.b	"@aneddotica"			;810
	
	dc.b	"@simontek27"			;821
	dc.b	"@AmigaL0ve"			;831
	dc.b	"@mange_johanson"		;846
	dc.b	"@randyandteddy"		;860
	dc.b	"@leopmdq"				;868
	dc.b	"@CervetoVictor"		;882
	dc.b	"@glynnquelch"			;894
	dc.b	"@jibiAyar"				;903
	dc.b	"@retromattuk"			;915
	dc.b	"@kerrichal"			;925
	dc.b	"@p_ylinen"				;934
	dc.b	"@kamelito"				;943
	dc.b	"@ceagagepe"			;953
	dc.b	"@pdschultz"			;963
	dc.b	"@jpjuanjp"				;972
	dc.b	"@Amiga_Paradise"		;987
	dc.b	"@bish500"				;995
	dc.b	"@KareyPyer"			;1005
	dc.b	"@fuzzyid"				;1013
	dc.b	"@synthmonkey"			;1025
	dc.b	"@waldbaerTV"			;1036
	dc.b	"@ricardomarasch"		;1051
	dc.b	"@CommodoreBlog"		;1065
	dc.b	"@dummheitstinkt"		;1070
	
	dc.b	"@RETRO13121"			;1081
	dc.b	"@PierreJoye"			;1092
	dc.b	"@EMFR68"				;1099
	dc.b	"@adesbro"				;1107
	;dc.b	"@C64Retweets"			;1119
	;dc.b	"@Kj_Janzer"			;1129
	;dc.b	"@EverythingC64"		;1143
	;dc.b	"@ZXRetweets"			;1154
	;dc.b	"@Phebian51"			;1164
	;dc.b	"@retrogamesearch"		;1180
	;dc.b	"@gregnacu"				;1189
	;dc.b	"@AmigaRetweets"		;1203
	;dc.b	"@Funtaman"				;1212
	;dc.b	"@ZuevAlex52"			;1223
	;dc.b	"@jamesfmackenzie"		;1239
	;dc.b	"@Ms_Duckie"			;1249

	even
	
