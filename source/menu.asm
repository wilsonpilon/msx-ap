;***** Definicoes do Compilador **********************************************
.basic
.bios

.include "source\msx.asm"

;***** Rotinas principais do programa ****************************************


;***** Rotina de Entrada *****************************************************
        ORG 0C000h
;***** Area de Rascunho usada entre BASIC e ASM, tem que estar '0' no carga
POSX: db 0                      ;Usada para marcar o X da tela/bloco
POSY: db 0                      ;Usada para marcar o Y da tela/bloco
WIDT: db 0                      ;Usada para marcar LARGURA da tela/bloco
HEIG: db 0                      ;Usada para marcar ALTURA da tela/bloco
CHAR: db 0                      ;Usada para marcar o CARACTER da tela/bloco
SLEN: db 0                      ;Usada temporariamente para guardar tamanho STR
MAIN:
        ld hl,POSX              ;Armazena o endereco do Alfabeto na forma LSB/MSB
        ld a,ALFABETO%256       ;Usa POSX e POSY temporariamente
        ld [hl],a               ;O Alfabeto se encontra em fonte.asm
        ld hl,POSY
        ld a,ALFABETO/256
        ld [hl],a

        ld hl,CHOICE            ;Programa a USR0 na execucao
        ld [USRTAB],hl          ; DEFUSR0
        ld hl,NPRIN             ;Programa a USR1 na execucao
        ld [USRTAB+2],hl        ; DEFUSR1
        ld hl,IPRIN             ;Programa a USR2 na execucao
        ld [USRTAB+4],hl        ; DEFUSR2
        ld hl,WINDS             ;Programa a USR3 na execucao
        ld [USRTAB+6],hl        ;DEFUSR3
        ret
;***** Escolhe Rotinas pelo parametro USR(x)**********************************
CHOICE:
        ld a,[FACLO]            ;A USR0 so aceita inteiro como parametro
        cp 0                    ;Modo SCREEN 1 mix SCREEN 2
        jp z,SCRNIV
        cp 1                    ;SubFuncao prepara alfabeto na VRAM
        jp z,CPALPH
        cp 2                    ;SubFuncao 'Desktop' preenche tela com character
        jp z,DSKTOP
        cp 3                    ;SubFuncao troca as cores do alfabeto
        jp z,COLORS
        cp 4                    ;SubFuncao preenche bloco tela/char
        jp z,FBLOK
        cp 5                    ;SubFuncao salva tela na RAM
        jp z,SVSCR
        cp 6                    ;SubFuncao carrega tela da RAM
        jp z,LDSRC
        ret

SCRNIV:
        ld a,7                  ;Ciano na cor de frente
        ld [FORCLR],a
        ld a,1                  ;Preto na cor de fundo
        ld [BAKCLR],a
        ld a,1                  ;Pretoo na cor de borda
        ld [BDRCLR],a
        call INIGRP             ;Prepara tabelas da SCREEN 2
        ld a,20h                ;WIDTH 32 na SCREEN 1
        ld [LINL32],a
        call INIT32             ;Prepara tabelas da SCREEN 1
        call ERAFNK             ;Esconde as telcas de funcao do display
        call SETGRP             ;Coloca apenas o VDP em SCREEN 2
        ret


;***** Desktop ***************************************************************
DSKTOP:
        ld a,[CHAR]             ;Caracter de preenchimento (em geral 0)
        ld hl,1820h             ;Inicio da area de nomes (6144 + 32 segunda linha)
        ld bc,2C0h              ;Preenche toda a tela exceto primeira e segunda linha
        call FILVRM
        ld hl,1800h             ;Cabecalo 32 caracteres do fim da tabela na linha 0
        ld a,0E0h               ;Inicio da tabela de caracteres
        ld b,31                 ;32 reservados para titulo
.loop:
        push af                 ;Slava registradores afetados
        call WRTVRM             ;Escreve na VRAM
        pop af                  ;Recupera registradores afetados
        inc a                   ;Proximo Caractere da tabela
        inc hl                  ;Proxima posicao da tela
        djnz .loop              ;loop 32x
        ret

