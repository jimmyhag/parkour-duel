# Du poids et du liant : des mouvements moins rapides, des animations qui coulent

**Statut : 🟢 Implémenté**

Session du 2026-11-15, avec Jimmy, après qu'il a joué le mode Chase et le
franchissement : « pour ce qui est des mouvements, je les trouve trop rapides et pas
assez réalistes […] c'est beaucoup trop saccadé dans le sens où c'est animation, puis
autre animation, c'est pas fluide […] peut-être des animations moins rapides, un peu plus
lentes, un peu plus clean ». Il a délégué la façon de faire (« fais en sorte de faire un
truc clean ») et accepte d'aller chercher d'autres animations s'il le faut.

## Contexte

La cause : **le jeu va plus vite que les animations.** Le moteur a été réglé à l'étape 1
sur une capsule ; les clips Mixamo sont de la capture de mouvement à vitesse humaine.

- Les gestes à durée fixe sont très courts : mantle 0,35 s, franchissement 0,4 s, roulade
  0,5 s, réception dure 0,35 s, réception simple 0,25 s. Leurs clips sont coupés (seul un
  morceau passe) et lus jusqu'à 1,8 fois leur vitesse.
- La course : 9 m/s, pour des foulées Mixamo de 4,49 m/s (course) et 5,65 m/s (sprint) ;
  le sprint est lu à 1,59 fois.
- Le saut est trois clips collés (départ du saut, chute, réception), avec des fondus
  linéaires de 0,05 à 0,2 s.

