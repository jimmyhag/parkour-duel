# Déplacement de base : course, saut, caméra et parcours chronométré

**Statut : 🟡 Prêt pour le dev**

Session du 2026-11-12, avec Jimmy. Amendée le 2026-11-12 après la première inspection,
avec l'accord de Jimmy : décisions 2, 8, 9, 14 et 17 complétées, décisions 20 et 21
ajoutées, cinq scénarios ajoutés ou déplacés (marqués « amendement »).

## Contexte

Première moitié de l'étape 1 de la feuille de route (prototype solo du déplacement).
L'étape a été coupée en deux specs pour que Jimmy ait la course, le saut et la caméra
en main avant qu'on construise par-dessus : celle-ci pose la base, et
`docs/specs/movement-advanced.md` ajoutera la glissade, la roulade, le mantle, le
wall-run et le wall-jump une fois cette base réglée.

Ce qui existe aujourd'hui : `game/levels/sandbox.tscn` (un sol, une caméra fixe, une
lumière), scène principale du projet, et `tests/test_sandbox_scene.gd` qui vérifie
qu'elle se charge. Aucun script de jeu, aucune action dans la table d'entrées de
`project.godot`. Le moteur physique n'est pas choisi (`DEFAULT`), la simulation tourne à
60 pas par seconde, l'interpolation physique est désactivée.

