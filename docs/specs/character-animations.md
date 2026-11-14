# Le personnage animé : Mixamo, gardé hors du dépôt

**Statut : 🟡 Prêt pour le dev**

Session du 2026-11-14, avec Jimmy. Première partie de l'étape 6 de la feuille de route
(« Art, audio, menus »), avancée avant l'étape 5 par décision de Jimmy : « je pense
qu'on va pouvoir passer aux animations ». Le jeu en ligne attend ; les figures, le flow,
le tir et le duel sont jugés par Jimmy en jouant (il a trouvé les figures « beaucoup
plus fluides […] ça peut s'enchaîner »).

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
| 6 | Le mouvement racine | Les animations jouent **sur place** : toute translation de l'os racine est retirée (les fichiers sans « In Place », comme `Wall Run` ou `Sprint To Wall Climb`, compris). Seul le moteur déplace le coureur. | Le moteur décide du mouvement ; l'animation le montre. |
| 7 | Les fondus | Entre deux animations, un fondu court (`animation_blend_time`, 0,1 s, ressource de réglage) ; les entrées brusques (crash, réception dure) sans fondu. | Fluidité, sans retard sur l'état. |
| 8 | La logique testable | Le choix de l'animation à partir de l'état du moteur (nom, vitesse de lecture, miroir, haut du corps en visée, pose de figure) est une fonction pure testée sans les fichiers. Le branchement sur un `AnimationPlayer` ou `AnimationTree` est de la présentation. | Les tests tournent dans la CI sans Mixamo. |
| 9 | Le bot et le fantôme | Ils prennent le même personnage, teinté (orange pour le bot ; orange transparent pour le fantôme), si les fichiers sont là ; sinon leur capsule. Le fantôme rejoue aussi l'état enregistré pour son animation. | Lisibles comme aujourd'hui, avec le vrai corps. |
| 10 | Crédits et README | `assets/CREDITS.md` décrit les fichiers Mixamo (source, auteur Adobe Mixamo, conditions de la FAQ, et qu'ils ne sont pas dans le dépôt) ; le README liste exactement les fichiers à télécharger sur mixamo.com, leurs réglages, et la commande `just mixamo`. La règle d'`AGENTS.md` sur `assets/` reste vraie : chaque fichier présent a sa ligne. | Qui reprend le dépôt sait quoi télécharger. |
| 11 | La visière et l'inclinaison | La visière disparaît avec le personnage ; l'inclinaison de wall-run reste sur `Visual` (réglable à 0 si l'animation `Wall Run` suffit). | La visière ne servait qu'à lire la capsule. |

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