Six clips de plus ont été téléchargés le 2026-11-15 par la session principale sur le
compte de Jimmy (Ch08, sans peau, 30 images par seconde), dans
`C:\Users\jimmy\Documents\mixamo\` : `Fast Run`, `Two Cycle Sprint`, `Running Quickly`
(« Running Forward Quickly »), `Jogging`, `Running Jump` (« Jumping From A Sprint »),
`Land To Run` (« Land From Fall A To Run Forward »). Mêmes règles : jamais dans le dépôt.

Ce que la spec ne doit pas casser : tous les scénarios ; le parcours reste faisable (les
rejeux et leur garantie à plus et moins 10 %) ; sans les fichiers, la capsule ; ce que le
coureur constate ne dépend jamais du corps visible.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Mesurer d'abord | Le développeur dresse la table de chaque clip joué : la partie gardée, sa durée propre, la durée de l'état, la vitesse de lecture ; et, à 144 images par seconde, la variation de vitesse angulaire des os à chaque changement d'état d'un enchaînement type (course, saut, réception, glissade, franchissement, mantle, roulade, wall-run). Avant et après, dans le rapport. | Corriger ce qu'on mesure. |
| 2 | Le plafond de lecture | Aucun clip n'est lu à plus de `animation_max_pace` = **1,25** fois sa vitesse propre (1,8 aujourd'hui). | « Moins rapides, plus clean ». |
| 3 | Des gestes qui prennent leur temps | Les durées des états suivent leurs clips : chaque geste dure le temps de sa partie de clip, lue entre 1,0 et 1,25 fois. Valeurs de départ : **mantle 0,7 s**, **franchissement 0,6 s**, **roulade 0,75 s**, **réception dure 0,6 s**, réception simple 0,35 s. Le développeur les ajuste d'après la table de la décision 1 et les écrit dans la ressource de réglage ; les parties de clips gardées sont choisies pour contenir le geste entier (appui, passage, reprise), pas seulement son début. | Un geste coupé et accéléré se lit comme une saccade. |
| 4 | Une course plus posée | `top_speed` passe de 9 à **8,2 m/s** ; `ground_acceleration` de 30 à **24 m/s²** ; `ground_deceleration` de 45 à **34 m/s²**. La locomotion se mélange sur Idle, Walking, **Jogging**, la course et le sprint ; pour la course et le sprint, le développeur **mesure** la vitesse de foulée de chaque candidat (`Running`, `Running Quickly`, `Fast Run`, `Sprint`, `Two Cycle Sprint`) et garde ceux qui laissent, à la vitesse de pointe et au palier 3 du flow, une lecture sous le plafond avec le pied d'appui à plus ou moins 10 % du sol. Si aucun candidat n'y arrive, il donne les chiffres : la session principale en téléchargera d'autres. | « Trop rapides, pas assez réalistes ». 8,2 m/s reste dans la marge de 10 % garantie du parcours. |
| 5 | Le parcours suit | Si une section du parcours, ou sa garantie à plus et moins 10 %, ne passe plus avec ces réglages, les distances de cette section sont ajustées dans la scène (proportionnellement, en gardant ce qu'elle force) ; le rapport dit ce qui a bougé. L'arène du Chase garde ses règles (murets franchis dans les deux sens, plateformes atteintes par leur rebord). | Ne pas relâcher la garantie : adapter le niveau au coureur. |
| 6 | Un saut d'un seul mouvement | En l'air, la pose ne vient plus de clips enchaînés mais d'une **position dans le saut** pilotée par la vitesse verticale : de l'appel au sommet pendant la montée, du sommet à l'approche du sol pendant la descente, tirée de `Running Jump` (ou de `Jump` à l'arrêt) ; au-delà d'une chute longue, elle se fond dans la boucle `Falling Idle`. La pose change continûment d'un pas à l'autre. | Le saut était « animation, puis autre animation ». |
| 7 | Une réception qui repart | En mouvement, la réception joue `Land To Run` et rejoint la course à la bonne phase de foulée ; à l'arrêt, `Landing`. | Atterrir puis recourir d'un seul geste. |
| 8 | Des fondus adoucis | Les fondus suivent une courbe adoucie (départ et arrivée à vitesse nulle), plus un fondu linéaire. Défaut **0,2 s** ; table de départ : course → saut 0,12 ; air → réception 0,08 ; réception → course 0,25 ; course → glissade 0,15 ; glissade → course 0,25 ; vers le franchissement 0,12, depuis lui 0,2 ; vers le mantle 0,12, depuis lui 0,25 ; vers la roulade 0,1, depuis elle 0,25 ; réception dure 0,06. Seul le crash reste sans fondu. | Le liant entre deux animations. |
| 9 | La mesure de la fluidité | À 144 images par seconde, sur l'enchaînement type de la décision 1, aucun os ne dépasse, à un changement d'état, **2,5 fois** la médiane de sa vitesse angulaire des 8 images voisines (crash excepté). Mesuré localement avec les fichiers, rapporté transition par transition. | Un seuil chiffré pour « fluide ». |
| 10 | Ce qui ne change pas | Le saut lui-même (hauteur, gravités), les figures (leurs durées et leurs règles), le wall-run, le flow. | Une passe à la fois ; Jimmy jugera ensuite. |
| 11 | La logique testable | La limite de lecture, la position dans le saut, la courbe des fondus, le choix de la réception et les poids de la locomotion sont des fonctions pures testées sans les fichiers ; `just mixamo` copie les clips retenus (pas les candidats écartés) ; le README les liste. | La CI tourne sans Mixamo. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Du poids et du liant

  Scénario: Aucun clip n'est lu à plus de 1,25 fois sa vitesse
    Soit chaque état à durée fixe et chaque vitesse au sol jusqu'au palier 3 du flow, avec le réglage du projet
    Quand on calcule la vitesse de lecture de son clip
    Alors elle ne dépasse jamais le plafond réglé

  Scénario: Chaque geste dure le temps de son clip
    Soit le mantle, le franchissement, la roulade et les réceptions
    Quand on compare la durée de l'état à la durée propre de la partie de clip gardée
    Alors la lecture est entre 1,0 et le plafond

  Scénario: La pose en l'air suit la vitesse verticale
    Soit un coureur qui saute, monte, passe son sommet et redescend
    Quand on suit sa position dans le saut à chaque pas
    Alors elle avance de l'appel au sommet pendant la montée, du sommet à l'approche du sol pendant la descente, sans saut d'un pas à l'autre

  Scénario: Une longue chute rejoint la boucle de chute
    Soit un coureur qui tombe plus longtemps que la descente d'un saut
    Quand on choisit son animation
    Alors elle se fond dans la boucle de chute

  Scénario: Une réception en mouvement repart en courant
    Soit un coureur qui atterrit en avançant, puis un coureur qui atterrit à l'arrêt
    Quand on choisit son animation
    Alors c'est Land To Run, puis Landing

  Scénario: Les fondus sont adoucis
    Soit un fondu entre deux animations
    Quand on suit son poids
    Alors il part et arrive à vitesse nulle, vaut la moitié à mi-parcours, et dure le temps de sa paire

  Scénario: La locomotion passe par le jogging
    Soit un coureur au sol entre la marche et la course
    Quand on calcule les poids de la locomotion
    Alors le jogging y a sa part, et les poids font toujours un tout

  Scénario: Le parcours reste faisable avec les nouveaux réglages
    Soit la vitesse de pointe, les accélérations et les durées des gestes de cette spec
    Quand le pilote rejoue chaque section, et sa garantie à plus et moins 10 %
    Alors il les franchit toutes

  Scénario: La copie range les clips retenus
    Soit un dossier de téléchargement avec tous les fichiers
    Quand on lance la commande de copie
    Alors assets/mixamo contient Jogging, Running Jump, Land To Run et les courses retenues
```

