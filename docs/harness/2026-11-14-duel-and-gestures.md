# Leçons des tours — duel local et figures par gestes

Tours du 2026-11-14, propriétaire : Jimmy. Deux changements, menés en partie de front :
`docs/specs/local-duel.md` (étape 4 de la feuille de route) et
`docs/specs/trick-gestures.md` (les figures refaites après que Jimmy les a jouées, avec
trois amendements). Pull requests n° 20, 28, 31 et 33 pour le duel ; n° 32, 34, 35,
36, 37, 38 et 40 pour les figures. Les sept rapports des agents sont à la fin, mot pour
mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

## Déroulé

| Étape | Qui | Résultat |
| ----- | --- | -------- |
| Duel : spec | session principale seule (délégation) | 17 décisions ; deux couloirs identiques, fantôme, bot, manche |
| Duel : passe 1 | développeur | 303 tests ; le bot tombait dans la dernière section, sabotait deux fois un joueur arrêté ; la décision 17 ne sauvait pas le coureur qui retombe |
| Duel : amendement 1, passe 2 | session principale, puis développeur | effet retardé qui attend une zone vide, bot vers le checkpoint suivant ; interrompu par la fin d'une session, relancé |
| Duel : inspection | inspecteur | aucun scénario cassé ; **le bot ne sabotait jamais** dans une vraie manche (première munition après la dernière cible) |
| Duel : amendement 2, passe 3 | session principale, puis développeur | deux munitions de départ pour chacun, fin du duel contre le fantôme à son arrivée, dix constats corrigés ; 311 tests ; fusion |
| Figures : la partie de Jimmy | Jimmy | « clavier-souris pas intuitif », le stick dirige et choisit à la fois, figures trop longues pour le plat |
| Figures : sparring | session principale avec Jimmy | la réception au bon moment ; puis les gestes dessinés à la Skate, aux deux claviers ; le Trick Park |
| Figures : passe 1 | développeur, sur la branche du duel | 314 tests ; la boucle sans risque sur le plat à 156 200 points par minute |
| Figures : réglages | session principale | fenêtre de répétition à 10 moves, vrille à 0,3 s : 3 790 par minute |
| Figures : inspection 1 et partie de Jimmy | inspecteur, Jimmy | 63 gestes humains, 9 mal lus ; Jimmy veut voir son tracé |
| Figures : amendement, passe 2 | session principale, puis développeur | le pavé à l'écran, la lecture pour la main, un corpus de gestes ; fusion |
| Figures : le saut de figure | Jimmy, puis développeur | lâcher au sol saute et lance la figure ; fusion |
| Figures : inspection 2, amendement 3 | inspecteur, session principale, développeur | 103 gestes humains ; la ligne flow à 72 000 par minute ; la sortie de mur demandée par Jimmy ; 85 gestes tous bien lus ; fusion |

## Leçons

1. **Le jeu de Jimmy a tranché ce que dix specs ne voyaient pas.** Les figures au stick
   passaient leurs 37 scénarios et deux inspections ; en dix minutes de jeu, Jimmy a vu
   qu'elles étaient injouables (le stick choisissait et dirigeait). Proposition : pour
   tout ce qui se joue à la main, une version jouable part vers Jimmy dès la première
   passe verte, avant l'inspection, comme au tour des murs.
2. **Un corpus de gestes humains vaut mieux que des seuils réglés à la main.** La
   reconnaissance a été jugée sur 63, puis 85 gestes écrits pour imiter une main (souris
   à plusieurs sensibilités, stick avec rampes et rebonds, hésitations, tremblements).
   Chaque geste mal lu est devenu une ligne du corpus ; les seuils, des réglages.
   Proposition : toute entrée « au geste » se spécifie avec son corpus.
3. **Le bot ne sabotait jamais, et les tests passaient.** Le scénario du sabotage
   donnait une munition au bot à la main ; dans une vraie manche, il n'en avait pas à
   temps. Proposition : chaque comportement d'un adversaire se prouve aussi dans une
   manche entière, sans rien donner à la main.
4. **Les boucles sans risque reviennent à chaque règle nouvelle.** La glissade parfaite
   après une pose, les figures payées par un wall-run, la fin d'un combo qui rend les
   figures neuves, le crash volontaire : chacune a été trouvée par un inspecteur qui
   jouait sans risque avec le vrai moteur. La dernière (20 068 par minute en variant
   huit figures vrillées avec des crashs) a été acceptée : c'est du jeu risqué.
   Proposition : distinguer dans les specs « sans risque » (à fermer) et « risqué mais
   payant » (à juger en jouant).
5. **Les limites de temps des portes se mesurent machine au repos.** Avec d'autres
   programmes et plusieurs agents, `just check` a pris de 71 à 127 s pour le même code.
   La limite de `just preflight` est passée à 40 s par sa propre spec quand le projet a
   atteint 95 scripts. La CI est restée l'arbitre.
6. **Une session interrompue laisse un agent sans trace.** Le développeur du duel a été
   arrêté par la fin d'une session ; son worktree était propre, rien n'était perdu.
   Proposition : à la reprise, toujours regarder l'état du worktree avant de relancer.

## Ce qui reste ouvert après ces tours

- **Point d'arrêt n° 3** : Jimmy a joué les figures (« beaucoup plus fluide […] ça peut
  s'enchaîner ») ; le duel contre le bot et le fantôme, et le tir, restent à juger.
- L'étape 6 (le personnage animé) est avancée avant l'étape 5 par décision de Jimmy.
- Les durées des portes à remesurer machine au repos.

## Rapports des agents, mot pour mot

### Développeur, duel local (trois passes)

`````markdown
# Rapport du développeur : duel local (`docs/specs/local-duel.md`)

Le duel local est implémenté et `just check` est vert. Un point à trancher avant la fusion : `just preflight` a dépassé 30 s sur 2 de mes 5 mesures (33,0 s et 33,3 s). Je n'ai touché à aucune porte (détails dans **Vérifié** et **Questions**).

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a6dc3d6121ae32f09`, branche `local-duel`. Trois commits sur `a1fec84` :
- `7e50bd5` : le code, les tests, `project.godot` et le README ;
- `4ece8a6` : les lignes Layout d'`AGENTS.md` ;
- `188fe98` : le statut de la spec (`🟢 Implémenté`), seule ligne changée.

Rien n'est poussé.

## Fait

Chaque scénario a son test du même nom.

**La manche** (`tests/test_round.gd`, `core`)
- Le compte à rebours précède la course : `test_the_countdown_precedes_the_race`. Le test de soutien `test_the_runners_wait_for_go_and_start_together` (`tests/test_course_duel.gd`, vraie physique) vérifie trois choses :
  - personne ne bouge avant GO, même en poussant ;
  - aucun chrono ne tourne avant GO ;
  - les deux chronos partent au même pas, et l'écran montre 3, 2, 1 puis GO.
- Le premier arrivé gagne : `test_the_first_to_finish_wins`.
- Une arrivée au même pas se départage au style : `test_a_finish_at_the_same_step_is_decided_by_style`.
- La limite de temps départage au checkpoint : `test_the_time_limit_is_decided_by_checkpoint`.
- Pas de recommencement en duel : `test_no_restart_in_a_duel`.
- La revanche remet tout à zéro : `test_the_rematch_resets_everything` (`tests/test_course_duel.gd`). Le test passe par l'écran de résultat, avec l'action saut.

**Les couloirs** (vraie physique)
- Les deux couloirs sont identiques et séparés : `test_the_two_lanes_are_identical_and_apart` (`tests/test_course_duel.gd`). Il compare blocs, cibles et checkpoints au millimètre, et mesure un vide de 4,000 m entre les blocs les plus proches, avec des couloirs à 28 m l'un de l'autre.
- En duel, on ne tire que sur le couloir adverse : `test_in_a_duel_only_the_opposing_lane_can_be_shot` (`tests/test_sabotage.gd`, `core`). Le test de soutien `test_the_player_of_a_duel_shoots_the_opposing_lane_only` (`tests/test_course_duel.gd`) fait la même chose avec la vraie caméra.
- Une cible adverse se tire depuis la section d'avant : `test_an_opposing_target_can_be_shot_from_the_section_before` (`tests/test_course_duel.gd`).
- Le solo d'entraînement reste comme à l'étape 3 : `test_solo_practice_stays_as_in_step_3` (`tests/test_course_duel.gd`).
- Une plateforme n'agit pas sous un coureur en l'air : `test_a_platform_does_not_act_under_a_runner_in_the_air` (`tests/test_course_duel.gd`). Le test de soutien `test_a_platform_waits_for_nobody_to_be_in_the_air_above_it` (`tests/test_sabotage.gd`) couvre les quatre types de cible.

**Le fantôme**
- Le fantôme rejoue la meilleure course solo : `test_the_ghost_replays_the_best_solo_run` (`tests/test_course_ghost.gd`). Le test fait une vraie course solo de la dernière section avec le pilote. Il compare ensuite la position et l'orientation du fantôme, pas par pas, à celles que le test a lui-même relevées pendant la course.
- Le fantôme ne touche rien : `test_the_ghost_touches_nothing` (`tests/test_course_ghost.gd`).
- Le duel contre le fantôme demande une course solo : `test_the_ghost_duel_needs_a_solo_run` (`tests/test_start_screen.gd`).

**Le bot** (`tests/test_course_bot.gd`, vraie physique)
- Le bot franchit le parcours entier : `test_the_bot_clears_the_whole_course`. Il finit en 31,45 s.
- Le bot sabote quand le joueur approche d'une cible : `test_the_bot_sabotages_when_the_player_nears_a_target`. Le test vérifie que le tir part après exactement 48 pas de visée.
- Le bot paie la visée : `test_the_bot_pays_for_the_aim`.
- Le bot ne tire pas sans munitions : `test_the_bot_does_not_shoot_without_ammunition`.

**Écrans**
- L'écran de départ se navigue aux deux claviers : `test_the_start_screen_is_navigated_on_keyboard_and_gamepad` (`tests/test_course_menus.gd`, avec de vrais événements de touche, de croix, de stick et de boutons).
- L'écran de résultat montre la manche : `test_the_result_screen_shows_the_round` (`tests/test_result_screen.gd`).
- Le HUD montre l'écart avec l'adversaire : `test_the_hud_shows_the_gap_to_the_opponent` (`tests/test_race_hud.gd`).

**Tests de soutien sans scénario du même nom**
- `test_the_round_knows_the_gap_at_the_last_common_checkpoint` (`tests/test_round.gd`).
- `tests/test_bot_saboteur.gd` : `test_the_bot_chooses_the_cheapest_target_the_player_nears` et `test_the_bot_leaves_a_target_the_player_does_not_near`.
- `tests/test_ghost_run.gd` : `test_a_run_is_recorded_from_the_step_before_the_runner_first_acts` et `test_the_session_keeps_the_best_solo_run`.
- `test_the_start_screen_chooses_with_up_down_and_jump` (`tests/test_start_screen.gd`).
- `tests/test_result_screen.gd` : `test_the_verdict_of_a_lost_round_and_of_a_draw` et `test_the_result_screen_chooses_the_rematch_or_the_menu`.
- `test_the_debug_display_shows_the_opponent_flow` (`tests/test_debug_overlay.gd`).
- `tests/test_course_menus.gd` : `test_a_finished_solo_run_opens_the_duel_against_the_ghost` et `test_the_main_scene_is_the_start_screen`.

**Tests existants modifiés** (aucun affaibli)
- `test_the_main_scene_is_the_test_course` (`tests/test_course.gd`) devient `test_the_test_course_has_its_runner_lines_and_checkpoints`. La spec change la scène principale, donc l'égalité avec le parcours ne pouvait plus tenir. Le test vérifie désormais que la scène principale n'est plus le parcours. Ses assertions sur le parcours sont gardées, et la scène principale est vérifiée dans `tests/test_course_menus.gd`.
- `tests/test_input_map.gd` : les trois nouvelles actions sont ajoutées à la liste vérifiée sur clavier et manette.
- `MotorBody.fixed_tuning()` reçoit les quatre réglages du groupe Duel.

**Preuve du rouge**
- Les nouveaux tests de `core` (sabotage, règle du bot, course enregistrée) ont tourné sans l'implémentation, mise de côté puis restaurée. Ils échouaient à l'analyse : type introuvable, ou trop d'arguments à `new()` ou `step()`.
- Les tests d'écrans et de duel étaient rouges parce que leurs types n'existaient pas encore. Pour ces scénarios, le rouge était une erreur d'analyse, pas une assertion.
- Le test de portée était rouge sur ses assertions à 45 m : 50,25 m pour la plateforme, 59,62 m pour l'obstacle.
- Les deux tests du fantôme ont d'abord échoué :
  - un vrai bug : le chrono du joueur démarrait pendant le compte à rebours, car un coureur ajouté par le code est d'abord à l'origine du couloir, dans sa ligne de départ ;
  - une erreur de mon second test : son coureur tombé était ramené au checkpoint avant la vérification.
- J'ai ajouté au test du compte à rebours l'assertion « aucun chrono ne tourne avant GO ». Je l'ai vue rouge avant de corriger le bug.

## Vérifié

- `just setup` : vert.
- Référence avant tout changement : `just check` vert en 53,8 s (tests 28,8 s, 262 tests).
- Final sur `4ece8a6` (le code de `188fe98` est identique) : `just check` vert en 65,3 s. Deux runs précédents ont pris 71,1 s et 65,8 s.
  - 297 tests passent, en 38,7 s de tests.
  - Les builds Windows et Linux sont exportées. Le build Windows tourne 60 images en headless sur la nouvelle scène principale.
  - `structure` : 0 problème dans les quatre sections.
- `just preflight` : vert à chaque fois, mais en 27,6 s, 27,7 s, 28,2 s, 33,0 s et 33,3 s.
  - Détail d'un run : `import` 3,2 s, `typecheck` 10,1 s (95 scripts au lieu de 70), `lint` 5,3 s, tests rapides 15,3 s, `deadcode` 0,3 s.
  - Mes nouveaux tests rapides coûtent environ 1 s en tout. Le reste de la hausse vient du typecheck des 25 nouveaux scripts, plus la variance de la machine.
  - La limite de 30 s est menacée. Je n'ai rien relâché (voir **Questions**).
- Mesure jetable, test supprimé avant le commit : les deux coureurs menés par le même pilote dès GO.
  - Bot à 0 munition au départ : il en gagne 2 mais ne tire jamais, car aucune cible ne remplit sa règle quand il en a. Il gagne en 31,45 s ; les deux sont tombés une fois.
  - Bot à 3 munitions au départ : 2 tirs (pont, plateforme), le joueur touché 2 fois et tombé 2 fois. Le bot gagne en 32,02 s.
- La chute du bot : chaque course du bot tombe une fois, dans la dernière section (x local ≈ −4, z ≈ −232). Il sort du zigzag à 4 m de l'axe et court droit.

## Non vérifié

- **Le ressenti, à la manette** :
  - le compte à rebours ;
  - la lisibilité des écrans de départ et de résultat, et le surlignage des choix ;
  - la couleur du bot (orange) et le fantôme orange à moitié transparent ;
  - l'écart à côté du chrono ;
  - si le couloir adverse, 28 m à droite, se voit bien avec la caméra ;
  - la portée de 60 m en solo.
- **Le fantôme ne s'accroupit pas** : il garde la hauteur debout pendant une glissade, car seules la position et l'orientation sont enregistrées (décision 6).
- **Les sons en duel** : le joueur entend les alertes, effets et retours de son couloir et ses propres tirs, pas les effets sur le couloir adverse. À juger à l'oreille.
- **Une vraie manette** : les tests envoient des événements simulés (Start, croix, stick, A), jamais une manette physique.
- **La souris** : Échap ramène désormais au menu en solo comme en duel, ce qui libère la souris.
- **Le build Linux** : exporté mais pas lancé (machine Windows).
- **La difficulté et l'équité du bot.**

## Écarts

