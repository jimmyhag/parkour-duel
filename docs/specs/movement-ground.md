# Mouvements au sol : glissade, roulade et conservation de l'élan

**Statut : 🟢 Implémenté**

Session du 2026-11-12, relue le 2026-11-13, avec Jimmy. Amendée le 2026-11-13 après la
première inspection : Jimmy a délégué la décision (« valide si tu estimes que c'est
clean »). Les décisions 3, 5, 6, 11 et 14 sont précisées, cinq scénarios sont ajoutés et
un est renforcé (marqués « amendement »), et la section « Choix acceptés à
l'inspection » liste ce que le code a tranché là où la spec se taisait. Jimmy peut
revenir sur chacun de ces choix après avoir joué.

Cette spec et `docs/specs/movement-walls.md` remplacent `docs/specs/movement-advanced.md`,
scindée en deux à la relecture pour que Jimmy joue les mouvements au sol pendant que
les mouvements aux murs se font.

## Contexte

Suite de l'étape 1 de la feuille de route. La base (`docs/specs/movement-base.md`) et
les tests réactifs (`docs/specs/reactive-replays.md`) sont implémentés. Ce qui existe :

- `game/core/runner_motor.gd` (`RunnerMotor`) : trois états (au sol, en montée, en
  chute), appelé à chaque pas fixe avec l'intention, « au sol ou non », la vitesse
  réelle et la durée du pas.
- `game/core/move_intent.gd` (`MoveIntent`) : il porte déjà `slide_held`, sans effet.
- `game/core/movement_tuning.gd` et `.tres` (`MovementTuning`) : la ressource de réglage.
- `game/player/player.gd` (`Player`) : exécute la vitesse rendue par le moteur.
- `game/levels/test_course.tscn` : quatre sections (élan, sauts courts, sauts longs,
  marches), puis la ligne d'arrivée.
- `tests/pilot_intent_source.gd` (`PilotIntentSource`), `tests/piloted_run.gd`,
  `tests/replay_test.gd` : le pilote de test, qui sait courir et sauter, et les tests
  de section qui rejouent chaque section avec quatre valeurs à plus et moins 10 %.

Cette spec ajoute la glissade, la roulade à la réception et la conservation de l'élan,
deux sections au parcours, et ce que le pilote doit apprendre pour les franchir.

