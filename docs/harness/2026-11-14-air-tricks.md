# Leçons du tour — figures aériennes (`docs/specs/air-tricks.md`)

Tour du 2026-11-14, propriétaire : Jimmy. Seconde moitié de l'étape 2 : spec écrite
avec Jimmy (17 questions, dont la méthode des figures composées et le clavier), une
passe du développeur, une inspection « à corriger », un amendement, une seconde
inspection « conforme », deux petites corrections, fusion (pull requests n° 18 et
n° 26). Les trois rapports des agents sont à la fin, mot pour mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

## Déroulé

| Étape | Qui | Résultat |
| ----- | --- | -------- |
| Sparring | session principale avec Jimmy | 17 questions ; les figures composées de briques (salto, tours, vrilles) ; la vrille déplacée sur la touche de saut pour le clavier ; accord pour les sons Kenney |
| Sons | session principale | deux packs Kenney téléchargés avec l'accord de Jimmy, licence CC0 lue dans chaque `License.txt`, cinq fichiers retenus |
| Développement, passe 1 | développeur, worktree isolé | 210 tests, `just check` vert ; environ 33 min |
| Inspection 1 | inspecteur, contexte neuf, avec un joueur sans risque | « à corriger » : un saut à plat durait exactement un tour plus la fenêtre PERFECT (150 000 points par minute, jamais de crash) ; le gain du PERFECT se cumulait jusqu'à 22 m/s |
| Amendement, passe 2 | session principale, puis développeur | un tour de 0,65 s, plus long qu'un saut à plat ; gain plafonné ; sept scénarios ; 217 tests |
| Inspection 2 | inspecteur, contexte neuf | « conforme » ; le PERFECT reste presque sûr en appuyant avec le saut sur une petite descente : gardé pour que Jimmy le juge |
| Clôture | session principale | `just check` vert, CI verte, fusion |

## Leçons

1. **La leçon du tour précédent a payé tout de suite.** Le brief de la première
   inspection lui demandait d'écrire un joueur sans risque et de mesurer ses gains par
   minute : la faille principale (une figure toujours PERFECT sur un saut à plat) est
   sortie dès la première inspection, au lieu de la seconde. Proposition : garder cette
   consigne dans chaque brief d'inspection qui touche une récompense.
2. **Une valeur de départ peut à elle seule créer la faille.** 36 pas de vol, 27 pas de
   tour, 9 pas de fenêtre : la somme tombait juste. Aucun scénario ne le voyait, parce
   que chacun testait une règle, pas la combinaison des valeurs. Proposition : quand une
   spec ajoute une durée qui se compare à une autre (un tour et un saut, une fenêtre et
   un vol), elle écrit la relation voulue entre elles (« un tour dure plus qu'un saut à
   plat ») et un test lit le réglage du projet pour la garder. C'est ce que fait
   maintenant « Un salto ne tient pas dans un saut à plat » : une PR de réglage seul qui
   descendrait sous 0,62 s serait refusée par la CI.
3. **Les mutations de l'inspecteur deviennent des scénarios.** La première inspection a
   listé cinq cassures que la suite laissait passer (un crash qui paie les figures déjà
   finies, le PERFECT de toutes les figures, le paiement au mantle, les quarts, le côté
   de la vrille) ; l'amendement les a écrites en scénarios. La seconde inspection n'en a
   trouvé qu'une. Proposition : chaque cassure non attrapée appelle soit un scénario,
   soit une ligne des choix acceptés qui dit pourquoi elle est sans importance.
4. **Ce que seul le jeu dira.** Le dernier risque mesuré (appuyer avec le saut donne un
   PERFECT presque sûr) est un réglage de sensation, pas une erreur de code. Il a été
   gardé et écrit pour Jimmy plutôt que tranché à l'aveugle : le harnais sait mesurer une
   boucle, pas dire si un geste est trop facile.

## Ce qui reste ouvert après ce tour

- **À juger par Jimmy en jouant** : le timing des figures, la facilité du PERFECT, la
  vrille seulement après le sommet, Shift gauche et la fenêtre des touches rémanentes
  de Windows, les cinq sons, la lisibilité du corps qui tourne, le coût des figures en
  munitions (à revoir avec l'étape 3).
- Le parcours de test offre peu d'endroits pour les figures (la grande chute, quelques
  bords de blocs).
- Toujours ouverts depuis les tours précédents : voir
  `docs/harness/2026-11-14-flow-combo.md`.

## Rapports des agents, mot pour mot

### Développeur (trois passes)

`````markdown
# Rapport du développeur : air-tricks (`docs/specs/air-tricks.md`)

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a1b568e952b7136f3`
Branche : `air-tricks`, partie de `main` à `108351b`. Rien n'est poussé.

Commits :
- `6cfd3d6` air-tricks: aerial tricks, their landing and their sounds (le code, les tests, les assets, le README)
- `1d7d98a` AGENTS.md: the layout describes the tricks, the sounds and assets/ (seulement les lignes de Layout)
- `a533a6d` spec: air-tricks implemented (statut `🟢 Implémenté`)

## Fait

Les 30 scénarios ont chacun leur test, du même nom en anglais.

