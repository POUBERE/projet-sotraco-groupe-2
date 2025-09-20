"""
Module Optimisation - Algorithmes d'optimisation pour SOTRACO
"""
module Optimisation

using Statistics, Dates
using ..Types

export calculer_frequence_optimale, optimiser_toutes_lignes, optimiser_avec_contraintes
export calculer_economies_potentielles, optimiser_allocation_flotte

"""
Calcule la fréquence optimale pour une ligne donnée
"""
function calculer_frequence_optimale(ligne_id::Int, systeme::SystemeSOTRACO)
    donnees_ligne = filter(d -> d.ligne_id == ligne_id, systeme.frequentation)

    if isempty(donnees_ligne)
        return systeme.lignes[ligne_id].frequence_min
    end

    analyse_demande = analyser_patterns_demande(donnees_ligne)
    analyse_occupation = analyser_patterns_occupation(donnees_ligne)
    
    freq_actuelle = systeme.lignes[ligne_id].frequence_min
    
    facteur_demande = calculer_facteur_demande(analyse_demande)
    facteur_occupation = calculer_facteur_occupation(analyse_occupation)
    facteur_temporel = calculer_facteur_temporel(donnees_ligne)
    
    # Pondération : demande (40%), occupation (40%), variation temporelle (20%)
    facteur_global = (facteur_demande * 0.4 + 
                     facteur_occupation * 0.4 + 
                     facteur_temporel * 0.2)
    
    nouvelle_frequence = round(Int, freq_actuelle / facteur_global)
    nouvelle_frequence = appliquer_contraintes(nouvelle_frequence, ligne_id, systeme)
    
    return nouvelle_frequence
end

"""
Analyse les patterns de demande horaire
"""
function analyser_patterns_demande(donnees_ligne::Vector{DonneeFrequentation})
    demande_par_heure = Dict{Int, Vector{Int}}()
    
    for donnee in donnees_ligne
        heure = Dates.hour(donnee.heure)
        demande = donnee.montees + donnee.descentes
        
        if !haskey(demande_par_heure, heure)
            demande_par_heure[heure] = Int[]
        end
        push!(demande_par_heure[heure], demande)
    end
    
    moyennes_horaires = Dict{Int, Float64}()
    variabilite_horaires = Dict{Int, Float64}()
    
    for (heure, demandes) in demande_par_heure
        if !isempty(demandes)
            moyennes_horaires[heure] = mean(demandes)
            variabilite_horaires[heure] = std(demandes)
        end
    end
    
    return Dict(
        "moyennes" => moyennes_horaires,
        "variabilite" => variabilite_horaires,
        "pic_max" => isempty(moyennes_horaires) ? 0.0 : maximum(values(moyennes_horaires)),
        "demande_moyenne" => isempty(moyennes_horaires) ? 0.0 : mean(values(moyennes_horaires))
    )
end

"""
Analyse les taux d'occupation des véhicules
"""
function analyser_patterns_occupation(donnees_ligne::Vector{DonneeFrequentation})
    taux_occupation = [d.occupation_bus / d.capacite_bus for d in donnees_ligne if d.capacite_bus > 0]
    
    if isempty(taux_occupation)
        return Dict("taux_moyen" => 0.5, "surcharge_freq" => 0.0, "sous_utilisation_freq" => 0.0)
    end
    
    taux_moyen = mean(taux_occupation)
    surcharge_freq = count(t -> t > 0.9, taux_occupation) / length(taux_occupation)
    sous_utilisation_freq = count(t -> t < 0.4, taux_occupation) / length(taux_occupation)
    
    return Dict(
        "taux_moyen" => taux_moyen,
        "surcharge_freq" => surcharge_freq,
        "sous_utilisation_freq" => sous_utilisation_freq,
        "variabilite" => std(taux_occupation)
    )
end