Ce qu'elle ne doit pas casser : les scénarios de la base et des tests réactifs restent
verts, sauf les deux que la décision 13 remplace explicitement ; les règles
d'architecture et de simulation d'`AGENTS.md` ; la décision 3 des tests réactifs (aucun
nombre calé sur le parcours ou les réglages dans le pilote et les tests de section).

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Où vivent les nouveaux mouvements ? | Trois nouveaux états du coureur dans `core` : glissade, roulade, réception lourde. `player` constate, `core` décide, `player` exécute, y compris la hauteur de la capsule, qui suit l'état. | Même coupe que la base. |
| 2 | Comment les constats arrivent-ils ? | Par une **structure typée de `core`**, qui remplace les arguments séparés du moteur : au sol ou non, vitesse réelle, altitude, normale du sol, et s'il y a la place de se tenir debout. Les appels existants du moteur dans les tests sont adaptés à cette structure, sans toucher à leurs assertions : ce n'est pas un test affaibli. | Trois constats de plus aujourd'hui, d'autres avec les murs. |
| 3 | Glissade : démarrage | Bouton maintenu, au sol, à partir d'une vitesse minimale. Tenir le bouton en atterrissant la lance aussi, si la vitesse suffit. Jamais en l'air. **Amendement** : une glissade qui s'est terminée parce que le coureur est passé sous la vitesse plancher ne redémarre pas tant que le bouton reste tenu ; il faut le relâcher puis l'enfoncer de nouveau. | Décision Q3. Amendement : sans cela, bouton tenu sur le plat, le coureur alterne sans fin glissade et course. |
| 4 | Glissade : vitesse | Elle ralentit sur le plat au rythme réglé. En descente, la pente l'accélère : l'accélération vient de la gravité en chute et de l'inclinaison du sol, pas d'une valeur de plus. La direction ne se corrige que lentement (valeur de réglage). | Décision Q3. |
| 5 | Glissade : fin | Au relâchement, ou sous la vitesse plancher : le coureur se relève. Quitter le sol en glissant fait tomber normalement, vitesse gardée. **Amendement** : le bord d'un bloc n'est pas une pente ; une glissade qui quitte un rebord part à l'horizontale, comme une course à la même vitesse. | Décision Q3. Amendement : l'inspection a mesuré une glissade plaquée vers le bas au bord d'un rebord. |
| 6 | Sous un plafond bas | Tant qu'il n'y a pas la place de se tenir debout, le coureur reste baissé : il ne se relève pas et ne saute pas, même bouton relâché. Si sa vitesse tombe à la vitesse plancher, il continue d'avancer à cette vitesse jusqu'à la sortie. **Amendement** : la règle vaut aussi en l'air ; un coureur baissé qui perd le sol sans la place de se tenir debout tombe en restant baissé, et se redresse dès que la place revient. | Jamais coincé sous un obstacle. Amendement : l'inspection a montré un coureur qui se relève dans l'obstacle et traverse le sol. |
| 7 | Saut en glissade | Avec la place de se tenir debout, sauter pendant une glissade donne un saut normal qui garde la vitesse horizontale de la glissade. | Décision Q3 : le saut long. |
| 8 | Roulade | La hauteur de chute se mesure dans `core`, du point le plus haut atteint en l'air à l'altitude de la réception. Au-dessus du seuil : si la glissade est **pressée** dans la fenêtre qui précède la réception, roulade (vitesse horizontale gardée, capsule basse, durée réglée) ; sinon réception lourde. Un bouton tenu depuis avant la fenêtre ne compte pas : c'est une réception lourde. Sous le seuil : réception normale. Aucun dégât. | Décision Q4 : un geste à réussir, pas un bouton à garder enfoncé. |
| 9 | Réception lourde | À la réception, la vitesse horizontale est réduite au pourcentage réglé. Pendant sa durée, le coureur ne peut pas dépasser ce même pourcentage de la vitesse de pointe, et un saut demandé est refusé. Pendant une roulade, sauter reste possible et garde la vitesse. | Rater le geste coûte du temps, rien d'autre. |
| 10 | Intention | `MoveIntent` gagne « glissade pressée à ce pas », rempli par `game/player/` comme le saut pressé. | La fenêtre de roulade a besoin de l'instant de l'appui. |
| 11 | Conservation de l'élan | Une vitesse horizontale supérieure à la vitesse de pointe n'est plus ramenée d'un coup : au sol, elle redescend au rythme lent réglé ; en l'air, elle ne diminue pas. Un plafond absolu la borne. Sans direction, le freinage au sol de la base ne change pas. **Amendement** : « ne diminue pas » s'entend sans changer de direction ; tourner coûte de la vitesse comme dans la base, au sol et en l'air. | Plan : « conservation de l'élan entre les mouvements ». |
| 12 | Capsule lisible | La capsule visible se tasse en glissade et en roulade, comme sa forme de collision. | Décision Q15. |
| 13 | Parcours | Deux sections s'ajoutent après les marches, chacune avec son checkpoint, et la ligne d'arrivée recule après la seconde. **Passage bas** : un élan, une rampe descendante, puis un obstacle sous lequel un coureur debout ne passe pas et un coureur baissé passe. **Grande chute** : une chute plus haute que le seuil de roulade, puis une ligne droite jusqu'à l'arrivée. En conséquence, le scénario de la base « La section des marches mène à l'arrivée » est **remplacé** par « La section des marches se franchit » et « La grande chute mène à l'arrivée » : remplacement décidé ici. | Décision Q14. |
| 14 | Pilote de test | Il apprend deux gestes : tenir la glissade quand un obstacle bas se présente devant lui (un corps debout serait arrêté, un corps baissé passe) jusqu'à ce qu'il y ait la place de se relever ; presser la glissade quand, tombant de plus haut que le seuil, il sera au sol avant la fin de la fenêtre. Mêmes règles que dans les tests réactifs : il sonde, il ne connaît aucun nombre calé. Il ne glisse pas sans raison. **Amendement** : une glissade demandée se tient d'une traite, du premier appui à la sortie de l'obstacle ; les sondes du pilote ne doivent pas dépendre des jointures entre deux blocs de sol. | Les nouvelles sections se prouvent comme les anciennes. Amendement : l'inspection a montré un pilote qui lâche la glissade à chaque jointure, et un test rouge pour un ralentissement de glissade passé de 4 à 4,5 m/s². |
| 15 | Plage de réglages garantie | Les deux nouvelles sections rejoignent les quatre premières dans les quatre tests à plus et moins 10 % (vitesse de pointe, gravité en montée, gravité en chute, hauteur de saut). Les nouvelles valeurs de réglage ne sont pas garanties pour l'instant. | Décision de la relecture. |
| 16 | Arrondi des durées | Les nouvelles durées (fenêtre et durée de roulade, durée de réception lourde) suivent la règle de la base : arrondi au pas le plus proche. | Décision 20 de la base. |
| 17 | Retour au checkpoint | Il fonctionne depuis chaque nouvel état et rend un coureur debout, capsule à sa hauteur normale. | Critère du plan : aucun blocage. |
| 18 | Affichage de debug | Il nomme les trois nouveaux états et montre la fenêtre de roulade restante et la durée restante de roulade ou de réception lourde. | Suite de la décision 18 de la base. |
| 19 | README | La section « Controls » décrit la glissade et la roulade. | Règle du plan. |
| 20 | Durée des tests | `just preflight` reste sous 30 secondes sur la machine de Jimmy. Le développeur donne les nouveaux temps. | Six sections au lieu de quatre dans les rejeux. |