Core, `tests/test_runner_tricks.gd` (en l'air) :
- La direction poussée choisit le salto : `test_the_pushed_direction_chooses_the_flip`
- Une figure ne se lance pas au sol : `test_a_trick_does_not_start_on_the_ground`
- Une figure ne se lance pas en wall-run ni en mantle : `test_a_trick_does_not_start_in_a_wall_run_or_a_mantle`
- Une figure ne change pas la trajectoire : `test_a_trick_does_not_change_the_trajectory`
- Lâcher le bouton finit le tour en cours : `test_releasing_the_button_finishes_the_current_turn`
- Garder le bouton enchaîne les tours : `test_holding_the_button_chains_the_turns`
- Un appui sur saut pendant un salto ajoute une vrille : `test_a_jump_press_during_a_flip_adds_a_twist`
- Les vrilles ne dépassent pas leur maximum par tour : `test_twists_do_not_exceed_their_maximum_per_turn`
- Pas de vrille sur un side flip ni un spin : `test_no_twist_on_a_side_flip_or_a_spin`
- Une vrille près du sol ne relance pas de saut : `test_a_twist_near_the_ground_does_not_start_a_jump`
- Pendant une figure, le saut ne lance pas de wall-jump : `test_during_a_trick_the_jump_does_not_start_a_wall_jump`
- Une seconde figure dans le même saut vaut plus : `test_a_second_trick_in_the_same_jump_is_worth_more`
- Pas de wall-run ni de mantle pendant une figure : `test_no_wall_run_or_mantle_during_a_trick`
- Le nom d'une figure se compose de ses briques : `test_the_name_of_a_trick_is_composed_of_its_bricks`

Core, `tests/test_runner_trick_landing.gd` (réception, crash, points) :
- Une figure finie rapporte à la réception : `test_a_finished_trick_pays_at_the_landing`
- Une figure non finie au sol est un crash : `test_an_unfinished_trick_on_the_ground_is_a_crash`
- Une figure finie juste avant le sol est parfaite : `test_a_trick_finished_just_before_the_ground_is_perfect`
- Une figure finie trop tôt n'est pas parfaite : `test_a_trick_finished_too_early_is_not_perfect`
- Une figure rapporte au début d'un wall-run : `test_a_trick_pays_at_the_start_of_a_wall_run`
- Les points d'une figure composée : `test_the_points_of_a_composed_trick`
- Une figure qui change d'une brique n'est pas une répétition : `test_a_trick_that_changes_one_brick_is_not_a_repetition`
- Une chute hors du parcours perd les figures du saut : `test_a_fall_off_the_course_loses_the_tricks_of_the_jump`
- La grande chute demande toujours une roulade : `test_the_big_fall_still_asks_for_a_roll`

Vraie physique et vraies entrées :
- Un backflip au clavier dans la vraie physique : `test_a_backflip_on_the_keyboard_in_the_real_physics` (`tests/test_course_tricks.gd`)
- Un backflip à la manette dans la vraie physique : `test_a_backflip_on_the_gamepad_in_the_real_physics` (`tests/test_course_tricks.gd`)
- Le corps visible fait le tour de la figure : `test_the_visible_body_makes_the_turn_of_the_trick` (`tests/test_player_facing.gd`)

Affichages et sons :
- Le HUD montre la figure en cours : `test_the_hud_shows_the_trick_under_way` (`tests/test_flow_hud.gd`)
- Le HUD montre la réception : `test_the_hud_shows_the_landing` (`tests/test_flow_hud.gd`)
- Le HUD signale un crash : `test_the_hud_signals_a_crash` (`tests/test_flow_hud.gd`)
- Chaque événement joue son son : `test_every_event_plays_its_sound` (`tests/test_flow_sounds.gd`)

Les tests clavier et manette passent par le vrai chemin des entrées :
`Input.parse_input_event` avec des `InputEventKey` (touches physiques, Shift avec
`location` gauche), des `InputEventJoypadButton` (A, X, LB) et des
`InputEventJoypadMotion` (stick gauche), puis la carte d'entrées de `project.godot`,
puis l'`InputIntentSource` du coureur du parcours. Aucune intention n'est écrite à la
main. Le test clavier vérifie aussi que le HUD du parcours nomme le backflip pendant le
saut, ce qui prouve le branchement `Course` → `FlowHud.motor`.
`tests/test_input_map.gd` ajoute `trick` aux actions de jeu : il faut une touche et une
entrée manette, et les touches sont physiques.

Ce qui a été construit :
- `game/core/air_trick.gd` (`AirTrick`, nouveau) : les trois briques (salto, tours,
  vrilles), le nom, l'identité pour la répétition (salto, tours, vrilles), les points,
  les angles lus par la présentation.
- `game/core/runner_motor.gd` : l'ordre d'un pas devient vrille ou mémoire de saut,
  puis le tour de la figure avance, puis le sol (réception, crash, paiement), les états,
  le mouvement, et enfin le départ d'une figure. Pendant une figure, aucun wall-run ni
  mantle ne commence. Les figures sont payées au sol, au début d'un wall-run ou d'un
  mantle (messages `TRICK` datés). Le `CRASH` est une réception dure. `reset()` perd
  les figures du saut.
- `game/core/runner_event.gd` : les sortes `TRICK` et `CRASH`, et la figure portée par
  le message.
- `game/core/flow_state.gd` : une figure est un move dont les points viennent d'elle.
  La fenêtre de répétition compare des identités : la sorte, et pour une figure
  salto, tours et vrilles. Le `CRASH` est une erreur, comptée comme la réception dure.
  Les affichages lisent les moves du dernier pas (`step_moves`, `step_points`) et des
  compteurs (`tricks_landed`, `perfect_landings`, `crashes`).
- `game/core/move_intent.gd` : `trick_pressed` et `trick_held`.
  `game/core/movement_tuning.gd` et `.tres` : groupe « Tricks » avec les valeurs de la
  spec. `tests/motor_body.gd` reprend les mêmes valeurs dans le réglage fixe.
- `project.godot` : l'action `trick` (Shift gauche physique, bouton manette 2 = X). La
  section `[debug]` n'a pas changé.
- `game/player/input_intent_source.gd` lit `trick`. `game/player/player.gd` garde le
  cap et l'inclinaison comme valeurs à lui (`_yaw`, `_lean`), puis place le corps
  visible à chaque pas (`_pose`) : vrille autour de son axe, salto autour de l'axe de la
  figure et du milieu du corps. Pendant une figure, le corps ne se tourne pas vers la
  poussée.
- `game/ui/flow_hud.gd` et `.tscn` : un `TrickLabel` pour le nom en l'air, puis
  PERFECT ou CRASH, et le texte de chaque move du pas. `game/ui/flow_sounds.gd` et
  `.tscn` (`FlowSounds`, nouveau) : cinq `AudioStreamPlayer` déclenchés par les
  compteurs du flow.
- `game/levels/course.gd` et `test_course.tscn` : le HUD reçoit le moteur, et
  `FlowSounds` est instancié et reçoit le flow.
- `assets/sounds/` : les cinq `.ogg` Kenney, avec les `.import` générés par Godot.
  `assets/CREDITS.md` a une ligne par fichier (pack et version, Kenney, source, CC0 1.0).
- Helpers de test : `tests/trick_test.gd` (`TrickTest`, base des deux scripts core) et
  `ScriptedIntentSource.trick()`.
- `README.md` : la ligne Trick dans les contrôles, un paragraphe sur les figures, la
  ligne de l'étape 2 de la feuille de route.
- `AGENTS.md`, dans un commit à part : les lignes de Layout de `core/`, `player/`,
  `ui/`, `tests/` et `assets/` décrivent ce qui existe. Aucune règle n'a changé.

## Vérifié

- `just setup` sur le worktree neuf : vert, 22 s.
- `just preflight` sur le dernier commit de code (`1d7d98a`) : vert en **19,97 s**
  (la limite est 30 s ; 19,4 s avant ce travail). Typecheck 54 scripts sans erreur,
  lint sans problème, 174 tests passent, structure sans problème.
- `just check` sur le même commit : vert en **40,9 s**. 210 tests, replays du parcours
  compris. Builds Windows (104 Mio) et Linux (70 Mio) exportés, et le Windows a tourné
  60 frames en headless.
- Chaque test a été vu rouge pour la bonne raison avant son code, avec quatre
  exceptions :
  - `test_a_trick_does_not_change_the_trajectory` est vert dès son premier passage.
    C'est un invariant : aucun code n'est à écrire pour lui. Il vérifie quand même
    qu'une figure était en cours pendant presque tout le vol.
  - `test_the_name_of_a_trick_is_composed_of_its_bricks` : `name()` existait avec la
    classe avant son test. Je l'ai vu rouge en remplaçant `name()` par un bouchon, puis
    j'ai remis le code.
  - Pour quatre tests, le code était déjà écrit au moment du test. Je les ai vus rouges
    en retirant la règle une fois, puis en la remettant :
    - side flip et spin (la condition sur le salto) ;
    - les deux tests de saut fantôme (un appui de saut gardé en mémoire pendant la
      figure) ;
    - les tests clavier et manette (`trick_pressed` non lu) ;
    - le branchement HUD du parcours.
- Aucun gate, test ni réglage de gate n'a été changé. Le lint limite un script à 20
  méthodes publiques : les tests core sont donc répartis sur deux scripts et une base.
  Aucun `RED-PROOF` ne reste dans le code (vérifié par grep).

## Non vérifié

Ce que seul Jimmy peut juger, manette en main :
- **Le feel du timing.** Un saut à plat dure environ 0,58 s, et un tour 0,45 s. Pour
  poser un backflip après un saut à plat, il faut donc appuyer sur figure dans les
  0,13 s environ après l'appel. Les doubles demandent une descente. Le
  PERFECT (0,15 s) tombe souvent tout seul sur un simple après un saut à plat. Il faut
  juger si c'est trop facile, ou si le tour est trop long pour le terrain actuel.
- **Le visuel.** Seule la rotation du backflip est mesurée par un test : un tour
  complet, la tête vers l'arrière, à l'envers à mi-tour, droit à la fin, sans se
  tourner vers la poussée. Rien ne mesure :
  - le front flip, le side flip, le spin, la vrille ;
  - le pivot au milieu de la capsule ;
  - le redressement d'un coup après un crash, avec l'interpolation physique active.
- **Le HUD à l'écran.** La place, la taille et la couleur du `TrickLabel` (bleu clair,
  26 px). La pile du HUD a été montée de 36 px (`offset_top` passe de -136 à -172).
  La lisibilité de plusieurs figures sur une ligne n'est pas vérifiée.
- **Les sons.** Les tests vérifient seulement que le bon `AudioStreamPlayer` passe en
  lecture, avec le pilote audio factice du headless. Personne ne les a écoutés : volume,
  bus par défaut, import par défaut sans boucle, choix des fichiers (la spec dit que
  Jimmy les juge en jouant). Les sons dans les builds exportés n'ont pas été écoutés
  non plus.
- **Une vraie manette et un vrai clavier.** Les tests envoient des événements
  synthétiques. Le X (bouton 2) et LB d'une vraie manette, et le Shift gauche sur un
  clavier AZERTY, ne sont pas essayés.
- **Le rechargement F4 du groupe « Tricks ».** Le rechargement en général est testé,
  pas ce groupe. Une valeur rechargée s'applique à la figure suivante, car la durée
  d'un tour est fixée au départ de chaque figure.
- **Le parcours.** Il reste faisable : les replays du pilote passent, et le pilote ne
  fait pas de figure (décision 19). Aucun test ne montre qu'une figure gêne ou aide une
  section.

## Écarts

Les choix faits là où la spec se tait ou laisse plusieurs lectures :

1. **Les bonus se multiplient.** Points = base × (1 + 0,5 × (n − 1)) × 1,5 si
   PERFECT. La spec ne donne un exemple que pour n = 1 : on pourrait aussi les
   additionner.
2. **Un crash reste un crash même avec la glissade pressée dans la fenêtre de
   roulade.** J'ai lu « une réception dure, quelle que soit la hauteur de chute » comme
   « la roulade ne sauve pas un crash ».
