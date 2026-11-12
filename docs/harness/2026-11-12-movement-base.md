# Leçons du tour — base du déplacement (`docs/specs/movement-base.md`)

Tour du 2026-11-12, propriétaire : Jimmy. Premier tour complet du harnais sur ce
projet : sparring, spec, développeur, inspecteur, corrections, second inspecteur,
fusion (pull request n° 4). Ce document dit ce que le tour a appris sur le harnais
lui-même. Les quatre rapports des agents sont à la fin, mot pour mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

## Déroulé et durées

| Étape | Qui | Durée | Résultat |
| ----- | --- | ----- | -------- |
| Sparring | session principale avec Jimmy | 2 questions de calibrage, 4 tours de questions (16 questions) | deux specs : la base (🟡) et les mouvements avancés (en attente) |
| Développement | développeur, worktree isolé | environ 34 min | 36 scénarios, 37 tests, `just check` vert en local |
| Inspection | inspecteur, contexte neuf | environ 10 min | « à corriger » : 2 constats bloquants, 7 conseillés |
| Amendement de la spec | session principale, décisions de Jimmy | quelques minutes | 40 scénarios, décisions 20 et 21 |
| Corrections | même développeur | environ 10 min | 40 tests, `just check` vert en local |
| Seconde inspection | nouvel inspecteur, contexte neuf | environ 12 min | « conforme », 5 constats conseillés |
| CI | GitHub Actions, Linux | moins d'une minute | verte |

## Ce que la grille du kit demande de noter

1. **Sparring.** Il a calibré d'abord (deux questions, une par message), puis posé ses
   questions par tours numérotés avec une réponse recommandée, puis écrit la spec au
   format, statut 🟡. Écart : il a écrit **deux** specs, la seconde avec un statut
   d'attente qui n'est pas celui que décrit `AGENTS.md`. Jimmy a répondu « oui pour
   tout » à quatre tours : les recommandations sont donc devenues des décisions sans
   être discutées, valeurs de réglage comprises.
2. **Développeur.** Il a travaillé sur la spec, fait passer `just check`, rendu les cinq
   sections. Écart qu'il a signalé lui-même : pour trois couches sur six (état de la
   course, affichages, parcours) il a écrit le code avant de voir le test échouer.
3. **Inspecteur.** Il a laissé le dépôt intact les deux fois, et chaque constat avait un
   fichier et une ligne.
4. **Écarts de lecture.** Voir les leçons ci-dessous.

## Leçons

1. **Un test peut porter le nom d'un scénario sans rien prouver.** Le test « une
   réapparition ne touche pas au chrono » ne faisait aucune réapparition, et toutes les
   portes étaient vertes. Seul l'inspecteur l'a vu. C'est la raison d'être de ce rôle ;
   la consigne « chaque test prouve-t-il vraiment son scénario » donnée à l'inspecteur
   dans son lancement a compté.
2. **Un trou de la spec devient un choix du développeur.** La spec ne disait pas où lire
   « retour au checkpoint » et « recommencer ». Le développeur les a lues dans le niveau,
   l'a écrit dans ses écarts, et l'inspecteur l'a classé bloquant. Proposition pour le
   sparring : pour chaque action nouvelle, écrire dans la spec si elle voyage dans
   l'intention.
3. **Ne pas montrer le rapport du développeur à l'inspecteur a servi.** Le premier
   inspecteur a trouvé le test vide et l'écart entre le README et la zone morte du
   stick, que le rapport du développeur ne mentionnait pas.
4. **« Relis la documentation et cite la page » corrige la mémoire d'un agent.** Au
   premier tour le développeur croyait, de mémoire, qu'il fallait mettre
   `physics_jitter_fix` à 0. Obligé de citer la documentation au second tour, il a
   constaté que le moteur le fait seul et n'a rien changé.
