"""
Module Utils - Fonctions utilitaires partagées entre les modules de menu
"""
module Utils

using Dates
using ...Types

export generer_donnees_test_performance, afficher_rapport_validation
export afficher_statut_api, afficher_documentation_api

"""
Génère un jeu de données synthétiques pour l'évaluation des performances système.
"""
function generer_donnees_test_performance(systeme::SystemeSOTRACO, volume::Int)
    donnees = []
    
    ligne_ids = collect(keys(systeme.lignes))
    arret_ids = collect(keys(systeme.arrets))
    
    # Fallback vers des identifiants par défaut si le système n'est pas initialisé
    if isempty(ligne_ids) || isempty(arret_ids)
        ligne_ids = [1, 2, 3]
        arret_ids = [1, 2, 3, 4, 5]
    end
    
    for i in 1:volume
        # Construction d'enregistrements avec valeurs réalistes
        push!(donnees, (
            id = i,
            date = Date(now()) - Day(rand(0:30)),
            heure = Time(rand(6:21), rand(0:59)),
            ligne_id = rand(ligne_ids),
            arret_id = rand(arret_ids),
            montees = rand(1:15),
            descentes = rand(1:12),
            occupation_bus = rand(20:60),
            capacite_bus = 80
        ))
    end
    
    return donnees
end

"""
Présente les métriques de validation sous forme de rapport structuré.
"""
function afficher_rapport_validation(metriques::Dict{String, Float64})
    println("\n📋 RAPPORT DE VALIDATION DES PRÉDICTIONS")
    println("=" ^ 50)

    for (metrique, valeur) in metriques
        valeur_affichee = if occursin("pourcentage", metrique) || occursin("precision", metrique)
            "$(round(valeur * 100, digits=1))%"
        else
            "$(round(valeur, digits=3))"
        end

        println("• $(replace(metrique, "_" => " ")): $valeur_affichee")
    end
end

"""
Contrôle et affichage de l'état actuel de l'API REST.
"""
function afficher_statut_api(systeme::SystemeSOTRACO)
    println("\n🌐 STATUT API REST")
    println("=" ^ 30)

    if systeme.api_active
        println("✅ État: ACTIVE")
        println("🌐 URL: http://127.0.0.1:8081")
        println("📊 Endpoints: 15+ disponibles")
        println("📈 Uptime: Actif depuis le démarrage")
    else
        println("⏸️ État: INACTIVE")
        println("💡 Utilisez l'option 1 pour démarrer l'API")
    end
end

"""
Documentation technique des endpoints et utilisation de l'API REST.
"""
function afficher_documentation_api()
    println("\n📖 DOCUMENTATION API SOTRACO")
    println("=" ^ 40)
    println("🌐 Documentation complète disponible à:")
    println("   http://127.0.0.1:8081 (quand l'API est active)")
    println()
    println("📋 Endpoints principaux:")
    println("   GET  /api/status - Statut du système")
    println("   GET  /api/arrets - Liste des arrêts")
    println("   GET  /api/lignes - Liste des lignes")
    println("   POST /api/optimisation - Optimisation globale")
    println("   POST /api/predictions/generer - Prédictions")
    println()
    println("💡 Exemples cURL:")
    println("   curl http://127.0.0.1:8081/api/status")
    println("   curl -X POST http://127.0.0.1:8081/api/optimisation")
end

end # module Utils