"""
Détermine le facteur d'ajustement selon le niveau de demande
"""
function calculer_facteur_demande(analyse_demande::Dict)
    demande_moyenne = analyse_demande["demande_moyenne"]
    
    # Seuils de référence pour ajustement de fréquence
    if demande_moyenne > 100
        return 1.5
    elseif demande_moyenne > 75
        return 1.25
    elseif demande_moyenne > 50
        return 1.0
    elseif demande_moyenne > 25
        return 0.8
    else
        return 0.6
    end
end

"""
Calcule l'ajustement basé sur les taux d'occupation
"""
function calculer_facteur_occupation(analyse_occupation::Dict)
    taux_moyen = analyse_occupation["taux_moyen"]
    surcharge_freq = analyse_occupation["surcharge_freq"]
    sous_utilisation_freq = analyse_occupation["sous_utilisation_freq"]
    
    # Priorisation de la réduction des surcharges
    if surcharge_freq > 0.2
        return 1.4
    elseif surcharge_freq > 0.1
        return 1.2
    elseif taux_moyen > 0.8
        return 1.1
    elseif sous_utilisation_freq > 0.5
        return 0.7
    elseif taux_moyen < 0.4
        return 0.8
    else
        return 1.0
    end
end

"""
Évalue les variations de demande selon les créneaux horaires
"""
function calculer_facteur_temporel(donnees_ligne::Vector{DonneeFrequentation})
    demande_par_heure = Dict{Int, Float64}()
    
    for donnee in donnees_ligne
        heure = Dates.hour(donnee.heure)
        demande = Float64(donnee.montees + donnee.descentes)
        demande_par_heure[heure] = get(demande_par_heure, heure, 0.0) + demande
    end
    
    if isempty(demande_par_heure)
        return 1.0
    end
    
    demandes = collect(values(demande_par_heure))
    cv = std(demandes) / mean(demandes)
    
    if cv > 1.0
        return 1.1
    elseif cv > 0.5
        return 1.05
    else
        return 1.0
    end
end

"""
Applique les contraintes opérationnelles du réseau
"""
function appliquer_contraintes(frequence::Int, ligne_id::Int, systeme::SystemeSOTRACO)
    freq_min = 5   # Service urbain minimum
    freq_max = 60  # Fréquence maximale autorisée
    
    ligne = systeme.lignes[ligne_id]
    
    # Ajustements selon les caractéristiques de ligne
    if ligne.distance_km > 25
        freq_min = 10
    end
    
    if ligne.statut != "Actif"
        freq_max = 30
    end
    
    return max(freq_min, min(freq_max, frequence))
end

"""
Lance l'optimisation complète du réseau
"""
function optimiser_toutes_lignes(systeme::SystemeSOTRACO)
    println("\n🚀 OPTIMISATION GLOBALE DU RÉSEAU")
    println("=" ^ 50)

    recommendations = Dict{Int, Dict{String, Any}}()
    economies_globales = Dict{String, Float64}()

    for (ligne_id, ligne) in systeme.lignes
        if ligne.statut == "Actif"
            rec = optimiser_ligne_complete(ligne_id, ligne, systeme)
            if !isnothing(rec)
                recommendations[ligne_id] = rec
            end
        end
    end

    calculer_impact_global!(recommendations, economies_globales, systeme)
    afficher_recommandations_optimisation(recommendations, systeme)
    afficher_impact_economique(economies_globales)
    generer_recommandations_strategiques(recommendations, systeme)

    return recommendations
end

