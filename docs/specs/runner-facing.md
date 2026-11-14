# Où regarde le coureur : le corps visible face à la poussée

**Statut : 🟢 Implémenté**

Session du 2026-11-14, au point d'arrêt n° 2. Jimmy a joué la version finale de
l'étape 1 et la trouve correcte, sauf un point : « dès qu'il détecte un objet, sa tête
se tourne. J'aimerais quand même qu'il reste face […] quand on aura les bonhommes, les
animations et tout, ça va être un peu bizarre. Donc qu'il reste bien droit quand il est
droit. » Puis, en précisant : « quand t'arrives sur un mur qui est trop haut […]
automatiquement il tourne sa tête, même si maintenant il monte quand même. Donc
j'aimerais qu'il reste de face, pour que ce soit plus fluide. » Le cas visé est d'abord
le saut vers un rebord suivi d'un mantle. Jimmy a délégué les décisions (« me demande plus rien de confirmer, juste
enchaîne jusqu'au bout ») ; il juge le résultat en jouant.

## Contexte

Ce qui existe sur `main` :

- `game/player/player.gd`, `_turn_towards_movement()` : à chaque pas, le corps visible
  (`Visual`, la capsule et sa visière) tourne vers la vitesse horizontale du corps, à
  `turn_speed` (14 rad/s). C'est la décision 10 de `docs/specs/movement-base.md` : « elle
  se tourne vers sa direction de déplacement ».
- `_lean_towards_the_wall()` : en wall-run seulement, la capsule penche de
  `wall_run_lean` (20°) vers le mur, puis se redresse.
- La décision 22 de `docs/specs/movement-walls.md` : ce que `player` constate pour le
  moteur ne dépend jamais de la direction où regarde le corps visible.

**La cause.** Contre une face, la physique retire la part de la vitesse qui entre dans
la face : il ne reste que la part qui glisse le long d'elle, souvent petite et de côté.
Le corps visible suit cette vitesse et se met de profil, alors que le joueur pousse
droit vers la face. Le même effet vient de toute vitesse résiduelle, petite et de
travers, après un choc.

