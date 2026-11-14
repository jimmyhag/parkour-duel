# Le personnage animé : Mixamo, gardé hors du dépôt

**Statut : 🟡 Prêt pour le dev**

Session du 2026-11-14, avec Jimmy. Première partie de l'étape 6 de la feuille de route
(« Art, audio, menus »), avancée avant l'étape 5 par décision de Jimmy : « je pense
qu'on va pouvoir passer aux animations ». Le jeu en ligne attend ; les figures, le flow,
le tir et le duel sont jugés par Jimmy en jouant (il a trouvé les figures « beaucoup
plus fluides […] ça peut s'enchaîner »).

Amendée le 2026-11-14 après une partie de Jimmy : « le wallrun, tu l'as fait du mauvais
côté […] il rentre sa tête dans le mur. Il faut qu'il soit bien attaché au mur et que ses
pieds ne rentrent pas aussi dans le mur ». Décision 12 ajoutée, scénario marqué « pose de
wall-run ».

## Contexte

Jimmy a choisi **Mixamo** (Adobe), pour la fluidité de la capture de mouvement. La FAQ
officielle (lue le 2026-11-14,
https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html) dit : gratuit avec un
compte Adobe ; personnages et animations utilisables « royalty free for personal,
commercial, and non-profit projects », dont « Create video games ». Elle ne dit rien de
la redistribution des fichiers bruts. Le dépôt est **public** et doit le rester (le
quota de CI des dépôts privés est épuisé) : les fichiers Mixamo ne vont **jamais** dans
le dépôt.

Jimmy a téléchargé, dans `C:\Users\jimmy\Documents\mixamo\` : le personnage
`Ch08_nonPBR.fbx`, et les animations `Idle`, `Running`, `Jump`, `Falling Idle`,
`Landing`, `Hard Landing`, `Falling To Roll`, `Running Slide`, `Sprint To Wall Climb`,
`Wall Run`, `Backflip`, `Running Forward Flip` (chacune avec le personnage dedans,
environ 87 Mo), et le pack `Pistol_Handgun Locomotion Pack.zip` (animations sans le
personnage, dont `pistol idle.fbx`).

Ce qui existe sur `main` : le corps visible (`Visual`, une capsule et sa visière) est de
la présentation seule ; il regarde la poussée, penche en wall-run, tourne avec une
figure (`docs/specs/runner-facing.md`, `docs/specs/air-tricks.md`,
`docs/specs/trick-gestures.md`). Le moteur expose son état (`RunnerMotor.state`, la
figure en cours, la visée).

Ce que la spec ne doit pas casser : tous les scénarios ; ce que le coureur constate ne
dépend jamais du corps visible (`AGENTS.md`) ; la CI, qui n'a pas les fichiers Mixamo ;
aucun asset sans licence vérifiée.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Où vivent les fichiers | Dans `assets/mixamo/`, **ignoré par Git** (ligne dans `.gitignore`). Une commande `just mixamo <dossier>` y copie les fichiers depuis le dossier de téléchargement, donné en argument (aucun chemin de machine n'est écrit dans le dépôt), et extrait du zip les seules animations utilisées. | Rien n'est redistribué ; le dépôt reste public. |
| 2 | Le jeu sans les fichiers | Si `assets/mixamo/` n'a pas le personnage, le jeu affiche la capsule actuelle, exactement comme aujourd'hui. La CI et les tests tournent ainsi. | La CI n'a pas les fichiers ; aucun test ne doit en dépendre. |
| 3 | Le jeu avec les fichiers | Le personnage remplace la capsule dans `Visual` ; il est mis à la hauteur de la capsule debout (1,8 m), les pieds au sol. Une seule copie du maillage est gardée (celle de `Ch08_nonPBR.fbx`) ; des autres fichiers, seule l'animation est importée. | Presentation only ; une seule copie du maillage dans le jeu. |
| 4 | Quelle animation pour quel état | Debout et lent : `Idle` ; au sol en mouvement : `Running`, sa vitesse de lecture suivant la vitesse horizontale ; `RISING` : `Jump` ; `FALLING` : `Falling Idle` ; atterrissage simple : `Landing`, brève ; `HARD_LANDING` : `Hard Landing` ; `ROLLING` : `Falling To Roll` (sa partie roulade) ; `SLIDING` : `Running Slide` ; `MANTLING` : `Sprint To Wall Climb` (sa partie où il se hisse) ; `WALL_RUNNING` : `Wall Run`, en miroir pour un mur de l'autre côté ; en visée : `pistol idle` sur le haut du corps, les jambes gardant leur animation. | Chaque état du moteur a son mouvement. |
| 5 | Les figures | Le corps entier tourne comme aujourd'hui (salto, vrilles, spin) ; pendant la figure, le personnage prend une **pose groupée**, extraite de `Backflip` (ou `Running Forward Flip`), puis se déplie à la fin. Une seule pose pour toutes les recettes. | Les figures sont composées : une animation par figure est impossible, une pose suffit (décision prise avec Jimmy). |
| 6 | Le mouvement racine | Les animations jouent **sur place** : toute translation de l'os racine est retirée (les fichiers sans « In Place », comme `Wall Run` ou `Sprint To Wall Climb`, compris). **Amendement** : la translation horizontale est retirée partout ; la hauteur des hanches est gardée là où c'est une posture (glissade, roulade, réceptions, Idle, course) et ramenée à la hauteur de repos là où le moteur fait déjà le mouvement (`Jump`, `Wall Run`, `Sprint To Wall Climb`) : sinon les jambes passeraient sous le sol. Seul le moteur déplace le coureur. | Le moteur décide du mouvement ; l'animation le montre. |
| 7 | Les fondus | Entre deux animations, un fondu court (`animation_blend_time`, 0,1 s, ressource de réglage) ; les entrées brusques (crash, réception dure) sans fondu. | Fluidité, sans retard sur l'état. |
| 8 | La logique testable | Le choix de l'animation à partir de l'état du moteur (nom, vitesse de lecture, miroir, haut du corps en visée, pose de figure) est une fonction pure testée sans les fichiers. Le branchement sur un `AnimationPlayer` ou `AnimationTree` est de la présentation. | Les tests tournent dans la CI sans Mixamo. |
| 9 | Le bot et le fantôme | Ils prennent le même personnage, teinté (orange pour le bot ; orange transparent pour le fantôme), si les fichiers sont là ; sinon leur capsule. Le fantôme rejoue aussi l'état enregistré pour son animation. | Lisibles comme aujourd'hui, avec le vrai corps. |
| 10 | Crédits et README | `assets/CREDITS.md` décrit les fichiers Mixamo (source, auteur Adobe Mixamo, conditions de la FAQ, et qu'ils ne sont pas dans le dépôt) ; le README liste exactement les fichiers à télécharger sur mixamo.com, leurs réglages, et la commande `just mixamo`. La règle d'`AGENTS.md` sur `assets/` reste vraie : chaque fichier présent a sa ligne. | Qui reprend le dépôt sait quoi télécharger. |
| 11 | La visière et l'inclinaison | La visière disparaît avec le personnage ; l'inclinaison de wall-run reste sur `Visual` (réglable à 0 si l'animation `Wall Run` suffit). | La visière ne servait qu'à lire la capsule. |

### Décision ajoutée

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 12 | La pose du wall-run | **Pose de wall-run.** En wall-run, le personnage a **les pieds du côté du mur et la tête qui s'en écarte** : le miroir du clip `Wall Run` est choisi d'après le côté où son pied d'appui est dans le fichier, mesuré, pas supposé. Aucun os (pieds compris) ne passe derrière la surface du mur ; les pieds la touchent presque (à quelques centimètres) : le personnage est décalé latéralement si besoin. L'inclinaison de la capsule (`wall_run_lean`) ne s'applique pas quand le personnage est affiché : l'animation penche déjà. | Jimmy a vu la tête rentrer dans le mur. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Le personnage animé

  # --- Choisir l'animation (sans les fichiers) ---

  Scénario: Chaque état du coureur a son animation
    Soit un coureur dans chacun de ses états
    Quand on choisit son animation
    Alors c'est Idle, Running, Jump, Falling Idle, Hard Landing, Falling To Roll, Running Slide, Sprint To Wall Climb ou Wall Run selon l'état

  Scénario: La course suit la vitesse
    Soit un coureur au sol à la moitié puis à la totalité de sa vitesse de pointe
    Quand on choisit son animation
    Alors c'est Running, lue plus lentement à la moitié qu'à la totalité

  Scénario: Le wall-run de l'autre côté est en miroir
    Soit un coureur en wall-run le long d'un mur à sa gauche, puis à sa droite
    Quand on choisit son animation
    Alors c'est Wall Run, en miroir pour l'un des deux

  Scénario: Une figure prend la pose groupée
    Soit un coureur en pleine figure
    Quand on choisit son animation
    Alors c'est la pose groupée

  Scénario: La visée prend le haut du corps
    Soit un coureur qui court en visant
    Quand on choisit son animation
    Alors les jambes courent et le haut du corps tient la pose de visée

  Scénario: Un atterrissage simple joue Landing brièvement
    Soit un coureur qui vient d'atterrir d'une petite chute
    Quand on choisit son animation pendant les premiers pas au sol
    Alors c'est Landing, puis la course ou Idle

  Scénario: Une entrée brusque se fait sans fondu
    # amendement
    Soit un coureur qui court
    Quand il fait une réception dure, puis un crash
    Alors l'animation change sans fondu

  Scénario: Le fantôme rejoue l'animation enregistrée
    # amendement
    Soit une course enregistrée avec l'animation de chaque pas
    Quand le fantôme la rejoue
    Alors à chaque pas il montre l'animation enregistrée à ce pas

  Scénario: En wall-run, les pieds sont au mur et la tête s'en écarte
    # pose de wall-run
    Soit un coureur en wall-run le long d'un mur à sa gauche, puis à sa droite, le personnage affiché
    Quand on mesure ses os par rapport au mur
    Alors la tête est plus loin du mur que les pieds, aucun os n'est derrière la surface du mur, et les pieds sont à quelques centimètres de la surface

  # --- Sans les fichiers ---

  Scénario: Sans les fichiers, la capsule reste
    Soit un projet sans le personnage dans assets/mixamo
    Quand le coureur apparaît
    Alors son corps visible est la capsule et sa visière, comme avant

  Scénario: Les fichiers Mixamo ne sont jamais suivis par Git
    Soit le dépôt
    Quand on lit .gitignore et les fichiers suivis
    Alors assets/mixamo est ignoré et aucun fichier Mixamo n'est suivi

  # --- La copie des fichiers ---

  Scénario: La commande de copie range les fichiers utilisés
    Soit un dossier de téléchargement avec le personnage, les animations et le pack pistolet
    Quand on lance la commande de copie sur ce dossier
    Alors assets/mixamo contient le personnage, chaque animation utilisée, et pistol idle extrait du pack, et rien d'autre du pack
```

La présentation avec les vrais fichiers (le personnage à l'écran, les fondus, la pose
groupée, le miroir, le haut du corps) ne peut pas être prouvée par la CI : le
développeur la vérifie sur cette machine, où les fichiers sont présents (import Godot
sans erreur, scène qui charge, captures d'écran ou relevés d'os à l'appui), et Jimmy la
juge en jouant.

## Choix acceptés après le développement

Acceptés le 2026-11-14 ; Jimmy peut rouvrir chacun après avoir joué.

- **Les parties de clips gardées** (roulade, mantle, réceptions, glissade, saut,
  wall-run) sont choisies d'après les données des fichiers ; les états à durée fixe
  étirent leur clip.
- **Trois réglages en plus** (groupe Animation) : la vitesse où `Running` joue à son
  rythme (6 m/s), la vitesse sous laquelle c'est `Idle` (0,5 m/s), la durée de
  `Landing` (0,25 s).
- **Le moteur** expose `steps_since_landing` en lecture et écriture publique : la limite
  de 20 méthodes publiques de gdlint empêchait une méthode de plus ; acceptée par
  précédent (`trick_ready`). La prochaine fois, une vue en lecture seule du moteur.
- **Tout ou rien** : le personnage n'apparaît que si lui et ses 12 clips sont présents.
- **Le clip `Wall Run`** a son mur à gauche : il est mis en miroir le long d'un mur à
  droite.
- **La visée** : un modificateur de squelette redresse le buste de `pistol idle`.
- **Les teintes** : le bot garde ses textures sous un voile orange ; le fantôme prend le
  matériau transparent de sa capsule.
- **Les builds de release** contiennent le personnage quand les fichiers sont présents
  sur la machine qui construit (environ 88 Mo de plus) : c'est l'usage qu'autorise la FAQ.

## Hors périmètre

- Des animations pour chaque figure : la pose groupée suffit (décision 5).
- Le modèle de l'arme, les effets de tir, les visages : plus tard.
- Les autres parties de l'étape 6 (menus d'options, musique, décor Kenney) : plus tard.
- Le jeu en ligne (étape 5) : après, sur décision de Jimmy.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Un asset sous licence restrictive tenu hors d'un dépôt public, avec un repli | — | discovered |
| Séparer le choix d'une animation (logique testable) de son affichage | — | discovered |
