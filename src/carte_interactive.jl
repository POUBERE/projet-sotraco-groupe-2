"""
Module CarteInteractive - Génération de cartes interactives avancées pour SOTRACO
"""
module CarteInteractive

using JSON3, Printf, Statistics, Dates
using ..Types

export generer_carte_interactive, exporter_donnees_geojson, personnaliser_carte
export generer_carte_temps_reel, generer_carte_analytique
export preparer_donnees_arrets_enrichies, preparer_donnees_lignes_enrichies

"""
Génère une carte interactive HTML sophistiquée du réseau SOTRACO.
"""
function generer_carte_interactive(systeme::SystemeSOTRACO, chemin_sortie::String="web/carte_interactive.html")
    println("🗺️ GÉNÉRATION CARTE INTERACTIVE AVANCÉE")
    println("=" ^ 50)

    if !systeme.donnees_chargees
        println("❌ Données non chargées! Impossible de générer la carte.")
        return ""
    end

    if isempty(systeme.arrets)
        println("❌ Aucun arrêt trouvé! Vérifiez les données.")
        return ""
    end

    try
        mkpath(dirname(chemin_sortie))

        donnees_arrets = preparer_donnees_arrets_enrichies(systeme)
        donnees_lignes = preparer_donnees_lignes_enrichies(systeme)
        donnees_analytics = calculer_analytics_carte(systeme)
        donnees_heatmap = generer_donnees_heatmap(systeme)

        html_carte = creer_carte_html_avancee(
            donnees_arrets, donnees_lignes, donnees_analytics, donnees_heatmap, systeme.config_carte
        )

        open(chemin_sortie, "w") do file
            write(file, html_carte)
        end

        println("✅ Carte interactive avancée générée: $chemin_sortie")
        afficher_fonctionnalites_carte()

        return chemin_sortie

    catch e
        println("❌ Erreur génération carte: $e")
        return ""
    end
end

"""
Prépare les données d'arrêts avec enrichissements avancés.
"""
function preparer_donnees_arrets_enrichies(systeme::SystemeSOTRACO)
    arrets_data = []
    
    for arret in values(systeme.arrets)
        freq_arret = [d for d in systeme.frequentation if d.arret_id == arret.id]

        # Calcul des métriques de performance
        total_passagers = isempty(freq_arret) ? 0 : sum(d.montees + d.descentes for d in freq_arret)
        freq_moyenne = isempty(freq_arret) ? 0.0 : total_passagers / length(freq_arret)

        score_importance = calculer_score_importance_arret(arret, freq_arret, systeme)

        # Intégration des prédictions
        predictions_arret = [p for p in systeme.predictions if p.arret_id == arret.id]
        demande_future = isempty(predictions_arret) ? 0.0 : mean([p.demande_prevue for p in predictions_arret])

        categorie = classifier_arret(score_importance, total_passagers, arret)

        # Paramètres d'affichage dynamiques
        couleur = determiner_couleur_arret_avancee(categorie, score_importance)
        taille = determiner_taille_marqueur(score_importance, total_passagers)

        push!(arrets_data, Dict(
            "id" => arret.id,
            "nom" => arret.nom,
            "lat" => arret.latitude,
            "lon" => arret.longitude,
            "quartier" => arret.quartier,
            "zone" => arret.zone,
            "lignes" => arret.lignes_desservies,
            "lignes_str" => join(arret.lignes_desservies, ", "),
            "abribus" => arret.abribus,
            "eclairage" => arret.eclairage,
            "total_passagers" => total_passagers,
            "freq_moyenne" => round(freq_moyenne, digits=1),
            "score_importance" => round(score_importance, digits=2),
            "demande_future" => round(demande_future, digits=1),
            "categorie" => categorie,
            "taille" => taille,
            "couleur" => couleur,
            "popup_html" => generer_popup_arret_avance(arret, total_passagers, freq_moyenne, predictions_arret)
        ))
    end

    return arrets_data
end

