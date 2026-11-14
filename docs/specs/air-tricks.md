# Figures aériennes : saltos, tours, vrilles et sons

**Statut : 🟡 Prêt pour le dev**

Session du 2026-11-14, avec Jimmy. Seconde des deux specs de l'étape 2 de la feuille de
route (« Figures et flow »). Elle se construit **sur** `docs/specs/flow-combo.md` : son
développement commence quand le flow et le combo sont fusionnés sur `main`.

Amendée le 2026-11-14 après l'inspection, par la session principale sur délégation de
Jimmy. L'inspecteur a mesuré avec le vrai moteur un joueur sans risque : un saut à plat
dure 36 pas, un tour 27 et la fenêtre PERFECT 9, si bien qu'une figure lancée au saut
était toujours PERFECT, jamais un crash (150 000 points de style par minute), et le
gain de vitesse du PERFECT se cumulait jusqu'au plafond absolu (22 m/s en 13 s). Les
décisions 3 et 10 sont amendées, des scénarios ajoutés (marqués « amendement »).

## Contexte

Ce que Jimmy veut, avec ses mots : « des saltos, des trucs comme ça […] des trucs
vraiment clean et beaux qui donnent envie » ; « j'aimerais pouvoir faire plus de
figures […] faire des combos, les vrilles […] il faut trouver une méthode qui soit
possible à intégrer » ; « faudra qu'on réfléchisse à comment rendre ça skillé […] du
training à faire pour être bon » ; « au clavier souris […] faut trouver un moyen que ça
soit propre aussi à réaliser ».

La méthode retenue : une figure n'est pas tirée d'une liste, elle se **compose** de trois
briques que le joueur combine : le salto (choisi par la direction), le nombre de tours
(le temps où il garde le bouton) et les vrilles (des appuis sur saut pendant le salto).
Le corps entier tourne : aucune animation par figure n'est nécessaire, aujourd'hui avec
la capsule comme demain avec un personnage Mixamo (étape 6), qui n'apportera que des
positions (groupé, tendu).

Ce qui existe sur `main` quand le développement commence :

- `game/core/runner_motor.gd` : les états du coureur, la réception dure, la roulade, la
  mémoire de saut (`jump_buffer_time`), la tolérance de wall-jump.
- L'état du flow de `docs/specs/flow-combo.md` : les moves comptés à partir de messages
  datés du moteur, la règle de variété, la chaîne du combo, les erreurs, le HUD du flow.
- `game/player/player.gd` : le corps visible regarde la poussée et reste droit hors du
  wall-run (`docs/specs/runner-facing.md`).
- `game/player/input_intent_source.gd` et `game/core/move_intent.gd` : l'intention.

