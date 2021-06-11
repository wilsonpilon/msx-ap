; TeddyWareZ MSX Z80 source file.
;
; Prog: SCC Blaffer NT BASIC replay ROM code with slot-expand!
; Code: d-fader^TwZ.
; Date: September 6, 1999
;
; cmnt: none.
;
; coded in Chaos Assembler 2.0
;
; (C) 1999 TeddyWareZ!

	.org $4000-7

	.db $fe
	.db $9000,end_program+ofs,start_program+ofs


; Versions:
;
; v1.50 - Added Slot Expander support. Read documentation on InitSCC again!!
; v1.41 - Fixed little bug with ML support.
; v1.40 - Added ML support. Read documentation on how to use it!
; v1.30 - Added the DOPSG override system (for sound effects while the music is playing)
;         Added the STOPPSG command to stop the PSG SE (for infinite loops and stuff)
; v1.25 - Added MPV (Maximum PSG Volume) options
; v1.20 - Added fading routine ( _bntfade(<x>) )
; v1.05 - No illegal function calls anymore (e.g. _bntstop while the music is stopped)
; v1.00 - First build


verHigh		.equ 1				; version H.HL
verLowH		.equ 5				;
verLowL		.equ 0				; where H  = major
								;       H2 = minor (High)
								;       L  = minor (Low)

RomBank		.equ 2				; The bank in which the replayer is stored...
SongBank		.equ 3				; The 'default' song bank
KitBank		.equ 4				; The 'default' instrument kit bank

