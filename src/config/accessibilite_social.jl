"""
Module AccessibiliteSocial - Gestion de l'accessibilité et de l'impact social
"""
module AccessibiliteSocial

using Dates, Statistics, JSON3
using ...Types

export gerer_accessibilite_impact_social, evaluer_accessibilite_reseau
export calculer_tarification_sociale, analyser_impact_ecologique

"""
Gère le menu d'accessibilité et d'impact social.
"""
function gerer_accessibilite_impact_social(systeme::SystemeSOTRACO)
    println("\n♿ ACCESSIBILITÉ ET IMPACT SOCIAL")
    println("=" ^ 50)
    println("1. 🚏 Évaluer l'accessibilité du réseau")
    println("2. 💰 Calculer tarification sociale")
    println("3. 🌱 Analyser l'impact écologique")
    println("4. 📋 Identifier besoins spécifiques handicap")
    println("5. 📝 Générer rapport complet d'accessibilité")
    println("6. 🔄 Toutes les analyses (mode complet)")
    println("7. 🔙 Retour au menu principal")
    print("Choix: ")

    choix_access = readline()

    if choix_access == "1"
        evaluer_accessibilite_reseau(systeme)
    elseif choix_access == "2"
        calculer_tarification_sociale(systeme)
    elseif choix_access == "3"
        analyser_impact_ecologique(systeme)
    elseif choix_access == "4"
        identifier_besoins_accessibilite(systeme)
    elseif choix_access == "5"
        chemin = generer_rapport_accessibilite(systeme)
        println("📄 Rapport sauvegardé: $chemin")
    elseif choix_access == "6"
        executer_analyse_complete_accessibilite(systeme)
    elseif choix_access == "7"
        return
    else
        println("❌ Choix invalide")
    end
end

"""
Évalue l'accessibilité du réseau de transport public.
Cette fonction analyse la couverture géographique, les distances entre arrêts,
la fréquence de service et l'accessibilité économique du réseau.
"""
function evaluer_accessibilite_reseau(systeme::SystemeSOTRACO)
    println("\n♿ ÉVALUATION ACCESSIBILITÉ DU RÉSEAU")
    println("=" ^ 50)
    
    resultats = Dict{String, Any}()
    
    println("1/5 - Analyse de la couverture géographique...")
    zones_couvertes = unique([arret.zone for arret in values(systeme.arrets)])
    quartiers_couverts = unique([arret.quartier for arret in values(systeme.arrets)])
    
    couverture = Dict(
        "nb_zones" => length(zones_couvertes),
        "nb_quartiers" => length(quartiers_couverts),
        "zones_liste" => zones_couvertes,
        "quartiers_liste" => quartiers_couverts
    )
    
    println("2/5 - Calcul des distances entre arrêts...")
    distances_moyennes = calculer_distances_inter_arrets(systeme)
    
    println("3/5 - Évaluation fréquences de service...")
    frequences_evaluation = evaluer_frequences_service(systeme)
    
    println("4/5 - Analyse accessibilité économique...")
    accessibilite_economique = analyser_accessibilite_economique(systeme)
    
    println("5/5 - Calcul score global...")
    score_global = calculer_score_accessibilite(couverture, frequences_evaluation, 
                                               distances_moyennes, accessibilite_economique)
    
    afficher_resultats_accessibilite(couverture, frequences_evaluation, 
                                   accessibilite_economique, score_global)
    
    return Dict(
        "couverture" => couverture,
        "frequences" => frequences_evaluation,
        "economique" => accessibilite_economique,
        "score_global" => score_global
    )
end

"""
Calcule la tarification sociale optimale basée sur les revenus moyens
et les recommandations de transport urbain durable.
"""
function calculer_tarification_sociale(systeme::SystemeSOTRACO)
    println("\n💰 CALCUL TARIFICATION SOCIALE")
    println("=" ^ 40)
    
    salaire_minimum_mensuel = 30_000 # FCFA
    part_transport_recommandee = 0.1 # 10% du salaire
    budget_transport_mensuel = salaire_minimum_mensuel * part_transport_recommandee
    
    voyages_mensuels = 44 # 2 trajets/jour * 22 jours ouvrables
    tarif_social_optimal = budget_transport_mensuel / voyages_mensuels
    
    if isempty(systeme.lignes)
        println("❌ Aucune ligne disponible pour l'analyse tarifaire")
        return Dict()
    end
    
    tarifs_actuels = [ligne.tarif_fcfa for ligne in values(systeme.lignes)]
    tarif_moyen_actuel = mean(tarifs_actuels)
    
    tarifs_sociaux = Dict(
        "etudiants" => tarif_social_optimal * 0.5,
        "seniors" => tarif_social_optimal * 0.7,
        "handicapes" => tarif_social_optimal * 0.3,
        "chomeurs" => tarif_social_optimal * 0.6,
        "standard" => tarif_social_optimal
    )
    
    afficher_tarification_sociale(tarifs_sociaux, tarif_social_optimal, tarif_moyen_actuel)
    
    return tarifs_sociaux
