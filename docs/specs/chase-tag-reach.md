# Ce qui touche à l'écran attrape : la portée des gestes prise sur le corps

**Statut : 🟢 Implémenté**

Session du 2026-11-15, après avoir joué l'attrape polie (`docs/specs/chase-tag-polish.md`).
Jimmy : « les hitbox sont bizarres. Quand tu touches, ça a l'air de pas trop marcher.
Règle ça pour que ça marche vraiment à chaque fois : si le bras se tend et touche la
personne, ça se finit. Et si le plongeon touche, ça se finit aussi. » Le reste est
délégué à la session principale.

## Contexte

Pourquoi ça « bugue », lu dans le code :

- **Le jeu et l'image ne disent pas la même chose.** Pour l'équilibre des bots, la
  portée de la touche a été réglée à **0 m** et celle du plongeon à **0,8 m**
  (`chase-tag.md`, décision 11). Il faut donc que les capsules se touchent. Mais la main
  du chat se pose sur la souris par IK dès qu'elle est **à portée du bras** : mesuré, la
  main touche encore la souris à 0,2 m d'écart. On voit la main toucher, et rien ne se
  passe.
- **Une portée nulle se rate entre deux pas.** À 6,5 m/s chacun, deux coureurs qui se
  croisent se rapprochent de plus de 0,2 m par pas de 1/60 s. Les capsules peuvent donc
  ne jamais être au contact à la fin d'un pas, même quand elles se sont touchées pendant
  le pas.
- **Le chat vise où il court.** Le cône (60°) part de la course du chat. Le bras, lui,
  peut se tendre vers une souris qui passe à côté.

L'équilibre a été tenu en rétrécissant les portées. Ce levier est maintenant fermé : la
portée vient du corps. Il en reste d'autres, et d'abord **la durée de la manche**
(`chase_round_time`, 20 s), qui donne plus de victoires à la souris quand elle
raccourcit.

Ce que la spec ne doit pas casser : les règles de `chase-tag.md` (seul un geste attrape ;
le simple contact ne compte pas ; le prix d'un raté), son polissage, `chase-bot.md`
(« un niveau plus haut gagne plus »), et la règle d'`AGENTS.md` : ce que le moteur
constate ne dépend jamais du corps visible. Les portées sont des **valeurs de réglage
mesurées une fois sur le corps**, pas lues sur la main pendant la partie.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | La règle | **Ce qui touche à l'écran attrape, et ce qui attrape touche à l'écran.** Si la main tendue ou le corps qui plonge touche la souris, la manche finit ; s'ils ne la touchent pas, elle continue. | La demande de Jimmy. |
| 2 | La portée de la touche | `tag_touch_reach` = la **longueur du bras tendu** au-delà de la capsule du chat, **mesurée sur les os** du personnage (épaule tournée vers la souris, bout des doigts dans la pose de Reaching Out), arrondie au centimètre. Un test sur les fichiers vérifie que le réglage et la mesure ne s'écartent pas de plus de 3 cm. | La portée du jeu est celle qu'on voit. |
| 3 | La portée du plongeon | `tag_dive_reach` = la distance la plus grande, pendant le plongeon, entre la capsule du chat et le **bout de ses doigts**, mesurée sur le clip du plongeon tel qu'il est joué. Même test. | Pareil pour le plongeon. |
| 4 | La main suit le jeu | La main ne se pose sur la souris (IK) **que si le jeu constate l'attrape**. Sur une touche ratée, elle se tend dans le vide vers la souris, sans l'atteindre. La main ne dépasse jamais la portée du jeu. | L'image ne ment plus. |
| 5 | Le cône suit le bras | `tag_touch_cone` passe à **120°** : l'épaule pivote vers une souris qui passe sur le côté. Le haut du corps se tourne vers elle dans ce cône. Le cône du plongeon (40°) ne change pas : on plonge droit. | Le bras se tend vers la souris, pas seulement devant soi. |
| 6 | Aucune attrape entre deux pas | À chaque pas du geste, la portée se mesure à la **distance la plus courte entre les deux capsules pendant le pas** : leurs deux trajets, du début à la fin du pas. Elle ne se mesure pas seulement à la fin du pas. | Deux coureurs qui se croisent ne passent plus l'un à travers l'autre. |
| 7 | L'équilibre | Bot NORMAL contre bot NORMAL, au moins **42 manches** variées (rapportées) : le chat en gagne **35 à 65 %**. Le test des 6 manches garde ses bornes, de 1 à 5. On règle dans cet ordre, en rapportant chaque mesure : la **durée de la manche** (pas moins de 12 s), la **distance de départ**, le **délai du bot chat** avant un geste (`chase_bot_tag_delay`), le **prix d'un raté**. Les portées, les cônes et les règles ne bougent jamais pour l'équilibre. « Un niveau plus haut gagne plus » tient. | Les portées viennent du corps : l'équilibre se cherche ailleurs. |
| 8 | Les réglages | Les valeurs dans la ressource de réglage, groupes « Tag » et « Chase ». F4 les recharge. | Règle d'`AGENTS.md`. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Ce qui touche à l'écran attrape

  Scénario: Une touche du bout des doigts attrape
    Soit le chat qui touche, la souris à un écart un peu sous la portée du bras
    Quand le geste se joue
    Alors la manche finit

  Scénario: Une touche juste hors de portée rate
    Soit le chat qui touche, la souris à un écart un peu au-delà de la portée du bras
    Quand le geste se joue
    Alors la manche continue et le chat paie le raté

  Scénario: Un plongeon du bout des doigts attrape
    Soit le chat qui plonge, la souris à un écart un peu sous la portée du plongeon
    Quand le plongeon se joue
    Alors la manche finit

  Scénario: Deux coureurs qui se croisent ne se manquent pas
    Soit le chat qui touche pendant que la souris le croise à pleine vitesse, et que les capsules ne sont à portée qu'au milieu d'un pas
    Quand ce pas se joue
    Alors la manche finit

  Scénario: Le bras se tend vers une souris sur le côté
    Soit le chat qui court tout droit, la souris à portée du bras, sur le côté, dans le cône de la touche
    Quand il touche
    Alors la manche finit

  Scénario: Les portées sont celles du corps
    Soit le personnage et ses clips de touche et de plongeon
    Quand on mesure sur les os la portée du bras tendu et celle du plongeon
    Alors les réglages ne s'en écartent pas de plus de 3 cm

  Scénario: La main ne se pose que sur une attrape
    Soit le chat qui touche, une fois la souris à portée, une fois juste hors de portée
    Quand le geste se joue
    Alors la main se pose sur la souris la première fois, et s'arrête avant elle la seconde

  Scénario: L'équilibre tient avec les vraies portées
    Soit les 6 manches de bots NORMAL contre NORMAL
    Quand elles sont jouées
    Alors le chat en gagne de 1 à 5
```

Avec les fichiers, le développeur rapporte :
- les portées mesurées et la façon de les mesurer ;
- chaque mesure d'équilibre sur 42 manches, avec le levier essayé ;
- les valeurs retenues ;
- le temps de `just check`.

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** : rien ne change dans les écrans.
- **Libellés** : aucun nouveau.

## Hors périmètre

- Des capsules par membre (bras, jambes) : la capsule du corps plus la portée mesurée
  suffit.
- Un clip propre à la touche ratée.
- Le jeu en ligne : étape 5.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Faire dire la même chose au jeu et à l'image (la hitbox lisible) | — | discovered |
| Détection continue (le plus court écart pendant un pas, pas seulement à sa fin) | — | discovered |
