# sky_line — application mobile de meteo (Flutter)

## 1. Stack Technique Approuvée

| Domaine                    | Technologie                             | Contrainte & Usage                                         |
| -------------------------- | --------------------------------------- | ---------------------------------------------------------- |
| **Framework**              | Flutter >=3.35.0 (Dart ^3.9.2)          | UI Multiplateforme                                         |
| **Gestion d'État**         | `flutter_bloc` 9.x                      | BLoC Pattern strict (Events & States)                      |
| **Immutabilité**           | `equatable` ^2.0.x                      | Comparaison value-based, `copyWith` manuel obligatoire     |
| **Réseau / API**           | `dio` 5.x                               | Client HTTP configuré de manière centralisée               |
| **Base de Données**        | `objectbox` 5.x                         | Base locale NoSQL (Codegen: `dart run build_runner build`) |
| **Graphiques**             | `fl_chart` 1.x                          | Visualisation des données météo et historiques             |
| **Géolocalisation**        | `geolocator` 14.x                       | Localisation GPS de l'appareil ; reverse geocoding via API HTTP (Open-Meteo / BigDataCloud) |
| **Design / Design System** | Fonts: SF Pro (400, 500, 900)           | Typographie Apple par défaut (`assets/fonts/SF_Pro/`)      |
| **Qualité & Linter**       | `package:flutter_lints/flutter.yaml`    | Zéro warning toléré à l'analyse                            |
| **Tests**                  | `flutter_test`, `mocktail`, `bloc_test` | TDD : Couverture unitaire et BLoC obligatoire              |

---

## 2. Architecture & Organisation des Fichiers

Le projet applique une structure **Clean Architecture stricte découpée par Fonctionnalités (Feature-Driven)**. La couche `core/` centralise les outils partagés transverses. Les dossiers `core/` et `features/` sont actuellement des squelettes vierges à initialiser.

### Arborescence Structurelle Obligatoire
lib
├── core                    # Couche transverse (cross-cutting concerns)
│   ├── config          # Thèmes, injection de dépendances, configuration ObjectBox, routing
│   ├── constants   # Constantes (API keys, dimensions, durées)
│   ├── enum           # Enumerations
│   ├── errors          # Système d'erreurs unifié (Failures, AppErrorCode)
│   └── utils             # Formateurs (dates, conversion météo), helpers de plateforme
├── features           # Modules métiers (ex: forecast, location, settings)
│   └── [feature_name]
│         ├── data              
│         │   ├── models                # DTO (JSON mapping, extensions d'entités)
│         │   ├── repositories       # Implémentations concrètes des contrats domaine
│         │   └── sources               # Distante (Dio/Open-Meteo) et Locale (ObjectBox)
│         ├── domain
│         │   ├── entities               # Objets métier purs (Immutables via Equatable)
│         │   ├── repositories      # Interfaces / Contrats du dépôt
│         │   └── usecases            # Cas d'utilisation unitaires (Callable classes)
│         └── presentation
│             ├── blocs            # Gestionnaires d'état (Bloc, Event, State)
│             ├── screens       # Écrans principaux de la feature
│             └── widgets       # Composants UI atomiques et réutilisables
└── main.dart               # Point d'entrée de l'application (à câbler)

## 3. Consultation du Code via Serena (Serveur MCP)

Lorsqu'une tâche nécessite de consulter le code source (localiser une classe, comprendre un flux de données, retrouver les usages d'un symbole), l'agent **DOIT** utiliser le serveur **Serena** (MCP) comme première approche, au lieu de scanner l'intégralité du codebase à chaque prompt.

### 3.1 Activation et Ordre de Priorité
* **Activation du Projet :** Avant toute consultation, activer le projet Serena (`serena_activate_project`, nom du projet : `sky_line`). Consulter le manuel d'instructions via `serena_initial_instructions` si nécessaire.
* **Découverte d'Abord :** Toute exploration du code commence par les outils symboliques de Serena (`serena_find_symbol`, `serena_get_symbols_overview`, `serena_find_declaration`, `serena_find_referencing_symbols`) **avant** tout `grep`, `glob` ou lecture brute de fichiers. Les recherches de contenu ne sont autorisées qu'en complément, jamais en premier recours.
* **Requêtes Parallèles :** Regrouper les appels Serena indépendants dans un même tour afin d'économiser les allers-retours et préserver le contexte.
* **Édition Symbolique :** Après lecture via Serena, privilégier ses outils d'édition (`serena_replace_symbol_body`, `serena_insert_after_symbol`, `serena_replace_content`) pour toute modification structurelle.

