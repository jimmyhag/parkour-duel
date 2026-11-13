# Mouvements aux murs : mantle, wall-run, wall-jump et parcours complet

**Statut : 🟢 Implémenté**

Session du 2026-11-12, relue le 2026-11-13 avec Jimmy, une première fois à la scission de
`docs/specs/movement-advanced.md`, une seconde fois après la fusion des mouvements au sol
(pull request n° 9). La seconde relecture a réaligné les noms sur le code, ajouté les
décisions 14 à 21 (croisements d'états, reprise de deux limites du sol) et les
scénarios qui les prouvent.

Amendée le 2026-11-13 après la première inspection et une première partie de Jimmy
sur la version d'avant-goût, Jimmy ayant délégué la décision (« me demande plus rien
de confirmer, juste enchaîne jusqu'au bout »). Les décisions 2, 3 et 4 sont précisées,
la décision 22 est ajoutée, six scénarios sont ajoutés (marqués « amendement »), un
test existant est redimensionné, et la section « Choix acceptés à l'inspection » liste
ce que le code a tranché là où la spec se taisait. Jimmy peut revenir sur chacun de
ces choix après avoir joué.

## Contexte

Fin de l'étape 1 de la feuille de route. Ce qui existe sur `main` :

- `game/core/runner_facts.gd` (`RunnerFacts`) : ce que `player` constate avant chaque pas
  (au sol, vitesse réelle, altitude, normale du sol sous les pieds, place pour se tenir
  debout).
- `game/core/runner_motor.gd` (`RunnerMotor`) : six états (`GROUNDED`, `RISING`,
  `FALLING`, `SLIDING`, `ROLLING`, `HARD_LANDING`), la hauteur de chute mesurée depuis le
  point le plus haut atteint en l'air, la tolérance de saut, la conservation de l'élan et
  son plafond absolu.
- `game/core/movement_tuning.gd` et `.tres` (`MovementTuning`) : la ressource de réglage,
  en groupes (Run, Jump, Slide, Landing, Momentum, Character, Camera).
- `game/player/player.gd` : construit les constats, exécute la vitesse, donne à la
  capsule la hauteur que l'état demande.
- `game/levels/test_course.tscn` : six sections (élan, sauts courts, sauts longs,
  marches, passage bas, grande chute), un checkpoint chacune, l'arrivée 20 m après la
  grande chute.
- `tests/pilot_intent_source.gd` : le pilote de test sait courir, sauter, glisser sous un
  obstacle bas et rouler à la réception ; les quatre tests à plus et moins 10 % rejouent
  les six sections.

Cette spec ajoute les trois mouvements qui s'appuient sur le décor vertical, les quatre
sections qui les forcent et l'enchaînement final. À la fin, le parcours complet force
chaque mouvement au moins une fois : c'est le point d'arrêt n° 2 du plan, où Jimmy juge
la sensation manette en main.

Ce qu'elle ne doit pas casser : tous les scénarios antérieurs restent verts, sauf celui
que la décision 21 remplace explicitement ; les règles d'architecture et de simulation
d'`AGENTS.md` ; la décision 3 des tests réactifs ; les « Choix acceptés à l'inspection »
de `docs/specs/movement-ground.md`, sauf les deux que la décision 18 remplace.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Où vivent les nouveaux mouvements ? | Deux nouveaux états du coureur dans `core` : mantle, wall-run. `player` ajoute à `RunnerFacts` : mur à gauche ou à droite, avec sa normale et son identité ; rebord devant, avec sa hauteur au-dessus des pieds et si son dessus est libre. `core` décide. | Même coupe que la base. |
| 2 | Mantle | Automatique : en l'air, en poussant vers un rebord situé dans la plage de hauteur réglée, dont le dessus est libre, le coureur se hisse et repart debout sur le rebord avec la vitesse de sortie vers l'avant. Aucun bouton. **Amendement** : le rebord se repère par la face que le corps touche et la direction où le joueur pousse, jamais par la direction où regarde le corps visible (décision 22). Le mantle se termine au sol : dans la vraie physique, le pas qui suit le mantle trouve le coureur debout sur le rebord, à la vitesse de sortie, sans passer par une chute. | Décision Q5. L'action contextuelle reste libre. Amendement : Jimmy a vu le mantle refusé quand le corps visible tournait contre la face ; l'inspection a mesuré deux pas de chute après chaque mantle. |
| 3 | Wall-run | Automatique : en l'air, le long d'un mur, avec assez de vitesse horizontale, en poussant le long du mur, assez haut au-dessus du sol. Durée limitée ; la gravité y est très réduite. Il se termine quand la durée est écoulée, que le mur s'arrête, que la vitesse tombe trop bas, que le joueur pousse à l'opposé du mur, qu'il saute ou qu'il touche le sol. **Amendement** : « assez de vitesse » se compte le long du mur, une fois retirée la part dirigée vers lui ; une approche trop raide ne donne pas de wall-run et ne rend pas le mur refusé. Le partage entre « le long de », « vers » et « à l'opposé de » est un angle de la ressource de réglage, 45° au départ. Une poussée exactement sur la limite compte pour le mouvement : la diagonale du clavier (avant et la touche vers le mur) lance un wall-run, et une poussée à la limite vers un rebord lance un mantle ; décrocher demande de pousser au-delà de la limite. | Décision Q2. Amendement : l'inspection a montré que la diagonale exacte du clavier ne lançait rien, et qu'une approche raide donnait un wall-run d'un seul pas qui gâchait le mur. |
| 4 | Wall-jump | Sauter pendant un wall-run repousse à l'opposé du mur et vers le haut, en gardant la vitesse le long du mur. Encore possible pendant une courte tolérance après avoir décroché. Relâcher le saut tôt écourte la montée comme pour un saut au sol. **Amendement** : le plafond absolu de vitesse horizontale s'applique dès le pas du wall-jump. | Décisions Q2 et Q15. Amendement : l'inspection a mesuré 23,1 m/s sur le pas du saut pour un plafond de 22. |
| 5 | Pas de montée infinie | Après un wall-run ou un wall-jump, le même mur est refusé tant que le coureur n'a pas touché le sol ou couru sur un autre mur. | Décision Q2. |
| 6 | Quels murs | Tout mur fixe à peu près vertical et assez haut. Celui qui construit un niveau peut en exclure un en le rangeant dans un groupe prévu pour ça. **Un mur est un seul objet physique** : son identité est celle de l'objet. Règle de construction : chaque mur d'un niveau est fait d'un seul bloc, sinon on pourrait remonter le « même » mur en passant d'un bloc à l'autre. | Décision Q8 ; Q6 de la seconde relecture. |
| 7 | Capsule lisible | Elle penche du côté du mur en wall-run. | Décision Q15. |
| 8 | Parcours complet | Après la grande chute, dans cet ordre : rebord à franchir, wall-run au-dessus d'un vide, zigzag de wall-jumps entre deux murs, enchaînement final qui mêle plusieurs mouvements, arrivée. Un checkpoint par section. Un passage propre du parcours entier dure de l'ordre de 45 à 60 secondes : c'est un ordre de grandeur que Jimmy juge en jouant, pas un test. | Décision Q14 ; Q7 de la seconde relecture. |
| 9 | Pilote de test | Il apprend ce que ces sections demandent : pousser vers un rebord, tenir le long d'un mur, sauter d'un mur à l'autre, et relâcher le saut tôt quand le tenir le ferait dépasser sa réception. Toujours sans nombre calé sur le parcours ou les réglages. Il ne court pas sur un mur sans raison. | Avec l'élan conservé les vitesses montent : un pilote qui tient toujours le saut dépasserait les blocs. |
| 10 | Plage de réglages garantie | Les quatre nouvelles sections rejoignent les six premières dans les quatre tests à plus et moins 10 % (vitesse de pointe, gravité en montée, gravité en chute, hauteur de saut). Les nouvelles valeurs ne sont pas garanties par des tests ; le développeur rejoue chaque nouvelle section avec au moins trois des nouvelles valeurs changées de 10 % en plus et en moins, une à la fois, et donne les résultats dans son rapport. | Décision de la relecture ; Q7 de la seconde relecture : un test peut passer au rouge sur un simple réglage. |
| 11 | Jamais coincé | Le retour au dernier checkpoint fonctionne depuis le mantle, le wall-run et le vol d'un wall-jump. | Critère du plan. |
| 12 | Affichage de debug | Il nomme les deux nouveaux états et montre la durée de wall-run restante et la tolérance de wall-jump restante. | Suite de la décision 18 de la base. |
| 13 | README | La section « Controls » décrit les mouvements automatiques. | Règle du plan. |
| 14 | Élan en wall-run | La vitesse le long du mur est gardée comme en l'air : aucune perte pendant le wall-run, et le plafond absolu de vitesse horizontale s'applique toujours. | Q2 de la seconde relecture. |
| 15 | Hauteur de chute | Elle se mesure depuis le point le plus haut atteint depuis le dernier contact avec le sol, quel que soit l'état : wall-run et vol d'un wall-jump compris. Un mantle est un contact avec le sol : la hauteur repart du rebord. | Q3 de la seconde relecture : une même règle partout. |
| 16 | Tolérance de saut vers le mur | Un saut demandé dans la tolérance de saut de la base avant qu'un wall-run commence donne un wall-jump au premier pas du wall-run. Un mur refusé par la décision 5 ne donne ni wall-run ni wall-jump. | Q4 de la seconde relecture : dans le zigzag, l'appui en avance est le geste ordinaire. |
| 17 | États qui excluent | Un coureur baissé (glissade, roulade, ou en l'air sous un plafond bas) n'entre ni en wall-run ni en mantle. Un coureur en wall-run n'entre pas en mantle : il quitte d'abord le mur. Pendant un mantle, saut et glissade sont ignorés : il se hisse jusqu'au bout. | Q5 de la seconde relecture : chaque mouvement part d'un état clair. |
| 18 | Deux limites du sol reprises | (a) La vitesse plancher de la décision 6 des mouvements au sol vaut aussi en l'air sous un plafond bas : un coureur baissé au-dessus d'une fente ne reste jamais pris. (b) Un coureur baissé qui atterrit sans la place de se tenir debout passe d'abord par la règle de la roulade : roulade s'il a pressé la glissade dans la fenêtre, réception lourde sinon, et il reste baissé tant que la place manque, la vitesse plancher s'appliquant. Ces deux points remplacent les choix correspondants de `docs/specs/movement-ground.md`. | Q1 de la seconde relecture ; limites trouvées au tour des mouvements au sol. |
| 19 | Arrondi des durées | Les nouvelles durées (mantle, wall-run, tolérance de wall-jump) suivent la règle de la base : arrondi au pas le plus proche. | Décision 20 de la base. |
| 20 | Durée des tests | `just preflight` reste sous 30 secondes sur la machine de Jimmy (environ 20 s aujourd'hui). Le développeur donne les nouveaux temps. | Dix sections au lieu de six dans les rejeux. |
| 21 | Scénario remplacé | « La grande chute mène à l'arrivée » est **remplacé** par « La grande chute se franchit » : l'arrivée recule après l'enchaînement final. « La roulade fait gagner du temps sur la grande chute » garde son titre ; ses deux coureurs comptent leurs pas jusqu'au checkpoint du rebord. Remplacement décidé ici. | La ligne d'arrivée recule de nouveau. |
| 22 | Constats indépendants du visuel | **Amendement.** Ce que `player` constate (le mur à côté, le rebord devant) ne dépend jamais de la direction où regarde le corps visible, qui n'est que de la présentation : il se déduit du mouvement du corps et de l'intention. | Bug vu par Jimmy en jouant : contre une face, le corps visible tourne sur le côté et le mantle ne part plus. |

### Valeurs de départ ajoutées à la ressource de réglage

Elles sont faites pour être changées par Jimmy. La tolérance de saut et le plafond
absolu existent déjà et ne changent pas.

| Réglage | Valeur |
| ------- | ------ |
| Mantle : hauteur du rebord au-dessus des pieds | de 0,9 m à 2,2 m |
| Mantle : durée, vitesse de sortie | 0,35 s, 4 m/s |
| Wall-run : distance au mur, écart à la verticale toléré | 0,6 m, 15° |
| Wall-run : hauteur minimale du mur, hauteur minimale au-dessus du sol | 2 m, 1 m |
| Wall-run : vitesse pour le lancer, vitesse sous laquelle il s'arrête | 6 m/s, 4 m/s |
| Wall-run : durée maximale, gravité pendant | 1,2 s, 6 m/s² |
| Wall-jump : vitesse à l'opposé du mur, vitesse vers le haut | 7 m/s, 9,5 m/s |
| Wall-jump : tolérance après avoir décroché | 0,10 s |
| Partage « le long de », « vers », « à l'opposé de » (amendement) | 45° |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Mouvements aux murs

  # --- Mantle (core) ---

  Scénario: Le coureur se hisse sur un rebord à sa portée
    Soit un coureur en l'air face à un rebord dans la plage de hauteur, dessus libre
    Quand il pousse vers le rebord
    Alors il se hisse et se retrouve debout sur le rebord avec la vitesse de sortie

  Scénario: Un rebord trop haut n'est pas franchi
    Soit un coureur en l'air face à un rebord plus haut que la plage
    Quand il pousse vers le rebord
    Alors il ne se hisse pas et retombe

  Scénario: Pas de mantle sans pousser vers le rebord
    Soit un coureur en l'air face à un rebord dans la plage de hauteur
    Quand il ne pousse pas vers le rebord
    Alors il ne se hisse pas

  Scénario: Pas de mantle si le dessus est encombré
    Soit un coureur en l'air face à un rebord dans la plage de hauteur, dessus occupé
    Quand il pousse vers le rebord
    Alors il ne se hisse pas

  Scénario: Le mantle va jusqu'au bout
    Soit un coureur en mantle
    Quand il demande un saut ou une glissade
    Alors il se hisse jusqu'au bout, puis repart debout sur le rebord

  # --- Wall-run et wall-jump (core) ---

  Scénario: Le wall-run démarre tout seul le long d'un mur
    Soit un coureur en l'air, assez rapide, assez haut, le long d'un mur vertical
    Quand il pousse le long du mur
    Alors il passe en wall-run sans appuyer sur un bouton

  Scénario: La diagonale du clavier lance un wall-run
    # amendement
    Soit un coureur en l'air, assez rapide, assez haut, le long d'un mur vertical
    Quand il pousse exactement à la limite entre le long du mur et vers le mur, comme avant et la touche vers le mur au clavier
    Alors il passe en wall-run

  Scénario: Une approche trop raide ne gâche pas le mur
    # amendement
    Soit un coureur en l'air qui arrive presque de face vers un mur, rapide mais trop lent le long du mur
    Quand il touche le mur, puis revient le long de ce mur assez vite sans avoir touché le sol
    Alors il n'entre pas en wall-run la première fois, et passe en wall-run la seconde

  Scénario: Pas de wall-run sans vitesse
    Soit un coureur en l'air le long d'un mur, plus lent que la vitesse de lancement
    Quand il pousse le long du mur
    Alors il tombe normalement

  Scénario: Le wall-run ralentit la chute
    Soit un coureur en wall-run
    Quand le wall-run se poursuit
    Alors il perd beaucoup moins de hauteur qu'en chute libre pendant la même durée

  Scénario: L'élan au-dessus de la vitesse de pointe se garde en wall-run
    Soit un coureur qui arrive le long d'un mur plus vite que la vitesse de pointe
    Quand le wall-run se poursuit
    Alors sa vitesse le long du mur ne diminue pas, et ne dépasse pas le plafond absolu

  Scénario: Le wall-run s'arrête au bout de sa durée
    Soit un coureur en wall-run depuis la durée maximale
    Quand un pas de plus s'écoule
    Alors il décroche et tombe

  Scénario: Le wall-run s'arrête quand le mur s'arrête
    Soit un coureur en wall-run
    Quand le mur n'est plus détecté
    Alors il décroche et tombe

  Scénario: Pousser à l'opposé du mur fait décrocher
    Soit un coureur en wall-run
    Quand il pousse à l'opposé du mur
    Alors il décroche et tombe

  Scénario: Le wall-jump repousse à l'opposé du mur
    Soit un coureur en wall-run
    Quand il saute
    Alors il part vers le haut et à l'opposé du mur, en gardant sa vitesse le long du mur

  Scénario: Le wall-jump ne dépasse pas le plafond absolu
    # amendement
    Soit un coureur en wall-run, sa vitesse le long du mur au plafond absolu
    Quand il saute
    Alors sa vitesse horizontale ne dépasse pas le plafond absolu, dès le pas du saut

  Scénario: Le wall-jump reste possible juste après avoir décroché
    Soit un coureur qui vient de décrocher d'un wall-run
    Quand il saute avant la fin de la tolérance
    Alors il fait un wall-jump

  Scénario: Un saut demandé juste avant le mur donne un wall-jump
    Soit un coureur en l'air qui demande un saut, puis arrive le long d'un mur avant la fin de la tolérance de saut
    Quand le wall-run commence
    Alors il fait un wall-jump dès le premier pas le long du mur

  Scénario: Le même mur est refusé deux fois de suite
    Soit un coureur qui vient de quitter un mur par un wall-jump, sans toucher le sol
    Quand il revient le long du même mur
    Alors il ne repasse pas en wall-run

  Scénario: Un autre mur est accepté
    Soit un coureur qui vient de quitter un mur par un wall-jump, sans toucher le sol
    Quand il arrive le long d'un autre mur
    Alors il passe en wall-run sur ce mur

  Scénario: Toucher le sol autorise de nouveau le même mur
    Soit un coureur qui a quitté un mur puis touché le sol
    Quand il revient en l'air le long de ce mur
    Alors il passe en wall-run

  # --- Croisements d'états (core) ---

  Scénario: Pas de wall-run ni de mantle en étant baissé
    Soit un coureur baissé en l'air sous un plafond bas, le long d'un mur et face à un rebord à sa portée
    Quand il pousse vers le mur puis vers le rebord
    Alors il n'entre ni en wall-run ni en mantle

  Scénario: Pas de mantle pendant un wall-run
    Soit un coureur en wall-run, un rebord à sa portée devant lui
    Quand il pousse vers le rebord sans quitter le mur
    Alors il reste en wall-run

  Scénario: La hauteur de chute compte depuis un wall-run
    Soit un coureur qui décroche d'un wall-run plus haut que le seuil de roulade au-dessus du sol
    Quand il touche le sol sans avoir pressé la glissade dans la fenêtre
    Alors la réception est lourde

  Scénario: Le coureur ne reste pas coincé au-dessus d'une fente sous un plafond bas
    Soit un coureur baissé en l'air sous un plafond bas, plus lent que la vitesse plancher
    Quand il continue de pousser
    Alors il avance à la vitesse plancher

  Scénario: Une grande chute reçue sous un plafond bas sans roulade est lourde
    Soit un coureur baissé qui tombe de plus haut que le seuil de roulade, sans la place de se tenir debout à la réception
    Quand il touche le sol sans avoir pressé la glissade dans la fenêtre
    Alors la réception est lourde, et il reste baissé tant que la place manque

  # --- Murs, parcours et pilote (player, world, levels, tests) ---

  Scénario: Un mur exclu ne donne pas de wall-run
    Soit un coureur en l'air, assez rapide, le long d'un mur rangé dans le groupe d'exclusion
    Quand il pousse le long du mur
    Alors il tombe normalement

  Scénario: Un mur trop incliné ne donne pas de wall-run
    Soit un coureur en l'air, assez rapide, le long d'une paroi plus inclinée que la tolérance
    Quand il pousse le long de la paroi
    Alors il tombe normalement

  Scénario: La grande chute se franchit
    Soit un coureur au checkpoint de la grande chute, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint du rebord en ayant roulé

  Scénario: Le rebord se franchit
    Soit un coureur au checkpoint du rebord, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint du wall-run en s'étant hissé

  Scénario: Le mantle se termine debout sur le rebord
    # amendement
    Soit un coureur qui se hisse sur un rebord, dans la vraie physique
    Quand le mantle se termine
    Alors au pas suivant il est au sol sur le rebord, à la vitesse de sortie, sans être passé par une chute

  Scénario: Un rebord abordé de biais donne un mantle
    # amendement
    Soit un coureur qui saute vers un rebord à sa portée, de biais, et dont le corps visible a tourné le long de la face
    Quand il pousse vers le rebord
    Alors il se hisse

  Scénario: Un rebord couvert ne donne pas de mantle
    # amendement
    Soit un rebord à portée dont le dessus est couvert par un plafond bas, dans la vraie physique
    Quand le coureur saute en poussant vers lui
    Alors il ne se hisse pas

  Scénario: Le vide se franchit en wall-run
    Soit un coureur au checkpoint du wall-run, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint du zigzag en ayant couru sur le mur

  Scénario: Le zigzag se franchit en wall-jumps
    Soit un coureur au checkpoint du zigzag, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint de l'enchaînement final en ayant fait des wall-jumps

  Scénario: L'enchaînement final mène à l'arrivée
    Soit un coureur au checkpoint de l'enchaînement final, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il passe la ligne d'arrivée et la course est terminée

  Scénario: Le pilote franchit des murs qu'il ne connaît pas
    Soit un petit parcours construit par le test, avec un rebord, un vide longé d'un mur et deux murs face à face
    Quand le pilote le parcourt
    Alors il atteint le bout du parcours, en s'étant hissé, en ayant couru sur un mur et fait un wall-jump

  Scénario: Le pilote ne court pas sur un mur sans raison
    Soit un coureur piloté sur un sol continu, le long d'un mur
    Quand le pilote le parcourt
    Alors il ne quitte jamais le sol

  Scénario: Le pilote relâche le saut pour ne pas dépasser sa réception
    Soit un petit parcours construit par le test, un vide puis un bloc court, abordé plus vite que la vitesse de pointe
    Quand le pilote le parcourt
    Alors il se reçoit sur le bloc court sans tomber

  Scénario: Le retour au checkpoint fonctionne depuis le mantle et le wall-run
    Soit un coureur en mantle, en wall-run ou dans le vol d'un wall-jump
    Quand le retour au dernier checkpoint est demandé
    Alors il réapparaît au dernier checkpoint, debout et à l'arrêt

  Scénario: L'affichage de debug montre les états des murs
    Soit l'affichage de debug visible
    Quand le coureur passe en mantle puis en wall-run
    Alors l'affichage nomme chaque état et montre les durées qui lui sont liées
```

Les quatre scénarios « Les sections se franchissent avec … changée de 10 % » des tests
réactifs gardent leur titre et leur test ; « chacune des sections » y désigne
maintenant les dix sections (décision 10).

**Amendement : un test existant redimensionné.** Le mur de
`test_the_pilot_does_not_jump_at_a_wall_it_cannot_clear` (scénario « Le pilote ne saute
pas devant un mur qu'il ne peut pas franchir », `docs/specs/reactive-replays.md`) fait
deux hauteurs de saut. Avec le mantle, un joueur peut le franchir : son titre ne dit plus
vrai. Sa hauteur se calcule désormais depuis le réglage, plus haute qu'un saut suivi
d'un mantle ; ses assertions ne changent pas.

## Choix acceptés à l'inspection

Le code a tranché ces points là où la spec se taisait. Ils sont acceptés tels quels le
2026-11-13 ; chacun se juge manette en main et peut être rouvert par Jimmy.

- **Durée du parcours** : le pilote franchit les dix sections en 29 s environ, chacune
  depuis son checkpoint, en deçà des 45 à 60 s de la décision 8. Jimmy a joué la
  version d'avant-goût et l'a trouvée fluide ; la longueur se juge au point d'arrêt
  n° 2.
- **Élan à travers un mantle** : il est perdu, le coureur repart toujours à la vitesse
  de sortie, comme la décision 2 le dit.
- **Déclenchement du mantle** : il faut avoir touché la face au pas précédent, sans
  portée à distance ; il peut partir pendant la montée d'un saut. Un mantle compte comme
  contact avec le sol à chaque pas : le mur refusé est oublié, la tolérance de wall-jump
  se ferme, le saut est consommé.
- **Rebord plus haut que la sonde** : un rebord dont le dessus dépasse la plage du
  mantle plus la hauteur d'un coureur debout compte comme encombré.
- **Ce qui est un mur** : tout corps fixe (`StaticBody3D`) hors du groupe d'exclusion,
  y compris un `AnimatableBody3D`. À rouvrir quand des plateformes mobiles arriveront.
- **Hauteur d'un mur** : celle de la forme touchée, partie enterrée comprise ; c'est à
  celui qui construit un niveau de ne pas enterrer un mur qu'il veut trop bas pour un
  wall-run. La mesure marche dans la version exportée : Jimmy y a couru sur les murs.
- **Hauteur au-dessus du sol** : elle n'est vérifiée qu'au départ du wall-run.
- **Le stick pendant un wall-run** : il ne fait ni accélérer ni freiner le long du mur ;
  pousser vers le mur ne fait rien, seul pousser à l'opposé fait décrocher.
- **Wall-run commencé en montée** : il garde la gravité de montée du saut, et relâcher
  le saut n'écourte plus cette montée.
- **Tolérance de wall-jump** : le pas du décrochage compte comme son premier pas ; elle
  vaut quelle que soit la raison du décrochage.
- **Mur refusé** : seul le dernier mur l'est ; courir sur A, puis B, puis de nouveau A
  est permis.
- **Inclinaison de la capsule** : 20° (`wall_run_lean`, ajoutée à la ressource de
  réglage), prise à la vitesse de rotation du corps, donc presque d'un coup.
- **Vitesse du wall-jump** : la vitesse vers le haut remplace celle du moment, la
  vitesse à l'opposé du mur s'ajoute à celle le long du mur ; la tolérance de la
  décision 16 est celle du saut de la base (0,12 s).
- **Matériau des murs** : les murs prévus pour le wall-run sont bleu-gris, pour se lire.
- **Rebords du parcours à 1,9 m** : choisis pour que le pilote les franchisse avec la
  hauteur de mantle changée de 10 %.
- **Pilote** : après un wall-jump, il pousse dans le sens de son vol ; il ne saute d'un
  mur que si un autre mur se trouve en face, à portée calculée depuis le réglage ; dans
  sa règle de relâche du saut, il ne distingue un mur d'un sol que par l'angle du sol.

## UI & Layout Contract

- **Référence visuelle** : aucune, affichage de prototype.
- **Arbre de composants** :

  | Composant | Couche | Statut |
  | --------- | ------ | ------ |
  | Affichage de debug | `game/ui/` | modifié : deux nouveaux états et deux durées |

- **États** : inchangés, plus les deux nouveaux états du coureur nommés à l'écran.
- **Focus** : aucun élément ne prend le focus.
- **Libellés** : libres, en anglais.

## Hors périmètre

- Jauge de flow, multiplicateur de combo, figures aériennes, munitions : étape 2.
- Tir, visée, objets sabotables, second joueur, fantôme : étapes 3 et 4.
- Wall-run vertical (courir vers le haut d'un mur), accroche de rebord en suspension,
  double saut : non demandés.
- Un test de la durée du parcours entier : la décision 8 en fait un ordre de grandeur.
- Sons, animations, modèle de personnage, menus, changement des touches en jeu : étape 6.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Tolérances de timing appliquées à d'autres gestes (wall-jump) | discovered | discovered |
| Croisements d'états : ce que devient chaque mouvement en l'air, sous un plafond, après un autre | non évalué | discovered |
