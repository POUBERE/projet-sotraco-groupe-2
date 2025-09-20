"""
Module Analyse - Analyses statistiques avancées avec insights métier pour SOTRACO
"""
module Analyse

using Statistics, DataFrames, Dates
using ..Types

export analyser_frequentation_globale, identifier_heures_pointe, analyser_taux_occupation
export analyser_performance_lignes, detecter_anomalies, generer_insights_metier

"""
Analyse complète de la fréquentation du réseau SOTRACO avec insights avancés.
"""
function analyser_frequentation_globale(systeme::SystemeSOTRACO)
    println("\n📈 ANALYSE COMPLÈTE DE LA FRÉQUENTATION SOTRACO")
    println("=" ^ 60)

    if !systeme.donnees_chargees || isempty(systeme.frequentation)
        println("❌ Données non chargées ou insuffisantes!")
        return
    end

    analyser_statistiques_generales(systeme)
    analyser_patterns_temporels(systeme)
    analyser_performance_par_ligne(systeme)
    detecter_anomalies_frequentation(systeme)
    generer_insights_metier(systeme)
end

"""
Analyse les statistiques générales avec métriques avancées.
"""
function analyser_statistiques_generales(systeme::SystemeSOTRACO)
    total_montees = sum(d.montees for d in systeme.frequentation)
    total_descentes = sum(d.descentes for d in systeme.frequentation)
    total_mouvements = total_montees + total_descentes

    jours_uniques = length(unique([d.date for d in systeme.frequentation]))
    mouvements_par_jour = round(total_mouvements / max(1, jours_uniques), digits=0)
    
    # Calcul du taux d'occupation pondéré
    taux_occupation_data = [d.occupation_bus / d.capacite_bus for d in systeme.frequentation if d.capacite_bus > 0]
    taux_occupation_moyen = isempty(taux_occupation_data) ? 0.0 : mean(taux_occupation_data) * 100

    println("📊 Statistiques générales avancées:")
    println("   • Total mouvements: $total_mouvements passagers")
    println("   • Montées: $total_montees | Descentes: $total_descentes")
    println("   • Période analysée: $jours_uniques jours")
    println("   • Moyenne journalière: $mouvements_par_jour mouvements/jour")
    println("   • Taux occupation moyen: $(round(taux_occupation_moyen, digits=1))%")
    
    # Évaluation de la charge du réseau
    if taux_occupation_moyen > 85
        println("   🔴 Alerte: Réseau surchargé (>85%)")
    elseif taux_occupation_moyen > 65
        println("   🟡 Attention: Charge élevée (65-85%)")
    elseif taux_occupation_moyen > 40
        println("   🟢 Bon: Utilisation normale (40-65%)")
    else
        println("   🔵 Info: Sous-utilisation (<40%)")
    end
end

"""
Analyse les patterns temporels avec détection des cycles.
"""
function analyser_patterns_temporels(systeme::SystemeSOTRACO)
    println("\n⏰ ANALYSE DES PATTERNS TEMPORELS")
    println("-" ^ 40)
    
    freq_par_heure = calculer_frequentation_horaire(systeme)
    heures_triees = sort(collect(freq_par_heure), by=x->x[2], rev=true)
    
    println("🔥 Top 5 heures de pointe:")
    for i in 1:min(5, length(heures_triees))
        heure, freq = heures_triees[i]
        pourcentage = round(100 * freq / sum(values(freq_par_heure)), digits=1)
        println("   $i. $(heure)h00: $freq passagers ($pourcentage%)")
    end
    
    analyser_patterns_hebdomadaires(systeme)
    detecter_heures_creuses(freq_par_heure)
end

"""
Analyse les patterns hebdomadaires.
"""
function analyser_patterns_hebdomadaires(systeme::SystemeSOTRACO)
    jours_semaine = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    freq_par_jour = Dict{Int, Int}()
    
    for donnee in systeme.frequentation
        jour = Dates.dayofweek(donnee.date)
        freq_par_jour[jour] = get(freq_par_jour, jour, 0) + donnee.montees + donnee.descentes
    end
    
    if !isempty(freq_par_jour)
        println("\n📅 Fréquentation par jour de semaine:")
        for jour in 1:7
            freq = get(freq_par_jour, jour, 0)
            if freq > 0
                total = sum(values(freq_par_jour))
                pourcentage = round(100 * freq / total, digits=1)
                println("   • $(jours_semaine[jour]): $freq ($pourcentage%)")
            end
        end
        
        # Comparaison weekend versus semaine
        freq_semaine = sum(get(freq_par_jour, j, 0) for j in 1:5)
        freq_weekend = sum(get(freq_par_jour, j, 0) for j in 6:7)
        if freq_weekend > 0
            ratio_weekend = round(freq_weekend / freq_semaine * 100, digits=1)
            println("   📊 Weekend vs Semaine: $(ratio_weekend)% du trafic semaine")
        end
    end
