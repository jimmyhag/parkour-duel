# Le franchissement : passer par-dessus un obstacle sans casser sa course

**Statut : 🟡 Prêt pour le dev**

Session du 2026-11-14, avec Jimmy (« oui pour tout »). Jimmy veut partir vers le format
« chat et souris » (une poursuite dans une arène d'obstacles), avec « beaucoup d'aspects
de franchissement » et des animations « plus propres, plus clean, plus réalistes ». Ce
mouvement est la base de ce format ; `docs/specs/chase-mode.md` s'en sert.

## Contexte

Le coureur sait sauter, glisser, se hisser sur un rebord (mantle, `RunnerMotor.State.MANTLING`,
rebord de 0,9 à 2,2 m au-dessus des pieds, déclenché en l'air contre la face), courir sur
un mur et sauter d'un mur. Il ne sait pas **passer par-dessus** un obstacle bas et fin en
gardant sa vitesse : il doit sauter (et retomber derrière) ou se hisser (et perdre son
élan, sortie à 4 m/s).

Trois clips Mixamo ont été téléchargés le 2026-11-14 par la session principale, sur le
compte de Jimmy, personnage Ch08, sans peau, 30 images par seconde, dans
`C:\Users\jimmy\Documents\mixamo\` : `Vault One Hand.fbx` (« Male Jumping Over An
Obstacle With 1 Hand Planted »), `Vault Two Hands.fbx` (« … With 2 Hands Planted »),
`Ledge Pull Up.fbx` (« Pulling Up To A Ledge »). Ils suivent les règles de
`docs/specs/character-animations.md` : jamais dans le dépôt, copiés par `just mixamo`.

Ce que la spec ne doit pas casser : tous les scénarios (le mantle, la glissade sous un
passage bas, les sauts) ; ce que le coureur constate ne dépend jamais du corps visible ;
les tests sans les fichiers.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Quand franchir | **Au sol**, en courant au moins à `vault_min_speed` (**4 m/s**), poussant vers un obstacle devant soi à moins de `vault_reach` (**0,8 m**), dont le dessus est entre `vault_min_height` (**0,6 m**) et `vault_max_height` (**1,3 m**) au-dessus des pieds, d'une profondeur au plus `vault_max_depth` (**1,5 m**), avec de la place derrière pour se poser debout : le coureur **franchit**, sans bouton. Sinon, rien ne change (il peut sauter, et en l'air le mantle reste). | Le mouvement roi du chat et souris ; automatique comme le mantle et le wall-run. |
| 2 | Le franchissement | Un nouvel état du moteur, `VAULTING`, de durée `vault_duration` (**0,4 s**) : le corps passe par-dessus l'obstacle sur un arc juste au-dessus de son dessus, et ressort de l'autre côté au sol, à `vault_speed_kept` (**90 %**) de sa vitesse d'entrée, dans la même direction. Pendant le franchissement, rien ne l'interrompt (comme le mantle). | Garder le rythme de la poursuite. |
| 3 | Ce que `player` observe | L'obstacle devant (hauteur de son dessus, profondeur, place derrière) est un constat de plus, pris par des sondes dans la direction de la poussée et du mouvement, jamais du corps visible (règle d'`AGENTS.md`). | Même règle que le rebord et le mur. |
| 4 | Le flow | Un franchissement est un move du flow (`VAULT`, **150** points), soumis à la règle de répétition comme les autres. | Le style récompense la fluidité. |
| 5 | L'animation | `Vault One Hand` par défaut ; `Vault Two Hands` quand l'obstacle est plus profond que `vault_two_hands_depth` (**0,8 m**). La partie du clip qui passe par-dessus est calée sur la durée du franchissement, sans dépasser le plafond de vitesse de lecture. | Deux gestes réalistes selon l'obstacle. |
| 6 | Les mains sur l'obstacle | Pendant le franchissement, la ou les mains d'appui se posent **sur le dessus réel** de l'obstacle (placement par IK, `SkeletonIK3D` ou `TwoBoneIK3D` selon ce que Godot 4.7 propose), au moment où le clip pose la main ; le corps suit la hauteur réelle de l'obstacle. Le mantle utilise `Ledge Pull Up` à la place de `Sprint To Wall Climb`, avec les mains posées sur le rebord. | Les animations « plus réalistes » demandées par Jimmy. |
| 7 | Les fichiers | `just mixamo` copie aussi les trois nouveaux clips ; le README les liste avec leur nom Mixamo et leurs réglages. | Même circuit que les autres. |
| 8 | Les réglages | Toutes les valeurs nouvelles vivent dans la ressource de réglage (groupe « Vault ») ; F4 les recharge. | Règle d'`AGENTS.md`. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Le franchissement

  # --- core ---

  Scénario: Un obstacle bas et fin se franchit en courant
    Soit un coureur au sol qui court à 6 m/s vers un muret de 1 m de haut et 0,4 m de profondeur, à portée
    Quand il pousse vers lui
    Alors il franchit, et ressort de l'autre côté au sol à 90 % de sa vitesse, dans la même direction

  Scénario: Trop lent, pas de franchissement
    Soit un coureur au sol qui avance à 2 m/s vers le même muret
    Quand il pousse vers lui
    Alors il ne franchit pas

  Scénario: Trop haut ou trop profond, pas de franchissement
    Soit un coureur qui court vers un muret de 1,6 m, puis vers un bloc de 1 m de haut et 3 m de profondeur
    Quand il pousse vers chacun
    Alors il ne franchit ni l'un ni l'autre

  Scénario: Pas de franchissement sans place derrière
    Soit un muret franchissable avec un mur juste derrière
    Quand le coureur court vers lui en poussant
    Alors il ne franchit pas

  Scénario: Le franchissement va jusqu'au bout
    Soit un coureur en franchissement
    Quand il demande un saut ou une glissade
    Alors il finit son franchissement, puis repart

  Scénario: Le franchissement est un move du flow
    Soit un coureur sans combo
    Quand il franchit un muret
    Alors le flow compte un move VAULT de 150 points

  # --- vraie physique ---

  Scénario: Le pilote franchit un muret dans la vraie physique
    Soit un coureur mené par le pilote, à sa vitesse de pointe, vers un muret de 1 m sur un sol plat
    Quand il arrive dessus
    Alors il passe par-dessus sans s'arrêter et continue de l'autre côté

  Scénario: Le mantle reste pour les rebords hauts
    Soit le rebord de 1,9 m du parcours
    Quand le pilote saute contre lui
    Alors il se hisse comme avant

  # --- présentation (logique testable sans les fichiers) ---

  Scénario: Le geste suit la profondeur de l'obstacle
    Soit un franchissement d'un muret fin, puis d'un obstacle plus profond que le seuil
    Quand on choisit son animation
    Alors c'est Vault One Hand, puis Vault Two Hands

  Scénario: La main se pose sur le dessus de l'obstacle
    Soit un franchissement d'un muret de hauteur donnée
    Quand on calcule la cible de la main d'appui au moment de l'appui
    Alors elle est sur le dessus de l'obstacle, à sa hauteur réelle

  Scénario: La copie range les clips de franchissement
    Soit un dossier de téléchargement avec tous les fichiers, les trois nouveaux compris
    Quand on lance la commande de copie
    Alors assets/mixamo contient Vault One Hand, Vault Two Hands et Ledge Pull Up
```

Avec les fichiers, le développeur mesure localement la main d'appui contre le dessus de
l'obstacle (quelques centimètres au plus) et la rapporte ; Jimmy juge le rendu.

## Hors périmètre

- D'autres franchissements (kong, lazy, passage dessous) : après avoir joué celui-ci.
- Le pilote et le bot qui choisissent de franchir : le pilote franchit parce que le
  mouvement est automatique.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Placement des membres par IK sur le décor réel | — | discovered |