5. **L'exception « réglage seul » se heurte aux tests rejoués.** Relevé par le second
   inspecteur : les suites d'intentions comptent des pas calés sur les valeurs
   actuelles, donc un changement de vitesse ou de gravité les fera échouer alors que le
   parcours reste faisable. À régler avant le premier changement de valeur, par une
   spec qui rend ces suites réactives (sauter à l'approche du bord, pas à un pas donné).
6. **Les tests rejoués en temps réel ont quadruplé `just preflight`** (7 s à 30 s).
   L'accélération décidée après coup l'a ramené à 11 s. Proposition : le prévoir dans
   la spec dès qu'elle demande un test rejoué. Cette accélération a fait entrer
   `Engine.time_scale` dans le code du jeu, à rouvrir quand la visée ralentira le temps
   (étape 3).
7. **Les rôles de `.claude/agents/` ne sont pas chargés par une session ouverte avant
   leur installation.** Le développeur et l'inspecteur ont été lancés comme agents
   génériques, avec la consigne de lire leur fichier de rôle en premier. Les deux ont
   suivi leur rôle. Dans une nouvelle session, les rôles seront disponibles directement.
8. **Un agent ne connaît de la machine que ce qu'on lui écrit.** Godot n'est pas sur le
   `PATH` des agents, et rien ne doit s'ouvrir à l'écran de Jimmy : ces deux faits
   figuraient dans chaque lancement. Ils pourraient vivre dans `AGENTS.md`.
9. **Ne pas changer l'état décrit à un agent pendant qu'il travaille.** La branche a été
   poussée pendant la seconde inspection, alors que son lancement la disait locale.
   L'inspecteur l'a remarqué et signalé ; sans conséquence ici.
10. **Jouer tôt.** Jimmy a pu jouer le premier commit depuis un `.exe` exporté dans un
    worktree à part, pendant les corrections. Son premier avis (« ça me paraît bien »)
    est arrivé avant la fusion.

## Ce qui reste ouvert après ce tour

- La sensation de la version corrigée n'a été jugée par personne, et aucune manette n'a
  été branchée.
- La stabilité des tests rejoués sous Linux repose sur une seule exécution de la CI.
- Trois constats conseillés du second inspecteur attendent une décision : les tests
  rejoués et les réglages (leçon 5), `Engine.time_scale` lu par le jeu (leçon 6), un
  test qui distingue l'arrondi de la troncature.
- `docs/specs/movement-advanced.md` attend que Jimmy ait réglé la base.

## Rapports des agents, mot pour mot

### Développeur, premier passage (commit 9800a8e)

````markdown
# Rapport du développeur — `docs/specs/movement-base.md`

Les 36 scénarios ont chacun leur test du même nom, `just check` est vert, et le tout tient en un commit sur `movement-base`. Rien n'a été lancé dans une fenêtre : toute la sensation de jeu reste à juger par Jimmy.

## Fait

**Logique du coureur — `tests/test_runner_motor.gd`** (code : `game/core/runner_motor.gd`, `move_intent.gd`, `movement_tuning.gd` et `.tres`)
1. Le coureur accélère jusqu'à la vitesse de pointe → `test_the_runner_accelerates_up_to_top_speed`
2. Le coureur s'arrête quand l'intention cesse → `test_the_runner_stops_when_the_intent_ceases`
3. Un stick à moitié poussé… → `test_a_half_pushed_stick_gives_a_reduced_top_speed`
4. Un saut tenu atteint la hauteur réglée → `test_a_held_jump_reaches_the_tuned_height`
5. Un saut relâché tôt monte moins haut → `test_a_jump_released_early_rises_less_high`
6. Le saut reste possible pendant le coyote time → `test_the_jump_remains_possible_during_coyote_time`
7. Le saut est refusé après le coyote time → `test_the_jump_is_refused_after_coyote_time`
8. Un saut demandé juste avant l'atterrissage… → `test_a_jump_requested_just_before_landing_starts_on_landing`
9. Un saut demandé trop tôt… → `test_a_jump_requested_too_early_before_landing_is_forgotten`
10. Un appui ne donne qu'un seul saut → `test_one_press_gives_only_one_jump`
11. Le contrôle en l'air est plus faible qu'au sol → `test_air_control_is_weaker_than_on_the_ground`
12. La vitesse de chute est plafonnée → `test_the_fall_speed_is_capped`
13. Les mêmes intentions donnent le même résultat → `test_the_same_intents_give_the_same_result`

**État de la course — `tests/test_race_state.gd`** (code : `game/core/race_state.gd`)
14. Le chrono démarre au passage de la ligne de départ → `test_the_timer_starts_when_crossing_the_start_line`
15. Le chrono s'arrête à la ligne d'arrivée → `test_the_timer_stops_at_the_finish_line`
16. Le meilleur temps de la session est conservé → `test_the_best_time_of_the_session_is_kept`
17. Un checkpoint atteint devient le point de réapparition → `test_a_reached_checkpoint_becomes_the_respawn_point`
18. Un checkpoint déjà dépassé… → `test_a_checkpoint_already_passed_does_not_move_the_respawn_back`
19. Recommencer remet le chrono à zéro… → `test_restarting_resets_the_timer_and_keeps_the_best_time`
20. Une réapparition ne touche pas au chrono → `test_a_respawn_does_not_touch_the_timer`

**Entrées — `tests/test_input_map.gd`** (code : section `[input]` de `project.godot`)
21. Chaque action de jeu a une entrée clavier-souris et une entrée manette → `test_every_game_action_has_a_keyboard_mouse_input_and_a_gamepad_input`
22. Les touches du clavier sont des touches physiques → `test_keyboard_keys_are_physical_keys`

**Joueur — `tests/test_player.gd`** (code : `game/player/player.gd`, `player.tscn`, `camera_rig.gd`, `input_intent_source.gd`, `game/core/intent_source.gd`)
23. Avancer va là où regarde la caméra → `test_forward_goes_where_the_camera_looks`
24. La caméra se rapproche quand un mur passe derrière le coureur → `test_the_camera_moves_closer_when_a_wall_passes_behind_the_runner`

**Parcours — `tests/test_course.gd`** (code : `game/levels/course.gd`, `test_course.tscn`, `game/world/checkpoint.gd`, `race_line.gd`, et l'aide de test `tests/scripted_intent_source.gd`)
25. La scène principale est le parcours test → `test_the_main_scene_is_the_test_course`
26. Tomber sous le parcours ramène au dernier checkpoint → `test_falling_below_the_course_brings_back_to_the_last_checkpoint`
27. Le retour au checkpoint fonctionne à tout moment → `test_returning_to_the_checkpoint_works_at_any_time`
28. La section d'élan se franchit → `test_the_run_up_section_can_be_cleared`
29. La section des sauts courts se franchit → `test_the_short_jumps_section_can_be_cleared`
30. La section des sauts longs se franchit → `test_the_long_jumps_section_can_be_cleared`
31. Un saut long sans élan échoue → `test_a_long_jump_without_run_up_fails`
32. La section des marches mène à l'arrivée → `test_the_steps_section_leads_to_the_finish`
36. Recharger les réglages applique les nouvelles valeurs → `test_reloading_the_tuning_applies_the_new_values`

**Affichages — `tests/test_race_hud.gd`, `tests/test_debug_overlay.gd`** (code : `game/ui/race_hud.gd` et `.tscn`, `debug_overlay.gd` et `.tscn`)
33. Le temps s'affiche au centième → `test_the_time_is_displayed_to_the_hundredth`
34. L'arrivée affiche le temps final et le meilleur temps → `test_the_finish_displays_the_final_time_and_the_best_time`
35. L'affichage de debug apparaît et disparaît → `test_the_debug_display_appears_and_disappears`

**Autres changements**
- `project.godot` : table d'entrées, Jolt, interpolation physique, couches physiques nommées (`world`, `runner`), scène principale. La section `[debug]` est intacte.
- `game/levels/sandbox.tscn` et `tests/test_sandbox_scene.gd` sont supprimés (décisions 15 et 16).
- `README.md` : sections « Running the game » et « Controls ».
- `AGENTS.md` : seules les lignes du bloc « Layout » sont mises à jour, aucune règle.
- Statut de la spec passé à `🟢 Implémenté`.

## Vérifié

- **`just setup`** : exécuté une fois, sans erreur.
- **`just check`** : vert, exécuté en dernier avant le commit, en 39 s. Sortie, sans les lignes d'import :

```
typecheck: 21 script(s), 0 with errors
gdlint game tests → Success: no problems found
gdformat --check game tests → 21 files would be left unchanged
res://tests/test_course.gd          10/10 passed.
res://tests/test_debug_overlay.gd    1/1 passed.
res://tests/test_input_map.gd        2/2 passed.
res://tests/test_player.gd           2/2 passed.
res://tests/test_race_hud.gd         2/2 passed.
res://tests/test_race_state.gd       7/7 passed.
res://tests/test_runner_motor.gd    13/13 passed.
Tests 37 · Passing Tests 37 · Asserts 219 · Time 22.394s
---- All tests passed! ----
structure: boundaries: 0 problem(s)
structure: dead files: 0 problem(s)
structure: .claude mirror: 0 problem(s)
structure: 26 file(s) checked
build: Windows Desktop: build/windows/parkour-duel.exe (104 MiB with its .pck)
build: Windows Desktop: the exported game ran 60 frames headless
build: Linux: build/linux/parkour-duel.x86_64 (70 MiB with its .pck)
```

- **Stabilité des tests rejoués sur cette machine** : 4 exécutions complètes de la suite avec les séquences finales (`just preflight` ×2, `just check` ×2), toutes vertes.
- **Marges des séquences**, mesurées avec une sonde temporaire non commitée qui décale chaque saut pas à pas :

| Section | Décalage toléré par saut |
| ------- | ------------------------ |
| Élan | toute course de 125 à 170 pas passe (145 retenu) |
| Sauts courts | au moins −11 à +14 pas |
| Sauts longs | −8 à +8 pas (±0,13 s) |
| Marches | au moins −11 à +10 pas |

- **Le saut long demande bien le saut tenu** : un saut tapé, un seul pas d'appui, n'atteint jamais le bloc d'en face, quel que soit le moment du saut (41 décalages essayés).
- **Les tests mordent** : j'ai cassé le code exprès, puis restauré. Les tests concernés sont passés rouges dans chaque cas :
  - vitesse de saut non compensée (sommet à 1,684 m, hors des 5 %) ;
  - bornes du coyote time et du jump buffer décalées d'un pas ;
  - chute et retour au checkpoint désactivés ;
  - rechargement désactivé.
- **Ordre test puis code** : les tests ont été écrits avant le code de chaque couche. Je les ai vus échouer avant d'écrire le code pour le coureur, la table d'entrées et le joueur. Pour l'état de la course, les affichages et le parcours, j'ai écrit le code avant de lancer le test ; leur premier lancement était donc vert, sauf les sauts longs, rouges tant que les pas n'étaient pas mesurés.
- **Mesures faites sans écran** : chrono centré en haut, meilleur temps juste dessous, debug à (16, 16) ; caméra à 4,5 m derrière et 1,6 m de haut ; limites verticales à +50° et −60°.

## Non vérifié

Je n'ai jamais lancé le jeu dans une fenêtre. Tout ce qui suit demande Jimmy, clavier-souris puis manette en main.

**Mouvements**
- Course : montée en vitesse (30 m/s²), freinage (45 m/s²), vitesse de pointe (9 m/s), demi-tours au sol.
- Stick à moitié poussé : vitesse proportionnelle, zone morte de 0,2.
- Saut : hauteur tenue (1,6 m), saut court au relâchement (45 % gardés), gravité plus forte en chute (32 puis 44 m/s²), plafond de chute (40 m/s).
- Contrôle en l'air (14 m/s²). L'élan est gardé en l'air quand on lâche le stick (voir Écarts).
- Rotation de la capsule et de sa visière vers le déplacement (14 rad/s).

**Fenêtres de tolérance**
- Coyote time : 0,10 s, soit 6 pas.
- Jump buffer : 0,12 s, appliqué comme 7 pas, soit 0,117 s.
- Fenêtre du saut long : environ 16 pas (0,27 s), coyote compris.

**Caméra**
- Sensibilité souris (0,0025 rad/pixel) et vitesse au stick droit (2,6 rad/s) ; sens des axes.
- Limites verticales ; distance et hauteur du point visé.
- Bras à ressort contre un mur ou contre le sol en regardant vers le haut. La distance se corrige au pas physique alors que la rotation suit l'image : à-coups possibles.
- Fluidité au-delà de 60 Hz avec l'interpolation physique.
- Caméra dans le dos après une réapparition. L'inclinaison verticale n'est pas remise à zéro.

**Périphériques**
- Clavier : touches physiques sur l'AZERTY de Jimmy (Z, Q, S, D), Espace, Ctrl gauche, R, Retour arrière, F3, F4.
- Souris : capture au lancement, `Échap` qui libère, clic qui reprend. Aucun test ne couvre ce code.
- Manette : stick gauche, stick droit, A et LB, B et RB (sans effet), Y, Back. Aucune manette n'a été branchée ; le regard à la souris et au stick n'a aucun test.

**À l'écran**
- Lisibilité du chrono et de l'affichage de debug en 1280 × 720 et au redimensionnement.
- Lisibilité des blocs gris, des faces des marches, des bandes blanches de départ et d'arrivée, de la visière ; éclairage et ombres.

**Parcours**
- Difficulté réelle : largeur 6 m, vides de 2,5 m (courts) et 4,2 m (longs), marches de 1 m de haut sur 5 m de profondeur.
- Parcours d'un seul trait : aucun test ne le rejoue du départ à l'arrivée. Chaque section est prouvée depuis son checkpoint, comme la décision 17 le demande.
- `F4` en vrai : le test passe par une copie du fichier dans `user://`.
- Bouton « recommencer » en jeu : testé sans écran seulement.

**Plates-formes**
- CI Linux : rien n'a tourné sous Linux. La stabilité des tests rejoués entre Windows et Linux n'est donc pas établie.
- Le binaire Linux est exporté mais pas lancé. Le binaire Windows a tourné 60 images sans écran.

## Écarts

**Comportement Jolt à rapporter (décision 8)**
- Avec le bras à ressort par défaut, l'origine de la caméra finit environ 1,1 mm à l'intérieur de la surface du mur : mur à 2,25 m, caméra à 2,2511 m.
- La propriété `margin` du bras n'a aucun effet dans ce mode : même valeur avec 0, 0,01 et 0,2.
- Avec une sphère de 0,2 m comme forme du bras, la caméra reste à 2,049 m.
- Je n'ai pas contourné. Le test du scénario 24 vérifie que le plan proche de la caméra (5 cm devant elle) reste du côté du coureur, pas son origine.
- Aucun autre comportement anormal aux arêtes ou aux marches dans les rejoués.

**Lectures de la spec**
1. **Suite d'intentions écrite à l'avance** : `ScriptedIntentSource` vit dans `tests/`, pas dans `game/`, parce que son seul consommateur est un test. La classe de base `IntentSource` est dans `game/core/`.
2. **Durées en pas fixes** : arrondies au pas le plus proche. Le jump buffer de 0,12 s vaut donc 7 pas.
3. **Vitesse de départ du saut** : corrigée pour le pas fixe (9,86 m/s au lieu de 10,12). Sans cela le sommet est à 1,684 m, hors des 5 % du scénario 4.
4. **Pas de freinage en l'air** : sans direction, la vitesse horizontale est gardée. La table n'a qu'un « freinage au sol ».
5. **Freinage au sol** : il ne sert que sans direction. Avec une direction, la vitesse rejoint la cible à l'accélération au sol, même pour ralentir ou tourner.
6. **Retour au checkpoint, recommencer, F3, F4** : ce ne sont pas des intentions (la décision 2 fixe leur contenu). Le niveau, l'affichage et le joueur les lisent comme actions nommées ; retour et recommencer s'appliquent au pas fixe suivant.
7. **Clic qui reprend la souris** : tout bouton de souris, reconnu par le type d'événement et non par une action, puisque les boutons doivent rester libres dans la table.
8. **Zone morte** : celle de la ressource de réglage s'applique aux deux sticks. Le champ `deadzone: 0.2` de chaque action dans `project.godot` est imposé par le moteur : le même nombre existe donc à deux endroits.
9. **Actions ajoutées** : `look_up`, `look_down`, `look_left`, `look_right`, à la manette seulement, pour le stick droit. Toutes les entrées valent pour tous les périphériques.
10. **Capsule** : ses dimensions viennent de la ressource au lancement. `player.tscn` garde les valeurs par défaut de Godot, donc l'éditeur montre une capsule plus grosse que celle du jeu.
11. **Nombres restés hors de la ressource** : la hauteur de la visière (80 % de la capsule, constante dans `player.gd`) et l'altitude limite (−8 m, propriété de la scène du parcours). Je les ai lus comme apparence et donnée de niveau.
12. **Affichage** : à l'arrivée, la ligne du haut montre `FINISHED 1:15.50`. Le coyote time affiché au sol est la fenêtre entière.
13. **Rechargement `F4`** : il relit le fichier d'où vient la ressource courante. Dans un build exporté ce fichier est dans le `.pck`, donc `F4` n'y change rien.
14. **Checkpoint 0** : la plateforme de départ est le point de réapparition initial. Les checkpoints sont acceptés avant la ligne de départ.
15. **Lignes de départ et d'arrivée** : dessinées par une bande blanche, non demandée par la spec. Les checkpoints sont invisibles.
16. **Cadence** : `physics_ticks_per_second` n'est pas écrit dans `project.godot`, 60 étant la valeur par défaut du moteur.
17. **Test en plus** : `test_restarting_the_course_brings_the_runner_back_to_the_start`, pour l'action « recommencer » vue du niveau (décision 14).
18. **Avertissement neutralisé** : `@warning_ignore("integer_division")` à trois endroits (`race_state.gd`, `race_hud.gd`). Ce n'est pas un des avertissements du gate.

## Questions

1. **Caméra contre un mur** : garde-t-on le bras par défaut (1 mm dans le mur, invisible en théorie), ou lui donne-t-on une sphère ? La sphère ajoute une valeur de réglage que la spec ne prévoit pas.
2. **Durée des tests** : la suite passe d'environ 1 s à 22 s, `just preflight` d'environ 7 s à 30 s, `just check` de 15 s à 39 s, parce que les rejoués tournent en temps réel. Multiplier par 10 `physics_ticks_per_second` et `time_scale` dans les tests garde un pas de 1/60 s (mesuré dans la sonde) et les mêmes résultats de franchissement. Je ne l'ai pas appliqué : c'est aux propriétaires de décider comment les tests tournent.
3. **Freinage en l'air** : faut-il une valeur dédiée, ou garder l'élan tel quel ?
4. **`physics_jitter_fix`** : de mémoire, la documentation de Godot conseille 0 avec l'interpolation physique. Je ne l'ai pas relue pendant cette session et la spec n'en dit rien : laissé par défaut.
5. **Emplacement de `ScriptedIntentSource`** : à déplacer dans `game/` quand le fantôme (étape 4) en aura besoin ?

## Branche, commit, worktree

- Branche : `movement-base` (renommée, non poussée, pas de pull request)
- Commit : `9800a8efe2b7555d776b452e5cd4e6d1e50cb368`
- Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ab62bed734bfc0e53`
````

### Inspecteur, première inspection (sur 9800a8e)

````markdown
# Inspection de `movement-base` contre `main` — spec `docs/specs/movement-base.md`

Périmètre : `git diff main...movement-base` (un commit, `9800a8e`), lu en entier, ainsi que tous les fichiers touchés.
Les chemins sont relatifs à `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ab62bed734bfc0e53`.
Types de tâche routés : `core`, `player`, `world`, `levels`, `ui`, `tooling` (`project.godot`), `harness` (`AGENTS.md`, `docs/`).
Commandes lancées ici, sous Windows : `just test` (37/37, 219 assertions), `just typecheck` (21 scripts, 0 erreur), `just lint` (rien), `just deadcode` (0 problème). Arbre de travail inchangé après coup.

## 1. Verdict

**À corriger** : deux constats bloquants. Le n° 2 demande d'abord une décision de Jimmy, parce que la spec ne dit pas où ces deux actions sont lues.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | bloquant | `tests/test_race_state.gd:93-103` | `AGENTS.md`, « Contributing workflow » (« turns each scenario into a test of the same name ») ; scénario « Une réapparition ne touche pas au chrono » | Le test ne fait aucune réapparition : il lit `race.last_checkpoint`, fait 60 `tick()` et vérifie 60. Il passerait quoi que fasse une réapparition au chrono. | Porter ce nom sur un test de `tests/test_course.gd` qui déclenche l'action `respawn` en pleine course et vérifie que `elapsed_steps` avance du nombre exact de pas. L'assertion existe déjà pour la chute (`tests/test_course.gd:83-84`). |
| 2 | bloquant (à trancher par Jimmy) | `game/levels/course.gd:52-57`, consommé en `:42-48` | `AGENTS.md`, « Architecture » : « Inputs are converted into **intents** (a simple typed structure) before they reach the simulation » ; table des couches (seul `game/player/` lit les entrées) | « Retour au checkpoint » et « Recommencer » sont lues dans `levels/` et atteignent la simulation (téléportation, `RaceState.restart()`) par deux booléens, hors de la source d'intentions. Une suite rejouée, un fantôme ou le réseau ne peuvent donc pas les porter. La décision 2 n'a pas ces champs, et la décision 12 n'exempte que F3, F4 et Échap. | Soit une exception écrite dans la spec, comme la décision 12. Soit lire les deux actions dans `game/player/` et les passer à `Course` par la source d'intentions, dans une structure typée de `core`. |
| 3 | conseillé (règle incertaine) | `game/levels/course.gd:42-46` | `AGENTS.md`, « Architecture » : « The game logic is strictly separated from its presentation: the logic is testable without the engine's scene tree » | La règle « sous l'altitude limite → réapparition » et la priorité de recommencer sur réapparaître sont décidées dans `levels/`, testables seulement avec la scène. Je ne suis pas sûr que la règle s'applique : la spec range ces scénarios sous « Parcours (levels, world, ui) ». | Si Jimmy la veut dans `core` : une fonction de `RaceState` qui reçoit l'altitude, la limite et les deux demandes, et rend la décision ; `Course` ne fait qu'exécuter. |
| 4 | conseillé | `tests/test_course.gd:107-120` | `.agents/inspector.md`, procédure 3 (« a test without its scenario is a finding ») | `test_restarting_the_course_brings_the_runner_back_to_the_start` n'a pas de scénario dans la spec ; son commentaire le dit. | Ajouter le scénario à la spec (décision 14, vue du parcours) ou retirer le test. |
| 5 | conseillé | `README.md:61-62` ; cause en `game/player/input_intent_source.gd:22` | Décision 5 (« vitesse de pointe proportionnelle ») ; décision 19 | Le README promet « a stick pushed halfway gives half of it ». `Input.get_vector` avec zone morte 0,2 ré-étale la course du stick : un stick à 50 % donne une intention de 0,375, soit environ 3,4 m/s et non 4,5. Lu dans le code, non mesuré manette en main. Le test du scénario passe parce qu'il injecte 0,5 directement dans `core`. | Corriger la phrase du README (« proportionnelle au-delà de la zone morte »), ou décider que 50 % de stick doit donner 50 % et le dire dans la spec. |
| 6 | conseillé | `tests/test_player.gd:44-49` | Scénario « La caméra se rapproche… sans le traverser » ; décision 8 (« rapporté, pas contourné ») | L'assertion porte sur le plan proche de la caméra (`camera.near`), pas sur sa position : le commentaire dit que son origine finit environ 1 mm dans le mur avec Jolt. Le test tolère donc jusqu'à 5 cm de pénétration. Le rendu ne voit pas à travers, mais c'est un comportement au mur, dont la seule trace dans le dépôt est ce commentaire. | Vérifier qu'il figure au rapport du développeur et que Jimmy l'accepte ; sinon l'écrire dans la spec. |
| 7 | conseillé | `tests/test_runner_motor.gd:248-253` ; `game/core/runner_motor.gd:138-141` | Scénarios coyote time et jump buffer ; tableau des valeurs (« `core` les applique avec le pas fixe ») | Les tests calculent les fenêtres avec la formule du moteur (`roundi(secondes / pas)`) : ils ne verraient pas un changement d'arrondi. L'arrondi au plus proche fait de 0,12 s une fenêtre de 7 pas (0,117 s) et peut en allonger d'autres (0,125 s donnerait 8 pas, 0,133 s). | Écrire les attendus en dur dans les tests (6 et 7 pas pour 0,10 s et 0,12 s à 60 Hz) et faire confirmer l'arrondi par Jimmy. |
| 8 | conseillé | `AGENTS.md:136-140` ; `project.godot:26-122` | `.agents/skills/index.md`, types `harness` et `tooling` (« An owner's review ») | Le développeur a modifié la section « Layout » d'`AGENTS.md`, que la spec ne demandait pas, et `project.godot`. Aucune porte n'est relâchée (`[debug]` intact) ; `[layer_names]` est ajouté sans être demandé. | Relecture explicite de ces deux fichiers par Jimmy avant la fusion. |
| 9 | conseillé (règle incertaine) | `game/player/player.gd:65-69` | `AGENTS.md`, « Architecture » : « load resources with a full literal path, `preload` or a `class_name`, never with a path built at run time » | Le rechargement F4 charge `tuning.resource_path`, une valeur lue à l'exécution. La référence reste littérale dans `game/player/player.tscn:5`, donc `just deadcode` la voit ; je ne suis pas sûr que la règle vise ce cas. | Aucune si Jimmy juge la référence de la scène suffisante ; sinon une constante de chemin littéral. |

Points demandés, sans constat :

- **Temps d'image** : la simulation n'avance qu'en `_physics_process` (`game/player/player.gd:32`, `game/levels/course.gd:41`). Les seuls `_process` sont la caméra, le chrono affiché et l'affichage de debug.
- **Nombres de réglage dans le code** : aucun. Les seules constantes numériques sont de la géométrie d'affichage (`game/player/player.gd:9`, `game/player/player.tscn:16`) et `fall_limit`, donnée du parcours (`game/levels/test_course.tscn:81`).
- **Tableau des décisions** : les 21 valeurs de `game/core/movement_tuning.tres` sont celles de la spec, et la disposition des entrées de `project.godot` est celle du tableau, codes de touches physiques et indices de boutons relus un par un. Les 19 décisions sont respectées, hors constats 2, 5 et 6.
- **`movement-advanced.md`** : rien dans la branche. `slide_held` et l'action `slide` sont déclarées sans effet, comme la décision 2 le demande.
- **Tests rejoués** : ils ne passent pas pour une mauvaise raison. Le checkpoint suivant et la phase `FINISHED` ne sont posés que par les signaux des `Area3D`, et l'altitude minimale est relevée à chaque pas. Calcul à la main, non mesuré : environ 0,9 à 1,5 m de marge à chaque réception. Les deux sauts longs partent 10 à 13 cm avant le bord, et le coyote time couvre un dépassement.

## 3. Couverture de la spec

36 scénarios, 36 tests de même nom, plus un test sans scénario (constat 4). Aucun test sauté ni affaibli ; `tests/test_sandbox_scene.gd` est supprimé comme la décision 16 le prévoit.

| Scénario | Test |
| -------- | ---- |
| Le coureur accélère jusqu'à la vitesse de pointe | `test_the_runner_accelerates_up_to_top_speed` |
| Le coureur s'arrête quand l'intention cesse | `test_the_runner_stops_when_the_intent_ceases` |
| Un stick à moitié poussé donne une vitesse de pointe réduite | `test_a_half_pushed_stick_gives_a_reduced_top_speed` (niveau `core` seulement, constat 5) |
| Un saut tenu atteint la hauteur réglée | `test_a_held_jump_reaches_the_tuned_height` |
| Un saut relâché tôt monte moins haut | `test_a_jump_released_early_rises_less_high` |
| Le saut reste possible pendant le coyote time | `test_the_jump_remains_possible_during_coyote_time` |
| Le saut est refusé après le coyote time | `test_the_jump_is_refused_after_coyote_time` |
| Un saut demandé juste avant l'atterrissage part à l'atterrissage | `test_a_jump_requested_just_before_landing_starts_on_landing` |
| Un saut demandé trop tôt avant l'atterrissage est oublié | `test_a_jump_requested_too_early_before_landing_is_forgotten` |
| Un appui ne donne qu'un seul saut | `test_one_press_gives_only_one_jump` |
| Le contrôle en l'air est plus faible qu'au sol | `test_air_control_is_weaker_than_on_the_ground` |
| La vitesse de chute est plafonnée | `test_the_fall_speed_is_capped` |
| Les mêmes intentions donnent le même résultat | `test_the_same_intents_give_the_same_result` |
| Le chrono démarre au passage de la ligne de départ | `test_the_timer_starts_when_crossing_the_start_line` |
| Le chrono s'arrête à la ligne d'arrivée | `test_the_timer_stops_at_the_finish_line` |
| Le meilleur temps de la session est conservé | `test_the_best_time_of_the_session_is_kept` |
| Un checkpoint atteint devient le point de réapparition | `test_a_reached_checkpoint_becomes_the_respawn_point` |
| Un checkpoint déjà dépassé ne fait pas reculer la réapparition | `test_a_checkpoint_already_passed_does_not_move_the_respawn_back` |
| Recommencer remet le chrono à zéro et garde le meilleur temps | `test_restarting_resets_the_timer_and_keeps_the_best_time` |
| Une réapparition ne touche pas au chrono | `test_a_respawn_does_not_touch_the_timer` : présent mais ne prouve rien (constat 1) |
| Chaque action de jeu a une entrée clavier-souris et une entrée manette | `test_every_game_action_has_a_keyboard_mouse_input_and_a_gamepad_input` |
| Les touches du clavier sont des touches physiques | `test_keyboard_keys_are_physical_keys` |
| Avancer va là où regarde la caméra | `test_forward_goes_where_the_camera_looks` |
| La caméra se rapproche quand un mur passe derrière le coureur | `test_the_camera_moves_closer_when_a_wall_passes_behind_the_runner` (constat 6) |
| La scène principale est le parcours test | `test_the_main_scene_is_the_test_course` |
| Tomber sous le parcours ramène au dernier checkpoint | `test_falling_below_the_course_brings_back_to_the_last_checkpoint` |
| Le retour au checkpoint fonctionne à tout moment | `test_returning_to_the_checkpoint_works_at_any_time` |
| La section d'élan se franchit | `test_the_run_up_section_can_be_cleared` |
| La section des sauts courts se franchit | `test_the_short_jumps_section_can_be_cleared` |
| La section des sauts longs se franchit | `test_the_long_jumps_section_can_be_cleared` |
| Un saut long sans élan échoue | `test_a_long_jump_without_run_up_fails` |
| La section des marches mène à l'arrivée | `test_the_steps_section_leads_to_the_finish` |
| Le temps s'affiche au centième | `test_the_time_is_displayed_to_the_hundredth` |
| L'arrivée affiche le temps final et le meilleur temps | `test_the_finish_displays_the_final_time_and_the_best_time` |
| L'affichage de debug apparaît et disparaît | `test_the_debug_display_appears_and_disappears` |
| Recharger les réglages applique les nouvelles valeurs | `test_reloading_the_tuning_applies_the_new_values` |

## 4. Non vérifiable ici

**Non lancé ou hors de portée**

- `just build` et `just check` : interdits au relecteur, donc les exports Windows et Linux ne sont pas vérifiés.
- La CI Linux : la branche n'est pas poussée. La stabilité des cinq tests rejoués entre Windows et Linux (décision 17) n'est établie que sous Windows.
- Aucun test n'enchaîne le parcours du départ à l'arrivée. Les quatre sections sont prouvées une par une, chacune depuis l'arrêt à son checkpoint, avec la course mise « en cours » par appel direct (`tests/test_course.gd:224-227`).
- Aucun test ne prouve qu'un saut long demande le saut tenu (ce n'est pas un scénario). À la main, un appui bref à pleine vitesse porte environ 2,5 m pour 4,2 m de vide.

**À juger par Jimmy, clavier-souris puis manette en main**

Course
- L'accélération jusqu'à 9 m/s et l'arrêt au relâchement.
- Le demi-tour au sol : pousser à l'opposé utilise l'accélération (30 m/s²) et non le freinage (45 m/s²), donc il est plus lent que relâcher puis repartir (`game/core/runner_motor.gd:91-92`).
- Le virage : la vitesse baisse pendant un changement de direction.
- Le stick gauche : zone morte 0,2 et vitesse réelle à mi-course (constat 5).
- En l'air : aucun frein sans direction (`game/core/runner_motor.gd:93-95`), contrôle à 14 m/s².

Saut
- La hauteur du saut tenu (1,6 m), la différence avec l'appui bref (coupe à 45 %), les gravités de montée et de chute.
- Le coyote time (6 pas) au bord des blocs et le jump buffer (7 pas, 0,117 s) à la réception.
- Un saut mis en mémoire puis relâché avant la réception part en petit saut.
- Aucun appui perdu quand l'écran dépasse 60 Hz.
- Le saut sur A et sur LB.

Caméra
- La sensibilité souris et stick droit, le sens vertical (non inversé), les butées à 60° vers le bas et 50° vers le haut.
- La fluidité avec l'interpolation physique au-delà de 60 Hz.
- Le bras à ressort contre un obstacle : il rapproche et relâche sans lissage, et le parcours n'a aucun mur pour l'essayer, seulement des contremarches de 1 m.
- La caméra dans le dos après une réapparition : l'inclinaison verticale n'est pas remise à zéro (`game/player/camera_rig.gd:57-58`).
- La capture de la souris au lancement, Échap qui la libère, le clic qui la reprend : aucun test.
- Le champ de vision, le plan proche, la marge du bras et l'accroche au sol du corps sont aux valeurs par défaut du moteur, pas dans la ressource de réglage.

Personnage et parcours
- La lisibilité de la capsule et de sa visière, la rotation à 14 rad/s vers le déplacement.
- La difficulté ressentie des sauts courts (2,5 m), des sauts longs (4,2 m) et des marches de 1 m.
- Le comportement aux arêtes avec Jolt : glissement au bord d'un bloc, accrochage sur une contremarche.
- La chute jusqu'à −8 m avant la réapparition (environ 0,6 s).
- R / Y et Retour arrière / Select à tout moment ; le chrono qui démarre bien à la ligne et s'arrête bien à l'arrivée.

Entrées
- La disposition sur un vrai clavier AZERTY (Z, Q, S, D).
- Les boutons sur une vraie manette : A, B, Y, LB, RB, Select.

Affichages
- La lisibilité de TIME, BEST et FINISHED en 1280 × 720 et quand la fenêtre change de taille.
- Le contenu de F3 pendant le jeu.
- F4 après avoir modifié `game/core/movement_tuning.tres` à la main, jeu lancé depuis le dossier du projet.
````

### Développeur, corrections (commit db16a3a)

````markdown
# Rapport du développeur — corrections après inspection de `docs/specs/movement-base.md`

Les sept points de l'inspection sont traités, les 40 scénarios de la spec amendée ont chacun leur test du même nom, et `just check` est vert. Un nouveau commit est posé sur `fae33cb`, sans réécriture des deux précédents et sans push. `physics_jitter_fix` n'est pas modifié : la documentation dit que le moteur le désactive seul.

## Fait

**Points bloquants**

1. **Test de réapparition qui ne prouvait rien** : `test_a_respawn_does_not_touch_the_timer` est supprimé de `tests/test_race_state.gd` et réécrit dans `tests/test_course.gd`. Course en cours, le coureur s'éloigne du checkpoint, une intention demande le retour, 31 pas s'écoulent. Le test vérifie que le coureur est au checkpoint à l'arrêt et que le chrono a avancé d'exactement 31 pas.
2. **Demandes hors de l'intention** : `MoveIntent` porte `respawn_requested` et `restart_requested`. `game/player/input_intent_source.gd` est le seul à lire ces deux actions. `game/levels/course.gd` n'a plus de `_unhandled_input` ni de booléens. Nouveau test `test_a_sequence_of_intents_can_request_the_return_to_the_checkpoint` (`tests/test_course.gd`), avec `ScriptedIntentSource.request_respawn()`.

**Points décidés**

3. **Règle de réapparition dans `core`** : `RaceState.apply_respawn_rule(altitude, fall_limit, intent)` rend `NONE`, `RESPAWN` ou `RESTART`. Le niveau l'appelle une fois par pas fixe du coureur et ne fait que replacer le coureur. Tests dans `tests/test_race_state.gd` : `test_going_below_the_fall_limit_requests_a_respawn` et `test_restarting_wins_over_respawning`.
4. **Recommencer** : `test_restarting_the_course_brings_the_runner_back_to_the_start` porte déjà le nom du scénario ; le commentaire « hors spec » est retiré. Le test passe maintenant par l'action `restart` de la table d'entrées.
5. **Stick** : comportement du moteur inchangé. La phrase du `README.md` dit maintenant que la vitesse visée est proportionnelle à la course au-delà de la zone morte, et qu'un stick à mi-course donne un peu moins que la moitié.
6. **Caméra** : le bras porte une `SphereShape3D` dont le rayon vient de la nouvelle valeur `camera_collision_radius` (0,2 m dans `movement_tuning.tres`). `test_the_camera_moves_closer_when_a_wall_passes_behind_the_runner` vérifie la position de la caméra elle-même : côté coureur du mur, à un rayon du mur (±1 cm), derrière le coureur.
7. **Arrondi** : `tests/test_runner_motor.gd` écrit `COYOTE_STEPS = 6` et `BUFFER_STEPS = 7` en dur ; les deux fonctions qui recalculaient ces nombres sont supprimées.

**Réponses à mes questions**

- **Accélération des tests** : appliquée à `tests/test_course.gd` seulement, par `before_all` et `after_all` (pas par seconde ×10 et `time_scale` ×10). Chaque rejoué vérifie que le pas vaut 1/60 s.
- **`physics_jitter_fix`** : inchangé, voir Vérifié.
- **Freinage en l'air** et **emplacement de `ScriptedIntentSource`** : aucun changement, comme décidé.

Le statut de la spec est repassé à `🟢 Implémenté`.

## Vérifié

- **`just check`** : vert, exécuté en dernier, en 20,3 s (39 s avant). Sortie, sans les lignes d'import :

```
typecheck: 21 script(s), 0 with errors
gdlint game tests → Success: no problems found
gdformat --check game tests → 21 files would be left unchanged
res://tests/test_course.gd          12/12 passed.
res://tests/test_debug_overlay.gd    1/1 passed.
res://tests/test_input_map.gd        2/2 passed.
res://tests/test_player.gd           2/2 passed.
res://tests/test_race_hud.gd         2/2 passed.
res://tests/test_race_state.gd       8/8 passed.
res://tests/test_runner_motor.gd    13/13 passed.
Tests 40 · Passing Tests 40 · Asserts 250 · Time 3.509s
---- All tests passed! ----
structure: boundaries: 0 problem(s)
structure: dead files: 0 problem(s)
structure: .claude mirror: 0 problem(s)
structure: 26 file(s) checked
build: Windows Desktop: build/windows/parkour-duel.exe (104 MiB with its .pck)
build: Windows Desktop: the exported game ran 60 frames headless
build: Linux: build/linux/parkour-duel.x86_64 (70 MiB with its .pck)
```

- **Nouveaux temps** :

| Commande | Avant | Maintenant |
| -------- | ----- | ---------- |
| Suite de tests | 22 s | 3,5 s |
| `just preflight` | environ 30 s | 11,2 s et 11,4 s (deux mesures) |
| `just check` | 39 s | 20,3 s |

- **Franchissements identiques en accéléré** : une sonde temporaire, non commitée, a rejoué les quatre sections à vitesse 1 puis 10. La position du coureur est identique à chaque pas (817 pas, 0 écart), et le pas observé est 1/60 s.
- **Marges des séquences**, remesurées à vitesse 10 avec le code final :

| Section | Décalage toléré par saut |
| ------- | ------------------------ |
| Élan | toute course de 125 à 170 pas passe (145 retenu) |
| Sauts courts | −11 à +14, puis au moins ±14 pour les deux suivants (limite de la mesure) |
| Sauts longs | −8 à +8 pas pour les deux sauts |
| Marches | −12 à +11, −11 à +11, −12 à +10 |

- **Stabilité** : 3 exécutions complètes de la suite avec le code final (`just preflight` ×2, `just check` ×1), toutes vertes.
- **Ordre test puis code** : les tests de ce tour ont été écrits d'abord et vus en échec (11 tests rouges et des erreurs d'analyse sur les membres absents) avant le code.
- **Les tests mordent** : j'ai cassé le code exprès, puis restauré. Sept tests sont passés rouges, ceux attendus :
  - règle sans l'altitude, et priorité de recommencer retirée : les deux tests de la règle, la chute sous le parcours, le saut long sans élan ;
  - `respawn` et `restart` non lus dans les entrées : retour au checkpoint, recommencer ;
  - rayon de la sphère non appliqué : test de la caméra.
- **`physics_jitter_fix`** : j'ai lu la documentation officielle de Godot 4.7.
  - Les trois pages du tutoriel sur l'interpolation physique (« Introduction », « Quick start guide », « Using physics interpolation ») ne mentionnent pas ce réglage.
  - La référence de `ProjectSettings` (`https://docs.godotengine.org/en/stable/classes/class_projectsettings.html`, propriété `physics/common/physics_jitter_fix`) dit : « Jitter fix is automatically disabled at runtime when physics/common/physics_interpolation is enabled. »
  - Mesure dans le projet : `Engine.physics_jitter_fix` vaut 0.0 à l'exécution alors que le réglage est à 0.5.
  - Mon souvenir du tour précédent était donc inexact : la mise à 0 à la main est conseillée pour une interpolation maison ou un jeu en réseau, pas pour l'interpolation intégrée.

## Non vérifié

- **Sensation de la caméra avec la sphère** : distance au mur et au sol (0,2 m), à-coups éventuels. À juger par Jimmy.
- **`R` / `Y` et Retour arrière / Back en vrai** : les tests pressent les actions par `Input.action_press`, pas par une touche ni une manette.
- **Arrondi ou troncature** : les valeurs 6 et 7 font échouer un arrondi au pas supérieur (vérifié au premier tour), mais pas une troncature, puisque 0,10 s et 0,12 s donnent 6 et 7 dans les deux cas.
- **Linux** : toujours rien d'exécuté sous Linux, accélération comprise.
- **Test de la caméra** : il reste en temps réel (moins d'une seconde).
- Le reste de la liste du premier rapport est inchangé : rien n'a été lancé dans une fenêtre.

## Écarts

1. **La règle applique elle-même le redémarrage** : quand recommencer est demandé, `apply_respawn_rule` remet la course à zéro, puis le niveau replace le coureur au checkpoint courant, qui est alors le départ.
2. **Moment de la règle** : le joueur émet un signal `stepped(intent)` à la fin de chaque pas fixe ; le niveau y évalue la règle et fait avancer le chrono. La chute est donc traitée dans le pas où elle se produit, et le chrono avance au rythme des pas du coureur.
3. **Pas par seconde du chrono** : le niveau les calcule comme `physics_ticks_per_second / time_scale`, pour que le chrono reste juste en accéléré (60 dans les deux cas).
4. **Déclenchement dans les tests** : `respawn` et `restart` passent par l'état d'`Input` et la source d'entrées du joueur. `F4` et `F3` restent déclenchés par un événement poussé dans la fenêtre.
5. **Sphère dans la scène** : `player.tscn` porte une sphère au rayon par défaut de Godot ; la valeur de la ressource la remplace au lancement, comme pour la capsule.

## Questions

1. **`F3` lu dans `game/ui/`** : la décision 14 dit que seul `player` lit les entrées, à propos du retour et de recommencer. L'affichage de debug lit encore lui-même son action. Faut-il le faire passer par `player` aussi ?
2. **Troncature non détectée** : veut-on une durée de test qui distingue l'arrondi de la troncature (par exemple 0,11 s, soit 7 pas arrondis et 6 tronqués) ? La décision 20 ne demande que 6 et 7.
3. **Étape 5** : la documentation conseille aussi `physics_jitter_fix` à 0 pour un jeu en réseau. Avec l'interpolation intégrée c'est déjà le cas à l'exécution ; à revoir seulement si l'interpolation change.

## Commit

- Branche : `movement-base`
- Commit : `db16a3ab13c1c96175b7e77aa687a2509cfdf768`, posé sur `fae33cb`
- Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ab62bed734bfc0e53`
````

### Inspecteur, seconde inspection (sur db16a3a)

````markdown
# Inspection de `movement-base` contre `main` — spec `docs/specs/movement-base.md` (40 scénarios)

Périmètre : `git diff main...movement-base` (commits `9800a8e`, `fae33cb`, `db16a3a`), lu en entier, ainsi que tous les fichiers de `game/` et de `tests/` en entier. Chemins relatifs à `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ab62bed734bfc0e53`.
Types de tâche routés : `core`, `player`, `world`, `levels`, `ui`, `tooling` (`project.godot`), `harness` (`AGENTS.md`, `docs/`).
Lancé ici, sous Windows, sur `db16a3a` : `just test` (40/40, 250 assertions, 3,5 s, aucun avertissement ni orphelin), `just typecheck` (21 scripts, 0 erreur), `just lint` (rien), `just deadcode` (0 problème). Arbre de travail inchangé après coup.

Un fait qui contredit la consigne reçue : la branche n'est pas seulement locale. `origin/movement-base` est sur `db16a3a`, la pull request n° 4 est ouverte, et la CI (`just check`, Linux) est verte sur `db16a3a` (run 43303628695). Je n'ai pas lu la description de la PR, pour ne pas voir le rapport du développeur.

## 1. Verdict

**Conforme.** Aucun constat bloquant. Cinq constats conseillés, dont trois demandent une décision de Jimmy plutôt qu'un correctif.

## Suivi de la première inspection

| # | Constat d'origine | État | Preuve |
| - | ----------------- | ---- | ------ |
| 1 | Le test « Une réapparition ne touche pas au chrono » ne faisait aucune réapparition | résolu | `tests/test_course.gd:136-150` : réapparition demandée par une intention, coureur revenu au checkpoint, chrono avancé de 31 pas exactement |
| 2 | Retour au checkpoint et recommencer lus dans `levels/` | résolu | `game/player/input_intent_source.gd:30-31`, `game/core/move_intent.gd:14-17` ; `game/levels/course.gd` ne lit plus aucune entrée |
| 3 | Règle de réapparition décidée dans `levels/` | résolu | `game/core/race_state.gd:67-73` ; `game/levels/course.gd:46-50` ne fait qu'exécuter |
| 4 | Test de « recommencer » sans scénario | résolu | scénario `docs/specs/movement-base.md:265-269`, test `tests/test_course.gd:166-177` |
| 5 | README : « un stick à moitié donne la moitié » | résolu | `README.md:61-63`, conforme à la décision 21 |
| 6 | Le test caméra tolérait la caméra dans le mur | résolu | sphère sur le bras (`game/player/player.tscn:18,39`, `game/player/camera_rig.gd:21`, `game/core/movement_tuning.tres:26`) ; `tests/test_player.gd:44-47` vérifie la position de la caméra, à 0,2 m du mur à 1 cm près |
| 7 | Fenêtres de tolérance recalculées avec la formule du code | partiellement | écrites en dur (`tests/test_runner_motor.gd:13-14`), mais ces deux valeurs ne distinguent pas tous les arrondis : constat 2 |
| 8 | `AGENTS.md` et `project.godot` modifiés par le développeur, `[layer_names]` non demandé | non résolu | inchangés (`AGENTS.md:136-140`, `project.godot:114-117`) ; seule une relecture de Jimmy le résout, rien dans la branche ne peut la montrer |
| 9 | F4 charge un chemin lu à l'exécution | non résolu | inchangé (`game/player/player.gd:69-73`) ; la spec amendée ne tranche pas |

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | conseillé | `game/levels/course.gd:25-26` | Décision 17 (elle autorise l'accéléré pour les tests, pas un changement du jeu) ; `.agents/inspector.md`, procédure 6 | `db16a3a` fait lire `Engine.time_scale` au jeu, uniquement pour l'accéléré de `tests/test_course.gd:50-54`. La formule est juste (un pas dure `time_scale / ticks`, donc `ticks / time_scale` pas par seconde de jeu, soit 60 en jeu). Mais aucun test ne lit l'horloge du parcours en accéléré, donc rien ne la vérifie, et la valeur est figée à `_ready`. | Jimmy l'accepte telle quelle, ou revenir à `Engine.physics_ticks_per_second` : aucune assertion n'en dépend. |
| 2 | conseillé (à trancher par Jimmy) | `tests/test_runner_motor.gd:13-14` et `:240-241` ; `game/core/runner_motor.gd:141` | Décision 20 (« un changement d'arrondi doit faire échouer un test ») | À 60 pas par seconde, 0,10 s vaut 6,0 pas exactement et 0,12 s vaut 7,2 : l'arrondi au plus proche et la troncature donnent tous deux 6 et 7. Remplacer `roundi` par `floori` laisserait les 40 tests verts (calculé, non lancé : lecture seule). Seul un arrondi vers le haut échouerait. | Ajouter à la décision 20 un exemple où le plus proche arrondit vers le haut (0,11 s vaut 7 pas, la troncature donnerait 6), et le test qui va avec. |
| 3 | conseillé (à trancher par Jimmy) | `tests/test_course.gd:182`, `:196-199`, `:212-214`, `:242-245` | `AGENTS.md`, « Contributing workflow » (l'exception du réglage seul, qui passe quand même par une CI verte) | Les suites rejouées comptent des pas calés sur les valeurs actuelles : les deux sauts longs partent 10 à 15 cm avant le bord (calcul à la main, non mesuré). Un changement de quelques pour cent de la vitesse de pointe, ou des gravités, les fera échouer alors que la section reste franchissable. Une PR « réglage seul » sera donc souvent rouge et demandera du code. | Jimmy choisit : l'accepter (chaque changement de réglage passe par un développeur qui recale les suites), ou le faire décider par une spec. |
| 4 | conseillé (règle incertaine, repris du n° 9) | `game/player/player.gd:69-73` | `AGENTS.md`, « Architecture » : « never with a path built at run time » | Inchangé : F4 recharge `tuning.resource_path`. La référence littérale reste dans `game/player/player.tscn:5`, donc `just deadcode` la voit ; je ne suis pas sûr que la règle vise ce cas. | Aucune si Jimmy juge la référence de la scène suffisante. |
| 5 | conseillé (repris du n° 8) | `AGENTS.md:136-140` ; `project.godot:114-117` | `.agents/skills/index.md`, types `harness` et `tooling` (« An owner's review ») | Fichiers des owners modifiés par le développeur ; `[layer_names]` n'était pas demandé. Aucune porte relâchée. | Relecture explicite de Jimmy avant la fusion. |

Points demandés, sans constat :

- **Tests rejoués en accéléré** : ils ne peuvent pas passer pour une mauvaise raison.
  - Le pas reste 1/60 s : `(1/600) × 10` et `1/60` sont le même nombre en double précision, au bit près (calculé). `tests/test_course.gd:302-303` le vérifie à chaque rejeu, à 1e-6 près.
  - Les suites des quatre sections n'ont pas été touchées par `db16a3a` : elles passaient à vitesse réelle sur `9800a8e` et passent telles quelles en accéléré.
  - Un pas du moteur donne un pas du coureur et un pas de chrono : les comptes exacts de `:110` (90 pas) et `:150` (31 pas) le prouvent.
  - Le checkpoint suivant et la phase `FINISHED` ne viennent que des signaux des `Area3D`.
  - Les réglages du moteur sont rendus dans `after_all`.
- **Règle de jeu hors de `game/core/`** : aucune. `levels/` exécute l'ordre rendu par `RaceState.apply_respawn_rule`, `world/` signale, `ui/` affiche, `player/` passe ses constats au moteur.
- **Entrées hors de `game/player/`** : une seule, F3 dans `game/ui/debug_overlay.gd:19-22`, couverte par la décision 12. F4 et Échap sont lus dans `player/`.
- **Temps d'image** : la simulation n'avance que dans `game/player/player.gd:35-40`, et le chrono par le signal `stepped` émis là. Les `_process` sont la caméra (décision 9) et les deux affichages.
- **Nombres de réglage dans le code** : aucun. Les 22 valeurs de `game/core/movement_tuning.tres` sont celles de la spec, rayon de la sphère compris. Restent de la géométrie d'affichage (`game/player/player.gd:12`, `game/player/player.tscn:16`) et `fall_limit`, donnée du parcours (`game/levels/test_course.tscn:81`).
- **`physics_jitter_fix`** (décision 8) : `project.godot:119-122` ne le fixe pas, et c'est conforme. La référence de classe `ProjectSettings` de Godot 4.7 dit qu'activer `physics/common/physics_interpolation` désactive automatiquement le jitter fix, les deux méthodes étant incompatibles (lu ici par résumé, pas mot à mot).
- **`movement-advanced.md`** : rien dans la branche. `slide_held` et l'action `slide` sont déclarées sans effet.
- **Tests** : aucun sauté ni affaibli. `tests/test_sandbox_scene.gd` est supprimé selon la décision 16, et l'ancien test de réapparition de `tests/test_race_state.gd` est remplacé par celui du parcours, selon l'amendement.

## 3. Couverture de la spec

40 scénarios, 40 tests de même nom, aucun test sans scénario.

| Scénario | Test |
| -------- | ---- |
| Le coureur accélère jusqu'à la vitesse de pointe | `test_the_runner_accelerates_up_to_top_speed` |
| Le coureur s'arrête quand l'intention cesse | `test_the_runner_stops_when_the_intent_ceases` |
| Un stick à moitié poussé donne une vitesse de pointe réduite | `test_a_half_pushed_stick_gives_a_reduced_top_speed` (au niveau de l'intention ; décision 21 pour le stick réel) |
| Un saut tenu atteint la hauteur réglée | `test_a_held_jump_reaches_the_tuned_height` |
| Un saut relâché tôt monte moins haut | `test_a_jump_released_early_rises_less_high` |
| Le saut reste possible pendant le coyote time | `test_the_jump_remains_possible_during_coyote_time` (6e pas en l'air accepté) |
| Le saut est refusé après le coyote time | `test_the_jump_is_refused_after_coyote_time` (7e pas refusé) |
| Un saut demandé juste avant l'atterrissage part à l'atterrissage | `test_a_jump_requested_just_before_landing_starts_on_landing` (7 pas avant) |
| Un saut demandé trop tôt avant l'atterrissage est oublié | `test_a_jump_requested_too_early_before_landing_is_forgotten` (8 pas avant) |
| Un appui ne donne qu'un seul saut | `test_one_press_gives_only_one_jump` |
| Le contrôle en l'air est plus faible qu'au sol | `test_air_control_is_weaker_than_on_the_ground` |
| La vitesse de chute est plafonnée | `test_the_fall_speed_is_capped` |
| Les mêmes intentions donnent le même résultat | `test_the_same_intents_give_the_same_result` |
| Le chrono démarre au passage de la ligne de départ | `test_the_timer_starts_when_crossing_the_start_line` |
| Le chrono s'arrête à la ligne d'arrivée | `test_the_timer_stops_at_the_finish_line` |
| Le meilleur temps de la session est conservé | `test_the_best_time_of_the_session_is_kept` |
| Un checkpoint atteint devient le point de réapparition | `test_a_reached_checkpoint_becomes_the_respawn_point` |
| Un checkpoint déjà dépassé ne fait pas reculer la réapparition | `test_a_checkpoint_already_passed_does_not_move_the_respawn_back` |
| Recommencer remet le chrono à zéro et garde le meilleur temps | `test_restarting_resets_the_timer_and_keeps_the_best_time` |
| Passer sous l'altitude limite demande une réapparition (amendement) | `test_going_below_the_fall_limit_requests_a_respawn` : prouve (rien au-dessus, réapparition en dessous et sur demande, chrono intact) |
| Recommencer l'emporte sur réapparaître (amendement) | `test_restarting_wins_over_respawning` : prouve (les deux demandes plus la chute donnent `RESTART`, course remise à zéro) |
| Chaque action de jeu a une entrée clavier-souris et une entrée manette | `test_every_game_action_has_a_keyboard_mouse_input_and_a_gamepad_input` |
| Les touches du clavier sont des touches physiques | `test_keyboard_keys_are_physical_keys` |
| Avancer va là où regarde la caméra | `test_forward_goes_where_the_camera_looks` |
| La caméra se rapproche quand un mur passe derrière le coureur | `test_the_camera_moves_closer_when_a_wall_passes_behind_the_runner` (réécrit : prouve) |
| La scène principale est le parcours test | `test_the_main_scene_is_the_test_course` |
| Tomber sous le parcours ramène au dernier checkpoint | `test_falling_below_the_course_brings_back_to_the_last_checkpoint` |
| Le retour au checkpoint fonctionne à tout moment | `test_returning_to_the_checkpoint_works_at_any_time` (réécrit : passe par l'action réelle et la source d'entrées, au sol puis en l'air) |
| Une réapparition ne touche pas au chrono (amendement) | `test_a_respawn_does_not_touch_the_timer` : prouve |
| Une suite d'intentions peut demander le retour au checkpoint (amendement) | `test_a_sequence_of_intents_can_request_the_return_to_the_checkpoint` : prouve le retour ; « sans qu'aucune touche soit lue » tient à la lecture du code, l'assertion de `tests/test_course.gd:163` ne peut pas échouer |
| Recommencer le parcours ramène le coureur au départ (amendement) | `test_restarting_the_course_brings_the_runner_back_to_the_start` : prouve (action réelle ; la course reste non commencée 30 pas après) |
| La section d'élan se franchit | `test_the_run_up_section_can_be_cleared` |
| La section des sauts courts se franchit | `test_the_short_jumps_section_can_be_cleared` |
| La section des sauts longs se franchit | `test_the_long_jumps_section_can_be_cleared` |
| Un saut long sans élan échoue | `test_a_long_jump_without_run_up_fails` |
| La section des marches mène à l'arrivée | `test_the_steps_section_leads_to_the_finish` |
| Le temps s'affiche au centième | `test_the_time_is_displayed_to_the_hundredth` |
| L'arrivée affiche le temps final et le meilleur temps | `test_the_finish_displays_the_final_time_and_the_best_time` |
| L'affichage de debug apparaît et disparaît | `test_the_debug_display_appears_and_disappears` |
| Recharger les réglages applique les nouvelles valeurs | `test_reloading_the_tuning_applies_the_new_values` |

## 4. Non vérifiable ici

**Non lancé ou hors de portée**

- `just build` et `just check` : interdits au relecteur. La CI les a passés sur `db16a3a`, une seule fois sous Linux ; c'est la seule preuve de stabilité des tests rejoués entre Windows et Linux (décision 17).
- Le rapport du développeur et la description de la PR n° 4, non lus exprès. Deux points en dépendent : la citation de la page de documentation exigée par la décision 8, et la règle « ce qui a été vérifié et ce qui ne l'a pas été ».
- Aucun test n'enchaîne le parcours du départ à l'arrivée : les quatre sections sont prouvées une par une, la course mise « en cours » par appel direct (`tests/test_course.gd:281-284`).
- L'écart réel de la caméra au mur dans `tests/test_player.gd:47` : le test passe à 1 cm près, la valeur mesurée n'est pas affichée.
- La marge réelle des réceptions et des appels des sauts rejoués : calculée à la main (0,9 à 1 m aux réceptions, 10 à 15 cm aux appels des sauts longs), non mesurée.

**À juger par Jimmy, clavier-souris puis manette en main**

Course et saut
- L'accélération jusqu'à 9 m/s, l'arrêt, le demi-tour (accélération de 30 m/s² et non freinage), le virage.
- Le stick gauche : zone morte de 0,2, et environ 3,4 m/s à mi-course.
- La hauteur du saut tenu, l'appui bref, les deux gravités, l'absence de frein en l'air.
- Le coyote time (6 pas) au bord des blocs et le jump buffer (7 pas, soit 0,117 s) à la réception.
- Aucun appui perdu au-delà de 60 Hz. Depuis `db16a3a`, cela vaut aussi pour R / Y et Retour arrière / Select, lus au pas fixe.

Caméra
- La sensibilité souris et stick droit, le sens vertical, les butées.
- La fluidité avec l'interpolation physique au-delà de 60 Hz.
- Nouveau : la sphère de 0,2 m du bras. Son comportement contre un mur et contre le sol quand on regarde vers le haut, et le rapprochement sans lissage, mis à jour à 60 Hz. Le parcours n'a aucun mur pour l'essayer, seulement des contremarches.
- La caméra dans le dos après une réapparition ou un recommencement : l'inclinaison verticale n'est pas remise à zéro (`game/player/camera_rig.gd:59-60`).
- La capture de la souris au lancement, Échap, le clic qui la reprend : aucun test.
- Le champ de vision, la marge du bras et l'accroche au sol du corps sont aux valeurs par défaut du moteur, pas dans la ressource de réglage.

Parcours et réapparition
- La difficulté des sauts courts (2,5 m), des sauts longs (4,2 m) et des marches de 1 m.
- Le comportement aux arêtes avec Jolt.
- La chute jusqu'à −8 m avant la réapparition (environ 0,6 s).
- Recommencer depuis n'importe où : retour sur la plateforme de départ, chrono à zéro, meilleur temps gardé.

Entrées et affichages
- La disposition sur un vrai AZERTY et sur une vraie manette (A, B, Y, LB, RB, Select).
- La lisibilité de TIME, BEST et FINISHED en 1280 × 720 et à d'autres tailles de fenêtre.
- Le contenu de F3 en jeu.
- F4 après modification de `game/core/movement_tuning.tres`, jeu lancé depuis le dossier du projet.
````

