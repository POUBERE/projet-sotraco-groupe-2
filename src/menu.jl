"""
Module Menu - Interface utilisateur modularisée SOTRACO v2.0
"""
module Menu

using Dates
using Statistics
using JSON3
using ..Types, ..Analyse, ..Optimisation, ..Visualisation, ..Rapports
using ..Prediction, ..CarteInteractive, ..API_REST, ..Accessibilite, ..Performance

include("config/config_avancee.jl")
include("config/tests_validation.jl")
include("config/accessibilite_social.jl") 
include("config/performance_optim.jl")
include("config/utils_commun.jl")

using .ConfigurationAvancee
using .TestsValidation
using .AccessibiliteSocial
using .PerformanceOptimisation
using .Utils

export afficher_menu_principal, gerer_menu_interactif, afficher_info_systeme
export demarrer_mode_avance

"""
Affiche le menu principal complet du système SOTRACO v2.0.
"""
function afficher_menu_principal()
    println("\n" * "=" ^ 80)
    println(" 🚌 SOTRACO v2.0 - SYSTÈME D'OPTIMISATION AVANCÉ 🚌")
    println("=" ^ 80)
    println("📊 ANALYSES CLASSIQUES:")
    println("1. 📈 Analyser la fréquentation globale")
    println("2. ⏰ Identifier les heures de pointe")
    println("3. 🎯 Analyser le taux d'occupation")
    println("4. 🚀 Optimiser les fréquences")
    println("5. 📋 Tableau de performance détaillé")
    println()
    println("✨ FONCTIONNALITÉS AVANCÉES:")
    println("6. 🔮 Prédiction intelligente de la demande")
    println("7. 🗺️ Carte interactive du réseau")
    println("8. 🌐 API REST et services web")
    println("9. 📊 Dashboard temps réel")
    println()
    println("📊 VISUALISATION ET RAPPORTS:")
    println("10. 🎨 Visualiser le réseau (ASCII)")
    println("11. 📝 Générer un rapport complet")
    println("12. 💾 Exporter les données")
    println("13. 📈 Économies potentielles")
    println()
    println("⚙️ SYSTÈME ET CONFIGURATION:")
    println("14. ℹ️ Informations système")
    println("15. 🚀 Mode avancé (tout activer)")
    println("16. 🔧 Configuration avancée")
    println("17. 🧪 Tests et validation")
    println()
    println("🌟 IMPACT SOCIAL ET PERFORMANCE:")
    println("18. ♿ Accessibilité et Impact Social")
    println("19. ⚡ Performance et Optimisation")
    println("0. 🚪 Quitter")
    println("=" ^ 80)
    print("Votre choix (0-19): ")
end

"""
Gère l'interface interactive du menu principal.
"""
function gerer_menu_interactif(systeme::SystemeSOTRACO)
    println("\n💡 Système prêt! Toutes les fonctionnalités sont disponibles.")

    while true
        afficher_menu_principal()
        choix = readline()

        try
            executer_choix_menu(choix, systeme)

            if choix == "0"
                break
            elseif choix in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"]
                attendre_utilisateur()
            else
                println("❌ Choix invalide! Veuillez entrer un nombre entre 0 et 19.")
                attendre_utilisateur()
            end

        catch e
            println("❌ Erreur: $e")
            println("💡 Si le problème persiste, vérifiez l'état du système (option 14)")
            attendre_utilisateur()
        end
    end
end

