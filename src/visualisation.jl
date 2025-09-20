"""
Module Visualisation - Visualisations ASCII et tableaux de performance
"""
module Visualisation

using Printf, Statistics
using ..Types

export afficher_carte_reseau_ascii, generer_graphique_frequentation_ascii
export afficher_tableau_performance_lignes, afficher_dashboard_ascii

"""
Affichage de la carte ASCII du réseau SOTRACO
"""
function afficher_carte_reseau_ascii(systeme::SystemeSOTRACO)
    println("\n🗺️ CARTE RÉSEAU SOTRACO - REPRÉSENTATION ASCII")
    println("=" ^ 70)

    if !systeme.donnees_chargees
        println("❌ Données non chargées!")
        return
    end

    carte = generer_carte_ouagadougou_detaillee()
    println(carte)

    afficher_statistiques_zones_detaillees(systeme)
    afficher_legende_carte(systeme)
end

"""
Génération de la carte ASCII de Ouagadougou
"""
function generer_carte_ouagadougou_detaillee()
    return """

              RÉSEAU DE TRANSPORT SOTRACO - OUAGADOUGOU
                     (Représentation schématique)

    ╔═══════════════════════════════════════════════════════════╗
    ║                    ZONE 1 - CENTRE-VILLE                 ║
    ║    🏛️  ──────────── [GARE ROUTIÈRE] ──────────── 🏛️      ║
    ║     │                      │                      │       ║
    ║     │         🚌L1,L10     │      🚌L2,L3         │       ║
    ║     │                      │                      │       ║
    ║  ZONE 2              ┌─────┼─────┐              ZONE 3   ║
    ║   Wemtenga           │     │     │             Ouaga 2000║
    ║     🚌 ──────────────┼─────●─────┼──────────────── 🚌     ║
    ║   L4,L5              │  [CENTRE] │              L6,L7    ║
    ║     │                │     │     │                │      ║
    ║     │             🚌L8,L9  │   🚌L11,L12          │      ║
    ║  ZONE 4              │     │     │              ZONE 5   ║
    ║   Tanghin            │     │     │              Kossodo  ║
    ║     🚌 ──────────────┴─────┼─────┴──────────────── 🚌     ║
    ║   L13,L14                  │                    L15,L16  ║
    ║                            │                             ║
    ║                      [PÉRIPHÉRIE]                       ║
    ║                         🚌L17+                          ║
    ║                                                         ║
    ╚═══════════════════════════════════════════════════════════╝

    🏛️ = Bâtiments institutionnels    ● = Carrefour principal
    🚌 = Station de bus majeure       │,─ = Axes de transport
    [NOM] = Terminal important        L## = Numéros de lignes
    """
end

"""
Affichage des statistiques par zone géographique
"""
function afficher_statistiques_zones_detaillees(systeme::SystemeSOTRACO)
    zones_stats = calculer_statistiques_zones(systeme)
    
    println("\n📊 ANALYSE DÉTAILLÉE PAR ZONE:")
    println("┌─────────────┬─────────┬─────────────┬─────────────┬──────────────┐")
    println("│ Zone        │ Arrêts  │ Équipement  │ Passagers   │ Performance  │")
    println("├─────────────┼─────────┼─────────────┼─────────────┼──────────────┤")
    
    zones_triees = sort(collect(zones_stats), by=x->x[2]["arrets_total"], rev=true)
    
    for (zone, stats) in zones_triees
        zone_nom = rpad(zone, 11)
        nb_arrets = lpad("$(stats["arrets_total"])", 7)
        taux_equipement = round(stats["arrets_equipes"] / max(1, stats["arrets_total"]) * 100, digits=0)
        equipement_str = lpad("$(Int(taux_equipement))%", 11)
        passagers_str = lpad("$(stats["passagers_total"])", 11)
        
        performance = if taux_equipement >= 80 && stats["passagers_total"] > 200
            "Excellent  "
        elseif taux_equipement >= 60 && stats["passagers_total"] > 100
            "Bon        "
        elseif taux_equipement >= 40 || stats["passagers_total"] > 50
            "Moyen      "
        else
            "À améliorer"
        end
        
        println("│ $zone_nom │$nb_arrets │$equipement_str │$passagers_str │ $performance │")
    end
    
    println("└─────────────┴─────────┴─────────────┴─────────────┴──────────────┘")
    
    total_arrets = sum(stats["arrets_total"] for (zone, stats) in zones_stats)
    total_equipes = sum(stats["arrets_equipes"] for (zone, stats) in zones_stats)
    total_passagers = sum(stats["passagers_total"] for (zone, stats) in zones_stats)
    
    println("\n📈 RÉSUMÉ GLOBAL:")
    println("   • Total arrêts: $total_arrets")
    println("   • Taux équipement global: $(round(total_equipes/total_arrets*100, digits=1))%")
    println("   • Total passagers: $total_passagers")
    println("   • Zones analysées: $(length(zones_stats))")