"""
Calcule un score d'importance pour un arrêt basé sur plusieurs critères.
"""
function calculer_score_importance_arret(arret::Arret, freq_arret::Vector{DonneeFrequentation}, systeme::SystemeSOTRACO)
    score = 0.0

    # Pondération par fréquentation
    total_passagers = isempty(freq_arret) ? 0 : sum(d.montees + d.descentes for d in freq_arret)
    score += min(1.0, total_passagers / 1000.0) * 40

    # Pondération par connectivité
    score += min(1.0, length(arret.lignes_desservies) / 5.0) * 25

    # Bonus équipements
    if arret.abribus && arret.eclairage
        score += 20
    elseif arret.abribus || arret.eclairage
        score += 10
    end

    # Bonus centralité
    if arret.zone == "Zone 1" || occursin("Centre", arret.quartier)
        score += 15
    end

    return score
end

"""
Classifie un arrêt selon son importance stratégique.
"""
function classifier_arret(score_importance::Float64, total_passagers::Int, arret::Arret)
    if score_importance >= 80 || total_passagers >= 800
        return "hub_majeur"
    elseif score_importance >= 60 || total_passagers >= 400
        return "station_importante"
    elseif score_importance >= 40 || total_passagers >= 200
        return "arret_standard"
    else
        return "arret_secondaire"
    end
end

"""
Détermine la couleur d'un arrêt selon sa catégorie.
"""
function determiner_couleur_arret_avancee(categorie::String, score::Float64)
    base_colors = Dict(
        "hub_majeur" => "#8B0000",
        "station_importante" => "#FF4500",
        "arret_standard" => "#32CD32",
        "arret_secondaire" => "#4169E1"
    )
    return get(base_colors, categorie, "#808080")
end

"""
Détermine la taille du marqueur selon l'importance.
"""
function determiner_taille_marqueur(score::Float64, total_passagers::Int)
    if score >= 80 || total_passagers >= 800
        return 15
    elseif score >= 60 || total_passagers >= 400
        return 12
    elseif score >= 40 || total_passagers >= 200
        return 10
    else
        return 8
    end
end

"""
Génère un popup HTML avancé pour un arrêt.
"""
function generer_popup_arret_avance(arret::Arret, total_passagers::Int, freq_moyenne::Float64, predictions::Vector{PredictionDemande})
    # Sélection d'icône contextuelle
    icone = if arret.abribus && arret.eclairage
        "🚏"
    elseif total_passagers > 500
        "🚌"
    else
        "📍"
    end

    # Indicateur de performance
    statut = if total_passagers > 500
        "<span style='color: #e74c3c;'>🔴 Forte demande</span>"
    elseif total_passagers > 200
        "<span style='color: #f39c12;'>🟡 Demande modérée</span>"
    else
        "<span style='color: #27ae60;'>🟢 Demande faible</span>"
    end

    # Section prédictions si disponibles
    pred_text = if !isempty(predictions)
        demande_future = round(mean([p.demande_prevue for p in predictions]), digits=1)
        "<div><strong>Prédiction:</strong> $demande_future passagers/jour</div>"
    else
        ""
    end

    return """
    <div style="font-family: Arial, sans-serif; min-width: 280px; max-width: 350px;">
        <h3 style="margin: 0 0 12px 0; color: #2c3e50; font-size: 1.2em; border-bottom: 2px solid #3498db; padding-bottom: 5px;">
            $icone $(arret.nom)
        </h3>

        <div style="background: #ecf0f1; padding: 8px; border-radius: 5px; margin-bottom: 10px;">
            <div><strong>📍 Zone:</strong> $(arret.zone)</div>
            <div><strong>🏘️ Quartier:</strong> $(arret.quartier)</div>
            <div><strong>🚌 Lignes:</strong> $(join(arret.lignes_desservies, ", "))</div>
        </div>

        <div style="margin-bottom: 10px;">
            <div><strong>👥 Total passagers:</strong> $total_passagers</div>
            <div><strong>📊 Moyenne/mesure:</strong> $(round(freq_moyenne, digits=1))</div>
            <div><strong>📈 Statut:</strong> $statut</div>
        </div>

        <div style="background: #e8f5e8; padding: 8px; border-radius: 5px; margin-bottom: 10px;">
            <div><strong>🏠 Abribus:</strong>
                <span style="color: $(arret.abribus ? "#27ae60" : "#e74c3c");">
                    $(arret.abribus ? "✓ Oui" : "✗ Non")
                </span>
            </div>
            <div><strong>💡 Éclairage:</strong>
                <span style="color: $(arret.eclairage ? "#27ae60" : "#e74c3c");">
                    $(arret.eclairage ? "✓ Oui" : "✗ Non")
                </span>
            </div>
        </div>

        $pred_text

        <div style="margin-top: 12px; text-align: center;">
            <button onclick="voirAnalyseDetaillee($(arret.id))"
                    style="background: #3498db; color: white; border: none;
                           padding: 8px 16px; border-radius: 20px; cursor: pointer;
                           font-size: 0.9em; transition: all 0.3s;"
                    onmouseover="this.style.background='#2980b9'"
                    onmouseout="this.style.background='#3498db'">
                📊 Analyse détaillée
            </button>
        </div>
    </div>
    """
