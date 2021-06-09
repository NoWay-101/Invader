; ==============================
                    ; DÃ©finition des constantes
                    ; ==============================

                    ; MÃ©moire vidÃ©o
                    ; ------------------------------

VIDEO_START         equ     $ffb500                         ; Adresse de dÃ©part
VIDEO_WIDTH         equ     480                             ; Largeur en pixels
VIDEO_HEIGHT        equ     320                             ; Hauteur en pixels
VIDEO_SIZE          equ     (VIDEO_WIDTH*VIDEO_HEIGHT/8)    ; Taille en octets
BYTE_PER_LINE       equ     (VIDEO_WIDTH/8)                 ; Nombre d'octets par ligne
VIDEO_BUFFER        equ     (VIDEO_START-VIDEO_SIZE)		; Tampon vidéo

                    ; Bitmaps
                    ; ------------------------------

WIDTH               equ     0                               ; Largeur en pixels
HEIGHT              equ     2                               ; Hauteur en pixels
MATRIX              equ     4                               ; Matrice de points

; Envahisseurs
; ------------------------------


INVADER_PER_LINE    equ		10
INVADER_PER_COLUMN  equ		5
INVADER_COUNT       equ     INVADER_PER_LINE*INVADER_PER_COLUMN
INVADER_STEP_X      equ	4
INVADER_STEP_Y      equ	8
INVADER_X_MIN       equ	0
INVADER_X_MAX       equ (VIDEO_WIDTH-(INVADER_PER_LINE*32))
SHOT_X_MIN  		equ	8
SHOT_X_MAX  		equ (VIDEO_WIDTH-8)
SHIP_STEP           equ 4; Pas du vaisseau
SHIP_SHOT_STEP      equ 5; Pas d'un tir de vaisseau
SHIP_SG_SHOT_STEP_X equ 2; 
SHIP_SG_SHOT_STEP_Y equ 5; 
SGRELOADTIME		equ 100


INVADER_SHOT_STEP   equ 1; Pas d'un tir d'envahisseur
INVADER_C_SHOT_STEP_X equ 3; Pas d'un tir d'envahisseur
INVADER_C_SHOT_STEP_Y equ 3; Pas d'un tir d'envahisseur




INVADER_SHOT_MAX    equ     6
INVADER_C_SHOT_MAX  equ     10

SHIP_SG_SHOT_MAX  	equ    3




SHIP_WIN 			equ 4
SHIP_DEAD 			equ 1
SHIP_COLLIDING 		equ 2
INVADER_LOW 		equ 3


; Sprites
; ------------------------------
STATE               equ 0; État de l'affichage
X                   equ 2; Abscisse
Y                   equ 4; Ordonnée
BITMAP1             equ 6; Bitmap no 1
BITMAP2             equ 10; Bitmap no 2
TYPE				equ	14; type de mob
CURRENTSTEP			equ	16; current step
LIFE				equ 18; nombre de vie

SIZE_OF_SPRITE      equ 20; Taille d'un sprite en octets

HIDE                equ 0; Ne pas afficher le sprite
SHOW                equ 1; Afficher le sprite
TSHIP				equ 0; val du ship
TSHIPSHOTGUN		equ 4
TA					equ 1; val du b
TB					equ 2; val du b
TC					equ 3; val du c

SHIP_LIFE			equ 3
A_LIFE				equ 2
B_LIFE				equ 1
C_LIFE				equ 1


                    ; ==============================
                    ; Initialisation des vecteurs
                    ; ==============================

                    org     $0

vector_000          dc.l    VIDEO_BUFFER                    ; Valeur initiale de A7
vector_001          dc.l    Main                            ; Valeur initiale du PC



                    ; ==============================
                    ; Programme principal
                    ; ==============================

                    org     $500


                    
                    ; ==============================
                    ; Sous-programmes
                    ; ==============================org$0vector_000          dc.l$ffb500vector_001          dc.l    Main

PixelToByte         ; Taille en pixels + 7 -> D3.W
                    addq.w  #7,d3
                    
                    ; D3.W/8 -> D3.W
                    lsr.w   #3,d3

                    ; Sortie du sous-programme.
                    rts

CopyBitmap          ; Sauvegarde les registres dans la pile.
                    movem.l d3/d4/a0/a1,-(a7)

                    ; Largeur en octets -> D3.W
                    move.w  WIDTH(a0),d3
                    jsr     PixelToByte

                    ; Nombre d'itÃ©rations - 1 (car DBRA) -> D4.W
                    ; Nombre d'itÃ©rations = Hauteur en pixels
                    move.w  HEIGHT(a0),d4
                    subq.w  #1,d4

                    ; Adresse de la matrice de points -> A0.L
                    lea     MATRIX(a0),a0

\loop               ; Copie une ligne de la matrice.
                    jsr     CopyLine

                    ; Passe Ã  l'adresse vidÃ©o de ligne suivante.
                    adda.l  #BYTE_PER_LINE,a1

                    ; Reboucle tant qu'il y a des lignes Ã  afficher.
                    dbra    d4,\loop

                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d3/d4/a0/a1
                    rts


                 
FillScreen          ; Sauvegarde les registres dans la pile.
					movem.l d7/a0,-(a7)
					
					; Fait pointer A0 sur la mémoire vidéo.
					; Cette instruction est identique à : 
					movea.l #VIDEO_START,a0
					lea     VIDEO_START,a0
					
					; Initialisation du compteur de boucle (D7.W).
					; La copie se fera sur 32 bits, c'est-à-dire sur 4 octets.
					; Le nombre d'itérations est donc la taille en octets divisée par 4.
					; Le test de sortie se fera à l'aide de DBRA,
					; donc D7.W doit contenir le nombre d'itérations moins 1 (cf. cours).
					move.w #VIDEO_SIZE/4-1,d7
					
\loop              	; Copie la donnée dans la mémoire vidéo
					; et passe à l'adresse suivante.
					move.l d0,(a0)+
					dbra d7,\loop
					
					; Restaure les registres puis sortie.
					movem.l (a7)+,d7/a0
					rts
					



HLines              ; Sauvegarde les registres dans la pile.
                    movem.l d6/d7/a0,-(a7)
                    ; Fait pointer A0 sur la mémoire vidéo.
                    lea     VIDEO_START,a0
                    ; D7.W = Compteur de boucle
                    ; = Nombre d'itérations - 1 (car DBRA).
                    ; ------------------------------
                    ; Nombre d'itérations = Nombre de rayures blanches et noires
                    ; Hauteur d'un rayure blanche = 8 pixels
                    ; Hauteur d'un rayure noire = 8 pixels
                    ; Nombre de rayures blanches et noires = Hauteur de la fenêtre / 2x8 
                    move.l #VIDEO_HEIGHT/16-1,d7

\loop               ; Dessine une rayure blanche (8 lignes blanches).
                    ; ------------------------------
                    ; D6.W = Compteur de boucles
                    ;      = Nombre d'itérations - 1 (car DBRA)
                    ; ------------------------------
                    ; Nombre d'itérations = Nombre de mots longs
                    ; Nombre de mots longs = Nombre d'octets / 4
                    ; Nombre d'octets = BYTE_PER_LINE x Hauteur d'une rayure blanche ; Hauteur d'une ligne = 8 pixels
                    move.w #BYTE_PER_LINE*8/4-1,d6



\white_loop         move.l #$ffffffff,(a0)+
                    dbra d6,\white_loop

                    ; Dessine une rayure noire (8 lignes noires).
                    move.w  #BYTE_PER_LINE*8/4-1,d6

\black_loop         clr.l   (a0)+
                    dbra    d6,\black_loop
                    ; Reboucle tant qu'il reste des rayures ; blanches et noires à dessiner.
                    dbra d7,\loop
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d6/d7/a0
                    rts



WhiteSquare32       ; Sauvegarde les registres dans la pile.
                    movem.l d7/a0,-(a7)
                    ; Fait pointer A0 sur l'emplacement du carré.
                    ; ------------------------------
                    ; Centrage horizontal :
                    ; La largeur ci-dessous est mesurée en octets.
                    ; Largeur totale = Largeur de la fenêtre = BYTE_PER_LINE
                    ; Largeur du carré = 4 octets (32 pixels)
                    ; Déplacement horizontal en octets
                    ; = (Largeur totale - Largeur du carré) / 2
                    ; ------------------------------
                    ; Centrage vertical :
                    ; La hauteur ci-dessous est mesurée en pixels.
                    ; Hauteur totale = Hauteur de la fenêtre = VIDEO_HEIGHT
                    ; Hauteur du carré = 32 pixels
                    ; Déplacement vertical en pixels
                    ; = (Hauteur totale - Hauteur du carré) / 2
                    ; Déplacement vertical en octets
                    ; = Déplacement vertical en pixels x BYTE_PER_LINE
                    ; ------------------------------
                    ; Adresse du carré
                    ; = VIDEO_START + (Déplacement horizontal) + (Déplacement vertical) 
                    lea VIDEO_START+((BYTE_PER_LINE-4)/2)+(((VIDEO_HEIGHT-32)/2)*BYTE_PER_LINE),a0
                    ; Initialisation du compteur de boucle (D7.W).
                    ; Nombre d'itérations = Nombre de lignes du carré (32). 
                    ; D7.W = Nombre d'itération - 1 (car DBRA).
                    move.w #32-1,d7
