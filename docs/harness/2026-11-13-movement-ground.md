# Leçons du tour — mouvements au sol (`docs/specs/movement-ground.md`)

Tour du 2026-11-13, propriétaire : Jimmy. Troisième tour complet du harnais : spec issue
de la scission de `movement-advanced.md` (pull request n° 8), trois passes du
développeur, deux inspections, fusion (pull request n° 9). Ce document dit ce que le tour
a appris sur le harnais lui-même. Les cinq rapports des agents sont à la fin, mot pour
mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

Particularité du tour : pendant l'inspection, Jimmy a délégué la décision à l'assistant
(« valide si tu estimes que c'est clean »). Les questions ouvertes ont été tranchées par
la session principale et écrites dans la spec, section « Choix acceptés à
l'inspection », pour que Jimmy puisse revenir sur chacune après avoir joué.

## Déroulé

| Étape | Qui | Résultat |
| ----- | --- | -------- |
| Spec | session principale avec Jimmy | relecture de `movement-advanced.md`, scindée en « au sol » (🟡, 32 scénarios) et « aux murs » (⏸) ; pull request n° 8 |
| Développement, passe 1 | développeur, worktree isolé | 7 commits, 82 tests, `just check` vert ; 53 sabotages volontaires ; 9 questions |
| Vérification | session principale | `just check` vert, relancé sur son commit |
| Inspection 1 | inspecteur, contexte neuf | « conforme », 10 constats conseillés dont 4 défauts réels ; coupée par un redémarrage de session, reprise par message |
| Amendement | session principale, décision déléguée | 5 décisions précisées, 5 scénarios ajoutés, 1 renforcé (37) ; `AGENTS.md` Layout dans un commit à part |
| Développement, passe 2 | développeur, même worktree | 7 commits, 85 tests ; coupé par une limite d'usage au 4e commit, repris par message après le passage de Fable 5.2 à Opus 5.5 |
| Inspection 2 | inspecteur, contexte neuf, sans les rapports ni la première inspection | « conforme », 3 constats conseillés |
| Développement, passe 3 | développeur | 1 commit, deux tests rendus justes ; une limite hors plage signalée |
| Clôture | session principale | deux choix ajoutés à la spec, `just check` vert, CI Linux verte, fusion |

## Ce que la grille du kit demande de noter

1. **Sparring.** Pas de nouvelle session : la relecture de la spec existante a suffi,
   avec trois recommandations acceptées par Jimmy (« oui pour tout »). La spec laissait
   beaucoup de transitions ouvertes (voir la leçon 3).
2. **Développeur.** Spec lue, tests d'abord, `just check` vert à chaque commit, cinq
   sections à chaque passe, chaque correction prouvée rouge avant.
3. **Inspecteurs.** Dépôt et worktree intacts, chaque constat avec fichier et ligne, les
   expériences faites sur une copie hors du dépôt, dans un dossier temporaire propre à
   chacun.
4. **Écarts de lecture.** Voir les leçons.

## Leçons

1. **Les sondes dans la vraie physique ont trouvé ce que les tests de `core` ne
   voyaient pas.** Les quatre défauts réels de la première inspection (glissade qui
   redémarre en boucle, coureur qui se relève dans l'obstacle et traverse le sol,
   glissade plaquée vers le bas au bord d'un rebord, pilote qui lâche la glissade aux
   jointures) ont été montrés par des parcours construits pour l'occasion, pas par la
   lecture. Tous les tests étaient verts.
2. **Une correction peut rendre un test fragile au réglage.** Le test du rebord, écrit
   pour corriger un constat de la première inspection, passait au rouge sur un simple
   changement de valeur : les deux coureurs n'arrivaient pas au bord à la même vitesse.
   C'est la seconde inspection qui l'a vu, en rejouant la suite avec des valeurs
   changées une à une. Proposition pour le développeur : pour chaque nouveau test du
   parcours, rejouer la suite avec deux ou trois valeurs de réglage changées, puisque
   l'exception « réglage seul » d'`AGENTS.md` repose sur une CI qui reste verte.
3. **Une spec muette laisse le code décider.** Onze choix ont été faits par le code là
   où la spec se taisait, surtout aux croisements d'états : en l'air sous un plafond
   bas, au-dessus de la vitesse de pointe en tournant, une roulade qui finit sous un
   plafond. Proposition pour le sparring : pour chaque nouvel état, passer en revue ce
   qu'il devient en l'air, sous un plafond, au-dessus de la vitesse de pointe, et quand
   un autre état se termine.
4. **Le moteur physique a ses détails, et ils comptent.** Jolt enfonce le corps de 1,5 mm
   pendant un pas à la jointure de deux blocs ; `cast_motion` ignore ce que la forme
   touche déjà ; au bord d'un bloc la normale de contact est inclinée. Les sondes du
   pilote partent maintenant du sol sous les pieds, et le joueur rapporte la normale du
   sol par un rayon. La correction du rebord est dans `player`, pas dans `core` : la
   règle du moteur était juste, c'est le constat qu'on lui donnait qui était faux.
5. **Deux inspections indépendantes valent mieux qu'une.** La seconde, sans les
   rapports ni la première inspection, a trouvé deux tests trop lâches que la première
   et le développeur n'avaient pas vus, et confirmé tout le reste. Coût : environ
   18 minutes.
6. **Les interruptions sont devenues ordinaires.** Un redémarrage de session a coupé la
   première inspection, une limite d'usage a coupé le développeur en pleine passe. Les
   deux ont repris par message, sans rien perdre : le développeur parce qu'il
   commitait chaque tranche verte, l'inspecteur parce que son transcript était gardé.
   Le changement de modèle en cours de tour a seulement changé la ligne d'attribution
   des commits.
7. **Demander le rapport dans un fichier dès le lancement.** La première inspection n'a
   écrit son rapport sur disque qu'à une seconde demande. Les rapports lancés avec cette
   consigne dans le brief ont tous été écrits.
8. **Les temps restent sous la limite, avec moins de marge.** `just preflight` : 14 s sur
   `main` avant le tour, 20 à 21 s après, jusqu'à 40 s sur une machine chargée. La
   limite de 30 s de la spec est tenue dans les mesures au calme.

## Ce qui reste ouvert après ce tour

- **Point d'arrêt n° 2.** Personne n'a joué la glissade, la roulade ni la réception
  lourde, ni au clavier ni à la manette. La caméra sous la poutre basse et pendant la
  grande chute n'a jamais été vue.
- **Deux limites acceptées, à reprendre avec la relecture de `movement-walls.md`** :
  la glissade lente prise dans une fente sous un plafond bas (au-delà de 6 m/s² de
  ralentissement), et le coureur baissé qui atterrit sous un plafond sans test de
  roulade.
- **La correction des jointures du pilote** n'est prouvée qu'avec un ralentissement de
  glissade différent de celui du projet ; aux valeurs actuelles, aucun test n'échoue si
  on l'annule.
- **Le pilote saute du bord de la grande chute** : la roulade est prouvée sur 6,6 m, pas
  sur les 5 m d'un joueur qui se laisse tomber.
- Toujours ouverts depuis les tours précédents : la protection de la branche `main`, le
  sort de la compétence `harness-setup`, la lecture d'`Engine.time_scale` (étape 3), la
  cause du `just preflight` rouge du tour précédent.

## Rapports des agents, mot pour mot

### Développeur, passe 1 (commit 85aee0d)

`````markdown
# Developer report — `docs/specs/movement-ground.md`

The 32 scenarios each have a test of the same name, `just check` is green on the final commit, and the working tree is clean. The work is in seven commits on `movement-ground`, not pushed. Nothing was run in a window: the feel is entirely for the owner to judge.

Four things need an owner's decision before merging; details are under Questions:
- a slide held on flat ground restarts by itself, over and over;
- the test pilot jumps off the big drop, so the tests prove a 6.6 m fall, not the 5 m one a player gets by walking off;
- two tests have no scenario in the spec;
- `AGENTS.md` was not edited, as instructed; the proposed Layout text is at the end.

- **Worktree:** `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261`
- **Branch:** `movement-ground` (local, never pushed, no pull request)
- **Base:** `2ac9d2b` (merge of pull request #8)

| Commit | Content |
| ------ | ------- |
| `48352d1` | core: the motor takes the observed facts as one typed structure |
| `dd05dd4` | core: the slide |
| `acba95c` | core: the roll and the hard landing |
| `340a51c` | core: momentum above the top speed |
| `fbca44f` | player, ui: the slide press, the capsule that squashes, the new debug lines |
| `d86cad0` | levels, tests: the low passage and the big drop, a pilot that slides and rolls |
| `85aee0d` | docs, player, tests: README Controls, spec status, last checks |

## Fait

**Structure of facts (decision 2).** `game/core/runner_facts.gd` (`RunnerFacts`: `on_floor`, `velocity`, `altitude`, `floor_normal`, `can_stand`) replaces the positional arguments of the motor: `RunnerMotor.step(intent: MoveIntent, facts: RunnerFacts, delta: float) -> Vector3`.

**Slide (core) — `tests/test_runner_slide.gd`**

| # | Scenario | Test |
| - | -------- | ---- |
| 1 | La glissade démarre au sol avec assez de vitesse | `test_the_slide_starts_on_the_floor_with_enough_speed` |
| 2 | La glissade est refusée sans vitesse | `test_the_slide_is_refused_without_speed` |
| 3 | La glissade ne démarre pas en l'air | `test_the_slide_does_not_start_in_the_air` |
| 4 | Tenir la glissade en atterrissant la lance | `test_holding_the_slide_while_landing_starts_it` |
| 5 | La glissade ralentit sur le plat puis le coureur se relève | `test_the_slide_slows_down_on_the_flat_then_the_runner_stands_up` |
| 6 | La glissade accélère en descente | `test_the_slide_accelerates_downhill` |
| 7 | Relâcher la glissade relève le coureur | `test_releasing_the_slide_stands_the_runner_up` |
| 8 | Le coureur reste baissé sous un plafond bas | `test_the_runner_stays_low_under_a_low_ceiling` |
| 9 | Le coureur ne reste pas coincé sous un plafond bas | `test_the_runner_does_not_get_stuck_under_a_low_ceiling` |
| 10 | Pas de saut sous un plafond bas | `test_no_jump_under_a_low_ceiling` |
| 11 | Sauter en glissade garde la vitesse | `test_jumping_while_sliding_keeps_the_speed` |

**Landing (core) — `tests/test_runner_landing.gd`**

| # | Scenario | Test |
| - | -------- | ---- |
| 12 | Une roulade réussie garde la vitesse | `test_a_successful_roll_keeps_the_speed` |
| 13 | Une réception lourde coûte de la vitesse | `test_a_hard_landing_costs_speed` |
| 14 | Une glissade pressée trop tôt ne donne pas de roulade | `test_a_slide_pressed_too_early_gives_no_roll` |
| 15 | Une glissade tenue depuis avant la fenêtre ne donne pas de roulade | `test_a_slide_held_since_before_the_window_gives_no_roll` |
| 16 | Une petite chute se reçoit normalement | `test_a_small_fall_is_landed_normally` |
| 17 | Pas de saut pendant une réception lourde | `test_no_jump_during_a_hard_landing` |
| 18 | Sauter pendant une roulade garde la vitesse | `test_jumping_during_a_roll_keeps_the_speed` |

**Momentum (core) — `tests/test_runner_momentum.gd`**

| # | Scenario | Test |
| - | -------- | ---- |
| 19 | L'élan au-dessus de la vitesse de pointe se garde en l'air | `test_momentum_above_top_speed_is_kept_in_the_air` |
| 20 | L'élan redescend lentement au sol | `test_momentum_comes_down_slowly_on_the_floor` |
| 21 | La vitesse horizontale a un plafond absolu | `test_the_horizontal_speed_has_an_absolute_cap` |

**Player, course, pilot, display**

| # | Scenario | Test | File |
| - | -------- | ---- | ---- |
| 22 | Presser la glissade se lit dans l'intention | `test_pressing_the_slide_is_read_in_the_intent` | `tests/test_player.gd` |
| 23 | La capsule s'abaisse en glissade et se relève après | `test_the_capsule_lowers_while_sliding_and_rises_after` | `tests/test_player.gd` |
| 24 | Le retour au checkpoint relève le coureur | `test_returning_to_the_checkpoint_stands_the_runner_up` | `tests/test_course_ground.gd` |
| 25 | La section des marches se franchit | `test_the_steps_section_can_be_cleared` | `tests/test_course.gd` |
| 26 | Le passage bas se franchit en glissade | `test_the_low_passage_can_be_cleared_by_sliding` | `tests/test_course_ground.gd` |
| 27 | Le passage bas arrête un coureur debout | `test_the_low_passage_stops_a_standing_runner` | `tests/test_course_ground.gd` |
| 28 | La grande chute mène à l'arrivée | `test_the_big_drop_leads_to_the_finish` | `tests/test_course_ground.gd` |
| 29 | La roulade fait gagner du temps sur la grande chute | `test_the_roll_saves_time_on_the_big_drop` | `tests/test_course_ground.gd` |
| 30 | Le pilote glisse sous un obstacle bas qu'il ne connaît pas | `test_the_pilot_slides_under_a_low_obstacle_it_does_not_know` | `tests/test_pilot.gd` |
| 31 | Le pilote ne glisse pas sans raison | `test_the_pilot_does_not_slide_without_a_reason` | `tests/test_pilot.gd` |
| 32 | L'affichage de debug montre les nouveaux états | `test_the_debug_display_shows_the_new_states` | `tests/test_debug_overlay.gd` |

**Replaced scenario (decision 13).** `test_the_steps_section_leads_to_the_finish` is renamed `test_the_steps_section_can_be_cleared`: its goal is now the low passage checkpoint, placed where the finish line was. `test_the_big_drop_leads_to_the_finish` is new.

**Guaranteed range (decision 15).** The four `test_the_sections_can_be_cleared_with_a_..._changed_by_10_percent` tests keep their name and now play the six sections: 12 runs each, side by side.

**Two tests without a scenario** (see Écarts 14):
- `test_the_direction_of_a_slide_is_corrected_slowly` (`tests/test_runner_slide.gd`);
- `test_a_slide_gains_speed_down_the_ramp_of_the_low_passage` (`tests/test_course_ground.gd`).

**Game code**
- `game/core/runner_motor.gd`: states `SLIDING`, `ROLLING`, `HARD_LANDING`; the fall height is measured from the highest point reached in the air; momentum; absolute cap. New queries: `is_low()`, `roll_window_left()`, `landing_time_left()`.
- `game/core/move_intent.gd`: `slide_pressed`.
- `game/core/movement_tuning.gd` and `.tres`: the 12 values of the spec, unchanged, in three groups (Slide, Landing, Momentum).
- `game/player/input_intent_source.gd`: fills `slide_pressed` like the jump press.
- `game/player/player.gd`: builds the facts (headroom is the low capsule swept up to its standing height), and gives the collision capsule and the visible one the height the motor's state asks for. `teleport()` stands the runner up at once.
- `game/player/player.tscn`: the capsule shape and mesh are local to each runner.
- `game/ui/debug_overlay.gd`: lines `ROLL WINDOW` and `LANDING`; the three new state names.
- `game/levels/test_course.tscn`:
  - the old `Finish` block becomes `LowPassageStart` (16 m long);
  - `Ramp`: 8 m long, 2 m down, 14 degrees;
  - `LowPassageFloor`, and `LowBeam`: underside 1.2 m above the floor, 3 m deep, 3 m tall;
  - `BigDropLanding`: 5 m lower, 30 m long;
  - checkpoints `LowPassage` (index 4) and `BigDrop` (index 5);
  - the finish line is 20 m after the drop.

**Tests and helpers**
- New helpers: `tests/motor_body.gd` (`MotorBody`, a runner without a scene) and `tests/course_test.gd` (`CourseTest`, the course helpers moved out of `test_course.gd`).
- `tests/pilot_intent_source.gd`: the two new gestures, and a `slides` option.
- `tests/piloted_run.gd`: `pilot_slides`, and the counters `slide_requests`, `steps_sliding`, `steps_rolling`, `steps_landing_hard`.
- `tests/scripted_intent_source.gd`: `slide(direction, steps)`.

**Docs.** `README.md`: course description, Controls (slide, roll, hard landing, momentum), tuning sentence, roadmap line. The spec's status line is set to `Implémenté`.

## Vérifié

**Gates, on the final commit `85aee0d`, clean tree**

`just check`: green, 28.2 s.

```
typecheck: 32 script(s), 0 with errors
gdlint: Success: no problems found / gdformat --check: 32 files would be left unchanged
test_course.gd 16/16 · test_course_ground.gd 6/6 · test_debug_overlay.gd 2/2 · test_input_map.gd 2/2
test_pilot.gd 6/6 · test_player.gd 4/4 · test_race_hud.gd 2/2 · test_race_state.gd 8/8
test_runner_landing.gd 7/7 · test_runner_momentum.gd 3/3 · test_runner_motor.gd 14/14 · test_runner_slide.gd 12/12
Tests 82 · Passing Tests 82 · Asserts 1261 · Time 10.969s
structure: boundaries 0 · dead files 0 · .claude mirror 0 · 37 file(s) checked
build: Windows Desktop: the exported game ran 60 frames headless
build: Linux: build/linux/parkour-duel.x86_64 (70 MiB with its .pck)
```

82 tests = 49 from `main` (one renamed) + 31 new scenario tests + 2 without a scenario.

**Timings (decision 20), same machine, same day, never two `just` commands at once**

| | Before the new sections | `movement-ground` (`85aee0d`) |
| --- | --- | --- |
| Test suite (GUT time) | 5.64 s on `main` (`2ac9d2b`) | 10.97 to 11.03 s |
| `just preflight` | 14.4 s on `main`; 13.8 s after the first commit (same 49 tests) | 19.79, 19.85, 19.84, 19.81, 19.80 s |
| `just check` | not timed on `main`; 22.3 to 23.5 s on commits 2 to 5 | 28.2, 28.5, 29.1 s |

`just preflight` stays under 30 s, with about 10 s of margin on this machine today. Rough split of the added time:
- `test_course_ground.gd`: 3.6 s, of which 1.1 s is the standing runner waiting out its step budget;
- `test_course.gd`: about +1 s (12 courses per variant test instead of 8);
- `test_player.gd`: +0.8 s (it runs in real time).

**No unexplained red run.** `just preflight` ran 17 times and `just check` 8 times, always one at a time. Every red was expected:
- tests written before the code;
- one `gdformat` finding;
- one strict-typing error in the pilot (an unsafe cast, fixed);
- the deliberate breaks below.

**Test first.** For each slice the tests were written and run before the code.
- Red for the right reason: 9 of 11 slide tests, 6 of 7 landing tests, 3 of 3 momentum tests, both player tests, the debug test, 12 course and pilot tests.
- Green before the code, because they assert an absence: `slide is refused without speed`, `slide does not start in the air`, `a small fall is landed normally`, `the pilot does not slide without a reason`. Each was later seen red on a deliberate break: a slide that starts at any speed, a slide that starts in the air, every fall asking for a roll, a pilot that always slides.

**The tests bite: 53 deliberate breaks**, each followed by the suite, then the file restored byte for byte.
- Motor, 30 breaks: slide start, end, friction, turning, heading memory, slope pull, slope following, ceiling rules, roll window one step shorter and longer, hold counted as press, fall threshold, roll and hard landing durations one step off, momentum, cap, rounding.
- Player and display, 7 breaks.
- Pilot, course, tuning file and player observations, 16 breaks.

All 53 now end with at least one red test. Four first came back green and made me add an assertion or a test, after which they were seen red:

| Break that stayed green | What I added |
| ----------------------- | ------------ |
| The hard landing does not cut the speed at touchdown | A runner landing at half the top speed keeps the same share |
| The fall is measured from the first altitude in the air, not the apex | A leap that tops above the threshold lands hard |
| The pilot presses the slide before every landing | One assertion added to `test_the_pilot_clears_a_course_it_does_not_know` |
| The player never reports the floor normal | `test_a_slide_gains_speed_down_the_ramp_of_the_low_passage` |

Two more holes were found by reasoning before the breaks were run, closed first, then confirmed red: a pilot that lets go of the slide under the beam (the pilot test checks the slide is held at every step the whole body is under it), and a player that always reports room to stand up (the capsule test hangs a beam over the sliding runner).

**Existing assertions.** Checked by script against `2ac9d2b`:
- no line containing an assertion was removed from any existing test file;
- of the 116 lines removed from `tests/test_course.gd`, 111 are found verbatim in `tests/course_test.gd`;
- the other 5 are two header comment lines, the checkpoint list (extended), the renamed test, and one comment.

**Measured with temporary probes (not committed)**

Low passage, tuning of the project:
- the pilot starts the slide 2.97 m before the beam, at 8.93 m/s;
- it slides for 55 steps and stands up 0.5 m after the beam, at 5.83 m/s;
- 63 slide steps with top speed x 0.9, 50 with x 1.1;
- the pilot that does not slide stops at z = -117.55, the face of the beam plus the capsule radius.

Big drop:
- the pilot jumps at the edge (its existing rule), so the fall is 6.6 m;
- it presses the slide 1.5 m above the floor; the landing is seen 5 steps later, in a window of 12;
- the roll lasts 30 steps;
- the race takes 185 steps with the roll and 202 without: 17 steps saved (0.28 s).

Other probes:
- a slide held from the top of the ramp stays on the floor at every step and goes from 9.0 to 13.15 m/s at the bottom;
- one pilot run over the whole course, start line to finish line: reached, race finished in 1025 steps (17.1 s), with 9 jumps, 54 slide steps and 30 roll steps.

How far the tuning can move, one value at a time, on the two new sections only:

| Value | Both new sections pass at | First failure |
| ----- | ------------------------- | ------------- |
| Top speed | x 0.6 to x 1.5 | none in that range |
| Fall gravity, rise gravity, jump height | x 0.5 to x 1.6 | none in that range |
| Slide: least speed to start | up to x 1.7 (8.5 m/s) | x 1.9 (9.5 m/s, above the top speed): the low passage is impossible |
| Slide and roll: capsule height | up to x 1.2 (1.08 m) | x 1.4 (1.26 m, above the 1.2 m clearance): impossible |
| Roll: fall height | up to x 1.6 (6.4 m) | x 1.7 (6.8 m): the pilot's fall no longer needs a roll, `test_the_big_drop_leads_to_the_finish` would be red |
| Roll window | x 0.25 to x 4 | none |
| Slide deceleration | x 0.5 to x 4 | none |
| Roll duration | x 0.2 to x 3 | none |
| Momentum deceleration | x 0.2 to x 5 | none |
| Max fall speed | x 0.4, x 0.6 | none |

**Engine behaviours observed (Godot 4.7.2, Jolt), reported, not worked around**
- `PhysicsDirectSpaceState3D.cast_motion` ignores what the shape already touches or overlaps. A capsule resting on the floor is free to move; a standing capsule that starts inside the beam is also reported free. This is why the pilot has a separate "the ceiling is low" probe.
- `Input.action_press` called inside a fixed step makes `is_action_pressed` true in that step but `is_action_just_pressed` true one step later. Called between two steps, both are true in the same step. The intent test presses between two steps.
- `CharacterBody3D.move_and_slide` zeroes the vertical velocity of a body on the floor. On the ramp the reported velocity has `y = 0` even though the motor asked for a downward one; the horizontal speed is what the motor keeps.
- A sliding runner rests at y = 1.001 on the flat instead of 1.000.

## Non vérifié

**Only the owner can judge, controller in hand**

Slide
- Starting it at 5 m/s, the squash of the capsule, the visor going down with it.
- The 4 m/s² slowdown on the flat, standing up under 2.5 m/s.
- The slow turn (1 rad/s).
- The speed-up on the ramp (9 to about 13 m/s) and going under the beam with that speed.
- Holding the button on flat ground with a direction: the restart loop described in Question 1.
- Being under the beam: staying low with the button released, the refused jump, the 2.5 m/s crawl.
- The long jump out of a slide.

Roll window
- 0.20 s (12 steps) before touching the floor, with a real key and a real button.
- Whether "a press, not a hold" reads well.
- The 0.5 s roll with no steering at all, and jumping out of it.
- Holding the button through the roll, which continues as a slide.

Hard landing penalty
- Speed cut to 35 %, 0.35 s capped at 3.15 m/s, the refused jump.
- A jump pressed in its last 0.12 s starts right after it (Question 2).
- 17 steps lost on the big drop: is the cost enough, or too much?

Momentum decay
- 6 m/s² above the top speed on the floor, nothing in the air, the 22 m/s cap.
- Turning or half-pushing the stick above the top speed.
- Letting go of the stick, which brakes at the usual 45 m/s² from any speed.

Course and display
- The readability of the ramp and of the beam, a grey slab from 1.2 m to 4.2 m above the floor.
- The 5 m drop, and the 5 m fall when walking off against the 6.6 m when jumping off.
- The length of the last straight.
- The camera under the beam and during the drop.
- The two new debug lines on screen (F3).

**Not run here**
- **Linux CI.** Nothing was pushed, so no replay ran under Linux. The new sections and the pilot's two gestures are proven on Windows only.
- **A window, a keyboard, a gamepad.** The slide press is read through `Input.action_press`, between two fixed steps. Real devices, and frame rates under 60 where several fixed steps share one frame, were not tried.
- **The whole course in one go.** No committed test proves it; the spec of the reactive replays leaves it out of scope. The probe above did it once.
- **The four guaranteed values beyond +/-10 % on the four old sections.** Not measured again this round.
- **A slide that leaves the floor under a low ceiling.** The capsule follows the state, so it stands up in the air. No such place exists on the course; not tried.
- **Slopes other than the 14 degree ramp**, in the real physics. The motor tests cover 20 and 30 degrees without the engine. Uphill slides are untested.
- **`just preflight` on a busy machine.** 19.8 s today; `main` took up to 21 s on a busy day last round, so the 30 s limit could be close on such a day.

## Écarts

**Instructions that differ from my role**
1. **Seven commits instead of one.** The launch asked for atomic commits; each was made after a green `just check`.
2. **`AGENTS.md` not edited.** The launch asked for a proposal instead; it is at the end.

**Readings of the spec, in `game/core`**
3. **The slide is level-triggered (decision 3).** Held, on the floor, fast enough: it starts, every time. After a slide ends by slowness, a held button starts another as soon as the runner is back at 5 m/s. See Question 1.
4. **Slope (decision 4).** Horizontal acceleration is `fall_gravity x sin x cos` of the slope, minus the flat slowdown, which still applies on a slope. On the 14 degree ramp that is +6.3 m/s². Under about 5.2 degrees a slope does not make up for the slowdown. Uphill uses the same formula and is not treated apart.
5. **A slide follows a descending floor.** The motor returns a downward velocity along the slope, in the slide only and downhill only. Running still relies on the engine's floor snap, as in the base.
6. **Under a low ceiling (decision 6).** The least speed applies along the heading the slide had, even if a bump stopped the runner dead. A roll that ends under a low ceiling goes on as a slide.
7. **Jump out of a slide (decision 7).** The take-off step first applies the slide's own slowdown, 0.067 m/s. "The speed of the slide" is the speed the slide has at that step; the test compares with a twin that keeps sliding.
8. **Roll (decision 8).**
   - The window is counted like the jump buffer: a press up to 12 steps before the step at which the motor sees the floor, that step included.
   - The fall must be strictly higher than the threshold.
   - During the 30 steps the horizontal velocity is kept as it is: no steering, no braking, even with no direction.
   - After the roll, a slide still held and fast enough continues as a slide.
9. **Hard landing (decision 9).** The speed is multiplied by 35 % at touchdown, then held under 35 % of the top speed. A landing faster than the top speed therefore ends at 3.15 m/s, not at 35 % of its own speed. A jump press is remembered by the jump buffer as usual (Question 2).
10. **Momentum (decision 11).** Above the top speed and with a direction, the wanted speed is the current one minus the slow loss on the floor, or the current one in the air.
    - A half-pushed stick keeps the momentum too.
    - Turning costs speed as it does under the top speed.
    - Pushing against the movement brakes at the usual acceleration.
    - The cap is applied last, to whatever the step produced.
11. **Zero defaults.** A `MovementTuning` built without the new values has a cap of 0 and a roll height of 0, which stops the runner. The tunings built by the existing tests needed the new values (item 16).

**Readings in `game/player` and `game/levels`**
12. **Headroom** is probed only while the runner is low. The capsule height follows the motor's state strictly (decision 1); see the untested edge case above.
13. **Course geometry**, chosen by me:
    - ramp 8 m by 2 m;
    - beam underside at 1.2 m, between 0.9 and 1.8;
    - beam 3 m tall, so that neither a player nor the pilot can jump onto it;
    - drop of 5 m;
    - the lowest block bottom goes from -1 m to -5 m; the fall limit stays at -8 m.

**Tests**
14. **Two tests without a scenario, and assertions beyond their scenario.** Each closes a hole that a deliberate break showed, or a decision no scenario covers:
    - `test_the_direction_of_a_slide_is_corrected_slowly`: last sentence of decision 4;
    - `test_a_slide_gains_speed_down_the_ramp_of_the_low_passage`: the player really reports the floor normal, and the course really has a ramp;
    - the capsule test hangs a beam over the sliding runner: the player really observes its headroom;
    - added assertions: a slide that runs out of floor falls with its speed (decision 5), a runner stopped under a ceiling sets off again, a roll that ends under a ceiling stays low.
15. **One assertion added to an existing test.** `test_the_pilot_clears_a_course_it_does_not_know` also checks `slide_requests == 0`. Nothing existing was changed or removed.
16. **Setup of existing tests adapted, assertions untouched.**
    - `test_the_same_intents_give_the_same_result`: its random sequence now also draws the slide inputs, the new facts and occasional pushes. Without that it could not "visit every state", which its unchanged assertion requires.
    - `_tuning()` of `tests/test_runner_motor.gd` and the tuning of `tests/test_debug_overlay.gd` receive the new values.
17. **`tests/test_course.gd` split.** The lint gate allows 20 public methods per file and the file would have had 22. Its helpers moved unchanged to `tests/course_test.gd`; the five new course tests are in `tests/test_course_ground.gd`. The motor tests are in three new files for the same reason.
18. **"Le passage bas arrête un coureur debout"** is played by the pilot with `pilot_slides = false`, not by a written sequence, to keep step counts out of the section tests (decision 3 of the reactive replays). It costs a full step budget, 1.1 s.

**The pilot (decision 14)**
19. **It still jumps where the floor stops**, so it jumps off the big drop (Question 3).
20. **Low obstacle.** A standing body would be stopped within the reach already used for steps (the distance covered while a jump rises), and a body as low as a slide passes one body width further. It holds the slide while that is true, or while a low body could not rise where the runner is.
21. **Roll.** It presses once per fall, when the fall from its highest point exceeds the tuned height and the time to the floor is at most half the window. The time comes from the fall gravity and the current speed; the ray looks down as far as the max fall speed allows within the window. "Half" is the only chosen factor.

**Small additions**
22. `tests/piloted_run.gd`: the comment of `FELL` now states the condition the previous inspection asked for (finding 3 of the reactive replays round).
23. Debug labels: `ROLL WINDOW` and `LANDING`, in English, free by the spec.
24. README roadmap line: step 1 now reads "the base ... and the ground moves (slide, roll, momentum) are in; mantle, wall-run and wall-jump are next".

## Questions

1. **Held slide on flat ground.** With the button and a direction held, the runner slides from 9 to 2.5 m/s (1.6 s), stands up, is back at 5 m/s in 0.08 s, and slides again, forever. It follows the letter of decision 3, and it lets a runner that came in too slowly still get under an obstacle. The alternative is to require a new press after a slide that ended by slowness. Which one?
2. **Jump pressed at the end of a hard landing.** A press in the last 0.12 s is kept by the jump buffer and starts on the first step after the landing. Is that "refused", or should a hard landing forget the press?
3. **The pilot jumps off the big drop.**
   - The tests prove a 6.6 m fall; a player who walks off falls 5 m.
   - If `roll_fall_height` is tuned above 5 m, a walking player no longer needs to roll while the tests stay green up to 6.4 m.
   - Above 6.4 m `test_the_big_drop_leads_to_the_finish` goes red on a tuning-only change; the new values are outside the guarantee (decision 15).
   - Options: accept; make the drop higher; or teach the pilot not to jump when there is a floor it can land on below.
4. **The two tests without a scenario** (Écarts 14): add their scenarios to the spec, or remove them?
5. **Hard landing faster than the top speed** (Écarts 9): cut to 35 % of the top speed. Is that the intent, or should it keep 35 % of its own speed?
6. **Slide on a slope** (Écarts 4): is the flat slowdown meant to apply on slopes too? As it is, a gentle slope does not speed a slide up.
7. **Capsule in the air.** Should a runner that slides off an edge under a low ceiling stay low until there is room? Today the capsule follows the state.
8. **`just preflight` at 19.8 s** against 14.4 s on `main`: acceptable? The cheapest cut is 1.1 s, by ending the standing runner's run when it stops instead of waiting out its budget; that changes `PilotedRun`.
9. **`AGENTS.md`, Layout.** Proposed text, to apply or reword. Nothing else in `AGENTS.md` describes changed code.

   Current:
   ```
     core/             runner motor, intents, race state, and the tuning resource
   ```
   ```
   tests/              headless tests, one script per subject: test_<subject>.gd; the other
                       scripts are their helpers (written sequences of intents, test pilot)
   ```
   Proposed:
   ```
     core/             runner motor, intents, the facts the player observes, race state,
                       and the tuning resource
   ```
   ```
   tests/              headless tests, one script per subject: test_<subject>.gd; the other
                       scripts are their helpers (written sequences of intents, test pilot,
                       a runner without a scene, the bases of the replay and course tests)
   ```

---

- **Branch:** `movement-ground`, in `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261`
- **Final commit:** `85aee0d28c7fd1b3ae2176d692a9b5c79e20f90e`
- **Commits, oldest first:** `48352d1`, `dd05dd4`, `acba95c`, `340a51c`, `fbca44f`, `d86cad0`, `85aee0d`
`````

### Inspecteur, première inspection (sur 85aee0d)

`````markdown
# Inspection: branch `movement-ground`, range `2ac9d2b..85aee0d` (PR 9)

Checkout confirmed after the restart: `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261` exists, is on `85aee0d`, and is clean before and after my work.

Spec: `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\docs\specs\movement-ground.md`. Task types routed: `core`, `player`, `ui`, `levels`, `harness` (no skill to load).

## 1. Verdict

**Conforme (compliant): no blocking finding.** Ten advisory findings follow. I recommend fixing finding 1 before the merge, and I am not certain it should not be blocking (the rule and my doubt are quoted there). Findings 2, 3 and 4 need a decision from the owner.

What I ran:

- **Gates, in the checkout, one at a time:** all green.
  - `just test`: 82 tests, 1261 asserts, all passing (GUT 11.0 s, command 18.6 s).
  - `just typecheck`: 32 scripts, 0 errors (5.4 s).
  - `just lint`: clean (3.4 s).
  - `just deadcode`: 0 problems (0.4 s).
- **CI:** PR 9, `just check` is green on Linux on `85aee0d`. I read the status only.
- **Outside the repository** (a copy in the scratch folder, deleted since):
  - 48 deliberately broken variants of the motor, player, pilot, course and tuning file, each against the full suite. Every one turned at least one test red.
  - 24 runs with one new tuning value at ×1.25 or ×0.75.
  - Instrumented probes in the real physics.
  - Scripts and raw outputs are in `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-movement-ground\scripts` and `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-movement-ground\out`.

Points you asked about, with no finding:

- **No assertion weakened or removed.**
  - 48 of the 49 tests of `main` keep their name; the 49th is the rename decision 13 orders (`test_the_steps_section_leads_to_the_finish` becomes `test_the_steps_section_can_be_cleared`).
  - The helpers moved from `test_course.gd` to `course_test.gd` are identical line for line.
  - `test_runner_motor.gd` and `test_debug_overlay.gd` only change call sites and tuning set-up. The new `max_horizontal_speed` must be set, because a cap of 0 freezes the runner.
  - `test_the_pilot_clears_a_course_it_does_not_know` gains one assertion.
  - Nothing is skipped.
- **Pilot numbers (reactive-replays decision 3).** No step count, edge position or hand-measured distance in `pilot_intent_source.gd`, `piloted_run.gd`, `course_test.gd` or `test_course_ground.gd`.
  - Derived from the tuning: the reach, one body diameter (`2.0 * capsule_radius`), `max_fall_speed * roll_window`, `roll_fall_height`.
  - Neutral factor: `roll_window / 2.0`.
  - Arbitrary lengths in `test_pilot.gd`: 12.3, 4.6, 2.7, 9.8, 10.7, 14.9. See finding 1 for why "arbitrary" does not hold in practice for one of these tests.
- **Layers and simulation rules.**
  - `RunnerFacts` is a plain `RefCounted` in `core`.
  - Every decision (state, fall height, roll window, speeds, capsule height through `is_low()`) is in `runner_motor.gd`; `player.gd` observes and executes.
  - The simulation only advances in `_physics_process`.
  - Input is read only in `input_intent_source.gd`.
  - No tuning number in game code: the 12 new values are in `movement_tuning.tres` and match the spec table one by one.
  - The debug strings live in `game/ui/`, in English.
- **Scope.** Nothing from `movement-walls.md`; no tooling, gate, `AGENTS.md`, asset or dependency change.

## 2. Findings

All advisory. Paths are absolute.

| # | Severity | File:line | Rule | Finding | Smallest change |
| - | -------- | --------- | ---- | ------- | --------------- |
| 1 | advisory; fix before merge recommended; unsure it is not blocking | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\pilot_intent_source.gd:144-156` (used at `:95`); shown by `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\test_pilot.gd:134` | Decision 14: "tenir la glissade quand un obstacle bas se présente devant lui … jusqu'à ce qu'il y ait la place de se relever". Reactive-replays decision 3: the pilot must stay "valable après un changement de réglage ou de parcours". My doubt: decision 15 says the new values "ne sont pas garanties pour l'instant", and no scenario fails. | The low-body probe is cast flush with the floor. When its sweep crosses a seam between two floor blocks it returns erratic shares below 1, and the pilot lets go of the slide. In the pilot's own test (seam 0.95 m before the beam) it presses and releases four times on the approach, and passes only because the last probe before the beam returns 1. Changing only `slide_deceleration` from 4.0 to 4.5 in the `.tres` turns this test red (81/82): the runner arrives standing and stops against the beam. Red also at 5.0 and 6.0, green at 3.0 and 4.0. Same track with a one-block floor: clean, slide held without a gap. | In `_free_share`, lift the query capsule by the body's own `safe_margin`. Tried on the copy only: 82/82 with 4.0, 4.5, 5.0 and 6.0. Make the test assert a single slide press from the first request to the exit; that assertion fails today. |
| 2 | advisory (owner decides) | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\game\core\runner_motor.gd:128-130` with `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\game\player\player.gd:106-107` | Decision 6: "Tant qu'il n'y a pas la place de se tenir debout, le coureur reste baissé", against decision 5: "Quitter le sol en glissant fait tomber normalement". | A low runner that loses the floor becomes `FALLING` and its capsule returns to 1.8 m with no headroom check. Probe: sliding under a 1.2 m beam over a 0.6 m crack (narrower than the 0.7 m capsule), the capsule stands up inside the beam, the solver pushes the body 0.56 m down in one step, horizontal speed goes from 6.5 to 0 and the runner falls through the floor. Not reachable on today's course (one block under the beam). | Owner decides which decision wins under a ceiling. Smallest code: the motor keeps the runner low in the air while `can_stand` is false, with a scenario. |
| 3 | advisory (feel, owner decides) | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\game\core\runner_motor.gd:51-52` and `:196-199` | Decision 5: "fait tomber normalement, vitesse gardée". | `_speed_down_the_slope` takes the tilted contact normal of a ledge for a slope: on its last step on the floor a slide gets a downward speed about equal to its horizontal speed. Probe, 3 m ledge: a slide at 11.6 m/s leaves with -9.3 m/s and lands 2.77 m past the edge; a run at 9.3 m/s lands 3.70 m past it. On the course: -5.0 m/s when sliding off the big drop at 5 m/s. The core test uses a plane and cannot see it. | Owner slides off the big drop and judges. If unwanted: a real-physics scenario (a slide off a ledge flies at least as far as a run at the same speed), then the correction. |
| 4 | advisory (owner decides) | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\game\core\runner_motor.gd:222-227`; `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\test_runner_momentum.gd:11` | Decision 11: "en l'air, elle ne diminue pas". | True only in a straight line. Probe on the motor, in the air at 13.5 m/s: steering 30° leaves 12.63 m/s; steering 90° goes down to 7.81 m/s, below the top speed. The scenario test pushes forward, half forward, or nothing. | Owner says whether steering may cost momentum in the air. If not: one test case that steers, then the fix. |
| 5 | advisory | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\test_course_ground.gd:132`; `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\test_runner_slide.gd:216` | `AGENTS.md`, "Contributing workflow": each scenario becomes a test of the same name; a test without its scenario is a finding. | Two tests have no scenario, and both say so. Each is the only test that sees a break: `test_the_direction_of_a_slide_is_corrected_slowly` alone went red when the slide turned instantly, and `test_a_slide_gains_speed_down_the_ramp_of_the_low_passage` alone went red when the player stopped reporting the floor normal. | Owner adds the two scenarios to the spec (as done in the last round), or the tests go. |
| 6 | advisory | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\piloted_run.gd:97-100`; `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\course_test.gd:86-87` | Scenario "Le passage bas se franchit en glissade"; reactive-replays decision 4. | "Cleared" accepts a runner that comes to rest anywhere after the goal. With headroom forced to "never", the runner never stands up again, slides off the big drop 7 m after the checkpoint and stops 5 m lower: the low-passage test and its 8 variant runs stay green. Other tests caught that break. | In `_assert_cleared`, also require the runner to rest at the altitude of its goal. |
| 7 | advisory | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\test_runner_landing.gd:133-146` | Scenario "Sauter pendant une roulade garde la vitesse". | The roll is at exactly the top speed, so a jump that clamps the horizontal speed to the top speed leaves this test green (only the slide-jump test went red). | Drop the body faster than the top speed in this test. |
| 8 | advisory | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\test_runner_landing.gd:12-17` | Decision 16; base decision 20. | The comment says "a change of rounding must fail here". It does not: 0.20, 0.5 and 0.35 s are whole numbers of steps, and with truncation or with a ceiling every landing test stays green. Only the older tests of `test_runner_motor.gd` went red. The rule holds because the new durations share `_window_steps`. | Correct the comment, or give one landing test a duration that is not a whole number of steps. |
| 9 | advisory | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\README.md:89` | Decision 19 asks for the "Controls" section only; unrequested work. | The roadmap row is rewritten to say the ground moves "are in", before the merge and before the owner has played them. The other README edits are accurate and follow base decision 19. | Owner accepts the line, or it waits for the merge. |
| 10 | advisory (owners' file) | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\AGENTS.md:136` and `:142-143` | Skills index, type `harness`: an owner's review. | "Layout" no longer matches: `core/` now also holds the runner facts, and the test helpers now include `course_test.gd` and `motor_body.gd`. The developer rightly did not touch the file. | An owner updates the two lines. |

More on finding 1, since it weighs most:

- **The course itself is clean today.** No seam lies within the sweep before the beam.
  - 199 probe runs, all cleared: the low passage and the big drop with each of the four guaranteed values from ×0.90 to ×1.10 in steps of 0.01, and the low passage with `slide_deceleration` from ×0.5 to ×2.0.
  - The other 23 single-value changes of the new tuning (×1.25 and ×0.75) kept 82/82.
- **Where it bites next.** The first tuning-only PR that touches `slide_deceleration`, and any later course that hangs a low obstacle near a block seam.

### Decided by the code where the spec is silent

None of these breaks a rule; the owner should know they were choices.

- **The stick does nothing during a roll**: no steering and no braking for the 0.5 s; only the jump works. Probe: 20 steps pushing backwards, velocity unchanged. `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\game\core\runner_motor.gd:45-47`.
- **A roll that ends under a low ceiling continues as a slide** (`:160-162`). It is asserted inside the test of "Une roulade réussie garde la vitesse".
- **Holding the slide with the stick pushed never ends** (`:164-169`). The runner stands up under 2.5 m/s, runs 6 steps up to 5 m/s, slides again for 45 steps, and so on: about 4 m/s on average (probe).
- **The flat-ground slowdown also applies on slopes** (`:185-188`). With today's values a slope under about 5.2° still slows a slide; the 14° ramp gives a net +6.35 m/s², and a slide held down it peaks at 12.87 m/s (probe).
- **Above the top speed, any stick deflection keeps the full momentum** (`:222-226`): a half-pushed stick too. Only a released stick brakes.
- **The roll window is inclusive** (`:141`): 13 steps, from the step the motor first sees the floor back to 12 steps earlier. Same convention as the jump buffer.
- **A hard landing applies both limits from its first step** (`:143-146`, `:220-221`): a landing at 15 m/s keeps 3.15 m/s, not 5.25.
- **A buffered jump skips the roll.** A jump pressed inside the jump buffer before a rolled landing takes off on the landing step, with the speed kept. By reading only (`:49-50`).
- **The pilot jumps off the big drop.** The floor stops ahead, so the roll is proved on a 6.6 m fall, not on the 5 m run-off. It presses 5 steps before the motor sees the floor (probe).
- **`can_stand` is reported true without probing** while the runner is not low (`C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\game\player\player.gd:95`).

## 3. Spec coverage

The 32 scenarios each have a test of the same name; none is missing. Tests without a scenario: the two of finding 5.

Test files, all under `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261\tests\`: `test_runner_slide.gd` (1-11), `test_runner_landing.gd` (12-18), `test_runner_momentum.gd` (19-21), `test_player.gd` (22-23), `test_course_ground.gd` (24, 26-29), `test_course.gd` (25), `test_pilot.gd` (30-31), `test_debug_overlay.gd` (32).

"Red on" names the deliberate break I saw the test fail on; "by reading" means I ran no break aimed at it.

| # | Scenario | Test | Red on |
| - | -------- | ---- | ------ |
| 1 | La glissade démarre au sol avec assez de vitesse | `test_the_slide_starts_on_the_floor_with_enough_speed` | by reading |
| 2 | La glissade est refusée sans vitesse | `test_the_slide_is_refused_without_speed` | slide ignoring the minimum speed |
| 3 | La glissade ne démarre pas en l'air | `test_the_slide_does_not_start_in_the_air` | slide kept after leaving the floor |
| 4 | Tenir la glissade en atterrissant la lance | `test_holding_the_slide_while_landing_starts_it` | by reading |
| 5 | La glissade ralentit sur le plat puis le coureur se relève | `test_the_slide_slows_down_on_the_flat_then_the_runner_stands_up` | deceleration doubled; no stand-up under the floor speed |
| 6 | La glissade accélère en descente | `test_the_slide_accelerates_downhill` | no slope pull; pull from rise gravity |
| 7 | Relâcher la glissade relève le coureur | `test_releasing_the_slide_stands_the_runner_up` | by reading |
| 8 | Le coureur reste baissé sous un plafond bas | `test_the_runner_stays_low_under_a_low_ceiling` | stand-up ignoring the ceiling |
| 9 | Le coureur ne reste pas coincé sous un plafond bas | `test_the_runner_does_not_get_stuck_under_a_low_ceiling` | floor speed removed |
| 10 | Pas de saut sous un plafond bas | `test_no_jump_under_a_low_ceiling` | jump allowed under the ceiling |
| 11 | Sauter en glissade garde la vitesse | `test_jumping_while_sliding_keeps_the_speed` | jump clamped to the top speed |
| 12 | Une roulade réussie garde la vitesse | `test_a_successful_roll_keeps_the_speed` | window short by one step; roll steered; roll ending upright under a ceiling |
| 13 | Une réception lourde coûte de la vitesse | `test_a_hard_landing_costs_speed` | no cut at landing; no cap during; fall not measured from the apex |
| 14 | Une glissade pressée trop tôt ne donne pas de roulade | `test_a_slide_pressed_too_early_gives_no_roll` | window that never closes |
| 15 | Une glissade tenue depuis avant la fenêtre ne donne pas de roulade | `test_a_slide_held_since_before_the_window_gives_no_roll` | hold counted as a press |
| 16 | Une petite chute se reçoit normalement | `test_a_small_fall_is_landed_normally` | threshold halved |
| 17 | Pas de saut pendant une réception lourde | `test_no_jump_during_a_hard_landing` | jump allowed |
| 18 | Sauter pendant une roulade garde la vitesse | `test_jumping_during_a_roll_keeps_the_speed` | none; green on the clamped jump (finding 7); by reading |
| 19 | L'élan au-dessus de la vitesse de pointe se garde en l'air | `test_momentum_above_top_speed_is_kept_in_the_air` | momentum lost in the air; straight line only (finding 4) |
| 20 | L'élan redescend lentement au sol | `test_momentum_comes_down_slowly_on_the_floor` | momentum taken at the ground acceleration |
| 21 | La vitesse horizontale a un plafond absolu | `test_the_horizontal_speed_has_an_absolute_cap` | cap removed |
| 22 | Presser la glissade se lit dans l'intention | `test_pressing_the_slide_is_read_in_the_intent` | pressed read as held |
| 23 | La capsule s'abaisse en glissade et se relève après | `test_the_capsule_lowers_while_sliding_and_rises_after` | mesh not lowered; collider not lowered; headroom always true; shapes shared between runners |
| 24 | Le retour au checkpoint relève le coureur | `test_returning_to_the_checkpoint_stands_the_runner_up` | teleport without fitting the capsule; reset keeping the state |
| 25 | La section des marches se franchit | `test_the_steps_section_can_be_cleared` | pilot always sliding; pilot sliding at any obstacle |
| 26 | Le passage bas se franchit en glissade | `test_the_low_passage_can_be_cleared_by_sliding` | beam too high, beam too low, collider not lowered; green when the runner never stands up again (finding 6) |
| 27 | Le passage bas arrête un coureur debout | `test_the_low_passage_stops_a_standing_runner` | beam raised to standing height |
| 28 | La grande chute mène à l'arrivée | `test_the_big_drop_leads_to_the_finish` | drop under the threshold; altitude not reported; pilot pressing too early |
| 29 | La roulade fait gagner du temps sur la grande chute | `test_the_roll_saves_time_on_the_big_drop` | hard landing that costs nothing |
| 30 | Le pilote glisse sous un obstacle bas qu'il ne connaît pas | `test_the_pilot_slides_under_a_low_obstacle_it_does_not_know` | pilot without its ceiling probe; without look-ahead; also red on an innocent tuning change (finding 1) |
| 31 | Le pilote ne glisse pas sans raison | `test_the_pilot_does_not_slide_without_a_reason` | pilot always sliding |
| 32 | L'affichage de debug montre les nouveaux états | `test_the_debug_display_shows_the_new_states` | by reading (the three state names and the six durations are asserted as text) |

The four "changée de 10 %" tests now play the six sections (12 runs each), as decision 15 asks. For the big drop they prove "cleared", not "rolled": with a pilot that presses too early they stay green, which matches the wording of their scenarios.

## 4. Not verifiable here: what only the owner can judge, controller in hand

**Slide**
- The 5 m/s start threshold, and starting one by holding the button while landing.
- The slowdown on the flat: from the top speed, 1.6 s and 9.3 m before standing up at 2.5 m/s.
- Holding the button with the stick pushed: the slide-run cycle described above.
- Steering at 1 rad/s, with no acceleration from the stick.
- The ramp, and the momentum that follows: about 13 m/s at its foot, then 6 m/s² lost on the floor.
- Jumping out of a slide.
- Sliding off a ledge (finding 3).

**Low beam**
- Staying low under it, creeping at 2.5 m/s, with the jump refused and nothing on screen saying why.
- Releasing the slide just before the beam: the runner stands up and hits it.
- Whether a grey beam reads as "slide here".

**Roll and hard landing**
- The 0.20 s window, with no cue for when to press.
- 0.5 s without any stick control during the roll.
- The hard landing: speed cut, 3.15 m/s at most for 0.35 s, jump refused silently.
- Which falls ask for a roll. The height is measured from the top of the jump, so a jump from a ledge 2.4 m high already does.

**Readability**
- The capsule and visor snap between 1.8 m and 0.9 m in one step, with no easing.
- Slide and roll look identical; the hard landing shows nothing.

**Camera** (file unchanged, situations new)
- It keeps aiming 1.6 m above the feet during a slide.
- Under the beam (underside 1.2 m above the floor) the pivot of the spring arm is inside the beam. What the camera does there has to be seen.
- The 5 m fall.

**Inputs**
- Left Ctrl held with W and Space; B or RB on a real gamepad.
- The same button for the slide and the roll.

**Debug display**
- Seven lines; one "LANDING" line serves both the roll and the hard landing.

**Course**
- The proportions of the two sections: 10 m run-up, 8 m ramp, 8 m flat, 3 m beam, 5 m drop, 20 m to the line.
- Respawning at the two new checkpoints.

## 5. What I did not check

- **The developer's report and the PR description**: not read, on purpose. I read the commit messages.
- **`just build`, `just check`, `just preflight`**: not run. For the build I rely on the CI status; I did not read its logs.
- **Decision 20 (preflight under 30 s)**: I only have the four gates run one after the other, 27.8 s in total on this machine today, about 2 s under the limit. I did not see the developer's timings.
- **The intermediate commits**: I inspected the range as a whole and did not gate the six earlier commits one by one. The test-first order is not checked either.
- **Linux**: every probe and every broken variant ran on this Windows machine only.
- **The game on screen**: never opened. Nothing in section 4 was seen, and no keyboard or gamepad was used.
- **Tuning combinations**: only one value at a time. The fine sweep of the four guaranteed values covered the two new sections, not the four older ones.
- **The correction proposed in finding 1**: tried on the copy against the suite, nothing more.
- **Why the low probe catches on a seam and the standing one does not**: I observed it step by step and did not read the engine's source.
- **Scenarios 1, 4, 7, 18 and 32**: judged by reading, with no break aimed at them.
- **Finding 2**: shown on a track I built; I did not look for a place on the real course that triggers it beyond noting that the floor under the beam is one block.
`````

### Développeur, passe 2 (commit 06f31c4)

`````markdown
# Developer report, second pass — `docs/specs/movement-ground.md`

All eight points of the inspection are dealt with, and the spec status is back to Implémenté. All 37 scenarios of the amended spec have a test of the same name, and `just check` is green on the last commit (85 tests). The tree is clean.

One thing differs from what the inspection expected. The first fix for the pilot (the probe lifted by the safe margin) was incomplete:
- the suite stayed red at a slide deceleration of 4.5 and 6.0;
- the real cause is the runner's body sinking into the joint between two floor blocks;
- a second commit fixes it, and the pilot test now passes at 4.0, 4.5, 5.0 and 6.0;
- that last fix is proven only by this deceleration sweep: at the project tuning no test fails if it is reverted (Questions 1).

I was cut off by a usage limit after the fourth commit of this pass, while a batch of deliberate breaks was running; it finished and restored every file.
- Before the interruption: the red-before evidence of fixes 1 to 4, and the list of deliberate breaks under Vérifié. Those breaks ran on the pilot of `d8772d4`, with the test tightenings already in the tree.
- After it: the fix 4 investigation and `0553a62`, the slide deceleration sweep on the final pilot, the fix 6 break, the two pilot probe breaks, and every gate and timing.

- **Worktree:** `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261`
- **Branch:** `movement-ground`, 9 commits ahead of `origin/movement-ground`, not pushed.

| Commit | Content |
| ------ | ------- |
| `383dd61`, `efa972f` | owners: spec amendments, `AGENTS.md` layout (not mine) |
| `c5413e2` | core: a slide that ended too slow needs a new press (fix 1) |
| `bc006c7` | core: a low runner that loses the floor stays low while it cannot stand up (fix 2) |
| `cec652e` | player: the edge of a block is not a slope (fix 3, and the renamed ramp test) |
| `d8772d4` | tests: the pilot holds a slide in one go, first fix for the probes (fix 4, part 1) |
| `0553a62` | tests: the pilot probes from the ground, not from a body sunk in a floor joint (fix 4, part 2) |
| `770c0a8` | tests: cleared section at the altitude of its goal, roll faster than the top speed, a roll window that is not a whole number of steps, momentum when turning (fixes 6, 7, 8) |
| `06f31c4` | docs: spec status |

The first four commits of this pass end with the Fable 5.2 attribution line; the last three with Opus 5.5, as asked.

## Fait

**Fix 1, slide restart (decision 3).** In `game/core/runner_motor.gd`, a slide that ended under its least speed with the button held does not start again until the button is released. Holding the button while landing still starts a slide. A roll that ends with the button held still goes on as a slide; that is now asserted in `test_a_successful_roll_keeps_the_speed`. README Controls: one sentence.
- Scenario "Une glissade terminée par la lenteur ne redémarre pas toute seule": `test_a_slide_ended_by_slowness_does_not_restart_by_itself` (`tests/test_runner_slide.gd`).

**Fix 2, low runner losing the floor (decision 6).** In the motor, `is_low()` stays true in the air while the runner cannot stand up, and that holds the capsule low and the jump refused. The runner straightens up as soon as there is room, and goes on as a slide if it finds a floor first.
- Scenario "Le coureur reste baissé en quittant le sol sous un plafond bas": `test_the_runner_stays_low_when_leaving_the_floor_under_a_low_ceiling` (`tests/test_runner_slide.gd`).
- Real physics, cheaply: the pilot test now also crosses a crack 0.85 of the body wide under the beam, and asserts the runner is low at every step under it (see fix 4).

**Fix 3, slide off a ledge (decision 5).** The correction is in `game/player/player.gd`. The player reports as floor normal the normal of the ground right under the feet, found by a ray straight down a capsule radius deep, and straight up when there is none. It no longer reports the contact normal of the body.
- Why there: the motor is right to follow a slope. What was wrong is the fact it received: over the edge of a block the contact is tilted, and that edge is not a slope. The motor stays pure and unchanged, and the ramp test stays green.
- Scenario "Glisser hors d'un rebord ne plaque pas le coureur vers le bas": `test_sliding_off_a_ledge_does_not_push_the_runner_down` (`tests/test_course_ground.gd`). Two courses side by side at the edge of the big drop, both runners launched at 13.5 m/s, one sliding and one running; the slider must land at least as far.
- Scenario "Une glissade gagne de la vitesse sur la rampe du passage bas": the test is renamed `test_a_slide_gains_speed_on_the_ramp_of_the_low_passage` (it was `..._down_the_ramp_...`). It also checks now that the runner never leaves the floor on the ramp and is faster at the bottom than at the top.

**Fix 4, pilot letting go at floor joints (decision 14).** In `tests/pilot_intent_source.gd`:
- its probe bodies stand on the ground under the feet, found by a ray, or on the feet when those are higher (slope, crack, air), plus the body's safe margin;
- the step probe uses the same cast instead of `test_move` from the body;
- under a low ceiling the slide stays held even when the floor is gone (crack).

`test_the_pilot_slides_under_a_low_obstacle_it_does_not_know` (`tests/test_pilot.gd`) now plays two courses side by side, one with a floor joint under the beam and one with a crack. It asserts:
- exactly one slide press;
- the slide held from that press until the whole body is out from under the beam;
- the runner low at every step under the beam;
- no jump, and the runner standing at the end.

**Fix 5, names.** "La direction d'une glissade se corrige lentement" keeps `test_the_direction_of_a_slide_is_corrected_slowly`, which is its English equivalent; only its "not a scenario" comment is removed. The ramp test is renamed (fix 3).

**Fix 6, what "cleared" means.** In `tests/course_test.gd`, `_assert_cleared` also requires the runner to rest at the altitude of its goal, within 5 cm (`NEAR`, already in the file). No number is tuned on the course.

**Fix 7.** "Sauter pendant une roulade garde la vitesse" now rolls at 1.5 times the top speed, and asserts the roll is faster than the top speed.

**Fix 8.** The comment of `tests/test_runner_landing.gd` is corrected: the three durations are whole numbers of steps. `test_a_slide_pressed_too_early_gives_no_roll` adds a roll window of 0.21 s (12.6 steps): a press 13 steps before the floor rolls, a press 14 steps before lands hard.

**Momentum while turning (decision 11 amendment).** One case is added to `test_momentum_above_top_speed_is_kept_in_the_air`: pushing sideways in the air costs speed, and the runner does turn. No behaviour change.

## Vérifié

**Gates, on the last commit `06f31c4`, clean tree.** `just check` is green in 28.7 s:

```
typecheck: 32 script(s), 0 with errors
gdlint: no problems / gdformat: 32 files would be left unchanged
test_course.gd 16/16 · test_course_ground.gd 7/7 · test_debug_overlay.gd 2/2 · test_input_map.gd 2/2
test_pilot.gd 6/6 · test_player.gd 4/4 · test_race_hud.gd 2/2 · test_race_state.gd 8/8
test_runner_landing.gd 7/7 · test_runner_momentum.gd 3/3 · test_runner_motor.gd 14/14 · test_runner_slide.gd 14/14
Tests 85 · Passing 85 · Asserts 1430 · Time 11.161s
structure: boundaries 0 · dead files 0 · .claude mirror 0 · 37 file(s) checked
build: Windows Desktop ran 60 frames headless · Linux exported
```

- 85 tests = 48 from the earlier specs + 37 for this spec, one per scenario. Checked by script: every name is present, and no test is left without a scenario.
- Both tests that were added without a scenario in the first pass now have one.

**Timings (decision 20).**

| | Before this pass (`85aee0d`) | After (`06f31c4`) |
| --- | --- | --- |
| `just preflight` | 19.8 s | 20.6, 20.2, 20.2 s (three runs, one after the other) |
| `just check` | 28.2 to 29.1 s | 29.1 s, 28.7 s |

During the pass, before the interruption, one `just preflight` took 40.1 s and some `just check` runs took 40 to 46 s. They were all green, and the machine was busy at that time. Every run measured after the interruption is under 30 s.

**No unexplained red run.** Every red was expected: a test written first, a deliberate break, a tuning sweep, or one break definition that did not apply (fixed, then re-run).

**Red before the fix**

| Fix | Evidence |
| --- | -------- |
| 1 | The restart test was red before the code: with the button held, the runner was sliding again within 60 steps (state `SLIDING` at step 59, 5.2 m/s instead of 9). |
| 2 | The low-in-the-air test was red before the code: back on a floor under the ceiling, the runner was standing. |
| 3 | The ledge test was red before the fix: the slider landed 4.20 m past the edge, the runner 4.84 m. |
| 4 | The strengthened pilot test was red before `d8772d4`: 3 presses over the joint and 5 over the crack, with 4 and 7 steps without the slide held. It was still red after `d8772d4` at slide deceleration 4.5 (a jump) and 6.0 (a second press, and a jump); green after `0553a62`. |
| 6 | Deliberate break, the big-drop checkpoint moved to the edge of the drop: the low-passage section is green without the new assertion, red with it (the runner rests 4.999 m below its goal). |
| 7 | Deliberate break, a jump that clamps the horizontal speed to the top speed: `test_jumping_during_a_roll_keeps_the_speed` is red (with `test_jumping_while_sliding_keeps_the_speed`). |
| 8 | Deliberate break, durations truncated instead of rounded: `test_a_slide_pressed_too_early_gives_no_roll` is red (with the existing rounding test). |

**Deliberate breaks on the fixes.** Each break was followed by the suite at the project tuning, then the file was restored byte for byte. All of these turn at least one test red:
- the player never reports room to stand up;
- a low runner stands up when it loses the floor;
- a runner back on a floor under a ceiling stands up;
- the player reports the contact normal again;
- a slide restarts by itself;
- releasing the slide no longer allows a new one;
- the pilot's probes back flush with the floor;
- the pilot lets go of the slide in the air.

Two breaks stay green at the project tuning: the probe base set from the body instead of the ground, and the step probe back to `test_move` (Questions 1).

**Fix 4: suite at `slide_deceleration` 4.0, 4.5, 5.0, 6.0.** The `.tres` was changed only for each run and restored; it was never committed.

| Value | Before `d8772d4` | After `d8772d4` | After `0553a62` |
| ----- | ---------------- | --------------- | --------------- |
| 4.0 | red (strengthened pilot test) | 85/85 | 85/85 |
| 4.5 | (inspection: red) | 84/85: one jump after the beam, crack course | 85/85 |
| 5.0 | (inspection: red) | 85/85 | 85/85 |
| 6.0 | (inspection: red) | 84/85: let go before the beam, 2 presses, 1 jump, joint course | 85/85 |

**Cause of fix 4, logged step by step.** At the joint of two floor blocks, the runner's body sinks for one step by 1.4 to 1.6 mm (y = -0.0016 and -0.0014). That is more than the 1 mm safe margin the first fix lifted the probes by. A probe set from the body then starts inside the floor and stops on the edge of the next block:
- the standing probe was free for 0.008 of its sweep, the low one for 0.027;
- `test_move` reported an obstacle 0.01 m ahead.

The inspector's lead (lift by the safe margin) was right in direction but not enough. On a plain block, a low probe flush with the floor was free for only 0.564 of a 2.5 m sweep, 3 m from any joint; lifted by 0.1 mm it was free for all of it.

## Non vérifié

**Only the owner can judge, controller in hand**
- The slide that needs a new press after it ran out of speed: does it read well with the button held?
- A slide leaving a ledge: it now leaves horizontally, like a run. The landing point when sliding off the big drop, against what it was.
- A low runner crossing a narrow crack under a low obstacle: it stays low and goes on. Nothing like that exists on the test course; it is proven only in `test_pilot.gd` and in the motor tests.
- Turning in the air above the top speed costs speed (decision 11, amended); unchanged behaviour, now documented by a test.

**Not run here**
- **Linux CI.** Nothing pushed by me. The joint dip is an engine detail (Jolt); whether it is the same under Linux is not known.
- **The ground-under-the-feet probe in the game** (`player.gd`), on slopes other than the 14 degree ramp and on steps. It is covered by the ramp and ledge tests only.
- **Ledge landing distances after the fix.** The test asserts the slider lands at least as far as the runner; the distances were not printed.
- **The tuning sweep** covers `slide_deceleration` only. The other new values were measured in the first pass, before these fixes, and not measured again.

## Écarts

1. **Fix 4 took two commits.** `d8772d4` says the cause is "a probe flush with the floor"; `0553a62` corrects it (the body sinks into the joint) and completes the fix. Earlier commits are not rewritten.
2. **Fix 3 lives in the player, not the motor.** The motor's rule (follow and speed up on a slope) was right; the fact it was given was wrong. That keeps `game/core` unchanged and pure, and the edge of a block is something only the player can observe.
3. **Fix 2 in the real physics** goes through the pilot test (a crack under the beam) rather than a separate course test; the motor test proves the rule. With a crack 0.85 of the body wide the runner dips 4.5 cm, with one 1.2 wide about 8 cm, and goes on low in both (probe before the interruption).
4. **The strengthened pilot test asserts more than the scenario:** the runner low at every step under the beam, and the crack course. It is the cheapest real-physics proof of decision 6.
5. **Fix 6, case of the inspection.** With fix 2 in, a runner that never gets room to stand up no longer reaches the goal at all: the low passage ends `OUT_OF_STEPS`, red even without the new assertion. That is why fix 6 is proven on another break (the checkpoint on the edge).
6. **Tried and dropped.** Playing the joint course at 5, 10 and 20 run-up phases (fractions of a stride) to catch the joint dip at the project tuning. Even at 20 phases the reverted probe stayed green, so I did not keep the extra courses.

## Questions

1. **The joint fix of the pilot is proven only off the project tuning.** At 4.0 no committed test fails if `_probe_feet` or the step cast is reverted: the dip only matters when the runner meets a joint at certain speeds and states. Options:
   - accept, with the sweep above as evidence;
   - add a pilot test on a copy of the tuning with a changed slide deceleration (a value found by me to trigger it, so close to a tuned number);
   - add a test that puts a body exactly on a joint.
2. **The joint dip itself** (Jolt, 1.4 to 1.6 mm for one step) is reported, not worked around in the game. Does the owner feel anything at the joints of the course? None of my tests shows an effect on the runner itself.

---

- **Branch:** `movement-ground`, in `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261`
- **Last commit:** `06f31c4`
- **Commits of this pass, oldest first:** `c5413e2`, `bc006c7`, `cec652e`, `d8772d4`, `0553a62`, `770c0a8`, `06f31c4`
`````

### Inspecteur, seconde inspection (sur 06f31c4)

`````markdown
# Inspection: `movement-ground` (`2ac9d2b..06f31c4`, PR 9), second inspection

## 1. Verdict

**Conforme.** I found no blocking finding. There are three advisory findings, all on behaviour that the tests do not pin down well enough.

## 2. Findings

| # | Severity | File:line | Rule | Finding | Proposal |
|---|----------|-----------|------|---------|----------|
| 1 | advisory | `tests/test_course_ground.gd:96` (assertion at :128) | Scenario "Glisser hors d'un rebord ne plaque pas le coureur vers le bas"; `AGENTS.md` "Contributing workflow" (a tuning-only change still needs a green CI); the reason given for amendment 14 | Both runners are launched at 1.5 × top speed 7 m before the edge. On the way, the slider loses 4 m/s² and the runner loses 6 m/s², so the slider reaches the edge faster. The test therefore depends on `slide_deceleration` < `momentum_deceleration`. On a copy, with the code fixed, it goes **red after a tuning-only change**: `slide_deceleration` 7.0 (red, while 6.0 stays green) or `momentum_deceleration` 2.0. The same head start (the slider lands 0.70 m farther) also hides any push-down that costs less than 0.70 m. With the contact normal put back (the bug), it fails by only 0.64 m. | Give both runners the same speed **at the edge**. Either launch them from the edge itself, or compare each flight distance with that runner's own take-off speed. Alternatively, assert that the slider's vertical speed at its first step in the air equals the runner's. |
| 2 | advisory | `game/core/runner_motor.gd:239` | Decision 9 ("ne peut pas dépasser ce même pourcentage de la vitesse de pointe"); accepted choice "Réception lourde plus rapide que la vitesse de pointe" | No test fails when the clamp `horizontal.limit_length(top_speed)` is removed: I ran the mutation and `test_runner_landing` stays 7/7. Every hard landing in the tests starts at or below top speed, so the ×0.35 at landing already gives the capped value. The accepted choice (a landing faster than top speed ends at 35 % of top speed) is not proven. | In `test_a_hard_landing_costs_speed`, add a landing at 1.5 × top speed and assert that the speed is ≤ 35 % of top speed from the first step. |
| 3 | advisory | `game/core/runner_motor.gd:128` | Decision 8 (above the threshold: roll or hard landing) against amendment 6 | A runner that is low in the air and lands where it cannot stand goes straight to SLIDING. `_land()` is skipped, so a fall of more than 4 m in that case gives neither a roll check nor a hard landing. The spec does not say which decision wins. This cannot happen on the current course. | Have the owner settle it. If decision 8 should apply, run the fall-height check before choosing SLIDING. |

## 3. Spec coverage

All 37 scenarios have a test with the matching snake_case name. Each one asserts the behaviour, not internals.

| Scenario | Test |
|---|---|
| La glissade démarre au sol avec assez de vitesse | `test_runner_slide.gd::test_the_slide_starts_on_the_floor_with_enough_speed` |
| La glissade est refusée sans vitesse | `test_the_slide_is_refused_without_speed` |
| La glissade ne démarre pas en l'air | `test_the_slide_does_not_start_in_the_air` |
| Tenir la glissade en atterrissant la lance | `test_holding_the_slide_while_landing_starts_it` |
| La glissade ralentit sur le plat puis le coureur se relève | `test_the_slide_slows_down_on_the_flat_then_the_runner_stands_up` |
| La glissade accélère en descente | `test_the_slide_accelerates_downhill` |
| Relâcher la glissade relève le coureur | `test_releasing_the_slide_stands_the_runner_up` |
| Le coureur reste baissé sous un plafond bas | `test_the_runner_stays_low_under_a_low_ceiling` |
| Le coureur ne reste pas coincé sous un plafond bas | `test_the_runner_does_not_get_stuck_under_a_low_ceiling` |
| Pas de saut sous un plafond bas | `test_no_jump_under_a_low_ceiling` |
| Une glissade terminée par la lenteur ne redémarre pas toute seule | `test_a_slide_ended_by_slowness_does_not_restart_by_itself` (mutation without `_slide_spent`: red) |
| La direction d'une glissade se corrige lentement | `test_the_direction_of_a_slide_is_corrected_slowly` |
| Le coureur reste baissé en quittant le sol sous un plafond bas | `test_the_runner_stays_low_when_leaving_the_floor_under_a_low_ceiling` (plus, in real physics, `steps_standing_under == 0` over a crack in `test_pilot.gd`) |
| Sauter en glissade garde la vitesse | `test_jumping_while_sliding_keeps_the_speed` |
| Une roulade réussie garde la vitesse | `test_runner_landing.gd::test_a_successful_roll_keeps_the_speed` |
| Une réception lourde coûte de la vitesse | `test_a_hard_landing_costs_speed` (see finding 2) |
| Une glissade pressée trop tôt ne donne pas de roulade | `test_a_slide_pressed_too_early_gives_no_roll` |
| Une glissade tenue depuis avant la fenêtre ne donne pas de roulade | `test_a_slide_held_since_before_the_window_gives_no_roll` |
| Une petite chute se reçoit normalement | `test_a_small_fall_is_landed_normally` |
| Pas de saut pendant une réception lourde | `test_no_jump_during_a_hard_landing` |
| Sauter pendant une roulade garde la vitesse | `test_jumping_during_a_roll_keeps_the_speed` |
| L'élan au-dessus de la vitesse de pointe se garde en l'air | `test_runner_momentum.gd::test_momentum_above_top_speed_is_kept_in_the_air` (mutation without momentum: red) |
| L'élan redescend lentement au sol | `test_momentum_comes_down_slowly_on_the_floor` |
| La vitesse horizontale a un plafond absolu | `test_the_horizontal_speed_has_an_absolute_cap` |
| Presser la glissade se lit dans l'intention | `test_player.gd::test_pressing_the_slide_is_read_in_the_intent` |
| La capsule s'abaisse en glissade et se relève après | `test_the_capsule_lowers_while_sliding_and_rises_after` |
| Le retour au checkpoint relève le coureur | `test_course_ground.gd::test_returning_to_the_checkpoint_stands_the_runner_up` (all three states) |
| La section des marches se franchit | `test_course.gd::test_the_steps_section_can_be_cleared` (renamed under decision 13; body unchanged) |
| Le passage bas se franchit en glissade | `test_the_low_passage_can_be_cleared_by_sliding` |
| Une glissade gagne de la vitesse sur la rampe du passage bas | `test_a_slide_gains_speed_on_the_ramp_of_the_low_passage` |
| Glisser hors d'un rebord ne plaque pas le coureur vers le bas | `test_sliding_off_a_ledge_does_not_push_the_runner_down` (red with the contact normal put back; see finding 1) |
| Le passage bas arrête un coureur debout | `test_the_low_passage_stops_a_standing_runner` |
| La grande chute mène à l'arrivée | `test_the_big_drop_leads_to_the_finish` |
| La roulade fait gagner du temps sur la grande chute | `test_the_roll_saves_time_on_the_big_drop` |
| Le pilote glisse sous un obstacle bas qu'il ne connaît pas | `test_pilot.gd::test_the_pilot_slides_under_a_low_obstacle_it_does_not_know` (over a seam and over a crack; one press, never released, low all the way under) |
| Le pilote ne glisse pas sans raison | `test_the_pilot_does_not_slide_without_a_reason` |
| L'affichage de debug montre les nouveaux états | `test_debug_overlay.gd::test_the_debug_display_shows_the_new_states` |

The four reactive-replays "± 10 %" tests keep their names and now run all six sections (decision 15).

## 4. Other checks (no finding)

- **Assertions from `main`.** None was removed or weakened. The helpers and `_assert_cleared` moved word for word into `tests/course_test.gd`. `_assert_cleared` gained one assertion (the runner ends at the altitude of its goal). `test_the_same_intents_give_the_same_result` only had its inputs widened (random facts, pushes), and its assertion "visits every state" now requires all 6 states. `test_the_pilot_clears_a_course_it_does_not_know` gained `slide_requests == 0`. Nothing is skipped or pending.
- **The pilot uses no number calibrated on the course or on the current values** (reactive-replays decision 3). It takes every look-ahead from the tuning and from probes: the window depth comes from `max_fall_speed × roll_window`, the fall height from `roll_fall_height`, and the probe heights from `capsule_height` / `slide_capsule_height`. Its feet are set on the ground plus the engine's `safe_margin`. The only constant is "half the roll window", a margin, not a calibration.
- **Tuning-only changes, on a copy**, running `test_course` (16 tests, including the four ±10 % ones over the six sections) and `test_course_ground` (7 tests). All green with:
  - `slide_deceleration` 3 / 4.5 / 6
  - `slide_capsule_height` 0.7 / 1.1 / 1.15
  - `roll_window` 0.08 / 0.12 / 0.3
  - `roll_fall_height` 3 / 4.5
  - `slide_min_speed` 7, `slide_stop_speed` 4
  - `momentum_deceleration` 4 / 5 / 12, `max_horizontal_speed` 12
  - `roll_duration` 1.0
  - `hard_landing_speed_ratio` 0.6, `hard_landing_duration` 0.1
  - `slide_turn_speed` 3

  The only red tests were the ones in finding 1.
- **Layers and simulation rules.** `core` only decides, and every input reaches it through `MoveIntent` and `RunnerFacts`. `player` only observes and executes:
  - it reports the floor normal from a straight-down ray, falling back to UP;
  - it reports headroom through `test_move`;
  - it sets the capsule height from `motor.is_low()`.

  Everything runs in `_physics_process`. Every new feel value is in `movement_tuning.tres` and matches the spec table. No numbers are written into `core`, `player` or `ui`. Debug labels are in `game/ui/`, in English. Nothing from `movement-walls.md` is present. No asset was added.
- **Accepted choices.** All nine match the code: the buffered jump after a hard landing; hard landing above top speed ending at 35 % of top speed (behaviour matches, but untested, see finding 2); deceleration also on slopes; no steering in a roll; roll into slide; jump buffered into a roll; momentum kept under any pushed direction; the pilot jumping off the big drop (6.6 m fall); the README roadmap.
- **`AGENTS.md` Layout** (`efa972f`) matches the code: `runner_facts.gd` is in `core/`, and `motor_body.gd`, `course_test.gd` and `replay_test.gd` are the test helpers.
- **README.** "Controls" describes the slide and the roll (decision 19).
- **Decision 20.** `just preflight` took 21.1 s in one timed run. The suite ran green 85/85 three times.
- **Unrequested work.** Nothing significant. `resource_local_to_scene` on the capsule shape and mesh is needed so each runner instance has its own capsule. The `CourseTest` extraction is needed to share helpers with the new test file.

## 5. Not verifiable here (needs the controller in hand)

- The feel of the slide:
  - start threshold (5 m/s);
  - deceleration 4 m/s²;
  - turning 1 rad/s;
  - the fact that a slope under about 5° does not accelerate a slide;
  - having to re-press after a slide that ended too slow.
- The roll timing: whether a 0.20 s window (13 steps counting the landing step) feels fair with a real thumb on Left Ctrl and on B/RB. Whether the 0.35 s, 35 % hard landing feels like the right price.
- The roll's 0.5 s with no steering at all.
- Momentum above top speed: how it feels on the ground at 6 m/s², and in the air when turning.
- The camera during a slide or roll: the look height stays at 1.6 m while the capsule drops to 0.9 m.
- The capsule squash itself.
- The readability of the low beam and of the big drop.
- Whether the debug overlay's seven lines fit its box on screen.
- The whole course run from start to finish in one go. Each section is only proven from its checkpoint, at rest.

## 6. What I did not check

- I did not run `just build` or `just check`, so the exports are not verified. I did not check CI on PR 9.
- I did not check on Linux.
- I did not play on keyboard, mouse or gamepad.
- I did not read the GUT addon or `tools/`.
- I did not mutation-test the pilot's seam and crack handling, the low-ceiling rules, or the roll-window rules. I only read them and saw them green.
`````

### Développeur, passe 3 (commit e0f0ab5)

`````markdown
# Developer report, third pass — `docs/specs/movement-ground.md`

Both tests now pin their behaviour. Only test files changed; the game code and the spec did not. `just check` is green on the commit.

One new problem for the owner (Questions): at `slide_deceleration` 7.0 the pilot test fails, because a slow slide gets stuck in a crack narrower than the runner, under a low obstacle.

- **Worktree:** `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a02f534301d241261`
- **Branch:** `movement-ground`, 2 ahead of `origin` (your `daed147`, then mine), not pushed.
- **Commit:** `e0f0ab5` — tests: a fair ledge comparison, and a hard landing faster than the top speed.

## Fait

**1. `test_sliding_off_a_ledge_does_not_push_the_runner_down` (`tests/test_course_ground.gd`).** The comparison of landing distances is replaced by what a push down changes whatever the speed at the edge. A small `Flight` class follows each runner from the ledge to its landing. The test asserts:
- the slider's vertical speed at its first step off the floor is no more downward than the runner's;
- the slider spends at least as many steps falling to the same floor as the runner, give or take one fixed step;
- both land on the same floor (within 5 cm) and below the ledge, one sliding off it and the other running.

The one-step allowance is the unit of the measurement, not a tuned number. How many steps a body takes to roll off the corner depends on where its steps fall: at `momentum_deceleration` 2.0 the runner fell 29 steps and the slider 28, with no push at all. The contact-normal bug costs 7 steps.

**2. `test_a_hard_landing_costs_speed` (`tests/test_runner_landing.gd`).** A landing at 1.5 times the top speed is added. It must be a hard landing, and it must be no faster than 35 % of the top speed from its first step and at every step of its duration.

No existing assertion is removed except the landing-distance comparison of test 1, which item 1 replaces.

## Vérifié

**`just check` green on `e0f0ab5`:** 85 tests, 85 passing, 1453 assertions; GUT time 11.16 s; the whole gate 29.3 s. Structure 0 problems, Windows build ran 60 frames, Linux exported.

**Red and green evidence.** Each change was temporary and the file restored byte for byte afterwards. The `.tres` was never committed.

| Change | Result |
| ------ | ------ |
| Values at the project tuning (print only) | 0.000 m/s down for both, 28 steps in the air for both |
| Contact normal put back in `player.gd` (the bug) | ledge test red on both assertions: -7.65 m/s against 0.0, and 21 steps against 28 |
| `slide_deceleration` 7.0 | ledge test green |
| `momentum_deceleration` 2.0 | ledge test green (28 steps against 29: within the step) |
| Hard-landing clamp removed (`runner_motor.gd:239`) | `test_a_hard_landing_costs_speed` red: 4.22, 3.72, 3.22 m/s against a cap of 3.15 |

## Non vérifié

- Linux CI: nothing pushed by me.
- The whole suite at `slide_deceleration` 7.0 and `momentum_deceleration` 2.0: run once each before the one-step allowance, then only the ledge test after it.
  - At `momentum_deceleration` 2.0 the only red was the ledge test, on the air time (28 against 29); the allowance covers it.
  - At `slide_deceleration` 7.0 the pilot test is red (Questions).
- Nothing new to feel with the controller: no game code changed.

## Écarts

1. **One fixed step of allowance on the air time**, explained above. Without it the test is red after a tuning-only change (`momentum_deceleration` 2.0).
2. **The vertical speed is compared exactly**, with no tolerance: on a real take-off both values are exactly 0 (the motor sets the vertical speed to 0 on a floor).

## Questions

1. **A slow slide gets stuck in a crack under a low obstacle.** At `slide_deceleration` 7.0, `test_the_pilot_slides_under_a_low_obstacle_it_does_not_know` fails on its crack course: `OUT_OF_STEPS`, and the runner is still `SLIDING` at the end. Not investigated step by step; my reading:
   - at that deceleration the runner reaches the crack (0.85 of its width) at the least slide speed;
   - over the crack it is in the air, where the least speed of decision 6 does not apply;
   - it stays caught between the two edges.

   The cause comes from the previous pass, not from this one, and the value is outside the guaranteed range (decision 15). Decision 6 says "jamais coincé sous un obstacle". Should the least speed also hold for a low runner in the air under a low ceiling? That is a change of game code, so a decision for the owner.
`````
