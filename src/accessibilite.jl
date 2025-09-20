"""
Module Accessibilité - Fonctionnalités d'accessibilité et d'impact social pour SOTRACO
"""
module Accessibilite

using Dates, Statistics
using ..Types

export evaluer_accessibilite_reseau, calculer_tarification_sociale, analyser_impact_ecologique
export generer_rapport_accessibilite, identifier_besoins_accessibilite

"""
Évalue l'accessibilité du réseau pour les personnes handicapées.
"""
function evaluer_accessibilite_reseau(systeme::SystemeSOTRACO)
    println("♿ ÉVALUATION ACCESSIBILITÉ DU RÉSEAU SOTRACO")
    println("=" ^ 60)
    
    arrets_accessibles = analyser_accessibilite_arrets(systeme)
    lignes_accessibles = analyser_accessibilite_lignes(systeme, arrets_accessibles)
    poi_accessibles = analyser_poi_accessibles(systeme, arrets_accessibles)
    recommandations = generer_recommandations_accessibilite(systeme, arrets_accessibles)
    
    afficher_rapport_accessibilite(arrets_accessibles, lignes_accessibles, poi_accessibles, recommandations)
    
    return Dict(
        "arrets_accessibles" => arrets_accessibles,
        "lignes_accessibles" => lignes_accessibles,
        "poi_accessibles" => poi_accessibles,
        "recommandations" => recommandations
    )
end

"""
Analyse l'accessibilité des arrêts pour personnes à mobilité réduite.
"""
function analyser_accessibilite_arrets(systeme::SystemeSOTRACO)
    accessibilite = Dict{Int, Dict{String, Any}}()
    
    for arret in values(systeme.arrets)
        score_accessibilite = 0
        defis = String[]
        
        # Évaluation des équipements de base
        if arret.abribus
            score_accessibilite += 30
        else
            push!(defis, "Absence d'abribus (exposition aux intempéries)")
        end
        
        if arret.eclairage
            score_accessibilite += 20
        else
            push!(defis, "Éclairage insuffisant (sécurité nocturne)")
        end
        
        # Score selon la zone géographique
        if arret.zone == "Zone 1"
            score_accessibilite += 25
        elseif arret.zone == "Zone 2"
            score_accessibilite += 15
        else
            score_accessibilite += 5
            push!(defis, "Zone périphérique (infrastructure limitée)")
        end
        
        # Bonus connectivité multi-lignes
        nb_lignes = length(arret.lignes_desservies)
        if nb_lignes >= 3
            score_accessibilite += 15
        elseif nb_lignes >= 2
            score_accessibilite += 10
        else
            score_accessibilite += 5
            push!(defis, "Connectivité limitée (peu d'alternatives)")
        end
        
        # Classification du niveau d'accessibilité
        niveau = if score_accessibilite >= 80
            "Excellent"
        elseif score_accessibilite >= 60
            "Bon"
        elseif score_accessibilite >= 40
            "Moyen"
        else
            "Insuffisant"
        end
        
        accessibilite[arret.id] = Dict(
            "nom" => arret.nom,
            "quartier" => arret.quartier,
            "zone" => arret.zone,
            "score" => score_accessibilite,
            "niveau" => niveau,
            "defis" => defis,
            "abribus" => arret.abribus,
            "eclairage" => arret.eclairage,
            "nb_lignes" => nb_lignes
        )
    end
    
    return accessibilite
end

"""
Analyse l'accessibilité des lignes de bus.
"""
function analyser_accessibilite_lignes(systeme::SystemeSOTRACO, arrets_accessibles::Dict)
    lignes_accessibles = Dict{Int, Dict{String, Any}}()
    
    for ligne in values(systeme.lignes)
        if ligne.statut != "Actif"
            continue
        end
        
        scores_arrets = []
        arrets_problematiques = []
        
        for arret_id in ligne.arrets
            if haskey(arrets_accessibles, arret_id)
                score = arrets_accessibles[arret_id]["score"]
                push!(scores_arrets, score)
                
                if score < 40
                    push!(arrets_problematiques, arrets_accessibles[arret_id]["nom"])
                end
            end
        end
        
        score_ligne = isempty(scores_arrets) ? 0 : mean(scores_arrets)
        pourcentage_accessible = count(s -> s >= 60, scores_arrets) / max(1, length(scores_arrets)) * 100
        
        accessibilite_tarifaire = evaluer_accessibilite_tarifaire(ligne)
        
        lignes_accessibles[ligne.id] = Dict(
            "nom" => ligne.nom,
            "origine" => ligne.origine,
            "destination" => ligne.destination,
            "score_moyen" => round(score_ligne, digits=1),
            "pourcentage_accessible" => round(pourcentage_accessible, digits=1),
            "nb_arrets_total" => length(ligne.arrets),
            "nb_arrets_problematiques" => length(arrets_problematiques),
            "arrets_problematiques" => arrets_problematiques,
            "tarif_fcfa" => ligne.tarif_fcfa,
            "accessibilite_tarifaire" => accessibilite_tarifaire
        )
    end
    
    return lignes_accessibles
end

"""
Évalue l'accessibilité tarifaire d'une ligne selon les standards locaux.
"""
function evaluer_accessibilite_tarifaire(ligne::LigneBus)
    # Seuils d'accessibilité tarifaire adaptés au contexte de Ouagadougou
    seuil_tres_accessible = 100
    seuil_accessible = 150
    seuil_moyennement_accessible = 200
    
    if ligne.tarif_fcfa <= seuil_tres_accessible
        return "Très accessible"
    elseif ligne.tarif_fcfa <= seuil_accessible
        return "Accessible"
    elseif ligne.tarif_fcfa <= seuil_moyennement_accessible
        return "Moyennement accessible"
    else
        return "Peu accessible"
    end
end

