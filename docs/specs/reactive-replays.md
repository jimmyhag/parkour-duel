# Tests rejoués réactifs : un pilote de test qui regarde devant lui

**Statut : 🟢 Implémenté**

Session du 2026-11-12, avec Jimmy. Amendée après l'inspection, avec l'accord de Jimmy : le
scénario « Le pilote ne saute pas devant un mur qu'il ne peut pas franchir » est ajouté
(marqué « amendement »). Son test existait déjà, écrit par le développeur pour prouver
la partie « franchissable d'un saut » de la décision 2.

## Contexte

La base du déplacement (`docs/specs/movement-base.md`, implémentée) prouve que chaque
section du parcours se franchit par un test rejoué : une suite d'intentions écrite à
l'avance, jouée sans écran dans la vraie physique. Dans `tests/test_course.gd`, ces
suites comptent des pas : « avancer 75 pas, sauter, avancer 61 pas, sauter ». Les nombres
ont été mesurés avec les réglages actuels ; les deux sauts longs partent 10 à 15 cm
avant le bord.

Conséquence, relevée par la seconde inspection de la base : dès que Jimmy changera la
vitesse de pointe ou une gravité de quelques pour cent, ces tests échoueront alors que
le parcours reste faisable. Or `AGENTS.md` (« Contributing workflow ») permet à un
changement de réglage seul de passer sans spec, à condition que la CI soit verte. Tel
quel, cette exception est inutilisable.

Cette spec remplace les partitions par un pilote de test qui observe le monde à chaque
pas et décide, et elle garantit par des tests une plage de réglages dans laquelle la CI
reste verte. Elle ne change aucun comportement du jeu.

