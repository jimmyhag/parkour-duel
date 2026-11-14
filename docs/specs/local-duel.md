# Duel local : deux couloirs, un fantôme, un bot, une manche

**Statut : 🟡 Prêt pour le dev**

Session du 2026-11-14. Étape 4 de la feuille de route, la dernière avant le point
d'arrêt n° 3. Jimmy a délégué toute la conception (« enchaîne sur tout le reste […]
fais tout jusqu'à ce que tu puisses plus faire ») : chaque décision ci-dessous est la
recommandation de l'assistant, prise à sa place, et Jimmy peut rouvrir chacune après
avoir joué. Son développement commence quand l'étape 3 (`docs/specs/sabotage.md`) est
fusionnée.

## Contexte

Le plan (étape 4) : « Deux couloirs miroirs ; adversaire = fantôme enregistré, puis bot
simple qui court et sabote ; règles de manche complètes, écran de résultat, revanche. À
la fin de cette étape, le jeu est jouable et amusant **sans réseau**. **Point d'arrêt
n° 3.** » Et sa vision : deux joueurs sur deux parcours identiques côte à côte, chacun
voit l'autre ; victoire au premier arrivé ; le score de style départage ; manches de 1 à
3 minutes.

Ce qui existe quand le développement commence : le parcours de dix sections
(`game/levels/test_course.tscn`, `Course`), le chrono et les checkpoints (`RaceState`),
le flow, le combo, les munitions et les figures (étape 2), la visée, le tir, les quatre
types de cibles et leurs messages datés (étape 3), le pilote de test
(`tests/pilot_intent_source.gd`), qui franchit chaque section seul en ne lisant que ce
qu'il sonde.