Ce que la spec ne doit pas casser : les règles d'architecture et de simulation
d'`AGENTS.md` (couches, intentions, pas fixe, ressource de réglage unique). Les
invariants métier ne sont pas encore écrits ; la sensation de jeu ne se vérifie pas par
un test et reste le jugement de Jimmy.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Qui décide du mouvement ? | `game/core/` calcule, `game/player/` exécute. À chaque pas fixe, `player` donne à `core` une **intention** et des **constats** (au sol ou non, vitesse réelle après collisions) ; `core` rend l'état du coureur et la vitesse voulue ; `player` l'applique à un `CharacterBody3D` avec `move_and_slide`. `core` n'utilise ni `Input`, ni `Time`, ni `Engine`, ni nœud : seulement ses arguments. | Testable sans moteur, et demain les intentions viendront du réseau. |
| 2 | Que contient une intention ? | Une structure typée de `core` : direction de déplacement **dans le monde** (vecteur horizontal, longueur de 0 à 1), saut pressé à ce pas, saut maintenu, glissade maintenue, retour au dernier checkpoint demandé à ce pas, recommencer demandé à ce pas. `player` la fabrique à partir des entrées et de l'orientation de la caméra. | La simulation ne connaît ni touche ni caméra. |
| 3 | D'où viennent les intentions ? | D'une **source d'intentions** remplaçable sur le joueur : par défaut la lecture des entrées, dans les tests une suite écrite à l'avance. | C'est ce qui permet les tests rejoués, puis le fantôme et le réseau. |
| 4 | États du coureur dans cette spec | Au sol, en montée de saut, en chute. Les autres états arrivent avec la seconde spec. | Périmètre. |
| 5 | Course | Accélération jusqu'à la vitesse de pointe, pas de bouton de sprint. Un stick à moitié poussé donne une vitesse de pointe proportionnelle. Contrôle en l'air plus faible qu'au sol. | Décision Q1. |
| 6 | Saut | Hauteur variable : relâcher pendant la montée coupe la vitesse verticale. Gravité plus forte en chute qu'en montée. Coyote time et jump buffer. Un appui donne un seul saut. | Plan, étape 1. |
| 7 | Ressource de réglage | Une seule ressource typée dans `game/core/`, avec son fichier `.tres`. Toute valeur de sensation y vit, caméra comprise. Aucun nombre de réglage dans le code. Valeurs de départ ci-dessous. | Règle d'`AGENTS.md` ; c'est ce que Jimmy modifiera pendant les allers-retours. |
| 8 | Moteur physique et cadence | Jolt choisi explicitement dans `project.godot` ; 60 pas par seconde ; interpolation physique activée. Tout comportement anormal aux arêtes ou aux murs est rapporté, pas contourné. Le réglage `physics_jitter_fix` suit ce que la documentation officielle de Godot recommande avec l'interpolation physique : le développeur relit la page et la cite dans son rapport. | Rendu fluide au-delà de 60 Hz. Jolt n'a pas été comparé à l'autre moteur sur ce jeu. |
| 9 | Caméra | 3e personne, libre : souris ou stick droit. Portée par un bras à ressort (`SpringArm3D`) qui la rapproche quand un obstacle passe entre elle et le coureur. Le bras porte une sphère de collision, dont le rayon vit dans la ressource de réglage, pour que la caméra reste à distance du mur au lieu de s'y enfoncer. La caméra n'est pas de la simulation : elle peut suivre le temps d'image. La souris est capturée au lancement, `Échap` la libère, un clic la reprend. | Décisions Q1 et Q11. |
| 10 | Personnage | Une capsule avec une « visière » qui montre où elle regarde ; elle se tourne vers sa direction de déplacement. | Sans animation, c'est ce qui rend le coureur lisible. |
| 11 | Entrées | Toutes les associations vivent dans la table d'entrées de `project.godot`. Le code ne connaît que des noms d'actions. Clavier en touches physiques. Disposition ci-dessous. Le menu de changement des touches est à l'étape 6. | Décisions Q7 et Q16. |
| 12 | Actions de debug | `F3` et `F4` sont au clavier seulement, comme `Échap`. C'est une exception décidée ici à la règle « chaque action au clavier-souris et à la manette » d'`AGENTS.md`, qui vise les actions de jeu. | Ce ne sont pas des actions de jeu. |
| 13 | Parcours et chrono | L'état d'une course (pas commencée, en cours, terminée ; temps écoulé ; dernier checkpoint ; meilleur temps de la session) vit dans `core`, et le temps se compte en pas fixes. Les checkpoints et les lignes vivent dans `game/world/` et signalent un passage ; `game/levels/` relie le tout. | Le chrono ne dépend pas du nombre d'images par seconde. |
| 14 | Chute et réapparition | Passer sous l'altitude limite du parcours ramène au dernier checkpoint, à l'arrêt, tourné vers la suite, caméra dans le dos. Le chrono continue. Deux actions : retour au dernier checkpoint, recommencer le parcours (chrono à zéro, meilleur temps conservé). Rien n'est sauvegardé sur disque. Les deux actions voyagent dans l'intention (décision 2) : seul `player` lit les entrées. La règle elle-même (sous l'altitude limite ou sur demande, on réapparaît ; recommencer l'emporte sur réapparaître) est décidée dans `core`, qui reçoit l'altitude du coureur, la limite et l'intention ; `levels` ne fait qu'exécuter. | Décision Q6. |
| 15 | Parcours de cette spec | Un nouveau niveau dans `game/levels/`, en blocs gris, qui devient la scène principale : plateforme de départ, ligne de départ, une ligne droite d'élan, une série de sauts courts, une série de sauts longs qui demandent l'élan et le saut tenu, des marches à monter, ligne d'arrivée. Un checkpoint au début de chaque section. `sandbox.tscn` est supprimée. | Décision Q14. |
| 16 | Test existant | `tests/test_sandbox_scene.gd` est **remplacé** par les tests du nouveau parcours (scénario « La scène principale est le parcours test »). Ce remplacement est décidé ici : ce n'est pas un test affaibli. | La scène qu'il vérifie disparaît. |
| 17 | Preuve que le parcours se finit | Un test rejoué par section : une courte suite d'intentions, jouée sans écran dans la vraie physique, doit amener le coureur d'un checkpoint au suivant. Si un tel test est instable entre Windows et la CI Linux, le développeur le rapporte ; il n'élargit pas la tolérance pour le faire passer. Les tests rejoués peuvent tourner en accéléré, à condition que le pas de simulation reste de 1/60 s et que les franchissements soient identiques. | Décision Q10. |
| 18 | Outils de réglage | Un affichage de debug (`F3`) : état du coureur, vitesse horizontale et verticale, temps restant de coyote time et de jump buffer. Une action de rechargement (`F4`) qui relit le fichier de réglage sans relancer le jeu. | Raccourcit les allers-retours. |
| 19 | README | La section « Controls » du `README.md` est écrite avec la disposition ci-dessous, et « Running the game » décrit le parcours. | Règle du plan. |
| 20 | Arrondi des durées | Une durée de la ressource de réglage devient un nombre de pas fixes, arrondi au pas le plus proche : à 60 pas par seconde, 0,10 s vaut 6 pas et 0,12 s vaut 7 pas. Les tests écrivent ces nombres attendus en dur, ils ne les recalculent pas avec la formule du code. | Un changement d'arrondi doit faire échouer un test. |
| 21 | Stick et zone morte | La vitesse visée est proportionnelle à la course du stick **au-delà de la zone morte** : un stick à mi-course ne donne donc pas exactement la moitié de la vitesse de pointe. Le README le dit ainsi. | Comportement du moteur, accepté par Jimmy. |

### Disposition des entrées