Ce que la spec ne doit pas casser : tous les scénarios antérieurs, sauf la phrase de la
décision 10 de `docs/specs/movement-base.md` que la décision 1 remplace ; la décision 22
de `docs/specs/movement-walls.md` ; le retour au checkpoint face à la suite du parcours.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Où regarde le corps visible au sol, en saut, en chute et en réception dure ? | Vers où le joueur pousse (la direction de l'intention), jamais vers la vitesse. Sans poussée, il garde son orientation. **Remplace** « elle se tourne vers sa direction de déplacement » de la décision 10 de `docs/specs/movement-base.md`. | Demande de Jimmy. La poussée est ce que le joueur veut ; la vitesse est ce que le décor en laisse. C'est aussi ce que demandera une animation de course. |
| 2 | En glissade et en roulade ? | Vers son mouvement (la vitesse horizontale), comme avant ; sous une vitesse horizontale presque nulle, il garde son orientation. | La glissade se dirige lentement : un corps tourné vers la poussée glisserait de côté. |
| 3 | En wall-run ? | Le long du mur, dans le sens de la course : la vitesse horizontale sans sa part vers le mur ou à l'opposé, quelle que soit la poussée. | Pousser en diagonale vers le mur lance un wall-run (décision 3 de `docs/specs/movement-walls.md`) ; le corps ne doit pas regarder le mur pour autant. |
| 4 | En mantle ? | Il ne tourne pas : du premier au dernier pas du mantle, le corps visible garde l'orientation qu'il avait au moment où le mantle a commencé, c'est-à-dire la poussée du joueur (décision 1), quelle que soit la direction de la montée. Après le mantle, la décision 1 reprend. | Demande de Jimmy : aujourd'hui, la montée part perpendiculaire à la face et le corps se tourne vers elle, alors que le joueur poussait droit. |
| 5 | « Qu'il reste bien droit » : penche-t-il hors du wall-run ? | Non. Hors du wall-run, le corps visible est vertical : ni roulis ni tangage, dans aucun état. L'inclinaison du wall-run ne change pas : 20°, et Jimmy peut la mettre à 0 dans la ressource de réglage s'il ne la veut pas. | Jimmy a aimé les murs (« c'est stylé »), l'inclinaison n'est pas en cause ; un réglage à 0 la retire sans code. |
| 6 | La vitesse de rotation ? | Inchangée : `turn_speed`, 14 rad/s, pour tourner comme pour se redresser. Aucune valeur nouvelle dans la ressource de réglage. | Rien dans le retour de Jimmy ne dit que le corps tourne trop vite ou trop lentement. |
| 7 | Les constats et le moteur ? | Inchangés : le changement est de la présentation seule. Aucun constat ne dépend du corps visible (décision 22 de `docs/specs/movement-walls.md`), et aucun test de mouvement ne change. | Garder la règle d'`AGENTS.md` : le corps visible n'est que de la présentation. |
| 8 | Comment le prouver ? | Dans la vraie physique, sur des scènes de test faites pour cela : un mur contre lequel sauter et courir, un mur à longer, un rebord. On mesure la direction de la visière à chaque pas. Un angle se compare avec une tolérance de quelques degrés, une fois la rotation terminée au rythme de `turn_speed`. | Le bug ne se voit que dans la vraie physique : c'est elle qui retire la vitesse contre la face. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Où regarde le coureur

  # --- Contre une face (vraie physique) ---

  Scénario: Sauter contre un mur en poussant droit vers lui garde le coureur face au mur
    Soit un coureur qui court vers un mur trop haut pour un mantle
    Quand il saute contre le mur en poussant droit vers lui
    Alors à chaque pas du contact, le corps visible regarde le mur

  Scénario: Courir contre un mur en poussant de biais garde le coureur face à sa poussée
    Soit un coureur au sol plaqué contre un mur
    Quand il pousse de biais vers le mur et que la physique le fait glisser le long de lui
    Alors le corps visible regarde vers sa poussée, pas le long du mur

  Scénario: Une vitesse de travers ne tourne pas le coureur qui ne pousse pas
    Soit un coureur au sol qui regarde devant lui
    Quand il ne pousse plus et qu'il lui reste une vitesse de travers
    Alors le corps visible garde son orientation

  # --- Tourner vers la poussée ---

  Scénario: Le coureur se tourne vers où il pousse au rythme réglé
    Soit un coureur au sol qui regarde devant lui
    Quand il pousse vers sa droite
    Alors le corps visible tourne vers sa droite à la vitesse de rotation réglée, puis la regarde

  Scénario: En l'air, le coureur regarde où il pousse, pas où il vole
    Soit un coureur en l'air qui vole de côté par rapport à sa poussée
    Quand il continue de pousser
    Alors le corps visible regarde vers sa poussée

  # --- États qui gardent leur propre regard ---

  Scénario: En glissade, le coureur regarde où il glisse
    Soit un coureur en glissade
    Quand il pousse de côté
    Alors le corps visible regarde vers son mouvement, pas vers sa poussée

  Scénario: En wall-run, le coureur regarde le long du mur
    Soit un coureur en wall-run lancé en poussant en diagonale vers le mur
    Quand le wall-run se poursuit
    Alors le corps visible regarde le long du mur, dans le sens de sa course

  Scénario: Sauter vers un rebord en poussant droit garde le coureur de face jusqu'en haut
    # le cas de Jimmy
    Soit un coureur qui court vers un rebord à sa portée, dans la vraie physique
    Quand il saute contre la face en poussant droit vers elle et se hisse
    Alors du saut à la fin du mantle, le corps visible regarde le rebord

  Scénario: En mantle, le coureur ne tourne pas
    Soit un coureur qui saute de biais vers un rebord à sa portée, en poussant de biais
    Quand il se hisse
    Alors pendant tout le mantle le corps visible garde l'orientation qu'il avait au début du mantle

  # --- Droit ---

  Scénario: Hors du wall-run, le coureur reste droit
    Soit un coureur qui saute contre un mur, se hisse sur un rebord, glisse et retombe
    Quand aucun wall-run n'a lieu
    Alors à chaque pas, le corps visible est vertical, sans roulis ni tangage
```

Le scénario « Le coureur se tourne vers où il pousse au rythme réglé » se prouve avec la
valeur de `turn_speed` lue dans la ressource de réglage, pas avec 14 écrit dans le test.

## Hors périmètre

- Animations, modèle de personnage : étape 6. Cette spec prépare leur orientation, rien
  de plus.
- La caméra : elle reste libre, sans recentrage automatique.
- L'inclinaison du wall-run : inchangée (décision 5).
- Le moteur, les constats, le pilote de test et le parcours : inchangés (décision 7).

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Séparer ce que veut le joueur (l'intention) de ce que le décor en laisse (la vitesse) | discovered | discovered |
