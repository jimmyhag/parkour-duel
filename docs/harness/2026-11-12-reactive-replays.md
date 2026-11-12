# Leçons du tour — tests rejoués réactifs (`docs/specs/reactive-replays.md`)

Tour du 2026-11-12, clos le 2026-11-13, propriétaire : Jimmy. Deuxième tour complet du
harnais : sparring court, spec, développeur, inspecteur, fusion (pull request n° 7).
Ce document dit ce que le tour a appris sur le harnais lui-même. Les deux rapports des
agents sont à la fin, mot pour mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

## Déroulé

| Étape | Qui | Résultat |
| ----- | --- | -------- |
| Sparring | session principale avec Jimmy | un seul tour de quatre questions, sans nouveau calibrage ; spec à 12 scénarios |
| Développement | développeur, worktree isolé | un commit, 49 tests ; interrompu par une limite d'usage après le commit et avant le rapport, repris par message |
| Vérification | session principale | `just check` vert, relancé sur son commit |
| Inspection | inspecteur, contexte neuf, rôle chargé nativement | « conforme », 3 constats conseillés, environ 19 min |
| CI | GitHub Actions, Linux | verte en 57 s |
| Amendement | session principale, décision de Jimmy | un 13e scénario pour un test que le développeur avait ajouté |

## Ce que la grille du kit demande de noter

1. **Sparring.** Pas de calibrage : la grille des compétences donnait déjà le niveau de
   Jimmy sur le sujet, et le sparring a commencé par l'explication. Un seul tour de
   questions numérotées avec recommandation, puis la spec, statut 🟡. Écart : la spec a
   été écrite juste après « oui pour tout », sans demander une confirmation séparée de
   la compréhension commune ; trois ajouts de l'assistant ont été signalés à Jimmy
   après coup, dans le message qui présentait la spec.
2. **Développeur.** Spec lue, tests d'abord pour neuf scénarios sur douze (trois étaient
   verts dès le pilote provisoire, il l'a dit), `just check` vert, cinq sections.
3. **Inspecteur.** Dépôt et worktree intacts, chaque constat avec fichier et ligne.
4. **Écarts de lecture.** Voir les leçons.

## Leçons

1. **« Quel changement ferait échouer ce test ? » a marché des deux côtés.** La consigne
   venait du tour précédent. Le développeur a cassé le code, le parcours et le fichier
   de réglages dix-sept fois ; l'un de ces essais a montré qu'un test restait vert à
   tort, et il a corrigé le test. L'inspecteur a refait l'exercice de son côté, sur une
   copie hors du dépôt, sans avoir lu le rapport, et est arrivé aux mêmes conclusions.
2. **Un inspecteur en lecture seule peut quand même exécuter.** Il a joué douze
   variantes abîmées sur une copie du projet placée hors du dépôt. Le rôle ne le
   prévoit pas et ne l'interdit pas ; c'est ce qui a rendu son verdict solide sur un
   changement fait presque uniquement de tests. À écrire dans le rôle si Jimmy veut que
   ce soit la règle pour ce type de changement.
3. **Un dossier temporaire par agent.** L'inspecteur a nettoyé ses fichiers par motifs
   de noms dans le dossier temporaire partagé de la session, et l'a signalé lui-même.
   Rien n'a été perdu, mais les rapports des agents y étaient rangés.
4. **Le commit est ce qui survit à une interruption.** La limite d'usage a coupé le
   développeur après son commit. Son worktree a été supprimé, la branche est restée, et
   il a repris par message dans un worktree recréé. Son rapport sépare ce qu'il a
   vérifié avant et après la coupure. Sans commit, tout aurait été à refaire.
5. **Les rôles se chargent au démarrage d'une session.** Au premier tour ils ne l'étaient
   pas ; à celui-ci l'inspecteur a été lancé directement avec son rôle. Le développeur
   de ce tour avait été lancé avant, comme agent générique avec son fichier de rôle en
   première lecture : les deux façons ont donné un rapport au format.
6. **Une décision de spec sans scénario finit en test sans scénario.** La décision 2
   disait « obstacle franchissable d'un saut », aucun scénario ne présentait d'obstacle
   infranchissable. Le développeur a ajouté le test et l'a signalé, l'inspecteur l'a
   relevé, Jimmy l'a accepté et la spec a reçu son scénario. Proposition pour le
   sparring : relire chaque adjectif d'une décision et se demander quel scénario le
   prouve.
7. **Une porte a échoué une fois sans raison connue.** Un `just preflight` sur 26 est
   sorti rouge chez le développeur, avant l'étape des tests, machine très chargée,
   sortie perdue. Piste non vérifiée : le contrôle des types lance plusieurs Godot en
   parallèle sur le même projet. Une porte qui échoue au hasard apprend aux agents à
   relancer au lieu de lire : à surveiller, et à instruire si cela se reproduit.
8. **Les temps mesurés dépendent de la machine du jour.** `just preflight` : 11 s au
   tour précédent, 16 à 27 s à celui-ci sur une machine occupée, `main` compris. La
   limite de 30 s de la spec est tenue, de peu dans le pire cas.

## Ce qui reste ouvert après ce tour

- Le pilote tient toujours le saut jusqu'au sommet : au-delà d'environ 20 % de vitesse
  de pointe en plus, il dépasse les blocs des sauts courts et la CI serait rouge sur un
  parcours qu'un joueur franchirait.
- « Franchie par le pilote » ne dit rien de l'agrément : le pilote décolle dans les
  quinze derniers centimètres, et un rattrapage sur l'arête d'en face compte comme
  réussi.