| Action | Clavier et souris | Manette |
| ------ | ----------------- | ------- |
| Se déplacer | Touches physiques à la place de W, A, S, D (Z, Q, S, D sur un AZERTY) | Stick gauche |
| Tourner la caméra | Mouvement de la souris | Stick droit |
| Sauter | Espace | A, et LB |
| Glisser (déclarée, sans effet avant la seconde spec) | Ctrl gauche | B, et RB |
| Retour au dernier checkpoint | R | Y |
| Recommencer le parcours | Retour arrière | Select (Back) |
| Libérer la souris | Échap | aucune |
| Affichage de debug | F3 | aucune |
| Recharger les réglages | F4 | aucune |

Maj gauche, les gâchettes et les boutons de la souris restent libres (visée et tir,
étape 3).

### Valeurs de départ de la ressource de réglage

Elles sont faites pour être changées par Jimmy. Les durées sont en secondes ; `core`
les applique avec le pas fixe.

| Réglage | Valeur |
| ------- | ------ |
| Vitesse de pointe | 9 m/s |
| Accélération au sol | 30 m/s² |
| Freinage au sol | 45 m/s² |
| Accélération en l'air | 14 m/s² |
| Hauteur d'un saut tenu | 1,6 m |
| Gravité en montée | 32 m/s² |
| Gravité en chute | 44 m/s² |
| Vitesse verticale gardée quand on relâche le saut en montée | 45 % |
| Vitesse de chute maximale | 40 m/s |
| Coyote time | 0,10 s |
| Jump buffer | 0,12 s |
| Zone morte du stick | 0,2 |
| Capsule | hauteur 1,8 m, rayon 0,35 m |
| Vitesse de rotation du personnage | 14 rad/s |
| Caméra : distance, hauteur du point visé | 4,5 m, 1,6 m |
| Caméra : limites verticales | de 60° vers le bas à 50° vers le haut |
| Caméra : sensibilité souris, stick | 0,0025 rad par pixel, 2,6 rad/s |
| Caméra : rayon de la sphère du bras | 0,2 m |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Déplacement de base

  # --- Logique du coureur (core) ---

  Scénario: Le coureur accélère jusqu'à la vitesse de pointe
    Soit un coureur à l'arrêt au sol
    Quand l'intention pousse à fond dans une direction assez longtemps
    Alors sa vitesse horizontale augmente à chaque pas puis se stabilise à la vitesse de pointe

  Scénario: Le coureur s'arrête quand l'intention cesse
    Soit un coureur lancé à la vitesse de pointe au sol
    Quand l'intention de déplacement devient nulle
    Alors sa vitesse horizontale revient à zéro au rythme du freinage au sol

  Scénario: Un stick à moitié poussé donne une vitesse de pointe réduite
    Soit un coureur à l'arrêt au sol
    Quand l'intention pousse à moitié dans une direction assez longtemps
    Alors sa vitesse se stabilise à la moitié de la vitesse de pointe

  Scénario: Un saut tenu atteint la hauteur réglée
    Soit un coureur au sol
    Quand il saute en maintenant le saut jusqu'au sommet
    Alors le sommet du saut est à la hauteur de saut réglée, à 5 % près

  Scénario: Un saut relâché tôt monte moins haut
    Soit un coureur au sol
    Quand il saute et relâche le saut juste après le départ
    Alors le sommet du saut est nettement plus bas que celui d'un saut tenu

  Scénario: Le saut reste possible pendant le coyote time
    Soit un coureur qui vient de quitter le sol sans sauter
    Quand il demande un saut avant la fin du coyote time
    Alors il saute comme s'il était encore au sol

  Scénario: Le saut est refusé après le coyote time
    Soit un coureur en chute depuis plus longtemps que le coyote time
    Quand il demande un saut
    Alors il ne saute pas et continue de tomber

  Scénario: Un saut demandé juste avant l'atterrissage part à l'atterrissage
    Soit un coureur en chute qui demande un saut moins d'un jump buffer avant de toucher le sol
    Quand il touche le sol
    Alors il saute au premier pas au sol, sans nouvel appui

  Scénario: Un saut demandé trop tôt avant l'atterrissage est oublié
    Soit un coureur en chute qui demande un saut plus d'un jump buffer avant de toucher le sol
    Quand il touche le sol
    Alors il ne saute pas

  Scénario: Un appui ne donne qu'un seul saut
    Soit un coureur qui vient de sauter
    Quand il demande un second saut en l'air, même pendant la durée du coyote time
    Alors il ne saute pas une seconde fois

  Scénario: Le contrôle en l'air est plus faible qu'au sol
    Soit un coureur en l'air sans vitesse horizontale
    Quand l'intention pousse à fond pendant une durée donnée
    Alors sa vitesse horizontale est plus faible qu'après la même durée au sol

  Scénario: La vitesse de chute est plafonnée
    Soit un coureur en chute libre depuis longtemps
    Quand la chute continue
    Alors sa vitesse verticale ne dépasse jamais la vitesse de chute maximale

  Scénario: Les mêmes intentions donnent le même résultat
    Soit deux coureurs identiques avec les mêmes réglages
    Quand ils reçoivent la même suite d'intentions et de constats
    Alors leurs états et leurs vitesses sont identiques à chaque pas

  # --- État de la course (core) ---

  Scénario: Le chrono démarre au passage de la ligne de départ
    Soit une course pas encore commencée
    Quand le coureur passe la ligne de départ
    Alors le chrono se met à compter, en pas fixes

  Scénario: Le chrono s'arrête à la ligne d'arrivée
    Soit une course en cours
    Quand le coureur passe la ligne d'arrivée
    Alors la course est terminée et le temps final ne change plus

  Scénario: Le meilleur temps de la session est conservé
    Soit une course terminée avec un temps final
    Quand une nouvelle course se termine avec un temps plus long
    Alors le meilleur temps reste celui de la première

  Scénario: Un checkpoint atteint devient le point de réapparition
    Soit une course en cours
    Quand le coureur atteint un checkpoint
    Alors ce checkpoint est le point de réapparition

  Scénario: Un checkpoint déjà dépassé ne fait pas reculer la réapparition
    Soit un coureur qui a atteint le deuxième checkpoint
    Quand il repasse par le premier
    Alors le point de réapparition reste le deuxième

  Scénario: Recommencer remet le chrono à zéro et garde le meilleur temps
    Soit une course en cours ou terminée, avec un meilleur temps
    Quand le joueur recommence le parcours
    Alors la course n'est plus commencée, le chrono est à zéro et le meilleur temps est inchangé

  Scénario: Passer sous l'altitude limite demande une réapparition
    # amendement
    Soit une course et un coureur plus bas que l'altitude limite du parcours
    Quand la règle de réapparition est évaluée
    Alors elle demande une réapparition au dernier checkpoint, sans toucher au chrono

  Scénario: Recommencer l'emporte sur réapparaître
    # amendement
    Soit une intention qui demande à la fois recommencer et le retour au checkpoint
    Quand la règle de réapparition est évaluée
    Alors elle demande de recommencer le parcours

  # --- Entrées et joueur (player) ---

  Scénario: Chaque action de jeu a une entrée clavier-souris et une entrée manette
    Soit la table d'entrées du projet
    Quand on examine se déplacer, sauter, glisser, retour au checkpoint et recommencer
    Alors chacune a au moins une touche de clavier et au moins un bouton ou un axe de manette

  Scénario: Les touches du clavier sont des touches physiques
    Soit la table d'entrées du projet
    Quand on examine toutes les entrées clavier
    Alors chacune est définie par sa position physique et non par la lettre qu'elle produit

  Scénario: Avancer va là où regarde la caméra
    Soit un joueur dont la caméra est tournée d'un quart de tour
    Quand il pousse vers l'avant
    Alors la direction de l'intention, dans le monde, est celle où regarde la caméra, à l'horizontale

  Scénario: La caméra se rapproche quand un mur passe derrière le coureur
    Soit un coureur dos à un mur plus proche que la distance de caméra
    Quand la caméra se place derrière lui
    Alors elle reste entre le coureur et le mur, sans le traverser

  # --- Parcours (levels, world, ui) ---

  Scénario: La scène principale est le parcours test
    Soit le projet
    Quand on charge sa scène principale
    Alors c'est le parcours test, avec un coureur, une ligne de départ, des checkpoints et une ligne d'arrivée

  Scénario: Tomber sous le parcours ramène au dernier checkpoint
    Soit un coureur qui a atteint un checkpoint
    Quand il passe sous l'altitude limite du parcours
    Alors il réapparaît à ce checkpoint, à l'arrêt, tourné vers la suite du parcours

  Scénario: Le retour au checkpoint fonctionne à tout moment
    Soit un coureur n'importe où sur le parcours, au sol ou en l'air
    Quand l'action de retour au dernier checkpoint est déclenchée
    Alors il réapparaît au dernier checkpoint atteint, à l'arrêt

  Scénario: Une réapparition ne touche pas au chrono
    # amendement : déplacé ici, il se prouve sur le parcours
    Soit une course en cours sur le parcours
    Quand le retour au dernier checkpoint est demandé, puis que des pas s'écoulent
    Alors le coureur a réapparu et le chrono a avancé exactement du nombre de pas écoulés

  Scénario: Une suite d'intentions peut demander le retour au checkpoint
    # amendement
    Soit un coureur piloté par une suite d'intentions écrite à l'avance, loin du dernier checkpoint
    Quand la suite demande le retour au dernier checkpoint
    Alors il réapparaît au dernier checkpoint, sans qu'aucune touche soit lue

  Scénario: Recommencer le parcours ramène le coureur au départ
    # amendement
    Soit un coureur qui a dépassé un checkpoint, course en cours
    Quand recommencer est demandé
    Alors il réapparaît sur la plateforme de départ, la course n'est plus commencée et le chrono est à zéro

  Scénario: La section d'élan se franchit
    Soit un coureur à la ligne de départ
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il atteint le checkpoint des sauts courts sans tomber

  Scénario: La section des sauts courts se franchit
    Soit un coureur au checkpoint des sauts courts
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il atteint le checkpoint des sauts longs sans tomber

  Scénario: La section des sauts longs se franchit
    Soit un coureur au checkpoint des sauts longs
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il atteint le checkpoint des marches sans tomber

  Scénario: Un saut long sans élan échoue
    Soit un coureur à l'arrêt au bord du premier saut long
    Quand il saute sans prendre d'élan
    Alors il tombe dans le vide et réapparaît au checkpoint des sauts longs

  Scénario: La section des marches mène à l'arrivée
    Soit un coureur au checkpoint des marches
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il passe la ligne d'arrivée et la course est terminée

  Scénario: Le temps s'affiche au centième
    Soit une course en cours depuis 75,5 secondes
    Quand l'affichage se met à jour
    Alors il montre TIME 1:15.50

  Scénario: L'arrivée affiche le temps final et le meilleur temps
    Soit une course qui vient de se terminer
    Quand l'affichage se met à jour
    Alors il montre FINISHED, le temps final, et BEST avec le meilleur temps de la session

  Scénario: L'affichage de debug apparaît et disparaît
    Soit l'affichage de debug masqué
    Quand son action est déclenchée, puis déclenchée de nouveau
    Alors il montre l'état du coureur, ses vitesses et ses deux minuteries, puis il disparaît

  Scénario: Recharger les réglages applique les nouvelles valeurs
    Soit un jeu lancé, dont le fichier de réglage est modifié sur disque
    Quand l'action de rechargement est déclenchée
    Alors le coureur utilise les nouvelles valeurs sans relancer le jeu
