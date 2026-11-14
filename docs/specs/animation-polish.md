# Des animations propres : sans saccade, et un wall-run comme dans les autres jeux

**Statut : 🟢 Implémenté**

Session du 2026-11-14, avec Jimmy, après qu'il a joué le personnage Mixamo : « elles
sont un peu toujours saccadées » ; « l'animation de wallrun, elle va pas du tout, on
dirait il s'écrase contre le mur et il court bizarrement. Ce serait bien […] que ce soit
propre comme d'autres jeux ». Il a délégué la façon de faire. Le développement commence
quand `docs/specs/locomotion-blend.md` est fusionnée.

Amendée le 2026-11-14 après l'inspection de la pull request n° 48 : la table des fondus
était écrasée par le défaut à chaque pas, l'interpolation cubique faisait ralentir la
course au bouclage de chaque cycle, l'arrêt et le départ tournaient les hanches de 15°
par image, et le pied glissait encore de 10 à 20 % selon la mesure de l'inspecteur.
Décisions 7 à 9, scénarios marqués « second passage ».

## Contexte

Ce qui existe (`game/core/runner_animation.gd`, `game/player/runner_character.gd`,
`game/player/wall_run_pose.gd`, `game/player/player.gd`) :

- l'état du moteur choisit un clip à chaque pas fixe ; le corps visible (`Visual`) est
  tourné et penché dans `_physics_process` ; l'interpolation physique est active dans le
  projet ; l'arbre d'animation a ses propres réglages de mise à jour ;
- des clips Mixamo coupés et étirés pour tenir une durée d'état (mantle joué 1,9 fois
  plus vite, roulade 1,6 fois) ;
- le wall-run joue le clip Mixamo « Wall Run » (0,55 s étirées sur 1,2 s), en miroir
  selon le côté, avec un décalage latéral à chaque clé qui garde un pied au mur : le
  corps se balance jusqu'à 35 cm ;
- la passe `docs/specs/locomotion-blend.md` ajoute le blend space de locomotion, les
  fondus par paire, la reprise en phase, le fondu du décalage du wall-run.