end

"""
Calcul des statistiques par zone
"""
function calculer_statistiques_zones(systeme::SystemeSOTRACO)
    zones_stats = Dict{String, Dict{String, Int}}()
    
    for arret in values(systeme.arrets)
        zone = arret.zone
        if !haskey(zones_stats, zone)
            zones_stats[zone] = Dict(
                "arrets_total" => 0,
                "arrets_equipes" => 0,
                "passagers_total" => 0
            )
        end
        
        zones_stats[zone]["arrets_total"] += 1
        if arret.abribus && arret.eclairage
            zones_stats[zone]["arrets_equipes"] += 1
        end
        
        freq_arret = [d for d in systeme.frequentation if d.arret_id == arret.id]
        zones_stats[zone]["passagers_total"] += sum(d.montees + d.descentes for d in freq_arret)
    end
    
    return zones_stats
end

"""
Affichage de la légende et analyse de connectivité
"""
function afficher_legende_carte(systeme::SystemeSOTRACO)
    println("\n🗂️ LÉGENDE DE LA CARTE:")
    println("┌──────────────────────────────────────────────────────────────┐")
    println("│ 🚌 = Station majeure      │ 🏛️ = Bâtiment institutionnel     │")
    println("│ ● = Carrefour principal    │ [NOM] = Terminal important       │")
    println("│ L## = Numéros de lignes   │ ─,│ = Axes de transport          │")
    println("│ Zone 1 = Centre-ville     │ Zones 2-5 = Périphérie          │")
    println("└──────────────────────────────────────────────────────────────┘")
    
    connexions = analyser_connectivite_reseau(systeme)
    
    println("\n🔗 CONNECTIVITÉ DU RÉSEAU:")
    println("   • Lignes interconnectées: $(connexions["lignes_connectees"])")
    println("   • Hubs de correspondance: $(connexions["hubs_correspondance"])")
    println("   • Couverture géographique: $(connexions["couverture_pct"])%")
end

"""
Analyse de la connectivité du réseau
"""
function analyser_connectivite_reseau(systeme::SystemeSOTRACO)
    hubs = count(a -> length(a.lignes_desservies) >= 3, values(systeme.arrets))
    
    lignes_actives = [l for l in values(systeme.lignes) if l.statut == "Actif"]
    connexions = 0
    
    for i in 1:length(lignes_actives)
        for j in (i+1):length(lignes_actives)
            ligne1 = lignes_actives[i]
            ligne2 = lignes_actives[j]
            if !isempty(intersect(ligne1.arrets, ligne2.arrets))
                connexions += 1
            end
        end
    end
    
    zones_couvertes = length(unique([a.zone for a in values(systeme.arrets)]))
    couverture_pct = round(zones_couvertes / 5 * 100, digits=0)
    
    return Dict(
        "lignes_connectees" => connexions,
        "hubs_correspondance" => hubs,
        "couverture_pct" => couverture_pct
    )
end