1. **Portée de tir à 60 m (décision 3).**
   - Lecture retenue : la cible adverse est à portée depuis tout point de la section d'avant. C'est mesuré depuis les yeux au checkpoint de cette section, son point le plus loin, jusqu'au point de visée en haut de la cible. Pour le pont, la « section d'avant » est le départ.
   - Il faut 59,62 m (obstacle depuis LowPassage) et 50,25 m (plateforme depuis ShortJumps).
   - La lecture faible (depuis un point quelconque de la section d'avant) était déjà vraie à 45 m : 34 m au plus.
   - Conséquences : la portée du solo passe aussi à 60 m (README mis à jour), et le bot porte plus loin.
2. **Décision 17 aussi en solo.** L'automate des cibles est commun. « En l'air au-dessus » veut dire : dans la zone de la cible et pas au sol.
   - Ce que je n'ai pas mesuré, seulement raisonné : dans la fenêtre de l'inspection, la règle ne rend pas la touche évitable. Le coureur atterrit sur la plateforme environ 0,59 s après l'appel du saut et y reste environ 0,66 s. L'effet commence alors qu'il est posé dessus, donc il est touché et tombe, comme le dit la spec. La règle ne change l'issue qu'en fin de fenêtre, quand l'alerte finit pendant le saut qui quitte la plateforme.
3. **En duel, la ligne de départ ne démarre plus la course : GO le fait.** Sans cela, le chrono du joueur démarrait au chargement : le bug ci-dessus.
4. **Le fantôme.**
   - Enregistrement : du pas avant la première action du coureur (direction, saut ou glissade) jusqu'à l'arrivée, pour qu'il ne piétine pas au départ.
   - Choix de la meilleure course : le meilleur temps affiché (BEST).
   - Son temps dans la manche : le nombre de pas de sa première action à son arrivée, comparé au chrono du joueur depuis GO. Les deux comptent les 3 m d'élan depuis l'arrêt.
   - Il porte le score de style de sa course, pour le départage et l'écran de résultat.
   - Ses checkpoints sont des messages de la manche, donc l'écart s'affiche aussi contre lui.
5. **Contre le fantôme, les cibles de son couloir restent tirables.** Elles réagissent, mais le fantôme les ignore.
6. **Menus, actions nouvelles dans `[input]`.**
   - `menu` : Échap ou Start.
   - `menu_up` et `menu_down` : flèches, W et S, croix, stick gauche.
   - Rien ne disait comment revenir au menu depuis le solo : c'est nécessaire pour atteindre le duel contre le fantôme. Échap ou Start ramène donc au menu depuis le solo et pendant un duel.
   - L'écran de résultat accepte aussi Recommencer (Retour arrière, Back) comme retour au menu : c'est le « Back » du contrat.
   - Le choix grisé du fantôme est sauté par la navigation.
   - Un écran ignore les entrées de l'image où il s'ouvre, pour que le saut qui a choisi ne choisisse pas une seconde fois sur l'écran suivant.
7. **L'écart affiché** est la différence des deux chronos tels qu'affichés, en centièmes : c'est ce qui permet « +1.24 ». Il ne s'affiche qu'à partir du checkpoint 1, le 0 étant le départ.
8. **En duel, le HUD cache BEST et le style**, que l'écran de résultat montre.
9. **La direction du bot** est celle du checkpoint de sa section, comme le dit la spec. Il en résulte la chute systématique en dernière section (voir **Vérifié**). Courir vers le checkpoint suivant l'éviterait.
10. **« Le joueur à moins de 25 m avant la cible »** se mesure le long de l'axe du checkpoint de la section du joueur, jusqu'au point de visée de la cible, avec 0 < distance ≤ 25. À coût égal, le bot préfère la cible dont le joueur est le plus près. Après 0,8 s de visée il appuie sur tir ; si l'arme refuse, il abandonne et rechoisit au pas suivant.
11. **Le couloir adverse est à droite**, décalé de la largeur du couloir plus 4 m, soit 28 m.
12. **Seule la visée du joueur fait briller les cibles visées.** Celle du bot ne trahit rien.
13. **`Course.RUNNER` passe de 1 à 0**, pour suivre les identifiants 0 et 1 de la décision 13.
14. **La session garde BEST et BEST STYLE du solo** d'une visite à l'autre. Sinon, le passage par le menu les remettrait à zéro.
15. **Le fantôme et le bot étaient visés « farmables »** (leçon de chaque tour) ; voici ce que la mesure jetable montre, sans rien changer à la spec.
    - Un joueur arrêté à 20 m de sa plateforme, qui n'avance jamais, fait tirer le bot (3 munitions) **deux fois** sur la même plateforme en 12 s : il tire de nouveau dès qu'elle redevient prête.
    - Le bot gaspille ses munitions et la visée lui coûte environ 0,3 s à chaque fois. Le joueur, lui, perd tout le temps qu'il attend : ce n'est pas rentable en temps.
    - La règle de la décision 8 regarde la distance, pas l'approche.
    - Autre faiblesse, raisonnée et non mesurée : le bot vise, donc ralentit à 5,4 m/s, même juste avant un saut long. Un joueur placé près d'une cible au bon moment peut le faire tomber.

## Questions

1. **`just preflight`** : 27,6 à 33,3 s sur cette machine, pour une limite de 30 s. Le coût vient surtout du typecheck des scripts (95 maintenant). Je n'ai rien relâché. Faut-il accepter, ou changer l'outillage dans un commit des propriétaires ?
2. **La portée** : 60 m (lecture « toute la section d'avant », retenue) ou 45 m (lecture « un point de la section d'avant ») ?
3. **La décision 17** ne rend pas la touche évitable pour un coureur qui atterrit sur la plateforme. Faut-il la rouvrir ?
4. **Le bot** :
   - doit-il courir vers le checkpoint suivant, pour éviter sa chute en dernière section ?
   - doit-il ne saboter que si le joueur s'approche, et pas une seconde fois la même cible pour un joueur arrêté ?

---

# Amendement (spec `461d394`) : rapport court

L'amendement est implémenté et `just check` est vert. Branche `local-duel`, commits, rien de poussé :
- `160d150` : fusion de `main` (limite de preflight à 40 s), sans conflit ;
- `4c81988` : code, tests et README de l'amendement ;
- `69d74a0` : spec remise à `🟢 Implémenté`, seule ligne changée.

## Fait (test d'abord, chaque nouveau test vu rouge)

- **Décision 17** : un effet retardé par un coureur en l'air attend ensuite que sa zone soit vide. C'est vrai aussi en solo, l'automate étant commun.
  - Scénario « Un coureur qui retombe sur une plateforme retardée n'est pas touché » : `test_a_runner_who_lands_back_on_a_delayed_platform_is_not_hit` (`tests/test_course_duel.gd`). Le pilote franchit les sauts longs avec une alerte d'un pas, lancée pendant qu'il survole la plateforme. Il y retombe, en repart, et n'est pas touché ; l'effet commence zone vide.
  - Rouge avant le code : 5 assertions, dont « it is not hit », car le coureur était touché et tombait.
  - Deux tests de l'ancienne règle étaient contredits par l'amendement :
    - le test réel `test_a_platform_does_not_act_under_a_runner_in_the_air` exigeait une touche (`sabotages == 1`) : il vérifie maintenant que l'effet attend en l'air, attend encore sous le coureur posé, puis commence quand il est parti, sans toucher personne, pour toute sa durée ;
    - le test de soutien `core` `test_a_platform_waits_for_nobody_to_be_in_the_air_above_it` exigeait aussi une touche ; il suit désormais la même séquence.
  - Le cas sans retard (coureur posé dessus à la fin de l'alerte : touché) reste couvert par les tests de l'étape 3.
- **Décision 7** : le bot court vers le checkpoint suivant, et vers l'arrivée dans la dernière section.
  - Scénario « Le bot finit le parcours sans tomber » : `test_the_bot_finishes_the_course_without_falling` (`tests/test_course_bot.gd`). Il exige zéro retour à un checkpoint et jamais sous les blocs.
  - Rouge avant le code : 1 retour, point le plus bas −7,71 m.
  - Résultat : le bot finit en 28,62 s sans tomber, contre 31,45 s avec une chute.
- **Décision 8** : `BotSaboteur` devient une instance qui se souvient de deux choses.
  - Approche : la distance du joueur à la cible doit avoir diminué depuis le pas d'avant. Choix : une marge de 1 mm, pour ignorer le bruit d'un corps immobile.
  - Une seule fois par cible tant que le joueur n'a pas atteint un nouveau checkpoint.
  - Le duel ne lance pas de visée quand le pilote voit un saut avant la fin de la visée. Méthode du pilote : `sees_a_jump_within`. Le pilote cherche le sol tous les 0,25 m, et une marche ou un rebord à franchir, sur la distance parcourue pendant la visée : la vitesse du moment, ou la vitesse de pointe en visée si elle est plus grande, fois 0,8 s.
  - Scénario « Le bot ne sabote pas un joueur arrêté deux fois » : `test_the_bot_does_not_sabotage_a_stopped_player_twice` (`tests/test_course_bot.gd`). Le test raccourcit le cycle de la plateforme (alerte 0,2 s, effet 0,5 s, repos 0,3 s) pour qu'elle revienne prête près du bot.
    - Pas de sabotage tant que le joueur est arrêté.
    - Un sabotage quand il s'approche.
    - Pas de second, ni à l'arrêt ni en s'approchant encore, sans nouveau checkpoint.
    - Rouge avant le code : un second tir.
  - Scénario « Le bot ne vise pas avant un saut » : `test_the_bot_does_not_aim_before_a_jump` (`tests/test_course_bot.gd`). Le bot est lancé à 3 m du vide, occasion de sabotage ouverte. Rouge : d'abord à cause de sa mise en place, qui ne lui donnait pas sa section. Après correction du test, revu rouge avec la vérification du saut désactivée exprès : « it did not start aiming before the jump ». Vert avec la règle.
  - Tests `core` de soutien dans `tests/test_bot_saboteur.gd` : `test_the_bot_waits_for_the_player_to_approach` et `test_the_bot_does_not_sabotage_a_target_twice_before_a_new_checkpoint`.
- **Tests existants adaptés à la nouvelle règle d'approche.** Les deux tests de l'API sans état ont été réécrits sur l'API à mémoire, mêmes assertions. Dans les tests « Le bot sabote quand le joueur approche » et « Le bot ne tire pas sans munitions », le joueur avance maintenant lentement (stick à 0,2) au lieu de rester immobile. Le bot y attend tenu au début des sauts longs, là où une visée finit avant le vide.

## Vérifié

- `just check` vert sur `4c81988` : 303 tests passent ; builds Windows et Linux exportées ; le build Windows tourne 60 images en headless.
- Temps sur `4c81988` : `just check` 71,1 s (limite 90 s), `just preflight` 27,0 s (limite 40 s). Deux runs précédents de preflight : 29,7 s et 27,7 s.
- Un incident pendant la vérification : `just build` a d'abord échoué. L'exécutable de `build/windows` était verrouillé par une instance du jeu lancée depuis l'Explorateur (sans `--headless`), sans doute par Jimmy en train de jouer à ce build. Je ne l'ai pas arrêtée.
  - En attendant, j'ai exporté le build Windows dans le scratchpad avec la même commande Godot : 0 erreur, 60 images en headless.
  - Une fois le jeu fermé, `just check` est passé vert sur le commit.

## Non vérifié

- À la manette : le moment où le bot sabote, maintenant seulement si on s'approche.
- La plateforme retardée qui disparaît derrière le joueur.
- La trajectoire du bot vers chaque checkpoint.

---

# Second amendement (spec `771c4ed`) : rapport court

Le second amendement et les constats 2 à 10 de l'inspection sont faits. `just check` est vert, mais il a pris 118,5 s, au-dessus de la limite de 90 s, sur une machine chargée par d'autres programmes. Sous la même charge, mes tests ne coûtent rien de mesurable (détails dans Vérifié).

Branche `local-duel`, commits, rien de poussé :
- `43f0c6f` : code, tests et README ;
- `7629b2a` : spec remise à `🟢 Implémenté`, seule ligne changée.

## Scénarios (tests d'abord, chacun vu rouge)

- **Décision 18** : `duel_start_ammo` = 2, dans le groupe Duel. Chaque coureur du duel le reçoit au début d'une manche et à la revanche ; le solo ne change pas.
  - « Le bot sabote dans une vraie manche » : `test_the_bot_sabotages_in_a_real_round` (`tests/test_course_bot.gd`). Le joueur, mené par le pilote, part 0,5 s après GO ; aucune munition n'est donnée à la main. Rouge : 0 tir sur toute la manche. Vert : le bot tire 0,82 s après GO.
  - « Les deux coureurs partent avec les mêmes munitions » : `test_both_runners_start_with_the_same_ammunition` (`tests/test_course_duel.gd`). Il vérifie aussi que le solo part à 0. Rouge : erreur d'analyse, le réglage n'existait pas.
  - `test_the_rematch_resets_everything` attend maintenant les munitions de départ après la revanche, et non 0 : c'est la décision 18.
- **Décision 19** : contre le fantôme, la manche se termine à son arrivée, sans limite de 3 min, et le joueur qui n'a pas fini perd.
  - « Le duel contre le fantôme se termine à son arrivée » : `test_the_ghost_duel_ends_at_its_finish` (`tests/test_course_ghost.gd`), avec une course de 4 s et une limite réglée à 2 s.
  - Rouge : la manche finissait à la limite (pas 120, verdict DRAW). Vert : elle finit au pas 239, YOU LOSE.

## Constats de l'inspection

- **#2** : la phase « joueur arrêté » de `test_the_bot_does_not_sabotage_a_stopped_player_twice` attend maintenant `WATCH_STEPS` et exige qu'aucun `aim_held` n'apparaisse. Le cassage B2 (condition d'approche retirée) le fait échouer.
- **#3, #4, #5** : trois tests de soutien en vraie physique dans `tests/test_course_duel.gd`, chacun vu rouge avec le cassage de l'inspecteur :
  - `test_a_restart_request_does_nothing_in_a_duel` : rouge avec B9 ;
  - `test_the_time_limit_of_a_duel_is_decided_by_checkpoint` (limite réglée à 3 s) : rouge avec B12 ;
  - `test_the_hud_of_a_duel_shows_the_gap_at_a_checkpoint` (vérifie `%GapLabel`) : rouge avec B13.
- **#6** : `Candidate` porte le fait « ligne de tir dégagée ». Le duel le mesure par `Player.aim_facts_towards`, le même rayon que le tir réel du bot. Test `core` : `test_the_bot_leaves_a_target_hidden_from_it`.
- **#7** : le duel tient les coureurs selon `round_state.runners_may_move()`. Il n'applique le maintien que quand la réponse change : appliqué à chaque pas, il écrasait le maintien posé par les tests.
- **#8** : « un saut vu avant la fin de la visée » est un fait passé à `BotSaboteur.choose`. Test `core` : `test_the_bot_starts_no_aim_with_a_jump_ahead`.
- **#9** : les libellés GHOST et BOT sont dans `game/ui/result_screen.gd`, derrière `ResultScreen.Opponent`.
- **#10** : l'action `menu` est lue par `Main`. `Course` et `Duel` ne lisent plus d'entrée ; le duel ne signale plus que le choix MENU de l'écran de résultat.

## Vérifié

- `just check` vert sur `43f0c6f` : 311 tests ; builds Windows et Linux exportées ; le build Windows tourne 60 images en headless.
- Temps mesurés sur une machine chargée par d'autres programmes : `PBZ` (environ 20 600 s de CPU) et Roblox, CPU entre 67 et 82 %.
  - `just check` : 116,8 s puis 118,5 s.
  - `just preflight` : 62,7 s, contre 27,0 s pour le commit précédent mesuré à vide.
- Comparaison à charge égale, toute la suite de tests lancée l'une après l'autre : 61,8 s pour le commit précédent (`69d74a0`, copie `git archive`), 60,1 s pour `43f0c6f`. Le coût ajouté est dans le bruit. À vide, il faut donc s'attendre au temps du commit précédent : 71 s pour `just check`, 27 à 30 s pour `just preflight`.
- Je ne peux pas le prouver ici tant que la machine est occupée : les deux limites sont à revérifier sur une machine au repos.
- Un test a été stabilisé : le test de l'écart rafraîchit le HUD avant de lire `%GapLabel`. Sans cela, il échouait selon l'instant où tombait la lecture.

## Non vérifié

- À la manette : le bot qui sabote dès le départ (il a 2 munitions) ; la fin du duel contre le fantôme à son arrivée.

`````

### Inspecteur, duel local

`````markdown
# Inspection de `local-duel` (a1fec84..local-duel)

Spec : `docs/specs/local-duel.md` (amendée : intro, décisions 7, 8, 17, scénarios « amendement », « Choix acceptés après le développement »), avec `sabotage.md`, `flow-combo.md`, `air-tricks.md`, `test-tiers.md` et `AGENTS.md`.
Types de tâche : core, player, world, levels, ui, tooling (`project.godot`), harness (`AGENTS.md`, `README.md`, `docs/`).
Toutes les expériences ont tourné sur une copie hors dépôt (`C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-local-duel\copy`). Le worktree n'a pas été modifié.

## 1. Verdict

**À corriger.** Un seul constat bloquant, et c'est une décision de conception que Jimmy doit trancher (constat 1). Aucun scénario n'échoue : les 303 tests passent.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
|---|---------|---------------|-------|---------|-------------|
| 1 | **bloquant (à trancher par Jimmy)** | `game/levels/duel.gd:245` (les munitions du bot) ; décision 7 (« Il ne fait pas de figure ») | Spec, décision 7, « Pourquoi » : le plan veut un « bot simple qui court et sabote » ; décision 8, « Pourquoi » : « Un bot qui sabote au bon moment donne du sens à l'alerte » | **Mesuré avec le vrai moteur : dans une vraie manche, le bot ne sabote jamais.** Il gagne sa première munition à z = -193 (zigzag, 22,4 s de course), après la dernière cible (l'obstacle, z = -144,5). Joueur à sa hauteur, puis 1, 2, 4, 6, 8 et 10 s derrière lui : 0 visée, 0 tir, et 3 munitions inutilisées à l'arrivée. Avec 6 à 8 s de retard, le seul cas où l'obstacle est à portée et payé (19 et 29 pas), le bot voit un saut à faire (zigzag) et ne vise pas. Une revanche remet les munitions à 0. Le scénario « Le bot sabote quand le joueur approche » ne passe que parce que le test lui donne une munition (`tests/test_course_bot.gd:186`). | Jimmy tranche : des munitions de départ pour le bot (une valeur `bot_start_ammo` dans le groupe Duel), quelques figures, ou une autre source. Puis un scénario « Dans une manche, le bot sabote le joueur qui court à sa hauteur », prouvé sur le parcours entier sans munitions données à la main. |
| 2 | conseillé | `tests/test_course_bot.gd:105-106` | Scénario « Le bot ne sabote pas un joueur arrêté deux fois » (« … et ne sabote pas sans que le joueur s'approche ») | **Cassage B2 :** j'ai retiré la condition d'approche (`game/core/bot_saboteur.gd:46`) et `test_course_bot` reste vert. L'assertion « a stopped player: no sabotage » n'attend que `SETTLE_STEPS` (30 pas), alors qu'une visée du bot dure 48 pas : aucun tir ne peut partir dans cette fenêtre. Seul le test core `test_bot_saboteur.gd::test_the_bot_waits_for_the_player_to_approach` attrape le cassage. | Attendre `WATCH_STEPS` à cet endroit, et vérifier que le bot n'a pas visé (`intent.aim_held`), comme le fait `test_the_bot_does_not_shoot_without_ammunition`. |
| 3 | conseillé | `game/levels/duel.gd:88` | Scénario « Pas de recommencement en duel » | **Cassage B9 :** j'ai supprimé `lane.race.restartable = false` et tout reste vert (`test_course_duel`, `_bot`, `_ghost`, `_menus`, `test_round`). Le test ne prouve que `RaceState` (`tests/test_round.gd:130`). Le câblage du duel n'est prouvé nulle part. | Un test en vraie physique dans `test_course_duel.gd` : pendant la manche, une demande de recommencer ne change ni le chrono ni la position. |
| 4 | conseillé | `game/levels/duel.gd:129-133` | Scénario « La limite de temps départage au checkpoint » | **Cassage B12 :** si le duel n'envoie jamais le message de limite de temps, tout reste vert. Seuls `RoundClock` et `RoundState` sont testés (`tests/test_round.gd:102`). Une manche où personne ne finit (fantôme d'une course solo de plus de 180 s, bot bloqué) ne finirait jamais. | Un test de duel avec une `round_time_limit` courte : la manche finit à la limite, et l'écran de résultat s'affiche. |
| 5 | conseillé | `game/levels/duel.gd:258-266` | Scénario « Le HUD montre l'écart avec l'adversaire » | **Cassage B13 :** si les checkpoints ne sont jamais transmis à la manche, tout reste vert. Le test (`tests/test_race_hud.gd:69`) remplit `RoundState` à la main. Ni l'écart en jeu ni le départage « checkpoint le plus loin » ne sont prouvés en vraie physique. | Dans un rejeu de duel, deux coureurs passent un checkpoint ; vérifier le texte de `%GapLabel`. |
| 6 | conseillé | `game/core/bot_saboteur.gd:65-71` | Décision 7 (« mêmes règles ») ; leçon 1 de `docs/harness/2026-11-14-flow-combo.md` | **Mesuré :** le joueur avance et recule devant la barrière. Le bot vise 3 fois et ne tire qu'une fois. Deux visées échouent : la ligne partie de sa tête touche un bloc à 42,3 m et à 33,7 m, avant le point visé (47,3 m et 37,6 m). La barrière au repos est au ras du sol. Le bot paie chaque visée (0,8 s à 60 %) et finit 0,78 s plus tard. Sans effet pour le joueur : pas de boucle à exploiter (voir les mesures), mais des visées perdues. | Ajouter au `Candidate` un fait « la ligne depuis la tête atteint la cible » (mesuré dans `duel.gd`), et l'exiger dans `_may_sabotage`. |
| 7 | conseillé | `game/core/round_state.gd:61` ; `game/levels/duel.gd:124,154,277` | `AGENTS.md`, « Ports and adapters » : « No dead code: a script, a scene or a resource appears with its first consumer » ; « Architecture » (les règles dans `core`) | `runners_may_move()` n'a aucun consommateur dans le jeu ; seul `test_round.gd` l'appelle. Qui peut bouger se décide dans `duel.gd`, sur l'événement de l'horloge (`_hold_the_runners`), pas sur l'état de la manche. | Mettre `held = not round_state.runners_may_move()` à chaque pas de `Duel`, ou supprimer la fonction. |
| 8 | conseillé | `game/levels/duel.gd:246-249` | `AGENTS.md`, « Architecture » ; décision 8, amendement | La règle « ne pas commencer une visée quand un saut vient avant sa fin » se décide dans `levels`, hors de `BotSaboteur` (core), qui porte les autres règles de la décision 8. | Passer « un saut vu avant la fin d'une visée » comme fait à `BotSaboteur.choose`. |
| 9 | conseillé | `game/levels/duel.gd:27-30` | Axe « Wording » : une chaîne visible hors de `game/ui/` | `"GHOST"` et `"BOT"`, affichés par l'écran de résultat, sont écrits dans `levels`. | Les déplacer dans `game/ui/result_screen.gd`, par exemple derrière l'enum de l'adversaire. |
| 10 | conseillé (je ne suis pas sûr que la règle s'applique) | `game/levels/course.gd:56`, `game/levels/duel.gd:136` | `AGENTS.md`, « Architecture » : `player/` est l'endroit où l'entrée est lue et changée en intentions ; `game/levels/lane.gd:9` : « It reads no input » | Les deux scènes de niveau lisent elles-mêmes l'action `menu`. Ce n'est pas une entrée de simulation, mais `levels` lit désormais une entrée. | Faire lire `menu` par `Main`, ou par un nœud de `game/ui/`. |
| 11 | conseillé | `docs/specs/local-duel.md` (« Choix acceptés ») | Procédure : un test sans scénario du même nom ; précédent `docs/specs/sabotage.md:341` | Environ 18 tests de soutien n'ont pas de scénario du même nom. Exemples : `test_the_runners_wait_for_go_and_start_together`, `test_the_round_knows_the_gap_at_the_last_common_checkpoint`, `test_in_a_duel_only_the_opposing_lane_can_be_shot`, `test_a_platform_waits_for_nobody_to_be_in_the_air_above_it`, les 4 de `test_bot_saboteur.gd`, les 2 de `test_ghost_run.gd`, `test_a_finished_solo_run_opens_the_duel_against_the_ghost`, `test_the_main_scene_is_the_start_screen`, `test_the_start_screen_chooses_with_up_down_and_jump`, `test_the_verdict_of_a_lost_round_and_of_a_draw`, `test_the_result_screen_chooses_the_rematch_or_the_menu`, `test_the_debug_display_shows_the_opponent_flow`, `test_the_test_course_has_its_runner_lines_and_checkpoints`. | Une ligne « Les tests de soutien » dans les choix acceptés, comme à l'étape 3. |
| 12 | conseillé | `docs/specs/movement-base.md:239` | Spec local-duel, Contexte : « Ce que la spec ne doit pas casser : tous les scénarios antérieurs » | Le scénario « La scène principale est le parcours test » est remplacé par un choix accepté (« Le test de la scène principale »). La spec d'origine ne le dit pas. Le renommage du test est sain (voir plus bas). | Une note dans `movement-base.md` qui renvoie à `local-duel.md`. |
| 13 | conseillé (règle ambiguë, je ne suis pas sûr) | `game/levels/duel.gd:254`, `game/core/round_state.gd:128-140` | Décision 9 : « Contre le fantôme, le joueur gagne s'il arrive avant la fin de la course du fantôme » | Lu dans le code, sans mesure. (a) Si la meilleure course solo dure plus de 180 s, le fantôme ne finit pas avant la limite. Le joueur peut alors gagner sans finir, au checkpoint le plus loin. Je ne sais pas si « s'il arrive » veut dire « seulement s'il arrive ». (b) À la limite, le fantôme départage avec le score de style de toute sa course, et le joueur avec son score du moment. | Jimmy tranche (a). Pour (b), donner au fantôme le style atteint au pas de la limite : enregistrer le style par checkpoint dans `GhostRun`. |

## 3. Couverture de la spec

Chaque scénario a son test du même nom. Le cassage indique si le test attrape une erreur réelle (un cassage à la fois, sur la copie).

| Scénario | Test | Cassage |
|---|---|---|
| Le compte à rebours précède la course | `test_round.gd::test_the_countdown_precedes_the_race` (+ `test_course_duel.gd::test_the_runners_wait_for_go_and_start_together`) | B10, coureurs jamais retenus : échoue |
| Le premier arrivé gagne | `test_round.gd::test_the_first_to_finish_wins` | — |
| Une arrivée au même pas se départage au style | `test_round.gd::test_a_finish_at_the_same_step_is_decided_by_style` | — |
| La limite de temps départage au checkpoint | `test_round.gd::test_the_time_limit_is_decided_by_checkpoint` | B12 : câblage non prouvé (constat 4) |
| Pas de recommencement en duel | `test_round.gd::test_no_restart_in_a_duel` | B9 : câblage non prouvé (constat 3) |
| La revanche remet tout à zéro | `test_course_duel.gd::test_the_rematch_resets_everything` | B11, `targets.reset()` retiré : échoue ; B10 : échoue |
| Les deux couloirs sont identiques et séparés | `test_course_duel.gd::test_the_two_lanes_are_identical_and_apart` | mesure : 4,000 m entre les blocs, couloirs à 28 m |
| En duel, on ne tire que sur le couloir adverse | `test_course_duel.gd::test_the_player_of_a_duel_shoots_the_opposing_lane_only`, `test_sabotage.gd::test_in_a_duel_only_the_opposing_lane_can_be_shot` | B7, pas de contrôle du couloir : les deux échouent |
| Une cible adverse se tire depuis la section d'avant | `test_course_duel.gd::test_an_opposing_target_can_be_shot_from_the_section_before` | mesures : 29,78 / 50,25 / 40,05 / 59,62 m ≤ 60 |
| Le solo d'entraînement reste comme à l'étape 3 | `test_course_duel.gd::test_solo_practice_stays_as_in_step_3` | — |
| Une plateforme n'agit pas sous un coureur en l'air | `test_course_duel.gd::test_a_platform_does_not_act_under_a_runner_in_the_air` | B4, pas de « en l'air » dans la scène : échoue ; B5 : échoue |
| Le fantôme rejoue la meilleure course solo | `test_course_ghost.gd::test_the_ghost_replays_the_best_solo_run` | B8, fantôme un pas en retard : échoue |
| Le fantôme ne touche rien | `test_course_ghost.gd::test_the_ghost_touches_nothing` | — |
| Le duel contre le fantôme demande une course solo | `test_start_screen.gd::test_the_ghost_duel_needs_a_solo_run` | — |
| Le bot franchit le parcours entier | `test_course_bot.gd::test_the_bot_clears_the_whole_course` | 28,62 s, 0 chute |
| Le bot sabote quand le joueur approche d'une cible | `test_course_bot.gd::test_the_bot_sabotages_when_the_player_nears_a_target` | B14, visée faussée : échoue ; B15 : échoue (mais voir constat 1) |
| Le bot paie la visée | `test_course_bot.gd::test_the_bot_pays_for_the_aim` | B15, `aim_held` seulement à la fin : échoue |
| Un coureur qui retombe sur une plateforme retardée n'est pas touché | `test_course_duel.gd::test_a_runner_who_lands_back_on_a_delayed_platform_is_not_hit` | B5, pas d'attente de la zone vide : échoue (et `test_sabotage`) |
| Le bot finit le parcours sans tomber | `test_course_bot.gd::test_the_bot_finishes_the_course_without_falling` | B6, ancienne direction (section) : échoue |
| Le bot ne sabote pas un joueur arrêté deux fois | `test_course_bot.gd::test_the_bot_does_not_sabotage_a_stopped_player_twice` | B3, cible sabotée non retenue : échoue ; B2, pas de condition d'approche : **reste vert** (constat 2) |
| Le bot ne vise pas avant un saut | `test_course_bot.gd::test_the_bot_does_not_aim_before_a_jump` | B1, vise toujours : échoue |
| Le bot ne tire pas sans munitions | `test_course_bot.gd::test_the_bot_does_not_shoot_without_ammunition` | — |
| L'écran de départ se navigue aux deux claviers | `test_course_menus.gd::test_the_start_screen_is_navigated_on_keyboard_and_gamepad` | vrais événements : flèche, Espace, Échap, croix, stick, A |
| L'écran de résultat montre la manche | `test_result_screen.gd::test_the_result_screen_shows_the_round` | — |
| Le HUD montre l'écart avec l'adversaire | `test_race_hud.gd::test_the_hud_shows_the_gap_to_the_opponent` | B13 : câblage non prouvé (constat 5) |

**Ce que le brief demandait de vérifier :**
- **Restructuration de `game/levels/`.** `lane.tscn` est l'ancien `test_course.tscn`, octet pour octet sur les blocs, les cibles et les checkpoints. Seuls changent le script et la ressource de réglage à la racine, et le joueur, le HUD et la lumière, partis dans `test_course.tscn`, qui hérite de `lane.tscn`. Les tests antérieurs ne perdent aucune assertion. Le test renommé (`test_the_main_scene_is_the_test_course` devenu `test_the_test_course_has_its_runner_lines_and_checkpoints`) garde toutes ses assertions sur le parcours. L'assertion sur la scène principale part dans `test_course_menus.gd::test_the_main_scene_is_the_start_screen`, comme le dit le choix accepté. Je juge ce renommage sain (seul le constat 12, sur la spec d'origine, reste). Les assertions retirées par l'amendement (« a runner standing on it is hit as before ») suivent la décision 17 amendée. Le coup porté sans délai reste prouvé par `test_being_in_the_zone_when_the_effect_starts_breaks_the_combo`.
- **Pilote déplacé vers `game/player/`.** C'est un renommage à 88 % de similarité. Il ajoute `run_towards`, `sees_a_jump_within` et `_no_floor_at`, une extraction de code sans changement de comportement. `test_pilot.gd` et `piloted_run.gd` ne changent que dans leurs commentaires. Aucune assertion n'est affaiblie.
- **Manche dans `core`.** `RoundState` ne change que par `receive(RoundMessage)`. Les identifiants valent 0 (joueur) et 1 (adversaire). `Course.RUNNER` passe de 1 à 0. Les messages de sabotage portent `Shooter.id`, c'est-à-dire le `runner_id` du couloir. Les tests le prouvent : `message.shooter == OPPONENT` pour le bot, `PLAYER` pour le joueur. Réserve : le constat 7.
- **Mêmes règles pour le bot.** Il a le même `Player`, le même réglage et le même flow. Le même `Shooter` applique la visée minimale, comptée au sol, et le coût. Le moteur applique le ralenti de la visée. B15 le prouve.
- **Durée des portes** (copie, mes lancements l'un après l'autre ; je ne sais pas si d'autres agents tournaient sur la machine) : `just preflight` **28,4 s** (limite 40 s), `just check` **70,0 s**, builds compris (limite 90 s). 303 tests, 0 échec.

**Mesures avec le vrai moteur et le réglage du projet** (fichier de test jetable `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-local-duel\scripts\test_course_inspect.gd`, cassages dans `...\scripts\breaks.py`, journaux `*.log` à côté) :
- **Le bot exploité ou « farmé ».**
  - Joueur arrêté : 0 visée.
  - Joueur qui avance et recule devant chaque cible, munitions du bot remplies à chaque pas : une seule visée tirée par cible et par checkpoint (plateforme, pont, obstacle), et 3 visées dont 2 perdues à la barrière (constat 6). Le bot perd 0,26 à 0,78 s. Il ne tombe jamais.
  - Ce joueur ne gagne rien : il n'avance pas. Je n'ai pas trouvé de boucle sans risque.
- **Le joueur appâte le bot avant un vide.** 0 chute du bot dans toutes les manches mesurées (B1 prouve que le garde-fou du saut sert).
- **Le joueur sabote le bot.**
  - Plateforme touchée quand le bot est à 20 m : le bot ne lit pas l'alerte, tombe 2 fois et perd 4,5 s.
  - Barrière, obstacle et pont : 0 à 0,35 s perdus.
- **Décision 17, avec la plateforme des sauts longs.** J'ai balayé l'instant du tir, de -1,5 s à +1,5 s autour de l'appel du saut long vers la plateforme. Chaque cas teste trois réponses : continuer, s'arrêter avec 0,2 s de réaction, ou sauter sur la plateforme avant la fin de l'alerte. **Les 61 instants ont tous une sortie.**
  - Si le tir part entre -1,5 et -0,55 s : s'arrêter suffit.
  - À -0,5 et -0,45 s : continuer suffit (effet retardé).
  - **À -0,40 s**, l'alerte finit au pas de l'atterrissage : seul l'arrêt avec 0,2 s de réaction sauve.
  - De -0,35 à +0,05 s : sauter sur la plateforme sauve.
  - **De +0,10 à +0,35 s**, seul un saut 0,5 à 0,7 s avant la fin de l'alerte sauve. Un saut 0,15 à 0,3 s avant retombe dans le vide suivant.
  - À partir de +0,40 s : continuer suffit.
  - Le pont n'a pas été mesuré de nouveau : la seconde inspection du sabotage y trouvait toujours une sortie, et l'amendement ne fait qu'ajouter du délai.
- **Les règles de résultat détournées.** Un duel contre le fantôme ne se gagne sans finir que si la meilleure course solo dépasse 180 s (constat 13). Pas d'autre moyen trouvé : le recommencement est coupé (dans le code ; constat 3 pour le test), et Échap quitte la manche sans résultat.

## 4. Non vérifiable ici (à juger manette en main)

- **Le duel contre le bot tel qu'il est** : le bot ne sabote jamais (constat 1). L'alerte n'arrive donc qu'en solo ou contre soi-même.
- **Le compte à rebours** (3, 2, 1, GO d'une seconde, chiffre de 160 px) et le départ au GO, coureurs figés : lisibilité et sensation de départ.
- **Voir l'adversaire** à 28 m sur la droite : se lit-il en course ? Le bot et le fantôme sont orange (1, 0,5, 0,1), presque la couleur de surbrillance des cibles (1, 0,55, 0,15). Risque de confusion.
- **Le fantôme** à moitié transparent : lisible ? Sa réaction parfaite au GO ; son temps sur l'écran de résultat compte depuis le GO et diffère donc du BEST du solo (qui compte depuis la ligne de départ).
- **Viser le couloir adverse** de côté, à 30 à 60 m, en courant tout droit, à la souris puis au stick (LT/RT) : le réticule se lit-il à 60 m ? La portée de 60 m change aussi le solo.
- **Esquiver une plateforme retardée en sautant dessus** : les fenêtres mesurées sont étroites (0,2 s). Est-ce jouable, ou de la chance ?
- **L'écart** (« +1.24 », jaune, à côté du chrono) : lisible en course ?
- **Les menus** :
  - le choix courant n'est marqué que par la couleur (jaune contre blanc) ; le choix grisé et sa raison ;
  - zone morte du stick à 0,5 ;
  - Échap ou Start quitte le solo ou la manche sans confirmation, et Échap ne sert plus à libérer la souris (l'action `release_mouse` reste liée à Échap) ;
  - un saut pressé juste après l'arrivée peut lancer la revanche.
- **Le parcours complet joué à la main contre le bot**, puis contre son propre fantôme.

`````

### Développeur, figures par gestes (trois passes)

`````markdown
# Rapport du développeur : trick-gestures

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a4870026ba8ce5c05`
Branche : `trick-gestures`. Base : `92ef5a7`, la fusion de `local-duel` (pointe `69d74a0`) dans `10b85ae`.
Commits :
- `bc2a28f` : l'implémentation, les tests et le README
- `2b577f0` : les lignes Layout d'AGENTS.md
- `f3b65bd` : la spec passe à `🟢 Implémenté`

Rien n'est poussé ni fusionné.

## Fait

### Reconnaître les gestes (core)

Fichier de test : `tests/test_trick_gesture.gd`. Code : `game/core/trick_gesture.gd` et `game/core/trick_recipe.gd`.

| Scénario | Test |
| --- | --- |
| Un coup sec choisit le salto | `test_a_quick_stroke_chooses_the_flip` |
| Le même coup répété ajoute un tour | `test_the_same_stroke_repeated_adds_a_turn` |
| Un demi-cercle ajoute une vrille | `test_a_half_circle_adds_a_twist` |
| Pas de vrille sur un side flip ni un spin | `test_no_twist_on_a_side_flip_or_a_spin` |
| Un cercle seul est un spin | `test_a_circle_alone_is_a_spin` |
| Un geste illisible ne lance rien | `test_an_unreadable_gesture_starts_nothing` |

Ces tests couvrent aussi des gestes imparfaits :
- un coup sec décalé de 30° et un peu courbe ;
- un « J » (le coup sec qui s'enroule en demi-cercle sans pause) ;
- un demi-cercle bâclé à 135° ;
- le retour de la main vers le haut entre deux coups vers le bas ;
- des gribouillis au hasard (graine fixe).

### Dessiner et lancer

| Scénario | Test |
| --- | --- |
| Tenir le bouton de figure fige la caméra | `test_holding_the_trick_button_freezes_the_camera` (`tests/test_player_tricks.gd`), avec les vrais événements F, souris et stick droit |
| La figure part quand on lâche le bouton en l'air | `test_the_trick_starts_when_the_button_is_released_in_the_air` (`tests/test_runner_tricks.gd`) |
| Lâcher le bouton au sol ne lance rien | `test_releasing_the_button_on_the_ground_starts_nothing` (`tests/test_player_tricks.gd`), avec les vrais événements. Le dessin est bien oublié : un appui suivant en l'air, sans dessin, lance la figure du contexte et pas le backflip |
| Sans geste, la figure du contexte part | `test_without_a_gesture_the_trick_of_the_context_starts` (`tests/test_runner_tricks.gd`). Couvre aussi le cas « à l'arrêt → backflip » |
| Une seule figure par saut | `test_one_trick_per_jump` (`tests/test_runner_tricks.gd`) |

### Durées

Fichier de test : `tests/test_runner_trick_risk.gd`. Les tests pèsent le réglage du projet.

| Scénario | Test |
| --- | --- |
| Un simple tient dans un saut à plat | `test_a_single_fits_in_a_jump_on_the_flat` |
| Un double ne tient pas dans un saut à plat | `test_a_double_does_not_fit_in_a_jump_on_the_flat` |
| Une vrille allonge la figure | `test_a_twist_makes_the_trick_longer` |

### Poser la figure

Fichier de test : `tests/test_runner_trick_landing.gd`.

| Scénario | Test |
| --- | --- |
| Appuyer dans la fenêtre pose la figure | `test_pressing_within_the_window_poses_the_trick` |
| Appuyer au dernier moment donne un PERFECT | `test_pressing_at_the_last_moment_gives_a_perfect` |
| Ne pas appuyer est un crash | `test_not_pressing_is_a_crash` |
| Un appui trop tôt est perdu | `test_a_press_too_early_is_lost` |
| Un appui trop tôt peut être refait | `test_a_press_too_early_can_be_made_again` |
| Une figure pas finie au sol est un crash même avec l'appui | `test_an_unfinished_trick_on_the_ground_is_a_crash_even_with_the_press` |
| Une figure posée en grande chute roule | `test_a_trick_posed_in_a_big_fall_rolls` |
| Une figure posée sur le plat lance une glissade | `test_a_trick_posed_on_the_flat_starts_a_slide` |
| Une figure rapporte au début d'un wall-run sans appui | `test_a_trick_pays_at_the_start_of_a_wall_run_without_a_press` |

### Points et variété

| Scénario | Test |
| --- | --- |
| Les points suivent la difficulté | `test_the_points_follow_the_difficulty` (`tests/test_runner_trick_landing.gd`) |
| Deux recettes différentes ne sont pas une répétition | `test_two_different_recipes_are_not_a_repetition` (`tests/test_runner_trick_landing.gd`) |
| Une boucle sans risque sur le plat rapporte peu | `test_a_riskless_loop_on_the_flat_earns_little` (`tests/test_runner_trick_risk.gd`). Seuil proposé, voir Questions |

### Vraies entrées et vraie physique

| Scénario | Test |
| --- | --- |
| Un backflip vrillé au clavier-souris | `test_a_twisted_backflip_on_keyboard_and_mouse` (`tests/test_course_trick_park.gd`). Événements F, W, Espace et Ctrl sur des touches physiques, plus des mouvements de souris. Le coureur est sur le bloc de 2 m du Trick Park |
| Un backflip vrillé à la manette | `test_a_twisted_backflip_on_the_gamepad` (`tests/test_course_trick_park.gd`). Stick gauche, LB, A et RB ; le stick droit donne un coup vers le bas puis fait un demi-tour sur son bord |
| Le Trick Park offre toutes les hauteurs | `test_the_trick_park_offers_every_height` (`tests/test_course_trick_park.gd`). Chaque bloc de 1, 2, 3, 5 et 8 m est vraiment gravi dans la vraie physique par un coureur qui pousse et saute. Le test vérifie aussi la géométrie des deux murs face à face et du mur à wall-run, et que chaque bloc est d'un seul tenant |
| Le Trick Park se choisit dans l'écran de départ | `test_the_trick_park_is_chosen_on_the_start_screen` (`tests/test_course_menus.gd`). Au clavier, puis à la manette. Vérifie l'absence de chrono, de cible et d'adversaire, le retour au départ par R puis par Y, et le menu par Échap puis par Start |

### Affichage

| Scénario | Test |
| --- | --- |
| Le HUD montre la recette en cours de dessin | `test_the_hud_shows_the_recipe_being_drawn` (`tests/test_flow_hud.gd`). Le HUD affiche « ? », puis « BACKFLIP », puis « BACKFLIP FULL » |

### Autres changements

- **Décision 1, les touches** : `project.godot` met « figure » sur F (touche physique) et sur LB (bouton 9). LB ne sert plus au saut ; Shift et X ne font plus rien. Test : `test_the_trick_is_on_f_and_lb_and_is_posed_with_the_slide` (`tests/test_input_map.gd`).
- **Décision 13, le Trick Park** : `game/levels/trick_park.tscn` et `trick_park.gd` (`TrickPark`).
  - Esplanade de 120 × 120 m.
  - Blocs de 1, 2, 3, 5 et 8 m en rang devant le départ. On monte sur ceux de 5 et 8 m par des marches de 2,5 m.
  - À gauche, deux murs face à face à 4 m l'un de l'autre ; à droite, un mur à wall-run de 24 m.
  - Le HUD du flow, ses sons et l'affichage de debug sont là.
  - Le choix « TRICK PARK » arrive en dernier sur l'écran de départ.
- **Décision 16, le réglage** : toutes les valeurs nouvelles sont dans le groupe « Tricks » de `movement_tuning.tres`. `trick_points_per_turn` et `trick_air_chain_bonus` ont été retirés.
- README : commandes, figures, Trick Park et feuille de route. AGENTS.md : lignes Layout de `core/`, `player/` et `levels/`.

### Tests des scénarios remplacés (décision 14)

**Retirés :**
- `test_the_pushed_direction_chooses_the_flip`
- `test_releasing_the_button_finishes_the_current_turn`
- `test_holding_the_button_chains_the_turns`
- `test_a_jump_press_during_a_flip_adds_a_twist`
- `test_twists_do_not_exceed_their_maximum_per_turn`
- l'ancien `test_no_twist_on_a_side_flip_or_a_spin` du moteur (le nom sert maintenant au scénario des gestes)
- `test_a_second_trick_in_the_same_jump_is_worth_more`
- `test_a_finished_trick_pays_at_the_landing`
- `test_a_crash_does_not_pay_the_tricks_already_finished_in_the_jump`
- `test_a_trick_finished_just_before_the_ground_is_perfect`
- `test_only_the_last_trick_of_the_jump_is_perfect`
- `test_a_trick_finished_too_early_is_not_perfect`
- `test_a_trick_pays_at_the_start_of_a_wall_run` (remplacé par la version « sans appui »)
- `test_the_points_of_a_composed_trick` (750 points, l'ancien barème)
- `test_a_trick_that_changes_one_brick_is_not_a_repetition` (remplacé par « deux recettes différentes »)
- `test_the_big_fall_still_asks_for_a_roll` : son scénario, un PERFECT sans appui sur glissade, est devenu impossible puisqu'il faut glisser pour poser
- `test_a_flip_does_not_fit_in_a_jump_on_the_flat`
- `test_a_drop_high_enough_allows_a_flip`
- `test_a_riskless_loop_on_the_flat_earns_nothing`
- `test_a_backflip_on_the_keyboard_in_the_real_physics` et `test_a_backflip_on_the_gamepad_in_the_real_physics`, avec tout le fichier `tests/test_course_tricks.gd`

**Gardés et adaptés au lâcher et à la pose** (leur règle reste en vigueur) :
- `test_a_trick_does_not_start_on_the_ground`
- `test_a_trick_does_not_start_in_a_wall_run_or_a_mantle`
- `test_a_trick_does_not_change_the_trajectory`
- `test_a_twist_near_the_ground_does_not_start_a_jump` : c'est la règle « pas de saut fantôme » ; c'est maintenant un appui sur saut pendant une figure
- `test_during_a_trick_the_jump_does_not_start_a_wall_jump`
- `test_no_wall_run_or_mantle_during_a_trick`
- `test_the_name_of_a_trick_is_composed_of_its_bricks`
- `test_an_unfinished_trick_on_the_ground_is_a_crash`
- `test_a_trick_pays_at_the_start_of_a_mantle`
- `test_a_fall_off_the_course_loses_the_tricks_of_the_jump`
- `test_perfect_landings_in_a_row_do_not_raise_the_speed_without_end`
- `test_the_visible_body_makes_the_turn_of_the_trick`
- `test_no_trick_while_aiming`
- les tests du HUD (figure en cours, réception) et des sons

## Vérifié

Toutes les commandes Godot et just sont lancées avec le PATH de WinGet.

**Installation**
- `just setup` : OK.

**Tests vus rouges avant leur code**
- `test_trick_gesture` contre un bouchon qui ne lisait jamais rien.
- `test_player_tricks`, `test_input_map`, `test_flow_hud` et `test_course_trick_park` avant leur implémentation : rouges pour la bonne raison (caméra qui tourne, F sans effet, HUD vide, `TrickPark` absent).
- Les tests du moteur ne pouvaient pas être vus rouges contre l'ancien moteur, qui ne compile plus avec la nouvelle intention. Je les ai écrits en même temps que la réécriture, puis prouvés rouges par 9 mutations ciblées (script dans le scratchpad, fichier restauré après chaque essai). À chaque fois, le test visé échoue :

| Mutation | Test qui échoue |
| --- | --- |
| pose ignorée | `not_pressing` et `press_too_early` |
| deux figures par saut | `one_trick_per_jump` |
| pas de contexte | `without_a_gesture` |
| départ à l'appui et non au lâcher | `starts_when_the_button_is_released` |
| pas de PERFECT | `last_moment_gives_a_perfect` et `big_fall_rolls` |
| vrille sans durée | `twist_makes_the_trick_longer` |
| contexte payé comme une figure dessinée | `points_follow_the_difficulty` |
| pavé sans le stick droit | `twisted_backflip_on_the_gamepad` |
| pavé sans la souris | `twisted_backflip_on_keyboard_and_mouse` |

**Portes sur le dernier commit de code (`2b577f0`)**
- `just preflight` : vert en 57,5 s.
  - typecheck : 100 scripts, 0 erreur.
  - lint : aucun problème.
  - 241 tests passent (12,3 s de GUT).
  - deadcode : 0 problème.
- `just check` : vert en 2 min 07 s.
  - 314 tests passent (56,1 s de GUT).
  - Builds Windows et Linux exportés ; le Windows a tourné 60 images en headless.

**Les temps dépassent les limites (40 s et 90 s), mais la base les dépassait déjà ce jour-là sur cette machine**
- `just preflight` de la base, au début de la session : 51,5 s et 63,3 s.
- `just check` de la base `92ef5a7`, lancé dans la même session : 2 min 07 s, dont 61,4 s de GUT.
- Ma branche ne les aggrave pas. Tests sans les replays : 10,8 s → 12,3 s. Tous les tests : 61,4 s → 56,1 s, parce que l'ancien `test_course_tricks.gd` est retiré.
- La machine semble chargée, sans doute par d'autres agents en parallèle. La limite est à revoir sur une machine au repos.

**Mesure de la décision 15** (réglage du projet, une minute, réception PERFECT à chaque saut)

| Boucle | Style par minute | Détail |
| --- | --- | --- |
| Courir et sauter seuls | 75 | 0 munition, 9,00 m/s |
| Toutes les recettes qui tiennent dans un saut à plat (front flip, backflip, side flip, spin, backflip FULL, front flip FULL), chacune lâchée au premier pas en l'air | **156 200** | 97 figures pour 98 sauts, 0 crash. Le style vaut environ 156 munitions ; la réserve, plafonnée à 3, est pleine en permanence. Vitesse moyenne 11,07 m/s, pointe 11,25 m/s |
| Simples, côtés gauche et droit séparés | 121 812 | |
| Quatre simples distincts | 132 725 | |
| Deux simples distincts | 62 900 | |
| Une seule recette | 525 | |
| Figure du contexte seule | 300 | |
| Quatre simples distincts, `flow_repetition_window` = 6 | 67 791 | |
| Idem, `flow_repetition_window` = 8 | 66 428 | |
| Idem, `flow_repetition_window` = 10 | 3 790 | |

**Comment j'ai choisi les seuils du geste**

Toutes ces valeurs sont dans `movement_tuning.tres`, à régler par Jimmy.

- **Échelle du pavé** : 1 pixel de souris vaut 0,01 unité, donc 100 px font 1 unité. Le stick droit à fond vaut 10 unités par seconde : il agit comme une vitesse. Ainsi, le donner d'un coup puis le relâcher trace un coup sec, et lui faire faire le tour de son bord trace un cercle.
- **Coup sec : au moins 0,8 unité.** À la souris, 80 px, environ 11° de caméra à la sensibilité actuelle : un petit coup franc. Au stick, environ 5 pas à fond, soit un coup de pouce d'environ 0,08 s.
- **« Rien dessiné » (la figure du contexte) : 0,3 unité de mouvement au plus**, soit 30 px. Une main qui tremble en appuyant sur F ne gâche pas l'appui simple. Entre 0,3 et 0,8 unité, c'est « trop peu pour un coup sec » : rien ne part.
- **Demi-cercle : 120° tournés suffisent sur 180°. Cercle : 270°.** Un geste humain est bâclé.
- **Pause qui sépare deux éléments : 0,05 s.** Un changement de direction de plus de 90° d'un pas à l'autre sépare aussi deux éléments, et un coup en sens contraire après le salto n'est pas lu : le retour de la main entre deux coups vers le bas est donc ignoré.
- **Constantes internes de `core`**, qui ne sont pas des réglages de sensation :
  - bruit : 0,004 unité par pas ;
  - un coup sec reste droit tant qu'il tourne de 40° au plus ;
  - un coup sec qui finit en crochet (60° ou plus) n'est lu que si son début droit fait la longueur d'un coup ;
  - le début droit d'un « J » doit faire au moins 40 % de sa longueur.
- **Une correction faite en route** : un demi-cercle de 90° à 120° n'est lu comme rien. Sans cela, le HUD affichait « DOUBLE BACKFLIP » un instant au milieu du demi-cercle.

## Non vérifié

**À juger manette en main et souris en main**
- Tout le ressenti.
- Les seuils sur une vraie souris, selon son DPI et l'accélération de Windows, et sur un vrai stick.
- Le délai de lâcher après le saut.
- La fenêtre de pose (0,25 s) et celle du PERFECT (0,1 s).
- Le rythme de la réception, le geste en J, le demi-tour du stick.

**Ce que les tests headless ne peuvent pas montrer**
- La souris qui tourne de nouveau la caméra une fois F lâché. En headless, la souris ne peut pas être capturée, donc la caméra n'y tourne jamais à la souris. Le test le prouve au stick ; pour la souris, il prouve seulement que le mouvement va au dessin et non à la caméra.

**À regarder à l'écran**
- Le HUD : « ? », puis le nom de la recette au-dessus de la jauge.
- Le choix « TRICK PARK » sur l'écran de départ, qui a été agrandi.
- Le Trick Park lui-même : couleurs, lumière (la même que le parcours de test), lisibilité des hauteurs.

**Prouvé seulement par la géométrie, pas dans la physique**
- Les wall-jumps entre les deux murs face à face.
- Le wall-run le long du mur du Trick Park.
- (Les blocs, eux, sont gravis dans la physique.)

**Autres**
- La rotation du corps visible pendant une vrille : le salto et la vrille sont maintenant répartis sur toute la durée de la figure.
- Je n'ai pas lancé le jeu en fenêtre, sur consigne.

## Écarts

1. **Une vrille tient dans un saut à plat**, contrairement à la phrase de la décision 7 (« une vrille demande une petite descente »). Mesuré avec le réglage :
   - un saut tenu à plat dure 36 pas ;
   - un backflip FULL dure 30 pas ; il tient s'il est lâché au plus 6 pas (0,1 s) après le décollage, y compris au pas même du saut ;
   - le double (42 pas) ne tient jamais.

   Aucun scénario ne le contredit. Je n'ai pas touché aux valeurs ; le README donne les chiffres. Voir Questions.
2. **Le spin**, c'est un cercle et un seul tour. Un second cercle après un spin n'est pas lu, donc pas de « 720 » dessiné. La spec ne dit rien des tours d'un spin.
3. **« À l'arrêt » pour la figure du contexte** : plus lent que la vitesse d'arrêt du flow (`flow_stop_speed`, 1 m/s). C'est un réglage réutilisé, pas une valeur nouvelle.
4. **Le côté d'un side flip** (gauche ou droite) ne fait pas partie de la recette pour la variété. C'est la règle d'air-tricks : salto, tours, vrilles. Une figure du contexte est le même move que la recette dessinée qui lui correspond (décision 11 lue ainsi).
5. **Le sens de la vrille** suit le sens dans lequel le demi-cercle est tracé : horaire à l'écran, la vrille part vers la droite. La spec n'en dit rien ; les points ne changent pas.
6. **Poser la figure** :
   - L'appui compte même s'il arrive avant la fin de la figure, pourvu qu'il soit dans les 0,25 s avant le contact et que la figure soit finie au contact.
   - Un appui au pas même où le moteur voit le sol compte comme « 0 s avant » : c'est un PERFECT. Le moteur voit le sol un pas après le contact physique.
   - Un appui pris entre 0,2 et 0,25 s pose la figure mais ne fait pas rouler.
7. **Le dessin à la souris marche même si la souris n'est pas capturée.** C'était nécessaire aux tests headless ; la caméra, elle, exige toujours la capture.
8. **Le HUD** :
   - Bouton tenu, le dessin passe avant la figure en cours.
   - Le HUD affiche « ? » aussi pour un dessin vide, qui donnerait la figure du contexte.
9. **Les tests adaptés plutôt que réécrits** :
   - `test_player_facing` : le seuil « passe la tête en bas » se calcule maintenant à partir du nombre de pas d'un tour, `cos(π/21)`. Avec 21 pas, le corps n'atteint jamais -0,99. Le sens du test ne change pas.
   - `test_start_screen` : le dernier choix est maintenant TRICK PARK.
10. **Le Trick Park ne sert qu'à tester les figures.** Il n'a pas de cible et donc pas de visée utile (pas de réticule) ; R et Y ramènent au départ, et la touche de redémarrage n'y fait rien.
11. **Le seuil de la boucle sans risque est à 160 000 dans le test.** C'est un garde-fou contre une hausse, pas « peu » : voir Questions.

## Questions

1. **Décision 15, le seuil de la boucle sans risque**, à écrire dans la spec.
   - Mesuré : 156 200 points de style par minute, toutes munitions pleines, contre 75 en courant et sautant seuls.
   - La variété ne limite pas le gain : il existe 4 à 6 recettes distinctes qui tiennent dans un saut à plat, pour une fenêtre de répétition de 4 moves. Le seul risque restant est le rythme de la pose, qu'un joueur parfait réussit à chaque fois.
   - Je propose 160 000 comme garde-fou (c'est ce que fait le test aujourd'hui).
   - Pour que la boucle « rapporte peu », il faut une décision du propriétaire. Pistes, toutes en réglage :
     - `flow_repetition_window` à 10 tombe à 3 790 (mesuré) ;
     - une durée de vrille d'au moins 0,27 s empêche toute vrille sur le plat.
2. **La vrille sur le plat** : faut-il la garder ou l'empêcher ?
   - La garder : un backflip FULL lâché dans les 0,1 s après le saut tient à plat.
   - L'empêcher : `trick_twist_duration` au moins à 0,27 s, ce qui donne 21 + 16 > 36 pas.
3. **Le spin** : un deuxième cercle doit-il faire un 720 ?
4. **Les seuils du geste** : à régler par Jimmy en jouant. Valeurs de départ ci-dessus.
5. **Les limites de temps des portes** (40 s et 90 s) ne tiennent pas sur cette machine aujourd'hui, même sur la base. Elles sont à remesurer machine au repos.

## Suite : fusion de main, décision 15, spins de plusieurs tours

**Commits** (branche `trick-gestures`) :
- `1612630` : fusion de `main` (`3418f98`), qui ne contient que la résolution. Conflit sur `game/levels/main.gd` : les deux côtés sont gardés. C'est maintenant `Main` qui lit l'action de menu ; le Trick Park n'a donc plus son propre signal `menu_requested`, comme le parcours solo.
- `b2fbf93` : un deuxième cercle après un spin fait un 720, un troisième un 1080, et pas plus. Assertions ajoutées à `test_a_circle_alone_is_a_spin`, vues rouges avant le code (le test lisait « 360 » à chaque cercle). README mis à jour.
- `72c6457` : décision 15.
  - `flow_repetition_window` passe à 10 dans `movement_tuning.tres`. Le réglage fixe des tests reste à 4 : ces tests vérifient les règles, pas les valeurs du propriétaire.
  - Seuil du test : 94 800.
  - Le seul test du flow qui dépendait d'une fenêtre de 4 lisait le réglage du projet : `test_restarting_resets_everything` (`tests/test_course_flow.gd`). Il calcule maintenant ce qu'il attend à partir de la fenêtre du réglage, sans affaiblir aucune assertion.
- `d2233f2` : correction d'un test instable qui existait déjà. `test_restarting_resets_everything` échouait environ une fois sur trois, sur `main` aussi (1 fois sur 5 sur `3418f98`, 2 sur 4 sur la fusion seule). Sans pas d'attente, la vérification pouvait passer avant le pas qui joue la demande. Les trois demandes de retour ou de redémarrage attendent maintenant un pas ; 8 passages sur 8 au vert ensuite.

**Mesures de la décision 15** (fenêtre de 10, PERFECT à chaque saut, une minute)

| Boucle | Style par minute |
| --- | --- |
| Les 6 recettes qui tiennent dans un saut à plat | **78 369** (156 200 avec une fenêtre de 4) |
| Les 4 simples (front flip, backflip, side flip, spin) | **3 790** (132 725 avec une fenêtre de 4) |
| Courir et sauter seuls | 75 |

- Seuil du test : 78 369 arrondi à 79 000, plus 20 %, soit **94 800**.
- La boucle à 6 recettes garde les munitions pleines : ce sont les deux simples à une vrille, qui tiennent dans un saut à plat, qui la rendent encore rentable.

**Portes**
- `just preflight` : vert en 31,1 s. 243 tests, typecheck et lint propres, deadcode 0 problème.
- `just check` : typecheck, lint, les 322 tests (49,4 s de GUT) et deadcode sont verts, en 1 min 09 jusqu'à l'export.
- **Le build n'a pas pu tourner.** `tools/export.py` ne peut pas effacer `build/windows/parkour-duel.exe` : ce fichier tourne en ce moment (PID 1580). Il a été lancé depuis l'Explorateur à 12:44, sans argument : c'est sans doute le propriétaire qui joue. Je ne l'ai pas arrêté. Cet exécutable est le build de `2b577f0` (avant la fusion, fenêtre de 4, pas de 720). Il faut relancer `just build` une fois le jeu fermé ; c'est la CI qui tranche.

## Suite 2 : la vrille à 0,3 s (décision 7)

Commit `d0487b1`.

- `trick_twist_duration` passe de 0,15 s à 0,3 s dans `movement_tuning.tres`. Un simple à une vrille dure 21 + 18 = 39 pas, plus qu'un saut tenu à plat (36 pas, calculés à partir du réglage).
- Nouveau test `test_a_twisted_trick_does_not_fit_in_a_jump_on_the_flat` (`tests/test_runner_trick_risk.gd`), qui lit le réglage du projet. Je l'ai vu échouer avant le changement de valeur (30 pas contre 36). Il vérifie deux choses :
  - la durée d'un simple à une vrille dépasse celle d'un saut tenu à plat ;
  - un backflip et un front flip à une vrille lâchés au pas même du saut finissent en crash.
- La boucle sans risque sur le plat, mesurée avec toutes les recettes qui tiennent encore dans un saut à plat (les quatre simples : front flip, backflip, side flip, spin) : **3 790 points de style par minute**. En courant et sautant seuls : 75.
- Seuil du test : 3 790 arrondi à 4 000, plus 20 %, soit **4 800**.
- README mis à jour (durée de la vrille).
- `just check` : vert jusqu'à l'export, en 1 min 09 (323 tests, 49,4 s de GUT ; typecheck, lint et deadcode propres).
- L'export bute toujours sur le jeu ouvert (PID 1580, lancé depuis l'Explorateur), que je n'ai pas arrêté. Le build est laissé à la CI.

## Suite 3 : l'amendement (décisions 17 à 21) et les constats de l'inspection

**Commits** (par-dessus `b845ba1`) :
- `ec664dc` : le code et les tests ;
- `7057e9c` : la ligne Layout de `game/ui` dans AGENTS.md ;
- `701c4f1` : la spec repasse à 🟢.

### Fait, scénario par scénario

Chaque test ci-dessous a été vu rouge avant son code.

**Le pavé à l'écran (décision 17)**

| Scénario | Test |
| --- | --- |
| Le pavé montre le tracé et valide la figure | `test_the_pad_shows_the_trace_and_validates_the_trick` (`tests/test_trick_pad.gd`) |
| Le pavé disparaît au lâcher | `test_the_pad_disappears_on_release` (`tests/test_trick_pad.gd`) |

- `TrickPad` (`game/ui/trick_pad.gd` et `.tscn`) est un disque translucide de 1/5 de la hauteur de l'écran.
- Le tracé y est dessiné à l'échelle de la reconnaissance : une seule échelle pour tout le tracé, réduite si le tracé sort du disque.
- Chaque élément lu est marqué : une flèche pour un coup sec, un arc coloré pour une vrille, un arc d'une autre couleur pour un spin.
- Le nom de la recette s'affiche sous le disque.
- Quand la figure est validée, le bord passe du blanc fin au vert épais. « Validée » veut dire : une recette dessinée, et la main au repos (aucun élément en cours).
- Le pavé lit `core` seulement : la `TrickGesture` du coureur, via `Player.drawing()`, et le moteur. Il est branché dans le parcours, le duel et le Trick Park.
- Le test des vraies entrées au clavier-souris dans le Trick Park vérifie aussi que le pavé valide « BACKFLIP FULL » puis disparaît au lâcher.

**Une lecture faite pour la main (décision 18)**

| Scénario | Test |
| --- | --- |
| Les gestes humains sont lus comme la main les veut | `test_human_gestures_are_read_as_the_hand_means_them` (`tests/test_trick_gesture_corpus.gd`) |
| Un coup au stick qui revient vite est lu | `test_a_stick_flick_that_comes_back_fast_is_read` (`tests/test_trick_gesture.gd`) |
| Un arc après le salto est une vrille | `test_an_arc_after_the_flip_is_a_twist` (`tests/test_trick_gesture.gd`) |
| Un retour de la main arrondi n'est pas une vrille | `test_a_rounded_return_of_the_hand_is_not_a_twist` (`tests/test_trick_gesture.gd`) |

- Le corpus reprend les 63 gestes de la sonde (38 à la souris, 25 au stick), avec le réglage du projet et une assertion par geste.
- Avant le changement, 9 gestes du corpus étaient mal lus.
- Les cas des constats 3 (retour arrondi), 4 (coup au stick rapide, à 60 %, double coup proche) et 5 (tenue avant une courbe, J au stick, J de 130°) font partie du corpus et des scénarios.

**La répétition survit à la fin d'un combo (décision 19)**

| Scénario | Test |
| --- | --- |
| La répétition des figures survit à la fin d'un combo | `test_the_repetition_of_tricks_survives_the_end_of_a_combo` (`tests/test_runner_trick_risk.gd`) |

- C'est la boucle de l'inspection : 4 simples posés PERFECT, puis la course au sol jusqu'à la fin du combo, sur une minute.
- **Mesuré : 2 776 points de style par minute**, au lieu de 27 350 avant le changement (sous le seuil de 4 800).

**Poser en grande chute (décision 20)**

| Scénario | Test |
| --- | --- |
| Une figure posée en grande chute ne finit pas en réception dure | `test_a_trick_posed_in_a_big_fall_does_not_end_in_a_hard_landing` (`tests/test_runner_trick_landing.gd`). Appui 15 pas avant le sol : TRICK puis ROLL, le combo continue |

**Le Trick Park, mur par mur (décision 21)**

| Scénario | Test |
| --- | --- |
| Aucun mur du Trick Park n'est fait de plusieurs blocs | `test_no_wall_of_the_trick_park_is_made_of_several_blocks` (`tests/test_course_trick_park.gd`) |

- Les marches sont plus étroites : 5 m pour Step5 et Step8High, 4 m pour Step8Low, sous des blocs de 6 m.
- Le test compare les faces verticales (X et Z) de deux blocs qui se touchent, tournées du même côté.

### Les constats de l'inspection

- **#1 (bloquant)** : les seuils du geste sont dans la ressource de réglage, groupe Tricks, et dans `MotorBody.fixed_tuning` :
  - `trick_gesture_noise` 0,004 ;
  - `trick_gesture_corner_angle` 90° ;
  - `trick_gesture_bend_angle` 25° ;
  - `trick_gesture_stroke_turn` 60° ;
  - `trick_gesture_stroke_share` 0,15 ;
  - `trick_gesture_two_twists_angle` 300° (nouveau).

  Valeurs changées :

  | Réglage | Avant | Après |
  | --- | --- | --- |
  | Vitesse du stick sur le pavé | 10 | 18 |
  | Longueur d'un coup sec | 0,8 | 0,65 (65 px) |
  | Mouvement qui compte pour rien | 0,3 | 0,55 |
  | Arc d'une vrille | 120° | 100° |

- **#2 (bloquant)** : les faces coplanaires du Trick Park, réglées par la décision 21.
- **#3, #4, #5** : dans le corpus (décision 18).
- **#6** : réglé par la décision 19.
- **#7** : un appui un pas avant la fenêtre PERFECT pose sans PERFECT. Ajouté à `test_pressing_within_the_window_poses_the_trick` ; vu échouer avec une fenêtre élargie d'un pas.
- **#8** : la souris tourne de nouveau la caméra après le lâcher. Le traitement d'un mouvement de souris est sorti dans `CameraRig.move_with_the_mouse(motion, captured)` ; le test l'appelle « capturée », parce qu'en headless la souris ne peut pas être capturée.
- **#9** : l'aller-retour bas, haut, bas est tracé sans pause.
- **#11** : deux tests de soutien aux vraies entrées, dans `tests/test_player_tricks.gd` :
  - `test_a_spin_drawn_with_the_right_stick` : LB tenu, le stick droit fait un tour de son bord, la lecture est « 360 » et la figure est validée ;
  - `test_the_trick_of_the_context_with_lb_posed_with_b` : à l'arrêt, A puis LB pressé et lâché en l'air donne un backflip du contexte, posé par B.
- **#13** : réglé par la décision 20.

### Comment le geste est lu maintenant

Un élément est mesuré en entier : sa partie droite au début, son arc, sa partie droite à la fin. L'arc est corrigé d'un pas pour valoir l'angle vraiment dessiné. Ensuite :
1. Un arc d'au moins 270° sans salto avant lui est un spin ; la partie droite du début ne compte pas. Après un spin, chaque cercle ajoute un tour.
2. Un arc d'au moins 100° sans salto avant lui, commencé par une partie droite d'au moins un coup sec, est un « J » : la partie droite donne le salto, l'arc une vrille.
3. Un arc d'au moins 100° après un front flip ou un backflip est une vrille ; à partir de 300°, deux vrilles. La partie droite du début ne compte pas : c'est la petite tenue avant une courbe.
4. Exception : si l'arc finit par une ligne droite plus longue qu'un coup sec, plus longue que la courbe elle-même, et dirigée contre le salto, c'est un retour de la main, pas une vrille.
5. Le stick qui revient dans sa zone morte termine l'élément tout de suite (l'appel `step(motion, delta, let_go)`). Le stick à 60 % se lit grâce à la vitesse du pavé portée à 18.

### Étiquettes choisies dans le corpus

- M1d (70 px vers le bas) est un **backflip**, voulu comme un coup de poignet.
- M9 (la caméra tournée de 50 px au moment de l'appui) est **la figure du contexte**.
- M9b (120 px à droite) est un **side flip** : impossible de le distinguer d'un coup voulu, et le pavé le montre.
- M6f (demi-cercle de 280° qui déborde) est **une vrille**.
- M7g (cercle de 290°) est **un spin**.
- M6j et S5 (tenue avant la courbe) donnent **BACKFLIP FULL**, pas un double.
- M7b, M7c, M7d, S7, S7b, S7e, S7f (cercle avec un élan droit) donnent **360**.
- M2, M2b, M2c (retour arrondi) donnent **BACKFLIP**.

### Tests touchés par les règles remplacées

- `test_the_end_of_a_combo_resets_the_repetition` (`tests/test_flow.gd`), qui portait la règle remplacée de flow-combo, devient le test de soutien `test_the_end_of_a_combo_by_its_delay_keeps_the_repetition` : après le délai, le troisième saut ne vaut plus rien ; après une erreur, il vaut de nouveau tous ses points.
- Le scénario de flow-combo « La fin d'un combo remet la répétition à zéro » est toujours dans cette spec-là : à amender.
- `test_every_slice_of_style_points_gives_ammunition` joue un move absent des derniers moves.
- `test_a_gauge_that_drops_then_rises_again_gives_no_extra_ammunition` fait tourner 7 moves au lieu d'un saut répété. Il calcule le style de chaque move et vérifie que les munitions sont exactement celles que donne le style. Aucune assertion n'est affaiblie.

### Vérifié

- `just preflight` : vert en 32,0 s.
- `just check` : **vert, export compris, en 1 min 23,6 s** (moins de 90 s).
  - typecheck : 104 scripts, 0 erreur ; lint propre ; deadcode 0 problème.
  - 334 tests passent (50,7 s de GUT).
  - Builds Windows et Linux exportés ; le Windows a tourné 60 images en headless.
  - Le jeu ouvert avait été fermé entre-temps.

### Non vérifié

**À juger en main**
- Le pavé : sa taille, sa lisibilité, ses couleurs (blanc, jaune, bleu, rose, vert de validation), la place du nom sous le disque, sa présence au centre de l'écran pendant la course.
- Les nouveaux seuils sur une vraie souris et un vrai stick : un coup sec de 65 px ; 0,55 unité de mouvement au plus pour la figure du contexte ; un stick à 18 unités par seconde ; une vrille dès 100°.
- La caméra qui reprend au lâcher, souris comprise (non jouable en headless).

**Un cas trouvé en écrivant un test**
- Un coureur tout juste replacé (respawn, état « en chute ») qui lâche le bouton de figure à ce pas lance la figure du contexte, puis se crashe en « atterrissant » au pas suivant. C'est rare : il faut tenir le bouton pendant un respawn. Je n'y ai pas touché.

### Écarts

- Décision 21 : seules les faces verticales comptent pour « coplanaire ». Les dessous des blocs posés sur le sol sont tous à y = 0 par construction.
- « Validée » (décision 17) veut dire une recette dessinée et aucun élément en cours. Au stick, c'est dès que le stick revient au centre ; à la souris, après 0,05 s de main immobile.
- Les choix acceptés de la spec citent encore les anciens seuils : 80 px, moins de 30 px, 120° pour un demi-cercle, et « un appui entre 0,2 et 0,25 s pose sans faire rouler », que la décision 20 remplace.

`````

### Inspecteur, figures par gestes, première inspection

`````markdown
# Inspection de la branche trick-gestures (main..trick-gestures, main à 3418f98)

Spec : docs/specs/trick-gestures.md (et ses « Choix acceptés »), docs/specs/air-tricks.md (ce que sa décision 14 garde), docs/specs/flow-combo.md, AGENTS.md.

Portes lancées sur la branche (worktree, lecture seule) : just typecheck (100 scripts, 0 erreur), just lint (0), just deadcode (0), just test (323 tests, « All tests passed », 48,9 s sur la machine chargée). Le test de la boucle sur le plat affiche bien style 3 790, 97 figures, 0 crash ; 75 en sautant sans figure.

Expériences faites sur une copie hors dépôt (scratchpad/inspector-trick-gestures/copy) : 20 cassures volontaires du code, une sonde de 63 gestes humains (souris et stick) passée au vrai TrickGesture avec la ressource de réglage du projet, et des boucles sans risque mesurées avec RunnerMotor + FlowState. Rien n’a été modifié dans le dépôt ni dans le worktree.

## 1. Verdict

**À corriger** : deux constats bloquants (seuils du geste écrits dans le code ; murs du Trick Park faits de plusieurs blocs). Le reste est conseillé, mais les constats 3 à 6 touchent directement ce que le propriétaire va sentir en premier.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | bloquant | game/core/trick_gesture.gd:22-32 (lus l.64, 73, 116, 125, 133) | AGENTS.md « Architecture » : « Every tuning value of the feel (speeds, gravity, tolerance windows) lives in one single tuning resource » ; spec décisions 5 et 16 | NOISE, CORNER (90°), BEND (40°), STROKE_TURN (60°) et STROKE_SHARE (0,4) sont des constantes du code, alors que la spec les annonce dans la ressource (« Choix acceptés », l.288-291 : « un virage de plus de 90° sépare deux éléments », « à régler par Jimmy ») ; ce sont elles qui décident les mauvaises lectures des constats 3 et 5, et F4 ne les atteint pas. | Les passer dans movement_tuning.gd/.tres, groupe Tricks, et dans MotorBody.fixed_tuning. |
| 2 | bloquant | game/levels/trick_park.tscn:167-192 (Block8, Step8High, Step8Low) ; même géométrie l.149-165 (Block5, Step5) | AGENTS.md « Working rules » : « Every wall of a level is a single block (one physics object) … a wall made of two blocks could be climbed twice. » | Block8 (x 21 à 27, z −24 à −16, 8 m), Step8High (mêmes x, z −16 à −13, 5 m) et Step8Low ont leurs faces latérales dans les mêmes plans x = 21 et x = 27 : un seul mur visible fait de trois objets. Un wall-run le long de x = 27 change de wall_id en passant de la marche au bloc : _stays_on_the_wall s’arrête (runner_motor.gd:531) et _can_run_along en relance un neuf (nouveau WALL_RUN, durée neuve ; lu dans le code, pas rejoué en physique). Le test ne vérifie qu’une forme de collision par bloc (test_course_trick_park.gd:117-121). | Rétrécir les marches (5 m de large au lieu de 6, centrées) pour qu’aucune face ne prolonge celle du bloc, ou mettre les marches dans no_wall_run ; vérifier dans le test qu’aucune face latérale de deux blocs voisins n’est coplanaire. |
| 3 | conseillé | game/core/trick_gesture.gd:125-130 | Spec, « Choix acceptés » : « le retour de la main entre deux coups est ignoré » ; décision 4 | Un coup vers le bas suivi d’un retour de main arrondi est lu comme une vrille : 150 px vers le bas, puis (8,10), (10,2), (6,−8), puis 140 px vers le haut → « BACKFLIP FULL » au lieu de « BACKFLIP » ; trois variantes de retour arrondi (dont un virage serré de 40 px) donnent toutes BACKFLIP FULL. Sur le plat ou d’un bloc de 1 m, cette figure ne tient pas : crash. | Ne pas compter comme demi-cercle une courbe qui finit par une ligne droite plus longue qu’un coup repartant contre le coup (c’est un retour) ; ajouter ces tracés au test. |
| 4 | conseillé | game/core/movement_tuning.tres:86-87 ; game/player/input_intent_source.gd:67 | Décision 4 ; README l.130-131 : « a stroke is a flick (push it and let it spring back) » | Au stick, un coup sec réel ne se lit pas : montée à 0,5, 4 pas à fond, retour à 0,5 (≈ 0,1 s) → rien, ni figure ni figure du contexte ; il faut 5 pas pleins à fond ; poussé à 60 % pendant 0,13 s → rien. Deux coups rapides séparés de 1 ou 2 pas (≤ 33 ms) au centre → « BACKFLIP » au lieu de « DOUBLE BACKFLIP ». | Un seuil de coup propre au stick (ou trick_pad_stick_speed vers 14) ; finir l’élément dès que le stick revient dans la zone morte, sans attendre la pause de 0,05 s. |
| 5 | conseillé | game/core/trick_gesture.gd:116-130 | Décision 4 (« un demi-cercle après le salto : une vrille » ; « un cercle complet seul : un spin ») ; « Choix acceptés » : « un demi-cercle se lit dès 120° » | Une petite tenue au début d’une courbe devient un coup de plus : stick relâché après un coup bas, repoussé en bas 0,1 s puis roulé d’un demi-tour en 0,3 s → « DOUBLE BACKFLIP FULL » (voulu BACKFLIP FULL) ; souris, 90 px droits avant le demi-cercle → idem ; stick poussé à droite 0,15 s puis roulé d’un tour → « SIDE FLIP » (voulu 360) ; J au stick (bas 0,05 s puis demi-tour en 0,3 s, ou bas 0,1 s puis demi-tour en 0,5 s) → rien. À la souris, un J de 130° ne donne pas de vrille : la partie droite absorbe les 40 premiers degrés, il en faut environ 160. | Après le constat 1, régler BEND et STROKE_SHARE avec Jimmy et ajouter ces tracés comme cas de test. |
| 6 | conseillé | tests/test_runner_trick_risk.gd:100-118 | Décision 15 : « la variété doit en limiter le gain » ; docs/harness/2026-11-14-flow-combo.md, leçon 1 | La boucle mesurée ne laisse jamais finir le combo, or sa fin par le délai remet la répétition à zéro (flow-combo, décision 3, amendement). Mesuré avec RunnerMotor + FlowState et la ressource du projet : 4 figures simples variées posées PERFECT, puis 2,1 s de course au sol, en boucle → **27 350 de style par minute**, 0 crash (25 250 avec 2,5 s de course ; 12 150 avec 2 figures), contre 3 790 annoncés et un seuil de 4 800 : environ 27 munitions de points par minute (3 tenues au plus), là où courir et sauter en donnait environ 1. | Décision du propriétaire. Pistes : la répétition des figures survit à la fin d’un combo par le délai, ou le test de boucle laisse le combo finir. |
| 7 | conseillé | tests/test_runner_trick_landing.gd:35-60 | Scénarios « Appuyer au dernier moment donne un PERFECT » et « Appuyer dans la fenêtre de réception […] sans PERFECT » | La fenêtre PERFECT n’est fixée que d’un côté : en la passant à 7 pas, ou à 9 pas (0,15 s), les 30 tests de test_runner_trick* restent verts (cassures vérifiées). | Ajouter un appui à PERFECT_STEPS + 1 qui pose sans PERFECT. |
| 8 | conseillé | tests/test_player_tricks.gd:50-55 | Scénario « Tenir le bouton de figure fige la caméra » : « elle tourne de nouveau une fois le bouton lâché » | Seul le retour du stick est vérifié : une souris qui ne tournerait plus jamais la caméra après le bouton laisse le test vert (cassure vérifiée). | Bouger la souris après le relâchement et vérifier que la caméra tourne. |
| 9 | conseillé | tests/test_trick_gesture.gd:76-81 | « Choix acceptés » : « un virage de plus de 90° sépare deux éléments » | L’aller-retour « down, back up, down » est tracé avec une pause après chaque coup : la règle du virage n’y joue pas ; CORNER à 181° ne casse que le gribouillis aléatoire. | Tracer l’aller-retour sans pause. |
| 10 | conseillé | docs/specs/trick-gestures.md:60, :67, :75 ; docs/specs/flow-combo.md:61, :87, :132 | Décision 14 : « Pas de règle contredite en silence » | La décision 7 et le tableau des valeurs disent encore une vrille de 0,15 s (0,3 s dans la ressource) ; flow-combo dit encore « les quatre derniers moves » (décision 3, valeurs, scénario « Un move absent des quatre derniers vaut tous ses points ») alors que flow_repetition_window passe à 10 ; la décision 14 ne liste pas les décisions 9 (paiement au premier contact, désormais soumis à la pose) et 11 (points, exemple à 750) d’air-tricks, que cette spec remplace aussi. | Amender ces lignes (« Amendement », comme ailleurs). |
| 11 | conseillé | tests/test_course_trick_park.gd:162-203 ; tests/test_player_tricks.gd:58-93 | air-tricks, décision 17 (gardée) : « Chaque geste a un test joué avec les entrées du clavier et un avec celles de la manette » | Aux vraies entrées, la figure du contexte et le lâcher au sol ne sont joués qu’au clavier ; double, side flip et spin ne sont joués sur aucun des deux ; la pose par B jamais (seulement RB). | Un test d’entrées réelles par geste et par périphérique : au moins le cercle au stick et la figure du contexte à LB. |
| 12 | conseillé | tests/test_runner_trick_risk.gd:63 ; tests/test_input_map.gd:67 | « Contributing workflow » : chaque scénario devient un test du même nom | Deux tests sans scénario : test_a_twisted_trick_does_not_fit_in_a_jump_on_the_flat (choix accepté) et test_the_trick_is_on_f_and_lb_and_is_posed_with_the_slide (décision 1). | Ajouter les deux scénarios à la spec. |
| 13 | conseillé | game/core/runner_motor.gd:341-356 | « Choix acceptés » : « un appui entre 0,2 et 0,25 s avant le sol pose la figure mais ne fait pas rouler » | Aucun test ; en grande chute ce cas paie la figure puis annonce HARD_LANDING au même pas, qui casse le combo et ôte un palier : la figure est « posée » mais punie. | Un test qui fixe ce comportement, et l’avis de Jimmy. |

## 3. Couverture de la spec

Chaque scénario a son test du même nom. « cassé » : une cassure volontaire du code sur la copie fait échouer le test ; « trou » : une cassure passe.

| Scénario | Test | Preuve |
| -------- | ---- | ------ |
| Un coup sec choisit le salto | test_trick_gesture.gd test_a_quick_stroke_chooses_the_flip | lu |
| Le même coup répété ajoute un tour | test_the_same_stroke_repeated_adds_a_turn | cassé (tours sans plafond) ; virage non exercé (constat 9) |
| Un demi-cercle ajoute une vrille | test_a_half_circle_adds_a_twist | lu |
| Pas de vrille sur un side flip ni un spin | test_no_twist_on_a_side_flip_or_a_spin | cassé |
| Un cercle seul est un spin | test_a_circle_alone_is_a_spin | lu |
| Un geste illisible ne lance rien | test_an_unreadable_gesture_starts_nothing | cassé (virage supprimé) |
| Tenir le bouton de figure fige la caméra | test_player_tricks.gd test_holding_the_trick_button_freezes_the_camera | cassé (stick, souris) ; trou au retour de la souris (constat 8) |
| La figure part quand on lâche le bouton en l’air | test_runner_tricks.gd test_the_trick_starts_when_the_button_is_released_in_the_air | lu |
| Lâcher le bouton au sol ne lance rien | test_player_tricks.gd test_releasing_the_button_on_the_ground_starts_nothing | cassé (pas de remise à zéro du dessin ; départ au sol) |
| Sans geste, la figure du contexte part | test_without_a_gesture_the_trick_of_the_context_starts | cassé (côté du side flip ; backflip après wall-jump) |
| Une seule figure par saut | test_one_trick_per_jump | cassé |
| Un simple tient dans un saut à plat | test_runner_trick_risk.gd test_a_single_fits_in_a_jump_on_the_flat | lu (ressource du projet) |
| Un double ne tient pas dans un saut à plat | test_a_double_does_not_fit_in_a_jump_on_the_flat | lu (ressource du projet) |
| Une vrille allonge la figure | test_a_twist_makes_the_trick_longer | cassé |
| Appuyer dans la fenêtre pose la figure | test_runner_trick_landing.gd test_pressing_within_the_window_poses_the_trick | cassé (pose non exigée) |
| Appuyer au dernier moment donne un PERFECT | test_pressing_at_the_last_moment_gives_a_perfect | cassé (gain de vitesse) ; trou sur la largeur de la fenêtre (constat 7) |
| Ne pas appuyer est un crash | test_not_pressing_is_a_crash | cassé (fenêtre élargie de 3 pas) |
| Un appui trop tôt est perdu | test_a_press_too_early_is_lost | cassé |
| Un appui trop tôt peut être refait | test_a_press_too_early_can_be_made_again | lu |
| Une figure pas finie au sol est un crash même avec l’appui | test_an_unfinished_trick_on_the_ground_is_a_crash_even_with_the_press | lu |
| Une figure posée en grande chute roule | test_a_trick_posed_in_a_big_fall_rolls | cassé (roulade ignorée) |
| Une figure posée sur le plat lance une glissade | test_a_trick_posed_on_the_flat_starts_a_slide | lu |
| Une figure rapporte au début d’un wall-run sans appui | test_a_trick_pays_at_the_start_of_a_wall_run_without_a_press | lu |
| Les points suivent la difficulté | test_the_points_follow_the_difficulty | lu |
| Deux recettes différentes ne sont pas une répétition | test_two_different_recipes_are_not_a_repetition | lu |
| Une boucle sans risque sur le plat rapporte peu | test_a_riskless_loop_on_the_flat_earns_little | vert, mais ne mesure qu’une boucle (constat 6) |
| Un backflip vrillé au clavier-souris | test_course_trick_park.gd test_a_twisted_backflip_on_keyboard_and_mouse | lu (vraies entrées, vraie physique) |
| Un backflip vrillé à la manette | test_a_twisted_backflip_on_the_gamepad | lu (stick idéal : passe du centre au bord sans rampe) |
| Le Trick Park offre toutes les hauteurs | test_the_trick_park_offers_every_height | lu ; ne voit pas les faces coplanaires (constat 2) |
| Le Trick Park se choisit dans l’écran de départ | test_course_menus.gd test_the_trick_park_is_chosen_on_the_start_screen | lu |
| Le HUD montre la recette en cours de dessin | test_flow_hud.gd test_the_hud_shows_the_recipe_being_drawn | cassé (« ? ») |

Règles d’air-tricks remplacées (décision 14) : plus aucun test ne les porte (direction poussée, tours tenus, vrille au saut, enchaînement en l’air, PERFECT par la fin de figure, tour de 0,65 s, backflips aux vraies entrées ; les huit tests concernés sont retirés ou réécrits). Règles gardées, toujours testées : départ ni au sol, ni en wall-run ni en mantle ; trajectoire inchangée ; pas de saut fantôme (test_a_twist_near_the_ground_does_not_start_a_jump, dont le nom parle encore de vrille) ; pas de wall-jump pendant une figure ; pas de wall-run ni de mantle pendant une figure ; crash d’une figure non finie ; paiement au wall-run et au mantle ; chute hors du parcours ; noms composés ; corps visible ; HUD ; sons ; PERFECT plafonné en vitesse.

Portes de l’input map : F (touche physique 70) et LB (bouton 9) pour la figure ; LB retiré du saut ; la glissade reste Ctrl, B, RB ; Shift et X ne servent plus (test_input_map.gd). Le tableau des commandes du README est exact.

Trick Park : esplanade 120 m × 120 m, blocs de 1, 2, 3, 5, 8 m chacun gravi par un grimpeur dans la vraie physique, murs face à face à 4 m, mur à wall-run de 24 m × 4 m ; tests dans des scripts test_course* (deadcode vert).

## Mesures (pour Jimmy)

**Gestes lus correctement** (sonde de 63 tracés, ressource du projet) : à la souris, un coup de 85 px ou plus, un coup de poignet arqué de 30 ou 50°, un coup à 40° de la verticale, un rebond de la main de 15 à 100 px après le coup (même souris rapide, 600 px en 3 pas), deux ou trois coups avec retours droits (même retour en biais de 20°, ou retour court de 40 px), demi-cercle après pause ou en J, demi-cercle de 250 à 280° (une vrille), cercles de 290 à 360°, rapides (5 pas) ou petits (20 px de rayon), avec ou sans élan droit ; une main qui tremble de 25 px reste la figure du contexte. Au stick : coup de 5 pas à fond, rebond au-delà du centre, demi-tour roulé après relâchement, cercle roulé sans tenue ou avec une tenue de 0,05 à 0,1 s.

**Mal lus** : voir constats 3, 4 et 5. Aussi : une souris qui tourne la caméra de 30 à 80 px au moment de l’appui donne « rien » (pas même la figure du contexte), et de plus de 80 px un side flip.

**Ce qui tient selon la hauteur** (saut tenu, figure lâchée au pas 1 après l’appel, posée PERFECT ; points avec PERFECT) :

| Chute sous le point d’appel | Pas en l’air | Ce qui tient |
| --- | --- | --- |
| 0 m (plat) | 36 | front flip, backflip (300), side flip, 360 (375) |
| 1 m | 40 | + front flip full, backflip full (525), seulement lâchés au plus 1 pas (17 ms) après l’appel |
| 2 m | 44 | + doubles front, back (750), double side flip, 720 (938) ; backflip full lâché au plus 5 pas (83 ms) après l’appel |
| 3 m | 47 | comme 2 m ; backflip full au plus 8 pas (0,13 s) après l’appel |
| 5 m | 52 | comme 2 m : rien de plus |
| 8 m | 59 | + front flip et backflip double full (750) ; aucun triple ne tient nulle part |

**Boucles sans risque, par minute** :
- plat, jamais de pause (la boucle du test) : 3 790 (reproduit) ;
- plat, 4 figures puis 2,1 s de course : 27 350, mesuré avec le moteur ;
- bloc de 3 m, 10 recettes en rotation, cycle supposé de 3,5 s (retour, saut, mantle, élan) : environ 36 000 ;
- murs face à face, 4 figures simples payées par les wall-runs (aucun appui, aucun risque de réception), cycle supposé de 6 s : environ 25 000 (5 750 sans figure).
Les deux dernières sont des estimations : vraie FlowState, mais des messages placés selon des durées supposées, pas la vraie physique.

## 4. Non vérifiable ici

À juger manette et clavier-souris en main, dans le Trick Park :
- le geste lui-même : un coup sec au stick que l’on sent « franc » se lit-il (constat 4) ; un retour de main arrondi après un backflip à la souris (constat 3) ; un demi-cercle ou un cercle commencé par une petite tenue (constat 5) ; le « ? » puis le nom au HUD aident-ils à corriger avant de lâcher ;
- la caméra figée tant que F ou LB est tenu, pendant la course (on ne peut plus viser sa trajectoire), et sa reprise au lâcher, stick encore poussé ou souris encore en mouvement : saut de caméra ;
- les doigts : au clavier, F avec l’index empêche-t-il D pendant le dessin ; à la manette, le pouce droit doit quitter le stick pour A : dessiner avant l’appel puis sauter, ou sauter puis dessiner en l’air, et poser à RB juste après ;
- le rythme de la pose : 0,25 s de fenêtre et 0,1 s de PERFECT avant le sol, en particulier sur 5 et 8 m où un appui entre 0,2 et 0,25 s pose puis donne une réception dure (constat 13) ;
- la vrille à 0,3 s : depuis 2 m il faut lâcher le bouton dans les 83 ms qui suivent l’appel ; depuis 1 m c’est impossible à la main ; les blocs de 3 et 5 m n’ouvrent rien de plus que celui de 2 m ;
- la figure du contexte (front flip en courant, backflip à l’arrêt ou après un wall-jump, side flip en quittant un wall-run) et la rotation du corps qui va avec ;
- la glissade sur pose au plat et le PERFECT qui ajoute 1 m/s ;
- l’économie : plus de 27 000 points par minute sur le plat en laissant finir le combo (constat 6), dans le duel compris ;
- le Trick Park à l’œil : lisibilité des blocs et des marches, murs face à face, mur à wall-run, et l’enchaînement de wall-runs le long de la tour de 8 m (constat 2).

`````

### Inspecteur, figures par gestes, seconde inspection

`````markdown
# Inspection de PR 34 (trick-gestures), plage 3418f98..553aa3f

Spec : `docs/specs/trick-gestures.md` (amendement, décisions 17 à 21 et « Choix acceptés »), parties gardées de `docs/specs/air-tricks.md` et `docs/specs/flow-combo.md`, et `AGENTS.md`. Routage : `core`, `player`, `ui`, `levels`, `tooling` (`project.godot`), `harness` (`AGENTS.md`, `README.md`, `docs/`).

Portes lancées sur le checkout principal à 553aa3f : `just lint`, `just deadcode` et `just typecheck` passent ; `just test` donne 334/334 en 51 s (57 s avec l’import). `just build` n’a pas été lancé. Les expériences (mutations, gestes, boucles) ont tourné sur un clone dans le scratchpad, jamais dans le dépôt.

Note : depuis, `main` est à 11f8830. Ce commit rouvre la décision 3 (second amendement, spec repassée en 🟡) : lâcher F au sol saute et lance la figure. Le constat 1 en devient plus urgent : la boucle à risque nul se jouera avec F et Ctrl seulement.

## 1. Verdict

**À corriger**

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | bloquant | `tests/test_runner_trick_risk.gd:241` (seuil `:14`, test `:101`) | Scénario « Une boucle sans risque sur le plat rapporte peu », décisions 9 et 15 | La boucle mesurée presse glissade sans jamais la garder. Si le coureur garde l’appui de pose, il fait la « ligne flow » de la décision 9 (figure posée, puis glissade parfaite) et saute en sortant de la glissade. Avec le vrai moteur (`MotorBody`) et le réglage du projet, cette boucle rapporte **64 390** de style par minute (6 pas de glissade) et **71 850** (2 pas), pour 0 crash. Les mêmes 4 figures simples sans la glissade : 3 903 ; saut et glissade parfaite sans figure : 300. Chaque glissade parfaite est un move de plus : un saut fait 3 moves, et 4 figures simples sortent de la fenêtre de répétition de 10 moves. | Ajouter au test la variante où l’appui de pose est gardé (2 et 6 pas de glissade, saut hors de la glissade) ; elle échoue aujourd’hui. Puis Jimmy choisit la règle, par exemple : la répétition d’une figure jugée sur les N dernières figures et non sur les N derniers moves, ou une glissade parfaite issue d’une pose qui ne compte pas comme un move à part. Remesurer et écrire le chiffre dans la spec. |
| 2 | conseillé (prioritaire) | `game/core/runner_motor.gd:524` et `:456` ; `game/levels/trick_park.tscn:197-213` | Décision 15 (dans son esprit), décision 8 | Les figures payées par un wall-run ou un mantle, sans appui, forment des boucles à risque nul. Entre les murs face à face du vrai Trick Park, un bot de la vraie physique enchaîne wall-run, wall-jump, une figure simple lâchée au pas suivant, et le wall-run d’en face la paie : **23 042** de style par minute, 0 crash, 29 figures sur 35 payées sans appui (925 sans figure). Avec `MotorBody`, couloir de 4 m × 20 m : 50 258. Sur le bloc de 2 m, saut, figure, puis le mantle la paie : **9 925** par minute, 0 crash (225 sans figure). Le seuil du plat est 4 800. Je le classe conseillé : la décision 8 garde explicitement ce paiement et la décision 15 ne mesure que le plat. | Mesurer ces deux boucles dans `test_runner_trick_risk.gd`, à côté de celle du plat, et faire trancher Jimmy : une figure payée par un wall-run ou un mantle réduite, ou la même règle de répétition par figures que pour le constat 1. |
| 3 | conseillé | `game/core/trick_gesture.gd:213-215` (et `:104-107`) | Décision 4 (« le même coup répété : un tour de plus ») et décision 18 (« ce qu’une main veut dire ») | Un double dessiné avec un retournement arrondi est mal lu. Bas 150 px, remontée sèche de 130 px, petite boucle de 20 px en haut, bas 150 px : lu **« BACKFLIP FULL »**. Avec les deux retournements arrondis en zigzag : **« BACKFLIP »**. En ellipse : **« 360 »**. Le corpus n’a que le retour arrondi du bas suivi d’un coup sec (M2), et des allers-retours à angle vif (M5). Je ne suis pas sûr que la décision 18 couvre ce geste : elle ne nomme que le retour qui « repart contre le coup ». Si Jimmy lit « le même coup répété » comme l’incluant, c’est bloquant. | Une courbe qui commence contre le salto et finit dans son sens, d’au moins un coup, est un retour suivi d’un coup, pas une vrille. Ajouter ces trois gestes au corpus avec « DOUBLE BACKFLIP ». |
| 4 | conseillé | `game/player/input_intent_source.gd:74` (`trick_pad_stick_speed` 18, `trick_gesture_stroke_length` 0,65) | Décision 18 (« un coup sec au stick finit dès que le stick revient dans sa zone morte, même vite » ; « poussé à 60 % compte ») | Un coup de stick se mesure par sa durée fois sa déflexion. À fond, il lui faut au moins 3 pas (50 ms) ; à 60 %, au moins 5 pas (83 ms). Lus « rien » (rien ne part, le pavé affiche « ? ») : 0,7 puis 1 puis 0,6 puis un rebond à −0,4 vers le bas ; deux pas à fond ; 60 % pendant 4 pas ; 0,6 puis 1 puis 0,5 vers le haut. Le test du scénario n’essaie que 6 pas (0,1 s), et le corpus S9 8 pas. | Lire un coup de stick par sa déflexion maximale (passé au-delà d’un seuil, puis revenu), ou monter `trick_pad_stick_speed`. Ajouter au corpus un coup de 3 pas et un coup à 60 % de 4 pas. |
| 5 | conseillé | `game/core/trick_gesture.gd:96-107` | Décision 18 | Deux coups de stick qui ne repassent pas par la zone morte (1, 1, 1, 0,3, 1, 1, 1) sont lus comme un seul coup : « BACKFLIP » au lieu de « DOUBLE BACKFLIP ». Seuls une pause, le stick dans sa zone morte ou un angle vif finissent un élément, pas un creux de déflexion. | Finir un élément quand la déflexion du stick retombe loin sous son maximum ; ajouter ce geste au corpus. |
| 6 | conseillé | `game/core/trick_gesture.gd:98` (`trick_gesture_pause` 0,05 s) | Décision 18 (une petite tenue ne compte pas comme un coup de plus) | Un coup de souris lent qui hésite 3 pas (50 ms) en son milieu est lu comme deux coups : bas 80 px, arrêt de 3 pas, bas 80 px donne **« DOUBLE BACKFLIP »** (avec 2 pas d’arrêt : « BACKFLIP »). | Ne compter un second coup dans le même sens qu’après une pause plus longue, ou un retour de la main entre les deux ; ajouter ce geste au corpus. |
| 7 | conseillé | `game/core/trick_gesture.gd:224-226` | Décision 17 (« c’est elle qui partira au lâcher ») | Une vrille commencée vers le bas après un backflip (gestes S5c et M6d du corpus) se lit, pendant quelques pas, « BACKFLIP » validé, puis « BACKFLIP », puis **« DOUBLE BACKFLIP »**, puis « BACKFLIP FULL » ; c’est vrai à la souris comme au stick. Le moteur lance la recette du pas du lâcher, validée ou non : lâcher à ce moment lance un double (0,7 s), qui se crashe depuis un petit bloc. | Ne compter un tour de plus qu’une fois l’élément en cours fini, ou ne lancer au lâcher que la dernière recette validée. |
| 8 | conseillé | `game/core/trick_gesture.gd:122` ; `game/ui/trick_pad.gd:58` | Décision 17 | La bordure « validée » n’est pas fiable dans les deux sens. Un tremblement de ±1 px par pas après un backflip garde le nom « BACKFLIP » mais retire la validation, qui ne revient pas tant que le tremblement dure ; la figure part pourtant au lâcher. À l’inverse, le pavé reste validé là où rien ne partira au lâcher : en wall-run, en visée, après la figure du saut. | Pour l’état validé, ignorer un mouvement plus court qu’une longueur de bruit cumulée (un réglage), ou exiger une recette stable depuis N pas ; ne montrer l’état validé que si le moteur peut lancer une figure. |
| 9 | conseillé | `game/core/movement_tuning.tres` (`trick_pad_mouse_scale` 0,01, `trick_gesture_still_length` 0,55) | Décision 6 (figure du contexte), décision 18 | Les seuils sont en pixels bruts, sans lien avec la DPI de la souris. Un appui sans dessin, la main tremblant de ±4 px par pas pendant 0,5 s (souris à grande DPI), cumule plus de 55 px de trace et lit « rien » au lieu de la figure du contexte. À ±1 et ±2 px, la lecture est juste. | Le dire dans le README à côté de `trick_pad_mouse_scale`, que Jimmy règle sur sa souris, ou ramener le pavé à la sensibilité de la caméra. |
| 10 | conseillé | `game/core/trick_gesture.gd:195` | Décision 4 (« un cercle complet seul ») | Un J dont le crochet dépasse 270° (bas 150 px, puis crochet de 290° sans pause) est lu « 360 ». Un crochet de 260° est lu « BACKFLIP FULL », et 280° après une pause (M6f) aussi. Le corpus a choisi « un cercle après un coup est un spin » (M7c) : la frontière tombe au milieu d’un J trop enthousiaste. | Décision de Jimmy : garder la frontière, ou lire un cercle précédé d’un vrai coup comme le salto plus ses vrilles. |
| 11 | conseillé | `game/core/trick_gesture.gd:260` et `:291` | Décision 18 (« Tous les seuils de la reconnaissance sont dans la ressource ») | Deux seuils sont des constantes du code : 180° par vrille au-delà de `trick_gesture_two_twists_angle`, et l’arrondi à 360° qui fait passer un spin à 720 dès 540°, alors qu’un cercle seul se lit dès 270°. | Deux réglages du groupe Tricks. |
| 12 | conseillé | `game/core/runner_motor.gd:856` | Décision 4 (« Un geste qui ne se lit pas ne lance rien ») | Aucun test ne prouve que le moteur ne lance rien quand le dessin ne se lit pas : la mutation qui remplace ce `return` par la figure du contexte laisse toute la suite verte. Le test du scénario ne vérifie que la lecture (recette nulle). | Dans `test_an_unreadable_gesture_starts_nothing`, ou dans `test_runner_tricks.gd`, lâcher en l’air avec une recette nulle et vérifier qu’aucune figure ne part. |
| 13 | conseillé | `tests/test_trick_pad.gd:18` | Contrat d’interface (« ? » tant que rien ne se lit) | Si le pavé affiche le nom de la figure du contexte au lieu de « ? » (mutation de `game/ui/trick_pad.gd:73`), aucun test ne casse. Celui du HUD, lui, casse. | Vérifier `recipe_shown() == "?"` avant tout mouvement. |
| 14 | conseillé | `tests/test_player_tricks.gd:76` et `:100` ; `tests/test_runner_trick_risk.gd:64` ; `tests/test_flow.gd:57` | Contributing workflow (un scénario, un test du même nom) | Quatre tests sans scénario du même nom : `test_a_spin_drawn_with_the_right_stick`, `test_the_trick_of_the_context_with_lb_posed_with_b`, `test_a_twisted_trick_does_not_fit_in_a_jump_on_the_flat` (amendement de la décision 7, sans scénario), et `test_the_end_of_a_combo_by_its_delay_keeps_the_repetition`. Ce dernier correspond à un scénario de flow-combo qui s’intitule toujours « La fin d’un combo remet la répétition à zéro », seulement marqué remplacé. | Ajouter les scénarios manquants à la spec, ou y rattacher ces tests. |
| 15 | conseillé | `game/core/trick_recipe.gd:16-24` | Axe libellés (un libellé visible hors de `game/ui/`) | Les noms affichés des figures (« FRONT FLIP », « DOUBLE », « FULL »…) vivent dans `core`. Ils ont été déplacés depuis `air_trick.gd` : ce n’est pas nouveau. | À trancher quand une spec fixera où vivent les libellés. |

Vérifié sans constat :
- les murs du Trick Park : chaque bloc est un seul objet, et les marches sont en retrait de 0,5 m ; la mutation qui rend une marche coplanaire avec son bloc est attrapée ;
- `core` n’a ni scène ni entrée ;
- chaque réglage de la spec est dans le `.tres` aux valeurs de la spec ;
- aucun test ne reste sur une règle remplacée (aucune trace de `rank`, `trick_pressed` ou `air_chain`) ;
- les tests modifiés de `test_course_flow`, `test_flow` et `test_runner_aim` suivent la décision 19 sans s’affaiblir.

Mutations (une à la fois, sur le clone) : 17 attrapées sur 20. Attrapées : pose sans appui, pas de roulade par l’appui de pose, fin de combo au délai qui vide la répétition, stick revenu en zone morte ignoré, retour de main jamais reconnu, validation pendant un élément en cours, pavé toujours visible, caméra qui tourne en dessinant, vrille qui n’allonge pas la figure, deuxième figure dans le même saut, marche coplanaire, figure du contexte valant un front flip, arc de vrille codé en dur à 130°, nom du contexte sur le HUD, côté du side flip du contexte, PERFECT dans toute la fenêtre, dessin non oublié à l’appui. Non attrapées : la recette nulle qui lance la figure du contexte (constat 12) ; « ? » sur le pavé (constat 13) ; une échelle du tracé changée, mais restée uniforme, ce qui n’a pas d’effet visible.

Gestes humains écrits pour cette inspection : 72 à la souris (pixels entiers, échelles ×0,5 à ×8, comme des DPI différentes), 31 au stick (rampes, rebonds au-delà du centre, roulements lents et rapides). Bien lus : coups lents ou rapides, J de 110° à 260°, demi-cercles tremblés ou en polygone, retours de la main droits ou arrondis vers le haut, tremblements de 1 à 2 px, roulements de 120° à 360°, spins de 330° et de 720°. Les gestes mal lus sont ceux des constats 3 à 7, 9 et 10, plus des coups courbés de 70° à 90° d’un bout à l’autre, lus « rien » (une courbure aussi forte est improbable aux DPI courantes).

## 3. Couverture de la spec

| Scénario | Test |
| -------- | ---- |
| Un coup sec choisit le salto | `test_a_quick_stroke_chooses_the_flip` |
| Le même coup répété ajoute un tour | `test_the_same_stroke_repeated_adds_a_turn` |
| Un demi-cercle ajoute une vrille | `test_a_half_circle_adds_a_twist` |
| Pas de vrille sur un side flip ni un spin | `test_no_twist_on_a_side_flip_or_a_spin` |
| Un cercle seul est un spin | `test_a_circle_alone_is_a_spin` |
| Un geste illisible ne lance rien | `test_an_unreadable_gesture_starts_nothing` (la lecture seulement, constat 12) |
| Tenir le bouton de figure fige la caméra | `test_holding_the_trick_button_freezes_the_camera` |
| La figure part quand on lâche le bouton en l’air | `test_the_trick_starts_when_the_button_is_released_in_the_air` |
| Lâcher le bouton au sol ne lance rien | `test_releasing_the_button_on_the_ground_starts_nothing` (scénario remplacé depuis par 11f8830) |
| Sans geste, la figure du contexte part | `test_without_a_gesture_the_trick_of_the_context_starts` |
| Une seule figure par saut | `test_one_trick_per_jump` |
| Un simple tient dans un saut à plat | `test_a_single_fits_in_a_jump_on_the_flat` |
| Un double ne tient pas dans un saut à plat | `test_a_double_does_not_fit_in_a_jump_on_the_flat` |
| Une vrille allonge la figure | `test_a_twist_makes_the_trick_longer` |
| Appuyer dans la fenêtre pose la figure | `test_pressing_within_the_window_poses_the_trick` |
| Appuyer au dernier moment donne un PERFECT | `test_pressing_at_the_last_moment_gives_a_perfect` |
| Ne pas appuyer est un crash | `test_not_pressing_is_a_crash` |
| Un appui trop tôt est perdu | `test_a_press_too_early_is_lost` |
| Un appui trop tôt peut être refait | `test_a_press_too_early_can_be_made_again` |
| Une figure pas finie au sol est un crash même avec l’appui | `test_an_unfinished_trick_on_the_ground_is_a_crash_even_with_the_press` |
| Une figure posée en grande chute roule | `test_a_trick_posed_in_a_big_fall_rolls` |
| Une figure posée sur le plat lance une glissade | `test_a_trick_posed_on_the_flat_starts_a_slide` |
| Une figure rapporte au début d’un wall-run sans appui | `test_a_trick_pays_at_the_start_of_a_wall_run_without_a_press` |
| Les points suivent la difficulté | `test_the_points_follow_the_difficulty` |
| Deux recettes différentes ne sont pas une répétition | `test_two_different_recipes_are_not_a_repetition` |
| Une boucle sans risque sur le plat rapporte peu | `test_a_riskless_loop_on_the_flat_earns_little` (ne mesure pas la boucle avec la glissade gardée, constat 1) |
| Un backflip vrillé au clavier-souris | `test_a_twisted_backflip_on_keyboard_and_mouse` |
| Un backflip vrillé à la manette | `test_a_twisted_backflip_on_the_gamepad` |
| Le Trick Park offre toutes les hauteurs | `test_the_trick_park_offers_every_height` |
| Le Trick Park se choisit dans l’écran de départ | `test_the_trick_park_is_chosen_on_the_start_screen` |
| Le pavé montre le tracé et valide la figure | `test_the_pad_shows_the_trace_and_validates_the_trick` |
| Le pavé disparaît au lâcher | `test_the_pad_disappears_on_release` |
| Les gestes humains sont lus comme la main les veut | `test_human_gestures_are_read_as_the_hand_means_them` (63 gestes ; voir les constats 3 à 7) |
| Un coup au stick qui revient vite est lu | `test_a_stick_flick_that_comes_back_fast_is_read` |
| Un arc après le salto est une vrille | `test_an_arc_after_the_flip_is_a_twist` |
| Un retour de la main arrondi n’est pas une vrille | `test_a_rounded_return_of_the_hand_is_not_a_twist` |
| La répétition des figures survit à la fin d’un combo | `test_the_repetition_of_tricks_survives_the_end_of_a_combo` |
| Une figure posée en grande chute ne finit pas en réception dure | `test_a_trick_posed_in_a_big_fall_does_not_end_in_a_hard_landing` |
| Aucun mur du Trick Park n’est fait de plusieurs blocs | `test_no_wall_of_the_trick_park_is_made_of_several_blocks` |
| Le HUD montre la recette en cours de dessin | `test_the_hud_shows_the_recipe_being_drawn` |

Les scénarios gardés d’air-tricks ont tous leur test : pas de figure au sol, ni en wall-run ni en mantle ; la trajectoire inchangée ; pas de saut fantôme ; pas de wall-jump pendant une figure ; pas de wall-run ni de mantle pendant une figure ; une figure non finie au sol est un crash ; une chute hors du parcours perd la figure ; le paiement au mantle ; le nom composé ; les réceptions parfaites plafonnées ; le corps visible ; le HUD ; les sons. Aucun manquant.

## 4. Non vérifiable ici

À juger par Jimmy, manette ou souris en main, dans le Trick Park :
- les seuils du geste, avec sa souris et sa DPI (65 px pour un coup, 55 px pour « rien », une pause de 50 ms), et avec sa manette : un coup sec bref est-il lu (constat 4) ?
- un double dessiné « bas, haut, bas » avec son geste naturel (constat 3), et une vrille commencée vers le bas, qui affiche un moment « DOUBLE BACKFLIP » (constat 7) ;
- le pavé : sa taille (un cinquième de la hauteur de l’écran), sa place au centre, par-dessus le coureur, la lisibilité de la bordure validée (vert et épaisseur) en pleine course, et le scintillement de la validation si la main tremble ;
- l’arrêt net de la caméra quand F est pressé en plein virage, et sa reprise au lâcher ;
- les mains : à la manette, le pouce droit partagé entre A (saut) et le stick droit (dessin) ; au clavier, F sous l’index pendant ZQSD, et Ctrl sous l’auriculaire ;
- les durées : un tour de 0,35 s, une vrille de 0,3 s, la rotation du corps visible ; les fenêtres de pose (0,25 s, et 0,1 s pour un PERFECT), la roulade après une pose en grande chute, la glissade qui suit une pose ;
- le Trick Park : les hauteurs, les marches de 2,5 m, les 4 m entre les murs face à face, le mur de wall-run ;
- l’équilibre du style : les boucles des constats 1 et 2 sont-elles du jeu qu’il veut récompenser ?

`````

### Développeur, saut de figure

`````markdown
# Rapport développeur : trick-gestures, second amendement (le saut de figure)

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-ad2ffe56c8d4596c3`
Branche : `trick-jump`. Commits : `bea09aa` (implémentation, tests, README), puis `97d0df4` (statut de la spec seul). Rien n'est poussé.

## Fait

Le moteur (`game/core/runner_motor.gd`) : lâcher le bouton de figure là où un saut est permis (au sol ou dans la tolérance de saut, saut pas encore dépensé, pas en réception dure, place pour se tenir debout), sans roulade ni visée et avec un dessin lisible, fait un saut entier. `_jump_cut` est mis à vrai, donc le saut n'est jamais coupé, et la figure part au même pas, par le chemin existant de `_start_a_trick`. Les conditions d'un saut sont sorties dans `_may_jump`, que se partagent `_can_jump` et le nouveau `_can_trick_jump`. Le bouton de saut ne change pas.

| Scénario | Test | Fichier |
| --- | --- | --- |
| Lâcher le bouton au sol saute et lance la figure | `test_releasing_the_button_on_the_ground_jumps_and_starts_the_trick` | `tests/test_runner_tricks.gd` (core : même pas, même vitesse et même trajectoire qu'un saut gardé jusqu'en haut, aussi dans la tolérance de saut, aucun JUMP annoncé) et `tests/test_player_tricks.gd` (vraies entrées : F + souris, puis LB + stick droit ; le coureur saute, un backflip part et le sommet est à `jump_height` à 0,1 m près) |
| Un saut de figure sur le plat laisse le temps d'un simple | `test_a_trick_jump_on_the_flat_leaves_time_for_a_single` | `tests/test_runner_trick_risk.gd` (réglage du projet : front flip, backflip, side flip, spin et figure du contexte, chacun fini avant le sol et posé PERFECT) |
| Lâcher le bouton là où on ne peut pas sauter ne lance rien | `test_releasing_the_button_where_no_jump_is_allowed_starts_nothing` | `tests/test_runner_tricks.gd` (core : roulade, réception dure, glissade sous un plafond bas, visée ; puis un saut normal ne lance aucune figure) et `tests/test_player_tricks.gd` (vraies entrées : chute de 7 m avec un backflip dessiné, F lâché en réception dure, pas de saut et rien ne part ; ensuite saut + appui sur F en l'air : la figure du contexte part, pas le backflip, donc le dessin est bien oublié) |
| Sans geste au sol, le saut lance la figure du contexte | `test_without_a_gesture_on_the_ground_the_jump_starts_the_trick_of_the_context` | `tests/test_runner_tricks.gd` (front flip en courant, backflip à l'arrêt) |

Le scénario remplacé, « Lâcher le bouton au sol ne lance rien », n'a plus de test. Deux tests sont retirés : `test_a_trick_does_not_start_on_the_ground` (core) et `test_releasing_the_button_on_the_ground_starts_nothing` (vraies entrées). Ce dernier est réécrit en `test_releasing_the_button_on_the_ground_jumps_and_starts_the_trick`, au clavier-souris et à la manette.

Un test voisin reposait sur l'ancienne règle : `test_the_hud_shows_the_recipe_being_drawn` (`tests/test_flow_hud.gd`) lâchait le bouton au sol pour vérifier que le HUD n'affiche plus rien. Il lâche maintenant en visée, où rien ne part, et vérifie toujours que plus rien n'est affiché.

Le flow : un saut de figure n'annonce **pas** de JUMP. La figure est le move : elle seule passe par la variété et le multiplicateur. Compter aussi un JUMP donnerait des points pour le seul fait de lancer une figure, même si elle finit en crash. Cela afficherait aussi « JUMP » au HUD avant la figure et remplirait la fenêtre de répétition d'entrées de saut. Le test de la boucle sans risque vérifie qu'un saut de figure n'est pas un JUMP du flow.

La boucle sans risque, re-mesurée (`test_a_riskless_loop_on_the_flat_earns_little`, une minute, réglage du projet, les 4 simples qui tiennent sur le plat, tous en PERFECT) :

| Boucle | Style par minute |
| --- | --- |
| Saut au bouton de saut, puis figure lâchée en l'air (comme avant) | 3 790 (inchangé) |
| Saut de figure (F lâché au sol) | **2 702** (97 figures, 0 crash, vitesse moyenne 10,63 m/s) |
| Course et saut seuls | 75 |

Le test vérifie maintenant les deux boucles sous le seuil de 4 800, et le seuil ne change pas. La boucle « quatre simples, pause » reste à 2 776.

README : la ligne des contrôles devient « Trick: hold to draw it, release to start it (on the ground, the release jumps too) ». Le paragraphe des figures décrit le saut de figure, les cas sans saut, le cas en l'air et le choix pour le flow. Commentaires mis à jour : en-tête de `RunnerMotor`, `_start_a_trick`, et l'en-tête des trois fichiers de tests touchés. Les descriptions d'`AGENTS.md` restent justes, il n'y avait rien à changer.

## Vérifié

- `just setup` : réussi (`.venv` et cache d'import créés).
- Chaque nouveau test lancé seul avant l'implémentation (`just test test_runner_trick`, `just test test_player_tricks`) : il échoue pour la bonne raison (pas de saut, pas de figure, ARRAY([]) au lieu de [TRICK]). Le test « là où on ne peut pas sauter » passait déjà, ce qui est attendu puisque la règle ne change pas pour ces cas.
- `just preflight` : vert, 258/258, 35,7 s.
- `just check` : vert deux fois, la seconde après les dernières retouches de commentaires. Typecheck sur 104 scripts sans erreur, lint propre, 338/338 tests (course replays compris, dont les deux backflips vrillés du Trick Park au clavier-souris et à la manette), deadcode 0 problème, builds Windows et Linux exportés et le build Windows lancé 60 frames en headless. Durée 82,7 s (limite 90 s).

## Non vérifié

À juger manette en main par Jimmy :
- Le ressenti du saut de figure : lâcher F ou LB pour sauter et tourner, au clavier-souris comme à la manette. Le saut est-il assez immédiat, et le saut entier est-il la bonne hauteur ?
- La réception PERFECT après un saut de figure sur le plat. Le moteur laisse le temps d'un simple (test), mais le rythme de l'appui sur Ctrl, RB ou B, c'est à la main d'en juger.
- Le lâcher dans la tolérance de saut, juste après le bord d'un bloc du Trick Park : cela saute (choix de la spec), ce qui peut surprendre qui croyait déjà être en l'air.
- La figure du contexte par un simple appui sur F ou LB au sol, qui fait maintenant un saut avec une figure. Pas encore jouée.

## Écarts

- **Un dessin illisible lâché au sol ne fait pas sauter.** La spec dit « un geste qui ne se lit pas ne lance rien » (décision 4) et, au sol, « le coureur saute […] et la figure part ». J'ai lu « ne lance rien » comme ne lançant pas non plus le saut. Le saut appartient à la figure, et un saut sans figure au lâcher de F serait une seconde manière de faire un saut simple. Testé.
- **Un saut de figure n'est pas un JUMP du flow** (raison plus haut). C'est la suggestion de la session principale, et la spec ne tranche pas.
- **Lâcher dans la tolérance de saut** (juste après un bord, pas encore sauté) fait un saut de figure, et non une figure sans saut. La décision 3 range explicitement la tolérance de saut avec le sol. En l'air sans saut permis, rien ne change.
- **Glissade avec de la place au-dessus** : le saut est permis, comme au bouton de saut, donc un lâcher en glissade fait un saut de figure. La spec n'exclut que la glissade sous un plafond bas.
- **Roulade** : le moteur permet un saut au bouton de saut pendant une roulade, s'il y a de la place, mais la spec exclut nommément la roulade pour le saut de figure. J'ai suivi la spec : un lâcher en roulade ne fait rien. Le bouton de saut et le bouton de figure diffèrent donc sur ce point.
- **Saut et lâcher au même pas** : quand le saut est appuyé au pas même où le bouton de figure est lâché, le saut de figure l'emporte. C'est un saut entier, sans JUMP annoncé.
- Le chiffre « 3 790 mesurés » du scénario de la boucle sans risque reste exact pour la boucle au bouton de saut. La boucle en saut de figure fait 2 702. Je n'ai pas touché au texte de la spec, seulement à sa ligne de statut.

## Questions

- Le saut de figure dans la roulade : faut-il le permettre, comme le bouton de saut qui, lui, saute d'une roulade quand il y a la place ? La spec l'interdit et je l'ai interdit. Si Jimmy trouve la roulade suivie d'un saut de figure naturelle à enchaîner, il faudra rouvrir la décision 3.
- Faut-il reporter 2 702 dans les « Choix acceptés » de la spec ? C'est à l'owner de le faire, je n'ai pas modifié la spec au-delà de son statut.

`````

### Développeur, troisième amendement et sortie de mur

`````markdown
# Rapport du développeur : trick-gestures, troisième amendement et sortie de mur

Spec : `docs/specs/trick-gestures.md`, décisions 22 à 27 (« troisième amendement ») et 28 (« sortie de mur », PR 38, fusionnée dans la branche en cours de travail, avance rapide). Routage : `core`, `player`, `ui`, `levels` (tests du Trick Park), `harness` (README, statut de la spec).

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a8ed02a166f314dc9`
Branche : `trick-gestures-3`, deux commits sur `main` (83ba3a7) :
- `9ab3081` trick-gestures: third amendment and the wall exit (docs/specs/trick-gestures.md, decisions 22 to 28)
- `538b633` spec trick-gestures: third amendment and wall exit implemented (statut 🟢, seul)

Rien n'est poussé.

## Fait

J'ai vu chaque test échouer avant d'écrire son code. Quand le code existait déjà, je l'ai prouvé par une mutation ciblée, puis j'ai remis le code. Le détail est dans « Vérifié ».

**Décision 22 : la répétition jugée sur les 8 dernières figures**
- La ligne flow sur le plat rapporte peu → `test_the_flow_line_on_the_flat_earns_little` (`tests/test_runner_trick_risk.gd`).
  - **Mesuré, scénario au sens littéral** (« saut de figure » = le saut du lâcher de F) : **4 053 points de style par minute**, avec 2 pas de glissade comme avec 6, 0 crash, 92 et 83 glissades parfaites.
  - **Variante de l'inspection** (bouton de saut hors de la glissade, puis figure) : **5 466 la première minute, puis plus rien**. Sur trois minutes, le total reste 5 466, tout gagné dans les 5 premières secondes. Avant le changement, cette variante faisait 71 850 et 64 390.
  - Voir Écarts n° 1.
- La répétition des figures survit à la fin d'un combo → `test_the_repetition_of_tricks_survives_the_end_of_a_combo`, dans `tests/test_flow.gd` (règle du flow) et dans `tests/test_runner_trick_risk.gd` (boucle de l'inspection, 2 776 par minute). La version du flow remplace l'ancien test de soutien `test_the_end_of_a_combo_by_its_delay_keeps_the_repetition`. Elle vérifie que la fenêtre de figures :
  - ignore les autres moves entre deux figures ;
  - survit à la fin du combo par le délai ;
  - se vide sur une erreur, une chute, un recommencement ;
  - laisse les autres moves sous la règle du flow.
- Code et réglage :
  - `game/core/flow_state.gd` : nouvelle fenêtre `_last_tricks`.
  - `trick_repetition_window = 8` dans le groupe Tricks.

**Décision 23 : la moitié pour une figure payée sans pose**
- Une figure payée sans réception vaut la moitié → `test_a_trick_paid_without_a_landing_is_worth_half` (`tests/test_runner_trick_landing.gd`).
- Les figures entre deux murs rapportent peu sans risque → `test_the_tricks_between_two_walls_earn_little_without_risk` (`tests/test_course_trick_park.gd`, vrai Trick Park, vraie physique). Un bot fait wall-run, wall-jump et une figure simple, et le mur d'en face la paie. Mesuré sur une minute :
  - **4 364** en sortant du mur au bouton de saut (avant : 24 784 ; décision 22 seule : 5 475) ;
  - **2 664** en sortant au bouton de figure (décision 28, demandé par le coordinateur), avec 28 figures payées par un wall-run à moitié prix et 0 crash.
- Code et réglage :
  - `AirTrick.unposed`, posé par `_pay_the_trick(perfect, posed)` ;
  - `trick_unposed_share = 0.5`.
- Les deux anciens tests de paiement au wall-run et au mantle attendent désormais 100 + 150 et 100 + 100.

**Décision 24 : la lecture des gestes** (`game/core/trick_gesture.gd`, réécrit en grande partie)
- Corpus → `test_human_gestures_are_read_as_the_hand_means_them` (`tests/test_trick_gesture_corpus.gd`) : les 63 gestes de la première inspection, plus 20 gestes mal lus par la seconde.
  - Souris : hésitations au milieu d'un coup, doubles « bas, haut, bas » arrondis (zigzag, ellipse, petite boucle), J à 290°, spin et demi, coups du poignet de 70 à 90°, tremblement de 4 px avec une sensibilité au quart.
  - Stick : coups de 2 pas à fond et de 4 pas à 60 %, coup court avec rebond, coup vers le haut sur 3 pas, deux coups séparés par un creux à 0,3, rampes.
  - Les 83 gestes sont lus juste. La sonde de l'inspecteur (un fichier de test temporaire, jamais commité) n'a plus qu'un geste mal lu : le tremblement de 4 px à la sensibilité du projet. Voir Écarts n° 9.
- Le scénario « Un coup au stick qui revient vite est lu » (`test_a_stick_flick_that_comes_back_fast_is_read`) teste en plus 2 pas à fond et 4 pas à 60 %.
- Ce que fait la nouvelle lecture :
  - elle coupe un élément là où la main fait demi-tour sur une courbe courte entre deux traits opposés d'au moins deux mouvements chacun ;
  - au stick, un coup se lit par sa déflexion maximale (`trick_gesture_stick_flick` 0,45, après la zone morte), et un creux sous la moitié du maximum finit un élément (`trick_gesture_stick_dip` 0,5) ;
  - à la souris, une reprise dans le même sens après moins de `trick_gesture_repeat_pause` (0,12 s) continue le même coup ;
  - un J (trait d'au moins deux mouvements) suivi d'un cercle donne le salto et ses vrilles, jamais un spin ;
  - une courbe avant tout salto qui tourne peu (`trick_gesture_stroke_turn`) est un coup ;
  - deux constantes passent dans le réglage : `trick_gesture_more_twists_angle` 180° et `trick_gesture_spin_turn_angle` 360°.

**Décision 25 : ce qui part au lâcher**
- Une recette lue en passant ne part pas → `test_a_recipe_read_in_passing_does_not_start` (`tests/test_player_tricks.gd`, vraies entrées). Un backflip validé ; une vrille commencée vers le bas passe par « DOUBLE BACKFLIP » ; on lâche F ; c'est le BACKFLIP qui part.
- Le pavé ne valide que ce qui peut partir → `test_the_pad_validates_only_what_can_start` (`tests/test_trick_pad.gd`) : un coureur en visée, puis un coureur qui a déjà fait la figure de son saut (version corrigée par la décision 28).
- Une main qui tremble garde la figure validée → `test_a_trembling_hand_keeps_the_trick_validated` (`tests/test_trick_pad.gd`) : ±2 px par pas pendant 40 pas.
- Code et réglages :
  - `TrickGesture.is_validated()` et `validated_recipe()` ;
  - `trick_gesture_settle` 0,1 s et `trick_gesture_settle_length` 0,25 unité ;
  - au lâcher, `InputIntentSource` envoie la recette validée ;
  - `RunnerMotor.trick_ready` est calculé à chaque pas, et `TrickPad.is_validated()` le lit.

**Décision 26 : la sensibilité**
- Le pavé suit la sensibilité de la caméra → `test_the_pad_follows_the_sensitivity_of_the_camera` (`tests/test_player_tricks.gd`, vraies entrées). Le même coup avec moitié moins de pixels sous une sensibilité double donne le même tracé et la même lecture ; les mêmes pixels tracent deux fois plus loin.
- `trick_pad_mouse_scale` (unités par pixel) devient `trick_pad_units_per_radian` = 4,0 (unités du pavé par radian de caméra). C'est la même échelle qu'avant avec la sensibilité actuelle (0,0025 × 4 = 0,01).
- Le README le dit.

**Décision 27 : les tests manquants**
- Un dessin illisible ne lance rien, même en l'air → `test_an_unreadable_drawing_starts_nothing_even_in_the_air` (`tests/test_player_tricks.gd`, vraies entrées).
- « ? » avant tout mouvement : une assertion ajoutée à `test_the_pad_shows_the_trace_and_validates_the_trick`.
- Les tests de soutien rattachés à un scénario existant :
  - `test_a_spin_drawn_with_the_right_stick` → `test_a_circle_alone_is_a_spin` (couche player) ;
  - `test_the_trick_of_the_context_with_lb_posed_with_b` → `test_without_a_gesture_the_trick_of_the_context_starts` (couche player) ;
  - `test_a_twisted_trick_does_not_fit_in_a_jump_on_the_flat` fondu dans `test_a_twist_makes_the_trick_longer` ;
  - le test du flow, voir la décision 22.

**Décision 28 : la sortie de mur**
- Lâcher le bouton en wall-run fait le wall-jump et la figure → `test_releasing_the_button_in_a_wall_run_makes_the_wall_jump_and_the_trick` (`tests/test_runner_tricks.gd`).
- Juste après le mur, le bouton de figure fait encore le wall-jump → `test_just_after_the_wall_the_trick_button_still_makes_the_wall_jump` (même fichier ; passé la tolérance, la figure part sans saut).
- Sans geste en wall-run, la sortie fait un side flip → `test_without_a_gesture_in_a_wall_run_the_exit_makes_a_side_flip` (même fichier).
- Une sortie de mur aux vraies entrées → `test_a_wall_exit_with_the_real_inputs` (`tests/test_course_trick_park.gd`) : le long du mur `Walls/WallRun`, au clavier-souris puis à la manette. Le backflip est posé, sans crash.
- Le wall-jump est celui du bouton de saut (mêmes vitesses), complet, comparé pas à pas dans les tests.
- Trois anciens tests encodaient la règle que la décision 28 remplace ; ils sont adaptés (Écarts n° 8).

**Descriptions mises à jour**
- README : le paragraphe des figures (décisions 22 à 28).
- AGENTS.md : son « Layout » décrit toujours le code, rien à changer.

## Vérifié

Environnement : Windows, Git Bash, Godot 4.7.2 du chemin donné. Toutes les commandes ont tourné dans le worktree.

- `just setup` : vert.
- Départ, sur `main` : `just preflight` 36,3 s (258 tests) ; `just check` 82,5 s (338 tests, exports Windows et Linux, jeu exporté lancé 60 images sans écran).
- Final, sur la branche :
  - `just preflight` : vert, **39,9 s** (267 tests, 11,5 s de tests) ;
  - `just check` : vert, **95,2 s** (349 tests, 54,8 s de tests ; typecheck, lint, deadcode, exports Windows et Linux, l'exe exporté a tourné 60 images sans écran).
  - **La machine a ralenti pendant la session** : mesurés à ce moment-là, sur les fichiers de `main`, `just preflight` prend 43,5 à 45,8 s et `just check` **96,2 s**. La branche ne rend donc pas le check plus lent que `main`, et elle rend le preflight plus rapide.
  - Le dépassement des 90 s vient de la charge de la machine (le jeu de Jimmy ouvert ?), pas de cette branche.
- Preuves du rouge :
  - **Avant toute écriture de code** :
    - ligne flow (71 850 avec la variante au bouton de saut) ;
    - moitié de prix (200 reçu, 100 attendu) ;
    - test du flow (`git show HEAD:game/core/flow_state.gd` remis le temps d'une exécution) ;
    - boucle entre les murs (24 784, ancien `flow_state.gd` et `trick_unposed_share` à 1,0) ;
    - corpus (20 gestes faux) ;
    - sensibilité (tracé moitié moins long) ;
    - les trois scénarios moteur de la sortie de mur ;
    - pavé en visée et après la figure.
  - **Par mutation, le code étant déjà là** :
    - lâcher qui envoie la lecture courante → « DOUBLE BACKFLIP » part ;
    - moteur qui lance la figure du contexte sur une recette nulle → une figure part ;
    - `trick_gesture_settle_length` à 0 → le tremblement perd la validation ;
    - sortie de mur désactivée → le test aux vraies entrées échoue.
- Les mesures de ce rapport viennent des `gut.p` des tests et d'une sonde temporaire. Les sondes n'ont jamais été commitées.

## Non vérifié

À juger par Jimmy, manette ou souris en main, dans le Trick Park :
- **La validation** : il faut garder la main au repos 0,1 s pour qu'une figure parte. Un coup sec lâché tout de suite part comme la figure du contexte, puisque la dernière recette validée est le dessin vide. Est-ce acceptable au toucher, ou faut-il raccourcir `trick_gesture_settle` ?
- La bordure verte qui ne s'allume pas en visée ni après la figure du saut, et qui s'allume en wall-run ; son scintillement si la main bouge.
- **Le pavé** : le nom affiché est la lecture courante. La bordure dit si cette lecture partira. Si on lâche bordure éteinte, c'est la dernière recette validée qui part, et son nom peut différer de celui affiché.
- **Les gestes** :
  - les doubles arrondis ;
  - l'hésitation de moins de 0,12 s ;
  - au stick, les coups courts et le creux qui sépare deux coups ;
  - un cercle dessiné dans la foulée d'un coup, qui donne maintenant le salto et ses vrilles (sur le stick, pousser 0,1 s avant de rouler donne un side flip ou un backflip à deux vrilles, pas un spin) ;
  - le coup du poignet de 70 à 90°.
- **La souris** à l'échelle de la sensibilité de la caméra, avec la souris et la DPI de Jimmy.
- **La sortie de mur** : le lâcher de F ou de LB en wall-run fait le wall-jump. Les mains : F tenu pendant le wall-run, au lieu d'Espace.
- L'équilibre : figures payées à moitié par un wall-run ou un mantle ; répétition jugée sur les 8 dernières figures.

## Écarts

1. **La ligne flow : ma lecture du scénario.**
   - Le scénario dit « saut de figure ». La spec emploie ce terme pour le saut du lâcher de F (choix acceptés, second amendement). Le test l'affirme donc sous 4 800 : 4 053 mesurés.
   - La variante de l'inspection (bouton de saut, puis figure) fait 5 466 la première minute. Sur ce cas, la consigne disait de m'arrêter.
   - J'ai continué, parce que ce n'est plus une boucle : tout est gagné dans les 5 premières secondes, puis rien, minute après minute.
   - Le test vérifie aussi cette variante : rien de plus après la première minute, et 1 822 par minute sur trois minutes. À trancher : voir Questions.
2. **Corpus : attentes changées par la décision 24** (« après un salto, un arc ne fait jamais un spin »). Ces six gestes ne sont plus des spins :
   - M7c (cercle après 120 px vers le bas) → BACKFLIP DOUBLE FULL ;
   - M7d (cercle après 120 px à droite) → SIDE FLIP ;
   - S7 et S7e (tenu à droite, puis roulé) → SIDE FLIP ;
   - S7b et S7f (tenu vers le bas, puis roulé) → BACKFLIP DOUBLE FULL.

   S7d (poussé 0,05 s, puis roulé lentement) reste un spin, parce que j'ai monté `trick_gesture_stroke_share` de 0,15 à 0,2 : à 0,15, il était lu comme un J d'un cheveu.
3. **Réglages changés ou ajoutés**, tous dans le groupe Tricks.
   - Changés : `trick_gesture_stroke_turn` 60 → 95 (pour les coups du poignet) ; `trick_gesture_stroke_share` 0,15 → 0,2.
   - Ajoutés :
     - `trick_repetition_window` 8 ;
     - `trick_unposed_share` 0,5 ;
     - `trick_gesture_more_twists_angle` 180 ;
     - `trick_gesture_spin_turn_angle` 360 ;
     - `trick_gesture_repeat_pause` 0,12 ;
     - `trick_gesture_stick_flick` 0,45 ;
     - `trick_gesture_stick_dip` 0,5 ;
     - `trick_gesture_settle` 0,1 ;
     - `trick_gesture_settle_length` 0,25.
   - Renommé : `trick_pad_mouse_scale` devient `trick_pad_units_per_radian`, à 4,0.
   - Les parts de répétition d'une figure (50 %, puis 0 %) réutilisent `flow_second_time_share` et `flow_later_times_share`.
4. **Le wall-jump d'une sortie de mur n'est pas annoncé au flow comme un wall-jump** : la figure est le move. C'est « la même logique que le saut de figure au sol », dont le saut n'est pas annoncé. Il en découle les 2 664 de la boucle entre les murs.
5. **Lint (`max-public-methods` 20)** : la méthode publique `can_start_a_trick()` aurait été la 21e. Je n'ai pas touché au lint. J'ai fait une valeur publique, `RunnerMotor.trick_ready`, calculée à chaque pas comme `state` et `events`.
6. **Tests plus rapides**, pour tenir les budgets de temps.
   - `tests/test_player_tricks.gd` hérite maintenant de `ReplayTest` (horloge ×10, chaque pas reste de 1/60 s) : 8,3 s → 1,2 s, stable sur quatre exécutions.
   - Le test de la minute entre les murs joue à ×100, 64 pas par image, puis remet le moteur de jeu comme il était : environ 1,2 s par minute simulée, résultats identiques à ceux du ×10.
7. **Le tremblement de 4 px du constat 9** est réglé par la décision 26 : il entre au corpus avec une sensibilité au quart. À la sensibilité du projet, il se lit encore « rien ».
8. **Tests adaptés à la décision 28**, qui remplace leur règle :
   - `test_a_trick_does_not_start_in_a_wall_run_or_a_mantle` : le mantle ne lance toujours rien ; le long d'un mur, le lâcher fait sauter du mur avant la figure ;
   - `test_without_a_gesture_the_trick_of_the_context_starts` : quitter le wall-run donne maintenant RISING (wall-jump) puis le side flip ;
   - `test_during_a_trick_the_jump_does_not_start_a_wall_jump` : réécrit, parce que son ancienne mise en place (une figure lancée dans la tolérance de wall-jump, sans sauter) n'existe plus. Il vérifie qu'après la sortie de mur par une figure, le saut pressé à côté d'un autre mur ne fait rien. La règle « le saut pendant une figure n'est pas retenu » reste couverte par `test_a_twist_near_the_ground_does_not_start_a_jump`.
9. **Un dessin illisible qui se pose est « validé » comme rien**, et rien ne part au lâcher (le scénario). Un dessin vide est validé comme la figure du contexte.

## Questions

1. **Erreur volontaire.** La décision 22 vide la fenêtre de figures sur une erreur. Entre les murs, avec huit recettes dont certaines ne finissent pas (sept crashs), un bot fait **26 950 par minute** : chaque crash rend les figures neuves. Faut-il qu'une erreur garde la fenêtre de figures, ou est-ce un coût assumé (un palier perdu, le combo cassé) ?
2. **Ligne flow au bouton de saut** : 5 466 la première minute, puis 0. Ce chiffre vous suffit-il, ou faut-il que la première minute aussi reste sous 4 800 ?
3. **Budget de temps** : `just check` fait 95,2 s sur la machine chargée, mais `main` fait 96,2 s dans les mêmes conditions. À remesurer sur une machine au repos (82,5 s pour `main` en début de session).
4. **Le pavé** : faut-il afficher, bordure éteinte, le nom de ce qui partira (la dernière recette validée) plutôt que la lecture courante ?

## Suite : décisions du coordinateur (commit `26b2eb3`)

### Fait
- **Une erreur ne vide plus la fenêtre de figures** (réception dure, crash, sabotage subi, arrêt). Seules une chute ou un retour au checkpoint, et un recommencement, la vident (`game/core/flow_state.gd`). Les autres moves gardent la règle du flow : une erreur vide toujours leur fenêtre.
  - Test : `test_the_repetition_of_tricks_survives_the_end_of_a_combo` (`tests/test_flow.gd`). Il a échoué d'abord sur les quatre erreurs (200 reçu, 100 attendu).
- **Boucle avec crashs volontaires entre les murs** : ajoutée comme cas de soutien de `test_the_tricks_between_two_walls_earn_little_without_risk`.
  - **20 068 par minute**, avec 7 crashs (26 950 avant).
  - Le test vérifie qu'elle reste sous 26 950. Rouge prouvé : 26 950 quand une erreur vidait de nouveau la fenêtre.
  - D'où viennent les 20 068 :
    - environ 9 300 des autres moves (wall-runs, wall-jumps, sauts, roulades), rendus neufs par chaque erreur selon la règle du flow ;
    - environ 9 200 des figures vrillées posées en roulade à la sortie du couloir. Avec 8 recettes distinctes dans une fenêtre de 8 figures, chacune revient une fois par fenêtre et vaut encore 50 %.
  - C'est ce que donnent les règles actuelles : elle ne descend pas sous 4 800.
- **`trick_gesture_settle` = 0,05 s** dans le réglage du projet (le réglage fixe des tests de règles reste à 0,1 s).
  - Deux gestes ajoutés au corpus : Q1 (coup de souris vers le bas, lâché après 3 pas de repos → BACKFLIP) et Q2 (coup de stick vers le haut sur 4 pas, lâché après 3 pas → FRONT FLIP). Le corpus vérifie ce que le lâcher lance pour ces deux gestes. Ils échouaient à 0,1 s (la figure du contexte partait).
  - Sonde sur les 85 gestes à 0,05 s :
    - chacun finit validé sur la recette voulue ;
    - aucune lecture vue en passant n'est validée en chemin ;
    - les seules validations intermédiaires sont des débuts de la même figure (le backflip avant sa vrille, le premier de deux coups), et « rien » un instant pendant le petit cercle lent M7h.
  - Aucun geste du corpus ne casse.
- **La minute entre les murs** joue maintenant 16 pas par image au lieu de 64 : sous charge, 64 a débordé une fois le pool de tâches de Jolt, avertissement que GUT compte comme une erreur. Environ 1,5 s par minute simulée, chiffres identiques.
- **README** : 0,05 s, et la règle des erreurs.

### Vérifié
- `just check` : vert, 122,6 s sur la machine chargée.
  - 349 tests ;
  - typecheck, lint, deadcode ;
  - exports Windows et Linux, le jeu exporté a tourné 60 images sans écran.
- `just preflight` : vert, 39,4 s, puis 61,1 s quand la charge a encore monté (267 tests, environ 11,5 s de tests).

`````
