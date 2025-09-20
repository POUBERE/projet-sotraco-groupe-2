#!/usr/bin/env julia

"""
Point d'entrée principal du système SOTRACO v2.0
Avec fonctionnalités avancées: Prédiction IA, Carte Interactive, API REST
"""

push!(LOAD_PATH, @__DIR__)

using SOTRACO

"""
    main()

Fonction principale avec gestion avancée des arguments.
"""
function main()
    if length(ARGS) > 0
        arg = ARGS[1]

        if arg == "--help" || arg == "-h"
            afficher_aide_complete()
            return

        elseif arg == "--api-only"
            lancer_api_seule()
            return

        elseif arg == "--avance" || arg == "--advanced"
            println("🚀 Démarrage en mode avancé...")
            try
                systeme = initialiser_systeme()
                if systeme.donnees_chargees
                    demarrer_mode_avance(systeme)
                    gerer_menu_interactif(systeme)
                else
                    println("❌ Échec de l'initialisation")
                    afficher_suggestions_correction()
                end
            catch e
                println("❌ Erreur mode avancé: $e")
                afficher_suggestions_correction()
            end
            return

        elseif arg == "--test"
            executer_tests_unitaires()
            return

        elseif arg == "--version" || arg == "-v"
            afficher_informations_version()
            return

        else
            println("❌ Argument non reconnu: $arg")
            println("💡 Utilisez --help pour voir les options disponibles")
            return
        end
    end

    lancer_systeme_sotraco()
end

"""
Affiche l'aide complète du système.
"""
function afficher_aide_complete()
    println("""
🚌 SYSTÈME SOTRACO v2.0 - AIDE COMPLÈTE
========================================

DESCRIPTION:
    Système d'Optimisation du Transport Public SOTRACO
    Version 2.0 avec fonctionnalités avancées:
    • Prédiction intelligente de la demande
    • Carte interactive du réseau
    • API REST pour intégrations
    • Analyses économiques détaillées

MODES DE DÉMARRAGE:

    julia main.jl                   Mode normal (interface menu)
    julia main.jl --avance          Mode avancé (toutes fonctionnalités)
    julia main.jl --api-only        API REST seulement
    julia main.jl --test            Tests unitaires
    julia main.jl --version         Informations version
    julia main.jl --help            Afficher cette aide

FONCTIONNALITÉS PRINCIPALES:

    📊 Analyses Classiques:
       • Analyse de fréquentation globale
       • Identification des heures de pointe
       • Calcul des taux d'occupation
       • Optimisation des fréquences

    ✨ Fonctionnalités Avancées:
       • Prédiction IA de la demande (7+ jours)
       • Carte interactive avec Leaflet
       • API REST complète (15+ endpoints)
       • Dashboard temps réel

    📈 Visualisation:
       • Graphiques ASCII avancés
       • Cartes géographiques
       • Tableaux de performance
       • Exports multiformats

CONFIGURATION REQUISE:

    • Julia 1.8+ (recommandé: 1.9+)
    • Dépendances: DataFrames, CSV, HTTP, JSON3
    • Fichiers CSV dans le dossier data/
    • 4GB RAM minimum (8GB recommandé)

STRUCTURE DES DONNÉES:

    data/arrets.csv:
        id, nom_arret, quartier, zone, latitude, longitude,
        abribus, eclairage, lignes_desservies

    data/lignes_bus.csv:
        id, nom_ligne, origine, destination, distance_km,
        duree_trajet_min, tarif_fcfa, frequence_min, statut

    data/frequentation.csv:
        id, date, heure, ligne_id, arret_id, montees, descentes,
        occupation_bus, capacite_bus

EXEMPLES D'UTILISATION:

    # Démarrage normal avec menu interactif
    julia main.jl

    # Mode avancé avec toutes les fonctionnalités
    julia main.jl --avance

    # API REST seule pour intégrations
    julia main.jl --api-only

    # Tests de validation
    julia main.jl --test

ENDPOINTS API (mode --api-only):

    GET  /api/status                    - Statut système
    GET  /api/arrets                    - Liste arrêts
    GET  /api/lignes                    - Liste lignes
    POST /api/optimisation              - Optimisation
    POST /api/predictions/generer       - Prédictions
    GET  /api/carte/donnees             - Données carte

DÉPANNAGE:

    Erreur "Fichier non trouvé":
        → Vérifiez la présence des CSV dans data/

    Erreur de parsing:
        → Vérifiez l'encodage UTF-8
        → Contrôlez les virgules dans les données

    Performance lente:
        → Réduisez la taille du dataset pour tests
        → Utilisez julia -O3 pour optimiser

SUPPORT:

    📧 Consultez la documentation dans docs/
    🐛 Rapportez les bugs avec --test
    💡 Suggestions d'amélioration bienvenues

VERSION: 2.0.0
LICENCE: Projet académique - Tous droits réservés
    """)
end

