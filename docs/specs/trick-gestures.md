# Figures par gestes, réception au bon moment, et le Trick Park

**Statut : 🟢 Implémenté**

Session du 2026-11-14, avec Jimmy, après qu'il a joué les figures de
`docs/specs/air-tricks.md`. Cette spec **remplace le mécanisme de lancement et de
réception** de cette spec-là ; ce qu'elle ne change pas reste en vigueur. Son
développement commence quand le duel local (`docs/specs/local-duel.md`) est fusionné :
elle ajoute un choix à son écran de départ. Elle passe avant tout le reste : c'est la
base du jeu.

Amendée le 2026-11-14 après une partie de Jimmy sur la première version et la première
inspection. Jimmy : « quand on fait tourner le joystick ou avec la souris, c'est pas
assez précis encore. Ce serait bien […] qu'on puisse voir le tracé qu'on fait, comme ça
ça nous valide la figure une fois que le tracé est fini […] si je fais un arc de
cercle, des fois ça prend juste le backflip ». L'inspection a mesuré, sur 63 gestes
humains, les mêmes défauts : un coup au stick qui revient vite n'est pas lu, une petite
tenue avant une courbe compte comme un coup de plus, un retour de souris arrondi est lu
comme une vrille, un arc de 130° n'est pas une vrille. Décisions 17 à 20 ajoutées,
décisions 7 et 14 corrigées, scénarios marqués « amendement ».

Amendée une seconde fois le même jour, à la demande de Jimmy : « quand tu as fini ton
tracé et que tu lâches F, il fait le saut et la figure, parce que sinon c'est pas assez
fluide, ça va être trop galère de timer les deux ensemble […] si on est dans les airs,
il fait la figure sans sauter ». Décision 3 amendée (marquée « second amendement »).

## Contexte

Ce que Jimmy a vu en jouant, avec ses mots : « clavier-souris, c'est pas très
intuitif » ; « même à la manette, quand on veut faire des backflips […] si on met le
joystick vers le bas, il tourne sur le côté un peu » ; « les figures sont un peu trop
longues, parce que sur du flat on peut rien faire » ; « ce qui serait bien, c'est qu'on
puisse faire des figures un peu quand on veut, mais faut juste les faire proprement ».
Puis, sur la proposition : « j'aime beaucoup l'idée de la réception, faut appuyer sur le
bouton au bon moment » ; « avoir une variété de figures […] qui rapporte plus si on
essaie de les faire » ; « des figures qu'on peut faire que si on a une certaine hauteur,
d'autres qu'on peut faire sur du flat […] une variété qui permet de monter en skill » ;
« un grand espace vide pour qu'on puisse tester les figures, avec des petites hauteurs ».

Les causes, côté code :

- le stick gauche choisissait la figure **et** dirigeait le coureur : tirer vers le bas
  pour un backflip freinait et déviait ;
- un tour durait 0,65 s, plus qu'un saut à plat (environ 0,6 s), pour fermer une boucle
  sans risque ; il ne restait aucune figure possible sur le plat ;
- le skill était un calcul de hauteur, pas un geste qu'on sent.

La nouvelle idée : **on dessine la figure, on la pose.** Le bouton de figure tenu
transforme la souris (ou le stick droit) en pavé de dessin ; la figure part quand on le
lâche ; on la pose en appuyant sur le bouton de réception au bon moment avant le sol.
Le skill est dans le geste et dans le rythme de la réception ; la hauteur trie les
figures faciles des figures longues.

Ce qui existe sur `main` quand le développement commence : tout ce que construit
`docs/specs/air-tricks.md` (la figure dans `core`, `AirTrick`, le crash, les noms
composés, la rotation du corps visible, le HUD, les sons), le flow et ses règles
(`docs/specs/flow-combo.md`), la visée (`docs/specs/sabotage.md`, qui empêche une figure
en visée), l'écran de départ et les modes (`docs/specs/local-duel.md`).

