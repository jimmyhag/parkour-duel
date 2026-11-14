# Flow et combo : la jauge que remplissent les moves

**Statut : 🟢 Implémenté**

Session du 2026-11-14, avec Jimmy. Première des deux specs de l'étape 2 de la feuille de
route (« Figures et flow ») ; la seconde ajoutera les figures aériennes (saltos) et les
sons.

Amendée le 2026-11-14 après l'inspection, par la session principale sur délégation de
Jimmy : deux règles faisaient mentir le dilemme (le gain des glissades parfaites se
cumulait jusqu'au plafond absolu ; une jauge pleine ne rapportait plus de munitions),
la répétition survivait à la fin d'un combo, et l'arrêt lisait la vitesse voulue au
lieu de la vitesse réelle. Les décisions 3, 5, 8 et 9 sont précisées, cinq scénarios
sont ajoutés (marqués « amendement »), et les choix du code sont listés.

Amendée une seconde fois le même jour après la seconde inspection, qui a mesuré deux
boucles sans risque avec le vrai moteur : une jauge pleine qui baisse d'un rien puis
remonte redonnait une munition à chaque saut (23 par minute), et alterner saut et
glissade bouton tenu sur le plat remplissait la jauge en 10 s au multiplicateur ×4.
Les munitions viennent désormais des points de style, pas des paliers ; la répétition
se juge sur les quatre derniers moves ; un move sans valeur ne prolonge plus le
combo ; une glissade ne compte qu'à un nouvel appui (marqués « second amendement »).

## Contexte

L'étape 1 est validée par Jimmy au point d'arrêt n° 2 (2026-11-14). Ce qui existe sur
`main` :

- `game/core/runner_motor.gd` (`RunnerMotor`) : les huit états du coureur (`GROUNDED`,
  `RISING`, `FALLING`, `SLIDING`, `ROLLING`, `HARD_LANDING`, `MANTLING`,
  `WALL_RUNNING`), le saut, le wall-jump, la roulade obligatoire au-delà de
  `roll_fall_height`, la vitesse de pointe `top_speed` et le plafond absolu
  `max_horizontal_speed`.
- `game/core/race_state.gd` (`RaceState`) : le chrono en pas fixes, les checkpoints, le
  retour au checkpoint et le recommencement, le meilleur temps de la session.
- `game/core/movement_tuning.gd` et `.tres` (`MovementTuning`) : la ressource de réglage
  unique.
- `game/levels/course.gd` (`Course`) : assemble les couches, exécute les retours au
  checkpoint, nourrit les affichages.
- `game/ui/race_hud.gd` (chrono en haut de l'écran) et `game/ui/debug_overlay.gd` (F3).

Ce que Jimmy veut, avec ses mots : la jauge « se remplit si on fait des moves […] des
glissades, des sauts, des figures, même en flat » ; « elle se vide si on fait une erreur,
genre une roulade mal faite, on trébuche, on rate un jump » ; quand elle est haute,
« ça te donne des munitions et tu vas plus vite ». Et : « faudra qu'on réfléchisse à
comment rendre ça skillé […] du training à faire pour être bon ».

Le dilemme du plan à préserver : **jouer stylé pour recharger, ou jouer sûr pour
avancer**.

Ce que la spec ne doit pas casser : tous les scénarios antérieurs ; les règles
d'architecture et de simulation d'`AGENTS.md` ; la garantie à plus et moins 10 % des
réglages sur le parcours ; la limite de 30 s de `just preflight`.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Découpage de l'étape 2 | Cette spec : le flow avec les mouvements qui existent. Une seconde spec : les figures aériennes, au bouton, et les sons, après l'accord de Jimmy sur un pack gratuit à licence vérifiée. | Q1. Le flow se juge seul ; les saltos s'y brancheront. |
| 2 | Ce qui compte comme un move | Sept moves : saut, glissade, glissade parfaite (décision 9), roulade, mantle, wall-run, wall-jump. Un move compte au pas où il commence. Un saut qui est un wall-jump compte comme wall-jump, jamais aussi comme saut. Une glissade parfaite compte comme glissade parfaite, jamais aussi comme glissade. **Second amendement** : une glissade, parfaite ou non, ne compte que si le bouton a été pressé depuis la dernière glissade ; garder le bouton enfoncé ne fait compter qu'une glissade. Courir ne compte pas ; la réception dure est une erreur (décision 5). | Q2. |
| 3 | Empêcher la répétition | **Le mouvement** : un saut ne compte que si la vitesse horizontale du coureur, au pas du saut, atteint la moitié de `top_speed`. **La variété** : le même move répété d'affilée vaut 100 %, puis 50 %, puis 0 % de ses points ; un autre move remet le compte à zéro. **Second amendement**, qui remplace la phrase précédente : la valeur d'un move se juge sur les **quatre derniers moves** du combo ; absent, il vaut 100 % ; présent une fois, 50 % ; présent deux fois ou plus, 0 %. Alterner deux moves ne les garde donc pas à pleine valeur. **Amendement** : la fin d'un combo par le délai et une erreur le remettent aussi à zéro. La vitesse d'un saut est la vitesse horizontale réelle du coureur, celle que la physique lui laisse. Un move à 0 % ne rapporte rien, mais il prolonge le combo et compte pour le multiplicateur comme les autres. **Second amendement**, qui remplace la phrase précédente : un move à 0 % ne rapporte rien, ne prolonge pas le combo et ne compte pas pour le multiplicateur ; jouer sûr fait bien redescendre la jauge. | Q3 et Q14. Sans ces garde-fous, sauter sur place serait le meilleur jeu, et le dilemme disparaît. Les autres moves ne se répètent pas sur place (le wall-run demande de la vitesse, le même mur est refusé). |
| 4 | La chaîne du combo | Le combo continue tant que le move suivant commence moins de 2 s après. Les 2 s ne s'écoulent qu'au sol : en l'air, en wall-run, en mantle, en glissade et en roulade, le décompte est suspendu. Au-delà, le combo se termine sans pénalité : le multiplicateur revient à ×1, la jauge et le score restent. | Q4 et Q14. La grande chute ou un long wall-run ne doivent pas fermer un combo en plein mouvement. |
| 5 | Les erreurs | Elles **cassent** le combo : multiplicateur à ×1, compte de répétition à zéro. **Réception dure** : la jauge perd la valeur d'un palier (pas en dessous de 0). **Chute hors du parcours ou retour au checkpoint demandé** : la jauge tombe à 0. **Arrêt** : au sol, une vitesse horizontale sous 1 m/s pendant 1 s ; **amendement** : la vitesse réelle, si bien qu'un coureur qui pousse contre un mur est arrêté. Le sabotage reçu (étape 3) et le salto inachevé (seconde spec) s'ajouteront. | Q5. « On trébuche » n'existe pas dans le jeu ; le plus proche est la réception dure. |
| 6 | Le multiplicateur | ×1 au début d'un combo ; +1 tous les 4 moves du combo ; ×4 au plus. Chaque move donne ses points (après la décision 3) multipliés par le multiplicateur du moment, à la jauge et au score de style. Le move qui fait monter le multiplicateur est compté au multiplicateur d'avant. | Q6. |
| 7 | La jauge | De 0 à 3 000, trois paliers : 1 000, 2 000 et 3 000. Elle ne baisse pas pendant un combo. Hors combo, elle baisse de 100 par seconde (10 s pour perdre un palier). Elle ne dépasse pas 3 000. | Q7. Jouer sûr fait redescendre, lentement. |
| 8 | Ce que donne le flow | **Vitesse** : au palier 1, 2 et 3, `top_speed` augmente de 5 %, 10 % et 15 % ; le plafond absolu ne change pas. Le bonus suit le palier du moment, en montant comme en descendant. **Munitions** : +1 munition chaque fois que la jauge franchit un palier en montant, 3 au plus en réserve. **Second amendement**, qui remplace cette règle et le premier amendement : les munitions viennent des **points de style** ; chaque tranche de `flow_points_per_ammo` (1 000) points de style gagnés donne +1 munition, 3 au plus en réserve ; le reste est gardé pour la tranche suivante. La jauge ne donne plus que la vitesse. Pas de style, pas de munitions. **Amendement** : jauge pleine, les points au-delà de 3 000 s'accumulent, et chaque fois qu'ils atteignent la valeur d'un palier, +1 munition et le compte repart de zéro ; la jauge reste pleine. Le joueur qui ne rate rien continue de recharger. Les munitions ne servent à rien avant l'étape 3 : elles s'affichent. | Q8. |
| 9 | La glissade parfaite | Une glissade qui commence dans les 0,15 s autour d'un atterrissage (le bouton pressé au plus 0,15 s avant de toucher le sol, ou au plus 0,15 s après) est parfaite : sa vitesse horizontale gagne 2 m/s dans le sens de la glissade, sans dépasser le plafond absolu. **Amendement** : ni la vitesse de pointe du moment (bonus du flow compris) plus le gain : enchaîner les glissades parfaites ne fait pas monter la vitesse sans fin. Une glissade parfaite abordée déjà plus vite que cela garde sa vitesse, sans gain. Une réception qui demande une roulade reste une roulade : la roulade est la « parfaite » des grandes chutes. | Q9, idée de Jimmy (« un petit boost de vitesse quand tu fais glissade […] parfaitement »). |
| 10 | Le score de style | La somme des points multipliés, comptés au pas du move. Il s'affiche à l'arrivée à côté du temps, avec le meilleur score de style de la session. Rien n'est enregistré sur le disque. | Q10. Le plan : le score de style départage et servira au classement. |
| 11 | Chute, recommencement, arrivée | **Chute ou retour au checkpoint** : la jauge tombe à 0, le combo est cassé ; les munitions et le score de style restent. **Recommencer** : jauge, combo, munitions et score repartent de zéro, comme le chrono. **Arrivée** : le flow se fige ; plus rien ne compte jusqu'au recommencement. | Q15. |
| 12 | Où vit le flow | Le moteur annonce chaque move commencé et chaque réception dure par un **message daté** de `core` (quel move, à quel pas fixe). Un nouvel état de `core`, l'état du flow, ne compte qu'à partir de ces messages, de la vitesse et du contact au sol que le moteur connaît déjà, et des ordres de la course (retour au checkpoint, recommencement, arrivée). Le bonus de vitesse revient au moteur par `core`. Aucune classe de `core` ne connaît `player`, une scène ou une entrée. | Q16. À l'étape 5, les moves de l'adversaire arriveront par le réseau sous la même forme ; les tests du flow rejouent une liste de messages sans physique. |
| 13 | Les réglages | Toutes les valeurs de cette spec vivent dans la ressource de réglage unique, dans un nouveau groupe « Flow » ; F4 les recharge. | Q12 et règle d'`AGENTS.md`. |
| 14 | Le parcours à pleine vitesse | Les sections des sauts longs, du wall-run, du zigzag et de la combinaison finale sont rejouées par le pilote avec le bonus du palier 3. Si ces rejeux font dépasser 30 s à `just preflight`, le développeur s'arrête et le dit : la limite ne se relâche pas. | Q17. Un bonus de 15 % peut faire dépasser un palier d'arrivée. |
| 15 | L'affichage de debug | F3 montre aussi la jauge, le palier, le temps restant pour enchaîner, le move répété et son compte, le multiplicateur et le bonus de vitesse. | Q18. Pour régler en jouant. |
| 16 | Le HUD | Voir le contrat d'interface ci-dessous. Pas d'image de référence : Jimmy juge en jouant. | Q11 et Q19. |
| 17 | Ce qui demande du skill | Dans cette spec : la fenêtre de la glissade parfaite, la roulade au bon moment, la variété des moves, garder la chaîne au sol sous 2 s, et ne pas faire d'erreur. Le skill des figures elles-mêmes est le cœur de la seconde spec. | Demande de Jimmy : « du training à faire pour être bon ». |

### Valeurs de départ ajoutées à la ressource de réglage

Elles sont faites pour être changées par Jimmy.

| Réglage | Valeur |
| ------- | ------ |
| Points : saut, glissade | 50, 50 |
| Points : mantle, roulade | 100, 100 |
| Points : wall-run, wall-jump, glissade parfaite | 150, 150, 150 |
| Vitesse minimale d'un saut qui compte, part de `top_speed` | 0,5 |
| Valeur d'un move déjà présent parmi les quatre derniers : une fois, deux fois et plus (second amendement) | 50 %, 0 % |
| Délai entre deux moves, compté au sol | 2 s |
| Moves pour gagner un multiplicateur, multiplicateur maximal | 4, ×4 |
| Valeur d'un palier, nombre de paliers | 1 000, 3 |
| Baisse de la jauge hors combo | 100 par seconde |
| Bonus de `top_speed` aux paliers 1, 2, 3 | 5 %, 10 %, 15 % |
| Munitions au plus | 3 |
| Points de style pour une munition (second amendement) | 1 000 |
| Glissade parfaite : fenêtre autour de l'atterrissage, gain de vitesse | 0,15 s, 2 m/s |
| Arrêt : vitesse sous laquelle le coureur est arrêté, durée | 1 m/s, 1 s |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Flow et combo

  # --- Les moves (core) ---

  Scénario: Chaque move commencé rapporte ses points
    Soit un coureur sans combo, la jauge vide
    Quand il commence un wall-run
    Alors la jauge et le score de style gagnent les points du wall-run, au multiplicateur ×1

  Scénario: Un saut sans élan ne compte pas
    Soit un coureur au sol plus lent que la moitié de la vitesse de pointe
    Quand il saute
    Alors le saut ne rapporte rien et ne prolonge pas le combo

  Scénario: Un wall-jump ne compte pas aussi comme un saut
    Soit un coureur en wall-run
    Quand il saute
    Alors seul le wall-jump est compté

  Scénario: Le même move répété d'affilée vaut de moins en moins
    Soit un coureur en combo
    Quand il fait trois sauts d'affilée avec élan
    Alors le premier vaut tous ses points, le deuxième la moitié, le troisième rien

  Scénario: La fin d'un combo remet la répétition à zéro
    # amendement
    Soit un coureur qui vient de faire deux sauts d'affilée
    Quand son combo se termine par le délai puis qu'il saute de nouveau avec élan
    Alors ce saut vaut tous ses points

  Scénario: Un move absent des quatre derniers vaut tous ses points
    # second amendement : remplace « Un autre move remet la répétition à zéro »
    Soit un coureur en combo qui a sauté, puis fait quatre autres moves différents
    Quand il saute de nouveau avec élan
    Alors ce saut vaut tous ses points

  Scénario: Alterner saut et glissade sur le plat ne remplit pas la jauge sans fin
    # second amendement
    Soit un coureur en combo sur le plat
    Quand il alterne saut et glissade, chacun avec un nouvel appui
    Alors à partir du cinquième move, chacun ne vaut plus rien et le combo finit

  Scénario: Une glissade tenue ne compte qu'une fois
    # second amendement
    Soit un coureur qui garde la glissade enfoncée
    Quand il saute et glisse plusieurs fois de suite sans relâcher le bouton
    Alors seule la première glissade compte

  Scénario: Un move sans valeur ne prolonge pas le combo
    # second amendement : remplace « Un move répété sans valeur prolonge quand même le combo »
    Soit un coureur en combo dont le saut ne vaut plus rien
    Quand il saute encore et que le délai s'écoule depuis son dernier move qui valait quelque chose
    Alors le combo se termine, et le saut ne compte pas pour le multiplicateur

  # --- La chaîne et le multiplicateur (core) ---

  Scénario: Le multiplicateur monte tous les quatre moves
    Soit un coureur sans combo
    Quand il enchaîne huit moves différents dans le délai
    Alors les quatre premiers sont comptés ×1, les quatre suivants ×2

  Scénario: Le multiplicateur ne dépasse pas son maximum
    Soit un coureur en combo au multiplicateur maximal
    Quand il enchaîne encore quatre moves
    Alors le multiplicateur reste au maximum

  Scénario: Le combo se termine sans pénalité après le délai au sol
    Soit un coureur en combo
    Quand il reste au sol sans nouveau move plus longtemps que le délai
    Alors le multiplicateur revient à ×1, et la jauge et le score ne perdent rien

  Scénario: Le délai ne s'écoule pas en l'air
    Soit un coureur en combo qui tombe plus longtemps que le délai
    Quand il atterrit en roulade
    Alors la roulade prolonge le combo

  # --- Les erreurs (core) ---

  Scénario: Une réception dure casse le combo et coûte un palier
    Soit un coureur en combo, la jauge au-dessus du premier palier
    Quand il fait une réception dure
    Alors le multiplicateur revient à ×1 et la jauge perd la valeur d'un palier

  Scénario: Une réception dure ne fait pas passer la jauge sous zéro
    Soit un coureur dont la jauge est sous la valeur d'un palier
    Quand il fait une réception dure
    Alors la jauge est à 0

  Scénario: S'arrêter casse le combo
    Soit un coureur en combo
    Quand il reste au sol plus lent que la vitesse d'arrêt pendant la durée d'arrêt
    Alors le combo est cassé

  Scénario: Une chute hors du parcours vide la jauge et garde le reste
    Soit un coureur avec de la jauge, des munitions et un score de style
    Quand il tombe hors du parcours et revient au checkpoint
    Alors la jauge est à 0, le combo est cassé, les munitions et le score restent

  Scénario: Le retour au checkpoint demandé vide la jauge
    Soit un coureur avec de la jauge
    Quand il demande le retour au checkpoint
    Alors la jauge est à 0 et le combo est cassé

  Scénario: Recommencer remet tout à zéro
    Soit un coureur avec de la jauge, un combo, des munitions et un score de style
    Quand il recommence
    Alors jauge, combo, munitions et score sont à zéro, et le meilleur score de style de la session reste

  # --- La jauge, la vitesse et les munitions (core) ---

  Scénario: La jauge ne baisse pas pendant un combo
    Soit un coureur en combo, la jauge à mi-palier
    Quand des pas s'écoulent dans le délai du combo
    Alors la jauge ne baisse pas

  Scénario: La jauge baisse lentement hors combo
    Soit un coureur sans combo, la jauge pleine
    Quand dix secondes s'écoulent
    Alors la jauge a perdu la valeur d'un palier

  Scénario: La jauge ne dépasse pas son maximum
    Soit un coureur la jauge pleine, en combo
    Quand il fait un move de plus
    Alors la jauge reste pleine et le score de style gagne les points du move

  Scénario: Chaque palier augmente la vitesse de pointe
    Soit un coureur au sol, la jauge au palier 2
    Quand il court droit devant assez longtemps
    Alors sa vitesse atteint la vitesse de pointe augmentée du bonus du palier 2, sans dépasser le plafond absolu

  Scénario: Le bonus de vitesse suit la jauge en descendant
    Soit un coureur au palier 3 sans combo
    Quand la jauge redescend sous le palier 3
    Alors le bonus de vitesse devient celui du palier 2

  Scénario: Chaque tranche de points de style donne une munition
    # second amendement : remplace « Franchir un palier en montant donne une munition »
    Soit un coureur sans munition, à 900 points de style depuis sa dernière munition
    Quand un move lui rapporte 150 points
    Alors il a une munition, et 50 points comptent déjà pour la suivante

  Scénario: Une jauge qui redescend puis remonte ne donne pas de munition en plus
    # second amendement : remplace « Une jauge pleine continue de donner des munitions par le style »
    Soit un coureur la jauge pleine, sans combo, sous le seuil de points d'une munition
    Quand la jauge baisse sous un palier puis qu'un move la refait franchir
    Alors il n'a pas de munition de plus que ce que ses points de style donnent

  Scénario: Les munitions ne dépassent pas leur maximum
    Soit un coureur avec le maximum de munitions
    Quand il gagne encore une tranche de points de style
    Alors il a toujours le maximum

  # --- La glissade parfaite (core) ---

  Scénario: Une glissade commencée juste à l'atterrissage est parfaite
    Soit un coureur en l'air, assez rapide pour glisser, au-dessous de la hauteur de roulade
    Quand il presse la glissade dans la fenêtre avant de toucher le sol et la garde
    Alors il glisse avec le gain de vitesse, et c'est une glissade parfaite

  Scénario: Une glissade commencée juste après l'atterrissage est parfaite
    Soit un coureur qui vient d'atterrir, assez rapide pour glisser
    Quand il presse la glissade dans la fenêtre après avoir touché le sol
    Alors il glisse avec le gain de vitesse, et c'est une glissade parfaite

  Scénario: Les glissades parfaites ne font pas monter la vitesse sans fin
    # amendement
    Soit un coureur qui enchaîne sauts et glissades parfaites sur le plat
    Quand il en fait dix
    Alors sa vitesse ne dépasse jamais la vitesse de pointe du moment plus le gain

  Scénario: Une glissade hors de la fenêtre est une glissade simple
    Soit un coureur au sol depuis plus longtemps que la fenêtre
    Quand il glisse
    Alors il glisse sans gain, et c'est une glissade simple

  Scénario: Le gain de la glissade parfaite respecte le plafond absolu
    Soit un coureur qui atterrit presque au plafond absolu
    Quand il fait une glissade parfaite
    Alors sa vitesse ne dépasse pas le plafond absolu

  Scénario: Une grande chute donne une roulade, pas une glissade parfaite
    Soit un coureur qui tombe de plus haut que la hauteur de roulade
    Quand il presse la glissade dans la fenêtre avant de toucher le sol
    Alors il roule

  # --- L'arrivée et le score (core) ---

  Scénario: À l'arrivée, le flow se fige
    Soit un coureur en combo
    Quand il franchit la ligne d'arrivée puis fait encore des moves
    Alors son score de style et sa jauge ne changent plus

  Scénario: Le meilleur score de style de la session est gardé
    Soit deux courses finies dans la session, la seconde avec un score plus bas
    Quand la seconde se termine
    Alors le meilleur score de style est celui de la première

  # --- Dans la vraie physique ---

  Scénario: Franchir la ligne d'arrivée fige le flow
    # amendement
    Soit le coureur mené par le pilote dans la section finale, avec un score de style
    Quand il franchit la vraie ligne d'arrivée
    Alors le flow est figé et le meilleur score de style de la session est le sien

  Scénario: Un coureur qui pousse contre un mur est arrêté
    # amendement
    Soit un coureur en combo, au sol, qui pousse droit contre un mur
    Quand la durée d'arrêt s'écoule
    Alors le combo est cassé

  Scénario: Le parcours rapporte du flow
    Soit le coureur au départ de la section du wall-run, mené par le pilote, dans la vraie physique
    Quand il franchit la section
    Alors la jauge a gagné les points d'au moins un wall-run

  Scénario: Le parcours reste faisable à pleine vitesse
    Soit le bonus de vitesse du palier 3
    Quand le pilote rejoue les sections des sauts longs, du wall-run, du zigzag et de la combinaison finale
    Alors il franchit chacune d'elles

  # --- Affichages ---

  Scénario: Le HUD montre le move et ses points
    Soit un coureur en combo au multiplicateur ×2
    Quand il commence un wall-run
    Alors le HUD affiche « WALL RUN +300 » et « x2 »

  Scénario: Le HUD signale un palier franchi
    Soit un coureur juste sous le palier 2
    Quand un move fait franchir le palier
    Alors le HUD affiche « FLOW 2 » et la jauge le montre

  Scénario: Le HUD signale un combo cassé
    Soit un coureur en combo
    Quand il fait une réception dure
    Alors le HUD affiche « COMBO BROKEN »

  Scénario: Le HUD montre les munitions
    Soit un coureur avec deux munitions
    Quand le HUD se met à jour
    Alors il montre deux munitions sur trois

  Scénario: L'arrivée montre le score de style
    Soit une course finie avec un score de style
    Quand le HUD se met à jour
    Alors il montre le score de style et le meilleur score de style de la session

  Scénario: L'affichage de debug montre le flow
    Soit l'affichage de debug visible
    Quand le coureur est en combo
    Alors il montre la jauge, le palier, le délai restant, le move répété et son compte, le multiplicateur et le bonus de vitesse
```

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy n'en a pas fourni, il juge en jouant.
- **Arbre de composants** :

  | Composant | Couche | Statut |
  | --------- | ------ | ------ |
  | HUD du flow (jauge, multiplicateur, munitions, texte du move) | `game/ui/` | créé : rien n'affiche le flow aujourd'hui |
  | HUD de la course (chrono) | `game/ui/` | modifié : score de style et meilleur score à l'arrivée |
  | Affichage de debug | `game/ui/` | modifié : lignes du flow |

- **Placement** : la jauge en bas au centre, une barre horizontale avec trois marques
  de palier ; le multiplicateur à gauche de la jauge ; les munitions à droite, trois
  pastilles, pleines ou vides ; le texte du move au-dessus de la jauge. Le chrono reste
  en haut.
- **États** :
  - au départ : jauge vide, « x1 », trois pastilles vides, pas de texte ;
  - nominal : le texte du dernier move et ses points s'affiche, puis s'efface après
    environ 1 s ;
  - palier franchi : la jauge flashe et « FLOW 1 », « FLOW 2 » ou « FLOW 3 » s'affiche ;
  - combo cassé : « COMBO BROKEN » s'affiche ;
  - arrivée : « STYLE » et le score, « BEST STYLE » et le meilleur score de la session,
    sous le temps.
- **Lisibilité** : chaque palier se lit par du texte et par les marques de la jauge, pas
  seulement par la couleur.
- **Focus** : aucun élément ne prend le focus.
- **Libellés** (en anglais) : « JUMP », « SLIDE », « PERFECT SLIDE », « ROLL »,
  « MANTLE », « WALL RUN », « WALL JUMP », suivis de « +<points> » ; « x<multiplicateur> » ;
  « FLOW <palier> » ; « COMBO BROKEN » ; « STYLE <score> » ; « BEST STYLE <score> ».

## Choix acceptés à l'inspection

Le code a tranché ces points là où la spec se taisait ; ils sont acceptés le
2026-11-14 et Jimmy peut rouvrir chacun après avoir joué.

- **« Au sol »** pour le délai et l'arrêt : debout sur ses pieds (`GROUNDED` ou
  `HARD_LANDING`) ; en glissade et en roulade, le délai est suspendu.
- **Une erreur hors combo** remet la répétition à zéro ; « COMBO BROKEN » ne s'affiche
  que s'il y avait un combo.
- **Le flow compte avant la ligne de départ** (elle est à 3 m) ; recommencer remet
  tout à zéro.
- **Un atterrissage** est la fin d'une chute ; un coureur posé par un retour au
  checkpoint n'atterrit pas, et ne peut pas faire de glissade parfaite à cet instant.
- **La glissade parfaite** demande l'appui et l'atterrissage dans la fenêtre : un
  bouton tenu depuis longtemps donne une glissade simple.
- **Une glissade compte** quand le joueur la demande, y compris en sortie de roulade
  bouton tenu ; une glissade forcée par un plafond bas ne compte pas.
- **Les points** : arrondis après la part de répétition, puis multipliés.
- **Les durées d'affichage du HUD** (texte environ 1 s, flash 0,4 s) sont des
  constantes de l'interface, pas des réglages de sensation.
- **Les messages du pas d'un retour au checkpoint** sont perdus ; ils n'auraient rien
  rapporté à une jauge remise à zéro.
- **Le pilote** court jusqu'à la vitesse de pointe du moment, bonus compris : les
  tests à plus et moins 10 % tournent avec le flow actif.
- **Le pilote ne fait pas de glissade parfaite** : aucun test ne prouve que son gain ne
  fait pas rater une réception du parcours ; à juger en jouant.

### Choix du second amendement

- **Ce qui remet la fenêtre des quatre derniers moves à zéro** : la fin d'un combo, une
  erreur, une chute, un recommencement.
- **Le reste des points d'une munition** est gardé à travers les combos et les
  chutes ; recommencer le remet à zéro. Avec le maximum de munitions en réserve, les
  points continuent de compter pour la suivante.
- **La boucle saut et glissade parfaite sur le plat** reste plus rapide que courir :
  c'est le skill voulu (une fenêtre de 0,15 s à chaque réception), mais ses moves
  perdent leur valeur à la répétition. À juger manette en main.

## Hors périmètre

- **Les figures aériennes** (saltos au bouton), leur skill (timing, réception, rotations
  selon la hauteur) et les **sons** : la seconde spec de l'étape 2. Elle commence par une
  session de sparring sur le skill des figures, à la demande de Jimmy.
- Le tir, la visée et la dépense des munitions : étape 3. Le sabotage reçu comme erreur :
  étape 3.
- Le personnage animé (Mixamo) : étape 6, confirmé par Jimmy le 2026-11-14.
- L'enregistrement des scores sur le disque, le classement : plus tard.
- Allonger le parcours : rien dans cette spec ne le demande.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Économie d'un combo : garde-fous contre la répétition, risque contre récompense | — | discovered |
| Événements datés produits par la simulation, comptés par un autre état | — | discovered |