end

"""
Prépare les données des lignes avec informations enrichies.
"""
function preparer_donnees_lignes_enrichies(systeme::SystemeSOTRACO)
    lignes_data = []

    for ligne in values(systeme.lignes)
        if ligne.statut != "Actif"
            continue
        end

        # Construction du tracé géographique
        coords_ligne = []
        arrets_ligne = []

        for arret_id in ligne.arrets
            if haskey(systeme.arrets, arret_id)
                arret = systeme.arrets[arret_id]
                push!(coords_ligne, [arret.latitude, arret.longitude])
                push!(arrets_ligne, arret.nom)
            end
        end

        if length(coords_ligne) >= 2
            freq_ligne = [d for d in systeme.frequentation if d.ligne_id == ligne.id]

            occupation_moyenne, total_passagers, efficacite = calculer_metriques_ligne_avancees(freq_ligne)

            performance_classe = classifier_performance_ligne(occupation_moyenne, total_passagers, efficacite)

            # Configuration visuelle adaptative
            couleur_ligne, largeur_ligne, opacite = determiner_style_ligne(performance_classe, occupation_moyenne)

            heures_pointe = identifier_heures_pointe_ligne(freq_ligne)

            push!(lignes_data, Dict(
                "id" => ligne.id,
                "nom" => ligne.nom,
                "origine" => ligne.origine,
                "destination" => ligne.destination,
                "distance_km" => ligne.distance_km,
                "frequence_min" => ligne.frequence_min,
                "tarif_fcfa" => ligne.tarif_fcfa,
                "coordonnees" => coords_ligne,
                "arrets" => arrets_ligne,
                "couleur" => couleur_ligne,
                "largeur" => largeur_ligne,
                "opacite" => opacite,
                "occupation" => round(occupation_moyenne * 100, digits=1),
                "total_passagers" => total_passagers,
                "efficacite" => round(efficacite, digits=2),
                "performance_classe" => performance_classe,
                "heures_pointe" => heures_pointe,
                "statut" => ligne.statut,
                "popup_html" => generer_popup_ligne_avance(ligne, occupation_moyenne, total_passagers, efficacite, heures_pointe)
            ))
        end
    end

    return lignes_data
end

"""
Calcule les métriques avancées d'une ligne.
"""
function calculer_metriques_ligne_avancees(freq_ligne::Vector{DonneeFrequentation})
    if isempty(freq_ligne)
        return (0.5, 0, 0.0)
    end

    taux_occ = [d.occupation_bus / d.capacite_bus for d in freq_ligne if d.capacite_bus > 0]
    occupation_moyenne = isempty(taux_occ) ? 0.5 : Statistics.mean(taux_occ)

    total_passagers = sum(d.montees + d.descentes for d in freq_ligne)

    # Calcul d'efficacité normalisée
    jours_donnees = length(unique([d.date for d in freq_ligne]))
    passagers_par_jour = total_passagers / max(1, jours_donnees)
    efficacite = passagers_par_jour / 100.0

    return (occupation_moyenne, total_passagers, efficacite)
end

"""
Classifie la performance d'une ligne selon un score composite.
"""
function classifier_performance_ligne(occupation::Float64, total_passagers::Int, efficacite::Float64)
    score_perf = (occupation * 0.4 + min(1.0, total_passagers/1000) * 0.4 + min(1.0, efficacite) * 0.2)

    if score_perf >= 0.8
        return "excellent"
    elseif score_perf >= 0.6
        return "bon"
    elseif score_perf >= 0.4
        return "moyen"
    else
        return "faible"
    end