"""
Génération du graphique de fréquentation 24h en ASCII
"""
function generer_graphique_frequentation_ascii(heures_pointe::Vector{Pair{Int, Int}})
    println("\n📊 GRAPHIQUE DE FRÉQUENTATION 24H (ASCII)")
    println("=" ^ 65)

    if isempty(heures_pointe)
        println("❌ Aucune donnée de fréquentation disponible")
        return
    end

    freq_dict = Dict(heures_pointe)
    max_freq = maximum(f for (h, f) in heures_pointe)
    
    println("Passagers                                    Heure")
    println("    │                                           │")
    
    echelle_max = 40
    
    for heure in 0:23
        freq = get(freq_dict, heure, 0)
        generer_barre_avancee(heure, freq, max_freq, echelle_max)
    end
    
    println("    └" * "─" ^ (echelle_max + 5) * "┘")
    println("      0" * " " ^ (echelle_max - 10) * "Max: $max_freq")
    
    afficher_analyse_temporelle(freq_dict, max_freq)
    afficher_recommandations_horaires(freq_dict)
end

"""
Génération d'une barre de graphique avec indicateurs visuels
"""
function generer_barre_avancee(heure::Int, freq::Int, max_freq::Int, echelle_max::Int)
    if max_freq > 0
        longueur = round(Int, (freq / max_freq) * echelle_max)
    else
        longueur = 0
    end
    
    char_barre = if freq > max_freq * 0.8
        "█"
    elseif freq > max_freq * 0.6
        "▓"
    elseif freq > max_freq * 0.3
        "▒"
    else
        "░"
    end
    
    periode = if 6 <= heure <= 9
        "🌅"
    elseif 10 <= heure <= 15
        "☀️"
    elseif 16 <= heure <= 20
        "🌆"
    else
        "🌙"
    end
    
    barre = char_barre ^ longueur
    espaces = " " ^ (echelle_max - longueur)
    
    @printf "%2dh │%-40s│ %s %4d\n" heure (barre * espaces) periode freq
end

"""
Analyse temporelle des données de fréquentation
"""
function afficher_analyse_temporelle(freq_dict::Dict{Int, Int}, max_freq::Int)
    println("\n📈 ANALYSE TEMPORELLE:")
    
    periodes = [
        ("Nuit (0h-5h)", 0:5),
        ("Matin (6h-11h)", 6:11),
        ("Après-midi (12h-17h)", 12:17),
        ("Soirée (18h-23h)", 18:23)
    ]
    
    for (nom_periode, heures) in periodes
        total_periode = sum(get(freq_dict, h, 0) for h in heures)
        moyenne_periode = total_periode / length(heures)
        intensite = if moyenne_periode > max_freq * 0.6
            "🔴 FORTE"
        elseif moyenne_periode > max_freq * 0.3
            "🟡 MODÉRÉE"
        else
            "🔵 FAIBLE"
        end
        
        println("   • $nom_periode: $(round(moyenne_periode, digits=0)) pass./h ($intensite)")
    end
    
    heures_triees = sort(collect(freq_dict), by=x->x[2], rev=true)
    if length(heures_triees) >= 3
        println("\n🏔️ PICS ET CREUX:")
        println("   • Pic principal: $(heures_triees[1][1])h ($(heures_triees[1][2]) passagers)")
        println("   • Pic secondaire: $(heures_triees[2][1])h ($(heures_triees[2][2]) passagers)")
        
        heure_creux = heures_triees[end]
        println("   • Creux principal: $(heure_creux[1])h ($(heure_creux[2]) passagers)")
    end
end