Ce qui existe : `tests/scripted_intent_source.gd` (la partition), `game/core/intent_source.gd`
(la source d'intentions dont elle hérite), les quatre tests de section et le test
« un saut long sans élan échoue » dans `tests/test_course.gd`, qui tournent en accéléré
avec un pas de simulation inchangé de 1/60 s.

Ce qu'elle ne doit pas casser : les 40 scénarios de la base restent verts ; un parcours
ou un réglage qui rend une section infranchissable doit toujours faire échouer un test.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Qu'est-ce qui remplace la partition ? | Un **pilote de test** : une source d'intentions qui, à chaque pas fixe, observe le coureur et le monde physique autour de lui, puis rend une intention. Il vit dans `tests/`, comme la partition : c'est un outil de test, pas du jeu. | Décision Q1. |
| 2 | Que sait faire le pilote ? | Courir dans une direction donnée. Sauter quand le sol s'arrête juste devant lui, ou quand un obstacle franchissable d'un saut (une marche) se présente juste devant lui. Tenir le saut jusqu'au sommet. Ne jamais sauter en l'air ni sur un sol continu. | Ce sont les seuls gestes que demandent les quatre sections actuelles. |
| 3 | Qu'a-t-il le droit de savoir ? | Ce qu'il sonde dans la physique autour du coureur, l'état du coureur, et les valeurs de la ressource de réglage. **Aucun nombre calé sur le parcours ou sur les réglages actuels** : ni compte de pas, ni position de bord, ni distance mesurée à la main. Ses distances d'anticipation se déduisent de la vitesse du coureur et de la ressource de réglage. | C'est ce qui le rend valable après un changement de réglage ou de parcours. |
| 4 | Quand un rejeu s'arrête-t-il ? | Quand le checkpoint visé (ou l'arrivée) est atteint : succès. Quand le coureur tombe sous les blocs, ou quand un budget de pas est épuisé : échec. Le budget se déduit de la longueur de la section et de la vitesse de pointe, largement, pas d'un nombre mesuré. | Un test ne doit ni attendre sans fin ni dépendre d'une durée calée. |
| 5 | Que deviennent les quatre tests de section ? | Ils gardent leur nom et passent au pilote. Leurs partitions sont supprimées. Ce remplacement est décidé ici : ce n'est pas un test affaibli, les scénarios ci-dessous en reprennent les titres avec le nouveau moyen. | Décision Q1. |
| 6 | Quelle plage de réglages est garantie ? | Chaque section se franchit encore quand **une** de ces valeurs change de 10 % en plus ou en moins, les autres restant celles du fichier : vitesse de pointe, gravité en montée, gravité en chute, hauteur de saut. Les variantes sont appliquées à une copie en mémoire de la ressource, jamais écrites dans le fichier du projet. | Décision Q2. Au-delà, une CI rouge veut dire que le parcours lui-même doit changer, et c'est le circuit complet. |
| 7 | Les tests négatifs | « Un saut long sans élan échoue » reste tel quel, avec sa partition. `ScriptedIntentSource` reste pour lui, pour la demande de retour au checkpoint et pour le rechargement des réglages. | Décision Q3 : s'il échoue un jour, c'est que le parcours ne force plus l'élan. |
| 8 | Comment prouver que le pilote lit le monde ? | Deux tests sur de petits parcours construits dans le test lui-même, que le pilote n'a jamais vus : un qui se franchit (un vide, puis une marche, à des distances quelconques), un dont le vide dépasse la portée d'un saut et où le pilote doit échouer. | Un pilote qui passerait partout ne prouverait plus rien. |
| 9 | Arrondi des durées | Un test de `core` avec une durée de 0,11 s : à 60 pas par seconde elle doit valoir 7 pas (l'arrondi au plus proche) et non 6 (la troncature). | Décision Q4, constat de la seconde inspection sur la décision 20 de la base. |
| 10 | Durée des tests | `just preflight` reste sous 30 secondes sur la machine de Jimmy (environ 11 s aujourd'hui). Le développeur donne les nouveaux temps. Les rejeux gardent l'accéléré actuel et le pas de 1/60 s. | Le nombre de rejeux passe de 4 à une trentaine. |
| 11 | Instabilité entre machines | Si un rejeu passe sur Windows et échoue en CI Linux, ou l'inverse, le développeur le rapporte avec les chiffres. Il n'élargit aucune tolérance pour le faire passer. | Même règle que la décision 17 de la base. |
| 12 | Changements dans `game/` | Aucun n'est attendu. Si le pilote a besoin d'une information que le jeu n'expose pas, le développeur ajoute le strict nécessaire et le signale dans ses écarts. Aucune valeur de réglage ne change. | Cette spec porte sur les tests. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Tests rejoués réactifs

  # --- Les sections du parcours, parcourues par le pilote ---

  Scénario: La section d'élan se franchit
    Soit un coureur à la ligne de départ, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint des sauts courts sans tomber

  Scénario: La section des sauts courts se franchit
    Soit un coureur au checkpoint des sauts courts, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint des sauts longs sans tomber

  Scénario: La section des sauts longs se franchit
    Soit un coureur au checkpoint des sauts longs, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il atteint le checkpoint des marches sans tomber

  Scénario: La section des marches mène à l'arrivée
    Soit un coureur au checkpoint des marches, piloté par le pilote de test
    Quand le pilote parcourt la section
    Alors il passe la ligne d'arrivée et la course est terminée

  # --- La plage de réglages garantie ---

  Scénario: Les sections se franchissent avec une vitesse de pointe changée de 10 %
    Soit les réglages du projet, sauf la vitesse de pointe, augmentée puis diminuée de 10 %
    Quand le pilote parcourt chacune des quatre sections avec chaque variante
    Alors chaque section est franchie sans tomber

  Scénario: Les sections se franchissent avec une gravité en montée changée de 10 %
    Soit les réglages du projet, sauf la gravité en montée, augmentée puis diminuée de 10 %
    Quand le pilote parcourt chacune des quatre sections avec chaque variante
    Alors chaque section est franchie sans tomber

  Scénario: Les sections se franchissent avec une gravité en chute changée de 10 %
    Soit les réglages du projet, sauf la gravité en chute, augmentée puis diminuée de 10 %
    Quand le pilote parcourt chacune des quatre sections avec chaque variante
    Alors chaque section est franchie sans tomber

  Scénario: Les sections se franchissent avec une hauteur de saut changée de 10 %
    Soit les réglages du projet, sauf la hauteur de saut, augmentée puis diminuée de 10 %
    Quand le pilote parcourt chacune des quatre sections avec chaque variante
    Alors chaque section est franchie sans tomber

  # --- Le pilote lit le monde ---

  Scénario: Le pilote franchit un parcours qu'il ne connaît pas
    Soit un petit parcours construit par le test, avec un vide puis une marche
    Quand le pilote le parcourt
    Alors il atteint le bout du parcours sans tomber

  Scénario: Un vide infranchissable arrête le pilote
    Soit un petit parcours construit par le test, dont le vide dépasse la portée d'un saut
    Quand le pilote le parcourt
    Alors le rejeu est un échec : le coureur est tombé et le bout n'est pas atteint

  Scénario: Le pilote ne saute pas sans raison
    Soit un coureur piloté sur un sol continu, sans vide ni marche
    Quand le pilote le parcourt
    Alors le coureur ne quitte jamais le sol

  Scénario: Le pilote ne saute pas devant un mur qu'il ne peut pas franchir
    # amendement
    Soit un petit parcours construit par le test, barré par un mur plus haut qu'un saut
    Quand le pilote le parcourt
    Alors il ne demande aucun saut, et le rejeu est un échec : le bout n'est pas atteint

  # --- Arrondi des durées (core) ---

  Scénario: Une durée s'arrondit au pas le plus proche
    Soit un coureur dont le coyote time est réglé à 0,11 s, à 60 pas par seconde
    Quand il quitte le sol sans sauter
    Alors un saut demandé au septième pas en l'air est accepté, et refusé au huitième
```

## Hors périmètre

- Tout changement de comportement du jeu et toute valeur de réglage.
- Le pilote pour les mouvements avancés (glissade, roulade, mantle, wall-run,
  wall-jump) : il sera étendu par `docs/specs/movement-advanced.md`, à relire en
  tenant compte de cette spec.
- Un adversaire piloté par l'ordinateur : c'est le bot de l'étape 4. Le pilote reste un
  outil de test dans `tests/`.
- La lecture d'`Engine.time_scale` par le jeu (constat de la seconde inspection) : à
  rouvrir à l'étape 3, avec le ralenti de visée.
- Un rejeu du parcours d'un seul trait, du départ à l'arrivée : non demandé.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Test rejoué par partition, et pourquoi il casse au premier réglage | discovered | discovered |
| Pilote réactif : observer puis décider, et prouver qu'il peut échouer | non évalué | discovered |