3. **L'ordre des messages d'un pas.** D'abord les figures du saut, puis le move de la
   réception (roulade, réception dure, wall-run, mantle). Après une grande chute sans
   roulade, les figures comptent donc dans le combo en cours, avec son multiplicateur.
   Ensuite la réception dure casse le combo et coûte un palier. Le crash envoie
   `CRASH` seul, sans `HARD_LANDING` en plus, et le flow le compte comme une réception
   dure.
4. **Le bord des quarts.** Une poussée à 45° exacts de la vitesse, comme la diagonale
   du clavier, donne un front flip ou un backflip, pas un side flip (tolérance
   `AirTrick.EDGE`).
5. **« Presque immobile ».** Sous 0,1 m/s horizontal (`AirTrick.ALMOST_STILL`), comme
   la constante `Player.ALMOST_STILL` qui existait déjà. C'est une constante de code et
   non une valeur de la ressource de réglage : je l'ai considérée comme un seuil
   technique, pas comme du feel.
6. **Une figure peut partir au pas même du saut ou du wall-jump** (les deux boutons
   ensemble). L'état est lu après le mouvement du pas.
7. **Le temps compte en pas fixes.** Un tour = round(0,45 × 60) = 27 pas, et la
   fenêtre PERFECT = 9 pas. La figure avance avant que le sol soit observé : une figure
   qui finit au pas même du contact est finie (PERFECT, pas crash).
8. **La limite de vrilles compte le tour en cours** : 2 au premier tour, puis 2 de
   plus au deuxième, et ainsi de suite.
9. **Présentation.**
   - Chaque vrille fait un tour complet autour de l'axe du corps, entre l'appui et la
     fin de son tour.
   - L'axe du salto est fixé au départ, par la vitesse au moment de l'appui.
   - Le spin tourne vers la droite (sens horaire vu du dessus) : la spec ne le dit pas.
   - Le corps pivote autour du milieu de la capsule.
10. **Un appui de saut pendant un side flip ou un spin ne fait rien** : ni vrille, ni
    mémoire.
11. **Le HUD.**
    - Le `TrickLabel` est au-dessus du texte du move.
    - En l'air, il affiche la figure en cours. Une figure finie reste affichée jusqu'à
      la réception.
    - Après la réception, PERFECT ou CRASH reste environ 1 s sur cette ligne. « CRASH »
      apparaît donc au-dessus de « COMBO BROKEN », et « PERFECT » au-dessus de
      « BACKFLIP +300 », en même temps. J'ai lu « puis » comme l'ordre de lecture.
    - Le texte du move montre tous les moves du dernier pas
      (« BACKFLIP +200   BACKFLIP +300   ROLL +100 »).
    - Si le combo casse au même pas (grande chute sans roulade), « COMBO BROKEN »
      remplace ce texte, comme avant.
12. **Les sons.**
    - Un PERFECT joue seulement son son, pas aussi celui de la figure posée.
    - Un crash en combo joue le son du crash et celui du combo cassé.
    - `FlowSounds` est à la racine de la scène du parcours, pas sous `Hud`.
13. **L'affichage de debug** montre « TRICK xN » comme move répété, sans le nom de la
    figure. Je ne l'ai pas changé : la spec ne demande rien à son sujet.
14. **Le README** gagne les contrôles et un paragraphe sur les figures. Sa ligne de
    feuille de route dit maintenant « built; the owner has not validated the step
    yet ».

## Questions

1. **Shift gauche sous Windows.** Cinq appuis de Shift à la suite ouvrent la boîte des
   touches rémanentes (Sticky Keys), sauf si le joueur l'a désactivée. Enchaîner les
   figures au clavier risque de la déclencher. À essayer avant la fusion. Si ça gêne,
   il faut choisir une autre touche.
2. **Les bonus : multiplier ou additionner** (écart 1) ? Ça ne change rien pour la
   première figure du saut.
3. **Le crash même avec la roulade pressée** (écart 2) : est-ce bien l'intention ?
4. **Le son d'un PERFECT** : son seul, ou aussi celui de la figure posée (écart 12) ?

---

# Amendement après l'inspection (spec `4f58f88`, 37 scénarios)

Commits sur la branche `air-tricks`, par-dessus `4f58f88` :
- `5f60f1c` air-tricks: the amendment after the inspection
- `ba26c3f` spec: air-tricks amendment implemented (statut `🟢 Implémenté`)

Rien n'est poussé.

## Fait

1. **Décision 3.** `trick_turn_duration` passe à 0,65 s, soit 39 pas, dans `movement_tuning.tres` et dans le réglage fixe des tests. Un nouveau script, `tests/test_runner_trick_risk.gd`, couvre trois scénarios :
   - « Un salto ne tient pas dans un saut à plat » : `test_a_flip_does_not_fit_in_a_jump_on_the_flat`. Avec le réglage du projet et quatre poussées, la figure appuyée au pas même du saut crashe à chaque fois.
   - « Une descente suffisante permet un salto » : `test_a_drop_high_enough_allows_a_flip`. `TrickTest._drop_for_a_turn` calcule la descente depuis le réglage : la chute depuis le haut du saut doit durer ce que le tour dure au-delà de la montée, plus deux pas. Cela donne 1,37 m. Le test vérifie aussi qu'elle reste sous la hauteur de roulade.
   - « Une boucle sans risque sur le plat ne rapporte rien » : `test_a_riskless_loop_on_the_flat_earns_nothing`. Une minute de sauts enchaînés, avec la figure appuyée de 0 à 9 pas après l'appel, en alternance.

   Les tests qui comptaient sur un salto dans un saut à plat ont été repris :
   - `_jump_with_a_backflip` saute d'un bloc vers un sol plus bas de cette descente.
   - Le vol `_launched` part à 15,5 m/s vers le haut, et reste sous la hauteur de roulade.
   - Dans `test_no_wall_run_or_mantle_during_a_trick`, la partie rebord garde un rebord à portée à chaque pas. Un jumeau sans figure se hisse, lui, dès le premier pas.
   - Les tests clavier et manette du parcours partent du checkpoint de la grande chute. Le coureur saute du bout du passage bas et pose le backflip vrillé avec une roulade (Ctrl gauche, ou B), tout par les vraies entrées. Le recul (S ou stick) est lâché avec le bouton figure, au milieu du tour. Tiré pendant tout le vol, il retournait la vitesse : le coureur repartait en arrière et tombait du bloc d'arrivée.

2. **Décision 10.** Le gain du PERFECT est plafonné à `top_speed()` (bonus du flow compris) plus le gain, comme la glissade parfaite. Un coureur déjà plus rapide garde sa vitesse. Le plafond absolu tient toujours.
   - « Les réceptions parfaites enchaînées ne font pas monter la vitesse sans fin » : `test_perfect_landings_in_a_row_do_not_raise_the_speed_without_end`. Dix PERFECT de bloc en bloc restent sous 10 m/s ; avant la correction, la vitesse montait à 17,1 m/s.
   - `test_a_trick_finished_just_before_the_ground_is_perfect` couvre quatre cas :
     - à la vitesse de pointe, gain de 1 ;
     - un peu plus vite, gain de 0,5 ;
     - bien plus vite, aucun gain ;
     - sous un plafond absolu proche, gain de 0,4.

3. **Les mutations non attrapées deviennent des scénarios.** Trois nouveaux tests, dans `tests/test_runner_trick_landing.gd` :
   - « Un crash ne paie pas les figures déjà finies du saut » : `test_a_crash_does_not_pay_the_tricks_already_finished_in_the_jump`.
   - « Seule la dernière figure du saut est parfaite » : `test_only_the_last_trick_of_the_jump_is_perfect`. Le flow compte `[200, 450, 100]`.
   - « Une figure rapporte au début d'un mantle » : `test_a_trick_pays_at_the_start_of_a_mantle`.

   « Une seconde figure dans le même saut vaut plus » est réécrit : un backflip puis un front flip, et le flow compte `[200, 300, 100]`.

   Ajouts dans des tests existants :
   - pour les quarts, les deux diagonales du clavier, et des poussées à 40° et à 50° ;
   - pour `twist_angle()`, une poussée à gauche (sens positif), sans poussée et à droite (sens négatif).

4. **Un défaut trouvé par la diagonale arrière**, corrigé dans le même commit. Le salto était mesuré contre la vitesse d'après le pas de l'appui, que la poussée vient elle-même de courber. En courant devant, la diagonale arrière du clavier (S+D) donnait donc un side flip au lieu d'un backflip. Le salto se mesure maintenant contre la vitesse que le coureur avait au début du pas (`_real_velocity`).

