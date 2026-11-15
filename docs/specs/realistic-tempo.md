# Un tempo réaliste : courir, sauter et tourner à vitesse humaine

**Statut : 🟢 Implémenté**

Session du 2026-11-15, avec Jimmy, après avoir joué la passe « du poids et du liant »
(`docs/specs/motion-weight.md`) : « c'est trop rapide […] pour le système que je veux
faire, faudrait peut-être que ce soit plus lent, plus réaliste ». Il a choisi une course
à **6,5 m/s** (la vitesse d'un vrai traceur) et veut ralentir aussi **le saut, les
figures, le wall-run et le bonus de vitesse du flow**. Le reste des choix a été délégué
à la session principale (« oui pour tout »).

## Contexte

Le moteur a été réglé à l'étape 1 sur une capsule, pour un jeu nerveux : vitesse de
pointe 8,2 m/s (9 avant), saut de 1,6 m avec des gravités de 32 et 44 m/s² (3 à 4,5 fois
la vraie) et 0,59 s de vol, wall-run de 1,2 s lancé à 6 m/s, wall-jump à 9,5 m/s vers le
haut. Les clips Mixamo sont de la capture de mouvement à vitesse humaine : leur sprint a
une foulée de 5,6 m/s, et les pieds glissent de 14 % à la vitesse de pointe.

Ce que la spec ne doit pas casser : tous les scénarios, en particulier les règles des
figures (« un simple tient dans un saut à plat », « un double ne tient pas dans un saut à
plat », une vrille demande une descente) et les boucles d'économie fermées par les
inspections ; le parcours faisable avec sa garantie à plus et moins 10 % ; les règles de
l'arène du Chase ; ce que le coureur constate ne dépend jamais du corps visible.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | La course | `top_speed` **6,5 m/s** ; `ground_acceleration` **16** et `ground_deceleration` **26 m/s²** (le coureur met environ 0,4 s pour atteindre sa pointe, 0,25 s pour s'arrêter) ; `air_acceleration` **11**. | Q1 de Jimmy. Un départ et un arrêt d'humain. |
| 2 | Le saut | `jump_height` **1,2 m** ; `rise_gravity` **16** et `fall_gravity` **22 m/s²** : environ 0,72 s de vol à plat (0,59 avant) et une portée à pleine vitesse proche d'avant (4,7 m contre 4,8). Le saut relâché tôt, le coyote et la mémoire du saut ne changent pas. | Q2. Plus bas, moins sec, plus de temps de vol ressenti. |
| 3 | Les figures | Les durées des figures suivent le temps de vol : `trick_turn_duration` et `trick_twist_duration` sont multipliées par le rapport entre le nouveau temps de vol d'un saut à plat et l'ancien (environ 1,22 : un tour vers **0,43 s**, une vrille vers **0,37 s**). Le développeur calcule les valeurs depuis le réglage et les écrit dans la ressource. Les fenêtres de réception (`trick_landing_window`, `trick_perfect_window`) ne changent pas. | Q2. Des figures plus lentes, sans rouvrir les règles et les boucles fermées : un simple tient toujours dans un saut à plat, un double et une vrille non. |
| 4 | Le wall-run | `wall_run_duration` **1,0 s** ; lancé à partir de `wall_run_start_speed` **4,8 m/s**, arrêté sous `wall_run_stop_speed` **3,2 m/s** ; `wall_jump_away_speed` **5,5** et `wall_jump_up_speed` **6,5 m/s** (environ la vitesse d'appel d'un saut). | Q2. Plus court et moins rapide. |
| 5 | Le flow | `flow_tier_speed_bonus` **[0,04 ; 0,07 ; 0,10]** (au palier 3 : 7,15 m/s, contre 9,43 aujourd'hui). `perfect_slide_speed_gain` **1,5** et `trick_perfect_speed_gain` **0,8 m/s**. | Q2. Le bonus reste une récompense, à l'échelle de la nouvelle course. |
| 6 | Les seuils qui suivent la vitesse | Multipliés par 6,5 / 8,2 (environ 0,79) et arrondis au dixième : `slide_min_speed` **4,0**, `slide_stop_speed` **2,0**, `vault_min_speed` **3,2**, `mantle_exit_speed` **3,2**. Les durées des gestes de `motion-weight.md` ne changent pas. | Les mouvements gardent le même rapport à la course. |
| 7 | Les pieds | Au sol, de la marche au palier 3 du flow, la locomotion est lue sous `animation_max_pace` et le pied d'appui suit le sol à plus ou moins 10 % (mesuré avec les fichiers, rapporté). À 6,5 m/s, le sprint est lu à environ 1,16 fois. | Les pieds ne glissent plus. |
| 8 | Le parcours suit | Si une section du parcours ou sa garantie à plus et moins 10 % ne passe plus, ses distances et hauteurs sont ajustées dans la scène (proportionnellement, en gardant ce qu'elle force) ; le rapport dit ce qui a bougé. Les sections qui demandent le bonus du flow le demandent encore. | Adapter le niveau au coureur, pas relâcher la garantie. |
| 9 | L'arène du Chase | Elle garde ses règles, recalculées depuis le réglage : chaque muret franchi dans les deux sens à la vitesse de pointe et au palier 3 ; les plateformes au-dessus d'un saut suivi d'un mantle depuis le sol, atteintes par leur bloc-rebord ; le départ des joueurs ajusté si l'équilibre chat et souris mesuré par les bots change (rapporté). | Le Chase reste jouable. |
| 10 | Les réglages seulement | Rien d'autre ne change : ni les règles du moteur, ni les points du flow, ni les gestes des figures, ni la caméra. | Une passe à la fois ; Jimmy juge ensuite. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Un tempo réaliste

  Scénario: La course plafonne à une vitesse humaine
    Soit un coureur qui pousse droit devant sur le plat, avec le réglage du projet
    Quand il atteint sa vitesse de pointe, puis lâche tout
    Alors il court à 6,5 m/s, l'atteint en environ 0,4 s et s'arrête en environ 0,25 s

  Scénario: Les pieds suivent le sol jusqu'au palier 3
    Soit un coureur au sol de la marche au palier 3 du flow, avec le réglage du projet
    Quand on calcule la vitesse de lecture de sa locomotion
    Alors elle ne dépasse jamais le plafond, et la foulée lue est à plus ou moins 10 % de sa vitesse

  Scénario: Le saut est plus bas et vole plus longtemps
    Soit un coureur qui saute à plat, saut tenu, à sa vitesse de pointe
    Quand il retombe au sol
    Alors il est monté de 1,2 m, a volé environ 0,72 s, et a couvert au moins 4,5 m

  Scénario: Les figures gardent leur place dans le saut
    Soit le réglage du projet
    Quand on compare la durée d'une figure au temps de vol d'un saut à plat
    Alors un simple y tient, un double et une vrille non, et le rapport entre un tour et le temps de vol est celui d'avant à 2 % près

  Scénario: Le wall-run est plus court et moins rapide
    Soit un coureur qui court le long d'un mur sans sauter
    Quand on suit son wall-run
    Alors il commence à partir de 4,8 m/s et dure au plus 1,0 s

  Scénario: Le bonus de vitesse du flow est réduit
    Soit un coureur au palier 3 du flow
    Quand il court droit devant
    Alors il plafonne à 7,15 m/s

  Scénario: Le parcours reste faisable au tempo réaliste
    Soit le réglage de cette spec
    Quand le pilote rejoue chaque section, et sa garantie à plus et moins 10 %
    Alors il les franchit toutes

  Scénario: L'arène du Chase garde ses règles au tempo réaliste
    Soit l'arène du mode Chase et le réglage de cette spec
    Quand le pilote franchit chaque muret dans les deux sens, à la vitesse de pointe puis au palier 3, et qu'on mesure les plateformes
    Alors chaque franchissement passe, et chaque plateforme est au-dessus d'un saut suivi d'un mantle et atteinte par son bloc-rebord
```

Avec les fichiers, le développeur mesure localement le pied d'appui (décision 7) et
rapporte les chiffres ; il mesure aussi, en vraie physique, les boucles de points de style
les moins risquées (avant et après) et les rapporte.

## Choix acceptés après le développement

Acceptés le 2026-11-15 par la session principale (délégation de Jimmy) ; Jimmy peut
rouvrir chacun après avoir joué.

- **La plateforme qui tombe** passe de 8 à 6,3 m (8 × 6,5 / 8,2), pour que l'alerte
  laisse toujours le temps d'en sortir (`docs/specs/sabotage.md`) ; dans le couloir, le
  départ des marches s'allonge de 1,7 m vers l'arrière. Le reste du parcours ne bouge pas.
- **L'arène du Chase ne change pas** ; le chat gagne toujours plus vite que la souris
  contre des bots qui foncent droit (2,25 s avant, 2,80 s après) : l'équilibre se juge
  entre humains.
- **Une fente sous un plafond bas peut encore coincer un coureur lent** (sous 3 m/s
  environ), contrairement à la décision 18 de `docs/specs/movement-walls.md`. Le défaut
  existait déjà avec l'ancien réglage ; aucune fente de ce genre sur le parcours ni dans
  l'arène. Il sera traité dans sa propre demande ; d'ici là, aucun niveau n'en dessine.
- **Les tests des scénarios vérifient les valeurs que la spec nomme** (6,5 m/s, 1,2 m,
  7,15 m/s, 4,8 m/s) : changer l'une d'elles passe désormais par une spec, même sans
  ligne de code.
- **`just check` met de 106 à 120 s** sur la machine de Jimmy avec les fichiers Mixamo
  (94 s sur `main` avant cette passe) : le coureur plus lent demande plus de pas aux
  rejeux. Au-dessus de la limite de 90 s ; à traiter dans sa propre demande, avant la
  suivante.

## Hors périmètre

- La caméra (champ de vision, distance) : à juger après cette passe.
- Refaire l'arène du Chase « plus propre » : la spec suivante, avec Jimmy.
- De nouveaux clips Mixamo : seulement si la décision 7 ne passe pas.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Garder les règles d'un jeu en changeant son échelle de temps (rapports plutôt que valeurs) | — | discovered |