"""
Exécute l'action correspondant au choix utilisateur.
"""
function executer_choix_menu(choix::String, systeme::SystemeSOTRACO)
    if choix == "1"
        analyser_frequentation_globale(systeme)

    elseif choix == "2"
        heures_pointe = identifier_heures_pointe(systeme)
        generer_graphique_frequentation_ascii(heures_pointe)

    elseif choix == "3"
        analyser_taux_occupation(systeme)

    elseif choix == "4"
        optimiser_toutes_lignes(systeme)

    elseif choix == "5"
        afficher_tableau_performance_lignes(systeme)

    elseif choix == "6"
        gerer_predictions_menu(systeme)

    elseif choix == "7"
        gerer_carte_interactive_menu(systeme)

    elseif choix == "8"
        gerer_api_rest_menu(systeme)

    elseif choix == "9"
        afficher_dashboard_ascii(systeme)

    elseif choix == "10"
        afficher_carte_reseau_ascii(systeme)

    elseif choix == "11"
        generer_rapport_complet(systeme)

    elseif choix == "12"
        exporter_donnees_csv(systeme)

    elseif choix == "13"
        calculer_economies_potentielles(systeme)

    elseif choix == "14"
        afficher_info_systeme_detaillees(systeme)

    elseif choix == "15"
        demarrer_mode_avance(systeme)

    elseif choix == "16"
        ConfigurationAvancee.gerer_configuration_avancee(systeme)

    elseif choix == "17"
        TestsValidation.gerer_tests_validation(systeme)
        
    elseif choix == "18"
        AccessibiliteSocial.gerer_accessibilite_impact_social(systeme)
        
    elseif choix == "19"
        PerformanceOptimisation.gerer_performance_optimisation(systeme)

    elseif choix == "0"
        if systeme.api_active
            try
                arreter_serveur_api()
                println("🛑 API REST arrêtée proprement")
            catch
            end
        end

        println("\n" * "=" ^ 60)
        println("👋 Au revoir! Merci d'avoir utilisé SOTRACO v2.0")
        println("📈 Votre analyse contribue à l'amélioration du transport public!")
        println("=" ^ 60)
    end
end

"""
Gestion du sous-menu des prédictions avancées.
"""
function gerer_predictions_menu(systeme::SystemeSOTRACO)
    println("\n🔮 PRÉDICTION INTELLIGENTE DE LA DEMANDE")
    println("=" ^ 50)
    println("1. Prédire demande globale (7 jours)")
    println("2. Prédire pour une ligne spécifique")
    println("3. Prédire avec facteurs externes")
    println("4. Analyser les tendances détectées")
    println("5. Valider la précision du modèle")
    println("6. Optimiser les paramètres de prédiction")
    println("7. Export des prédictions (CSV)")
    println("8. Retour au menu principal")
    print("Choix: ")

    choix_pred = readline()

    if choix_pred == "1"
        executer_prediction_globale(systeme)
    elseif choix_pred == "2"
        executer_prediction_ligne_specifique(systeme)
    elseif choix_pred == "3"
        gerer_predictions_facteurs_externes(systeme)
    elseif choix_pred == "4"
        analyser_tendances(systeme)
    elseif choix_pred == "5"
        metriques = valider_predictions(systeme)
        afficher_rapport_validation(metriques)
    elseif choix_pred == "6"
        optimiser_predictions(systeme)
    elseif choix_pred == "7"
        exporter_predictions_csv(systeme)
    elseif choix_pred == "8"
        return
    else
        println("❌ Choix invalide")
    end
end

"""
Gestion du sous-menu de la carte interactive.
"""
function gerer_carte_interactive_menu(systeme::SystemeSOTRACO)
    println("\n🗺️ CARTE INTERACTIVE AVANCÉE")
    println("=" ^ 40)
    println("1. Générer la carte HTML complète")
    println("2. Carte analytique (clusters & corridors)")
    println("3. Carte temps réel (simulation)")
    println("4. Exporter données GeoJSON")
    println("5. Personnaliser l'apparence")
    println("6. Générer toutes les cartes")
    println("7. Retour au menu principal")
    print("Choix: ")

    choix_carte = readline()

    if choix_carte == "1"
        generer_carte_interactive_complete(systeme)
    elseif choix_carte == "2"
        chemin = generer_carte_analytique(systeme)
        println("✅ Carte analytique générée: $chemin")
    elseif choix_carte == "3"
        chemin = generer_carte_temps_reel(systeme)
        if !isempty(chemin)
            println("✅ Carte temps réel générée: $chemin")
        end
    elseif choix_carte == "4"
        chemin = exporter_donnees_geojson(systeme)
        println("✅ Export GeoJSON: $chemin")
    elseif choix_carte == "5"
        gerer_personnalisation_carte(systeme)
    elseif choix_carte == "6"
        generer_toutes_cartes(systeme)
    elseif choix_carte == "7"
        return
    else
        println("❌ Choix invalide")
    end