"""
Effectue l'analyse complète d'une ligne
"""
function optimiser_ligne_complete(ligne_id::Int, ligne::LigneBus, systeme::SystemeSOTRACO)
    freq_actuelle = ligne.frequence_min
    freq_optimale = calculer_frequence_optimale(ligne_id, systeme)
    
    if freq_optimale == freq_actuelle
        return nothing
    end
    
    changement_pct = round((freq_actuelle - freq_optimale) / freq_actuelle * 100, digits=1)
    impact_qualite = evaluer_impact_qualite(ligne_id, freq_actuelle, freq_optimale, systeme)
    impact_economique = calculer_impact_economique_ligne(ligne, freq_actuelle, freq_optimale)
    
    type_action = if freq_optimale < freq_actuelle
        "Augmentation fréquence (amélioration service)"
    else
        "Réduction fréquence (optimisation coûts)"
    end
    
    return Dict(
        "nom" => ligne.nom,
        "frequence_actuelle" => freq_actuelle,
        "frequence_optimale" => freq_optimale,
        "changement_pct" => abs(changement_pct),
        "type_action" => type_action,
        "impact_qualite" => impact_qualite,
        "impact_economique" => impact_economique,
        "priorite" => calculer_priorite_optimisation(changement_pct, impact_qualite)
    )
end

"""
Évalue l'impact sur la qualité de service
"""
function evaluer_impact_qualite(ligne_id::Int, freq_actuelle::Int, freq_optimale::Int, systeme::SystemeSOTRACO)
    donnees_ligne = filter(d -> d.ligne_id == ligne_id, systeme.frequentation)
    
    if isempty(donnees_ligne)
        return "Impact inconnu"
    end
    
    if freq_optimale < freq_actuelle
        reduction_attente = round((freq_actuelle - freq_optimale) / 2, digits=1)
        return "Réduction attente: ~$(reduction_attente)min"
    else
        augmentation_attente = round((freq_optimale - freq_actuelle) / 2, digits=1)
        return "Augmentation attente: ~$(augmentation_attente)min"
    end
end

"""
Calcule l'impact financier d'un changement de fréquence
"""
function calculer_impact_economique_ligne(ligne::LigneBus, freq_actuelle::Int, freq_optimale::Int)
    rotations_actuelles = 60 / freq_actuelle
    rotations_optimales = 60 / freq_optimale
    
    changement_rotations = (rotations_optimales - rotations_actuelles) / rotations_actuelles
    
    cout_base_par_km = 200  # FCFA par km
    cout_quotidien_actuel = rotations_actuelles * 12 * ligne.distance_km * cout_base_par_km
    
    variation_cout = cout_quotidien_actuel * changement_rotations
    
    if variation_cout < 0
        return "Économie: $(Int(round(abs(variation_cout)))) FCFA/jour"
    else
        return "Coût: $(Int(round(variation_cout))) FCFA/jour"
    end
end

"""
Détermine le niveau de priorité d'intervention
"""
function calculer_priorite_optimisation(changement_pct::Float64, impact_qualite::String)
    score_changement = min(changement_pct / 20.0, 1.0)
    
    score_impact = if occursin("Réduction attente", impact_qualite)
        0.8
    elseif occursin("Économie", impact_qualite)
        0.6
    else
        0.4
    end
    
    score_final = (score_changement + score_impact) / 2
    
    if score_final > 0.7
        return "HAUTE"
    elseif score_final > 0.4
        return "MOYENNE"
    else
        return "FAIBLE"
    end
end

"""
Calcule les métriques d'impact à l'échelle du réseau
"""
function calculer_impact_global!(recommendations::Dict, economies::Dict, systeme::SystemeSOTRACO)
    economies_carburant = 0.0
    ameliorations_service = 0
    lignes_optimisees = length(recommendations)
    
    for (ligne_id, rec) in recommendations
        if occursin("Économie", rec["impact_economique"])
            economie_str = split(rec["impact_economique"], " ")[2]
            economie_val = parse(Float64, economie_str)
            economies_carburant += economie_val * 30
        end
        
        if occursin("Réduction attente", rec["impact_qualite"])
            ameliorations_service += 1
        end
    end
    
    economies["carburant_mensuel"] = economies_carburant
    economies["pourcentage_reseau"] = round(lignes_optimisees / length(systeme.lignes) * 100, digits=1)
    economies["lignes_ameliorees"] = Float64(ameliorations_service)
end

