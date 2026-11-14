# Leçons du tour — flow et combo, et les deux paliers de tests

Tour du 2026-11-14, propriétaire : Jimmy. Deux changements menés de front :
`docs/specs/flow-combo.md` (première moitié de l'étape 2) et `docs/specs/test-tiers.md`
(un changement de porte devenu nécessaire en cours de route). Pull requests n° 17
(spec du flow), n° 21 et n° 22 (paliers de tests), n° 23 (flow), n° 24 (notes). Les cinq
rapports des agents sont à la fin, mot pour mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

Particularité du tour : après avoir validé l'étape 1, Jimmy a délégué la suite de la
feuille de route (« enchaîne sur tout le reste […] fais tout jusqu'à ce que tu puisses
plus faire »). Le sparring du flow s'est fait avec lui (19 questions) ; ceux du sabotage
et du duel local, écrits pendant que le flow était développé, ont été tranchés par la
session principale seule.

## Déroulé

| Étape | Qui | Résultat |
| ----- | --- | -------- |
| Sparring du flow | session principale avec Jimmy | 19 questions en deux séries, 17 décisions, 36 scénarios ; pull request n° 17 |
| Développement, passe 1 | développeur, worktree isolé | 173 tests, `just check` vert ; 22 sabotages ; `just preflight` à 28,8 s pour 30 s ; environ 27 min |
| Inspection 1 | inspecteur, contexte neuf | « conforme », 7 constats conseillés, dont le gain des glissades parfaites qui se cumule jusqu'au plafond absolu (9 à 22 m/s en 3 s) ; environ 12 min |
| Spec des paliers de tests | session principale | `just preflight` sans les rejeux du parcours, `just check` complet ; pull request n° 21 |
| Paliers de tests | développeur en parallèle, puis inspecteur | `just preflight` de 27,5 s à 17 s ; « conforme », un trou du garde-fou fermé ; pull request n° 22 |
| Amendement 1 du flow, passe 2 | session principale, puis développeur | gain plafonné, munitions au-delà de la jauge pleine, vitesse réelle ; 178 tests |
| Inspection 2 | inspecteur, contexte neuf | « à corriger » : deux boucles sans risque mesurées avec le vrai moteur ; environ 10 min |
| Amendement 2 du flow, passe 3 | session principale, puis développeur | munitions par points de style, répétition sur les quatre derniers moves ; 180 tests ; les deux boucles fermées |
| Clôture | session principale | `just check` vert, CI verte, fusion |

## Leçons

1. **Une économie de jeu se prouve contre les boucles, pas seulement contre ses
   scénarios.** Les 36 scénarios d'origine passaient tous, et l'économie cassait le
   dilemme du plan de trois façons : un gain de vitesse qui se cumulait, une jauge
   pleine qui redonnait une munition à chaque petite baisse (23 par minute), une
   alternance saut et glissade tenue qui remplissait la jauge en 10 s. Chaque fois, c'est
   un inspecteur qui a écrit un petit joueur sans risque et mesuré ce qu'il gagnait par
   minute. Proposition : toute spec qui donne une récompense (jauge, munitions, vitesse,
   score) contient des scénarios « une boucle sans risque ne rapporte pas », et le brief
   de l'inspecteur lui demande de chercher ces boucles.
2. **La seconde inspection a encore trouvé ce que la première avait laissé.** La
   première a vu le cumul de vitesse ; la seconde, sans les rapports, les deux boucles de
   munitions et de jauge. Troisième tour de suite où elle paie ; elle reste la norme pour
   tout changement du moteur ou d'une économie.
3. **Un sparring tranché par la session principale seule produit des règles plus
   fragiles.** Les deux amendements corrigent des décisions que la session principale
   avait proposées et que Jimmy avait acceptées d'un « oui pour tout ». Proposition :
   quand la délégation est totale, la spec dit pour chaque récompense ce qu'un joueur
   prudent gagne par minute, avant le développement.
4. **Une porte trop serrée se règle par sa propre spec, en parallèle.** À 1,2 s de la
   limite de `just preflight`, trois specs de rejeux arrivaient. Une spec dédiée, un
   développeur en parallèle du flow, une inspection : `just preflight` est revenu à
   17 s sans qu'aucun test ne sorte de `just check`. Le garde-fou de nommage a eu besoin
   d'une correction (le chargement par le réglage de la scène principale).
5. **Des agents en parallèle faussent les mesures de temps.** `just preflight` a mesuré
   17 s, 19 s et 24 s selon la charge de la machine. Les limites de temps se lisent
   machine au repos ; un rapport dit si d'autres agents tournaient.

## Ce qui reste ouvert après ce tour

- **À juger par Jimmy en jouant** : le rythme de la jauge, la fenêtre et le gain de la
  glissade parfaite, le bonus de vitesse par palier, le HUD, le saut régulier qui garde
  la jauge au palier 2 (accepté).
- Le pilote ne fait jamais de glissade parfaite sur le parcours.
- Toujours ouverts depuis les tours précédents : voir
  `docs/harness/2026-11-13-movement-walls.md`.

## Rapports des agents, mot pour mot

### Développeur, flow (trois passes)

`````markdown
# Rapport du développeur : `docs/specs/flow-combo.md`

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a54451d8d180553ed`
Branche : `flow-combo` (depuis `main` à `8eb4ead`), non poussée.
Commits :
- `872f7d2` flow-combo: the gauge that moves fill (le code et les tests)
- `f06b281` spec: flow-combo implemented (la ligne de statut seulement)

Routage (`.agents/skills/index.md`) : types `core`, `levels`, `ui`, plus les tests. Aucun skill
à charger. Les vérifications en plus des types `levels` et `ui` sont dans « Vérifié » et
« Non vérifié ».

## Fait

**Architecture (décision 12)**
- `game/core/runner_event.gd` (`RunnerEvent`) : le message daté. Il donne le genre (JUMP,
  SLIDE, PERFECT_SLIDE, ROLL, MANTLE, WALL_RUN, WALL_JUMP, HARD_LANDING) et le pas fixe du
  moteur.
- `RunnerMotor` compte ses pas (`steps`). À chaque pas, il remplit `events` avec les moves
  commencés et la réception dure. Il expose `top_speed()` (`top_speed` × (1 + bonus)),
  `horizontal_speed()` et `is_on_foot()` (GROUNDED ou HARD_LANDING). Le bonus arrive par
  `top_speed_bonus` ; `_steer` utilise `top_speed()` ; le plafond absolu ne change pas.
- `game/core/flow_state.gd` (`FlowState`) : la jauge, le combo, le multiplicateur, la
  répétition, les munitions, le score de style et le meilleur score. `step(events, vitesse,
  au_sol)` ne compte qu'à partir des messages. `follow(motor)` fait le pas et rend le bonus
  au moteur. Les ordres de la course sont `respawn()`, `restart()` et `finish()`. Aucune
  référence à `player`, à une scène ou à une entrée (`just deadcode` : 0 problème).
- `game/levels/course.gd` assemble à chaque pas, dans cet ordre : la règle de retour, puis
  `flow.respawn()` ou `flow.restart()`, puis `flow.follow(motor)`. La ligne d'arrivée passe
  par `_on_finish_line_crossed`, qui fige le flow quand la course est finie. Le flow suit
  la ressource de réglage du coureur, donc F4 vaut aussi pour lui.
- Glissade parfaite (décision 9), dans le moteur : `_start_slide` regarde les pas depuis
  le dernier atterrissage et depuis le dernier appui. Les deux doivent être dans la
  fenêtre. Le gain s'ajoute dans le sens de la vitesse horizontale, puis `_move` applique le
  plafond.
- Réglages (décision 13) : un groupe « Flow » de 22 valeurs dans `movement_tuning.gd` et
  `.tres`, avec les valeurs de départ du tableau de la spec.
- Affichages : `game/ui/flow_hud.gd` et `.tscn` (créés), un nœud `Hud/FlowHud` dans
  `test_course.tscn`. `race_hud` (modifié) affiche STYLE et BEST STYLE sous le temps à
  l'arrivée. `debug_overlay` (modifié) ajoute GAUGE, TIER, CHAIN, REPEAT, MULTIPLIER et
  SPEED BONUS.

**Les 38 scénarios et leurs tests**

| Scénario | Test | Fichier |
| -------- | ---- | ------- |
| Chaque move commencé rapporte ses points | `test_every_move_started_earns_its_points` | `tests/test_runner_flow.gd` |
| Un saut sans élan ne compte pas | `test_a_jump_without_run_up_does_not_count` | `tests/test_runner_flow.gd` |
| Un wall-jump ne compte pas aussi comme un saut | `test_a_wall_jump_does_not_also_count_as_a_jump` | `tests/test_runner_flow.gd` |
| Le même move répété d'affilée vaut de moins en moins | `test_the_same_move_repeated_in_a_row_is_worth_less_and_less` | `tests/test_flow.gd` |
| Un autre move remet la répétition à zéro | `test_another_move_resets_the_repetition` | `tests/test_flow.gd` |
| Un move répété sans valeur prolonge quand même le combo | `test_a_repeated_move_worth_nothing_still_extends_the_combo` | `tests/test_flow.gd` |
| Le multiplicateur monte tous les quatre moves | `test_the_multiplier_rises_every_four_moves` | `tests/test_flow.gd` |
| Le multiplicateur ne dépasse pas son maximum | `test_the_multiplier_does_not_go_above_its_maximum` | `tests/test_flow.gd` |
| Le combo se termine sans pénalité après le délai au sol | `test_the_combo_ends_without_penalty_after_the_delay_on_the_ground` | `tests/test_flow.gd` |
| Le délai ne s'écoule pas en l'air | `test_the_delay_does_not_run_in_the_air` | `tests/test_runner_flow.gd` |
| Une réception dure casse le combo et coûte un palier | `test_a_hard_landing_breaks_the_combo_and_costs_a_tier` | `tests/test_runner_flow.gd` |
| Une réception dure ne fait pas passer la jauge sous zéro | `test_a_hard_landing_does_not_take_the_gauge_below_zero` | `tests/test_flow.gd` |
| S'arrêter casse le combo | `test_stopping_breaks_the_combo` | `tests/test_flow.gd` |
| Une chute hors du parcours vide la jauge et garde le reste | `test_a_fall_off_the_course_empties_the_gauge_and_keeps_the_rest` | `tests/test_flow.gd` |
| Le retour au checkpoint demandé vide la jauge | `test_returning_to_the_checkpoint_on_request_empties_the_gauge` | `tests/test_course_flow.gd` |
| Recommencer remet tout à zéro | `test_restarting_resets_everything` | `tests/test_course_flow.gd` |
| La jauge ne baisse pas pendant un combo | `test_the_gauge_does_not_drop_during_a_combo` | `tests/test_flow.gd` |
| La jauge baisse lentement hors combo | `test_the_gauge_drops_slowly_out_of_a_combo` | `tests/test_flow.gd` |
| La jauge ne dépasse pas son maximum | `test_the_gauge_does_not_go_above_its_maximum` | `tests/test_flow.gd` |
| Chaque palier augmente la vitesse de pointe | `test_every_tier_raises_the_top_speed` | `tests/test_runner_flow.gd` |
| Le bonus de vitesse suit la jauge en descendant | `test_the_speed_bonus_follows_the_gauge_down` | `tests/test_flow.gd` |
| Franchir un palier en montant donne une munition | `test_crossing_a_tier_upwards_gives_ammunition` | `tests/test_flow.gd` |
| Les munitions ne dépassent pas leur maximum | `test_ammunition_does_not_go_above_its_maximum` | `tests/test_flow.gd` |
| Une glissade commencée juste à l'atterrissage est parfaite | `test_a_slide_started_right_at_the_landing_is_perfect` | `tests/test_runner_perfect_slide.gd` |
| Une glissade commencée juste après l'atterrissage est parfaite | `test_a_slide_started_right_after_the_landing_is_perfect` | `tests/test_runner_perfect_slide.gd` |
| Une glissade hors de la fenêtre est une glissade simple | `test_a_slide_out_of_the_window_is_a_plain_slide` | `tests/test_runner_perfect_slide.gd` |
| Le gain de la glissade parfaite respecte le plafond absolu | `test_the_gain_of_a_perfect_slide_respects_the_absolute_cap` | `tests/test_runner_perfect_slide.gd` |
| Une grande chute donne une roulade, pas une glissade parfaite | `test_a_big_fall_gives_a_roll_not_a_perfect_slide` | `tests/test_runner_perfect_slide.gd` |
| À l'arrivée, le flow se fige | `test_at_the_finish_the_flow_freezes` | `tests/test_flow.gd` |
| Le meilleur score de style de la session est gardé | `test_the_best_style_score_of_the_session_is_kept` | `tests/test_flow.gd` |
| Le parcours rapporte du flow | `test_the_course_earns_flow` | `tests/test_course_flow.gd` |
| Le parcours reste faisable à pleine vitesse | `test_the_course_stays_clearable_at_full_speed` | `tests/test_course_flow.gd` |
| Le HUD montre le move et ses points | `test_the_hud_shows_the_move_and_its_points` | `tests/test_flow_hud.gd` |
| Le HUD signale un palier franchi | `test_the_hud_signals_a_tier_crossed` | `tests/test_flow_hud.gd` |
| Le HUD signale un combo cassé | `test_the_hud_signals_a_broken_combo` | `tests/test_flow_hud.gd` |
| Le HUD montre les munitions | `test_the_hud_shows_the_ammunition` | `tests/test_flow_hud.gd` |
| L'arrivée montre le score de style | `test_the_finish_shows_the_style_score` | `tests/test_race_hud.gd` |
| L'affichage de debug montre le flow | `test_the_debug_display_shows_the_flow` | `tests/test_debug_overlay.gd` |

Les tests de `tests/test_flow.gd` rejouent des listes de messages, sans physique
(décision 12). Ceux de `tests/test_runner_flow.gd` et `tests/test_runner_perfect_slide.gd`
passent par le vrai moteur (`MotorBody`), pour prouver ce que le moteur annonce. Ceux de
`tests/test_course_flow.gd` tournent dans la vraie physique, sur le parcours.

**Aides de test modifiées (rien d'affaibli)**
- `tests/motor_body.gd` : `fixed_tuning()` reçoit les 22 valeurs du groupe Flow.
- `tests/scripted_intent_source.gd` : nouvelle `request_restart()`.
- `tests/pilot_intent_source.gd` : `_speed_ahead()` plafonne à `motor.top_speed()`, qui
  inclut le bonus, au lieu de `tuning.top_speed`. Sans bonus, rien ne change. Avec le bonus,
  le pilote estime sa vitesse comme elle est vraiment.

## Vérifié

- `just setup` dans le worktree : OK. `just preflight` sur `main` avant de commencer : vert,
  135 tests, 27,4 s (les tests seuls : 15,97 s).
- **Rouge avant le code** : j'ai d'abord écrit des classes avec la bonne API mais un
  comportement vide (`FlowState`, `FlowHud`, les nouvelles fonctions du moteur, les champs
  `flow`). Puis j'ai lancé les 7 fichiers de test, un par un. Les **38 tests nouveaux
  étaient rouges, tous sur leurs assertions**, aucun sur une erreur de parse. Exemples :
  « [0] expected to equal [50]: the first jump is worth all its points » ; « ARRAY([]) !=
  ARRAY(["PERFECT_SLIDE"]) » ; « [9.0] expected to equal [10.35]: LongJumps: at tier 3 ».
  Les sorties sont dans
  `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\red_*.txt`.
- **Sabotages** : un script du scratchpad
  (`C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\mutate.py`)
  applique un sabotage, lance les tests visés, puis restaure le fichier, avec un md5
  vérifié. **22 sabotages sur 22 tués**. Le détail est dans
  `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\mutations.txt`.
  Les sabotages essayés : la fenêtre de la glissade parfaite ignorée, ou réduite au seul
  appui ; le gain sans plafond ; un gain sur la roulade ; un wall-jump annoncé aussi comme
  saut ; le bonus ignoré par le moteur ; la jauge qui baisse en combo ; le délai qui
  s'écoule en l'air ; un move à 0 qui ne prolonge pas le combo ; une erreur qui ne remet pas
  la répétition à zéro ; un saut lent qui compte ; `<=` au lieu de `<` pour la vitesse du
  saut ; l'arrêt compté à 1 m/s pile, ou en l'air ; le move qui monte le multiplicateur
  compté au nouveau ; un respawn qui vide un flow figé ; un recommencement qui oublie le
  meilleur score ; la course qui n'appelle ni `flow.respawn`, ni `flow.restart`, ni
  `flow.follow` ; pas de COMBO BROKEN ; des munitions au-delà du maximum.
  Leçon du dernier tour appliquée : plusieurs règles disent « ne change pas pendant X ». Pour
  chacune, l'entrée change pendant X :
  - jauge en combo : sol et air alternés, vitesse variable ;
  - délai en l'air : poussée qui tourne pendant la chute ;
  - arrivée : moves, réception dure, arrêt et respawn après l'arrivée.
- **Rejeux à ±10 % des nouvelles valeurs**, avec un test temporaire, supprimé ensuite et
  jamais commité :
  - bonus du palier 3 à 0,165 puis 0,135 (au lieu de 0,15), sur les quatre sections de la
    décision 14 : les 8 courses franchissent leur section ;
  - `perfect_slide_speed_gain` × 1,1 et × 0,9, et `perfect_slide_window` × 1,1 et × 0,9, sur
    les 10 sections : les 40 courses franchissent leur section. **Mais le pilote ne fait
    jamais de glissade parfaite** : 0 sur toutes les courses. Ces rejeux ne prouvent donc
    rien sur le gain de la glissade parfaite (voir « Non vérifié »).
  - Ce que le flow fait en vrai, réglages du projet, d'après le même relevé : le zigzag
    seul monte la jauge à 2 150 (palier 2, pointe à 11,40 m/s). La combinaison finale monte
    à 500, les autres sections à 200 au plus. Les tests existants à ±10 % (vitesse,
    gravités, hauteur de saut) tournent désormais avec le flow actif, donc ce bonus compris.
    Ils restent verts.
- Lint : `gdlint` relevait trop de `return` dans `_points` ; je l'ai réécrit avec un
  dictionnaire. `gdformat` a reformaté trois fichiers, que j'ai remis en fins de ligne LF.
- `just preflight` final : vert, 173 tests sur 173, **28,8 s** mesurés deux fois (les tests
  seuls : 17,0 s). C'est sous les 30 s de la décision 14, mais il ne reste que 1,2 s de
  marge. Le gate rapide a pris 1,4 s par rapport à `main` (27,4 s dans ce worktree).
- `just check` sur l'arbre commité en `872f7d2` : vert, code de sortie 0, 37,1 s.
  Vérification des types sur 47 scripts sans erreur, lint propre, 173 tests sur 173,
  structure à 0 problème (53 fichiers), builds Windows et Linux exportés, build Windows
  lancé 60 images sans écran.
- `just deadcode` après le commit du statut : 0 problème.

## Non vérifié

Je n'ai rien joué : pas d'écran ni de manette ici. Seuls les tests sans écran et le build
lancé sans écran ont tourné. Ce que Jimmy doit juger manette en main :
- **Le ressenti de la glissade parfaite** : la fenêtre de 0,15 s autour de l'atterrissage
  et le gain de 2 m/s. Le parcours ne la prouve nulle part, car le pilote n'en fait jamais.
  Aucun test ne garantit qu'une glissade parfaite, sur le parcours, ne fait pas rater une
  réception.
- **Le bonus de vitesse en jeu** : le zigzag seul donne le palier 2 (+10 %). Le parcours
  complet joué avec style monte probablement au palier 3. Les sections qui ne sont pas dans
  la décision 14 (sauts courts, marches, passage bas, grande chute, rebord) ne sont pas
  rejouées à pleine vitesse.
- **L'économie** : est-ce qu'enchaîner saut et glissade sur le plat remplit trop vite ? Le
  délai de 2 s au sol est-il trop court ou trop long ? La baisse de 100 par seconde
  est-elle juste ? Le dilemme « stylé contre sûr » existe-t-il vraiment ?
- **Le HUD à l'écran** (type `ui`) :
  - la barre en bas au centre et ses trois marques blanches ;
  - « x1 » à gauche, les trois pastilles jaunes à droite (pleines ou cerclées) ;
  - « FLOW n » en jaune au-dessus du texte du move ;
  - le flash de la jauge : 0,4 s, modulé à ×2 ;
  - l'effacement des textes après 1 s ;
  - STYLE et BEST STYLE sous le temps à l'arrivée ;
  - les six lignes de flow de F3, et la hauteur du cadre de debug portée à 400 px.

  Aucune image de référence ; je n'ai rien vu à l'écran. L'effacement après 1 s n'a pas de
  test : ce n'est pas un scénario.
- **F4** : la course repasse la ressource du coureur au flow à chaque pas, donc F4 vaut
  aussi pour le flow. Aucun test ne recharge une valeur du groupe Flow.
- **Le parcours de bout en bout** (type `levels`) : chaque section est prouvée seule, avec
  le flow actif, mais aucun test ne fait le parcours entier d'un seul tenant. Les sections
  suivantes partent donc avec une jauge vide, alors qu'en vrai la jauge se porte d'une
  section à l'autre.

## Écarts

Les choix faits là où la spec se tait, à inscrire dans la spec si vous les acceptez :

1. **La répétition survit à la fin d'un combo par le délai.** La décision 4 dit seulement
   que le multiplicateur revient à ×1. Seuls un autre move ou une erreur remettent la
   répétition à zéro (décisions 3 et 5). Sauter, attendre 2 s, puis sauter donne donc 50,
   puis 25, puis 0. C'est la lecture la plus littérale et la plus anti-farm.
2. **Une erreur hors combo remet aussi la répétition à zéro** : arrêt, réception dure ou
   respawn. « COMBO BROKEN » ne s'affiche que s'il y avait un combo. Le compteur
   `combos_broken` ne compte que les vrais combos cassés.
3. **« Au sol », pour le délai et pour l'arrêt**, veut dire l'état GROUNDED ou HARD_LANDING.
   Le délai est suspendu partout ailleurs, comme la décision 4 l'énumère.
4. **L'arrêt casse le combo une fois par arrêt**, au pas où l'arrêt atteint 1 s. Il ne se
   répète pas tant que le coureur reste immobile. « Sous 1 m/s » est strict : 1 m/s pile
   n'est pas un arrêt.
5. **La vitesse d'un saut** est la vitesse horizontale que le moteur veut au pas du saut.
   Le seuil est la moitié du `top_speed` **de la ressource**, sans le bonus. « Atteint »
   veut dire `>=`.
6. **La date d'un message** est le compteur de pas du moteur. Il n'est jamais remis à zéro,
   même par un respawn. Le flow ne lit pas la date aujourd'hui : il compte par pas. Les
   tests vérifient que chaque message porte le pas de son move.
7. **Les messages d'un pas de respawn sont perdus.** La course exécute d'abord le retour
   (`motor.reset()` vide `events`), puis le flow suit le moteur. Ces moves n'auraient de
   toute façon rien rapporté à la jauge, remise à 0.
8. **Arrivée** : un flow figé ignore aussi `respawn()`. « Plus rien ne compte jusqu'au
   recommencement. »
9. **Le flow compte aussi avant la ligne de départ.** La décision 11 ne fige qu'à l'arrivée.
   Le départ est à 3 m de la ligne, donc la différence est minime. Recommencer remet tout à
   zéro, comme le chrono.
10. **La baisse hors combo** s'applique à un pas passé hors combo du début à la fin. Le pas
    où un combo commence ne baisse pas. Le pas où il se termine non plus, ce qui garantit
    « la jauge ne perd rien » à la fin du combo.
11. **Ce qui « commence » une glissade** : le passage de GROUNDED à SLIDING demandé par le
    joueur, y compris en sortie de roulade bouton tenu. Une glissade forcée ne compte pas :
    réception basse, ou roulade qui finit sous un plafond.
12. **« Atterrissage » pour la glissade parfaite** : une vraie chute, de hauteur finie. Un
    coureur juste posé (spawn, respawn) n'atterrit pas. Sans ce garde-fou, chaque `MotorBody`
    neuf aurait « atterri » à son premier pas.
13. **La glissade parfaite** exige que le dernier appui **et** l'atterrissage soient tous
    deux dans la fenêtre au pas où la glissade commence. Un bouton tenu depuis longtemps ne
    donne qu'une glissade simple.
14. **Le gain de la glissade parfaite** est appliqué au pas où elle commence, avant la
    décélération de ce pas. Le plafond est appliqué ensuite par le moteur, comme d'habitude.
15. **Points arrondis** : `roundi(points × part) × multiplicateur`. La jauge est un `float`
    (la baisse ajoute des fractions), le score de style un entier.
16. **Réglages** : 22 valeurs dans le groupe « Flow ». Les bonus de vitesse sont une liste
    (`flow_tier_speed_bonus`) ; un palier au-delà de la liste prend le dernier bonus. Le
    nombre de paliers reste un réglage séparé, et les marques de la jauge et les pastilles
    suivent `flow_tier_count` et `flow_max_ammo`. Le gain et la fenêtre de la glissade
    parfaite sont dans ce groupe, comme le dit la décision 13.
17. **HUD** :
    - « FLOW n » s'affiche au-dessus du texte du move ; « COMBO BROKEN » prend la place du
      texte du move.
    - Le flash de la jauge dure 0,4 s, et les textes 1 s.
    - Les pastilles sont des disques pleins ou cerclés, lisibles sans la couleur.
    - Les durées d'affichage sont des constantes de `game/ui/flow_hud.gd`, pas des
      réglages : c'est de la présentation, pas du ressenti du mouvement.
18. **Libellés de debug** : GAUGE, TIER, CHAIN, REPEAT (le move et « xN », « - » sans
    répétition), MULTIPLIER, SPEED BONUS en %. « FLOW » est gardé pour le HUD, où il veut
    dire le palier.
19. **Deux scénarios marqués « (core) » sont testés par la course**, dans la vraie physique.
    C'est le cas du retour demandé et de « Recommencer remet tout à zéro ». Le test prouve
    ainsi la règle et son câblage. La chute hors du parcours est testée en `core` seul.
20. **Test « Chaque move commencé rapporte ses points »** : il vérifie le wall-run du
    scénario, puis les six autres moves. Pour chacun : un seul message, du bon genre, au bon
    pas, avec ses points.
21. **Le pilote utilise `motor.top_speed()`** : c'est une aide de test, modifiée sans
    affaiblir aucun test.
22. **`AGENTS.md` n'a pas changé**, comme demandé. Des lignes de description suivent le
    code et sont à mettre à jour par la session principale :
    - « Layout », `core/` : ajouter « the flow state and the dated messages of the motor » ;
    - « Layout », `ui/` : « timer, flow and debug displays » ;
    - « Layout », `tests/` : les aides n'ont pas changé de nature.
    - La règle « dated message » de l'architecture parle du sabotage. Les messages du moteur
      en sont un premier exemple.

## Questions

Rien ne bloque la fusion. À trancher si la session principale le veut :
- Accepter les choix 1, 2, 9 et 12 ci-dessus (ce sont eux qui touchent l'économie) et les
  inscrire dans la spec.
- **Marge du gate rapide** : 28,8 s pour une limite de 30 s. La prochaine spec qui ajoute
  des rejeux sur le parcours risque de la dépasser. Faut-il prévoir dès maintenant comment
  regrouper les rejeux ?
- Faut-il un test où le pilote fait une glissade parfaite sur le parcours, pour garantir
  que le gain ne fait pas rater une réception ? La spec ne le demande pas.

---

## Amendement après inspection (spec amendée en `052ec2c`, 43 scénarios)

Les cinq nouveaux scénarios sont implémentés et `just check` est vert. Mais `just preflight`
dépasse désormais la limite : 29,9 s et 30,8 s, pour 30 s. Comme convenu, je le signale et
je continue.

Commits sur `flow-combo` :
- `ea20f57` flow-combo: the amendment after the inspection (le code et les tests)
- `e26e055` agents: the layout names the flow state and the flow display (les deux lignes
  de « Layout » d'`AGENTS.md`, rien d'autre)
- `0002324` spec: flow-combo amendment implemented (le statut repasse à 🟢)

### Fait

| Scénario | Test | Rouge avant le code ? |
| -------- | ---- | --------------------- |
| La fin d'un combo remet la répétition à zéro | `test_the_end_of_a_combo_resets_the_repetition` (`tests/test_flow.gd`) | oui : le saut valait 0 au lieu de 50 |
| Une jauge pleine continue de donner des munitions par le style | `test_a_full_gauge_keeps_giving_ammunition_for_style` (`tests/test_flow.gd`) | oui : 0 munition au lieu de 1 |
| Les glissades parfaites ne font pas monter la vitesse sans fin | `test_perfect_slides_do_not_raise_the_speed_without_end` (`tests/test_runner_perfect_slide.gd`) | oui : 9,65 m/s au-dessus de la limite, et le coureur déjà rapide gagnait 2 m/s |
| Franchir la ligne d'arrivée fige le flow | `test_crossing_the_finish_line_freezes_the_flow` (`tests/test_course_flow.gd`) | non : le code existait déjà. Le test est rouge avec le sabotage de l'inspecteur (`flow.finish()` remplacé par `pass`) |
| Un coureur qui pousse contre un mur est arrêté | `test_a_runner_pushing_against_a_wall_is_stopped` (`tests/test_course_flow.gd`) | oui, pour le cas « poussée forte » ; voir ci-dessous |

- **Décision 9** (`runner_motor.gd`, `_start_slide`) : la vitesse devient
  `min(vitesse + gain, top_speed() + gain)`, où `top_speed()` inclut le bonus du flow. Un
  coureur déjà plus rapide garde sa vitesse, sans gain. Le plafond absolu s'applique
  ensuite, comme avant.
  - Le test enchaîne dix fois un petit saut et une glissade parfaite, en suivant le flow.
    Il vérifie que la vitesse ne dépasse jamais la limite du moment, et que la dernière
    glissade atteint exactement cette limite, bonus du palier compris.
  - Sans cette seconde vérification, le sabotage « la limite ignore le bonus » passait vert.
    Je l'ai donc ajoutée.
- **Décision 8** (`flow_state.gd`, `_fill`) : quand la jauge est pleine, les points en trop
  s'accumulent. Chaque fois que le cumul atteint la valeur d'un palier, le coureur gagne une
  munition (au plus le maximum), et le cumul perd la valeur d'un palier.
- **Décision 3** : la fin d'un combo par le délai remet aussi la répétition à zéro.
- **Décisions 3 et 5** : le flow lit `motor.real_speed()`, la vitesse horizontale des faits
  du pas. C'est celle que la physique a laissée au coureur au pas d'avant. L'ancienne
  `horizontal_speed()` (la vitesse voulue) est supprimée.
- **Test du mur** : il tourne dans la vraie physique, contre la face de la première marche,
  avec deux coureurs.
  - Avec les réglages du projet, l'ancien code passait déjà : la vitesse voulue contre un
    mur vaut 0,5 m/s, sous le seuil de l'arrêt.
  - D'où un second coureur, avec une accélération au sol ×4 : il demande 2 m/s à chaque pas,
    au-dessus de 1 m/s. Celui-là est rouge sur l'ancien code et vert sur le nouveau.
- **Un test existant a changé** : `test_the_gain_of_a_perfect_slide_respects_the_absolute_cap`.
  Avec la décision 9 amendée, un coureur qui atterrit à 21 m/s ne gagne plus rien. Le test
  baisse donc le plafond à `top_speed` + la moitié du gain (10 m/s), et fait atterrir le
  coureur à `top_speed`. Le gain seul le mènerait au-delà, et il s'arrête au plafond. Le
  scénario est toujours celui-là, et le test reste rouge avec le sabotage « gain sans
  plafond ».

### Vérifié

- Avant le code, sur `f06b281` + les nouveaux tests : 4 tests rouges sur leurs assertions.
  Le cinquième (l'arrivée) était vert, car le code existait déjà.
  - Une première version du test d'enchaînement était rouge pour une mauvaise raison : aucune
    glissade parfaite. Le script relâchait la glissade au pas même de l'atterrissage. Je l'ai
    corrigée avant d'écrire le code ; elle était ensuite rouge pour la bonne raison.
- **Sabotages : 29 sur 29 détectés**. Ce sont les 22 d'avant, rejoués sur le code amendé, et
  7 nouveaux :
  - la course qui ne fige plus le flow ;
  - le flow qui lit la vitesse voulue ;
  - le gain qui se cumule de nouveau ;
  - la limite sans le bonus ;
  - un coureur rapide ralenti jusqu'à la limite ;
  - la fin du combo qui garde la répétition ;
  - rien au-delà de la jauge pleine.

  Chaque fichier a été restauré, md5 vérifié.
- `just preflight` : vert, 178 tests. Durées : 34,5 s juste après un reformatage, puis
  29,9 s et 30,8 s (les tests seuls : 17,9 s). **C'est au-dessus de 30 s une fois sur
  deux**.
- `just check` sur l'arbre de `ea20f57` : vert, code de sortie 0, 47,1 s. Types sans erreur
  (47 scripts), lint propre, 178 tests sur 178, structure à 0 problème, builds Windows et
  Linux exportés, build Windows lancé.
- `just deadcode` sur `0002324` : 0 problème.

### Non vérifié

- **Le ressenti de la vitesse plafonnée** : top + 2 m/s, soit 11 m/s sans bonus et 12,35 m/s
  au palier 3. Est-ce encore une récompense ?
- **L'arrêt contre un mur en jeu** : le seuil de 1 m/s, lu une fois par pas sur la vitesse
  réelle du pas d'avant.
- **Les munitions par le style à jauge pleine** : se rechargent-elles trop vite, ou pas
  assez ?
- **Le pilote ne fait toujours pas de glissade parfaite** sur le parcours.

### Écarts

1. **Le cumul au-delà de la jauge pleine**, à chaque munition, perd la valeur d'un palier et
   garde le reste. Je n'ai pas lu « repart de zéro » au pied de la lettre : avec un cumul de
   1 150, le prochain compte part de 150 et non de 0, pour qu'aucun point ne se perde.
2. **Le cumul retombe à zéro** dès que la jauge n'est plus pleine : baisse hors combo,
   réception dure, chute, retour au checkpoint. Il retombe aussi au recommencement. Un arrêt
   le garde au pas même, puis il tombe dès que la jauge baisse. **Aucun test ne couvre ces
   remises à zéro**, car ce n'est pas un scénario.
3. **La vitesse réelle** est celle des faits que le moteur reçoit au début du pas : la
   vitesse laissée par la physique à la fin du pas d'avant. L'arrêt se lit donc avec un pas
   de retard, et un saut se juge sur la vitesse qu'avait le coureur en le lançant.
4. **Le mur du test** est la face de la première marche du parcours. Elle mesure 1 m de
   haut, ce qui n'est pas un mur de wall-run, mais une face qui arrête le coureur.
5. **Le test d'enchaînement** utilise de petits sauts : le bouton n'est tenu qu'au premier
   pas. C'est le cas que l'inspecteur a mesuré.

### Questions

- Les deux choix sur le cumul (le reste gardé, la remise à zéro quand la jauge n'est plus
  pleine) vous conviennent-ils ?
- **`just preflight` est à la limite** : 29,9 à 30,8 s. La branche `test-tiers` doit sortir
  les rejeux du parcours du gate rapide.

---

## Second amendement (spec amendée en `209ed83`, 45 scénarios)

Les boucles de l'inspecteur sont fermées : plus de jauge pleine sans risque, et au plus
1 munition par minute. `just check` est vert. Une boucle reste ouverte (voir
« Questions »).

Commits sur `flow-combo` :
- `0d23669` flow-combo: the second amendment (le code et les tests)
- `a1b57a9` spec: flow-combo second amendment implemented (le statut repasse à 🟢)

### Fait

- **Décision 8** : les munitions viennent des points de style. Chaque tranche de
  `flow_points_per_ammo` points (1 000) donne +1 munition, 3 au plus. Le reste est gardé
  (`FlowState.ammo_progress`), même quand le coureur a déjà le maximum. Les paliers ne
  donnent plus que la vitesse, et les annonces « FLOW n » du HUD. Le cumul au-delà de la
  jauge pleine est supprimé.
- **Décision 3** : la valeur d'un move se juge sur les quatre derniers moves du combo qui
  valaient quelque chose. Absent, il vaut 100 % ; présent une fois, 50 % ; deux fois ou
  plus, 0 %. Un move à 0 % ne rapporte rien, ne relance pas le délai, n'entre pas dans les
  quatre derniers et ne compte pas pour le multiplicateur. La fin d'un combo, une erreur,
  une chute ou un recommencement vident ces quatre derniers moves.
- **Décision 2** : une glissade, parfaite ou non, ne compte que si le bouton a été pressé
  depuis la dernière glissade. Une glissade tenue a toujours lieu, mais sans annonce ni
  gain. Dans le code, c'est l'indicateur `_slide_pressed_since_the_last_slide` du moteur.
  Un respawn le remet à faux.

| Scénario | Test | Rouge avant le code ? |
| -------- | ---- | --------------------- |
| Un move absent des quatre derniers vaut tous ses points (remplace « Un autre move remet la répétition à zéro ») | `test_a_move_absent_from_the_last_four_is_worth_all_its_points` (`tests/test_flow.gd`) | oui : avec trois moves seulement depuis le saut, l'ancien code donnait 100 au lieu de 50 |
| Alterner saut et glissade sur le plat ne remplit pas la jauge sans fin | `test_alternating_jump_and_slide_on_the_flat_does_not_fill_the_gauge_without_end` (`tests/test_runner_flow.gd`, vrai moteur, une nouvelle pression à chaque glissade) | oui : l'ancien code donnait 50, 50, 50, 50, la jauge pleine, et le combo ne finissait jamais |
| Une glissade tenue ne compte qu'une fois | `test_a_held_slide_counts_only_once` (`tests/test_runner_flow.gd`) | oui : 16 glissades comptées au lieu d'une |
| Un move sans valeur ne prolonge pas le combo (remplace « Un move répété sans valeur prolonge quand même le combo ») | `test_a_move_worth_nothing_does_not_extend_the_combo` (`tests/test_flow.gd`) | oui : ×2 au lieu de ×1, et le combo continuait |
| Chaque tranche de points de style donne une munition (remplace « Franchir un palier en montant donne une munition ») | `test_every_slice_of_style_points_gives_ammunition` (`tests/test_flow.gd`) | oui : 0 munition, 0 point vers la suivante |
| Une jauge qui redescend puis remonte ne donne pas de munition en plus (remplace « Une jauge pleine continue de donner des munitions par le style ») | `test_a_gauge_that_drops_then_rises_again_gives_no_extra_ammunition` (`tests/test_flow.gd`) | oui : 3 munitions au lieu d'1 |
| Les munitions ne dépassent pas leur maximum (réécrit) | `test_ammunition_does_not_go_above_its_maximum` | oui : 0 point vers la suivante au lieu de 100 |

Aucun test d'un scénario remplacé ne reste : j'ai vérifié par une recherche des quatre
anciens noms.

**Tests existants adaptés aux nouvelles règles.** Rien n'est affaibli ; chacun reste rouge
pour au moins une de ses cassures.
- `test_the_same_move_repeated_in_a_row_is_worth_less_and_less` : `repeat_count` vaut
  maintenant 3 au lieu de 4. Le compte est celui des quatre derniers moves, le move jugé
  compris, et le saut à 0 % n'y entre pas.
- `test_a_fall_off_the_course_empties_the_gauge_and_keeps_the_rest` et
  `test_restarting_resets_everything` : la munition vient maintenant de 1 000 points de
  style. Le second vérifie aussi que `ammo_progress` revient à 0.
- `test_the_debug_display_shows_the_flow` : la suite de moves devient glissade, saut,
  roulade, saut, pour rester à ×2. Les valeurs attendues deviennent GAUGE 2175 et REPEAT
  JUMP x2.
- `test_perfect_slides_do_not_raise_the_speed_without_end` : la jauge part du palier 2. Les
  moves répétés ne rapportent plus rien, donc sans cela le bonus du flow ne serait jamais
  testé.
- La ressource du projet et la ressource de test gagnent `flow_points_per_ammo = 1000` et
  `flow_repetition_window = 4`.

### Vérifié

- Avant le code : les 7 tests nouveaux ou réécrits étaient rouges sur leurs assertions,
  ainsi que les 3 tests adaptés.
- **Sabotages : 33 sur 33 détectés.** La liste d'avant a été remise à jour, et 6 nouveaux
  ont été ajoutés :
  - un move jugé seulement contre le précédent ;
  - un move à 0 qui prolonge le combo ;
  - plus de munitions par le style ;
  - une glissade tenue qui recompte ;
  - le reste d'une tranche perdu ;
  - un recommencement qui garde le reste.

  Chaque fichier a été restauré, md5 vérifié.
- **Les boucles de l'inspecteur**, rejouées avec ses scripts copiés dans `tests/` puis
  supprimés, jamais commités :

  | Boucle | Avant | Maintenant |
  | ------ | ----- | ---------- |
  | Jauge pleine, un saut toutes les 125 à 180 pas | 23 munitions/min | 0 à 1 munition/min (style de 725 à 1 200/min), la jauge reste au palier 2 |
  | Glissade tenue et saut martelé sur le plat | jauge pleine en 9,6 s, 23 munitions/min, 584 m | 1 glissade comptée, 190 sauts, jauge jamais pleine, 0 munition, style 125, 539 m (540 m en courant) |
  | Même boucle, saut pressé tous les 20, 30, 45 et 60 pas | jauge pleine en 3,2 s, 617 m | jamais pleine, 0 munition/min, de 513 à 538 m |
  | Saut et glissade parfaite enchaînés | jauge pleine en 2,2 s, 728 m | jamais pleine, 650 m (+20 % sur la course à pied) : c'est le skill accepté |
- `just preflight` : vert, 146 tests, 18,7 s et 18,8 s. Depuis la fusion de `main`, le
  gate rapide n'exécute plus les rejeux du parcours.
- `just check` sur l'arbre de `0d23669` : vert, code de sortie 0, 39,7 s. 180 tests sur
  180, structure à 0 problème (y compris la nouvelle vérification des rejeux du parcours),
  les deux builds exportés et le build Windows lancé.

### Non vérifié

- Je n'ai rien joué. **Ce que Jimmy doit juger** :
  - la règle des quatre derniers moves au toucher : un 0 % arrive vite quand on alterne
    deux moves ;
  - le « +0 » que le HUD affiche pour un move sans valeur ;
  - une glissade tenue qui ne compte plus ;
  - le rythme d'une munition pour 1 000 points de style.
- **Le HUD n'a pas changé** : les pastilles montrent toujours `ammo`.

### Écarts

1. **Un move à 0 % est quand même annoncé** au HUD (« JUMP +0 ») et compté dans
   `moves_counted`, mais il n'entre ni dans le combo ni dans les quatre derniers moves.
   « Sans valeur » veut dire qu'il rapporte 0 point.
2. **La longueur de la fenêtre** (4) est un réglage, `flow_repetition_window`, dans le groupe
   Flow, au nom de la règle « every tuning value … in one single tuning resource ». La spec
   écrit « quatre » sans en faire une ligne du tableau.
3. **`repeat_count` (affichage F3)** : nombre de fois que le move jugé est parmi les quatre
   derniers, lui compris. Il vaut 0 après la fin d'un combo.
4. **Les deux réglages de part** (`flow_second_time_share`, `flow_later_times_share`)
   gardent leur nom. Seul leur commentaire change : présent une fois, présent deux fois ou
   plus.
5. **Une glissade tenue sans nouvel appui** a lieu physiquement, mais elle n'est ni annoncée
   ni parfaite. Au départ et après un respawn, il faut un appui pour qu'une glissade compte.

### Questions

- **Une boucle reste ouverte.** C'est le constat 3 de l'inspecteur, qui n'est pas fermé en
  entier. Mesure : partant d'une jauge pleine, un saut toutes les 100 pas pendant 120 s
  garde la jauge à 2 927, au palier 2 (+10 %), sans aucun risque, pour 1 800 points de
  style.
  - Chaque combo s'ouvre par un saut à 50, le suivant vaut 25, puis le combo finit et
    tout recommence.
  - La jauge baisse quand même : le palier 3 se perd vite, mais pas le palier 2.
  - Est-ce acceptable, ou faut-il une règle de plus ? Par exemple, un saut seul ne relance
    pas la jauge. C'est à trancher par Jimmy.

`````

### Inspecteur, flow, première inspection

`````markdown
# Inspection : branche `flow-combo` (8eb4ead..f06b281), spec `docs/specs/flow-combo.md`

## 1. Verdict : **Conforme**

Aucun constat bloquant. Les quatre gates passent sur la branche, lancées par moi : `just typecheck` (47 scripts, 0 erreur), `just lint`, `just test` (173/173, 3 728 assertions), `just deadcode` (0 problème). Deux `just preflight` complets : 29,1 s et 29,0 s, donc sous la limite de 30 s de la décision 14, mais avec moins d'une seconde de marge. Les 4 tests de `test_course_flow` prennent 1,2 s.

Décision 12 : respectée. `RunnerEvent` (`game/core/runner_event.gd`) porte le move et le pas fixe. `FlowState` ne lit que les messages, la vitesse et le contact au sol du moteur, plus les ordres `respawn`/`restart`/`finish`. Il ne référence que `RunnerEvent`, `RunnerMotor` et `MovementTuning`. Aucune classe de `core` ne connaît `player`, une scène ou une entrée. Le bonus revient au moteur par `FlowState.follow` → `motor.top_speed_bonus`.

Changements de comportement du moteur : il y en a exactement deux, et la spec demande les deux.
- La glissade parfaite (décision 9) : `runner_motor.gd:301-310`.
- Le bonus de `top_speed` (décision 8) : `runner_motor.gd:123-124, 508`. Il n'agit que dans `_steer`, et le plafond absolu (`_cap_horizontal_speed`) reste inchangé.

Le reste du diff du moteur ne change aucun comportement : compteur `steps`, `events`, `_announce`, `_steps_since_landing`, et `reset()` qui vide les messages.

Les 22 valeurs du tableau « Valeurs de départ » sont toutes dans `movement_tuning.gd`, groupe « Flow », et dans `.tres`, avec les bonnes valeurs. Les libellés du contrat d'interface sont tous exacts : JUMP, SLIDE, PERFECT SLIDE, ROLL, MANTLE, WALL RUN, WALL JUMP suivis de « +n », « xn », « FLOW n », « COMBO BROKEN », « STYLE n », « BEST STYLE n ». Ils sont en anglais et vivent dans `game/ui/`.

**La liste des 22 choix du développeur ne m'a pas été transmise.** J'ai relevé dans le code les choix là où la spec se tait. Aucun ne contredit la spec. Un seul (constat 2) affaiblit le dilemme, et je le signale. Les constats 3 et 4 visent la spec elle-même : ce sont des questions pour Jimmy, pas des écarts du développeur.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | conseillé | `game/levels/course.gd:71-74` | Scénario « À l'arrivée, le flow se fige » (« Quand il franchit la ligne d'arrivée ») | Aucun test ne fait passer la ligne d'arrivée et ne vérifie que le flow se fige. J'ai remplacé `flow.finish()` par `pass` sur une copie hors dépôt : les 173 tests restent verts. Les tests de `core` et du HUD appellent `flow.finish()` directement. | Dans `test_course_flow.gd`, une assertion `flow.frozen` et `best_style_score` après une vraie arrivée. Un rejeu de la section finale suffit, ou un appel au signal `crossed` de la ligne d'arrivée. |
| 2 | conseillé | `game/core/flow_state.gd:56-57` vs `:222-224` | Dilemme de la spec (« jouer stylé pour recharger, ou jouer sûr pour avancer ») ; décisions 3, 4 et 5 | Choix du développeur sur un point où la spec se tait : quand le combo finit proprement après le délai, la répétition est gardée. Une erreur, elle, la remet à zéro (décision 5). Or un arrêt d'1 s n'a pas d'autre coût et finit le combo plus vite qu'une fin propre (2 s). S'arrêter exprès remet donc la répétition à zéro : l'erreur paie mieux que de bien jouer. | Remettre aussi `repeat_count` à 0 quand le combo finit par le délai (ligne 57), ou faire trancher Jimmy. |
| 3 | conseillé (question de spec) | `game/core/runner_motor.gd:301-310` | Dilemme de la spec ; décisions 3, 8 et 9 | Le gain de la glissade parfaite se cumule d'un saut à l'autre jusqu'au plafond absolu. Mesure sur une copie, sans physique, réglage fixe des tests, sol plat : petits sauts relâchés avec la glissade pressée dans la fenêtre avant chaque réception. Le coureur passe de 9 à 22 m/s (2,4 fois `top_speed`) en 3 s, la jauge à 3 000 et 3 munitions en 3 s. Saut et glissade parfaite alternés ne se répètent jamais, donc la garde contre la répétition (décision 3) ne joue pas. Les 15 % du palier 3 deviennent négligeables. C'est la lettre de la décision 9, mais « jouer sûr pour avancer » n'a plus de sens si le jeu stylé est aussi le plus rapide. | Faire trancher Jimmy, manette en main : soit un gain non cumulable, plafonné à `top_speed()` plus le gain, soit le laisser. Le cas échéant, la décision passe dans la spec avant toute ligne de code. |
| 4 | conseillé (question de spec) | `game/core/flow_state.gd:197-204` | Décision 8 ; dilemme | Selon la lettre de la décision 8, chaque passage d'un palier en montant donne une munition, y compris après une redescente. Une jauge pleine ne donne donc plus rien à qui joue parfaitement. En revanche, une réception dure (−1 palier) suivie d'une remontée, ou une pause de 2 s puis un move, redonne une munition. À l'étape 3, l'erreur et l'attente rechargeront mieux que le style. | Question pour Jimmy avant l'étape 3, par exemple « une munition par palier atteint pour la première fois depuis la dernière munition dépensée ». Rien à changer dans cette branche. |
| 5 | conseillé | `game/core/flow_state.gd:68` | Décision 5 (arrêt : « une vitesse horizontale sous 1 m/s ») ; décision 12 | L'arrêt et le seuil du saut lisent `motor.horizontal_speed()`, c'est-à-dire la vitesse voulue après accélération, pas la vitesse observée du corps. Un coureur qui pousse contre un mur « vaut » `ground_acceleration × pas` = 0,5 m/s. Avec les réglages actuels, il est bien vu arrêté. Si Jimmy règle `ground_acceleration` à 60 m/s² ou plus, il ne le sera plus jamais. | Passer à `step` la vitesse observée (`facts.velocity` ou la vitesse du corps après `move_and_slide`), ou noter ce lien dans le commentaire de `flow_stop_speed`. |
| 6 | conseillé | `game/ui/flow_hud.gd:23-24` | Décision 13 (« Toutes les valeurs de cette spec vivent dans la ressource de réglage unique ») | La durée du texte, « environ 1 s » dans le contrat d'interface, et celle du flash (0,4 s, absente de la spec) sont écrites en constantes dans le code. F4 ne les recharge pas. Ce sont des valeurs de présentation : la règle s'applique peut-être, je n'en suis pas sûr. | Les déplacer dans le groupe « Flow » de `MovementTuning`, ou faire confirmer par Jimmy qu'elles restent dans le HUD. |
| 7 | conseillé | `AGENTS.md:136, 141` | `AGENTS.md`, « Layout » (fichier des propriétaires) | La description de `core/` ne mentionne ni l'état du flow ni les messages du moteur. Celle de `ui/` dit encore « timer display and debug display », sans le HUD du flow. | Les propriétaires mettent la section « Layout » à jour dans un commit dédié. |

## 3. Couverture de la spec

Les 38 scénarios ont chacun leur test, sous le même nom. Aucun test n'est sans scénario, sauf les tests existants du HUD et du debug. Aucun test n'est sauté, supprimé ou affaibli.

| Scénario | Test |
| -------- | ---- |
| Chaque move commencé rapporte ses points | `test_runner_flow.gd::test_every_move_started_earns_its_points` |
| Un saut sans élan ne compte pas | `test_runner_flow.gd::test_a_jump_without_run_up_does_not_count` |
| Un wall-jump ne compte pas aussi comme un saut | `test_runner_flow.gd::test_a_wall_jump_does_not_also_count_as_a_jump` |
| Le même move répété d'affilée vaut de moins en moins | `test_flow.gd::test_the_same_move_repeated_in_a_row_is_worth_less_and_less` |
| Un autre move remet la répétition à zéro | `test_flow.gd::test_another_move_resets_the_repetition` |
| Un move répété sans valeur prolonge quand même le combo | `test_flow.gd::test_a_repeated_move_worth_nothing_still_extends_the_combo` |
| Le multiplicateur monte tous les quatre moves | `test_flow.gd::test_the_multiplier_rises_every_four_moves` |
| Le multiplicateur ne dépasse pas son maximum | `test_flow.gd::test_the_multiplier_does_not_go_above_its_maximum` |
| Le combo se termine sans pénalité après le délai au sol | `test_flow.gd::test_the_combo_ends_without_penalty_after_the_delay_on_the_ground` |
| Le délai ne s'écoule pas en l'air | `test_runner_flow.gd::test_the_delay_does_not_run_in_the_air` (chute de plus de 120 pas, la poussée change à chaque pas) |
| Une réception dure casse le combo et coûte un palier | `test_runner_flow.gd::test_a_hard_landing_breaks_the_combo_and_costs_a_tier` |
| Une réception dure ne fait pas passer la jauge sous zéro | `test_flow.gd::test_a_hard_landing_does_not_take_the_gauge_below_zero` |
| S'arrêter casse le combo | `test_flow.gd::test_stopping_breaks_the_combo` (bornes : à la vitesse d'arrêt, et lent en l'air) |
| Une chute hors du parcours vide la jauge et garde le reste | `test_flow.gd::test_a_fall_off_the_course_empties_the_gauge_and_keeps_the_rest` (dans `core` seulement ; dans la course, la chute et la demande passent par le même ordre `RESPAWN`, que couvre le test suivant) |
| Le retour au checkpoint demandé vide la jauge | `test_course_flow.gd::test_returning_to_the_checkpoint_on_request_empties_the_gauge` |
| Recommencer remet tout à zéro | `test_course_flow.gd::test_restarting_resets_everything` |
| La jauge ne baisse pas pendant un combo | `test_flow.gd::test_the_gauge_does_not_drop_during_a_combo` (sol et air alternés, vitesse variable) |
| La jauge baisse lentement hors combo | `test_flow.gd::test_the_gauge_drops_slowly_out_of_a_combo` |
| La jauge ne dépasse pas son maximum | `test_flow.gd::test_the_gauge_does_not_go_above_its_maximum` |
| Chaque palier augmente la vitesse de pointe | `test_runner_flow.gd::test_every_tier_raises_the_top_speed` |
| Le bonus de vitesse suit la jauge en descendant | `test_flow.gd::test_the_speed_bonus_follows_the_gauge_down` |
| Franchir un palier en montant donne une munition | `test_flow.gd::test_crossing_a_tier_upwards_gives_ammunition` |
| Les munitions ne dépassent pas leur maximum | `test_flow.gd::test_ammunition_does_not_go_above_its_maximum` |
| Une glissade commencée juste à l'atterrissage est parfaite | `test_runner_perfect_slide.gd::test_a_slide_started_right_at_the_landing_is_perfect` (bornes à 9 et 10 pas) |
| Une glissade commencée juste après l'atterrissage est parfaite | `test_runner_perfect_slide.gd::test_a_slide_started_right_after_the_landing_is_perfect` (bornes à 9 et 10 pas) |
| Une glissade hors de la fenêtre est une glissade simple | `test_runner_perfect_slide.gd::test_a_slide_out_of_the_window_is_a_plain_slide` |
| Le gain de la glissade parfaite respecte le plafond absolu | `test_runner_perfect_slide.gd::test_the_gain_of_a_perfect_slide_respects_the_absolute_cap` |
| Une grande chute donne une roulade, pas une glissade parfaite | `test_runner_perfect_slide.gd::test_a_big_fall_gives_a_roll_not_a_perfect_slide` |
| À l'arrivée, le flow se fige | `test_flow.gd::test_at_the_finish_the_flow_freezes` (règle de `core` couverte ; le passage de la ligne ne l'est pas, voir constat 1) |
| Le meilleur score de style de la session est gardé | `test_flow.gd::test_the_best_style_score_of_the_session_is_kept` |
| Le parcours rapporte du flow | `test_course_flow.gd::test_the_course_earns_flow` |
| Le parcours reste faisable à pleine vitesse | `test_course_flow.gd::test_the_course_stays_clearable_at_full_speed` |
| Le HUD montre le move et ses points | `test_flow_hud.gd::test_the_hud_shows_the_move_and_its_points` |
| Le HUD signale un palier franchi | `test_flow_hud.gd::test_the_hud_signals_a_tier_crossed` |
| Le HUD signale un combo cassé | `test_flow_hud.gd::test_the_hud_signals_a_broken_combo` |
| Le HUD montre les munitions | `test_flow_hud.gd::test_the_hud_shows_the_ammunition` |
| L'arrivée montre le score de style | `test_race_hud.gd::test_the_finish_shows_the_style_score` |
| L'affichage de debug montre le flow | `test_debug_overlay.gd::test_the_debug_display_shows_the_flow` |

Pour les règles du type « ne change pas pendant X », l'entrée varie bien pendant X dans trois tests :
- jauge pendant un combo : sol et air, vitesse en sinus ;
- délai en l'air : direction tournante ;
- arrivée : moves, réception dure, 20 s d'arrêt et retour au checkpoint après `finish`.

La suspension du délai en wall-run, en mantle, en glissade et en roulade (décision 4) n'a pas de scénario propre. Le code la couvre par `is_on_foot()`, `runner_motor.gd:134-135`.

## 4. Non vérifiable ici (à juger manette en main)

- **La boucle saut et glissade parfaite (constat 3)** : est-ce le skill voulu ou une faille ? Il faut essayer de l'enchaîner au clavier et à la manette. Il faut aussi voir si le parcours reste lisible quand le coureur approche 22 m/s : le test de la décision 14 ne rejoue les sections qu'à +15 %, pas au plafond absolu.
- **La fenêtre de 0,15 s de la glissade parfaite**, avant et après la réception : trop large ou trop serrée ? Le gain de 2 m/s se sent-il ?
- **Les « atterrissages » parasites** : après une marche descendue ou une crête de rampe, une glissade peut-elle devenir parfaite sans saut ? Le moteur compte tout passage de l'air au sol comme un atterrissage.
- **Le bonus de 5, 10 et 15 %** : se sent-il ? La redescente de palier (perte de vitesse en pleine course) est-elle désagréable ?
- **Le délai de 2 s au sol et la baisse de 100/s** : trop généreux ou trop punitifs ?
- **L'arrêt** (sous 1 m/s pendant 1 s) : se déclenche-t-il quand on hésite devant un obstacle ou qu'on bute contre un mur ?
- **Le HUD du flow** : lisibilité en bas au centre, taille de la jauge et des pastilles, texte du move qui s'efface après 1 s, flash du palier (0,4 s, éclaircissement), « COMBO BROKEN » à la place du texte du move. Absence de chevauchement avec l'affichage F3, agrandi à 400 px de haut.
- **L'arrivée** : STYLE et BEST STYLE sous le temps, lisibles.
- **Le rythme des points** : « +0 » s'affiche pour un move répété sans valeur. Est-ce voulu, ou faut-il ne rien afficher ?
- **just preflight à 29 s** : une machine chargée dépassera les 30 s, comme lors des rondes précédentes. Les propriétaires décident s'il faut agir avant la seconde spec de l'étape 2.

`````

### Inspecteur, flow, seconde inspection

`````markdown
# Inspection de `flow-combo` (8eb4ead..flow-combo), seconde inspection indépendante

Spec : `docs/specs/flow-combo.md` (amendée, avec ses « Choix acceptés à l'inspection »).
Types de tâche : `core`, `levels`, `ui`, `harness` (AGENTS.md, spec).
Gates lancés sur la branche : `just lint` (0 problème), `just deadcode` (0 problème, 53 fichiers),
`just typecheck` (47 scripts, 0 erreur), `just test` (178/178, 18 s).

## 1. Verdict

**À corriger.** Le code suit la lettre de la spec et chaque scénario a un test qui le prouve
(13 cassures volontaires, toutes attrapées sauf une hors scénario). Mais l'économie ne garde
pas le dilemme que la spec pose comme son objectif (Contexte : « Le dilemme du plan à
préserver : jouer stylé pour recharger, ou jouer sûr pour avancer ») : deux boucles sans
risque, mesurées dans la vraie physique du moteur avec les valeurs du `.tres`, donnent jauge,
vitesse et munitions. Aucun scénario ne les interdit et les décisions 3 et 8 les permettent
à la lettre : je les classe bloquantes à cause de cet objectif écrit. Je n'en suis pas
certain, car aucune règle d'`AGENTS.md` ni aucun scénario n'est enfreint. La correction
demande un amendement que Jimmy tranche, puis du code.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
|---|---------|---------------|-------|---------|-------------|
| 1 | bloquant (à trancher par l'owner) | `game/core/flow_state.gd:67-68` et `:213-217` | Spec, Contexte (« Le dilemme du plan à préserver ») ; décision 8 amendée (jauge pleine : une munition par palier de points) | Avec une jauge pleine, la baisse hors combo la fait passer à 2 999,8, et le move suivant refranchit le palier 3 : +1 munition pour 50 points. Mesure : un coureur sur le plat qui saute une fois toutes les 2,5 s gagne **23 munitions par minute** pour 24 sauts, sans aucune erreur possible, avec 1 200 points de style. La même chose arrive à chaque palier. | Ne donner une munition que pour un palier franchi au-dessus du plus haut palier atteint depuis la dernière erreur, chute ou relance (une marque haute) : la baisse ne réarme pas la récompense. Amendement de la décision 8, puis un scénario « La jauge qui redescend puis remonte ne redonne pas de munition ». |
| 2 | bloquant (à trancher par l'owner) | `game/core/flow_state.gd:165-169` et `game/core/runner_motor.gd:293-296` | Spec, Contexte (dilemme) ; décision 3, « Pourquoi » (« sauter sur place serait le meilleur jeu, et le dilemme disparaît ») | Garder la glissade et le saut enfoncés et presser le saut une fois par seconde, sur le plat, alterne JUMP et SLIDE, qui valent chacun tous leurs points (décision 3 : « un autre move remet le compte à zéro » ; choix accepté : une glissade bouton tenu compte). Résultat : ×4 permanent, **jauge pleine en 9,6 s, 23 munitions par minute, 584 m en 60 s contre 540 m en courant**, zéro erreur possible (une réception dure est impossible sur le plat). En pressant plus vite, la jauge est pleine en 3,2 s et le coureur fait 617 m. Jouer stylé est ici à la fois sans risque et plus rapide. | Plusieurs options pour Jimmy : une glissade ne compte qu'à un nouvel appui ; la répétition compte sur une fenêtre (les N derniers moves) et pas seulement sur le move précédent ; ou un saut, comme une glissade, ne compte qu'une fois par contact avec le sol. Amendement de la décision 3, et un scénario « Alterner saut et glissade sur le plat ne remplit pas la jauge sans fin ». |
| 3 | conseillé | `game/core/flow_state.gd:170-172` (scénario « Un move répété sans valeur prolonge quand même le combo », `tests/test_flow.gd:83`) | Décision 7, « Pourquoi » (« Jouer sûr fait redescendre, lentement ») | Un saut à 0 % garde le combo, donc la jauge ne baisse jamais. Mesure : partant d'une jauge pleine, un saut toutes les 1,67 s pendant 120 s laisse la jauge à 3 000, au palier 3 (+15 %), pour 75 points de style. Le joueur prudent garde le bonus de vitesse sans jouer stylé. | À trancher par Jimmy : un move à 0 % ne remet pas le délai à zéro, ou le délai ne repart qu'avec un move qui rapporte. |
| 4 | conseillé | `game/core/flow_state.gd:69-70` | `.agents/skills/index.md`, type `core` (« every rule of `core` has a headless test ») ; absent des « Choix acceptés » | Le report au-delà du plein est remis à zéro dès que la jauge n'est plus pleine. C'est une règle de l'économie que la spec ne dit pas, et aucun test ne la prouve : la cassure M5 (supprimer la remise à zéro) laisse passer les 23 tests de `test_flow*`. | L'ajouter aux « Choix acceptés » et la couvrir par une assertion dans `test_a_full_gauge_keeps_giving_ammunition_for_style`. |

Contrôles sans constat :

- Le moteur ne change que par la glissade parfaite (`_start_slide`) et le bonus de vitesse (`top_speed()` dans `_steer`, y compris le plafond de la réception dure). Le reste ne fait qu'annoncer des messages : `_announce`, `steps`, `real_speed`, `is_on_foot`, le compteur d'atterrissage.
- `core` ne connaît ni scène, ni entrée, ni `player` : `FlowState` ne lit que `RunnerMotor` et `RunnerEvent`, qui sont dans `core`.
- Toutes les valeurs de la spec sont dans le `.tres`, groupe « Flow ». F4 est suivi, car `course.gd` réaffecte `flow.tuning` à chaque pas.
- Les glissades parfaites restent bornées à la vitesse de pointe du moment plus 2 m/s (mesuré : 12,18 m/s pour une borne de 12,35).
- Les chutes et les réceptions dures volontaires ne rapportent rien de plus que le taux normal (1 munition pour 1 000 points).
- Un arrêt volontaire ne fait gagner ni points ni munitions.

## 3. Couverture de la spec

Les 43 scénarios ont chacun leur test du même nom, et tous passent. Cassures volontaires faites sur une copie : M1 (pas de remise à zéro de la répétition à la fin du délai), M2 (vitesse voulue au lieu de la vitesse réelle), M3 (glissade parfaite sans le plafond « vitesse de pointe + gain »), M4 (pas de munition au-delà du plein), M6 (l'arrivée ne fige pas le flow), M7 (multiplicateur compté après le move), M9 (bouton tenu donne une glissade parfaite), M10 (délai qui s'écoule en l'air), M11 (réception dure gratuite), M13 (retour au checkpoint sans vider la jauge), M14 (bonus jamais rendu au moteur) et M15 (pas de « COMBO BROKEN »). Chacune fait échouer le test de son scénario. Seule M5, hors scénario, passe (constat 4).

| Scénario | Test |
|----------|------|
| Chaque move commencé rapporte ses points | `tests/test_runner_flow.gd` `test_every_move_started_earns_its_points` |
| Un saut sans élan ne compte pas | `test_runner_flow.gd` `test_a_jump_without_run_up_does_not_count` |
| Un wall-jump ne compte pas aussi comme un saut | `test_runner_flow.gd` `test_a_wall_jump_does_not_also_count_as_a_jump` |
| Le même move répété d'affilée vaut de moins en moins | `test_flow.gd` `test_the_same_move_repeated_in_a_row_is_worth_less_and_less` |
| La fin d'un combo remet la répétition à zéro | `test_flow.gd` `test_the_end_of_a_combo_resets_the_repetition` |
| Un autre move remet la répétition à zéro | `test_flow.gd` `test_another_move_resets_the_repetition` |
| Un move répété sans valeur prolonge quand même le combo | `test_flow.gd` `test_a_repeated_move_worth_nothing_still_extends_the_combo` |
| Le multiplicateur monte tous les quatre moves | `test_flow.gd` `test_the_multiplier_rises_every_four_moves` |
| Le multiplicateur ne dépasse pas son maximum | `test_flow.gd` `test_the_multiplier_does_not_go_above_its_maximum` |
| Le combo se termine sans pénalité après le délai au sol | `test_flow.gd` `test_the_combo_ends_without_penalty_after_the_delay_on_the_ground` |
| Le délai ne s'écoule pas en l'air | `test_runner_flow.gd` `test_the_delay_does_not_run_in_the_air` |
| Une réception dure casse le combo et coûte un palier | `test_runner_flow.gd` `test_a_hard_landing_breaks_the_combo_and_costs_a_tier` |
| Une réception dure ne fait pas passer la jauge sous zéro | `test_flow.gd` `test_a_hard_landing_does_not_take_the_gauge_below_zero` |
| S'arrêter casse le combo | `test_flow.gd` `test_stopping_breaks_the_combo` |
| Une chute hors du parcours vide la jauge et garde le reste | `test_flow.gd` `test_a_fall_off_the_course_empties_the_gauge_and_keeps_the_rest` (au niveau de `core` ; la course câble la chute et la demande sur le même ordre `RESPAWN`) |
| Le retour au checkpoint demandé vide la jauge | `test_course_flow.gd` `test_returning_to_the_checkpoint_on_request_empties_the_gauge` |
| Recommencer remet tout à zéro | `test_course_flow.gd` `test_restarting_resets_everything` |
| La jauge ne baisse pas pendant un combo | `test_flow.gd` `test_the_gauge_does_not_drop_during_a_combo` |
| La jauge baisse lentement hors combo | `test_flow.gd` `test_the_gauge_drops_slowly_out_of_a_combo` |
| La jauge ne dépasse pas son maximum | `test_flow.gd` `test_the_gauge_does_not_go_above_its_maximum` |
| Chaque palier augmente la vitesse de pointe | `test_runner_flow.gd` `test_every_tier_raises_the_top_speed` |
| Le bonus de vitesse suit la jauge en descendant | `test_flow.gd` `test_the_speed_bonus_follows_the_gauge_down` |
| Franchir un palier en montant donne une munition | `test_flow.gd` `test_crossing_a_tier_upwards_gives_ammunition` |
| Une jauge pleine continue de donner des munitions par le style | `test_flow.gd` `test_a_full_gauge_keeps_giving_ammunition_for_style` |
| Les munitions ne dépassent pas leur maximum | `test_flow.gd` `test_ammunition_does_not_go_above_its_maximum` |
| Une glissade commencée juste à l'atterrissage est parfaite | `test_runner_perfect_slide.gd` `test_a_slide_started_right_at_the_landing_is_perfect` |
| Une glissade commencée juste après l'atterrissage est parfaite | `test_runner_perfect_slide.gd` `test_a_slide_started_right_after_the_landing_is_perfect` |
| Les glissades parfaites ne font pas monter la vitesse sans fin | `test_runner_perfect_slide.gd` `test_perfect_slides_do_not_raise_the_speed_without_end` |
| Une glissade hors de la fenêtre est une glissade simple | `test_runner_perfect_slide.gd` `test_a_slide_out_of_the_window_is_a_plain_slide` |
| Le gain de la glissade parfaite respecte le plafond absolu | `test_runner_perfect_slide.gd` `test_the_gain_of_a_perfect_slide_respects_the_absolute_cap` |
| Une grande chute donne une roulade, pas une glissade parfaite | `test_runner_perfect_slide.gd` `test_a_big_fall_gives_a_roll_not_a_perfect_slide` |
| À l'arrivée, le flow se fige | `test_flow.gd` `test_at_the_finish_the_flow_freezes` |
| Le meilleur score de style de la session est gardé | `test_flow.gd` `test_the_best_style_score_of_the_session_is_kept` |
| Franchir la ligne d'arrivée fige le flow | `test_course_flow.gd` `test_crossing_the_finish_line_freezes_the_flow` |
| Un coureur qui pousse contre un mur est arrêté | `test_course_flow.gd` `test_a_runner_pushing_against_a_wall_is_stopped` |
| Le parcours rapporte du flow | `test_course_flow.gd` `test_the_course_earns_flow` |
| Le parcours reste faisable à pleine vitesse | `test_course_flow.gd` `test_the_course_stays_clearable_at_full_speed` |
| Le HUD montre le move et ses points | `test_flow_hud.gd` `test_the_hud_shows_the_move_and_its_points` |
| Le HUD signale un palier franchi | `test_flow_hud.gd` `test_the_hud_signals_a_tier_crossed` (le flash de la jauge n'est pas vérifié) |
| Le HUD signale un combo cassé | `test_flow_hud.gd` `test_the_hud_signals_a_broken_combo` |
| Le HUD montre les munitions | `test_flow_hud.gd` `test_the_hud_shows_the_ammunition` |
| L'arrivée montre le score de style | `test_race_hud.gd` `test_the_finish_shows_the_style_score` |
| L'affichage de debug montre le flow | `test_debug_overlay.gd` `test_the_debug_display_shows_the_flow` |

## 4. Non vérifiable ici (à juger manette en main)

- **Les deux boucles des constats 1 et 2** : sentir si « glissade tenue + saut » sur le plat ressemble à un exploit, et si farmer des munitions en sautant toutes les 2,5 s se remarque en jouant.
- **La glissade parfaite** : la fenêtre de 0,15 s autour de l'atterrissage, au clavier comme à la manette. Le gain de 2 m/s se sent-il ? La chaîne saut + glissade parfaite sur le plat est mesurée à 728 m en 60 s contre 540 m en courant, avec une jauge pleine en 2,2 s. Est-ce le skill voulu ou trop facile ? Selon le choix accepté, le pilote ne fait pas de glissade parfaite : vérifier en jouant que le gain ne fait pas rater une réception du parcours.
- **Le bonus de vitesse** de +5, +10 et +15 % : se sent-il palier par palier ? La caméra suit-elle ? Les passages précis (sauts longs, zigzag) restent-ils maîtrisables à +15 % joués à la main, et pas seulement par le pilote ?
- **Le délai de 2 s au sol** et **l'arrêt** (sous 1 m/s pendant 1 s) : le combo casse-t-il quand on s'arrête pour viser un saut, ou contre un rebord ?
- **Le HUD** : la position de la jauge en bas au centre, la lisibilité des trois marques, le flash de 0,4 s, le texte d'environ 1 s quand les moves s'enchaînent vite, les pastilles pleines et vides. « COMBO BROKEN » s'affiche aussi lors d'une chute ou d'un retour au checkpoint en plein combo : est-ce voulu ?
- **L'arrivée** : « STYLE » et « BEST STYLE » sous le temps, leur lisibilité.
- **F4** : recharger les valeurs du flow en jouant.

Expériences (copie hors dépôt, rien n'a été modifié dans le worktree) :
- `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-flow-combo-2\copy\tests\test_zz_exploit.gd`
- `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-flow-combo-2\copy\tests\test_zz_rhythm.gd`
- cassures : `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-flow-combo-2\tools\run_mut.sh`

`````

### Développeur, paliers de tests

`````markdown
# test-tiers : rapport du développeur

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a169071927234c646`
Branche : `test-tiers` (depuis `main` à `6d25727`), quatre commits, rien de poussé :

- `b8eda89` gate: two test tiers, course replays out of preflight : `justfile`, `tools/run_tests.py`, `tools/check_structure.py`, `tools/repo.py`
- `e60420b` AGENTS.md: the two test tiers in Commands : la section « Commands » seule
- `857d36b` specs: earlier time limits read with the test tiers : les notes de la décision 7
- `a012c07` spec: test-tiers implemented : la ligne de statut, rien d'autre

## Mécanisme choisi

GUT 9.7.1 (code lu dans `addons/gut/cli/gut_cli.gd`, `gut_config.gd`, `gut.gd`, `cli/optparse.gd`) peut **sélectionner** des scripts mais pas en **exclure** :

- `-gselect` : sous-chaîne cherchée dans le chemin ;
- `-gprefix` : préfixe du nom de fichier ;
- `-gtest` : liste de chemins ;
- `-ginner_class` et `-gunit_test_name` : filtres d'inclusion.

Il n'existe aucune option d'exclusion. Donc :

- **Les deux paliers.** `tools/run_tests.py --edit-loop` et `--course` établissent eux-mêmes la liste des scripts de `tests/` : préfixe `test_`, suffixe `.gd`, sous-dossiers compris, comme `.gutconfig.json`. Ils la coupent sur le préfixe `test_course` et la passent à GUT avec `-gdir= -gtest=<liste>`. Le `-gdir=` vide remplace les dossiers de `.gutconfig.json`, ce qui est vérifié : 16 scripts lancés, pas 19. Un palier vide échoue avant même de lancer Godot. La vérification du résumé « All tests passed! » reste en place.
- **La découpe.** Les préfixes vivent à un seul endroit, `tools/repo.py` (`TEST_PREFIX`, `COURSE_REPLAY_PREFIX`, `is_test_script`, `is_course_replay`). `run_tests.py` et `check_structure.py` les partagent.
- **`justfile`.**
  - `test-course` : nouvelle commande, publique.
  - `_test-edit-loop` : cachée de `just --list` par le `_`.
  - `preflight: typecheck lint _test-edit-loop deadcode`.
  - `check: typecheck lint test deadcode build`.

  `check` garde exactement l'étape `test` d'aujourd'hui : un seul lancement de GUT, sans filtre, avec sa propre découverte. Les lignes des recettes n'ajoutent que `--course` ou `--edit-loop`, ce qui passe tel quel sous cmd.exe et sh.
- **`just deadcode`.** Une nouvelle section « course replays » refuse tout script de test qui atteint une scène de `game/levels/` sans le préfixe `test_course`. Elle cherche une référence directe ou une chaîne passant par les fichiers de `tests/`, par exemple `CourseTest`. Le message donne la ligne et la chaîne, par exemple `class CourseTest -> res://game/levels/test_course.tscn`.

## Fait

Ces scénarios portent sur les commandes elles-mêmes : aucun test GUT ne peut les porter, et le dépôt n'a pas de place pour des tests des outils Python (voir **Écarts**). Comme la spec le permet, chacun est prouvé par une démonstration : commande, sortie, code de retour. Le côté rouge a été montré avant d'implémenter.

1. **La boucle rapide ne lance pas les rejeux du parcours** (`the_edit_loop_does_not_run_the_course_replays`)
   - `just preflight` liste et lance 16 scripts, aucun `test_course*` : 107 tests sur 107.
   - Avec une assertion de `tests/test_course_walls.gd` cassée exprès, `just preflight` sort à rc=0, 16 scripts.
2. **La porte du commit lance tous les tests** (`the_commit_gate_runs_every_test`)
   - `just check` donne `Scripts 19`, `Tests 135`, `Passing Tests 135`.
   - Avant le changement, `just preflight` donnait 19 scripts et 135 tests.
   - Les deux paliers font 16 + 3 = 19 scripts et 107 + 28 = 135 tests.
3. **Un rejeu du parcours qui échoue fait échouer la porte du commit** (`a_failing_course_replay_fails_the_commit_gate`)
   - Cassure exprès : `assert_gt(attempt.run.steps_mantling, 0, …)` remplacé par `assert_eq(…, 0, …)` dans `tests/test_course_walls.gd`.
   - `just check` sort à rc=1 : `[Failed]: [20] expected to equal [0]: the runner mantled`, `Failing Tests 1`, `error: recipe test failed`.
   - Assertion remise ensuite, arbre propre (`git status` vide).
4. **Les rejeux se lancent seuls** (`the_course_replays_run_alone`)
   - Avant : `just test-course` répondait `justfile does not contain recipe test-course`.
   - Après : 3 scripts (`test_course`, `test_course_ground`, `test_course_walls`), 28 tests sur 28, rc=0, 14,9 s.
5. **Un rejeu du parcours mal nommé est refusé** (`a_misnamed_course_replay_is_refused`)
   - Deux scripts posés exprès dans `tests/` : `test_misnamed_replay.gd` (`extends CourseTest`) et `test_misnamed_direct.gd` (`load("res://game/levels/test_course.tscn")`).
   - Avant le changement, `check_structure.py` les laissait passer (rc=0).
   - Après, les deux sont signalés et `just deadcode` sort à rc=1.
   - Les deux scripts ont été retirés ensuite.
6. **Un palier sans test échoue** (`a_tier_without_tests_fails`)
   - `tests/test_course*.gd` déplacés un moment hors du dépôt : `just test-course` répond `test: the course replays, 0 script(s)` puis `test: no test script in this tier`, rc=1.
   - Même chose pour l'autre palier, avec les 16 autres scripts déplacés : `just _test-edit-loop` sort à rc=1.
   - Tout a été remis, `git status` vide.
   - Le sens de `just test <filtre>` ne change pas : `just test race_state` lance 1 script, rc=0 ; `just test no_such_script` sort à rc=1.

Les deux autres livrables :

- **`AGENTS.md`**, section « Commands » seule : les deux paliers, `just test-course`, la règle de nommage que `just deadcode` vérifie, les deux limites de temps, et le fait qu'un palier vide échoue.
- **Décision 7** : une note datée dans la cellule de chaque décision « sous 30 s ». Elle est dans `docs/specs/reactive-replays.md` (décision 10), `docs/specs/movement-ground.md` (décision 20) et `docs/specs/movement-walls.md` (décision 20), et renvoie aux décisions 1 et 3 de `test-tiers.md`.

## Vérifié

Tout a été lancé ici, sous Windows (Git Bash, recettes sous cmd.exe), just 1.58.0, Godot 4.7.2.

- `just setup` : rc=0 (19,8 s).
- **Avant le changement**, `just preflight` : vert, 19 scripts, 135 tests, **27,5 s**.
- `just test-course` : vert, 3 scripts, 28 tests, 14,9 s.
- `just test race_state` : vert. `just test no_such_script` : rouge, comme prévu.
- `just deadcode` avec un rejeu mal nommé : rouge, comme prévu. Sans lui : vert, 0 problème dans les quatre sections.
- Cassure exprès d'un rejeu du parcours : `just preflight` vert, `just check` rouge à l'étape `test`.

Sur le dernier commit de code, `857d36b` (le commit de statut ne touche qu'une ligne de la spec) :

| Commande | Résultat | Durée |
| --- | --- | --- |
| `just preflight` | vert : typecheck 39 scripts, lint propre, 16 scripts et 107 tests, structure 0 problème | **16,9 s** (17,2 s au premier passage), limite 30 s |
| `just check` | vert : typecheck 39 scripts, lint propre, 19 scripts et 135 tests, structure 0 problème, exports Windows (lancé 60 images sans écran) et Linux | **42,0 s** (35,0 s au premier passage), limite 90 s |

## Non vérifié

- **sh et la CI Linux.** Les recettes n'ont tourné que sous cmd.exe. Elles n'ajoutent que `--course` et `--edit-loop`, et les arguments de GUT (`-gdir=`, `-gtest=…`) passent par une liste `subprocess`, pas par un shell. Je ne l'ai pas lancé sous sh : la CI de la pull request le dira.
- **Les temps sur la machine de Jimmy au repos.** Mes mesures viennent de cette machine, à ce moment-là : `just check` a varié de 35 à 42 s d'un lancement à l'autre.
- **`tests/test_course_flow.gd` de la branche `flow-combo`.** Il tombera dans le palier des rejeux par son nom, mais il est absent ici, donc rien n'a été lancé avec lui.
- **Le jeu.** Aucun fichier de `game/` ne change. Il n'y a rien à juger manette en main.

## Écarts

1. **Pas de tests nommés d'après les scénarios.** Ils portent sur les commandes. Pour les écrire en Python, il faudrait un lanceur de tests Python dans la porte, ce qui veut dire une nouvelle dépendance ou une nouvelle recette que la spec n'a pas décidée. J'ai donc pris l'autre voie que la spec ouvre : la démonstration dans ce rapport.
2. **`just check` n'est plus écrit `preflight build`, mais `typecheck lint test deadcode build`.** Il lance donc tous les tests en un seul passage de GUT, avec la découverte de GUT, et non l'union des deux paliers. C'est la garantie la plus forte que rien ne sort de `check` : son étape `test` est mot pour mot celle d'avant.
3. **La recette `_test-edit-loop` est cachée** : la spec ne décide qu'une seule nouvelle commande publique, `test-course`. Elle reste lançable à la main.
4. **J'ai lu « la scène du parcours » comme toute scène `.tscn` de `game/levels/`.** `AGENTS.md`, « Layout », dit « course scenes » : cette lecture couvre déjà les futures scènes du duel. La recherche ne suit que les fichiers de `tests/`, ce qui correspond à « directement ou par CourseTest », et ne passe pas par `game/`. Un test qui n'emploie que la classe `Course` sans charger la scène n'est pas signalé.
5. **La liste des paliers est établie en Python, pas par GUT.** C'est la même règle que `.gutconfig.json`. Une seule différence en théorie : GUT ignore les fichiers et dossiers cachés, Python ignore `SKIPPED_DIRS`. Elle est sans effet sur `tests/` aujourd'hui. J'aurais pu lancer le palier des rejeux avec `-gprefix=test_course`, que GUT sait faire, mais j'ai gardé une seule définition de la découpe pour les deux paliers.
6. **`AGENTS.md` dit « the owner's machine » là où la spec dit « la machine de Jimmy »**, pour suivre le ton du fichier. La règle de nommage y cite aussi « the bot », qui n'existe pas encore (spec `local-duel`), parce que la décision 4 le nomme.
7. **`README.md` n'est pas modifié**, car il est hors du périmètre autorisé. Sa ligne `just check  # before every commit: preflight and the release builds` reste à peu près vraie, mais elle ne dit pas que `check` lance les rejeux que `preflight` saute.

## Questions

1. **D'autres specs nomment encore la limite de 30 s.** La décision 7 ne vise que trois specs, mais `flow-combo` (décision 14), `local-duel` (décision 16), `sabotage` et `air-tricks` la citent aussi. Les mots de `local-duel` 16 (« les rejeux du parcours entier ne tournent que dans `just check` ») et de `flow-combo` 14 (« le développeur s'arrête ») se lisent désormais avec cette spec. Faut-il une note dans ces specs aussi ?
2. **`README.md`, lignes 46 et 47** : faut-il dire que `check` lance aussi les rejeux du parcours ? Le coordinateur y a répondu par le commit `3f35644`, que j'ai gardé tel quel.

## Suite de l'inspection : commit `28e66c7`

Point conseillé de l'inspection : un script mal nommé qui chargeait le parcours par `load(ProjectSettings.get_setting("application/run/main_scene"))` passait le contrôle de structure. C'est le même schéma que `tests/test_course.gd:42-45`.

**Corrigé dans `tools/check_structure.py`**
- `Project.settings_naming_files()` lit `project.godot` et retient chaque réglage dont la valeur nomme un fichier du projet, par chemin `res://` ou par uid. Il les range sous le nom complet que lit `ProjectSettings.get_setting()`. Aujourd'hui, un seul réglage est concerné : `application/run/main_scene`, qui pointe vers `game/levels/test_course.tscn`. Aucun chemin n'est écrit en dur.
- `Project.setting_references()` : une chaîne littérale d'un script égale à l'un de ces noms compte comme une référence au fichier nommé.
- `course_scene_loaded_by` est la seule fonction qui ajoute ces références. Les contrôles des frontières et des fichiers morts ne changent pas.

**Rouge d'abord**
- J'ai posé `tests/test_misnamed_main.gd`, qui charge la scène par le réglage. Avant la correction : `structure: course replays: 0 problem(s)`, rc=0.
- Après la correction, `just deadcode` sort à rc=1 et signale ces quatre scripts :
  - `tests/test_misnamed_main.gd:5`, par `setting "application/run/main_scene"` ;
  - `tests/test_misnamed_preload.gd:3`, par un `preload` de la scène ;
  - `tests/test_misnamed_replay.gd:1`, par `extends CourseTest`, chaîne `class CourseTest -> res://game/levels/test_course.tscn` ;
  - `tests/misnamed/test_misnamed_sub.gd:1`, par `extends "res://tests/course_test.gd"` dans un sous-dossier, chaîne `res://tests/course_test.gd -> res://game/levels/test_course.tscn`.
- Les quatre fichiers et le sous-dossier sont retirés ; `git status` ne montrait plus que l'outil.

**Vérifié** : `just check` est vert sur `28e66c7`, en **36,6 s**.
- typecheck : 39 scripts, 0 erreur ; lint propre ;
- tests : 19 scripts, 135 tests sur 135 ;
- structure : 0 problème dans les quatre sections ;
- exports Windows (le jeu exporté a tourné 60 images sans écran) et Linux.

Ni `docs/specs/` ni le commit `3f35644` n'ont été touchés.

`````

### Inspecteur, paliers de tests

`````markdown
# Inspection : branche `test-tiers` (`6d25727..3f35644`) contre `docs/specs/test-tiers.md`

Types de tâche routés : `tooling` (justfile, tools/), `harness` (AGENTS.md, README.md, docs/specs/). Pas de code de jeu touché.

## 1. Verdict

**Conforme** (aucun constat bloquant ; deux constats conseillés).

Réponse à la question clé : oui. `just check` = `typecheck lint test deadcode build` ; `test` sans argument laisse GUT découvrir les scripts avec `.gutconfig.json`, exactement comme avant (19 scripts, 135 tests, identiques à `main`). Un rejeu du parcours qui échoue fait échouer `just check` (démontré ci-dessous) ; aucun test n'est retiré, sauté ni affaibli (aucun fichier de `tests/` dans le diff).

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | conseillé | tools/check_structure.py:334 | Spec, décision 4 ; AGENTS.md, « Commands » (« `just deadcode` refuses one that does not ») | Un script `tests/test_misnamed_main.gd` qui charge le parcours par `load(ProjectSettings.get_setting("application/run/main_scene"))` (le motif même de `tests/test_course.gd:42-45`) passe la structure sans problème : le rejeu mal nommé entre dans `just preflight` sans que la porte le voie. | Dans `course_scene_loaded_by`, traiter la chaîne littérale `application/run/main_scene` comme une référence à la scène que `project.godot` y déclare ; à défaut, écrire cette limite dans la phrase d'AGENTS.md. |
| 2 | conseillé | docs/specs/flow-combo.md:57, docs/specs/local-duel.md:51 | Spec, décision 7 (« une note dans chacune renvoie à cette spec ») | Deux specs antérieures portent aussi une décision sur les 30 s de `just preflight` (flow-combo d14 : « le développeur s'arrête » ; local-duel d16 : un autre mécanisme pour sortir les rejeux, que cette spec remplace) et n'ont pas reçu de note ; je ne suis pas sûr que la décision 7 vise aussi les specs encore 🟡 (le Contexte n'en cite que trois). | Ajouter la même note à flow-combo d14 et local-duel d16 (attention : flow-combo est en cours sur une autre branche, risque de conflit), ou faire confirmer le périmètre par l'owner. |

## 3. Couverture de la spec

Pas de test du même nom : la spec autorise pour ces scénarios « une démonstration dans le rapport du développeur » et le dépôt n'a pas de tests des outils Python. Je n'ai pas vu la démonstration du développeur (seul le message de a012c07 cite « just check green on 857d36b: 19 test scripts, 135 tests ») ; voici la mienne, faite sur une copie hors dépôt (`scratchpad/copy`), le dépôt non modifié :

| Scénario | Preuve |
| -------- | ------ |
| La boucle rapide ne lance pas les rejeux du parcours | `just _test-edit-loop` (recette de `preflight`) : 16 scripts listés, aucun `test_course*`, 107 tests, exit 0. 16 + 3 = 19 : tous les autres tournent. |
| La porte du commit lance tous les tests | `just check` sur la copie propre : 19 scripts, 135 tests, builds Windows et Linux, exit 0, 34 s. `just --dry-run check` montre `run_tests.py godot_console` sans filtre. |
| Un rejeu du parcours qui échoue fait échouer la porte du commit | Test `test_planted_failure` (`assert_true(false)`) ajouté à `tests/test_course_walls.gd` de la copie : `just check` exit 1 (« 1 failing tests », « recipe `test` failed »), build non lancé ; `just preflight` reste à 0 (attendu). |
| Les rejeux se lancent seuls | `just test-course` : 3 scripts (`test_course`, `_ground`, `_walls`), 28 tests, exit 0, 16 s. |
| Un rejeu du parcours mal nommé est refusé | Copie : `test_misnamed_direct.gd` (preload direct), `test_misnamed_helper.gd` (`extends CourseTest`), `tests/sub/test_misnamed_sub.gd` (`extends "res://tests/course_test.gd"`) : les trois signalés, exit 1. Échappe : le chargement par le réglage `main_scene` (constat 1). |
| Un palier sans test échoue | `--course` sans aucun `test_course*` : « no test script in this tier », exit 1 sans lancer Godot. `--course` avec un seul `test_course_empty.gd` sans test : GUT « Nothing was run », exit 1. Filtre `zzznomatch` : exit 1. |

Autres vérifications demandées :
- `-gdir=` : dans GUT 9.7.1 (`addons/gut/cli/optparse.gd:83-85`, `gut_cli.gd:170`), il donne une liste vide qui remplace les `dirs` du `.gutconfig.json` (priorité ligne de commande) ; confirmé par l'exécution : seuls les scripts listés tournent.
- cmd.exe et sh : les nouvelles lignes ne contiennent que `{{ python }} tools/run_tests.py {{ godot }} --course|--edit-loop`, sans syntaxe propre à un shell ; vérifiées sous cmd.exe (Windows). La CI (`.github/workflows/check.yml`) lance toujours `just check` sur ubuntu-24.04, inchangée.
- Table « Commands » d'AGENTS.md : exacte pour chaque commande (`check` = typecheck + lint + tous les tests + deadcode + build ; `preflight` sans les rejeux ; `test-course` ; `deadcode` avec les noms de rejeux ; un palier échoue sans test). Seule réserve : « refuses one that does not » sur-promet (constat 1). README (3f35644) exact.
- Commits : porte (b8eda89) et AGENTS.md (e60420b) dans des commits dédiés qui citent la spec ; aucune dépendance ajoutée.
- Temps mesurés ici (pas la machine de Jimmy) : `just preflight` 17 s, `just check` 34 s builds compris.

## 4. Non vérifiable ici

- La CI Linux sous sh : à regarder sur la pull request (le `just check` vert sur ubuntu).
- Les temps sur la machine de Jimmy (30 s pour `preflight`, 90 s pour `check`, décision 3).
- Revue owner exigée par l'index des skills pour les types `tooling` et `harness`.
- Ressenti manette : rien, la branche ne touche ni mouvement, ni caméra, ni retour visuel.

`````
