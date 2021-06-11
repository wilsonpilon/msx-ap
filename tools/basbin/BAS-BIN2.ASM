;                                                             Sun Jun 31, 2005
;BAS-BIN2.ASM  bugfixed BAS-BIN.ASM
;Delay added to fix VDP access timing on non Brazilian MSX's.
;Orphaned code and data removed.
;Program loader rewrittem (it stops drives in any MSX)
;Deletion of the selected basic program feature removed.
;Directory read routine totally rewritten (now reads any kind of MSX disk)
;File read/write routines now work on current drive
;Ugly character generator removed
;Exit key changed to ESC and help key changed to 'H'
;Messages translated to English

;(C) Eduardo Barbosa - Nemesis Informatica.
;Unauthorized disassembly (c) 2005 Garohard O.M.S

;BAS-BIN.COM  BASIC (LOADable) to CODE (BLOADable) file converter

        ORG     0100H           ;like all the COM files
L0100:  DI                      ;disable interrupts

;COPY THE FIRST HALF OF THE CHARACTER GENERATOR INVERTED IN THE SECOND HALF
        LD      HL,L0800        ;start of the chr gen - start vpeeking
        LD      DE,L0C00        ;second half of the chr gen - start vpoking
        LD      BC,0400H        ;1k
L010D:  CALL    L0194           ;vpeek in A
        CALL    L019D           ;vpoke the A complement
        INC     DE              ;increment the vpoke pointer
        INC     HL              ;increment the vpeek pointer
        DEC     BC              ;decremennt the byte counter
        LD      A,B             ;were all the
        OR      C               ;bytes processed?
        JR      NZ,L010D        ;loop back if not

;CLS AND SET SOME SCREEN PARAMETERS
        EI                      ;enable ints
        CALL    L068D           ;clear the screen
        CALL    L0631           ;key off
        XOR     A               ;zero A
        LD      (LFCA9),A       ;hide the cursor
        CPL                     ;A = FF
        LD      (LFCAB),A       ;activate caps lock
        LD      A,28H           ;40 characters
        LD      (LF3B0),A       ;set as width
        LD      (LF3AE),A       ;and default for screen 0

;CLEAR THE 16K DATA BUFFER
L0131:  LD      HL,L8000        ;16K buffer
        LD      (HL),00H        ;clear the first byte
        LD      DE,L8001        ;the second byte of the buffer
        LD      BC,3FFFH        ;clear the rest of
        LDIR                    ;the buffer using LDIR

;DISPLAY THE TITLE MESSAGE AND RUN MAIN PROGRAM
        LD      HL,0902H        ;line 2 col 9
        CALL    L0629           ;print at
        LD      HL,L0C63        ;'BAS-BIN CONVERTER' message
        CALL    L058B           ;display the message in inverse video
        CALL    L0179           ;clear 13 lines from line 7
        CALL    L06AB           ;display the copyright message
        EI                      ;enable ints
        XOR     A               ;zero A
        LD      (LFCA9),A       ;hide the cursor
        CPL                     ;A = FF
        LD      (LFCAB),A       ;activate caps lock

;READ DIRECTORY AND GENERATE A TABLE WITH FILENAMES
;Note: Totally rewritten routine using search-first search-next technics
;SETUP THE FCB FOR ALL FILES
        CALL    L03F7           ;clear the FCB
        LD      DE,L8000        ;the 16k data buffer
        LD      (LF601),DE      ;save as entry pointer
        LD      C,1AH           ;set the transfer address
        CALL    L0005           ;BDOS
        LD      HL,QSTMRK       ;'*.*' all the files
        LD      DE,L005D        ;filename for the first FCB
        LD      BC,11           ;copy the question marks
        LDIR                    ;using LDIR

;SEARCH THE FIRST FILE
        LD      DE,L005C        ;the first FCB
        LD      C,11H           ;search first
        CALL    L0005           ;BDOS
        AND     A               ;file found?
        JR      NZ,GENTAB       ;jump if not, else..

;CONTINUE SEARCHING UNTIL ALL THE FILES ARE  READ
SRCHLP: LD      HL,(LF601)      ;get the entry pointer
        LD      DE,32           ;the directory entry length
        ADD     HL,DE           ;point to the address for the next dir entry
        LD      (LF601),HL      ;update the entry pointer
        EX      DE,HL           ;new pointer to DE
        LD      C,1AH           ;set the transfer address
        CALL    L0005           ;BDOS
        LD      DE,L005C        ;the first FCB
        LD      C,12H           ;search next
        CALL    L0005           ;BDOS
        AND     A               ;file found?
        JR      Z,SRCHLP        ;if yes, process next filename, else..

GENTAB: CALL    L01CA           ;generate the filenames table at 9000H

;CALL THE MAIN PROGRAM AND JUMP TO THE SYSTEM UPON RETURN
        CALL    L020E           ;call the main program
        CALL    L068D           ;clear the screen
        JP      0000H           ;return to MSX-DOS

;CLEAR 13 LINES FROM LINE 7 DOWNWARDS, SET PRINT POSITION AT LINE 7 COL 1
L0179:  LD      HL,0107H        ;line 7 col 1
        PUSH    HL              ;push line and column
        CALL    L0629           ;print at
        LD      B,0DH           ;thirteen lines
