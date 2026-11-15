# Le Chase en ligne : héberger la partie sur son PC, un ami s'y connecte

**Statut : 🟡 Prêt pour le dev**

Session du 2026-11-15. Jimmy : « est-ce que tu peux me créer une logique pour avoir juste
un serveur qui correspond à mon PC ? Comme ça mon pote peut se connecter à mon serveur
hébergé sur mon propre PC, pour que je puisse tester le jeu avec lui. » C'est le début de
l'étape 5 de la feuille de route (PVP en ligne). Le reste a été délégué à la session
principale.

## Contexte

Le jeu est déjà prêt pour le réseau : la logique est dans `game/core/` sans scène, le
moteur ne reçoit que des intentions (`MoveIntent`), la simulation avance par pas fixes, et
la manche du Chase n'apprend ce qui se passe que par des messages datés (`ChaseMessage`
reçus par `ChaseState`). Le Chase se joue à deux en écran partagé, ou contre un bot en
plein écran (`docs/specs/chase-bot.md`). Il n'y a aucun code réseau, et `game/net/`
n'existe pas.

Ce que Jimmy veut, c'est **tester avec un ami** : pas de serveur dédié ni de service
extérieur, pas de compte, pas de Steam. Le PC de Jimmy héberge la partie et y joue ; l'ami
s'y connecte par son adresse.

Le moteur physique (Jolt) ne garantit pas le même résultat au bit près sur deux machines
différentes. Recalculer les deux coureurs sur chaque machine (le « rollback » des jeux de
combat) est donc risqué. La règle d'or du projet est que **se déplacer seul doit être bon** :
un coureur qui répond avec le retard du réseau serait un recul.

