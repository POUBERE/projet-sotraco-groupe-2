"""
Module DataLoader - Chargement et validation robuste des données CSV
"""
module DataLoader

using CSV, DataFrames, Dates
using ..Types

export charger_arrets, charger_lignes, charger_frequentation

"""
Charge les données des arrêts depuis un fichier CSV avec validation avancée.
"""
function charger_arrets(chemin_fichier::String)::Dict{Int, Arret}
    println("📍 Chargement des arrêts depuis $chemin_fichier...")

    if !isfile(chemin_fichier)
        error("❌ Fichier $chemin_fichier non trouvé!")
    end

    df = CSV.read(chemin_fichier, DataFrame)
    arrets = Dict{Int, Arret}()

    for row in eachrow(df)
        try
            # Traitement des lignes desservies (format: "1,10" ou "1")
            lignes_str = string(row.lignes_desservies)
            lignes_ids = if occursin(",", lignes_str)
                parse.(Int, split(lignes_str, ","))
            else
                [parse(Int, lignes_str)]
            end

            # Vérification des coordonnées pour Ouagadougou
            lat = Float64(row.latitude)
            lon = Float64(row.longitude)
            if !(11.5 <= lat <= 13.0) || !(-2.5 <= lon <= -0.5)
                println("⚠️  Coordonnées suspectes pour arrêt $(row.id): ($lat, $lon)")
            end

            arret = Arret(
                row.id,
                row.nom_arret,
                row.quartier,
                row.zone,
                lat,
                lon,
                row.abribus == "Oui",
                row.eclairage == "Oui",
                lignes_ids
            )
            arrets[row.id] = arret
        catch e
            println("⚠️  Erreur ligne arrêt $(row.id): $e, ligne ignorée")
        end
    end

    println("✅ $(length(arrets)) arrêts chargés avec validation")
    valider_qualite_arrets(arrets)
    return arrets
end

"""
Charge les données des lignes de bus avec validation métier.
"""
function charger_lignes(chemin_fichier::String)::Dict{Int, LigneBus}
    println("🚌 Chargement des lignes depuis $chemin_fichier...")

    if !isfile(chemin_fichier)
        error("❌ Fichier $chemin_fichier non trouvé!")
    end

    df = CSV.read(chemin_fichier, DataFrame)
    lignes = Dict{Int, LigneBus}()

    for row in eachrow(df)
        try
            distance = Float64(row.distance_km)
            duree = Int(row.duree_trajet_min)
            tarif = Int(row.tarif_fcfa)
            frequence = Int(row.frequence_min)

            # Contrôles de cohérence métier
            if distance <= 0 || distance > 100
                println("⚠️  Distance suspecte ligne $(row.id): $(distance)km")
            end
            if duree <= 0 || duree > 180
                println("⚠️  Durée suspecte ligne $(row.id): $(duree)min")
            end
            if tarif < 50 || tarif > 1000
                println("⚠️  Tarif suspect ligne $(row.id): $(tarif)FCFA")
            end
            if frequence < 5 || frequence > 60
                println("⚠️  Fréquence suspecte ligne $(row.id): $(frequence)min")
            end

            ligne = LigneBus(
                row.id,
                row.nom_ligne,
                row.origine,
                row.destination,
                distance,
                duree,
                tarif,
                frequence,
                row.statut,
                Int[]
            )
            lignes[row.id] = ligne
        catch e
            println("⚠️  Erreur ligne bus $(row.id): $e, ligne ignorée")
        end
    end

    println("✅ $(length(lignes)) lignes chargées avec validation")
    return lignes
end