L0182:  PUSH    BC              ;push the line count
        LD      B,28H           ;40 characters each line
L0185:  LD      A,20H           ;a space
        CALL    L0621           ;display it
        DJNZ    L0185           ;display next space
        POP     BC              ;pop the line count
        DJNZ    L0182           ;clear next line
        POP     HL              ;pop line and column
        CALL    L0629           ;print at
        RET                     ;ret

;VPEEK IN 'A' THE VRAM ADDRES POINTED BY 'HL'
L0194:  LD      A,L             ;vram low address to A
        OUT     (99H),A         ;out to the vdp
        LD      A,H             ;vram high byte to A
        OUT     (99H),A         ;out to the vdp
        EX      (SP),HL         ;little
        EX      (SP),HL         ;time delay
        IN      A,(98H)         ;perform the vpeek
        RET                     ;ret

;VPOKE THE COMPLEMENT OF 'A' TO THE VRAM ADDRESS POINTED BY 'DE'
L019D:  PUSH    AF              ;push the data byte
        LD      A,E             ;vram low address to A
        OUT     (99H),A         ;out to the vdp
        LD      A,D             ;vram high address to A
        OR      40H             ;add the 'write flag'
        OUT     (99H),A         ;out to the vdp
        POP     AF              ;pop the data byte
        CPL                     ;complement it
        OUT     (98H),A         ;perform the vpoke
        RET                     ;ret

;GENERATE A TABLE WITH FILENAMES OF THE FORM NNNNNNNN.EEE AT 9000H
L01CA:  LD      HL,L8001        ;input buffer with the directory loaded +1
        LD      DE,L9000        ;output buffer with filenames
        XOR     A               ;reset to zero
        LD      (LF600),A       ;the files counter
L01D4:  LD      A,(HL)          ;get the first byte of filename
        CP      0E5H            ;is it a deleted file entry?
        JR      Z,L0208         ;if yes, skip this entry
        CP      00H             ;is it the end of directory marker?
        RET     Z               ;ret if yes, else..
        LD      B,08H           ;filename length, 8 characters
L01DE:  LD      A,(HL)          ;get a byte from fiename in directory
        LD      (DE),A          ;poke it in destination buffer
        INC     HL              ;increment read pointer
        INC     DE              ;increment write pointer
        DJNZ    L01DE           ;process next byte of filename
        LD      A,(HL)          ;get the first byte of the extension
        CP      20H             ;is it a space?
        JR      NZ,L01EF        ;jump if not, else..
        LD      (DE),A          ;print a space istead of the period
        LD      B,03H           ;file extension length, 3 characters
        INC     DE              ;increment destination pointer
        JR      L01F5           ;display the file extension
L01EF:  LD      A,2EH           ;a period
        LD      (DE),A          ;poke in destination buffer
        LD      B,03H           ;file extension length, 3 characters
        INC     DE              ;increment destination pointer
L01F5:  LD      A,(HL)          ;get a byte from file extension in directory
        LD      (DE),A          ;poke it in destination buffer
        INC     DE              ;increment write pointer
        INC     HL              ;increment read pointer
        DJNZ    L01F5           ;process next byte of file extension
        LD      BC,0015H        ;(21 dec) entry length minus filename length
        ADD     HL,BC           ;point to next directory entry
        LD      A,(LF600)       ;get the files counter
        INC     A               ;increment it
        LD      (LF600),A       ;update the variable
        JR      L01D4           ;process next directory entry

;POINT TO THE NEXT DIRECTORY ENTRY
L0208:  LD      BC,0020H        ;(32 dec) directory entry length
        ADD     HL,BC           ;point HL to next entry
        JR      L01D4           ;process next directory entry

;DISPLAY THIRTY OR LESS FILENAMES
L020E:  LD      HL,0107H        ;line 7 col 1
        CALL    L0629           ;print at
        XOR     A               ;zero A
        LD      (LF603),A       ;no files displayed yet
        LD      (LF620),A       ;signal 'screen complete' 30 files displayed
        LD      HL,L9000        ;the filenames table
L021E:  LD      A,(HL)          ;get the first byte of filename
        CP      00H             ;is it the end marker?
        JR      Z,L0251         ;jump if yes
        LD      B,0CH           ;12 characters (filename.ext)
        LD      A,20H           ;a space
        CALL    L0621           ;display it
L022A:  LD      A,(HL)          ;get a byte from the filename
        CALL    L0621           ;display it
        INC     HL              ;increment pointer
        DJNZ    L022A           ;process next char of current filename
        LD      A,(LF3DD)       ;CSRX get the cursor column
        CP      28H             ;is it 40?
        JR      NZ,L0244        ;jump if not, else..
        LD      A,(LF3DC)       ;CSRY get the cursor line
        INC     A               ;increment line
        LD      (LF3DC),A       ;update the variable
        LD      A,01H           ;point to the first column
        LD      (LF3DD),A       ;update CSRX
L0244:  LD      A,(LF603)       ;get the number of files displayed
        INC     A               ;increment it
        LD      (LF603),A       ;update the variable
        CP      1EH             ;30 files displayed?
        JR      Z,L0256         ;jump if yes, else..
        JR      L021E           ;process next filename

