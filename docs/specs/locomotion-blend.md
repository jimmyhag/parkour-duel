# Une locomotion fluide : blend space, transitions réglées, pieds en phase

**Statut : 🟢 Implémenté**

Session du 2026-11-14, avec Jimmy. Suite de `docs/specs/character-animations.md` : Jimmy
a demandé « tout ce qui est blend space, pour fluidifier les animations, les
enchaînements », puis : « gère ». Il a délégué les choix ; il juge en jouant. Son
développement commence quand la pose du wall-run (décision 12 de
`docs/specs/character-animations.md`) est fusionnée.

## Contexte

Aujourd'hui (`game/core/runner_animation.gd`, `game/player/runner_character.gd`) : un
fondu fixe de 0,1 s entre deux clips, `Running` dont la vitesse de lecture suit la
vitesse horizontale, `Idle` sous 0,5 m/s ; pas de marche, pas de sprint. Démarrer et
s'arrêter passent d'`Idle` à `Running` d'un fondu.

Deux clips de plus ont été téléchargés le 2026-11-14 par la session principale dans le
dossier de Jimmy (`C:\Users\jimmy\Documents\mixamo\`), sur le personnage Ch08, sans
peau, 30 images par seconde, sur place : `Walking.fbx` (« Standard Walk ») et
`Sprint.fbx` (« Sprint », « Standard Sprint »). Ils suivent les mêmes règles que les
autres : jamais dans le dépôt, copiés par `just mixamo`.

Ce que la spec ne doit pas casser : tous les scénarios ; sans les fichiers, la capsule ;
ce que le coureur constate ne dépend jamais du corps visible.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Le blend space de locomotion | Au sol, debout, un mélange continu sur la vitesse horizontale : `Idle` (0), `Walking`, `Running` (vitesse de pointe du réglage), `Sprint` (vitesse de pointe avec le bonus du palier 3 du flow et au-delà). **Amendement (2026-11-14, après `docs/specs/animation-polish.md`)** : les foulées Mixamo sont courtes (course 4,49 m/s, sprint 5,65 m/s) ; pour que le pied suive le sol sans cadence frénétique, `Running` est seul à sa vitesse propre multipliée par 1,3, et `Sprint` seul **dès la vitesse de pointe** ; au-delà, le sprint accélère. Le plafond de vitesse de lecture (`animation_max_pace`) est **1,8**. Les points de passage sont des réglages (groupe Animation), placés chacun à la vitesse propre de son clip. Les clips mélangés jouent à une vitesse qui garde les pieds sans glisser. | Démarrages, arrêts et changements d'allure sans à-coup ; le sprint montre le flow. |
| 2 | Les pieds en phase | Les clips du blend space sont calés sur la même phase de foulée (pied gauche au sol au même temps relatif) ; le mélange ne fait jamais deux foulées décalées. | Sans cela, les jambes se croisent pendant le mélange. |
| 3 | Les transitions, paire par paire | Les fondus deviennent une table (dans la ressource de réglage) : un temps par paire « de → vers », avec une valeur par défaut. Valeurs de départ : course → saut 0,05 s ; saut → chute 0,15 s ; chute → réception 0,05 s ; réception → course 0,15 s ; course → glissade 0,08 s ; glissade → course 0,2 s ; course → wall-run 0,1 s ; wall-run → chute 0,15 s ; vers la pose groupée 0,08 s ; depuis la pose groupée 0,12 s ; défaut 0,1 s. Les entrées brusques (crash, réception dure) restent sans fondu. | Chaque enchaînement a sa vitesse naturelle. |
| 4 | La reprise de la course | En revenant à la course (après une réception, une glissade, un wall-run), le blend space reprend à la phase de foulée la plus proche de la pose d'où l'on vient, pas au début du clip. | Les pieds ne sautent pas à la reprise. |
| 5 | Les fichiers | `just mixamo` copie aussi `Walking.fbx` et `Sprint.fbx` ; le personnage n'apparaît que si tous les clips sont là (règle actuelle) ; le README liste les deux nouveaux téléchargements. | Même circuit que les autres fichiers. |
| 6 | La logique testable | Les poids du blend space pour une vitesse, la table des transitions et la phase de reprise sont des fonctions pures testées sans les fichiers ; l'AnimationTree est de la présentation, vérifiée localement avec les fichiers. | Les tests tournent dans la CI sans Mixamo. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Une locomotion fluide

  Scénario: Les poids du blend space suivent la vitesse
    Soit un coureur au sol à l'arrêt, entre la marche et la course, à sa vitesse de pointe, puis au-delà avec le flow
    Quand on calcule les poids de la locomotion
    Alors c'est Idle seul, un mélange de Walking et Running, Running seul, puis un mélange de Running et Sprint

  Scénario: Les poids font toujours un tout
    Soit n'importe quelle vitesse au sol
    Quand on calcule les poids de la locomotion
    Alors ils sont entre 0 et 1, au plus deux sont non nuls, et leur somme vaut 1

  Scénario: Les clips mélangés gardent la même phase
    Soit deux clips voisins du blend space
    Quand ils sont mélangés
    Alors ils sont à la même phase de foulée

  Scénario: Chaque enchaînement a son temps de fondu
    Soit la table des transitions
    Quand on demande le fondu de la course au saut, de la glissade à la course, et d'une paire absente de la table
    Alors c'est la valeur de chaque paire, et la valeur par défaut pour la paire absente

  Scénario: Une entrée brusque reste sans fondu
    Soit un coureur qui court
    Quand il fait une réception dure, puis un crash
    Alors l'animation change sans fondu

  Scénario: La course reprend à la bonne foulée
    Soit un coureur qui sort d'une glissade, puis d'une réception
    Quand il revient à la course
    Alors la locomotion reprend à la phase de foulée la plus proche de la pose d'où il vient

  Scénario: La copie range aussi la marche et le sprint
    Soit un dossier de téléchargement avec tous les fichiers, Walking et Sprint compris
    Quand on lance la commande de copie
    Alors assets/mixamo contient Walking et Sprint
```

La présentation (le mélange à l'écran, les pieds qui ne glissent pas, les reprises) se
vérifie localement avec les fichiers, et Jimmy la juge en jouant.

## Hors périmètre

- Les pieds qui s'adaptent au sol (IK) : plus tard, si Jimmy le demande.
- Des clips de démarrage et d'arrêt dédiés : le blend space suffit pour commencer.
- Le jeu en ligne : étape 5.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Blend space : mélanger des clips selon une valeur continue, en phase | — | discovered |