end

"""
Gestion du sous-menu de l'API REST.
"""
function gerer_api_rest_menu(systeme::SystemeSOTRACO)
    println("\n🌐 API REST SOTRACO")
    println("=" ^ 30)
    println("1. Démarrer l'API (port 8081)")
    println("2. Arrêter l'API")
    println("3. Statut de l'API")
    println("4. Tester les endpoints")
    println("5. Voir la documentation")
    println("6. Configurer le port")
    println("7. Retour au menu principal")
    print("Choix: ")

    choix_api = readline()

    if choix_api == "1"
        demarrer_api_avec_config(systeme)
    elseif choix_api == "2"
        if systeme.api_active
            arreter_serveur_api()
        else
            println("ℹ️ API non active")
        end
    elseif choix_api == "3"
        afficher_statut_api(systeme)
    elseif choix_api == "4"
        if systeme.api_active
            tester_endpoints_api()
        else
            println("❌ API non active. Démarrez-la d'abord (option 1)")
        end
    elseif choix_api == "5"
        afficher_documentation_api()
    elseif choix_api == "6"
        println("💡 Le port sera configuré au prochain démarrage de l'API")
    elseif choix_api == "7"
        return
    else
        println("❌ Choix invalide")
    end
end

"""
Initialise et démarre l'ensemble des fonctionnalités avancées du système.
"""
function demarrer_mode_avance(systeme::SystemeSOTRACO)
    println("\n🚀 DÉMARRAGE DU MODE AVANCÉ COMPLET")
    println("=" ^ 60)

    if !systeme.donnees_chargees
        println("❌ Données non chargées! Impossible de démarrer le mode avancé.")
        return
    end

    services_actives = []

    println("🔮 1/4 - Génération des prédictions initiales...")
    try
        predictions_globales = predire_demande_globale(systeme, 7)
        if !isempty(predictions_globales)
            push!(services_actives, "Prédictions IA: $(length(systeme.predictions)) générées")
            println("✅ Prédictions générées pour $(length(predictions_globales)) lignes")
        end
    catch e
        println("⚠️ Erreur prédictions: $e")
    end

    println("\n🗺️ 2/4 - Génération des cartes interactives...")
    try
        chemin_carte = generer_carte_interactive(systeme)
        if !isempty(chemin_carte)
            push!(services_actives, "Carte interactive: $chemin_carte")
            println("✅ Carte interactive générée")
        end

        chemin_analytique = generer_carte_analytique(systeme)
        push!(services_actives, "Carte analytique: $chemin_analytique")
        println("✅ Carte analytique générée")

        chemin_geojson = exporter_donnees_geojson(systeme)
        push!(services_actives, "Export GeoJSON: $chemin_geojson")
        println("✅ Export GeoJSON créé")

    catch e
        println("⚠️ Erreur cartes: $e")
    end

    println("\n🌐 3/4 - Démarrage de l'API REST...")
    try
        if !systeme.api_active
            demarrer_serveur_api(systeme, 8081)
            push!(services_actives, "API REST: http://127.0.0.1:8081")
            println("✅ API REST active")
        else
            push!(services_actives, "API REST: déjà active")
            println("ℹ️ API REST déjà active")
        end
    catch e
        println("⚠️ Erreur API: $e")
    end

    println("\n📝 4/4 - Génération des rapports complets...")
    try
        generer_rapport_complet(systeme)
        push!(services_actives, "Rapport complet: resultats/rapport_sotraco.txt")
        println("✅ Rapport complet généré")

        calculer_economies_potentielles(systeme)
        push!(services_actives, "Analyse économique: complétée")
        println("✅ Analyse économique terminée")

    catch e
        println("⚠️ Erreur rapports: $e")
    end

    afficher_resume_mode_avance(services_actives)