"""
Recommandations opérationnelles basées sur l'analyse horaire
"""
function afficher_recommandations_horaires(freq_dict::Dict{Int, Int})
    println("\n💡 RECOMMANDATIONS OPÉRATIONNELLES:")
    
    total_quotidien = sum(values(freq_dict))
    
    heures_renforcement = [h for (h, f) in freq_dict if f > total_quotidien / 24 * 1.5]
    if !isempty(heures_renforcement)
        println("   🚀 RENFORCEMENT requis:")
        for heure in sort(heures_renforcement)
            println("      - $(heure)h: +25% de fréquence recommandée")
        end
    end
    
    heures_economie = [h for (h, f) in freq_dict if f < total_quotidien / 24 * 0.5]
    if !isempty(heures_economie)
        println("   💰 ÉCONOMIES possibles:")
        for heure in sort(heures_economie)
            println("      - $(heure)h: réduction de fréquence possible")
        end
    end
    
    println("   📋 ACTIONS PRIORITAIRES:")
    println("      1. Service renforcé aux heures de pointe")
    println("      2. Buses articulés pour pics de demande")
    println("      3. Information voyageurs en temps réel")
    println("      4. Régulation automatique selon affluence")
end

"""
Tableau de performance détaillé des lignes
"""
function afficher_tableau_performance_lignes(systeme::SystemeSOTRACO)
    println("\n📋 TABLEAU DE PERFORMANCE DÉTAILLÉ DES LIGNES")
    println("=" ^ 80)

    println("┌────┬─────────────────────┬──────────┬─────────┬──────────┬─────────────┐")
    println("│ ID │ Nom Ligne          │ Distance │ Tarif   │ Fréq.    │ Performance │")
    println("│    │                    │   (km)   │ (FCFA)  │  (min)   │   (Score)   │")
    println("├────┼─────────────────────┼──────────┼─────────┼──────────┼─────────────┤")

    lignes_performance = []
    
    for ligne in values(systeme.lignes)
        if ligne.statut == "Actif"
            freq_ligne = [d for d in systeme.frequentation if d.ligne_id == ligne.id]
            score_perf = calculer_score_performance_ligne(ligne, freq_ligne)
            push!(lignes_performance, (ligne, score_perf, length(freq_ligne)))
        end
    end

    sort!(lignes_performance, by=x->x[2], rev=true)

    for (i, (ligne, score, nb_mesures)) in enumerate(lignes_performance[1:min(10, length(lignes_performance))])
        id_str = lpad("$(ligne.id)", 2)
        nom_tronque = length(ligne.nom) > 19 ? ligne.nom[1:16] * "..." : ligne.nom
        nom_str = rpad(nom_tronque, 19)
        dist_str = lpad(@sprintf("%.1f", ligne.distance_km), 8)
        tarif_str = lpad("$(ligne.tarif_fcfa)", 7)
        freq_str = lpad("$(ligne.frequence_min)", 8)
        
        score_str, indicateur = if score >= 80
            ("$(round(score, digits=0))%", "🟢")
        elseif score >= 60
            ("$(round(score, digits=0))%", "🟡")
        elseif score >= 40
            ("$(round(score, digits=0))%", "🟠")
        else
            ("$(round(score, digits=0))%", "🔴")
        end
        
        perf_str = rpad("$indicateur $score_str", 11)
        
        println("│$id_str │ $nom_str │$dist_str │$tarif_str │$freq_str │ $perf_str │")
    end

    println("└────┴─────────────────────┴──────────┴─────────┴──────────┴─────────────┘")

    afficher_statistiques_performance_globale(lignes_performance)
end

"""
Calcul du score de performance d'une ligne
"""
function calculer_score_performance_ligne(ligne::LigneBus, freq_ligne::Vector{DonneeFrequentation})
    score = 0.0
    
    if !isempty(freq_ligne)
        total_passagers = sum(d.montees + d.descentes for d in freq_ligne)
        score_frequentation = min(40.0, (total_passagers / 1000.0) * 40)
        score += score_frequentation
    end
    
    if ligne.distance_km > 0
        ratio_tarif_distance = ligne.tarif_fcfa / ligne.distance_km
        score_efficacite = min(30.0, (ratio_tarif_distance / 20.0) * 30)
        score += score_efficacite
    end
    
    if !isempty(freq_ligne)
        taux_occ = [d.occupation_bus / d.capacite_bus for d in freq_ligne if d.capacite_bus > 0]
        if !isempty(taux_occ)
            occupation_moyenne = mean(taux_occ)
            if occupation_moyenne <= 0.7
                score_occupation = (occupation_moyenne / 0.7) * 30
            else
                score_occupation = 30 - ((occupation_moyenne - 0.7) / 0.3) * 10
            end
            score += max(0, score_occupation)
        end
    end
    
    return min(100.0, score)