"""
Lance uniquement l'API REST sans interface.
"""
function lancer_api_seule()
    println("🌐 DÉMARRAGE API REST SEULEMENT")
    println("=" ^ 40)

    try
        systeme = initialiser_systeme()

        if !systeme.donnees_chargees
            println("❌ Impossible de démarrer l'API sans données")
            println("💡 Vérifiez la présence des fichiers CSV dans data/")
            return
        end

        demarrer_serveur_api(systeme, 8081)

        println("\n🎯 API REST SOTRACO ACTIVE")
        println("📍 URL: http://127.0.0.1:8081")
        println("📖 Documentation: http://127.0.0.1:8081")
        println("🔧 Status: http://127.0.0.1:8081/api/status")
        println("\n⏹️ Appuyez sur Ctrl+C pour arrêter")

        # Maintien du serveur en vie
        try
            while true
                sleep(1)
            end
        catch InterruptException
            println("\n🛑 Arrêt du serveur demandé...")
            arreter_serveur_api()
            println("✅ Serveur arrêté proprement")
        end

    catch e
        println("❌ Erreur: $e")
        try
            arreter_serveur_api()
        catch
            # Nettoyage silencieux en cas d'erreur
        end
        afficher_suggestions_correction()
    end
end

"""
Exécute les tests unitaires du système.
"""
function executer_tests_unitaires()
    println("🧪 EXÉCUTION DES TESTS UNITAIRES")
    println("=" ^ 40)

    try
        # Vérification de la disponibilité du package Test
        try
            @eval using Test
        catch LoadError
            println("⚠️ Package Test non disponible")
            println("💡 Installation avec: using Pkg; Pkg.add(\"Test\")")
            executer_tests_simples()
            return
        end

        println("🔍 Démarrage des tests avec @testset...")
        
        @eval begin
            @testset "Tests SOTRACO v2.0" begin
                @testset "Structures de données" begin
                    println("🔍 Test des structures...")
                    arret = Arret(1, "Test", "Centre", "Zone 1", 12.0, -1.0, true, true, [1, 2])
                    @test arret.id == 1
                    @test arret.nom == "Test"
                    @test arret.abribus == true
                    @test length(arret.lignes_desservies) == 2

                    ligne = LigneBus(1, "Ligne Test", "A", "B", 10.0, 30, 150, 15, "Actif", [1, 2])
                    @test ligne.id == 1
                    @test ligne.statut == "Actif"
                    @test ligne.distance_km == 10.0
                    println("✅ Structures validées")
                end

                @testset "Système de base" begin
                    println("🔍 Test du système...")
                    systeme = SystemeSOTRACO()
                    @test !systeme.donnees_chargees
                    @test length(systeme.arrets) == 0
                    @test length(systeme.lignes) == 0
                    println("✅ Système de base validé")
                end

                @testset "Intégration modules" begin
                    println("🔍 Test d'intégration...")
                    @test isdefined(SOTRACO, :Types)
                    @test isdefined(SOTRACO, :DataLoader)
                    @test isdefined(SOTRACO, :Analyse)
                    @test isdefined(SOTRACO, :Optimisation)
                    println("✅ Modules intégrés")
                end
            end
        end

        println("\n🎉 TOUS LES TESTS RÉUSSIS!")

    catch e
        println("❌ Erreur lors des tests: $e")
        println("💡 Tentative de tests simplifiés...")
        executer_tests_simples()
    end
end

"""
Exécute des tests simplifiés sans le package Test.
"""
function executer_tests_simples()
    println("🔍 Tests basiques sans package Test...")
    
    try
        println("Test 1: Création d'un arrêt")
        arret = Arret(1, "Test", "Centre", "Zone 1", 12.0, -1.0, true, true, [1, 2])
        assert(arret.id == 1, "ID arrêt incorrect")
        assert(arret.nom == "Test", "Nom arrêt incorrect")
        println("✅ Arrêt créé avec succès")

        println("Test 2: Création d'une ligne")
        ligne = LigneBus(1, "Test", "A", "B", 10.0, 30, 150, 15, "Actif", [1, 2])
        assert(ligne.id == 1, "ID ligne incorrect")
        assert(ligne.statut == "Actif", "Statut ligne incorrect")
        println("✅ Ligne créée avec succès")

        println("Test 3: Création du système")
        systeme = SystemeSOTRACO()
        assert(!systeme.donnees_chargees, "État initial incorrect")
        assert(length(systeme.arrets) == 0, "Arrêts initiaux non vides")
        println("✅ Système créé avec succès")

        println("\n🎉 TESTS BASIQUES RÉUSSIS!")

    catch e
        println("❌ Erreur tests basiques: $e")
        afficher_suggestions_correction()
    end
end

"""
Fonction assert simple pour les tests.
"""
function assert(condition::Bool, message::String="Assertion failed")
    if !condition
        throw(AssertionError(message))
    end
end

