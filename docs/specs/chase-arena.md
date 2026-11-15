# La nouvelle arène du Chase : plus grande, plus propre, avec des boucles

**Statut : 🟡 Prêt pour le dev**

Session du 2026-11-15, avec Jimmy, après avoir joué le Chase à deux puis contre le bot :
« revoir la map […] plus propre », « peut-être faire une map plus grande, en vrai », « oui,
la nouvelle arène ». Le reste a été délégué à la session principale (« je te fais
confiance »).

## Contexte

L'arène actuelle (`game/levels/chase.tscn`) fait 20 m sur 20, a été dessinée avant le
franchissement et le tempo réaliste, et ses passages bas sont des poutres flottantes.
Mesuré avec le bot (`docs/specs/chase-bot.md`, décision 10 amendée) : **sans boucle
autour d'un obstacle, un chat de même niveau attrape toujours la souris** (NORMAL contre
NORMAL : 40 manches sur 40). L'équilibre à niveau égal y a été renvoyé vers cette spec.

Le coureur, depuis `docs/specs/realistic-tempo.md` : 6,5 m/s (7,15 au palier 3), saut de
1,2 m qui couvre environ 4,7 m à pleine vitesse, franchissement de 0,6 à 1,3 m, mantle
de 0,9 à 2,2 m au-dessus des pieds, wall-run d'1 s à partir de 4,8 m/s.