Ce que la spec ne doit pas casser : tous les scénarios antérieurs ; les règles
d'`AGENTS.md` ; le mode solo d'entraînement de l'étape 3 ; la limite de 30 s de
`just preflight` (décision 16).

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | « Couloirs miroirs » | Deux **copies identiques** du parcours, côte à côte, décalées sur le côté, dans le même sens. Pas de symétrie gauche-droite : une échelle négative casse la physique dans Godot. L'écart est le plus petit qui laisse au moins 4 m de vide entre les blocs les plus proches des deux couloirs. | Le plan : « deux parcours identiques côte à côte ». Identiques, ils sont équitables par construction. |
| 2 | Un couloir | Le parcours devient une scène de couloir (blocs, cibles, checkpoints, lignes), instanciée deux fois par la scène du duel. Chaque couloir a son `RaceState`, son flow, ses munitions, ses cibles. Le mode solo d'entraînement reste : un seul couloir, ses propres cibles, comme à l'étape 3. | Une seule source pour le parcours ; le solo ne régresse pas. |
| 3 | Qui on vise en duel | En duel, un coureur ne peut tirer que sur les cibles du **couloir adverse** ; les cibles de son couloir ne sont pas tirables par lui. La portée du tir (`shot_range`) est réglée pour qu'une cible adverse soit tirable depuis la section d'avant du couloir du tireur. | La vision du plan : on sabote le décor de l'autre. |
| 4 | Se voir | Chaque coureur voit l'autre : l'adversaire est une capsule d'une autre couleur (orange), avec sa visière. Le fantôme est la même capsule, à moitié transparente. | « Chacun voit l'autre ». |
| 5 | Choisir son adversaire | Un écran de départ minimal, au clavier et à la manette, propose **« SOLO PRACTICE »**, **« DUEL VS GHOST »** et **« DUEL VS BOT »**. Le duel contre le fantôme est grisé, avec la raison « FINISH A SOLO RUN FIRST », tant qu'aucune course solo n'est finie dans la session. | Il faut choisir entre fantôme et bot ; les vrais menus sont l'étape 6. |
| 6 | Le fantôme | Le fantôme rejoue la **meilleure course solo de la session**, pas à pas : la position et l'orientation du corps visible enregistrées à chaque pas fixe. Il n'a pas de collision, pas de flow, ne sabote pas et n'est pas saboté. Il est dans le couloir adverse. Rien n'est enregistré sur le disque. | Le plan : « fantôme enregistré ». Rejouer des positions est exact ; rejouer des intentions dépendrait du déterminisme de la physique. |
| 7 | Le bot | Un coureur complet dans le couloir adverse : même moteur, même réglage, même flow, mêmes munitions, mêmes règles. Il est mené par le pilote, déplacé de `tests/` vers `game/player/` puisqu'il a désormais un consommateur dans le jeu (les tests le gardent). Section après section, le bot court dans la direction du checkpoint de la section où il est. Il ne fait pas de figure. | Le plan : « bot simple qui court et sabote ». Le pilote franchit déjà chaque section. |
| 8 | Le bot sabote | Quand le bot a assez de munitions, qu'une cible prête du couloir du joueur est à sa portée et que le **joueur** est à moins de `bot_sabotage_lead` (25 m) avant cette cible, il vise pendant `bot_aim_time` (0,8 s), ralenti comme un joueur qui vise, puis tire si la cible est toujours prête et tirable. Sa ligne de tir part de sa tête. Il préfère la cible la moins chère. | Un bot qui sabote au bon moment donne du sens à l'alerte (`docs/specs/sabotage.md`, décision 8). Il paie le ralenti de la visée comme le joueur. |
| 9 | La manche | **Compte à rebours** « 3 », « 2 », « 1 », « GO » d'une seconde chacun, coureurs immobiles à leur départ ; la course démarre pour les deux au même pas. Le **premier qui franchit l'arrivée** gagne. Arrivés au même pas : le plus haut score de style gagne ; même score : égalité. Limite de **3 minutes** : si personne n'a fini, celui qui a atteint le checkpoint le plus loin gagne, puis le score de style, puis égalité. Contre le fantôme, le joueur gagne s'il arrive avant la fin de la course du fantôme. | Le plan : premier arrivé, le style départage, manches de 1 à 3 minutes. |
| 10 | Pendant la manche | Retour au checkpoint et chute fonctionnent comme en solo, le chrono ne s'arrête pas. **Recommencer** (Backspace / Back) n'existe pas en duel : il est remplacé par la revanche, à l'écran de résultat. | On ne recommence pas seul une manche à deux. |
| 11 | L'écran de résultat | À la fin de la manche : **« YOU WIN »**, **« YOU LOSE »** ou **« DRAW »** ; le temps et le score de style de chacun (« DNF » pour qui n'a pas fini) ; deux choix : **« REMATCH »** (même adversaire, même couloir) et **« MENU »** (l'écran de départ). Saut (Espace / A) choisit, la direction change de choix. | Le plan : « écran de résultat, revanche ». |
| 12 | La revanche | Remet les deux couloirs, leurs cibles, flows, munitions et chronos à zéro, puis relance le compte à rebours. Le fantôme d'une revanche est la meilleure course solo, inchangée. | |
| 13 | Le réseau, plus tard | Chaque coureur a un identifiant de joueur (0 et 1). Les messages de sabotage portent l'identifiant du tireur. L'état de la manche (compte à rebours, en cours, finie, résultat) est un état de `core`, sans scène, qui ne voit que des messages datés : départ, checkpoint atteint, arrivée, limite de temps. | Règles d'`AGENTS.md` ; l'étape 5 fera passer ces messages par le réseau. |
| 14 | Le HUD en duel | En haut, le chrono ; à côté, l'écart avec l'adversaire au dernier checkpoint commun (« +1.24 » ou « -0.80 », en secondes). Le HUD du flow est celui du joueur. Le flow et les munitions du bot ne s'affichent pas, sauf dans l'affichage de debug. | Savoir si on est devant, sans encombrer. |
| 15 | Les réglages | Les valeurs de cette spec (compte à rebours, limite de manche, durées et distances du bot) vivent dans la ressource de réglage unique, groupe « Duel ». | Règle d'`AGENTS.md`. |
| 16 | La durée des tests | Les rejeux du parcours entier (le bot, le fantôme, les deux couloirs) vivent dans des scripts `test_course*` : `just preflight` les saute, `just check` et la CI les lancent (`docs/specs/test-tiers.md`, fusionnée depuis). `just check` reste sous 90 s ; si un rejeu le menace, le développeur s'arrête et le dit. | La boucle rapide reste rapide ; la porte du commit garde tout. |
| 17 | Une alerte qui laisse toujours une chance | En duel, la touche doit toujours pouvoir s'éviter. La seconde inspection du sabotage a mesuré qu'une alerte de plateforme lancée entre 0,4 s avant l'appel d'un saut long et 0,25 s après rend la chute inévitable. Règle : une plateforme ou un pont en alerte **ne commence pas son effet tant qu'un coureur est en l'air au-dessus de lui** ; l'effet commence au premier pas où personne n'y est en l'air (un coureur posé dessus est touché comme avant). La durée de l'effet compte depuis son vrai début. | Le plan : être touché casse le combo, mais une touche impossible à éviter n'est que de la malchance. |

### Valeurs de départ ajoutées à la ressource de réglage

| Réglage | Valeur |
| ------- | ------ |
| Compte à rebours, par chiffre | 1 s |
| Limite d'une manche | 180 s |
| Bot : avance du joueur sur une cible pour la saboter | 25 m |
| Bot : temps de visée avant de tirer | 0,8 s |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Duel local

  # --- La manche (core) ---

  Scénario: Le compte à rebours précède la course
    Soit une manche qui commence
    Quand le compte à rebours se déroule
    Alors les coureurs ne peuvent pas bouger avant « GO », et les deux chronos démarrent au même pas

  Scénario: Le premier arrivé gagne
    Soit une manche en cours
    Quand le joueur franchit l'arrivée avant l'adversaire
    Alors le joueur gagne

  Scénario: Une arrivée au même pas se départage au style
    Soit deux coureurs qui franchissent l'arrivée au même pas
    Quand la manche se termine
    Alors celui qui a le plus haut score de style gagne, et égalité si les scores sont égaux

  Scénario: La limite de temps départage au checkpoint
    Soit une manche où personne n'a fini à la limite de temps
    Quand la limite est atteinte
    Alors celui qui a atteint le checkpoint le plus loin gagne, puis le score de style, puis égalité

  Scénario: Pas de recommencement en duel
    Soit une manche en cours
    Quand le joueur demande à recommencer
    Alors rien ne se passe

  Scénario: La revanche remet tout à zéro
    Soit une manche finie
    Quand le joueur choisit la revanche
    Alors les deux couloirs, leurs cibles, flows, munitions et chronos sont remis à zéro, et le compte à rebours recommence

  # --- Les couloirs (vraie physique) ---

  Scénario: Les deux couloirs sont identiques et séparés
    Soit la scène du duel
    Quand on compare les deux couloirs
    Alors ils ont les mêmes blocs, cibles et checkpoints, décalés sur le côté, avec au moins 4 m de vide entre eux

  Scénario: En duel, on ne tire que sur le couloir adverse
    Soit un joueur en visée en duel, le réticule sur une cible prête de son propre couloir
    Quand il tire
    Alors rien ne se passe et rien n'est dépensé

  Scénario: Une cible adverse se tire depuis la section d'avant
    Soit chaque cible du couloir adverse
    Quand le joueur est dans la section d'avant, dans son couloir
    Alors elle est à portée de tir

  Scénario: Le solo d'entraînement reste comme à l'étape 3
    Soit le mode solo
    Quand le joueur tire sur une cible de son couloir
    Alors elle est sabotée comme à l'étape 3

  Scénario: Une plateforme n'agit pas sous un coureur en l'air
    Soit une plateforme en alerte et un coureur qui saute au-dessus d'elle à la fin de l'alerte
    Quand l'alerte se termine pendant qu'il est en l'air au-dessus
    Alors l'effet attend qu'il ne soit plus en l'air au-dessus, puis commence

  # --- Le fantôme ---

  Scénario: Le fantôme rejoue la meilleure course solo
    Soit une course solo finie dans la session
    Quand un duel contre le fantôme commence
    Alors à chaque pas, le fantôme est où était le coureur au même pas de sa meilleure course, dans le couloir adverse

  Scénario: Le fantôme ne touche rien
    Soit un duel contre le fantôme
    Quand le fantôme traverse une cible ou le joueur
    Alors rien ne se passe

  Scénario: Le duel contre le fantôme demande une course solo
    Soit une session sans course solo finie
    Quand l'écran de départ s'affiche
    Alors « DUEL VS GHOST » est grisé avec « FINISH A SOLO RUN FIRST »

  # --- Le bot (vraie physique) ---

  Scénario: Le bot franchit le parcours entier
    Soit un duel contre le bot, sans joueur qui le gêne
    Quand la manche se déroule
    Alors le bot franchit l'arrivée avant la limite de temps

  Scénario: Le bot sabote quand le joueur approche d'une cible
    Soit le bot avec une munition, et le joueur à moins de l'avance de sabotage d'une cible prête de son couloir, à portée du bot
    Quand le temps de visée du bot est passé
    Alors un message de sabotage du bot vise cette cible

  Scénario: Le bot paie la visée
    Soit le bot qui vise
    Quand il court au sol
    Alors sa vitesse de pointe est celle de la visée

  Scénario: Le bot ne tire pas sans munitions
    Soit le bot sans munition, et le joueur près d'une cible prête
    Quand des pas s'écoulent
    Alors aucun message de sabotage ne part du bot

  # --- Écrans ---

  Scénario: L'écran de départ se navigue aux deux claviers
    Soit l'écran de départ
    Quand le joueur change de choix et valide, au clavier puis à la manette
    Alors le mode choisi démarre

  Scénario: L'écran de résultat montre la manche
    Soit une manche gagnée par le joueur, l'adversaire n'ayant pas fini
    Quand l'écran de résultat s'affiche
    Alors il montre « YOU WIN », le temps et le score de style du joueur, et « DNF » pour l'adversaire, avec « REMATCH » et « MENU »

  Scénario: Le HUD montre l'écart avec l'adversaire
    Soit un duel où les deux coureurs ont passé le même checkpoint, le joueur 1,24 s après l'adversaire
    Quand le HUD se met à jour
    Alors il affiche « +1.24 »
```

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** :

  | Composant | Couche | Statut |
  | --------- | ------ | ------ |
  | Écran de départ | `game/ui/` | créé : aucun menu n'existe |
  | Compte à rebours | `game/ui/` | créé |
  | Écran de résultat | `game/ui/` | créé |
  | HUD de la course | `game/ui/` | modifié : écart avec l'adversaire |
  | Scène de couloir, scène du duel | `game/levels/` | créées à partir du parcours actuel |

- **États** :
  - écran de départ : trois choix, le premier sélectionné ; le fantôme grisé avec sa
    raison tant qu'aucune course solo n'est finie ;
  - compte à rebours : un grand chiffre au centre, puis « GO » ;
  - course : chrono, écart, HUD du flow ;
  - résultat : le verdict en grand, une ligne par coureur (« YOU » et « GHOST » ou
    « BOT », temps ou « DNF », « STYLE <score> »), deux choix.
- **Focus** : à l'ouverture de chaque écran, le premier choix ; haut et bas (touches,
  stick, croix) changent de choix ; saut valide ; Esc ou Back revient à l'écran de
  départ depuis le résultat.
- **Libellés** (en anglais) : « SOLO PRACTICE », « DUEL VS GHOST », « DUEL VS BOT »,
  « FINISH A SOLO RUN FIRST », « 3 », « 2 », « 1 », « GO », « YOU WIN », « YOU LOSE »,
  « DRAW », « YOU », « GHOST », « BOT », « DNF », « STYLE », « REMATCH », « MENU ».

## Hors périmètre

- Le jeu en ligne, deux joueurs sur deux machines : étape 5, après le point d'arrêt n° 3.
- Deux joueurs sur le même écran (écran partagé) : non demandé par le plan.
- Plusieurs niveaux de bot, des figures pour le bot : plus tard.
- Enregistrer les fantômes sur le disque : plus tard.
- Les vrais menus (options, touches) : étape 6.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Un état de manche dans `core`, nourri de messages datés, prêt pour le réseau | — | discovered |
| Fantôme par positions enregistrées contre rejeu d'intentions | — | discovered |
