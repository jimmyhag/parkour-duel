# Le Chase contre un bot : un adversaire qui court, franchit et grimpe

**Statut : 🟢 Implémenté**

Session du 2026-11-15, avec Jimmy, après avoir joué le tempo réaliste
(`docs/specs/realistic-tempo.md`, « un peu plus lent, un peu mieux ») : « est-ce que tu
peux créer un mode avec un bot en chase ? […] avec un bot qui peut faire des trucs ». Il a
choisi des **rôles qui alternent** comme dans le Chase à deux, et **trois niveaux**. Le
reste a été délégué à la session principale (« je te fais confiance »).

## Contexte

Le mode Chase (`docs/specs/chase-mode.md`) se joue à deux, en écran partagé, sur la
même machine : manches de 20 s, rôles échangés à chaque manche, premier à 3 manches. Le
bot du duel (`BotIntentSource`) suit un couloir en ligne droite avec le pilote
(`PilotIntentSource`) ; il ne sait pas se déplacer dans une arène. Les inspections ont
déjà fait courir des bots dans l'arène, mais droit vers l'autre, sans obstacles choisis.

L'arène sera refaite « plus propre » dans une spec suivante : le bot ne doit pas dépendre
de la forme de cette arène-ci, seulement de ce que la scène de l'arène déclare.