"""
Présente les recommandations par ordre de priorité
"""
function afficher_recommandations_optimisation(recommendations::Dict, systeme::SystemeSOTRACO)
    if isempty(recommendations)
        println("✅ Toutes les lignes sont déjà optimales!")
        return
    end
    
    println("💡 Recommandations d'optimisation détaillées:")
    
    recs_triees = sort(collect(recommendations), by=x->x[2]["priorite"], rev=true)
    
    for (ligne_id, rec) in recs_triees
        priorite_icon = rec["priorite"] == "HAUTE" ? "🔴" : 
                       rec["priorite"] == "MOYENNE" ? "🟡" : "🔵"
        
        println("\n$priorite_icon $(rec["nom"]) (Priorité: $(rec["priorite"]))")
        println("   • Fréquence: $(rec["frequence_actuelle"])min → $(rec["frequence_optimale"])min")
        println("   • Changement: $(rec["changement_pct"])%")
        println("   • Action: $(rec["type_action"])")
        println("   • Impact service: $(rec["impact_qualite"])")
        println("   • Impact économique: $(rec["impact_economique"])")
    end
end

"""
Synthèse de l'impact économique global
"""
function afficher_impact_economique(economies::Dict{String, Float64})
    println("\n💰 IMPACT ÉCONOMIQUE GLOBAL:")
    println("   • Lignes à optimiser: $(Int(economies["pourcentage_reseau"]))% du réseau")
    
    if economies["carburant_mensuel"] > 0
        println("   • Économies mensuelles: $(Int(economies["carburant_mensuel"])) FCFA")
        println("   • Projection annuelle: $(Int(economies["carburant_mensuel"] * 12)) FCFA")
    end
    
    if economies["lignes_ameliorees"] > 0
        println("   • Lignes avec amélioration service: $(Int(economies["lignes_ameliorees"]))")
    end
    
    investissement_changement = 50_000 * length(economies)
    if economies["carburant_mensuel"] > 0
        roi_mois = round(investissement_changement / max(economies["carburant_mensuel"], 1), digits=1)
        println("   • ROI estimé: $(roi_mois) mois")
    end
end

"""
Établit les orientations stratégiques
"""
function generer_recommandations_strategiques(recommendations::Dict, systeme::SystemeSOTRACO)
    println("\n🎯 RECOMMANDATIONS STRATÉGIQUES:")
    
    nb_haute_priorite = count(r -> r["priorite"] == "HAUTE", values(recommendations))
    nb_augmentation_freq = count(r -> occursin("Augmentation", r["type_action"]), values(recommendations))
    nb_reduction_freq = count(r -> occursin("Réduction", r["type_action"]), values(recommendations))
    
    if nb_haute_priorite > 0
        println("   1. URGENT: $(nb_haute_priorite) lignes nécessitent une action immédiate")
    end
    
    if nb_augmentation_freq > nb_reduction_freq
        println("   2. PRIORITÉ: Renforcer l'offre de service ($(nb_augmentation_freq) lignes)")
        println("      → Réallouer des bus depuis les lignes sous-utilisées")
    elseif nb_reduction_freq > nb_augmentation_freq
        println("   2. OPPORTUNITÉ: Optimiser les coûts ($(nb_reduction_freq) lignes)")
        println("      → Réduction possible sans impact majeur sur le service")
    end
    
    if length(recommendations) / length(systeme.lignes) > 0.3
        println("   3. PLANIFICATION: Plus de 30% du réseau nécessite des ajustements")
        println("      → Mise en œuvre progressive recommandée sur 3-6 mois")
    end
    
    println("   4. SUIVI: Implémenter un monitoring temps réel des taux d'occupation")
    println("   5. COMMUNICATION: Informer les usagers des changements à l'avance")
end

"""
Analyse détaillée du potentiel d'économies
"""
function calculer_economies_potentielles(systeme::SystemeSOTRACO)
    println("\n💰 CALCUL DES ÉCONOMIES POTENTIELLES")
    println("=" ^ 50)
    
    economies = Dict{String, Float64}()
    
    calculer_economies_carburant!(economies, systeme)
    calculer_economies_maintenance!(economies, systeme)
    calculer_amelioration_recettes!(economies, systeme)
    
    afficher_resume_economies(economies)
    
    return economies