end

"""
Statistiques de performance globale
"""
function afficher_statistiques_performance_globale(lignes_performance::Vector)
    if isempty(lignes_performance)
        return
    end
    
    scores = [score for (ligne, score, nb_mesures) in lignes_performance]
    
    println("\n📊 STATISTIQUES DE PERFORMANCE:")
    println("   • Score moyen du réseau: $(round(mean(scores), digits=1))%")
    println("   • Meilleure ligne: $(round(maximum(scores), digits=1))%")
    println("   • Ligne à améliorer: $(round(minimum(scores), digits=1))%")
    
    excellentes = count(s -> s >= 80, scores)
    bonnes = count(s -> 60 <= s < 80, scores)
    moyennes = count(s -> 40 <= s < 60, scores)
    faibles = count(s -> s < 40, scores)
    
    println("\n🎯 RÉPARTITION QUALITATIVE:")
    println("   • Excellentes (≥80%): $excellentes lignes")
    println("   • Bonnes (60-79%): $bonnes lignes")
    println("   • Moyennes (40-59%): $moyennes lignes")
    println("   • À améliorer (<40%): $faibles lignes")
    
    if faibles > 0
        println("\n⚠️ RECOMMANDATION: Focus prioritaire sur les $faibles lignes sous-performantes")
    end
end

"""
Dashboard complet du système
"""
function afficher_dashboard_ascii(systeme::SystemeSOTRACO)
    println("\n🎛️ DASHBOARD SOTRACO - VUE D'ENSEMBLE")
    println("=" ^ 70)
    
    afficher_metriques_principales(systeme)
    afficher_etat_reseau(systeme)
    afficher_alertes_dashboard(systeme)
end

"""
Métriques principales du système
"""
function afficher_metriques_principales(systeme::SystemeSOTRACO)
    println("📊 MÉTRIQUES PRINCIPALES:")
    println("┌─────────────────┬──────────────┬─────────────────┬──────────────────┐")
    println("│ Arrêts Total    │ Lignes Active│ Pass. Quotidien │ Taux Occupation  │")
    println("├─────────────────┼──────────────┼─────────────────┼──────────────────┤")
    
    total_arrets = length(systeme.arrets)
    lignes_actives = count(l -> l.statut == "Actif", values(systeme.lignes))
    
    passagers_quotidien = if !isempty(systeme.frequentation)
        total_pass = sum(d.montees + d.descentes for d in systeme.frequentation)
        dates_uniques = length(unique([d.date for d in systeme.frequentation]))
        round(total_pass / max(1, dates_uniques), digits=0)
    else
        0
    end
    
    taux_occupation = if !isempty(systeme.frequentation)
        taux = [d.occupation_bus/d.capacite_bus for d in systeme.frequentation if d.capacite_bus > 0]
        isempty(taux) ? 0.0 : round(mean(taux) * 100, digits=1)
    else
        0.0
    end
    
    arrets_str = lpad("$total_arrets", 15)
    lignes_str = lpad("$lignes_actives", 12)
    pass_str = lpad("$(Int(passagers_quotidien))", 15)
    occ_str = lpad("$taux_occupation%", 16)
    
    println("│$arrets_str │$lignes_str │$pass_str │$occ_str │")
    println("└─────────────────┴──────────────┴─────────────────┴──────────────────┘")
end

