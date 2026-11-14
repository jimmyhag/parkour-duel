# Leçons du tour — où regarde le coureur (`docs/specs/runner-facing.md`)

Tour du 2026-11-14, propriétaire : Jimmy. Cinquième tour complet du harnais, le plus
court : un retour de Jimmy au point d'arrêt n° 2, une spec, une passe du développeur,
une inspection, une correction, fusion (pull requests n° 14 et n° 15). Les deux rapports
des agents sont à la fin, mot pour mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

## Déroulé

| Étape | Qui | Résultat |
| ----- | --- | -------- |
| Retour de jeu | Jimmy, sur la version finale de l'étape 1 | « le reste me paraît correct » ; la tête tourne contre une face et pendant le mantle |
| Spec | session principale, décision déléguée | 8 décisions, 10 scénarios ; précisée en cours d'écriture par un second message de Jimmy (le mantle) ; pull request n° 14 |
| Développement | développeur, worktree isolé | 2 commits, 135 tests, `just check` vert ; 7 tests sur 10 rouges sur l'ancien code, les 3 autres prouvés par sabotage ; environ 15 min |
| Inspection | inspecteur, contexte neuf | « conforme », 4 constats conseillés ; environ 7 min |
| Correction | développeur | le test du mantle change la poussée pendant le mantle ; environ 3 min |
| Clôture | session principale | choix acceptés dans la spec, `just check` vert, CI verte, fusion, version jouable reconstruite |

## Leçons

1. **Le premier message de Jimmy ne nommait pas le cas.** « Dès qu'il détecte un
   objet, sa tête se tourne » a d'abord été lu comme « contre un mur » ; son second
   message visait le mantle. La cause commune (le corps suit la vitesse, que la face
   réduit) a permis d'absorber la précision sans recommencer la spec. Proposition : à
   un retour de jeu, chercher la cause avant d'écrire, et écrire un scénario avec les
   mots du cas de Jimmy (« le cas de Jimmy »).
2. **Un test vert sur l'ancien code ne prouve rien du nouveau.** Trois scénarios
   décrivaient un comportement que l'ancien code avait déjà ; le développeur les a
   prouvés par sabotage, sans qu'on le demande. L'inspection a trouvé un quatrième
   test vert pour une mauvaise raison : la poussée ne changeait pas pendant le mantle,
   donc « ne pas tourner » et « suivre la poussée » se confondaient. Proposition : une
   règle « ne change pas pendant X » se prouve en changeant l'entrée pendant X.
3. **La spec disait « aucun test ne change » ; un test a dû changer.** Il comptait sur
   l'ancien bug pour mettre le corps de profil. Le développeur l'a dit dans ses écarts,
   l'inspecteur l'a relevé, et l'écart est écrit dans la spec. Proposition : quand une
   spec change la présentation, chercher d'abord les tests qui lisent le corps visible
   (ici quatre fichiers) et le dire dans la spec.
4. **Une seule inspection a suffi.** La seconde inspection, devenue la norme au tour
   précédent, n'a pas été lancée : le changement tient en 30 lignes de présentation,
   et la seule correction ne touche qu'un test. Proposition : la seconde inspection
   reste la norme pour un changement du moteur ou du parcours, pas pour une retouche
   de présentation.

## Ce qui reste ouvert après ce tour

- **Point d'arrêt n° 2** : Jimmy juge la nouvelle version, puis l'étape 2 commence avec
  son accord.
- Toujours ouverts depuis les tours précédents : voir
  `docs/harness/2026-11-13-movement-walls.md`.

## Rapports des agents, mot pour mot

### Développeur

`````markdown
# Rapport du développeur : `docs/specs/runner-facing.md`

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-aca86878cd85b9b53`
Branche : `runner-facing` (depuis `main` à `cae57ce`), non poussée.
Commits :
- `68fe78c` runner-facing: the visible body faces the push (le code et les tests)
- `55569c5` spec: runner-facing implemented (la ligne de statut seulement)

Routage (`.agents/skills/index.md`) : type `player` (`game/player/player.gd`) et les
tests. Aucun skill à charger. La vérification en plus du type `player` est dans
« Non vérifié ».

## Fait

Le changement est dans `game/player/player.gd`. `_turn_towards_movement(delta)` devient
`_turn(intent, delta)` et `_heading(intent)` :
- états GROUNDED, RISING, FALLING, HARD_LANDING : le corps se tourne vers la direction
  de l'intention ; sans poussée, il garde son orientation (décision 1) ;