end

"""
Évalue les économies sur les coûts de carburant
"""
function calculer_economies_carburant!(economies::Dict, systeme::SystemeSOTRACO)
    donnees_sous_utilisees = filter(d -> d.capacite_bus > 0 && d.occupation_bus / d.capacite_bus < 0.4, 
                                   systeme.frequentation)
    
    if !isempty(donnees_sous_utilisees)
        lignes_analysees = unique([d.ligne_id for d in donnees_sous_utilisees])
        km_gaspilles = 0.0
        
        for ligne_id in lignes_analysees
            if haskey(systeme.lignes, ligne_id)
                ligne = systeme.lignes[ligne_id]
                nb_trajets_vides = count(d -> d.ligne_id == ligne_id, donnees_sous_utilisees)
                km_gaspilles += nb_trajets_vides * ligne.distance_km
            end
        end
        
        cout_carburant_gaspille = km_gaspilles * 100
        economies["carburant"] = cout_carburant_gaspille * 0.15
    else
        economies["carburant"] = 0.0
    end
end

"""
Estime les économies de maintenance préventive
"""
function calculer_economies_maintenance!(economies::Dict, systeme::SystemeSOTRACO)
    total_km_reseau = sum(l.distance_km for l in values(systeme.lignes) if l.statut == "Actif")
    
    cout_maintenance_base = total_km_reseau * 50 * 30
    economies["maintenance"] = cout_maintenance_base * 0.10
end

"""
Projette l'augmentation de recettes par amélioration du service
"""
function calculer_amelioration_recettes!(economies::Dict, systeme::SystemeSOTRACO)
    total_passagers = sum(d.montees + d.descentes for d in systeme.frequentation)
    
    if total_passagers > 0
        tarifs = [l.tarif_fcfa for l in values(systeme.lignes) if l.statut == "Actif"]
        tarif_moyen = isempty(tarifs) ? 150 : mean(tarifs)
        
        recettes_actuelles = total_passagers * tarif_moyen
        economies["recettes_supplementaires"] = recettes_actuelles * 0.05
    else
        economies["recettes_supplementaires"] = 0.0
    end
end

"""
Synthèse financière des optimisations
"""
function afficher_resume_economies(economies::Dict{String, Float64})
    total_economies = sum(values(economies))
    
    println("📊 Résumé des économies potentielles:")
    
    for (type, montant) in economies
        if montant > 0
            montant_m = round(montant / 1_000_000, digits=2)
            println("   • $(uppercase(type)): $(montant_m)M FCFA/an")
        end
    end
    
    if total_economies > 0
        total_m = round(total_economies / 1_000_000, digits=2)
        println("\n🎯 TOTAL ÉCONOMIES POTENTIELLES: $(total_m)M FCFA/an")
        
        if total_m > 100
            println("   💡 Impact majeur: budget d'investissement significatif libéré")
        elseif total_m > 50
            println("   💡 Impact modéré: améliorations infrastructures possibles")
        else
            println("   💡 Impact limité: optimisations ponctuelles")
        end
    end
end

"""
Optimisation de la répartition des véhicules
"""
function optimiser_allocation_flotte(systeme::SystemeSOTRACO)
    println("\n🚌 OPTIMISATION DE L'ALLOCATION DE FLOTTE")
    println("=" ^ 50)
    
    demande_par_ligne = analyser_demande_par_ligne(systeme)
    allocation_optimale = calculer_allocation_optimale(demande_par_ligne, systeme)
    generer_recommandations_redistribution(allocation_optimale, systeme)
    
    return allocation_optimale
end