end

"""
Détecte les heures creuses pour optimisation.
"""
function detecter_heures_creuses(freq_par_heure::Dict{Int, Int})
    if isempty(freq_par_heure)
        return
    end
    
    total_freq = sum(values(freq_par_heure))
    seuil_creux = total_freq / length(freq_par_heure) * 0.3
    
    heures_creuses = [h for (h, f) in freq_par_heure if f < seuil_creux]
    
    if !isempty(heures_creuses)
        println("\n🔽 Heures creuses détectées (opportunités d'optimisation):")
        for heure in sort(heures_creuses)
            freq = freq_par_heure[heure]
            println("   • $(heure)h00: seulement $freq passagers")
        end
    end
end

"""
Analyse la performance détaillée par ligne.
"""
function analyser_performance_par_ligne(systeme::SystemeSOTRACO)
    println("\n🚌 ANALYSE DE PERFORMANCE PAR LIGNE")
    println("-" ^ 40)
    
    performance_lignes = Dict{Int, Dict{String, Any}}()
    
    for ligne in values(systeme.lignes)
        if ligne.statut == "Actif"
            donnees_ligne = [d for d in systeme.frequentation if d.ligne_id == ligne.id]
            
            if !isempty(donnees_ligne)
                perf = calculer_metriques_ligne(ligne, donnees_ligne)
                performance_lignes[ligne.id] = perf
            end
        end
    end
    
    afficher_top_performers(performance_lignes, systeme)
end

"""
Calcule les métriques de performance pour une ligne.
"""
function calculer_metriques_ligne(ligne::LigneBus, donnees::Vector{DonneeFrequentation})
    total_passagers = sum(d.montees + d.descentes for d in donnees)
    passagers_par_jour = total_passagers / max(1, length(unique([d.date for d in donnees])))
    
    # Métriques d'occupation
    taux_occ = [d.occupation_bus / d.capacite_bus for d in donnees if d.capacite_bus > 0]
    taux_occupation_moyen = isempty(taux_occ) ? 0.0 : mean(taux_occ) * 100
    
    # Estimation de rentabilité
    recettes_estimees = total_passagers * ligne.tarif_fcfa
    
    # Score composite de performance
    score_performance = (taux_occupation_moyen / 100) * 0.6 + 
                       min(passagers_par_jour / 1000, 1.0) * 0.4
    
    return Dict(
        "total_passagers" => total_passagers,
        "passagers_par_jour" => round(passagers_par_jour, digits=0),
        "taux_occupation" => round(taux_occupation_moyen, digits=1),
        "recettes_estimees" => round(recettes_estimees, digits=0),
        "score_performance" => round(score_performance * 100, digits=1),
        "nom" => ligne.nom
    )
end

"""
Affiche les lignes les plus et moins performantes.
"""
function afficher_top_performers(performance_lignes::Dict, systeme::SystemeSOTRACO)
    if isempty(performance_lignes)
        println("❌ Aucune donnée de performance disponible")
        return
    end
    
    lignes_triees = sort(collect(performance_lignes), by=x->x[2]["score_performance"], rev=true)
    
    println("🏆 Top 3 lignes les plus performantes:")
    for i in 1:min(3, length(lignes_triees))
        ligne_id, perf = lignes_triees[i]
        println("   $i. $(perf["nom"])")
        println("      • Score: $(perf["score_performance"])%")
        println("      • Passagers/jour: $(perf["passagers_par_jour"])")
        println("      • Occupation: $(perf["taux_occupation"])%")
        println("      • Recettes: $(Int(perf["recettes_estimees"])) FCFA")
    end
    
    println("\n⚠️  Bottom 2 lignes à améliorer:")
    for i in max(1, length(lignes_triees)-1):length(lignes_triees)
        ligne_id, perf = lignes_triees[i]
        println("   $(length(lignes_triees)-i+1). $(perf["nom"])")
        println("      • Score: $(perf["score_performance"])% (faible)")
        println("      • Occupation: $(perf["taux_occupation"])%")
        
        # Recommandations d'optimisation
        if perf["taux_occupation"] < 40
            println("      💡 Suggestion: Réduire fréquence ou redistribuer bus")
        elseif perf["taux_occupation"] > 90
            println("      💡 Suggestion: Augmenter fréquence")
        end
    end
