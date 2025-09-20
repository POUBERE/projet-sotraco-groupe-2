"""
Module Types - Définition des structures de données SOTRACO
"""
module Types

using Dates
export Arret, LigneBus, DonneeFrequentation, SystemeSOTRACO
export PredictionDemande, ConfigurationCarte, APIResponse

"""
Structure représentant un arrêt de bus du réseau SOTRACO
"""
struct Arret
    id::Int
    nom::String
    quartier::String
    zone::String
    latitude::Float64
    longitude::Float64
    abribus::Bool
    eclairage::Bool
    lignes_desservies::Vector{Int}
end

"""
Structure représentant une ligne de bus du réseau SOTRACO
"""
struct LigneBus
    id::Int
    nom::String
    origine::String
    destination::String
    distance_km::Float64
    duree_trajet_min::Int
    tarif_fcfa::Int
    frequence_min::Int
    statut::String
    arrets::Vector{Int}
end

"""
Structure pour les données de fréquentation
"""
struct DonneeFrequentation
    id::Int
    date::Date
    heure::Time
    ligne_id::Int
    arret_id::Int
    montees::Int
    descentes::Int
    occupation_bus::Int
    capacite_bus::Int
end

"""
Structure pour les prédictions de demande
"""
struct PredictionDemande
    ligne_id::Int
    arret_id::Int
    date_prediction::Date
    heure_prediction::Time
    demande_prevue::Float64
    intervalle_confiance::Tuple{Float64, Float64}
    facteurs_influents::Dict{String, Float64}
end

"""
Configuration de la carte interactive
"""
struct ConfigurationCarte
    centre_lat::Float64
    centre_lon::Float64
    zoom_initial::Int
    afficher_lignes::Bool
    afficher_arrets::Bool
    afficher_flux::Bool
    couleurs_lignes::Dict{Int, String}
end

"""
Structure de réponse pour l'API REST
"""
struct APIResponse{T}
    success::Bool
    data::T
    message::String
    timestamp::DateTime
    version::String
end

"""
Système principal contenant toutes les données SOTRACO
"""
mutable struct SystemeSOTRACO
    arrets::Dict{Int, Arret}
    lignes::Dict{Int, LigneBus}
    frequentation::Vector{DonneeFrequentation}
    predictions::Vector{PredictionDemande}
    config_carte::ConfigurationCarte
    donnees_chargees::Bool
    api_active::Bool
end

function SystemeSOTRACO()
    return SystemeSOTRACO(
        Dict{Int, Arret}(),
        Dict{Int, LigneBus}(),
        DonneeFrequentation[],
        PredictionDemande[],
        ConfigurationCarte(12.3686, -1.5275, 12, true, true, true, Dict{Int, String}()),
        false,
        false
    )
end

end # module Types