end

"""
Affiche le résumé des services activés en mode avancé.
"""
function afficher_resume_mode_avance(services)
    services_str = String[string(s) for s in services]

    println("\n" * "🎯" ^ 20)
    println("MODE AVANCÉ SOTRACO v2.0 - RÉSUMÉ")
    println("🎯" ^ 20)

    println("\n✅ SERVICES ACTIVÉS ($(length(services_str))):")
    for (i, service) in enumerate(services_str)
        println("   $i. $service")
    end

    println("\n🚀 FONCTIONNALITÉS DISPONIBLES:")
    println("   📊 Dashboard temps réel avec métriques avancées")
    println("   🔮 Prédictions IA avec validation continue")
    println("   🗺️ Cartes interactives multi-niveaux")
    println("   🌐 API REST pour intégrations externes")
    println("   📈 Analyses économiques détaillées")
    println("   📝 Rapports exécutifs automatisés")

    println("\n💡 PROCHAINES ÉTAPES RECOMMANDÉES:")
    println("   1. Consulter le dashboard (option 9)")
    println("   2. Ouvrir la carte interactive dans votre navigateur")
    println("   3. Tester l'API REST avec les endpoints fournis")
    println("   4. Examiner le rapport détaillé généré")

    println("\n🎓 SYSTÈME SOTRACO v2.0 PLEINEMENT OPÉRATIONNEL!")
    println("🎯" ^ 20)
end

"""
Affiche les informations détaillées sur l'état du système.
"""
function afficher_info_systeme_detaillees(systeme::SystemeSOTRACO)
    println("\nℹ️ INFORMATIONS SYSTÈME DÉTAILLÉES")
    println("=" ^ 50)

    println("📊 DONNÉES:")
    println("   • Arrêts chargés: $(length(systeme.arrets))")
    println("   • Lignes chargées: $(length(systeme.lignes))")
    lignes_actives = count(l -> l.statut == "Actif", values(systeme.lignes))
    println("   • Lignes actives: $lignes_actives / $(length(systeme.lignes))")
    println("   • Données fréquentation: $(length(systeme.frequentation)) enregistrements")
    println("   • Prédictions générées: $(length(systeme.predictions))")

    println("\n🔧 SERVICES:")
    println("   • Données chargées: $(systeme.donnees_chargees ? "✅ Oui" : "❌ Non")")
    println("   • API REST: $(systeme.api_active ? "✅ Active" : "⏸️ Inactive")")

    println("\n🗺️ CONFIGURATION CARTE:")
    println("   • Centre: ($(systeme.config_carte.centre_lat), $(systeme.config_carte.centre_lon))")
    println("   • Zoom initial: $(systeme.config_carte.zoom_initial)")
    println("   • Couleurs personnalisées: $(length(systeme.config_carte.couleurs_lignes)) lignes")

    afficher_metriques_qualite(systeme)
    afficher_etat_memoire()
end

function attendre_utilisateur()
    println("\n⏸️ Appuyez sur Entrée pour continuer...")
    readline()
end

function afficher_lignes_disponibles(systeme::SystemeSOTRACO)
    println("\n🚌 Lignes disponibles:")
    lignes_actives = [l for l in values(systeme.lignes) if l.statut == "Actif"]
    for ligne in sort(lignes_actives, by=l->l.id)
        println("   $(ligne.id). $(ligne.nom)")
    end
end

end # module Menu