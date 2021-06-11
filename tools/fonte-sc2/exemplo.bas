10 REM { carrega fonte padrao graphos III }
20 bload"amazonia.alf",&H3A00 
22 poke &hf91f,peek(&hf341+3)
24 poke &hf920,&H00
26 poke &hf921,&hCC
28 REM
30 REM {Serve apenas para centralizar texto na tela}
32 REM
40 def fncx(fs$)=128-4*len(fs$)
50 def fnct(fs$)=15-len(fs$)/2
60 REM
70 REM {Exemplo na SCREEN 2}
80 REM
100 screen 2
110 open "grp:" as #1
120 color 15,12,4
130 cls
140 color 15
150 fs$="Usando FONTE Amaz"+chr$(&H93)+"nia"
160 pset(fncx(fs$),64),12
170 print #1,fs$
180 color 7
190 fs$="na SCREEN 2"
200 pset(fncx(fs$),80),12
210 print #1,fs$
220 color 10
230 fs$="Fonte em CC00h"
240 pset(fncx(fs$),96),12
250 print #1,fs$
260 color 3
270 fs$="Pressione Espaco"
280 pset(fncx(fs$),160),12
290 print #1,fs$
300 for i=0to1
310   i=-strig(0)
320 next
400 REM
410 REM {Exemplo na SCREEN 2}
420 REM
430 screen 1
440 color 15,12,4
450 width 30
460 fs$="Usando FONTE Amaz"+chr$(&H93)+"nia"
470 locate fnct(fs$),6
480 print fs$
490 fs$="na SCREEN1"
500 locate fnct(fs$),8
510 print fs$
520 fs$="Fonte em CC00h"
530 locate fnct(fs$),10
540 print fs$
560 for i=0 to 1
570   i=-strig(0)
580 next
700 REM
710 REM {Volta fonte da ROM}
720 REM
730 poke &hf91f,peek(&hfcc1)
740 poke &hf920,peek(4)
750 poke &hf921,peek(5)
800 screen 0
810 end