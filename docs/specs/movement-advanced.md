# Mouvements avancés : glissade, roulade, mantle, wall-run, wall-jump et parcours complet

**Statut : ⏸ En attente — ne pas confier au développeur avant que Jimmy ait validé la base**

Session du 2026-11-12, avec Jimmy.

Cette spec passera à `**Statut : 🟡 Prêt pour le dev**` après une relecture courte avec
Jimmy, une fois `docs/specs/movement-base.md` implémentée, jouée et réglée. Les
décisions ci-dessous sont prises ; les valeurs de départ et les noms de fichiers seront
réalignés sur ce que la base aura produit.

## Contexte

Seconde moitié de l'étape 1 de la feuille de route. La base
(`docs/specs/movement-base.md`) aura posé : le calcul du mouvement dans `game/core/`,
son exécution dans `game/player/`, les intentions et leur source remplaçable, la
ressource de réglage unique, la caméra, les checkpoints, le chrono, l'affichage de
debug, et le début du parcours test avec ses tests rejoués par section.

Cette spec ajoute les cinq mouvements qui font le parkour, la conservation de l'élan
qui les relie, et le reste du parcours. À la fin, le parcours complet force chaque
mouvement au moins une fois : c'est le point d'arrêt n°2 du plan, où Jimmy juge la
sensation manette en main.

Ce qu'elle ne doit pas casser : tous les scénarios de la base restent verts, et les
règles d'architecture et de simulation d'`AGENTS.md`.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Où vivent les nouveaux mouvements ? | Nouveaux états du coureur dans `core` : glissade, roulade, réception lourde, mantle, wall-run. `player` fournit les nouveaux constats (mur à gauche ou à droite avec sa normale et son identité, rebord devant avec sa hauteur, plafond au-dessus, pente du sol, hauteur de la chute) ; `core` décide. | Même coupe que la base. |
| 2 | Glissade | Maintien du bouton, au sol, à partir d'une vitesse minimale. Ralentit doucement sur le plat, accélère en descente. La capsule s'abaisse et passe sous un obstacle bas. Elle s'arrête au relâchement ou sous une vitesse plancher ; tant qu'un plafond est au-dessus, le coureur reste baissé. Sauter pendant la glissade garde la vitesse horizontale. | Décision Q3. |
| 3 | Roulade | Après une chute haute, glissade pressée dans une courte fenêtre avant de toucher le sol : roulade, vitesse horizontale conservée. Sinon : réception lourde, vitesse fortement réduite et accélération affaiblie un court instant. Sous le seuil de hauteur : réception normale. Aucun dégât. | Décision Q4 : le beau geste rapporte, le rater coûte du temps. |
| 4 | Mantle | Automatique : en l'air, en poussant vers un rebord situé entre la taille et un peu au-dessus de la tête, dont le dessus est libre, le coureur se hisse et repart avec un peu de vitesse vers l'avant. Aucun bouton. | Décision Q5. L'action contextuelle reste libre. |
| 5 | Wall-run | Automatique : en l'air, le long d'un mur, avec assez de vitesse horizontale, en poussant le long du mur, assez haut au-dessus du sol. Durée limitée ; la gravité y est très réduite. Il se termine quand la durée est écoulée, que le mur s'arrête, que la vitesse tombe trop bas, que le joueur pousse à l'opposé du mur, qu'il saute ou qu'il touche le sol. | Décision Q2. |
| 6 | Wall-jump | Sauter pendant un wall-run repousse à l'opposé du mur et vers le haut, en gardant la vitesse le long du mur. Encore possible pendant une courte tolérance après avoir décroché. | Décisions Q2 et Q15. |
| 7 | Pas de montée infinie | Après un wall-run ou un wall-jump, le même mur est refusé tant que le coureur n'a pas touché le sol ou couru sur un autre mur. | Décision Q2. |
| 8 | Quels murs | Tout mur fixe à peu près vertical et assez haut. Celui qui construit un niveau peut en exclure un en le rangeant dans un groupe prévu pour ça. | Décision Q8. |
| 9 | Conservation de l'élan | Une vitesse supérieure à la vitesse de pointe (descente en glissade, wall-jump, chute) n'est pas coupée d'un coup : elle redescend lentement au sol et pas du tout en l'air, sous un plafond absolu. | Plan : « conservation de l'élan entre les mouvements ». |
| 10 | Capsule lisible | Elle se tasse en glissade et en roulade, et penche du côté du mur en wall-run. | Décision Q15. |
| 11 | Parcours complet | Le parcours de la base est prolongé, dans cet ordre : passage bas à franchir en glissade, grande chute à amortir en roulade, rebord à franchir, wall-run au-dessus d'un vide, zigzag de wall-jumps entre deux murs, enchaînement final qui mêle plusieurs mouvements, arrivée. Un checkpoint par section. Environ 45 à 60 secondes pour un passage propre. | Décision Q14. |
| 12 | Jamais coincé | Un test rejoué par nouvelle section, comme dans la base. Le retour au dernier checkpoint doit fonctionner depuis n'importe quel état (glissade, mantle, wall-run). | Critère du plan : aucun blocage dans le décor. |
| 13 | Affichage de debug | Il montre les nouveaux états et les nouvelles minuteries (durée de wall-run restante, tolérance de wall-jump, fenêtre de roulade). | Suite de la décision 18 de la base. |
| 14 | README | La section « Controls » décrit la glissade, la roulade et les mouvements automatiques. | Règle du plan. |