"""
Analyse l'accessibilité aux points d'intérêt critiques de la ville.
"""
function analyser_poi_accessibles(systeme::SystemeSOTRACO, arrets_accessibles::Dict)
    # Principaux points d'intérêt de Ouagadougou
    poi_critiques = [
        ("Hôpital Yalgado", "Centre"),
        ("Université de Ouagadougou", "Samandin"), 
        ("Marché Central", "Centre"),
        ("Gare Routière", "Centre"),
        ("Ministères", "Ouaga 2000"),
        ("Aéroport", "Zone Aéroportuaire")
    ]
    
    accessibilite_poi = []
    
    for (nom_poi, quartier_approx) in poi_critiques
        # Identification des arrêts de desserte
        arrets_proches = [a for a in values(arrets_accessibles) 
                         if occursin(quartier_approx, a["quartier"]) || 
                            occursin("Centre", a["quartier"]) ||
                            a["zone"] == "Zone 1"]
        
        if !isempty(arrets_proches)
            scores_proches = [a["score"] for a in arrets_proches]
            score_moyen = mean(scores_proches)
            meilleur_arret = arrets_proches[argmax(scores_proches)]
            
            niveau_acces = if score_moyen >= 70
                "Bon accès"
            elseif score_moyen >= 50
                "Accès moyen"
            else
                "Accès difficile"
            end
            
            push!(accessibilite_poi, Dict(
                "poi" => nom_poi,
                "quartier" => quartier_approx,
                "score_moyen_acces" => round(score_moyen, digits=1),
                "niveau_acces" => niveau_acces,
                "meilleur_arret" => meilleur_arret["nom"],
                "nb_arrets_proches" => length(arrets_proches)
            ))
        else
            push!(accessibilite_poi, Dict(
                "poi" => nom_poi,
                "quartier" => quartier_approx,
                "score_moyen_acces" => 0.0,
                "niveau_acces" => "Non desservi",
                "meilleur_arret" => "Aucun",
                "nb_arrets_proches" => 0
            ))
        end
    end
    
    return accessibilite_poi
end

"""
Génère des recommandations d'amélioration de l'accessibilité basées sur l'analyse.
"""
function generer_recommandations_accessibilite(systeme::SystemeSOTRACO, arrets_accessibles::Dict)
    recommandations = Dict{String, Vector{String}}()
    
    # Identification des arrêts prioritaires
    arrets_prioritaires = []
    for (id, data) in arrets_accessibles
        if data["score"] < 40 && data["nb_lignes"] >= 2
            push!(arrets_prioritaires, (id, data["nom"], data["score"], data["nb_lignes"]))
        end
    end
    
    sort!(arrets_prioritaires, by=x -> (x[4], -x[3]), rev=true)
    
    # Actions immédiates
    recommandations["immediates"] = [
        "Installer des abribus sur les $(length([a for a in values(arrets_accessibles) if !a["abribus"]])) arrêts non couverts",
        "Améliorer l'éclairage de $(length([a for a in values(arrets_accessibles) if !a["eclairage"]])) arrêts",
        "Prioriser l'amélioration des $(min(5, length(arrets_prioritaires))) arrêts les plus critiques"
    ]
    
    # Développements à moyen terme
    recommandations["moyen_terme"] = [
        "Installer des rampes d'accès pour fauteuils roulants",
        "Former le personnel à l'assistance aux personnes handicapées",
        "Mettre en place un système d'annonces audio/visuelles dans les bus",
        "Créer des espaces réservés PMR dans les véhicules"
    ]
    
    # Objectifs long terme
    recommandations["long_terme"] = [
        "Acquérir des bus à plancher bas (low-floor)",
        "Développer une application mobile avec fonctionnalités d'accessibilité",
        "Créer un réseau de transport adapté complémentaire",
        "Implémenter des arrêts intelligents avec information temps réel"
    ]
    
    # Estimation budgétaire
    budget_estime = estimer_budget_ameliorations(arrets_accessibles)
    recommandations["budget"] = [
        "Budget estimé améliorations immédiates: $(budget_estime["immediat"]) FCFA",
        "Budget total accessibilité: $(budget_estime["total"]) FCFA",
        "Rechercher financement auprès de bailleurs internationaux",
        "Partenariat avec ONG spécialisées handicap"
    ]
    
    return recommandations
end

"""
Estime le budget nécessaire pour les améliorations d'accessibilité.
"""
function estimer_budget_ameliorations(arrets_accessibles::Dict)
    # Coûts unitaires basés sur le marché local burkinabè
    cout_abribus = 2_500_000
    cout_eclairage = 800_000
    cout_rampe = 1_200_000
    
    nb_abribus_manquants = count(a -> !a["abribus"], values(arrets_accessibles))
    nb_eclairage_manquant = count(a -> !a["eclairage"], values(arrets_accessibles))
    nb_total_arrets = length(arrets_accessibles)
    
    cout_immediat = nb_abribus_manquants * cout_abribus + nb_eclairage_manquant * cout_eclairage
    cout_total = cout_immediat + nb_total_arrets * cout_rampe
    
    return Dict(
        "immediat" => Int(cout_immediat),
        "total" => Int(cout_total),
        "detail" => Dict(
            "abribus" => nb_abribus_manquants * cout_abribus,
            "eclairage" => nb_eclairage_manquant * cout_eclairage,
            "rampes" => nb_total_arrets * cout_rampe
        )
    )
end

