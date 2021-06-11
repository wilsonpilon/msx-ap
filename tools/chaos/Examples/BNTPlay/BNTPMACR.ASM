; TeddyWareZ MSX Z80 source file.
;
; Prog: SCC Blaffer NT BASIC replay routine Macro's!
; Code: d-fader^TwZ.
; Date: Septemper 6, 1999
;
; cmnt: none
;
; coded in Chaos Assembler 2.0
;
; (C) 1999 TeddyWareZ!

; error codes returned in register C after a disk-error occurs:
Err_DiskOffline:			.equ %00000010
Err_DiskIOError:			.equ %00001010

; Basic Disk Operation System (BDOS)
bdos_call	.equ $f37d					; BDOS address

sel_dsk		.equ 14				; Select Disk
open			.equ 15				; Open File
close			.equ 16				; Close File
get_ddn		.equ 25				; Get Default Drive Name
set_dma		.equ 26				; Set DMA address
rnd_br		.equ 39				; Random Block Read

; Bios 
chput			.equ $00a2
enaslt		.equ $0024
chget			.equ $009F
beep			.equ $00C0
cls			.equ $00C3

; other

scc_source:			.equ $8000
psg_source:			.equ $a060

MusicAddress				.equ $8000
SongName					.equ MusicAddress
InsKitName					.equ SongName+67
LastPos					.equ InsKitName+11
LoopPos					.equ LastPos+1
Patterns					.equ LoopPos+2
InitialTempo				.equ Patterns+256
StartVolumes				.equ InitialTempo+1
StartInstruments				.equ StartVolumes+5
DetuneSettings				.equ StartInstruments+4
VolumeSlideSettings			.equ DetuneSettings+5
PatternData					.equ MusicAddress+448

fcb:				.equ $da00
FileName_fcb:		.equ fcb+1
FileExt:			.equ FileName_fcb+8
CurBlock:			.equ FileExt+3
RecSize:			.equ CurBlock+2
FileSize:			.equ RecSize+2
Date:				.equ FileSize+4
Time:				.equ Date+2
DeviceID:			.equ Time+2
DirLocation:		.equ DeviceId+1
FirstClus:			.equ DirLocation+1
LastClus:			.equ FirstClus+2
CurRec:			.equ LastClus+2
RndRec:			.equ CurRec+1
EndFcb:			.equ RndRec+7

RepBegin			.equ EndFcb

MusicPlay			.equ RepBegin			; Is music playing? <>0 if so.
MusicPeak			.equ MusicPlay+1			; Is a new row started??
SccSlot			.equ MusicPeak+1			; Current SCC Slot. (slot * 16)
SngBnkPlay			.equ SccSlot+1			; Song bank
InsBnkPlay			.equ SngBnkPlay+1			; Instrument bank
SngPos			.equ InsBnkPlay+1			; Current song position
SngRow			.equ SngPos+1			; Current song row
SngTmp			.equ SngRow+1			; Current song tempo
SngFreqs			.equ SngTmp+1			; Song Frequencies
SngVolumes			.equ SngFreqs+10			; Song Volumes
RepCommand			.equ SngVolumes+5			; Replayer command
RepEnd			.equ RepCommand+7

pr.org			.equ RepEnd+1			; Original primair page
pr.set			.equ pr.org+1			; Primair page to set (in interrupt)
sec.org			.equ pr.set+1			; Original secondare page
sec.set			.equ sec.org+1			; Secondare page to set (in interrupt)
map1.org			.equ sec.set+1			; Original page 1
map2.org			.equ map1.org+1			; Original page 2
SongPatsToSave		.equ map2.org+1
SongPatAdrToSave		.equ SongPatsToSave+1
StackSave			.equ SongPatAdrToSave+2
PrimairPageSave		.equ StackSave+2
SecondarePageSave		.equ PrimairPageSave+1

ErrorHandAdr		.equ SeconDarePageSave+1

RepInterrupt		.equ $da00				; Replay interrupt Init


#define	DoShowText(point,way)				  ld hl,point
#defcont								\ ld a,way
#defcont								\ call ShowText

#define	bdos(command)					  ld c,command
#defcont								\ call bdos_call

#define	OutPSG(reg)						\ ld a,reg
#defcont								\ out ($a0),a
#defcont								\ ld a,d
#defcont								\ out ($a1),a

#define	InPSG(reg)						\ ld a,reg
#defcont								\ out ($a0),a
#defcont								\ in a,($a2)


.end