### Valeurs de départ ajoutées à la ressource de réglage

| Réglage | Valeur |
| ------- | ------ |
| Glissade : vitesse minimale pour la lancer, vitesse plancher | 5 m/s, 2,5 m/s |
| Glissade : ralentissement sur le plat | 4 m/s² |
| Glissade : hauteur de la capsule | 0,9 m |
| Roulade : hauteur de chute qui la rend nécessaire | 4 m |
| Roulade : fenêtre avant l'atterrissage, durée | 0,20 s, 0,5 s |
| Réception lourde : vitesse gardée, durée | 35 %, 0,35 s |
| Mantle : hauteur du rebord au-dessus des pieds | de 0,9 m à 2,2 m |
| Mantle : durée, vitesse de sortie | 0,35 s, 4 m/s |
| Wall-run : distance au mur, écart à la verticale toléré | 0,6 m, 15° |
| Wall-run : hauteur minimale du mur, hauteur minimale au-dessus du sol | 2 m, 1 m |
| Wall-run : vitesse pour le lancer, vitesse sous laquelle il s'arrête | 6 m/s, 4 m/s |
| Wall-run : durée maximale, gravité pendant | 1,2 s, 6 m/s² |
| Wall-jump : vitesse à l'opposé du mur, vitesse vers le haut | 7 m/s, 9,5 m/s |
| Wall-jump : tolérance après avoir décroché | 0,10 s |
| Élan : ralentissement au sol au-dessus de la vitesse de pointe | 6 m/s² |
| Élan : vitesse horizontale maximale absolue | 22 m/s |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Mouvements avancés

  # --- Glissade (core) ---

  Scénario: La glissade démarre au sol avec assez de vitesse
    Soit un coureur au sol plus rapide que la vitesse minimale de glissade
    Quand il maintient la glissade
    Alors il passe en glissade et sa capsule s'abaisse

  Scénario: La glissade est refusée sans vitesse
    Soit un coureur au sol plus lent que la vitesse minimale de glissade
    Quand il maintient la glissade
    Alors il reste debout

  Scénario: La glissade ralentit sur le plat
    Soit un coureur en glissade sur un sol plat
    Quand la glissade se poursuit
    Alors sa vitesse diminue au rythme réglé, puis il se relève sous la vitesse plancher

  Scénario: La glissade accélère en descente
    Soit un coureur en glissade sur une pente descendante
    Quand la glissade se poursuit
    Alors sa vitesse augmente

  Scénario: Le coureur reste baissé sous un plafond bas
    Soit un coureur en glissade sous un obstacle bas
    Quand il relâche la glissade
    Alors il reste baissé jusqu'à ce que le plafond soit dégagé

  Scénario: Sauter en glissade garde la vitesse
    Soit un coureur en glissade plus rapide que la vitesse de pointe
    Quand il saute
    Alors sa vitesse horizontale au départ du saut est celle de la glissade

  # --- Réception (core) ---

  Scénario: Une roulade réussie garde la vitesse
    Soit un coureur qui tombe de plus haut que le seuil de roulade
    Quand il presse la glissade dans la fenêtre avant de toucher le sol
    Alors il roule et sa vitesse horizontale est conservée

  Scénario: Une réception lourde coûte de la vitesse
    Soit un coureur qui tombe de plus haut que le seuil de roulade
    Quand il touche le sol sans avoir pressé la glissade dans la fenêtre
    Alors sa vitesse horizontale est fortement réduite pendant un court instant

  Scénario: Une glissade pressée trop tôt ne donne pas de roulade
    Soit un coureur qui tombe de plus haut que le seuil de roulade
    Quand il presse la glissade avant la fenêtre et la relâche
    Alors la réception est lourde

  Scénario: Une petite chute se reçoit normalement
    Soit un coureur qui tombe de moins haut que le seuil de roulade
    Quand il touche le sol
    Alors il continue sa course sans roulade ni ralentissement

  # --- Mantle (core) ---

  Scénario: Le coureur se hisse sur un rebord à sa portée
    Soit un coureur en l'air face à un rebord dans la plage de hauteur, dessus libre
    Quand il pousse vers le rebord
    Alors il se hisse et se retrouve debout sur le rebord avec la vitesse de sortie

  Scénario: Un rebord trop haut n'est pas franchi
    Soit un coureur en l'air face à un rebord plus haut que la plage
    Quand il pousse vers le rebord
    Alors il ne se hisse pas et retombe

  Scénario: Pas de mantle sans pousser vers le rebord
    Soit un coureur en l'air face à un rebord dans la plage de hauteur
    Quand il ne pousse pas vers le rebord
    Alors il ne se hisse pas

  Scénario: Pas de mantle si le dessus est encombré
    Soit un coureur en l'air face à un rebord dans la plage de hauteur, dessus occupé
    Quand il pousse vers le rebord
    Alors il ne se hisse pas

  # --- Wall-run et wall-jump (core) ---

  Scénario: Le wall-run démarre tout seul le long d'un mur
    Soit un coureur en l'air, assez rapide, assez haut, le long d'un mur vertical
    Quand il pousse le long du mur
    Alors il passe en wall-run sans appuyer sur un bouton

  Scénario: Pas de wall-run sans vitesse
    Soit un coureur en l'air le long d'un mur, plus lent que la vitesse de lancement
    Quand il pousse le long du mur
    Alors il tombe normalement

  Scénario: Le wall-run ralentit la chute
    Soit un coureur en wall-run
    Quand le wall-run se poursuit
    Alors il perd beaucoup moins de hauteur qu'en chute libre pendant la même durée

  Scénario: Le wall-run s'arrête au bout de sa durée
    Soit un coureur en wall-run depuis la durée maximale
    Quand un pas de plus s'écoule
    Alors il décroche et tombe

  Scénario: Le wall-run s'arrête quand le mur s'arrête
    Soit un coureur en wall-run
    Quand le mur n'est plus détecté
    Alors il décroche et tombe

  Scénario: Pousser à l'opposé du mur fait décrocher
    Soit un coureur en wall-run
    Quand il pousse à l'opposé du mur
    Alors il décroche et tombe

  Scénario: Le wall-jump repousse à l'opposé du mur
    Soit un coureur en wall-run
    Quand il saute
    Alors il part vers le haut et à l'opposé du mur, en gardant sa vitesse le long du mur

  Scénario: Le wall-jump reste possible juste après avoir décroché
    Soit un coureur qui vient de décrocher d'un wall-run
    Quand il saute avant la fin de la tolérance
    Alors il fait un wall-jump

  Scénario: Le même mur est refusé deux fois de suite
    Soit un coureur qui vient de quitter un mur par un wall-jump, sans toucher le sol
    Quand il revient le long du même mur
    Alors il ne repasse pas en wall-run

  Scénario: Un autre mur est accepté
    Soit un coureur qui vient de quitter un mur par un wall-jump, sans toucher le sol
    Quand il arrive le long d'un autre mur
    Alors il passe en wall-run sur ce mur

  Scénario: Toucher le sol autorise de nouveau le même mur
    Soit un coureur qui a quitté un mur puis touché le sol
    Quand il revient en l'air le long de ce mur
    Alors il passe en wall-run

  # --- Élan (core) ---

  Scénario: L'élan au-dessus de la vitesse de pointe se garde en l'air
    Soit un coureur en l'air plus rapide que la vitesse de pointe
    Quand il reste en l'air
    Alors sa vitesse horizontale ne diminue pas

  Scénario: L'élan redescend lentement au sol
    Soit un coureur au sol plus rapide que la vitesse de pointe
    Quand il continue de pousser vers l'avant
    Alors sa vitesse revient vers la vitesse de pointe au rythme lent réglé, pas d'un coup

  Scénario: La vitesse horizontale a un plafond absolu
    Soit un coureur qui enchaîne des gains de vitesse
    Quand sa vitesse atteint le plafond absolu
    Alors elle ne le dépasse pas

  # --- Constats, murs et parcours (player, world, levels) ---

  Scénario: Un mur exclu ne donne pas de wall-run
    Soit un coureur en l'air, assez rapide, le long d'un mur rangé dans le groupe d'exclusion
    Quand il pousse le long du mur
    Alors il tombe normalement

  Scénario: Un mur trop incliné ne donne pas de wall-run
    Soit un coureur en l'air, assez rapide, le long d'une paroi plus inclinée que la tolérance
    Quand il pousse le long de la paroi
    Alors il tombe normalement

  Scénario: Le retour au checkpoint fonctionne depuis chaque mouvement
    Soit un coureur en glissade, en mantle ou en wall-run
    Quand l'action de retour au dernier checkpoint est déclenchée
    Alors il réapparaît au dernier checkpoint, debout et à l'arrêt

  Scénario: Le passage bas se franchit en glissade
    Soit un coureur au checkpoint du passage bas
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il atteint le checkpoint suivant

  Scénario: Le passage bas arrête un coureur debout
    Soit un coureur au checkpoint du passage bas
    Quand il court vers le passage sans glisser
    Alors il est arrêté par l'obstacle et n'atteint pas le checkpoint suivant

  Scénario: La grande chute se franchit avec une roulade
    Soit un coureur au checkpoint de la grande chute
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il atteint le checkpoint suivant en ayant roulé

  Scénario: Le rebord se franchit
    Soit un coureur au checkpoint du rebord
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il atteint le checkpoint suivant en s'étant hissé

  Scénario: Le vide se franchit en wall-run
    Soit un coureur au checkpoint du wall-run
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il atteint le checkpoint suivant

  Scénario: Le zigzag se franchit en wall-jumps
    Soit un coureur au checkpoint du zigzag
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il atteint le checkpoint suivant

  Scénario: L'enchaînement final mène à l'arrivée
    Soit un coureur au checkpoint de l'enchaînement final
    Quand une suite d'intentions écrite à l'avance est rejouée
    Alors il passe la ligne d'arrivée et la course est terminée

  Scénario: L'affichage de debug montre les nouveaux états
    Soit l'affichage de debug visible
    Quand le coureur passe en glissade, en roulade, en mantle puis en wall-run
    Alors l'affichage nomme chaque état et montre les minuteries qui lui sont liées
```

## Hors périmètre

- Jauge de flow, multiplicateur de combo, figures aériennes, munitions : étape 2. Les
  mouvements de cette spec n'ont pas encore de score.
- Tir, visée, objets sabotables, second joueur, fantôme : étapes 3 et 4.
- Wall-run vertical (courir vers le haut d'un mur), accroche de rebord en suspension,
  double saut : non demandés.
- Sons, animations, modèle de personnage, menus, changement des touches en jeu : étape 6.

## Concepts travaillés

Les mêmes que la base ; voir `docs/specs/movement-base.md`.

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Tolérances de timing appliquées à d'autres gestes (roulade, wall-jump) | non évalué | discovered |