### Valeurs de départ ajoutées à la ressource de réglage

Elles sont faites pour être changées par Jimmy.

| Réglage | Valeur |
| ------- | ------ |
| Glissade : vitesse minimale pour la lancer | 5 m/s |
| Glissade : vitesse plancher | 2,5 m/s |
| Glissade : ralentissement sur le plat | 4 m/s² |
| Glissade : vitesse de correction de la direction | 1 rad/s |
| Glissade et roulade : hauteur de la capsule | 0,9 m |
| Roulade : hauteur de chute qui la rend nécessaire | 4 m |
| Roulade : fenêtre avant la réception | 0,20 s |
| Roulade : durée | 0,5 s |
| Réception lourde : vitesse gardée | 35 % |
| Réception lourde : durée | 0,35 s |
| Élan : ralentissement au sol au-dessus de la vitesse de pointe | 6 m/s² |
| Élan : vitesse horizontale maximale absolue | 22 m/s |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Mouvements au sol

  # --- Glissade (core) ---

  Scénario: La glissade démarre au sol avec assez de vitesse
    Soit un coureur au sol plus rapide que la vitesse minimale de glissade
    Quand il maintient la glissade
    Alors il passe en glissade

  Scénario: La glissade est refusée sans vitesse
    Soit un coureur au sol plus lent que la vitesse minimale de glissade
    Quand il maintient la glissade
    Alors il reste debout

  Scénario: La glissade ne démarre pas en l'air
    Soit un coureur en l'air, assez rapide
    Quand il maintient la glissade
    Alors il reste en chute

  Scénario: Tenir la glissade en atterrissant la lance
    Soit un coureur qui retombe d'une petite hauteur, assez rapide, glissade maintenue
    Quand il touche le sol
    Alors il passe en glissade

  Scénario: La glissade ralentit sur le plat puis le coureur se relève
    Soit un coureur en glissade sur un sol plat, avec la place de se tenir debout
    Quand la glissade se poursuit
    Alors sa vitesse diminue au rythme réglé, et il se relève sous la vitesse plancher

  Scénario: La glissade accélère en descente
    Soit un coureur en glissade sur une pente descendante
    Quand la glissade se poursuit
    Alors sa vitesse augmente

  Scénario: Relâcher la glissade relève le coureur
    Soit un coureur en glissade, avec la place de se tenir debout
    Quand il relâche la glissade
    Alors il se relève et court

  Scénario: Le coureur reste baissé sous un plafond bas
    Soit un coureur en glissade sans la place de se tenir debout
    Quand il relâche la glissade
    Alors il reste baissé jusqu'à ce que la place revienne

  Scénario: Le coureur ne reste pas coincé sous un plafond bas
    Soit un coureur en glissade sans la place de se tenir debout, à la vitesse plancher
    Quand la glissade se poursuit
    Alors il continue d'avancer à la vitesse plancher

  Scénario: Pas de saut sous un plafond bas
    Soit un coureur en glissade sans la place de se tenir debout
    Quand il demande un saut
    Alors il ne saute pas

  Scénario: Une glissade terminée par la lenteur ne redémarre pas toute seule
    # amendement
    Soit un coureur dont la glissade vient de se terminer sous la vitesse plancher, bouton toujours tenu
    Quand il repasse la vitesse minimale de glissade sans relâcher le bouton
    Alors il reste debout, et il ne glisse de nouveau qu'après avoir relâché puis renfoncé le bouton

  Scénario: La direction d'une glissade se corrige lentement
    # amendement
    Soit un coureur en glissade
    Quand il pousse dans une autre direction
    Alors la direction de la glissade tourne à la vitesse de correction réglée, pas d'un coup

  Scénario: Le coureur reste baissé en quittant le sol sous un plafond bas
    # amendement
    Soit un coureur en glissade sans la place de se tenir debout
    Quand il perd le sol
    Alors il tombe en restant baissé, et se redresse quand la place revient

  Scénario: Sauter en glissade garde la vitesse
    Soit un coureur en glissade plus rapide que la vitesse de pointe, avec la place de se tenir debout
    Quand il saute
    Alors sa vitesse horizontale au départ du saut est celle de la glissade

  # --- Réception (core) ---

  Scénario: Une roulade réussie garde la vitesse
    Soit un coureur qui tombe de plus haut que le seuil de roulade
    Quand il presse la glissade dans la fenêtre avant de toucher le sol
    Alors il roule et sa vitesse horizontale est conservée

  Scénario: Une réception lourde coûte de la vitesse
    Soit un coureur qui tombe de plus haut que le seuil de roulade
    Quand il touche le sol sans avoir pressé la glissade dans la fenêtre
    Alors sa vitesse horizontale est réduite au pourcentage réglé, et le reste pendant la durée réglée

  Scénario: Une glissade pressée trop tôt ne donne pas de roulade
    Soit un coureur qui tombe de plus haut que le seuil de roulade
    Quand il presse la glissade avant la fenêtre et la relâche
    Alors la réception est lourde

  Scénario: Une glissade tenue depuis avant la fenêtre ne donne pas de roulade
    Soit un coureur qui tombe de plus haut que le seuil de roulade
    Quand il presse la glissade avant la fenêtre et la tient jusqu'au sol
    Alors la réception est lourde

  Scénario: Une petite chute se reçoit normalement
    Soit un coureur qui tombe de moins haut que le seuil de roulade
    Quand il touche le sol
    Alors il continue sa course sans roulade ni ralentissement

  Scénario: Pas de saut pendant une réception lourde
    Soit un coureur en réception lourde
    Quand il demande un saut
    Alors il ne saute pas avant la fin de la réception lourde

  Scénario: Sauter pendant une roulade garde la vitesse
    Soit un coureur en roulade
    Quand il saute
    Alors il saute avec la vitesse horizontale de la roulade

  # --- Élan (core) ---

  Scénario: L'élan au-dessus de la vitesse de pointe se garde en l'air
    Soit un coureur en l'air plus rapide que la vitesse de pointe
    Quand il reste en l'air
    Alors sa vitesse horizontale ne diminue pas

  Scénario: L'élan redescend lentement au sol
    Soit un coureur au sol plus rapide que la vitesse de pointe
    Quand il continue de pousser vers l'avant
    Alors sa vitesse revient vers la vitesse de pointe au rythme lent réglé, pas d'un coup

  Scénario: La vitesse horizontale a un plafond absolu
    Soit un coureur dont la vitesse horizontale atteint le plafond absolu
    Quand quelque chose l'accélère encore
    Alors sa vitesse ne dépasse pas le plafond

  # --- Joueur (player) ---

  Scénario: Presser la glissade se lit dans l'intention
    Soit un joueur qui presse l'action de glissade
    Quand l'intention du pas est lue
    Alors elle porte « glissade pressée » à ce pas seulement, et « glissade maintenue » tant que l'action est tenue

  Scénario: La capsule s'abaisse en glissade et se relève après
    Soit un coureur debout
    Quand il glisse, puis se relève
    Alors sa forme de collision a la hauteur de glissade pendant la glissade, puis sa hauteur normale

  Scénario: Le retour au checkpoint relève le coureur
    Soit un coureur en glissade, en roulade ou en réception lourde
    Quand le retour au dernier checkpoint est demandé
    Alors il réapparaît debout, à l'arrêt, capsule à sa hauteur normale

  # --- Parcours et pilote (levels, tests) ---

  Scénario: La section des marches se franchit
    Soit un coureur au checkpoint des marches, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint du passage bas sans tomber

  Scénario: Le passage bas se franchit en glissade
    Soit un coureur au checkpoint du passage bas, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint de la grande chute, en ayant glissé

  Scénario: Une glissade gagne de la vitesse sur la rampe du passage bas
    # amendement
    Soit un coureur au sommet de la rampe du passage bas, glissade tenue
    Quand il descend la rampe
    Alors il reste au sol et arrive en bas plus vite qu'il n'est parti

  Scénario: Glisser hors d'un rebord ne plaque pas le coureur vers le bas
    # amendement
    Soit deux coureurs lancés à la même vitesse vers un rebord, l'un en glissade, l'autre en course
    Quand chacun quitte le rebord
    Alors celui qui glisse retombe au moins aussi loin que celui qui court

  Scénario: Le passage bas arrête un coureur debout
    Soit un coureur au checkpoint du passage bas, qui court sans jamais glisser
    Quand il arrive à l'obstacle
    Alors il est arrêté et n'atteint pas le checkpoint de la grande chute

  Scénario: La grande chute mène à l'arrivée
    Soit un coureur au checkpoint de la grande chute, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il passe la ligne d'arrivée en ayant roulé, et la course est terminée

  Scénario: La roulade fait gagner du temps sur la grande chute
    Soit deux coureurs au checkpoint de la grande chute, l'un qui roule, l'autre qui ne presse jamais la glissade
    Quand chacun parcourt la section
    Alors les deux passent la ligne d'arrivée, et celui qui roule en moins de pas

  Scénario: Le pilote glisse sous un obstacle bas qu'il ne connaît pas
    Soit un petit parcours construit par le test, barré par un obstacle bas
    Quand le pilote le parcourt
    # amendement : « d'une traite » est ajouté
    Alors il atteint le bout du parcours, en ayant glissé d'une traite : un seul appui, tenu jusqu'à la sortie de l'obstacle

  Scénario: Le pilote ne glisse pas sans raison
    Soit un coureur piloté sur un sol continu et dégagé
    Quand le pilote le parcourt
    Alors il ne demande jamais la glissade

  Scénario: L'affichage de debug montre les nouveaux états
    Soit l'affichage de debug visible
    Quand le coureur passe en glissade, en roulade puis en réception lourde
    Alors l'affichage nomme chaque état et montre les durées qui lui sont liées