- Un commentaire à compléter dans `tests/piloted_run.gd` (constat 3 de l'inspection).
- La cause du `just preflight` rouge.

## Rapports des agents, mot pour mot

### Développeur (commit 23e7cfe)

````markdown
# Rapport du développeur — `docs/specs/reactive-replays.md`

Les 12 scénarios ont chacun leur test du même nom, `just check` est vert, et le tout tient en un commit (`23e7cfe`) sur `reactive-replays`. Aucun fichier de `game/` n'a changé. Trois points demandent une décision de Jimmy : un test en plus des 12 scénarios, le plafond du pilote au-delà de +20 % de vitesse de pointe, et un `just preflight` tombé rouge une fois sur 26, avant l'étape des tests, sans que j'aie pu en lire la cause.

J'ai été interrompu par une limite d'usage après le commit et avant ce rapport. Chaque vérification ci-dessous dit si elle date d'avant ou d'après l'interruption. Aucun code n'a changé après le commit.

## Fait

**Sections du parcours, menées par le pilote — `tests/test_course.gd`**
1. La section d'élan se franchit → `test_the_run_up_section_can_be_cleared`
2. La section des sauts courts se franchit → `test_the_short_jumps_section_can_be_cleared`
3. La section des sauts longs se franchit → `test_the_long_jumps_section_can_be_cleared`
4. La section des marches mène à l'arrivée → `test_the_steps_section_leads_to_the_finish`

Les quatre gardent leur nom. Leurs partitions (les comptes de pas et la constante `JUMP_STEPS`) sont supprimées.

**Plage de réglages garantie — `tests/test_course.gd`**
5. Vitesse de pointe changée de 10 % → `test_the_sections_can_be_cleared_with_a_top_speed_changed_by_10_percent`
6. Gravité en montée changée de 10 % → `test_the_sections_can_be_cleared_with_a_rise_gravity_changed_by_10_percent`
7. Gravité en chute changée de 10 % → `test_the_sections_can_be_cleared_with_a_fall_gravity_changed_by_10_percent`
8. Hauteur de saut changée de 10 % → `test_the_sections_can_be_cleared_with_a_jump_height_changed_by_10_percent`

Chacun joue les quatre sections avec la valeur à ×1,1 puis à ×0,9, soit 8 rejeux par test, sur une copie en mémoire de la ressource. Rien n'est écrit dans le fichier du projet.

**Le pilote lit le monde — `tests/test_pilot.gd`** (nouveau fichier)
9. Le pilote franchit un parcours qu'il ne connaît pas → `test_the_pilot_clears_a_course_it_does_not_know`
10. Un vide infranchissable arrête le pilote → `test_an_impassable_gap_stops_the_pilot`
11. Le pilote ne saute pas sans raison → `test_the_pilot_does_not_jump_without_a_reason`

**Arrondi des durées — `tests/test_runner_motor.gd`**
12. Une durée s'arrondit au pas le plus proche → `test_a_duration_is_rounded_to_the_nearest_step`

**Un test en plus des scénarios — `tests/test_pilot.gd`**
- `test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear` (voir Écarts, point 1).

**Outils de test ajoutés dans `tests/`**
- `pilot_intent_source.gd` (`PilotIntentSource`) : le pilote. Il hérite d'`IntentSource`, comme la partition.
- `piloted_run.gd` (`PilotedRun`) : un rejeu mené par le pilote, avec ses conditions d'arrêt et son résultat.
- `replay_test.gd` (`ReplayTest`) : la base commune de `test_course.gd` et `test_pilot.gd`, qui porte l'accéléré ×10 et la boucle de rejeu.
- Les quatre fichiers `.uid` correspondants sont commités.

**Autres changements**
- `AGENTS.md` : la ligne `tests/` du bloc « Layout » nomme les scripts d'aide. Aucune règle touchée.
- `docs/specs/reactive-replays.md` : statut passé à `🟢 Implémenté`.
- `ScriptedIntentSource` et le test « un saut long sans élan échoue » sont inchangés (décision 7).

Les 40 tests de la base sont toujours là et verts : la suite compte 49 tests (40 + 8 scénarios nouveaux + 1 test en plus).

## Vérifié

### Les portes

**Avant l'interruption**, dans mon premier worktree, sur le code du commit :
- `just check` : vert 4 fois (44,9 s, 47,3 s, 46,1 s, 46,3 s).
- `just preflight` : 22 lancements, 21 verts, **1 rouge** (voir « Un preflight rouge » plus bas).
- `just test` seul : 9 lancements, tous à 49/49.

**Après l'interruption**, dans `C:\Users\jimmy\Documents\parkour\.claude\worktrees\reactive-replays`, sur `23e7cfe` :
- `just preflight` : 4 lancements, tous verts (18,5 s, 19,5 s, 18,0 s, 18,3 s).
- `just check` : vert, 1 lancement, 33,1 s. C'est le dernier que j'ai lancé. Sa sortie, sans les lignes d'import ni le détail des tests :

```
typecheck: 25 script(s), 0 with errors
gdlint game tests → Success: no problems found
gdformat --check game tests → 25 files would be left unchanged
res://tests/test_course.gd         16/16 passed.
res://tests/test_debug_overlay.gd   1/1 passed.
res://tests/test_input_map.gd       2/2 passed.
res://tests/test_pilot.gd           4/4 passed.
res://tests/test_player.gd          2/2 passed.
res://tests/test_race_hud.gd        2/2 passed.
res://tests/test_race_state.gd      8/8 passed.
res://tests/test_runner_motor.gd   14/14 passed.
Scripts 8 · Tests 49 · Passing Tests 49 · Asserts 426 · Time 5.695s
---- All tests passed! ----
structure: boundaries: 0 problem(s)
structure: dead files: 0 problem(s)
structure: .claude mirror: 0 problem(s)
structure: 30 file(s) checked
build: Windows Desktop: build/windows/parkour-duel.exe (104 MiB with its .pck)
build: Windows Desktop: the exported game ran 60 frames headless
build: Linux: build/linux/parkour-duel.x86_64 (70 MiB with its .pck)
```

### Stabilité des rejeux

- La suite complète a tourné 39 fois par mes soins sur le code du commit (34 avant l'interruption, 5 après). Chaque fois que les tests ont tourné, ils étaient à 49/49.
- Avant l'interruption, une sonde temporaire non commitée a rejoué deux fois de suite les 36 rejeux de section (réglages du projet et 8 variantes) : 72 sauts, positions d'appel et de réception identiques au millimètre entre les deux passages. La sonde jouait chaque parcours seul, pas côte à côte.
- Marges mesurées par cette sonde sur les sauts longs (vide de 4,2 m) :

| Réglage | Appel avant le bord | Réception après le bord d'en face |
| ------- | ------------------- | --------------------------------- |
| Projet | 2,5 cm et 7,4 cm | 1,18 m et 1,13 m |
| Vitesse ×0,9 | 9,2 cm et 0,6 cm | **0,57 m** et 0,65 m |
| Hauteur de saut ×0,9 | 2,5 cm et 7,4 cm | 0,88 m et 0,83 m |
| Gravité en montée ou en chute ×1,1 | 2,5 cm et 7,4 cm | 1,03 m et 0,98 m |

  L'appel se fait toujours dans la dernière foulée avant le bord (15 cm à 9 m/s). La plus petite marge de réception est de 0,57 m.

### Temps (décision 10)

Mesurés sur cette machine pendant que Jimmy s'en servait. Je n'ai jamais retrouvé les 11 s de référence pour `main` : la machine était plus lente ce jour-là, et les temps varient du simple au double d'un lancement à l'autre.

| | `main` (`5e6ac76`) | `reactive-replays` (`23e7cfe`) |
| --- | --- | --- |
| Suite de tests (temps GUT) | 3,5 s | 5,7 à 5,9 s |
| `just preflight`, avant l'interruption | 15,9 à 21,4 s (8 lancements) | 16,0 à 26,6 s (20 lancements), plus un à 41,4 s |
| `just preflight`, après l'interruption | non mesuré | 18,0 à 19,5 s (4 lancements) |
| `just check`, avant l'interruption | 31,1 s, 35,1 s, 42,8 s | 44,9 à 47,3 s (4 lancements) |
| `just check`, après l'interruption | non mesuré | 33,1 s (1 lancement) |

- La suite prend 2,3 s de plus. Le contrôle des types charge 25 scripts au lieu de 21.
- `just preflight` est resté sous 30 s dans 24 lancements verts sur 25. L'exception est un lancement à 41,4 s, vert.
- `just build` seul a pris 13,7 s sur `main` et 19 à 20 s sur la branche, alors que `tests/` n'est pas exporté : l'écart sur `just check` vient donc en bonne partie de la charge de la machine, pas du changement.

### Un preflight rouge

Avant l'interruption, un `just preflight` sur 22 est sorti en erreur après 11,5 s. Le lancement d'avant avait mis 41,4 s, signe d'une machine très chargée à ce moment. À 11,5 s l'étape des tests n'avait pas commencé (import plus contrôle des types prennent environ 12 s) : l'échec vient de l'import, du contrôle des types ou du lint. Je n'ai pas la cause : la sortie a été écrasée par le lancement suivant. Il ne s'est pas reproduit dans les 24 `just preflight` et les 5 `just check` lancés ensuite.

### Les tests mordent

Tout ce qui suit date d'avant l'interruption. À chaque fois : une casse volontaire, la suite complète, puis le fichier restauré à l'octet près. Les dernières retouches du code sont postérieures à une partie de ces essais : une garde retirée du pilote (expliquée sous les tableaux), un compteur rendu privé et un commentaire.

**Le pilote**

| # | Casse | Tests passés au rouge |
| - | ----- | --------------------- |
| 1 | Le pilote ne voit plus la fin du sol | sauts longs, les 4 tests de variantes, parcours inconnu, vide infranchissable |
| 2 | Le pilote ne voit plus les marches | marches, les 4 tests de variantes, parcours inconnu |
| 3 | Le pilote saute dès qu'il est au sol | sauts courts, sauts longs, les 4 variantes, et les 4 tests du pilote |
| 4 | Le pilote saute devant tout obstacle, franchissable ou non | le test du mur, lui seul |
| 5 | Le pilote tape le saut au lieu de le tenir | sauts longs, marches, les 4 variantes, parcours inconnu |
| 6 | Le pilote demande aussi des sauts en l'air | parcours inconnu (10 demandes au lieu de 2), vide infranchissable (21 au lieu de 1) |

**Le rejeu et les tests eux-mêmes**

| # | Casse | Tests passés au rouge |
| - | ----- | --------------------- |
| 7 | Le rejeu ne détecte plus les chutes | vide infranchissable (budget épuisé au lieu de « tombé ») |
| 8 | La variante n'est pas donnée au coureur | les 4 tests de variantes |
| 9 | Variante à −30 % au lieu de −10 % | variante de vitesse de pointe (sauts longs) |
| 10 | Le vide « infranchissable » ramené à une demi-portée | vide infranchissable (le bout est atteint) |
| 11 | Arrondi remplacé par une troncature dans `runner_motor.gd` | `test_a_duration_is_rounded_to_the_nearest_step`, lui seul (13/14) |

**Le parcours et le fichier de réglages**

| # | Casse | Tests passés au rouge |
| - | ----- | --------------------- |
| 12 | Premier vide long élargi de 4,2 m à 5,2 m | variante de vitesse ×0,9 seule ; la section reste verte avec les réglages du projet |
| 13 | Première marche montée à 2 m | marches, les 4 variantes |
| 14 | Bloc d'élan coupé 8 m avant son checkpoint | élan, sauts courts, les 4 variantes, et 3 tests anciens |
| 15 | Premier vide court élargi de 2,5 m à 6,5 m | sauts courts, les 4 variantes |
| 16 | Vitesse de pointe du fichier à 6,0 | sauts longs, les 4 variantes |
| 17 | Vitesse de pointe du fichier à 7,0 | variantes vitesse ×0,9 et hauteur ×0,9 ; les sections restent vertes |

Deux essais ont changé le code :
- Au premier passage de l'essai 1, le test du parcours inconnu restait vert : en glissant du bord, le coureur voyait le bloc d'en face comme une marche et sautait quand même. J'ai abaissé le bloc de réception d'un quart de hauteur de saut ; le test passe maintenant au rouge.
- Une garde « pas pendant la montée » dans le pilote ne changeait aucun résultat une fois retirée. Je l'ai supprimée.

### Un changement de réglage seul reste vert

Avant l'interruption, valeurs changées dans `movement_tuning.tres`, suite complète, fichier restauré :
- vitesse de pointe à 9,6 : 49/49 ;
- vitesse de pointe à 8,3 : 49/49 ;
- hauteur de saut à 1,45, gravité en montée à 35, gravité en chute à 40, ensemble : 49/49.

Les tests à partition conservés (décision 7) sont restés verts dans ces trois cas.

### Jusqu'où les sections se franchissent

Sonde temporaire non commitée, avant l'interruption : une valeur multipliée par un facteur de 0,50 à 1,60, par pas de 0,05, les quatre sections à chaque fois.

| Valeur | Toutes les sections passent de… à… | Ce qui casse en dehors |
| ------ | ---------------------------------- | ---------------------- |
| Vitesse de pointe | ×0,80 à ×1,20 | en dessous, les sauts longs tombent ; au-dessus, les sauts courts tombent |
| Hauteur de saut | ×0,65 à ×1,50 | en dessous, les marches bloquent puis les sauts longs tombent ; au-dessus, les sauts courts tombent |
| Gravité en montée | ×0,50 à ×1,60 (toute la plage essayée) | rien |
| Gravité en chute | ×0,50 à ×1,60 (toute la plage essayée) | rien |

### Ordre test puis code

- Tests des sections, des variantes et du pilote : écrits d'abord, lancés contre un pilote provisoire qui ne faisait que courir. Rouges pour la bonne raison (tombé, ou budget épuisé devant la marche) : sauts courts, sauts longs, marches, les 4 variantes, parcours inconnu, vide infranchissable. J'ai écrit le vrai pilote ensuite.
- Verts dès le pilote provisoire : la section d'élan (courir suffit), « le pilote ne saute pas sans raison » et le test du mur (un pilote qui ne saute jamais les satisfait). Je ne les ai vus rouges que par les essais 3, 4 et 14.
- Test d'arrondi : le code arrondissait déjà. Vert au premier lancement, rouge par l'essai 11.

## Non vérifié

- **La CI Linux** : rien n'a été poussé, donc aucun rejeu n'a tourné sous Linux. La stabilité entre Windows et Linux (décision 11) reste à constater à la première exécution de la CI.
- **`just preflight` sur une machine au repos** : mes mesures vont de 16 à 27 s, avec un lancement à 41 s, sur une machine occupée où `main` lui-même prend 16 à 21 s. À remesurer par Jimmy.
- **La cause du preflight rouge** : inconnue, sortie perdue.
- **Arrondi vers le haut** : je voulais aussi remplacer l'arrondi par un plafond pour confirmer que le test d'arrondi le laisse passer (0,11 s donne 7 pas dans les deux cas). Non lancé.
- **Le parcours d'un seul trait** : chaque section est prouvée depuis son checkpoint. Aucun test ne joue le parcours du départ à l'arrivée ; la spec le met hors périmètre.
- **Le pilote hors des cas actuels** : il n'a vu que des parcours droits faits de boîtes. Virages, pentes, plafonds et blocs mobiles ne sont pas essayés.
- **Les petits parcours de `test_pilot.gd` après un gros changement de réglage** : le vide et la marche sont taillés d'après la ressource, mais les longueurs des blocs sont en mètres fixes. Essayés seulement avec les réglages du projet.
- **La sensation de jeu** : rien à juger manette en main, aucun fichier de `game/` n'a changé.

## Écarts

1. **Un test en plus des 12 scénarios.** La décision 2 dit que le pilote saute devant un obstacle « franchissable d'un saut ». Aucun scénario ne présente d'obstacle infranchissable. J'ai codé la distinction et ajouté `test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear` (un mur de deux hauteurs de saut : le pilote ne saute pas, le budget s'épuise). Sans lui, l'essai 4 ne fait échouer aucun test.

2. **« Le sol s'arrête juste devant lui ».** Lu ainsi : sous le point où le coureur sera après ce pas (une foulée, déduite de sa vitesse), un rayon ne trouve aucun sol jusqu'à une hauteur de saut sous ses pieds. Une marche descendante plus basse qu'une hauteur de saut est donc traitée comme un vide.

3. **« Une marche juste devant lui ».** Lu ainsi : le corps du coureur, déplacé vers l'avant, serait arrêté avant la distance qu'il parcourt pendant la montée d'un saut. Le pilote saute donc environ 2,85 m avant la marche à 9 m/s, pour être au sommet en y arrivant. « Franchissable » : le même corps, relevé d'une hauteur de saut, passe au-dessus avec la place de s'y poser.

4. **Fin d'un rejeu réussi.** La décision 4 dit « checkpoint atteint : succès ». J'exige en plus que le coureur, lâché par le pilote, s'arrête debout sur le sol. C'est plus strict, et cela garde l'ancienne vérification « le coureur est debout sur le parcours ».

5. **« Tombé sous les blocs ».** Lu ainsi : les pieds du coureur sont plus bas que le point le plus bas de tous les blocs du parcours, calculé depuis leurs formes de collision. Sur le parcours test cela donne −1 m, contre la constante −0,5 m des anciens tests.

6. **Budget de pas.** Trois fois le temps que met la distance en ligne droite du départ au but à la vitesse de pointe. Le « 3 » est le seul nombre choisi ; il n'est calé sur rien.

7. **Rejeux joués en même temps.** Les 8 rejeux d'un test de variante tournent ensemble, sur 8 exemplaires du parcours posés côte à côte, écartés de deux largeurs de parcours (largeur calculée depuis les blocs). Joués l'un après l'autre, la suite prenait 13,7 s et `just preflight` 32 s ici. Chaque rejeu garde l'accéléré ×10 et le pas de 1/60 s, vérifié à chaque fois. Conséquence : ces parcours ne sont pas à x = 0.

8. **Direction du pilote.** La décision 2 parle d'une « direction donnée ». Le rejeu la calcule : l'horizontale du point de départ vers le but.

9. **Les quatre tests de section passent par une même fonction d'aide**, que les tests de variantes réutilisent. Elle vérifie : but atteint sans tomber, coureur au sol, checkpoint suivant ou arrivée, course en cours.

10. **`jumps` compte les demandes de saut du pilote**, pas les décollages. C'est ce qui rend visible un pilote qui demande un saut en l'air (essai 6).

11. **`test_course.gd` hérite de `ReplayTest`** au lieu de `GutTest`. GUT l'accepte ; l'accéléré vit maintenant dans cette base.

12. **Test d'arrondi : même façon de compter que les tests de coyote time existants.** Le pas pendant lequel le sol disparaît n'est pas compté ; le « septième pas en l'air » est le septième où le moteur ne voit plus de sol.

13. **Commentaires de `game/` laissés tels quels** (décision 12). `game/core/intent_source.gd` et `game/player/player.gd` disent encore qu'un test rejoue « une suite écrite à l'avance », sans mentionner le pilote. C'est incomplet, pas faux.

## Questions

1. **Garde-t-on le test du mur ?** Le retirer laisse la partie « franchissable » de la décision 2 sans preuve. On pourrait aussi en faire un scénario de la spec.

2. **Le pilote tient toujours le saut jusqu'au sommet** (décision 2). Au-delà de +20 % de vitesse de pointe ou de +50 % de hauteur de saut, il dépasse les blocs de 4 m des sauts courts et tombe, alors qu'un joueur qui tape le saut passerait. La CI serait rouge sur un parcours encore faisable. Faut-il que le pilote sache relâcher tôt, ou est-ce acceptable tant que les réglages restent dans la plage ?

3. **La plage garantie suit le fichier.** Après un changement de réglage, les variantes testent ±10 % autour de la nouvelle valeur. Avec les limites mesurées, une PR « réglage seul » resterait verte pour une vitesse de pointe d'environ 8,0 à 9,8 m/s (calculé depuis le tableau, non essayé aux bornes). Est-ce la marge voulue ?

4. **La section des sauts courts ne prouve pas à elle seule que le pilote voit le vide** (essai 1 : elle reste verte). Les sauts longs et les tests du pilote le prouvent. Je le signale, sans proposer de changer le parcours.

5. **Le preflight rouge sans cause connue** : si la CI ou Jimmy le revoit, la sortie dira s'il vient du contrôle des types, qui lance 8 Godot en parallèle sur le même projet. Je n'ai rien pour l'affirmer.

6. **Faut-il mettre à jour les deux commentaires de `game/`** (écart 13) ? C'est une ligne chacun, mais hors de ce que la décision 12 attend.

---

- **Branche :** `reactive-replays` (locale, non poussée, aucune pull request)
- **Commit :** `23e7cfe` — « tests: reactive replays, a test pilot that looks ahead (docs/specs/reactive-replays.md) ». Aucun commit ajouté après l'interruption.
- **Worktree :** `C:\Users\jimmy\Documents\parkour\.claude\worktrees\reactive-replays`
````

### Inspecteur (sur 23e7cfe)

````markdown
# Inspection : branche `reactive-replays` (commit `23e7cfe`) contre `main`

Spec : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\reactive-replays\docs\specs\reactive-replays.md`.
Types de tâche (index des skills) : `core` (tests de `game/core/`) et `harness` (`AGENTS.md`, `docs/`). Aucun skill à charger.
Tous les fichiers cités sont dans `C:\Users\jimmy\Documents\parkour\.claude\worktrees\reactive-replays\`.

## 1. Verdict

**Conforme.** Aucun constat bloquant. Trois constats conseillés, dont un test sans scénario et une ligne d’`AGENTS.md` à faire relire par un propriétaire.

Ce qui a été exécuté dans le worktree, en lecture seule :

- `just typecheck` : 25 scripts, 0 erreur. `just lint` : aucun constat. `just deadcode` : 0 problème.
- `just test` : 49 tests, 426 assertions, tous verts (GUT 5,7 s ; la commande entière 10,2 s).
- Les quatre commandes à la suite : 17,1 s, sous les 30 s de la décision 10.
- CI de la PR 7 : `just check` vert en 57 s sur Linux, sur le commit `23e7cfe` (statut lu, journaux non lus).
- `git status` vide après ces exécutions. `git diff --name-only main...reactive-replays -- game` est vide : la décision 12 est tenue, aucun fichier de `game/` ne change.

Pour répondre à « ces tests peuvent-ils échouer », j’ai joué en plus, sur une copie du projet placée hors du dépôt (dossier temporaire), 12 variantes abîmées (parcours, pilote, moteur), 4 sondages de plage, 8 fichiers de réglage modifiés et 3 exécutions instrumentées. Rien n’a été modifié dans le worktree. Les résultats sont dans les sections 2 et 3.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | conseillé | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\reactive-replays\tests\test_pilot.gd:108` | Spec, liste des 12 scénarios ; `AGENTS.md`, « Contributing workflow » (un test par scénario, du même nom) | `test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear` n’a aucun scénario dans la spec. C’est pourtant le seul test qui rougit quand le pilote saute devant n’importe quel mur (variante abîmée : 48 tests verts sur 49, lui seul rouge). | Décision d’un propriétaire : ajouter à la spec le scénario « Le pilote ne saute pas devant un mur qu’il ne peut pas franchir » (il couvre « obstacle franchissable d’un saut » de la décision 2), ou retirer le test. |
| 2 | conseillé | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\reactive-replays\AGENTS.md:142` | Index des skills, type `harness` (fichier des propriétaires, relecture d’un propriétaire) ; travail que la spec ne demande pas | La ligne `tests/` de « Layout » est réécrite dans le commit de la fonctionnalité pour mentionner les scripts d’aide. Le texte est exact, mais la spec ne le demande pas. | Un propriétaire relit et accepte cette ligne explicitement, ou elle part dans un commit à part. |
| 3 | conseillé | `C:\Users\jimmy\Documents\parkour\.claude\worktrees\reactive-replays\tests\piloted_run.gd:71` | Spec, décision 4 (tomber sous les blocs = échec) | La chute n’est vue que si le dessous des blocs (calculé, -1,0 m sur le parcours test) est au-dessus de `fall_limit` du parcours (-8,0 m). Dans le cas contraire `Course` ramènerait le coureur au checkpoint avant, et l’échec sortirait en `OUT_OF_STEPS` au lieu de `FELL`. Sans effet aujourd’hui ; par raisonnement seulement, le test resterait rouge. | Une phrase dans le commentaire de `FELL` (ligne 9) qui dit cette condition. Rien d’autre. |

### Nombres littéraux (décision 3)

Aucune calibration déguisée trouvée dans le pilote ni dans les tests de section.

| Fichier:ligne | Littéral | Jugement |
| ------------- | -------- | -------- |
| `tests/pilot_intent_source.gd:34` et `:66-67` | foulée = vitesse au prochain pas x durée du pas | Déduit : vitesse du coureur, `ground_acceleration` et `top_speed` du réglage, durée du pas lue dans le moteur. |
| `tests/pilot_intent_source.gd:37` | `capsule_height / 2.0` | Facteur neutre : le rayon part du milieu du corps. |
| `tests/pilot_intent_source.gd:38` | profondeur de sonde = `jump_height` | Déduit du réglage. |
| `tests/pilot_intent_source.gd:51-52` | `sqrt(2.0 * rise_gravity * jump_height)`, puis `/ rise_gravity` | Déduit : formule physique sur le réglage. |
| `tests/pilot_intent_source.gd:58` | `2.0 * capsule_radius` | Déduit : un diamètre de corps. |
| `tests/piloted_run.gd:14` | `BUDGET_MARGIN = 3` | Facteur neutre et large : les 36 rejeux de section consomment 137 à 226 pas pour des budgets de 348 à 633, soit 41 % au plus. Le budget suit la vitesse de pointe de la variante. |
| `tests/piloted_run.gd:45` | dessous des blocs | Déduit des formes de collision ; remplace le -0,5 écrit à la main des anciens tests de section. |
| `tests/replay_test.gd:8-9` et `:48` | 60, 10, tolérance 0,000001 | Repris tels quels de `main` (pas du jeu, accéléré). |
| `tests/test_course.gd:27` | `[1.1, 0.9]` | La spec (décision 6). |
| `tests/test_course.gd:355` | `2.0 *` largeur des blocs | Facteur neutre : espacement des parcours. |
| `tests/test_course.gd:30-41`, pas des lignes 110, 118, 131, 148, 201 | `SETTLE_STEPS`, `FALL_STEPS`, `BELOW_THE_BLOCKS`, `FIRST_LONG_JUMP_EDGE`, `OVER_THE_VOID`, `TAP_STEPS`, 20, 12, 40 | Calés sur le parcours et les réglages, mais inchangés depuis `main` et lus seulement par les tests que la décision 7 garde tels quels ou qui ne sont pas des tests de section. Plus aucun test de section ne les lit. |
| `tests/test_pilot.gd:63-66`, `:80-82`, `:95-98`, `:111-112` | longueurs 7,3 / 8,6 / 6,4 / 11,2 / 13,7 / 9,4 / 5,1 | Arbitraires (décision 8, « distances quelconques »), pas mesurées. Elles supposent seulement un bloc de départ assez long pour prendre de la vitesse et un bloc de réception plus long que le saut. |
| `tests/test_pilot.gd:64`, `:81`, `:65-66`, `:112` | vide = portée / 2 et portée x 2 ; hauteurs = `jump_height` / 4, / 2, x 2 | Déduits du réglage, facteurs neutres. |
| `tests/test_pilot.gd:16-20` | `WIDTH`, `DEPTH`, couches 1 et 2 | Géométrie du test, et les couches « world » et « runner » de `project.godot`. |

### Les quatre tests de section, avant et après

Comparé avec `git show main:tests/test_course.gd`. Aucune assertion n’a été abandonnée.

- Checkpoint suivant atteint (`last_checkpoint`) : gardé (`tests/test_course.gd:339`). Arrivée `FINISHED` : gardé (`:341`).
- Course en cours (`RUNNING`), vérifié avant sur la seule section d’élan : gardé, et étendu aux trois premières sections (`:337`).
- « Sans tomber » : `lowest > -0,5` devient `outcome == REACHED` (`:334`), qui exige de ne jamais passer sous le dessous des blocs. Le seuil passe de -0,5 m écrit à la main à -1,0 m calculé. Équivalent ici : rien ne porte le coureur entre les deux, et sa capsule (rayon 0,35 m) ne peut pas descendre de plus que son rayon en accrochant un bord.
- Coureur au sol à la fin : gardé (`:335`). `REACHED` exige en plus l’arrêt complet.
- Pas de 1/60 s : gardé (`tests/replay_test.gd:48`, après chaque `_play`).
- Ajouté : un coureur qui traverse le but en l’air puis tombe est compté `FELL`, pas `REACHED` (constaté : bloc d’élan raccourci avant son checkpoint, le checkpoint est franchi en vol, le test est rouge).
- `test_a_long_jump_without_run_up_fails` est inchangé, avec sa partition (décision 7). `ScriptedIntentSource` reste et sert encore.

### Rejeux joués en même temps

- 8 parcours à 12 m d’axe en axe, donc 6 m de vide entre deux. L’espace physique est commun, mais : les coureurs sont sur la couche 2 avec le masque 1 et ne se touchent pas ; les zones (checkpoints, lignes) ont le masque 2 et sont à 6 m au moins du coureur voisin ; la direction du pilote est exactement -Z ; `PilotedRun` ne compte que son propre coureur (`tests/piloted_run.gd:104`).
- Une variante est une copie en mémoire (`duplicate()`), partagée par les 4 parcours de cette variante et jamais modifiée après sa création. La ressource du projet n’est jamais modifiée ni écrite.
- Constaté par exécution : avec les facteurs remplacés par 1,0, les 8 rejeux côte à côte donnent, section par section, exactement les nombres du rejeu seul (145 / 185 / 208 / 178 pas, 0 / 3 / 2 / 3 sauts, position finale identique à 0,00001 m près). Un rejeu n’influence pas son voisin.
- Pas de simulation : 1/60 s, vérifié par une assertion après chaque `_play` et chaque `_replay`.

## 3. Couverture de la spec

Les 12 scénarios ont chacun leur test, du même nom. « Rouge constaté » veut dire : variante jouée sur la copie hors dépôt.

| # | Scénario | Test | Ce qui le rend rouge |
| - | -------- | ---- | -------------------- |
| 1 | La section d’élan se franchit | `test_the_run_up_section_can_be_cleared` | Rouge constaté : bloc d’élan qui s’arrête avant son checkpoint (`FELL`). Reste vert avec un pilote qui saute sans arrêt. |
| 2 | La section des sauts courts se franchit | `test_the_short_jumps_section_can_be_cleared` | Rouge constaté : pilote qui saute sans arrêt (`FELL`). Reste vert avec un pilote aveugle aux vides (les vides de 2,5 m passent quand même, mécanisme non vérifié) : ce défaut du pilote est attrapé par les scénarios 3, 9 et 10. |
| 3 | La section des sauts longs se franchit | `test_the_long_jumps_section_can_be_cleared` | Rouge constaté : premier vide porté de 4,2 à 6,5 m (`FELL`) ; pilote aveugle aux vides ; pilote qui ne tient pas le saut. |
| 4 | La section des marches mène à l’arrivée | `test_the_steps_section_leads_to_the_finish` | Rouge constaté : première marche portée à 1,7 m, au-dessus du saut de 1,6 m (`OUT_OF_STEPS`) ; pilote aveugle aux marches ; pilote qui ne tient pas le saut. |
| 5 | ... vitesse de pointe changée de 10 % | `test_the_sections_can_be_cleared_with_a_top_speed_changed_by_10_percent` | Rouge constaté : premier vide long à 5,3 m, seul « LongJumps, top speed x 0.9 » échoue, le test de base et les 31 autres rejeux restent verts. Variante non appliquée au coureur : rouge (`assert_same`, 8 échecs). |
| 6 | ... gravité en montée changée de 10 % | `test_the_sections_can_be_cleared_with_a_rise_gravity_changed_by_10_percent` | Rouge constaté : marche à 1,7 m (les deux sens) ; variante non appliquée. |
| 7 | ... gravité en chute changée de 10 % | `test_the_sections_can_be_cleared_with_a_fall_gravity_changed_by_10_percent` | Rouge constaté : marche à 1,7 m (les deux sens) ; variante non appliquée. |
| 8 | ... hauteur de saut changée de 10 % | `test_the_sections_can_be_cleared_with_a_jump_height_changed_by_10_percent` | Rouge constaté : marche à 1,7 m, seul le sens x 0,9 échoue (x 1,1 donne 1,76 m et passe) ; variante non appliquée. |
| 9 | Le pilote franchit un parcours qu’il ne connaît pas | `test_the_pilot_clears_a_course_it_does_not_know` | Rouge constaté avec chacun des pilotes abîmés : aveugle aux vides, aveugle aux marches, saut non tenu, saut permanent. |
| 10 | Un vide infranchissable arrête le pilote | `test_an_impassable_gap_stops_the_pilot` | Le rejeu finit `FELL` au pas 74 d’un budget de 348 : c’est une chute, pas un délai. Rouge constaté : pilote qui ne saute pas au bord (`jumps == 1`), pilote qui saute sans arrêt. Par lecture : vide devenu franchissable (`REACHED`), coureur bloqué sans tomber (`OUT_OF_STEPS`). |
| 11 | Le pilote ne saute pas sans raison | `test_the_pilot_does_not_jump_without_a_reason` | Rouge constaté : pilote qui saute sans arrêt (3 sauts, 93 pas en l’air). Reste vert avec un pilote qui ne saute jamais, que les scénarios 9 et 10 attrapent. |
| 12 | Une durée s’arrondit au pas le plus proche | `test_a_duration_is_rounded_to_the_nearest_step` | Rouge constaté : `roundi` remplacé par une troncature dans `game/core/runner_motor.gd:141`, lui seul échoue (13 sur 14). Il ne distingue pas le plus proche de l’arrondi supérieur ; par lecture, les tests existants à 0,10 s et 0,12 s s’en chargent. |

Les quatre tests « 10 % » appliquent bien la variante au coureur (`apply_tuning`, vérifié par `assert_same` sur le moteur), dans les deux sens, sur les quatre sections, et vérifient chacun des 8 rejeux un par un, avec la section et la variante dans le message.

Test sans scénario : `test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear` (constat 1). Aucun autre.

Les 40 scénarios de `docs/specs/movement-base.md` : les 40 tests de `main` sont tous présents sous le même nom ; 36 sont intacts, les 4 tests de section sont réécrits au titre de la décision 5 sans assertion perdue (section 2).

Plage réelle, au-delà de ce que la spec demande : les 32 rejeux restent verts à ±12 %, ±15 % et ±20 % ; à ±30 %, « ShortJumps, top speed x 1.30 » et « LongJumps, top speed x 0.70 » échouent. Aucun rejeu n’est donc au bord de l’échec à ±10 %. Et avec le fichier de réglage lui-même modifié de ±10 % sur chacune des quatre valeurs (8 fichiers), la suite entière reste à 49 sur 49 sur cette machine.

Rien de `docs/specs/movement-advanced.md` dans la branche, ni rejeu d’un seul trait, ni dépendance, ni option nouvelle.

## 4. Non vérifiable ici

- **Rien de nouveau à sentir manette en main** : aucun fichier de `game/` et aucune valeur de réglage ne changent. Mouvement, fenêtres de tolérance, caméra et retours sont ceux de `main`.
- **Ce que « franchie » veut dire** : le pilote décolle au dernier pas où son centre est encore sur le sol (au plus une foulée avant le bord, 15 cm à 9 m/s) et tient le saut jusqu’au sommet. La garantie de ±10 % vaut pour ce décollage. Savoir si les sauts longs (4,2 m) restent faisables à la main avec 10 % de vitesse en moins, c’est au propriétaire de le juger en jouant.
- **Le rattrapage au bord** : un rejeu compte comme réussi quand la capsule accroche l’arête d’en face et remonte dessus. Vu avec le premier vide long porté à 4,9 m et la vitesse x 0,9 (portée balistique d’environ 4,75 m) : vert. La physique du jeu n’est pas changée par cette branche ; dire si ce rattrapage est voulu revient au propriétaire.
- **Linux** : la CI est verte ; je n’ai lu que son statut. La suite entière à ±10 % dans le fichier de réglage n’a été jouée que sur ce poste Windows.
- **Temps annoncés par le développeur** (décision 10) : ils sont dans son rapport, que je n’ai pas lu. Les miens sont en section 1.
- **Non joué** : une variante du vide infranchissable où le coureur ne peut pas tomber (ma tentative ne compilait pas) ; le constat 3 repose sur un raisonnement.
- **Note de méthode** : les copies abîmées étaient dans le dossier temporaire partagé de la session. Je les ai supprimées par motifs (`m_*`, `out_*.txt`, `base/`, `mutant.sh`, `test-out.txt`, `test2.txt`, `tc.txt`, `lint.txt`, `dead.txt`) sans avoir listé ce dossier avant de m’en servir : si un fichier d’un autre agent portait déjà l’un de ces noms, il a été écrasé ou supprimé. Le dépôt et le worktree ne sont pas concernés.
````

