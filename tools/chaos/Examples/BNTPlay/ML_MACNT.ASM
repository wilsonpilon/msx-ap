; TeddyWareZ MSX Z80 source file.
;
; Prog: SCC Blaffer NT replay routine macro's
; Code: d-fader^TwZ.
; Date: February 11, 2000
;
; cmnt: You can use this file to support the SCC Blaffer NT replay routine for ML use... 
;
; coded in Chaos Assembler 2.0
;
; (C) 2000 TeddyWareZ!

;----------------------------------------------------------------------------------------------
; This function will call the replayer to execute a command. e.g. to play a song type in this
; in your program: BNTReplay(InitSCC)
;
; The equates of all functions available are listed below. Be sure to have intergrated the
; block of code that can be found at the end of this file in your own program. This code is 
; needed to actually correctly call the replayer.

#define	BNTReplay(function)			  in a,($fd)
#defcont							\ push af
#defcont							\ ld a,2
#defcont							\ out ($fd),a
#defcont							\ ld a,function
#defcont							\ ld (RepFunction),a
#defcont							\ call $4000
#defcont							\ pop af
#defcont							\ out ($fd),a


;----------------------------------------------------------------------------------------------

romBank			.equ 2				; This equate tells in which map the
									; replay routine is stored, normally 2
									; for the Replayer calls

bntReplay			.equ $4100				; Replayer address
RepCommand			.equ $da3d				; Function parameter
RepFunction			.equ $f7f8				; Replayer function to call
ErrorCode			.equ $f414				; Error/Return Code

initSCC			.equ 0				; Initialize SCC
forceMusic			.equ 1				; Force Music
SBMLoad			.equ 2				; Load SBM File
SBKLoad			.equ 3				; Load SBK File
BNTPlay			.equ 4				; Play Music
BNTStop			.equ 5				; Stop Music
BNTHalt			.equ 6				; Pause Music
BNTCont			.equ 7				; Continue Music
BNTFade			.equ 8				; Fade out Music
doPSG				.equ 9				; PSG Override
stopPSG			.equ 10				; PSG Override Stop

									; Error codes:
errCorrect			.equ 0				; Function executed correctly
errSlot1			.equ 1				; SCC Found in Slot 1
errSlot2			.equ 2				; SCC Found in Slot 2
errFileError		.equ 100				; Error while executing command
errFuncNotFound		.equ 101				; Function not Found
errFuncNotAvail		.equ 102				; Function not available

bntFcb			.equ $da00				; File Control Block
bntDrive			.equ $da00				;
bntFileName			.equ $da01				;
bntFileExt			.equ $da09				;

MusicPlay			.equ $da26				; Is music playing? <>0 if so.
MusicPeak			.equ MusicPlay+1			; Is a new row started??
SccSlot			.equ MusicPeak+1			; Current SCC Slot. (slot * 16)
SngBnkPlay			.equ SccSlot+1			; Song bank
InsBnkPlay			.equ SngBnkPlay+1			; Instrument bank
SngPos			.equ InsBnkPlay+1			; Current song position
SngRow			.equ SngPos+1			; Current song row
SngTmp			.equ SngRow+1			; Current song tempo
SngFreqs			.equ SngTmp+1			; Song Frequencies
SngVolumes			.equ SngFreqs+10			; Song Volumes

; To call the replayer, you need this block of code...
; Remember this part only may not lay in page 1 (address $4000-$7fff) as the replayer itself is
; stored in page 1...

;doReplay:
;	in a,($fd)
;	push af
;
;	in a,($fe)
;	push af
;
;	ld a,RomBank
;	out ($fd),a
;
;	ld a,($f342)
;	ld (Replay.Slot),a
;
;	rst 30h
;Replay.slot:
;	.db 0
;	.dw bntReplay
;
;	pop af
;	out ($fe),a
;
;	pop af
;	out ($fd),a
;
;	ret
.end