- SLIDING, ROLLING : il se tourne vers la vitesse horizontale ; sous 0,1 m/s, il garde
  son orientation (décision 2) ;
- WALL_RUNNING : il se tourne vers la vitesse horizontale moins sa part le long de
  `motor.wall_run_normal()` (décision 3) ;
- MANTLING : il ne tourne pas du tout (décision 4).

La vitesse de rotation reste `turn_speed` (décision 6). Je n'ai touché ni à
l'inclinaison ni à `_facing()` (décision 5) : l'inclinaison s'appuie toujours dessus, et
pendant un wall-run le corps regarde maintenant le long du mur. Le moteur, les constats,
le pilote et le parcours sont inchangés (décision 7) : le changement se limite à
`player.gd`, qui lit seulement `motor.state` et `motor.wall_run_normal()`. Je n'ai ajouté
aucune requête au moteur.

Les tests sont dans le nouveau fichier `tests/test_player_facing.gd`. Ils tournent dans
la vraie physique (Jolt) sur des blocs construits pour chaque cas, et la visière est
mesurée à chaque pas (décision 8) :

| Scénario | Test | Rouge sur `main` ? |
| -------- | ---- | ------------------ |
| Sauter contre un mur en poussant droit vers lui garde le coureur face au mur | `test_jumping_against_a_wall_pushing_straight_keeps_the_runner_facing_the_wall` | oui : 90° de profil, pour une caméra décalée de ±1° ou ±3° |
| Courir contre un mur en poussant de biais garde le coureur face à sa poussée | `test_running_against_a_wall_pushing_aslant_keeps_the_runner_facing_its_push` | oui : 60° d'écart avec la poussée |
| Une vitesse de travers ne tourne pas le coureur qui ne pousse pas | `test_a_sideways_velocity_does_not_turn_a_runner_that_does_not_push` | oui : 67° |
| Le coureur se tourne vers où il pousse au rythme réglé | `test_the_runner_turns_towards_where_it_pushes_at_the_tuned_pace` | oui : sur `main`, il suit la vitesse, qui tourne plus lentement |
| En l'air, le coureur regarde où il pousse, pas où il vole | `test_in_the_air_the_runner_looks_where_it_pushes_not_where_it_flies` | oui : 80° |
| En glissade, le coureur regarde où il glisse | `test_in_a_slide_the_runner_looks_where_it_slides` | non (`main` le faisait déjà) ; rouge contre un sabotage « intention partout » |
| En wall-run, le coureur regarde le long du mur | `test_in_a_wall_run_the_runner_looks_along_the_wall` | non ; rouge contre les sabotages « intention partout » et « poussée en wall-run » |
| Sauter vers un rebord en poussant droit garde le coureur de face jusqu'en haut | `test_jumping_at_a_ledge_pushing_straight_keeps_the_runner_facing_it_to_the_top` | oui, sur le rebord haut : 68 à 70° |
| En mantle, le coureur ne tourne pas | `test_in_a_mantle_the_runner_does_not_turn` | oui : 90° pendant le mantle |
| Hors du wall-run, le coureur reste droit | `test_out_of_a_wall_run_the_runner_stays_upright` | non (`main` le faisait déjà) ; rouge contre les sabotages « léger roulis partout » et « tangage en l'air » |

`test_the_runner_turns_towards_where_it_pushes_at_the_tuned_pace` lit `turn_speed` dans
`res://game/core/movement_tuning.tres`. Il vérifie à chaque pas que l'angle tourné vaut
`min(k · turn_speed / 60, 90°)`, à 2° près. Un sabotage qui double la vitesse le fait
passer au rouge.

Un test existant a changé : `tests/test_player_ledges.gd`,
`test_a_ledge_approached_at_an_angle_gives_a_mantle` (voir « Écarts »).

## Vérifié

- `just setup` dans le worktree : OK.
- `just preflight` sur `main` avant de commencer : vert, 125 tests, 26,0 s au total (les
  tests seuls : 14,8 s).
- `just test test_player_facing` sur le code de `main` : 7 tests sur 10 rouges, chacun
  pour la bonne raison (angles ci-dessus). Les 3 autres sont verts sur `main` parce que
  `main` le faisait déjà.
