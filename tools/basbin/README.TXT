BAS-BIN.COM is a file converter, it converts BASIC (loadable) files
into BIN (bloadable) files.
This program belongs to a Brazilian utility package called Nemesis Tools.
The files converted by this utility hang my SVI738, this fact made me to
disassembly, bug-fix and slightly enhance the program.

Files description
BAS-BIN.COM     original com file from the Nemesis Tools package.
BAS-BIN.ASM     source of the above.
BAS-BIN2.COM    bugfixed version of BAS-BIN.
BAS-BIN2.COM    source of the above.

I made the following changes to the original.

Delay added to fix VDP access timing on non Brazilian MSX's.
Orphaned code and data removed.
Program loader rewrittem (it stops drives in any MSX).
Deletion of the selected basic program feature removed.
Directory read routine totally rewritten (now reads any kind of MSX disk).
File read/write routines now work on current drive.
Ugly character generator removed.
Exit key changed to ESC and help key changed to 'H'.
Messages translated to English.

Hope you find this program useful.     Luis C. Grosso


CONVERSOR BASIC-BINARIO (BAS-BIN.COM)

     Usa-se para converter programas em formato BASIC para o BINARIO. Os programas que eram carregados por "LOAD" serao carregados por "BLOAD". Este utilitario funciona nos moldes dos programas da versao anterior do MSX-DOS TOOLS da NEMESIS INFORMATICA LTDA. basta selecionar o arquivo com as setas e [RETURN]. Pressione [I] para ver as instrucoes e [S] para voltar ao sistema.