Ce que la spec ne doit pas casser : le Chase à deux, le Chase contre le bot, les autres
modes ; les règles de `chase-tag.md`, de son polissage et de `chase-tag-reach.md` ; la
table des couches et les règles « Ports and adapters » d'`AGENTS.md` (le transport
seulement dans `game/net/`, un contrat en types de `core`, un vrai adaptateur et un faux,
une seule racine de composition, une suite de tests de contrat, les échecs attendus rendus
comme un résultat typé).

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Le mode | Le **Chase** seulement. Un nouveau choix **« CHASE ONLINE »** dans l'écran de départ, après « CHASE VS BOT », qui mène à **« HOST »** et **« JOIN »**. Le duel en ligne viendra dans une autre spec. | Le mode que Jimmy joue en ce moment, déjà à deux. |
| 2 | Qui héberge | Le joueur qui choisit HOST **héberge et joue** : son PC est le serveur. Pas de serveur dédié, aucun service extérieur, aucun compte. Connexion directe par l'adresse, en UDP, avec ENet (fourni par Godot), sur le port **24680** par défaut. | La demande de Jimmy. |
| 3 | Qui simule quoi | **Chaque machine simule son propre coureur**, à partir de ses entrées, sans attendre le réseau. À chaque pas fixe, elle envoie à l'autre un **instantané** de son coureur : la date, la place et l'orientation, la vitesse, l'état de l'animation (`RunnerAnimation`), le geste de la touche ou du plongeon, et l'état « attrapé ». L'autre machine montre ce coureur **distant** sans le simuler : un corps qui suit les instantanés, **interpolé** avec un retard de `net_interpolation_delay` (0,05 s) pour rester fluide malgré les paquets irréguliers. Le coureur distant est un obstacle solide qu'on ne pousse pas. | Aucun retard sur son propre coureur, pour les deux joueurs. Rien ne dépend d'une physique identique sur deux machines. |
| 4 | Qui arbitre | **L'hôte tient la partie** : `ChaseState` et `RoundClock` (le compte à rebours, le GO, la fin du temps, les scores, la revanche). Il envoie chacun de ces messages datés à l'autre machine, dont le `ChaseState` reçoit les mêmes messages, dans le même ordre. Le coureur de l'invité reste tenu jusqu'à ce que le GO de l'hôte arrive. | Une seule vérité sur le score, comme le veut la règle des messages datés. |
| 5 | Qui juge l'attrape | **La machine du chat**, sur ce qu'elle montre : le geste de son coureur contre le coureur distant tel qu'il est à son écran (`Tag.catches`, avec le pas du coureur distant tiré de ses deux derniers instantanés montrés). Ce qui touche à l'écran du chat attrape (`chase-tag-reach.md`, décision 1). La machine du chat envoie un message daté d'attrape à l'hôte ; l'hôte l'accepte **si la manche court encore quand il le reçoit**, puis le diffuse. Les deux machines jouent alors l'attrape : la main du chat sur la souris, la réaction de la souris, la pause. | Le chat ne se fait jamais voler une touche qu'il voit réussir. La souris peut parfois se sentir attrapée « de loin » : c'est le prix habituel, et Jimmy le juge en jouant. |
| 6 | Les départs | Les mêmes départs que le Chase, calculés pareil sur les deux machines. L'hôte est le **joueur 1** (chat à la première manche), l'invité le **joueur 2**. Chaque machine place son propre coureur au début du compte à rebours. Une chute hors de l'arène se règle sur la machine du coureur qui tombe. | Les règles du Chase, sans changement. |
| 7 | Les écrans | Chaque joueur joue **seul, en plein écran**, au clavier-souris ou à la manette (comme contre le bot), avec le HUD du Chase (rôle, temps, indicateur de l'autre). Il porte son nom : **« YOU »** pour soi, **« FRIEND »** pour l'autre, dans l'écran entre deux manches et dans le résultat (« YOU WIN » / « FRIEND WINS »). Le **ping** s'affiche dans un coin (« PING 42 ms »). | Un joueur par machine. Le ping aide à comprendre un essai. |
| 8 | Héberger | HOST ouvre le port et affiche **« WAITING FOR A PLAYER »**, le port, et les **adresses locales** du PC (celles du réseau de la maison). La partie commence quand un invité est connecté. L'action menu annule. Le jeu ne cherche **pas** l'adresse publique : il faudrait un service extérieur. | Rien ne sort du PC sans que Jimmy le fasse. |
| 9 | Rejoindre | JOIN demande l'**adresse** de l'hôte, avec un port optionnel (`192.168.1.20` ou `86.12.3.4:24680`). Elle se tape au clavier, **ou à la manette** : le pavé (haut/bas) change le caractère sous le curseur parmi `0-9 . :`, gauche/droite déplace le curseur, la validation se connecte. La dernière adresse jointe est proposée la fois suivante, gardée pour la session. | Chaque action existe au clavier et à la manette (`AGENTS.md`). |
| 10 | La poignée de main | À la connexion, les deux machines échangent la **version du protocole** et la **version du jeu** (celle de `project.godot`). Une version différente est refusée des deux côtés, avec **« DIFFERENT GAME VERSION »**. L'hôte refuse un **troisième** joueur. | Chaque machine simule son coureur : deux versions différentes ne joueraient pas au même jeu. |
| 11 | Les échecs | Ce sont des **résultats typés**, jamais un plantage ni une erreur poussée : le port déjà pris (**« PORT ALREADY IN USE »**) ; aucune réponse au bout de **5 s** (**« COULD NOT CONNECT »**, retour à JOIN) ; l'autre joueur part ou ne donne plus de nouvelles pendant **3 s** (**« THE OTHER PLAYER LEFT »**, puis retour au menu). | Règle d'`AGENTS.md`, et un essai entre amis qui coupe proprement. |
| 12 | Ce que l'on reçoit | Un paquet ne se décode qu'en **types simples** (jamais d'objet créé à partir du réseau). Chaque champ est vérifié : un paquet mal formé, d'un type inconnu, d'une date absurde ou d'un instantané plus ancien que le dernier montré est **ignoré**, sans erreur. | Le port est ouvert sur internet : ce qui arrive n'est jamais fiable. |
| 13 | La fin de partie | Sur le résultat, **REMATCH** choisi par l'un des deux relance la partie pour les deux (l'autre rôle commence, comme hors ligne). **MENU** quitte la partie : l'autre voit « THE OTHER PLAYER LEFT ». | Comme hors ligne, sans attendre un accord. |
| 14 | L'architecture | `game/net/` naît : un **contrat** de lien écrit en types de `core` (héberger, rejoindre, envoyer un message fiable ou un instantané, relever ce qui est arrivé, l'état du lien, fermer), son **vrai adaptateur** ENet et son **faux**, déterministe (horloge et latence injectées, perte de paquets choisie, appels enregistrés). Les nouveaux types échangés (l'instantané, les messages de la partie en ligne) vivent dans `core`. **Une seule racine de composition**, `Main`, choisit l'adaptateur ENet et le donne au Chase ; les tests donnent le faux. Une **suite de contrat** tourne contre les deux, l'ENet en local (127.0.0.1). | Les règles « Ports and adapters » d'`AGENTS.md`, qui s'appliquent dès maintenant. |
| 15 | Les réglages | `net_interpolation_delay` dans la ressource de réglage, groupe « Net » ; F4 le recharge. Le port par défaut, les deux délais (5 s, 3 s) et la version du protocole sont des constantes de `game/net/` : ce ne sont pas des réglages du ressenti. | Règle d'`AGENTS.md`. |
| 16 | Ce que Jimmy doit faire | Le `README.md` gagne une partie « Play online » : héberger, accepter le pare-feu de Windows à la première fois, **rediriger le port UDP 24680** de la box vers le PC, donner son adresse publique à l'ami (ou passer par un réseau privé virtuel entre amis, si Jimmy en choisit un), envoyer à l'ami le même build. La feuille de route passe l'étape 5 à « in progress » et la disposition d'`AGENTS.md` décrit `game/net/`. | Le jeu ne touche ni la box, ni le pare-feu, ni aucun compte. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Le Chase en ligne

  Scénario: Un ami rejoint la partie hébergée
    Soit un joueur qui héberge et un autre qui rejoint son adresse
    Quand la connexion se fait
    Alors la partie commence sur les deux machines, l'hôte chat à la première manche

  Scénario: Une autre version du jeu est refusée
    Soit un hôte et un invité qui n'ont pas la même version du jeu
    Quand l'invité se connecte
    Alors les deux voient « DIFFERENT GAME VERSION » et aucune partie ne commence

  Scénario: Un troisième joueur est refusé
    Soit une partie en ligne en cours
    Quand un troisième joueur se connecte
    Alors il est refusé et la partie continue

  Scénario: Mon coureur répond sans attendre le réseau
    Soit une partie en ligne avec 100 ms de latence
    Quand l'invité pousse son stick
    Alors son coureur bouge au pas même de l'entrée

  Scénario: Chacun voit l'autre courir
    Soit une partie en ligne avec de la latence et des paquets perdus
    Quand l'invité court et saute
    Alors l'hôte le voit suivre ses instantanés avec le retard d'interpolation, sans saut, avec son animation et sa couleur

  Scénario: Le départ attend le GO de l'hôte
    Soit une partie en ligne avec de la latence
    Quand le compte à rebours de l'hôte arrive à GO
    Alors le coureur de l'invité reste tenu jusqu'à ce que le GO lui arrive

  Scénario: Le chat attrape ce qu'il touche sur son écran
    Soit l'invité chat, la souris de l'hôte à portée sur l'écran de l'invité
    Quand l'invité touche
    Alors la manche finit sur les deux machines, avec l'attrape montrée

  Scénario: Une attrape arrivée après la fin du temps ne compte pas
    Soit l'invité chat qui touche juste avant la fin du temps, son message arrivant après
    Quand l'hôte le reçoit
    Alors la manche est gagnée par la souris sur les deux machines

  Scénario: Les deux machines comptent le même score
    Soit une partie en ligne jouée jusqu'au résultat
    Quand elle finit
    Alors les deux machines montrent les mêmes manches, le même score et le même gagnant

  Scénario: La revanche de l'un relance pour les deux
    Soit le résultat d'une partie en ligne
    Quand l'invité choisit REMATCH
    Alors une partie recommence sur les deux machines, l'autre rôle au départ

  Scénario: La connexion échoue proprement
    Soit une adresse où personne n'héberge
    Quand on la rejoint
    Alors « COULD NOT CONNECT » s'affiche au bout de 5 s et l'écran JOIN revient

  Scénario: Le port déjà pris est dit
    Soit le port déjà ouvert par un autre programme
    Quand on héberge
    Alors « PORT ALREADY IN USE » s'affiche

  Scénario: L'autre joueur part
    Soit une partie en ligne en cours
    Quand l'invité ferme le jeu, ou ne donne plus de nouvelles pendant 3 s
    Alors l'hôte voit « THE OTHER PLAYER LEFT » puis revient au menu

  Scénario: Un paquet mal formé est ignoré
    Soit une partie en ligne en cours
    Quand arrivent un paquet illisible, un type inconnu et un instantané plus ancien que le dernier
    Alors ils sont ignorés et la partie continue

  Scénario: L'adresse se tape à la manette
    Soit l'écran JOIN et une manette
    Quand le joueur compose « 127.0.0.1 » au pavé et valide
    Alors le jeu rejoint cette adresse

  Scénario: Les deux liens tiennent le même contrat
    Soit le lien ENet en local et le faux lien
    Quand la suite de contrat tourne contre chacun
    Alors ils se connectent, échangent messages et instantanés, et rendent les mêmes échecs typés
```

Avec les fichiers, le développeur rapporte :
- le contenu de l'instantané et sa taille en octets ;
- comment les deux machines sont mises côte à côte dans les tests (deux mondes séparés) ;
- un essai réel de deux instances du jeu sur la même machine (127.0.0.1), s'il a pu le faire ;
- le temps de `just preflight` et de `just check`.

## UI & Layout Contract

- **Référence visuelle** : aucune ; les écrans reprennent le style de l'écran de départ.
- **Arbre de composants** : l'écran de départ gagne « CHASE ONLINE », puis un choix
  HOST / JOIN (`ChoiceMenu`, comme le choix du niveau du bot) ; HOST montre un panneau
  d'attente (message, port, adresses locales) ; JOIN un champ d'adresse et son message
  d'échec. En partie, la vue unique du Chase contre le bot, plus le ping en haut à droite.
- **Libellés** : `CHASE ONLINE`, `HOST`, `JOIN`, `WAITING FOR A PLAYER`, `PORT 24680`,
  `YOUR ADDRESSES ON THIS NETWORK`, `ADDRESS OF THE HOST`, `CONNECTING…`,
  `COULD NOT CONNECT`, `PORT ALREADY IN USE`, `DIFFERENT GAME VERSION`,
  `THE OTHER PLAYER LEFT`, `YOU`, `FRIEND`, `YOU WIN`, `FRIEND WINS`, `PING 42 ms`.

## Hors périmètre

- Le duel en ligne, plus de deux joueurs, des spectateurs.
- Un serveur dédié, la recherche de parties, Steam, le passage des box (NAT) : la
  redirection du port est faite par Jimmy.
- La prédiction et la correction du coureur distant, l'anti-triche : on teste entre amis.
- Chercher l'adresse publique du PC.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Autorité : qui simule, qui arbitre (chacun son coureur, l'hôte la partie) | — | discovered |
| Interpolation d'un objet distant avec un retard fixe | — | discovered |
| Ne jamais faire confiance à ce qui arrive du réseau | — | discovered |