```

## UI & Layout Contract

- **Référence visuelle** : aucune. Jimmy n'a pas fourni de maquette ; c'est un affichage
  de prototype en texte blanc, sans habillage.
- **Arbre de composants** :

  | Composant | Couche | Statut |
  | --------- | ------ | ------ |
  | Affichage du chrono (HUD) | `game/ui/` | créé : rien n'existe |
  | Affichage de debug | `game/ui/` | créé : rien n'existe |

- **Placement** : chrono en haut au centre, meilleur temps juste dessous en plus petit ;
  affichage de debug en haut à gauche. Lisible en 1280 × 720 et ancré aux bords, pour
  suivre un changement de taille de fenêtre.
- **États** :
  - course pas commencée : `TIME 0:00.00`, `BEST --:--.--` s'il n'y a pas encore de
    meilleur temps ;
  - course en cours : `TIME` qui défile au centième ;
  - course terminée : `FINISHED`, le temps final figé, `BEST` mis à jour ;
  - vide, chargement, erreur, hors connexion : sans objet (aucune donnée extérieure).
- **Focus** : aucun élément ne prend le focus ; la souris est capturée par le jeu.
- **Libellés** : `TIME`, `BEST`, `FINISHED`. Les libellés de l'affichage de debug sont
  libres, en anglais.

## Hors périmètre

- Glissade, roulade, mantle, wall-run, wall-jump, conservation de l'élan au-delà de la
  vitesse de pointe : seconde spec. L'action « glisser » est déclarée mais sans effet.
- Jauge de flow, figures, munitions, tir, second joueur, fantôme : étapes 2 à 4.
- Menu, pause, changement des touches en jeu, options, sauvegarde des temps : étape 6.
- Recentrage automatique de la caméra : non demandé ; à rediscuter si la manette le
  réclame.
- Sons, animations, modèle de personnage : primitives seulement.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Machine à états du personnage (détection, état, sorties) | non évalué | discovered |
| Coyote time et jump buffer | non évalué | discovered |
| Séparation constat (`player`) / décision (`core`) | non évalué | discovered |
| Intentions, pas fixe et test rejoué | non évalué | discovered |
| Table d'entrées (actions nommées, touches physiques) | non évalué | discovered |