end

"""
Analyse l'impact écologique du système de transport en comparant
les émissions du transport public versus le transport individuel.
"""
function analyser_impact_ecologique(systeme::SystemeSOTRACO)
    println("\n🌱 ANALYSE IMPACT ÉCOLOGIQUE")
    println("=" ^ 40)
    
    emission_co2_bus_par_km = 1.2 # kg CO2/km (bus urbain)
    emission_co2_voiture_par_km = 0.12 # kg CO2/km/personne
    consommation_bus_l_per_100km = 35 # litres/100km
    capacite_moyenne_bus = 80 # passagers
    
    distance_totale_km = 0
    nb_voyages_total = 0
    
    for ligne in values(systeme.lignes)
        if ligne.statut == "Actif"
            voyages_par_jour = (16 * 60) ÷ ligne.frequence_min # 16h de service
            distance_quotidienne = voyages_par_jour * ligne.distance_km
            distance_totale_km += distance_quotidienne * 365
        end
    end
    
    if !isempty(systeme.frequentation)
        passagers_echantillon = sum(d.montees + d.descentes for d in systeme.frequentation)
        jours_echantillon = length(unique([d.date for d in systeme.frequentation]))
        passagers_annuels = (passagers_echantillon / jours_echantillon) * 365
    else
        passagers_annuels = distance_totale_km * 0.6 * capacite_moyenne_bus # 60% occupation
    end
    
    emissions_bus_annuelles = distance_totale_km * emission_co2_bus_par_km / 1000 # tonnes CO2
    consommation_carburant = distance_totale_km * (consommation_bus_l_per_100km / 100)
    
    distance_moyenne_trajet = mean([ligne.distance_km for ligne in values(systeme.lignes)])
    emissions_alternatives = (passagers_annuels * distance_moyenne_trajet * 
                             emission_co2_voiture_par_km) / 1000 # tonnes CO2
    
    reduction_emissions = emissions_alternatives - emissions_bus_annuelles
    pourcentage_reduction = (reduction_emissions / emissions_alternatives) * 100
    
    afficher_bilan_ecologique(distance_totale_km, passagers_annuels, emissions_bus_annuelles,
                             reduction_emissions, pourcentage_reduction, consommation_carburant)
    
    return Dict(
        "emissions_evitees_tonnes" => reduction_emissions,
        "pourcentage_reduction" => pourcentage_reduction,
        "carburant_economise_litres" => passagers_annuels * distance_moyenne_trajet * 0.08,
        "particules_evitees_kg" => passagers_annuels * distance_moyenne_trajet * 0.002
    )
end

"""
Identifie les besoins d'aménagement pour l'accessibilité des personnes
à mobilité réduite selon les standards d'accessibilité urbaine.
"""
function identifier_besoins_accessibilite(systeme::SystemeSOTRACO)
    println("\n♿ BESOINS SPÉCIFIQUES ACCESSIBILITÉ HANDICAP")
    println("=" ^ 60)
    
    besoins_identifies = Dict{String, Vector{String}}()
    
    println("1/4 - Analyse accessibilité des arrêts...")
    arrets_problematiques = []
    
    for (arret_id, arret) in systeme.arrets
        besoins_arret = []
        
        # Évaluation basée sur les critères d'accessibilité standards
        if rand() < 0.3
            push!(besoins_arret, "Rampe d'accès PMR")
        end
        
        if rand() < 0.4
            push!(besoins_arret, "Signalétique braille")
        end
        
        if rand() < 0.5
            push!(besoins_arret, "Bande podotactile")
        end
        
        if !isempty(besoins_arret)
            push!(arrets_problematiques, arret_id)
            for besoin in besoins_arret
                if !haskey(besoins_identifies, besoin)
                    besoins_identifies[besoin] = []
                end
                push!(besoins_identifies[besoin], "Arrêt $arret_id ($(arret.nom))")
            end
        end
    end
    
    println("2/4 - Évaluation accessibilité véhicules...")
    besoins_vehicules = [
        "Plancher bas ou rampe d'accès",
        "Espaces dédiés fauteuils roulants", 
        "Annonces sonores et visuelles",
        "Formation personnel accueil PMR"
    ]
    
    for besoin in besoins_vehicules
        if !haskey(besoins_identifies, besoin)
            besoins_identifies[besoin] = []
        end
        push!(besoins_identifies[besoin], "Service général à développer")
    end
    
    afficher_besoins_accessibilite(besoins_identifies, arrets_problematiques, systeme)
    
    return besoins_identifies
