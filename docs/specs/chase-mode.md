# Le mode Chase : un chat, une souris, une arène d'obstacles

**Statut : 🟢 Implémenté**

Session du 2026-11-14, avec Jimmy (« oui pour tout, je te fais confiance »). Jimmy a vu
les vraies compétitions de poursuite en arène (« des vraies compètes de chat et souris
[…] où t'as quelqu'un qui doit attraper ») et pense que c'est la bonne direction pour le
jeu. Ce mode est un **prototype** pour juger le fun : le duel en couloirs reste jouable
tant que Jimmy n'a pas décidé de pivoter. On reprend le genre, pas une compétition
existante (ni son nom, ni son logo, ni son arène).

## Contexte

Ce qui existe : le déplacement complet, les figures dessinées et la réception, le flow
(jauge, paliers, bonus de vitesse), le personnage animé, l'écran de départ et ses modes
(`docs/specs/local-duel.md`), l'état de manche de `core` (`RoundState`). Le franchissement
(`docs/specs/vault.md`) est développé en parallèle ; l'arène est faite pour lui.

Ce que la spec ne doit pas casser : tous les scénarios ; les autres modes ; les règles
d'`AGENTS.md` (chaque action aux deux claviers, `core` sans scène ni entrée).

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Le mode | Un nouveau choix **« CHASE »** dans l'écran de départ. | Q1. |
| 2 | Les joueurs | **Deux joueurs sur la même machine, en écran partagé** (gauche et droite) : le joueur 1 au clavier-souris, le joueur 2 à la manette. Chacun a sa caméra et son HUD. Si aucune manette n'est branchée, l'écran de départ le dit et le mode attend. | Q7 : juger le fun sans attendre un bot. |
| 3 | La manche | Un joueur est le **chat**, l'autre la **souris**. La manche dure **20 s**. Si le chat **touche** la souris (les deux capsules se touchent), le chat gagne la manche ; si les 20 s passent, la souris la gagne. Les rôles s'**échangent** à chaque manche ; le premier à **3 manches** gagne la partie. Entre deux manches, un écran court (le gagnant de la manche, le score, « 3, 2, 1, GO »). | Q2. |
| 4 | L'état de partie | Un état de `core`, nourri de messages datés (départ, contact, fin du temps), comme `RoundState` : il dit qui est chat, le temps restant, le score, le vainqueur. Le contact est constaté par `levels` (les deux corps) et devient un message. | Prêt pour le réseau. |
| 5 | L'arène | Environ **20 m × 20 m**, fermée par des murs (sans wall-run sur l'enceinte), dense : des **murets franchissables** (0,8 à 1,2 m), des **blocs à hisser** (1,5 à 2 m), des **murs** pour le wall-run et les wall-jumps, des **passages bas** pour glisser, **une ou deux plateformes** en hauteur reliées par des rebords. Les deux joueurs partent face à face à environ **10 m**. Chaque mur est un seul bloc (règle d'`AGENTS.md`). | Q3 : la poursuite se gagne aux franchissements. |
| 6 | Se repérer | Le chat est en **rouge**, la souris en **bleu** (teinte du personnage, ou de la capsule sans les fichiers), et un indicateur au bord de l'écran montre où est l'autre quand il est hors champ. Le HUD de chacun dit son rôle (« CAT » ou « MOUSE ») et le temps restant. | Lisible en écran partagé. |
| 7 | Le flow dans ce mode | Le flow, les figures et leurs paliers donnent le **bonus de vitesse** comme ailleurs ; pas de munitions, pas de tir, pas de cible. Le flow repart de zéro à chaque manche. | Q6 : une figure posée peut sauver la souris. |
| 8 | Les entrées | Les entrées du joueur 1 ne lisent que le clavier et la souris ; celles du joueur 2 que la manette (périphérique 0). En solo, rien ne change (les deux restent possibles). | Deux joueurs sur une machine. |
| 9 | Hors de l'arène | Une chute hors de l'arène (impossible en principe) ramène le joueur à son point de départ, le temps continue. | Pas de blocage. |
| 10 | Les réglages | Durée de manche, manches pour gagner, distance de départ et couleurs dans la ressource de réglage (groupe « Chase »). | Règle d'`AGENTS.md`. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Le mode Chase

  # --- La partie (core) ---

  Scénario: Le chat qui touche la souris gagne la manche
    Soit une manche en cours
    Quand le contact entre le chat et la souris arrive avant la fin du temps
    Alors le chat gagne la manche

  Scénario: La souris qui tient le temps gagne la manche
    Soit une manche en cours
    Quand les 20 secondes passent sans contact
    Alors la souris gagne la manche

  Scénario: Les rôles s'échangent à chaque manche
    Soit une manche finie
    Quand la suivante commence
    Alors le chat est devenu la souris et la souris le chat

  Scénario: Le premier à trois manches gagne
    Soit une partie où un joueur a deux manches
    Quand il gagne la troisième
    Alors la partie est finie et il la gagne

  Scénario: Le flow repart de zéro à chaque manche
    Soit un joueur avec de la jauge à la fin d'une manche
    Quand la suivante commence
    Alors sa jauge est vide

  # --- L'arène (vraie physique) ---

  Scénario: L'arène a tous ses obstacles
    Soit l'arène du mode Chase
    Quand on mesure ses obstacles
    Alors elle a des murets franchissables, des blocs à hisser, des murs à wall-run, des passages bas et au moins une plateforme, dans environ 20 m sur 20 m, chaque mur d'un seul bloc

  Scénario: Le contact des deux corps est constaté
    Soit deux coureurs dans l'arène qui se rapprochent
    Quand leurs capsules se touchent
    Alors un message de contact daté part vers la partie

  Scénario: Les deux joueurs partent face à face
    Soit une manche qui commence
    Quand le compte à rebours se termine
    Alors les deux coureurs sont à leur point de départ, à environ 10 m l'un de l'autre, face à face

  # --- Écrans et entrées ---

  Scénario: Le mode se choisit dans l'écran de départ
    Soit l'écran de départ avec une manette branchée
    Quand on choisit « CHASE »
    Alors la partie démarre en écran partagé

  Scénario: Sans manette, le mode attend
    Soit l'écran de départ sans manette
    Quand on choisit « CHASE »
    Alors l'écran dit qu'il faut une manette pour le joueur 2

  Scénario: Chaque joueur n'obéit qu'à son périphérique
    Soit une partie en écran partagé
    Quand le clavier pousse en avant, puis la manette
    Alors seul le joueur 1 avance, puis seul le joueur 2

  Scénario: Chaque HUD dit son rôle et le temps
    Soit une manche en cours
    Quand les HUD se mettent à jour
    Alors chacun affiche « CAT » ou « MOUSE » et le temps restant

  Scénario: L'indicateur montre l'autre hors champ
    Soit l'autre joueur derrière la caméra
    Quand le HUD se met à jour
    Alors un indicateur au bord de l'écran montre sa direction
```

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** : écran de départ (modifié : « CHASE ») ; HUD de poursuite
  (créé : rôle, temps, indicateur de l'autre) ; écran entre deux manches (créé) ; écran de
  fin de partie (réutilise l'écran de résultat du duel si possible) ; arène (créée).
- **États** : compte à rebours ; manche en cours (rôle, temps, indicateur) ; fin de
  manche (« CAT WINS » ou « MOUSE WINS », le score) ; fin de partie (« PLAYER 1 WINS » ou
  « PLAYER 2 WINS », « REMATCH », « MENU ») ; manette manquante (« CONNECT A GAMEPAD FOR
  PLAYER 2 »).
- **Libellés** (en anglais) : « CHASE », « CAT », « MOUSE », « CAT WINS », « MOUSE
  WINS », « PLAYER 1 WINS », « PLAYER 2 WINS », « CONNECT A GAMEPAD FOR PLAYER 2 »,
  « REMATCH », « MENU ».

## Choix acceptés après le développement

Acceptés le 2026-11-15 ; Jimmy peut rouvrir chacun après avoir joué.

- **Pas de visée, de tir, de retour au checkpoint ni de recommencement** dans ce mode ;
  les munitions ne s'affichent pas.
- **Entre deux manches**, le HUD et la couleur montrent déjà le rôle de la manche
  suivante ; les joueurs sont replacés à leur départ dès la fin d'une manche ; l'écran du
  vainqueur reste affiché pendant le compte à rebours.
- **Le joueur 1 est chat à la première manche** ; chacun part toujours du même côté.
- **Un contact au pas même où le temps finit ne compte pas** : la souris gagne.
- **Le contact est mesuré entre les deux capsules** ; les coureurs peuvent se traverser.
- **Les plateformes** sont atteintes par des rebords, pas reliées entre elles ; les
  passages bas sont des poutres flottantes.
- **Pas de sons du flow ni d'affichage de debug** dans ce mode, pour commencer.
- **« CHASE »** est le dernier choix de l'écran de départ.
- **Les tests de soutien** : la chute hors de l'arène, et l'écran de fin de partie.

### Après l'inspection (2026-11-15)

- **Équilibre** : des bots montraient le chat toujours gagnant. Départ à **14 m** (et non
  10, décision 5 amendée ; `chase_start_distance`) ; à chaque revanche, l'autre joueur est
  chat à la première manche.
- **Plateformes à 4,2 m** (au-dessus d'un saut suivi d'un mantle depuis le sol, calculé
  depuis le réglage), atteintes par un bloc-rebord ; l'enceinte passe à 10 m. Contre le
  chat bot qui fonce droit, une souris sur une plateforme lui échappe ; un chat humain y
  monte par le rebord. À juger en jouant : refuge trop fort ou non.
- **Un contact au pas exact de la fin du temps** ne fige plus la manche : la souris gagne.

## Hors périmètre

- Un bot chat ou souris : après, si le mode plaît.
- Le jeu en ligne : étape 5.
- Plusieurs arènes, des pouvoirs gagnés par le flow (obstacle qui tombe, etc.) : après
  avoir joué.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Écran partagé et entrées par périphérique | — | discovered |