## Vérifié

- **Chaque test nouveau ou réécrit a été vu rouge avant son code.**
  - Les trois tests de risque et celui des PERFECT enchaînés étaient rouges sous 0,45 s, avant le changement. Par exemple : 97 figures payées, 525 points de style contre 75 sans figure, une vitesse jusqu'à 17,1 m/s.
  - La diagonale arrière était rouge avant la correction du point 4.
- **Les tests dont le code existait déjà ont été vus rouges par mutation**, une à la fois, avec le fichier remis après chaque essai. Le script est `mutate_amend.py` dans le scratchpad, et le résultat `mutate_amend.txt`. Chaque mutation est attrapée par le test visé :

  | Mutation | Test qui échoue |
  |---|---|
  | Un crash paie les figures finies | Le test du crash |
  | Toutes les figures du saut sont PERFECT | « Seule la dernière » |
  | Un mantle ne paie pas | Le test du mantle |
  | Bonus d'enchaînement retiré | « Seconde figure » |
  | Quarts à 60° ou à 30°, diagonale sans tolérance | Le test des saltos |
  | Vrille toujours d'un même côté | Le test de la vrille |
  | Gain PERFECT sans plafond (l'ancien code) | Le test PERFECT et celui des PERFECT enchaînés |
  | Mesure après la poussée du pas | Le test des saltos |
  | Wall-run et mantle permis pendant une figure | Le test qui les interdit |
  | `trick_pressed` jamais lu | Les deux tests du parcours |

- `just preflight` : vert en **20,25 s**, 181 tests.
- `just check` sur `5f60f1c` : vert en **42,6 s**, 217 tests. Les builds Windows et Linux sont faits, et l'export Windows a tourné 60 frames en headless.
- **Le joueur sans risque de l'inspecteur** (`test_zz_loops.gd`, `test_zz_flight.gd`) a été copié dans le worktree le temps de tourner, puis supprimé : il n'est pas commité. Nouveaux taux, sur une minute à plat avec le réglage du projet :

  | Joueur | Style/min | Munitions/min | Distance | Figures payées | Crashs |
  |---|---|---|---|---|---|
  | Course seule | 0 | 0 | 540 m | 0 | 0 |
  | Sauts enchaînés, sans figure | 75 | 0,1 | 540 m | 0 | 0 |
  | Sauts + figure 1 pas après l'appel, 6 variantes (avant : 150 450) | 50 | 0,1 | 350 m | 0 | 62 |
  | Toujours le même front flip (avant : 525, 1 255 m) | 50 | 0,1 | 353 m | 0 | 62 |
  | Figure appuyée de 2 à 10 pas après l'appel | 50 | 0,1 | 350 m | 0 | 62 |
  | Sauts toutes les 0,5 s, sans figure | 825 | 0,8 | 540 m | 0 | 0 |
  | Figure à chaque saut, 0,5 s au sol (avant : 79 050) | **2 100** | **2,1** | 435 m | 0 | 41 |
  | Figure à chaque saut, 1 s au sol (avant : 52 650) | **1 550** | **1,6** | 463 m | 0 | 30 |

  Aucun PERFECT dans aucune de ces boucles. `test_zz_flight` : appuyée à +0, +1, +9 ou +10 pas, la figure crashe toujours au pas 36 du vol, et la vitesse tombe à 3,15 m/s. La vitesse maximale ne dépasse plus 9 m/s.

## Non vérifié

- Le feel d'un tour de 0,65 s : juger sa hauteur, avec au moins environ 1,4 m de descente.
- Le parcours n'offre presque aucun endroit où faire un salto sans roulade. Les tests du parcours utilisent la grande chute, avec une roulade ; c'est un des choix acceptés.
- Le reste du « Non vérifié » de la première partie tient toujours : visuel, HUD, sons, vraie manette, touches rémanentes.

## Écarts

- **La correction du point 4 n'était pas demandée telle quelle.** C'est le test des diagonales, lui demandé, qui a révélé le défaut. La correction suit la lecture la plus fidèle de la décision 2 : la vitesse « du coureur » au pas de l'appui.
- **La descente calculée prend deux pas de marge** (1,37 m), et la spec dit « environ 1 m ou plus ». Sans marge, la formule continue donne 0,85 m, et à cette valeur le moteur à pas fixes crashe.
- **Le test de la boucle sans risque se compare au joueur qui ressaute dès qu'il touche le sol.** Pour lui, l'affirmation est vraie : 50 points de style contre 75. Elle ne l'est plus pour un joueur qui attend au sol entre deux sauts (question 1).

## Questions

1. **Le crash rapporte encore, indirectement.** Une erreur casse le combo et remet la fenêtre de répétition à zéro : c'est une règle de `flow-combo`, dans ses choix acceptés.
   - Un joueur qui saute, crashe, attend 0,5 s pour reprendre de la vitesse et ressaute fait donc valoir chaque saut 50 points pleins.
   - Il gagne ainsi 2 100 points de style et 2,1 munitions par minute, contre 825 et 0,8 pour les mêmes sauts sans figure : 2,5 fois plus, en parcourant 435 m au lieu de 540.
   - Les figures elles-mêmes ne rapportent rien : c'est l'erreur qui recharge.
   - Pour ce joueur, le scénario « moins de style qu'en sautant sans figure » est faux.
   - Je n'ai pas touché la règle du flow, qui n'est pas dans cette spec. À trancher : une erreur ne remet pas la répétition à zéro, ou un saut juste après une erreur ne compte pas, par exemple.
2. **À −10 % (0,585 s, soit 35 pas), un tour tient de nouveau dans un saut à plat (36 pas).** Mesuré : la figure appuyée avec le saut est posée en PERFECT, et la boucle sans risque revient.
   - Avec la hauteur de saut à +10 % (38 pas de vol), il ne reste qu'un pas de marge sous les 39 pas du tour.
   - Je n'ai pas changé la valeur, comme demandé. Il ne faut pas descendre sous environ 0,62 s (37 pas). En dessous, `test_a_flip_does_not_fit_in_a_jump_on_the_flat` passe au rouge et le signale.
   - Les replays ±10 % du parcours ne font pas varier la durée d'un tour : aucun test ne la fait bouger.

---

# Corrections après la seconde inspection

Commit `b242d2a`. `just check` est vert en 41,5 s : 217 tests, builds Windows et Linux.

- **Les tours en plus, avec les vraies entrées (décision 17).** Les tests clavier et manette rejouent maintenant le saut sur un second parcours, le bouton figure (Shift, puis X) tenu au-delà du premier tour (39 pas). Ils vérifient qu'un second tour a commencé pendant que le coureur est encore en l'air. Rouge vu en forçant `intent.trick_held = false`, puis le code a été remis.
- **Les descentes mesurées, dans le README.**
  - Figure appuyée au pas même du saut : 0,6 m suffit, la figure finit au pas du contact ; à 0,9 m, il reste un pas de marge ; à 1,1 m, deux pas.
  - Figure appuyée deux pas après le saut : il faut 1,1 m.
  - L'inspecteur avait mesuré « 0,9 m = 2 pas de marge ». Je trouve un pas à 0,9 m et deux pas à 1,1 m. Le README donne mes chiffres.
- **Une correction de mon rapport précédent.** J'y avais écrit qu'à 0,85 m le moteur crashe. Je ne l'avais pas mesuré, et c'est faux : 0,6 m suffit si la figure part avec le saut. Les 1,37 m du test de descente sont une marge, pas un seuil.

`````

### Inspecteur, première inspection

`````markdown
# Inspection — branche `air-tricks` (`108351b..air-tricks`)

Spec : `docs/specs/air-tricks.md`, sur `docs/specs/flow-combo.md` (amendée deux fois). Types de tâche : `core`, `player`, `ui`, `levels`, `assets`, `tooling` (`project.godot`), `harness` (`AGENTS.md`, `README.md`, spec).

Portes lancées dans le worktree, sans rien y modifier : `just typecheck` (54 scripts, 0 erreur), `just lint` (rien), `just deadcode` (0 problème), `just test` (28 scripts, 210/210, 18,6 s). Le worktree est resté propre (`git status` vide).

## 1. Verdict

**À corriger.** Le code fait ce que dit la spec. Mais la spec, appliquée telle quelle, casse le dilemme du plan, et elle le casse plus fort que les deux boucles qui ont fait amender `flow-combo` :

- sur le plat, une figure est sans risque et toujours PERFECT ;
- le gain de vitesse du PERFECT s'additionne jusqu'au plafond absolu.

La suite est une décision du propriétaire : amender la spec, puis le code.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
|---|---|---|---|---|---|
| 1 | bloquant (spec) | `game/core/runner_motor.gd:729-736` | Dilemme du plan (`flow-combo`, Contexte). Décision 8 d'`air-tricks` : « le dilemme du plan en petit ». `flow-combo`, décision 9, amendement : « enchaîner les glissades parfaites ne fait pas monter la vitesse sans fin ». | Chaque PERFECT ajoute +1 m/s, avec pour seule limite le plafond absolu (22 m/s). Sur des sauts enchaînés, il n'y a qu'un pas au sol par saut (−0,1 m/s), donc la vitesse monte d'environ 0,9 m/s par saut. Mesuré avec le vrai moteur : 21,9 m/s en environ 13 s, 1 247 m par minute contre 540 m en courant. Le résultat est le même avec une seule figure répétée qui ne rapporte presque rien (1 255 m/min, 525 points/min) : le PERFECT donne sa vitesse même à une figure à 0 %. C'est la faille que le premier amendement de `flow-combo` a corrigée pour la glissade parfaite. | Amender la décision 10 comme la décision 9 de `flow-combo` : gain = `min(v + gain, top_speed() + gain)`. Ajouter le scénario « enchaîner les réceptions parfaites ne fait pas monter la vitesse sans fin ». |
| 2 | bloquant (spec) | `game/core/runner_motor.gd:753-760` et les valeurs de `game/core/movement_tuning.tres:71-76` | Décision 8 (« Le seul risque est la réception », décision 6) ; leçon 1 de `docs/harness/2026-11-14-flow-combo.md` (sur `main`) : « une boucle sans risque ne rapporte pas » | Saut tenu sur le plat : 36 pas de vol. Un tour de figure dure 27 pas et la fenêtre PERFECT fait 9 pas, or 36 − 27 = 9. Toute figure lancée de 0 à 9 pas après l'appel est donc PERFECT ; une figure lancée à partir du 10e pas crashe ; « finie trop tôt » ne peut pas arriver. Appuyer saut et figure au même pas, au sol, lance la figure à l'appel (`_start_a_trick` lit l'état après `_move`) : jamais de crash. Mesuré sur 1 min (tableau ci-dessous) : 150 450 points de style, 150 munitions possibles, jauge pleine 95 % du temps, 0 crash, 99 PERFECT sur 99. En courant 1 s entre deux sauts : 52 650 points/min, jauge pleine 87 % du temps, 0 crash. La spec n'a aucun scénario de boucle sans risque. | Décision du propriétaire. Par exemple : un tour plus long qu'un saut à plat (`trick_turn_duration` ≥ environ 0,6 s), pour qu'une figure demande de la hauteur ; ou une fenêtre PERFECT plus courte que vol − tour. Puis ajouter à la spec les scénarios « une boucle sans risque sur le plat ne rapporte pas » (style/min, munitions/min, vitesse), avec des chiffres. |
| 3 | conseillé | `tests/test_runner_trick_landing.gd:38` (code `runner_motor.gd:743-744`) | Décision 8 : « Les figures du saut ne rapportent rien » | Le test du crash n'a qu'une figure. Mutation : un crash qui paie quand même les figures déjà finies du saut. La suite reste verte. Or c'est le risque de l'enchaînement en l'air. | Dans ce test, ou dans un autre, poser une figure finie puis une seconde non finie, et vérifier que rien n'est payé. |
| 4 | conseillé | `game/core/runner_motor.gd:401` | Décision 9 : les figures rapportent « au début d'un wall-run ou d'un mantle » | Mutation : retirer `_pay_the_tricks(false)` de `_start_mantle`. La suite reste verte. Aucun test ne prouve qu'un mantle paie. | Ajouter la variante mantle au test `test_a_trick_pays_at_the_start_of_a_wall_run`. |
| 5 | conseillé | `game/core/runner_motor.gd:730` | Décision 10 : seule « cette figure » (la dernière) prend le bonus PERFECT | Mutation : marquer PERFECT toutes les figures du saut. La suite reste verte. | Dans un test, enchaîner deux figures avec une réception parfaite, et vérifier que seule la seconde est PERFECT. |
| 6 | conseillé | `game/core/air_trick.gd:84-88` ; `tests/test_runner_tricks.gd:186` | Décision 2 : quart avant, arrière, côté | Le test ne pousse que dans les quatre axes. Mutation : frontière à 60° au lieu de 45°. La suite reste verte. La diagonale du clavier (Z+Q) tombe sur la frontière : le code la classe en front flip grâce à `EDGE`, et aucun test ne le dit. | Ajouter les deux diagonales du clavier (avant et arrière) et une poussée à 50°. |
| 7 | conseillé | `game/core/air_trick.gd:123-128` | Décision 4 : la vrille tourne « du côté poussé, à droite sans poussée » | Mutation : vrille toujours du même côté. La suite reste verte. | Vérifier `twist_angle()` pour une poussée à gauche et sans poussée. |
| 8 | conseillé | `tests/test_runner_tricks.gd:472-473` | Scénario « Une seconde figure dans le même saut vaut plus » ; décisions 7, 11 et 12 | Le test vérifie `AirTrick.points` (200 puis 300), pas ce que compte le flow. Comme les deux figures sont identiques, la règle de variété passe la seconde à 50 % : 300 × 0,5 = 150, moins que la première. Le HUD affiche « BACKFLIP +200   BACKFLIP +150 ». La spec se contredit, et le joueur lira le contraire du scénario. | À trancher par le propriétaire : soit le bonus d'enchaînement s'applique après la variété, soit le scénario prend deux figures différentes et vérifie les points du flow. |
| 9 | conseillé | `game/core/air_trick.gd:15-23` | Axe « Interface » du brief : un texte visible hors de `game/ui/` | Les noms affichés (« FRONT FLIP », « DOUBLE », « FULL »…) sont écrits dans `core`. | Laisser `core` donner les briques, et construire le texte dans `game/ui/` ; ou accepter et l'écrire dans la spec. |
| 10 | conseillé (règle incertaine) | `game/core/air_trick.gd:26` | « Every tuning value of the feel (speeds, gravity, tolerance windows) lives in one single tuning resource » | `ALMOST_STILL = 0.1` m/s est un seuil de vitesse écrit dans le code ; la spec dit « presque immobile » sans donner de valeur. Je ne sais pas si c'est une valeur de sensation. | Le déplacer dans le groupe « Tricks », ou noter dans la spec que c'est une constante. |

### Mesures de la boucle sans risque (vrai moteur, `movement_tuning.tres`, plat, 60 s, poussée avant)

| Joueur | Style/min | Munitions/min (1 000 points chacune) | Distance | Vitesse moyenne / max | Jauge pleine | Crash | PERFECT |
|---|---|---|---|---|---|---|---|
| Course, sans saut | 0 | 0 | 540 m | 9,00 / 9,00 | 0 % | 0 | — |
| Sauts enchaînés, sans figure | 75 | 0,1 | 540 m | 9,00 / 9,00 | 0 % | 0 | — |
| Sauts enchaînés + une figure à chaque saut, lancée 1 à 9 pas après l'appel, six variantes en rotation (front, front full, front double full, back, spin, side) | **150 450** | **150** | **1 247 m** | **20,8 / 21,9** | 95 % | 0 | 99/99 |
| La même chose, toujours le même front flip | 525 | 0,5 | 1 255 m | 20,9 / 21,9 | 0 % | 0 | 99/99 |
| Figures variées, 0,5 s de course entre deux sauts | 79 050 | 79 | 619 m | 10,3 / 11,25 | 91 % | 0 | 54/54 |
| Figures variées, 1 s de course entre deux sauts | 52 650 | 53 | 616 m | 10,3 / 11,25 | 87 % | 0 | 37/37 |
| Sauts seuls, 0,5 s de course entre deux sauts | 825 | 0,8 | 540 m | 9,00 | 0 % | 0 | — |

La fenêtre sur un saut tenu à plat (36 pas) : une figure lancée au pas de l'appel ou dans les 9 pas suivants est PERFECT (+1 m/s) ; à partir du 10e pas, c'est un CRASH (3,15 m/s). Le seul vrai risque est un saut lâché tôt : 18 pas de vol, et la figure crashe à coup sûr.

Pour comparer : le niveau que `flow-combo` a accepté pour « un saut régulier sur le plat » était d'environ 1 800 points en 2 minutes. **Le dilemme ne survit pas :** sur le plat, la figure recharge tout et fait aller plus vite, sans risque pour qui l'appuie juste après l'appel ou avec le saut.

### Ce que les tests prouvent vraiment (mutations sur une copie)

Mutations attrapées par au moins un test :

- saut gardé en mémoire pendant une figure : vrille près du sol, et wall-jump ;
- wall-run ou mantle permis pendant une figure ;
- fenêtre PERFECT décalée de ±1 pas ;
- crash désactivé ;
- vrille sur side flip ou spin ;
- tours qui ignorent le bouton tenu ;
- bonus d'enchaînement retiré ;
- identité de répétition sans les briques ;
- figure lancée au sol ;
- corps qui se tourne vers la poussée, ou qui ne tourne pas ;
- `trick_pressed` jamais lu ;
- Shift remplacé par Ctrl dans `project.godot` ;
- X remplacé par Y ;
- son de figure posée joué avec le PERFECT ;
- CRASH absent du HUD ;
- trajectoire modifiée par la figure ;
- gain de vitesse retiré, ou sans plafond ;
- figures gardées après un retour au checkpoint ;
- maximum de vrilles compté sur toute la figure ;
- côté du side flip.

Mutations qui passent la suite : constats 3 à 7.

Les tests du clavier et de la manette passent par le vrai chemin des entrées (`Input.parse_input_event`, puis la carte d'entrées, puis `InputIntentSource`). Le corps visible est de la présentation seule : `_facing()` lit `_yaw`, pas `_visual`, et rien de ce qu'observe le moteur ne dépend du corps visible. `AirTrick` ne connaît ni scène ni entrée. Chaque `.ogg` a sa ligne CC0 dans `assets/CREDITS.md`, et deux fichiers portent l'étiquette `ARTIST=Kenney`.

## 3. Couverture de la spec

| Scénario | Test |
|---|---|
| La direction poussée choisit le salto | `test_the_pushed_direction_chooses_the_flip` (frontières des quarts non testées, constat 6) |
| Une figure ne se lance pas au sol | `test_a_trick_does_not_start_on_the_ground` |
| Une figure ne se lance pas en wall-run ni en mantle | `test_a_trick_does_not_start_in_a_wall_run_or_a_mantle` |
| Une figure ne change pas la trajectoire | `test_a_trick_does_not_change_the_trajectory` |
| Lâcher le bouton finit le tour en cours | `test_releasing_the_button_finishes_the_current_turn` |
| Garder le bouton enchaîne les tours | `test_holding_the_button_chains_the_turns` |
| Un appui sur saut pendant un salto ajoute une vrille | `test_a_jump_press_during_a_flip_adds_a_twist` |
| Les vrilles ne dépassent pas leur maximum par tour | `test_twists_do_not_exceed_their_maximum_per_turn` |
| Pas de vrille sur un side flip ni un spin | `test_no_twist_on_a_side_flip_or_a_spin` |
| Une vrille près du sol ne relance pas de saut | `test_a_twist_near_the_ground_does_not_start_a_jump` |
| Pendant une figure, le saut ne lance pas de wall-jump | `test_during_a_trick_the_jump_does_not_start_a_wall_jump` |
| Une seconde figure dans le même saut vaut plus | `test_a_second_trick_in_the_same_jump_is_worth_more` (points de la figure, pas du flow : constat 8) |
| Pas de wall-run ni de mantle pendant une figure | `test_no_wall_run_or_mantle_during_a_trick` |
| Une figure finie rapporte à la réception | `test_a_finished_trick_pays_at_the_landing` |
| Une figure non finie au sol est un crash | `test_an_unfinished_trick_on_the_ground_is_a_crash` |
| Une figure finie juste avant le sol est parfaite | `test_a_trick_finished_just_before_the_ground_is_perfect` |
| Une figure finie trop tôt n'est pas parfaite | `test_a_trick_finished_too_early_is_not_perfect` |
| Une figure rapporte au début d'un wall-run | `test_a_trick_pays_at_the_start_of_a_wall_run` |
| Les points d'une figure composée | `test_the_points_of_a_composed_trick` |
| Une figure qui change d'une brique n'est pas une répétition | `test_a_trick_that_changes_one_brick_is_not_a_repetition` |
| Une chute hors du parcours perd les figures du saut | `test_a_fall_off_the_course_loses_the_tricks_of_the_jump` |
| La grande chute demande toujours une roulade | `test_the_big_fall_still_asks_for_a_roll` |
| Le nom d'une figure se compose de ses briques | `test_the_name_of_a_trick_is_composed_of_its_bricks` |
| Un backflip au clavier dans la vraie physique | `test_a_backflip_on_the_keyboard_in_the_real_physics` |
| Un backflip à la manette dans la vraie physique | `test_a_backflip_on_the_gamepad_in_the_real_physics` |
| Le corps visible fait le tour de la figure | `test_the_visible_body_makes_the_turn_of_the_trick` |
| Le HUD montre la figure en cours | `test_the_hud_shows_the_trick_under_way` |
| Le HUD montre la réception | `test_the_hud_shows_the_landing` |
| Le HUD signale un crash | `test_the_hud_signals_a_crash` |
| Chaque événement joue son son | `test_every_event_plays_its_sound` |

Aucun scénario sans test, aucun test de figure sans scénario.

## 4. Non vérifiable ici

Ce que seul Jimmy peut juger, manette en main :

- **Le timing d'un tour (0,45 s) sur un saut à plat (environ 0,6 s).** Est-ce qu'appuyer juste après l'appel est trop facile, et le PERFECT trop automatique ? (constat 2).
- **La vitesse après une série de réceptions parfaites (jusqu'à 22 m/s).** Le parcours reste-t-il jouable, et la caméra suit-elle ? (constat 1).
- **Vrilles au clavier.** Taper Espace pendant la montée coupe le saut, et un vol raccourci crashe à coup sûr. Le geste « pouce sur Espace, auriculaire sur Shift gauche, S tenu » est-il confortable ?
- **Vrilles à la manette.** A tenu, X tenu, LB tapé, stick tiré : le geste est-il confortable ? Le X d'une manette PlayStation (Carré) est-il bien le bouton de gauche ?
- **La lecture de la rotation.**
  - Le salto tourne autour de l'axe de la vitesse prise au départ, alors que le corps garde l'orientation qu'il avait : si le coureur regardait de côté, un backflip peut se lire comme un side flip.
  - Une vrille tapée au dernier pas d'un tour fait un tour complet en un seul pas.
- **Le redressement d'un coup après un crash, et le pivot au milieu du corps.**
- **Le HUD.**
  - L'emplacement et la couleur du nom de la figure en cours (cyan, au-dessus du texte des moves).
  - Les deux textes de réception affichés en même temps.
  - Une grande chute posée en PERFECT sans roulade : « COMBO BROKEN » remplace aussitôt les points de la figure.
- **Les cinq sons Kenney** : choisis d'après leur nom, ils sont à écouter (volume, ton, et un même son répété à chaque saut).
- **Les licences.** CC0 est déclaré dans `assets/CREDITS.md`, mais je n'ai pas pu revoir le `License.txt` des packs (hors ligne).
- **La modification d'`AGENTS.md`** (Layout), dans son propre commit : relecture par le propriétaire (type `harness`).
- **`main` a avancé depuis la base de la branche** (`bddc6c6` : leçons, notes des paliers de tests, spec `local-duel`). Les fichiers ne se recouvrent pas, mais la CI de la pull request doit tourner sur la fusion.

## Fichiers de l'expérience (hors dépôt)

- Copie de travail : `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks\copy`
- Joueur sans risque : `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks\copy\tests\test_zz_loops.gd`
- Fenêtre sur un saut : `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks\copy\tests\test_zz_flight.gd`
- Mutations : `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks\tools\mutate.py` (résultats dans `mut1.txt` et `mut2.txt`, dans le même dossier)

`````

### Inspecteur, seconde inspection

`````markdown
# Inspection de la branche air-tricks (seconde, indépendante)

Plage : `108351b..air-tricks` (HEAD `d480c8c`, la fusion de `main` en `a0252eb` ne touche que des docs). Spec : `docs/specs/air-tricks.md` amendée, construite sur `docs/specs/flow-combo.md` amendée deux fois. Types de tâche : core, player, ui, levels, assets, tooling (`project.godot` : la carte des entrées), harness (docs, `AGENTS.md`, `README.md`).

Portes lancées sur le worktree (lecture seule) : `just typecheck` (55 scripts, 0 erreur), `just lint` (0), `just deadcode` (0 problème), `just test` (217/217, 19 s), `just test-course` (36/36). Le worktree n'a pas changé (`git status` vide).

## 1. Verdict

**Conforme.** Aucun scénario de la spec ni aucune règle d'`AGENTS.md` n'est cassé. Mais le constat 1 et les mesures du n° 5 disent que le dilemme du plan ne tient plus que par le risque d'exécution : c'est à Jimmy de trancher, manette en main, avant de valider l'étape 2.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | conseillé | `game/core/runner_motor.gd:759` (avec `game/core/movement_tuning.tres:71`, `:76`) | Spec, décision 3 amendée : « Le joueur doit juger sa hauteur : c'est le risque de la figure » ; décision 10 : « Partir tard pour finir juste à temps » ; dilemme du plan (`flow-combo.md`, Contexte) | Dès qu'il y a un mur courable ou une descente d'au moins 0,6 m, appuyer figure **en même temps** que saut (ou wall-jump) donne toujours un PERFECT. Un appui trop tôt (au sol, en wall-run) ne lance rien et ne coûte rien. Le crash ne vient qu'avec un appui 2 pas (33 ms) trop tard. Sous environ 3,5 m de descente, toute figure qui ne crashe pas est PERFECT : il n'y a pas de « trop tôt ». La ligne stylée va plus loin que la ligne sûre (mesures au n° 5). | Décision de Jimmy après avoir joué. S'il veut rendre du risque : rouvrir le choix accepté « Une figure peut partir au pas même du saut ou du wall-jump », par exemple avec un délai minimal après la poussée (un réglage). Ou bien raccourcir `trick_perfect_window` devant la marge réelle. Cela demande un amendement de la spec. |
| 2 | conseillé | `game/core/movement_tuning.tres:73` (avec `:66` `flow_points_per_ammo`, `:60` multiplicateur max) | `flow-combo.md`, décision 8 (second amendement) : les munitions viennent des points de style | Une figure posée en combo ×4 vaut en moyenne environ 1 600 points de style, soit 1,6 munition. Deux figures remplissent la réserve de 3. Les joueurs sans risque du n° 5 gagnent 90 000 à 176 000 points par minute, contre 75 pour un sauteur sur le plat et 300 pour la boucle saut et glissade parfaite. | À juger avec l'étape 3, quand les munitions serviront : les points d'un tour (200) contre la tranche d'une munition (1 000). Ce sont des valeurs de réglage, donc sans spec. |
| 3 | conseillé (je ne sais pas si c'est bloquant : la décision 17 n'est pas un scénario) | `game/player/input_intent_source.gd:33` ; `tests/test_course_tricks.gd:75-105` | Spec, décision 17 : « Chaque geste a un test joué avec les entrées du clavier et un avec celles de la manette » | Le geste « garder le bouton pour plus de tours » n'a aucun test par les vraies entrées. J'ai cassé exprès sur une copie (`intent.trick_held = false`) : les 217 tests et les 36 rejeux restent verts. | Dans `test_course_tricks.gd`, garder Shift puis X au-delà de la fin du premier tour (39 pas) et vérifier `current_trick().turns == 2` en l'air, sans attendre la réception. |
| 4 | conseillé | `game/core/runner_motor.gd:644-646` (le saut coupé), en jeu avec `:230-232` | Spec, décision 4 : « chaque appui sur saut ajoute une vrille » | Pour taper une vrille, il faut d'abord relâcher saut. Pendant la montée, ce relâché coupe le saut (×0,45) : la figure crashe. Mesuré avec une descente de 1,4 m : une vrille aux pas 5, 10 ou 15 après le saut donne CRASH, au pas 22 (après le sommet) PERFECT. La manette ne contourne pas le problème : j'ai vérifié dans Godot qu'avec A tenu, appuyer sur LB ne donne pas de `is_action_just_pressed(jump)`. Les deux tests par les vraies entrées tapent la vrille après le sommet. | Le dire à Jimmy : vriller seulement en descente, est-ce voulu ? Si non, il faut un amendement. Ne plus couper le saut pendant une figure changerait la trajectoire, ce qui touche la décision 6. |
| 5 | conseillé | `README.md:118` ; `docs/specs/air-tricks.md:52` et `:351-352` | Working rules : « Never say “it works” without having run it » (ici, un chiffre que le dessin des niveaux va utiliser) | Le README et la décision 3 disent « une descente d'environ 1 m ou plus », et le choix accepté donne 1,37 m. Mesuré avec le vrai moteur : 0,6 m suffit avec figure appuyée au pas du saut, 0,9 m laisse 2 pas de marge, 1,4 m en laisse 4. Le 1,37 m est la valeur du test, marge comprise, pas le seuil. | Écrire les seuils mesurés (0,6 m au pas du saut, 0,9 m avec un pas de marge), puisque « les endroits pour les figures viendront avec le dessin des niveaux ». |

Rien à signaler sur les points demandés :

- **La figure vit dans `core`** sans scène ni entrée : `AirTrick` est un `RefCounted` de calcul vectoriel, et `just deadcode` passe.
- **Aucun appui sur saut pendant une figure n'est mémorisé ni ne devient un wall-jump.** Je l'ai vérifié par un fuzz de 40 × 1 200 pas aléatoires (mur, descentes, figures, sauts, glissades) : 1 091 sauts et wall-jumps, aucun qui ne vienne d'un appui hors figure dans la mémoire de saut.
- **La rotation du corps visible est de la présentation seule.** `_observe` ne lit pas `_visual`, `_facing()` ne sert qu'à l'inclinaison, et casser `_turn` ou `_pose` ne fait échouer que `test_player_facing`.
- **`assets/CREDITS.md`** couvre les 5 `.ogg`. Les 5 `.import` sont les fichiers de Godot qui les accompagnent.
- **Toutes les valeurs de sensation** sont dans le groupe « Tricks » de la ressource de réglage. `ALMOST_STILL` et `EDGE` sont des constantes acceptées.

## 3. Couverture de la spec

Chaque test a été mis à l'épreuve par une casse volontaire sur une copie hors du dépôt (25 casses). Toutes font échouer le test du scénario visé, sauf la n° 22 (constat 3).

| Scénario | Test | Casse qui le fait échouer |
| -------- | ---- | ------------------------- |
| La direction poussée choisit le salto | `test_the_pushed_direction_chooses_the_flip` | M20 (bord des quarts) |
| Une figure ne se lance pas au sol | `test_a_trick_does_not_start_on_the_ground` | M09 |
| Une figure ne se lance pas en wall-run ni en mantle | `test_a_trick_does_not_start_in_a_wall_run_or_a_mantle` | M09 |
| Une figure ne change pas la trajectoire | `test_a_trick_does_not_change_the_trajectory` | M17 |
| Lâcher le bouton finit le tour en cours | `test_releasing_the_button_finishes_the_current_turn` | (core) |
| Garder le bouton enchaîne les tours | `test_holding_the_button_chains_the_turns` | core oui ; vraies entrées non (constat 3) |
| Un appui sur saut pendant un salto ajoute une vrille | `test_a_jump_press_during_a_flip_adds_a_twist` | M01, M25 |
| Les vrilles ne dépassent pas leur maximum par tour | `test_twists_do_not_exceed_their_maximum_per_turn` | M07 |
| Pas de vrille sur un side flip ni un spin | `test_no_twist_on_a_side_flip_or_a_spin` | (core) |
| Une vrille près du sol ne relance pas de saut | `test_a_twist_near_the_ground_does_not_start_a_jump` | M01, M02 |
| Pendant une figure, le saut ne lance pas de wall-jump | `test_during_a_trick_the_jump_does_not_start_a_wall_jump` | M01, M02 |
| Une seconde figure dans le même saut vaut plus | `test_a_second_trick_in_the_same_jump_is_worth_more` | M19, M08 |
| Pas de wall-run ni de mantle pendant une figure | `test_no_wall_run_or_mantle_during_a_trick` | M03 |
| Une figure finie rapporte à la réception | `test_a_finished_trick_pays_at_the_landing` | (core) |
| Une figure non finie au sol est un crash | `test_an_unfinished_trick_on_the_ground_is_a_crash` | M04, M16 |
| Une figure finie juste avant le sol est parfaite | `test_a_trick_finished_just_before_the_ground_is_perfect` | M05 |
| Une figure finie trop tôt n'est pas parfaite | `test_a_trick_finished_too_early_is_not_perfect` | M24 (fenêtre +1 pas) |
| Une figure rapporte au début d'un wall-run | `test_a_trick_pays_at_the_start_of_a_wall_run` | M14, M03 |
| Les points d'une figure composée | `test_the_points_of_a_composed_trick` | M01 |
| Une figure qui change d'une brique n'est pas une répétition | `test_a_trick_that_changes_one_brick_is_not_a_repetition` | M08 |
| Une chute hors du parcours perd les figures du saut | `test_a_fall_off_the_course_loses_the_tricks_of_the_jump` | M18 |
| La grande chute demande toujours une roulade | `test_the_big_fall_still_asks_for_a_roll` | (core) |
| Le nom d'une figure se compose de ses briques | `test_the_name_of_a_trick_is_composed_of_its_bricks` | (core) |
| Un salto ne tient pas dans un saut à plat | `test_a_flip_does_not_fit_in_a_jump_on_the_flat` | M04, M11 (tour 0,6 s) |
| Une descente suffisante permet un salto | `test_a_drop_high_enough_allows_a_flip` | (core) |
| Une boucle sans risque sur le plat ne rapporte rien | `test_a_riskless_loop_on_the_flat_earns_nothing` | M04, M11 |
| Les réceptions parfaites enchaînées ne font pas monter la vitesse sans fin | `test_perfect_landings_in_a_row_do_not_raise_the_speed_without_end` | M05 |
| Un crash ne paie pas les figures déjà finies du saut | `test_a_crash_does_not_pay_the_tricks_already_finished_in_the_jump` | M16 |
| Seule la dernière figure du saut est parfaite | `test_only_the_last_trick_of_the_jump_is_perfect` | M06 |
| Une figure rapporte au début d'un mantle | `test_a_trick_pays_at_the_start_of_a_mantle` | M15, M03 |
| Un backflip au clavier dans la vraie physique | `test_a_backflip_on_the_keyboard_in_the_real_physics` | passe par `Input.parse_input_event` puis la carte des entrées puis `InputIntentSource` |
| Un backflip à la manette dans la vraie physique | `test_a_backflip_on_the_gamepad_in_the_real_physics` | M23 (X retiré de `trick`) |
| Le corps visible fait le tour de la figure | `test_the_visible_body_makes_the_turn_of_the_trick` | M10, M21 |
| Le HUD montre la figure en cours | `test_the_hud_shows_the_trick_under_way` | M12 |
| Le HUD montre la réception | `test_the_hud_shows_the_landing` | (ui) |
| Le HUD signale un crash | `test_the_hud_signals_a_crash` | (ui) |
| Chaque événement joue son son | `test_every_event_plays_its_sound` | M13 (sons échangés) |

37 scénarios, 37 tests du même nom, aucun test sans scénario. Le pilote ne fait pas de figure (décision 19) et les rejeux du parcours n'ont pas changé. Aucun test n'a été sauté, supprimé ou affaibli. Les assertions retirées par l'amendement (`5f60f1c`) suivent les scénarios amendés.

## 4. Non vérifiable ici

- **Le geste au clavier** : Shift gauche tenu par l'auriculaire, Espace tapé par le pouce, la flèche arrière tenue en même temps. La fenêtre des touches rémanentes de Windows (choix accepté). Un vrai clavier envoie `shift_pressed` sur Espace ; Godot le tolère en correspondance non exacte, mais le test ne le reproduit pas.
- **À la manette** : X tenu pendant que le stick tire en arrière, puis LB tapé (index gauche) pendant que le pouce droit tient X.
- **L'accord saut + figure** (Espace+Shift, A+X) : est-il trop facile, et est-ce du skill ou un réflexe gratuit ? (constat 1)
- **Vriller seulement après le sommet**, est-ce lisible et voulu ? (constat 4)
- **Le gain de 1 m/s du PERFECT** ressenti, cumulé avec la glissade parfaite (jusqu'à environ 12,3 m/s mesuré, borné).
- **Le corps qui tourne** : la lisibilité du backflip, du side flip, du spin et de la vrille avec la caméra, le redressement d'un coup après un crash, le corps figé dans sa direction pendant la figure.
- **Le HUD** : le nom de la figure au-dessus de la jauge, « PERFECT » et « CRASH », la lisibilité de la couleur bleu clair.
- **Les cinq sons Kenney** : le choix, le volume, un seul son au PERFECT, crash puis combo cassé l'un sur l'autre.
- **Les licences** : je n'ai pas pu revérifier en ligne les `License.txt` des packs (CC0 déclaré).
- **Enchaîner deux figures dans le même saut** (bonus de 50 %) demande environ 79 pas de vol (≈ 1,3 s), soit une chute d'environ 20 m après un saut (calcul, pas mesuré). Le parcours de test n'en offre pas : le bonus d'enchaînement ne se joue pas encore.

## 5. Mesures (vrai moteur `RunnerMotor` + `FlowState`, réglage du projet, 3 600 pas = 1 minute)

Le dilemme ne survit que sur le plat sans mur. Partout où il y a un mur ou une descente de 0,6 m ou plus, la figure ne coûte aucune distance, le PERFECT est automatique, la jauge reste pleine (+15 %) et la ligne stylée va plus loin que la ligne sûre. Le dilemme ne tient plus que par le risque d'exécution, et l'appui simultané couvre ce risque.

Les joueurs sont des robots au timing parfait, d'où « sans risque ». Les distances sont mesurées le long de la course. Les munitions sont les tranches de 1 000 points de style ; la réserve plafonne à 3. Les vrilles sont tapées après le sommet, comme avec les vraies entrées. Exception : les lignes « idem + glissade parfaite » et « 2,4 m + roulade + figure » viennent d’une première passe où les vrilles étaient tapées pendant la montée sans couper le saut. Elles sont donc un peu optimistes ; les autres lignes ont été refaites avec des vrilles après le sommet et ne changent pas.

| Joueur | Style/min | Munitions | Jauge moy. | Vitesse moy. | Distance | Figures (PERFECT) | Crashs |
| ------ | --------- | --------- | ---------- | ------------ | -------- | ----------------- | ------ |
| Course droite | 0 | 0 | 0 | 9,00 m/s | 540 m | – | 0 |
| Sauter à chaque réception, plat | 75 | 0,1 | 75 | 9,00 | 540 | – | 0 |
| Saut + glissade parfaite, plat | 300 | 0,3 | 297 | 10,82 | 649 | – | 0 |
| Saut + figure au saut, plat | 50 | 0,1 | 1 | 5,64 | 338 | 0 | 62 |
| Marches de 0,5 m + figure (tout décalage 0–29) | aucun décalage sûr | | | | | | |
| Marches de 1,0 m, figure 1 pas après le saut | 144 700 | 145 | 2 883 | 10,97 | 658 | 87 (87) | 0 |
| idem + glissade parfaite | 175 700 | 176 | 2 911 | 12,00 | 720 | 87 (87) | 0 |
| Marches de 1,4 m, figure au pas 1 | 136 000 | 136 | 2 878 | 10,96 | 658 | 83 (83) | 0 |
| Marches de 2,0 m, figure au pas 1 | 132 200 | 132 | 2 872 | 10,96 | 658 | 80 (80) | 0 |
| Marches de 2,4 m + roulade, sans figure | 225 | 0,2 | 222 | 9,00 | 540 | – | 0 |
| Marches de 2,4 m + roulade + figure | 148 850 | 149 | 2 896 | 11,17 | 670 | 78 (78) | 0 |
| Le long d'un mur, zigzag saut / wall-run / wall-jump, sans figure | 31 000–36 000 | 31–36 | 2 771–2 799 | 9,39–9,49 | 563–569 | – | 0 |
| idem, figure au pas même du wall-jump (accord A+X) | 114 825 | 115 | 2 880 | 9,62 | 577 | 52 (52) | 0 |

Les fenêtres de la figure, en pas de 1/60 s comptés depuis l'appui sur saut. Tout décalage sûr est aussi PERFECT jusqu'à 3 m de descente :

| Descente | Décalages sans crash | Décalages PERFECT |
| -------- | -------------------- | ----------------- |
| 0,6 à 0,8 m | 0 | 0 |
| 0,9 et 1,0 m | 0 et 1 | 0 et 1 |
| 1,2 m | 0 à 2 | tous |
| 1,4 m | 0 à 3 | tous |
| 2,0 m | 0 à 5 | tous |
| 2,4 m (roulade) | 0 à 6 | tous |
| 3,0 m | 0 à 8 | tous |
| 4,0 m | 0 à 11 | 2 à 11 |
| 6,0 m | 0 à 16 | 7 à 16 |
| wall-jump (après 1 à 30 pas de wall-run) | 0 et 1 (0 à 2 pour 10 à 20 pas de wall-run) | tous |

Avant le saut, l'appui sur figure ne lance rien et ne coûte rien.

## Fichiers de l'inspection (hors dépôt)

- Ce rapport : C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks-2\report.md
- Les joueurs : C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks-2\scripts\test_zz_economy.gd et C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks-2\scripts\test_zz_economy_realistic.gd
- Les casses : C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks-2\scripts\all.sh, avec un journal par casse C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-air-tricks-2\mut_M*.log

`````
