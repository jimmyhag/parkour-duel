# Leçons du tour — mouvements aux murs (`docs/specs/movement-walls.md`)

Tour du 2026-11-13, propriétaire : Jimmy. Quatrième tour complet du harnais : spec relue
une seconde fois après les mouvements au sol (pull request n° 11), trois passes du
développeur, deux inspections, une partie de Jimmy sur une version d'avant-goût, fusion
(pull request n° 12). Ce document dit ce que le tour a appris sur le harnais lui-même.
Les cinq rapports des agents sont à la fin, mot pour mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

Particularité du tour : Jimmy a délégué tout le circuit (« me demande plus rien de
confirmer, juste enchaîne jusqu'au bout »). La session principale a tranché les
constats et les questions, amendé la spec deux fois et fusionné. Chaque choix est écrit
dans la spec, section « Choix acceptés à l'inspection », pour que Jimmy puisse le
rouvrir après avoir joué.

## Déroulé

| Étape | Qui | Résultat |
| ----- | --- | -------- |
| Spec | session principale avec Jimmy | seconde relecture, 21 décisions, 35 scénarios ; pull request n° 11 |
| Développement, passe 1 | développeur, worktree isolé | 5 commits, 119 tests, `just check` vert ; 62 sabotages volontaires ; 160 rejeux de réglage ; 6 questions ; environ 70 min |
| Vérification | session principale | `just check` vert (34 s), CI Linux verte sur la pull request en brouillon |
| Partie d'avant-goût | Jimmy, sur la version exportée de la passe 1 | « plutôt fluide » ; un bug : le mantle refusé quand la tête tourne sur le côté |
| Inspection 1 | inspecteur, contexte neuf | « à corriger » : 1 constat bloquant (plafond de vitesse dépassé au pas du wall-jump), 4 conseillés ; environ 25 min |
| Amendement 1 | session principale, décision déléguée | décisions 2, 3, 4 précisées, décision 22, 6 scénarios (41), un test redimensionné, 17 choix acceptés ; `AGENTS.md` dans un commit à part |
| Développement, passe 2 | développeur, même worktree | 2 commits, 125 tests ; le bug de Jimmy reproduit dans la vraie physique puis corrigé ; environ 20 min |
| Inspection 2 | inspecteur, contexte neuf, sans les rapports ni la première inspection | « conforme », 4 constats conseillés ; environ 22 min |
| Amendement 2 | session principale | décision 3 simplifiée, décision 10 précisée, 7 choix ajoutés |
| Développement, passe 3 | développeur | 2 commits ; 2720 rejeux croisés de réglage ; environ 16 min |
| Clôture | session principale | `just check` vert, CI Linux verte, fusion, version jouable reconstruite |

## Ce que la grille du kit demande de noter

1. **Sparring.** La seconde relecture avant le développement a tranché les croisements
   d'états (décisions 14 à 18), comme le proposait la leçon 3 du tour précédent. Aucun
   constat des inspections ne porte sur un croisement que la spec aurait oublié.
2. **Développeur.** Spec lue, tests d'abord, `just check` vert à chaque commit, cinq
   sections à chaque passe, chaque correction prouvée rouge avant ; il a refusé de
   toucher `AGENTS.md` et de redimensionner un test existant sans décision, et l'a dit.
3. **Inspecteurs.** Dépôt et worktree intacts, chaque constat avec fichier et ligne,
   les expériences faites sur une copie hors du dépôt. Les deux rapports ont été écrits
   sur disque du premier coup, la consigne étant dans le brief (leçon 7 du tour
   précédent).
4. **Écarts de lecture.** Voir les leçons.

## Leçons

1. **Jimmy a trouvé en jouant un bug que ni les tests ni l'inspection ne voyaient.** Le
   rebord n'était retenu que s'il était devant le corps visible, et ce corps tourne vite
   vers la vitesse : contre une face, la vitesse glisse le long d'elle, le corps tourne,
   et le mantle ne part plus. Un élément de présentation décidait d'un mouvement. La
   règle est maintenant écrite (décision 22, et une règle de travail d'`AGENTS.md`).
   Proposition : donner une version jouable à Jimmy dès que la première passe est verte,
   sans attendre la fusion ; ici elle a coûté une reconstruction et apporté le bug le
   plus visible du tour.
2. **Une correction prouvée dans `core` seul peut n'exister que sur le papier.** Le
   premier amendement, écrit par la session principale, faisait compter la diagonale du
   clavier « exactement à la limite » de 45°. Le test du moteur passait ; la seconde
   inspection a montré dans la vraie physique qu'à un degré de caméra près, un mur sur
   deux du zigzag ne donnait plus rien. Une règle bâtie sur une égalité exacte ne résiste
   pas à une entrée réelle. La correction a été de simplifier : le wall-run demande
   seulement de ne pas pousser à l'opposé du mur, et c'est la vitesse le long du mur qui
   le sépare du mantle. Proposition pour la session principale : une règle sur les
   entrées du joueur se prouve avec du bruit réel (caméra décalée, diagonale normalisée),
   dans la vraie physique.
3. **Les rejeux croisés ont trouvé ce que les rejeux une à une manquaient.** Une valeur
   nouvelle changée de 10 % (la poussée verticale du wall-jump), combinée à un des quatre
   réglages garantis, faisait passer la CI au rouge sur le zigzag : une pull request de
   réglage seul aurait été bloquée. Le développeur a rejoué chaque nouvelle valeur
   croisée avec chacun des réglages garantis, sur les dix sections : 2720 courses, qui
   ont fait élargir le palier d'arrivée de 12 à 24 m. Proposition : faire de ce rejeu
   croisé la règle de la décision 10 dans les prochaines specs qui ajoutent des sections.
4. **Un test peut lire un réglage dans une autre convention que le moteur.** Le test du
   rebord de biais mesurait l'angle de partage depuis la normale, le moteur depuis la
   surface ; les deux ne coïncident qu'à 45°, la valeur du projet. Seul le rejeu avec une
   valeur changée l'a montré. C'est la leçon 2 du tour précédent, une seconde fois :
   rejouer les nouveaux tests avec des valeurs changées reste le meilleur filet.
5. **Deux inspections indépendantes, encore.** La seconde, sans les rapports ni la
   première, a trouvé trois défauts réels après les corrections, dont deux qui touchent
   Jimmy au clavier. Coût : environ 22 minutes. Le tour précédent l'avait déjà montré ;
   la seconde inspection devient la norme du harnais pour un changement de cette taille.
6. **La délégation a fait couler le tour, et alourdit la liste des choix.** Rien n'a
   attendu Jimmy entre la spec et la fusion. En contrepartie, la spec liste maintenant
   26 choix acceptés que Jimmy n'a pas lus. Proposition : au point d'arrêt, lui présenter
   seulement ceux qui se sentent manette en main, pas la liste entière.
7. **Les temps : la marge sous 30 s se réduit.** `just preflight` : 21,4 s sur `main`
   avant le tour, 25 s après ; `just check` entre 33 et 41 s. Il reste environ 5 s sous
   la limite de la décision 20 ; l'étape 2 devra dire comment les rejeux grandissent
   sans la dépasser.

## Ce qui reste ouvert après ce tour

- **Point d'arrêt n° 2.** La version fusionnée n'a pas été jouée. La caméra le long des
  murs et dans le zigzag n'a jamais été regardée.
- **La durée du parcours** : 29 s pour le pilote, section par section, contre 45 à 60 s
  visés par la décision 8. À juger par Jimmy en jouant.
- **Pour plus tard** : un `AnimatableBody3D` compte comme un mur (à rouvrir avec les
  plateformes mobiles de l'étape 3) ; une couverture mince au-dessus d'un rebord se
  grimpe (limite de construction de niveau) ; l'idée de Jimmy d'un petit gain de vitesse
  pour une glissade bien faite, à porter à la spec de l'étape 2.
- Toujours ouverts depuis les tours précédents : la protection de la branche `main`, le
  sort de la compétence `harness-setup`, la lecture d'`Engine.time_scale` (étape 3), la
  cause du `just preflight` rouge d'un ancien tour, la correction des jointures du
  pilote prouvée seulement hors du réglage du projet, le pilote qui saute du bord de la
  grande chute.

## Rapports des agents, mot pour mot

### Développeur, passe 1 (commit 480158c)

`````markdown
# Developer report: `docs/specs/movement-walls.md`

All 35 scenarios have a test of the same name, and `just check` is green on the last commit (119 tests). The runner now mantles, wall-runs and wall-jumps. The four new sections are on the course and the pilot clears each one, section by section. The working tree is clean; nothing was pushed or merged.

Three things need an owner before the merge (details under Questions):
- **The course is shorter than decision 8 asks.** The pilot takes about 29 s over the ten sections; the spec says a clean run lasts about 45 to 60 s.
- **One existing pilot test no longer means what its name says.** Its 3.2 m wall can now be climbed with a jump and a mantle; the test is unchanged and still green.
- **`AGENTS.md` was not edited**, as instructed. The proposed text is at the end.

- **Worktree:** `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ac2db3e8c48bad46a`
- **Branch:** `movement-walls`, based on `71e0499` (the merge of pull request #11)

| Commit | Content |
| ------ | ------- |
| `4f2a98c` | core: mantle, wall run and wall jump, and the crossings of the states |
| `13b5fc2` | player, levels, tests: walls and ledges observed, four wall sections, a pilot for them |
| `d553bfd` | ui, docs: the debug display names the wall states, the README describes the wall moves |
| `3474b07` | levels, tests: ledges at 1.9 m, and the checks that deliberate breaks left green |
| `480158c` | tests, docs: a mantle is a contact with the ground, and the spec is implemented |

## Fait

**Mantle (core): `tests/test_runner_mantle.gd`**

| # | Scenario | Test |
| - | -------- | ---- |
| 1 | Le coureur se hisse sur un rebord à sa portée | `test_the_runner_mantles_onto_a_ledge_within_reach` |
| 2 | Un rebord trop haut n'est pas franchi | `test_a_ledge_too_high_is_not_climbed` |
| 3 | Pas de mantle sans pousser vers le rebord | `test_no_mantle_without_pushing_towards_the_ledge` |
| 4 | Pas de mantle si le dessus est encombré | `test_no_mantle_if_the_top_is_blocked` |
| 5 | Le mantle va jusqu'au bout | `test_the_mantle_goes_to_the_end` |

**Wall run and wall jump (core): `tests/test_runner_wall_run.gd`**

| # | Scenario | Test |
| - | -------- | ---- |
| 6 | Le wall-run démarre tout seul le long d'un mur | `test_the_wall_run_starts_by_itself_along_a_wall` |
| 7 | Pas de wall-run sans vitesse | `test_no_wall_run_without_speed` |
| 8 | Le wall-run ralentit la chute | `test_the_wall_run_slows_the_fall` |
| 9 | L'élan au-dessus de la vitesse de pointe se garde en wall-run | `test_momentum_above_top_speed_is_kept_in_a_wall_run` |
| 10 | Le wall-run s'arrête au bout de sa durée | `test_the_wall_run_stops_at_the_end_of_its_duration` |
| 11 | Le wall-run s'arrête quand le mur s'arrête | `test_the_wall_run_stops_when_the_wall_stops` |
| 12 | Pousser à l'opposé du mur fait décrocher | `test_pushing_away_from_the_wall_detaches` |
| 13 | Le wall-jump repousse à l'opposé du mur | `test_the_wall_jump_pushes_away_from_the_wall` |
| 14 | Le wall-jump reste possible juste après avoir décroché | `test_the_wall_jump_remains_possible_just_after_detaching` |
| 15 | Un saut demandé juste avant le mur donne un wall-jump | `test_a_jump_requested_just_before_the_wall_gives_a_wall_jump` |
| 16 | Le même mur est refusé deux fois de suite | `test_the_same_wall_is_refused_twice_in_a_row` |
| 17 | Un autre mur est accepté | `test_another_wall_is_accepted` |
| 18 | Toucher le sol autorise de nouveau le même mur | `test_touching_the_ground_allows_the_same_wall_again` |

**Crossings of the states (core): `tests/test_runner_crossings.gd`**

| # | Scenario | Test |
| - | -------- | ---- |
| 19 | Pas de wall-run ni de mantle en étant baissé | `test_no_wall_run_or_mantle_while_low` |
| 20 | Pas de mantle pendant un wall-run | `test_no_mantle_during_a_wall_run` |
| 21 | La hauteur de chute compte depuis un wall-run | `test_the_fall_height_counts_from_a_wall_run` |
| 22 | Le coureur ne reste pas coincé au-dessus d'une fente sous un plafond bas | `test_the_runner_does_not_get_stuck_over_a_crack_under_a_low_ceiling` |
| 23 | Une grande chute reçue sous un plafond bas sans roulade est lourde | `test_a_big_fall_landed_under_a_low_ceiling_without_a_roll_is_hard` |

**Walls, course, pilot and display**

| # | Scenario | Test | File |
| - | -------- | ---- | ---- |
| 24 | Un mur exclu ne donne pas de wall-run | `test_an_excluded_wall_gives_no_wall_run` | `tests/test_player_walls.gd` |
| 25 | Un mur trop incliné ne donne pas de wall-run | `test_a_wall_too_tilted_gives_no_wall_run` | `tests/test_player_walls.gd` |
| 26 | La grande chute se franchit | `test_the_big_drop_can_be_cleared` (renamed from `..._leads_to_the_finish`, decision 21) | `tests/test_course_ground.gd` |
| 27 | Le rebord se franchit | `test_the_ledge_can_be_cleared` | `tests/test_course_walls.gd` |
| 28 | Le vide se franchit en wall-run | `test_the_gap_can_be_cleared_by_wall_running` | `tests/test_course_walls.gd` |
| 29 | Le zigzag se franchit en wall-jumps | `test_the_zigzag_can_be_cleared_by_wall_jumps` | `tests/test_course_walls.gd` |
| 30 | L'enchaînement final mène à l'arrivée | `test_the_final_combination_leads_to_the_finish` | `tests/test_course_walls.gd` |
| 31 | Le pilote franchit des murs qu'il ne connaît pas | `test_the_pilot_clears_walls_it_does_not_know` | `tests/test_pilot.gd` |
| 32 | Le pilote ne court pas sur un mur sans raison | `test_the_pilot_does_not_wall_run_without_a_reason` | `tests/test_pilot.gd` |
| 33 | Le pilote relâche le saut pour ne pas dépasser sa réception | `test_the_pilot_releases_the_jump_so_as_not_to_overshoot_its_landing` | `tests/test_pilot.gd` |
| 34 | Le retour au checkpoint fonctionne depuis le mantle et le wall-run | `test_returning_to_the_checkpoint_works_from_the_mantle_and_the_wall_run` | `tests/test_course_walls.gd` |
| 35 | L'affichage de debug montre les états des murs | `test_the_debug_display_shows_the_wall_states` | `tests/test_debug_overlay.gd` |

Decision 21 is applied: `test_the_roll_saves_time_on_the_big_drop` keeps its title, and both runners now count their steps up to the ledge checkpoint (new `PilotedRun.steps_to_the_goal`). The four `..._changed_by_10_percent` tests now play the ten sections, 20 runs each.

**Game code**
- **`game/core/runner_facts.gd`.** New facts:
  - `ground_clearance`;
  - the wall beside the runner: `wall_id`, `wall_normal`, `wall_distance`, `wall_height` (`NO_WALL` = 0 means none);
  - the ledge ahead: `ledge_normal`, `ledge_height`, `ledge_clear`.
- **`game/core/runner_motor.gd`.**
  - New states `MANTLING` and `WALL_RUNNING`, appended after the six existing ones.
  - The wall jump, its grace after the runner leaves the wall, and the buffered jump of decision 16.
  - The refused wall of decision 5.
  - Decision 15: the fall is measured from the highest point since the last ground contact, and a mantle counts as a ground contact.
  - Decision 18: the floor speed applies in the air, and a low runner lands by the roll rule (`_held_low` replaces `_low_in_the_air`).
  - New queries: `mantle_time_left()`, `wall_run_time_left()`, `wall_jump_time_left()`, `wall_run_normal()`, and the per-step flag `jumped_off_a_wall`.
- **`game/core/movement_tuning.gd` and `.tres`.** The 15 starting values of the spec, unchanged, in the groups Mantle, Wall run and Wall jump. One more value: `wall_run_lean` = 20° (see Écarts).
- **`game/player/player.gd`.**
  - It reports the clearance under the feet, probed as deep as `wall_run_min_height`.
  - It reports the nearest wall at the left or right. Rays start at mid-body, perpendicular to the facing, as long as radius + `wall_run_distance`. A wall is a `StaticBody3D` outside the group `no_wall_run` (`Player.NO_WALL_RUN_GROUP`). Its identity is the body's instance id; its height is the height of the bounding box of the shape that was hit.
  - It reports the ledge it ran into in front of it: the face comes from last step's slide collisions. The top is probed by a ray going down, one body radius behind the face, and the top is free if a standing capsule fits on it.
  - The visible capsule leans towards the wall of a wall run. `teleport()` straightens it.
- **`game/ui/debug_overlay.gd`.** New lines `MANTLE`, `WALL RUN` and `WALL JUMP`.
- **`game/levels/test_course.tscn`.** Checkpoints 6 to 9: `Ledge`, `WallRun`, `Zigzag`, `Final`. Each wall is a single block.
  - **Ledge:** 1.9 m high, 10 m after the old finish line.
  - **Wall run:** a 7 m gap along a wall at the left; the wall face is 0.4 m from the runner's side.
  - **Zigzag:** a 9 m void between two walls 4 m apart. The far side is 3 m higher and 12 m wide.
  - **Final:**
    - a low beam (underside 1.2 m above the floor, 3 m deep);
    - a 7 m gap along a wall at the right;
    - a 1.9 m ledge;
    - then the finish line, now at z = −243.9.
  - The walls have a new blue-grey material, and the `Final` checkpoint has a 12 m wide trigger.
- **`README.md`.**
  - Controls describes the automatic moves (decision 13).
  - The paragraph that describes the course and the tuning sentence follow the new code.
  - The roadmap row says the wall moves are in.

**Tests and helpers**
- **`tests/motor_body.gd`:** the new tuning values, a wall set by the test, a modelled ledge that stops the body, and `floor_height`.
- **`tests/pilot_intent_source.gd`.** The pilot learned four gestures:
  - It jumps at a ledge that would stop it within the current step, if a body lifted by `mantle_max_height` would pass over it.
  - On a wall, it jumps off when another wall stands across, within the distance a wall jump carries it.
  - After a wall jump, it pushes the way it flies.
  - It releases the jump when holding it would carry it past every floor and releasing it now would land it on one. Both paths are followed step by step with the tuning's gravities.
- **`tests/piloted_run.gd`:** new counters `steps_mantling`, `steps_wall_running`, `wall_jumps` and `steps_to_the_goal`.
- **`tests/course_test.gd`:** the four new checkpoints.
- **`tests/test_pilot.gd`:** `Track` gains `add_wall()`, and optional widths for `add_block()` and `add_goal()`.
- **Existing test setup adapted, assertions untouched** (by script: the only lines removed from `tests/` since `71e0499` are the renamed test and the roll test's step measure):
  - `test_the_same_intents_give_the_same_result` now also draws random walls, ledges and clearances, so that it can still visit every state, as its unchanged assertion requires. Its `_tuning()` gets the new values.

## Vérifié

**Gates on the last commit `480158c`, clean tree.** `just check` is green in 33.5 s:
- typecheck: 37 scripts, 0 errors;
- gdlint and gdformat: no problem, 37 files left unchanged;
- tests: 119 of 119 pass, 2803 asserts, 14.17 s;
- structure: 0 boundary, dead-file or mirror problem;
- builds: Windows exported and ran 60 frames headless; Linux built.

`just check` was green before each of the five commits.

**Timings (decision 20), same machine, one `just` command at a time**

| | Before (`71e0499`) | After (`480158c`) |
| --- | --- | --- |
| `just preflight` | 21.4 s | 24.7, 24.7, 25.2, 25.2 s |
| GUT time | 11.15 s (85 tests) | 14.2 s (119 tests) |
| `just check` | not timed | 30.1 s at the first commit, 33.5 s at the last |

That leaves about 5 s of margin under 30 s at rest; a busy machine took twice as long last round.

**Test first.**
- I wrote the motor in the same pass as the first mantle tests, so most core tests were seen green before being seen red. To prove they bite I ran deliberate breaks, each against the suite, with the file restored byte for byte. The scripts and outputs are in `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\breaks`.
- The debug display test was seen red for the right reason before its code.
- **The motor, 45 breaks:**
  - range ends, push rules (45° split), free top, mantle duration, exit speed, ignored presses, mantle while low or while on a wall;
  - refused wall and its reset on the ground, distance, height, tilt, clearance, start and stop speed, duration and its rounding, wall end, pushing away, speed kept, cap, gravity down and up;
  - wall-jump speeds, the speed kept along the wall, the jump cut, grace ±1 step, buffer at the wall, the `jumped_off_a_wall` flag;
  - floor speed in the air, the old landing rule, hard landing ending standing, not low through a hard landing, apex reset at the start or end of a wall run, wall run not counted as "in the air", a hard landing that costs nothing.
  - 43 were red at once. Two stayed green and made me add a case, after which both were seen red:

| Break that stayed green | What I added |
| ----------------------- | ------------ |
| The wall run steered like the air instead of keeping its speed | A runner pushing mostly into the wall keeps its speed along it (test 9) |
| A mantle is not a ground contact | A runner that fell from high onto a face, whose mantle ends a step before the floor is felt, stands with no hard landing (test 5) |

- **Player, pilot and course, 17 breaks:**
  - exclusion group, distance measured from the axis, no ledge observed, lean the wrong way;
  - pilot without its ledge rule, without the wall jump, steering to the goal after a wall jump, never releasing;
  - ledge as high as a jump, no wall along the gap, no right zigzag wall, no final wall.
  - 13 were red at once. Four stayed green:

| Break that stayed green | What I did |
| ----------------------- | ---------- |
| Every wall reported as tall | Test 25 also refuses a wall too short (real physics): now red |
| The ground always reported far below | Test 25 also refuses a wall beside a runner too close to the ground: now red |
| A teleport keeps the lean | Test 34 checks the capsule is upright one step after the return: now red |
| Every ledge top reported free | Still green. No scenario puts a blocked ledge in the real physics; a probe shows the observation works (no mantle). Reported |
| The pilot takes any hit of its path as a floor | Still green. No course or track distinguishes a wall hit from a floor in the release rule. Reported |

**Decision 10: tuning replays.** Each of the 16 new values at ×1.1 and ×0.9, one at a time, on copies in memory (nothing written), on the big drop and the four new sections: 160 runs. A run passes if the section is cleared with its move: a roll, a mantle, a wall run, at least two wall jumps, or slide + wall run + mantle in the final.
- **First pass, ledges at 2.0 m: 158 of 160.** `mantle_max_height` × 0.9 (1.98 m) failed on the Ledge and Final sections. The pilot only tries a ledge whose top is within the mantle range from its feet, and 2.0 > 1.98.
- **The smallest change:** both ledges lowered to 1.9 m, which sits between jump height × 1.1 (1.76 m, under which the pilot simply jumps onto it) and 1.98 m. Commit `3474b07`.
- **Second pass: 160 of 160.** Steps to the goal barely move:
  - big drop 185, wall run 145, zigzag 144 to 145 (always 3 wall jumps), final 275 to 278;
  - ledge 115 (mantle × 0.9) to 119 (mantle × 1.1).
  - Most values do not change these sections at ±10 %: the wall run ends where its wall ends, long before its 1.2 s.
- **The four guaranteed values on the ten sections** are covered by the committed tests (green).

**Probes in the real physics** (temporary scripts, not committed, in `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\probes`)
- **Mantle** (ledge section):
  - The pilot jumps 0.35 m before the face and touches it at feet 0.17 m.
  - 10 steps rising at 11 m/s against the face, then 11 steps forward at 4 m/s, feet exactly at the top.
  - Jolt does not report the floor while the vertical speed is zero, so the mantle ends FALLING and the runner lands 1 or 2 steps later (fall height 0).
  - Other cases:
    - A jump from standing at the foot of a 1.9 m ledge mantles.
    - At 13.5 m/s the runner leaves at 4 m/s: the momentum is lost.
    - A ledge whose top is covered 1 m above gives no mantle.
- **Wall run** (wall-run section):
  - It starts on the first air step over the void, rises as a jump to 1.6 m, then sinks at 6 m/s².
  - It lasts 47 steps (0.78 s) and ends where the wall ends; the runner lands 0.8 m lower.
  - The lean reaches 20° in 2 steps.
  - The capsule stays 0.4 m from the wall and never touches it.
- **Zigzag:**
  - 3 wall jumps, about 1.2 m gained per crossing, each crossing about 0.35 s.
  - Each wall is touched for one step, and the wall run starts 0.28 to 0.33 m from the wall rather than 0.6 m: the rays are perpendicular to the facing, which has turned towards the flight.
  - The first version of the release rule released the last wall jump, because it guessed the landing on the floor it jumped from, 3 m lower. I replaced it by following the path. The held jump now lands 1.15 m from the side edge, and the landing platform was widened to 12 m.
- **A wall made of two blocks end to end** gives two wall runs in a row, the second with a fresh duration, with one falling step between. This is the loophole decision 6 closes.
- **Section by section, from rest at each checkpoint:** 1761 steps (29.4 s). The pilot cannot run the whole course in one go: it keeps one direction and lands about 3 m to the side after the zigzag.

## Non vérifié

**Only the owner can judge, controller in hand**
- **Mantle:**
  - The trigger on contact with the face.
  - The climb: 0.17 s of rise at about 11 m/s, then 0.18 s over the top.
  - Setting off at 4 m/s whatever the speed it came with.
  - The ignored jump and slide.
  - The 1.9 m ledges.
- **Wall run:**
  - The automatic start.
  - The jump that keeps rising along the wall, then a 6 m/s² sink.
  - No steering at all on the wall.
  - Pushing more than 45° away to leave the wall.
  - The 1.2 s limit, which never shows on the course.
  - The 0.6 m reach.
- **Wall jump:**
  - 7 m/s away and 9.5 m/s up.
  - Pressing just before the wall, which is the ordinary gesture in the zigzag.
  - The 0.10 s grace.
  - The jump cut.
  - The climb of the zigzag.
  - Air control fighting the wall jump if the stick is held forward: the pilot avoids it by pushing the way it flies.
- **The capsule lean:** 20° (`wall_run_lean`), at the turn speed.
- **The camera along walls and in the zigzag.** The spring arm was never looked at.
- **The length of the whole course** (Question 1).
- **Readability:** the blue-grey walls, the 3 m higher far side of the zigzag, the final beam.

**Not run here**
- **Linux CI.** Nothing was pushed.
- **A window, a keyboard, a gamepad**, and frame rates below 60.
- **The whole course in one go:** no committed test (decision 8), and the pilot cannot do it.
- **The player's "free top" measure of a ledge in a committed test.** Only probed, and the core rule is tested.
- **Uphill or tilted ledges, and walls that are not boxes.** For a trimesh, the bounding box of the shape is not the wall's height.

## Écarts

1. **Five commits instead of one, and `AGENTS.md` not edited.** As the launch asked.
2. **New tuning value `wall_run_lean` = 20°.** Decision 7 has no value, and `AGENTS.md` puts every feel value in the tuning resource.
3. **Course ledges at 1.9 m, not "in the range" anywhere.** Chosen for decision 10 (see Vérifié).
4. **Assertions beyond their scenario,** each closing a hole a break showed or a decision without a scenario:
   - test 1: a ledge below the range is not climbed while rising;
   - test 5: a mantle is a ground contact (decision 15);
   - test 6: no wall run along a wall too far, too short, leaning 30°, too close to the ground, or without pushing along it;
   - test 9: slowed under the stop speed, the runner leaves the wall (decision 3);
   - test 13: a released wall jump rises less (decision 4);
   - test 25: a wall too short, or too close to the ground;
   - test 28: the capsule leans to the wall and straightens (decision 7);
   - test 34: upright at once after the return.
   - There is no test without a scenario.
5. **The debug display also shows `MANTLE`.** Decision 12 lists two durations; the scenario says "les durées qui lui sont liées" for each state.
6. **README:**
   - the course paragraph, the tuning sentence and the roadmap row also changed, as descriptions of what now exists;
   - the roadmap row says the wall moves "are in" before the merge, as last round.

**Places where the code decided what the spec leaves open**
- **Starting a wall run** keeps the vertical speed:
  - rising, the runner follows the jump's rise gravity, so no wall run climbs;
  - falling, it uses the 6 m/s² of the wall run, even from a fast fall.
- **During a wall run:**
  - the horizontal speed is projected onto the wall and kept exactly: no steering, no gain, no loss;
  - only pushing away does anything;
  - the start speed is the horizontal speed before that projection.
- **"Along", "towards" and "away"** are decided by a 45° split between the push's component along the surface and its component across it. The same rule is used for the start, the detach and the mantle. A stick at rest keeps the wall run going.
- **The wall-jump grace:**
  - It opens on every detach except the ground and a wall jump.
  - It counts from the first step off the wall: 6 steps.
  - It is full (0.10 s) while the runner is on the wall.
- **The refused wall** is the wall of the last wall run. It is cleared by the ground and by a mantle (a mantle is a ground contact, decision 15).
- **A ledge in front and a wall beside both qualify:** the mantle wins.
- **Mantle:**
  - The rise lasts the duration minus the time to cross one body width at the exit speed.
  - The exit speed replaces any momentum.
  - Jump and slide presses made during it are forgotten, not delayed.
  - It ends GROUNDED if the floor is felt, FALLING otherwise.
- **Decision 18:**
  - The floor speed also applies in a roll and a hard landing kept low by a ceiling.
  - A hard landing that ends without room continues as a slide; a small fall under a ceiling still continues as a slide.
- **What the player observes:**
  - The ledge comes from last step's contacts, in front by the same 45° rule.
  - The top is probed from `mantle_max_height` + standing height above the feet, down to the feet.
  - The ground is probed as deep as `wall_run_min_height`.
  - A fixed wall means a `StaticBody3D`.
- **Pilot:**
  - It only tries ledges within the mantle range from its feet.
  - It wall-jumps at the first step of every wall run when a wall stands across.
  - Its release rule follows the path step by step, and treats the first hit as a landing only if it is a floor (`floor_max_angle`).
- **Course geometry:** as listed under Fait; the zigzag climbs, its far side 3 m higher.

## Questions

1. **The length of the course (decision 8).**
   - The pilot clears the ten sections in about 29 s from rest at each checkpoint, so a clean continuous run is about 27 s for a perfect runner.
   - The spec says a clean run is of the order of 45 to 60 s.
   - Reaching it means about 150 m more, as straights or as more elements in the final combination.
   - Each extra second of the longest section adds about 0.1 s to every replay test, so `just preflight` would grow by roughly 1 to 3 s, close to the 30 s limit of decision 20.
   - Should the course be lengthened, and how?
2. **`test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear`** (unchanged, green). Its wall is 2 × jump height = 3.2 m. A player can now clear it: jump to 1.6 m, then a mantle of up to 2.2 m, which reaches 3.8 m. The test stays true only because the pilot does not try ledges beyond the mantle range from its feet. Keep it as it is, rename it, or re-size its wall (above jump height + mantle height)? I was not allowed to change it.
3. **Momentum through a mantle.** It is lost: the runner always leaves at 4 m/s. Is that the intent?
4. **The two-block wall loophole (decision 6)** is a rule for whoever builds a level, and no gate checks it. Write it in `AGENTS.md` (see below)?
5. **Two green breaks** (the free-top observation of a ledge, the pilot's floor test in its landing guess): add scenarios, or accept?
6. **`AGENTS.md`.** Proposed text, to apply or reword.

   Current:
   ```
     core/             runner motor, intents, race state, and the tuning resource
     player/           the runner's scene: body, camera rig, intents read from the inputs
   ```
   ```
   tests/              headless tests, one script per subject: test_<subject>.gd; the other
                       scripts are their helpers (written sequences of intents, test pilot)
   ```
   Proposed:
   ```
     core/             runner motor, intents, the facts the player observes, race state,
                       and the tuning resource
     player/           the runner's scene: body, camera rig, intents read from the inputs,
                       and what the body observes around it (floor, walls, ledges)
   ```
   ```
   tests/              headless tests, one script per subject: test_<subject>.gd; the other
                       scripts are their helpers (written sequences of intents, test pilot,
                       a runner without a scene, the bases of the replay and course tests)
   ```
   A possible rule for "Working rules", from decision 6, which is an owner's call: "Every wall of a level is a single block (one physics object); a wall that must not be run along goes in the `no_wall_run` group."

---

- **Branch:** `movement-walls`, in `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ac2db3e8c48bad46a`
- **Final commit:** `480158c`
- **Commits, oldest first:** `4f2a98c`, `13b5fc2`, `d553bfd`, `3474b07`, `480158c`
`````

### Inspecteur, première inspection (sur 480158c)

`````markdown
# Inspection : `movement-walls` (71e0499..480158c) contre `docs/specs/movement-walls.md`

## 1. Verdict

**À corriger.** Un constat bloquant : sur le pas d'un wall-jump, la vitesse horizontale dépasse le plafond absolu. La correction tient en une ligne, plus une assertion. Les quatre constats conseillés ne bloquent pas la fusion.

Ce que j'ai lancé, en lecture seule dans le worktree :
- `just typecheck`, `just lint`, `just test` (119/119) et `just deadcode` : tous verts.
- `just preflight` deux fois : 24,7 s et 24,8 s, donc sous les 30 s de la décision 20.
- `git status` est propre après les lancements.

Ce que j'ai lancé sur une copie dans le dossier temporaire :
- **Les cinq nouvelles sections** (BigDrop, Ledge, WallRun, Zigzag, Final), rejouées par le pilote avec 22 réglages changés de +10 % puis de −10 %, un seul à la fois. Il y a les 16 nouvelles valeurs (lean compris), plus `capsule_radius`, `air_acceleration`, `max_fall_speed`, `jump_release_velocity_ratio`, `turn_speed` et `ground_acceleration`. Résultat : 220 courses sur 220 franchies.
- **Les fichiers `walls` et `pilot`**, rejoués avec 13 réglages à ±10 % : tous verts.
- **La suite entière**, rejouée avec 8 variantes (`top_speed`, `mantle_duration`, `wall_run_duration`, `capsule_radius`, `roll_fall_height`) : toute verte.
- **Des sondes de croisements en physique Jolt** : rebord fait de deux blocs avec un joint, plafond bas au-dessus d'un rebord, wall-run qui finit contre une réception plus haute, zigzag sans wall-jump.
- **Des sondes `core`** : diagonale du clavier, approche raide du mur, relâcher le saut pendant un wall-run en montée, wall-jump au plafond de vitesse.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
|---|---------|---------------|-------|---------|-------------|
| 1 | bloquant | `game/core/runner_motor.gd:386-388` et `:496-499` | Spec, décision 14 : « le plafond absolu de vitesse horizontale s'applique toujours ». `movement-ground.md`, décision 11 et scénario « La vitesse horizontale a un plafond absolu ». | `_wall_jump()` ajoute `wall_jump_away_speed` après `_cap_horizontal_speed()`. Le pas du saut dépasse donc le plafond. Ma sonde `core` donne, pour une vitesse le long du mur de 22 m/s : **23,09 m/s** sur le pas du saut, puis 22,0 au pas suivant. Pour 21,5 m/s, elle donne 22,61. Aucun test ne couvre ce cas : `faster_than_the_cap` ne teste que le wall-run. | Appeler `_cap_horizontal_speed()` à la fin de `_wall_jump()`. Ajouter à `test_momentum_above_top_speed_is_kept_in_a_wall_run` un wall-jump depuis `faster_than_the_cap`, avec l'assertion `horizontal_speed() <= max_horizontal_speed`. |
| 2 | conseillé | `game/core/runner_motor.gd:321-322` et `tests/test_runner_mantle.gd:39` | Spec, scénario « Le coureur se hisse sur un rebord à sa portée » : « se retrouve debout sur le rebord avec la vitesse de sortie ». | En Jolt, un mantle ne finit jamais en `GROUNDED`. Sa trace donne `41:MANTLING`, puis `61:FALLING@1.900`, puis `63:GROUNDED@1.901`, avec ou sans joint. Pendant ces deux pas, le pas de crossing laisse `velocity.y = 0` et Jolt ne signale pas le sol. Le coureur passe donc en `FALLING` et se reçoit sur le rebord à environ 4,47 m/s au lieu de 4. Le test `core` affirme `GROUNDED` parce que `MotorBody` signale le sol quand `vy <= 0`, ce que Jolt ne fait pas. Le cas « fallen » du dernier commit couvre la conséquence sur la hauteur de chute, pas l'état. | Au dernier pas du mantle, donner une petite vitesse vers le bas (par exemple `-fall_gravity * delta`) pour que le sol soit senti. Sinon, consigner ce comportement comme choix accepté. Dans les deux cas, ajouter à `test_the_ledge_can_be_cleared` une assertion sur l'état réel au pas qui suit le mantle. |
| 3 | conseillé | `game/core/runner_motor.gd:562-575` | AGENTS.md, Architecture, règles de simulation : « Every tuning value of the feel (speeds, gravity, tolerance windows) lives in one single tuning resource ». Je ne suis pas sûr que cette règle couvre ce seuil. | Le partage entre « le long du mur » et « vers le mur » est un 45° strict, écrit dans le code. Au clavier, avant+gauche donne exactement 45° une fois normalisé par `Input.get_vector`. Ma sonde donne : 44° → `WALL_RUNNING` ; 45°, 46° et W+A exact → `FALLING`. Caméra dans l'axe du mur, tenir W et la touche vers le mur ne lance pas de wall-run. Le même seuil décide le mantle. | Choix pour Jimmy. Soit compter l'égalité comme « le long du mur » (`>=`), soit sortir l'angle dans la ressource de réglage. |
| 4 | conseillé | `game/core/runner_motor.gd:334` et `:351-357` | Spec, décisions 3 et 5 : la lettre est respectée (« assez de vitesse horizontale »). | Le départ compare la vitesse horizontale totale, mais le premier pas retire la composante vers le mur. Une approche raide donne alors un wall-run d'un seul pas, et ce pas suffit à refuser le mur. Ma sonde, à 9 m/s avec un cap à 65° vers le mur : `WALL_RUNNING(3.80)`, puis `FALLING`, et le mur est refusé jusqu'au sol. | Au départ, comparer `_along_the_wall(velocity)` à `wall_run_stop_speed` (ou à la vitesse de départ). Sinon, garder et consigner ce choix. |
| 5 | conseillé | `game/core/runner_motor.gd:26` | AGENTS.md, Ports and adapters : « No dead code: a script, a scene or a resource appears with its first consumer ». Je ne suis pas sûr que la règle vise un membre public. | `jumped_off_a_wall` n'est lu que par `tests/` (`piloted_run.gd:139`, `pilot_intent_source.gd:50`, les tests). Aucun code du jeu ne le lit. | Le garder si un retour son ou visuel arrive à l'étape 2. Sinon, que les tests le déduisent de l'état et de la vitesse. |

## 3. Couverture de la spec

Les 35 scénarios ont tous un test du même nom. La décision 21 est respectée : `test_the_big_drop_leads_to_the_finish` devient `test_the_big_drop_can_be_cleared` avec le même corps, et la roulade compte jusqu'au checkpoint du rebord (`steps_to_the_goal`). Aucune autre assertion n'a été retirée, et il n'y a ni `pending` ni test ignoré.

| Scénario | Test |
|---|---|
| Le coureur se hisse sur un rebord à sa portée | `test_the_runner_mantles_onto_a_ledge_within_reach` (constat 2) |
| Un rebord trop haut n'est pas franchi | `test_a_ledge_too_high_is_not_climbed` |
| Pas de mantle sans pousser vers le rebord | `test_no_mantle_without_pushing_towards_the_ledge` |
| Pas de mantle si le dessus est encombré | `test_no_mantle_if_the_top_is_blocked` (en `core` seulement ; ma sonde Jolt sous une poutre confirme) |
| Le mantle va jusqu'au bout | `test_the_mantle_goes_to_the_end` |
| Le wall-run démarre tout seul le long d'un mur | `test_the_wall_run_starts_by_itself_along_a_wall` |
| Pas de wall-run sans vitesse | `test_no_wall_run_without_speed` |
| Le wall-run ralentit la chute | `test_the_wall_run_slows_the_fall` |
| L'élan au-dessus de la vitesse de pointe se garde en wall-run | `test_momentum_above_top_speed_is_kept_in_a_wall_run` (constat 1) |
| Le wall-run s'arrête au bout de sa durée | `test_the_wall_run_stops_at_the_end_of_its_duration` |
| Le wall-run s'arrête quand le mur s'arrête | `test_the_wall_run_stops_when_the_wall_stops` |
| Pousser à l'opposé du mur fait décrocher | `test_pushing_away_from_the_wall_detaches` |
| Le wall-jump repousse à l'opposé du mur | `test_the_wall_jump_pushes_away_from_the_wall` |
| Le wall-jump reste possible juste après avoir décroché | `test_the_wall_jump_remains_possible_just_after_detaching` |
| Un saut demandé juste avant le mur donne un wall-jump | `test_a_jump_requested_just_before_the_wall_gives_a_wall_jump` |
| Le même mur est refusé deux fois de suite | `test_the_same_wall_is_refused_twice_in_a_row` |
| Un autre mur est accepté | `test_another_wall_is_accepted` |
| Toucher le sol autorise de nouveau le même mur | `test_touching_the_ground_allows_the_same_wall_again` |
| Pas de wall-run ni de mantle en étant baissé | `test_no_wall_run_or_mantle_while_low` |
| Pas de mantle pendant un wall-run | `test_no_mantle_during_a_wall_run` (confirmé en Jolt par ma sonde « réception plus haute ») |
| La hauteur de chute compte depuis un wall-run | `test_the_fall_height_counts_from_a_wall_run` |
| Le coureur ne reste pas coincé au-dessus d'une fente sous un plafond bas | `test_the_runner_does_not_get_stuck_over_a_crack_under_a_low_ceiling` |
| Une grande chute reçue sous un plafond bas sans roulade est lourde | `test_a_big_fall_landed_under_a_low_ceiling_without_a_roll_is_hard` |
| Un mur exclu ne donne pas de wall-run | `test_an_excluded_wall_gives_no_wall_run` |
| Un mur trop incliné ne donne pas de wall-run | `test_a_wall_too_tilted_gives_no_wall_run` |
| La grande chute se franchit | `test_the_big_drop_can_be_cleared` |
| Le rebord se franchit | `test_the_ledge_can_be_cleared` |
| Le vide se franchit en wall-run | `test_the_gap_can_be_cleared_by_wall_running` |
| Le zigzag se franchit en wall-jumps | `test_the_zigzag_can_be_cleared_by_wall_jumps` (ma sonde : sans wall-jump, 7 sauts sur 7 retombent, donc la section force bien les wall-jumps) |
| L'enchaînement final mène à l'arrivée | `test_the_final_combination_leads_to_the_finish` |
| Le pilote franchit des murs qu'il ne connaît pas | `test_the_pilot_clears_walls_it_does_not_know` |
| Le pilote ne court pas sur un mur sans raison | `test_the_pilot_does_not_wall_run_without_a_reason` |
| Le pilote relâche le saut pour ne pas dépasser sa réception | `test_the_pilot_releases_the_jump_so_as_not_to_overshoot_its_landing` |
| Le retour au checkpoint fonctionne depuis le mantle et le wall-run | `test_returning_to_the_checkpoint_works_from_the_mantle_and_the_wall_run` |
| L'affichage de debug montre les états des murs | `test_the_debug_display_shows_the_wall_states` |
| Les quatre tests à ±10 % sur les dix sections (décision 10) | `test_the_sections_can_be_cleared_with_*_changed_by_10_percent` : la boucle porte sur `CHECKPOINT_NAMES.size()`, soit 10 sections |

Autres vérifications sans constat :
- **Décisions 1 à 21** : respectées, sauf la décision 14 sur le pas du wall-jump (constat 1).
- **Décision 6** : chacun des cinq murs du parcours est un `StaticBody3D` d'une seule forme.
- **Décision 19** : les trois durées passent par `_window_steps`, qui arrondit au pas le plus proche. Seul l'arrondi du wall-run est testé (1,21 s donne 73 pas).
- **Décision 20** : 24,7 s.
- **Couches** : aucune règle de jeu ne vit dans `player/` ou `levels/`. Les seuils de distance, d'inclinaison, de hauteur et de vitesse sont décidés dans `core`.
- **Simulation** : toutes les entrées passent par des intentions, tout avance sur `_physics_process`, et il n'y a aucun chargement par chemin construit.
- **Choix acceptés de `movement-ground.md`** : toujours vrais, sauf les deux que la décision 18 remplace.
- **Documentation** : la section Controls du README décrit les mouvements automatiques. La section Layout d'`AGENTS.md` reste exacte : aucun dossier ni rôle nouveau.
- **Textes visibles** : les libellés du debug sont en anglais et vivent dans `game/ui/`.
- **Assets** : aucun fichier dans `assets/`.

## 4. Choix faits par le code là où la spec se tait

Chacun se juge manette en main et peut être accepté ou rouvert.

**Mantle**
1. **Détection du rebord** : le mantle ne voit un rebord que si le corps a touché sa face au pas précédent. Il n'y a pas de portée à distance. Il faut aussi que la face soit plus devant que sur le côté du corps visible (45°) et que le stick pousse plus vers elle que le long d'elle (45°). Ni la vitesse ni le sens vertical n'entrent en compte : le mantle peut partir pendant la montée d'un saut.
2. **Mouvement du mantle** : il monte le long de la face pendant (durée − traversée) pas, puis traverse une largeur de corps (2 × `capsule_radius`) à la vitesse de sortie. Avec les valeurs du `.tres`, cela fait 10 pas de montée et 11 de traversée. La vitesse horizontale vaut la vitesse de sortie pendant tout le mantle : l'élan d'arrivée est perdu. En Jolt, le mantle finit par deux pas en `FALLING` (constat 2).
3. **Le mantle vaut contact avec le sol à chaque pas** : la hauteur de chute repart du rebord, le mur refusé est oublié, la tolérance de wall-jump se ferme, et le saut est consommé (`_jump_spent`).
4. **Rebord trop haut pour la sonde** : un rebord dont le dessus dépasse ce que la sonde atteint (`mantle_max_height + capsule_height` au-dessus des pieds) est déclaré « non libre ».

**Murs**
5. **Ce qui compte comme mur** : tout `StaticBody3D` hors du groupe `no_wall_run`. Cela inclut les `AnimatableBody3D`, une sous-classe : une future plateforme mobile serait un mur. L'identité est celle du corps, donc toutes les formes d'un même corps forment un seul mur.
6. **Hauteur d'un mur** : c'est la hauteur de l'AABB de la forme touchée, mesurée par `get_debug_mesh()`, partie enterrée comprise. Le bloc `Ledge` compte ainsi 3 m alors qu'il ne dépasse que de 1,9 m.
7. **Sonde des murs** : un rayon droit à gauche et un à droite du corps visible, à mi-hauteur. Le mur le plus proche l'emporte.

**Wall-run**
8. **Seuils de départ** : la vitesse de départ porte sur la vitesse horizontale totale (constat 4). Le partage « le long / vers » est un 45° strict (constat 3). La hauteur au-dessus du sol n'est vérifiée qu'au départ : un wall-run peut se poursuivre jusqu'au sol.
9. **Le stick en wall-run** : il ne fait ni accélérer ni freiner le long du mur. Seul pousser à plus de 45° vers l'extérieur fait décrocher. Pousser vers le mur ne fait rien.
10. **Wall-run commencé en montée** : il garde la gravité de montée du saut. Relâcher le saut n'écourte alors plus la montée, que le saut soit parti du sol ou non. Ma sonde donne la même apogée bouton tenu et bouton relâché.
11. **Tolérance après décrochage** : elle compte le pas du décrochage comme le premier de ses 6 pas. Elle vaut quelle que soit la raison du décrochage (durée, fin du mur, lenteur, poussée vers l'extérieur), même si le mur n'existe plus.
12. **Mur refusé** : seul le dernier mur est refusé. Courir sur A, puis B, puis de nouveau A est permis.
13. **Inclinaison de la capsule** : 20° (`wall_run_lean`, une valeur absente du tableau de la spec), à la vitesse `turn_speed`, ce qui la rend presque instantanée.

**Wall-jump**
14. **Vitesse du saut** : la vitesse verticale remplace celle du moment, la vitesse vers l'extérieur s'ajoute à la vitesse le long du mur, et la tolérance de la décision 16 est le `jump_buffer_time` de la base (0,12 s).

**Parcours et pilote**
15. **Matériau des murs** : les murs prévus pour le wall-run ont un matériau bleu-gris, ce que la spec ne demandait pas.
16. **Pilote** : après un wall-jump, il pousse dans le sens de son vol. Il ne saute d'un mur que si un autre mur se trouve en face, dans la portée calculée depuis le réglage.

## 5. Non vérifiable ici

À juger par Jimmy, manette en main, puis au clavier et à la souris :
- **Mantle** : la durée de 0,35 s, la sortie à 4 m/s qui coupe l'élan, le moment où il se déclenche (il faut toucher la face), et les deux pas `FALLING` visibles au debug après chaque mantle.
- **Wall-run** :
  - le départ automatique et la diagonale du clavier (W + touche vers le mur, constat 3) ;
  - la gravité de 6 m/s² et la durée de 1,2 s ;
  - le fait que le stick ne règle pas la vitesse le long du mur ;
  - l'inclinaison de 20°, quasi instantanée ;
  - la caméra pendant le wall-run et le wall-jump, qui n'a pas changé.
- **Wall-jump** : la force (7 et 9,5 m/s), la tolérance de 0,10 s après décrochage, l'appui en avance avant le mur, et le rythme du zigzag (3 wall-jumps chez le pilote).
- **Parcours** : la durée d'un passage propre, de l'ordre de 45 à 60 s (décision 8), et la lisibilité du bleu-gris des murs.
- **Build de release** : la hauteur des murs passe par `Shape3D.get_debug_mesh()` au moment du jeu. Le démarrage headless de `just build` ne fait aucun wall-run, et je n'ai pas vérifié ce chemin dans une build de release.
`````

### Développeur, passe 2 (commit 92fa4e6)

`````markdown
# Developer report, correction pass: `docs/specs/movement-walls.md` (amended, 41 scenarios)

All eight fixes are in. The 41 scenarios have their tests (the 6 new ones were each seen red first) and `just check` is green on the last commit (125 tests). The spec is back to 🟢. Nothing was pushed or merged; `AGENTS.md` was not touched.

The owner's bug is reproduced and fixed. Against a face, the visible body turned along it, by more than the 45° limit in the reproduction, and the player then stopped reporting the ledge. The ledge is now the face the push goes most into.

One thing for an owner, under Questions:
- **A thin cover can still be climbed.** A cover over a ledge whose own top is within reach of a jump plus a mantle can still be mantled onto. My first test hit this by chance; the scenario's test uses a thicker cover.

- **Worktree:** `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ac2db3e8c48bad46a`
- **Branch:** `movement-walls`, on top of the coordinator's `3811006` and `8646fc3`

| Commit | Content |
| ------ | ------- |
| `acf6feb` | core, player, tests: the corrections of the first inspection and of the owner's play |
| `92fa4e6` | docs: movement-walls implemented again, its 41 scenarios green |

## Fait

| # | Fix | Scenario test | File |
| - | --- | ------------- | ---- |
| 1 | `_wall_jump()` caps its own horizontal speed | `test_the_wall_jump_does_not_exceed_the_absolute_cap` | `tests/test_runner_wall_run.gd` |
| 2 | Decision 22: the ledge comes from the touched face the push goes most into; the wall rays are aside from the motion, or from the push when the body hardly moves; `_facing()` only serves the lean | `test_a_ledge_approached_at_an_angle_gives_a_mantle` | `tests/test_player_ledges.gd` (new) |
| 3 | The last stretch of the mantle presses the runner onto the top with the weight of one step (`-fall_gravity * delta`) | `test_the_mantle_ends_standing_on_the_ledge` (real physics) | `tests/test_player_ledges.gd` |
| 4 | Split angle `push_split_angle` = 45° (new group Push), on the limit counts | `test_the_keyboard_diagonal_starts_a_wall_run` | `tests/test_runner_wall_run.gd` |
| 5 | Start speed counted along the wall | `test_a_too_steep_approach_does_not_spoil_the_wall` | `tests/test_runner_wall_run.gd` |
| 6 | The free top of a ledge, in the real physics | `test_a_covered_ledge_gives_no_mantle` | `tests/test_player_ledges.gd` |
| 7 | Re-sized wall: `jump_height + mantle_max_height + capsule_height`; assertions unchanged | `test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear` | `tests/test_pilot.gd` |
| 8 | `RunnerMotor.jumped_off_a_wall` removed (see below) | existing tests, adapted | several |

**Fix 4 in detail.** `_push_angle()` gives the angle of the push off the surface.
- Along (wall run): |angle| ≤ the limit.
- Into (mantle): at least the limit towards the face.
- Away (leaving the wall): strictly beyond the limit.
- "On the limit" uses `is_equal_approx`, so forward + the key towards the wall, normalised, counts.

**Fix 8 in detail.**
- The pilot marks its own wall jumps: it pressed jump along a wall.
- `PilotedRun.wall_jumps` counts a press of the jump made while the runner ran along a wall, followed by a rise.
- The wall-run tests use `_jumped_off()`: rising at exactly `wall_jump_up_speed`, away from the wall.
- The respawn test detects a rise right after a wall run.

**Assertions added inside existing tests,** each for decision 3:
- a push exactly on the limit towards a ledge mantles (test 3, mantle);
- a push exactly on the limit away from the wall does not detach (test 12).

**One test strengthened after a break stayed green** (see Vérifié): in `tests/test_player_walls.gd` the visible body now looks at the wall at launch, and the plain wall must give a wall run from the very first step.

**README Controls:** the keyboard diagonal, and the steep approach that leaves the wall free.

## Vérifié

**Gates.** `just check` is green on `acf6feb` (35.0 s) and on `92fa4e6`:
- typecheck: 38 scripts, 0 errors;
- lint: 0 findings, 38 files left unchanged;
- tests: 125 of 125 pass, 2828 asserts;
- structure: 0 problems;
- builds: Windows exported and ran 60 frames headless; Linux built.

`just preflight`: 25.2, 25.3 and 25.6 s, against 24.7 s before this pass and 21.4 s before the round.

**Red before the fix.**
- The three real-physics tests were red on the previous code:
  - at an angle, the visible body turned more than 45° along the face and no mantle came: the owner's bug, reproduced;
  - the mantle ended FALLING;
  - the covered ledge was climbed.
- The four core tests were red:
  - 23.087 m/s on the wall-jump step;
  - the diagonal did not start a wall run;
  - the steep approach gave a wall run at once;
  - the push on the limit gave no mantle.

**Deliberate breaks** against the whole suite, each restored byte for byte (`C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\breaks`). Of 12 breaks, 9 were red at once:
- the wall jump without its cap;
- the limit excluded;
- the split fixed at 45°;
- detaching on the limit;
- the steep approach judged on total speed;
- the mantle never pressed onto the top;
- the ledge taken from the visible body;
- every ledge top free (the green break of the last pass, now red);
- the pilot not letting the wall jump carry it.

The three that stayed green changed the code or a test:

| Break that stayed green | What I did |
| ----------------------- | ---------- |
| Press during the whole last stretch, not only once the body is past the face | Kept the simpler rule: the progress tracking was not needed, in Jolt or in the core |
| Probe the top from high again (my first fix had lowered it to the mantle range) | Reverted to the previous probe, the one the accepted choices describe: the lower start fails the same corner case (Questions) |
| Wall rays from the visible body | The wall test turns the visible body towards the wall and demands a wall run from step one: now red |

**Decision 10.** All 17 new values at ±10 %, the split angle included, one at a time, on copies in memory, on the big drop and the four wall sections: 170 runs, 170 pass.
- `push_split_angle`, `mantle_exit_speed`, `wall_run_start_speed` and `wall_jump_away_speed` keep the same counts: goal steps 185, 117 to 118, 145, 144 to 145, 276 to 277.
- The moves do not change: mantle 20 steps, wall run 47 steps, 3 wall jumps, roll 30 steps.

## Non vérifié

**Only the owner can judge, controller in hand**
- The angled mantle that was refused: please replay the case he saw.
- The keyboard diagonal along a wall.
- A steep approach that now simply bounces off the wall.
- The mantle ending standing: this probe saw no vertical jolt, but nobody has watched it on screen.
- The 45° split on a stick.

**Not run here**
- Linux CI (nothing pushed).
- A window, a keyboard, a gamepad.
- The whole course in one go.

## Écarts

1. **The cap is applied inside `_wall_jump()`, not at the end of the step.** Moving the cap to the end of `_move` turned `test_the_horizontal_speed_has_an_absolute_cap` red, at 22.08 m/s: a slide's downhill vertical speed is derived from the horizontal speed before the cap. The wall jump is the only move that adds horizontal speed after the cap.
2. **The thicker cover in the covered-ledge test** (thickness = two standing heights). With my first slab, the cover's own top sat exactly at jump height + mantle range (3.8 m), and the runner mantled onto it through the gap at the top of its jump. The scenario's low ceiling is the thick cover; the corner case remains (Questions).
3. **The "towards" side of the split, for a mantle,** is read as "at least the split angle away from the face plane". It is one angle for all three sides, as decision 3 says, and identical to today's behaviour at 45°.
4. **No ledge is reported without a push.** The motor would refuse the mantle without one anyway, and there is no visible body to fall back on.
5. **The wall rays come from the motion,** or from the push when the body hardly moves; with neither, no wall is reported.
6. **`PilotedRun.wall_jumps` counts the pilot's own wall jumps** only: a press made along a wall, followed by a rise. The buffered wall jump of decision 16 is not counted; the pilot never makes one.
7. **The re-sized wall height formula** (jump + mantle + standing height) is mine.

## Questions

1. **The thin-cover corner case.** A cover over a ledge, whose own top lies within jump height + mantle range of the floor, can be mantled onto through the gap under it. Both top probes tried fail it; a fix needs a probe that finds the top of the touched face itself. Accept it as a level-building limit, or open a scenario for it?
2. **Should the accepted choice "Rebord plus haut que la sonde" be kept as written?** The probe is unchanged from the version it describes, so it still is; I only list it in case my first fix is preferred.

---

- **Branch:** `movement-walls`, in `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ac2db3e8c48bad46a`
- **Final commit:** `92fa4e673131c9d03ba2b8bf35406340ed0a9578`
- **Commits of this pass:** `acf6feb`, `92fa4e6` (on top of `3811006`, `8646fc3`)
`````

### Inspecteur, seconde inspection (sur 2841779)

`````markdown
# Inspection de `movement-walls` (71e0499..2841779), deuxième tour

## 1. Verdict

**Conforme.** Rien ne bloque la fusion. Il y a quatre constats conseillés. Deux d'entre eux touchent la décision 3 dans la vraie physique et demandent un arbitrage de Jimmy plutôt qu'une correction du développeur.

Ce que j'ai lancé : `just preflight` dans le worktree passe (125 tests sur 125, 2828 assertions, 25,2 s au total dont 14,8 s de tests ; deadcode à 0 problème ; arbre de travail resté propre). J'ai écrit des sondes Jolt sur une copie hors dépôt et fait un balayage du réglage : 15 valeurs nouvelles × 0,9 et × 1,1, sur `test_course*`, `test_player*` et `test_pilot`.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
|---|---------|---------------|-------|---------|-------------|
| 1 | conseillé | `game/core/runner_motor.gd:596-601`, `game/core/movement_tuning.tres:30`, `README.md:98` | Décision 3 (amendement : « la diagonale du clavier lance un wall-run ») | La limite est inclusive à 1e-5 rad près. La diagonale ne lance donc un wall-run que si la caméra libre est exactement parallèle au mur. Je l'ai sondé dans Jolt avec un mur abordé à 20° et une poussée avant + vers le mur. Caméra à 0°, −1° ou −3° : wall-run de 31 pas. Caméra à +1° ou +3° : aucun wall-run, le coureur glisse 21 pas contre le mur. Dans le zigzag du parcours, avec des diagonales vers le mur suivant : à 0°, 3 wall-jumps et le checkpoint Final est atteint ; à ±1°, 1 ou 2 wall-runs puis chute, Final non atteint (un mur sur deux tombe du côté « vers »). Le README promet la diagonale sans cette réserve. | Faire trancher Jimmy, par un amendement de spec. Mettre `push_split_angle` à 49,5 répare le wall-run mais casse « une poussée à la limite vers un rebord lance un mantle ». Il faut donc soit une bande de tolérance autour de la limite comptée pour les deux mouvements, soit des angles séparés pour le démarrage et le décrochage. |
| 2 | conseillé | `game/player/player.gd:130-160` (mur vu à distance) contre `:178-211` (rebord vu seulement au contact) ; ordre de `runner_motor.gd:274-277` | Décision 3 (« une poussée à la limite vers un rebord lance un mantle ») ; scénario « Un rebord abordé de biais donne un mantle » | Le mur se repère par rayon jusqu'à 0,6 m, le rebord seulement au contact. Sur une face assez haute pour être un mur, le wall-run démarre donc avant que le rebord existe dans les constats. Le « rebord avant mur » du moteur ne joue alors pas. Sonde : élan à 9 m/s, poussée exactement à 45° vers la face. Mantle à 1,9, 2,5 et 3,0 m ; wall-run le long de la face à 3,5 m (à portée : 1,6 + 2,2 = 3,8 m), sans mantle, retour au sol. De 0° à 44°, toutes les hauteurs de 1,9 à 3,7 m donnent un mantle. | À trancher avec le constat 1. Sinon, ajouter aux « Choix acceptés » que, sur la limite exacte, une face assez haute pour être un mur donne le wall-run. |
| 3 | conseillé | `tests/test_player_ledges.gd:100` et `:107` | « Working rules » / exception de réglage d'`AGENTS.md` (une modification de valeurs seules passe sur une CI verte) | Le test lit `push_split_angle` comme un angle mesuré depuis la normale de la face (`aslant = split × 0,9`). Le moteur le mesure depuis la surface (`_push_angle`, `_pushes_into`). Les deux conventions ne coïncident qu'à 45°. Avec `push_split_angle = 49,5` (+10 %), la poussée du test vaut 44,55° depuis la normale, soit 45,45° depuis la surface, sous la limite. Le test échoue (« and yet the runner mantled ») alors que le moteur fait ce qui est réglé. Le second contrôle, ligne 107, mélange aussi les deux conventions. | Prendre `aslant = deg_to_rad(90 - push_split_angle) * 0.9` et comparer `widest_look_aside` à `90 - push_split_angle`. |
| 4 | conseillé | `game/levels/test_course.tscn:337-338` (ZigzagLanding, dessus à 0,9 m, 3 m au-dessus du checkpoint Zigzag) ; `tests/test_course.gd:209` | Décision 10 et exception de réglage d'`AGENTS.md` | Avec `wall_jump_up_speed` × 0,9 (8,55), le test réactif « … rise gravity changed by 10 percent » passe au rouge sur Zigzag à × 1,1 : chute, 3 m sous le but, checkpoint 9 non atteint. Seul, chacun des deux réglages passe. La décision 10 tolère ce rouge, mais une baisse de 10 % de la poussée verticale du wall-jump suffit à bloquer la CI d'un réglage pur. | Donner de la marge au zigzag (palier d'arrivée plus bas ou murs plus rapprochés). Ou bien noter dans la spec que cette combinaison est hors garantie. |

Résultat complet du balayage (×0,9 / ×1,1, une valeur à la fois) : toutes les autres valeurs gardent tous les tests verts. Ce sont `mantle_min_height`, `mantle_max_height`, `mantle_duration`, `mantle_exit_speed`, `wall_run_distance`, `wall_run_min_wall_height`, `wall_run_min_height`, `wall_run_start_speed`, `wall_run_stop_speed`, `wall_run_duration`, `wall_run_gravity`, `wall_jump_away_speed`, `wall_jump_grace_time`, `wall_jump_up_speed` ×1,1 et `push_split_angle` ×0,9. `test_pilot` reste vert pour les 30 variantes.

Ce que j'ai vérifié sans rien trouver à corriger :
- Décision 22 : `_observe` ne lit que la vitesse du corps, l'intention, les collisions du pas précédent et la capsule de collision. `_facing()` ne sert qu'à l'inclinaison visible.
- Décision 4 : `_cap_horizontal_speed` est appelée dans `_wall_jump`.
- Mantle debout dans Jolt : 84 cas sondés (hauteurs de 1,9 à 3,7 m, angles de 0° à 44°, départ arrêté ou avec élan). Tous finissent GROUNDED, au sol, à la hauteur du rebord + 0,001 m, à 4,0 m/s, sans aucun pas FALLING ensuite.
- Approche raide en vraie physique : à 80° le coureur touche le mur sans wall-run ; en poussant ensuite le long du mur, il obtient un wall-run de 10 pas. Le mur n'est pas gâché et il n'y a plus de wall-run d'un seul pas.
- Frontières de couches au-delà de ce que voit l'outil : rien.
- Toutes les valeurs de ressenti sont dans la ressource ; les nombres du code en sont dérivés.
- Code mort : aucune fonction non référencée.
- Assertions existantes : aucune retirée, hors la décision 21 et le mur redimensionné.
- Travail non demandé : rien hors des « Choix acceptés ».
- `AGENTS.md` et le README sont exacts, à la réserve du constat 1 près.

## 3. Couverture de la spec

Les 41 scénarios ont leur test ; aucun test nouveau n'est sans scénario.

| Scénario | Test |
|---|---|
| Le coureur se hisse sur un rebord à sa portée | `test_the_runner_mantles_onto_a_ledge_within_reach` |
| Un rebord trop haut n'est pas franchi | `test_a_ledge_too_high_is_not_climbed` |
| Pas de mantle sans pousser vers le rebord | `test_no_mantle_without_pushing_towards_the_ledge` |
| Pas de mantle si le dessus est encombré | `test_no_mantle_if_the_top_is_blocked` |
| Le mantle va jusqu'au bout | `test_the_mantle_goes_to_the_end` |
| Le wall-run démarre tout seul le long d'un mur | `test_the_wall_run_starts_by_itself_along_a_wall` |
| La diagonale du clavier lance un wall-run | `test_the_keyboard_diagonal_starts_a_wall_run` (moteur seul, alignement exact : voir constat 1) |
| Une approche trop raide ne gâche pas le mur | `test_a_too_steep_approach_does_not_spoil_the_wall` |
| Pas de wall-run sans vitesse | `test_no_wall_run_without_speed` |
| Le wall-run ralentit la chute | `test_the_wall_run_slows_the_fall` |
| L'élan au-dessus de la vitesse de pointe se garde en wall-run | `test_momentum_above_top_speed_is_kept_in_a_wall_run` |
| Le wall-run s'arrête au bout de sa durée | `test_the_wall_run_stops_at_the_end_of_its_duration` |
| Le wall-run s'arrête quand le mur s'arrête | `test_the_wall_run_stops_when_the_wall_stops` |
| Pousser à l'opposé du mur fait décrocher | `test_pushing_away_from_the_wall_detaches` |
| Le wall-jump repousse à l'opposé du mur | `test_the_wall_jump_pushes_away_from_the_wall` |
| Le wall-jump ne dépasse pas le plafond absolu | `test_the_wall_jump_does_not_exceed_the_absolute_cap` |
| Le wall-jump reste possible juste après avoir décroché | `test_the_wall_jump_remains_possible_just_after_detaching` |
| Un saut demandé juste avant le mur donne un wall-jump | `test_a_jump_requested_just_before_the_wall_gives_a_wall_jump` |
| Le même mur est refusé deux fois de suite | `test_the_same_wall_is_refused_twice_in_a_row` |
| Un autre mur est accepté | `test_another_wall_is_accepted` |
| Toucher le sol autorise de nouveau le même mur | `test_touching_the_ground_allows_the_same_wall_again` |
| Pas de wall-run ni de mantle en étant baissé | `test_no_wall_run_or_mantle_while_low` |
| Pas de mantle pendant un wall-run | `test_no_mantle_during_a_wall_run` |
| La hauteur de chute compte depuis un wall-run | `test_the_fall_height_counts_from_a_wall_run` |
| Le coureur ne reste pas coincé au-dessus d'une fente sous un plafond bas | `test_the_runner_does_not_get_stuck_over_a_crack_under_a_low_ceiling` |
| Une grande chute reçue sous un plafond bas sans roulade est lourde | `test_a_big_fall_landed_under_a_low_ceiling_without_a_roll_is_hard` |
| Un mur exclu ne donne pas de wall-run | `test_an_excluded_wall_gives_no_wall_run` |
| Un mur trop incliné ne donne pas de wall-run | `test_a_wall_too_tilted_gives_no_wall_run` |
| La grande chute se franchit | `test_the_big_drop_can_be_cleared` |
| Le rebord se franchit | `test_the_ledge_can_be_cleared` |
| Le mantle se termine debout sur le rebord | `test_the_mantle_ends_standing_on_the_ledge` |
| Un rebord abordé de biais donne un mantle | `test_a_ledge_approached_at_an_angle_gives_a_mantle` (voir constats 2 et 3) |
| Un rebord couvert ne donne pas de mantle | `test_a_covered_ledge_gives_no_mantle` |
| Le vide se franchit en wall-run | `test_the_gap_can_be_cleared_by_wall_running` |
| Le zigzag se franchit en wall-jumps | `test_the_zigzag_can_be_cleared_by_wall_jumps` |
| L'enchaînement final mène à l'arrivée | `test_the_final_combination_leads_to_the_finish` |
| Le pilote franchit des murs qu'il ne connaît pas | `test_the_pilot_clears_walls_it_does_not_know` |
| Le pilote ne court pas sur un mur sans raison | `test_the_pilot_does_not_wall_run_without_a_reason` |
| Le pilote relâche le saut pour ne pas dépasser sa réception | `test_the_pilot_releases_the_jump_so_as_not_to_overshoot_its_landing` |
| Le retour au checkpoint fonctionne depuis le mantle et le wall-run | `test_returning_to_the_checkpoint_works_from_the_mantle_and_the_wall_run` |
| L'affichage de debug montre les états des murs | `test_the_debug_display_shows_the_wall_states` |

Les quatre tests à ±10 % rejouent bien les dix sections (`tests/test_course.gd:271`). Le mur de `test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear` est redimensionné depuis le réglage, et ses assertions sont inchangées.

## 4. Choix tranchés par le code là où la spec se tait, absents des « Choix acceptés »

- **Vitesse verticale à l'entrée d'un wall-run** (`runner_motor.gd:543-545`) : elle est gardée, seule la gravité est réduite. Un coureur qui attrape un mur en tombant vite continue de descendre vite.
- **Distance au mur pendant le wall-run** (`runner_motor.gd:379-383`, `:367-372`) : le wall-run peut partir et durer jusqu'à 0,6 m du mur, et rien ne colle le coureur au mur. La capsule penche alors de 20° vers un mur qui peut être à 0,6 m.
- **Sortie du mantle** (`runner_motor.gd:296`, `:313`) : elle se fait perpendiculairement à la face, quel que soit l'angle d'approche ou de poussée. Le coureur réoriente ensuite par l'accélération au sol.
- **Mantle et wall-run possibles au même pas** (`runner_motor.gd:274-277`) : le mantle passe d'abord. Combiné aux portées de détection différentes, cela donne le constat 2.
- **Deux murs à portée à gauche et à droite** (`player.gd:154`) : le plus proche gagne, même s'il est refusé. Un mur accepté plus loin est ignoré tant que le mur refusé reste le plus proche (couloir de moins de 1,9 m).
- **Direction des rayons latéraux** (`player.gd:131-134`) : elle vient de la vitesse horizontale. L'intention ne sert que si la vitesse est exactement nulle.
- **Affichage de debug** : « WALL JUMP » montre toute la tolérance (0,10 s) pendant le wall-run, puis le décompte après le décrochage.

## 5. Non vérifiable ici (manette et clavier en main)

- Wall-run et zigzag au clavier : la diagonale avec une caméra presque parallèle au mur (constat 1). À la manette, la question est de savoir si le coureur colle ou décroche quand on pousse « vers le mur » au-delà de 45°.
- Sensation du mantle : 0,35 s de montée puis la sortie à 4 m/s, droit devant la face, avec perte de l'élan. Le déclenchement pendant la montée d'un saut sur un bloc qu'on aurait franchi.
- Wall-run : la gravité de 6 m/s² ; l'entrée en tombant vite (vitesse verticale gardée) ; l'écart de 0,6 m au mur ; l'inclinaison de 20° prise presque d'un coup ; la durée de 1,2 s ; le décrochage en poussant à l'opposé.
- Wall-jump : la poussée de 7 m/s à l'opposé et 9,5 m/s vers le haut, la tolérance de 0,10 s après le décrochage et le saut en avance de 0,12 s. Dans le zigzag, avec seulement l'avant tenu, l'air ramène la vitesse vers l'avant et coupe la poussée à l'opposé : il faut viser le mur d'en face.
- Caméra pendant un wall-run et dans le zigzag (ressort contre les murs proches), lisibilité des murs bleu-gris.
- Longueur et rythme du parcours complet (29 s par le pilote, contre 45 à 60 s visés par la décision 8), au point d'arrêt n° 2.

Sondes et journaux : `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-movement-walls-2\` (`sweep.txt`, `sweep_pilot.txt`, `fail_push_split_angle_1.1.log`, `fail_wall_jump_up_speed_0.9.log`, `test_zprobe_zigzag.gd`).
`````

### Développeur, passe 3 (commit 776d0be)

`````markdown
# Developer report, third pass: `docs/specs/movement-walls.md` (second amendment, 41 scenarios)

The three points are fixed, and `just check` is green on the last commit (125 tests). The spec is back to 🟢. Nothing was pushed or merged; `AGENTS.md` was not touched.

- **A wall run now starts on any push that is not away from the wall.** It works in the real physics with the camera 3° and 1° off the wall's axis on either side.
- **The ledge test reads the split angle as the motor does,** from the surface.
- **The zigzag has its margin:** each of the 17 new values at ±10 % keeps the four guaranteed tests green on all ten sections (2720 runs).

One thing for an owner, under Questions:
- **The spec now says one thing that is no longer true:** its accepted choice "Deux murs à portée" says "Les murs du zigzag sont à 4 m", and they are now 3.2 m apart.

- **Worktree:** `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ac2db3e8c48bad46a`
- **Branch:** `movement-walls`, on top of the coordinator's `2841779` and `8bc06af`

| Commit | Content |
| ------ | ------- |
| `bcad787` | core, levels, tests: a wall run only asks not to push away, and the zigzag keeps its margin |
| `776d0be` | docs: movement-walls implemented after the second amendment, 41 scenarios green |

## Fait

1. **Decision 3, second amendment** (`game/core/runner_motor.gd`).
   - `_can_run_along()` asks for a push that is not away from the wall (`_pushes_away`, strictly beyond the split), along with the speed along the wall. `_pushes_along()` had no other user and is gone.
   - The split angle still decides the mantle (on the limit counts) and leaving a wall (strictly beyond).
   - **Scenario « La diagonale du clavier lance un wall-run »:** `test_the_keyboard_diagonal_starts_a_wall_run` moved to `tests/test_player_walls.gd` and plays in the real physics:
     - the normalised keyboard diagonal, rotated by the camera at −3°, −1°, 0°, +1° and +3°;
     - the runner flying along the wall, or coming at it at 20°;
     - 10 runs, then the same push in the core at splits of 45° and 30°.
   - **Test 6** (`test_the_wall_run_starts_by_itself_along_a_wall`): its contrasts follow the amendment.
     - Pushing straight into the wall, or mostly into it, now starts a wall run.
     - Pushing away, mostly away, or not at all does not.
   - **README Controls** says the same.
2. **Test convention** (`tests/test_player_ledges.gd`).
   - The limit "towards the face" is `90 − push_split_angle` degrees off the normal, the motor's convention.
   - The test aims halfway inside it and checks that the visible body turned past it.
3. **Zigzag margin** (`game/levels/test_course.tscn`).
   - The right wall stands 3.2 m from the left one instead of 4 m. The crossings get shorter, close to the rise of a wall jump, so more height is gained per metre along the zigzag.
   - The far platform, its beam and the `Final` checkpoint's trigger are 24 m wide and centred (they were 12 m wide).
4. **Nothing to do** for the high face approached at an angle (an accepted choice).

## Vérifié

**Gates.** `just check` is green on `bcad787` (33.9 s) and on `776d0be`:
- typecheck: 38 scripts, 0 errors;
- lint: 0 findings, 38 files left unchanged;
- tests: 125 of 125 pass, 2840 asserts;
- structure: 0 problems;
- builds: Windows exported and ran 60 frames headless; Linux built.

`just preflight`: 25.2, 25.2 and 25.0 s (25.2 to 25.6 s last pass).

**Red first**
- **Point 1.** On the previous motor, the new keyboard-diagonal test was red for +1° and +3°, along the wall and at 20°: as the inspection measured. It also failed with a 30° split, and test 6's "straight into the wall" cases were red.
- **Point 2.** With `push_split_angle` = 49.5 in a temporary tuning file, `test_a_ledge_approached_at_an_angle_gives_a_mantle` was red. After the fix it is green at 40.5°, 45° and 49.5°. The file was restored and checked byte for byte with `cmp`.
- **Point 3.** With `wall_jump_up_speed` = 8.55 in a temporary tuning file, the guaranteed `..._rise_gravity_changed_by_10_percent` test was red on the zigzag at ×1.1: the runner fell 3 m under the goal. After the change it is green; the file was restored.

**Decision 10, as amended.** Each of the 17 new values at ×0.9 and ×1.1, one at a time, combined with each of the four guaranteed values (top speed, rise gravity, fall gravity, jump height) at ×0.9 and ×1.1, on all ten sections. Each run was judged as `_assert_cleared` judges it: 17 × 2 × 8 × 10 = 2720 runs. Probe and outputs are in `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\probes` (`cross1.txt` to `cross3.txt`).
- **Walls 3.2 m apart, platform still 12 m wide: 2560 of 2720.**
  - Rise gravity ×0.9 or fall gravity ×0.9 failed on the zigzag whatever the new value. A trace shows why: one more crossing makes the last wall jump head left. The runner lands 0.3 m from the left edge with 6.5 m/s of sideways speed, and slides off.
- **Platform 16 m wide: 2719 of 2720.**
  - `wall_jump_up_speed` ×1.1 with fall gravity ×0.9 still failed. The higher climb makes the fall over 4 m, the pilot rolls (correctly), and a roll keeps its sideways speed for 0.5 s (an accepted choice): 3.5 m of drift past the edge.
- **Platform 24 m wide: 2720 of 2720.**

**The inspector's zigzag probe on the new course** (`test_zprobe_zigzag.gd`, run temporarily): a human-like runner pushing the keyboard diagonal towards the next wall, or W only, with the camera at 0°, ±1° and ±3°. All 10 runs reach the `Final` checkpoint (3 or 4 wall runs, 2 or 3 wall jumps). Before this pass, ±1° lost it.

## Non vérifié

**Only the owner can judge, controller in hand**
- Pushing diagonally into a wall, or straight into it, now starts a wall run.
- The narrower zigzag, 3.2 m between the walls: the climb is steeper, and the runner arrives up to about 5 m above its start.
- The 24 m wide far platform and its beam: it is very wide to read.
- A face approached nearly head-on now gives a mantle, never a wall run, if it is within reach.

**Not run here**
- Linux CI (nothing pushed).
- A window, a keyboard, a gamepad.
- The whole course in one go.

## Écarts

1. **No push, no wall run.** Decision 3 now asks "seulement de ne pas pousser à l'opposé"; a stick at rest is not away, but the decision lists only pushes (along, diagonally towards, straight into). I kept the need for a push.
2. **The keyboard-diagonal test changed file,** from `tests/test_runner_wall_run.gd` to `tests/test_player_walls.gd`, so that it can prove the scenario in the real physics. Its core part stays in it.
3. **The angled ledge is aimed halfway inside the limit, not at 0.9 of it.** At 0.9 the runner slides along the face at 5.85 m/s on the floor, just under the 6 m/s wall-run start. With `wall_run_start_speed` × 0.9 it would wall-run instead of mantling, and the test would turn red on a tuning-only change.
4. **The far platform is 24 m wide.** The last wall jump may head either way at 7 m/s sideways, and a roll after a high landing keeps that speed for 0.5 s. Narrower widths failed the combined replays (see Vérifié).

## Questions

1. **The accepted choice "Deux murs à portée"** says "Les murs du zigzag sont à 4 m". They are now 3.2 m apart, still more than two wall-run reaches (1.9 m). The spec is the owners' file: please update that sentence.

---

- **Branch:** `movement-walls`, in `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ac2db3e8c48bad46a`
- **Final commit:** `776d0bed89f86477b73564cf377599054ef5cb9a`
- **Commits of this pass:** `bcad787`, `776d0be`
`````
