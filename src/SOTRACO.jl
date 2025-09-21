"""
Module SOTRACO - Système d'Optimisation du Transport Public
"""
module SOTRACO

using Reexport
using Dates, DataFrames, CSV, Statistics, Printf, HTTP, JSON3

include("types.jl")
include("data_loader.jl")
include("analyse.jl")
include("optimisation.jl")
include("prediction.jl")
include("carte_interactive.jl")
include("visualisation.jl")
include("rapports.jl")
include("accessibilite.jl")
include("performance.jl")
include("api_rest.jl")
include("menu.jl")

@reexport using .Types
@reexport using .DataLoader
@reexport using .Analyse
@reexport using .Optimisation
@reexport using .Prediction
@reexport using .CarteInteractive
@reexport using .API_REST
@reexport using .Visualisation
@reexport using .Rapports
@reexport using .Accessibilite
@reexport using .Performance
@reexport using .Menu

export initialiser_systeme, lancer_systeme_sotraco

"""
Initialisation du système SOTRACO complet
"""
function initialiser_systeme()
    println("🚀 INITIALISATION DU SYSTÈME SOTRACO")
    println("=" ^ 60)
    println("✨ Fonctionnalités: Prédiction • Carte Interactive • API REST")
    println("=" ^ 60)

    systeme = SystemeSOTRACO()

    try
        println("📊 Chargement des données...")
        systeme.arrets = charger_arrets("data/arrets.csv")
        systeme.lignes = charger_lignes("data/lignes_bus.csv")
        systeme.frequentation = charger_frequentation("data/frequentation.csv")

        associer_arrets_lignes!(systeme)
        configurer_carte_par_defaut!(systeme)

        systeme.donnees_chargees = true

        println("\n✅ Système initialisé avec succès!")
        afficher_resume_initialisation(systeme)

    catch e
        println("❌ Erreur lors du chargement: $e")
        println("🔍 Vérifiez que les fichiers CSV sont dans le dossier data/")
    end

    systeme.donnees_chargees = true

    if !isempty(systeme.frequentation) && length(systeme.lignes) > 0
        try
            println("🔮 Génération des prédictions initiales...")
            predictions_initiales = predire_demande_globale(systeme, 7)
            println("✅ $(length(systeme.predictions)) prédictions générées")
        catch e
            println("⚠️ Erreur génération prédictions: $e")
        end
    end

    return systeme
end

"""
Configuration des paramètres de carte par défaut
"""
function configurer_carte_par_defaut!(systeme::SystemeSOTRACO)
    couleurs_defaut = Dict(
        1 => "#FF6B6B", 2 => "#4ECDC4", 3 => "#45B7D1", 4 => "#96CEB4",
        5 => "#FFEAA7", 6 => "#DDA0DD", 7 => "#98D8C8", 8 => "#F7DC6F",
        9 => "#BB8FCE", 10 => "#85C1E9"
    )

    systeme.config_carte = ConfigurationCarte(
        12.3686,  # Centre Ouagadougou lat
        -1.5275,  # Centre Ouagadougou lon
        12,       # Zoom initial
        true,     # Afficher lignes
        true,     # Afficher arrêts
        true,     # Afficher flux
        couleurs_defaut
    )
end

"""
Association bidirectionnelle arrêts-lignes
"""
function associer_arrets_lignes!(systeme::SystemeSOTRACO)
    for arret in values(systeme.arrets)
        for ligne_id in arret.lignes_desservies
            if haskey(systeme.lignes, ligne_id)
                if !(arret.id in systeme.lignes[ligne_id].arrets)
                    push!(systeme.lignes[ligne_id].arrets, arret.id)
                end
            end
        end
    end
end

"""
Affichage du résumé d'initialisation
"""
function afficher_resume_initialisation(systeme::SystemeSOTRACO)
    println("📋 Résumé de l'initialisation:")
    println("   • Arrêts chargés: $(length(systeme.arrets))")
    println("   • Lignes chargées: $(length(systeme.lignes))")
    println("   • Données fréquentation: $(length(systeme.frequentation))")

    lignes_actives = count(l -> l.statut == "Actif", values(systeme.lignes))
    println("   • Lignes actives: $lignes_actives")

    arrets_equipes = count(a -> a.abribus && a.eclairage, values(systeme.arrets))
    println("   • Arrêts équipés: $arrets_equipes/$(length(systeme.arrets))")

    zones = unique([a.zone for a in values(systeme.arrets)])
    println("   • Zones desservies: $(join(zones, ", "))")

    if !isempty(systeme.frequentation)
        dates = [d.date for d in systeme.frequentation]
        debut = minimum(dates)
        fin = maximum(dates)
        println("   • Période données: du $debut au $fin")
    end

    println("   • Configuration carte: Centre($(systeme.config_carte.centre_lat), $(systeme.config_carte.centre_lon))")
end

"""
Point d'entrée principal du système
"""
function lancer_systeme_sotraco()
    systeme = initialiser_systeme()

    if systeme.donnees_chargees
        gerer_menu_interactif(systeme)
    else
        println("❌ Impossible de lancer le système sans données valides")
    end
end

end # module SOTRACO