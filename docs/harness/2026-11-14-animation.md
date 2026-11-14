# Leçons des tours — le personnage animé

Tours du 2026-11-14, propriétaire : Jimmy. L'étape 6 avancée avant l'étape 5 par
décision de Jimmy : le personnage Mixamo (`docs/specs/character-animations.md`), la pose
du wall-run, la locomotion fluide (`docs/specs/locomotion-blend.md`), puis deux passes de
propreté (`docs/specs/animation-polish.md`). Pull requests n° 39, 42, 43, 44, 45, 46, 47,
48, 49 et 50. Les huit rapports des agents sont à la fin, mot pour mot.

Rédigé par l'assistant de la session principale, à relire par Jimmy : ce sont des
constats et des propositions, aucun rôle n'a été modifié.

## Déroulé

| Étape | Qui | Résultat |
| ----- | --- | -------- |
| Licence et compte | session principale, Jimmy | FAQ Mixamo lue dans le navigateur intégré (l'outil de lecture web était refusé) ; dépôt public obligatoire (quota de CI épuisé) : les fichiers restent hors du dépôt, ignorés |
| Téléchargements | Jimmy, puis la session principale | Jimmy a téléchargé le personnage et 12 animations ; plus tard, connecté dans le navigateur intégré, la session principale a téléchargé « Standard Walk » et « Sprint » elle-même |
| Personnage | développeur, inspecteur | 1,8 m, chaque état son clip, capsule sans les fichiers ; « conforme » ; version d'avant-goût jouée par Jimmy |
| Wall-run, pose | Jimmy, développeur | « il rentre sa tête dans le mur » : inclinaison en double et aucun décalage ; corrigé par mesure des os |
| Locomotion | développeur, inspecteur | blend space, fondus par paire, pieds en phase ; « conforme » |
| Propreté, passe 1 | Jimmy, développeur | « saccadé », « il s'écrase contre le mur » ; mesure image par image à 60, 144, 240 Hz : fantôme figé, miroir instantané ; wall-run refait en course inclinée |
| Inspection après fusion | inspecteur | « à corriger » : fondus par paire écrasés chaque pas, creux au bouclage de la course, arrêt brutal, pied droit qui glisse |
| Propreté, passe 2 | développeur | tout corrigé, pieds à ±5 % le long de la course |

## Leçons

1. **Ce que Jimmy voit, les tests ne le voient pas sans mesure.** « Saccadé » et « il
   s'écrase contre le mur » ont été transformés en chiffres (vitesse des os image par
   image, distance des os au mur, vitesse du pied d'appui contre le sol). Sans ces
   mesures, les deux premières versions passaient tous leurs tests. Proposition : toute
   spec de présentation définit sa mesure et son seuil.
2. **Deux mesures du même phénomène peuvent diverger.** Le développeur trouvait 0 à 6 %
   de glissement du pied, l'inspecteur 10 à 21 % : l'un mêlait les deux pieds, l'autre
   comptait le glissement de côté qui est dans le fichier Mixamo. La spec dit maintenant
   la méthode exacte. Proposition : une mesure dans une spec vient avec sa méthode.
3. **Un fichier sous licence restrictive se tient hors d'un dépôt public, avec un
   repli.** Ignoré par Git, copié par une commande, la capsule quand il manque : la CI et
   les tests ont tourné sans lui tout du long, et aucun fichier n'a fui (vérifié à chaque
   tour par `git add -A --dry-run`).
4. **Un clip dédié n'est pas toujours la bonne réponse.** Le wall-run Mixamo étiré et
   balancé n'a jamais été propre ; la course du blend space, le corps incliné et une
   entrée douce l'ont été du premier coup. C'est la façon des jeux du genre.
5. **L'inspection après fusion a encore trouvé trois défauts bloquants.** Fusionner pour
   que Jimmy joue vite était le bon choix ; l'inspection juste après, aussi. Les deux ne
   s'excluent pas.
6. **Les portes grossissent avec le projet.** Avec les fichiers Mixamo, `just check`
   dépasse 90 s et `just preflight` frôle 40 s : une spec dédiée les accélère, sans rien
   retirer (`docs/specs/gate-speed.md`).

## Ce qui reste ouvert après ces tours

