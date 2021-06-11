; TeddyWareZ MSX Z80 source file.
;
; Prog: Blaffer NT replay routine 1.4 test program...
; Code: d-fader^TwZ.
; Date: February 11, 2000
;
; cmnt: none.
;
; coded in Chaos Assembler 2.0
;
; (C) 2000 TeddyWareZ!

#include "ml_macnt.asm"

; This will show a text in text mode. Refer to 'ShowText:' for more information.
#define	doShowText(pointer)				  ld hl,pointer
#defcont								\ call ShowText

chgMod		.equ $5f				; change Screen mode
chPut			.equ $a2				; Put character on screen

	.org $9000 - 7

	.db $fe
	.dw startProgram,endProgram,startProgram

startProgram:
	ld a,80							; width 80
	ld ($f3ae),a						; 

	xor a								; switch to screen 0 (width 80)
	call chgMod							; 

	doShowText(welcomeText)					; Show Welcome message

	BNTReplay(InitSCC)					; Try to initialize SCC

	ld a,(ErrorCode)						; Check if SCC was found.
	cp errFileError						; if not (code = 100)
	jp z,noSCCFound						; then terminate.

	ld b,a							; save slot

	srl a								; rotate primare
	srl a								;
	srl a								;
	srl a								;

	add a,48							; Get primare slot number
	ld (SCCFound.prim),a					; for 'on screen' 1 or 2 char.

	ld a,b
	and $0f

	add a,48							; Get secondare slot number
	ld (SCCFound.sec),a					; for 'on screen' 1 or 2 char.



	doShowText(SCCFound)					; Say we found an SCC

	doShowText(InsKit.Load)					; Say we are loading the Instrument Kit
	
	ld hl,sbkFile						; Copy the filename to the FCB which the
	ld de,bntFcb						; replayer will use...
	ld bc,12							;
	ldir								;

	BNTReplay(SBKLoad)					; Try to load it.
	
	ld a,(ErrorCode)						; Check if executed correctly
	cp errFileError						; if error ocurred
	jp z,insKitError						; say so and terminate program.


	doShowText(Song.Load)					; Say we are loading the song
	
	ld hl,sbmFile						; Copy the filename to the FCB which the
	ld de,bntFcb						; replayer will use...
	ld bc,12							;
	ldir								;

	BNTReplay(SBMLoad)					; Try to load it.
	
	ld a,(ErrorCode)						; Check if executed correctly
	cp errFileError						; if error ocurred
	jp z,songError						; say so and terminate program.

	BNTReplay(BNTPlay)					; All Ok, so play music!!

	doShowText(End.Right)					; Say it's ok and terminate!

	ret


insKitError:
	doShowText(InsKit.error)

	jp endProgError

songError:
	doShowText(Song.error)

	jp endProgError

noSCCFound:
	doShowText(SCCNotFound)

endProgError:
	doShowText(End.Wrong)

	ret

; All texts that could be shown on screen are stored here.

WelcomeText:
	.text "SCC-Blaffer NT replay routine test for assembler coders...``"
	.db 0

SCCFound:
	.text "SCC found in slot: "
SCCFound.prim:
	.db "X."
SCCFound.sec:
	.db "X`"


SCCNotFound:
	.text "No SCC found... Terminating example program...`"
	.db 0


InsKit.Load:
	.text "Loading instrument kit...`"
	.db 0
InsKit.Error:
	.text "An error occured while loading instrument kit... (file: BLAF_NT.SBK)`"
	.db 0

Song.Load:
	.text "Loading song...`"
	.db 0
Song.Error:
	.text "An error occured while loading song... (file: SDCHURCH.SBM)`"
	.db 0

End.Wrong:
	.text "`Sow... Try again! ;)`"
	.db 0

End.Right:
	.text "`All Ok... Playing song... Have a nice day... Stop the music with _BNTStop!``"
	.text "SCC-Blaffer NT is (C) 1999/2000 TeddyWareZ!`"
	.db 0

sbkFile:
		;12345678123
	.db 0,"BLAF_NT SBK"
sbmFile:
	.db 0,"SDCHURCHSBM"


ShowText:
; routine : Show text on screen
; in      : HL - pointer to text
; out     : none.
; cmnt    : Text has to terminated with chr(0), use the "`" charcater for a carriage return...

	ld a,(hl)
	or a
	ret z

	cp 96
	jp z,DoEnter

	call chput

EnterDone:
	inc hl

	jp ShowText

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


; --- The actual call to the replay routine ---
doReplay:
	in a,($fd)
	push af

	in a,($fe)
	push af

	ld a,RomBank
	out ($fd),a

	ld a,($f342)
	ld (Replay.Slot),a

	rst 30h
Replay.slot:
	.db 0
	.dw bntReplay

	pop af
	out ($fe),a

	pop af
	out ($fd),a

	ret

; --- Till here ---

endProgram:

.end