end

"""
Calcule la fréquentation par heure.
"""
function calculer_frequentation_horaire(systeme::SystemeSOTRACO)
    freq_par_heure = Dict{Int, Int}()
    for donnee in systeme.frequentation
        heure = Dates.hour(donnee.heure)
        freq_par_heure[heure] = get(freq_par_heure, heure, 0) + donnee.montees + donnee.descentes
    end
    return freq_par_heure
end

"""
Identifie les heures de pointe avec analyse avancée.
"""
function identifier_heures_pointe(systeme::SystemeSOTRACO)
    println("\n⏰ IDENTIFICATION AVANCÉE DES HEURES DE POINTE")
    println("=" ^ 50)

    freq_par_heure = calculer_frequentation_horaire(systeme)
    
    if isempty(freq_par_heure)
        println("❌ Aucune donnée horaire disponible")
        return []
    end
    
    heures_triees = sort(collect(freq_par_heure), by=x->x[2], rev=true)
    total_journalier = sum(values(freq_par_heure))
    
    println("🔥 Classification des heures de pointe:")
    
    # Identification des pics majeurs
    pics_majeurs = [(h, f) for (h, f) in heures_triees if f / total_journalier > 0.10]
    
    if !isempty(pics_majeurs)
        println("\n🚨 PICS MAJEURS (>10% du trafic quotidien):")
        for (heure, freq) in pics_majeurs
            pourcentage = round(100 * freq / total_journalier, digits=1)
            println("   • $(heure)h00: $freq passagers ($pourcentage%)")
        end
    end
    
    generer_recommandations_pointe(pics_majeurs, total_journalier)
    
    return heures_triees
end

"""
Génère des recommandations basées sur l'analyse des heures de pointe.
"""
function generer_recommandations_pointe(pics_majeurs::Vector, total_journalier::Int)
    if isempty(pics_majeurs)
        return
    end
    
    println("\n💡 RECOMMANDATIONS OPÉRATIONNELLES:")
    
    heures_pic = [h for (h, f) in pics_majeurs]
    
    # Stratégies selon les créneaux
    pics_matin = count(h -> 6 <= h <= 10, heures_pic)
    pics_soir = count(h -> 16 <= h <= 20, heures_pic)
    
    if pics_matin > 0
        println("   🌅 Renforcement matinal recommandé (6h-10h)")
        println("      • Augmenter fréquence de 25-30%")
        println("      • Anticiper l'offre dès 5h30")
    end
    
    if pics_soir > 0
        println("   🌆 Renforcement vespéral recommandé (16h-20h)")
        println("      • Maintenir service renforcé jusqu'à 20h30")
        println("      • Bus express vers zones résidentielles")
    end
    
    # Évaluation de l'intensité des pics
    charge_pics = sum(f for (h, f) in pics_majeurs)
    pourcentage_pics = round(100 * charge_pics / total_journalier, digits=1)
    
    if pourcentage_pics > 40
        println("   ⚡ Concentration élevée: $pourcentage_pics% du trafic sur $(length(pics_majeurs)) heures")
        println("      • Envisager buses articulés aux heures de pointe")
        println("      • Système de régulation en temps réel")
    end
end

"""
Analyse le taux d'occupation avec segmentation avancée.
"""
function analyser_taux_occupation(systeme::SystemeSOTRACO)
    println("\n🎯 ANALYSE AVANCÉE DU TAUX D'OCCUPATION")
    println("=" ^ 50)

    taux_occupation = calculer_taux_occupation_detaille(systeme)

    if isempty(taux_occupation)
        println("❌ Aucune donnée d'occupation disponible")
        return
    end

    afficher_statistiques_occupation(taux_occupation)
    segmenter_occupation(taux_occupation)
    analyser_occupation_par_ligne(systeme)
    detecter_problemes_critiques(taux_occupation, systeme)