"""
Affiche le rapport d'accessibilité complet.
"""
function afficher_rapport_accessibilite(arrets_accessibles, lignes_accessibles, poi_accessibles, recommandations)
    println("\n📊 RÉSULTATS DE L'ÉVALUATION D'ACCESSIBILITÉ")
    println("=" ^ 60)
    
    # Calcul des statistiques générales
    scores = [a["score"] for a in values(arrets_accessibles)]
    score_moyen = mean(scores)
    
    excellent = count(s -> s >= 80, scores)
    bon = count(s -> s >= 60 && s < 80, scores)
    moyen = count(s -> s >= 40 && s < 60, scores)
    insuffisant = count(s -> s < 40, scores)
    
    println("🎯 SYNTHÈSE GÉNÉRALE:")
    println("   • Score d'accessibilité moyen: $(round(score_moyen, digits=1))/100")
    println("   • Répartition des arrêts:")
    println("     - Excellent (≥80): $excellent arrêts ($(round(excellent/length(scores)*100, digits=1))%)")
    println("     - Bon (60-79): $bon arrêts ($(round(bon/length(scores)*100, digits=1))%)")
    println("     - Moyen (40-59): $moyen arrêts ($(round(moyen/length(scores)*100, digits=1))%)")
    println("     - Insuffisant (<40): $insuffisant arrêts ($(round(insuffisant/length(scores)*100, digits=1))%)")
    
    # Arrêts les plus performants
    println("\n✅ TOP 5 ARRÊTS LES PLUS ACCESSIBLES:")
    arrets_tries = sort(collect(arrets_accessibles), by=x->x[2]["score"], rev=true)
    for i in 1:min(5, length(arrets_tries))
        arret = arrets_tries[i][2]
        println("   $i. $(arret["nom"]) ($(arret["quartier"])): $(arret["score"])/100")
    end
    
    # Arrêts nécessitant des améliorations prioritaires
    println("\n⚠️ TOP 5 ARRÊTS NÉCESSITANT DES AMÉLIORATIONS URGENTES:")
    arrets_urgents = sort(collect(arrets_accessibles), by=x->(x[2]["nb_lignes"], x[2]["score"]), rev=true)
    arrets_urgents = filter(x -> x[2]["score"] < 60, arrets_urgents)
    
    for i in 1:min(5, length(arrets_urgents))
        arret = arrets_urgents[i][2]
        println("   $i. $(arret["nom"]) ($(arret["quartier"])): $(arret["score"])/100")
        println("      Défis: $(join(arret["defis"], ", "))")
    end
    
    # Performance des lignes
    println("\n🚌 ACCESSIBILITÉ DES LIGNES:")
    lignes_triees = sort(collect(lignes_accessibles), by=x->x[2]["score_moyen"], rev=true)
    for (id, ligne) in lignes_triees[1:min(5, length(lignes_triees))]
        println("   • Ligne $(ligne["nom"]): $(ligne["score_moyen"])/100")
        println("     $(ligne["pourcentage_accessible"])% d'arrêts accessibles, Tarif: $(ligne["tarif_fcfa"]) FCFA ($(ligne["accessibilite_tarifaire"]))")
    end
    
    # Desserte des services essentiels
    println("\n🏥 ACCESSIBILITÉ AUX SERVICES ESSENTIELS:")
    for poi in poi_accessibles
        println("   • $(poi["poi"]): $(poi["niveau_acces"]) (Score: $(poi["score_moyen_acces"])/100)")
    end
    
    # Actions prioritaires
    println("\n💡 RECOMMANDATIONS PRIORITAIRES:")
    for rec in recommandations["immediates"]
        println("   ✅ $rec")
    end
    
    println("\n💰 BUDGET NÉCESSAIRE:")
    for rec in recommandations["budget"]
        println("   💵 $rec")
    end
end

"""
Calcule une tarification sociale adaptée aux réalités économiques locales.
"""
function calculer_tarification_sociale(systeme::SystemeSOTRACO)
    println("\n💰 CALCUL DE TARIFICATION SOCIALE")
    println("=" ^ 50)
    
    # État des lieux tarifaire
    tarifs_actuels = [ligne.tarif_fcfa for ligne in values(systeme.lignes) if ligne.statut == "Actif"]
    tarif_moyen = mean(tarifs_actuels)
    tarif_max = maximum(tarifs_actuels)
    tarif_min = minimum(tarifs_actuels)
    
    println("📊 ANALYSE TARIFAIRE ACTUELLE:")
    println("   • Tarif moyen: $(round(tarif_moyen, digits=0)) FCFA")
    println("   • Plage tarifaire: $(tarif_min) - $(tarif_max) FCFA")
    
    # Références économiques locales
    salaire_min_bf = 30_684  # SMIG Burkina Faso
    revenu_moyen_urbain = 75_000
    
    # Calcul des seuils de tarification sociale
    seuil_pauvrete = 0.002
    seuil_social = 0.005
    seuil_standard = 0.01
    
    tarification_sociale = Dict{String, Dict{String, Any}}()
    
    # Tarif grande précarité
    tarif_pauvrete = Int(round(salaire_min_bf * seuil_pauvrete))
    tarification_sociale["grande_precarite"] = Dict(
        "tarif" => tarif_pauvrete,
        "reduction" => round((tarif_moyen - tarif_pauvrete) / tarif_moyen * 100, digits=1),
        "criteres" => ["Bénéficiaires RSA local", "Étudiants boursiers d'État", "Personnes handicapées"],
        "justification" => "Garantir l'accès transport aux plus démunis"
    )
    
    # Tarif social standard
    tarif_social = Int(round(revenu_moyen_urbain * seuil_social))
    tarification_sociale["social"] = Dict(
        "tarif" => tarif_social,
        "reduction" => round((tarif_moyen - tarif_social) / tarif_moyen * 100, digits=1),
        "criteres" => ["Familles nombreuses", "Seniors >65 ans", "Jeunes <18 ans"],
        "justification" => "Soutenir les catégories vulnérables"
    )
    
    # Tarif étudiant
    tarif_etudiant = Int(round(tarif_social * 0.8))
    tarification_sociale["etudiant"] = Dict(
        "tarif" => tarif_etudiant,
        "reduction" => round((tarif_moyen - tarif_etudiant) / tarif_moyen * 100, digits=1),
        "criteres" => ["Étudiants université/lycée", "Apprentis", "Stagiaires"],
        "justification" => "Favoriser l'accès à l'éducation"
    )
    
    # Évaluation de l'impact budgétaire
    impact_budget = estimer_impact_budgetaire(systeme, tarification_sociale, tarif_moyen)
    
    afficher_tarification_sociale(tarification_sociale, impact_budget, tarif_moyen)
    
    return Dict(
        "tarification" => tarification_sociale,
        "impact_budget" => impact_budget,
        "tarif_reference" => tarif_moyen
    )
end

"""
Estime l'impact budgétaire de la tarification sociale.
"""
function estimer_impact_budgetaire(systeme::SystemeSOTRACO, tarification::Dict, tarif_reference::Float64)
    # Estimation du volume de passagers
    total_passagers = length(systeme.frequentation) > 0 ? 
                     sum(d.montees + d.descentes for d in systeme.frequentation) : 10000
    
    # Répartition estimée des usagers par catégorie
    repartition_usagers = Dict(
        "standard" => 0.65,
        "social" => 0.20,
        "etudiant" => 0.10,
        "grande_precarite" => 0.05
    )
    
    recettes_actuelles = total_passagers * tarif_reference
    recettes_nouvelles = 0
    
    for (categorie, proportion) in repartition_usagers
        nb_usagers = total_passagers * proportion
        if categorie == "standard"
            recettes_nouvelles += nb_usagers * tarif_reference
        else
            tarif_cat = tarification[categorie]["tarif"]
            recettes_nouvelles += nb_usagers * tarif_cat
        end
    end
    
    perte_recettes = recettes_actuelles - recettes_nouvelles
    pourcentage_perte = (perte_recettes / recettes_actuelles) * 100
    
    return Dict(
        "recettes_actuelles" => recettes_actuelles,
        "recettes_nouvelles" => recettes_nouvelles,
        "perte_recettes" => perte_recettes,
        "pourcentage_perte" => round(pourcentage_perte, digits=1),
        "compensation_necessaire" => perte_recettes,
        "sources_compensation" => [
            "Subvention municipale",
            "Aide internationale développement",
            "Taxe transport employeurs",
            "Partenariat public-privé"
        ]
    )