Ce que la spec ne doit pas casser : tous les scénarios antérieurs ; les règles
d'`AGENTS.md` (chaque action au clavier-souris et à la manette, touches physiques,
aucun asset sans licence vérifiée) ; la limite de 30 s de `just preflight`.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Le bouton | Une nouvelle action, « figure » : **Shift gauche** (touche physique) au clavier, **X** (bouton de face gauche) à la manette. Elle ne sert qu'en l'air. L'intention gagne « figure pressée à ce pas » et « figure maintenue ». | Q1. La souris reste libre pour la visée de l'étape 3. |
| 2 | Le salto | La direction poussée **au pas de l'appui** choisit le salto, mesurée par rapport à la vitesse horizontale du coureur : dans le quart avant, **front flip** ; dans le quart arrière, **backflip** ; dans un quart de côté, **side flip** de ce côté ; sans poussée, **spin** (rotation à plat). Un coureur presque immobile à l'horizontale prend sa poussée pour « l'avant ». | Q2. Le visuel ne décide rien (décision 22 de `docs/specs/movement-walls.md`) : la vitesse, oui. |
| 3 | Le nombre de tours | Un tour dure `trick_turn_duration` (0,45 s). **Amendement** : 0,65 s, plus long qu'un saut à plat (environ 0,6 s) : un salto ne tient pas dans un saut à plat, il demande de la hauteur (une descente d'environ 1 m ou plus, un wall-jump, une grande chute). Le joueur doit juger sa hauteur : c'est le risque de la figure. Tant que le bouton est gardé quand un tour s'achève, le tour suivant commence ; lâché, le corps finit le tour en cours. La figure compte ses tours achevés. | Q10. Le skill : lâcher au bon moment. |
| 4 | Les vrilles | Pendant un front flip ou un backflip, chaque appui sur **saut** ajoute une vrille, au plus `trick_max_twists_per_turn` (2) par tour de la figure. Elle tourne du côté poussé à l'appui, à droite sans poussée ; le côté ne change pas les points. Pas de vrille sur un side flip ni un spin. Une vrille ne rallonge pas la figure. | Q11 corrigée : au clavier, le pouce tape Espace pendant que l'auriculaire garde Shift. |
| 5 | Pas de saut fantôme | Pendant une figure, un appui sur saut n'est jamais gardé en mémoire de saut et ne lance jamais de wall-jump : il ne fait qu'une vrille, ou rien. | Q16. Sinon une vrille tapée près du sol relancerait un saut à l'atterrissage. |
| 6 | Où on peut lancer une figure | En l'air : en montée ou en chute, après un saut, un wall-jump ou une chute d'un rebord. Pas pendant un wall-run, un mantle, une glissade, une roulade ou une réception dure. Une figure ne change pas la trajectoire et le contrôle en l'air reste. Pendant une figure, aucun wall-run ni mantle ne commence. | Q6. Le seul risque est la réception. |
| 7 | Enchaîner en l'air | Une figure finie, un nouvel appui en lance une autre dans le même saut. La n-ième figure du même saut vaut `1 + trick_air_chain_bonus × (n − 1)` fois ses points (bonus de 50 %). | Q4. |
| 8 | Le crash | Toucher le sol avant la fin de la figure en cours est un **crash** : une réception dure, quelle que soit la hauteur de chute, et une erreur du flow (combo cassé, un palier perdu, comme la réception dure de `docs/specs/flow-combo.md`). Les figures du saut ne rapportent rien. | Q3. Le dilemme du plan en petit. |
| 9 | Quand les figures rapportent | Les figures d'un saut rapportent **à la réception** : au premier contact avec le sol sans crash, ou au début d'un wall-run ou d'un mantle. Chacune est alors un move du flow, daté de ce pas. Une chute hors du parcours ou un retour au checkpoint pendant le saut les perd. | Le PERFECT dépend de la réception. |
| 10 | La réception parfaite | Si la dernière figure du saut s'est finie au plus `trick_perfect_window` (0,15 s) avant le contact avec le sol, c'est **PERFECT** : cette figure vaut `trick_perfect_bonus` (+50 %) de plus, et la vitesse horizontale gagne `trick_perfect_speed_gain` (1 m/s) dans son sens, sans dépasser le plafond absolu. **Amendement** : ni la vitesse de pointe du moment (bonus du flow compris) plus le gain, comme la glissade parfaite (`docs/specs/flow-combo.md`, décision 9) ; un coureur déjà plus rapide garde sa vitesse, sans gain. Le PERFECT ne vaut que pour une réception au sol. Une grande chute demande toujours la roulade ; PERFECT et roulade se cumulent. | Q5. Partir tard pour finir juste à temps. |
| 11 | Les points | Une figure vaut `trick_points_per_turn` (200) par tour, plus `trick_points_per_twist` (100) par vrille ; puis les bonus PERFECT et d'enchaînement en l'air ; puis, comme tout move, la règle de variété et le multiplicateur de combo de `docs/specs/flow-combo.md`. | Q7 et Q13. Exemple : un double backflip vrillé posé en PERFECT, premier du saut, vaut (2 × 200 + 100) × 1,5 = 750 avant le multiplicateur. |
| 12 | La variété | Pour la règle « le même move d'affilée », deux figures sont le même move si leur salto, leur nombre de tours et leur nombre de vrilles sont les mêmes ; une brique qui change en fait un autre move. | Q14. |
| 13 | Les noms | Ils se construisent, en anglais. Saltos : « FRONT FLIP », « BACKFLIP », « SIDE FLIP » ; préfixe de tours « DOUBLE », « TRIPLE », puis « 4X », « 5X »… ; suffixe de vrilles « FULL », « DOUBLE FULL », « TRIPLE FULL », puis « 4X FULL »… Le spin se nomme par ses degrés : « 360 », « 720 », « 1080 »… Exemples : « DOUBLE BACKFLIP FULL », « TRIPLE SIDE FLIP », « 720 ». | Q12. |
| 14 | À l'écran | Le corps visible tourne vraiment : le front flip et le backflip autour de l'axe horizontal perpendiculaire à la vitesse, le side flip autour de l'axe de la vitesse, le spin autour de la verticale, la vrille autour de l'axe du corps. C'est l'exception à « hors du wall-run, le coureur reste droit » (`docs/specs/runner-facing.md`) ; pendant une figure, le corps ne se tourne pas vers la poussée. Il est droit à la fin de chaque figure ; après un crash, il se redresse d'un coup. La rotation se lit dans l'état de la figure de `core`, en lecture seule. | Q8. |
| 15 | Le HUD | Pendant le saut, le nom de la figure en cours s'affiche et se met à jour (tours, vrilles). À la réception : « <NOM> +<points> » pour chaque figure, « PERFECT » et « CRASH ». | Q8. Apprendre ce qu'on fait, c'est déjà du training. |
| 16 | Les sons | Cinq sons des packs Kenney « Interface Sounds » et « Impact Sounds » (licence CC0, vérifiée le 2026-11-14 dans le `License.txt` de chaque pack, téléchargés avec l'accord de Jimmy) : figure posée `confirmation_001.ogg`, PERFECT `confirmation_002.ogg`, crash `impactPunch_heavy_000.ogg`, palier de flow franchi `maximize_006.ogg`, combo cassé `error_004.ogg`. Ils vivent dans `assets/sounds/`, chacun avec sa ligne dans `assets/CREDITS.md`. Ils sont joués par la présentation (`game/ui/`), à partir des messages de `core`. | Q9 et règle d'`AGENTS.md`. Choisis d'après leur nom : Jimmy les juge en jouant. |
| 17 | Les deux claviers | Chaque geste a un test joué avec les entrées du clavier et un avec celles de la manette. Changer les touches dans un menu : étape 6. | Q17 et règle d'`AGENTS.md`. |
| 18 | Les réglages | Toutes les valeurs de cette spec vivent dans la ressource de réglage unique, dans un groupe « Tricks » ; F4 les recharge. | Règle d'`AGENTS.md`. |
| 19 | Le pilote de test | Il ne fait pas de figure : les tests du parcours ne changent pas. | Les figures ne sont pas nécessaires pour franchir le parcours. |

### Valeurs de départ ajoutées à la ressource de réglage

| Réglage | Valeur |
| ------- | ------ |
| Durée d'un tour (amendement) | 0,65 s |
| Vrilles au plus par tour | 2 |
| Points par tour, par vrille | 200, 100 |
| Bonus d'enchaînement en l'air, par figure déjà faite dans le saut | 50 % |
| Réception parfaite : fenêtre, bonus de points, gain de vitesse | 0,15 s, 50 %, 1 m/s |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Figures aériennes

  # --- Lancer une figure (core) ---

  Scénario: La direction poussée choisit le salto
    Soit un coureur en l'air qui avance
    Quand il appuie sur figure en poussant vers l'avant, vers l'arrière, sur le côté, ou sans pousser
    Alors il commence un front flip, un backflip, un side flip de ce côté, ou un spin

  Scénario: Une figure ne se lance pas au sol
    Soit un coureur au sol
    Quand il appuie sur figure
    Alors rien ne commence

  Scénario: Une figure ne se lance pas en wall-run ni en mantle
    Soit un coureur en wall-run, puis un coureur en mantle
    Quand il appuie sur figure
    Alors rien ne commence

  Scénario: Une figure ne change pas la trajectoire
    Soit deux coureurs en l'air identiques, avec la même poussée
    Quand l'un lance une figure et l'autre non
    Alors leurs positions restent les mêmes jusqu'à la réception

  # --- Les tours (core) ---

  Scénario: Lâcher le bouton finit le tour en cours
    Soit un coureur qui vient de lancer un backflip
    Quand il lâche le bouton au milieu du premier tour
    Alors le backflip se finit à la fin du premier tour, avec un tour

  Scénario: Garder le bouton enchaîne les tours
    Soit un coureur qui vient de lancer un backflip
    Quand il garde le bouton jusqu'au milieu du deuxième tour puis le lâche
    Alors la figure se finit à la fin du deuxième tour, avec deux tours

  # --- Les vrilles (core) ---

  Scénario: Un appui sur saut pendant un salto ajoute une vrille
    Soit un coureur en backflip
    Quand il appuie sur saut
    Alors la figure gagne une vrille et ne dure pas plus longtemps

  Scénario: Les vrilles ne dépassent pas leur maximum par tour
    Soit un coureur en backflip d'un tour
    Quand il appuie trois fois sur saut pendant ce tour
    Alors la figure a deux vrilles

  Scénario: Pas de vrille sur un side flip ni un spin
    Soit un coureur en side flip, puis un coureur en spin
    Quand il appuie sur saut
    Alors la figure n'a pas de vrille

  Scénario: Une vrille près du sol ne relance pas de saut
    Soit un coureur en figure, juste avant de toucher le sol
    Quand il appuie sur saut puis atterrit, la figure finie
    Alors il ne saute pas à l'atterrissage

  Scénario: Pendant une figure, le saut ne lance pas de wall-jump
    Soit un coureur en figure, juste après avoir quitté un wall-run
    Quand il appuie sur saut
    Alors il ne fait pas de wall-jump

  # --- Enchaîner en l'air (core) ---

  Scénario: Une seconde figure dans le même saut vaut plus
    # amendement : deux figures différentes, pour que la variété ne se mêle pas au bonus
    Soit un coureur qui a fini une figure en l'air
    Quand il lance et finit une seconde figure différente avant la réception
    Alors la seconde vaut le bonus d'enchaînement en plus, dans les points comptés par le flow

  Scénario: Pas de wall-run ni de mantle pendant une figure
    Soit un coureur en figure le long d'un mur, puis face à un rebord
    Quand les conditions d'un wall-run ou d'un mantle sont réunies
    Alors il n'entre ni en wall-run ni en mantle avant la fin de la figure

  # --- Réception, crash et points (core) ---

  Scénario: Une figure finie rapporte à la réception
    Soit un coureur qui a fini un backflip en l'air, en combo
    Quand il atterrit
    Alors le flow compte un move « BACKFLIP » de ses points, à ce pas

  Scénario: Une figure non finie au sol est un crash
    Soit un coureur en figure, son tour pas fini
    Quand il touche le sol
    Alors il fait une réception dure, le combo est cassé, la jauge perd un palier et la figure ne rapporte rien

  Scénario: Une figure finie juste avant le sol est parfaite
    Soit un coureur dont la figure se finit dans la fenêtre avant le sol
    Quand il atterrit
    Alors c'est un PERFECT : la figure vaut le bonus en plus et sa vitesse gagne le gain, sans dépasser le plafond absolu

  Scénario: Une figure finie trop tôt n'est pas parfaite
    Soit un coureur dont la figure se finit plus tôt que la fenêtre avant le sol
    Quand il atterrit
    Alors la figure rapporte ses points sans bonus ni gain

  Scénario: Une figure rapporte au début d'un wall-run
    Soit un coureur qui a fini une figure en l'air le long d'un mur
    Quand il entre en wall-run
    Alors la figure rapporte ses points, sans PERFECT

  Scénario: Les points d'une figure composée
    Soit un coureur en combo à ×1, premier move de son combo
    Quand il pose un double backflip vrillé en PERFECT
    Alors le flow compte 750 points

  Scénario: Une figure qui change d'une brique n'est pas une répétition
    Soit un coureur qui vient de poser un backflip
    Quand il pose un backflip vrillé
    Alors cette figure vaut tous ses points

  Scénario: Une chute hors du parcours perd les figures du saut
    Soit un coureur qui a fini une figure en l'air
    Quand il tombe hors du parcours
    Alors la figure ne rapporte rien

  Scénario: La grande chute demande toujours une roulade
    Soit un coureur qui pose une figure en PERFECT après une chute plus haute que la hauteur de roulade
    Quand il ne presse pas la glissade
    Alors il fait une réception dure, même si la figure rapporte

  # --- Les noms (core) ---

  Scénario: Le nom d'une figure se compose de ses briques
    Soit des figures de saltos, de tours et de vrilles différents
    Quand on lit leurs noms
    Alors ce sont « BACKFLIP », « DOUBLE BACKFLIP FULL », « TRIPLE SIDE FLIP », « FRONT FLIP DOUBLE FULL », « 4X BACKFLIP » et « 720 »

  # --- Le risque (amendement) ---

  Scénario: Un salto ne tient pas dans un saut à plat
    # amendement
    Soit un coureur qui court sur le plat
    Quand il saute en gardant le saut et lance une figure au pas même du saut
    Alors il touche le sol avant la fin du tour et se crashe

  Scénario: Une descente suffisante permet un salto
    # amendement
    Soit un coureur qui saute d'un bloc vers un sol plus bas d'au moins la descente qu'un tour demande
    Quand il lance une figure d'un tour au bon moment
    Alors il la pose

  Scénario: Une boucle sans risque sur le plat ne rapporte rien
    # amendement
    Soit un coureur qui, sur le plat, lance une figure à chaque saut pendant une minute
    Quand on compte ce qu'il a gagné
    Alors aucune figure n'a rapporté de points, et il a moins de style qu'en sautant sans figure

  Scénario: Les réceptions parfaites enchaînées ne font pas monter la vitesse sans fin
    # amendement
    Soit un coureur qui enchaîne des figures posées en PERFECT
    Quand il en pose dix
    Alors sa vitesse ne dépasse jamais la vitesse de pointe du moment plus le gain

  Scénario: Un crash ne paie pas les figures déjà finies du saut
    # amendement
    Soit un coureur qui a fini une figure puis en a lancé une seconde
    Quand il touche le sol avant la fin de la seconde
    Alors aucune des deux ne rapporte

  Scénario: Seule la dernière figure du saut est parfaite
    # amendement
    Soit un coureur qui a fini deux figures, la seconde dans la fenêtre avant le sol
    Quand il atterrit
    Alors seule la seconde est PERFECT

  Scénario: Une figure rapporte au début d'un mantle
    # amendement
    Soit un coureur qui a fini une figure en l'air face à un rebord à sa portée
    Quand il se hisse
    Alors la figure rapporte ses points, sans PERFECT

  # --- Dans la vraie physique et avec les vraies entrées ---

  Scénario: Un backflip au clavier dans la vraie physique
    Soit un coureur sur le parcours, mené par les entrées du clavier
    Quand il saute, appuie sur Shift en tenant la touche arrière, tape Espace, lâche Shift
    Alors il pose un backflip vrillé

  Scénario: Un backflip à la manette dans la vraie physique
    Soit un coureur sur le parcours, mené par les entrées de la manette
    Quand il saute, appuie sur X en tirant le stick vers l'arrière, tape LB, lâche X
    Alors il pose un backflip vrillé

  Scénario: Le corps visible fait le tour de la figure
    Soit un coureur qui lance un backflip d'un tour
    Quand le tour s'achève
    Alors le corps visible a fait un tour complet autour de l'axe du salto et est droit

  # --- Affichages et sons ---

  Scénario: Le HUD montre la figure en cours
    Soit un coureur en backflip qui vient d'ajouter une vrille
    Quand le HUD se met à jour
    Alors il affiche « BACKFLIP FULL »

  Scénario: Le HUD montre la réception
    Soit un coureur qui pose un backflip en PERFECT
    Quand le HUD se met à jour
    Alors il affiche le nom de la figure avec ses points, et « PERFECT »

  Scénario: Le HUD signale un crash
    Soit un coureur qui touche le sol en pleine figure
    Quand le HUD se met à jour
    Alors il affiche « CRASH »

  Scénario: Chaque événement joue son son
    Soit la présentation des sons
    Quand une figure est posée, posée en PERFECT, crashée, un palier est franchi ou un combo est cassé
    Alors le son de cet événement est joué
```

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** :

  | Composant | Couche | Statut |
  | --------- | ------ | ------ |
  | HUD du flow (`docs/specs/flow-combo.md`) | `game/ui/` | modifié : figure en cours, PERFECT, CRASH |
  | Sons du flow et des figures | `game/ui/` | créé : rien ne joue de son aujourd'hui |

- **États** : en l'air, le nom de la figure en cours au-dessus de la jauge ; à la
  réception, le texte de la figure et ses points comme pour tout move, puis
  « PERFECT » ; au crash, « CRASH » puis « COMBO BROKEN ».
- **Focus** : aucun élément ne prend le focus.
- **Libellés** (en anglais) : les noms de la décision 13, « PERFECT », « CRASH ».

## Choix acceptés à l'inspection

Le code a tranché ces points là où la spec se taisait ; ils sont acceptés le 2026-11-14
et Jimmy peut rouvrir chacun après avoir joué.

- **Les bonus se multiplient** : points de base × bonus d'enchaînement × PERFECT, puis
  la variété et le multiplicateur de combo du flow.
- **La roulade ne sauve pas un crash** : une figure pas finie au sol est un crash, même
  avec la glissade pressée dans la fenêtre de roulade.
- **L'ordre des messages d'un pas** : les figures paient d'abord, puis la roulade, la
  réception dure, le wall-run ou le mantle ; le crash est un message seul.
- **La diagonale exacte du clavier** (45°) donne un front flip ou un backflip, pas un
  side flip.
- **Une figure peut partir au pas même du saut ou du wall-jump.**
- **Le maximum de vrilles** compte le tour en cours : 2 au premier tour, 2 de plus au
  deuxième.
- **Un appui sur saut pendant un side flip ou un spin** ne fait rien.
- **Les noms des figures** sont construits dans `core` : ce sont aussi l'identité d'une
  figure pour la répétition ; le HUD les affiche tels quels.
- **« Presque immobile »** (0,1 m/s) et la frontière des quarts sont des constantes de
  `core`, pas des réglages de sensation.
- **Les sons** : un PERFECT joue seulement son son ; un crash en combo joue le crash et
  le combo cassé.
- **Shift gauche** : sous Windows, cinq appuis rapides ouvrent la fenêtre des touches
  rémanentes si le joueur ne l'a pas désactivée. Gardé ; à juger par Jimmy, une autre
  touche se change en deux lignes.
- **Les endroits pour les figures** : avec un tour de 0,65 s, le parcours n'offre que
  peu de descentes (la grande chute, les bords de blocs plus hauts que la suite). Des
  endroits faits pour les figures viendront avec le dessin des niveaux.

## Hors périmètre

- **Les grabs, les figures sur les murs et au sol** : de nouvelles briques, après que
  Jimmy a joué les saltos (Q15). La composition les accueille sans rien refaire.
- **Les positions du corps** (groupé, tendu) et le personnage Mixamo : étape 6.
- **Changer les touches dans un menu** : étape 6.
- **Une musique** : non demandée.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Composer des figures avec des briques plutôt qu'une liste | — | discovered |
| Risque contre récompense dans un timing (crash, PERFECT) | discovered | discovered |