end

"""
Détermine le style visuel d'une ligne selon sa performance.
"""
function determiner_style_ligne(performance_classe::String, occupation::Float64)
    styles = Dict(
        "excellent" => ("#2E8B57", 6, 0.9),
        "bon" => ("#32CD32", 5, 0.8),
        "moyen" => ("#FFD700", 4, 0.7),
        "faible" => ("#FF6347", 3, 0.6)
    )

    return styles[performance_classe]
end

"""
Identifie les heures de pointe d'une ligne.
"""
function identifier_heures_pointe_ligne(freq_ligne::Vector{DonneeFrequentation})
    if isempty(freq_ligne)
        return [7, 18]
    end

    freq_par_heure = Dict{Int, Int}()
    for d in freq_ligne
        heure = Dates.hour(d.heure)
        freq_par_heure[heure] = get(freq_par_heure, heure, 0) + d.montees + d.descentes
    end

    heures_triees = sort(collect(freq_par_heure), by=x->x[2], rev=true)
    return [h for (h, f) in heures_triees[1:min(2, length(heures_triees))]]
end

"""
Génère un popup HTML avancé pour une ligne.
"""
function generer_popup_ligne_avance(ligne::LigneBus, occupation::Float64, total_passagers::Int, efficacite::Float64, heures_pointe::Vector{Int})
    # Indicateur visuel de performance
    icone = if occupation > 0.8
        "🔴"
    elseif occupation > 0.6
        "🟡"
    else
        "🟢"
    end

    couleur_statut = if occupation > 0.85
        "#e74c3c"
    elseif occupation > 0.65
        "#f39c12"
    else
        "#27ae60"
    end

    return """
    <div style='font-family: Arial, sans-serif; min-width: 320px; max-width: 400px;'>
        <h3 style='margin: 0 0 15px 0; color: #2c3e50; font-size: 1.3em; border-bottom: 3px solid #3498db; padding-bottom: 8px;'>
            $icone $(ligne.nom)
        </h3>

        <div style='background: linear-gradient(135deg, #f8f9fa, #e9ecef); padding: 12px; border-radius: 8px; margin-bottom: 12px;'>
            <div style='margin-bottom: 6px;'><strong>🚩 Origine:</strong> $(ligne.origine)</div>
            <div style='margin-bottom: 6px;'><strong>🏁 Destination:</strong> $(ligne.destination)</div>
            <div style='margin-bottom: 6px;'><strong>📏 Distance:</strong> $(ligne.distance_km) km</div>
            <div><strong>💰 Tarif:</strong> $(ligne.tarif_fcfa) FCFA</div>
        </div>

        <div style='background: #fff; border: 2px solid $couleur_statut; border-radius: 8px; padding: 12px; margin-bottom: 12px;'>
            <div style='text-align: center; margin-bottom: 8px;'>
                <strong style='color: $couleur_statut; font-size: 1.1em;'>PERFORMANCE</strong>
            </div>
            <div style='margin-bottom: 6px;'><strong>📊 Occupation:</strong> $(round(occupation * 100, digits=1))%</div>
            <div style='margin-bottom: 6px;'><strong>👥 Total passagers:</strong> $total_passagers</div>
            <div style='margin-bottom: 6px;'><strong>⚡ Efficacité:</strong> $(round(efficacite, digits=2))</div>
            <div><strong>⏰ Fréquence:</strong> $(ligne.frequence_min) min</div>
        </div>

        <div style='background: #e8f5e8; padding: 10px; border-radius: 6px; margin-bottom: 12px;'>
            <div><strong>🔥 Heures de pointe:</strong> $(join(heures_pointe, "h, "))h</div>
            <div><strong>⏱️ Durée trajet:</strong> $(ligne.duree_trajet_min) min</div>
        </div>

        <div style='margin-top: 15px; text-align: center;'>
            <button onclick='analyserLigneDetaille($(ligne.id))'
                    style='background: linear-gradient(135deg, #3498db, #2980b9); color: white; border: none;
                           padding: 10px 20px; border-radius: 25px; cursor: pointer; margin-right: 8px;
                           font-size: 0.9em; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.3s;'
                    onmouseover='this.style.transform="translateY(-2px)"'
                    onmouseout='this.style.transform="translateY(0px)"'>
                📈 Analyser
            </button>
            <button onclick='optimiserLigne($(ligne.id))'
                    style='background: linear-gradient(135deg, #e74c3c, #c0392b); color: white; border: none;
                           padding: 10px 20px; border-radius: 25px; cursor: pointer;
                           font-size: 0.9em; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.3s;'
                    onmouseover='this.style.transform="translateY(-2px)"'
                    onmouseout='this.style.transform="translateY(0px)"'>
                🚀 Optimiser
            </button>
        </div>
    </div>
    """