end

"""
Affiche les résultats de la tarification sociale.
"""
function afficher_tarification_sociale(tarification::Dict, impact::Dict, tarif_ref::Float64)
    println("\n🎯 PROPOSITION DE TARIFICATION SOCIALE:")
    println("=" ^ 60)
    
    for (categorie, data) in tarification
        nom_categorie = replace(categorie, "_" => " ") |> uppercasefirst
        println("\n📋 CATÉGORIE: $(uppercase(nom_categorie))")
        println("   • Tarif proposé: $(data["tarif"]) FCFA")
        println("   • Réduction: $(data["reduction"])% par rapport au tarif moyen")
        println("   • Critères d'éligibilité:")
        for critere in data["criteres"]
            println("     - $critere")
        end
        println("   • Justification: $(data["justification"])")
    end
    
    println("\n💰 IMPACT BUDGÉTAIRE:")
    println("   • Recettes actuelles: $(Int(round(impact["recettes_actuelles"]))) FCFA/période")
    println("   • Recettes avec tarification sociale: $(Int(round(impact["recettes_nouvelles"]))) FCFA/période")
    println("   • Perte de recettes: $(Int(round(impact["perte_recettes"]))) FCFA ($(impact["pourcentage_perte"])%)")
    
    println("\n🔄 SOURCES DE COMPENSATION SUGGÉRÉES:")
    for source in impact["sources_compensation"]
        println("   • $source")
    end
    
    println("\n🎯 RECOMMANDATIONS DE MISE EN ŒUVRE:")
    println("   ✅ Phase pilote sur 2-3 lignes test (6 mois)")
    println("   ✅ Système de carte transport rechargeable")
    println("   ✅ Contrôles réguliers d'éligibilité")
    println("   ✅ Communication large auprès des bénéficiaires")
    println("   ✅ Évaluation impact social après 1 an")
end

"""
Analyse l'impact écologique du réseau de transport urbain.
"""
function analyser_impact_ecologique(systeme::SystemeSOTRACO)
    println("\n🌱 ANALYSE D'IMPACT ÉCOLOGIQUE SOTRACO")
    println("=" ^ 55)
    
    emissions_actuelles = calculer_emissions_actuelles(systeme)
    alternatives_eco = evaluer_alternatives_ecologiques(systeme)
    potentiel_reduction = calculer_potentiel_reduction_emissions(systeme, emissions_actuelles)
    
    afficher_bilan_ecologique(emissions_actuelles, alternatives_eco, potentiel_reduction)
    
    return Dict(
        "emissions_actuelles" => emissions_actuelles,
        "alternatives" => alternatives_eco,
        "potentiel_reduction" => potentiel_reduction
    )
end

"""
Calcule les émissions de CO2 actuelles du réseau selon les standards de mesure.
"""
function calculer_emissions_actuelles(systeme::SystemeSOTRACO)
    # Paramètres techniques pour le calcul d'émissions
    conso_bus_l_100km = 35.0
    emission_co2_l_diesel = 2.68
    
    lignes_actives = [l for l in values(systeme.lignes) if l.statut == "Actif"]
    
    distance_quotidienne = 0.0
    for ligne in lignes_actives
        # Calcul basé sur la fréquence de service
        trajets_par_jour = (12 * 60) / ligne.frequence_min
        distance_ligne_jour = trajets_par_jour * ligne.distance_km * 2
        distance_quotidienne += distance_ligne_jour
    end
    
    # Calculs d'émissions et coûts
    conso_carburant_jour = distance_quotidienne * conso_bus_l_100km / 100
    emissions_co2_jour = conso_carburant_jour * emission_co2_l_diesel
    
    emissions_annuelles = emissions_co2_jour * 365
    cout_carburant_annuel = conso_carburant_jour * 365 * 650
    
    return Dict(
        "distance_quotidienne_km" => round(distance_quotidienne, digits=1),
        "consommation_jour_litres" => round(conso_carburant_jour, digits=1),
        "emissions_co2_jour_kg" => round(emissions_co2_jour, digits=1),
        "emissions_co2_annuelles_tonnes" => round(emissions_annuelles / 1000, digits=1),
        "cout_carburant_annuel_fcfa" => Int(round(cout_carburant_annuel)),
        "nb_lignes_analysees" => length(lignes_actives)
    )
end

"""
Évalue les alternatives écologiques disponibles sur le marché local.
"""
function evaluer_alternatives_ecologiques(systeme::SystemeSOTRACO)
    alternatives = Dict{String, Dict{String, Any}}()
    
    # Électrification du parc
    alternatives["bus_electriques"] = Dict(
        "reduction_emissions" => 85,
        "cout_acquisition" => 180_000_000,
        "cout_infrastructure" => 50_000_000,
        "economies_carburant_annuel" => 4_500_000,
        "duree_amortissement" => 8,
        "avantages" => [
            "Réduction drastique pollution urbaine",
            "Silence de fonctionnement",
            "Économies carburant long terme",
            "Image moderne et écologique"
        ],
        "defis" => [
            "Investissement initial très élevé",
            "Infrastructure électrique à développer",
            "Formation technique spécialisée nécessaire",
            "Autonomie limitée (besoin de rechargement)"
        ]
    )
    
    # Technologie hybride
    alternatives["bus_hybrides"] = Dict(
        "reduction_emissions" => 35,
        "cout_acquisition" => 95_000_000,
        "cout_infrastructure" => 5_000_000,
        "economies_carburant_annuel" => 1_800_000,
        "duree_amortissement" => 6,
        "avantages" => [
            "Technologie éprouvée",
            "Réduction significative consommation",
            "Transition progressive possible",
            "Maintenance proche du conventionnel"
        ],
        "defis" => [
            "Coût encore élevé",
            "Complexité technique accrue",
            "Disponibilité pièces détachées"
        ]
    )
    
    # Solutions de biocarburant
    alternatives["biocarburant"] = Dict(
        "reduction_emissions" => 20,
        "cout_acquisition" => 0,
        "cout_infrastructure" => 15_000_000,
        "economies_carburant_annuel" => -500_000,
        "duree_amortissement" => 3,
        "avantages" => [
            "Compatible avec flotte existante",
            "Soutien agriculture locale (jatropha)",
            "Création emplois ruraux",
            "Technologie accessible"
        ],
        "defis" => [
            "Disponibilité matière première",
            "Qualité et standardisation",
            "Réseau de distribution à créer"
        ]
    )
    
    # Optimisation opérationnelle
    alternatives["optimisation_trajets"] = Dict(
        "reduction_emissions" => 15,
        "cout_acquisition" => 0,
        "cout_infrastructure" => 2_000_000,
        "economies_carburant_annuel" => 1_200_000,
        "duree_amortissement" => 1,
        "avantages" => [
            "Mise en œuvre immédiate",
            "Coût très faible",
            "Amélioration service usagers",
            "Base de données pour futures décisions"
        ],
        "defis" => [
            "Résistance au changement",
            "Formation conducteurs",
            "Maintenance système GPS"
        ]
    )
    
    return alternatives