Ce que la spec ne doit pas casser : tous les scénarios du Chase à deux et contre le bot
(les règles, les écrans, le bot et ses niveaux) ; les règles d'`AGENTS.md` (chaque mur
d'un seul bloc ; un mur qu'on ne doit pas longer dans `no_wall_run`).

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | La taille | Un sol libre de **32 m sur 32**, fermé par une enceinte (sans wall-run). L'ancienne arène est remplacée : le Chase à deux et contre le bot jouent la nouvelle. | « Une map plus grande ». |
| 2 | Des boucles | Au moins **trois boucles** : un tour fermé autour d'un obstacle, de **12 à 30 m** de long, que l'on peut faire en courant sans s'arrêter. Chaque boucle a au moins un **raccourci** par un mouvement (franchir, glisser, se hisser puis descendre) qui fait gagner de la distance au prix d'un geste. | La souris tourne, le chat coupe : c'est le jeu du chat et de la souris. |
| 3 | Juste pour les deux | L'arène est **symétrique par rapport à son centre** (une rotation d'un demi-tour la redonne) ; les deux départs sont l'un l'image de l'autre. | Aucun côté avantagé, les rôles s'échangent. |
| 4 | Un jeu d'obstacles net | Des mesures sur une grille de **0,5 m**, une hauteur par sorte : **murets** 1,0 m de haut et 0,3 m d'épaisseur (franchis dans les deux sens, à la vitesse de pointe et au palier 3, avec leur place derrière) ; **blocs à hisser** 1,8 m ; **murs de wall-run** 3,5 m de haut, au moins 6 m de long ; **passages bas** en **tunnel** (deux côtés et un toit, le dessous du toit à 1,2 m, 2 à 3 m de long), sans poutre flottante ; **plateformes** au-dessus d'un saut suivi d'un mantle depuis le sol (calculé depuis le réglage), atteintes par un bloc-rebord. Chaque mur est un seul bloc. | « Plus propre » : on lit chaque obstacle à sa forme. |
| 5 | Ce qu'on voit | Un seul matériau de **grille** (des lignes tous les mètres, posées dans le monde, un shader écrit dans le projet, sans fichier d'image) avec **une couleur par sorte** d'obstacle : sol gris clair, murets jaunes, blocs orange, murs de wall-run bleus, tunnels verts, plateformes violettes, enceinte gris foncé. Une lumière directionnelle avec ombres. Les couleurs du chat (rouge) et de la souris (bleu des coureurs) restent lisibles sur toutes. | Lisible d'un coup d'œil, et la grille donne les distances. |
| 6 | Les départs | Face à face, de part et d'autre du centre, à `chase_start_distance` (réglée par la mesure de la décision 8), chacun avec au moins 3 m d'élan libre devant lui. | Q : un départ juste. |
| 7 | Le bot suit | Les **liens** de navigation (franchir, se hisser, monter, descendre) et les **points de fuite** sont redéclarés pour la nouvelle arène ; les points de fuite sont pris **sur les boucles** (au moins deux par boucle, de part et d'autre de son obstacle). Les règles de `chase-bot.md` tiennent : chaque lien se parcourt, le bot n'est jamais coincé, un niveau plus haut gagne plus. | Le bot fait tourner la souris autour des obstacles. |
| 8 | L'équilibre à niveau égal | Mesuré bot contre bot, NORMAL contre NORMAL, sur au moins **40 manches** variées (rapportées) : le chat gagne **35 à 65 %** des manches. Le test joue les **6 manches** de `chase-bot.md` et demande au chat NORMAL d'en gagner **de 1 à 5** (ni toujours, ni jamais). Si la mesure sort, le développeur ajuste d'abord la distance de départ, puis la forme des boucles (pas les règles du Chase ni le bot) et le rapporte. | L'exigence renvoyée ici par `chase-bot.md`. |
| 9 | La durée des portes | Les nouveaux tests de l'arène réutilisent les manches de bots déjà jouées par `tests/chase_bot_rounds.gd` ; l'arène n'ajoute pas plus de **10 s** au palier des parcours. | Les portes sont déjà au-dessus de leur budget. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: La nouvelle arène du Chase

  Scénario: L'arène est grande et fermée
    Soit l'arène du mode Chase
    Quand on mesure son sol et son enceinte
    Alors le sol libre fait 32 m sur 32, et l'enceinte ne se longe pas en wall-run

  Scénario: L'arène a ses boucles et leurs raccourcis
    Soit l'arène du mode Chase
    Quand le pilote fait le tour de chaque boucle déclarée, puis prend son raccourci
    Alors il y a au moins trois boucles de 12 à 30 m, faites sans s'arrêter, et chaque raccourci passe par un franchissement, une glissade ou un mantle

  Scénario: L'arène est la même des deux côtés
    Soit l'arène du mode Chase
    Quand on la tourne d'un demi-tour autour de son centre
    Alors chaque obstacle et chaque départ retombe sur un obstacle de même sorte ou sur l'autre départ

  Scénario: Chaque obstacle a les mesures de sa sorte
    Soit chaque obstacle de l'arène
    Quand on mesure sa hauteur, son épaisseur et sa longueur
    Alors il a les mesures de sa sorte, sur la grille de 0,5 m, chaque mur d'un seul bloc

  Scénario: Chaque muret se franchit dans les deux sens au nouveau tempo
    Soit chaque muret de l'arène
    Quand le pilote court vers lui de chaque côté, à la vitesse de pointe puis au palier 3
    Alors il le franchit à chaque fois

  Scénario: Les tunnels se passent en glissant
    Soit chaque tunnel de l'arène
    Quand le pilote y arrive en courant et glisse
    Alors il le traverse sans s'arrêter, et un coureur debout ne passe pas dessous

  Scénario: Chaque sorte d'obstacle a sa couleur
    Soit l'arène du mode Chase
    Quand on lit la couleur du matériau de chaque obstacle
    Alors chaque sorte a la sienne, toutes différentes, et différentes du rouge du chat et du bleu de la souris

  Scénario: Le chat et la souris font jeu égal au même niveau
    Soit les 6 manches de bots NORMAL contre NORMAL dans la nouvelle arène
    Quand elles sont jouées
    Alors le chat en gagne de 1 à 5
```

Avec les fichiers, le développeur rapporte la mesure sur 40 manches (décision 8), la
distance de départ retenue, la longueur de chaque boucle, et le temps de `just check`.

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** : l'arène (refaite) ; le matériau de grille (créé) ; rien ne
  change dans les écrans.
- **Libellés** : aucun nouveau.

## Hors périmètre

- Plusieurs arènes au choix, un éditeur : plus tard.
- Le wall-run du bot : après avoir joué.
- Le jeu en ligne : étape 5.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Dessiner un niveau pour une règle de jeu (des boucles pour la fuite) | — | discovered |
| Matériau procédural (shader de grille en coordonnées du monde) | — | discovered |