end

"""
Calcule les analytics pour la carte.
"""
function calculer_analytics_carte(systeme::SystemeSOTRACO)
    analytics = Dict{String, Any}()

    analytics["total_arrets"] = length(systeme.arrets)
    analytics["total_lignes"] = length(systeme.lignes)
    analytics["lignes_actives"] = count(l -> l.statut == "Actif", values(systeme.lignes))

    # Métriques d'équipement
    analytics["arrets_equipes"] = count(a -> a.abribus && a.eclairage, values(systeme.arrets))
    analytics["taux_equipement"] = round(analytics["arrets_equipes"] / max(1, analytics["total_arrets"]) * 100, digits=1)

    # Analyse de fréquentation
    if !isempty(systeme.frequentation)
        analytics["total_passagers"] = sum(d.montees + d.descentes for d in systeme.frequentation)

        taux_valides = [d.occupation_bus/d.capacite_bus for d in systeme.frequentation if d.capacite_bus > 0]
        analytics["taux_occupation_moyen"] = isempty(taux_valides) ? 0.0 : round(Statistics.mean(taux_valides) * 100, digits=1)

        dates_uniques = unique([d.date for d in systeme.frequentation])
        analytics["passagers_par_jour"] = round(analytics["total_passagers"] / length(dates_uniques), digits=0)
    else
        analytics["total_passagers"] = 0
        analytics["taux_occupation_moyen"] = 0.0
        analytics["passagers_par_jour"] = 0
    end

    lignes_actives = [l for l in values(systeme.lignes) if l.statut == "Actif"]
    analytics["distance_totale"] = sum(l.distance_km for l in lignes_actives)

    analytics["nb_predictions"] = length(systeme.predictions)

    return analytics
end

"""
Génère les données pour la heatmap de fréquentation.
"""
function generer_donnees_heatmap(systeme::SystemeSOTRACO)
    heatmap_data = []

    # Agrégation spatiale des données de fréquentation
    freq_par_position = Dict{Tuple{Float64, Float64}, Int}()

    for donnee in systeme.frequentation
        if haskey(systeme.arrets, donnee.arret_id)
            arret = systeme.arrets[donnee.arret_id]
            # Regroupement par coordonnées arrondies
            lat_round = round(arret.latitude, digits=3)
            lon_round = round(arret.longitude, digits=3)
            position = (lat_round, lon_round)

            intensite = donnee.montees + donnee.descentes
            freq_par_position[position] = get(freq_par_position, position, 0) + intensite
        end
    end

    # Conversion au format heatmap
    for ((lat, lon), intensite) in freq_par_position
        if intensite > 0
            push!(heatmap_data, [lat, lon, intensite])
        end
    end

    return heatmap_data
end

