# Deux paliers de tests : la boucle rapide et la porte du commit

**Statut : 🟢 Implémenté**

Session du 2026-11-14, décidée par la session principale sur délégation de Jimmy
(« enchaîne sur tout le reste »). Changement d'une porte : il passe par sa propre spec,
sa propre pull request et des commits dédiés, comme le demande `AGENTS.md`.

## Contexte

`just preflight` (typecheck, lint, tous les tests, structure) doit rester sous 30 s sur
la machine de Jimmy : décision 10 de `docs/specs/reactive-replays.md`, décisions 20 de
`docs/specs/movement-ground.md` et de `docs/specs/movement-walls.md`. Après le flow
(`docs/specs/flow-combo.md`), il mesure 28,8 s : il reste 1,2 s, et les trois specs
suivantes (figures, sabotage, duel local) ajoutent des rejeux dans la vraie physique,
dont le parcours entier mené par le bot.

L'essentiel du temps vient des rejeux du parcours par le pilote, dans
`tests/test_course.gd`, `tests/test_course_ground.gd`, `tests/test_course_walls.gd` et
`tests/test_course_flow.gd` (environ 10 s sur 17 s de tests).

`just check` (preflight plus les exports) est la porte du commit et de la CI ; il n'a pas
de limite de temps.

Ce que la spec ne doit pas casser : aucun test n'est retiré de `just check` ni affaibli ;
`just test <filtre>` garde son sens.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Deux paliers | `just preflight` lance tous les tests **sauf** les scripts de rejeu du parcours, ceux dont le nom de fichier commence par `test_course`. `just check` lance **tous** les tests, plus le typecheck, le lint, la structure et les exports. La CI lance `just check`, comme avant. | La boucle d'édition reste rapide ; la porte qui protège `main` garde tout. |
| 2 | Lancer les rejeux seuls | Une nouvelle commande `just test-course` lance seulement les scripts `test_course*`. `just test` sans filtre lance toujours tous les tests. | Pour qui travaille sur le parcours. |
| 3 | La limite de 30 s | Elle s'applique désormais à `just preflight` tel que redéfini. Une limite pour `just check` : 90 s sur la machine de Jimmy, exports compris. Le développeur donne les deux temps. | Garder une borne sur chaque palier. |
| 4 | La règle de nommage | Tout test qui rejoue le parcours, ou une section, avec le pilote ou le bot, vit dans un script dont le nom commence par `test_course`. `just deadcode` le vérifie : un script de test qui charge la scène du parcours (directement ou par `CourseTest`) sans ce préfixe échoue. | Sans ce garde-fou, un rejeu lent rentrerait dans la boucle rapide sans que personne le voie. |
| 5 | Ne jamais passer à vide | Comme `just test <filtre>` aujourd'hui, chaque palier échoue si aucun test n'a tourné ou si le résumé de GUT ne dit pas que tout a passé. | La protection de `tools/run_tests.py` reste. |
| 6 | `AGENTS.md` | La table des commandes décrit les deux paliers et `just test-course`, dans un commit à part. | `AGENTS.md` est la source des règles. |
| 7 | Les specs antérieures | Les décisions « `just preflight` reste sous 30 s » des specs antérieures restent vraies au sens de la décision 1 ; une note dans chacune renvoie à cette spec. | Pas de règle contredite en silence. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Deux paliers de tests

  Scénario: La boucle rapide ne lance pas les rejeux du parcours
    Soit la suite de tests
    Quand on lance just preflight
    Alors aucun script dont le nom commence par test_course ne tourne, et tous les autres tournent

  Scénario: La porte du commit lance tous les tests
    Soit la suite de tests
    Quand on lance just check
    Alors tous les scripts de test tournent, rejeux du parcours compris

  Scénario: Un rejeu du parcours qui échoue fait échouer la porte du commit
    Soit un test de rejeu du parcours qui échoue
    Quand on lance just check
    Alors just check échoue

  Scénario: Les rejeux se lancent seuls
    Soit la suite de tests
    Quand on lance just test-course
    Alors seuls les scripts dont le nom commence par test_course tournent

  Scénario: Un rejeu du parcours mal nommé est refusé
    Soit un script de test qui charge la scène du parcours sans que son nom commence par test_course
    Quand on lance just deadcode
    Alors la structure signale le script

  Scénario: Un palier sans test échoue
    Soit un palier dont la sélection ne trouve aucun test
    Quand on le lance
    Alors il échoue
```

Les scénarios sur les commandes se prouvent par des tests des outils Python s'il en
existe la place, ou par une démonstration dans le rapport du développeur (commande,
sortie, code de retour), comme pour les autres portes du dépôt.

## Hors périmètre

- Accélérer les rejeux eux-mêmes (pas de physique plus grand, parallélisme) : plus tard,
  si `just check` approche 90 s.
- Changer la CI : elle lance déjà `just check`.

## Concepts travaillés

| Concept | Avant | Après |
| ------- | ----- | ----- |
| Paliers de vérification : boucle rapide contre porte complète | — | discovered |