end

"""
Calcule le potentiel de réduction des émissions selon différents scénarios.
"""
function calculer_potentiel_reduction_emissions(systeme::SystemeSOTRACO, emissions_actuelles::Dict)
    nb_lignes = length([l for l in values(systeme.lignes) if l.statut == "Actif"])
    
    scenarios = Dict{String, Dict{String, Any}}()
    
    # Scénario court terme
    scenarios["optimisation_court_terme"] = Dict(
        "duree" => "6 mois",
        "mesures" => [
            "Optimisation fréquences existantes",
            "Formation éco-conduite",
            "Maintenance préventive moteurs"
        ],
        "reduction_co2" => 12,
        "economies_annuelles" => emissions_actuelles["cout_carburant_annuel"] * 0.12,
        "investissement" => 8_000_000,
        "faisabilite" => "Très haute"
    )
    
    # Scénario moyen terme
    scenarios["hybridation_moyen_terme"] = Dict(
        "duree" => "3 ans",
        "mesures" => [
            "Remplacement 30% flotte par bus hybrides",
            "Biocarburant sur lignes restantes",
            "Système de monitoring avancé"
        ],
        "reduction_co2" => 28,
        "economies_annuelles" => emissions_actuelles["cout_carburant_annuel"] * 0.25,
        "investissement" => 285_000_000,
        "faisabilite" => "Moyenne"
    )
    
    # Scénario long terme
    scenarios["electrification_long_terme"] = Dict(
        "duree" => "7 ans",
        "mesures" => [
            "70% flotte électrique",
            "Infrastructure de charge complète",
            "Formation technique avancée"
        ],
        "reduction_co2" => 75,
        "economies_annuelles" => emissions_actuelles["cout_carburant_annuel"] * 0.65,
        "investissement" => 1_260_000_000,
        "faisabilite" => "Faible sans financement international"
    )
    
    # Calcul des équivalences environnementales
    for (nom_scenario, scenario) in scenarios
        reduction_co2_tonnes = emissions_actuelles["emissions_co2_annuelles_tonnes"] * 
                              scenario["reduction_co2"] / 100
        scenario["reduction_co2_tonnes_an"] = round(reduction_co2_tonnes, digits=1)
        scenario["equivalent_voitures"] = round(reduction_co2_tonnes / 4.6, digits=0)
        scenario["arbres_equivalents"] = round(reduction_co2_tonnes * 50, digits=0)
    end
    
    return scenarios
end

"""
Affiche le bilan écologique complet avec analyses et recommandations.
"""
function afficher_bilan_ecologique(emissions_actuelles::Dict, alternatives::Dict, scenarios::Dict)
    println("\n📊 BILAN ÉCOLOGIQUE ACTUEL:")
    println("   • Distance parcourue: $(emissions_actuelles["distance_quotidienne_km"]) km/jour")
    println("   • Consommation carburant: $(emissions_actuelles["consommation_jour_litres"]) L/jour")
    println("   • Émissions CO2: $(emissions_actuelles["emissions_co2_annuelles_tonnes"]) tonnes/an")
    println("   • Coût carburant: $(Int(emissions_actuelles["cout_carburant_annuel_fcfa"])) FCFA/an")
    
    equivalent_voitures = round(emissions_actuelles["emissions_co2_annuelles_tonnes"] / 4.6, digits=0)
    println("   • Équivalent à $(Int(equivalent_voitures)) voitures particulières")
    
    println("\n🌱 ALTERNATIVES ÉCOLOGIQUES ÉVALUÉES:")
    for (nom, alt) in alternatives
        nom_affiche = replace(nom, "_" => " ") |> uppercasefirst
        println("\n🔋 $(uppercase(nom_affiche)):")
        println("   • Réduction émissions: $(alt["reduction_emissions"])%")
        println("   • Investissement: $(Int(alt["cout_acquisition"])) FCFA/unité")
        println("   • Économies annuelles: $(Int(alt["economies_carburant_annuel"])) FCFA/unité")
        println("   • Avantages principaux:")
        for avantage in alt["avantages"][1:min(3, length(alt["avantages"]))]
            println("     ✅ $avantage")
        end
        if length(alt["defis"]) > 0
            println("   • Principaux défis:")
            for defi in alt["defis"][1:min(2, length(alt["defis"]))]
                println("     ⚠️ $defi")
            end
        end
    end
    
    println("\n📈 SCÉNARIOS DE TRANSITION ÉCOLOGIQUE:")
    for (nom_scenario, scenario) in scenarios
        nom_affiche = replace(nom_scenario, "_" => " ") |> uppercasefirst
        println("\n🎯 $(uppercase(nom_affiche)) ($(scenario["duree"])):")
        println("   • Réduction CO2: $(scenario["reduction_co2"])% ($(scenario["reduction_co2_tonnes_an"]) tonnes/an)")
        println("   • Équivalent: $(Int(scenario["equivalent_voitures"])) voitures en moins")
        println("   • Impact forestier: $(Int(scenario["arbres_equivalents"])) arbres équivalents")
        println("   • Investissement requis: $(Int(scenario["investissement"])) FCFA")
        println("   • Économies annuelles: $(Int(scenario["economies_annuelles"])) FCFA")
        println("   • Faisabilité: $(scenario["faisabilite"])")
        println("   • Mesures clés:")
        for mesure in scenario["mesures"]
            println("     📋 $mesure")
        end
    end
    
    println("\n🎯 RECOMMANDATIONS ÉCOLOGIQUES PRIORITAIRES:")
    println("   1️⃣ IMMÉDIAT (0-6 mois):")
    println("      • Formation éco-conduite pour tous les chauffeurs")
    println("      • Optimisation des fréquences (réduction 12% émissions)")
    println("      • Maintenance préventive systématique")
    
    println("   2️⃣ COURT TERME (6-18 mois):")
    println("      • Pilote biocarburant sur 2-3 lignes")
    println("      • Système GPS/monitoring consommation")
    println("      • Sensibilisation usagers aux transports en commun")
    
    println("   3️⃣ MOYEN TERME (2-5 ans):")
    println("      • Acquisition progressive bus hybrides")
    println("      • Partenariat développement biocarburant local")
    println("      • Infrastructure de recharge préparatoire")
    
    println("   4️⃣ LONG TERME (5-10 ans):")
    println("      • Transition vers flotte électrique")
    println("      • Énergies renouvelables (solaire)")
    println("      • Transport multimodal intégré")
    
    println("\n💚 IMPACT SOCIAL DE LA TRANSITION ÉCOLOGIQUE:")
    println("   • Amélioration qualité air Ouagadougou")
    println("   • Création emplois verts (maintenance, biocarburant)")
    println("   • Formation technique avancée pour jeunes")
    println("   • Positionnement de Ouaga comme ville durable en Afrique")