"""
Crée le HTML avancé avec toutes les fonctionnalités.
"""
function creer_carte_html_avancee(arrets_data::Vector, lignes_data::Vector, analytics::Dict, heatmap_data::Vector, config::ConfigurationCarte)
    arrets_json = JSON3.write(arrets_data)
    lignes_json = JSON3.write(lignes_data)
    analytics_json = JSON3.write(analytics)
    heatmap_json = JSON3.write(heatmap_data)

    return """
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Carte Interactive SOTRACO - Analyse Avancée</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }

        .header {
            background: linear-gradient(135deg, #2E8B57, #32CD32);
            color: white; padding: 15px; text-align: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .controls-panel {
            background: #f8f9fa; padding: 15px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            display: flex; flex-wrap: wrap; gap: 15px; align-items: center;
        }

        .control-group {
            display: flex; align-items: center; gap: 8px;
            background: white; padding: 8px 12px; border-radius: 20px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .control-group label { font-weight: 500; color: #2c3e50; }
        .control-group input[type="checkbox"] { transform: scale(1.2); }

        .analytics-panel {
            background: linear-gradient(135deg, #ecf0f1, #bdc3c7);
            padding: 10px; display: flex; flex-wrap: wrap; gap: 15px;
            justify-content: center;
        }

        .metric-card {
            background: white; padding: 12px 16px; border-radius: 10px;
            text-align: center; min-width: 120px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .metric-value {
            font-size: 1.8em; font-weight: bold; color: #2E8B57;
            margin-bottom: 4px;
        }

        .metric-label {
            font-size: 0.85em; color: #7f8c8d; text-transform: uppercase;
        }

        #map { height: 600px; }

        .legend {
            position: absolute; bottom: 20px; right: 20px; z-index: 1000;
            background: rgba(255,255,255,0.95); padding: 15px; border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2); font-size: 12px;
        }

        .legend-item {
            display: flex; align-items: center; margin-bottom: 6px;
        }

        .legend-color {
            width: 16px; height: 16px; border-radius: 50%;
            margin-right: 8px; border: 1px solid #ccc;
        }

        .btn {
            background: #3498db; color: white; border: none;
            padding: 8px 16px; border-radius: 20px; cursor: pointer;
            font-size: 0.9em; transition: all 0.3s;
        }

        .btn:hover { background: #2980b9; transform: translateY(-1px); }

        @media (max-width: 768px) {
            .controls-panel { flex-direction: column; }
            .analytics-panel { flex-direction: column; }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚌 Carte Interactive SOTRACO - Analyse Avancée</h1>
        <p>Système d'Optimisation du Transport Public de Ouagadougou</p>
    </div>

    <div class="analytics-panel">
        <div class="metric-card">
            <div class="metric-value" id="metricArrets">$(analytics["total_arrets"])</div>
            <div class="metric-label">Arrêts</div>
        </div>
        <div class="metric-card">
            <div class="metric-value" id="metricLignes">$(analytics["lignes_actives"])</div>
            <div class="metric-label">Lignes Actives</div>
        </div>
        <div class="metric-card">
            <div class="metric-value" id="metricPassagers">$(analytics["passagers_par_jour"])</div>
            <div class="metric-label">Pass./Jour</div>
        </div>
        <div class="metric-card">
            <div class="metric-value" id="metricOccupation">$(analytics["taux_occupation_moyen"])%</div>
            <div class="metric-label">Occupation</div>
        </div>
        <div class="metric-card">
            <div class="metric-value" id="metricEquipement">$(analytics["taux_equipement"])%</div>
            <div class="metric-label">Équipés</div>
        </div>
    </div>

    <div class="controls-panel">
        <div class="control-group">
            <label><input type="checkbox" id="showArrets" checked> 📍 Arrêts</label>
        </div>
        <div class="control-group">
            <label><input type="checkbox" id="showLignes" checked> 🚌 Lignes</label>
        </div>
        <div class="control-group">
            <label><input type="checkbox" id="showHeatmap"> 🔥 Heatmap</label>
        </div>
        <div class="control-group">
            <label>Filtre ligne:
                <select id="filtreligne">
                    <option value="">Toutes les lignes</option>
                </select>
            </label>
        </div>
        <div class="control-group">
            <button class="btn" onclick="centrerCarte()">🎯 Centrer</button>
            <button class="btn" onclick="toggleFullscreen()">⛶ Plein écran</button>
            <button class="btn" onclick="exporterDonnees()">💾 Exporter</button>
        </div>
    </div>

    <div id="map"></div>

    <div class="legend">
        <h4 style="margin-bottom: 10px; color: #2c3e50;">🗂️ Légende</h4>
        <div class="legend-item">
            <div class="legend-color" style="background: #8B0000;"></div>
            <span>Hub majeur (>800 pass.)</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background: #FF4500;"></div>
            <span>Station importante (400-800)</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background: #32CD32;"></div>
            <span>Arrêt standard (200-400)</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background: #4169E1;"></div>
            <span>Arrêt secondaire (&lt;200)</span>
        </div>
    </div>

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        // Données du système
        const arretsData = $arrets_json;
        const lignesData = $lignes_json;
        const analyticsData = $analytics_json;
        const heatmapData = $heatmap_json;

        // Initialisation de la carte
        const map = L.map('map').setView([$(config.centre_lat), $(config.centre_lon)], $(config.zoom_initial));

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors | SOTRACO Analytics'
        }).addTo(map);

        // Couches de données
        const arretsLayer = L.layerGroup().addTo(map);
        const lignesLayer = L.layerGroup().addTo(map);
        let heatmapLayer = null;

        // Chargement des arrêts
        function chargerArrets() {
            arretsLayer.clearLayers();

            arretsData.forEach(arret => {
                const marker = L.circleMarker([arret.lat, arret.lon], {
                    radius: arret.taille,
                    fillColor: arret.couleur,
                    color: '#ffffff',
                    weight: 2,
                    opacity: 1,
                    fillOpacity: 0.8
                }).bindPopup(arret.popup_html, {
                    maxWidth: 400,
                    className: 'custom-popup'
                });

                arretsLayer.addLayer(marker);
            });
        }

        // Chargement des lignes
        function chargerLignes() {
            lignesLayer.clearLayers();

            lignesData.forEach(ligne => {
                if (ligne.coordonnees && ligne.coordonnees.length >= 2) {
                    const polyline = L.polyline(ligne.coordonnees, {
                        color: ligne.couleur,
                        weight: ligne.largeur,
                        opacity: ligne.opacite
                    }).bindPopup(ligne.popup_html, {
                        maxWidth: 450,
                        className: 'custom-popup'
                    });

                    lignesLayer.addLayer(polyline);
                }
            });
        }

        // Gestionnaires d'événements
        document.getElementById('showArrets').addEventListener('change', function(e) {
            if (e.target.checked) {
                map.addLayer(arretsLayer);
            } else {
                map.removeLayer(arretsLayer);
            }
        });

        document.getElementById('showLignes').addEventListener('change', function(e) {
            if (e.target.checked) {
                map.addLayer(lignesLayer);
            } else {
                map.removeLayer(lignesLayer);
            }
        });

        // Fonctions utilitaires
        function centrerCarte() {
            map.setView([$(config.centre_lat), $(config.centre_lon)], $(config.zoom_initial));
        }

        function toggleFullscreen() {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
            } else {
                document.exitFullscreen();
            }
        }

        function exporterDonnees() {
            const data = {
                arrets: arretsData,
                lignes: lignesData,
                analytics: analyticsData,
                timestamp: new Date().toISOString()
            };

            const blob = new Blob([JSON.stringify(data, null, 2)], {type: 'application/json'});
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'sotraco_donnees_' + new Date().toISOString().split('T')[0] + '.json';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }

        // Fonctions pour les popups
        window.voirAnalyseDetaillee = function(arretId) {
            alert('Analyse détaillée arrêt ' + arretId + ' - Fonctionnalité à implémenter');
        };

        window.analyserLigneDetaille = function(ligneId) {
            alert('Analyse détaillée ligne ' + ligneId + ' - Fonctionnalité à implémenter');
        };

        window.optimiserLigne = function(ligneId) {
            alert('Optimisation ligne ' + ligneId + ' - Fonctionnalité à implémenter');
        };

        // Initialisation
        chargerArrets();
        chargerLignes();

        console.log('Carte SOTRACO avancée chargée:', arretsData.length, 'arrêts,', lignesData.length, 'lignes');
    </script>
</body>
</html>
    """