end

"""
Calcule des taux d'occupation détaillés.
"""
function calculer_taux_occupation_detaille(systeme::SystemeSOTRACO)
    taux_occupation = []
    
    for donnee in systeme.frequentation
        if donnee.capacite_bus > 0
            taux = (donnee.occupation_bus / donnee.capacite_bus) * 100
            push!(taux_occupation, Dict(
                "taux" => taux,
                "ligne_id" => donnee.ligne_id,
                "heure" => Dates.hour(donnee.heure),
                "jour" => Dates.dayofweek(donnee.date)
            ))
        end
    end
    
    return taux_occupation
end

"""
Affiche les statistiques descriptives d'occupation.
"""
function afficher_statistiques_occupation(taux_occupation::Vector)
    taux_simples = [d["taux"] for d in taux_occupation]
    
    println("📊 Statistiques descriptives:")
    println("   • Taux moyen: $(round(mean(taux_simples), digits=1))%")
    println("   • Taux médian: $(round(median(taux_simples), digits=1))%")
    println("   • Taux maximum: $(round(maximum(taux_simples), digits=1))%")
    println("   • Taux minimum: $(round(minimum(taux_simples), digits=1))%")
    println("   • Écart-type: $(round(std(taux_simples), digits=1))%")
end

"""
Segmente l'occupation par tranches d'utilisation.
"""
function segmenter_occupation(taux_occupation::Vector)
    total = length(taux_occupation)
    
    surchargés = count(d -> d["taux"] > 90, taux_occupation)
    optimaux = count(d -> 65 <= d["taux"] <= 90, taux_occupation)
    normaux = count(d -> 40 <= d["taux"] < 65, taux_occupation)
    sous_utilisés = count(d -> d["taux"] < 40, taux_occupation)

    println("\n📈 Segmentation de l'utilisation:")
    println("   🔴 Surchargés (>90%): $surchargés ($(round(100*surchargés/total, digits=1))%)")
    println("   🟠 Optimaux (65-90%): $optimaux ($(round(100*optimaux/total, digits=1))%)")
    println("   🟡 Normaux (40-65%): $normaux ($(round(100*normaux/total, digits=1))%)")
    println("   🔵 Sous-utilisés (<40%): $sous_utilisés ($(round(100*sous_utilisés/total, digits=1))%)")
    
    # Alertes et opportunités
    if surchargés / total > 0.15
        println("\n⚠️  ALERTE: Plus de 15% des trajets surchargés")
        println("   💡 Actions urgentes: redistribution de flotte nécessaire")
    end
    
    if sous_utilisés / total > 0.30
        println("\n💰 OPPORTUNITÉ: Plus de 30% de sous-utilisation")
        println("   💡 Potentiel d'économies: réduction de fréquence sur certaines lignes")
    end
end

"""
Analyse l'occupation spécifiquement par ligne.
"""
function analyser_occupation_par_ligne(systeme::SystemeSOTRACO)
    println("\n🚌 Occupation par ligne:")
    
    occupation_par_ligne = Dict{Int, Vector{Float64}}()
    
    for donnee in systeme.frequentation
        if donnee.capacite_bus > 0
            taux = (donnee.occupation_bus / donnee.capacite_bus) * 100
            if !haskey(occupation_par_ligne, donnee.ligne_id)
                occupation_par_ligne[donnee.ligne_id] = Float64[]
            end
            push!(occupation_par_ligne[donnee.ligne_id], taux)
        end
    end
    
    lignes_triees = sort([(id, mean(taux)) for (id, taux) in occupation_par_ligne], by=x->x[2], rev=true)
    
    for (ligne_id, taux_moyen) in lignes_triees[1:min(5, length(lignes_triees))]
        nom_ligne = haskey(systeme.lignes, ligne_id) ? systeme.lignes[ligne_id].nom : "Ligne $ligne_id"
        statut = if taux_moyen > 85
            "🔴 CRITIQUE"
        elseif taux_moyen > 65
            "🟠 ÉLEVÉ"
        elseif taux_moyen > 40
            "🟢 NORMAL"
        else
            "🔵 FAIBLE"
        end
        println("   • $nom_ligne: $(round(taux_moyen, digits=1))% $statut")
    end
end