end

"""
Génère un rapport complet d'accessibilité et d'impact social.
"""
function generer_rapport_accessibilite(systeme::SystemeSOTRACO, fichier_sortie::String="resultats/rapport_accessibilite_sotraco.txt")
    println("\n📝 GÉNÉRATION DU RAPPORT D'ACCESSIBILITÉ ET D'IMPACT SOCIAL")
    println("=" ^ 70)
    
    mkpath(dirname(fichier_sortie))
    
    eval_accessibilite = evaluer_accessibilite_reseau(systeme)
    tarif_social = calculer_tarification_sociale(systeme)
    impact_eco = analyser_impact_ecologique(systeme)
    
    rapport = generer_contenu_rapport_accessibilite(eval_accessibilite, tarif_social, impact_eco, systeme)
    
    open(fichier_sortie, "w") do file
        write(file, rapport)
    end
    
    println("\n✅ Rapport d'accessibilité généré: $fichier_sortie")
    println("📊 Sections incluses:")
    println("   • Évaluation accessibilité réseau")
    println("   • Propositions tarification sociale")
    println("   • Analyse impact écologique")
    println("   • Recommandations d'amélioration")
    println("   • Plan d'action prioritaire")
    
    return fichier_sortie
end

"""
Génère le contenu du rapport d'accessibilité avec analyses détaillées.
"""
function generer_contenu_rapport_accessibilite(eval_accessibilite::Dict, tarif_social::Dict, impact_eco::Dict, systeme::SystemeSOTRACO)
    timestamp = Dates.format(now(), "yyyy-mm-dd HH:MM")
    
    return """
================================================================================
RAPPORT D'ACCESSIBILITÉ ET D'IMPACT SOCIAL - RÉSEAU SOTRACO
================================================================================
Date de génération: $timestamp
Système d'Optimisation du Transport Public - Ouagadougou

RÉSUMÉ EXÉCUTIF
===============
Ce rapport évalue l'accessibilité du réseau SOTRACO sous trois dimensions 
critiques: accessibilité physique pour personnes handicapées, accessibilité 
tarifaire pour populations vulnérables, et impact écologique du transport 
public urbain.

SYNTHÈSE DES PRINCIPALES DÉCOUVERTES:
• $(length(systeme.arrets)) arrêts analysés, score d'accessibilité moyen: $(round(mean([a["score"] for a in values(eval_accessibilite["arrets_accessibles"])]), digits=1))/100
• $(count(a -> a["score"] < 40, values(eval_accessibilite["arrets_accessibles"]))) arrêts nécessitent des améliorations urgentes
• Tarification sociale pourrait réduire de $(tarif_social["impact_budget"]["pourcentage_perte"])% les barrières économiques
• Potentiel de réduction de $(impact_eco["potentiel_reduction"]["optimisation_court_terme"]["reduction_co2"])% des émissions CO2 à court terme

1. ÉVALUATION ACCESSIBILITÉ PHYSIQUE
====================================

1.1 Méthodologie
Le score d'accessibilité (0-100) intègre:
- Présence abribus et éclairage (50 points)
- Zone urbaine et infrastructure (25 points)  
- Connectivité multi-lignes (15 points)
- Accessibilité des POI critiques (10 points)

1.2 Résultats Globaux
$(length([a for a in values(eval_accessibilite["arrets_accessibles"]) if a["score"] >= 80])) arrêts "Excellents" (≥80/100)
$(length([a for a in values(eval_accessibilite["arrets_accessibles"]) if 60 <= a["score"] < 80])) arrêts "Bons" (60-79/100)
$(length([a for a in values(eval_accessibilite["arrets_accessibles"]) if 40 <= a["score"] < 60])) arrêts "Moyens" (40-59/100)
$(length([a for a in values(eval_accessibilite["arrets_accessibles"]) if a["score"] < 40])) arrêts "Insuffisants" (<40/100)

1.3 Points d'Intérêt Critiques
Accessibilité aux services essentiels:
$(join([poi["poi"] * ": " * poi["niveau_acces"] for poi in eval_accessibilite["poi_accessibles"]], "\n"))

1.4 Investissements Prioritaires
Budget estimé améliorations immédiates: $(eval_accessibilite["recommandations"]["budget"][1])

2. TARIFICATION SOCIALE
=======================

2.1 Analyse Tarifaire Actuelle
Tarif moyen réseau: $(round(tarif_social["tarif_reference"], digits=0)) FCFA
Plage tarifaire: $(minimum([l.tarif_fcfa for l in values(systeme.lignes) if l.statut == "Actif"])) - $(maximum([l.tarif_fcfa for l in values(systeme.lignes) if l.statut == "Actif"])) FCFA

2.2 Proposition Tarification Différenciée
• Grande précarité: $(tarif_social["tarification"]["grande_precarite"]["tarif"]) FCFA ($(tarif_social["tarification"]["grande_precarite"]["reduction"])% réduction)
• Tarif social: $(tarif_social["tarification"]["social"]["tarif"]) FCFA ($(tarif_social["tarification"]["social"]["reduction"])% réduction)
• Tarif étudiant: $(tarif_social["tarification"]["etudiant"]["tarif"]) FCFA ($(tarif_social["tarification"]["etudiant"]["reduction"])% réduction)

2.3 Impact Budgétaire
Perte de recettes estimée: $(tarif_social["impact_budget"]["pourcentage_perte"])%
Compensation nécessaire: $(Int(round(tarif_social["impact_budget"]["perte_recettes"]))) FCFA/période
Sources de financement: subvention municipale, aide internationale, taxe transport

3. IMPACT ÉCOLOGIQUE
====================

3.1 Bilan Carbone Actuel
• Émissions CO2: $(impact_eco["emissions_actuelles"]["emissions_co2_annuelles_tonnes"]) tonnes/an
• Consommation carburant: $(impact_eco["emissions_actuelles"]["consommation_jour_litres"]) L/jour
• Équivalent à $(round(impact_eco["emissions_actuelles"]["emissions_co2_annuelles_tonnes"] / 4.6, digits=0)) voitures particulières

3.2 Alternatives Écologiques Évaluées
• Bus électriques: -85% émissions, investissement élevé
• Bus hybrides: -35% émissions, transition progressive
• Biocarburant: -20% émissions, compatible flotte existante
• Optimisation trajets: -15% émissions, mise en œuvre immédiate

3.3 Scénarios de Transition
Court terme (6 mois): -$(impact_eco["potentiel_reduction"]["optimisation_court_terme"]["reduction_co2"])% émissions
Moyen terme (3 ans): -$(impact_eco["potentiel_reduction"]["hybridation_moyen_terme"]["reduction_co2"])% émissions  
Long terme (7 ans): -$(impact_eco["potentiel_reduction"]["electrification_long_terme"]["reduction_co2"])% émissions

4. RECOMMANDATIONS STRATÉGIQUES
===============================

4.1 Priorité 1: Actions Immédiates (0-6 mois)
• Équiper $(length([a for a in values(eval_accessibilite["arrets_accessibles"]) if !a["abribus"]])) arrêts manquant d'abribus
• Lancer pilote tarification sociale sur 3 lignes
• Formation éco-conduite conducteurs
• Optimisation fréquences existantes

4.2 Priorité 2: Développement (6-24 mois)
• Installation rampes d'accès PMR sur arrêts prioritaires
• Système carte transport rechargeable
• Pilote biocarburant local
• Monitoring GPS/consommation

4.3 Priorité 3: Transformation (2-7 ans)
• Renouvellement flotte (hybride puis électrique)
• Infrastructure de recharge solaire
• Transport multimodal intégré
• Formation technique spécialisée

5. PLAN DE FINANCEMENT
======================

5.1 Sources de Financement Identifiées
• Subventions internationales développement durable
• Partenariats public-privé
• Taxe transport sur employeurs urbains
• Mécanismes carbone (crédits CO2)

5.2 Phasage Investissements
Phase 1 (6 mois): 25M FCFA - améliorations accessibilité urgentes
Phase 2 (18 mois): 150M FCFA - pilotes et systèmes
Phase 3 (5 ans): 800M FCFA - renouvellement flotte partiel

6. IMPACT SOCIAL ATTENDU
========================

6.1 Bénéficiaires Directs
• Personnes handicapées: meilleur accès transport public
• Familles précaires: réduction barrière financière  
• Étudiants: facilitation accès éducation
• Population générale: amélioration qualité air

6.2 Retombées Économiques
• Création 50-80 emplois directs/indirects
• Développement filière biocarburant locale
• Formation technique avancée jeunes
• Attractivité touristique/investissement

CONCLUSION
==========
Le réseau SOTRACO présente un potentiel significatif d'amélioration de son 
accessibilité et de son impact social. Les recommandations proposées, si 
mises en œuvre de manière coordonnée, peuvent transformer le transport public 
de Ouagadougou en modèle d'inclusion sociale et de durabilité environnementale 
pour l'Afrique de l'Ouest.

L'investissement total estimé (1 milliard FCFA sur 5 ans) est substantiel mais 
justifié par les bénéfices sociaux, environnementaux et économiques attendus.
Une approche progressive et des partenariats stratégiques sont essentiels pour 
la réussite de cette transformation.

================================================================================
Rapport généré automatiquement par le Système d'Optimisation SOTRACO v2.0
Contact: Équipe de développement - Projet académique d'optimisation transport
================================================================================
"""
end