Ce que la spec ne doit pas casser : tous les scénarios ; sans les fichiers, la capsule ;
ce que le coureur constate ne dépend jamais du corps visible ; le moteur et ses tests.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | D'abord mesurer | Le développeur mesure les saccades avant de corriger : à 60, 144 et 240 images par seconde affichées (le pas fixe restant à 60), la vitesse angulaire de chaque os et la position du corps visible d'une image à l'autre, en course, en saut, en réception, en glissade, en wall-run, en figure. Un « à-coup » est une image dont la variation dépasse nettement celle des images voisines. Le rapport donne les sources trouvées, chiffres à l'appui. | Corriger ce qu'on a vu, pas ce qu'on suppose. |
| 2 | Les animations au rythme de l'affichage | L'arbre d'animation avance à chaque image affichée ; le corps visible (orientation, inclinaison, décalage) est interpolé entre deux pas fixes. Aucun os, aucun nœud visible n'avance par paliers de 1/60 s quand l'écran va plus vite. | La cause la plus probable des saccades sur un écran rapide. |
| 3 | Plus de changement d'un coup | Tout changement visible passe par un fondu ou une interpolation : clip, miroir, décalage, inclinaison, échelle. Seuls le crash et la réception dure restent sans fondu. Un clip n'est jamais lu plus de 1,5 fois (**amendement** : 1,8 fois, `animation_max_pace`, avec le blend space amendé de `docs/specs/locomotion-blend.md`) plus vite que sa vitesse propre : s'il le faudrait, on garde une partie plus courte du clip. | Les sauts de pose se voient plus que des fondus courts. |
| 4 | Le wall-run, refait | Le clip « Wall Run » n'est plus utilisé. En wall-run, le personnage joue la **course** du blend space (course ou sprint selon la vitesse le long du mur) et **tout le corps est incliné** autour de la direction de course, **pieds vers le mur, tête vers l'extérieur**, de `wall_run_body_roll` (**35°**, ressource de réglage). Le corps est placé pour que ses pieds effleurent la surface du mur (un décalage fixe, calculé depuis l'inclinaison et la distance au mur que le moteur connaît), **sans balancement** d'une clé à l'autre. L'inclinaison monte et redescend en douceur (`wall_run_roll_time`, **0,15 s**) à l'entrée et à la sortie. Les règles de la décision 12 de `docs/specs/character-animations.md` restent vraies : la tête plus loin du mur que les pieds, aucun os derrière la surface du mur. | La façon de faire des jeux à wall-run : une course qui boucle, un corps incliné, une entrée et une sortie douces. |
| 5 | La logique testable | L'angle d'inclinaison du wall-run à chaque instant (montée, tenue, descente), le décalage qui pose les pieds au mur, le choix de la course ou du sprint le long du mur et la limite de vitesse de lecture sont des fonctions pures testées sans les fichiers. La mesure des saccades et des os est faite localement avec les fichiers, et rapportée. | Les tests tournent dans la CI sans Mixamo. |
| 7 | Les fondus vraiment par paire | **Second passage.** Redemander l'état déjà demandé ne relance pas de fondu : le temps de la paire s'applique en entier. | Mesuré : glissade → course durait 0,10 s au lieu de 0,2 s. |
| 8 | Le bouclage sans accroc | **Second passage.** Un clip en boucle n'a pas de clé finale égale à sa clé 0 : l'interpolation passe le bouclage à vitesse constante. | Mesuré : un creux à 18-27 % de la vitesse des os environ trois fois par seconde à 144 Hz. |
| 9 | Arrêt et départ en douceur | **Second passage.** La position dans le blend space de locomotion suit la vitesse avec un lissage réglé (`animation_start_stop_time`, **0,18 s**) : l'arrêt et le départ passent par la marche au lieu de la sauter en deux images. Le pied d'appui suit le sol à ±10 % de la marche au sprint, mesuré par la même méthode que l'inspecteur (os le plus bas du pied, sous 2 cm de son point le plus bas, vitesse vers l'arrière), pour les deux pieds. | Mesuré : hanches 14-16° par image à l'arrêt ; pied droit qui glisse de 10 à 21 %. |
| 6 | Les réglages | `wall_run_body_roll`, `wall_run_roll_time` et toute autre valeur nouvelle vivent dans la ressource de réglage (groupe Animation). | Règle d'`AGENTS.md`. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Des animations propres

  Scénario: L'inclinaison du wall-run monte et redescend en douceur
    Soit un coureur qui entre en wall-run, le tient, puis le quitte
    Quand on suit l'inclinaison du corps
    Alors elle monte de 0 à l'inclinaison réglée pendant la durée réglée, la tient, puis redescend à 0 pendant la même durée, sans saut

  Scénario: En wall-run, le personnage court
    Soit un coureur en wall-run lent, puis rapide le long du mur
    Quand on choisit son animation
    Alors c'est la course, puis le sprint, et jamais le clip Wall Run

  Scénario: Le décalage du wall-run est fixe
    Soit un coureur en wall-run à une distance du mur donnée
    Quand le wall-run se poursuit
    Alors le décalage du corps vers le mur ne change pas d'un pas à l'autre

  Scénario: Les pieds effleurent le mur et la tête s'en écarte
    Soit un coureur en wall-run à gauche puis à droite, à plusieurs distances du mur
    Quand on calcule la pose du corps incliné
    Alors les pieds sont à quelques centimètres de la surface, la tête plus loin, et aucun point du corps derrière le mur

  Scénario: Aucun clip n'est lu trop vite
    Soit chaque état à durée fixe et chaque vitesse au sol
    Quand on calcule la vitesse de lecture de son clip
    Alors elle ne dépasse jamais 1,8 fois la vitesse propre du clip

  Scénario: Un fondu demandé de nouveau garde son temps
    # second passage
    Soit un coureur qui sort d'une glissade vers la course
    Quand l'état de course est redemandé à chaque pas pendant le fondu
    Alors le fondu dure le temps de la paire glissade → course

  Scénario: Une boucle passe son bouclage sans ralentir
    # second passage
    Soit un clip en boucle préparé pour l'arbre d'animation
    Quand on le lit autour de son bouclage
    Alors la vitesse des os ne creuse pas au bouclage

  Scénario: L'arrêt passe par la marche
    # second passage
    Soit un coureur qui court puis s'arrête net, puis repart
    Quand on suit la position dans le blend space de locomotion
    Alors elle redescend et remonte en douceur sur la durée réglée, sans sauter la marche

  Scénario: Le corps visible n'avance pas par paliers
    Soit un coureur qui court, l'affichage à 144 images par seconde et le pas fixe à 60
    Quand on suit le corps visible image par image
    Alors sa position et son orientation changent à chaque image, sans palier d'une image à l'autre
```

## Hors périmètre

- Les pieds qui s'adaptent au sol (IK).
- D'autres clips Mixamo : si une animation reste laide après cette passe, la session
  principale en télécharge une autre sur le compte de Jimmy.
- Le jeu en ligne : étape 5.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Animation au rythme de l'affichage, simulation au pas fixe, interpolation entre les deux | — | discovered |
| Un mouvement fait d'une boucle et d'une pose procédurale plutôt que d'un clip dédié | — | discovered |