;THE END MARKER WAS FOUND BEFORE DISPLAYING 30 BYTES, UPDATE THE FLAG
L0251:  LD      A,01H           ;signal 'screen not complete'
        LD      (LF620),A       ;in the complete screen flag
L0256:  CALL    L04B8           ;highlight the top left filename

;ROTATE THE BOTTOM MESSAGE, READ THE KEYBOARD, JUMP TO THE PROPER ROUTINE
L0259:  PUSH    HL              ;save HL
        CALL    L05B5           ;rotate bottom msg and read the keyboard
        POP     HL              ;retrieve HL
        CP      'D'             ;is it 'D'?
        JP      Z,L0131         ;jump if yes, restart the program
        CP      'H'             ;is it 'H'?
        JP      Z,L051A         ;jump if yes, show help screen
        CP      ' '             ;is it a space?
        JP      Z,L028B         ;jump if yes, display next filenames screen
        CP      0DH             ;is it enter?
        JP      Z,L029F         ;jump if yes, select the highlighted program
        CP      1BH             ;is it ESC?
        RET     Z               ;return if yes
        CP      1CH             ;is it right?
        JP      Z,L0422         ;jump if yes,
        CP      1DH             ;is it left?
        JP      Z,L044D         ;jump if yes
        CP      1EH             ;is it up?
        JP      Z,L04A1         ;jump if yes
        CP      1FH             ;is it down?
        JP      Z,L0465         ;jump if yes
        JR      L0259           ;loop back if none of the above

;SPACE PRESSED DISPLAY NEXT FILE CHOOSING SCREEN
L028B:  PUSH    HL              ;save HL
        CALL    L0179           ;clear 13 lines from line 7
        POP     HL              ;retrieve HL
        XOR     A               ;zero to A
        LD      (LF603),A       ;signal 'no files displayed yet'
        LD      A,(LF620)       ;get the 'complete screen flag'
        CP      01H             ;uncomplete screen?
        JP      NZ,L021E        ;jump if complete (30 filenames), else..
        JP      L020E           ;previous scr incomplete, start from begining

;ENTER PRESSED - HIGHLIGHTED FILE IS CHOSEN
;LOAD THE BASIC PROGRAM INTO THE BUFFER
L029F:  LD      DE,L1000        ;buffer for the basic program
        LD      C,1AH           ;set the transfer address
        CALL    L0005           ;BDOS
        CALL    L06AB           ;display the copyright message
        CALL    L03F7           ;clear the FCB
        CALL    L0405           ;copy the selected flename into the 1st FCB
        LD      DE,L005C        ;the first FCB
        LD      C,0FH           ;open file
        CALL    L0005           ;BDOS
        INC     A               ;set ZF in case of error
        JP      Z,L0131         ;jump if error, restart the program
        LD      HL,0A13H        ;line 19 col 10
        CALL    L0629           ;print at
        LD      HL,L0D00        ;'LOADING....' message
        CALL    L058B           ;display the message
        LD      HL,0001H        ;one byte
        LD      (L006A),HL      ;set record length to one byte
        LD      HL,0000H        ;zero
        LD      (L007C),HL      ;point the current record and the
        LD      (L007E),HL      ;current relative record
        LD      (L0080),HL      ;to the begining of the file
        LD      HL,7000H        ;28672, the maximum BASIC program length
        LD      DE,L005C        ;FCB with the BASIC program name
        LD      C,027H          ;random block read, read the BASIC program
        CALL    L0005           ;BDOS

;CHECK IF THE FILE HAS A VALID BASIC HEADER
        PUSH    HL              ;save the basic program length
        LD      HL,L1000        ;start of loaded file
        LD      A,(HL)          ;get the first byte
        CP      0FFH            ;is it the BASIC file ID?
        POP     HL              ;retrieve the basic program length
        JP      Z,L0304         ;jump if yes, else..
        LD      HL,0A13H        ;line 19 col 10
        CALL    L0629           ;print at
        LD      HL,L0D2E        ;' INVALID FILE' message
        CALL    L058B           ;display the message
        LD      C,08H           ;direct input, wait a key
        CALL    L0005           ;BDOS
        JP      L0131           ;restart the program

;COPY THE PROGRAM LOADER AT THE END OF THE BASIC PROGRAM
L0304:  PUSH    HL              ;save the basic program length
        LD      HL,L1000        ;start of the loaded basic program
        LD      (HL),00H        ;reset the basic ID byte to zero
        LD      DE,L005C        ;BASIC program FCB
        LD      C,10H           ;close file
        CALL    L0005           ;BDOS
        LD      DE,8000H        ;execution address of the basic program
        POP     HL              ;pop the basic program length
        ADD     HL,DE           ;point to end address of basic program
        LD      (L03D6),HL      ;update variable in the epilogue code
        XOR     A               ;reset the carry flag
        SBC     HL,DE           ;recalculate the basic program length
        LD      DE,L1000        ;start of the loaded basic program
        ADD     HL,DE           ;point to the end of the loaded basic program
        LD      (L0C5F),HL      ;store in variable
        EX      DE,HL           ;end of basic program to DE
        LD      HL,L03D5        ;start of epilogue code
        LD      BC,L03F6-L03D5  ;33 bytes
        LDIR                    ;copy epilogue code to the end of dest pgm
        LD      (L0C61),DE      ;store end of epilogue code in variable