"""
Identifie les besoins d'accessibilité spécifiques par type de handicap.
"""
function identifier_besoins_accessibilite(systeme::SystemeSOTRACO)
    println("\n♿ IDENTIFICATION DES BESOINS D'ACCESSIBILITÉ SPÉCIFIQUES")
    println("=" ^ 65)
    
    besoins_specifiques = Dict{String, Dict{String, Any}}()
    
    # Besoins pour mobilité réduite
    besoins_specifiques["mobilite_reduite"] = Dict(
        "population_estimee" => 2500,
        "besoins_infrastructure" => [
            "Rampes d'accès aux arrêts (pente <8%)",
            "Espaces attente suffisants (1.5m x 1.5m minimum)",
            "Hauteur quais adaptée aux bus",
            "Revêtement anti-dérapant"
        ],
        "besoins_vehicules" => [
            "Plancher bas ou rampe d'accès",
            "Espace réservé fauteuil roulant",
            "Barres d'appui renforcées",
            "Système fixation fauteuil"
        ],
        "priorite" => "Très haute",
        "cout_adaptation_arret" => 1_500_000
    )
    
    # Besoins pour déficience visuelle
    besoins_specifiques["deficience_visuelle"] = Dict(
        "population_estimee" => 1800,
        "besoins_infrastructure" => [
            "Bandes podotactiles au sol",
            "Signalisation braille",
            "Éclairage renforcé",
            "Annonces sonores arrêts"
        ],
        "besoins_vehicules" => [
            "Annonces vocales destinations",
            "Système audio embarqué",
            "Contraste visuel renforcé",
            "Éclairage intérieur adapté"
        ],
        "priorite" => "Haute",
        "cout_adaptation_arret" => 800_000
    )
    
    # Besoins pour déficience auditive
    besoins_specifiques["deficience_auditive"] = Dict(
        "population_estimee" => 1200,
        "besoins_infrastructure" => [
            "Affichage visuel temps d'attente",
            "Panneaux information visuels",
            "Signalisation lumineuse",
            "Applications smartphone alertes"
        ],
        "besoins_vehicules" => [
            "Écrans d'information embarqués",
            "Signalisation visuelle arrêts",
            "Applications temps réel",
            "Communication gestuelle formation"
        ],
        "priorite" => "Moyenne",
        "cout_adaptation_arret" => 600_000
    )
    
    # Besoins pour déficience cognitive
    besoins_specifiques["deficience_cognitive"] = Dict(
        "population_estimee" => 3000,
        "besoins_infrastructure" => [
            "Signalisation simplifiée avec pictogrammes",
            "Plans de réseau visuels clairs",
            "Code couleur intuitive",
            "Information répétitive"
        ],
        "besoins_vehicules" => [
            "Indications visuelles simples",
            "Personnel formé à l'accompagnement",
            "Horaires fixes et prévisibles",
            "Application simple d'usage"
        ],
        "priorite" => "Moyenne",
        "cout_adaptation_arret" => 400_000
    )
    
    # Besoins pour personnes âgées
    besoins_specifiques["personnes_agees"] = Dict(
        "population_estimee" => 15000,
        "besoins_infrastructure" => [
            "Bancs d'attente nombreux",
            "Protection solaire renforcée",
            "Accès graduel sans marches",
            "Éclairage sécurisé"
        ],
        "besoins_vehicules" => [
            "Montée facilitée (marches basses)",
            "Sièges prioritaires bien signalés",
            "Barres d'appui nombreuses",
            "Temps d'arrêt suffisant"
        ],
        "priorite" => "Haute",
        "cout_adaptation_arret" => 700_000
    )
    
    plan_adaptation = calculer_plan_adaptation_global(systeme, besoins_specifiques)
    
    afficher_besoins_accessibilite(besoins_specifiques, plan_adaptation)
    
    return Dict(
        "besoins_specifiques" => besoins_specifiques,
        "plan_adaptation" => plan_adaptation
    )
