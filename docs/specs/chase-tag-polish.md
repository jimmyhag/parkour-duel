# L'attrape se voit : la chute, le relevé, le déséquilibre, la souris touchée

**Statut : 🟢 Implémenté**

Session du 2026-11-15, après la première version de l'attrape (`docs/specs/chase-tag.md`).
Jimmy : « j'aime bien le principe, c'est plutôt sympathique. Améliore-moi tout ce que tu
peux améliorer niveau animation, niveau tout ça ». Le choix des améliorations a été
délégué à la session principale.

## Contexte

Ce que `chase-tag` a laissé, d'après son développeur et son inspection :

- Un plongeon raté montre le plongeon (0,45 à 0,95 s de Run To Dive), puis seulement la
  fin du relevé (Getting Up, de 4,4 à 5,5 s : des genoux à debout). On ne voit ni la
  chute sur le ventre ni l'appui des mains.
- Une touche ratée n'a pas de clip : seul le bras revient, alors qu'elle coûte 0,35 s à
  60 % de la vitesse. Le prix ne se lit pas.
- La souris attrapée ne réagit pas : la manche s'arrête, les corps restent tels quels.
- La caméra pendant le plongeon et au sol n'a été vérifiée par personne.
- Deux clips sont déjà téléchargés sur le personnage et pas encore utilisés : `Jogging
  Stumble` et `Falling Flat Impact` (dans le dossier Mixamo de Jimmy).

Ce que la spec ne doit pas casser : les règles et l'équilibre de `chase-tag.md` (le test
des 6 manches, 1 à 5 pour le chat NORMAL, « un niveau plus haut gagne plus ») ; le
plafond de rythme des clips (`animation_max_pace`, 1,25) ; les règles d'`AGENTS.md` (le
corps visible n'est que de la présentation : rien de ce que le moteur constate n'en
dépend).

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Le plongeon raté se voit en entier | Trois temps lisibles : **le plongeon** jusqu'au contact du sol, **couché** sur le ventre (au moins `tag_down_lying`, **0,25 s**), puis **le relevé** depuis l'appui des mains jusqu'à debout. Le développeur prend, parmi Run To Dive, Falling Flat Impact et Getting Up, les morceaux qui s'enchaînent le mieux (mesurés sur les os, pas à l'œil), chacun à un rythme d'au plus 1,25. Si le relevé depuis les mains ne tient pas dans `tag_dive_recovery`, celui-ci peut monter jusqu'à **1,2 s**, pas plus, et l'équilibre est remesuré (décision 5). | On comprend qu'on s'est jeté et qu'on se relève : le prix se voit. |
| 2 | La touche ratée trébuche | Pendant la récupération d'une touche ratée, le corps entier joue **un déséquilibre** (un morceau de Jogging Stumble, au rythme d'au plus 1,25), puis revient à la course par le fondu habituel. Le bras tendu le précède sans saut de pose. | Le ralentissement se lit. |
| 3 | La souris touchée réagit | Quand le chat attrape, la souris joue **une réaction** : un trébuchement (le même morceau de Jogging Stumble) après une touche, une chute (Falling Flat Impact) après un plongeon. La manche reste finie au pas même (rien ne change dans `ChaseState`) ; l'écran « CAUGHT! » attend `chase_catch_pause` (**0,8 s**) pour qu'on voie la réaction. | L'attrape a un effet visible sur celui qui la subit. |
| 4 | La caméra suit le corps au sol | Pendant le plongeon et au sol, la caméra **descend avec le corps**, sans à-coup (lissée par `tag_camera_follow`, en secondes), et remonte avec le relevé. Pas de secousse. | On reste lisible sans donner mal au cœur. |
| 5 | L'équilibre tient | Si un temps change (décision 1), le chat NORMAL gagne toujours **35 à 65 %** de 42 manches variées (rapportées), et les tests de `chase-tag.md` et `chase-bot.md` passent sans être changés. | Le polissage ne change pas le jeu. |
| 6 | Les réglages | Les valeurs nouvelles dans le groupe « Tag » de la ressource de réglage. Les clips nouveaux déclarés dans `tools/mixamo.py`, le README et `assets/CREDITS.md`, jamais suivis par Git. | Règles d'`AGENTS.md`. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: L'attrape se voit

  Scénario: Un plongeon raté se voit en entier
    Soit le chat qui plonge sans attraper
    Quand son plongeon et son temps au sol s'écoulent
    Alors son corps joue le plongeon, reste couché au moins le temps réglé, puis se relève depuis l'appui des mains, chaque clip au rythme d'au plus 1,25

  Scénario: Une touche ratée trébuche
    Soit le chat qui touche sans attraper
    Quand sa récupération commence
    Alors son corps joue le déséquilibre, au rythme d'au plus 1,25, puis revient à la course

  Scénario: La souris touchée réagit
    Soit le chat qui attrape la souris, une fois par la touche, une fois par le plongeon
    Quand la manche s'arrête
    Alors la souris trébuche après la touche et tombe après le plongeon, et « CAUGHT! » n'apparaît qu'après la pause réglée

  Scénario: La caméra suit le chat au sol
    Soit le chat qui plonge sans attraper
    Quand il touche le sol puis se relève
    Alors la caméra descend puis remonte avec lui, sans saut d'une image à l'autre

  Scénario: Le polissage garde l'équilibre
    Soit les 6 manches de bots NORMAL contre NORMAL avec les nouveaux temps
    Quand elles sont jouées
    Alors le chat en gagne de 1 à 5

  Scénario: La copie range les clips de la réaction
    Soit le dossier Mixamo de Jimmy
    Quand la copie des fichiers tourne
    Alors les clips du déséquilibre et de la chute sont rangés avec les autres, et aucun n'est suivi par Git