"""
Analyse de la charge par ligne de transport
"""
function analyser_demande_par_ligne(systeme::SystemeSOTRACO)
    demande_par_ligne = Dict{Int, Dict{String, Float64}}()
    
    for (ligne_id, ligne) in systeme.lignes
        if ligne.statut == "Actif"
            donnees_ligne = filter(d -> d.ligne_id == ligne_id, systeme.frequentation)
            
            if !isempty(donnees_ligne)
                total_passagers = sum(d.montees + d.descentes for d in donnees_ligne)
                jours_donnees = length(unique([d.date for d in donnees_ligne]))
                
                taux_occ = [d.occupation_bus / d.capacite_bus for d in donnees_ligne if d.capacite_bus > 0]
                taux_occ_moyen = isempty(taux_occ) ? 0.5 : mean(taux_occ)
                
                demande_par_ligne[ligne_id] = Dict(
                    "passagers_jour" => total_passagers / max(1, jours_donnees),
                    "taux_occupation" => taux_occ_moyen,
                    "score_demande" => (total_passagers / max(1, jours_donnees)) * taux_occ_moyen,
                    "nom" => ligne.nom
                )
            end
        end
    end
    
    return demande_par_ligne
end

"""
Détermine la répartition optimale des véhicules
"""
function calculer_allocation_optimale(demande_par_ligne::Dict, systeme::SystemeSOTRACO)
    if isempty(demande_par_ligne)
        return Dict()
    end
    
    score_total = sum(d["score_demande"] for d in values(demande_par_ligne))
    flotte_totale = count(l -> l.statut == "Actif", values(systeme.lignes)) * 3
    
    allocation = Dict{Int, Dict{String, Any}}()
    
    for (ligne_id, demande) in demande_par_ligne
        ratio_demande = demande["score_demande"] / score_total
        bus_optimaux = round(Int, flotte_totale * ratio_demande)
        bus_optimaux = max(1, min(8, bus_optimaux))
        
        ligne = systeme.lignes[ligne_id]
        bus_actuels_estimes = max(1, round(Int, 60 / ligne.frequence_min))
        
        allocation[ligne_id] = Dict(
            "nom" => demande["nom"],
            "bus_actuels" => bus_actuels_estimes,
            "bus_optimaux" => bus_optimaux,
            "changement" => bus_optimaux - bus_actuels_estimes,
            "score_demande" => demande["score_demande"]
        )
    end
    
    return allocation
end

"""
Plan de redistribution de la flotte
"""
function generer_recommandations_redistribution(allocation::Dict, systeme::SystemeSOTRACO)
    if isempty(allocation)
        println("❌ Données insuffisantes pour l'allocation")
        return
    end
    
    lignes_besoin = [(id, alloc) for (id, alloc) in allocation if alloc["changement"] > 0]
    lignes_surplus = [(id, alloc) for (id, alloc) in allocation if alloc["changement"] < 0]
    
    println("📈 Lignes nécessitant des renforts:")
    sort!(lignes_besoin, by=x->x[2]["changement"], rev=true)
    for (ligne_id, alloc) in lignes_besoin[1:min(3, length(lignes_besoin))]
        println("   • $(alloc["nom"]): +$(alloc["changement"]) bus")
        println("     Justification: score demande $(round(alloc["score_demande"], digits=1))")
    end
    
    println("\n📉 Lignes avec surplus potentiel:")
    sort!(lignes_surplus, by=x->x[2]["changement"])
    for (ligne_id, alloc) in lignes_surplus[1:min(3, length(lignes_surplus))]
        println("   • $(alloc["nom"]): $(alloc["changement"]) bus")
        println("     Disponible pour redistribution")
    end
    
    if !isempty(lignes_besoin) && !isempty(lignes_surplus)
        println("\n🔄 Plan de redistribution recommandé:")
        println("   1. Phase pilote: tester sur 1-2 lignes prioritaires")
        println("   2. Monitoring: évaluer l'impact après 2 semaines")
        println("   3. Déploiement: étendre si résultats positifs")
        println("   4. Ajustement: réajuster selon les retours terrain")
    end
end

end # module Optimisation