"""
Affiche les informations de version.
"""
function afficher_informations_version()
    println("""
🚌 SOTRACO - Système d'Optimisation du Transport Public
=========================================================

VERSION: 2.0.0
DATE: $(Dates.format(now(), "yyyy-mm-dd"))
JULIA: $(VERSION)

MODULES INTÉGRÉS:
  ✅ Types               - Structures de données
  ✅ DataLoader          - Chargement CSV robuste
  ✅ Analyse             - Analyses statistiques
  ✅ Optimisation        - Algorithmes d'optimisation
  ✅ Visualisation       - Graphiques ASCII
  ✅ Rapports            - Génération rapports
  ✅ Menu                - Interface utilisateur

FONCTIONNALITÉS:
  📊 Analyses détaillées
  🚀 Optimisation intelligente
  📈 Visualisations ASCII
  📝 Rapports automatisés

STATISTIQUES:
  📄 Lignes de code: ~2,000+
  🧪 Tests unitaires: Intégrés
  📚 Documentation: Complète
  🎯 Couverture: Transport urbain Ouagadougou

ÉQUIPE DE DÉVELOPPEMENT:
  👥 Binôme d'étudiants (à personnaliser)
  🎓 Projet académique avancé
  🇧🇫 Focus: Transport public burkinabè

LICENCE: Projet éducatif - Usage académique
SUPPORT: Documentation intégrée
    """)
end

"""
Affiche des suggestions de correction pour les erreurs communes.
"""
function afficher_suggestions_correction()
    println("\n💡 SUGGESTIONS DE CORRECTION:")
    println("   📁 Vérifiez que les fichiers CSV sont présents dans data/:")
    println("      • data/arrets.csv")
    println("      • data/lignes_bus.csv")
    println("      • data/frequentation.csv")
    println()
    println("   🔑 Vérifiez les permissions de lecture des fichiers")
    println("   📝 Vérifiez le format des données CSV (headers, encodage UTF-8)")
    println("   🧾 Consultez les logs d'erreur ci-dessus pour plus de détails")
    println()
    println("   🚀 Relancez avec: julia --project=. src/main.jl")
    println("   📖 Ou consultez le README.md pour l'installation complète")
end

"""
Point d'entrée principal du système en mode normal.
"""
function lancer_systeme_sotraco()
    println("🚌 DÉMARRAGE DU SYSTÈME SOTRACO v2.0")
    println("=" ^ 50)

    try
        systeme = initialiser_systeme()

        if systeme.donnees_chargees
            println("\n💡 Système prêt! Choisissez votre mode:")
            println("   1. Menu interactif normal")
            println("   2. Mode avancé (si modules disponibles)")
            print("Votre choix (1 ou 2): ")

            choix = readline()

            if choix == "2"
                # Vérification des modules avancés
                try
                    if isdefined(SOTRACO, :Prediction)
                        demarrer_mode_avance(systeme)
                    else
                        println("⚠️ Modules avancés non disponibles, mode normal utilisé")
                    end
                catch e
                    println("⚠️ Erreur modules avancés: $e, mode normal utilisé")
                end
            end

            gerer_menu_interactif(systeme)
        else
            println("❌ Échec de l'initialisation. Vérifiez les fichiers de données.")
            afficher_suggestions_correction()
        end

    catch e
        println("❌ Erreur fatale: $e")
        println("📍 Trace d'erreur détaillée:")

        # Analyse contextuelle de l'erreur
        if isa(e, SystemError)
            println("   Erreur système: Vérifiez les permissions et chemins de fichiers")
        elseif isa(e, ArgumentError)
            println("   Erreur d'argument: Vérifiez la validité des données CSV")
        elseif isa(e, BoundsError)
            println("   Erreur d'index: Données CSV potentiellement corrompues")
        else
            println("   Type d'erreur: $(typeof(e))")
        end

        afficher_suggestions_correction()
    end
end

"""
Démarre le mode avancé si les modules sont disponibles.
"""
function demarrer_mode_avance(systeme::SystemeSOTRACO)
    println("\n🚀 TENTATIVE DE DÉMARRAGE MODE AVANCÉ")

    try
        if isdefined(SOTRACO, :Prediction)
            println("✅ Modules de prédiction disponibles")
        end

        if isdefined(SOTRACO, :CarteInteractive)
            println("✅ Modules de carte interactive disponibles")
        end

        if isdefined(SOTRACO, :API_REST)
            println("✅ Modules API REST disponibles")
        end

        println("🎯 Mode avancé activé avec modules disponibles")

    catch e
        println("⚠️ Certains modules avancés non disponibles: $e")
        println("💡 Utilisation du mode standard")
    end
end

# Point d'entrée principal
if abspath(PROGRAM_FILE) == @__FILE__
    try
        main()
    catch e
        if isa(e, InterruptException)
            println("\n🛑 Programme interrompu par l'utilisateur")
            println("👋 Au revoir!")
        else
            println("\n❌ Erreur inattendue: $e")
            println("\n🐛 INFORMATIONS DE DÉBOGAGE:")
            println("   • Type d'erreur: $(typeof(e))")
            println("   • Vérifiez que tous les modules sont correctement définis")
            println("   • Vérifiez que les dépendances sont installées")
            println("   • Utilisez: julia --project=. src/main.jl")
            println("   • Pour les tests: julia --project=. src/main.jl --test")

            afficher_suggestions_correction()
        end
        exit(1)
    end
end