- J'ai ajouté des traces le temps d'une passe, puis je les ai retirées, pour comprendre
  pourquoi le rebord ne virait pas au rouge. Contre une face au sol, la physique de
  Godot bloque la vitesse horizontale quand on pousse presque droit (vitesse nulle : le
  corps ne tourne pas). C'est en l'air que la vitesse glisse le long de la face et que le
  corps se met de profil. Pour un rebord à 1,9 m, le mantle part dès le premier pas en
  l'air, donc `main` ne tourne pas. Pour un rebord plus haut (3,0 m), que le saut doit
  d'abord faire monter dans la plage du mantle, `main` tourne de 68 à 70° avant que le
  mantle parte. C'est le cas que Jimmy décrit (« un mur qui est trop haut […] il monte
  quand même »). Le test couvre les deux hauteurs.
- Sabotages de `player.gd` (un script dans le scratchpad, rien dans le dépôt), chacun
  passé avec `just test test_player_facing` puis annulé. Le fichier restauré a le même
  md5 que l'original :
  - « intention partout » : glissade et wall-run rouges ;
  - « le mantle tourne vers son mouvement » : mantle rouge ;
  - « poussée en wall-run » : wall-run rouge ;
  - « léger roulis partout » et « tangage en l'air » : « reste droit » rouge ;
  - « vitesse de rotation doublée » : « rythme réglé » rouge.
- Pour le test de rebord adapté, un sabotage « le rebord n'est retenu que devant le corps
  visible » (la décision 22 cassée) le fait passer au rouge (« and yet the runner
  mantled ») : le test garde sa force.
- Rejeu avec `turn_speed` à 8 puis à 25 dans `movement_tuning.tres`, puis restauré (même
  md5) : `just test test_player_` vert les deux fois, 16 tests sur 16.
- `just preflight` après le changement : vert, 135 tests, 26,7 s au total (les tests
  seuls : 16,0 s). Le nouveau script ajoute environ 1,2 s de tests ; le gate rapide reste
  sous 30 s.
- `just check` sur le commit `68fe78c` : vert, code de sortie 0, environ 35 s
  (vérification des types sur 39 scripts sans erreur, lint propre, 135 tests sur 135,
  structure à 0 problème, les deux builds exportés, le build Windows lancé 60 images sans
  écran).
- `just deadcode` après le commit du statut : 0 problème.

## Non vérifié

