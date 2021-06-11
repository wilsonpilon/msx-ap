;***** Imprime uma string armazenada em RAM (STR) na SCREEN IV ***************
; POSY e passada via BASIC representa a linha da impressao
; POSX tambem passada via BASIC representa a coluna
; WIDT e calculada em outras rotinas que usam NPRIN e tem o tamanho da string
PTSTR:
        call CALCXY             ;Posiciona VRAM
        ex de,hl                ;Swap de registradores
        ld a,[WIDT]
        ld b,0
        ld c,a
        ld hl,STR
        call LDIRVM
        ret


;***** Calcula o endereco da VRAM a partir de POSX e POSY ********************
CALCXY:
        ld a,[POSY]             ;Linha inicial
        ld h,a
        ld e,32                 ;WIDTH do programa (SCREENIV)
        call MULHXE
        ld a,[POSX]             ;Coluna inicial
        ld e,a
        ld d,0
        add hl,de
        ld de,1800h             ;Tabela de nomes (SCREEN IV)
        add hl,de
        ret


;***** SVSCR *****************************************************************
; Salva a tela corrente na RAM para auxiliar no tracado de pseudo janelas
SVSCR:
        ld bc,768               ;Tamanho da SCREEN IV
        ld de,SCRN              ;Destino na RAM
        ld hl,1800h             ;Inicio tabela de nomes
        call LDIRMV             ;Transfere
        ret
;***** LDSCR *****************************************************************
; Carrega tela da RAM na corrente para auxiliar no tracado de pseudo janelas
LDSRC:
        ld bc,768               ;Tamanho da SCREEN IV
        ld de,1800h             ;Inicio tabela de nomes
        ld hl,SCRN              ;Origem na RAM
        call LDIRVM             ;Transfere
        ret

;***** Rotina para impressao de String na Screen IV **************************
NPRIN:
        call LDSTR              ;Carrega a string de USR em STR
        call PTSTR              ;Chama rotina de impressao
        ret
;***** Inverte uma String e a imprime na Screen IV ***************************
IPRIN:
        call LDSTR              ;Carrega a string de USR em STR
        ld a,[SLEN]             ;Tamanho da STRING
        ld b,a                  ;Laco para inverter STRING
        ld hl,STR               ;Endereco da STRING
.loop:
        ld a,[hl]               ;Aponta para o caractere
        add a,96                ;Desloca para o invertido
        ld [hl],a               ;Troca o original
        inc hl                  ;proximo caracter
        djnz .loop              ;laco
        call PTSTR              ;Chama rotina de impressao
        ret