end

"""
Affiche les fonctionnalités de la carte générée.
"""
function afficher_fonctionnalites_carte()
    println("\n🎯 FONCTIONNALITÉS DE LA CARTE INTERACTIVE:")
    println("   ✨ Arrêts avec classification intelligente")
    println("   📊 Analytics en temps réel")
    println("   🎮 Contrôles interactifs avancés")
    println("   📱 Interface responsive")
    println("   💾 Export de données intégré")
    println("   🖼️ Mode plein écran")
    println("   📈 Métriques de performance")
end

"""
Exporte les données au format GeoJSON standard.
"""
function exporter_donnees_geojson(systeme::SystemeSOTRACO, chemin_sortie::String="resultats/reseau_sotraco.geojson")
    println("📍 EXPORT GEOJSON PROFESSIONNEL")
    println("=" ^ 40)

    mkpath(dirname(chemin_sortie))

    geojson = Dict(
        "type" => "FeatureCollection",
        "name" => "Réseau SOTRACO Ouagadougou",
        "crs" => Dict(
            "type" => "name",
            "properties" => Dict("name" => "EPSG:4326")
        ),
        "features" => []
    )

    # Export des arrêts au format Point
    for arret in values(systeme.arrets)
        freq_arret = [d for d in systeme.frequentation if d.arret_id == arret.id]
        total_passagers = isempty(freq_arret) ? 0 : sum(d.montees + d.descentes for d in freq_arret)

        feature = Dict(
            "type" => "Feature",
            "geometry" => Dict(
                "type" => "Point",
                "coordinates" => [arret.longitude, arret.latitude]
            ),
            "properties" => Dict(
                "id" => arret.id,
                "nom" => arret.nom,
                "quartier" => arret.quartier,
                "zone" => arret.zone,
                "abribus" => arret.abribus,
                "eclairage" => arret.eclairage,
                "lignes_desservies" => arret.lignes_desservies,
                "total_passagers" => total_passagers,
                "type" => "arret",
                "score_importance" => calculer_score_importance_arret(arret, freq_arret, systeme)
            )
        )
        push!(geojson["features"], feature)
    end

    # Export des lignes au format LineString
    for ligne in values(systeme.lignes)
        if ligne.statut == "Actif" && !isempty(ligne.arrets)
            coords = []
            for arret_id in ligne.arrets
                if haskey(systeme.arrets, arret_id)
                    arret = systeme.arrets[arret_id]
                    push!(coords, [arret.longitude, arret.latitude])
                end
            end

            if length(coords) >= 2
                feature = Dict(
                    "type" => "Feature",
                    "geometry" => Dict(
                        "type" => "LineString",
                        "coordinates" => coords
                    ),
                    "properties" => Dict(
                        "id" => ligne.id,
                        "nom" => ligne.nom,
                        "origine" => ligne.origine,
                        "destination" => ligne.destination,
                        "distance_km" => ligne.distance_km,
                        "frequence_min" => ligne.frequence_min,
                        "tarif_fcfa" => ligne.tarif_fcfa,
                        "statut" => ligne.statut,
                        "type" => "ligne"
                    )
                )
                push!(geojson["features"], feature)
            end
        end
    end

    open(chemin_sortie, "w") do file
        JSON3.pretty(file, geojson)
    end

    println("✅ Export GeoJSON terminé: $chemin_sortie")
    println("   • $(count(f -> f["properties"]["type"] == "arret", geojson["features"])) arrêts exportés")
    println("   • $(count(f -> f["properties"]["type"] == "ligne", geojson["features"])) lignes exportées")

    return chemin_sortie