;***** Define a colorizacao dos caracteres ***********************************
COLORS:
        ; ***** Blocos iniciais (decoracoes)
        ld b,16                 ;Caracteres do 0 ao 15 do 1/3 da tela
        ld de, 2000h            ; inicio da area de cores SCREEN IV
        ld hl, CDECO            ; degrade azul
        call CHGBLK             ; muda cores

        ld b,16                 ;Caracteres do 0 ao 15 do 2/3 da tela
        ld de, 2800h            ; inicio da area de cores SCREEN IV
        ld hl, CDECO            ; degrade azul
        call CHGBLK             ; muda cores

        ld b,16                 ;Caracteres do 0 ao 15 do 3/3 da tela
        ld de, 3000h            ; inicio da area de cores SCREEN IV
        ld hl, CDECO            ; degrade azul
        call CHGBLK             ; muda cores

        ; ***** Blocos iniciais (janelas, quadros)
        ld b,16                 ;Caracteres do 16 ao 31 do 1/3 da tela
        ld de, 2080h            ; inicio da area de cores SCREEN IV
        ld hl, CWIND            ; degrade amarelo
        call CHGBLK             ; muda cores

        ld b,16                 ;Caracteres do 16 ao 31 do 2/3 da tela
        ld de, 2880h            ; inicio da area de cores SCREEN IV
        ld hl, CWIND            ; degrade amarelo
        call CHGBLK             ; muda cores

        ld b,16                 ;Caracteres do 16 ao 31 do 3/3 da tela
        ld de, 3080h            ; inicio da area de cores SCREEN IV
        ld hl, CWIND            ; degrade amarelo
        call CHGBLK             ; muda cores

        ; ***** Blocos finais (Revista CPU N. NN)
        ld b,32                 ;Caracteres do 224 ao 255 do 1/3 da tela
        ld de, 2700h            ; inicio da area de cores do caracter 224
        ld hl, CTITL            ; degrade vermelho
        call CHGBLK             ; muda cores

        ld b,32                 ;Caracteres do 224 ao 255 do 2/3 da tela
        ld de, 2F00h            ; inicio da area de cores do caracter 224
        ld hl, CTITL            ; degrade vermelho
        call CHGBLK             ; muda cores

        ld b,32                 ;Caracteres do 224 ao 255 do 3/3 da tela
        ld de, 3700h            ; inicio da area de cores do caracter 224
        ld hl, CTITL            ; degrade vermelho
        call CHGBLK             ; muda cores

        ; ***** Blocos A-Z/a-z Normais e Ivertidos
        ld b, 96                ;Caracteres de 32 a 127 1/3 da tela
        ld de, 2100h            ; inicio da area de cores do caracter 64
        ld hl, CCHAR            ; degrade verde
        call CHGBLK             ; muda cores
        ld b, 96                ;Caracteres de 128 a 223 1/3 da tela
        ld de, 2400h            ; inicio da area de cores do caracter 128
        ld hl, CICHR            ; degrade verde
        call CHGBLK             ; muda cores
        
        ld b, 96                ;Caracteres de 32 a 127 2/3 da tela
        ld de, 2900h            ; inicio da area de cores do caracter 64
        ld hl, CCHAR            ; degrade verde
        call CHGBLK             ; muda cores
        ld b, 96                ;Caracteres de 128 a 223 2/3 da tela
        ld de, 2C00h            ; inicio da area de cores do caracter 128
        ld hl, CICHR            ; degrade verde
        call CHGBLK             ; muda cores

        ld b, 96                ;Caracteres de 32 a 127 3/3 da tela
        ld de, 3100h            ; inicio da area de cores do caracter 64
        ld hl, CCHAR            ; degrade verde
        call CHGBLK             ; muda cores
        ld b, 96                ;Caracteres de 128 a 223 3/3 da tela
        ld de, 3400h            ; inicio da area de cores do caracter 128
        ld hl, CICHR            ; degrade verde
        call CHGBLK             ; muda cores
        ret