```

Les quatre scénarios « Les sections se franchissent avec … changée de 10 % » des tests
réactifs gardent leur titre et leur test ; « chacune des sections » y désigne
maintenant les six sections (décision 15).

## Choix acceptés à l'inspection

Le code a tranché ces points là où la spec se taisait. Ils sont acceptés tels quels le
2026-11-13 ; chacun se juge manette en main et peut être rouvert par Jimmy.

- **Saut demandé à la fin d'une réception lourde** : la tolérance de saut de la base le
  retient, il part au premier pas après la réception lourde.
- **Réception lourde plus rapide que la vitesse de pointe** : elle finit à 35 % de la
  vitesse de pointe, pas à 35 % de sa propre vitesse.
- **Ralentissement de la glissade en pente** : le ralentissement du plat s'applique
  aussi en pente ; avec les valeurs de départ, une pente de moins de 5° environ
  n'accélère pas une glissade.
- **Pendant une roulade** : la direction poussée ne fait rien, ni tourner ni freiner ;
  seul le saut répond.
- **Roulade puis glissade** : une roulade qui se termine bouton tenu, ou sous un plafond
  bas, continue en glissade.
- **Saut retenu avant une roulade** : un saut demandé juste avant une réception roulée
  part au pas de la réception, vitesse gardée.
- **Au-dessus de la vitesse de pointe** : toute direction poussée, même à moitié, garde
  l'élan ; seul un stick relâché freine.
- **Le pilote saute du bord de la grande chute** : les tests prouvent la roulade sur une
  chute de 6,6 m, pas sur les 5 m d'un joueur qui se laisse tomber. Les deux dépassent
  le seuil de 4 m.
- **Feuille de route du README** : la ligne de l'étape 1 dit que les mouvements au sol
  sont en place ; elle devient vraie à la fusion.

## UI & Layout Contract

- **Référence visuelle** : aucune, affichage de prototype.
- **Arbre de composants** :

  | Composant | Couche | Statut |
  | --------- | ------ | ------ |
  | Affichage de debug | `game/ui/` | modifié : nouveaux états et durées |

- **États** : inchangés, plus les trois nouveaux états du coureur nommés à l'écran.
- **Focus** : aucun élément ne prend le focus.
- **Libellés** : libres, en anglais.

## Hors périmètre

- Mantle, wall-run, wall-jump, leurs sections et l'enchaînement final :
  `docs/specs/movement-walls.md`.
- Jauge de flow, figures, munitions, tir, second joueur : étapes 2 à 4. La glissade et
  la roulade n'ont pas encore de score.
- Les nouvelles valeurs de réglage dans la garantie à plus et moins 10 % : quand Jimmy
  commencera à les régler.
- Glissade en montée traitée à part, accroupi à l'arrêt, plongeon : non demandés.
- Sons, animations, modèle de personnage, menus : étape 6.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Tolérances de timing appliquées à d'autres gestes (roulade) | discovered | discovered |