Ce que la spec ne doit pas casser : tous les scénarios antérieurs, sauf ceux que la
décision 14 remplace explicitement ; les règles d'`AGENTS.md` (chaque action au
clavier-souris et à la manette, touches physiques, `core` sans scène ni entrée) ; les
limites de temps des portes.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Les boutons | **Figure** : **F** (touche physique) au clavier, **LB** à la manette ; se **garde enfoncé** pour dessiner. **Dessiner** : la souris, ou le stick droit. **Poser** : l'action de glissade, **Ctrl**, **RB** ou **B**. LB n'est plus un saut (A reste le saut) ; X et Shift ne servent plus aux figures. | Q7. Chaque doigt a un rôle ; le même geste existe aux deux claviers (règle d'`AGENTS.md`). |
| 2 | La caméra | Tant que le bouton de figure est tenu, la souris et le stick droit ne tournent plus la caméra : ils dessinent. Lâché, la caméra reprend. | Q12. |
| 3 | Dessiner, puis lancer | On peut commencer à dessiner au sol ou en l'air. La figure **part au pas où le bouton est lâché**, si le coureur est en l'air et peut lancer une figure (décision 6 de `docs/specs/air-tricks.md`). Lâché au sol, rien ne part et le dessin est oublié. **Second amendement**, qui remplace la phrase précédente : lâché **au sol**, là où un saut est permis (au sol ou dans la tolérance de saut, avec la place de se tenir debout), le coureur **saute** à ce pas, d'un saut entier comme si le bouton de saut était gardé jusqu'en haut, et la figure part au même pas. Lâché là où un saut n'est pas permis (en glissade sous un plafond bas, en roulade, en réception dure, en visée), rien ne part et le dessin est oublié. En l'air, rien ne change : la figure part sans saut. Le bouton de saut reste le saut simple. | Jimmy : « faire les figures avant de les réaliser ». Préparer pendant la course, lancer au saut. |
| 4 | Les gestes | Un **coup sec** dans une direction : haut **front flip**, bas **backflip**, gauche ou droite **side flip** de ce côté. Le **même coup répété** : un tour de plus (double, triple ; trois tours au plus). Un **demi-cercle** après le salto : une **vrille** (deux au plus par tour, et seulement sur un front flip ou un backflip). Un **cercle complet seul** : un **spin** à plat (360). Un geste qui ne se lit pas ne lance rien. | Q8. Une grammaire courte qui donne des dizaines de figures. |
| 5 | Reconnaître un geste | La reconnaissance est de la logique pure de `core` : elle reçoit les déplacements du pavé à chaque pas (de la souris ou du stick, ramenés à une même échelle par `player`) et rend la « recette » (salto, tours, vrilles) ou rien. Ses seuils (amplitude d'un coup, angle d'un demi-cercle, délais) sont dans la ressource de réglage. | Testable sans scène ; demain, la recette passera par le réseau comme une intention. |
| 6 | Sans geste | Un simple appui sur le bouton de figure, sans rien dessiner, lance la **figure du contexte** : front flip en courant vers l'avant, backflip à l'arrêt ou juste après un wall-jump, side flip en quittant un wall-run, du côté opposé au mur. Elle vaut la moitié des points d'un front flip. | Q9. Les débutants font quelque chose tout de suite. |
| 7 | Durées et hauteur | Un tour dure `trick_turn_duration` **0,35 s** ; chaque vrille ajoute `trick_twist_duration` **0,15 s** (**amendement** : **0,3 s**, pour qu'une vrille ne tienne pas dans un saut à plat) ; un spin dure un tour. Un simple tient dans un saut à plat ; une vrille demande une petite descente ; un double, une descente ou un wall-jump. Les figures ne s'enchaînent plus en l'air : une seule figure par saut. | Q10. La hauteur trie les figures. |
| 8 | Poser la figure | Une figure finie doit être **posée** : un appui sur glissade au plus `trick_landing_window` (**0,25 s**) avant le contact avec le sol. Au plus `trick_perfect_window` (**0,1 s**) avant : **PERFECT**. Pas d'appui dans la fenêtre, ou figure pas finie au contact : **crash** (réception dure et erreur du flow, comme aujourd'hui). Un appui plus tôt que la fenêtre est perdu ; on peut réappuyer. La figure ne rapporte qu'une fois posée ; un wall-run ou un mantle après une figure finie la paie sans appui ni PERFECT, comme aujourd'hui. | Q1 et Jimmy : « faut appuyer sur le bouton au bon moment ». |
| 9 | Réception et glissade | L'appui de réception est un appui de glissade comme un autre : une réception qui demande une roulade roule ; sur le plat, assez vite, le coureur glisse, et la glissade est parfaite si elle est dans sa fenêtre. | Q6. La ligne « flow » : figure posée, glissade parfaite. |
| 10 | Les points | Front flip et backflip **200**, side flip et spin **250** ; figure du contexte **100** ; double **× 2,5**, triple **× 4** ; chaque vrille **+ 150** ; PERFECT **+ 50 %** ; puis la variété et le multiplicateur du flow. Le gain de vitesse du PERFECT reste, plafonné comme aujourd'hui. | Q11. Plus c'est dur, plus ça rapporte. |
| 11 | La variété | Deux figures sont le même move si leur recette est la même (salto, tours, vrilles) ; une figure du contexte est le move de sa recette. | Q14 et Q5 de la session. |
| 12 | Le HUD | Pendant que le joueur dessine, le nom de la recette lue s'affiche et se met à jour (« BACKFLIP », « BACKFLIP FULL »…), ou « ? » si rien ne se lit encore ; puis, comme aujourd'hui, la figure en cours, « PERFECT » ou « CRASH ». | Apprendre les gestes en les voyant. |
| 13 | Le Trick Park | Un nouveau mode, **« TRICK PARK »**, dans l'écran de départ : une grande esplanade plate (au moins 100 m × 100 m) avec des blocs à gravir (par des marches et des rebords à mantle) d'où sauter vers le sol : **1 m, 2 m, 3 m, 5 m et 8 m** ; une paire de murs face à face pour les wall-jumps ; un mur à wall-run au-dessus d'un sol. Pas de chrono, pas de cible, pas d'adversaire ; le HUD du flow est là ; le retour au point de départ (R, Y) et le menu (Échap, Start) marchent. Il se joue à partir d'une scène de `game/levels/`. | Demande de Jimmy, pour tester les figures selon la hauteur. |
| 14 | Ce qui est remplacé | Dans `docs/specs/air-tricks.md` : les décisions 1 (le bouton), 2 (le stick choisit), 3 (garder pour les tours), 4 (vrilles sur saut), 7 (enchaîner en l'air), 9 (quand les figures rapportent, pour la réception au sol), 10 (PERFECT par la fin de la figure), 11 (les points) et la valeur d'un tour de 0,65 s. Leurs scénarios sont **remplacés** par ceux de cette spec ; leurs tests sont réécrits ou retirés avec eux, aucun ne reste sur une règle remplacée. Le reste (le crash, le paiement au wall-run et au mantle, la rotation du corps visible, les sons, pas de wall-run ni de mantle pendant une figure, pas de saut fantôme) reste. | Pas de règle contredite en silence. |
| 15 | Le risque sur le plat | Un joueur sans risque qui enchaîne saut, figure et réception sur le plat est mesuré pendant une minute (style, munitions, vitesse) contre la course et le saut seuls ; la variété doit en limiter le gain. Le chiffre va dans le rapport et la spec. | Leçon 1 de `docs/harness/2026-11-14-flow-combo.md`. |
| 17 | Le pavé à l'écran | **Amendement.** Tant que le bouton de figure est tenu, un pavé rond s'affiche au centre de l'écran : le tracé de la souris ou du stick s'y dessine en direct, à la même échelle que la reconnaissance. Chaque élément reconnu s'y marque (une flèche pour un coup sec, un arc pour une vrille, un cercle pour un spin), et le nom de la recette lue s'affiche à côté. Quand le tracé forme une recette complète, le pavé change de couleur et de forme de bord : la figure est **validée**, et c'est elle qui partira au lâcher. Lâché, le pavé disparaît. Le pavé est de la présentation (`game/ui/`) : il lit le tracé et la recette de `core`. | Demande de Jimmy : voir ce qu'on dessine et savoir ce qui va partir. |
| 18 | Une lecture faite pour la main | **Amendement.** Tous les seuils de la reconnaissance sont dans la ressource de réglage (groupe Tricks), y compris ceux qui étaient des constantes du code (bruit, virage qui sépare deux éléments, courbure d'un coup sec, part droite d'un « J »). La reconnaissance doit lire ce qu'une main veut dire : un coup sec au stick finit dès que le stick revient dans sa zone morte, même vite et même s'il dépasse le centre ; un coup au stick poussé à 60 % compte ; un arc d'au moins **100°** après le salto est une vrille, qu'il commence par une partie droite ou non ; une petite tenue au début d'une courbe ne compte pas comme un coup de plus ; un retour de la main qui s'arrondit puis repart contre le coup n'est pas une vrille. Les 63 gestes humains mesurés par l'inspection, plus ceux décrits par Jimmy, deviennent un **corpus de test** : chacun avec la recette attendue. | Jimmy : « pas assez précis ». La spec disait déjà « à régler par Jimmy » : il faut que ce soit réglable. |
| 19 | La répétition des figures survit à la fin d'un combo | **Amendement.** La fenêtre de répétition du flow n'est plus vidée par la fin d'un combo au délai (elle reste vidée par une erreur, une chute, un recommencement). Ceci remplace, dans `docs/specs/flow-combo.md`, la phrase « la fin d'un combo par le délai et une erreur le remettent aussi à zéro » pour la fin au délai. | L'inspection a mesuré une boucle sans risque à 27 350 points par minute : quatre figures simples, une pause de 2 s pour laisser finir le combo, et on recommence. |
| 20 | Poser en grande chute | **Amendement.** L'appui qui pose une figure compte aussi pour la roulade, dans toute la fenêtre de réception : une figure posée ne finit jamais en réception dure. | Une figure posée entre 0,2 et 0,25 s avant le sol, en grande chute, payait ses points puis cassait le combo par une réception dure. |
| 21 | Le Trick Park, mur par mur | **Amendement.** Aucune face d'un bloc du Trick Park n'est dans le même plan que la face d'un bloc voisin qui la touche : chaque mur visible est un seul objet (règle d'`AGENTS.md`). | L'inspection a trouvé un mur de 8 m fait de trois blocs alignés, où un wall-run pouvait se relancer. |
| 16 | Les réglages | Toutes les valeurs nouvelles (seuils des gestes, durées, fenêtres, points) vivent dans la ressource de réglage, groupe « Tricks » ; F4 les recharge. | Règle d'`AGENTS.md`. |

### Valeurs de départ de la ressource de réglage

| Réglage | Valeur |
| ------- | ------ |
| Durée d'un tour, d'une vrille (amendement) | 0,35 s, 0,3 s |
| Arc minimal d'une vrille (amendement) | 100° |
| Tours au plus, vrilles au plus par tour | 3, 2 |
| Fenêtre de réception, fenêtre PERFECT | 0,25 s, 0,1 s |
| Points : front flip et backflip, side flip et spin, figure du contexte | 200, 250, 100 |
| Multiplicateur d'un double, d'un triple ; points d'une vrille | × 2,5, × 4 ; + 150 |
| Geste : amplitude d'un coup sec, angle d'un demi-cercle, délai entre deux éléments | au choix du développeur, à régler par Jimmy |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Figures par gestes

  # --- Reconnaître les gestes (core) ---

  Scénario: Un coup sec choisit le salto
    Soit un dessin vide
    Quand le pavé fait un coup sec vers le haut, le bas, la gauche ou la droite
    Alors la recette est un front flip, un backflip, ou un side flip de ce côté

  Scénario: Le même coup répété ajoute un tour
    Soit un dessin qui a lu un backflip
    Quand le pavé refait un coup sec vers le bas, puis encore un
    Alors la recette est un double backflip, puis un triple, et pas plus

  Scénario: Un demi-cercle ajoute une vrille
    Soit un dessin qui a lu un backflip
    Quand le pavé fait un demi-cercle, puis un second
    Alors la recette est un backflip à une vrille, puis à deux, et pas plus par tour

  Scénario: Pas de vrille sur un side flip ni un spin
    Soit un dessin qui a lu un side flip, puis un dessin qui a lu un spin
    Quand le pavé fait un demi-cercle
    Alors la recette n'a pas de vrille

  Scénario: Un cercle seul est un spin
    Soit un dessin vide
    Quand le pavé fait un cercle complet
    Alors la recette est un spin

  Scénario: Un geste illisible ne lance rien
    Soit un dessin vide
    Quand le pavé bouge trop peu pour un coup sec, ou au hasard
    Alors aucune recette n'est lue

  # --- Dessiner et lancer (player et core) ---

  Scénario: Tenir le bouton de figure fige la caméra
    Soit un coureur qui tient le bouton de figure
    Quand la souris bouge, puis le stick droit
    Alors la caméra ne tourne pas, et elle tourne de nouveau une fois le bouton lâché

  Scénario: La figure part quand on lâche le bouton en l'air
    Soit un coureur qui a dessiné un backflip au sol puis a sauté
    Quand il lâche le bouton de figure en l'air
    Alors un backflip commence à ce pas

  Scénario: Lâcher le bouton au sol saute et lance la figure
    # second amendement : remplace « Lâcher le bouton au sol ne lance rien »
    Soit un coureur au sol qui a dessiné un backflip
    Quand il lâche le bouton de figure
    Alors il saute d'un saut entier et le backflip commence au même pas

  Scénario: Un saut de figure sur le plat laisse le temps d'un simple
    # second amendement
    Soit un coureur qui court sur le plat et a dessiné un front flip
    Quand il lâche le bouton de figure au sol puis appuie sur glissade au bon moment
    Alors le front flip est fini avant le sol et posé

  Scénario: Lâcher le bouton là où on ne peut pas sauter ne lance rien
    # second amendement
    Soit un coureur en roulade, puis un coureur en réception dure, qui a dessiné un backflip
    Quand il lâche le bouton de figure
    Alors il ne saute pas, rien ne commence, et le dessin est oublié

  Scénario: Sans geste au sol, le saut lance la figure du contexte
    # second amendement
    Soit un coureur qui court vers l'avant au sol
    Quand il appuie sur le bouton de figure et le lâche sans rien dessiner
    Alors il saute et un front flip commence

  Scénario: Sans geste, la figure du contexte part
    Soit un coureur qui court vers l'avant, puis un coureur qui vient de faire un wall-jump, puis un coureur qui quitte un wall-run
    Quand il appuie sur le bouton de figure et le lâche en l'air sans rien dessiner
    Alors un front flip, un backflip, ou un side flip du côté opposé au mur commence

  Scénario: Une seule figure par saut
    Soit un coureur qui a fini une figure en l'air
    Quand il dessine et lâche le bouton de figure avant la réception
    Alors aucune seconde figure ne commence

  # --- Durées (core) ---

  Scénario: Un simple tient dans un saut à plat
    Soit un coureur qui court sur le plat
    Quand il saute en gardant le saut, lance un front flip au début du saut et le pose
    Alors la figure est finie avant le sol et posée

  Scénario: Un double ne tient pas dans un saut à plat
    Soit un coureur qui court sur le plat
    Quand il saute et lance un double backflip au début du saut
    Alors il touche le sol avant la fin et se crashe

  Scénario: Une vrille allonge la figure
    Soit deux figures lancées au même pas, un backflip et un backflip à une vrille
    Quand le temps passe
    Alors le backflip vrillé finit une durée de vrille après l'autre

  # --- Poser la figure (core) ---

  Scénario: Appuyer dans la fenêtre pose la figure
    Soit un coureur dont la figure est finie, en l'air
    Quand il appuie sur glissade dans la fenêtre de réception, mais avant la fenêtre PERFECT, puis touche le sol
    Alors la figure est posée et rapporte ses points, sans PERFECT

  Scénario: Appuyer au dernier moment donne un PERFECT
    Soit un coureur dont la figure est finie, en l'air
    Quand il appuie sur glissade dans la fenêtre PERFECT, puis touche le sol
    Alors la figure est PERFECT : elle vaut le bonus en plus et sa vitesse gagne le gain, plafonné

  Scénario: Ne pas appuyer est un crash
    Soit un coureur dont la figure est finie, en l'air
    Quand il touche le sol sans avoir appuyé sur glissade dans la fenêtre
    Alors il se crashe et la figure ne rapporte rien

  Scénario: Un appui trop tôt est perdu
    Soit un coureur dont la figure est finie, haut au-dessus du sol
    Quand il appuie sur glissade avant la fenêtre, puis ne réappuie pas
    Alors il se crashe en touchant le sol

  Scénario: Un appui trop tôt peut être refait
    Soit un coureur qui a appuyé sur glissade avant la fenêtre
    Quand il réappuie dans la fenêtre
    Alors la figure est posée

  Scénario: Une figure pas finie au sol est un crash même avec l'appui
    Soit un coureur dont la figure n'est pas finie
    Quand il appuie sur glissade dans la fenêtre puis touche le sol
    Alors il se crashe

  Scénario: Une figure posée en grande chute roule
    Soit un coureur qui tombe de plus haut que la hauteur de roulade, sa figure finie
    Quand il appuie sur glissade dans la fenêtre puis touche le sol
    Alors la figure est posée et il roule

  Scénario: Une figure posée sur le plat lance une glissade
    Soit un coureur assez rapide pour glisser, sa figure finie, sur le plat
    Quand il appuie sur glissade dans la fenêtre et la garde
    Alors la figure est posée et il glisse

  Scénario: Une figure rapporte au début d'un wall-run sans appui
    Soit un coureur dont la figure est finie, le long d'un mur
    Quand il entre en wall-run
    Alors la figure rapporte ses points, sans PERFECT

  # --- Points et variété (core) ---

  Scénario: Les points suivent la difficulté
    Soit des figures posées sans PERFECT, chacune première de son combo
    Quand on lit leurs points
    Alors un backflip vaut 200, un side flip 250, une figure du contexte 100, un double backflip 500 et un backflip à une vrille 350

  Scénario: Deux recettes différentes ne sont pas une répétition
    Soit un coureur qui vient de poser un backflip
    Quand il pose un backflip à une vrille
    Alors cette figure vaut tous ses points

  Scénario: Une boucle sans risque sur le plat rapporte peu
    Soit un coureur qui, sur le plat, enchaîne pendant une minute saut, figure et réception parfaite, en variant les figures qui tiennent dans un saut à plat
    Quand on compte ce qu'il a gagné
    Alors son style par minute reste sous 4 800 (3 790 mesurés)

  # --- Vraies entrées et vraie physique ---

  Scénario: Un backflip vrillé au clavier-souris
    Soit un coureur dans le Trick Park, mené par les vraies entrées du clavier et de la souris, devant un bloc de 2 m
    Quand il saute du bloc en tenant F, fait un coup de souris vers le bas puis un demi-cercle, lâche F, puis appuie sur Ctrl au bon moment
    Alors il pose un backflip à une vrille

  Scénario: Un backflip vrillé à la manette
    Soit un coureur dans le Trick Park, mené par les vraies entrées de la manette, devant un bloc de 2 m
    Quand il saute du bloc en tenant LB, fait un coup de stick droit vers le bas puis un demi-cercle, lâche LB, puis appuie sur RB au bon moment
    Alors il pose un backflip à une vrille

  Scénario: Le Trick Park offre toutes les hauteurs
    Soit le Trick Park
    Quand on mesure ses blocs et ses murs
    Alors il a des blocs à 1, 2, 3, 5 et 8 m, chacun gravissable, une paire de murs face à face et un mur à wall-run, sur une esplanade d'au moins 100 m sur 100 m

  Scénario: Le Trick Park se choisit dans l'écran de départ
    Soit l'écran de départ
    Quand le joueur choisit « TRICK PARK » au clavier, puis à la manette
    Alors le Trick Park démarre, sans chrono ni cible ni adversaire

  # --- Affichage ---

  # --- Amendement : le pavé et la lecture ---

  Scénario: Le pavé montre le tracé et valide la figure
    # amendement
    Soit un coureur qui tient le bouton de figure
    Quand il fait un coup vers le bas puis un demi-cercle
    Alors le pavé montre le tracé, marque le coup puis l'arc, et passe à l'état validé avec « BACKFLIP FULL »

  Scénario: Le pavé disparaît au lâcher
    # amendement
    Soit un coureur qui tient le bouton de figure et a dessiné
    Quand il lâche le bouton
    Alors le pavé n'est plus affiché

  Scénario: Les gestes humains sont lus comme la main les veut
    # amendement
    Soit le corpus des gestes humains, souris et stick, chacun avec sa recette attendue
    Quand chacun est passé à la reconnaissance avec le réglage du projet
    Alors chacun donne sa recette attendue

  Scénario: Un coup au stick qui revient vite est lu
    # amendement
    Soit un stick poussé vers le bas et relâché en 0,1 s, puis un stick poussé à 60 %
    Quand chacun est lu
    Alors chacun donne un backflip

  Scénario: Un arc après le salto est une vrille
    # amendement
    Soit un dessin qui a lu un backflip
    Quand le pavé trace un arc de 100° sans partie droite
    Alors la recette est un backflip à une vrille

  Scénario: Un retour de la main arrondi n'est pas une vrille
    # amendement
    Soit un coup sec vers le bas
    Quand la main revient en s'arrondissant puis repart vers le haut
    Alors la recette reste un backflip

  Scénario: La répétition des figures survit à la fin d'un combo
    # amendement
    Soit un coureur qui pose quatre figures simples différentes, laisse finir son combo, puis recommence
    Quand on compte son style pendant une minute
    Alors il reste sous le seuil de la boucle sans risque sur le plat

  Scénario: Une figure posée en grande chute ne finit pas en réception dure
    # amendement
    Soit un coureur qui tombe de plus haut que la hauteur de roulade, sa figure finie
    Quand il appuie sur glissade entre la fenêtre de roulade et le début de la fenêtre de réception
    Alors la figure est posée, il roule et son combo continue

  Scénario: Aucun mur du Trick Park n'est fait de plusieurs blocs
    # amendement
    Soit le Trick Park
    Quand on compare les faces des blocs qui se touchent
    Alors aucune n'est dans le même plan qu'une face voisine

  Scénario: Le HUD montre la recette en cours de dessin
    Soit un coureur qui tient le bouton de figure
    Quand il fait un coup vers le bas puis un demi-cercle
    Alors le HUD affiche « BACKFLIP », puis « BACKFLIP FULL »
```

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** :

  | Composant | Couche | Statut |
  | --------- | ------ | ------ |
  | HUD du flow | `game/ui/` | modifié : la recette en cours de dessin |
  | Écran de départ | `game/ui/` | modifié : le choix « TRICK PARK » |
  | Trick Park | `game/levels/` | créé |

- **États du HUD** : bouton de figure tenu, « ? » puis le nom de la recette lue au-dessus
  de la jauge ; ensuite, comme aujourd'hui.
- **Le pavé (amendement)** : un disque translucide au centre, environ un cinquième de la
  hauteur de l'écran ; le tracé en ligne claire ; les éléments reconnus marqués ; le
  bord change de couleur et s'épaissit quand la recette est validée (pas seulement la
  couleur) ; caché quand le bouton n'est pas tenu.
- **Focus** : l'écran de départ garde sa navigation ; « TRICK PARK » est un choix de
  plus, après les duels.
- **Libellés** (en anglais) : « TRICK PARK », « ? », les noms de
  `docs/specs/air-tricks.md`.

## Choix acceptés après le développement

Le code et la session principale ont tranché ces points le 2026-11-14 ; Jimmy peut
rouvrir chacun après avoir joué.

- **La boucle sans risque sur le plat (décision 15)** : avec la fenêtre de répétition du
  flow à 4 moves et une vrille de 0,15 s, enchaîner les six figures qui tenaient dans un
  saut à plat, toutes en PERFECT, rapportait 156 200 points de style par minute. La
  fenêtre de répétition passe à **10 moves** (`flow_repetition_window`, réglage du
  projet) et une vrille dure **0,3 s** (`trick_twist_duration`) : une figure vrillée ne
  tient plus dans un saut à plat, il reste les quatre simples, et la boucle rapporte
  **3 790** points par minute (75 en sautant sans figure). Le test refuse plus de 4 800.
- **Les seuils des gestes** (dans la ressource de réglage, après l'amendement) : le stick
  à fond vaut 18 unités par seconde ; un coup sec fait au moins 0,65 unité (65 px de
  souris) ; un dessin de moins de 0,55 unité compte comme rien (la figure du contexte
  part) ; une vrille se lit dès 100° d'arc, deux vrilles dès 300° ; un cercle dès 270°.
  Le corpus des gestes humains les garde. À régler par Jimmy en jouant.
- **Le spin** : un deuxième cercle fait un 720, un troisième un 1080, trois tours au plus.
- **« À l'arrêt »** pour la figure du contexte : sous la vitesse d'arrêt du flow (1 m/s).
- **Le côté d'un side flip** ne compte pas pour la variété ; une figure du contexte est le
  même move que la recette dessinée qui lui correspond.
- **Le sens de la vrille** suit le sens du demi-cercle ; les points ne changent pas.
- **Poser** : un appui dans la fenêtre compte même avant la fin de la figure, si elle est
  finie au contact ; un appui au pas du contact est un PERFECT ; un appui entre 0,2 et
  0,25 s avant le sol pose la figure et fait rouler en grande chute (décision 20 ; avant
  l'amendement, il ne faisait pas rouler).
- **Le dessin à la souris** marche même souris non capturée ; la caméra, elle, demande la
  capture.
- **Le HUD** : bouton tenu, le dessin passe avant la figure en cours ; « ? » aussi pour un
  dessin vide.
- **Le Trick Park** : 120 m × 120 m, blocs de 1, 2, 3, 5 et 8 m (5 et 8 m par des marches
  de 2,5 m), deux murs face à face à 4 m, un mur à wall-run ; pas de réticule, et
  recommencer n'y fait rien.

## Hors périmètre

- Les grabs et les figures au sol : des briques de plus, plus tard.
- Changer les touches dans un menu : étape 6.
- Le pilote et le bot ne font toujours pas de figure.
- Des figures pour le parcours de course (endroits dédiés) : avec le dessin des niveaux.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Composer des figures avec des briques plutôt qu'une liste | discovered | discovered |
| Séparer le geste (présentation des entrées) de sa recette (logique) | — | discovered |