Avec les fichiers, le développeur vérifie localement la décision 9 (aucun à-coup aux
changements d'état) et le pied d'appui à plus ou moins 10 %, et rapporte les chiffres.

## Choix acceptés après le développement

Acceptés le 2026-11-15 par la session principale (délégation de Jimmy) ; Jimmy peut
rouvrir chacun après avoir joué.

- **Aucune course Mixamo n'a la foulée voulue** (décision 4). Mesurées : Running Quickly
  3,45 m/s, Fast Run 5,5, Sprint 5,6, Two Cycle Sprint 5,9 ; il faudrait 6,56 à la
  vitesse de pointe et 7,54 au palier 3. Running et Sprint restent, plafonnés à 1,25 :
  le pied d'appui glisse d'environ 14 % à la vitesse de pointe et 25 % au palier 3. Le
  plafond passe avant les pieds (« moins rapides ») ; Jimmy juge en jouant, et l'on
  choisira ensuite entre un pack de courses plus rapides, un plafond propre à la
  locomotion, ou une vitesse de pointe plus basse.
- **Le seuil de fluidité (décision 9) vaut pour le corps, sans orteils ni doigts** : le
  clip de sprint dépasse déjà 2,5 sur l'orteil en course stable, sans aucun changement
  d'état. Mesuré : 2,42 au plus pour le corps.
- **Réception simple à 0,4 s** (et non 0,35), pour garder l'amorti.
- **Gestes longs** : le mantle (1,45 s de fichier) et la réception dure (1,5 s) ne
  tiennent pas entiers sous le plafond ; on garde la traction et l'impact, et chaque
  geste continue dans son clip pendant un suivi de 0,25 s, le temps de son fondu de
  sortie.
- **Seuils** : « en mouvement » veut dire plus vite que la marche ; une longue chute,
  plus vite qu'un saut complet n'atterrit, plus un pas de gravité ; la position dans le
  saut avance au plus à deux fois l'allure d'un saut.
- **Arène du Chase** : le passage bas Nord recule d'un mètre (z −7,5 à −8,5), pour que
  le franchissement du muret Nord ne se pose pas dessous.
- **`just check` met de 90 à 97 s** avec les fichiers Mixamo sur la machine de Jimmy, au
  bord ou au-dessus de la limite de 90 s ; il dépassait déjà avant cette passe. À traiter
  dans sa propre demande.

## Hors périmètre

- Refaire l'arène du Chase « plus propre » : la spec suivante, avec Jimmy.
- Ralentir les figures, changer le saut : après avoir joué cette passe.
- Les pieds qui s'adaptent au sol (IK), l'inertie des fondus par pose : plus tard.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Accorder les durées du jeu à celles de la capture de mouvement | — | discovered |
| Piloter une pose par une grandeur physique (la vitesse verticale) plutôt que par le temps | — | discovered |