Ce que seul Jimmy peut juger, manette en main (type `player`) :
- Sauter contre une face trop haute pour un mantle, puis vers un rebord haut (le cas
  qu'il a décrit) : la tête reste-t-elle droite jusqu'en haut ?
- Au clavier, la diagonale avant-gauche vers un mur : en wall-run, le corps regarde le
  long du mur. Est-ce naturel ?
- Le stick qui traverse lentement sa zone morte : le corps garde son orientation quand
  la poussée tombe à zéro. Un petit coup de stick le tourne d'un coup vers la nouvelle
  direction, même pour une poussée faible : faut-il que ce soit plus doux ?
- La glissade et la roulade suivent toujours le mouvement : le passage de « face à la
  poussée » à « face au mouvement » au début d'une glissade poussée de côté peut se voir.
- La caméra n'a pas changé (hors périmètre). Je n'ai rien joué : pas de manette ni
  d'écran ici. Seuls les tests sans écran et le build lancé sans écran ont tourné.

## Écarts

1. **Un test existant a changé** : `tests/test_player_ledges.gd`,
   `test_a_ledge_approached_at_an_angle_gives_a_mantle`. Sa mise en place supposait que
   la physique tourne le corps visible le long de la face (« dont le corps visible a
   tourné le long de la face »), et il vérifiait que le corps avait dépassé 45°. Avec la
   décision 1, le corps regarde la poussée (22,5°) et l'assertion tombait. Je n'ai pas
   touché à l'assertion. J'ai rendu la condition de départ explicite : un champ
   `forced_look` de la scène tourne lui-même le corps visible le long de la face, à la
   fin de chaque pas avant le mantle. Le constat du pas suivant voit donc toujours un
   corps tourné contre la face. C'est au moins aussi fort qu'avant : le sabotage de la
   décision 22 le fait passer au rouge. Les autres tests qui lisent `Visual`
   (`test_course.gd:74`, `test_course_walls.gd`, `test_player_walls.gd:72`) sont restés
   verts sans changement.
2. **Seuil « presque nulle » (décision 2)** : la spec ne donne pas de valeur. J'ai pris
   0,1 m/s, une constante `ALMOST_STILL` dans `player.gd`, pas dans la ressource de
   réglage, puisque la décision 6 dit « aucune valeur nouvelle dans la ressource ». Le
   même seuil vaut pour la part le long du mur en wall-run. Pour la poussée, il suffit
   qu'elle soit non nulle : la zone morte du stick met déjà à zéro ce qui est trop
   petit.
3. **Réception dure** : rangée avec le sol, donc tournée vers la poussée, comme le dit la
   décision 1 (« en réception dure »).
4. **Pendant le mantle** (décision 4) : le corps garde l'orientation qu'il avait à la fin
   du pas d'avant, même si une rotation n'était pas finie. Le test vérifie aussi que
   cette orientation est la poussée, à 2° près, dans le cas joué (poussée de biais tenue
   depuis le sol).
5. **« Droit » (décision 5)** : après un wall-run, le corps se redresse toujours au
   rythme de `turn_speed`, comme avant. C'est ce que disent les décisions 5 et 6
   (« l'inclinaison du wall-run ne change pas », « pour tourner comme pour se
   redresser »). Le scénario ne porte que sur les courses sans wall-run, et c'est ce que
   le test vérifie.
6. **Lecture de « droit vers le mur »** : suivant la leçon 2 du tour précédent, les
   scénarios « en poussant droit » sont joués avec une caméra décalée de -3, -1, 0, +1 et
   +3°. Avec un décalage nul exact, `main` ne tourne pas : le bug ne se voit qu'avec le
   bruit d'une vraie main. « Regarde le mur » est compris comme « à moins du décalage
   plus 2° de l'axe du mur ».
7. **Deux commits** au lieu d'un : le code, puis la ligne de statut. C'est la consigne de
   la session principale (« mark the spec … in a commit »).
8. **`AGENTS.md` n'a pas changé**, comme demandé. Une ligne de description pourrait
   suivre le code : dans « Layout », `player/` dit « the runner's scene: body, camera
   rig, intents read from the inputs, and what the body observes around it ». On
   pourrait y ajouter « and where its visible body looks ». C'est à décider par la
   session principale. La phrase de la décision 10 de `docs/specs/movement-base.md`,
   remplacée par la décision 1, est toujours là telle quelle : je n'édite pas les specs.

## Questions

Rien ne bloque la fusion. À trancher seulement si la session principale le veut :
- Faut-il ajouter à `AGENTS.md` la ligne de description ci-dessus (Écarts, point 8) ?
- 0,1 m/s pour « presque nulle » vous convient-il ? Ce n'est pas une valeur de feeling,
  et je l'ai laissée dans le code.

---

## Correction après inspection (constat conseillé)

Commit `3fc3725` sur `runner-facing`, après `55569c5`.

Le constat : `test_in_a_mantle_the_runner_does_not_turn` gardait la même poussée
pendant le mantle. « Garder l'orientation du début » et « suivre la poussée » donnaient
le même résultat : sans le cas `MANTLING` de `_heading`, les 10 tests restaient verts.

**Fait** (dans `tests/test_player_facing.gd`, et nulle part ailleurs) :
- Une nouvelle source d'intentions, `PushElsewhereInTheMantle`, enveloppe la séquence
  écrite. Dès que `runner.motor.state == MANTLING`, elle pousse vers `Vector3.LEFT`. Elle
  lit l'état du pas d'avant, donc le pas qui lance le mantle suit encore la séquence.
- Le test vérifie maintenant que le mantle commence en regardant la poussée de biais, à
  2° près. Il vérifie aussi que chaque pas du mantle après le premier pousse bien
  ailleurs, et que la visière ne bouge pas de plus de 2° pendant tout le mantle.
- Le code du jeu ne change pas.

**Vérifié** :
- `just test test_player_facing` sur le code corrigé : 10 tests sur 10 verts.
- Sabotage « cas `MANTLING` retiré de `_heading` » : le test est rouge (112,5° d'écart
  avec l'orientation du début), et c'est le seul à l'être.
- Sabotage « le mantle tourne vers son mouvement » : le même test est rouge (22,5°).
- Après les deux sabotages, `player.gd` est restauré : même md5 que l'original.
- `just check` : vert, code de sortie 0, 34,9 s. Vérification des types sur 39 scripts
  sans erreur, lint propre, 135 tests sur 135 (16,0 s), structure à 0 problème, les deux
  builds exportés et le build Windows lancé sans écran. J'ai commité tel quel l'arbre
  qui a passé `just check`.

**Réponses prises en compte** : je garde `ALMOST_STILL` à 0,1 m/s dans le code, et je
n'ai touché ni à `AGENTS.md` ni à `docs/`.

`````

### Inspecteur

`````markdown
# Inspection : branche `runner-facing` (main..runner-facing, base cae57ce)

Spec : `docs/specs/runner-facing.md`. Routage : `player` (game/player/player.gd), `harness` (docs/specs/), tests.

## 1. Verdict

**Conforme**, aucun constat bloquant.

Ce que j’ai lancé : `just preflight` sur le worktree est vert (typecheck, lint, 135/135 tests, deadcode 0 problème). L’arbre de travail est resté propre. Les tests de mutation ont tourné sur une copie dans le scratchpad (`oldplayer/`) :
- **Ancien `player.gd` (main) + nouveaux tests** : 7 des 10 tests de `test_player_facing.gd` échouent. Les trois qui passent (glissade, wall-run, droit) portent sur un comportement que la spec garde tel quel (décisions 2, 3 et 5).
- **Cas `WALL_RUNNING` retiré** (le corps suit alors la poussée) : le test wall-run échoue (45°).
- **Glissade tournée vers la poussée** : le test glissade échoue.
- **Constats du rebord tirés de `_facing()`** (violation de la décision 22) : le test de rebord modifié échoue (« and yet the runner mantled »).
- **Cas `MANTLING` retiré** (le corps suit alors la poussée pendant le mantle) : **10/10 restent verts**. Voir le constat 1.
- **Nouveau code + ancien test de rebord** : il échoue (22,5° < 45°). Sa précondition ne tient plus, donc il fallait le modifier.

La décision 7 est respectée. Le diff de `game/` ne touche que `_turn`/`_heading` (et l’ajout de `ALMOST_STILL`) dans `player.gd`. `_observe` et ses sondes, le moteur (`game/core/`), le pilote (`tests/pilot_intent_source.gd`) et le parcours (`game/levels/`) ne changent pas. `_facing()` ne sert encore qu’à l’inclinaison.

**Test de rebord modifié** (`test_a_ledge_approached_at_an_angle_gives_a_mantle`) : son intention (décision 22 de movement-walls) est toujours prouvée, sans affaiblissement. Le handler force `Visual.rotation.y` sur RIGHT à la fin de chaque pas avant le mantle. Le `_observe` du pas suivant voit donc un corps visible à 90°, au-delà de la limite de 45°, et le mantle part quand même. La mutation M4 montre que le test attrape bien une dépendance des constats au visuel. Le même procédé existe déjà dans `tests/test_player_walls.gd:72`. Seule réserve : `assert_gt(aside, towards_limit)` mesure maintenant l’angle forcé lui-même. C’est presque une tautologie : elle prouve seulement qu’il y a eu des pas au sol avec le corps tourné. La vraie preuve est `did_mantle`.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | conseillé | tests/test_player_facing.gd:322-346 | Spec, décision 4 et scénario « En mantle, le coureur ne tourne pas » | La poussée reste constante pendant le mantle. « Garder l’orientation du début » et « suivre la poussée » donnent alors le même résultat : si on retire le cas `MANTLING` de `_heading` (player.gd:301-302), les 10 tests passent quand même. Le test attrape l’ancien bug (se tourner vers la montée), mais il ne verrait pas un mantle qui suit la poussée. | Dans ce test, changer la poussée pendant le mantle et vérifier que la visière ne bouge pas. Deux façons : une source d’intentions de test qui pousse ailleurs dès que `runner.motor.state == MANTLING`, ou un basculement scripté à un pas connu pour tomber dans le mantle. |
| 2 | conseillé | docs/specs/runner-facing.md:48 | Spec, décision 7 (« aucun test de mouvement ne change ») ; AGENTS.md, « Contributing workflow » (« if a rule is truly wrong, say so in the pull request ») | `tests/test_player_ledges.gd:43-45, 85-86, 111-113` a changé, contrairement à la lettre de la décision 7. Le changement est nécessaire et ne retire rien au test. L’écart n’est expliqué que dans le message de commit, et la spec marquée Implémenté ne le dit pas. | Le signaler dans la description de la PR. La spec pourrait le noter en une ligne : décision 7, « sauf la précondition du test du rebord de biais, qui tourne désormais le corps visible lui-même ». |
| 3 | conseillé | game/player/player.gd:303 | Spec, décisions 1 (réception dure vers la poussée) et 2 (roulade vers le mouvement) | Aucun scénario ne couvre la roulade ni la réception dure. Une régression qui tournerait la roulade vers la poussée ne serait vue par aucun test. C’est un trou de la spec, pas du développement. | Ajouter deux scénarios à la prochaine session de sparring, ou accepter le trou en connaissance de cause. |
| 4 | conseillé | game/player/player.gd:18-20 | AGENTS.md, « Architecture » (« Every tuning value of the feel … lives in one single tuning resource ») ; spec, décision 6 (« Aucune valeur nouvelle dans la ressource de réglage ») | `ALMOST_STILL = 0.1` m/s est un seuil écrit dans le code. Je ne sais pas si c’est une valeur de ressenti ou un simple epsilon : il ne décide que du moment où le corps cesse de tourner en fin de glissade, de roulade ou de wall-run. La spec interdit explicitement une nouvelle valeur dans la ressource. | Rien à changer si l’owner le considère comme un epsilon. Sinon, une décision de spec. |

## 3. Couverture de la spec

| Scénario | Test |
| -------- | ---- |
| Sauter contre un mur en poussant droit vers lui garde le coureur face au mur | test_jumping_against_a_wall_pushing_straight_keeps_the_runner_facing_the_wall |
| Courir contre un mur en poussant de biais garde le coureur face à sa poussée | test_running_against_a_wall_pushing_aslant_keeps_the_runner_facing_its_push |
| Une vitesse de travers ne tourne pas le coureur qui ne pousse pas | test_a_sideways_velocity_does_not_turn_a_runner_that_does_not_push |
| Le coureur se tourne vers où il pousse au rythme réglé | test_the_runner_turns_towards_where_it_pushes_at_the_tuned_pace (turn_speed lu dans la ressource, conforme à la note de la spec) |
| En l’air, le coureur regarde où il pousse, pas où il vole | test_in_the_air_the_runner_looks_where_it_pushes_not_where_it_flies |
| En glissade, le coureur regarde où il glisse | test_in_a_slide_the_runner_looks_where_it_slides |
| En wall-run, le coureur regarde le long du mur | test_in_a_wall_run_the_runner_looks_along_the_wall |
| Sauter vers un rebord en poussant droit garde le coureur de face jusqu’en haut | test_jumping_at_a_ledge_pushing_straight_keeps_the_runner_facing_it_to_the_top (seul le rebord de 3,0 m distingue l’ancien code ; celui de 1,9 m passait déjà) |
| En mantle, le coureur ne tourne pas | test_in_a_mantle_the_runner_does_not_turn (voir le constat 1) |
| Hors du wall-run, le coureur reste droit | test_out_of_a_wall_run_the_runner_stays_upright (deux coureurs au lieu d’un : le premier saute contre le mur, le second se hisse, glisse et retombe) |

Aucun test n’existe sans scénario correspondant.

## 4. Non vérifiable ici (à juger manette en main)

- **Saut puis mantle sur un rebord haut** (le cas de Jimmy) : le corps reste-t-il de face de façon fluide, avec la caméra qui dévie légèrement à la souris ou au stick ?
- **Course contre un mur en diagonale** : le corps regarde la poussée pendant qu’il glisse de côté. Est-ce naturel, ou est-ce le « moonwalk » que la décision 1 accepte ?
- **Relâcher la poussée en pleine course** : le corps garde son orientation pendant la décélération, y compris après un choc qui le fait glisser de travers.
- **Changer de direction au stick** : la rotation de 14 rad/s vers la poussée et non plus vers la vitesse. Un demi-tour au stick fait maintenant pivoter le corps tout de suite, avant que la vitesse ne suive.
- **En l’air** : le corps se tourne vers la poussée alors que la trajectoire ne change presque pas. Est-ce lisible ?
- **Wall-run** : le corps regarde le long du mur, et l’inclinaison de 20° se redresse au rythme de `turn_speed` à la sortie.
- **Mantle de biais** : le corps ne tourne pas pendant la montée. Vérifier aussi que la reprise vers la poussée, juste après, ne donne pas d’à-coup.
- **Clavier et souris contre manette** : la poussée clavier en diagonale (45°) fait regarder le corps en diagonale au sol. Au stick, la poussée est continue.

`````