\loop               ; Copie 32 pixels blancs dans la mémoire vidéo 
                    ; et passe à l'adresse suivante.
                    move.l #$ffffffff,(a0)
                    adda.l #BYTE_PER_LINE,a0
                    dbra    d7,\loop
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d7/a0
                    rts

WhiteSquare128      ; Sauvegarde les registres dans la pile.
                    movem.l d7/a0,-(a7)
                    ; Fait pointer A0 sur l'emplacement du carré.
                    ; ------------------------------
                    ; Centrage horizontal :
                    ; La largeur ci-dessous est mesurée en octets.
                    ; Largeur totale = Largeur de la fenêtre = BYTE_PER_LINE
                    ; Largeur du carré = 16 octets (128 pixels)
                    ; Déplacement horizontal en octets
                    ; = (Largeur totale - Largeur du carré) / 2
                    ; ------------------------------
                    ; Centrage vertical :
                    ; La hauteur ci-dessous est mesurée en pixels.
                    ; Hauteur totale = Hauteur de la fenêtre = VIDEO_HEIGHT
                    ; Hauteur du carré = 128 pixels
                    ; Déplacement vertical en pixels
                    ; = (Hauteur totale - Hauteur du carré) / 2
                    ; Déplacement vertical en octets
                    ; = Déplacement vertical en pixels x BYTE_PER_LINE
                    ; ------------------------------
                    ; Adresse du carré
                    ; = VIDEO_START + (Déplacement horizontal) + (Déplacement vertical) 
                    lea VIDEO_START+((BYTE_PER_LINE-16)/2)+(((VIDEO_HEIGHT-128)/2)*BYTE_PER_LINE),a0
                    ; Initialisation du compteur de boucle (D7.W).
                    ; Nombre d'itérations = Nombre de lignes du carré (128). ; D7.W = Nombre d'itération - 1 (car DBRA).
                    move.w #128-1,d7

\loop               ; Copie 128 pixels blancs dans la mémoire vidéo ; et passe à l'adresse suivante.
                    move.l #$ffffffff,(a0)
                    move.l #$ffffffff,4(a0)
                    move.l #$ffffffff,8(a0)
                    move.l #$ffffffff,12(a0)
                    adda.l #BYTE_PER_LINE,a0
                    dbra   d7,\loop
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d7/a0
                    rts
 

WhiteLine           ; Sauvegarde les registres dans la pile.
                    movem.l d0/a0,-(a7)
                    ; Nombre d'itérations = Taille de la ligne en octets 
                    ; D0.W = Nombre d'itérations - 1 (car DBRA)
                    subq.w #1,d0

\loop               ; Copie 8 pixels blancs et passe à l'adresse suivante.
                    move.b  #$ff,(a0)+
                    dbra    d0,\loop
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d0/a0
                    rts


WhiteSquare         ; Sauvegarde les registres dans la pile.
                    movem.l d0-d2/a0,-(a7)
                    ; D2.W = Taille en pixels du carré.
                    move.w  d0,d2
                    lsl.w   #3,d2
                    ; Fait pointer A0 sur la mémoire vidéo.
                    lea     VIDEO_START,a0
                    ; Centre horizontalement.
                    ; A0 + (Largeur totale - largeur carré) / 2 
                    move.w #BYTE_PER_LINE,d1
                    sub.w d0,d1
                    lsr.w #1,d1
                    adda.w d1,a0
                    ; Centre verticalement.
                    ; A0 + ((Hauteur totale - Hauteur carré) / 2) * BYTE_PER_LINE 
                    move.w #VIDEO_HEIGHT,d1
                    sub.w d2,d1
                    lsr.w #1,d1
                    mulu.w #BYTE_PER_LINE,d1
                    adda.w d1,a0
                    ; Nombre d'itérations = Taille en pixels
                    ; D2.W = Nombre d'itérations - 1 (car DBRA) 
                    subq.w #1,d2


\loop               ; Affiche la ligne en cours et passe à la ligne suivante.
                    jsr     WhiteLine
                    adda.l  #BYTE_PER_LINE,a0
                    dbra    d2,\loop
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d0-d2/a0
                    rts
                    
CopyLine           	; Sauvegarde les registres.org$0vector_000          dc.l$ffb500vector_001          dc.l    Main
					movem.l d1-d4/a1,-(a7)
					
					; Nombre d'itérations = Largeur en octets
					; Nombre d'itérations - 1 (car DBRA) -> D3.W
					subq.w #1,d3
					
\loop				; Octet à copier -> D1.B et D2.B
					move.b (a0)+,d1
					move.b d1,d2
					
					; Décale D1.B vers la droite de D0 bits.
					lsr.b d0,d1
					
					; Décale D2.B vers la gauche de (8 - D0) bits.
					moveq.l #8,d4
					sub.w d0,d4
					lsl.b d4,d2
					; Copie D1.B et D2.B dans la mémoire vidéo.
					or.b d1,(a1)+
					or.b d2,(a1)
					
					; Reboucle tant qu'il y a des octets à copier.
					dbra d3,\loop
					; Restaure les registres puis sortie.
					movem.l (a7)+,d1-d4/a1
					rts
					
