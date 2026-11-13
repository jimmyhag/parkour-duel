# Mouvements aux murs : mantle, wall-run, wall-jump et parcours complet

**Statut : ⏸ En attente — ne pas confier au développeur avant la fusion de `docs/specs/movement-ground.md`**

Session du 2026-11-12, relue le 2026-11-13, avec Jimmy.

Cette spec et `docs/specs/movement-ground.md` remplacent `docs/specs/movement-advanced.md`,
scindée en deux à la relecture. Elle passera à `**Statut : 🟡 Prêt pour le dev**` après
une relecture courte avec Jimmy, une fois les mouvements au sol fusionnés : ses
décisions sont prises, ses noms et ses valeurs seront réalignés sur le code d'alors.

## Contexte

Fin de l'étape 1 de la feuille de route. Les mouvements au sol auront posé la structure
typée des constats, la glissade, la roulade, la conservation de l'élan, et un parcours
de six sections que le pilote de test franchit. Cette spec ajoute les trois mouvements
qui s'appuient sur le décor vertical, les sections qui les forcent et l'enchaînement
final. À la fin, le parcours complet force chaque mouvement au moins une fois : c'est le
point d'arrêt n°2 du plan, où Jimmy juge la sensation manette en main.

Ce qu'elle ne doit pas casser : tous les scénarios antérieurs restent verts, sauf ceux
que la relecture remplacera explicitement (la ligne d'arrivée recule de nouveau) ; les
règles d'architecture et de simulation d'`AGENTS.md` ; la décision 3 des tests réactifs.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Où vivent les nouveaux mouvements ? | Nouveaux états du coureur dans `core` : mantle, wall-run. `player` ajoute à la structure des constats : mur à gauche ou à droite avec sa normale et son identité, rebord devant avec sa hauteur et si son dessus est libre. `core` décide. | Même coupe que la base. |
| 2 | Mantle | Automatique : en l'air, en poussant vers un rebord situé entre la taille et un peu au-dessus de la tête, dont le dessus est libre, le coureur se hisse et repart avec un peu de vitesse vers l'avant. Aucun bouton. | Décision Q5. L'action contextuelle reste libre. |
| 3 | Wall-run | Automatique : en l'air, le long d'un mur, avec assez de vitesse horizontale, en poussant le long du mur, assez haut au-dessus du sol. Durée limitée ; la gravité y est très réduite. Il se termine quand la durée est écoulée, que le mur s'arrête, que la vitesse tombe trop bas, que le joueur pousse à l'opposé du mur, qu'il saute ou qu'il touche le sol. | Décision Q2. |
| 4 | Wall-jump | Sauter pendant un wall-run repousse à l'opposé du mur et vers le haut, en gardant la vitesse le long du mur. Encore possible pendant une courte tolérance après avoir décroché. | Décisions Q2 et Q15. |
| 5 | Pas de montée infinie | Après un wall-run ou un wall-jump, le même mur est refusé tant que le coureur n'a pas touché le sol ou couru sur un autre mur. | Décision Q2. |
| 6 | Quels murs | Tout mur fixe à peu près vertical et assez haut. Celui qui construit un niveau peut en exclure un en le rangeant dans un groupe prévu pour ça. | Décision Q8. |
| 7 | Capsule lisible | Elle penche du côté du mur en wall-run. | Décision Q15. |
| 8 | Parcours complet | Après la grande chute, dans cet ordre : rebord à franchir, wall-run au-dessus d'un vide, zigzag de wall-jumps entre deux murs, enchaînement final qui mêle plusieurs mouvements, arrivée. Un checkpoint par section. Environ 45 à 60 secondes pour un passage propre du parcours entier. | Décision Q14. |
| 9 | Pilote de test | Il apprend ce que ces sections demandent : pousser vers un rebord, tenir le long d'un mur, sauter d'un mur à l'autre, et relâcher le saut tôt quand le tenir le ferait dépasser sa réception. Toujours sans nombre calé sur le parcours ou les réglages. | Avec l'élan conservé les vitesses montent : un pilote qui tient toujours le saut dépasserait les blocs. |
| 10 | Plage de réglages garantie | Les nouvelles sections rejoignent les tests à plus et moins 10 % sur les quatre mêmes valeurs. | Décision de la relecture. |
| 11 | Jamais coincé | Le retour au dernier checkpoint fonctionne depuis le mantle et le wall-run. | Critère du plan. |
| 12 | Affichage de debug | Il montre les nouveaux états, la durée de wall-run restante et la tolérance de wall-jump. | Suite de la décision 18 de la base. |
| 13 | README | La section « Controls » décrit les mouvements automatiques. | Règle du plan. |

### Valeurs de départ ajoutées à la ressource de réglage

| Réglage | Valeur |
| ------- | ------ |
| Mantle : hauteur du rebord au-dessus des pieds | de 0,9 m à 2,2 m |
| Mantle : durée, vitesse de sortie | 0,35 s, 4 m/s |
| Wall-run : distance au mur, écart à la verticale toléré | 0,6 m, 15° |
| Wall-run : hauteur minimale du mur, hauteur minimale au-dessus du sol | 2 m, 1 m |
| Wall-run : vitesse pour le lancer, vitesse sous laquelle il s'arrête | 6 m/s, 4 m/s |
| Wall-run : durée maximale, gravité pendant | 1,2 s, 6 m/s² |
| Wall-jump : vitesse à l'opposé du mur, vitesse vers le haut | 7 m/s, 9,5 m/s |
| Wall-jump : tolérance après avoir décroché | 0,10 s |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Mouvements aux murs

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

  # --- Murs, parcours et pilote (player, world, levels, tests) ---

  Scénario: Un mur exclu ne donne pas de wall-run
    Soit un coureur en l'air, assez rapide, le long d'un mur rangé dans le groupe d'exclusion
    Quand il pousse le long du mur
    Alors il tombe normalement

  Scénario: Un mur trop incliné ne donne pas de wall-run
    Soit un coureur en l'air, assez rapide, le long d'une paroi plus inclinée que la tolérance
    Quand il pousse le long de la paroi
    Alors il tombe normalement

  Scénario: Le rebord se franchit
    Soit un coureur au checkpoint du rebord
    Quand le pilote de test parcourt la section
    Alors il atteint le checkpoint suivant en s'étant hissé

  Scénario: Le vide se franchit en wall-run
    Soit un coureur au checkpoint du wall-run
    Quand le pilote de test parcourt la section
    Alors il atteint le checkpoint suivant

  Scénario: Le zigzag se franchit en wall-jumps
    Soit un coureur au checkpoint du zigzag
    Quand le pilote de test parcourt la section
    Alors il atteint le checkpoint suivant

  Scénario: L'enchaînement final mène à l'arrivée
    Soit un coureur au checkpoint de l'enchaînement final
    Quand le pilote de test parcourt la section
    Alors il passe la ligne d'arrivée et la course est terminée

  Scénario: Le retour au checkpoint fonctionne depuis le mantle et le wall-run
    Soit un coureur en mantle ou en wall-run
    Quand le retour au dernier checkpoint est demandé
    Alors il réapparaît au dernier checkpoint, debout et à l'arrêt

  Scénario: L'affichage de debug montre les états des murs
    Soit l'affichage de debug visible
    Quand le coureur passe en mantle puis en wall-run
    Alors l'affichage nomme chaque état et montre les durées qui lui sont liées
```

## Hors périmètre

- Jauge de flow, multiplicateur de combo, figures aériennes, munitions : étape 2.
- Tir, visée, objets sabotables, second joueur, fantôme : étapes 3 et 4.
- Wall-run vertical (courir vers le haut d'un mur), accroche de rebord en suspension,
  double saut : non demandés.
- Sons, animations, modèle de personnage, menus, changement des touches en jeu : étape 6.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Tolérances de timing appliquées à d'autres gestes (wall-jump) | discovered | discovered |
