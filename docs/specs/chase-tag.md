# Attraper pour de vrai : la touche, le plongeon, et le prix d'un raté

**Statut : 🟢 Implémenté**

Session du 2026-11-15, avec Jimmy, après la nouvelle arène (`docs/specs/chase-arena.md`) :
« pour la version chat et souris, comme dans les compétitions IRL […] quand tu veux
attraper quelqu'un, faut qu'il y ait une animation […] si on rate, ça nous ralentit […]
pour que la map, on puisse la laisser plus petite, mais qu'il y ait quand même de
l'enjeu ». Puis : « un bouton pour pouvoir toucher et aussi le plongeon […] les deux
possibilités, mais s'il y a juste un contact et pas de touche avec le bouton, ça compte
pas ». Le reste (les boutons, le prix d'un raté, la taille) a été délégué à la session
principale.

## Contexte

Aujourd'hui, le chat gagne la manche dès que les deux capsules se touchent : pas de
geste, pas de risque. Le jeu reprend le genre des poursuites en arène, pas une
compétition existante (ni son nom, ni ses règles écrites, ni son arène).

Ce qui existe et sert ici : la visée du duel lève le haut du corps sur une couche à part
(Pistol Idle) ; les mains se posent par IK (`TwoBoneIK3D`) sur le dessus d'un obstacle ;
le contact est constaté par `levels` et devient un message daté pour `ChaseState` ; le
bot du Chase (`docs/specs/chase-bot.md`) ne commande que par des intentions.

Ce que la spec ne doit pas casser : tous les scénarios des autres modes ; les règles
d'`AGENTS.md` (chaque action au clavier-souris et à la manette, touches physiques ; `core`
sans scène ni entrée ; ce que le coureur constate ne dépend jamais du corps visible).

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Ce qui attrape | **Seul un geste du chat attrape** : la touche ou le plongeon, quand la capsule de la souris est à sa portée pendant le geste. Le simple contact des corps **ne compte plus** (les corps se traversent toujours). | Q1 de Jimmy. |
| 2 | La touche | Bouton **clic gauche** / **gâchette droite** (RT). Le chat tend le bras pendant `tag_touch_time` (**0,25 s**) en continuant de courir (vitesse plafonnée à **85 %** de sa pointe pendant le geste). Elle attrape si la souris est à moins de `tag_touch_reach` (**0,0 m** : le contact des corps ; 1,0 m au départ, réglé par la mesure de la décision 11) de la surface de sa capsule, dans un cône de **60°** devant lui (direction de sa course, ou de la caméra à l'arrêt). Au sol ou en l'air ; pas pendant un franchissement, un mantle, une roulade ni une glissade. | Le geste de base : sûr, court. |
| 3 | Le plongeon | Bouton **clic droit** / **gâchette gauche** (LT), au sol, à au moins `tag_dive_min_speed` (**3 m/s**). Le chat se jette en avant, bas (pas plus de **0,4 m** de hauteur), avec `tag_dive_push` (**+2 m/s**) de plus que sa vitesse, pendant `tag_dive_time` (**0,4 s**). Il attrape si la souris est à moins de `tag_dive_reach` (**0,8 m** ; 1,6 m au départ, réglé par la mesure de la décision 11) de la surface de sa capsule, dans un cône de **40°** devant lui, pendant le plongeon. Rien ne l'interrompt (comme un mantle), sauf un mur, contre lequel il s'arrête. | Q1 : plus loin, plus risqué. |
| 4 | Le prix d'un raté | **Touche ratée** : `tag_touch_recovery` (**0,35 s**) à **60 %** de la vitesse de pointe au plus, sans nouvelle touche ni plongeon. **Plongeon raté** : le chat finit **au sol**, `tag_dive_recovery` (**0,9 s**) sans bouger, puis se relève. Une manche ne se perd pas sur un raté : la souris gagne quelques mètres (environ 1,5 m pour une touche, 4 à 5 m pour un plongeon). | Q2 : « si on rate, ça nous ralentit ». Le plongeon rapporte plus loin et coûte plus cher. |
| 5 | Le moteur | La touche et le plongeon sont des **intentions** (`MoveIntent`) et des **états du moteur** (`core`) : `DIVING`, `DOWN` (au sol après un plongeon raté), et le geste de touche avec sa récupération. Le moteur ne sait pas s'il a attrapé : `levels` constate la portée pendant le geste (les deux corps, comme le contact aujourd'hui) et l'envoie en **message daté** (qui, quand, quel geste) ; `ChaseState` donne la manche au chat sur ce message, et seulement pendant la fenêtre du geste. Un geste qui ne trouve personne est un raté. | Prêt pour le réseau : le geste est une intention, l'attrape un message. |
| 6 | Seul le chat | La souris n'a pas ces gestes ; ses boutons ne font rien dans ce mode. Hors du Chase, rien ne change (les boutons gardent la visée et le tir du duel). | Un rôle chacun. |
| 7 | Les animations | La touche lève **le haut du corps** sur une couche à part (comme la visée), sur un clip de bras tendu, et la main se pose par IK vers la souris quand elle est à portée (présentation seulement) ; le plongeon, un clip de plongeon ; le raté du plongeon, un clip de relevé ; la touche ratée, un clip de déséquilibre ou rien que le bras qui revient. La **session principale télécharge** sur le compte Mixamo de Jimmy des candidats (bras tendu, plongeon, relevé, trébuchement), avant le développement ; le développeur choisit, mesure leur lecture (plafond `animation_max_pace`) et les déclare dans `just mixamo`. Sans les fichiers, la capsule s'incline (plongeon) ou rien (touche). | « Faut qu'il y ait une animation ». |
| 8 | Ce qu'on voit et entend | Une attrape : la manche s'arrête au pas même, un son d'impact (Kenney, déjà dans `assets/sounds/`), « CAUGHT! » sur l'écran entre deux manches. Un raté : un son court (déjà dans `assets/sounds/`). | Le geste se lit. |
| 9 | Le bot | Le bot chat se sert des deux gestes, par intentions : la **touche** quand la souris entre dans sa portée et son cône ; le **plongeon** quand elle est entre la portée de la touche et celle du plongeon et que son avance (vitesse comptée) ne l'en fera pas sortir pendant le plongeon. Par niveau : EASY ne plonge jamais et touche avec un retard de `chase_bot_tag_delay` (**0,15 s**) ; NORMAL plonge, retard **0,05 s** ; HARD plonge, sans retard. | Le bot joue aux mêmes règles. |
| 10 | Une arène plus petite | L'arène passe à **24 m sur 24** (sol libre), les règles de `chase-arena.md` gardées : au moins trois boucles (de **10 à 24 m**), chacune avec son raccourci, symétrie par un demi-tour, jeu d'obstacles et couleurs inchangés, chaque muret franchi dans les deux sens, liens et points de fuite du bot redéclarés. | Q3 : « la laisser plus petite ». |
| 11 | L'équilibre | Remesuré avec ces gestes : bot NORMAL contre bot NORMAL, au moins **40 manches** variées (rapportées), le chat gagne **35 à 65 %** ; le test garde ses 6 manches et ses bornes (de 1 à 5), et la règle « un niveau plus haut gagne plus » de `chase-bot.md`. Si la mesure sort : d'abord la distance de départ, puis les portées et les prix d'un raté (rapportés), jamais les règles du Chase. **Mesuré au développement** (42 manches par réglage, victoires du chat ; portées touche / plongeon de corps à corps) : 1,0 / 1,6 m à 14, 18 et 22 m de départ : 42, 42, 42 ; 0,5 / 0,8 à 14 m : 42 ; 0,3 / 0,6 à 14 m : 37 ; 0,2 / 0,5 à 14 et 18 m : 38 et 37 ; 0,1 / 0,4 à 14 m : 38 ; 0,0 / 0,0 à 12, 14 et 20 m : 27, 19, 7 ; 0,0 / 0,4 à 14 m : 19 ; 0,0 / 0,6 à 16 m : 16 ; départs variés de ±0,5 m : 0,0 / 0,6 à 14 et 15 m : 22 et 24 ; **0,0 / 0,8 à 14 m : 23 (55 %), retenu** (départ inchangé à 14 m, prix d'un raté inchangés). | Le genre se joue sur le geste, l'arène et l'équilibre. |
| 12 | Les réglages | Toutes les valeurs nouvelles dans la ressource de réglage (groupe « Tag ») ; F4 les recharge. | Règle d'`AGENTS.md`. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Attraper pour de vrai

  # --- Les gestes (core) ---

  Scénario: Le contact seul n'attrape plus
    Soit une manche en cours où les deux corps se touchent sans geste du chat
    Quand le pas se joue
    Alors la manche continue

  Scénario: Une touche à portée attrape
    Soit un chat qui court et une souris à 0,8 m devant lui
    Quand il touche
    Alors la manche est au chat, par un message daté de la touche

  Scénario: Une touche hors de portée est un raté qui ralentit
    Soit un chat qui court à sa vitesse de pointe et une souris à 2 m devant lui
    Quand il touche
    Alors il ne l'attrape pas, puis court à 60 % de sa pointe au plus pendant 0,35 s, sans pouvoir toucher ni plonger

  Scénario: Le plongeon attrape plus loin
    Soit un chat qui court et une souris à 1,4 m devant lui
    Quand il plonge
    Alors la manche est au chat, par un message daté du plongeon

  Scénario: Un plongeon raté laisse le chat au sol
    Soit un chat qui court et une souris à 4 m devant lui
    Quand il plonge
    Alors il ne l'attrape pas, finit au sol 0,9 s sans bouger, puis se relève

  Scénario: Le plongeon demande de l'élan
    Soit un chat qui marche à 2 m/s, puis un chat en l'air
    Quand il demande un plongeon
    Alors il ne plonge pas

  Scénario: Un geste ne marche que dans son cône
    Soit une souris à 0,8 m sur le côté du chat, à 90° de sa course
    Quand il touche
    Alors il ne l'attrape pas

  Scénario: La souris n'a pas de geste
    Soit la souris qui appuie sur les boutons de la touche et du plongeon
    Quand le pas se joue
    Alors rien ne se passe

  # --- Vraie physique ---

  Scénario: Le plongeon s'arrête contre un mur
    Soit un chat qui plonge vers un mur à 1 m
    Quand le plongeon se joue
    Alors il s'arrête contre le mur sans le traverser, et finit au sol

  Scénario: Les gestes marchent au clavier comme à la manette
    Soit une partie de Chase
    Quand le chat appuie sur clic gauche, puis gâchette droite, puis clic droit, puis gâchette gauche
    Alors il touche, touche, plonge, plonge

  Scénario: Le bot chat attrape avec ses gestes
    Soit un bot chat de niveau HARD et une souris immobile, puis une souris qui s'enfuit à 1,3 m
    Quand il arrive sur elle
    Alors il la touche, puis il plonge sur la seconde

  Scénario: Le bot facile ne plonge jamais
    Soit les manches de bots où le chat est EASY
    Quand on compte ses gestes
    Alors il a touché, et n'a jamais plongé

  Scénario: L'arène plus petite garde ses règles
    Soit l'arène du mode Chase
    Quand on la mesure et que le pilote parcourt ses boucles, ses raccourcis et ses murets
    Alors son sol libre fait 24 m sur 24, elle a au moins trois boucles de 10 à 24 m avec leur raccourci, elle est symétrique, et chaque muret se franchit dans les deux sens

  Scénario: Le chat et la souris font jeu égal avec les gestes
    Soit les 6 manches de bots NORMAL contre NORMAL avec la touche et le plongeon
    Quand elles sont jouées
    Alors le chat en gagne de 1 à 5

  # --- Présentation (logique testable sans les fichiers) ---

  Scénario: Chaque geste a son animation
    Soit un chat qui touche, plonge, rate son plongeon puis se relève
    Quand on choisit son animation
    Alors c'est le bras tendu sur le haut du corps, le plongeon, puis le relevé

  Scénario: La copie range les clips de l'attrape
    Soit un dossier de téléchargement avec tous les fichiers
    Quand on lance la commande de copie
    Alors assets/mixamo contient les clips retenus de la touche, du plongeon et du relevé
```

Avec les fichiers, le développeur rapporte la lecture de chaque nouveau clip, la main
vers la souris (distance à la cible), et la mesure de l'équilibre sur 40 manches.

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** : écran entre deux manches (modifié : « CAUGHT! » quand le chat
  attrape) ; rien d'autre.
- **Libellés** (en anglais) : « CAUGHT! ».

## Hors périmètre

- Un geste de la souris (esquive, feinte) : après avoir joué.
- Le jeu en ligne : étape 5.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Une action risquée : portée, fenêtre active, coût d'un raté | — | discovered |
| Animation par couches (haut du corps sur la locomotion) avec IK vers une cible mobile | — | discovered |