"""
État général du réseau
"""
function afficher_etat_reseau(systeme::SystemeSOTRACO)
    println("\n🔍 ÉTAT DU RÉSEAU:")
    
    sante_globale = calculer_sante_reseau(systeme)
    
    if sante_globale >= 80
        etat_icon = "🟢"
        etat_text = "EXCELLENT"
    elseif sante_globale >= 60
        etat_icon = "🟡"
        etat_text = "BON"
    elseif sante_globale >= 40
        etat_icon = "🟠"
        etat_text = "MOYEN"
    else
        etat_icon = "🔴"
        etat_text = "CRITIQUE"
    end
    
    println("   État général: $etat_icon $etat_text ($(round(sante_globale, digits=0))%)")
    
    composants = [
        ("Infrastructure", calculer_score_infrastructure(systeme)),
        ("Fréquentation", calculer_score_frequentation(systeme)),
        ("Efficacité", calculer_score_efficacite(systeme))
    ]
    
    for (composant, score) in composants
        icon = score >= 70 ? "✅" : score >= 50 ? "⚠️" : "❌"
        println("   $composant: $icon $(round(score, digits=0))%")
    end
end

"""
Calcul de la santé globale du réseau
"""
function calculer_sante_reseau(systeme::SystemeSOTRACO)
    if !systeme.donnees_chargees
        return 0.0
    end
    
    score_infra = calculer_score_infrastructure(systeme)
    score_freq = calculer_score_frequentation(systeme)
    score_eff = calculer_score_efficacite(systeme)
    
    return (score_infra + score_freq + score_eff) / 3
end

"""
Score d'infrastructure
"""
function calculer_score_infrastructure(systeme::SystemeSOTRACO)
    if isempty(systeme.arrets)
        return 0.0
    end
    
    arrets_equipes = count(a -> a.abribus && a.eclairage, values(systeme.arrets))
    taux_equipement = arrets_equipes / length(systeme.arrets)
    
    return taux_equipement * 100
end

"""
Score de fréquentation
"""
function calculer_score_frequentation(systeme::SystemeSOTRACO)
    if isempty(systeme.frequentation)
        return 50.0
    end
    
    total_passagers = sum(d.montees + d.descentes for d in systeme.frequentation)
    score = min(100.0, (total_passagers / 10000.0) * 100)
    
    return score
end

"""
Score d'efficacité
"""
function calculer_score_efficacite(systeme::SystemeSOTRACO)
    if isempty(systeme.frequentation)
        return 50.0
    end
    
    taux_occ = [d.occupation_bus/d.capacite_bus for d in systeme.frequentation if d.capacite_bus > 0]
    
    if isempty(taux_occ)
        return 50.0
    end
    
    occupation_moyenne = mean(taux_occ)
    
    if occupation_moyenne <= 0.7
        return (occupation_moyenne / 0.7) * 100
    else
        return 100 - ((occupation_moyenne - 0.7) / 0.3) * 30
    end
end

"""
Alertes et notifications du dashboard
"""
function afficher_alertes_dashboard(systeme::SystemeSOTRACO)
    println("\n🚨 ALERTES ET NOTIFICATIONS:")
    
    alertes = []
    
    if !isempty(systeme.frequentation)
        surcharges = count(d -> d.capacite_bus > 0 && d.occupation_bus/d.capacite_bus > 0.95, systeme.frequentation)
        if surcharges > length(systeme.frequentation) * 0.1
            push!(alertes, "⚠️ SURCHARGE: Plus de 10% des trajets en surcharge")
        end
    end
    
    if !isempty(systeme.arrets)
        taux_equipement = count(a -> a.abribus && a.eclairage, values(systeme.arrets)) / length(systeme.arrets)
        if taux_equipement < 0.5
            push!(alertes, "🔧 INFRASTRUCTURE: Moins de 50% des arrêts équipés")
        end
    end
    
    if length(systeme.predictions) < 10
        push!(alertes, "🔮 PRÉDICTIONS: Données prédictives insuffisantes")
    end
    
    if isempty(alertes)
        println("   ✅ Aucune alerte critique")
    else
        for alerte in alertes
            println("   $alerte")
        end
    end
end

end # module Visualisation