;***** Coloriza um bloco de caracteres no modo SCREEN IV *********************
CHGBLK:
        push bc                 ;Salva os registradores afetados
        push de
        push hl
        ld bc, 8h               ;8 linhas por caracter
        call LDIRVM             ; Transfere da RAM para VRAM
        pop hl                  ;Recupera parte dos registradores
        pop de
        ex de,hl                ;Soma 8 para o proximo caracter
        ld bc,0008h
        add hl,bc
        ex de,hl
        pop bc                  ;Recupera resto dos registradores
        djnz CHGBLK             ;Loop para o proximo caracter
        ret

;***** FBLOK *****************************************************************
; Funcao: Preenche um bloco da VRAM com um caractere especifico. O bloco
; nao e contiguo, pensado para criar janelas.
; Os agrumentos vem do BASIC e sao auto descritivos, basta dar POKE nos
; enderecos
FBLOK:
        call CALCXY
        ld a,[HEIG]             ;Altura do bloco
        ld b,a
.loop:
        push hl                 ;Salva registradores
        push bc
        ld a,[WIDT]             ;Largura do Bloco
        ld c,a
        ld b,0
        ld a,[CHAR]             ;Caracter de Preenchimento
        call FILVRM             ;Preenche o tamanho da largura do bloco
        pop bc                  ;Restaura registradores
        pop hl
        ld e,32                 ;Tamanho da tela (SCREEN IV)
        ld d,0
        add hl,de
        djnz .loop              ;Laco para cada linha
        ret


;***** LDSTR ******************************************************************
; Carrega uma STRING passada por parametro em USR("") na memoria em STR
LDSTR:
        cp 3                    ;E String?
        ret nz                  ;nao, volta
        ex de,hl                ;HL descritor STRING
        ld b,[hl]               ;B tamanho
        ld a,b                  
        ld [SLEN],a             ;WIDTH tem tamnho da STRING
        inc hl
        ld e,[hl]               ;LSB Endereco
        inc hl
        ld d,[hl]               ;MSB DE String
        inc b
        ld hl,STR               ;Armazena localmente
.loop:
        dec b                   ;Final?
        ret z
        ld a,[de]               ;Armazena caractere
        ld [hl],a
        inc hl
        inc de
        jr .loop                ;Proximo caractere
        ret
.include "source\windows.asm"
.include "source\video.asm"
.include "source\matematica.asm"

;***** Area de Dados do Programa *********************************************
;***** Cores do alfabeto SCRNIV usadas pelo programa *************************
; 0 -> Transparente             8 -> Vermelho medio
; 1 -> Preto                    9 -> Vermelho claro
; 2 -> Verde medio              A -> Amarelo escuro
; 3 -> Verde claro              B -> Amarelo claro
; 4 -> Azul escuro              C -> Verde escuro
; 5 -> Azul medio               D -> Roxo
; 6 -> Vermelho escuro          E -> Branco escuro
; 7 -> Azul claro               F -> Branco claro
;***** Cores do titulo *******************************************************
CTITL:
        db 061h, 061h, 061h, 081h, 081h, 081h, 091h, 091h
;***** Cor dos caracteres padrao *********************************************
CCHAR:
        db 0C1h, 0C1h, 0C1h, 021h, 021h, 021h, 031h, 031h
;***** Cor dos caracteres invertidos
CICHR:
        db 0CAh, 0CAh, 0CAh, 02Ah, 02Bh, 02Bh, 03Bh, 03Bh
;***** Cor dos caracreres de decoracao
CDECO:
        db 041h, 041h, 041h, 051h, 051h, 051h, 071h, 071h
;***** Cor dos caracteres das janelas
CWIND:
        db 0A1h, 0A1h, 0A1h, 0A1h, 0B1h, 0B1h, 0B1h, 0B1h
STR:
        ds 40
STR2:
        ds 40
STR3:
        ds 40
SCRN:
        ds 768
LSBMSB:
        dw 0
.include "source\fonte.asm"