;DEFINE A CODE HEADER JUST BEFORE THE LOADED PROGRAM
        LD      IX,L1000        ;start of loaded basic program
        LD      (IX-07H),0FEH   ;code file ID
        LD      (IX-06H),00H    ;define the start
        LD      (IX-05H),80H    ;address as 8000H
        LD      HL,(L0C61)      ;get the epilogue end address
        LD      DE,L1000        ;get the start of loaded basic program
        XOR     A               ;calculate the length of the resultant
        SBC     HL,DE           ;bloadable code file
        LD      DE,8000H        ;the execution address of the basic program
        ADD     HL,DE           ;calc the code file end address
        LD      (IX-04H),L      ;define the end address
        LD      (IX-03H),H      ;in the code header
        LD      HL,(L0C5F)      ;get the end of the loaded basic program
        LD      DE,L1000        ;the start of the loaded basic program
        XOR     A               ;clear carry
        SBC     HL,DE           ;calculate the basic program length
        LD      DE,8000H        ;the execution address of the basic program
        ADD     HL,DE           ;point just after the basic prog (loader code)
        LD      (IX-02H),L      ;define the execution adress
        LD      (IX-01H),H      ;in the code header

;CREATE THE 'BIN' FILE AND SAVE IT TO DISK
        LD      DE,L0FF9        ;include the code header
        LD      C,1AH           ;set the transfer address
        CALL    L0005           ;BDOS
        CALL    L03F7           ;clear the FCB
        CALL    L0405           ;copy the selected flename into the 1st FCB
        LD      IX,L0065        ;point to the file extension
        LD      (IX+00H),'B'    ;replace the
        LD      (IX+01H),'I'    ;file extension
        LD      (IX+02H),'N'    ;with 'BIN'
        LD      DE,L005C        ;FCB is now for the new 'BIN' file
        LD      C,16H           ;create file
        CALL    L0005           ;BDOS
        LD      HL,0A13H        ;line 19 col 10
        CALL    L0629           ;print at
        LD      HL,L0D17        ;'SAVING..' message
        CALL    L058B           ;display it
        LD      HL,0000H        ;zero
        LD      (L007C),HL      ;point the current record and the
        LD      (L007E),HL      ;current relative record
        LD      (L0080),HL      ;to the begining of the file
        LD      HL,0001H        ;one byte
        LD      (L006A),HL      ;set record length to one byte
        LD      HL,(L0C61)      ;the end of the program loader
        LD      DE,L0FF9        ;the start of the code header
        XOR     A               ;calculate the code file length (header+
        SBC     HL,DE           ;(code header+basic program+program loader)
        LD      DE,L005C        ;FCB for the 'BIN' output file
        LD      C,26H           ;random block write
        CALL    L0005           ;BDOS   write the code file
        LD      DE,L005C        ;FCB for the 'BIN' file
        LD      C,10H           ;close file
        CALL    L0005           ;BDOS
        JP      L0131           ;restart the program

;EPILOGUE CODE TO BE COPIED AT THE END OF DESTINATION PROGRAM
;IT'S USED AS A PROGRAM LOADER
;Note: This rotine was rewritten to stop the drive on any MSX computer
;      and the software protection feature was removed.

L03D5:  LD      HL,0000H        ;self modifying code
L03D6:  EQU     $-2             ;end of basic program
        LD      (LF6C2),HL      ;VARTAB start of basic variables

;FAKE 256 TIMER INTERRUPTS TO STOP THE DRIVE
        LD      B,0             ;256 rounds
SDLOOP: PUSH    BC              ;save the counter
        CALL    LFD9F           ;call the timer interrupt handler
        POP     BC              ;pop the counter
        DJNZ    SDLOOP          ;loop back

        JP      L73AC           ;execute the basic program
L03F6:  NOP                     ;unused location

;CLEAR THE FIRST FCB
L03F7:  LD      HL,L005C        ;the first FCB
        LD      (HL),00H        ;clear the first byte
        LD      DE,L005D        ;the second byte
        LD      BC,0020H        ;32 bytes
        LDIR                    ;clear using LDIR
        RET                     ;ret

;COPY THE SELECTED FILENAME INTO THE FIRST FCB
L0405:  LD      HL,LF604        ;selected filename
        INC     HL              ;skip the initial space
        LD      DE,L005C        ;the first FCB
        LD      A,00H           ;signal 'current drive'
        LD      (DE),A          ;into the FCB
        INC     DE              ;point to first byte of filename
        LD      B,08H           ;filename has 8 characters
L0412:  LD      A,(HL)          ;get a byte from filename
        LD      (DE),A          ;poke it into the FCB
        INC     HL              ;increment read pointer
        INC     DE              ;increment write pointer
        DJNZ    L0412           ;process the whole filename
        INC     HL              ;skip the period
        LD      B,03H           ;file extension has 3 characters
L041B:  LD      A,(HL)          ;get a byte from file extension
        LD      (DE),A          ;poke it into the FCB
        INC     DE              ;increment write pointer
        INC     HL              ;increment read pointer
        DJNZ    L041B           ;process the whole extension
        RET                     ;ret

;RIGHT ARROW PRESSED
L0422:  LD      A,(LF3DD)       ;get the cursor column
        LD      DE,(LF601)      ;get coordinates of the end of last filename
        ADD     A,0DH           ;point to the end of current filename
        CP      D               ;compare with column
        JR      NZ,L0435        ;jump if not match, else check line
        LD      A,(LF3DC)       ;get the cursor line
        CP      E               ;compare wuth line of last filename
        JP      Z,L0259         ;if they match then do nothing
L0435:  LD      A,(LF3DD)       ;get the cursor column
        CP      1BH             ;is it at column 27?
        JP      Z,L0259         ;if yes, then do nothing
        ADD     A,0DH           ;point to 13 columns to the right
        PUSH    AF              ;save the new column
        CALL    L04CB           ;unhighlight the current filename
        POP     AF              ;retrieve the new column
        LD      (LF3DD),A       ;update the cursor column
        CALL    L04CB           ;highlight the new filename
        JP      L0259           ;loop back to read the keyboard

;LEFT ARROW PRESSED
L044D:  LD      A,(LF3DD)       ;get the cursor column
        CP      01H             ;is it at column 1?
        JP      Z,L0259         ;if yes, then do nothing
        SUB     0DH             ;point to 13 columns to the left
        PUSH    AF              ;save the new column
        CALL    L04CB           ;unhighlight the current filename
        POP     AF              ;retrieve the new column
        LD      (LF3DD),A       ;update the cursor column
        CALL    L04CB           ;highlight the new filename
        JP      L0259           ;loop back to read the keyboard

;DOWN ARROW PRESSED
L0465:  LD      DE,(LF601)      ;get coordinates of the end of last filename
        LD      A,D             ;pass column to A
        CP      01H             ;is it column 1?
        JR      NZ,L0478        ;jump if not, else..
        DEC     E               ;point to previous line
        LD      A,(LF3DC)       ;get the cursor line
        CP      E               ;compare with last filename line
        JR      C,L048F         ;jump if lower than
        JP      L0259           ;else do nothing
L0478:  LD      A,(LF3DC)       ;get the current cursor line
        CP      E               ;compare with last filename line
        JP      NC,L0259        ;if greater or equal then do nothing, else..
        SUB     0DH             ;why?
        LD      A,(LF3DD)       ;get the current cursor column
        CP      D               ;compare with last filename column
        JR      C,L048F         ;jump if greater or equal, else..
        LD      A,(LF3DC)       ;get the current cursor line
        INC     A               ;point to the line below
        CP      E               ;compare with last filename line
        JP      NC,L0259        ;if greater or equal then do nothing, else..
L048F:  LD      A,(LF3DC)       ;get the current cursor line
        INC     A               ;down one line
        PUSH    AF              ;save the new line
        CALL    L04CB           ;unhighlight the current filename
        POP     AF              ;retrieve the new line
        LD      (LF3DC),A       ;update the cursor line
        CALL    L04CB           ;highlight the new filename
        JP      L0259           ;loop back to read the keyboard

;UP ARROW PRESSED
L04A1:  LD      A,(LF3DC)       ;get the cursor line
        CP      07H             ;is it line 7?
        JP      Z,L0259         ;if yes then do nothing, else..
        DEC     A               ;up one line
        PUSH    AF              ;save the new line
        CALL    L04CB           ;unhighlight the current filename
        POP     AF              ;retrieve the new line
        LD      (LF3DC),A       ;update the cursor line
        CALL    L04CB           ;highlight the new filename
        JP      L0259           ;loop back to read the keyboard

;HIGHLIGHT THE TOP LEFT FILENAME
L04B8:  LD      DE,(LF3DC)      ;get coordinates of the end of last filename
        LD      (LF601),DE      ;save in a program variable
        LD      DE,0107H        ;line 7 col 1  (the top left filename)
        LD      (LF3DC),DE      ;update cursor coordinates
        CALL    L04CB           ;highlight the pointed filename
        RET                     ;ret

;INVERT THE 13 CHAS AT THE CURSOR POSITION (HIGHLIGHT THE POINTED FILENAME)
L04CB:  DI                      ;disable ints
        LD      DE,(LF3DC)      ;get the cursor coordinates
        DEC     D               ;change the cordinates
        DEC     E               ;reference to 0,0
        LD      B,E             ;pass the line to B
        PUSH    HL              ;save HL
        LD      HL,L0000        ;the start of display file in vram
        LD      A,B             ;get the line number
        CP      00H             ;is it line 0?
        JR      Z,L04E4         ;jump if yes, else..
        PUSH    DE              ;push cursor coordinates
        LD      DE,0028H        ;the line length (40 characters)
L04E0:  ADD     HL,DE           ;multiply line*40 by adding
        DJNZ    L04E0           ;40 'line' times
        POP     DE              ;pop the coordinates
L04E4:  LD      E,D             ;pass the column to E
        LD      D,00H           ;high byte = 0
        ADD     HL,DE           ;add the column
        EX      DE,HL           ;pass line*40+column to DE (vram address)
        POP     HL              ;pop HL
        LD      A,E             ;get vram address low byte
        OUT     (99H),A         ;out to the vdp
        LD      A,D             ;get vram address high byte
        OUT     (99H),A         ;out to the vdp
        LD      B,0DH           ;13 characters
        PUSH    HL              ;push HL
        LD      HL,LF604        ;filename peek buffer
L04F6:  IN      A,(98H)         ;vpeek from vram
        LD      (HL),A          ;poke in buffer
        INC     HL              ;increment buffer pointer
        DJNZ    L04F6           ;loop until the whole filename is vpeeked
        LD      HL,LF604        ;filename peek buffer
        LD      A,E             ;get vram address low byte
        OUT     (99H),A         ;out to the vdp
        LD      A,D             ;get vram addres high byte
        OR      40H             ;add the 'write' mask
        OUT     (99H),A         ;out to the vdp
        LD      A,(HL)          ;get the first byte from buffer
        AND     07FH            ;set to normal video
        OUT     (98H),A         ;out to the vdp
        INC     HL              ;point to next character
        LD      B,0CH           ;12 characters
L050F:  LD      A,(HL)          ;peek a byte from buffer
        XOR     80H             ;invert it
        OUT     (98H),A         ;vpoke the character
        INC     HL              ;increment pointer
        DJNZ    L050F           ;loop until the whole buffer is vpoked
        POP     HL              ;pop HL
        EI                      ;enable ints
        RET                     ;and ret

;'I' PRESSED - SHOW THE AVAILABLE COMMANDS
L051A:  PUSH    HL              ;push HL
        PUSH    DE              ;and DE
        LD      HL,(LF3DC)      ;get the cursor coordinates
        PUSH    HL              ;push the cursor coordinates
        LD      HL,L0000        ;the start of the display file
        LD      DE,LA000        ;buffer to save the screen
        LD      BC,0398H        ;920 chars 23 lines * 40 cols
        CALL    L0601           ;save the screen in the ram buffer
        LD      HL,L0000        ;the start of the display file
        LD      BC,0398H        ;920 chars 23 lines * 40 cols
        LD      A,20H           ;a space
        CALL    L05F9           ;clear the screen with repetitive vpoke
        LD      HL,0B05H        ;line 5 col 11
        CALL    L0629           ;print at
        LD      HL,L0C7B        ;'AVAILABLE COMMANDS' message
        CALL    L058B           ;display it
        LD      HL,080AH        ;line 10 col 8
        CALL    L0629           ;print at
        LD      HL,L0C92        ;'[S] Returns..' message
        CALL    L058B           ;display it
        LD      HL,0A0CH        ;line 12 col 10
        CALL    L0629           ;print at
        LD      HL,L0CAB        ;'[D] Another dir..' message
        CALL    L058B           ;display it
        LD      HL,050EH        ;line 14 col 5
        CALL    L0629           ;print at
        LD      HL,L0CC1        ;'[RETURN] Loads...' message
        CALL    L058B           ;display it
        LD      HL,0610H        ;line 16 col 6
        CALL    L0629           ;print at
        LD      HL,L0CDF        ;'[SPACE] Selects..' message
        CALL    L058B           ;display it
        CALL    L05B5           ;rotate bottom msg and read the keyboard
        LD      HL,LA000        ;buffer with previous screen saved
        LD      DE,L0000        ;the start of display file
        LD      BC,0398H        ;920 chars 23 lines * 40 cols
        CALL    L0609           ;retrieve the previous screen from ram buffer
        POP     HL              ;pop the cursor coordinates
        LD      (LF3DC),HL      ;restore the original value
        POP     DE              ;pop DE
        POP     HL              ;and HL
        JP      L0259           ;loop back to read the keyboard

;PRINT THE ASCII STRING IN REVERSE VIDEO POINTED BY HL AND TERMINATED WITH '/'
; In: HL pointer to the '/' terminated string
; '[' is replaced by an inverted space
; ']' is replaced by an inverted space and the following chrs are not inverted
L058B:  LD      A,(HL)          ;get a byte from string
        CP      '/'             ;is it the terminator?
        RET     Z               ;ret if yes
        CP      '['             ;is it '['?
        JR      NZ,L0599        ;jump if not
        LD      A,' '           ;else change to space
        SET     7,A             ;invert it
        JR      L05A5           ;print the char...
L0599:  CP      ']'             ;is it ']'?
        JR      NZ,L05A3        ;jump if not
        LD      A,' '           ;else change to a space
        SET     7,A             ;invert it
        JR      L05AB           ;print the character and...
L05A3:  SET     7,A             ;invert the character
L05A5:  CALL    L0621           ;display the character
        INC     HL              ;increment pointer
        JR      L058B           ;process next character
L05AB:  CALL    L0621           ;display the character
        INC     HL              ;increment pointer
        LD      A,(HL)          ;get a byte from string
        CP      '/'             ;is it the end marker?
        RET     Z               ;ret if yes
        JR      L05AB           ;else process next char

;ROTATE THE BOTTOM MESSAGE AND READ THE KEYBOARD
L05B5:  CALL    L0639           ;flush the keyboard buffer
L05B8:  CALL    L05C4           ;rotate bottom line
        CALL    L0611           ;check the keyboard buffer
        JR      Z,L05B8         ;loop back if empty
        CALL    L0619           ;get a character from keyboard
        RET                     ;ret

;ROTATE THE BOTTOM LINE ONE CHARACTER TO THE LEFT AND WAIT A LITTLE TIME
L05C4:  PUSH    HL              ;push both
        PUSH    DE              ;registers
        LD      HL,0398H        ;start of the bottom line
        CALL    L05E9           ;vpeek
        PUSH    AF              ;push the first byte
        LD      B,027H          ;39 bytes
L05CF:  INC     HL              ;point to the next byte
        CALL    L05E9           ;vpeek the next byte
        DEC     HL              ;point to the previous
        CALL    L05F1           ;overwrite the character
        INC     HL              ;increment pointer
        DJNZ    L05CF           ;process the whole line
        POP     AF              ;get the first character
        CALL    L05F1           ;vpoke it as the last one
        LD      HL,3000H        ;12288
L05E1:  DEC     HL              ;produce a
        LD      A,H             ;time delay
        OR      L               ;until HL
        JR      NZ,L05E1        ;is zero
        POP     DE              ;retrieve
        POP     HL              ;registers
        RET                     ;and ret

;VPEEK IN 'A' THE ADDRESS POINTED BY 'HL'
L05E9:  LD      IX,L004A        ;VPEEK
        CALL    L0641           ;call the bios
        RET                     ;ret

;VPOKE 'A' TO THE VRAM ADDRESS POINTED BY 'HL'
L05F1:  LD      IX,L004D        ;VPOKE
        CALL    L0641           ;call the bios
        RET                     ;ret

;VPOKE 'A' 'BC' TIMES FROM THE VRAM ADDRESS POINTED BY 'HL'
L05F9:  LD      IX,L0056        ;repetitive vpoke
        CALL    L0641           ;call the bios
        RET

;COPY VRAM TO RAM
L0601:  LD      IX,L0059        ;copy vram to ram
        CALL    L0641           ;call the bios
        RET

;COPY RAM TO VRAM
L0609:  LD      IX,L005C1       ;copy ram to vram
        CALL    L0641           ;call the bios
        RET

;CHECK THE KEYBOARD BUFFER STATE, ZF SET IF EMPTY
L0611:  LD      IX,L009C        ;CHSNS
        CALL    L0641           ;call the bios
        RET                     ;ret

;GET A CHARACTER IN 'A' FROM THE KEYBOARD BUFFER
L0619:  LD      IX,L009F        ;CHGET
        CALL    L0641           ;call the bios
        RET                     ;ret

;DISPLAY A CHARACTER AND UPDATE THE COORDINATES
L0621:  LD      IX,L00A2        ;display a character
        CALL    L0641           ;call the bios
        RET                     ;ret

;MOVE THE CURSOR TO COL 'H' AND ROW 'L' (PRINT AT)
L0629:  LD      IX,L00C6        ;position the cursor
        CALL    L0641           ;call the bios
        RET                     ;ret

;DO NOT SHOW THE FUNCTION KEYS (KEY OFF)
L0631:  LD      IX,L00CC        ;KEY OFF
        CALL    L0641           ;call the bios
        RET                     ;ret

;FLUSH THE KEYBOARD BUFFER
L0639:  LD      IX,L0156        ;KILL BUFF
        CALL    L0641           ;call the bios
        RET                     ;ret

;CALL A SUBROUTINE IN THE BIOS ROM
L0641:  LD      IY,0000H        ;bios ROM
        CALL    L001C           ;CALLSLT
        RET                     ;ret

;ENCRYPTED 40 BYTE COPYRIGHT MESSAGE (ADD 40H TO DECRYPT)
L0649:  DEFB    0E0H, 05H, 24H, 35H, 21H, 32H, 24H, 2FH ;' Eduardo'
        DEFB    0E0H, 02H, 21H, 32H, 22H, 2FH, 33H, 21H ;' Barbosa'
        DEFB    0E0H,0EDH,0E0H, 0EH, 25H, 2DH, 25H, 33H ;' - Nemes'
        DEFB     29H, 33H,0E0H, 09H, 2EH, 26H, 2FH, 32H ;'is Infor'
        DEFB     2DH, 21H, 34H, 29H, 23H, 21H,0EEH,0E0H ;'matica. '

L0671:  DEFB    0E0H            ;unused byte

;CLEAR THE SCREEN (CLS) IN SCREEN 0
L068D:  PUSH    HL              ;save HL
        PUSH    BC              ;and DE
        LD      HL,0000H        ;screen 0 display file
        LD      BC,03C0H        ;960 bytes the whole screen
        DI                      ;disable ints
        LD      A,L             ;vram low address to A
        OUT     (99H),A         ;out to the vdp
        LD      A,H             ;vram high address to A
        OR      40H             ;add the 'write mask'
        OUT     (99H),A         ;out to the vdp
L069E:  LD      A,20H           ;a space
        OUT     (98H),A         ;vpoke it
        DEC     BC              ;decrement the byte counter
        LD      A,B             ;have all the
        OR      C               ;screen bytes cleared?
        JR      NZ,L069E        ;loop back if not
        EI                      ;enable ints
        POP     BC              ;retrieve BC
        POP     HL              ;and HL
        RET                     ;ret

;DECRYPT AND PRINT THE 40 BYTE COPYRIGHT MESSAGE IN THE SCREEN BOTTOM LINE
L06AB:  LD      HL,L0649        ;encrypted 40 byte message
        LD      DE,0398H        ;start of the bottom line
        DI                      ;no ints
        LD      A,E             ;vram low address to A
        OUT     (99H),A         ;out to the vdp
        LD      A,D             ;vram high address to A
        OR      40H             ;add the 'write mask'
        OUT     (99H),A         ;out to the vdp
        LD      B,28H           ;40 characters (the whole line)
L06BC:  LD      A,(HL)          ;get an encrypted byte
        ADD     A,40H           ;decrypt the byte
        OUT     (98H),A         ;print it
        INC     HL              ;increment pointer
        DJNZ    L06BC           ;process next byte
        RET                     ;ret

L0C5F:  DEFW    0000H   ;end of the loaded basic program
L0C61:  DEFW    0000H   ;end of the program loader


L0C63:  DEFB    ' BAS-BIN 1.2 CONVERTER /'
L0C7B:  DEFB    '  AVAILABLE COMMANDS  /'
L0C92:  DEFB    '[ESC] - Returns to the system/'
L0CAB:  DEFB    '[D] - Another directory/'
L0CC1:  DEFB    '[RETURN] - Loads a file/'
L0CDF:  DEFB    '[SPACE] - Selects the files/'
L0D00:  DEFB    '  LOADING  A  FILE  /'
L0D17:  DEFB    '   SAVING  A  FILE  /'
L0D2E:  DEFB    '   INVALID  FILE   /'
QSTMRK: DEFB    '???????????'               ;'*.*' FOR THE fcb

;PROGRAM EQUS
L0FF9:  EQU     0FF9H   ;start of code header
L1000:  EQU     1000H   ;buffer for the loaded basic prog
L8000:  EQU     8000H   ;buffer for directory read 
L8001:  EQU     8001H   ;the next byte in the directory buffer
L9000:  EQU     9000H   ;buffer with filenames
LA000:  EQU     0A000H  ;buffer to save the screen

;VIDEO RAM EQUS
L0000:  EQU     0000H   ;start of screen 0 display file
L0800:  EQU     0800H   ;start of the screen 0 character generator
L0C00:  EQU     0C00H   ;start of the second half of the character generator

;SOME PROGRAM VERIABLES ARE PLACED WITHIN THE KEYBOARD BUFFER
LF600:  EQU     0F600H  ;number of filenames read from directory
LF601:  EQU     0F601H  ;coordinates of the end of the last filename
LF603:  EQU     0F603H  ;number of files displayed on current screen
LF604:  EQU     0F604H  ;13 byte buffer for the selected filename
LF620:  EQU     0F620H  ;complete screen flag 0=30 files  1=less than 30

;BDOS EQUS
L0005:  EQU     0005H   ;BDOS
L005C:  EQU     005CH   ;default first FCB
L005D:  EQU     005DH   ;first FCB second byte
L0065:  EQU     0065H   ;first FCB file extension
L006A:  EQU     006AH   ;first FCB record length
L007C:  EQU     007CH   ;first FCB current record first word
L007E:  EQU     007EH   ;first FCB current record second word
L0080:  EQU     0080H   ;first FCB current record third word

;BIOS ROM EQUS
L001C:  EQU     001CH   ;CALSLT call a routine on another slot
L004A:  EQU     004AH   ;VPEEK  vpeek a byte from vram
L004D:  EQU     004DH   ;VPOKE  vpoke a byte in vram
L0056:  EQU     0056H   ;repetitive vpoke
L0059:  EQU     0059H   ;copy vram to ram
L005C1: EQU     005CH   ;copy ram to vram
L009C:  EQU     009CH   ;CHSNS  check the keyboard buffer state
L009F:  EQU     009FH   ;CHGET  get a character from the keyboard buffer
L00A2:  EQU     00A2H   ;CHPUT  display a charecter and update the coordinates
L00C6:  EQU     00C6H   ;POSIT  move the cursor to coordinates (print at)
L00CC:  EQU     00CCH   ;ERAFNK do not show the function keys (key off)
L0156:  EQU     0156H   ;KILBUF flush the keyboard buffer
L73AC:  EQU     73ACH   ;execute the basic program

;SYSTEM VARIABLES EQUS
LF348:  EQU     0F348H  ;slot ID for disk rom
LF3AE:  EQU     0F3AEH  ;LIML40 default screen width for screen 0
LF3B0:  EQU     0F3B0H  ;LINLEN current screen width
LF3DC:  EQU     0F3DCH  ;CSRY   current cursor line
LF3DD:  EQU     0F3DDH  ;CSRX   current cursor column
LF6C2:  EQU     0F6C2H  ;VARTAB start of basic variables
LFBB0:  EQU     0FBB0H  ;ENSTOP CTRL-SHIFT-CODE-GRAPH warm boot flag 0=disable
LFBB1:  EQU     0FBB1H  ;BASROM CTRL-STOP enable flag  0=enabled
LFCA9:  EQU     0FCA9H  ;CSRMOD cursor on/off flag  0=OFF
LFCAB:  EQU     0FCABH  :CAPFLG capslock flag       0=OFF

;SYSTEM HOOKS EQUS
LFD9F:  EQU     0FD9FH  ;H-TIMI timer interrupt handling
LFF89:  EQU     0FF89H  ;H-LIST hook useed to disable the BASIC list command

;DISK ROM EQUS
L5C11:  EQU     05C16H  ;initialize disk pointers
        END