;BasicComp		.equ 1				; When 1 the replayer will be compiled with
								; Basic use in mind (all calls and stuff)
								;
								; When 0 then the replayer will be compiled
								; with ML use in mind (all functions available
								; with 'CALLS'.

SilentComp		.equ 0				; When <> 0 the replayer is ALWAYS silent. The
								; loud option will then not be compiled.

.NOLIST
#include "bntpmacr.asm"
.LIST

ofs			.equ $5000

; Start of 'ROM' code:

StartRom:
	.db "AB"						; ID bytes
	.dw 0							; Init byte
	.dw StartRomCode					; Pointer
	.dw 0,0,0,0,0					; Reserved

	.db "         "
	.db "                "
	.db " SCC Blaffer NT " 
	.db "                "
	.db " Replay Routine "
	.db "                "
	.db "(C)1999/2000 TwZ"
	.db "                "
	.db "  Version ", verHigh + 48, ".", verLowH + 48, verLowL + 48, "  "
	.db "                "

MlUsage:
	.ds $4100-MlUsage

; From this point all ML routines follow... Just call address $4100, but make sure to have
; selected the replayer map on page 1.
; Address $f7f8 is the USR peek.
;
; When returning from the replay routine address $f414 will have an error code...
;   0 - Function executed correctly
;   1 - SCC Found in slot 1 (only used with InitSCC)
;   2 - SCC Found in slot 2 (only used with InitSCC)
; 100 - Function NOT executed (correctly), e.g. load-error or no SCC found.
; 101 - Function NOT found
; 102 - Function NOT available, e.g. BntPLay while the music is playing

; commands: 
;  0 - Initialize SCC
;  1 - Force SCC     -> param: 1 byte at $da3d (RepCommand)
;  2 - Load SBM file -> param: 12 bytes at $da00 (fcb)
;  3 - Load SBK file -> param: 12 bytes at $da00 (fcb)
;  4 - Play Music
;  5 - Stop Music
;  6 - Pause Music
;  7 - Continue Music
;  8 - Fade Music -> param: 1 byte at $da3d (RepCommand)
;  9 - PSG Override (Sound Effect) -> param: 1 byte at $da3d (RepCommand)
; 10 - PSG Override Stop (Sound Effect)

	xor a
	ld ($f414),a
	ld (MlMenu),a

	ld a,($f7f8)

	or a
	jp z,ml.InitSCC
	dec a
	jp z,ml.ForceMusic
	dec a
	jp z,ml.SBMLoad
	dec a
	jp z,ml.SBKLoad
	dec a
	jp z,ml.startMusic
	dec a
	jp z,ml.stopMusic
	dec a
	jp z,ml.haltMusic
	dec a
	jp z,ml.contMusic
	dec a
	jp z,ml.fadeMusic
	dec a
	jp z,ml.psgOverride
	dec a
	jp z,psgOverrideStop

	ld a,101
	ld ($f414),a

	ret

ml.InitSCC:
	ld a,(MusicPlay)
	or a
	jp nz,ml.err102

	call SearchSCC
	jp c,ml.err100

	ld a,(scc.prim)
	ld b,a

	ld a,(scc.sec)
	srl a
	srl a
	srl a
	srl a
	
	or b
	ld ($f414),a

	ret

ml.SBMLoad:
; routine : Load an SBM file into memory
; in      : $da00       - 12 bytes pointer to file.
; out     : ($f414)     - error code
; cmnt    : $da00       - drive (0 - default, 1 - drive a, etc.)
;           $da01-$da11 - 8 bytes filename and 3 bytes extension.

	ld a,(musicPlay)
	or a
	jp nz,ml.err102

	ld a,1
	ld (MlMenu),a

	ld hl,fcb
	ld de,drive
	ld bc,12
	ldir

	call ml.SBMLoad.1

	ret

ml.SBKLoad:
	ld a,(musicPlay)
	or a
	jp nz,ml.err102

	ld a,1                            
	ld (MlMenu),a

	ld hl,fcb
	ld de,drive
	ld bc,12
	ldir

	call ml.SBKLoad.1

	ret

ml.startMusic:
	ld a,(MusicPlay)
	or a
	jp nz,ml.err102

	jp ml.startMusic.1

ml.stopMusic:
	ld a,(MusicPlay)
	or a
	jp z,ml.err102

	jp ml.stopMusic.1
	
ml.haltMusic:
	ld a,(MusicPlay)
	cp 1
	jp nz,ml.err102

	jp ml.haltMusic.1

ml.contMusic:
	ld a,(MusicPlay)
	cp 2
	jp nz,ml.err102

	jp ml.contMusic.1

ml.fadeMusic:
	ld a,(MusicPlay)
	or a
	jp z,ml.err102

	ld a,(RepCommand)

	ld b,a
	jp ml.fadeMusic.1	

ml.psgOverride:
	ld a,1
	ld (MlMenu),a

	ld a,(RepCommand)
	jp ml.psgOverride.1

ml.forceMusic:
	ld a,1
	ld (MlMenu),a

	ld a,(RepCommand)
	jp ml.forceMusic.1

ml.err100:
	ld a,100
	ld ($f414),a

	ret

ml.err102:
	ld a,102
	ld ($f414),a

	ret



; From this point is the code for BASIC users and the 'actual' routines also for ML users.
StartRomCode:
	push hl						; Save pointer

	ld de,Identifiers

NextIdent:	
	ld hl,$fd89						; ProcNm

NextChar:	
	ld a,(de)						; Compare the chars
	cp (hl)						;
	jp nz,SkipLabel					; not equal, skip the rest, next identifier
								;
	or a							;
	jp z,IdentFound					; end marker, so identified...
								;
	inc hl						;
	inc de						;
								;
	jp NextChar						; check next char of call

SkipLabel:
	ld a,(de)						; Set pointer to next identifier
	or a							;
	jp z,SkipPointer					;
								;
	inc de						;
								;
	jp SkipLabel					;

SkipPointer:
	inc de						; skip address (and terminate character)
	inc de						;
	inc de						;
								;
	ld a,(de)						; check if this was the last label
	cp $ff						;
	jp z,IdentNotFound				; yes, so call not found
								;
	jp NextIdent					; no, check next label

;IdentNotAvail:
	pop de

	ld ix,$475a						; Illegal function call error
	call $159

	pop hl

	or a
	ret

playNotAvail:
	ld hl,onlyPlayText
	jp notAvailDone

stopNotAvail:
	ld hl,onlyStopText
	jp notAvailDone

pauseNotAvail:
	ld hl,onlyPauseText

notAvailDone:
	ld a,1
	call ShowText

	pop de
	pop hl

	ld a,101
	ld ($f414),a

	or a
	ret

onlyPlayText:
	.text "This command is only available when the music is playing!`"
	.db 0
onlyStopText:
	.text "This command is only available when the music is stopped!`"
	.db 0
onlyPauseText:
	.text "This command is only available when the music is paused!`"
	.db 0


IdentNotFound:	
	pop hl						; get pointer back!

	scf							; Set carry flag (neccessary)
	ret							; return to where it came from.

IdentFound:
	xor a
	ld ($f414),a
	ld (MlMenu),a

	ex de,hl

	inc hl						; HL has pointer to address to call...
	ld e,(hl)						; get pointer to call

	inc hl

	ld d,(hl)

	ex de,hl						; HL has pointer to call

	ld de,ROMCodeDone					; Return to ROMCodeDone
	push de

	jp (hl)						; Jump with call effect!

RomCodeDone:
	pop hl						; Get pointer back!

	or a							; RESet carry flag! (label found)
	ret							; Return

Identifiers:
	.db "SBMLOAD",0
	.dw SBMLoad

	.db "SBKLOAD",0
	.dw SBKLoad

	.db "BNTPLAY",0
	.dw StartMusic
      
	.db "BNTSTOP",0
	.dw StopMusic

	.db "BNTHALT",0
	.dw HaltMusic

	.db "BNTCONT",0
	.dw ContMusic
	
	.db "PLAYVER",0
	.dw PlayVer

#IF (SilentComp = 0)

	.db "BNTSILENT",0
	.dw BntSilent

	.db "BNTLOUD",0
	.dw BntLoud
#EndIf

	.db "INITSCC",0
	.dw InitSCC

	.db "FORCE",0
	.dw ForceMusic

	.db "SNGBANK",0
	.dw SelectSongBank

	.db "KITBANK",0
	.dw SelectKitBank

	.db "BNTFADE",0
	.dw fadeMusic

	.db "DOPSG",0
	.dw psgOverride

	.db "STOPPSG",0
	.dw psgOverrideStop

	.db $ff

psgOverrideStop:
	xor a
	ld (newPSGStyle),a

	call PSG.StopSound

	ret

psgOverride:
	call invokeByte

ml.psgOverride.1:
	or a
	jp z,psgOverrideImp
	cp 45
	jp nc,psgOverrideImp

	dec a
	ld (newPSG),a

	ld a,1
	ld (newPSGStyle),a

	ret

psgOverrideImp:
	ld a,100
	ld ($f414),a

	ld a,(MlMenu)
	or a
	ret nz

	DoShowText(psgORtxt, 1)

	ret

psgORtxt:
	.text "PSG Overriding impossible!`"
	.text "Not compatible PSG instrument given... Valid: 1-44`"
	.db 0

SelectSongBank:
	call InvokeByte

	ld b,a

	ld a,(MusicPlay)
	or a
	jp nz,stopNotAvail

	ld a,b

	ld (SngBnkPlay),a

	ret

SelectKitBank:
	call InvokeByte

	ld b,a

	ld a,(MusicPlay)
	or a
	jp nz,stopNotAvail

	ld a,b

	ld (InsBnkPlay),a

	ret

fadeMusic:
	call InvokeByte

	ld b,a

	ld a,(MusicPlay)
	or a
	jp z,playNotAvail

ml.fadeMusic.1:
	ld a,1
	ld (musicFade),a

	ld a,15
	ld (fadeCount.1),a

	xor a
	ld (fadeCount.2),a

	ld a,b
	ld (fadingSpeed),a

	ret

InitSCC:
	ld a,(MusicPlay)
	or a
	jp nz,stopNotAvail

	call SearchSCC
	jp c,NoSCCFound

	ld a,(scc.prim)
	ld b,a

	ld a,(scc.sec)
	srl a
	srl a
	srl a
	srl a
	
	or b
	ld ($f414),a

	ld a,(scc.prim)
	srl a
	srl a
	srl a
	srl a
	add a,48
	ld (SCCSlot.prim),a

	ld a,(scc.sec)
	srl a
	srl a
	srl a
	srl a
	add a,48
	ld (SCCSlot.sec),a

	DoShowText(SCCFoundText,1)

	ret

NoSCCFound:
	DoShowText(SCCNotFound,1)

	ld a,100
	ld ($f414),a

	ret

SCCFoundText:
	.text "SCC Initialise successful (slot "
SCCSlot.Prim:
	.text "?-"
SCCSlot.Sec:
	.text "?)...`"
	.db 0

SCCNotFound:
	.text "SCC Initialise unsuccessful!! No SCC found...`"
	.db 0

ForceMusic:
	call InvokeByte

	ld b,a

	ld a,(MusicPlay)
	or a
	jp nz,stopNotAvail

	ld a,b

	add a,48
	ld (ForceText.1),a
	sub 48

ml.forceMusic.1:
	or a
	jp z,ForceImp

	cp 3
	jp nc,ForceImp

	sla a
	sla a
	sla a
	sla a

	ld (scc),a

	ld a,(mlMenu)
	or a
	ret nz

	DoShowText(ForceText,1)

	ret	

ForceImp:
	ld a,100
	ld ($f414),a

	ld a,(mlMenu)
	or a
	ret nz

	DoShowText(ForceWrong,1)

	ret

ForceText:
	.text "Music forced through slot "
ForceText.1:
	.db "?...`",0

ForceWrong:
	.text "Force music error: Not compatible slot given!``"
	.text "Usage: _Force(<slot>)``"
	.text "Where <slot> is the slot number you want the music to go through...`"
	.text "<slot> can be a number from 1 through 2...`"
	.db 0
	
InvokeByte:
	pop bc
	pop de
	pop hl

	push de
	push bc

	ld ix,$521c						; Read byte (tokonized BASIC)
	call $159

	pop bc
	pop de

	push hl
	push de
	push bc

	ret


SearchSCC:
	ld (SCC.StackSave),sp

	ld sp,newStack

	call SearchSCC.1

	ld sp,(SCC.StackSave)

	ret

Scc.StackSave:
	.dw 0

SearchScc.1:
; routine : Search for SCC.
; in      : none.
; out     : (scc)/16 = port where SCC is in.
; cmnt    : The search routine works as follows:
;
; First the slot is selected by changing the primairy port selections. After that a zero is
; poked at $9000 (the slot will be from $8000-$bfff). If we read it after that, and it is still
; zero, then NO SCC is found, because the SCC changes the value directly to another value. After
; that, the address $9000 is inversed (one's compliment) and then outted again, if it after that
; contains the same value as the first time that was read, then NO SCC is found. Else an SCC
; is found (because the SCC changes the value again, ofcourse).

	ld a,255
	ld (scc.prim),a
	ld (scc.sec),a

	in a,($a8)
	ld (org.prim),a

	ld a,($ffff)
	cpl
	ld (org.sec),a


	ld b,4
	ld d,0
PrimaryLoop:
	push bc	

	call SecondaryLoop

	pop bc

	jp z,SCCDone

	ld a,d
	add a,%01010000
	ld d,a

	djnz PrimaryLoop

	ld a,(org.prim)
	out ($a8),a

	ld a,(org.sec)
	ld ($ffff),a

	xor a
	ld (scc),a

	scf
	ret

SCCDone:
	ld a,(org.prim)
	out ($a8),a

	ld a,(org.sec)
	ld ($ffff),a
	
	or a
	ret

SecondaryLoop:
	ld b,4

	ld c,0
SecondaryLoop.1:
	call Check
	ret z

	ld a,c
	add a,%01010000
	ld c,a

	djnz SecondaryLoop.1

	ld a,1
	or a
	ret

Check:
; routine : Search for SCC in slot.
; in      : d - primary slot, c - secondary slot
; out     : (scc.prim) and (scc.sec) for slot.
; cmnt    : none.

	in a,($a8)					; set right slot.
	and %00001111				;
	or d						;
	out ($a8),a					;
							;
	ld a,($ffff)				;
	cpl						;
	and %00001111				;
	or c						;
	ld ($ffff),a				;


;	Check routine...

	ld a,$3f
	ld ($9000),a

	xor a
	ld ($9800),a

	ld a,($9800)
	or a
	jp nz,NoScc

	cpl
	ld ($9800),a

	ld a,($9800)
	inc a
	jp nz,NoScc
	
	ld a,($9000)

	cp $3f
	jp z,NoScc

SccFnd:
	ld a,d
	and %00110000
	ld (scc.prim),a
	ld (scc),a

	ld a,c
	and %00110000
	ld (scc.sec),a

	xor a
	ret

NoScc:
	ld a,1
	or a
	ret

org.prim:
	.db 0
org.sec:
	.db 0
scc.prim:
	.db 0
scc.sec:
	.db 0
scc:
	.db 0

#IF (SilentComp = 0)

BNTSilent:
;	DoShowText(SilentText,0)

	ld a,1
	ld (Silent),a

	ret

BNTLoud:
	DoShowText(LoudText,0)

	xor a
	ld (Silent),a

	ret

SilentText:
	.text "Silent mode set ON... No (error) messages will be shown...`"
	.db 0
LoudText:
	.text "Loud mode set ON... All (error) messages will be shown...`"
	.db 0

#EndIf

Silent:

#IF (SilentComp = 0)
	.db 0

#Else
	.db 1
#EndIf

PlayVer:
	DoShowText(VersionText,0)

	ret

VersionText:
	.text "`         SCC Blaffer NT!`"     
	.text "    (C) 1999/2000 TeddyWareZ!``" 
	.text "BASIC replay routine version "
	.db verHigh + 48, ".", verLowH + 48, verLowL + 48,"``"	

	.db 0

SBMLoad:
	call BuildFile
	jp nc,SBMLoad.1

	ld a,(Silent)
	or a
	call z,beep

	DoShowText(SBMHelp,1)

	ld a,100
	ld ($f414),a

	ret

SBMLoad.1:
	ld a,(MusicPlay)
	or a
	jp nz,NoLoadAllowed

ml.SBMLoad.1:
	call MakeFCB

	ld hl,ErrorHandler
	ld de,ErrorHandAdr+2
	ld bc,EndErrorHandler-ErrorHandler
	ldir

	ld hl,($f323)
	ld (OriginalErrHand),hl

	ld hl,ErrorHandAdr+2
	ld (ErrorHandAdr),hl

	ld hl,ErrorHandAdr
	ld ($f323),hl

	call SetMemory

	xor a
	ld (WhatMenu),a

	call LoadFile

LoadDone:
	ld hl,(OriginalErrHand)
	ld ($f323),hl

	call ResetMemory

	ret

SBKLoad:
	call BuildFile
	jp nc,SBKLoad.1

	ld a,(Silent)
	or a
	call z,beep

	DoShowText(SBKHelp,1)

	ld a,100
	ld ($f414),a

	ret

SBKLoad.1:
	ld a,(MusicPlay)
	or a
	jp nz,NoLoadAllowed

ml.SBKLoad.1:
	call MakeFCB

	ld hl,ErrorHandler
	ld de,ErrorHandAdr+2
	ld bc,EndErrorHandler-ErrorHandler
	ldir

	ld hl,($f323)
	ld (OriginalErrHand),hl

	ld hl,ErrorHandAdr+2
	ld (ErrorHandAdr),hl

	ld hl,ErrorHandAdr
	ld ($f323),hl

	call SetMemory

	ld a,1
	ld (WhatMenu),a

	call LoadFile

	jp LoadDone

	ret

NoLoadAllowed:
	DoShowText(NoLoadText,0)

	ret

NoLoadText:
	.text "Hey! Stop the music before you try to load something!`"
	.db 0

SetMemory:
	in a,($fd)
	ld (Map1.org),a

	in a,($fe)
	ld (Map2.org),a

	in a,($a8)
	ld (pr.org),a

	ld a,($ffff)
	cpl
	ld (sec.org),a

	di

	ld a,(pr.set)
	out ($a8),a

	ld a,(sec.set)
	ld ($ffff),a

	ei

	ret

ResetMemory:
; routine : return all memory states as they were.
; in      : none.
; out     : none.
; cmnt    : none.

	ld a,(Map1.org)
	out ($fd),a

	ld a,(Map2.org)
	out ($fe),a

	ld a,(Sec.org)
	ld ($ffff),a

	ld a,(Pr.org)
	out ($a8),a

	ret

InitBank:
	ld a,(WhatMenu)

	ld b,a

	ld a,(SngBnkPlay)
	ld c,a

	ld a,b

	or a
	ret z

	ld a,(InsBnkPlay)
	ld c,a

	ret

LoadFile:
	call Initbank

	ld a,c
	out ($fe),a

	ld de,fcb
	ld c,15
	call DoBdos
	jp c,LoadFileError
	or a
	jp nz,LoadFileNotFound

	ld hl,1
	ld (RecSize),hl

	ld de,$8000
	bdos(26)

	ld de,fcb
	ld hl,16
	ld c,39
	call DoBdos
	jp c,LoadFileError
	or a
	jp nz,LoadFileIncorrect

	ld a,(WhatMenu)
	sla a
	sla a
	sla a
	sla a

	ld e,a
	ld d,0
	ld hl,FileHeaders
	add hl,de
	ld de,$8000

	ld a,16
	call CompareStrings

	jp z,LoadFileOk

	ld a,100
	ld ($f414),a

	ld a,(MlMenu)
	or a
	ret nz

	DoShowText(LoadErrorText7, 1)	

	ret

LoadFileOk:
	ld a,(WhatMenu)
	or a
	jp z,LoadSong

	jp LoadInsKit

LoadInsKit:
	ld de,$8000
	bdos(26)

	ld hl,16384
	ld de,fcb
	ld c,39
	call DoBdos
	jp c,LoadFileError
	or a
	jp nz,LoadFileIncorrect

	jp LoadFileDone


LoadSong:
	ld hl,PatternData						; Clear Song data (only pattern data)
	ld de,PatternData+1
	ld bc,83*192-1
	ld (hl),0
	ldir

	ld de,$8000
	bdos(26)

	ld hl,448
	call ReadFile						; Load Init Bytes of song.

	ld de,SongPatsToSave
	bdos(26)

	ld hl,1
	call ReadFile						; Number of patterns to load		

	ld a,(SongPatsToSave)
	ld b,a
LoadSong.1:
	ld a,b
	ld (SongPatsToSave),a

	ld de,SongPatAdrToSave
	bdos(26)

	ld hl,2
	call ReadFile						; Get address to store pattern data in

	ld a,(SongPatAdrToSave)
	ld e,a
	ld a,(SongPatAdrToSave+1)
	ld d,a
	bdos(26)							; Set Read address to pattern data.

	ld hl,192
	call ReadFile						; Read Pattern

	ld a,(SongPatsToSave)
	ld b,a

	djnz LoadSong.1						; Repeat until song is loaded.

	jp LoadFileDone

LoadFileDone:
	ld de,fcb
	ld c,16
	call DoBdos
	jp c,LoadFileError
	or a
	jp nz,LoadFileIncorrect

	ret

ReadFile:
	ld de,fcb
	ld c,39
	call DoBdos

	pop bc
	jp c,LoadFileError
	or a
	jp nz,LoadFileIncorrect
	push bc

	ret


CompareStrings:
; routine : Compare 2 strings.
; in      : DE - Pointer to first string, HL - Pointer to second string, A - length of string
; out     : Z if identical, NZ if not.
; cmnt    : none.
	ld b,a

CompareStringsLoop:
	ld a,(de)
	cp (hl)
	ret nz

	inc hl
	inc de

	djnz CompareStringsLoop

	xor a
	ret

WhatMenu:
	.db 0
MlMenu:
	.db 0

LoadFileIncorrect:
	ld hl,LoadErrorText4

	jp LoadErrorFound

LoadFileNotFound:
	ld hl,LoadErrorText3

	jp LoadErrorFound

LoadFileError:
	ld hl,LoadErrorText1

	ld a,($f414)
	cp Err_DiskOffline
	jp z,LoadErrorFound

	ld hl,LoadErrorText2

	cp Err_DiskIOError
	jp z,LoadErrorFound

	ld hl,LoadErrorText5
LoadErrorFound:
	ld a,100
	ld ($f414),a

	ld a,(MlMenu)
	or a
	ret nz

	ld a,1
	call ShowText

	ld a,(silent)
	or a
	call z,beep

	ret
	

LoadErrorText1:
	.text "SCC Blaffer NT - Load error: Disk offline!`"
	.db 0
LoadErrorText2:
	.text "SCC Blaffer NT - Load error: Disk I/O Error!`"
	.db 0
LoadErrorText3:
	.text "SCC Blaffer NT - Load error: File not found!`"
	.db 0
LoadErrorText4:
	.text "SCC Blaffer NT - Load error: File not loaded (completely)...`"
	.db 0
LoadErrorText5:
	.text "SCC Blaffer NT - Load error: Unknown!`"
	.db 0
LoadErrorText6:
	.text "SCC Blaffer NT - Load error: This file ain't no song!`"
	.db 0
LoadErrorText7:
	.text "SCC Blaffer NT - Load error: This file ain't no instrument kit!`"
	.db 0
	;      12345678901234567890123456789012345678901234567890123456789012345678901234567890

FileHeaders:
;	       1234567890123456
	.text "Blaf NT Song    "
	.text "Blaf NT Ins Kit "

MakeFCB:
	ld hl,fcb
	ld de,fcb+1
	ld bc,EndFcb-fcb-1
	ld (hl),0
	ldir

	ld hl,Drive
	ld de,FCB
	ld bc,12
	ldir

	ret

BuildFile:
	pop bc
	pop de
	pop hl

	push bc
	push de

	ld	ix,04c64h
	call	$159

	pop de
	pop bc

	push hl
	push de
	push bc

	ld	ix,067d0h					; get filename
	call	$159

	push hl
	pop ix

	ld a,(ix+0)
	ld (StringLength),a

	ld	l,(ix+1)
	ld	h,(ix+2)					; pointer to start of string

	push hl
	pop ix						; IX Now has the address which contains the name

	ld a,(StringLength)
	or a
	jp z,NoFileGiven

	push ix

	bdos(get_ddn)
	ld (Drive),a

	pop ix


	ld a,(ix+1)
	cp 58
	call z,OtherDrive

	ld a,(StringLength)
	or a
	jp z,NoFileGiven

	ld hl,FileName
	ld de,FileName+1
	ld bc,10
	ld (hl),63
	ldir

	ld b,8

	ld hl,FileName
FileName_Name:
	ld a,(ix+0)
	cp 46
	jp z,CheckExtension

	ld (hl),a

	ld a,(StringLength)
	dec a
	ld (StringLength),a

	or a
	jp z,FileBuildComplete

	inc ix
	inc hl

	djnz FileName_Name	

	ld a,(ix+0)
	cp 46
	jp z,CheckExtension

	DoShowText(NameTooLong,1)

	scf
	ret
	
CheckExtension:
	ld a,(StringLength)
	dec a
	ld (StringLength),a

	or a
	jp z,FileBuildComplete

	cp 4
	jp c,ExtensionOk

	DoShowText(ExtTooLong,1)

	scf
	ret

ExtensionOk:
	ld hl,FileName+8
	inc ix

	ld b,3
FileName_Ext:
	ld a,(ix+0)
	ld (hl),a

	ld a,(StringLength)
	dec a
	ld (StringLength),a

	or a
	jp z,FileBuildComplete

	inc ix
	inc hl

	djnz FileName_Ext

FileBuildComplete:
	or a
	ret

StringLength:
	.db 0

OtherDrive:
	ld a,(ix+0)
	cp 97
	jp c,OtherDriveOk

	sub 32

OtherDriveOk:
	sub 64

	ld (drive),a

	ld a,(StringLength)
	dec a
	dec a
	ld (StringLength),a

	inc ix
	inc ix

	ret

NoFileGiven:
	DoShowText(NoFileText,1)

	scf
	ret

NameTooLong:
	.text "SCC Blaffer NT - Load error: Specified name too long!`"
	.db 0
ExtTooLong:
	.text "SCC Blaffer NT - Load error: Specified extension too long!`"
	.db 0
NoFileText:
	.text "SCC Blaffer NT - Load error: No filename specified!`"
	.db 0

SBMHelp:
	.text "`Usage: CALL SBMLOAD (\"[D:]FileName.Ext\")``"
	.text "[] means that it is optional...`"
	.text "D        - Drive name     (max. 1 character)`"
	.text "FileName - File name      (max. 8 characters)`"
	.text "Ext      - File extension (max. 3 characters)``"
	.text "When no drive is specified, the current drive will be used...`"
	.db 0

SBKHelp:
	.text "`Usage: CALL SBKLOAD (\"[D:]FileName.Ext\")``"
	.text "[] means that it is optional...`"
	.text "D        - Drive name     (max. 1 character)`"
	.text "FileName - File name      (max. 8 characters)`"
	.text "Ext      - File extension (max. 3 characters)``"
	.text "When no drive is specified, the current drive will be used...`"
	.db 0

Drive:
	.db 0
FileName:
	.ds 11

ShowText:
; routine : Show text on screen
; in      : HL - pointer to text, a - way (0 = Show always, 1 = Only show in loud mode)
; out     : none.
; cmnt    : Text has to terminated with chr(0)!

	or a
	jp z,ShowText.1

	ld a,(Silent)
	or a
	ret nz

ShowText.1:
	ld a,(hl)
	or a
	ret z

	cp 96
	jp z,DoEnter

	call chput

EnterDone:
	inc hl

	jp ShowText.1

DoEnter:
	push hl

	ld hl,EnterText

	ld b,4
DoEnter.1:
	ld a,(hl)

	call chput

	inc hl

	djnz DoEnter.1

	pop hl

	jp EnterDone

EnterText:
	.db 27,75,$0d,$0a

ErrorHandler:
	ld a,c
	and %00001110

	ld ($f414),a

	ld a,(PrimairPageSave)
	out ($a8),a
	ld a,(SecondarePageSave)
	ld ($ffff),a

	ld sp,(StackSave)

	scf
	ret
EndErrorHandler:

DoBdos:
	in a,($a8)
	ld (PrimairPageSave),a

	ld a,($ffff)
	cpl
	ld (SecondarePageSave),a

	ld (StackSave),sp
	call bdos_call

	or a
	ret

OriginalErrHand:
	.dw 0

; replay rout from here

InitReplay:
; routine : Initialise memory mapper for replaying
; in      : (scc) - SCC Slot
; out     : none
; cmnt    : none.
	
	ld a,($f342)
	and %00000011

	ld b,a

	sla a
	sla a

	sla b
	sla b
	sla b
	sla b

	or b

	ld b,a

	in a,($a8)
	and %11000011

	or b

	and %11001111
	ld b,a

	ld a,(scc)								; get SCC Slot
	or b
	ld (SccSlot),a

	ret

startMusic:
; routine : Start music replay
; in      : none.
; out     : none.
; cmnt    : This rout. does it all.. after this you hear music! (after d-fader has coded the
;           routines, ofcourse, but I think he has done it, because else you wouldn't be 
;		reading this, exept if d-fader dies, and somebody (I don't know why though) decides
;		to continue coding this damn project... (Y'know, I type this because of the fact
;		I don't want to start coding the replayer, 'cause it's so damn irritating to code!))
;		(and it's also hard/much... ;))

	ld a,(MusicPlay)
	or a
	jp nz,stopNotAvail

ml.startMusic.1:
	call InitReplay

	ld a,255
	ld (NewPSG),a

	ld a,15
	ld (PSGMaxVol),a

	ld a,16
	ld (PSGPlayRow),a

	in a,($fe)
	ld (map2.org),a

	ld a,(SngBnkPlay)
	out ($fe),a

	ld a,255
	ld (SngPos),a

	xor a
	ld (LastPosDone),a

	ld a,15
	ld (SngRow),a

	ld a,(InitialTempo)
	ld b,a
	ld a,26
	sub b
	
	ld (SngTmp),a

	xor a
	ld (TmpCount),a

	ld hl,DataBlocks.start
	ld de,DataBlocks.start+1
	ld bc,DataBlocks.end-DataBlocks.start-1
	ld (hl),0
	ldir

	ld hl,SngFreqs	
	ld de,SngFreqs+1
	ld bc,9
	ld (hl),0
	ldir

	call SetSCC

	ld hl,SngFreqs
	ld de,$9880
	ld bc,10
	ldir	

	ld a,%00011111
	ld ($988f),a

	call ResetSCC

	ld a,3
	ld (Block.Modulate),a

	ld hl,StartInstruments
	ld de,Block.LastInstruments
	ld bc,4
	ldir

	ld hl,StartVolumes
	ld de,SngVolumes
	ld bc,5
	ldir

	ld hl,VolumeSlideSettings
	ld de,Block.AutoSlide
	ld bc,5
	ldir

	ld hl,DetuneSettings
	ld de,Detune
	ld bc,5
	ldir

	ld hl,$9800
	ld (SaveInsAdr),hl

	ld b,4
	ld hl,Block.LastInstruments
StartMusic.1:
	push bc
	push hl

	ld a,(SngBnkPlay)
	out ($fe),a

	ld a,(hl)
	inc a
	ld b,a

	ld hl,$8000-32
	ld de,40
StartMusic.2:
	add hl,de

	djnz StartMusic.2

	ld a,(InsBnkPlay)
	out ($fe),a

	ld de,InstrumentChange
	ld bc,32
	ldir

	call SetSCC

	ld hl,(SaveInsAdr)
	ld de,InstrumentChange

	ex de,hl

	ld bc,32

	ldir

	ex de,hl

	ld (SaveInsAdr),hl

	call ResetSCC

	pop hl
	pop bc
	
	inc hl

	djnz StartMusic.1

	ld a,(SngBnkPlay)
	out ($fe),a

	ld a,1
	ld (MusicPlay),a

	ld hl,$fd9f
	ld de,OldPlayInt
	ld bc,5
	ldir

	ld a,($f342)
	ld (RepInt.slot),a

	ld hl,RepInt.start
	ld de,RepInterrupt
	ld bc,RepInt.end-RepInt.start
	ldir

	ld a,$c9
	ld ($fd9f),a

	ld hl,IntCode+4
	ld de,$fd9f+4
	ld bc,5
	lddr

	ld a,(map2.org)
	out ($fe),a

	ret

StopMusic:
; routine : Stop music
; in      : none.
; out     : none.
; cmnt    : none.

	ld a,(MusicPlay)
	or a
	jp z,playNotAvail

ml.StopMusic.1:
	xor a
	ld (MusicPlay),a

	ld a,$c9
	ld ($fd9f),a

	ld hl,OldPlayInt+4
	ld de,$fd9f+4
	ld bc,5
	lddr

	call SetSCC

	xor a
	ld ($988f),a

	call ResetSCC

	call PSG.StopSound

	ret

PSG.StopSound:
	ld a,16
	ld (PSGPlayRow),a

	ld d,%10111111
	OutPSG(7)

	ret

HaltMusic:
	ld a,(MusicPlay)
	cp 1
	jp nz,playNotAvail

ml.HaltMusic.1:
	ld a,2
	ld (MusicPlay),a

	call PSG.StopSound

	ret

ContMusic:
	ld a,(MusicPlay)
	cp 2
	jp nz,pauseNotAvail

ml.ContMusic.1:
	call SetSCC

	ld a,%00011111
	ld ($988f),a

	call ResetSCC

	ld a,1
	ld (MusicPlay),a

	ret

SetScc:
	in a,($a8)
	ld (SaveSetSCC),a

	ld a,(SccSlot)
	out ($a8),a

	ld a,$3f
	ld ($9000),a

	xor a
	ld ($98e0),a

	ret

ResetSCC:
	ld a,(SaveSetSCC)
	out ($a8),a

	ret

SaveSetSCC:
	.db 0

PlayInt:
	ld a,(MusicPlay)
	or a
	jp z,NoMusicPlay
	cp 2
	jp z,NoMusicPlay

	xor a
	ld (MusicPeak),a

	ld a,($ffe8)
	bit 1,a
	jp nz,NoHertzEqualizer

	ld a,(HertzCount)
	or a
	jp nz,NoHertzAdjust

	ld a,5
	ld (HertzCount),a

	jp EndPlayInt

NoHertzAdjust:	
	dec a
	ld (HertzCount),a

NoHertzEqualizer:
	ld a,(TmpCount)
	or a
	jp nz,NoNewRow

; --- new row code ---
NewRow:
	ld a,1
	ld (MusicPeak),a

	ld a,(SngBnkPlay)
	out ($fe),a

	ld a,(SngTmp)
	ld (TmpCount),a

	ld a,(LastRowPlayed)
	or a
	jp nz,NewPosition

	ld a,(SngRow)
	inc a
	cp 16
	jp z,NewPosition

	ld (SngRow),a

	ld hl,(NowAddress)
	ld de,12
	add hl,de
	ld (NowAddress),hl

NewRowDone:
; --- Remove all pitch bend 2 data ---

	ld hl,Block.Pitch
	ld b,5
Clear.Pitch2:
	ld a,(hl)
	bit 2,a
	jp z,Clear.Pitch2.done

	ld (hl),0
Clear.Pitch2.done:
	inc hl
	inc hl

	djnz Clear.Pitch2

	ld hl,(NowAddress)
	ld de,10
	add hl,de

; --- Check PSG channel ---
	ld a,(newPSGStyle)
	or a
	jp nz,PSGChannelDone

	ld a,(hl)
	ld (RepCommand+5),a

	or a
	jp z,PSGChannelDone

	dec a
	ld (NewPSG),a
PSGChannelDone:
; --- Check command channel ---

	inc hl

	ld a,(hl)
	ld (RepCommand+6),a

	or a
	jp z,CheckCommandChannelDone

	cp 26
	jp c,ComC.ChangeTempo

	cp 26
	jp z,ComC.EndOfPat

	cp 40
	jp c,ComC.ChangeTransPose

ComC.ChangePMV:
	sub 40

	ld (PSGMaxVol),a

	jp CheckCommandChannelDone

ComC.ChangeTransPose:
	sub 33
	ld (Block.Transpose),a

	jp CheckCommandChannelDone

ComC.EndOfPat:
	ld a,1
	ld (LastRowPlayed),a

	jp CheckCommandChannelDone

ComC.ChangeTempo:
	ld b,a
	ld a,26
	sub b
	ld (SngTmp),a
	ld (TmpCount),a

	jp CheckCommandChannelDone


CheckCommandChannelDone:
; --- Do all Autoslides ---

	ld de,Block.AutoSlide
	ld hl,Block.VolumeSlides

	ld b,5
AS.loop1:
	push bc

	ld a,(de)

	ld c,a

	cp $10
	jp z,AS.NotOn

	set 5,a
AS.NotOn:
	and $f0
	ld (hl),a

	ld a,(SngTmp)
	inc a
	ld b,a

	ld a,c
	and %00011111

	cp $10
	jp nc,AS.Add

	ld c,a
	ld a,$10
	sub c

AS.Add:
	and $0f

; a - correcte slide value (15)
; b - correcte tempo       (16)

	ld c,0
AS.loop2:
	inc c
	sub b
	jp nc,AS.loop2

	add a,b

; a = 15
; c = 1

; a - number of interrupts to do.
; c - number of volume steps per interrupt.

	ld b,a
	ld a,c

	or (hl)					; Add all other shit to value to slide per interrupt
	ld (hl),a					; Set that in HL.

	inc hl

	ld (hl),b					; Set how much interrupts to slide in hl

	pop bc

	inc hl					; Next volume slide channel
	inc de					; Next auto slide channel

	djnz AS.loop1	


; --- alle data die nodig voor een nieuwe row komt hier! ---

	ld ix,SngVolumes
	ld iy,RepCommand

	ld hl,(NowAddress)
	ex de,hl
	ld hl,SngFreqs
	ld b,5
CheckCommand.1:
	push hl
	push bc

	ld a,(de)
	ld (iy),a

	or a
	jp z,CC.OutNewVolume

	cp 97
	jp c,CC.OutNewFreq

	cp 97
	jp z,CC.OffEvent

	cp 98
	jp z,CC.ChangeInstrument

	cp 99
	jp z,CC.Pitch1UpEvent

	cp 100
	jp z,CC.Pitch1DownEvent

	cp 101
	jp z,CC.Pitch2UpEvent

	cp 102
	jp z,CC.Pitch2DownEvent

	cp 103
	jp z,CC.ModulateUpEvent

	cp 104
	jp z,CC.ModulateDownEvent

	cp 105
	jp z,CC.DetuneUp

	cp 106
	jp z,CC.DetuneDown

	cp 107
	jp z,CC.VolSlide.Up

	cp 108
	jp z,CC.VolSlide.Down

	cp 109
	jp z,CC.AutoSlide.Up

	cp 110	
	jp z,CC.AutoSlide.Down

CC.done:
	pop bc
	pop hl

	inc hl
	inc hl

	inc de
	inc de

	inc ix

	inc iy

	djnz CheckCommand.1

	jp PlayContinue

CC.ChangeInstrument:
	ld a,5
	sub b

	cp 4
	jp z,CC.Done

	push af

	sla a
	sla a
	sla a
	sla a
	sla a
	ld c,a
	ld b,0
	ld hl,$9800
	add hl,bc

	ld (SaveInsAdr),hl

;	---- remove!!!! ----
;	pop af
;	jp CC.Done
;	---- remove!!!! ----

	pop af

	ld c,a
	ld b,0
	ld hl,Block.LastInstruments
	add hl,bc

	ld a,(hl)
	ld b,a

	inc de
	ld a,(de)
	dec de

	cp b
	jp z,CC.Done

	cp 207
	jp nc,CC.Done

	ld (hl),a

	inc a
	ld b,a

	push de

	ld hl,$8000-32
	ld de,40
CC.CI.1:
	add hl,de

	djnz CC.CI.1

	ld a,(InsBnkPlay)
	out ($fe),a

	ld de,InstrumentChange
	ld bc,32
	ldir

	call SetSCC

	ld hl,(SaveInsAdr)
	ld de,InstrumentChange
	ex de,hl
	ld bc,32
	ldir

	call ResetSCC

	ld a,(SngBnkPlay)
	out ($fe),a

	pop de

	jp CC.Done

CC.ModulateUpEvent:
	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0

	ld hl,Block.Pitch						; Remove pitch bend data
	add hl,bc							;
	ld (hl),0							;

	ld hl,Block.ModulateData
	add hl,bc

	ld (hl),%00000011

	inc de
	ld a,(de)
	dec de

	inc hl

	ld (hl),a

	jp CC.Done

CC.ModulateDownEvent:
	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0

	ld hl,Block.Pitch						; Remove pitch bend data
	add hl,bc							;
	ld (hl),0							;

	ld hl,Block.ModulateData
	add hl,bc
	
	ld (hl),%00000010

	inc de
	ld a,(de)
	dec de

	inc hl

	ld (hl),a

	jp CC.Done


CC.Pitch2UpEvent:
	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0

	ld hl,Block.ModulateData				; Remove modulate
	add hl,bc							;
	ld (hl),0							;

	ld hl,Block.Pitch
	add hl,bc
	
	ld (hl),%00000111						; pitch 2, pitch on, pitch up

	jp CC.Pitch2.Calculate

CC.Pitch2DownEvent:
	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0

	ld hl,Block.ModulateData				; Remove modulate
	add hl,bc							;
	ld (hl),0							;

	ld hl,Block.Pitch
	add hl,bc
	
	ld (hl),%00000110						; pitch 2, pitch on, pitch down

	jp CC.Pitch2.Calculate

CC.Pitch2.Calculate:
	inc hl

	ld a,(SngTmp)
	inc a
	ld b,a
	ld c,0

	inc de
	ld a,(de)
	dec de

CC.P2.calc.1:
	sub b

	inc c

	jp nc,CC.P2.calc.1

	dec c

	ld (hl),c

	jp CC.Done



CC.Pitch1UpEvent:
	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0

	ld hl,Block.ModulateData				; Remove modulate
	add hl,bc							;
	ld (hl),0							;

	ld hl,Block.Pitch
	add hl,bc
	
	ld (hl),%00000011						; pitch 1 pitch on, pitch up

	inc hl

	inc de
	ld a,(de)
	dec de

	or a
	jp z,CC.Pitch1Off

	ld (hl),a

	jp CC.Done

CC.Pitch1Off:
	dec hl
	ld (hl),0

	jp cc.done

CC.Pitch1DownEvent:
	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0

	ld hl,Block.ModulateData				; Remove modulate
	add hl,bc							;
	ld (hl),0							;

	ld hl,Block.Pitch
	add hl,bc

	ld (hl),%00000010						; pitch 1, pitch on, pitch down

	inc hl

	inc de
	ld a,(de)
	dec de

	ld (hl),a

	jp CC.Done

CC.DetuneUp:
	ld a,5
	sub b

	ld c,a
	ld b,0
	ld hl,Detune
	add hl,bc

	inc de
	ld a,(de)
	dec de

	or 128
	ld (hl),a

	jp CC.Done

CC.DetuneDown:
	ld a,5
	sub b

	ld c,a
	ld b,0
	ld hl,Detune
	add hl,bc

	inc de
	ld a,(de)
	dec de

	and 127

	ld b,a
	ld a,128
	sub b

	ld (hl),a

	jp CC.Done


CC.VolSlide.Up:
	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0
	ld hl,Block.VolumeSlides
	add hl,bc

	ld a,%00110000
	;     76543210

	jp CC.CreateVolSlide

CC.VolSlide.Down:
	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0
	ld hl,Block.VolumeSlides
	add hl,bc

	ld a,%00100000

CC.CreateVolSlide:
	ld (hl),a

	ld a,(SngTmp)
	inc a
	ld b,a

	inc de
	ld a,(de)
	dec de
	and $0f	


; a - correcte slide value (15)
; b - correcte tempo       (16)

	ld c,0
VS.loop2:
	inc c
	sub b
	jp nc,VS.loop2

	add a,b

; a - number of interrupts to do.
; c - number of volume steps per interrupt.

	ld b,a
	ld a,c

	or (hl)					; Add all other shit to value to slide per interrupt
	ld (hl),a					; Set that in HL.

	inc hl

	ld (hl),b					; Set how much interrupts to slide in hl

	jp CC.Done

CC.AutoSlide.Up:
	ld a,5
	sub b
	ld c,a
	ld b,0
	ld hl,Block.AutoSlide
	add hl,bc

	inc de

	ld a,(de)

	dec de

	and $0f
	or $10

	ld (hl),a

	jp CC.done

CC.AutoSlide.Down:
	ld a,5
	sub b
	ld c,a
	ld b,0
	ld hl,Block.AutoSlide
	add hl,bc

	inc de

	ld a,(de)

	dec de

	and $0f

	ld b,a
	ld a,$10

	sub b

	ld (hl),a

	jp CC.Done	

CC.OffEvent:
	ld (hl),0
	inc hl
	ld (hl),0

	ld a,5
	sub b

	sla a

	ld c,a
	ld b,0

	ld hl,Block.Pitch						; Remove pitch bend
	add hl,bc							;
	ld (hl),0							;

	ld hl,Block.ModulateData				; Remove modulate
	add hl,bc							;
	ld (hl),0							;


	jp cc.done


CC.OutNewVolume:
	inc de
	ld a,(de)
	dec de
	and $0f
	jp z,CC.Done

	ld (ix),a

	jp CC.Done

CC.OutNewFreq:
	push af

	ld a,b

	exx

	ld b,a
	ld a,5
	sub b
	ld e,a
	ld d,0
	ld hl,Detune
	add hl,de

	ld a,(hl)	
	ld (NowDetune),a

	exx 

	inc de
	ld a,(de)
	dec de
	
	exx 

	and $f0
	jp nz,CC.NoPitchRemove

	ld hl,Block.Pitch						; Remove pitch bend
	sla e								;
	add hl,de							;
	ld (hl),0							;

	ld hl,Block.ModulateData				; Remove modulate
	add hl,de							;
	ld (hl),0							;

CC.NoPitchRemove:
	exx

	pop af

	ld b,a

	ld a,(Block.Transpose)
	add a,b
	ld b,a

	cp 97
	jp c,TransposeOk

	ld b,96
TransposeOk:
	inc de

	ld a,(de)
	and $0f
	ld (ix),a

	dec de

	ld a,b

	or a
	jp z,cc.done

	exx

	dec a
	sla a
	ld e,a
	ld d,0
	ld hl,FreqData.start
	add hl,de

	ld c,(hl)
	inc hl
	ld b,(hl)

	ld l,c
	ld h,b

	ld de,0

	ld a,(NowDetune)
	cp 128
	jp z,DetuneSelected

	ld d,255

	and $7f

	cpl
	inc a

	ld e,a

	ld a,(NowDetune)

	bit 7,a
	jp nz,DetuneSelected	

	ld b,a

	ld d,0
	ld a,128
	sub b
	ld e,a
DetuneSelected:
	add hl,de

	ld c,l
	ld b,h

	push bc

	exx

	pop bc

	ld (hl),c
	inc hl
	ld (hl),b

	jp CC.done

NowDetune:
	.db 0

NewPosition:
	xor a
	ld (LastRowPlayed),a

	ld a,(LastPosDone)
	or a
	jp nz,DoLoopSong

	ld a,(SngPos)
	inc a
	ld b,a
	ld a,(LastPos)
	cp b
	jp nz,NotLastPos

	ld a,1
	ld (LastPosDone),a

NotLastPos:
	xor a
	ld (SngRow),a

	ld a,b
	ld (SngPos),a

	ld hl,Patterns
	ld e,a
	ld d,0
	add hl,de

	ld b,(hl)

	inc b

	ld hl,Patterndata-192
	ld de,192
NewPosition.1:
	add hl,de

	djnz NewPosition.1

	ld (NowAddress),hl

	jp NewRowDone

DoLoopSong:
	xor a
	ld (LastPosDone),a

	ld a,(LoopPos)
	or a
	jp z,DoLoopSong.1

PlayPattern.stop:
	call stopMusic

	jp PlayIntDone

DoLoopSong.1:
	ld a,(LoopPos+1)

	dec a
	ld (SngPos),a

	jp NewPosition


NoNewRow:
	dec a
	ld (TmpCount),a
	
PlayContinue:
; --- continue player ongein ---


; --- out all volume slides ---

;	ld a,(MusicPeak)
;	or a
;	jp nz,PC.NoVolumeSlide

	ld hl,Block.VolumeSlides
	ld de,SngVolumes
	ld b,5
OVS.loop1:
	push hl
	push bc

	inc hl

	ld a,(hl)
	or a
	jp z,OVS.loop1.done

	dec (hl)

	dec hl

	ld a,(hl)
	bit 5,a
	jp z,OVS.loop1.done 

	bit 4,a
	jp z,OVS.SlideDown

OVS.SlideUp:
	and $0f
	inc a

	ld b,a

	ld a,(de)
	add a,b

	cp 15
	jp z,OVS.NoAdjustUp
	jp c,OVS.NoAdjustUp

	ld a,15
OVS.NoAdjustUp:
	ld (de),a

	jp OVS.loop1.done

OVS.SlideDown:
	and $0f
	inc a

	ld b,a

	ld a,(de)
	sub b

	jp nc,OVS.NoAdjustDown

	xor a
OVS.NoAdjustDown:
	ld (de),a

OVS.loop1.done:
	pop bc
	pop hl

	inc hl
	inc hl

	inc de

	djnz OVS.loop1


PC.NoVolumeSlide:

; --- Pitch slide 1 and 2 ---

	ld de,Block.Pitch
	ld hl,SngFreqs
	ld b,5
Pitch.1:
	push bc
	push de
	push hl

	ld a,(de)
	bit 1,a
	jp z,Pitch.ChanDone

	ex af,af'

	inc de
	ld a,(de)

	ld b,255

	cpl
	inc a
	ld c,a

	ex af,af'

	bit 0,a
	jp nz,Pitch.Selected

	ld a,(de)
	ld c,a
	ld b,0
Pitch.Selected:
	ld e,(hl)
	inc hl
	ld d,(hl)

	ex de,hl

	add hl,bc

	ex de,hl

	ld (hl),d
	dec hl
	ld (hl),e

Pitch.ChanDone:
	pop hl
	pop de
	pop bc

	inc hl
	inc hl

	inc de
	inc de

	djnz Pitch.1

; --- Modulate ---
	ld a,(Block.Modulate)
	dec a
	ld (Block.Modulate),a

	jp nz,NoModulateExecution

	ld a,3
	ld (Block.Modulate),a

	ld de,Block.ModulateData
	ld hl,SngFreqs
	ld b,5
PC.Modulate.1:
	push bc
	push de

	ld a,(de)
	bit 1,a
	jp z,PC.Modulate.1.NoMod

	push hl

	ld c,(hl)
	inc hl
	ld b,(hl)

	ld l,c
	ld h,b

	bit 0,a
	jp z,PC.Modulate.1.Subst

	xor 1
	ld (de),a

	inc de
	ld a,(de)

	ld e,a
	ld d,0

	or a
	sbc hl,de
PC.Modulate.1.Done:
	ld c,l
	ld b,h

	pop hl

	ld (hl),c
	inc hl
	ld (hl),b
	dec hl
PC.Modulate.1.NoMod:
	pop de
	pop bc

	inc de
	inc de

	inc hl
	inc hl

	djnz PC.Modulate.1

	jp NoModulateExecution

PC.Modulate.1.Subst:
	xor 1
	ld (de),a

	inc de
	ld a,(de)

	ld e,a
	ld d,0

	add hl,de

	jp PC.Modulate.1.Done
	

NoModulateExecution:
; --- all of the replaying done, so out all volumes and frequencies to the SCC ---

	call SetSCC

	ld de,SngFreqs
	ld hl,Block.LastFreqs
	ld ix,$9880
	ld b,5
OutFreqSCC.1:
	ld a,(de)
	cp (hl)
	jp nz,OutFreqSCC.2

	inc de
	ld a,(de)
	dec de

	inc hl
	cp (hl)
	dec hl

	jp nz,OutFreqSCC.2

OutFreqSCC.3:
	inc de
	inc de

	inc hl
	inc hl

	inc ix
	inc ix

	djnz OutFreqSCC.1

	ld a,(musicFade)
	or a
	jp nz,doFadeMusic

fadeMusicComplete:
	ld de,SngVolumes
	ld hl,Block.LastVolumes
	ld ix,$988a
	ld b,5
OutVolSCC.1:
	ld a,(de)
	cp (hl)
	jp z,OutVolSCC.2

	ld (hl),a
	ld (ix+0),a

OutVolSCC.2:
	inc de

	inc hl

	inc ix

	djnz OutVolSCC.1

	call ResetSCC

EndPlayInt:
	ld a,(InsBnkPlay)
	out ($fe),a

	call DoPSG

PlayIntDone:
	ret

doFadeMusic:
	ld a,(fadeCount.2)
	or a
	jp z,newFade

	dec a
	ld (fadeCount.2),a

	jp newfadeDone

newFade:
	ld a,(fadingSpeed)
	ld (fadeCount.2),a

	ld a,(fadeCount.1)
	dec a
	ld (fadeCount.1),a

	or a
	jp nz,newFadeDone

	call stopMusic

	jp playIntDone

newFadeDone:
	ld hl,sngVolumes
	ld b,5

	ld a,(fadeCount.1)
	ld c,a

newFade.1:
	ld a,(hl)
	cp c
	jp c,newFade.ok

	ld (hl),c
newFade.ok:
	inc hl

	djnz newFade.1

	jp fadeMusicComplete	

doFadeMusicPSG:
	ld hl,PSGVolume
	ld b,3

	ld a,(fadeCount.1)
	add a,7

	cp 15
	jp c,fadePSGOk

	ld a,15

fadePSGOk:
	ld c,a

psgFade.1:
	ld a,(hl)
	cp c
	jp c,psgFade.ok

	ld (hl),c
psgFade.ok:
	inc hl

	djnz psgFade.1

	ret

OutFreqSCC.2:
	ld a,(de)
	ld (hl),a
	ld (ix+0),a

	inc de
	ld a,(de)

	ld (ix+1),a

	inc hl
	ld (hl),a
	dec hl

	dec de	

	jp OutFreqSCC.3

NoMusicPlay:
	call SetSCC

	xor a
	ld ($988f),a

	call ResetSCC

	jp PlayIntDone

;--- replayer data blocks ---

PitchSave:
	.db 0
HertzCount:
	.db 0
TmpCount:
	.db 0
NowAddress:
	.dw 0
Detune:								; current detune settings
	.ds 5
LastPosDone:
	.db 0

InstrumentChange:
	.ds 32
SaveInsAdr:
	.dw 0

; --- these need to be behind eachother!!! ---

DataBlocks.start:

LastRowPlayed:
	.db 0

Block.Transpose:
	.db 0

Block.LastFreqs:
	.ds 10

Block.LastVolumes:
	.ds 5

Block.LastInstruments:
	.ds 4

Block.Pitch:
; byte 1:	bit 2: Which pitch slide?? 0 = Pitch slide 1, 1 = Pitch Slide 2
;		bit 1: Pitch slide ? on (1) or off (0)
;		bit 0: How to slide: up (1) or down (0)
;
; byte 2:	How much to slide per interrupt ($01-$ff)

	.ds 10

Block.ModulateData:
; byte 1:	bit 1: Modulate ? on (1) or off (0)
;		bit 0: How to modulate: up (1) or down (0)
;
; byte 2:	How much to slide per 3 interrupts

	.ds 10

Block.Modulate:
	.db 0				; modulate is executed once per 3 interrupts.

Block.VolumeSlides:
; byte 1:	bit   5: Volume slide on (1) or off (0)			(channel 1)
;      	bit   4: How to slide: up (1) or down (0)			(channel 1)
;		bit 3-0: How much to slide per interrupt			(channel 1)
;
; byte 2:	counter: How much interrupts have to be slided?		(channel 1)
;
; byte 3:   see byte 1								(channel 2)
; byte 4:	see byte 2								(channel 2)
;
; etc. (in total 10 bytes)

	.ds 10

Block.Autoslide:
; These are slightly different then the normal VolumeSlides. Autoslides will be executed (if set
; on, that is) every row by copying these Autoslides to the normal slide block. If (after that)
; a norml slide (VS) may occur, then that slide is done. So, the Autoslides have less influence
; on the playing routine as the normal Volume slides.

	.ds 5

musicFade:
	.db 0

fadeCount.1:
	.db 0
fadeCount.2:
	.db 0

volValues:
	.ds 5
fadingSpeed:
	.db 0

DataBlocks.end:

; --- till here ---

FreqData.start:
        .dw 3421,3228,3047,2876,2715,2562,2419,2283,2155,2034,1920,1812		; c 1 - b 1
        .dw 1711,1614,1524,1438,1358,1281,1210,1142,1078,1017,0960,0906		; c 2 - b 2
        .dw 0855,0807,0762,0719,0679,0641,0605,0569,0539,0509,0480,0453		; c 3 - b 3
        .dw 0428,0404,0381,0360,0339,0320,0302,0285,0269,0254,0240,0227		; c 4 - b 4
        .dw 0214,0202,0190,0180,0170,0160,0151,0143,0135,0127,0120,0113		; c 5 - b 5
        .dw 0107,0101,0095,0090,0085,0080,0076,0071,0067,0064,0060,0057		; c 6 - b 6
        .dw 0053,0050,0048,0045,0042,0040,0038,0036,0034,0032,0030,0028		; c 7 - b 7
        .dw 0027,0025,0024,0022,0021,0020,0019,0018,0017,0016,0015,0014		; c 8 - b 8
FreqData.end:

;--------- PSG Replay Routine ---------

DoPSG:
	ld a,(NewPSG)
	inc a

	ld b,a

	jp z,NoNewPSG

	ld a,(newPSGStyle)
	cp 2
	jp z,noNewPSG

	cp 1
	jp nz,noOverride

	inc a
	ld (newPSGStyle),a

noOverride:
	ld hl,psg_source-176
	ld de,184
NewPSGLoop1:
	add hl,de
	djnz NewPSGLoop1

	ld d,%10111111
	OutPSG(7)

	ld (PSGPlayAddress),hl

	ld a,15
	ld (PSGVolume),a
	ld (PSGVolume+1),a
	ld (PSGVolume+2),a

	ld (PSGPlayTempo),a

	xor a
	ld (PSGPlayRow),a
	ld (PSGPlayTempoCount),a
	ld (PSGWait),a
	ld (PSGPointRow),a

	dec a
	ld (NumberOfReps),a

	ld hl,0
	ld (PSGPointAddress),hl	

	ld a,255
	ld (NewPSG),a

NoNewPSG:
	ld a,(PSGPlayTempoCount)
	or a
	jp z,NewPSGPlayTempo

	dec a
	ld (PSGPlayTempoCount),a

	ret

NewPSGPlayTempo:
	ld a,(PSGWait)
	or a
	jp z,NoPSGWait

	dec a
	ld (PSGWait),a

	ret

NoPSGWait:
	ld a,(PSGPlayTempo)
	ld b,a

	ld a,15
	sub b

	ld (PSGPlayTempoCount),a


StartPSGRowCode:
; Check if instrument has reached it's end.

	ld a,(PSGPlayRow)
	cp 16
	jp nz,psgNotEnded

	xor a
	ld (newPSGStyle),a

	ret

psgNotEnded:
; Check command

	ld hl,(PSGPlayAddress)

	ld a,(hl)
	or a
	jp z,PSGNoCommand

	cp 16
	jp c,PSGMakeRep

	cp 16
	jp z,PSGMakeDoRep

	cp 26
	jp c,PSGMakeWait

	cp 26
	jp z,PSGMakePoint

	cp 27
	jp z,PSGMakeGotoPoint

	cp 28
	jp z,PSGMakeEndPattern

	cp 45
	jp c,PSGMakeNewTempo

PSGNoCommand:
	inc hl									; Set HL to PSG frequencies

	ld b,3									; 3 PSG channels to out to.
	ld c,0									; First PSG register
	ld e,1									; For tones to be set off
PSGOutFreqLoop1:
	ld d,(hl)									; check if Freq = 0
											;
	inc hl									;
											;
	ld a,(hl)									;
											;
	or d										; if freq = 0 then
	jp z,NoPSGFreqChange							; jump to ..


	ld a,(hl)

	dec hl									; Set HL to original address

	bit 5,a
	jp nz,PSGOutFreqDown

	bit 6,a
	jp nz,PSGOutFreqUp

	ld a,c									; Out register to PSG
	out ($a0),a									;

	ld a,(hl)									; Out LSByte to PSG
	out ($a1),a									;

	inc hl									; increase address
	inc c										; increase PSG reg.

	ld a,(hl)									; Get MSByte of freq

	bit 4,a									; check if it is OFF
	jp z,PSGOutFreqNotOff							; nope.

	InPSG(7)									; Get reg. 7
	or e										; set channel off

	ld d,a									;
	OutPSG(7)									; Set reg. 7

	jp PSGFreqDone								; all done, next PSG

PSGOutFreqNotOff:
	ld a,e
	cpl
	ld e,a

	InPSG(7)
	and e
	ld d,a
	OutPSG(7)
	
	ld a,e
	cpl
	ld e,a

	ld a,c									; Out register to PSG
	out ($a0),a									;

	ld a,(hl)									; Out MSByte to PSG
	out ($a1),a									;

PSGFreqDone:
	sla e
	inc hl
	inc c

	djnz PSGOutFreqLoop1	

	ld ix,PSGvolume

	InPSG(7)
	or %00111000
	ld d,a

	ld bc,$0308^255
PSGVolNoiceLoop1:
	ld a,(hl)									; Get first volume and noice

	bit 6,a
	jp z,NoNoiceChange

	ld a,d
	and c
	ld d,a

	ld a,(hl)
NoNoiceChange:
	and %00111111
	jp z,NoVolumeChange

	bit 4,a
	jp nz,PSGVolumeUp

	bit 5,a
	jp nz,PSGVolumeDown

	and $0f
NoiceVolumeDone:
	ld (ix),a

NoVolumeChange:
	inc hl
	inc ix

	ld a,c

	sla a
	or 1

	ld c,a

	djnz PSGVolNoiceLoop1

	OutPSG(7)

	ld a,(hl)
	bit 5,a
	jp nz,NoiceFreqDown
	bit 6,a
	jp nz,NoiceFreqUp

	or a
	jp z,NoNoiceFreqChange

NoiceFreqChangeDone:
	ld d,a
	OutPSG(6)

NoNoiceFreqChange:
	ld a,(newPSGStyle)
	cp 2
	jp z,noVolumeBullshit

	ld a,(PSGMaxVol)

	ld hl,PSGVolume
	ld b,3
ChkMaxPSG.1:
	ld c,(hl)

	cp c
	jp nc,ChkMaxPSG.done

	ld (hl),a
ChkMaxPSG.Done:
	inc hl

	djnz ChkMaxPSG.1

	ld a,(musicFade)
	or a
	call nz,doFadeMusicPSG

noVolumeBullshit:
	ld a,(PSGVolume+0)
	ld d,a
	OutPSG(8)

	ld a,(PSGVolume+1)
	ld d,a
	OutPSG(9)

	ld a,(PSGVolume+2)
	ld d,a
	OutPSG(10)

	jp PSGAllDone

NoiceFreqDown:
	and %00011111
	ld b,a

	InPSG(6)

	sub b

	and %00011111

	jp NoiceFreqChangeDone

NoiceFreqUp:
	and %00011111
	ld b,a

	InPSG(6)

	add a,b

	and %00011111

	jp NoiceFreqChangeDone

PSGOutFreqDown:
	push de

	ld a,c

	out ($a0),a
	in a,($a2)

	ld e,a

	ld a,c
	inc a

	out ($a0),a
	in a,($a2)

	ld d,a

	ld a,(hl)

	push hl

	ld l,a
	ld h,0

	ex de,hl

	or a
	sbc hl,de

	ld a,c
	out ($a0),a

	ld a,l
	out ($a1),a

	inc c

	ld a,c
	out ($a0),a

	ld a,h
	out ($a1),a

	pop hl
	pop de

	inc hl

	jp PSGFreqDone

PSGOutFreqUp:
	push de

	ld a,c

	out ($a0),a
	in a,($a2)

	ld e,a

	ld a,c
	inc a

	out ($a0),a
	in a,($a2)

	ld d,a

	ld a,(hl)

	push hl

	ld l,a
	ld h,0

	add hl,de

	ld a,c
	out ($a0),a

	ld a,l
	out ($a1),a

	inc c

	ld a,c
	out ($a0),a

	ld a,h
	out ($a1),a

	pop hl
	pop de

	inc hl

	jp PSGFreqDone

PSGVolumeUp:
	push bc

	and $0f
	ld b,a

	ld a,(ix)
	add a,b

	pop bc

	cp 16
	jp c,NoiceVolumeDone

	ld a,15
	jp NoiceVolumeDone

PSGVolumeDown:
	push bc

	and $0f
	ld b,a

	ld a,(ix)
	sub b

	pop bc

	jp nc,NoiceVolumeDone

	xor a
	jp NoiceVolumeDone

PSGAllDone:
	ld a,(PSGPlayRow)
	inc a
	ld (PSGPlayRow),a

	ld hl,(PSGPlayAddress)
	ld de,11
	add hl,de
	ld (PSGPlayAddress),hl

	ret

NoPSGFreqChange:
	inc c

	jp PSGFreqDone

PSGMakeNewTempo:
	sub 29

	ld (PSGPlayTempo),a

	ld b,a

	ld a,15
	sub b

	ld (PSGPlayTempoCount),a

	jp PSGNoCommand

PSGMakeRep:
	ld b,a

	ld a,(NumberOfReps)
	cp 255
	jp nz,PSGNoCommand

	ld a,b

	ld (NumberOfReps),a
	ld (RepPointerAddress),hl

	ld a,(PSGPlayRow)
	ld (RepPointerRow),a

	jp PSGNoCommand

PSGMakeDoRep:
	ld a,(NumberOfReps)
	cp 255
	jp z,PSGNoCommand

	dec a
	ld (NumberOfReps),a

	cp 255
	jp z,PSGNoCommand

	ld a,(RepPointerRow)
	ld (PSGPlayRow),a

	ld hl,(RepPointerAddress)
	ld (PSGPlayAddress),hl

	jp StartPSGRowCode

PSGMakeWait:
	sub 16
	ld (PSGWait),a

	jp PSGNoCommand

PSGMakePoint:
	ld (PSGPointAddress),hl

	ld a,(PSGPlayRow)
	ld (PSGPointRow),a

	jp PSGNoCommand

PSGMakeGotoPoint:	
	ld a,(PSGPlayRow)
	ld b,a
	ld a,(PSGPointRow)
	cp b
	jp z,PSGNoCommand

	ld (PSGPlayRow),a

	ld hl,(PSGPointAddress)
	ld (PSGPlayAddress),hl

	jp StartPSGRowCode

PSGMakeEndPattern:
	ld a,15
	ld (PSGPlayRow),a

	jp PSGNoCommand

NewPSG:
	.db 0
NewPSGStyle:
	.db 0

PSGPlayRow:
	.db 16
PSGPlayAddress:
	.dw 0
PSGPlayTempo:
	.db 0
PSGPlayTempoCount:
	.db 0

NumberOfReps:
	.db 255
RepPointerRow:
	.db 0
RepPointerAddress:
	.dw 0
PSGWait:
	.db 0
PSGPointRow:
	.db 0
PSGPointAddress
	.dw 0

PSGVolume:
	.db 0,0,0

PSGMaxVol:
	.db 0

RepInt.start:
	in a,($fd)
	push af

	in a,($fe)
	push af

	ld a,RomBank
	out ($fd),a

	rst 30h
RepInt.slot:
	.db 0
	.dw PlayInt

	pop af
	out ($fe),a

	pop af
	out ($fd),a

OldPlayInt:
	.ds 5

RepInt.end:

IntCode:
	jp RepInterrupt

	.ds 2


; This part will be used by the stack while searching for an SCC.. Note that the label is
; behind the actual data, as when you PUSH something on the stack, the address will be lowered,
; and when POPping it, it will be raised again...

	.ds 256
NewStack:



EndRom:

start_program:
	ld a,($f342)					; Make page 1 a RAM slot
	ld h,$40						; 
	call enaslt						;

	ld a,2
	out ($fd),a

	ld hl,StartRom+ofs
	ld de,$4000
	ld bc,EndRom-StartRom
	ldir

	ld a,($f342)

	push af

	and %00000011
	sla a
	sla a
	sla a
	sla a

	ld e,a
	ld d,0
	ld hl,$fcc9

	add hl,de

	pop af

	and %00001100

	ld e,a

	add hl,de

	inc hl

	ld (hl),%00100000

	ld a,($fcc1)					; Return to BASIC Rom code (original)
	ld h,$40						; page 1
	call enaslt						;

	ld a,3						; Initial song bank
	ld (SngBnkPlay),a					;

	ld a,4						; Initial instrument kit bank
	ld (InsBnkPlay),a					;
	
	call InitMapper+ofs				; Initialise Memory mapper

	xor a
	ld (MusicPlay),a


	ret							; return to basic

InitMapper:
	in a,($a8)							; get primair slot selections

	ld b,a							; in b

	ld a,($f342)
	and %00000011						; get primair selection of page 1 (RAM)
	sla a
	sla a								; rotate it to primair page 1

	ld c,a							; for save keepin'

	sla a								; rotate to primair page 2
	sla a								;

	or c								; Get primair 1 in it too

	ld c,a

	ld a,b							; get primair selection again.
	and %11000011						; get rid of primair page 1 and 2

	or c								; get our primair selection in it..

	ld (pr.set),a


	ld a,($ffff)						; get secondare slot selection
	cpl
	and %11000011						; get rid of secondare slot sel. of page 1
	ld b,a							; save it

	ld a,($f342)
	and %00001100						; get secondare selection (page 1)..
	ld c,a

	sla a								; get secondate selection (page 2)..
	sla a

	or c

	or b								; get our secondare selection in it!
	ld (sec.set),a

	ret

end_program:

;.end


; end of code