end

"""
Personnalise les paramètres d'affichage de la carte.
"""
function personnaliser_carte(systeme::SystemeSOTRACO; zoom::Int=12, centre_lat::Float64=12.3686, centre_lon::Float64=-1.5275, couleurs_personnalisees::Dict{Int, String}=Dict{Int, String}())
    # Validation des paramètres d'affichage
    if !(8 <= zoom <= 18)
        println("⚠️ Zoom ajusté à la plage 8-18")
        zoom = max(8, min(18, zoom))
    end

    couleurs_finales = merge(systeme.config_carte.couleurs_lignes, couleurs_personnalisees)

    systeme.config_carte = ConfigurationCarte(
        centre_lat,
        centre_lon,
        zoom,
        true, true, true,
        couleurs_finales
    )

    println("✅ Configuration mise à jour:")
    println("   • Centre: ($centre_lat, $centre_lon)")
    println("   • Zoom: $zoom")
end

"""
Génère une carte temps réel.
"""
function generer_carte_temps_reel(systeme::SystemeSOTRACO)
    println("⏱️ GÉNÉRATION CARTE TEMPS RÉEL")
    return generer_carte_interactive(systeme, "web/carte_temps_reel.html")
end

"""
Génère une carte analytique.
"""
function generer_carte_analytique(systeme::SystemeSOTRACO)
    println("📊 GÉNÉRATION CARTE ANALYTIQUE")
    return generer_carte_interactive(systeme, "web/carte_analytique.html")
end

end # module CarteInteractive