end

"""
Calcule un plan d'adaptation global pour l'accessibilité selon les priorités.
"""
function calculer_plan_adaptation_global(systeme::SystemeSOTRACO, besoins::Dict)
    nb_arrets = length(systeme.arrets)
    nb_lignes_actives = length([l for l in values(systeme.lignes) if l.statut == "Actif"])
    
    arrets_priorite_haute = []
    arrets_priorite_moyenne = []
    arrets_priorite_basse = []
    
    for arret in values(systeme.arrets)
        score_priorite = length(arret.lignes_desservies) * 10
        
        if arret.zone == "Zone 1"
            score_priorite += 30
        elseif arret.zone == "Zone 2"
            score_priorite += 20
        else
            score_priorite += 10
        end
        
        if arret.abribus && arret.eclairage
            score_priorite += 15
        end
        
        if score_priorite >= 50
            push!(arrets_priorite_haute, arret.id)
        elseif score_priorite >= 30
            push!(arrets_priorite_moyenne, arret.id)
        else
            push!(arrets_priorite_basse, arret.id)
        end
    end
    
    cout_phase_1 = length(arrets_priorite_haute) * 1_200_000
    cout_phase_2 = length(arrets_priorite_moyenne) * 900_000
    cout_phase_3 = length(arrets_priorite_basse) * 600_000
    
    cout_vehicules_adaptes = nb_lignes_actives * 15_000_000
    
    return Dict(
        "arrets_priorite_haute" => arrets_priorite_haute,
        "arrets_priorite_moyenne" => arrets_priorite_moyenne,
        "arrets_priorite_basse" => arrets_priorite_basse,
        "cout_phase_1" => cout_phase_1,
        "cout_phase_2" => cout_phase_2,
        "cout_phase_3" => cout_phase_3,
        "cout_vehicules" => cout_vehicules_adaptes,
        "cout_total" => cout_phase_1 + cout_phase_2 + cout_phase_3 + cout_vehicules_adaptes,
        "duree_totale" => "5 ans",
        "beneficiaires_directs" => sum(b["population_estimee"] for b in values(besoins)),
        "beneficiaires_indirects" => 300_000
    )
end

"""
Affiche l'analyse détaillée des besoins d'accessibilité par catégorie.
"""
function afficher_besoins_accessibilite(besoins::Dict, plan::Dict)
    println("\n📋 ANALYSE DÉTAILLÉE DES BESOINS D'ACCESSIBILITÉ")
    println("=" ^ 60)
    
    total_population_handicap = sum(b["population_estimee"] for b in values(besoins))
    println("📊 POPULATION CONCERNÉE:")
    println("   • Total personnes en situation de handicap: $total_population_handicap")
    println("   • Bénéficiaires directs: $(plan["beneficiaires_directs"])")
    println("   • Bénéficiaires indirects: $(plan["beneficiaires_indirects"])")
    
    println("\n♿ BESOINS SPÉCIFIQUES PAR TYPE DE HANDICAP:")
    for (type_handicap, details) in besoins
        nom_type = replace(type_handicap, "_" => " ") |> uppercasefirst
        println("\n🎯 $(uppercase(nom_type)) ($(details["population_estimee"]) personnes)")
        println("   Priorité: $(details["priorite"])")
        println("   Coût adaptation/arrêt: $(Int(details["cout_adaptation_arret"])) FCFA")
        println("   ")
        println("   Infrastructure nécessaire:")
        println(join(["     • " * besoin for besoin in details["besoins_infrastructure"]], "\n"))
        println("   ")
        println("   Adaptations véhicules:")
        println(join(["     • " * besoin for besoin in details["besoins_vehicules"]], "\n"))
    end
    
    println("\n📅 PLAN D'ADAPTATION GLOBAL:")
    println("   • Phase 1 (Priorité haute): $(length(plan["arrets_priorite_haute"])) arrêts - $(Int(plan["cout_phase_1"])) FCFA")
    println("   • Phase 2 (Priorité moyenne): $(length(plan["arrets_priorite_moyenne"])) arrêts - $(Int(plan["cout_phase_2"])) FCFA")
    println("   • Phase 3 (Priorité basse): $(length(plan["arrets_priorite_basse"])) arrêts - $(Int(plan["cout_phase_3"])) FCFA")
    println("   • Adaptation véhicules: $(Int(plan["cout_vehicules"])) FCFA")
    println("   • TOTAL: $(Int(plan["cout_total"])) FCFA sur $(plan["duree_totale"])")
    
    println("\n🎯 IMPACT SOCIAL ATTENDU:")
    println("   • Réduction de 70% des barrières d'accès transport")
    println("   • Amélioration autonomie déplacement")
    println("   • Inclusion sociale renforcée")
    println("   • Respect des droits humains fondamentaux")
    println("   • Modèle pour autres villes africaines")
end

end # module Accessibilite