- **À juger par Jimmy en jouant** : le wall-run en course inclinée, les fondus par paire,
  l'arrêt qui passe par la marche, la cadence au sprint, le glissement de côté au sprint
  (il faudrait l'IK), le va-et-vient des hanches.
- Le temps des portes (spec en cours).

## Rapports des agents, mot pour mot

### Développeur, personnage

`````markdown
# Rapport développeur : character-animations

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a598a93b4f6797023`
Branche : `character-animations` (rien n'est poussé, aucune PR ouverte)
Commits :
- `896ab97` character-animations: the Mixamo character, kept out of the repository (docs/specs/character-animations.md)
- `37fe26a` AGENTS.md: the layout with the animated character and the Mixamo files (lignes Layout seulement)
- `6587571` spec: character-animations implemented (ligne de statut seulement)
- `e1a69fb` merge de `main` (5974871 : PR #40 trick-gestures-3, puis PR #41, qui n'ajoute qu'un fichier de docs/harness)

## Fait

Les 9 scénarios ont chacun leur test. Je les ai vus rouges avant le code : erreur de parse tant que `RunnerAnimation`, `character_model` ou `tools/mixamo.py` n'existaient pas, et des asserts en échec pour `.gitignore`.

| Scénario | Test | Fichier |
| --- | --- | --- |
| Chaque état du coureur a son animation | `test_every_state_of_the_runner_has_its_animation` | `tests/test_runner_animation.gd` |
| La course suit la vitesse | `test_the_run_follows_the_speed` | idem |
| Le wall-run de l'autre côté est en miroir | `test_the_wall_run_on_the_other_side_is_mirrored` | idem |
| Une figure prend la pose groupée | `test_a_trick_takes_the_tuck_pose` | idem |
| La visée prend le haut du corps | `test_aiming_takes_the_upper_body` | idem |
| Un atterrissage simple joue Landing brièvement | `test_a_simple_landing_plays_landing_briefly` | idem |
| Sans les fichiers, la capsule reste | `test_without_the_files_the_capsule_stays` (joueur et fantôme) | `tests/test_player.gd` |
| Les fichiers Mixamo ne sont jamais suivis par Git | `test_mixamo_files_are_never_tracked_by_git` | `tests/test_mixamo_files.gd` |
| La commande de copie range les fichiers utilisés | `test_the_copy_command_puts_away_the_used_files` (dossier et zip factices, l'outil lancé avec le Python de `.venv`) | `tests/test_mixamo_files.gd` |

J'ai ajouté deux tests qui ne correspondent pas à un scénario : `test_abrupt_entries_have_no_blend` (décision 7) et `test_the_ghost_replays_the_animation_recorded_with_each_frame` (décision 9, dans `tests/test_ghost_run.gd`).

Ce que fait le code :
- `game/core/runner_animation.gd` (`RunnerAnimation.of(motor, step_seconds)`) est la fonction pure de la décision 8. Elle rend le clip, la vitesse de lecture ou la durée à tenir, le miroir, la visée du haut du corps et le temps de fondu.
- `game/player/runner_character.gd` affiche ce choix. Il charge le personnage, qu'il met à 1,8 m, pieds au sol, tourné vers -Z. Il construit une fois la bibliothèque de clips : chaque clip est coupé et joué sur place, la pose groupée est extraite de Backflip au moment où le genou est le plus plié, avec les hanches droites, et Pistol Idle sert de clip de visée. Il joue le tout dans un AnimationTree : une transition entre clips, une échelle de temps, puis un Blend2 filtré sur la colonne vertébrale et tout ce qu'elle porte. Un `SkeletonModifier3D` redresse le buste de la visée par rapport aux hanches des jambes.
- `Player` et `Ghost` prennent le personnage quand les fichiers sont là. Sinon ils gardent la capsule et sa visière, inchangées. Le bot est teinté orange, et le fantôme porte le matériau orange transparent de sa capsule. `GhostRun` enregistre l'animation de chaque frame, et le duel la rejoue.
- `.gitignore` ignore `assets/mixamo/`. `just mixamo <dossier>` lance `tools/mixamo.py` (bibliothèque standard seulement, sans chemin machine dans le dépôt). L'outil copie les 12 fichiers sous des noms fixes et extrait du zip le seul `pistol idle.fbx`. Il écrit à côté de chaque fichier ses réglages d'import :
  - le personnage avec son maillage ;
  - pour les autres fichiers, les nœuds de maillage sont sautés (`import/skip_import`) : il ne reste que le squelette et l'animation, et la seule copie du maillage est celle de `Ch08_nonPBR.fbx`.

  S'il manque un fichier, l'outil le nomme et ne copie rien. Un fichier déjà identique n'est pas recopié.
- README : nouvelle section « The animated character » (les fichiers à télécharger, les réglages, `just mixamo`). `assets/CREDITS.md` : les lignes Mixamo, avec l'auteur, la FAQ et la mention « jamais dans le dépôt ». `AGENTS.md` : seules les lignes Layout changent.

## Vérifié

Toutes les commandes ont tourné sur la machine de Jimmy, dans le worktree, avec PATH vers Godot 4.7.2.
- `just setup` : vert, 42 s.
- `just mixamo "C:\Users\jimmy\Documents\mixamo"` : « 13 file(s) copied », 5 s. Le premier import Godot a pris 1 min 32, **sans aucune erreur ni warning**.
- `just check` **sans** les fichiers (dossier `assets/mixamo` déplacé hors du projet, donc les conditions de la CI) : vert, 86 s.
- `just check` **avec** les fichiers, après le dernier merge de main : vert, **88 s**. GUT : 57,4 s. Builds : Windows 192 MiB, Linux 158 MiB. Sans les fichiers : 104 et 70 MiB.
- `just preflight` avec les fichiers : vert, **35 s**. Les tests sans les replays de course prennent 20 s, contre 18 s sans le personnage.
- `tools/check_structure.py` : 0 problème avec et sans les fichiers. Il ne lit que `game/` et `tests/`, donc aucune règle de gate n'a changé.
- `git ls-files` ne contient aucun fichier Mixamo, aucun `.fbx` et aucun `.import` ou `.uid` de Mixamo. `git check-ignore` confirme que `assets/mixamo/*.import` et les PNG extraits sont ignorés.
- Un piège de performance, trouvé puis corrigé. Le cache de ressources libérait la scène du personnage dès qu'aucun coureur n'existait plus. Chaque nouveau coureur la rechargeait alors, à environ 1,4 s par chargement, et `test_player_facing` passait de 1,7 s à 17,5 s. La scène est maintenant gardée dans une variable statique, comme la bibliothèque de clips. Il reste 1,45 s de construction de la bibliothèque, une fois par processus.
- Présentation réelle, vérifiée en headless seulement, avec des scripts de relevé hors du dépôt :
  - **Hauteur et sol.** Échelle calculée sur la boîte de liaison : 1,80 m. En Idle, le haut de la tête est à 1,68 m et les orteils à 0,01-0,02 m. En course, la tête est à 1,75 m. En Landing et en Hard Landing, les orteils restent à 0,01-0,04 m. L'avant des pieds pointe vers -Z, la main gauche est à -X : le personnage regarde bien là où regarde le coureur.
  - **Chaque clip affiché.** Accroupi en Landing et en Hard Landing (hanches à 0,60-0,65 m), tête à 0,14 m pendant la roulade, hanches à 0,36 m et pied tendu 1 m devant en slide. En pose groupée, les genoux sont à hauteur de hanche devant le corps, les pieds sous les genoux et les mains aux genoux.
  - **Wall Run.** Le pied gauche monte sur le côté gauche (x = -0,47, y = 0,53) : le mur de Mixamo est à gauche. En miroir, le même pied passe à +0,47.
  - **Visée.** En Idle, les deux mains sont devant la poitrine (y ≈ 1,45, z ≈ -0,35). En course, elles sont devant aussi, décalées de 0,2 à 0,3 m vers la gauche.
  - **Coureur complet** sur un sol, piloté. La chaîne état → clip → état de l'AnimationTree suit : FALLING/falling_idle, GROUNDED/landing, idle, running, SLIDING/running_slide, RISING/tuck, FALLING/tuck, FALLING/falling_idle (déplié), SLIDING (posé), puis course en visant. La capsule est cachée.
  - **Toute la suite de tests** a tourné avec le personnage présent, bot et fantôme compris, sans aucune erreur moteur, alors que GUT échoue sur toute erreur inattendue.

## Non vérifié

- **Aucune image à l'écran.** Le rendu headless n'en produit pas, et la consigne interdisait la fenêtre. Rien n'a été vu de l'œil : textures, éclairage, l'overlay orange du bot, le fantôme transparent.
- **Le ressenti, à juger par Jimmy manette en main :**
  - la cadence de Running ;
  - la brièveté de Landing, y compris à chaque marche descendue ;
  - le fondu de 0,1 s ;
  - la pose groupée pendant salto, vrille et spin, et son dépliage ;
  - le miroir du wall-run, et le léger pivot du buste (environ 35°) que le clip garde avant la coupe ;
  - la montée du mantle, jouée 1,9 fois plus vite pour tenir en 0,35 s ;
  - la roulade, accélérée 1,6 fois ;
  - le buste en visée pendant un slide ou une roulade ;
  - l'inclinaison de wall-run qui s'ajoute à celle de l'animation (décision 11 : réglable à 0).
- **Défauts visuels connus**, sans vérification à l'écran :
  - le miroir bascule d'un coup quand le wall-run finit, donc le fondu vers Falling Idle peut « sauter » une fois ;
  - F4 (rechargement du réglage) ne remet pas le personnage à l'échelle si `capsule_height` change.
- **La copie dans le checkout principal n'a pas été faite.** Sur `main`, `assets/mixamo/` n'est pas encore ignoré : la ligne `.gitignore` n'existe que sur ma branche. Y copier 1 Go de fichiers Mixamo les aurait laissés non suivis mais visibles dans `git status`, à un `git add -A` d'un dépôt public. J'ai voulu ajouter `/assets/mixamo/` à `.git/info/exclude`, mais l'action a été refusée par le système de permissions. À faire une fois la branche mergée, depuis `C:\Users\jimmy\Documents\parkour` : `just mixamo "C:\Users\jimmy\Documents\mixamo"`, puis un démarrage de Godot pour l'import (environ 1 min 30). Ensuite, comme tu l'as noté, `just build` dans ce checkout inclura les fichiers dans le build (+88 MiB environ).
- **Le build exporté :** il démarre en headless avec les fichiers, mais je n'ai pas vérifié qu'il affiche le personnage (le build ne lance que l'écran de départ).

## Écarts

1. **Décision 6, translation racine.** La translation horizontale des hanches est retirée partout. La translation verticale n'est retirée que là où elle est un déplacement que le moteur fait déjà : Jump, Sprint To Wall Climb et Wall Run, dont les hanches restent à la hauteur d'un corps debout. Elle est gardée là où elle est une posture : slide, roulade, réceptions accroupies, Idle, course. Les retirer partout aurait fait flotter le slide et la roulade à 0,9 m. C'est la lecture la plus proche de « seul le moteur déplace le coureur ».
2. **Les parties des clips** (constantes `CUTS`, choisies d'après les données) :

   | Clip | Partie gardée | Pourquoi |
   | --- | --- | --- |
   | Falling To Roll | 0,3 à 1,1 s | la roulade |
   | Sprint To Wall Climb | 0,74 à 1,4 s | la partie où il se hisse |
   | Landing | 0,35 à 0,8 s | depuis le contact au sol |
   | Hard Landing | 0 à 0,5 s | l'impact |
   | Running Slide | 0,1 à 0,8 s | la glissade |
   | Jump | 0,05 à 0,42 s | la montée |
   | Wall Run | 0,05 à 0,6 s | avant que le corps pivote de 90° |

   Ces parties ne bouclent pas. Les clips des états à durée fixe (roulade, réception dure, mantle, Landing, wall-run) sont étirés pour tenir la durée de leur état dans le réglage. Les coupes sont des constantes de présentation liées aux fichiers, pas des valeurs de ressenti : elles ne sont pas dans la ressource de réglage.
3. **Valeurs de réglage ajoutées.** La spec n'en nommait qu'une : `animation_blend_time` = 0,1. J'en ai ajouté trois dans un groupe Animation, parce que toute valeur de ressenti doit vivre dans la ressource de réglage :
   - `animation_run_speed` = 6 m/s : la vitesse où Running joue à son propre rythme (le clip avance à 4,5 m/s ; à 9 m/s, il joue donc 1,5 fois plus vite) ;
   - `animation_still_speed` = 0,5 m/s : en dessous, Idle ;
   - `animation_landing_time` = 0,25 s.
4. **Moteur.** Le compteur privé `_steps_since_landing` devient la variable publique `steps_since_landing`. Ajouter une méthode publique dépassait la limite de 20 méthodes publiques de gdlint. `RunnerAnimation.of` reçoit donc la durée du pas fixe pour convertir.
5. **Tout ou rien.** Le personnage n'apparaît que si le personnage **et** les 12 clips sont présents. Sinon, c'est la capsule. La décision 2 ne parle que du personnage.
6. **Miroir.** Le clip Wall Run de Mixamo a son mur à **gauche** (vérifié sur les os). Il est donc joué en miroir le long d'un mur à droite. Le miroir est une échelle -1 en X sur le modèle.
7. **Haut du corps en visée.** En plus du filtre du Blend2 (la colonne vertébrale et ce qu'elle porte), un petit `SkeletonModifier3D` tourne la colonne pour compenser la rotation des hanches des jambes. Sans lui, le buste pointait 40 à 50° à côté en Idle. C'est une lecture de « le haut du corps tient la pose de visée ».
8. **Teinte.** Le bot reçoit un overlay orange à 50 %, qui garde les textures. Le fantôme porte le matériau orange transparent de sa capsule, qui remplace les textures.
9. **Fichiers d'outillage.** `justfile` (recette `mixamo`) et `tools/mixamo.py` sont des fichiers d'owner. Je les ai ajoutés parce que la spec et ta consigne demandent `just mixamo`. Aucune recette de gate ni aucun outil de gate n'a changé.
10. **TDD.** Les six scénarios du choix d'animation ont été écrits ensemble, puis vus rouges ensemble (la classe n'existait pas), avant l'implémentation. Ce n'était pas un scénario à la fois.

## Questions

- Faut-il ajouter `/assets/mixamo/` à `.git/info/exclude` du dépôt local, ou attendre le merge, avant de copier les fichiers dans le checkout principal ? Je n'ai pas pu le faire moi-même.
- Avec les fichiers, le build grossit d'environ 88 MiB (textures du personnage). C'est voulu d'après toi : reste à décider si un build de release doit contenir Mixamo (la FAQ le permet dans un jeu).
- `animation_run_speed` = 6 m/s et `animation_landing_time` = 0,25 s sont des valeurs de départ, à régler par Jimmy en jouant.

`````

### Inspecteur, personnage

`````markdown
# Inspection : character-animations (main 5974871..character-animations e1a69fb)

Spec : docs/specs/character-animations.md. Types de tâche : core, player, levels, assets, tooling, harness.

## Verdict : Conforme

Aucun constat bloquant. Huit constats conseillés ci-dessous. Les deux premiers demandent une décision du propriétaire.

### Vérifications prioritaires (toutes passées)

- **Rien de Mixamo n'est suivi.** `git ls-files` ne contient aucun `.fbx` ni rien sous `assets/mixamo/`. `git status --short --ignored` dans le worktree avec les fichiers : seuls `.godot/`, `.venv/`, `assets/mixamo/` et `build/` sont ignorés, l'arbre est propre. `git add -A --dry-run` n'ajoute rien. Les fichiers que Godot écrit à côté (`*.fbx.import`, `ch08_nonpbr_0..9.png` et leurs `.import`) restent tous dans `assets/mixamo/`. L'uid est dans le `.import`, il n'y a pas de `.uid`.
- **Chemin CI (clone frais sans les fichiers, dans le scratchpad)** : `just import`, `just typecheck` (108 scripts, 0 erreur), `just lint`, `just deadcode` (0 problème) et `just test` (360/360) passent. Le tier edit-loop passe aussi (278/278, 17,8 s).
- **Avec les fichiers (worktree)** : `just typecheck`, `just lint`, `just deadcode` et `just test` (360/360, 63 s ; 57 s de temps GUT) passent, sans erreur Godot dans le journal. Le tier edit-loop prend 19,2 s.
- **Ce que j'ai mesuré avec les fichiers** (script headless dans le scratchpad, rien de modifié) :
  - `Visual` a 3 enfants : Body et Visor cachés, plus le personnage.
  - La boîte du maillage va de 0,00 à 1,80 m.
  - Les 65 os sont préfixés `mixamorig7_`. Toutes les pistes des 12 clips visent un os du squelette (aucune inconnue).
  - Dans tous les clips construits, les hanches ont x et z constants : le mouvement racine horizontal est retiré.
  - Les fichiers d'animation importés n'ont aucun maillage (décision 3).

## Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
|---|---------|---------------|-------|---------|-------------|
| 1 | conseillé | game/player/runner_character.gd:48-55, 339 | Spec, décision 6 (« toute translation de l'os racine est retirée ») | Seule la translation horizontale des hanches est retirée. Leur hauteur est gardée (roulade 0,12 à 0,64 m, slide 0,23 à 0,87 m, Hard Landing 0,51 à 0,89 m), sauf pour Jump, Wall Run et Sprint To Wall Climb, ramenés à la hauteur de repos. Le code s'écarte donc du texte de la spec, et la spec n'a pas été amendée. Sur le fond, je juge le choix juste : c'est une posture, pas un déplacement. Le moteur ne bouge pas verticalement pendant un slide ou une roulade, et retirer cette hauteur ferait passer les jambes sous le sol. | Amender la décision 6 (« translation horizontale retirée ; hauteur des hanches gardée pour les postures, remise au repos pour Jump, Wall Run, Sprint To Wall Climb »), avec l'accord de Jimmy. |
| 2 | conseillé | README.md:290 | AGENTS.md, « Out of scope » (« Anything from a later roadmap step while an earlier one is not validated ») | Ce travail ouvre l'étape 6 avant l'étape 5, et les étapes 2 à 4 ne sont pas validées. La décision de Jimmy est écrite dans la spec, mais la feuille de route dit toujours « 6 … not started ». | Mettre à jour la ligne 6 de la feuille de route : « started : the animated character (docs/specs/character-animations.md), ahead of step 5 by the owner's decision ». |
| 3 | conseillé | tests/test_mixamo_files.gd:37, 73-74 | Spec, scénario « La commande de copie range les fichiers utilisés » (« et rien d'autre du pack ») | Dans le zip de test, le contenu de chaque membre est son propre nom, donc identique au `Ch08_nonPBR.fbx` téléchargé. J'ai ajouté `"Ch08_nonPBR.fbx": "ch08_nonpbr.fbx"` à `PACK_CLIPS` (le personnage du pack écrase alors celui téléchargé) : le test passe encore. Le vrai zip contient bien un `Ch08_nonPBR.fbx` différent d'un octet. | Écrire `"pack:" + clip` comme contenu des membres du zip, et attendre ce préfixe pour `pistol_idle.fbx`. |
| 4 | conseillé | tests/test_runner_animation.gd:63 ; tests/test_ghost_run.gd:35 | AGENTS.md, « Contributing workflow » (un test par scénario) ; procédure d'inspection (un test sans scénario) | `test_abrupt_entries_have_no_blend` (décision 7) et `test_the_ghost_replays_the_animation_recorded_with_each_frame` (décision 9) n'ont pas de scénario. | Ajouter ces deux scénarios à la spec. |
| 5 | conseillé | game/core/runner_motor.gd:51 | AGENTS.md, « Contributing workflow » (« fix the code », ne pas contourner un gate) | Le compteur privé `_steps_since_landing` devient public pour ne pas créer une 21e méthode publique (limite `max-public-methods`). Il existe un précédent, `trick_ready`, mais celui-ci est recalculé à chaque pas. `steps_since_landing` est un état persistant qui décide d'une règle, la fenêtre du slide parfait (ligne 428) : n'importe quelle couche peut maintenant le modifier, et le commentaire « Only the motor changes it » ne l'empêche pas. | Acceptable par précédent ; le dire dans la PR. La prochaine fois que la limite bloque, préférer une vue en lecture seule du moteur, ou un choix d'animation en core qui compte lui-même ses pas. |
| 6 | conseillé | game/player/runner_character.gd:60-62 ; README.md:58 | Spec, décision 10 (« le README liste exactement les fichiers … leurs réglages ») | Les noms d'os sont figés avec le préfixe `mixamorig7_`, que Mixamo donne au personnage Ch08. Le README ne dit pas que le pack pistolet doit être téléchargé avec Ch08 sélectionné. Avec un autre personnage, le préfixe change : `find_bone` renvoie -1, la visée ne fait rien et sans message clair. | README : « the pack, downloaded with Ch08_nonPBR selected ». Dans `create()`, renvoyer null (la capsule) si `HIPS` est absent du squelette. |
| 7 | conseillé | justfile:69 | AGENTS.md, « Working rules » (les outils sous cmd.exe et sh) | Testé : sous cmd.exe, si le dossier passé entre guillemets finit par une barre oblique inverse (`C:\no such\folder\`), la barre et le guillemet fermant forment un guillemet échappé : l'argument reçu est `C:\no such\folder` suivi d'un guillemet. La commande échoue sans rien copier, mais la liste « missing » qu'elle affiche est trompeuse. Sous sh, la commande marche. | Dans tools/mixamo.py, retirer un guillemet final de l'argument, ou une note dans le README (« sans barre oblique finale »). |
| 8 | conseillé | game/core/ghost_run.gd:30-31 | Procédure (option non demandée) | La valeur par défaut `animation = RunnerAnimation.new()` ne sert qu'aux anciens tests. Un futur appelant qui l'oublierait enregistrerait Idle sans que rien ne le signale. | Rendre le paramètre obligatoire et passer l'animation dans les appels de test. |

### Points demandés, jugés conformes

- **Choix d'animation** : `RunnerAnimation.of` (game/core/runner_animation.gd) est une fonction pure de core qui ne fait que lire le moteur. L'affichage est dans `game/player/runner_character.gd`. La présentation ne fait aucun appel en retour vers core, et `play()` est appelé au pas fixe (`_physics_process`).
- **Observations** : aucune fonction `_observe*` n'est touchée. Le personnage n'a pas de corps physique. `root_motion_track` n'est pas utilisé, donc l'AnimationTree ne déplace jamais le coureur. `visual_transform()` est inchangé.
- **tools/mixamo.py** :
  - bibliothèque standard seule ;
  - testé sous cmd.exe et sous sh ;
  - écrit seulement dans `assets/mixamo/` (l'option `--into` sert au test) ;
  - n'extrait que `pistol idle.fbx` du zip, avec des noms de destination fixes, donc pas de « zip slip » ;
  - n'écrit rien si un fichier manque.
- **README** : la liste des téléchargements correspond exactement à `CHARACTER`, `ANIMATIONS` et `PACK` du script et à `CLIP_FILES` du jeu. Le dossier de téléchargement réel contient bien ces noms, et `pistol idle.fbx` est dans le zip.
- **assets/CREDITS.md** : il y a une ligne par fichier présent (fbx, textures `ch08_nonpbr_*.png`, `pistol_idle.fbx`), avec la source, l'auteur et les conditions de la FAQ. Ces conditions sont celles que cite la spec.
- **Réglages** : les quatre valeurs `animation_*` sont dans `movement_tuning.tres` et dans `MotorBody.fixed_tuning()`. Les découpes de clips (`CUTS`) et `TINT_SHARE` restent dans le code. Ce sont des données des fichiers Mixamo et de présentation, pas du ressenti : je ne le relève pas.

## Couverture de la spec

Les cassures volontaires ont été faites sur un clone dans le scratchpad. Le test a échoué à chaque fois, sauf dans le cas du constat 3.

| Scénario | Test | Cassure volontaire |
|----------|------|--------------------|
| Chaque état du coureur a son animation | tests/test_runner_animation.gd `test_every_state_of_the_runner_has_its_animation` | slide → RUNNING : rouge |
| La course suit la vitesse | `test_the_run_follows_the_speed` | vitesse fixée à 1 : rouge |
| Le wall-run de l'autre côté est en miroir | `test_the_wall_run_on_the_other_side_is_mirrored` | miroir toujours faux : rouge |
| Une figure prend la pose groupée | `test_a_trick_takes_the_tuck_pose` | TUCK retiré : rouge |
| La visée prend le haut du corps | `test_aiming_takes_the_upper_body` | aiming toujours faux : rouge |
| Un atterrissage simple joue Landing brièvement | `test_a_simple_landing_plays_landing_briefly` | Landing retiré : rouge |
| Sans les fichiers, la capsule reste | tests/test_player.gd `test_without_the_files_the_capsule_stays` | Body caché (joueur), Visor caché (fantôme) : rouge |
| Les fichiers Mixamo ne sont jamais suivis par Git | tests/test_mixamo_files.gd `test_mixamo_files_are_never_tracked_by_git` | ligne `.gitignore` retirée : rouge |
| La commande de copie range les fichiers utilisés | `test_the_copy_command_puts_away_the_used_files` | clip du pack en trop, animation en trop : rouge ; personnage du pack copié par-dessus celui téléchargé : **vert** (constat 3) |

En plus, la cassure « réception dure avec fondu » fait échouer `test_abrupt_entries_have_no_blend`, un test sans scénario (constat 4).

## Non vérifiable ici (Jimmy, manette en main)

- **Taille et appuis** : le personnage mesure 1,8 m, pieds au sol, à l'arrêt comme en course. En slide et en roulade, il faut voir si la descente des hanches colle à la capsule basse (constat 1), et s'il y a un saut de hauteur au passage Running → Jump ou Wall Run (hanches remises à 0,98 m contre environ 0,93 m en course).
- **Running** : le cycle joue 1,5 fois plus vite à la vitesse de pointe (9 m/s), et environ 2 fois avec le bonus de flow (12,3 m/s). Il faut voir si les pieds glissent. Le réglage est `animation_run_speed`.
- **Landing** (0,25 s) suit chaque petite chute, y compris chaque saut à plat. Sur les enchaînements du Trick Park, cela peut donner un accroc.
- **Fondus** de 0,1 s ; réception dure et crash sans fondu.
- **Pose groupée** pendant les saltos, vrilles et spins, puis le dépliage en Falling Idle.
- **Côté du miroir** : le code suppose que le clip Wall Run de Mixamo a le mur à gauche. Aucun test ne fixe le côté. Si l'hypothèse est fausse, chaque wall-run est montré du mauvais côté.
- **Clips étirés** : Wall Run (0,55 s) est étiré sur 1,2 s puis tient sa dernière pose. Le mantle (0,66 s) est joué en 0,35 s, et la roulade (0,8 s) en 0,5 s.
- **Visée** : le haut du corps prend Pistol Idle par-dessus la course, en clavier-souris comme à la manette. Il n'y a pas encore de modèle d'arme.
- **Adversaires** : le bot avec sa surcouche orange à 50 %, et le fantôme orange transparent sur un maillage à cheveux et cils (ordre de tri du transparent).
- **Performance et build** : la fréquence d'images avec deux personnages skinnés et des textures de 14 à 23 Mo. `just build` et `just check` n'ont pas été lancés avec les fichiers présents (le build les embarque, `export_filter="all_resources"`). Il reste à vérifier la limite de 90 s et la taille du build sur cette machine.
- **Premier import** : environ 1 min 30 après `just mixamo`.

`````

### Développeur, pose du wall-run

`````markdown
# Rapport développeur : décision 12, la pose du wall-run

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a564abb76c3464488`
Branche : `wall-run-pose` (partie de `main` à `503b9d7`), non poussée.
Commits : `ad7397d` (implémentation), `812627a` (statut de la spec, `🟢 Implémenté`).

## Fait

- **Scénario « En wall-run, les pieds sont au mur et la tête s'en écarte »** :
  `test_in_a_wall_run_the_feet_are_at_the_wall_and_the_head_moves_away`, dans
  `tests/test_player_walls.gd`. Le test a deux parties :
  1. **Toujours, avec ou sans les fichiers** : la règle pure sur deux clips inventés
     (positions latérales des os données en entrée : pieds à gauche et tête à droite,
     puis le miroir). Il vérifie que `WallRunPose.measure` trouve le mur du côté des
     pieds, la portée et un décalage par image. Ensuite, pour un mur à gauche et à
     droite, à 0, 0,30 et 0,60 m : miroir choisi, décalage `offset`, os le plus proche
     exactement à `WALL_GAP` (5 cm), aucun derrière, tête plus loin que les pieds.
  2. **En vraie physique**, six coureurs (mur à gauche et à droite, à 0, 0,30 et 0,54 m)
     lancés en wall-run. **Avec les fichiers** : à chaque pose finale du squelette
     (signal `skeleton_updated`), le test mesure les 65 os contre la face du mur : aucun
     os derrière (pendant tout le wall-run, fondu compris), pieds à moins de 10 cm, tête
     toujours plus loin que le pied le plus proche, et aucune inclinaison de `Visual`.
     **Sans les fichiers** (CI) : la capsule s'incline de `wall_run_lean` et ne bouge
     pas en travers. Ce n'est pas un saut silencieux : chaque branche affirme quelque
     chose.
- **La mesure est dans le code** : `game/player/wall_run_pose.gd` (nouveau, pur, ne lit
  aucun fichier). `RunnerCharacter._lay_against_the_wall` fait la cinématique directe
  du clip `Wall Run` gardé, à chaque clé, et en tire le côté du mur, la portée et le
  décalage des hanches par clé, qui est inscrit dans le clip. Un autre clip serait
  mesuré de la même façon.
- `RunnerAnimation.mirrored` devient `wall_side` (`WallSide.NONE/LEFT/RIGHT`, un fait du
  moteur). Le miroir est choisi dans `game/player` (`WallRunPose.mirrors`). Le scénario
  « Le wall-run de l'autre côté est en miroir » (`test_the_wall_run_on_the_other_side_is_mirrored`)
  vérifie maintenant les deux côtés du mur, et le miroir pour un clip qui aurait son mur
  à gauche comme à droite.
- `Player` : `wall_run_lean` n'est plus appliqué quand le personnage est affiché.
  L'origine de `Visual` est décalée en travers selon `capsule_radius`, la distance au
  mur observée à ce pas (bornée à `wall_run_distance`) et la portée mesurée. Le fantôme
  rejoue donc la pose sans rien de plus.
- Tests adaptés, sans les affaiblir :
  - `test_course_walls.gd` attend l'inclinaison réglée avec la capsule, et 0 avec le
    personnage.
  - `test_player.gd` utilise `RunnerCharacter.RIG` : `fits` exige maintenant aussi la
    tête et les pieds.
- `AGENTS.md`, Layout, ligne `player/` : complétée.

## Vérifié

- Mesure du clip `Wall Run` (partie gardée, 0,05 à 0,6 s, sur place), côté latéral
  dans le repère du coureur : les pieds sont à gauche (pied gauche de -0,11 à -0,44 m,
  orteil jusqu'à -0,67 m), la tête est à droite (+0,04 à +0,27 m). **Le mur est à
  gauche** : la supposition d'avant sur le côté était juste. La tête entrait dans le mur
  parce que l'inclinaison de 20° de la capsule s'ajoutait à celle du clip, et parce que
  le personnage n'était pas décalé : les orteils vont à 0,66 m de l'axe, le mur est
  entre 0,35 et 0,95 m.
- Mesure retenue : côté `LEFT`, portée 0,659 (unités du clip, ×1,011), décalage des
  hanches de 0 à 0,355 m selon l'image. Décalage du personnage : -0,37 m à 0 m du mur,
  -0,07 m à 0,30 m, +0,17 m à 0,54 m.
- Mesures des os en local (16 à 17 poses par coureur), **identiques des deux côtés et
  aux trois distances** :
  - tête à 0,72 m du mur en moyenne ;
  - hanches à 0,57 m ;
  - pied le plus proche à 0,057 m en moyenne, 0,048 m au plus près ;
  - os le plus proche à 0,048 m au plus près, aucun derrière la surface.
- Avec la visée tenue (essai temporaire, retiré) : tête à 0,59 m, aucun os derrière.
- `just preflight` (fichiers présents) : vert, 281 tests, 36 s.
- `just test` sans les fichiers (`assets/mixamo` sorti du worktree) : vert, 363 tests.
- `just check` (fichiers présents) : vert. typecheck 109 scripts, lint, 363 tests,
  deadcode 0 problème. Builds Windows et Linux exportés, Windows lancé 60 images sans
  écran. 93 s au total, dont un ré-import Godot après la remise des fichiers.

## Non vérifié

- Le rendu à l'écran avec la manette en main, pour Jimmy :
  - le corps qui se balance en travers jusqu'à 35 cm pendant le clip, pour garder un
    pied au mur ;
  - le personnage dessiné jusqu'à 37 cm à côté de la capsule (et de la caméra) quand le
    coureur colle au mur ;
  - le saut du décalage à l'entrée et à la sortie du wall-run : il s'applique d'un coup,
    seul le clip fait son fondu de 0,1 s.
- La sortie du wall-run n'est pas couverte par la règle : pendant le fondu de 0,1 s
  hors du clip, le décalage est déjà revenu à 0, et des pieds peuvent passer brièvement
  dans le mur si le coureur reste collé.
- La CI n'a pas les fichiers : la partie « os » du test n'y tourne pas, seules la règle
  pure et le chemin capsule y tournent.

## Écarts

- **Le miroir sort du cœur** : `RunnerAnimation` dit le côté du mur (`wall_side`), et
  `game/player` choisit le miroir d'après la mesure. La décision 8 met le miroir dans la
  fonction pure ; le choix reste pur et testé sans fichiers (`WallRunPose.mirrors`),
  mais il vit dans la couche player, parce que la mesure du clip n'existe que là.
- **« Pieds à quelques centimètres »** : lu comme l'os le plus proche du mur tenu à
  5 cm à chaque clé (`WallRunPose.WALL_GAP`, une constante de présentation, pas une
  valeur de la ressource de réglage). Il en résulte un balancement latéral du corps :
  la décision 6 retire la translation horizontale, la décision 12 l'autorise (« décalé
  latéralement si besoin »).
- `fits` exige maintenant `Head`, `LeftFoot` et `RightFoot` en plus des trois os
  d'avant.
- Le test sans fichiers utilise un mur à 0,54 m plutôt que 0,60 m : à 0,60 m tout
  juste, aucun wall-run ne démarre (limite de `wall_run_distance`).

## Questions

- Jimmy doit juger le balancement latéral et le décalage personnage/capsule. S'il gêne,
  on pourrait garder un décalage fixe (pieds au mur seulement au plus loin du clip), ou
  lisser l'entrée et la sortie.
- Le temps de `just check` (93 s) dépasse de peu la limite de 90 s, mais il comprenait
  un ré-import ; à remesurer sur un import chaud.

`````

### Développeur, locomotion

`````markdown
# Rapport du développeur : locomotion-blend

Spec : `docs/specs/locomotion-blend.md`. Routage : `core` (runner_animation, tuning), `player` (runner_character, stride, wall_run_pose, player, ghost), `assets` (CREDITS), `tooling` (`tools/mixamo.py`), `harness` (README, AGENTS.md, statut de la spec).

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-abcd8d60f510c8436`, branche `locomotion-blend`, partie de `main` à `4ea181d`. Rien n'est poussé.

- `f7f418a` locomotion-blend: blend space, blend times per pair, strides in phase (code, tests, tuning, `tools/mixamo.py`, README, CREDITS)
- `17c9401` AGENTS.md: layout lines for the locomotion blend (uniquement les lignes de Layout)
- `5effd42` spec: locomotion-blend implemented (statut 🟢, seul)

## Fait

Chaque scénario a un test du même nom :

| Scénario | Test | Fichier |
| --- | --- | --- |
| Les poids du blend space suivent la vitesse | `test_the_blend_space_weights_follow_the_speed` | `tests/test_runner_locomotion.gd` |
| Les poids font toujours un tout | `test_the_weights_always_make_a_whole` | `tests/test_runner_locomotion.gd` |
| Les clips mélangés gardent la même phase | `test_the_blended_clips_keep_the_same_phase` | `tests/test_runner_locomotion.gd` |
| Chaque enchaînement a son temps de fondu | `test_each_transition_has_its_blend_time` | `tests/test_runner_locomotion.gd` |
| Une entrée brusque reste sans fondu | `test_an_abrupt_entry_stays_without_a_blend` | `tests/test_runner_locomotion.gd` |
| La course reprend à la bonne foulée | `test_the_run_resumes_at_the_right_stride` | `tests/test_runner_locomotion.gd` |
| La copie range aussi la marche et le sprint | `test_the_copy_also_puts_away_the_walk_and_the_sprint` | `tests/test_mixamo_files.gd` |

Les tests 3 et 6 vérifient d'abord la règle sur des mesures inventées, toujours, puis l'arbre réel du personnage quand les fichiers sont là. Sans les fichiers, ils s'arrêtent avec `pass_test` après la règle.

Le défaut de sortie du wall-run relevé par l'inspecteur est corrigé, et une assertion est ajoutée à `test_in_a_wall_run_the_feet_are_at_the_wall_and_the_head_moves_away` (`tests/test_player_walls.gd`). Elle porte sur deux choses :

- la règle, sur le clip inventé mélangé avec une chute inventée : à chaque part du fondu, à l'entrée comme à la sortie, aucun os n'est derrière le mur ;
- avec les fichiers : pendant le fondu de sortie, aucun os ne va plus loin derrière le mur que la chute qui suit ne va d'elle-même.

Ce qui a été construit :

- **`game/core/runner_animation.gd`** :
  - deux clips en plus, `WALKING` et `SPRINT`, et `LOCOMOTION` (Idle, Walking, Running, Sprint) ;
  - les poids `locomotion` ;
  - les fonctions pures `locomotion_weights`, `own_speed`, `stride_speeds` et `blend_time_between` ;
  - `of(motor, step, before)` reçoit maintenant l'animation du pas d'avant, pour lire la table.
  - Au sol, `clip` vaut `IDLE` (Idle seul) ou `RUNNING` (la locomotion).
- **`game/core/movement_tuning.gd` et `.tres`**, groupe Animation :
  - `animation_blend_times` : la table « de>vers », avec `*` pour « n'importe quel clip », et les valeurs de départ de la décision 3 ;
  - `animation_walk_speed` 1,49, `animation_run_speed` 4,49 (6,0 avant) et `animation_sprint_speed` 5,65 m/s ;
  - `animation_blend_time` reste la valeur par défaut.
- **`game/player/stride.gd`** (nouveau, pur) :
  - `touchdown` : le contact du pied gauche ;
  - `cycles_per_second` : le nombre de foulées par seconde qui empêche le pied de glisser ;
  - `nearest_phase` : la phase de reprise.
- **`game/player/runner_character.gd`** :
  - un état « locomotion » dans la Transition : un Blend2 qui mélange Idle avec un BlendSpace1D (Walking, Running, Sprint) ;
  - chaque clip qui fait des foulées est sur une timeline de 1 s étirée, qui commence au contact de son pied gauche (synchro INDEPENDENT) ;
  - un TimeSeek sert à la reprise, un TimeScale règle les foulées par seconde ;
  - une échelle de vitesse (pace) par clip pour les autres états ;
  - un modificateur de squelette `WallLean` déplace le corps vers le mur au rythme réel du fondu de l'arbre ;
  - `create(model, tuning)` remplace `create(model, height)`.
- **`game/player/wall_run_pose.gd`** : `shift_share`, la part du décalage selon le fondu.
- **`game/player/player.gd`** :
  - le décalage contre le mur passe au personnage (`lean_on_the_wall`) ;
  - `visual_transform()` inclut ce décalage, pour que le fantôme reste collé au mur.
- **`tools/mixamo.py`** copie `Walking.fbx` et `Sprint.fbx`. README : les deux téléchargements et le blend. CREDITS : une ligne pour `walking.fbx` et `sprint.fbx`.

## Vérifié

Les fichiers ont été copiés par `just mixamo "C:/Users/jimmy/Documents/mixamo"` : 15 fichiers copiés, import Godot sans erreur.

**Gates :**

- `just check`, avec les fichiers : vert. typecheck 111 scripts sans erreur, lint propre, 370 tests sur 370 passent, structure à 0 problème. Builds Windows (192 Mio) et Linux (158 Mio) ; l'exe Windows a joué 60 images en headless. Durée : **95,5 s**.
- `just preflight` : vert. 288 tests, **38,8 s** avec les fichiers, **35,7 s** sans.
- `just test` sans les fichiers (`assets/mixamo` déplacé puis remis) : 370 sur 370 passent, 63 s.

**Rouges vus avant le code :**

- La copie : `walking.fbx` et `sprint.fbx` n'étaient pas copiés, et la copie n'échouait pas sans eux.
- Les tests `core` : erreurs de parsing, l'API n'existait pas encore. Je n'ai pas vu de rouge sur le comportement lui-même.
- La phase 0 avec les fichiers : le pied gauche était à 0,17 m du sol pour Running et Sprint. Cela a révélé que `start_offset` s'exprime en unités de timeline, pas en secondes du clip ; c'est corrigé.
- Le fondu du wall-run : j'ai remis temporairement l'ancien saut du décalage (« tout pendant le wall-run, rien après »). Résultat : 0,25 m derrière le mur sur le clip inventé, à 0 m du mur, pendant la sortie. La règle a ensuite été restaurée.

**Glissement des pieds, mesuré sur l'arbre réel en avance manuelle** (script local, pas un test). Vitesse à laquelle le pied d'appui recule, comparée à la vitesse au sol :

| Vitesse au sol | Poids | Foulées/s | Recul du pied | Écart |
| --- | --- | --- | --- | --- |
| 1,40 m/s | Walk 0,91, Idle 0,09 | 0,81 | 1,46 m/s | +0,06 |
| 2,5 m/s | Walk 0,87, Run 0,13 | 1,30 | 2,34 m/s | −0,16 |
| 4,4 m/s | Walk 0,61, Run 0,39 | 1,93 | 4,17 m/s | −0,23 |
| 6,0 m/s | Walk 0,40, Run 0,60 | 2,32 | 5,97 m/s | −0,03 |
| 7,5 m/s | Walk 0,20, Run 0,80 | 2,62 | 7,54 m/s | +0,04 |
| 9,0 m/s | Run 1,00 | 2,86 | 8,99 m/s | −0,01 |
| 9,45 m/s | Run 0,67, Sprint 0,33 | 3,05 | 9,50 m/s | +0,05 |
| 9,9 m/s | Run 0,33, Sprint 0,67 | 3,24 | 9,90 m/s | 0,00 |
| 10,35 m/s | Sprint 1,00 | 3,43 | 10,34 m/s | −0,01 |
| 12 m/s | Sprint 1,00 | 3,98 | 11,99 m/s | −0,01 |

Le mélange marche-course perd jusqu'à 5 % (les positions des deux foulées ne se mélangent pas linéairement). Ailleurs, l'écart est d'au plus 0,06 m/s. Avant ce travail, à 9 m/s, Running jouait 1,5 fois plus vite que sa vitesse propre et le pied d'appui reculait à environ 6,7 m/s : il glissait.

**Phases :**

- Contact du pied gauche mesuré dans les données : Walking 0,331 s sur 1,167 s, Running 0,257 s sur 0,7 s, Sprint 0,169 s sur 0,533 s.
- À la phase 0 de chaque clip seul, joué dans l'arbre, le pied gauche est à 3 à 8 mm de son point le plus bas.
- Walking, Running et Sprint sont lus à la même position dans l'arbre (0,144, 0,144, 0,144).
- Reprise après une glissade : phase 0,717, et le plus proche calculé par le test est 0,717. Après une réception : 0,700 et 0,700.

**Wall-run, avec les fichiers.** Pendant le wall-run, aux trois distances et des deux côtés :

- aucun os derrière le mur : le plus proche est à 0,047 m ;
- pieds à 0,047 m du mur ;
- tête à 0,69 m en moyenne.

Pendant le fondu de sortie :

| Distance au mur | Os le plus proche pendant le fondu | Dans la chute qui suit, seule |
| --- | --- | --- |
| 0,30 m | +0,011 m | +0,019 m |
| 0,54 m | +0,131 m | +0,259 m |
| 0 m (capsule contre le mur) | −0,265 m | −0,281 m |

## Non vérifié

- **Le rendu à l'écran, manette en main** (Jimmy), sur clavier-souris et sur manette :
  - le passage d'Idle à la marche (à partir de 0,5 m/s) puis à la course, et le sprint au palier 3 du flow ;
  - la cadence : 2,86 foulées/s à 9 m/s (5,7 pas/s), 3,43 à 10,35 m/s (6,9 pas/s). C'est le prix de pieds qui ne glissent pas avec les foulées courtes de Mixamo (3,1 m par cycle de Running) ;
  - les reprises après une réception ou une glissade ;
  - les fondus de la table.
- **L'entrée en wall-run contre un mur que la capsule touche** : le corps s'écarte du mur d'un coup (jusqu'à 0,37 m), comme avant. Voir Écarts.
- **La fin du miroir** après un wall-run le long d'un mur à droite : il est retiré quand le fondu de sortie est fini, ce qui inverse gauche et droite de la pose de chute à cet instant (un à-coup possible).
- **Le fantôme et le bot avec le personnage dans un vrai duel** : couverts par les tests de parcours sans assertion visuelle.
- **Le timing de `just check` sur la machine de Jimmy** : mesuré à 95,5 s ici avec les fichiers (avec les 88 Mo du personnage dans les builds). Cela dépasse la limite de 90 s. Je n'ai pas mesuré `main` avec les fichiers pour comparer.

## Écarts

1. **Points du blend space.** La décision 1 dit « placés chacun à la vitesse propre de son clip », mais elle met Running à la vitesse de pointe et Sprint à la pointe du palier 3. Le scénario exige aussi Running seul à la vitesse de pointe. Or la foulée propre de Running, mesurée, est de 4,49 m/s, pas 9. J'ai donc lu la décision ainsi :
   - Idle seul jusqu'à `animation_still_speed` (0,5 m/s), puis mélange vers Walking ;
   - Walking à sa vitesse propre (1,49 m/s) ;
   - Running à `top_speed` ;
   - Sprint à `top_speed × (1 + bonus du dernier palier)` ;
   - la vitesse de lecture vient des vitesses propres mesurées, rangées dans le réglage (`animation_*_speed`).

   Le point d'Idle n'est donc pas 0, mais Idle est bien seul à l'arrêt.
2. **Vitesses propres mesurées hors du jeu, écrites dans le `.tres`.** Ce sont les vitesses de recul du pied d'appui, mesurées par script sur l'arbre. `animation_run_speed` passe de 6,0 (choix accepté de la spec précédente) à 4,49. Le contact du pied gauche et le cycle de poses, eux, sont mesurés dans le code au chargement, comme pour la pose du wall-run.
3. **Test existant modifié.** Dans `test_the_run_follows_the_speed`, l'assertion « in proportion to the speed » (moitié de vitesse, moitié de lecture) devient « in step with the ground » : vitesse divisée par la vitesse propre pondérée du mélange. La décision 1 remplace la règle proportionnelle. Les autres assertions de ce test restent.
4. **Fondu du décalage de wall-run.** Le décalage vers le mur suit le fondu réel du clip, à l'entrée comme à la sortie. Un décalage qui éloigne du mur, en revanche, s'applique d'un coup à l'entrée et ne s'estompe qu'à la sortie. Sans cela, l'assertion existante « aucun os derrière le mur » pendant le wall-run échoue à 0 m du mur : les bras de Falling Idle passent déjà à 0,25-0,28 m derrière un mur que la capsule touche, avant tout wall-run. Pour la sortie, l'assertion ajoutée se mesure par rapport à cette chute seule, pas en absolu. Le fait que Falling Idle traverse un mur collé n'est pas traité ; c'est un défaut antérieur.
5. **Le miroir est tenu jusqu'à la fin du fondu de sortie.** Avant, il sautait à la sortie, ce qui retournait la pose du wall-run vers le mur.
6. **`tools/mixamo.py` est un fichier de `tools/`.** Le harnais le réserve aux owners, mais la décision 5 et la consigne de la session principale demandent de l'étendre. Ce n'est pas une porte.
7. **Le fantôme.** Le décalage contre le mur vit maintenant dans le squelette du coureur ; `visual_transform()` l'ajoute à la trame enregistrée, pour que le fantôme garde son corps contre le mur.
8. **Table des fondus.**
   - Ordre de recherche : la paire exacte, puis `*>vers`, puis `de>*`, puis la valeur par défaut.
   - Un clip vers lui-même prend la valeur par défaut.
   - Idle, Walking et Sprint comptent comme « running ».
   - La réception dure n'a jamais de fondu, quoi que dise la table : c'est codé, pas réglable.
9. **Deux faits Godot 4.7 lus dans la documentation officielle (XML de la 4.7-stable), puis vérifiés :**
   - `start_offset` d'une timeline étirée s'exprime en unités de timeline ;
   - les modes `SYNC_MODE_CYCLIC_*` n'ont pas été retenus, car la doc dit qu'un TimeSeek casse leur synchro.

## Questions

- La limite de 90 s de `just check` est dépassée de 5,5 s ici avec les fichiers Mixamo, qui ajoutent les builds avec le personnage et la construction de la bibliothèque dans les tests. Sans les fichiers (le cas de la CI), le preflight prend 35,7 s. Faut-il mesurer `main` avec les fichiers pour savoir si ce dépassement vient de ce travail ?
- La cadence haute à vitesse de pointe est le prix de pieds qui ne glissent pas. Si Jimmy la trouve trop rapide, il y a deux leviers, tous deux à sa décision :
  - laisser un peu de glissement, avec des vitesses propres réglées plus haut ;
  - prendre des clips de course aux foulées plus longues.

`````

### Inspecteur, locomotion

`````markdown
# Inspection : branche `locomotion-blend` (`main` 4ea181d..5effd42)

Contrôlée par rapport à : `docs/specs/locomotion-blend.md`, `docs/specs/character-animations.md` (décision 12 et choix acceptés), `AGENTS.md`.
Types de tâche concernés : core, player, assets (CREDITS), tooling (`tools/mixamo.py`), harness (`AGENTS.md`, `README.md`, spec).

## Verdict : Conforme

Aucun constat bloquant. Cinq constats conseillés, tous sur des tests qui pourraient prouver davantage ou sur un glissement des pieds que la spec n'exige pas explicitement par un scénario.

### Vérifications préalables (commandes lancées)

- **Fichiers Mixamo** : `git ls-files` ne suit aucun fichier `.fbx`, `ch08`, `.import` ni sidecar Mixamo. `assets/mixamo/` est ignoré (`.gitignore`), et `git add -A --dry-run` dans le worktree ne renvoie rien. Aucun commit de la plage n'ajoute de fichier sous `assets/` hormis `CREDITS.md`.
- **Avec les fichiers** (worktree) : `just typecheck` donne 111 scripts, 0 erreur. `just lint` ne trouve aucun problème. `just deadcode` donne 0 problème sur les 4 axes. `just test` passe 370/370 (12258 asserts, 61 s).
- **Sans les fichiers** (chemin de la CI : clone de la branche dans le scratchpad, sans `assets/mixamo/`, puis import Godot) : typecheck 0 erreur, structure 0 problème, tests 370/370 (12220 asserts). La tranche du cycle d'édition prend environ 16 s avec ou sans les fichiers.
- **`tools/mixamo.py`** : il n'importe que la bibliothèque standard (`filecmp`, `shutil`, `sys`, `zipfile`, `pathlib`, `typing`). Le diff se limite à deux entrées du dictionnaire. La recette `just mixamo` n'a pas changé et le test cmd.exe (barre oblique inverse finale) passe.
- **Tuning** : la table de la ressource (`movement_tuning.tres:133-144`) contient exactement les 10 valeurs de départ de la décision 3, plus le défaut à 0,1 s. Chaque clé correspond à un nom de clip réel.
- **Pas de garde-fou relâché** : aucun changement dans `.gutconfig.json`, `project.godot`, `tools/check_structure.py` ou la CI. Aucun test sauté. Dans `test_runner_animation.gd:112-115`, une assertion est remplacée (« in proportion to the speed » devient « in step with the ground »). C'est la règle nouvelle de la décision 1 et le scénario de l'ancienne spec (plus lent à mi-vitesse) reste asserté.
- **Rechargement du tuning à chaud** : `CACHE_MODE_REPLACE` rend le même objet (vérifié par sonde). Le `_tuning` gardé par `RunnerCharacter` suit donc les modifications.

### Cassures délibérées (sur une copie hors dépôt)

| Cassure | Sans fichiers | Avec fichiers |
| ------- | ------------- | ------------- |
| Poids inversés dans un intervalle | échoue (scénario 1) | n/a |
| Un troisième poids non nul | échoue (scénario 2) | n/a |
| Table des fondus ignorée | échoue (scénario 4) | n/a |
| Réception dure avec fondu | échoue (scénario 5) | n/a |
| Fondu calculé sans le clip d'avant | échoue (scénario 4) | n/a |
| `Stride.touchdown` qui rend 0 | échoue (scénario 3) | n/a |
| `cycles_per_second` qui ignore les longueurs | échoue (scénario 3) | n/a |
| `nearest_phase` sans mise à l'échelle, ou qui rend 0 | échoue (scénario 6) | n/a |
| Allure à l'ancienne (`/ animation_run_speed`) | échoue (`test_the_run_follows_the_speed`) | n/a |
| `start_offset` à 0 (phases non calées sur le contact du pied) | rien à vérifier | échoue (pied gauche 3 à 27 cm au-dessus du sol à la phase 0) |
| Sprint sorti de la timeline commune (désynchronisé) | rien à vérifier | échoue (phases 0,13 contre 0,06) |
| Reprise à la phase 0, ou sans reprise | rien à vérifier | échoue (0,28 à 0,32 de cycle d'écart) |
| Décalage de mur qui saute à 0 hors wall-run (comportement de `main`) | échoue (os jusqu'à 17,5 cm derrière le mur) | échoue |
| Miroir défait dès la sortie du wall-run | n/a | échoue (os 4 cm plus loin derrière le mur que la chute) |
| `touchdown` qui prend la première période au sol au lieu de la plus longue | **passe** | **passe** |
| `shift_share` qui rend toujours 1 (le décalage ne revient jamais à 0) | **passe** | **passe** |
| Règle « s'écarter du mur tout de suite » retirée | **passe** | **passe** |

Les tests qui ne vérifient l'arbre réel « quand les fichiers sont là » vérifient d'abord la règle pure : sans les fichiers, ils assertent quelque chose de réel avant `pass_test`. Aucun ne saute en silence.

### Glissement des pieds, mesuré sur l'arbre réel

J'ai fait la mesure sur une copie avec les fichiers : `AnimationTree` en mode manuel, pas de 1/240 s pendant 3 s. Pour chaque pied, je prends son os le plus bas (cheville ou orteil) et je calcule sa vitesse vers l'arrière quand il est à moins de 2 cm de son point le plus bas. Le ratio idéal entre cette vitesse et la vitesse au sol vaut 1.

| Vitesse au sol | Mélange | Ratio pied G / pied D |
| -------------- | ------- | --------------------- |
| 0,80 m/s | Idle 0,70 + Walking 0,30 | 0,05 / 0,01 (le pied glisse d'environ 0,77 m/s) |
| 1,00 m/s | Idle 0,49 + Walking 0,51 | 0,26 / -0,04 |
| 1,49 m/s | Walking seul | 0,99 / 0,61 (il est possible que mon critère attrape le déroulé de l'orteil) |
| 2,50 m/s | Walking 0,87 + Running 0,13 | 0,91 / 0,98 |
| 4,49 m/s | Walking 0,60 + Running 0,40 | 0,93 / 0,98 |
| 7,00 m/s | Walking 0,27 + Running 0,73 | 0,96 / 1,03 |
| 9,00 m/s | Running seul (allure x2,0) | 0,96 / 1,04 |
| 9,70 m/s | Running + Sprint | 1,00 / 0,99 |
| 10,35 m/s | Sprint seul (allure x1,83) | 1,02 / 0,96 |

À partir de la marche, les vitesses de foulée mesurées par le développeur (1,49, 4,49 et 5,65 m/s) sont justes : en moyenne, les pieds restent à ±4 % du sol. Entre 0,5 et 1,49 m/s (le mélange Idle et Walking), en revanche, les pieds patinent nettement (constat 1).

## Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
| - | ------- | ------------- | ----- | ------- | ----------- |
| 1 | conseillé | `game/core/runner_animation.gd:190` (avec `own_speed`, l.137) | locomotion-blend, décision 1 : « Les clips mélangés jouent à une vitesse qui garde les pieds sans glisser » | Entre 0,5 et 1,49 m/s, Idle est mélangé à Walking, mais l'allure de Walking ignore le poids d'Idle. Le pied posé recule à 0,04 à 0,26 m/s pendant que le sol défile à 0,8 à 1 m/s : environ 0,75 m/s de patinage, mesuré sur l'arbre réel. | Faire juger cette plage par Jimmy (une manette poussée à moitié peut y rester). Si le glissement se voit, diviser l'allure par le poids des clips qui marchent (avec un plafond), ou commencer Walking plus près de 0. |
| 2 | conseillé | `tests/test_player_walls.gd:47` (`MADE_UP_FALL`) ; `game/player/wall_run_pose.gd:80-83` | `AGENTS.md`, « Contributing workflow » (une règle de présentation tient par un test) ; character-animations, décision 12 | Deux variantes de `shift_share` passent tous les tests, avec et sans les fichiers : retirer la règle « s'écarter du mur tout de suite pendant le wall-run », et rendre toujours 1 (le personnage resterait décalé pour toujours après un wall-run). La chute inventée ne touche jamais le mur, et aucun test ne vérifie que le décalage revient à 0. | Ajouter une chute inventée dont un os dépasse le mur à 0 m (par ex. `-0.4`), plus une assertion `shift_share(0.0, ..., false) == 0` (ou `wall_shift()` nul dans la chute, avec les fichiers). |
| 3 | conseillé | `game/core/movement_tuning.tres:145-147` ; `tests/test_runner_locomotion.gd:200` | locomotion-blend, décisions 1 et 6 (« l'AnimationTree est de la présentation, vérifiée localement avec les fichiers ») ; `AGENTS.md`, « Working rules » (« Never say "it works" without having run it ») | Les trois vitesses de foulée ont été mesurées à la main, et aucune mesure ne peut être rejouée depuis le dépôt. Les tests avec fichiers vérifient la phase et la reprise, pas que le pied posé suit le sol. Un nouveau téléchargement, ou une retouche du tuning (permise sans revue), ferait revenir le glissement sans qu'aucun test ne bouge. | Dans la partie avec fichiers de `test_the_blended_clips_keep_the_same_phase`, asserter qu'à la vitesse propre de Walking, Running et Sprint, le pied posé recule à ±10 % de la vitesse au sol (la mesure ci-dessus en donne la forme). |
| 4 | conseillé | `game/core/movement_tuning.tres:133-144` ; `game/core/runner_animation.gd:164` | `AGENTS.md`, « Contributing workflow » (un changement de tuning seul passe sans spec ni inspecteur) | Les clés de la table sont des chaînes libres. Une faute de frappe (`runing>jump`) retombe en silence sur le défaut. Les tests lisent la copie de la table dans `tests/motor_body.gd:90-101`, jamais la ressource que Jimmy retouchera. | Ajouter un test qui charge `movement_tuning.tres` et vérifie que chaque clé a la forme `de>vers`, chaque côté étant un nom de `RunnerAnimation.Clip` en minuscules ou `*`. |
| 5 | conseillé | `game/player/stride.gd:38` | locomotion-blend, scénario « Les clips mélangés gardent la même phase » | Remplacer « la plus longue période au sol » par « la première » passe les tests : chaque foulée inventée n'a qu'une période au sol. | Donner à l'une des foulées inventées un court contact parasite avant le vrai contact. |

## Couverture de la spec

| Scénario | Test |
| -------- | ---- |
| Les poids du blend space suivent la vitesse | `tests/test_runner_locomotion.gd` : `test_the_blend_space_weights_follow_the_speed` |
| Les poids font toujours un tout | `test_the_weights_always_make_a_whole` |
| Les clips mélangés gardent la même phase | `test_the_blended_clips_keep_the_same_phase` (sans fichiers : la règle seule ; avec : l'arbre réel) |
| Chaque enchaînement a son temps de fondu | `test_each_transition_has_its_blend_time` |
| Une entrée brusque reste sans fondu | `test_an_abrupt_entry_stays_without_a_blend` |
| La course reprend à la bonne foulée | `test_the_run_resumes_at_the_right_stride` (sans fichiers : la règle seule ; avec : la sortie de glissade et de réception sur l'arbre réel) |
| La copie range aussi la marche et le sprint | `tests/test_mixamo_files.gd` : `test_the_copy_also_puts_away_the_walk_and_the_sprint` |

Aucun test sans scénario. Le scénario de décision 12 (`test_in_a_wall_run_the_feet_are_at_the_wall_and_the_head_moves_away`) a été étendu aux fondus d'entrée et de sortie et reste vert.

## Non vérifiable ici (à juger manette en main)

- **Démarrer et s'arrêter** : le passage Idle → Walking → Running doit se faire sans à-coup. Sur la plage 0,5 à 1,5 m/s, regarder si les pieds patinent (constat 1), surtout au stick à demi-poussé.
- **La cadence de course** : `animation_run_speed` passe de 6 m/s (le choix accepté de la spec précédente) à 4,49 m/s, mesuré sur le clip. À la vitesse de pointe, Running joue donc à x2,0 au lieu de x1,5 (environ 5,7 pas/s), et Sprint à x1,83 (environ 6,9 pas/s). Les pieds ne glissent plus, mais une foulée trop rapide pour la taille du personnage peut sembler frénétique : c'est à Jimmy de trancher.
- **Le sprint du flow** : on ne voit Sprint qu'au-delà de la vitesse de pointe, avec le flow. À juger : se lit-il comme une récompense ?
- **Les reprises de course** après une glissade, une réception et un wall-run : les jambes ne doivent pas sauter. Les tests le prouvent pour la glissade et la réception, pas pour le wall-run.
- **La fin du miroir après un wall-run le long d'un mur à droite** : le miroir tient désormais jusqu'à la fin du fondu de Wall Run, puis s'inverse d'un coup sur le clip qui suit (Falling Idle, Jump après un saut de mur). Selon le clip, gauche et droite peuvent permuter visiblement à cet instant.
- **Chaque fondu de la table** (course → saut 0,05, saut → chute 0,15, glissade → course 0,2, entrée et sortie de la pose groupée 0,08 et 0,12, etc.) : à juger un par un, à la sensation.
- **Le corps qui glisse vers le mur et s'en éloigne** au rythme du fondu de Wall Run (entrée et sortie), à 0 m et à 0,5 m du mur.
- **Défaut antérieur, hors de cette branche** : contre un mur que la capsule touche (0 m), les bras de Falling Idle passent jusqu'à 28 cm derrière le mur pendant la chute qui suit le wall-run (mesure du test : `in the fall, -0.281 m`). Pendant le fondu de sortie, la branche ne fait pas pire (-0,265 m). C'est le même comportement que `main`, où aucun décalage n'est appliqué pendant la chute.
- **La manette et le clavier** : la branche ne touche à aucune entrée. Rien à vérifier de ce côté.

Journaux des runs et des cassures : `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-locomotion-blend\` (`test_nofiles.log`, `mut_*.log`). Les copies de travail, y compris celle qui contenait les fichiers Mixamo, ont été supprimées. Le worktree n'a pas été modifié (`git status` propre, HEAD 5effd42).

`````

### Développeur, propreté, passe 1

`````markdown
# Rapport du développeur : animation-polish

Spec : `docs/specs/animation-polish.md`, passée à `**Statut : 🟢 Implémenté**` dans son propre commit.
Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a9ddcee74ffa6aa35`, branche `animation-polish`, sur `main` à `7bafe2b`.
Commits : `89f8b0f` (implémentation), `8d5eb1d` (statut de la spec). Rien n'a été poussé.

## Mesure d'abord (décision 1)

Méthode : un script hors dépôt lance le jeu headless avec `--fixed-fps 60 / 144 / 240` (pas fixe à 60), les fichiers Mixamo présents. Il fait courir 7 coureurs (course, saut et réception, glissade, wall-run à gauche et à droite avec l'entrée depuis une chute, figure, virage puis arrêt) et un fantôme. À chaque image affichée, il relève la position interpolée de `Visual`, sa rotation, et chaque os (vitesse et accélération par rapport au corps). Un « à-coup » est une image dont la valeur dépasse 2,5 fois la médiane de ses 8 voisines.

Ce qui était déjà bon : `Visual` est interpolé par l'interpolation physique (0 image sans mouvement à 144 et 240 fps), et l'AnimationTree avance à chaque image (mode idle, aucun palier d'os).

Les vraies sources trouvées :

| Source | Avant (144 fps / 240 fps) | Après (144 / 240) |
| --- | --- | --- |
| Fantôme : `reset_physics_interpolation()` à chaque pas | 413/708 et 891/1188 images sans bouger (0 à 60 fps) | 0/708 et 0/1188 |
| Entrée en wall-run le long d'un mur à droite : miroir instantané | un os à 214 m/s, 571x ses voisines / 356 m/s, 950x | aucun à-coup |
| Sortie du wall-run : le décalage tombe quand un fondu est coupé par le suivant (`AnimationNodeTransition` oublie l'état d'avant), puis miroir rendu | 128 m/s (10x) à gauche, 213 m/s (15x) à droite / 206 et 351 m/s | aucun à-coup |
| Course stable : coins de vitesse aux clés à 30 Hz (interpolation linéaire), clip lu à 2x | accélération p95 des os 651 / 1020 m/s² (344 à 60 fps) : elle croît avec la fréquence, signature d'un coin | 434 / 565 m/s² (230 à 60 fps) |
| Arrêt : le mélange Idle/locomotion posé une fois par pas fixe, donc en marches à 60 Hz | 41 m/s (9x) et 13 m/s (29x) / 66 m/s (19x) | 28 m/s étalés sur 2 à 4 images, 3 à 4x : c'est l'arrêt rapide du moteur lui-même |
| Réception dure | 58 m/s / 97 m/s | inchangée (sans fondu, comme le veut la spec) |

## Fait

Scénarios de la spec, chacun avec son test, vu rouge avant son code :
1. « L'inclinaison du wall-run monte et redescend en douceur » : `test_the_wall_run_roll_rises_and_falls_smoothly`, `tests/test_runner_animation.gd`.
2. « En wall-run, le personnage court » : `test_in_a_wall_run_the_character_runs`, `tests/test_runner_animation.gd`.
3. « Le décalage du wall-run est fixe » : `test_the_wall_run_offset_is_fixed`, `tests/test_player_walls.gd` (vrai moteur physique ; vu rouge par mutation : un décalage qui oscille).
4. « Les pieds effleurent le mur et la tête s'en écarte » : `test_the_feet_brush_the_wall_and_the_head_moves_away`, `tests/test_player_walls.gd` (corps inventé, gauche et droite, 0 / 0,3 / 0,6 m, et pendant la montée de l'inclinaison ; vu rouge par mutation : décalage nul).
5. « Aucun clip n'est lu trop vite » : `test_no_clip_is_played_too_fast`, `tests/test_runner_animation.gd`.
6. « Le corps visible n'avance pas par paliers » : `test_the_visible_body_does_not_move_in_steps`, `tests/test_player_frames.gd`. En temps réel, `Engine.max_fps = 144` et le pas à 60 ; le corps du coureur, le fantôme et, avec les fichiers, les os. Rouge sur le fantôme avant correction.

Autres tests :
- Décision 12, gardée et adaptée : `test_in_a_wall_run_the_feet_are_at_the_wall_and_the_head_moves_away` (`tests/test_player_walls.gd`). Avec les fichiers, à gauche comme à droite et à chaque distance : pied le plus proche à 0,050 m du mur, tête à environ 1 m, aucun os derrière le mur, ni pendant le retour à la verticale.
- Décision 3 : `test_an_interrupted_blend_does_not_jump` (`tests/test_crossfade.gd`), rouge sur un bouchon qui basculait d'un coup.
- Constat 1 (le pas de la marche ignorait le poids d'Idle) : le rythme compte maintenant Idle (`RunnerAnimation.own_speed`). Il est testé dans la partie sans fichiers de `test_the_blended_clips_keep_the_same_phase` (`tests/test_runner_locomotion.gd`), rouge contre l'ancien `own_speed` (pied à 0,03 m/s au lieu de 0,55).
- Constat 3 : dans la partie avec fichiers du même test, chaque clip seul à sa vitesse propre. Pied d'appui : Walking 1,44 m/s pour 1,49, Running 4,25 pour 4,49, Sprint 5,46 pour 5,65 (dans les ±10 %).
- Constat 4 : `test_the_table_of_blend_times_names_real_clips` (`tests/test_runner_animation.gd`), rouge sur `running>wall_run` et `wall_run>falling_idle`, retirés de la table.
- Constat 5 : une troisième foulée inventée, avec un contact parasite d'un échantillon, dans `test_the_blended_clips_keep_the_same_phase`. Vue rouge contre un `touchdown` qui prend le premier contact.
- Tests mis à jour parce que la spec change le comportement : `test_every_state_of_the_runner_has_its_animation` (WALL_RUNNING donne la course) ; `test_the_wall_run_on_the_other_side_is_mirrored` (le « miroir » devient le sens de l'inclinaison) ; `test_the_gap_can_be_cleared_by_wall_running` (`tests/test_course_walls.gd` : avec le personnage, il s'incline vers sa droite le long d'un mur à gauche ; la capsule est inchangée).

Code :
- `game/core/runner_animation.gd` : la clip `WALL_RUN` disparaît. En wall-run, la locomotion joue Running jusqu'à la vitesse de pointe, mélangée au Sprint au-delà, selon la vitesse le long du mur, avec `wall_side`. S'y ajoutent `wall_run_roll()`, `fitted_pace()` et le rythme plafonné.
- `game/core/movement_tuning.gd` et `.tres` : `animation_max_pace` (1,5), `wall_run_body_roll` (35), `wall_run_roll_time` (0,15), groupe Animation.
- `game/player/crossfade.gd` (nouveau, pur) : les poids des états, avancés à chaque image.
- `game/player/wall_run_pose.gd` (refait, pur) : corps incliné autour du milieu du corps debout, plus un décalage fixe calculé depuis l'inclinaison, la distance au mur et la course jouée.
- `game/player/runner_character.gd` :
  - une chaîne de `Blend2` pilotée par `Crossfade` à chaque image, chaque clip relancé quand il revient de zéro ;
  - le mélange de la locomotion montré entre deux pas fixes ;
  - les clés interpolées en cubique ;
  - les clips à durée fixe passés par `fitted_pace` ;
  - plus de miroir, plus de `WallLean`, plus de clip Wall Run.
- `game/player/player.gd` : inclinaison et décalage posés sur `Visual` au pas fixe, l'interpolation physique les montre entre deux pas ; `visual_transform()` n'ajoute plus rien.
- `game/player/ghost.gd` : interpolé entre deux pas ; remis à zéro seulement sur un saut de 2 m ou plus.
- `AGENTS.md` (lignes du Layout core/ et player/) et `README.md` (table des téléchargements, paragraphe des animations, ligne de la feuille de route) décrivent ce qui existe.

## Vérifié

Tout est lancé dans ce worktree, Windows, Godot 4.7.2 :
- `just setup`, puis `just mixamo "C:/Users/jimmy/Documents/mixamo"` : 15 fichiers copiés (jamais suivis par Git).
- Référence avant tout changement : `just preflight` vert, 288 tests, 40,0 s.
- `just test test_runner_animation`, `test_runner_locomotion`, `test_crossfade`, `test_player_walls`, `test_player_frames`, `test_course_walls` : rouges avant le code (bouchons ou mutations, voir plus haut), verts après.
- Sans les fichiers (`assets/mixamo` sorti du projet) : `just typecheck` à 0 erreur, `just test` à 378/378. Fichiers remis, `just import` sans erreur.
- `just preflight` final : vert, 296 tests, 40,5 s (une autre fois 43,0 s).
- `just check` final, avec les fichiers : vert. Typecheck à 0 erreur, lint propre, 378/378, structure à 0 problème, builds Windows et Linux exportés, le Windows lancé 60 images headless. 96,9 s.
- Mesures avant/après : le tableau ci-dessus, avec `--fixed-fps` 60, 144 et 240.

## Non vérifié

- Le rendu en jouant, manette en main (Jimmy) :
  - l'allure du wall-run (35°, 0,15 s, pieds au mur, tête dehors) ;
  - si le pied qui glisse à pleine vitesse se voit (voir Écarts 1) ;
  - les parties raccourcies de la réception, de la roulade et du mantle ;
  - la visée en courant ;
  - le fantôme et le bot.
- Un vrai écran à 144 ou 240 Hz : la mesure est headless avec des images à intervalle exact. La gigue réelle du rythme d'affichage (vsync) n'est pas mesurée.
- La caméra : ni changée ni mesurée (elle suit le corps interpolé, comme avant).
- Le build Linux : exporté, pas lancé (la porte lance celui de la plateforme hôte).
- `just check` en 96,9 s : la limite est de 90 s, mais je ne l'avais pas chronométré avant le changement ; le build Windows avec le personnage pèse 192 Mio. `just preflight` est à 40,5 s pour une limite de 40 (40,0 s avant).

## Écarts

1. **Le plafond de 1,5 sur la locomotion.** Je l'applique au rythme de la locomotion, c'est-à-dire au mélange rapporté à sa propre foulée (`RunnerAnimation.speed`), et non à chaque clip du mélange. Dans un mélange, un clip tenu en phase avec un clip plus court joue plus vite que le rythme : Walking jusqu'à 2,05x à 4,5 m/s (2,49x près de 8,9 m/s, où il ne pèse qu'environ 1 %), Running 1,67x dans le mélange Running/Sprint. Prendre la lecture clip par clip aurait effondré la cadence dès que Walking pèse un peu (−52 % à 8 m/s), puis l'aurait fait sauter à 9 m/s. Conséquence du plafond avec les points de passage de `locomotion-blend` (Running seul à 9 m/s, sa foulée propre est de 4,49 m/s) : le pied d'appui glisse de −10 % à 4,5 m/s, −18 % à 6 m/s et −25 % à la vitesse de pointe. Avant, Running jouait à 2,0x et le pied suivait. Le réglage `animation_max_pace` le change sans code.
2. **« Garder une partie plus courte du clip ».** On garde le début de la coupe (le contact, le début de la roulade, le début du hissé), lu à 1,5x ; l'état finit avant la fin du clip et le fondu suivant enchaîne. Landing : 0,375 s gardées sur 0,45 (lu à 1,8x avant) ; roulade : 0,75 sur 0,8 (1,6x avant) ; mantle : 0,525 sur 0,66 (1,89x avant). Hard Landing reste à 1,43x.
3. **Le décalage fixe dépend aussi de la course jouée.** Le pied gauche du Sprint va 7 cm plus loin que celui de Running : la portée est donc pondérée par le mélange Running/Sprint. Ce mélange est constant pendant un wall-run (le moteur garde la vitesse le long du mur), donc le décalage aussi. Il suit l'inclinaison en proportion à l'entrée et à la sortie. L'inclinaison pivote autour du milieu du corps debout (0,9 m), comme les figures.
4. **Course ou sprint le long du mur.** Running seul jusqu'à la vitesse de pointe, même en dessous (jamais Walking), puis mélangé au Sprint jusqu'au palier 3 du flow.
5. **Table des fondus.** `running>wall_run` (0,1) et `wall_run>falling_idle` (0,15) ont disparu. L'entrée et la sortie du wall-run prennent le défaut, 0,1 s.
6. **La capsule (sans les fichiers) est inchangée.** Elle penche toujours vers le mur (`wall_run_lean`, 20°), à l'inverse du personnage ; la spec parle du personnage.
7. **Corrections venues de la mesure, au-delà des listes de la spec :**
   - interpolation cubique des clés ;
   - mélange de la locomotion montré entre deux pas ;
   - fantôme interpolé ;
   - fondu maison à la place d'`AnimationNodeTransition` (sans lui, un fondu coupé fait sauter la pose).
8. **`Wall Run.fbx` reste exigé par `just mixamo`** : `tools/` n'est pas à moi. Le jeu ne le charge plus ; le README le dit.
9. **Le test de la décision 12 mesure une pose à chaque pas fixe.** Il fait passer l'arbre et les modificateurs du squelette en mode physique, dans le test seulement : au 10x des rejeux, on ne voyait que 8 poses au hasard de la foulée.
10. **Seuil de « saut » du fantôme : 2 m**, une constante et non un réglage du ressenti.
11. **Le constat 3 est lu comme « chaque clip seul à sa propre vitesse ».** Aux vitesses propres de Running et Sprint, le mélange réel est un mélange Walking/Running.
12. **Le pied « posé » des tests suit la définition du projet** (`Stride.ON_THE_GROUND`, 1 cm). À 2 cm, Walking lisait −16 % parce que le pied qui se déroule était compté comme posé.
13. **`PackedVector2Array.append_array` et une constante `Array[PackedVector2Array]` littérale se sont mal comportés sous Godot 4.7** (tableau vide, valeurs aberrantes). J'ai remplacé les deux par des boucles et une constante plate.

## Questions

1. **Pied qui glisse à pleine vitesse ou plafond de 1,5 ?** Trois voies :
   - garder 1,5 : le pied glisse de 25 % à 9 m/s ;
   - relever `animation_max_pace` : réglage seul, sans spec ;
   - placer les points du blend space aux vitesses propres des clips (Running seul à 4,49 m/s, Sprint dès 5,65) : −6 % à 9 m/s, mais cela contredit le scénario « Running seul à sa vitesse de pointe » de `locomotion-blend.md`, donc il faut amender cette spec.
2. **Retirer `Wall Run.fbx` de la liste exigée ?** Il faut toucher `tools/mixamo.py` et `DOWNLOADED` dans `tests/test_mixamo_files.gd`, fichiers des propriétaires.
3. **Aligner la capsule sur le personnage ?** Tête vers l'extérieur avec `wall_run_body_roll`, au lieu de pencher vers le mur.

## Addendum : décisions du coordinateur (commit `08db07d`)

Les questions 1 à 3 du rapport ci-dessus sont tranchées et faites.

- **Points de la locomotion** (amendement de `locomotion-blend.md`, décision 1 et scénario des poids) : Running seul à `animation_run_speed × animation_run_alone_pace` (nouveau réglage, 1,3, soit ≈ 5,84 m/s), Sprint seul dès la vitesse de pointe et au-delà. Le long d'un mur, Running seul jusqu'à ce point. Le test `test_the_blend_space_weights_follow_the_speed` a été réécrit sur le scénario amendé, vu rouge, puis vert.
- **Plafond** : `animation_max_pace` passe à 1,8 dans le réglage du jeu. `test_no_clip_is_played_too_fast` attend 1,8 ; vu rouge puis vert.
- **`Wall Run.fbx` n'est plus exigé** : retiré de `tools/mixamo.py`, de `DOWNLOADED` dans `tests/test_mixamo_files.gd` (une copie sans lui doit réussir ; vu rouge puis vert), du README et de `assets/CREDITS.md`.
- **Capsule** : inchangée.
- **Tests mis à jour pour les nouveaux points** : `test_the_run_follows_the_speed`, les cas de `test_in_a_wall_run_the_character_runs`, et les vitesses « clip seul » du test de phase avec fichiers.

Pied d'appui contre le sol, avec les fichiers, dans l'arbre d'animation réel ; animation choisie par `RunnerAnimation.of` depuis un moteur à cette vitesse :

| Sol | Poids (Idle, Walking, Running, Sprint) | Rythme | Pied d'appui |
| --- | --- | --- | --- |
| 4,5 m/s | 0 / 0,31 / 0,69 / 0 | 1,26 | 4,39 m/s (−2 %) |
| 6 m/s | 0 / 0 / 0,95 / 0,05 | 1,32 | 5,62 m/s (−6 %) |
| 9 m/s | Sprint seul | 1,59 | 9,04 m/s (+0 %) |
| 10,35 m/s (le moteur donne 10,25) | Sprint seul | 1,80 (plafond) | 10,03 m/s (−3 % de 10,35, −2 % de 10,25) |

Avec le plafond de 1,5, c'était −10 % à 4,5 m/s, −18 % à 6 m/s et −25 % à 9 m/s. Le calcul théorique donne 0 % jusqu'à 10,2 m/s, puis −15 % à 12 m/s quand le plafond s'applique ; l'écart de 2 à 6 % vient de la précision des vitesses de foulée mesurées. Dans un mélange, un clip faible peut jouer vite : Walking jusqu'à 2,1x à 5,6 m/s, Running jusqu'à 2,0x à 8,8 m/s, quand ils ne pèsent qu'environ 5 %.

**Vérifié** :
- `just check` vert avec les fichiers : 378 tests, builds exportés, 97,1 s.
- `just check` vert sans les fichiers (`assets/mixamo` sorti) : 378 tests, 89,7 s.
- Fichiers remis, `just import` sans erreur.

`````

### Inspecteur, propreté, après fusion

`````markdown
# Inspection : PR 48 `animation-polish` (7bafe2b..4f522fc)

Specs : `docs/specs/animation-polish.md`, `docs/specs/locomotion-blend.md` (amendée), `docs/specs/character-animations.md`. Types de tâche : core, player, harness, tooling (`tools/mixamo.py`), assets (`assets/CREDITS.md`).

## 1. Verdict : **À corriger**

Trois constats bloquants :
- les temps de fondu par paire ne s'appliquent qu'au premier pas fixe ;
- un accroc revient à chaque cycle des boucles de course, à 144 et 240 Hz ;
- `just preflight` dépasse 40 s sur la machine du propriétaire.

## 2. Constats

| # | Gravité | Fichier:ligne | Règle | Constat | Proposition |
|---|---|---|---|---|---|
| 1 | bloquant | `game/player/crossfade.gd:20-22` (avec `game/core/runner_animation.gd:167-168`) | AGENTS.md « Architecture » (chaque réglage du ressenti vit dans la ressource de réglage) ; décision 3 de locomotion-blend (un temps par paire) | `go_to` est rappelé à chaque pas fixe. Dès le deuxième pas, `blend_time_between(x, x)` renvoie le fondu par défaut (0,1 s), qui remplace le temps de la paire. Mesuré à 144 Hz : glissade → course fait 0,10 s au lieu de 0,2 s ; course → saut fait 0,083 s au lieu de 0,05 s. Modifier la table de réglage n'a donc presque aucun effet. | Dans `Crossfade.go_to`, ajouter en tête `if state == _wanted: return false`. Vérifié sur une copie : 0,2 s et 0,05 s sont respectés. Ajouter un test sur `Crossfade` qui rappelle le même état avec le temps par défaut. |
| 2 | bloquant | `game/player/runner_character.gd:639-641` (avec 533-534) | animation-polish, décision 2 (« aucun os n'avance par paliers… quand l'écran va plus vite ») et définition de l'à-coup en décision 1. C'est ma lecture : le constat est un arrêt quasi complet d'une image, pas un palier de 1/60 s. | Cet écart a été introduit par cette PR (`INTERPOLATION_CUBIC`). Les clips en boucle gardent une clé finale à t = durée, identique à la clé 0. L'interpolation cubique en boucle prend alors cette pose doublée comme voisine : la tangente tombe à zéro au point de bouclage. Tout le corps ralentit à environ 18 % de sa vitesse pendant environ 20 ms, une fois par cycle. Exemple sur le pied : Running 0,025 → 0,0046 → 0,025 par 1/240 s ; Sprint 0,035 → 0,005 ; Walking 0,006 → 0,001. Le clip source (linéaire) est régulier. En jeu, à 9 m/s (Sprint seul, au sol comme le long du mur), on mesure un creux à 27 % des voisines toutes les 48 images à 144 Hz, et à 17 % toutes les 80 images à 240 Hz : environ 3 accrocs par seconde. Le creux est invisible à 60 Hz. | Pour les clips de `LOOPED`, ne pas insérer la dernière clé (t = durée). Vérifié sur une copie : le creux disparaît (0,0187…0,0208 de façon régulière). |
| 3 | bloquant | `tests/test_player_walls.gd:353` et `:404`, `tests/test_player_frames.gd:44` | AGENTS.md « Commands » : 40 s pour `just preflight` sur la machine du propriétaire | `just preflight` dans le dépôt principal, fichiers Mixamo présents, rien d'autre de lancé de mon côté : 40,6 s, 40,6 s puis 41,3 s. Sur un clone, la boucle d'édition passe de 29,3 s en 7bafe2b à 32,6 s en 4f522fc (+3,3 s ; 288 → 296 tests). | Faire courir une seule série de coureurs à personnage pour les deux tests de mur. Les scènes à `gap/2` existent déjà dans le premier test. Sinon, réduire `WALL_RUN_STEPS`. Re-mesurer si le propriétaire jouait pendant ma mesure. |
| 4 | conseillé (prioritaire pour le ressenti) | `game/core/runner_animation.gd:211` (`_walk`) / `game/player/runner_character.gd:425` | animation-polish, décision 3 (« tout changement visible passe par un fondu ») | Arrêt et départ : la part d'Idle suit la vitesse instantanée. Avec 30 m/s² d'accélération, la bande 0,5–1,49 m/s est franchie en 2 pas fixes. L'arrêt donne hanches 14–16°/image et jambes 12–19°/image pendant 2 à 3 images, contre 0,5–1° autour (×10 à ×16). Le départ donne 8–12°/image pendant 5 images. À l'arrêt, la cadence monte aussi à 1,8 (vitesse 0,6 m/s pour une foulée à 10 % de Walking). C'est l'à-coup le plus fort qui reste hors chute et crash. | Lisser la part d'Idle et la position du blend vers leur cible à une vitesse réglée (par exemple `animation_start_stop_time`, environ 0,15–0,2 s, dans la ressource de réglage), ou élargir la bande. |
| 5 | conseillé | `tests/test_runner_animation.gd:289`, `tests/test_runner_locomotion.gd:121` | AGENTS.md « Contributing workflow » (un réglage du ressenti seul passe sans code, avec une CI verte) | Ces tests figent des valeurs du réglage du jeu (`animation_max_pace == 1.8`, point de Running à 5,84 m/s). Si le propriétaire règle ces valeurs seules, la CI casse. | Faire porter ces assertions sur `MotorBody.fixed_tuning()`. Pour le réglage du jeu, n'affirmer que des relations (allure ≤ `animation_max_pace`). |
| 6 | conseillé | `tests/test_player_frames.gd:89` et `:105-110` | Scénario « Le corps visible n'avance pas par paliers » (preuve) | L'assertion « the bones moved » ne prouve rien. J'ai cassé exprès `AnimationTree` en mode physique (os mis à jour seulement aux pas fixes) : le test reste vert. Les os y sont mesurés dans l'espace du corps, mais le `Visual` tourne à chaque image. Le volet corps visible, lui, est solide : interpolation coupée, test rouge ; fantôme remis à zéro, test rouge. | Mesurer les os dans l'espace du squelette (`get_bone_global_pose` sans la transformée du `Visual`). |
| 7 | conseillé | `tests/test_player_frames.gd:91` | Fiabilité de la CI | Le test tourne en temps réel (`max_fps` 144) et exige plus de 11 images sans pas fixe. Sur une machine qui tombe sous 60 images/s, il échoue. | Garder, mais le signaler ; ou piloter les images (`--fixed-fps`) dans un test dédié. |
| 8 | conseillé | `docs/specs/animation-polish.md:70` | AGENTS.md « Contributing workflow » (scénario = test du même nom) | Le Gherkin dit encore « 1,5 fois » alors que la décision 3 amendée et le test disent 1,8. | Amender le scénario : 1,8, `animation_max_pace`. |
| 9 | conseillé | `docs/specs/character-animations.md:77`, `:87`, décisions 4, 11 et 12, « Tout ou rien… 12 clips », `:162` ; `docs/specs/locomotion-blend.md:33` | Cohérence des specs | Les scénarios « … ou Wall Run selon l'état » et « Le wall-run de l'autre côté est en miroir » sont devenus faux. Leurs tests du même nom affirment désormais la course et l'inclinaison. Les valeurs « course → wall-run 0,1 s ; wall-run → chute 0,15 s » ont disparu de la table : un wall-run → chute vaut maintenant 0,1 s. | Ajouter un amendement qui renvoie à animation-polish, décision 4. Mettre à jour la décision 3 de locomotion-blend. |
| 10 | conseillé | `tools/mixamo.py:48` / `assets/CREDITS.md:25` | AGENTS.md « Working rules » (chaque fichier d'`assets/` a sa ligne dans CREDITS) | Le dossier `assets/mixamo/` du propriétaire contient encore `wall_run.fbx` (87 Mo), qui n'a plus de ligne dans CREDITS. Les builds de `build/` l'embarquent : `export_filter="all_resources"`, 2 occurrences de `mixamo/wall_run` dans chaque `.pck`. `just mixamo` ne retire rien. | Supprimer localement `assets/mixamo/wall_run.fbx*`. Option : `mixamo.py` signale ou retire les fichiers absents de sa liste. |
| 11 | conseillé | `tests/test_player_walls.gd:427-429` | animation-polish, décision 5 (décalage testé sans les fichiers) | Sans les fichiers (CI), « Le décalage du wall-run est fixe » n'affirme que « la capsule reste ». J'ai injecté un balancement dans `WallRunPose.offset` : sans fichiers, seul l'autre test l'a attrapé. | Ajouter au test une vérification de fixité sur un `WallRunPose` mesuré sur la course fictive (MADE_UP_RUN), le même pas après pas. |
| 12 | conseillé | `tests/test_crossfade.gd:20`, `tests/test_runner_animation.gd:317` | AGENTS.md « Contributing workflow » | Deux tests n'ont pas de scénario du même nom : `test_an_interrupted_blend_does_not_jump` et `test_the_table_of_blend_times_names_real_clips`. Ils sont utiles. | Ajouter les scénarios (décision 3) à la spec, ou l'accepter explicitement dans la PR. |

Points vérifiés et conformes :
- Mixamo et Git : aucun fichier Mixamo n'est suivi ; `git add --dry-run assets/mixamo` refuse ; `check-ignore` couvre `.fbx` et `.import`.
- Gates : `just typecheck` (114 scripts, 0 erreur), `just lint` et `just deadcode` sont verts. 378/378 tests passent avec les fichiers (dépôt principal) et sans les fichiers (clone).
- Couches : `core/` n'a ni scène ni entrée.
- Réglages : les quatre nouveaux réglages sont dans `movement_tuning.tres` (groupe Animation).
- README : exact, à une phrase près (ligne 168, « the capsule leans », ne parle que de la capsule).

## 3. Couverture de la spec (animation-polish)

| Scénario | Test | Cassé exprès |
|---|---|---|
| L'inclinaison du wall-run monte et redescend en douceur | `test_the_wall_run_roll_rises_and_falls_smoothly` | inclinaison d'un coup → rouge |
| En wall-run, le personnage court | `test_in_a_wall_run_the_character_runs` | Running seul le long du mur → rouge |
| Le décalage du wall-run est fixe | `test_the_wall_run_offset_is_fixed` | balancement → rouge avec les fichiers ; sans fichiers, prouve seulement la capsule (constat 11) |
| Les pieds effleurent le mur et la tête s'en écarte | `test_the_feet_brush_the_wall_and_the_head_moves_away` (+ `test_in_a_wall_run_the_feet_are_at_the_wall_and_the_head_moves_away` avec les fichiers) | balancement, sens d'inclinaison inversé, portée ignorée → rouge |
| Aucun clip n'est lu trop vite | `test_no_clip_is_played_too_fast` (texte du scénario à amender, constat 8) | `fitted_pace` et locomotion sans plafond → rouge |
| Le corps visible n'avance pas par paliers | `test_the_visible_body_does_not_move_in_steps` | interpolation coupée → rouge, avec et sans fichiers ; fantôme remis à zéro → rouge ; arbre en mode physique → **vert** (constat 6) |

Locomotion-blend amendée : `test_the_blend_space_weights_follow_the_speed` suit l'amendement (1,3×, mélange, Sprint seul à la vitesse de pointe).

## 4. Mesures (copie hors dépôt, `--headless --fixed-fps` 60, 144 et 240, pas fixe à 60)

Dix-huit coureurs :
- vitesses constantes (1,8 / 3,6 / 5,4 / 7,2 / 9 m/s) puis arrêt ;
- départ arrêté ;
- saut et réception ;
- glissade ;
- figure crashée ; figure réussie (×3) ;
- wall-run depuis l'air et depuis le sol, à gauche et à droite ;
- saut de mur, des deux côtés.

Corps visible et corps physique : aucun pic et aucun palier à 144 et 240 Hz. Seules exceptions :
- le crash, qui redresse le corps d'un coup (permis : « seuls le crash et la réception dure ») ;
- à 60 Hz, les virages de 25° (vitesse de rotation réglée, pas un à-coup).

À-coups d'os restants :
1. le bouclage cubique (constat 2) ;
2. l'arrêt et le départ (constat 4) ;
3. chute → réception (0,05 s dans la table) : cuisse à environ 6°/image contre environ 1° autour (×6). C'est voulu par la table, mais avec le constat 1 ce fondu dure en réalité environ 0,08 s.

Wall-run, des deux côtés :
- décalage constant pendant toute la tenue (écart 0,0000 m sur 75 à 123 images) ;
- os le plus proche à 5,0 cm (départ en l'air) et 3,6 / 6,2 cm (départ du sol), et c'est toujours un pied ;
- pied le plus proche à 13–16 cm en moyenne ;
- tête à 0,82–1,0 m ;
- jamais la tête plus près que les pieds, aucun os derrière le mur pendant le wall-run ;
- entrée et sortie à 1,62°/image (35° en 0,15 s), sans saut.

Pied d'appui, vitesse au sol de l'orteil ou de la cheville (idéal : 0) :

| Vitesse du coureur | Vitesse du pied | Glissement |
|---|---|---|
| 1,8 m/s | 0,20 | 11 % |
| 3,6 m/s | 0,17–0,50 | 5–14 % |
| 5,4 m/s | 0,36–0,97 | 7–18 % |
| 7,2 m/s | 0,66–1,61 | 9–22 % |
| 9 m/s | 0,9–1,9 | 10–21 % |

Le pied droit glisse toujours plus que le gauche. Au-delà de 10,2 m/s (plafond 1,8 × 5,65), le glissement augmente par construction : à 12,3 m/s, vitesse vue avec le flow, il faudrait 2,17.

## 5. Non vérifiable ici (à juger manette en main)

- **Le ressenti de la course à 144 et 240 Hz**, après correction du constat 2 : l'accroc par cycle était la saccade la plus probable.
- **Arrêt et départ** (constat 4) : aujourd'hui une bascule d'environ 35 ms entre la foulée et Idle.
- **Temps de fondu par paire** une fois le constat 1 corrigé. Glissade → course passera de 0,10 à 0,2 s, course → saut de 0,08 à 0,05 s, chute → réception de 0,08 à 0,05 s : le rendu changera.
- **Wall-run** :
  - inclinaison de 35° et ses 0,15 s ;
  - pied à environ 5 cm du mur, est-ce « propre comme d'autres jeux » ?
  - foulée Sprint à 1,59× le long du mur ;
  - entrée en diagonale : le corps tourne encore vers le mur pendant l'inclinaison.
- **Fin de wall-run au sol contre le mur** : le personnage debout plonge un bras de 17 à 39 cm dans le mur (mesuré, et toléré par le test). Hors de la règle du wall-run, mais visible.
- **Pieds qui glissent** de 10 à 22 % (tableau plus haut), et davantage avec le flow au-delà de 10,2 m/s.
- **Crash** : redressement d'un coup, voulu.
- **Le fantôme** désormais interpolé, en duel.
- **Clavier et souris contre manette** : rien de changé côté entrées.
- **Durée de `just check`** : la build n'a pas été lancée, conformément à la consigne. Sans build, typecheck + lint + test + deadcode prennent déjà environ 90 s (test-course seul : 54,7 s).

Outils de mesure (hors dépôt) : `C:\Users\jimmy\AppData\Local\Temp\claude\4d21bbf6abae0ffe\dbcbedcc-dd48-4246-8513-ae8cc00b312c\scratchpad\inspector-animation-polish\measure_scripts\measure.gd` et `...\py\*.py`. Données brutes : `...\m_144.csv`, `...\m_240.csv`, `...\m_60.csv`.

`````

### Développeur, propreté, passe 2

`````markdown
# Rapport du développeur : animation-polish, second passage (décisions 7 à 9)

Worktree : `C:\Users\jimmy\Documents\parkour\.claude\worktrees\agent-a6aad09214b2923b5`
Branche : `animation-polish-2`, basée sur main `4567777` (PR 49).
Commits :
- `b7669a3` animation-polish, second pass: pair blend times, seamless loops, stop and start through the walk
- `608f1d2` spec: animation-polish implemented (second pass) (ligne de statut seule)

Rien n'est poussé. Aucun fichier Mixamo n'est suivi : `assets/mixamo/` est ignoré, vérifié par `git check-ignore`.

## Fait

Scénarios du second passage. Chaque test a été vu rouge pour la bonne raison avant la correction.

| Scénario | Test | Fichier | Rouge avant, vert après |
|---|---|---|---|
| Un fondu demandé de nouveau garde son temps | `test_a_blend_asked_for_again_keeps_its_time` | `tests/test_crossfade.gd` | glissade → course : 0,111 s avant, 0,201 s après, pour 0,2 s dans la table |
| Une boucle passe son bouclage sans ralentir | `test_a_loop_passes_its_seam_without_slowing_down` | `tests/test_player_frames.gd` | rotation au bouclage rapportée aux lignes droites entre clés, comparée au reste de la boucle (voir le tableau ci-dessous) |
| L'arrêt passe par la marche | `test_the_stop_goes_through_the_walk` | `tests/test_runner_locomotion.gd` | Idle entrait en 2 pas et sortait en 2 pas ; après, 11 pas dans les deux sens, pour 11 réglés |

Test du bouclage, rotation au bouclage / rotation ailleurs dans la boucle :

| Boucle | Avant | Après |
|---|---|---|
| Boucle fictive | 0,62 / 1,01 | 1,01 / 1,01 |
| Walking | 0,71 / 0,98 | 0,98 / 0,97 |
| Running | 0,63 / 1,00 | 0,97 / 0,99 |
| Sprint | 0,68 / 0,99 | 0,98 / 0,99 |

Correctifs :
1. **Constat 1 (bloquant)**, `game/player/crossfade.gd` : `go_to` ne fait rien si l'état demandé est déjà celui qui vient (`if state == _wanted: return false`). Le temps de la paire s'applique donc en entier.
2. **Constat 2 (bloquant)**, `game/player/runner_character.gd` :
   - `_in_place` devient la fonction publique `in_place(..., looped)`, pour pouvoir la tester sans les fichiers.
   - Elle pose `loop_mode` et n'insère plus de clé finale égale à la clé 0 sur les boucles.
3. **Constat 3 (bloquant)**, temps de la boucle d'édition :
   - Les deux tests de mur partagent maintenant une seule série de six coureurs à personnage. La série est lancée une fois, au premier test qui la demande, et libérée dans `after_all`. Les mêmes écarts et les mêmes assertions sont gardés.
   - Le test des images ne dépend plus de la vitesse de la machine : le personnage prend son élan 10 fois plus vite que le temps réel, puis le temps du jeu passe à 0,25 pendant les 60 images suivies (affichage à 144). Il y a donc environ 10 images par pas fixe, et le test reste valable jusqu'à environ 17 images/s.
   - `tests/test_runner_locomotion.gd` hérite maintenant de `ReplayTest` (10 fois le temps réel). Ses attentes de pas physiques en temps réel coûtaient environ 0,9 s.
4. **Décision 9** :
   - Dans `game/core/runner_animation.gd`, la position dans le blend space est un `Vector2` : la part des clips de foulée face à Idle, et la place sur l'axe Walking → Sprint.
   - Fonctions : `locomotion_position_of`, `locomotion_weights_at`, `locomotion_moved`. `locomotion_weights` passe par elles et ne change pas de résultat.
   - D'un pas à l'autre, la position va vers celle de la vitesse sans aller plus vite que `animation_start_stop_time` (0,18 s, groupe Animation, dans `movement_tuning.tres` et `MotorBody.fixed_tuning()`).
   - Il n'y a pas de lissage en entrant dans la locomotion depuis un autre clip : le fondu par paire s'en charge.
5. **Pied d'appui** : voir « Vérifié » pour les chiffres et « Écarts » pour le correctif. Les boucles gardent maintenant le va-et-vient avant-arrière de leurs hanches ; seule leur avancée sur un cycle est retirée. Le test de foulée de `test_the_blended_clips_keep_the_same_phase` mesure désormais chaque pied séparément avec la méthode de la spec (os le plus bas entre cheville et base des orteils, sous 2 cm, médiane), au lieu de faire la moyenne des deux pieds.
6. **Constats conseillés** :
   - (5) `test_no_clip_is_played_too_fast` n'affirme 1,8 que sur `MotorBody.fixed_tuning()`. Le réglage du jeu n'est tenu qu'à sa propre limite. Le point de Running seul à 5,84 m/s devient une relation : entre la marche et la vitesse de pointe.
   - (6) Les os sont mesurés dans l'espace du squelette. J'ai forcé l'arbre en mode physique pour vérifier : le test devient rouge (« the bones moved in the skeleton »). Il restait vert avant.
   - (7) Voir le point 3.
   - (11) Le test « décalage fixe » vérifie aussi un `WallRunPose` mesuré sur `MADE_UP_RUN`, placé pas après pas sur 20 pas physiques. Il tourne avec et sans les fichiers. J'ai injecté un balancement temporel dans `WallRunPose.offset` : le volet fictif devient rouge.
   - (12) Les deux tests sans scénario homonyme sont acceptés, comme demandé ; je n'ai rien changé.
7. **README** : décrit le pied gauche comme le droit, l'arrêt et le départ par la marche, le nouveau réglage, et « the game removes the way forward of the root ». Rien à changer dans `AGENTS.md`.

## Vérifié

Commandes lancées dans le worktree, avec les fichiers Mixamo sauf mention contraire :

**`just setup` puis `just mixamo "C:/Users/jimmy/Documents/mixamo"`** : 14 fichiers copiés.

**`just check` final (après le dernier changement), avec les fichiers** : vert en 99 s.
- typecheck : 114 scripts, 0 erreur.
- lint : aucun problème.
- 381 tests, tous verts (GUT : 64,5 s).
- deadcode : vert.
- Builds Windows (192 Mio) et Linux (158 Mio) ; la build Windows a tourné 60 images en headless.

**`just check` sans les fichiers** : `assets/mixamo/` déplacé hors du projet le temps du passage, puis remis et réimporté. Vert en 92 s, 381 tests. Seule la boucle fictive est mesurée ; ailleurs, la capsule.

**`just preflight`, avec les fichiers, sur cette machine** :
- Mesures successives : 40 s au début du travail, puis 42 s, puis 39,0 / 39,0 / 40,6 / 40,6 s après les réductions.
- Temps GUT de la boucle d'édition : 16,6 s → 15,3–15,9 s.
- Coût par test (JUnit) : deux tests de mur 0,86 s au total (dont la série partagée 0,67 s) ; test des images 0,76 → 0,49 s ; `test_runner_locomotion` environ 1,0 → 0,2 s.
- Répartition des étapes : typecheck environ 13 s, lint environ 7,8 s, les deux imports environ 3,6 s chacun.
- **On reste à la limite de 40 s** (voir Questions).

**Contre-épreuves (cassé exprès, puis remis)** :
- Arbre d'animation forcé en mode physique : le test des images est rouge.
- Clé finale remise sur les boucles : le test du bouclage est rouge.
- Balancement injecté dans `WallRunPose.offset` : les deux volets du test de décalage sont rouges.
- Ancien traitement des hanches (va-et-vient supprimé) : le test par pied reste vert, car les écarts étaient déjà sous 10 % au niveau du clip. C'est un renforcement, pas un test rouge d'abord.

**Mesures en jeu, méthode de l'inspecteur** : scripts hors dépôt, `--headless --fixed-fps` 60, 144 et 240, pas fixe à 60. Fichiers : `...\scratchpad\dev2\measure2.gd`, `feet.py`, `jerk.py`, `window2.py`, `clipfeet.gd` ; données `c_60.csv`, `c_144.csv`, `c_240.csv`.

**Bouclage** :
- Aucune image de creux (moins de 40 % de la médiane des ±3 voisines, rotation des 8 os majeurs) aux 5 vitesses, à 60, 144 et 240 Hz.
- Ratio le plus bas : 0,84–0,96 à 144 et 240 Hz.
- Avant : creux à 27 % toutes les 48 images à 144 Hz, à 17 % toutes les 80 images à 240 Hz.

**Arrêt depuis la vitesse de pointe, 144 Hz** :
- Avant (inspecteur) : hanches 14–16°/image et jambes 12–19°/image pendant 2 à 3 images.
- Après : Idle entre en 11 pas sur un pas de Walking seul (0,907 → 0). Hanches au plus 1,8°/image, jambes au plus 3,0°/image.

**Départ, 144 Hz** :
- Avant (inspecteur) : 8–12°/image pendant 5 images.
- Après : hanches au plus 2,0°/image ; jambes de 2,6 à 8,4°/image en rampe, vers les 13°/image de la foulée de sprint elle-même.
- Au premier pas, Walking seul se mélange à Idle.

**Pied d'appui, deux pieds**. Mesure : os le plus bas entre cheville et base des orteils, sous 2 cm de son point le plus bas, vitesse le long de la course dans le monde (0 = posé), médiane, en part de la vitesse du coureur. Après, 144 Hz (gauche / droit) :

| Vitesse | Le long de la course | Horizontal complet (méthode d'origine de l'inspecteur) |
|---|---|---|
| 1,8 m/s | +2 % / +2 % | 4 % / 4 % |
| 3,6 m/s | -1 % / -2 % | 4 % / 4 % |
| 5,4 m/s | -1 % / -3 % | 2 % / 4 % |
| 7,2 m/s | +4 % / +4 % | 9 % / 12 % |
| 9 m/s | -4 % / +3 % | 15 % / 13 % |

- À 60 et 240 Hz, tout reste dans ±5 %.
- Avec le bout des orteils (Toe_End) inclus, les médianes restent dans ±4 %.
- Avant mon changement des hanches (seule la correction du bouclage étant faite), le long de la course : +6/0, +2/0, +2/-5, +6/+3, +1/+7 %.

Au niveau du clip (test, chaque clip seul à sa vitesse propre ; vitesse propre réglée entre parenthèses) :

| Clip | Pied gauche | Pied droit | Avant le changement des hanches |
|---|---|---|---|
| Walking (1,49 m/s) | 1,50 | 1,49 | -4 % / 0 % |
| Running (4,49 m/s) | 4,51 | 4,59 | -1,6 % / +5,1 % |
| Sprint (5,65 m/s) | 5,89 (+4,2 %) | 5,45 (-3,5 %) | -0,7 % / -8,1 % |

**Réconciliation des deux méthodes** :
- L'ancienne mesure du développeur (clip seul, cheville et orteil des deux pieds mis ensemble, sous 1 cm, moyenne signée) cachait l'asymétrie gauche/droite.
- La mesure de l'inspecteur prenait la vitesse horizontale complète, qui inclut le glissement de côté. C'est l'essentiel de ses 10–21 % à 7,2–9 m/s. Dans le fichier Sprint lui-même, l'orteil posé glisse déjà de côté à 0,35–0,44 m/s à son allure propre, puis 0,49–0,65 m/s une fois le balancement latéral des hanches retiré, ce qui fait environ 1 m/s à l'allure de 1,59.
- La différence gauche/droite le long de la course venait du traitement des hanches. Leur va-et-vient avant-arrière était supprimé, et ce va-et-vient n'est pas symétrique d'une foulée à l'autre (les fichiers Running et Sprint portent aussi une avancée de 3,17 et 3,13 m par cycle). Le garder et ne retirer que l'avancée rend chaque pied régulier.
- La phase de pose du seul pied gauche n'y est pour rien : elle sert au calage des clips, pas à la vitesse.

## Non vérifié

À juger manette en main :
- **La course à 144 et 240 Hz** sans l'accroc du bouclage, environ 3 fois par seconde avant.
- **Les temps de fondu par paire** désormais appliqués en entier : glissade → course 0,2 s au lieu de 0,10 s ; course → saut 0,05 s ; chute → réception 0,05 s au lieu d'environ 0,08 s. Le rendu change.
- **L'arrêt** : le corps s'arrête en environ 0,2 s, puis le personnage passe d'une pose de marche figée (allure 0) à Idle en 0,18 s. Est-ce naturel ou « glissé » ?
- **Le départ** : avec le réglage du jeu, la marche se voit (jusqu'à 0,30) sans dominer, puis Running prend le dessus. Au départ, le pied peut glisser brièvement : allure plafonnée à 1,8 pendant 3 à 4 pas.
- **Le va-et-vient avant-arrière des hanches** gardé sur les boucles : ±3 à 4 cm en course, ±2,5 cm en sprint, ±3 cm à la marche. Il est visible ; à juger.
- **Le glissement de côté du pied** au sprint (environ 13–15 % en vitesse horizontale). Il vient surtout du fichier ; IK hors périmètre.
- **Le wall-run** : inchangé à part le lissage de la locomotion (le va-et-vient des hanches est le long du mur, pas vers lui). Les tests prouvent la fixité du décalage vers le mur.
- **Clavier et souris contre manette** : rien de changé côté entrées.
- **CI** : les temps de la CI, sans les fichiers, ne sont pas mesurés ici.

## Écarts

1. **Forme du lissage de la décision 9.** J'ai lu « la position dans le blend space » comme les deux paramètres de l'arbre : la part d'Idle, et la place sur l'axe Walking → Sprint. Chacun suit sa cible sans traverser son étendue entière en moins de `animation_start_stop_time` : Idle ↔ marche en 0,18 s au moins, Walking ↔ Sprint en 0,18 s au moins.
   - Un plafond unique par unité aurait fait traîner la course derrière le corps (pied qui glisse au départ, foulée figée longtemps à l'arrêt).
   - Lisser seulement Idle aurait laissé un saut de pose dans un arrêt brutal, contre un mur.
   - Le test vérifie que l'arrêt et le départ durent le temps réglé (±1 pas), qu'aucun poids ne saute, que l'arrêt mélange Idle à Walking, et que le départ commence par Walking seul et le montre tant qu'Idle part.
   - « La marche domine au départ » n'est vrai qu'avec le réglage fixe des tests, pas avec celui du jeu ; je ne l'affirme donc pas.
2. **Va-et-vient des hanches gardé sur les boucles.** Ce n'est pas demandé tel quel par la spec, mais c'est la correction que la consigne demandait pour le pied droit. Le côté reste retiré, pour respecter le « sans balancement » du wall-run et son test de hanches fixes vers le mur.
3. **`test_the_run_resumes_at_the_right_stride`.** Il reprenait la course à la vitesse de pointe, où Sprint joue seul depuis l'amendement, mais calculait la phase attendue sur le cycle de Running. Il passait par chance et est devenu rouge avec la correction du bouclage. Il reprend maintenant là où Running joue seul ; les deux phases coïncident exactement (0,700 / 0,700, 0,717 / 0,717).
4. **Test des images.** Le rapport 144:60 du scénario devient, en temps réel, 144 images pour 15 pas par seconde (temps du jeu à 0,25), pour qu'il y ait des images sans pas sur toute machine. Chaque pas vaut toujours 1/60 s de jeu. Images suivies : 90 → 60. Assertion renforcée : plus de la moitié des images sans pas, et des pas pendant le suivi.
5. **Constat 5.** Le 1,8 n'est affirmé que sur le réglage fixe.
6. **Mesure de la spec.** « Os le plus bas du pied » est lu comme la cheville ou la base des orteils (les os de l'inspecteur), seuil 2 cm, médiane, composante le long de la course (« vitesse vers l'arrière »). J'indique aussi la vitesse horizontale complète, celle de l'inspecteur.

## Questions

1. **Limite de 40 s de `just preflight`.** Sur cette machine, avec les fichiers, elle tourne entre 39,0 et 40,6 s, alors que j'ai retiré environ 1,3 s de tests d'animation. Le reste du dépassement ne vient pas de cette spec :
   - typecheck environ 13 s, lint environ 7,8 s, deux imports ;
   - `test_player.gd` et `test_player_aim.gd` attendent des pas physiques en temps réel (environ 3,9 s à eux deux) ; ils pourraient hériter de `ReplayTest`.

   Faut-il une passe dédiée, ou revoir la limite ?
2. **`just check` dépasse la limite de 90 s** : 99 s avec les fichiers, 92 s sans. C'était déjà le cas avant cette passe d'après l'inspecteur (environ 90 s sans build). Même question.
3. **Typecheck instable.** Une fois, `just typecheck` a signalé `game/levels/trick_park.gd` en erreur. Le fichier seul passait, et le typecheck suivant aussi ; je n'ai pas pu reproduire. À surveiller.

`````
