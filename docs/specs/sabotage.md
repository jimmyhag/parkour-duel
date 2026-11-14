# Tir et sabotage : viser, tirer, faire tomber le décor

**Statut : 🟢 Implémenté**

Session du 2026-11-14. Étape 3 de la feuille de route. Jimmy a délégué toute la
conception (« enchaîne sur tout le reste […] fais tout jusqu'à ce que tu puisses plus
faire ») : chaque décision ci-dessous est la recommandation de l'assistant, prise à sa
place, et Jimmy peut rouvrir chacune après avoir joué. Son développement commence quand
l'étape 2 (`docs/specs/flow-combo.md` et `docs/specs/air-tricks.md`) est fusionnée.
La feuille de route ne commence une étape que quand la précédente est validée par
Jimmy (`AGENTS.md`, « Out of scope ») : Jimmy a levé cette attente pour les étapes 2 à 4
(« enchaîne sur tout le reste, puis une fois que t'as fini ça, enchaîne sur tout le
reste […] jusqu'à ce que tu puisses plus faire ») ; les étapes 2, 3 et 4 se jugent
ensemble au point d'arrêt n° 3.

Amendée le 2026-11-14 après le premier développement : viser puis tirer au même pas
coûtait 0,002 s, si bien que « chaque tir coûte de l'avance » n'était vrai que pour une
visée tenue ; et la barrière de 4 m, infranchissable, faisait attendre la victime 4 s
pour une seule munition. Les décisions 4 et 6 sont amendées, deux scénarios ajoutés
et un remplacé (marqués « amendement »), et les choix du code sont listés.

Amendée une seconde fois le même jour après l'inspection, qui a mesuré avec le vrai
moteur : viser en glissant ne coûtait rien (0,14 m perdus au lieu de 0,97 m), viser
pendant un saut non plus (0,03 m) ; le pont saboté se franchissait d'un saut suivi d'un
mantle (0,33 s perdues pour 2 munitions) ; un coureur au bord du vide empêchait son
pont de revenir ; sur la plateforme, une touche était inévitable avec 0,6 s d'alerte.
Les décisions 2, 4, 8 et 9 et la valeur de l'alerte sont amendées (marquées « second
amendement »).

## Contexte

Le plan (étape 3) : « Visée par-dessus l'épaule avec ralenti ; cibles surlignées ; 4 à
6 types d'objets sabotables (plateforme qui tombe, corde coupée, obstacle qui chute,
piège déclenché…) ; réapparition ou état de secours pour qu'un parcours reste
**toujours finissable** ; coût en munitions par type. » Et ses règles : l'arme ne blesse
jamais, elle ne touche que le décor ; seuls des objets prédéfinis et surlignés se
sabotent ; tout sabotage est un **message daté** (qui, quelle cible, quand) ; être
touché casse le combo et fait perdre du temps, sans éliminer ; viser ralentit, donc
chaque tir coûte de l'avance.

Ce qui existe quand le développement commence : les munitions gagnées par le flow (3 au
plus, `docs/specs/flow-combo.md`), les erreurs qui cassent le combo, les figures
aériennes et les sons (`docs/specs/air-tricks.md`), la caméra libre à ressort
(`game/player/camera_rig.gd`), le parcours de dix sections (`game/levels/test_course.tscn`),
`game/world/` (checkpoints et lignes).