"""
Détecte les problèmes critiques d'occupation.
"""
function detecter_problemes_critiques(taux_occupation::Vector, systeme::SystemeSOTRACO)
    surcharges_critiques = filter(d -> d["taux"] > 95, taux_occupation)
    
    if !isempty(surcharges_critiques)
        println("\n🚨 ALERTES CRITIQUES DÉTECTÉES:")
        
        surcharges_par_ligne = Dict{Int, Int}()
        for surcharge in surcharges_critiques
            ligne_id = surcharge["ligne_id"]
            surcharges_par_ligne[ligne_id] = get(surcharges_par_ligne, ligne_id, 0) + 1
        end
        
        for (ligne_id, nb_surcharges) in sort(collect(surcharges_par_ligne), by=x->x[2], rev=true)
            nom_ligne = haskey(systeme.lignes, ligne_id) ? systeme.lignes[ligne_id].nom : "Ligne $ligne_id"
            println("   🚨 $nom_ligne: $nb_surcharges cas de surcharge critique")
            println("      💡 Action immédiate: renforcement prioritaire")
        end
    end
end

"""
Détecte les anomalies dans les données de fréquentation.
"""
function detecter_anomalies(systeme::SystemeSOTRACO)
    println("\n🔍 DÉTECTION D'ANOMALIES")
    println("-" ^ 30)
    
    anomalies_detectees = []
    
    detecter_pics_anormaux(systeme, anomalies_detectees)
    detecter_chutes_anormales(systeme, anomalies_detectees)
    detecter_incoherences(systeme, anomalies_detectees)
    
    if !isempty(anomalies_detectees)
        println("\n⚠️  $(length(anomalies_detectees)) anomalies détectées:")
        for (i, anomalie) in enumerate(anomalies_detectees)
            println("   $i. $(anomalie["type"]): $(anomalie["description"])")
        end
    else
        println("✅ Aucune anomalie majeure détectée")
    end
    
    return anomalies_detectees
end

"""
Détecte les anomalies dans les données de fréquentation (alias pour detecter_anomalies).
"""
function detecter_anomalies_frequentation(systeme::SystemeSOTRACO)
    return detecter_anomalies(systeme)
end

"""
Détecte les pics anormaux de fréquentation.
"""
function detecter_pics_anormaux(systeme::SystemeSOTRACO, anomalies::Vector)
    freq_par_heure = calculer_frequentation_horaire(systeme)
    
    if length(freq_par_heure) < 5
        return
    end
    
    freqs = collect(values(freq_par_heure))
    moyenne = mean(freqs)
    ecart_type = std(freqs)
    
    # Seuil statistique pour détection de pics
    seuil_pic = moyenne + 3 * ecart_type
    
    for (heure, freq) in freq_par_heure
        if freq > seuil_pic
            push!(anomalies, Dict(
                "type" => "Pic anormal",
                "description" => "$(heure)h00: $freq passagers (seuil: $(round(seuil_pic)))"
            ))
        end
    end
end

"""
Détecte les chutes anormales de fréquentation.
"""
function detecter_chutes_anormales(systeme::SystemeSOTRACO, anomalies::Vector)
    freq_par_jour = Dict{Date, Int}()
    
    for donnee in systeme.frequentation
        date = donnee.date
        freq_par_jour[date] = get(freq_par_jour, date, 0) + donnee.montees + donnee.descentes
    end
    
    if length(freq_par_jour) < 5
        return
    end
    
    freqs_jour = collect(values(freq_par_jour))
    moyenne_jour = mean(freqs_jour)
    
    # Seuil de détection de chute anormale
    seuil_chute = moyenne_jour * 0.3
    
    for (date, freq) in freq_par_jour
        if freq < seuil_chute
            push!(anomalies, Dict(
                "type" => "Chute anormale",
                "description" => "$date: seulement $freq passagers (moyenne: $(round(moyenne_jour)))"
            ))
        end
    end
end

"""
Détecte les incohérences dans les données.
"""
function detecter_incoherences(systeme::SystemeSOTRACO, anomalies::Vector)
    incoherences = 0
    
    for donnee in systeme.frequentation
        # Vérifications de cohérence logique
        if donnee.occupation_bus > donnee.capacite_bus
            incoherences += 1
        end
        
        if donnee.montees > donnee.capacite_bus || donnee.descentes > donnee.capacite_bus
            incoherences += 1
        end
    end
    
    if incoherences > 0
        push!(anomalies, Dict(
            "type" => "Incohérences données",
            "description" => "$incoherences enregistrements avec des valeurs impossibles"
        ))
    end