PixelToAddress  		; Sauvegarde les registres.
					movem.l d1/d2,-(a7)
					
					; Détermine le nombre d'octets à ajouter en abscisse.
					; Divise l'abscisse par 8 :
					; Quotient -> D1.W (nombre d'octets)
					; Reste -> D0.W (décalage)
					move.w d1,d0
					lsr.w #3,d1
					andi.w #%111,d0
					
					; Détermine le nombre d'octets à ajouter en ordonnée.
					; Multiplie l'ordonnée par le nombre d'octets par ligne.
					; D2.W * BYTE_PER_LINE -> D2.L
					mulu.w #BYTE_PER_LINE,d2
					
					; Détermine l'adresse vidéo.
					; VIDEO_START + Nombre d'octets à ajouter en abscisse et en ordonnée.
					lea     VIDEO_BUFFER,a1
					adda.w d1,a1
					adda.l d2,a1
					; Restaure les registres puis sortie.
					movem.l (a7)+,d1/d2
					rts

PrintBitmap			; Sauvegarde les registres.
					movem.l  d0/a1,-(a7)
					
					; Adresse vidéo -> A1.L
					; Décalage -> D0.W
					jsr       PixelToAddress
					
					; Copie la matrice de points du bitmap dans la mémoire vidéo.
					jsr     CopyBitmap
					
\quit				; Restaure les registres puis sortie.
					movem.l (a7)+,d0/a1
					rts
					
					
					
					
PrintChar           incbin "PrintChar.bin"					
					
					
					
					
Print           ; Sauvegarde les registres dans la pile.
					movem.l d0/d1/a0,-(a7)
\loop           
					; Charge un caractère de la chaîne dans D0.
					; Si le caractère est nul, il s'agit de la fin de la chaîne.
					; On peut sortir du sous-programme.
					move.b (a0)+,d0
					beq  \quit
					; Affiche le caractère.
					jsr     PrintChar
					; Incrémente la colonne d'affichage du caractère,
					; et reboucle.
					addq.b #1,d1
					bra  \loop
\quit           ; Restaure les registres puis sortie.
					movem.l (a7)+,d0/d1/a0
					rts
					
					
					
					
					
					

ClearScreen         ; Sauvegarde les registres.
					move.l d0,-(a7)
					
					; Remplit la mémoire vidéo avec des zéros.
					moveq.l #0,d0
					jsr     FillScreen
					; Restaure les registres puis sortie.
					move.l (a7)+,d0
					rts

BufferToScreen      ; Sauvegarde les registres.
                    movem.l d7/a0/a1,-(a7) 
                    ; Tampon vidéo -> A0.L
                    lea VIDEO_BUFFER,a0 
                    ; mémoire vidéo -> A1.L
                    lea     VIDEO_START,a1
                    ; Nombre d'itérations - 1 -> D7.W (car DBRA) 
                    ; Nombre d'itérations = Nombre de mots longs 
                    move.w #VIDEO_SIZE/4-1,d7
\loop               ; Copie un mot long du tampon vers la mémoire vidéo.
                    move.l (a0),(a1)+
                    ; Met à 0 le mot long du tampon qui vient d'être copié.
                    clr.l (a0)+
                    ; Reboucle tant qu'il y a des mots longs à copier.
                    dbra    d7,\loop
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d7/a0/a1
                    rts

PrintSprite         ; Sauvegarde les registres.
                    movem.l d1/d2/a0,-(a7)
                    ; Si le sprite ne doit pas être affiché, on quitte.
                    cmp.w   #HIDE,STATE(a1)
                    beq     \quit
                    ; Affiche le sprite.
                    move.w  X(a1),d1
                    move.w  Y(a1),d2
                    movea.l BITMAP1(a1),a0
                    jsr     PrintBitmap
\quit               ; Restaure les registres puis sortie.
                    movem.l (a7)+,d1/d2/a0
                    rts

PrintShipLife		; affiche les vie 
					movem.l d1/d2/d7/a0/a1,-(a7)
					
					lea Ship,a1
					tst LIFE(a1)
					beq \quit
					move.w LIFE(a1),d7
					sub #1,d7
					
					move.w #10,d1
					move.w #10,d2
					lea Heart,a0
					
\loop				jsr     PrintBitmap
					
					add.w #20,d1
					dbra d7,\loop

\quit				movem.l (a7)+,d1/d2/d7/a0/a1
                    rts
					
	


IsOutOfX        ; Sauvegarde les registres.
                move.l  d1,-(a7)
                ; Si l'abscisse est négative, le bitmap sort de l'écran. 
                ; On renvoie true.
                tst.w d1
                bmi \true
                ; Abscisse à la droite du bitmap -> D1.W
                add.w   WIDTH(a0),d1
                ; Si l'abscisse à la droite du bitmap
                ; est supérieure stricte à la largeur de l'écran, 
                ; le bitmap sort de l'écran.
                ; On renvoie true.
                cmp.w #VIDEO_WIDTH,d1
                bgt \true
                ; Sinon, le bitmap ne sort pas de l'écran.
                ; On renvoie false.
\false          ; Sortie qui renvoie false (Z = 0).
                move.l (a7)+,d1
                andi.b  #%11111011,ccr
                rts
\true           ; Sortie qui renvoie true (Z = 1).
                move.l (a7)+,d1
                ori.b   #%00000100,ccr
                rts

IsOutOfY            ; Sauvegarde les registres.
                    move.l  d2,-(a7)
                    ; Si l'ordonnée est négative, le bitmap sort de l'écran. ; On renvoie true.
                    tst.w d2
                    bmi \true
                    ; Ordonnée juste sous le bitmap -> D2.W
                    add.w   HEIGHT(a0),d2
                    ; Si l'ordonnée juste sous le bitmap
                    ; est supérieure stricte à la hauteur de l'écran, ; le bitmap sort de l'écran.
                    ; On renvoie true.
                    cmp.w #VIDEO_HEIGHT,d2
                    bgt \true
                    ; Sinon, le bitmap ne sort pas de l'écran.
                    ; On renvoie false.
\false              ; Sortie qui renvoie false (Z = 0).
                    move.l (a7)+,d2
                    andi.b  #%11111011,ccr
                    rts
\true               ; Sortie qui renvoie true (Z = 1).
                    move.l (a7)+,d2
                    ori.b   #%00000100,ccr
                    rts
            
IsOutOfScreen       ; Si le bitmap sort de l'axe des abscisses, on renvoie true.
                    jsr     IsOutOfX
                    beq     \quit
                    ; Si le bitmat sort de l'axe des ordonnées, on renvoie true. ; Sinon on renvoie false.
                    jsr IsOutOfY
\quit               rts

MoveSprite      ; Sauvegarde les registres.
                movem.l d1/d2/a0,-(a7)
                ; Nouvelle abscisse du sprite -> D1.W ; Nouvelle ordonnée du sprite -> D2.W 
                add.w X(a1),d1
                add.w Y(a1),d2
                ; Adresse du bitmap 1 du sprite -> A0.L
                movea.l BITMAP1(a1),a0
                ; Si les nouvelles coordonnées font sortir le bitmap de l'écran, 
                ; on renvoie false (sans modifier les coordonnées du sprite). 
                jsr IsOutOfScreen
                beq \false
                ; Sinon, on modifie les coordonées du sprite.
                move.w  d1,X(a1)
                move.w  d2,Y(a1)
                ; Et on renvoie true.
                ; Sortie qui renvoie true (Z = 1).
\true           ori.b   #%00000100,ccr
                bra     \quit
                ; Sortie qui renvoie false (Z = 0).
\false          andi.b  #%11111011,ccr
\quit           movem.l (a7)+,d1/d2/a0
				rts


MoveSpriteKeyboard  ; Sauvegarde les registres. 
                    movem.l d1/d2,-(a7)
                    ; Initialise le mouvement relatif à zéro.
                    clr.w   d1
                    clr.w   d2
\up                 ; Si la touche "haut" est pressée,
                    ; décremente D2.W (déplacement d'un pixel vers le haut). 
                    tst.b UP_KEY
                    beq \down
                    sub.w #1,d2
\down               ; Si la touche "bas" est pressée,
                    ; incrémente D2.W (déplacement d'un pixel vers le bas). 
                    tst.b DOWN_KEY
                    beq \right
                    add.w #1,d2
\right              ; Si la touche "droite" est pressée,
                    ; incrémente D1.W (déplacement d'un pixel vers la droite). 
                    tst.b RIGHT_KEY
                    beq \left
                    add.w #1,d1
\left               ; Si la touche "gauche" est pressée,
                    ; décremente D1.W (déplacement d'un pixel vers la gauche). 
                    tst.b LEFT_KEY
                    beq \next
                    sub.w #1,d1
\next               ; Déplace le sprite (en fonction de D1.W et de D2.W).
                    jsr     MoveSprite
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d1/d2
                    rts
                    

GetRectangle        ; Sauvegarde les registres.
                    move.l a0,-(a7)
                    ; Abscisse du point supérieur gauche -> D1.W
                    move.w X(a0),d1
                    ; Ordonnée du point supérieur gauche -> D2.W
                    move.w Y(a0),d2
                    ; Adresse du bitmap 1 -> A0.L
                    movea.l BITMAP1(a0),a0
                    ; Abscisse du point inférieur droit -> D3.W
                    move.w  WIDTH(a0),d3
                    add.w   d1,d3
                    subq.w  #1,d3
                    ; Ordonnée du point inférieur droit -> D4.W
                    move.w  HEIGHT(a0),d4
                    add.w   d2,d4
                    subq.w  #1,d4
                    ; Restaure les registres puis sortie.
                    movea.l (a7)+,a0
                    rts

IsSpriteColliding   ; Sauvegarde les registres.
                    movem.l d1-d4/a0,-(a7)
                    ; Si les sprites ne sont pas visibles, on quitte.
                    ; Le BNE saute si Z = 0, on renvoie donc false.
                    ; On ne peut pas effectuer un BNE \false tout de suite, 
                    ; car ce dernier passe par le nettoyage de la pile. 
                    cmp.w #SHOW,STATE(a1)
                    bne \quit
                    cmp.w #SHOW,STATE(a2)
                    bne \quit
                    ; Coordonnées du rectangle 1 -> Pile
                    ; D1.W -> (a7) ; x1 = Abscisse du point supérieur gauche 
                    ; D2.W -> 2(a7) ; y1 = Ordonnée du point supérieur gauche 
                    ; D3.W -> 4(a7) ; X1 = Abscisse du point inférieur droit 
                    ; D4.W -> 6(a7) ; Y1 = Ordonnée du point inférieur droit 
                    movea.l a1,a0
                    jsr GetRectangle
                    movem.w d1-d4,-(a7)
                    ; Coordonnées du rectangle 2 -> D1-D4
                    ; D1.W = x2 = Abscisse du point supérieur gauche 
                    ; D2.W = y2 = Ordonnée du point supérieur gauche 
                    ; D3.W = X2 = Abscisse du point inférieur droit 
                    ; D4.W = Y2 = Ordonnée du point inférieur droit 
                    movea.l a2,a0
                    jsr GetRectangle
                    ; Si x2 > X1, on renvoie false.
                    cmp.w   4(a7),d1
                    bgt     \false
                    ; Si y2 > Y1, on renvoie false.
                    cmp.w   6(a7),d2
                    bgt     \false
                    ; Si X2 < x1, on renvoie false.
                    cmp.w   (a7),d3
                    blt     \false
                    ; Si Y2 < y1, on renvoie false.
                    cmp.w   2(a7),d4
                    blt     \false
\true               ; Sortie qui renvoie true (Z = 1).
                    ori.b   #%00000100,ccr
                    bra     \cleanStack
\false              ; Sortie qui renvoie false (Z = 0).
                    andi.b  #%11111011,ccr
\cleanStack         ; Dépile les coordonnées du rectangle 1.
                    ; (L'instruction ADDA ne modifie pas les flags.) 
                    adda.l #8,a7
\quit               ; Restaure les registres puis sortie.
                    movem.l (a7)+,d1-d4/a0
                    rts


PrintShip           ; Sauvegarde les registres.
                    move.l  a1,-(a7)
                    ; Affiche le vaisseau.
                    lea     Ship,a1
                    jsr     PrintSprite
                    ; Restaure les registres puis sortie.
                    move.l  (a7)+,a1
                    rts


MoveShip            ; Sauvegarde les registres.
                    movem.l d1/d2/a1,-(a7)
                    ; Initialise le mouvement relatif à zéro.
                    clr.w   d1
                    clr.w   d2
\right              ; Si la touche "droite" est pressée,
                    ; incrémente D1.W (déplacement vers la droite). 
                    tst.b RIGHT_KEY
                    beq \left
                    add.w #SHIP_STEP,d1
\left               ; Si la touche "gauche" est pressée,
                    ; décrémente D1.W (déplacement vers la gauche). 
                    tst.b LEFT_KEY
                    beq \next
                    sub.w #SHIP_STEP,d1
\next               ; Déplace le vaisseau (en fonction de D1.W et de D2.W).
                    lea     Ship,a1
                    jsr     MoveSprite
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d1/d2/a1
                    rts

PrintShipShot       ; Sauvegarde les registres.
                    move.l  a1,-(a7)
                    ; Affiche le tir du vaisseau.
                    lea     ShipShot,a1
                    jsr     PrintSprite
                    
                    
                    move.w #SHIP_SG_SHOT_MAX-1,d7
					; Adresse des tirs d'envahisseurs -> A1.L
					lea ShipSGShots,a1
\loop           	; Affiche un tir d'envahisseur.
					jsr PrintSprite
					; Passe au prochain tir et reboucle.
					adda.l #SIZE_OF_SPRITE,a1
					dbra d7,\loop
                    ; Restaure les registres puis sortie.
                    move.l  (a7)+,a1
                    rts

MoveShipShot        ; Sauvegarde les registres.
                    movem.l a1/d1/d2,-(a7)
                    ; Adresse du sprite de tir -> A1.L
                    lea     ShipShot,a1
                    ; Si le tir n'est pas affiché, on ne fait rien.
                    cmp.w   #HIDE,STATE(a1)
                    beq     \quit
                    ; Déplace le tir vers le haut.
                    ; Si le déplacement a eu lieu, on peut quitter. 
                    clr.w d1
                    move.w #-SHIP_SHOT_STEP,d2
                    jsr MoveSprite
                    beq \quit
\outOfScreen        ; Sinon, le tir sort de l'écran. 
                    ; Il faut alors le camoufler. 
                    move.w #HIDE,STATE(a1)
\quit               ; Restaure les registres puis sortie.
                    movem.l (a7)+,a1/d1/d2
                    rts
             
                    
                    
MoveShipSGShot		movem.l a1/d7/d1/d2/d3-d5,-(a7)     
                
					
					move.w #SHIP_SG_SHOT_MAX-1,d7
					; Adresse des tirs d'envahisseurs -> A1.L
					lea ShipSGShots,a1
\loop           ; Si le tir n'est pas affiché, on ne fait rien.
					cmp.w #HIDE,STATE(a1)
					beq \continue
					; Déplace un tir.
					
					move.w 	X(a1),d3
					move.w 	Y(a1),d4
					move.w 	CURRENTSTEP(a1),d5
					

					jsr GetShipSGShotsStep

					jsr MoveSprite
					beq \continue
\outOfScreen    ; Le tir sort de l'écran (on le rend invisible).
					move.w #HIDE,STATE(a1)
\continue       ; Passe au prochain tir et reboucle.
					adda.l #SIZE_OF_SPRITE,a1
					dbra d7,\loop    
					
			   
					; Échange les bitmaps.
					jsr SwapInvaderShots
					; Restaure les registres puis sortie.
					movem.l (a7)+,a1/d7/d1/d2/d3-d5
					rts


ReloadSG			move.l	a1,-(a7)
					lea     Ship,a1
					cmp.w 	#TSHIPSHOTGUN,TYPE(a1)
                    bne \quit
                    
                    tst.w	SGReload
					beq		\quit
					
					sub.w #1,SGReload
					

\quit				move.l (a7)+,a1
					rts



NewShipShot         movem.l d1-d3/d7/a0/a1,-(a7)
                    ; Si la touche espace est relâchée, on ne fait rien.
                    tst.b   SPACE_KEY
                    beq     \quit
                    ; Si le tir de vaisseau est déjà présent, on ne fait rien.
                    lea     Ship,a1
                    
                    move.w #SHIP_SG_SHOT_MAX-1,d7                
                    lea     ShipSGShots,a0
                    
                    cmp.w 	#TSHIPSHOTGUN,TYPE(a1)
                    beq \beforShotgun
                    

                    
                    
                    lea     ShipShot,a0
                    cmp.w   #SHOW,STATE(a0)
                    beq     \quit
                    
                    bra \continue
                    
                    
\beforShotgun       tst.w	SGReload
					bne		\quit
					move.w #SGRELOADTIME,SGReload
					bra \shotgun
\shotgun			

					
					;move.w #SHIP_SG_SHOT_STEP_X,d1
					;move.w d7,CURRENTSTEP(a0)
					move.w #SHIP_SG_SHOT_STEP_X,CURRENTSTEP(a0)
					sub.w d7,CURRENTSTEP(a0)
					sub.w #1,CURRENTSTEP(a0)

\continue       
                    
                    move.w  X(a1),X(a0)
                    move.w  Y(a1),Y(a0)
                    ; Largeur du vaisseau -> D1.W
                    movea.l BITMAP1(a1),a1
                    move.w  WIDTH(a1),d1
                    ; Hauteur du tir -> D2.W 
                    ; Largeur du tir -> D3.W 
                    movea.l BITMAP1(a0),a1 
                    move.w HEIGHT(a1),d2 
                    move.w WIDTH(a1),d3
                    ; Centre le tir horizontalement par rapport au vaisseau.
                    sub.w   d3,d1
                    lsr.w   #1,d1
                    add.w   d1,X(a0)
                    ; Positionne le tir juste au dessus du vaisseau.
                    sub.w d2,Y(a0)
                    ; Le tir est rendu visible.
                    move.w  #SHOW,STATE(a0)
					
					lea     Ship,a1
					cmpi.w #TSHIPSHOTGUN,TYPE(a1)
					bne \quit
					adda.l #SIZE_OF_SPRITE,a0
					dbra d7,\shotgun
					


                    
\quit               ; Restaure les registres puis sortie.
                    movem.l (a7)+,d1-d3/d7/a0/a1
                    rts


InitInvaderLine ; Sauvegarde les registres.
                movem.l d1-d5/d7/a0,-(a7)
                ; Nombre d'itérations = Nombre d'envahisseurs par ligne
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_PER_LINE-1,d7

                ; Modifie l'abscisse de départ de la ligne
                ; afin de centrer le sprite sur une largeur de 32 pixels.
                ; D1.W += (32 - Largeur du sprite) / 2
                move.w #32,d5
                sub.w WIDTH(a1),d5
                lsr.w #1,d5
                add.w d5,d1
\loop           ; Initialise tous les champs du sprite.
                move.w #SHOW,STATE(a0)
                move.w d1,X(a0)
                move.w d2,Y(a0)
                move.l a1,BITMAP1(a0)
                move.l a2,BITMAP2(a0)
                move.w d3,TYPE(a0)
                move.w d4,LIFE(a0)

                ; Passe à l'envahisseur suivant.
                adda.l #SIZE_OF_SPRITE,a0
                addi.w #32,d1
                dbra d7,\loop

                ; Restaure les registres puis sortie.
                movem.l (a7)+,d1-d5/d7/a0
                rts



PrintInvaders   ; Sauvegarde les registres.
                movem.l d7/a1,-(a7)
                ; Nombre d'itérations = Nombre d'envahisseurs
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_COUNT-1,d7

                ; Adresse de départ des sprites -> A1.L
                lea Invaders,a1
\loop           ; Affiche un envahisseur.
                jsr PrintSprite
                ; Passe au prochain envahisseur et reboucle.
                adda.l #SIZE_OF_SPRITE,a1
                dbra d7,\loop
                ; Sauvegarde les registres puis sortie.
                movem.l (a7)+,d7/a1
                rts


InitInvaders ; Sauvegarde les registres.
                    movem.l d1-d4/a0-a2,-(a7)

                    ; 1re ligne d'envahisseurs.
                    move.w InvaderX,d1
                    move.w InvaderY,d2
                    lea Invaders,a0
                    lea InvaderC1_Bitmap,a1
                    lea InvaderC2_Bitmap,a2
                    move.w 	#TC,d3
                    move.w 	#C_LIFE,d4
                    jsr InitInvaderLine

                    ; 2e ligne d'envahisseurs.
                    add.w #32,d2
                    adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
                    lea InvaderB1_Bitmap,a1
                    lea InvaderB2_Bitmap,a2
                    move.w 	#TB,d3
                    move.w 	#B_LIFE,d4
                    jsr InitInvaderLine
                    ; 3e ligne d'envahisseurs.
                    add.w #32,d2
                    adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
                    jsr InitInvaderLine
                    ; 4e ligne d'envahisseurs.
                    add.w #32,d2
                    adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
                    lea InvaderA1_Bitmap,a1
                    lea InvaderA2_Bitmap,a2
                    move.w 	#TA,d3
                    move.w 	#A_LIFE,d4
                    jsr InitInvaderLine
                    ; 5e ligne d'envahisseurs.
                    add.w #32,d2
                    adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
                    jsr InitInvaderLine
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d1-d4/a0-a2
                    rts


SwapBitmap 			; Échange les contenus de BITMAP1 et BITMAP2.
                    move.l BITMAP1(a1),-(a7)
                    move.l BITMAP2(a1),BITMAP1(a1)
                    move.l (a7)+,BITMAP2(a1)
                    ; Sortie du sous-programme.
                    rts



DestroyInvaders     ; Sauvegarde les regitres.
                    movem.l d6/d7/a1-a3,-(a7)
                    ; Fait pointer A1.L sur les envahisseurs.
                    ; Fait pointer A2.L sur le tir du vaisseau.
                    lea Invaders,a1
                    lea ShipShot,a2
                    ; Nombre d'itérations – 1 (car DBRA) -> D7.W
                    move.w #INVADER_COUNT-1,d7

\loop1               ; Si le tir n'entre pas en collision
                    ; avec l'envahisseur, on passe au suivant.
                    jsr IsSpriteColliding
                    bne \next1
                    bra \colliding
                    
\next1               ; Passe à l'envahisseur suivant.
                    adda.l #SIZE_OF_SPRITE,a1
                    dbra d7,\loop1
                    
                    
                    ; SG
                    
                    
                    lea ShipSGShots,a2
                    move.w #SHIP_SG_SHOT_MAX-1,d6
                    
\bigLoop			lea Invaders,a1
                    move.w #INVADER_COUNT-1,d7
                    
\loop2               ; Si le tir n'entre pas en collision
                    ; avec l'envahisseur, on passe au suivant.
                    jsr IsSpriteColliding
                    bne \next2
                    bra \colliding
                    
\next2               ; Passe à l'envahisseur suivant.
                    adda.l #SIZE_OF_SPRITE,a1
                    dbra d7,\loop2
                    adda.l	#SIZE_OF_SPRITE,a2
                    dbra d6,\bigLoop
                    bra \quit
                    
                    
  
                    
                    
\colliding          ; S'il y a une collision,
                    ; on efface le tir et l'envahisseur.
                    ; Puis on décrémente le nombre d'envahisseurs.

                    move.w #HIDE,STATE(a2)
                    
                    sub.w #1,LIFE(a1)
                    tst.w LIFE(a1)
                    bne \break

                    move.w #HIDE,STATE(a1)
                    
                    subq.w #1,InvaderCount
                    bra \quit
                    
\break              cmpi.w #TA,TYPE(a1)
					bne \quit
					lea InvaderA1_Break_Bitmap,a3
					move.l a3,BITMAP1(a1)
                    lea InvaderA2_Break_Bitmap,a3
					move.l a3,BITMAP2(a1)
                    
\quit               ; Restaure les registres.
                    movem.l (a7)+,d6/d7/a1-a3
                    rts

SpeedInvaderUp      ; Sauvegarde les registres.
                    movem.l d0/a0,-(a7)
                    ; Initialise le compteur de vitesse.
                    clr.w InvaderSpeed
                    ; Nombre d'envahisseurs en cours d'affichage -> D0.W
                    move.w InvaderCount,d0
                    ; Fait pointer A0.L sur le tableau des paliers de vitesse.
                    lea SpeedLevels,a0
\loop               ; Incrémente le compteur de vitesse.
                    addq.w #1,InvaderSpeed
                    ; Compare le nombre d'envahisseurs à un palier du tableau.
                    ; Si le nombre d'envahisseurs est plus grand,
                    ; on passe au palier suivant.
                    cmp.w (a0)+,d0
                    bhi \loop
                    ; Restaure les registres puis sortie.
                    movem.l (a7)+,d0/a0
                    rts





GetInvaderStep  ; Sauvegarde les registres.
                move.l d0,-(a7)
                ; Nouvelle abscisse globale -> D0.W
                move.w InvaderX,d0
                add.w InvaderCurrentStep,d0
                ; Si l'abscisse globale est trop petite,
                ; les envahisseurs ont atteint le bord gauche.
                ; Il faut donc changer de direction.
                cmpi.w #INVADER_X_MIN,d0
                blt \change
                ; Si l'abscisse globale est trop grande,
                ; les envahisseurs ont atteint le bord droit.
                ; Il faut donc changer de direction.
                cmpi.w #INVADER_X_MAX,d0
                bgt \change
\noChange       ; Pas de changement de direction.
                ; Mouvement relatif -> D1.W et D2.W.
                ; L'abscisse globale est mise à jour.
                move.w InvaderCurrentStep,d1
                clr.w d2
                move.w d0,InvaderX
                bra \quit
\change         ; Changement de direction.
                ; Mouvement relatif -> D1.W et D2.W.
                ; L'ordonnée globale est mise à jour.
                ; Le signe du pas est inversé.
                clr.w d1
                move.w #INVADER_STEP_Y,d2
                add.w d2,InvaderY
                neg.w InvaderCurrentStep
\quit           ; Restaure les registres puis sortie.
                move.l (a7)+,d0
                rts



GetInvaderCShotStep  ; Sauvegarde les registres.
                move.l d0,-(a7)
                ; Nouvelle abscisse globale -> D0.W
                ; d3 = bulletX
                ; d4 = bulletY
                ; d5 = current step
                move.w d3,d0
                add.w d5,d0
                ; Si l'abscisse globale est trop petite,
                ; les envahisseurs ont atteint le bord gauche.
                ; Il faut donc changer de direction.
                
                
                cmpi.w #SHOT_X_MIN,d0
                blt \change
                ; Si l'abscisse globale est trop grande,
                ; les envahisseurs ont atteint le bord droit.
                ; Il faut donc changer de direction.
                cmpi.w #SHOT_X_MAX,d0
                bgt \change
\noChange       ; Pas de changement de direction.
                ; Mouvement relatif -> D1.W et D2.W.
                ; L'abscisse globale est mise à jour.
                move.w d5,d1
                bra \quit
\change         ; Changement de direction.
                ; Mouvement relatif -> D1.W et D2.W.
                ; L'ordonnée globale est mise à jour.
                ; Le signe du pas est inversé.
                
                neg.w d5
                move.w d5,d1
                
                move.w d5,CURRENTSTEP(a1)
				
\quit           ; Restaure les registres puis sortie.

				move.w #INVADER_C_SHOT_STEP_X,d2
                move.l (a7)+,d0
                rts
                
                
                
GetShipSGShotsStep
				move.l d0,-(a7)
                ; Nouvelle abscisse globale -> D0.W
                ; d3 = bulletX
                ; d4 = bulletY
                ; d5 = current step
                move.w d3,d0
                add.w d5,d0
                ; Si l'abscisse globale est trop petite,
                ; les envahisseurs ont atteint le bord gauche.
                ; Il faut donc changer de direction.
                
                
                cmpi.w #SHOT_X_MIN,d0
                blt \change
                ; Si l'abscisse globale est trop grande,
                ; les envahisseurs ont atteint le bord droit.
                ; Il faut donc changer de direction.
                cmpi.w #SHOT_X_MAX,d0
                bgt \change
\noChange       ; Pas de changement de direction.
                ; Mouvement relatif -> D1.W et D2.W.
                ; L'abscisse globale est mise à jour.
                move.w d5,d1
                bra \quit
\change         ; Changement de direction.
                ; Mouvement relatif -> D1.W et D2.W.
                ; L'ordonnée globale est mise à jour.
                ; Le signe du pas est inversé.
                
                neg.w d5
                move.w d5,d1
                
                move.w d5,CURRENTSTEP(a1)
				
\quit           ; Restaure les registres puis sortie.

				move.w #-SHIP_SG_SHOT_STEP_Y,d2
                move.l (a7)+,d0
                rts
                
                


MoveAllInvaders ; Sauvegarde les registres.
                movem.l d1/d2/a1/d7,-(a7)
                ; Récupère les déplacements relatifs dans D1.W et D2.W.
                ; (La position globale est mise à jour.)
                jsr GetInvaderStep
                ; Fait pointer A1.L sur le premier envahisseur.
                lea Invaders,a1
                ; Nombre d'envahisseurs - 1 (car DBRA) -> D7.W
                move.w #INVADER_COUNT-1,d7
\loop           ; Si l'envahisseur n'est pas affiché, on passe au suivant.
                cmp.w #HIDE,STATE(a1)
                beq \continue
                
                ; Déplace l'envahisseur et permute ses bitmaps.
                jsr     MoveSprite
                jsr     SwapBitmap
                

\continue       ; Pointe sur le prochain envahisseur.
                adda.l #SIZE_OF_SPRITE,a1

                ; On reboucle tant qu'il reste des envahisseurs.
                dbra d7,\loop
\quit           ; Restaure les registres puis sortie.
                movem.l (a7)+,d1/d2/a1/d7
                rts





MoveInvaders    ; Décrémente la variable "skip",
                ; et ne fait rien si elle n'est pas nulle.
                subq.w #1,\skip
                bne \quit
                ; Réinitialise "skip" à sa valeur maximale
                move.w InvaderSpeed,\skip
				add.w #1,\skip
                ; Appel de MoveAllInvaders.
                jsr MoveAllInvaders
\quit           ; Sortie du sous programme.
                rts
                ; Compteur d'affichage des envahisseurs
\skip           dc.w 1


InitInvaderShots 	; Sauvegarde les registres.
					movem.l d7/a0,-(a7)
					; Adresse des tirs -> A0.L
					lea InvaderShots,a0
					; Nombre d'itérations - 1 (car DBRA) -> D7.W
					move.w #INVADER_SHOT_MAX-1,d7
\loop 	            ; Initialise l'état et les bitmaps.
					move.w #HIDE,STATE(a0)
					move.l #InvaderShot1_Bitmap,BITMAP1(a0)
					move.l #InvaderShot2_Bitmap,BITMAP2(a0)

					; Passe au tir suivant.
					adda.l #SIZE_OF_SPRITE,a0
					dbra d7,\loop

					; Restaure les registres puis sortie.
					movem.l (a7)+,d7/a0
					rts
					
					
					
					
InitInvaderCShots 	; Sauvegarde les registres.
					movem.l d7/a0,-(a7)
					; Adresse des tirs -> A0.L
					lea InvaderCShots,a0
					; Nombre d'itérations - 1 (car DBRA) -> D7.W
					move.w #INVADER_C_SHOT_MAX*2-1,d7
\loop 	            ; Initialise l'état et les bitmaps.
					move.w #HIDE,STATE(a0)
					move.l #InvaderCShot1_Bitmap,BITMAP1(a0)
					move.l #InvaderCShot2_Bitmap,BITMAP2(a0)
					move.w #INVADER_C_SHOT_STEP_X,CURRENTSTEP(a0)

					; Passe au tir suivant.
					adda.l #SIZE_OF_SPRITE,a0
					dbra d7,\loop

					; Restaure les registres puis sortie.
					movem.l (a7)+,d7/a0
					rts




InitShipSGShots 	; Sauvegarde les registres.
					movem.l d7/a0,-(a7)
					; Adresse des tirs -> A0.L
					lea ShipSGShots,a0
					; Nombre d'itérations - 1 (car DBRA) -> D7.W
					move.w #SHIP_SG_SHOT_MAX-1,d7
\loop 	            ; Initialise l'état et les bitmaps.
					move.w #HIDE,STATE(a0)
					move.l #InvaderCShot1_Bitmap,BITMAP1(a0)
					move.l #InvaderCShot2_Bitmap,BITMAP2(a0)

					; Passe au tir suivant.
					adda.l #SIZE_OF_SPRITE,a0
					dbra d7,\loop

					; Restaure les registres puis sortie.
					movem.l (a7)+,d7/a0
					rts




GetHiddenShot   ; Sauvegarde les registres.
                move.l d7,-(a7)
                ; Adresse des tirs -> A0.L
                lea InvaderShots,a0
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_SHOT_MAX-1,d7
\loop           ; Si le tir n'est pas visible, renvoie true.
                ; (L'adresse du tir se trouve dans A0.L.)
                cmp.w #HIDE,STATE(a0)
                beq \true
                ; Passe au tir suivant.
                adda.l #SIZE_OF_SPRITE,a0
                dbra d7,\loop

\false          ; Renvoie false (pas de tir disponible).
                move.l (a7)+,d7
                andi.b #%11111011,ccr
                rts
\true           ; Renvoie true (un tir disponible a été trouvé).
                move.l (a7)+,d7
                ori.b #%00000100,ccr
                rts
                
                
                
GetHiddenCShot   ; Sauvegarde les registres.
                move.l d7,-(a7)
                ; Adresse des tirs -> A0.L
                lea InvaderCShots,a0
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_C_SHOT_MAX*2-1,d7
\loop           ; Si le tir n'est pas visible, renvoie true.
                ; (L'adresse du tir se trouve dans A0.L.)
                cmp.w #HIDE,STATE(a0)
                beq \true
                ; Passe au tir suivant.
                adda.l #SIZE_OF_SPRITE,a0
                dbra d7,\loop

\false          ; Renvoie false (pas de tir disponible).
                move.l (a7)+,d7
                andi.b #%11111011,ccr
                rts
\true           ; Renvoie true (un tir disponible a été trouvé).
                move.l (a7)+,d7
                ori.b #%00000100,ccr
                rts







ConnectInvaderShot ; Sauvegarde les registres.
                movem.l d1/d2/d3/d7/a0/a1/a2,-(a7)
                ; Si l'envahisseur n'est pas visible, on quitte.
                cmpi.w #HIDE,STATE(a1)
                beq \quit
                
                move.w #1,d7
                cmpi.w #TC,TYPE(a1)
                beq \invaderC
                
                
                ; Récupère l'adresse d'un tir disponible.
                ; Si aucun tir disponible, on ne fait rien.
                jsr GetHiddenShot
                bne \quit
                bra \continue
      
\invaderC		jsr GetHiddenCShot
				bne \quit				
				move.w #INVADER_C_SHOT_STEP_X,CURRENTSTEP(a0)

                ; Place le tir au même endroit que l'envahisseur.
\continue       move.w X(a1),X(a0)
                move.w Y(a1),Y(a0)

                ; Détermine la largeur et la hauteur de l'envahisseur.
                movea.l BITMAP1(a1),a2
                move.w WIDTH(a2),d1
                move.w HEIGHT(a2),d2

                ; Détermine la largeur du tir.
                movea.l BITMAP1(a0),a2
                move.w WIDTH(a2),d3

                ; (Largeur Envahisseur – Largeur Tir) / 2 -> D1.W
                sub.w d3,d1
                lsr.w #1,d1

                ; On centre le tir sur les abscisses.
                ; On descend le tir juste au dessous de l'envahisseur.
                add.w d1,X(a0)
                add.w d2,Y(a0)

                ; Le tir est rendu visible.
                move.w #SHOW,STATE(a0)
                
                cmpi.w #TC,TYPE(a1)
                bne \quit
                dbra d7,\invaderC
                move.w #-INVADER_C_SHOT_STEP_X,CURRENTSTEP(a0)


\quit           ; Restaure les registres puis sortie.
                movem.l (a7)+,d1/d2/d3/d7/a0/a1/a2
                rts


Random          move.l \old,d0
                muls.w #16807,d0
                and.l #$7fffffff,d0
                move.l d0,\old
                lsr.l #4,d0
                and.l #$7ff,d0
                rts
\old            dc.l 425625





NewInvaderShot  ; Sauvegarde les registres.
                movem.l d0/a1,-(a7)
                ; Récupère un nombre aléatoire.
                jsr Random
                ; Si ce nombre est supérieur ou égale
                ; au nombre d'envahisseurs, on ne fait rien.
                cmp.w #INVADER_COUNT,d0
                bhs \quit
                ; Détermine l'adresse de l'envahisseur.
                mulu.w #SIZE_OF_SPRITE,d0
                lea Invaders,a1
                adda.l d0,a1
                ; Connecte un tir à cet envahisseur.
                jsr ConnectInvaderShot
\quit           ; Restaure les registres puis sortie.
                movem.l (a7)+,a1/d0
                rts




PrintInvaderShots ; Sauvegarde les registres.
                movem.l d7/a1,-(a7)
                ; Nombre d'itérations = Nombre de tirs d'envahisseurs.
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_SHOT_MAX-1,d7
                ; Adresse des tirs d'envahisseurs -> A1.L
                lea InvaderShots,a1
\loop1           ; Affiche un tir d'envahisseur.
                jsr PrintSprite
                ; Passe au prochain tir et reboucle.
                adda.l #SIZE_OF_SPRITE,a1
                dbra d7,\loop1
                
                ;for C
				move.w #INVADER_C_SHOT_MAX*2-1,d7
                ; Adresse des tirs d'envahisseurs -> A1.L
                lea InvaderCShots,a1
\loop2           ; Affiche un tir d'envahisseur.
                jsr PrintSprite
                ; Passe au prochain tir et reboucle.
                adda.l #SIZE_OF_SPRITE,a1
                dbra d7,\loop2

                ; Restaure les registres puis sortie.
                movem.l (a7)+,d7/a1
                rts




MoveInvaderShots ; Sauvegarde les registres.
                movem.l a1/d7/d1/d2/d3-d5,-(a7)

                ; Nombre d'itérations = Nombre de tirs d'envahisseurs.
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_SHOT_MAX-1,d7
                ; Adresse des tirs d'envahisseurs -> A1.L
                lea InvaderShots,a1
\loop1           ; Si le tir n'est pas affiché, on ne fait rien.
                cmp.w #HIDE,STATE(a1)
                beq \continue1
                ; Déplace un tir.
                clr.w d1                
                move.w #INVADER_SHOT_STEP,d2
                jsr MoveSprite
                beq \continue1
\outOfScreen1    ; Le tir sort de l'écran (on le rend invisible).
                move.w #HIDE,STATE(a1) 
\continue1       ; Passe au prochain tir et reboucle.
                adda.l #SIZE_OF_SPRITE,a1
                dbra d7,\loop1
                
                
                
                
                move.w #INVADER_C_SHOT_MAX*2-1,d7
                ; Adresse des tirs d'envahisseurs -> A1.L
                lea InvaderCShots,a1
\loop2           ; Si le tir n'est pas affiché, on ne fait rien.
                cmp.w #HIDE,STATE(a1)
                beq \continue2
                ; Déplace un tir.
                
                move.w 	X(a1),d3
                move.w 	Y(a1),d4
                move.w 	CURRENTSTEP(a1),d5
				

				jsr GetInvaderCShotStep

                jsr MoveSprite
                beq \continue2
\outOfScreen2    ; Le tir sort de l'écran (on le rend invisible).
                move.w #HIDE,STATE(a1)
\continue2       ; Passe au prochain tir et reboucle.
                adda.l #SIZE_OF_SPRITE,a1
                dbra d7,\loop2    
                
           
                ; Échange les bitmaps.
                jsr SwapInvaderShots
                ; Restaure les registres puis sortie.
                movem.l (a7)+,a1/d7/d1/d2/d3-d5
                rts
                
               
                
                
                
SwapInvaderShots ; Décrémente la variable \skip,
                ; et ne fait rien si elle n'est pas nulle.
                movem.l d7/a1,-(a7)

                subq.w #1,\skip
                bne \quit
                ; Réinitialise la variable \skip.
                move.w #6,\skip
                ; Sauvegarde les registres.
                ; Nombre d'itérations = Nombre de tirs d'envahisseurs.
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_SHOT_MAX-1,d7

                ; Adresse des tirs d'envahisseurs -> A1.L
                lea InvaderShots,a1

\loop1           ; Échange les bitmaps 1 et 2 pour tous les tirs.
                jsr SwapBitmap
                adda.l #SIZE_OF_SPRITE,a1
                dbra d7,\loop1
                
                
                move.w #INVADER_C_SHOT_MAX*2-1,d7

                ; Adresse des tirs d'envahisseurs -> A1.L
                lea InvaderCShots,a1

\loop2           ; Échange les bitmaps 1 et 2 pour tous les tirs.
                jsr SwapBitmap
                adda.l #SIZE_OF_SPRITE,a1
                dbra d7,\loop2

                ; Restaure les registres puis sortie.
\quit           movem.l (a7)+,d7/a1
				rts
                ; Initialise une variable \skip à 6.
\skip           dc.w 6






ChangeWeapon	move.l a1,-(a7)
				lea     Ship,a1
				tst.b   UP_KEY
				beq     \next
				cmp.w 	#TSHIP,TYPE(a1)
                bne \changeS
                
\next			tst.b   DOWN_KEY
				beq     \quit
				cmp.w 	#TSHIPSHOTGUN,TYPE(a1)
                bne \changeSG
				
				bra	\quit
				
\changeS		move.w	#TSHIP,TYPE(a1)
				jsr 	SwapBitmap
				bra		\quit
\changeSG		move.w	#TSHIPSHOTGUN,TYPE(a1)
				jsr 	SwapBitmap
				
\quit               ; Restaure les registres puis sortie.
				move.l (a7)+,a1
				rts






Cheat			move.l a1,-(a7)
				tst.b   UP_KEY
				beq     \quit
				tst.b   DOWN_KEY
				beq     \quit
				tst.b   RIGHT_KEY
				beq     \quit
				tst.w	SGReload
				bne		\quit
				move.w #SGRELOADTIME,SGReload
				lea Ship,a1
				add.w #1,LIFE(a1)
\quit			move.l (a7)+,a1
                rts


IsShipDead		;verifie les vie
				move.l a1,-(a7)
				jsr IsShipHit
				bne \false
				
				lea Ship,a1
				sub.w #1,LIFE(a1)
				tst.w LIFE(a1)
				beq \true
				
				
				
\false          ; Renvoie false (aucune collision).
				jsr		Cheat
                andi.b #%11111011,ccr
                bra \quit
\true           ; Renvoie true (collision).
                ori.b #%00000100,ccr
\quit           move.l (a7)+,a1
                rts




IsShipHit       ; Sauvegarde les registres.
                movem.l d7/a1/a2,-(a7)

                ; Adresse du vaisseau -> A1.L
                lea Ship,a1
                ; Adresse des tirs d'envahisseurs -> A2.L
                lea InvaderShots,a2
                ; Nombre d'itérations = Nombre de tirs d'envahisseurs.
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_SHOT_MAX-1,d7
\loop1           ; Si un tir entre en collision avec le vaisseau,
                ; on renvoie true.
                jsr IsSpriteColliding
                beq \true
                ; Passe au tir suivant.
                adda.l #SIZE_OF_SPRITE,a2
                dbra d7,\loop1
                
                
                
                lea InvaderCShots,a2
                ; Nombre d'itérations = Nombre de tirs d'envahisseurs.
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_C_SHOT_MAX*2-1,d7
\loop2           ; Si un tir entre en collision avec le vaisseau,
                ; on renvoie true.
                jsr IsSpriteColliding
                beq \true
                ; Passe au tir suivant.
                adda.l #SIZE_OF_SPRITE,a2
                dbra d7,\loop2


\false          ; Renvoie false (aucune collision).
                andi.b #%11111011,ccr
                bra \quit
\true           ; Renvoie true (collision).
				move.w #HIDE,STATE(a2)
                ori.b #%00000100,ccr
\quit           movem.l (a7)+,d7/a1/a2
                rts





IsShipColliding ; Sauvegarde les registres.
                movem.l d7/a1/a2,-(a7)

                ; Adresse du vaisseau -> A1.L
                lea Ship,a1
                ; Adresse des envahisseurs -> A2.L
                lea Invaders,a2
                ; Nombre d'itérations = Nombre d'envahisseurs.
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_COUNT-1,d7
\loop           ; Si un envahisseur entre en collision avec le vaisseau,
                ; on renvoie true.
                jsr IsSpriteColliding
                beq \true
                ; Passe à l'envahisseur suivant.
                adda.l #SIZE_OF_SPRITE,a2
                dbra d7,\loop

\false          ; Renvoie false (aucune collision).
                andi.b #%11111011,ccr
                bra \quit
\true           ; Renvoie true (collision).
                ori.b #%00000100,ccr
\quit           movem.l (a7)+,d7/a1/a2
                rts





IsInvaderTooLow ; Sauvegarde les registres.
                movem.l d7/a0,-(a7)
                ; Adresse des envahisseurs -> A0.L
                lea Invaders,a0
                ; Nombre d'itérations = Nombre d'envahisseurs.
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w #INVADER_COUNT-1,d7
\loop           ; Si l'envahisseur n'est pas affiché,
                ; on passe à l'envahisseur suivant.
                cmp.w #HIDE,STATE(a0)
                beq \next
                ; If the invader is too low, return true.
                cmpi.w #280,Y(a0)
                bhi \true
\next           ; Passe à l'envahisseur suivant.
                adda.l #SIZE_OF_SPRITE,a0
                dbra d7,\loop
\false          ; Renvoie false.
                andi.b #%11111011,ccr
                bra \quit
\true           ; Renvoie true.
                ori.b #%00000100,ccr
\quit           movem.l (a7)+,d7/a0
                rts
                
                
                
IsGameOver		movem.l d7/a0,-(a7)

				lea Invaders,a0
				
                ; Nombre d'itérations = Nombre d'envahisseurs.
                ; Nombre d'itérations - 1 (car DBRA) -> D7.W
                move.w 		#INVADER_COUNT-1,d7
\loop           ; Si l'envahisseur n'est pas affiché,
                ; on passe à l'envahisseur suivant.
                cmp.w 		#HIDE,STATE(a0)
                bne   		\touched 
                adda.l 		#SIZE_OF_SPRITE,a0
                dbra 		d7,\loop
                
                move.l 		#SHIP_WIN,d0
                bra 		\true


\touched		jsr 		IsShipDead
				move.l 		#SHIP_DEAD,a0
				beq 		\true
				jsr 		IsShipColliding
				move.l 		#SHIP_COLLIDING,a0
				beq 		\true
				jsr 		IsInvaderTooLow
				move.l 		#INVADER_LOW,a0
				beq 		\true
				


\false          ; Renvoie false .
                andi.b #%11111011,ccr
                bra \quit
\true           ; Renvoie true.
                ori.b #%00000100,ccr
\quit           movem.l (a7)+,d7/a0
                rts















                
Main                jsr     InitInvaders
					jsr     InitInvaderShots
					jsr		InitInvaderCShots
					jsr		InitShipSGShots
					
\loop               jsr     PrintShip
					jsr     PrintShipShot
					jsr		PrintShipLife
					jsr     PrintInvaders
					jsr     PrintInvaderShots
					
					jsr     BufferToScreen
					
					jsr     DestroyInvaders
					
					jsr     MoveShip
					jsr     MoveInvaders
					jsr     MoveShipShot
					jsr 	MoveShipSGShot
					jsr     MoveInvaderShots

					jsr 	ChangeWeapon
					jsr     NewShipShot
					jsr		ReloadSG
					jsr     NewInvaderShot

					
					
					jsr     SpeedInvaderUp

					jsr     IsGameOver
					bne		\loop
					
					; end screen
					
					
					
					jsr     PrintShip
					jsr     PrintShipShot
					jsr		PrintShipLife
					jsr     PrintInvaders
					jsr     PrintInvaderShots
					
					jsr     BufferToScreen


					lea     win,a0
					cmp.l	#SHIP_WIN,d0
					beq		\print
					lea		lose,a0
			

\print				move.b #20,d1
					move.b #39,d2
					jsr     Print
					
					illegal














					; ==============================
					; Données
					; ==============================
					; Sprites
					; ------------------------------
MovingSprite        dc.w    SHOW
					dc.w    0,152
					dc.l    InvaderB1_Bitmap
					dc.l	0
FixedSprite         dc.w    SHOW
					dc.w	228,152
					dc.l    InvaderA1_Bitmap
					dc.l	0
							
		
Invaders            ds.b    INVADER_COUNT*SIZE_OF_SPRITE

				
InvaderShots        ds.b    SIZE_OF_SPRITE*INVADER_SHOT_MAX
InvaderCShots       ds.b    SIZE_OF_SPRITE*INVADER_C_SHOT_MAX*2

					
					



Ship 				dc.w    SHOW
					dc.w	(VIDEO_WIDTH-24)/2,VIDEO_HEIGHT-32
					dc.l    Ship_Bitmap
					dc.l	Ship_Shotgun_Bitmap
					dc.w	TSHIP
					dc.w	0
					dc.w	SHIP_LIFE
					
ShipShot 			dc.w    HIDE
					dc.w	0,0
					dc.l    ShipShot_Bitmap
					dc.l	0
					
					
ShipSGShots       	ds.b    SIZE_OF_SPRITE*SHIP_SG_SHOT_MAX


SGReload			dc.w	0


; Touches du clavier
; ------------------------------
SPACE_KEY equ     $420
LEFT_KEY  equ     $46f
UP_KEY    equ     $470
RIGHT_KEY equ     $471
DOWN_KEY  equ     $472

Invader             dc.w    SHOW                            ; Afficher le sprite
					dc.w	0,152; X = 0, Y = 152
					dc.l    InvaderA1_Bitmap                 ; Bitmap à afficher
					dc.l    0



win               	dc.b "===== YOU WIN =====",0
lose               	dc.b "===== YOU LOSE =====",0


               
InvaderX            dc.w (VIDEO_WIDTH-(INVADER_PER_LINE*32))/2; Abscisse globale
InvaderY            dc.w 32; Ordonnée global
InvaderCurrentStep  dc.w    INVADER_STEP_X 
InvaderCount        dc.w	INVADER_COUNT         ; Cpt. d'envahisseurs


InvaderSpeed        dc.w    8                                       ; Vitesse (1 -> 8)
SpeedLevels         dc.w  1,5,10,15,20,25,35,50   ; Paliers de vitesse

                


InvaderA1_Bitmap    dc.w    24,16
                    dc.b    %00000000,%11111111,%00000000
                    dc.b    %00000000,%11111111,%00000000
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111100,%00111100,%00111111
                    dc.b    %11111100,%00111100,%00111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %00000011,%11000011,%11000000
                    dc.b    %00000011,%11000011,%11000000
                    dc.b    %00001111,%00111100,%11110000
                    dc.b    %00001111,%00111100,%11110000
                    dc.b    %11110000,%00000000,%00001111
                    dc.b    %11110000,%00000000,%00001111

InvaderB1_Bitmap     dc.w    22,16
                    dc.b    %00001100,%00000000,%11000000
                    dc.b    %00001100,%00000000,%11000000
                    dc.b    %00000011,%00000011,%00000000
                    dc.b    %00000011,%00000011,%00000000
                    dc.b    %00001111,%11111111,%11000000
                    dc.b    %00001111,%11111111,%11000000
                    dc.b    %00001100,%11111100,%11000000
                    dc.b    %00001100,%11111100,%11000000
                    dc.b    %00111111,%11111111,%11110000
                    dc.b    %00111111,%11111111,%11110000
                    dc.b    %11001111,%11111111,%11001100
                    dc.b    %11001111,%11111111,%11001100
                    dc.b    %11001100,%00000000,%11001100
                    dc.b    %11001100,%00000000,%11001100
                    dc.b    %00000011,%11001111,%00000000
                    dc.b    %00000011,%11001111,%00000000

InvaderC1_Bitmap     dc.w    16,16
                    dc.b    %00000011,%11000000
                    dc.b    %00000011,%11000000
                    dc.b    %00001111,%11110000
                    dc.b    %00001111,%11110000
                    dc.b    %00111111,%11111100
                    dc.b    %00111111,%11111100
                    dc.b    %11110011,%11001111
                    dc.b    %11110011,%11001111
                    dc.b    %11111111,%11111111
                    dc.b    %11111111,%11111111
                    dc.b    %00110011,%11001100
                    dc.b    %00110011,%11001100
                    dc.b    %11000000,%00000011
                    dc.b    %11000000,%00000011
                    dc.b    %00110000,%00001100
                    dc.b    %00110000,%00001100

Ship_Bitmap         dc.w    24,14
                    dc.b    %00000000,%00011000,%00000000
                    dc.b    %00000000,%00011000,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    
                    
Ship_Shotgun_Bitmap dc.w    24,14
                    dc.b    %00000000,%00000000,%00000000
                    dc.b    %00000110,%10100101,%01100000
                    dc.b    %00000011,%11111111,%11000000
                    dc.b    %00000001,%11111111,%10000000
                    dc.b    %00000000,%11111111,%00000000
                    dc.b    %00000000,%01111110,%00000000
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %00111111,%11111111,%11111100
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111111,%11111111,%11111111

InvaderA2_Bitmap    dc.w 24,16
                    dc.b %00000000,%11111111,%00000000
                    dc.b %00000000,%11111111,%00000000
                    dc.b %00111111,%11111111,%11111100
                    dc.b %00111111,%11111111,%11111100
                    dc.b %11111111,%11111111,%11111111
                    dc.b %11111111,%11111111,%11111111
                    dc.b %11111100,%00111100,%00111111
                    dc.b %11111100,%00111100,%00111111
                    dc.b %11111111,%11111111,%11111111
                    dc.b %11111111,%11111111,%11111111
                    dc.b %00001111,%11000011,%11110000
                    dc.b %00001111,%11000011,%11110000
                    dc.b %00111100,%00111100,%00111100
                    dc.b %00111100,%00111100,%00111100
                    dc.b %00001111,%00000000,%11110000
                    dc.b %00001111,%00000000,%11110000


InvaderB2_Bitmap    dc.w 22,16
                    dc.b %00001100,%00000000,%11000000
                    dc.b %00001100,%00000000,%11000000
                    dc.b %00000011,%00000011,%00000000
                    dc.b %00000011,%00000011,%00000000
                    dc.b %11001111,%11111111,%11001100
                    dc.b %11001111,%11111111,%11001100
                    dc.b %11001100,%11111100,%11001100
                    dc.b %11001100,%11111100,%11001100
                    dc.b %00111111,%11111111,%11110000
                    dc.b %00111111,%11111111,%11110000
                    dc.b %00001111,%11111111,%11000000
                    dc.b %00001111,%11111111,%11000000
                    dc.b %00001100,%00000000,%11000000
                    dc.b %00001100,%00000000,%11000000
                    dc.b %00110000,%00000000,%00110000
                    dc.b %00110000,%00000000,%00110000

InvaderC2_Bitmap    dc.w 16,16
                    dc.w %0000001111000000
                    dc.w %0000001111000000
                    dc.w %0000111111110000
                    dc.w %0000111111110000
                    dc.w %0011111111111100
                    dc.w %0011111111111100
                    dc.w %1111001111001111
                    dc.w %1111001111001111
                    dc.w %1111111111111111
                    dc.w %1111111111111111
                    dc.w %0000110000110000
                    dc.w %0000110000110000
                    dc.w %0011001111001100
                    dc.w %0011001111001100
                    dc.w %1100110000110011
                    dc.w %1100110000110011
                    
                    
                    
                    
                    
                    
InvaderA1_Break_Bitmap    dc.w    24,16
                    dc.b    %00000000,%11111111,%00000000
                    dc.b    %00000000,%11111100,%00000000
                    dc.b    %00111111,%11111000,%11111100
                    dc.b    %00011111,%11000001,%11111100
                    dc.b    %11001111,%11011111,%11111111
                    dc.b    %11111111,%11111111,%11111111
                    dc.b    %11111100,%00111100,%00111111
                    dc.b    %11101100,%00111100,%00111011
                    dc.b    %00011111,%11111111,%11111000
                    dc.b    %10111111,%11111111,%11111111
                    dc.b    %00000011,%11000011,%11000000
                    dc.b    %00000011,%11000011,%11000000
                    dc.b    %00001111,%00111100,%11110000
                    dc.b    %00001111,%00111100,%11110000
                    dc.b    %11110000,%00000000,%00001111
                    dc.b    %11110000,%00000000,%00001111

InvaderA2_Break_Bitmap    dc.w     24,16
                    dc.b     %00000000,%11111111,%00000000
                    dc.b     %00000000,%11111100,%00000000
                    dc.b     %00111111,%11111000,%11111100
                    dc.b     %00011111,%11000001,%11111100
                    dc.b     %11001111,%11011111,%11111111
                    dc.b     %11111111,%11111111,%11111111
                    dc.b     %11111100,%00111100,%00111111
                    dc.b     %11101100,%00111100,%00111011
                    dc.b     %00011111,%11111111,%11111000
                    dc.b     %11111111,%11111111,%11111111
                    dc.b     %00001111,%11000011,%11110000
                    dc.b     %00001111,%11000011,%11110000
                    dc.b     %00111100,%00111100,%00111100
                    dc.b     %00111100,%00111100,%00111100
                    dc.b     %00001111,%00000000,%11110000
                    dc.b     %00001111,%00000000,%11110000


ShipShot_Bitmap     dc.w 2,6
					dc.b	%11000000
					dc.b	%11000000
					dc.b	%11000000
					dc.b 	%11000000
					dc.b	%11000000	
					dc.b	%11000000


InvaderShot1_Bitmap dc.w 4,6
                    dc.b %11000000
                    dc.b %11000000
                    dc.b %00110000
                    dc.b %00110000
                    dc.b %11000000
                    dc.b %11000000
InvaderShot2_Bitmap dc.w 4,6
                    dc.b %00110000
                    dc.b %00110000
                    dc.b %11000000
                    dc.b %11000000
                    dc.b %00110000
                    dc.b %00110000
                    
                    
                    
InvaderCShot1_Bitmap dc.w 6,6
                    dc.b %11001100
                    dc.b %11001100
                    dc.b %00110000
                    dc.b %00110000
                    dc.b %11001100
                    dc.b %11001100
InvaderCShot2_Bitmap dc.w 6,6
                    dc.b %00110000
                    dc.b %00110000
                    dc.b %11111100
                    dc.b %11111100
                    dc.b %00110000
                    dc.b %00110000



Heart				dc.w 6,8
                    dc.b %01101100
                    dc.b %11111110
                    dc.b %11111110
                    dc.b %01111100
                    dc.b %00111000
                    dc.b %00010000