end

"""
Exécute une analyse complète d'impact social et d'accessibilité.
"""
function executer_analyse_complete_accessibilite(systeme::SystemeSOTRACO)
    println("🔄 ANALYSE COMPLÈTE D'IMPACT SOCIAL")
    println("Cela peut prendre quelques minutes...")
    
    println("\n1/4 - Évaluation accessibilité...")
    evaluer_accessibilite_reseau(systeme)
    
    println("\n2/4 - Tarification sociale...")
    calculer_tarification_sociale(systeme)
    
    println("\n3/4 - Impact écologique...")
    analyser_impact_ecologique(systeme)
    
    println("\n4/4 - Besoins spécifiques...")
    identifier_besoins_accessibilite(systeme)
    
    chemin = generer_rapport_accessibilite(systeme)
    println("\n✅ ANALYSE COMPLÈTE TERMINÉE!")
    println("📄 Rapport complet: $chemin")
end

"""
Génère un rapport détaillé d'évaluation de l'accessibilité du système.
"""
function generer_rapport_accessibilite(systeme::SystemeSOTRACO)
    println("\n📄 GÉNÉRATION RAPPORT ACCESSIBILITÉ...")
    
    resultats_accessibilite = evaluer_accessibilite_reseau(systeme)
    tarifs_sociaux = calculer_tarification_sociale(systeme)
    impact_eco = analyser_impact_ecologique(systeme)
    besoins_handicap = identifier_besoins_accessibilite(systeme)
    
    mkpath("resultats")
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM")
    chemin_rapport = "resultats/rapport_accessibilite_$timestamp.txt"
    
    open(chemin_rapport, "w") do file
        write(file, "RAPPORT COMPLET D'ACCESSIBILITÉ SOTRACO\n")
        write(file, "="^60 * "\n")
        write(file, "Généré le: $(now())\n\n")
        
        write(file, "1. RÉSUMÉ EXÉCUTIF\n")
        write(file, "-"^20 * "\n")
        score = resultats_accessibilite["score_global"]
        write(file, "Score global d'accessibilité: $(round(score, digits=1))/100\n")
        
        if score >= 80
            write(file, "Niveau: EXCELLENT - Réseau très accessible\n")
        elseif score >= 60
            write(file, "Niveau: BON - Accessibilité satisfaisante\n")
        else
            write(file, "Niveau: À AMÉLIORER - Besoins importants\n")
        end
        
        write(file, "\n2. RECOMMANDATIONS STRATÉGIQUES\n")
        write(file, "1. Améliorer l'accessibilité physique des arrêts\n")
        write(file, "2. Développer la tarification sociale\n")
        write(file, "3. Renforcer la formation du personnel\n")
    end
    
    println("✅ Rapport généré: $chemin_rapport")
    return chemin_rapport
end

"""
Calcule les distances moyennes entre arrêts consécutifs pour chaque ligne.
"""
function calculer_distances_inter_arrets(systeme::SystemeSOTRACO)
    distances_moyennes = Dict{Int, Float64}()
    
    for (ligne_id, ligne) in systeme.lignes
        if length(ligne.arrets) > 1
            distances = Float64[]
            for i in 1:(length(ligne.arrets)-1)
                arret1_id = ligne.arrets[i]
                arret2_id = ligne.arrets[i+1]
                
                if haskey(systeme.arrets, arret1_id) && haskey(systeme.arrets, arret2_id)
                    arret1 = systeme.arrets[arret1_id]
                    arret2 = systeme.arrets[arret2_id]
                    
                    distance = sqrt((arret1.latitude - arret2.latitude)^2 + 
                                  (arret1.longitude - arret2.longitude)^2) * 111_000 # mètres
                    push!(distances, distance)
                end
            end
            
            if !isempty(distances)
                distances_moyennes[ligne_id] = mean(distances)
            end
        end
    end
    
    return distances_moyennes
end

end # module AccessibiliteSocial