```

Le développeur rapporte les morceaux de clips retenus (début, fin, rythme), le temps au
sol final, la mesure sur 42 manches si un temps a changé, et le temps de `just check`.

## Amendements

Après l'inspection, le 2026-11-15, par la session principale (choix délégué par Jimmy) :

- **Décision 1** : Getting Up met environ 3,4 s de clip des mains jusqu'à debout, ce qui
  ne tient pas dans 1,2 s au rythme de 1,25. Un pont de 0,1 s à la place de 2,2 s de clip
  ferait « sauter » le corps de 0,55 m : refusé. Pour **ce seul clip** (le relevé), le
  rythme peut monter jusqu'à `tag_getup_max_pace` (**2,0**), et `tag_dive_recovery`
  jusqu'à **1,6 s**. Une coupe entre deux morceaux n'est permise qu'entre deux poses
  proches : les hanches et les mains à **moins de 0,1 m** l'une de l'autre. La poussée
  des mains se joue, elle n'est jamais pontée. Le relevé finit **debout** (les hanches
  à au moins 90 % de leur hauteur de course).
- **Décision 2** : le déséquilibre ne se joue qu'au sol. Une touche ratée en l'air ne
  trébuche pas : son bras revient seulement.
- **Décision 3** : la pause vaut aussi pour l'attrape qui finit le match ; l'écran de fin
  attend `chase_catch_pause`, comme l'écran entre deux manches.
- **Décision 4** : la caméra suit la hauteur des hanches du corps visible quand les
  fichiers Mixamo sont là, et une courbe calculée depuis le réglage sinon. C'est de la
  présentation seulement : rien de ce que le moteur constate n'en dépend.
- **Décision 5** : deux tests de `chase-tag.md` changent, parce que les décisions 3 et 6
  l'imposent, sans perdre une assertion. `test_the_catch_of_a_touch_is_observed_not_the_contact`
  attend la pause. La liste des clips non copiés disparaît de `test_mixamo_files.gd`.

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** : l'écran entre deux manches et l'écran de fin de match (attendent la pause) ; rien d'autre ne
  change dans les écrans.
- **Libellés** : aucun nouveau.

## Hors périmètre

- La portée de la touche (0 m) : Jimmy la juge en jouant, puis un simple réglage.
- Un clip propre à la touche réussie, des effets de particules, des secousses de caméra.
- Le jeu en ligne : étape 5.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Enchaîner des morceaux de clips mesurés sur les os | discovered | practiced |
| Réaction de celui qui subit (le retour d'un coup) | — | discovered |