### 3.2 Bonnes Pratiques de Consultation
* **Lecture Limitative :** Ne lire que les fichiers ou extraits strictement nécessaires. L'aperçu symbolique (`serena_get_symbols_overview`) suffit généralement à appréhender la structure d'un fichier sans le parcourir en entier. Ne jamais relire un fichier déjà parcouru.
* **Mémoires de Contexte :** Consulter les mémoires pertinentes (`serena_list_memories`, `serena_read_memory`) pour récupérer le contexte déjà documenté du projet.
* **Objectif :** Éviter le scan exhaustif du code à chaque prompt et récupérer rapidement uniquement ce qui est pertinent pour la tâche en cours, préservant ainsi le contexte de travail.

## 4. Conventions de Codage Absolues (Gouvernance Superpowers)

Pour éviter toute dégradation de contexte ou paresse intellectuelle lors de l'utilisation de Superpowers, l'agent devra valider chaque micro-tâche selon les règles d'ingénierie suivantes :

### 4.1 Conception des Composants et Immutabilité
* **Anglais Intégral :** Tout le code (nom de variables, classes, commentaires, bases de données, commits) doit être rédigé exclusivement en anglais. Aucun compromis.
* **Equatable Systématique :** Toutes les classes du Domaine (`Entities`), les modèles de données (`Models`), ainsi que les `Events` et `States` des BLoCs doivent obligatoirement étendre `Equatable` avec leurs `props` explicitement déclarées.
* **Pas de Générateurs d'Immutabilité :** L'utilisation de packages comme `freezed` est interdite. Les méthodes `copyWith` doivent être codées manuellement pour chaque entité et modèle.
* **Mappers Dédiés :** L'isolation des couches doit être garantie par des classes statiques de mapping indépendantes (ex: `WeatherMapper`). Le modèle de données (`Model`) ne doit jamais s'infiltrer dans la couche domaine ou présentation.

### 4.2 Gestion des Erreurs Rigoureuse
* **Pas de Crash Silencieux :** Les exceptions bas niveau (réseau Dio, stockage ObjectBox) doivent être capturées dans la couche `Data` et converties en objets typés `Failure` (définis dans `core/errors/`).
* **Propagation Propre :** Les couches `Data` et `Domain` propagent les erreurs de manière structurée. La logique métier ne doit pas lever d'exceptions non gérées.
* **Consommation Présentation :** La couche présentation intercepte les états d'erreur des BLoCs via un `BlocListener` pour afficher des retours utilisateurs explicites et localisés (SnackBar, vues d'erreur dédiées). Les chaînes de caractères de débogage ne doivent jamais être visibles par l'utilisateur.

### 4.3 Isolation UI et États Mutables
* **États Immutables :** Il est strictement interdit de manipuler des propriétés mutables privées (champs mutables modifiés par référence) à l'intérieur d'un BLoC. Chaque changement d'état doit émettre une nouvelle instance via `emit(state.copyWith(...))`.
* **Couplage Faible :** Les widgets de la couche présentation doivent être le plus possible "sans état" (`StatelessWidget`). Ils ne doivent contenir aucune règle métier.
* **Gestion des États Fluides :** Toute opération asynchrone (récupération météo, géolocalisation) doit obligatoirement transiter par un état intermédiaire de chargement explicite (`LoadingState`) avant d'afficher les données ou l'erreur.
* **Zéro Logique Globale dans l'UI :** Le `BuildContext` ne doit jamais être passé en paramètre ou manipulé au sein des Use Cases ou des dépôts.

---

## 5. Commandes de l'Usine Logicielle

Ces commandes doivent être exécutées par l'agent dans son environnement de travail isolé (`Git Worktree`) pour valider l'intégrité du code avant chaque livraison.

| Action / Vérification | Commande | Objectif |
|---|---|---|
| **Analyse Statique** | `flutter analyze` | Tolérance zéro : 0 warning, 0 info. |
| **Tests Unitaires** | `flutter test` | Exécution globale de la suite de tests. |
| **Test Spécifique** | `flutter test test/path/to_test.dart` | Validation unitaire d'une tâche du plan. |
| **Génération de Code** | `dart run build_runner build` | À lancer après chaque modification ObjectBox. |
| **Vérification Icônes** | `dart run flutter_launcher_icons` | Configuration des assets du projet. |
| **Exécution** | `flutter run` | Lancement de l'environnement de développement. |

---

## 6. Philosophie Générale du Projet

Le projet **SkyLine** applique une **Clean Architecture et un découpage Feature-Driven inflexibles**. L'application est pensée pour être robuste, testable et hautement modulaire dès ses fondations. 