Ce que la spec ne doit pas casser : tous les scénarios, le Chase à deux, les autres
modes ; les règles d'`AGENTS.md` (`core` sans scène ni entrée, les intentions comme seule
entrée du moteur, chaque action aux deux claviers) ; ce que le coureur constate ne dépend
jamais du corps visible.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Le mode | Un nouveau choix **« CHASE VS BOT »** dans l'écran de départ, après « CHASE » ; puis le choix du niveau **« EASY »**, **« NORMAL »**, **« HARD »** (NORMAL en premier sélectionné). | Q1 de Jimmy. |
| 2 | Le joueur | **Plein écran**, une seule vue ; le joueur joue au clavier-souris **ou** à la manette (les deux à la fois, comme en solo). Aucune manette n'est demandée. | Un joueur seul. |
| 3 | La partie | Les règles du Chase, sans changement : 20 s, contact des capsules, rôles échangés à chaque manche, premier à 3 manches, flow remis à zéro à chaque manche. Le **joueur est chat** à la première manche ; à chaque revanche, l'autre rôle commence. Mêmes départs, mêmes couleurs, même indicateur de l'autre hors champ, même écran entre deux manches. | Q2 : les rôles alternent. |
| 4 | Le bot ne triche pas | Le bot est un coureur comme le joueur : même scène, même moteur, même réglage, même bonus du flow ; il ne commande le moteur que par des **intentions** (`MoveIntent`), pas à pas, comme une manette. Il ne voit le joueur que par sa position et sa vitesse au pas courant. | Une victoire contre lui doit se mériter, et se perdre, à la régulière. |
| 5 | Se déplacer dans l'arène | Le bot suit un chemin dans l'arène : une **navigation** cuite depuis la géométrie de l'arène (`NavigationRegion3D` ; Godot 4.7 le propose, le développeur lit sa documentation), avec la hauteur d'un coureur en glissade pour passer sous les passages bas. Les mouvements qui quittent le sol marchable sont des **liens** déclarés dans la scène de l'arène (`NavigationLink3D` ou équivalent), chacun avec son mouvement : **franchir** un muret (dans les deux sens), **se hisser** sur un bloc (mantle), **monter** sur une plateforme par son bloc-rebord, **descendre** d'un bloc ou d'une plateforme. Sous un passage bas, le bot **glisse**. | Le bot suit ce que l'arène déclare : refaire l'arène, c'est refaire ses liens. |
| 6 | Le cerveau du bot | Un état de `core`, pur et testé sans scène : à chaque décision, il reçoit son rôle, sa position et sa vitesse, celles du joueur, et des points candidats avec leurs distances de chemin (calculées par `player`), et rend **un but**. **Chat** : la position du joueur prévue `chase_bot_lead` s plus tard (sa vitesse comptée), ramenée sur la navigation. **Souris** : parmi des **points de fuite** déclarés dans l'arène, celui qui maximise (distance de chemin du chat au point) − (distance de chemin du bot au point), en écartant ceux dont le chemin passe à moins de `chase_bot_danger_radius` du chat ; il change de point quand le chat s'approche à moins de ce rayon ou quand il l'atteint. | Q3 : chasser en anticipant, fuir en gardant de la marge. Pur, donc testable et prêt pour le réseau. |
| 7 | Les trois niveaux | Un niveau règle seulement : le temps entre deux décisions (`chase_bot_decision_time` : EASY **0,5 s**, NORMAL **0,25 s**, HARD **0,1 s**) ; l'anticipation du chat (`chase_bot_lead` : EASY **0**, NORMAL **0,3 s**, HARD **0,6 s**) ; les liens qu'il prend (EASY : ni plateformes ni blocs à hisser ; NORMAL et HARD : tous) ; la poussée (EASY **85 %** du stick, NORMAL et HARD **100 %**) ; les figures (décision 8). | Q4 : trois niveaux, qui jouent plus ou moins juste, sans aller plus vite que le joueur. |
| 8 | Il fait des trucs | En **NORMAL** et **HARD**, le bot fait une **figure simple** quand il descend d'une plateforme ou d'un bloc et que la hauteur le permet (calculé depuis le réglage, un simple qui finit avant le sol), et pose la réception avec une glissade : **PERFECT** en HARD, dans la fenêtre simple en NORMAL. Ses franchissements, mantles et glissades comptent au flow comme ceux du joueur, et lui donnent le même bonus de vitesse. | « Un bot qui peut faire des trucs », et le flow qui compte dans la poursuite. |
| 9 | Jamais coincé | Si le bot n'avance plus vers son but pendant `chase_bot_stuck_time` (**0,6 s**), il reprend un chemin depuis sa position (et saute s'il est contre un obstacle) ; il ne reste jamais plus de **2 s** sans progresser. Une chute hors de l'arène le ramène à son départ, comme le joueur. | Un bot coincé tue le mode. |
| 10 | L'équilibre | **Amendé le 2026-11-15 avec Jimmy** (« revoir la cible »). Mesuré bot contre bot sur des manches variées (départs décalés de ±1 m, des deux côtés). Dans cette arène, sans boucle autour d'un obstacle, un chat de même niveau attrape toujours la souris (NORMAL contre NORMAL : 40 manches sur 40) ; l'équilibre à niveau égal (35 à 65 %) devient une exigence de **l'arène refaite** (spec suivante), pas du bot. Ici, **un niveau plus haut gagne plus** : sur **6 manches** par confrontation, HARD chat contre EASY souris en gagne au moins **4**, EASY chat contre HARD souris au plus **3**, et le chat HARD contre EASY gagne plus que le chat EASY contre HARD. NORMAL contre NORMAL est rapporté, sans borne. Le développeur rapporte aussi la mesure sur au moins 40 manches. | Trois niveaux qui veulent dire quelque chose ; l'équilibre se joue dans l'arène. |
| 11 | Les écrans | Le HUD du Chase (rôle, temps, indicateur de l'autre) en plein écran ; l'écran entre deux manches dit « CAT WINS » ou « MOUSE WINS » ; la fin de partie dit **« YOU WIN »** ou **« BOT WINS »**, avec « REMATCH » et « MENU ». | Mêmes écrans, adaptés à un joueur seul. |
| 12 | Les réglages | Les valeurs du bot vivent dans la ressource de réglage (groupe « Chase bot »), une valeur par niveau. | Règle d'`AGENTS.md`. |
| 13 | Les couches | Le cerveau dans `core` ; la navigation, le suivi du chemin et les intentions du bot dans `player` (comme les autres bots) ; les liens, les points de fuite et l'assemblage dans `levels`. | Table d'`AGENTS.md`. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Le Chase contre un bot

  # --- Le cerveau (core) ---

  Scénario: Le chat vise où le joueur va être
    Soit un bot chat de niveau NORMAL et un joueur qui court en ligne droite
    Quand le bot choisit son but
    Alors c'est la position du joueur prévue 0,3 s plus tard

  Scénario: La souris fuit vers le point le plus sûr
    Soit un bot souris, un chat, et trois points de fuite dont un derrière le chat
    Quand le bot choisit son but
    Alors c'est le point où il arrive avec le plus d'avance sur le chat, jamais celui derrière le chat

  Scénario: La souris change de point quand le chat s'approche
    Soit un bot souris qui court vers un point de fuite
    Quand le chat entre dans le rayon de danger
    Alors le bot choisit un autre point

  Scénario: Un niveau plus haut décide plus souvent et anticipe plus
    Soit les trois niveaux du réglage du projet
    Quand on compare leurs temps de décision et leur anticipation
    Alors HARD décide plus souvent et anticipe plus que NORMAL, et NORMAL plus qu'EASY

  # --- Le bot dans l'arène (vraie physique) ---

  Scénario: Le bot franchit, se hisse, monte et glisse
    Soit un bot de niveau HARD et un but de l'autre côté de chaque lien de l'arène
    Quand il y va
    Alors il franchit les murets, se hisse sur les blocs, monte sur les plateformes et glisse sous les passages bas, et atteint chaque but

  Scénario: Le bot facile ne prend ni plateformes ni blocs
    Soit un bot de niveau EASY et un but sur une plateforme
    Quand il cherche son chemin
    Alors il n'en trouve pas qui passe par un bloc à hisser ou une plateforme

  Scénario: Le bot fait une figure en descendant d'une plateforme
    Soit un bot de niveau HARD sur une plateforme, et un but au sol
    Quand il en descend
    Alors il fait une figure simple et la pose en PERFECT

  Scénario: Le bot ne reste jamais coincé
    Soit les manches entre bots du scénario « Un niveau plus haut gagne plus », aux trois niveaux
    Quand on suit chaque bot pas à pas
    Alors aucun ne reste plus de 2 s sans progresser vers son but

  Scénario: Le bot ne commande que par des intentions
    Soit un bot dans l'arène
    Quand il joue une manche
    Alors son moteur ne reçoit que des intentions, une par pas, et sa vitesse ne dépasse jamais celle d'un coureur de son palier de flow

  Scénario: Un niveau plus haut gagne plus
    # amendement
    Soit 6 manches variées par confrontation
    Quand des bots s'affrontent
    Alors HARD chat contre EASY souris en gagne au moins 4, EASY chat contre HARD souris au plus 3, et le premier plus que le second

  Scénario: Chaque lien de l'arène se parcourt
    Soit chaque lien déclaré dans la scène de l'arène
    Quand le pilote le parcourt dans son sens, à la vitesse de pointe
    Alors il arrive de l'autre côté par le mouvement du lien

  # --- Écrans et entrées ---

  Scénario: Le mode se choisit dans l'écran de départ
    Soit l'écran de départ, sans manette
    Quand on choisit « CHASE VS BOT », puis « NORMAL »
    Alors la partie démarre en plein écran contre un bot de niveau NORMAL, le joueur chat

  Scénario: Le joueur joue au clavier comme à la manette
    Soit une partie contre le bot
    Quand le clavier pousse en avant, puis la manette
    Alors le joueur avance les deux fois

  Scénario: La fin de partie dit qui a gagné
    Soit une partie où le joueur gagne sa troisième manche, puis une où le bot gagne la sienne
    Quand la partie finit
    Alors l'écran dit « YOU WIN », puis « BOT WINS »
```

## UI & Layout Contract

- **Référence visuelle** : aucune ; Jimmy juge en jouant.
- **Arbre de composants** : écran de départ (modifié : « CHASE VS BOT », puis le choix du
  niveau) ; vue plein écran du joueur avec le HUD du Chase (réutilisé) ; écran entre deux
  manches (réutilisé) ; fin de partie (réutilisée, libellés adaptés).
- **États** : choix du niveau ; compte à rebours ; manche en cours ; fin de manche ; fin
  de partie.
- **Libellés** (en anglais) : « CHASE VS BOT », « EASY », « NORMAL », « HARD », « CAT »,
  « MOUSE », « CAT WINS », « MOUSE WINS », « YOU WIN », « BOT WINS », « REMATCH »,
  « MENU ».

## Hors périmètre

- L'équilibre à niveau égal : l'arène refaite devra le permettre (des boucles autour des
  obstacles), mesuré avec ce bot.
- Refaire l'arène « plus propre » : la spec suivante ; elle redéclarera ses liens et ses
  points de fuite.
- Le wall-run et le wall-jump du bot, les figures doubles ou vrillées : après avoir joué.
- Un bot dans le duel en couloirs ou le Trick Park : rien ne change pour eux.
- Le jeu en ligne : étape 5.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Navigation avec liens déclarés (navmesh, liens hors du sol) | — | discovered |
| Séparer la décision (pure) du suivi de chemin (moteur de jeu) | — | discovered |
