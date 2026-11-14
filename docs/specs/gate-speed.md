# Des portes plus rapides, sans rien retirer

**Statut : 🟢 Implémenté**

Session du 2026-11-14, décidée par la session principale sur délégation de Jimmy
(« continue, peaufine, avance »). Changement d'outillage et de tests : aucun test n'est
retiré ni affaibli, aucune vérification n'est enlevée d'une porte.

## Contexte

Limites (`docs/specs/test-tiers.md`, `AGENTS.md`) : `just preflight` 40 s, `just check`
90 s, sur la machine de Jimmy. Mesures du 2026-11-14 avec les fichiers Mixamo :
`just preflight` de 39,0 à 40,6 s (typecheck environ 13 s, lint environ 7,8 s, tests
environ 15,5 s) ; `just check` 99 s (92 s sans les fichiers). Des tests attendent encore
en temps réel (`tests/test_player.gd`, `tests/test_player_aim.gd`, environ 3,9 s) au lieu
de l'horloge accélérée de `ReplayTest` ; le projet a 114 scripts.

## Décisions

| # | Question | Décision | Pourquoi |
| - | -------- | -------- | -------- |
| 1 | Mesurer d'abord | Le développeur mesure chaque étape des deux portes (import, typecheck, lint, chaque script de test, structure, chaque export) et les trie par durée, avant et après. | Accélérer ce qui coûte, pas ce qu'on suppose. |
| 2 | Les tests en temps réel | Tout test qui attend des pas de physique en temps réel passe à l'horloge accélérée de `ReplayTest` (chaque pas reste 1/60 s de jeu), sauf ceux dont la règle exige le temps réel, qui le disent en commentaire. | Le temps du jeu, pas celui de la machine. |
| 3 | Les outils | Le typecheck, le lint et l'import ne refont pas un travail déjà fait dans la même porte (un seul import par commande, des fichiers lus une fois) ; les outils qui peuvent travailler en parallèle le font, si leur documentation le permet. Aucune vérification n'est sautée. | Le typecheck et le lint font la moitié de `just preflight`. |
| 4 | Les limites | Après la passe, `just preflight` sous 32 s et `just check` sous 85 s sur la machine de Jimmy au repos, avec les fichiers. Si une limite ne peut pas être tenue sans retirer une vérification, le développeur s'arrête et le dit. | Garder de la marge pour les prochaines specs. |

## Scénarios

```gherkin
# language: fr
Fonctionnalité: Des portes plus rapides

  Scénario: La boucle rapide tient sous sa nouvelle marge
    Soit le dépôt avec les fichiers Mixamo, la machine au repos
    Quand on lance just preflight trois fois
    Alors chaque passage prend moins de 32 s

  Scénario: La porte du commit tient sous sa nouvelle marge
    Soit le dépôt avec les fichiers Mixamo, la machine au repos
    Quand on lance just check
    Alors il prend moins de 85 s

  Scénario: Rien n'est retiré des portes
    Soit la liste des scripts de test, des fichiers vérifiés par le typecheck et le lint, et des étapes de chaque porte, avant et après
    Quand on les compare
    Alors rien n'a disparu
```

Ces scénarios se prouvent par la démonstration du développeur (commandes, sorties,
temps), comme pour `docs/specs/test-tiers.md`.

## Hors périmètre

- Changer les limites de `AGENTS.md` : elles restent 40 s et 90 s.
- Retirer ou alléger un test.