"""
Charge les données de fréquentation avec parsing robuste.
"""
function charger_frequentation(chemin_fichier::String)::Vector{DonneeFrequentation}
    println("📊 Chargement des données de fréquentation depuis $chemin_fichier...")

    if !isfile(chemin_fichier)
        error("❌ Fichier $chemin_fichier non trouvé!")
    end

    df = CSV.read(chemin_fichier, DataFrame)
    frequentation = DonneeFrequentation[]

    for (idx, row) in enumerate(eachrow(df))
        try
            heure_time = parser_heure_robuste(string(row.heure), idx)
            date_parsed = parser_date_robuste(string(row.date), idx)

            # Nettoyage et validation des valeurs numériques
            montees = max(0, Int(row.montees))
            descentes = max(0, Int(row.descentes))
            occupation = max(0, Int(row.occupation_bus))
            capacite = max(1, Int(row.capacite_bus))

            # Contrôles de cohérence opérationnelle
            if occupation > capacite
                println("⚠️  Surcharge détectée ligne $idx: $occupation/$capacite")
                occupation = capacite
            end

            if montees > 50 || descentes > 50
                println("⚠️  Mouvement suspect ligne $idx: +$montees -$descentes")
            end

            donnee = DonneeFrequentation(
                Int(row.id),
                date_parsed,
                heure_time,
                Int(row.ligne_id),
                Int(row.arret_id),
                montees,
                descentes,
                occupation,
                capacite
            )
            push!(frequentation, donnee)

        catch e
            println("⚠️  Erreur ligne $idx: $e, ligne ignorée")
            continue
        end
    end

    println("✅ $(length(frequentation)) enregistrements de fréquentation chargés")
    afficher_statistiques_frequentation(frequentation)
    return frequentation
end

"""
Parse une chaîne d'heure avec gestion robuste des formats.
"""
function parser_heure_robuste(heure_str::String, ligne_idx::Int)::Time
    try
        # Gestion du format standard HH:MM
        if occursin(":", heure_str)
            return Time(heure_str)
        # Gestion du format numérique simple
        elseif length(heure_str) <= 2
            heure_int = parse(Int, heure_str)
            if 0 <= heure_int <= 23
                return Time(heure_int, 0, 0)
            else
                throw(ArgumentError("Heure invalide: $heure_int"))
            end
        else
            return Time(heure_str)
        end
    catch e
        println("⚠️  Erreur heure ligne $ligne_idx: $heure_str, utilisation 12:00 par défaut")
        return Time(12, 0, 0)
    end
end

"""
Parse une chaîne de date avec gestion robuste des formats.
"""
function parser_date_robuste(date_str::String, ligne_idx::Int)::Date
    try
        return Date(date_str)
    catch e
        println("⚠️  Erreur date ligne $ligne_idx: $date_str, utilisation 2024-01-01 par défaut")
        return Date("2024-01-01")
    end
end

"""
Valide la qualité des données d'arrêts chargées.
"""
function valider_qualite_arrets(arrets::Dict{Int, Arret})
    arrets_equipes = count(a -> a.abribus && a.eclairage, values(arrets))
    arrets_non_equipes = count(a -> !a.abribus && !a.eclairage, values(arrets))
    
    println("📋 Qualité des arrêts:")
    println("   • Entièrement équipés: $arrets_equipes")
    println("   • Non équipés: $arrets_non_equipes")
    
    # Analyse de la répartition géographique
    zones = Dict{String, Int}()
    for arret in values(arrets)
        zones[arret.zone] = get(zones, arret.zone, 0) + 1
    end
    
    println("   • Zones couvertes: $(length(zones))")
    for (zone, nb) in sort(collect(zones))
        println("     - $zone: $nb arrêts")
    end
end

"""
Affiche des statistiques sur les données de fréquentation.
"""
function afficher_statistiques_frequentation(frequentation::Vector{DonneeFrequentation})
    if isempty(frequentation)
        return
    end
    
    total_montees = sum(d.montees for d in frequentation)
    total_descentes = sum(d.descentes for d in frequentation)
    
    # Calcul de la période couverte
    dates = [d.date for d in frequentation]
    periode_debut = minimum(dates)
    periode_fin = maximum(dates)
    
    lignes_uniques = unique([d.ligne_id for d in frequentation])
    
    println("📈 Statistiques de fréquentation:")
    println("   • Période: du $periode_debut au $periode_fin")
    println("   • Total montées: $total_montees")
    println("   • Total descentes: $total_descentes")
    println("   • Lignes avec données: $(length(lignes_uniques))")
    println("   • Moyenne/jour: $(round((total_montees + total_descentes) / max(1, (periode_fin - periode_debut).value + 1), digits=0))")
end

end # module DataLoader