end

"""
Génère des insights métier automatiques basés sur les analyses.
"""
function generer_insights_metier(systeme::SystemeSOTRACO)
    println("\n💡 INSIGHTS MÉTIER AUTOMATIQUES")
    println("=" ^ 40)
    
    insights = []
    
    generer_insight_economique(systeme, insights)
    generer_insight_qualite(systeme, insights)
    generer_insight_operationnel(systeme, insights)
    
    for (i, insight) in enumerate(insights)
        println("$i. 💡 $(insight["titre"])")
        println("   📊 $(insight["donnee"])")
        println("   🎯 $(insight["recommandation"])")
        println()
    end
end

"""
Génère un insight sur l'efficacité économique.
"""
function generer_insight_economique(systeme::SystemeSOTRACO, insights::Vector)
    total_passagers = sum(d.montees + d.descentes for d in systeme.frequentation)
    
    if total_passagers > 0
        tarifs = [ligne.tarif_fcfa for ligne in values(systeme.lignes) if ligne.statut == "Actif"]
        tarif_moyen = isempty(tarifs) ? 150 : mean(tarifs)
        recettes_estimees = total_passagers * tarif_moyen

        recettes_millions_str = string(round(recettes_estimees / 1_000_000, digits=1))
        lignes_actives = count(l -> l.statut == "Actif", values(systeme.lignes))
        recettes_par_ligne = recettes_estimees / max(1, lignes_actives)
        recettes_par_ligne_k_str = string(round(recettes_par_ligne / 1000, digits=0))

        push!(insights, Dict(
            "titre" => "Efficacité Économique du Réseau",
            "donnee" => "Recettes estimées: $(recettes_millions_str)M FCFA, soit $(recettes_par_ligne_k_str)k FCFA/ligne",
            "recommandation" => recettes_par_ligne < 500_000 ?
                "Optimiser la rentabilité: certaines lignes semblent peu rentables" :
                "Performance économique satisfaisante du réseau"
        ))
    end
end

"""
Génère un insight sur la qualité de service.
"""
function generer_insight_qualite(systeme::SystemeSOTRACO, insights::Vector)
    taux_occ = [d.occupation_bus / d.capacite_bus for d in systeme.frequentation if d.capacite_bus > 0]
    
    if !isempty(taux_occ)
        taux_moyen = mean(taux_occ) * 100
        surcharge_rate = count(t -> t > 0.9, taux_occ) / length(taux_occ) * 100
        
        qualite = if surcharge_rate < 10 && taux_moyen < 80
            "Bonne qualité: confort préservé"
        elseif surcharge_rate < 20
            "Qualité correcte avec quelques pics"
        else
            "Qualité dégradée: surcharges fréquentes"
        end
        
        push!(insights, Dict(
            "titre" => "Qualité de Service Usagers",
            "donnee" => "Taux occupation: $(round(taux_moyen, digits=1))%, surcharges: $(round(surcharge_rate, digits=1))% des trajets",
            "recommandation" => qualite
        ))
    end
end

"""
Génère un insight sur l'optimisation opérationnelle.
"""
function generer_insight_operationnel(systeme::SystemeSOTRACO, insights::Vector)
    freq_par_heure = calculer_frequentation_horaire(systeme)
    
    if !isempty(freq_par_heure)
        freqs = collect(values(freq_par_heure))
        cv = std(freqs) / mean(freqs)
        
        concentration = if cv > 0.8
            "Très concentrée: optimisation horaire prioritaire"
        elseif cv > 0.5
            "Modérément concentrée: ajustements horaires recommandés"
        else
            "Bien répartie: maintenir la régularité"
        end
        
        # Estimation du potentiel d'économie
        heures_creuses = count(f -> f < mean(freqs) * 0.5, freqs)
        potentiel_economie = heures_creuses / length(freqs) * 15
        
        push!(insights, Dict(
            "titre" => "Optimisation Opérationnelle",
            "donnee" => "Variabilité horaire: $(round(cv, digits=2)), $(heures_creuses) heures creuses détectées",
            "recommandation" => "$concentration. Économie potentielle: ~$(round(potentiel_economie, digits=1))%"
        ))
    end
end

end # module Analyse