;***** Rotina para criar janelas na Screen IV ********************************
WINDS:
        call LDSTR              ;Carrega string do titulo
        call DRWIND             ;Desenha Janela
        ret


DRWIND:
        ld hl,STR               ;Copia a string original deslocada de 1
        ld de,STR3              ; de STR para STR3
        inc de                  ;desloca
        ld bc,20h               ;32 caracteres
        ldir                    ;backup
        ld hl,STR3              ;Adiciona decoracao no inicio titulo
        ld [hl],12h

        ld a,[SLEN]             ;Adiciona decoracao no fim do titulo
        inc a
        ld e,a
        ld d,0
        add hl,de
        ld [hl],10h

        ld hl,STR2              ;Montagem da janela
        ld a,10h                ;Canto superior esquerdo
        ld [hl],a
        inc hl
        ld a,[WIDT]             ;Largura da Janela
        dec a
        dec a
        ld b,a
.loop:                          ;Completa largura da janela
        ld [hl],11h             ;Barra superior
        inc hl
        djnz .loop              ;laco
        ld [hl],12h             ;Canto superior direito
        ld hl,STR2              ;Transfere a STRING decorada
        ld de,STR               ;Para a area principal
        ld bc,20h               ; 32 caracteres
        ldir
        call PTSTR              ;Imprime a String

        call CALCXY             ;Recalcula VRAM
        ld a,[HEIG]
        dec a
        dec a
        ld b,a
.loop2:
        push bc
        ld d,0
        ld e,20h
        add hl,de
        push hl
        ld a,13h
        call WRTVRM
        ld a,[WIDT]
        dec a
        ld d,0
        ld e,a
        add hl,de
        ld a,14h
        call WRTVRM
        pop hl
        pop bc
        djnz .loop2

        ld b,20h
        ld a,20h
.loop3:
        ld hl,STR2
        ld [hl],a
        inc hl
        djnz .loop3

        ld hl,STR2              ;Montagem da janela
        ld a,15h                ;Canto superior esquerdo
        ld [hl],a
        inc hl
        ld a,[WIDT]             ;Largura da Janela
        dec a
        dec a
        ld b,a
.loop4:                         ;Completa largura da janela
        ld [hl],16h             ;Barra superior
        inc hl
        djnz .loop4             ;laco
        ld [hl],17h             ;Canto superior direito
        ld hl,STR2              ;Transfere a STRING decorada
        ld de,STR               ;Para a area principal
        ld bc,20h               ; 32 caracteres
        ldir

        ld a,[POSY]
        ld [CHAR],a
        ld a,[POSY]
        ld h,0
        ld l,a
        ld a,[HEIG]
        ld d,0
        ld e,a
        dec hl
        add hl,de
        ld a,l
        ld [POSY],a

        call PTSTR              ;Imprime a String

        ld a,[POSX]
        inc a
        ld [POSX],a
        ld a,[CHAR]
        ld [POSY],a
        ld hl,STR3              ;Copia a string backup
        ld de,STR               ; de STR3 para STR
        ld bc,20h               ;32 caracteres
        ldir                    ;backup
        ld a,[SLEN]
        inc a
        inc a
        ld [WIDT],a
        call PTSTR

        ret