Ce que la spec ne doit pas casser : tous les scénarios antérieurs ; les règles
d'`AGENTS.md` (`core` sans scène ni entrée, chaque action aux deux claviers, aucun asset
sans licence) ; la garantie à plus et moins 10 % du parcours ; la limite de 30 s de
`just preflight`.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Sur quel parcours tire-t-on à l'étape 3 ? | Sur **son propre parcours**, en entraînement : le joueur tire sur les cibles devant lui et vit leur effet. Les deux couloirs miroirs, et tirer sur celui de l'adversaire, sont l'étape 4. Le code ne suppose pas pour autant que tireur et victime sont le même coureur : le message dit qui tire. | La feuille de route met les couloirs miroirs à l'étape 4 ; l'étape 3 se juge seule : viser, tirer, l'effet, la récupération. |
| 2 | Le ralenti de la visée | **Le coureur qui vise ralentit, pas le temps du monde.** En visée, sa vitesse de pointe au sol est multipliée par `aim_speed_ratio` (0,6) ; en l'air, rien ne change. **Second amendement** : « au sol » comprend la glissade et la roulade ; en visée, leur vitesse redescend aussi vers la vitesse de pointe en visée, au rythme du freinage au sol. `Engine.time_scale` n'est jamais touché par le jeu. | En duel en ligne (étape 5), on ne peut pas ralentir le temps de l'adversaire. Le plan le dit : « viser ralentit, donc chaque tir coûte de l'avance ». À rouvrir par Jimmy s'il voulait un vrai ralenti du temps en solo. |
| 3 | Viser | Garder **clic droit** ou **gâchette gauche (LT)**. La caméra passe par-dessus l'épaule droite et resserre son champ ; un réticule apparaît au centre. Pendant la visée, aucune figure ne se lance ; une figure en cours se finit normalement. | Décision 3 du plan. La souris est libre depuis l'étape 2 pour cela. |
| 4 | Tirer | **Clic gauche** ou **gâchette droite (RT)**, seulement en visée. Le tir part du centre de l'écran : il touche la première chose sur sa ligne. Il ne part que si le réticule est sur une **cible prête, à portée** (`shot_range`, 45 m) et si le coureur a assez de munitions pour son type : sinon rien ne se passe et rien n'est dépensé. **Amendement** : le tir ne part qu'après `aim_min_time` (0,25 s) de visée tenue sans interruption ; avant, appuyer sur tir ne fait rien. Au sol, chaque tir coûte donc au moins un quart de seconde de course ralentie ; en l'air, rien (décision 2). **Second amendement** : la visée minimale ne se compte qu'au sol (debout, en glissade ou en roulade) ; en l'air, le compte s'arrête sans repartir de zéro. On peut tirer en l'air, à condition d'avoir payé sa visée au sol avant. | Cibles surlignées (décision 4 du plan) : on ne gaspille pas une munition dans le vide. Le skill est de viser vite en courant ralenti. |
| 5 | Surligner | Toute cible prête est surlignée d'une couleur unique en permanence. En visée, la cible sous le réticule et tirable change d'aspect (plus vive) et le réticule le montre ; une cible trop chère pour les munitions du moment le montre aussi (réticule barré). Une cible pas prête n'est plus surlignée. | Lisible, et portable en tactile plus tard. Pas seulement la couleur : le réticule change de forme. |
| 6 | Les types de cibles | Quatre types, chacun dans `game/world/` : **plateforme qui tombe** (une plateforme de passage disparaît), **pont qui lâche** (« corde coupée » : une passerelle tombe dans le vide), **obstacle qui chute** (un bloc tombe sur le chemin : il se franchit en mantle ou se contourne), **barrière qui se lève** (« piège » : un mur sort du sol en travers du chemin). **Amendement** : la barrière se franchit par un saut suivi d'un mantle (sa hauteur au-dessus du sol du chemin est dans la plage d'un mantle depuis le haut d'un saut) : elle coûte du temps et casse l'élan, elle ne bloque pas. | Les 4 à 6 du plan, sans modèle 3D : des blocs. |
| 7 | Le coût | Plateforme 1 munition, pont 2, obstacle 1, barrière 1. Valeurs dans la ressource de réglage. | Le pont coupe un passage entier : il coûte plus. |
| 8 | Le déroulé d'un sabotage | Chaque cible est un petit automate de `core` : **prête** → touchée → **alerte** (`sabotage_warning`, 0,6 s : la cible clignote, le son d'alerte joue) → **sabotée** (son effet, pendant la durée de son type) → **récupération** (elle revient à sa place) → **repos** (`sabotage_cooldown`, 3 s, pas tirable) → prête. Une cible pas prête ne peut pas être touchée. | L'alerte laisse une chance de réagir : du skill pour la victime aussi. |
| 9 | Toujours finissable | Chaque effet a une durée : plateforme 5 s, pont 6 s, obstacle 6 s, barrière 4 s ; puis la cible revient. Aucun effet ne rend un passage infranchissable pour toujours ; l'obstacle qui chute est franchissable en mantle ou en glissade selon sa forme. Si un objet qui revient à sa place occupe l'endroit où est le coureur, il revient sans le pousser : il attend que la place soit libre. | « Réapparition ou état de secours » du plan. |
| 10 | Être touché | Le coureur est **touché** si l'effet commence pendant qu'il est dans la zone de la cible (sur la plateforme, sur le pont, sous l'obstacle, sur la ligne de la barrière). Touché = une erreur du flow : combo cassé, la jauge perd un palier, « SABOTAGED » s'affiche. Il ne perd pas de vie (il n'en a pas) ; s'il tombe, la chute suit les règles habituelles. | Le plan : être touché casse le combo et fait perdre du temps, sans éliminer. |
| 11 | Le message daté | Un tir réussi produit un message de `core` : qui tire, quelle cible (un identifiant stable de la cible dans son parcours), à quel pas fixe. Seuls ces messages font changer l'état d'une cible ; la scène de la cible ne fait qu'exécuter ce que dit son automate. | Règle d'`AGENTS.md` et du plan ; l'étape 5 enverra ces messages par le réseau. |
| 12 | Les munitions | Un tir dépense le coût de son type sur la réserve du flow ; le HUD des munitions le montre. | `docs/specs/flow-combo.md`, décision 8. |
| 13 | Où sont les cibles | Au moins une cible de chaque type sur le parcours, sur un passage obligé, visible depuis la section d'avant, et pas sur un passage que seul un saut parfait franchit. Les dix sections et leurs tests restent ; une cible peut remplacer un bloc existant (une plateforme des sauts longs par exemple) s'il garde sa forme. | Le parcours doit rester faisable par le pilote, cible prête. |
| 14 | Le pilote de test | Il ne vise ni ne tire. Un test lui fait franchir le parcours toutes cibles prêtes ; un autre sabote chaque cible pendant qu'il est loin, attend la récupération, et le laisse franchir. | « Toujours finissable », prouvé. |
| 15 | Les sons | Alerte, tir, effet et récupération réutilisent les packs Kenney CC0 déjà présents (`assets/sounds/`), avec une ligne de plus dans `assets/CREDITS.md` par fichier ajouté. Aucun nouveau téléchargement. | Jimmy a autorisé ces packs ; le développeur choisit les fichiers dans les archives déjà vérifiées si elles sont fournies, sinon il réutilise les cinq sons présents. |
| 16 | Les réglages | Toutes les valeurs de cette spec vivent dans la ressource de réglage unique, dans un groupe « Sabotage » ; F4 les recharge. Les durées et coûts par type aussi. | Règle d'`AGENTS.md`. |
| 17 | L'affichage de debug | F3 montre aussi l'état de visée, la cible sous le réticule et son état, et le temps restant de chaque cible qui n'est pas prête. | Pour régler en jouant. |

### Valeurs de départ ajoutées à la ressource de réglage

| Réglage | Valeur |
| ------- | ------ |
| Vitesse de pointe en visée, part de la normale | 0,6 |
| Portée du tir | 45 m |
| Visée minimale avant un tir (amendement) | 0,25 s |
| Champ de la caméra en visée, décalage par-dessus l'épaule | 50°, 0,6 m à droite |
| Alerte avant l'effet (second amendement) | 1 s |
| Repos après récupération | 3 s |
| Coût : plateforme, pont, obstacle, barrière | 1, 2, 1, 1 |
| Durée de l'effet : plateforme, pont, obstacle, barrière | 5 s, 6 s, 6 s, 4 s |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Tir et sabotage

  # --- Viser (core et player) ---

  Scénario: Viser ralentit le coureur au sol
    Soit un coureur qui court à sa vitesse de pointe
    Quand il vise
    Alors sa vitesse descend vers la vitesse de pointe en visée

  Scénario: Viser ne change rien en l'air
    Soit un coureur en l'air
    Quand il vise
    Alors sa trajectoire est la même que sans viser

  Scénario: Viser ne ralentit pas le temps
    Soit le jeu en cours
    Quand le coureur vise
    Alors l'échelle de temps du moteur ne change pas

  Scénario: Pas de figure en visée
    Soit un coureur en l'air qui vise
    Quand il appuie sur figure
    Alors aucune figure ne commence

  # --- Tirer (core) ---

  Scénario: Un tir sur une cible prête à portée la touche
    Soit un coureur en visée avec assez de munitions, le réticule sur une cible prête à portée
    Quand il tire
    Alors un message daté dit qui tire, quelle cible et à quel pas, et le coût de la cible est dépensé

  Scénario: Pas de tir sans munitions suffisantes
    Soit un coureur en visée avec une munition, le réticule sur un pont
    Quand il tire
    Alors rien ne se passe et sa munition reste

  Scénario: Pas de tir dans le vide
    Soit un coureur en visée, le réticule sur un bloc qui n'est pas une cible
    Quand il tire
    Alors rien ne se passe et rien n'est dépensé

  Scénario: Pas de tir hors de portée
    Soit un coureur en visée, le réticule sur une cible prête au-delà de la portée
    Quand il tire
    Alors rien ne se passe et rien n'est dépensé

  Scénario: Pas de tir avant la visée minimale
    # amendement
    Soit un coureur qui vient de commencer à viser, le réticule sur une cible prête, à portée et payable
    Quand il tire avant la visée minimale, puis après
    Alors le premier appui ne fait rien et ne dépense rien, le second part

  Scénario: Viser en glissant coûte de l'avance
    # second amendement
    Soit deux coureurs qui glissent côte à côte à la même vitesse
    Quand l'un vise et tire le plus vite possible, l'autre ne vise pas
    Alors le tireur a perdu au moins le retard d'une visée minimale au sol

  Scénario: La visée minimale ne se compte pas en l'air
    # second amendement
    Soit un coureur qui saute et commence à viser en l'air
    Quand il tire avant d'avoir visé au sol pendant la visée minimale
    Alors rien ne se passe et rien n'est dépensé

  Scénario: Chaque tir coûte de l'avance au sol
    # amendement
    Soit deux coureurs qui courent côte à côte à leur vitesse de pointe
    Quand l'un vise et tire le plus vite possible, l'autre ne vise pas
    Alors le tireur a perdu au moins le retard d'une visée minimale

  Scénario: Pas de tir sans viser
    Soit un coureur qui ne vise pas
    Quand il appuie sur tir
    Alors rien ne se passe

  # --- L'automate d'une cible (core) ---

  Scénario: Une cible touchée passe par l'alerte puis l'effet
    Soit une cible prête
    Quand un message de sabotage la vise
    Alors elle est en alerte pendant la durée d'alerte, puis sabotée pendant la durée de son type

  Scénario: Une cible revient puis se repose
    Soit une cible sabotée
    Quand la durée de son effet est écoulée
    Alors elle revient à sa place, se repose pendant la durée de repos, puis est prête

  Scénario: Une cible pas prête ne peut pas être touchée
    Soit une cible en alerte, sabotée ou au repos
    Quand un message de sabotage la vise
    Alors son état ne change pas et aucune munition n'est dépensée

  Scénario: Une cible ne revient pas sur le coureur
    Soit une cible dont l'effet est fini, le coureur à sa place
    Quand elle devrait revenir
    Alors elle attend que la place soit libre

  # --- Être touché (core) ---

  Scénario: Être dans la zone au début de l'effet casse le combo
    Soit un coureur en combo sur une plateforme en alerte
    Quand l'effet commence
    Alors il est touché : le combo est cassé, la jauge perd un palier, et « SABOTAGED » s'affiche

  Scénario: Sortir de la zone pendant l'alerte évite d'être touché
    Soit un coureur en combo sur une plateforme en alerte
    Quand il la quitte avant la fin de l'alerte
    Alors il n'est pas touché et son combo continue

  # --- Les quatre types (vraie physique) ---

  Scénario: La plateforme sabotée ne porte plus
    Soit une plateforme sabotée
    Quand le coureur arrive dessus
    Alors il tombe à travers

  Scénario: Le pont saboté laisse un vide
    Soit un pont saboté
    Quand le coureur arrive au bord
    Alors il n'y a plus de passerelle

  Scénario: Le vide du pont saboté ne se franchit pas
    # second amendement
    Soit un pont saboté, le bonus de vitesse du palier 3
    Quand le pilote arrive au bord en courant
    Alors il ne franchit pas le vide, ni d'un saut ni d'un saut suivi d'un mantle

  Scénario: Un coureur qui attend au bord ne bloque pas le retour du pont
    # second amendement
    Soit un pont saboté et un coureur arrêté au bord du vide, sans toucher le volume du pont
    Quand l'effet du pont est fini
    Alors le pont revient

  Scénario: L'alerte laisse le temps de quitter une plateforme
    # second amendement
    Soit un coureur qui vient de poser le pied au début d'une plateforme en alerte, à sa vitesse de pointe
    Quand il court droit devant
    Alors il quitte la zone avant la fin de l'alerte et n'est pas touché

  Scénario: L'obstacle tombé se franchit
    Soit un obstacle tombé sur le chemin
    Quand le pilote arrive devant
    Alors il le franchit

  Scénario: La barrière levée se franchit en sautant et en se hissant
    # amendement : remplace « La barrière levée barre le passage »
    Soit une barrière levée sur le chemin
    Quand le pilote arrive devant
    Alors il la franchit, plus lentement qu'en passant sans barrière

  # --- Le parcours (vraie physique) ---

  Scénario: Le parcours se franchit toutes cibles prêtes
    Soit toutes les cibles prêtes
    Quand le pilote rejoue chaque section
    Alors il les franchit toutes

  Scénario: Le parcours reste finissable après chaque sabotage
    Soit chaque cible sabotée pendant que le coureur est loin
    Quand sa récupération est passée et que le pilote rejoue sa section
    Alors il la franchit

  Scénario: Chaque type de cible est sur le parcours
    Soit le parcours
    Quand on compte ses cibles
    Alors il y en a au moins une de chaque type

  # --- Entrées et affichages ---

  Scénario: Viser et tirer existent au clavier-souris et à la manette
    Soit la table des entrées
    Quand on lit les actions de visée et de tir
    Alors chacune a un bouton de souris et un bouton ou une gâchette de manette

  Scénario: Le réticule montre une cible tirable
    Soit un coureur en visée, le réticule sur une cible prête, à portée et payable
    Quand le HUD se met à jour
    Alors le réticule le montre et la cible est mise en valeur

  Scénario: Le réticule montre une cible trop chère
    Soit un coureur en visée avec une munition, le réticule sur un pont prêt
    Quand le HUD se met à jour
    Alors le réticule est barré

  Scénario: Une cible prête est surlignée et une cible au repos ne l'est pas
    Soit une cible prête et une cible au repos
    Quand on regarde leur aspect
    Alors seule la cible prête est surlignée

  Scénario: L'affichage de debug montre la visée et les cibles
    Soit l'affichage de debug visible
    Quand le coureur vise une cible
    Alors il montre la visée, la cible sous le réticule et son état
```

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** :

  | Composant | Couche | Statut |
  | --------- | ------ | ------ |
  | Réticule | `game/ui/` | créé : rien ne vise aujourd'hui |
  | HUD du flow (munitions, textes) | `game/ui/` | modifié : munitions dépensées, « SABOTAGED » |
  | Caméra par-dessus l'épaule | `game/player/` | modifié : décalage et champ en visée |
  | Cibles et leur surlignage | `game/world/` | créé |
  | Affichage de debug | `game/ui/` | modifié |

- **États du réticule** : caché hors visée ; neutre en visée ; « tirable » sur une cible
  prête, à portée et payable ; barré sur une cible trop chère ; neutre sur tout le
  reste.
- **Focus** : aucun élément ne prend le focus.
- **Libellés** (en anglais) : « SABOTAGED ».

## Choix acceptés après le développement

Le code a tranché ces points là où la spec se taisait ; ils sont acceptés le 2026-11-14
et Jimmy peut rouvrir chacun après avoir joué.

- **Le pont coupe la ligne droite du départ** : un vide enjambé par un pont de 4 m de
  large ; **second amendement** : le vide est assez large pour qu'aucun saut, même
  suivi d'un mantle au bord, ne le franchisse, bonus du palier 3 compris ; il fait 10 m (un saut
  suivi d'un mantle franchit au plus 9,18 m au palier 3) ; une glissade parfaite juste
  avant le saut le franchirait : c'est une échappatoire de skill, acceptée ; « visible depuis la section d'avant » se
  lit « visible depuis le départ ».
- **Les autres cibles** : la plateforme remplace `LongJump1` (même forme), la barrière
  est sur `LowPassageStart`, l'obstacle (1,8 m de haut, plus qu'un saut, dans la plage
  d'un mantle) tombe sur `BigDropLanding`, avancé à z = −144,5 pour que le saut depuis
  son sommet ne fasse pas manquer le checkpoint du rebord ; il coûte environ 0,3 s.
- **Chaque tir paie sa visée minimale**, même dans une visée gardée après un tir.
- **L'obstacle et la barrière ne se posent pas sur un coureur** : celui qui est dans la
  zone au début de l'effet est touché, et l'objet se pose dès que la place est libre.
- **Les zones de touche** : plateforme et pont, leur volume et l'espace au-dessus ;
  obstacle et barrière, le volume où ils arrivent.
- **Le ralenti freine fort** (`ground_deceleration`), pas au rythme du momentum.
- **La portée** se mesure depuis les yeux du coureur ; le rayon voit les blocs et les
  cibles, pas les coureurs.
- **`aim_camera_blend_time`** (0,12 s) est dans la ressource de réglage.
- **Recommencer** remet toutes les cibles en place ; le retour au checkpoint ne les
  touche pas. Après l'arrivée, on peut encore tirer, mais être touché ne compte plus.
- **« SABOTAGED »** prend la place du texte de réception, puis « COMBO BROKEN » s'il y
  avait un combo ; le palier est perdu même hors combo.
- **Le réticule** n'est barré que sur une cible prête et à portée trop chère.
- **La barrière** est un `StaticBody3D` déplacé d'un coup.
- **Viser en l'air** ne ralentit pas (décision 2), mais la visée minimale se paie au
  sol (second amendement).
- **Le retour d'une cible** regarde seulement le volume de son corps ; sa zone, plus
  large, ne sert qu'à savoir qui est touché (second amendement).
- **L'alerte de 1 s** laisse environ 0,2 s de marge pour quitter une plateforme en
  venant de s'y poser à la vitesse de pointe.
- **Les tests de soutien** : huit tests sans scénario du même nom prouvent les
  décisions 3, 10 et 15 ou des choix de cette liste (la touche en vraie physique, les
  vrais événements de souris et de gâchettes, la caméra par-dessus l'épaule,
  l'observation sous le réticule, les sons, l'obstacle et la barrière qui ne se posent
  pas sur un coureur, le pilote qui franchit un mur en sautant et en se hissant).
  Acceptés comme tests de soutien.

## Hors périmètre

- Les deux couloirs miroirs, tirer sur l'adversaire, le fantôme et le bot : étape 4.
- Le réseau : étape 5 ; les messages datés le préparent.
- Plus de quatre types de cibles, des cibles mobiles, des plateformes mobiles : plus
  tard. Rappel : un `AnimatableBody3D` compte comme un mur pour le wall-run
  (`docs/specs/movement-walls.md`, choix accepté) ; la barrière qui se lève est un
  `StaticBody3D` déplacé d'un coup, qui compte aussi comme un mur.
- Des modèles 3D pour les cibles : étape 6 (Kenney).

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Petits automates d'objets pilotés par des messages datés | — | discovered |
| Ce qui ne peut pas exister en ligne (ralentir le temps) et son équivalent local | — | discovered |
