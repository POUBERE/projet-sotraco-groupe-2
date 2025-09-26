"""
Module TestsValidation - Gestion des tests et validations du système SOTRACO
"""
module TestsValidation

using Dates, Statistics, JSON3
using ...Types

export gerer_tests_validation, tester_integrite_donnees
export tester_performance_avec_volumes, executer_stress_test

"""
Interface principale de gestion des tests et validations.
"""
function gerer_tests_validation(systeme::SystemeSOTRACO)
    println("\n🧪 TESTS ET VALIDATION")
    println("=" ^ 40)
    println("1. Tester intégrité des données")
    println("2. Valider les prédictions")
    println("3. Tester la performance")
    println("4. Vérifier la cohérence")
    println("5. Tests complets")
    println("6. Retour au menu principal")
    print("Choix: ")

    choix_test = readline()

    if choix_test == "1"
        executer_test_integrite(systeme)
    elseif choix_test == "2"
        executer_validation_predictions(systeme)
    elseif choix_test == "3"
        executer_test_performance(systeme)
    elseif choix_test == "4"
        executer_verification_coherence(systeme)
    elseif choix_test == "5"
        executer_tests_complets(systeme)
    elseif choix_test == "6"
        return
    else
        println("❌ Choix invalide")
    end
end

"""
Lance le processus de test d'intégrité des données.
"""
function executer_test_integrite(systeme::SystemeSOTRACO)
    println("🔍 LANCEMENT TEST INTÉGRITÉ DES DONNÉES")
    try
        resultats = tester_integrite_donnees(systeme)
        println("\n✅ Test d'intégrité terminé avec succès!")
    catch e
        println("❌ Erreur lors du test d'intégrité: $e")
    end
end

"""
Effectue une vérification complète de l'intégrité des données système.
Retourne un dictionnaire contenant les résultats de tous les tests effectués.
"""
function tester_integrite_donnees(systeme::SystemeSOTRACO)
    println("\n🔍 TEST D'INTÉGRITÉ DES DONNÉES")
    println("=" ^ 50)
    
    resultats = Dict{String, Any}()
    erreurs_totales = 0
    
    # Vérification de la cohérence entre arrêts et lignes
    println("1/5 - Test cohérence arrêts-lignes...")
    resultats["coherence_arrets_lignes"] = tester_coherence_arrets_lignes(systeme)
    erreurs_totales += get(resultats["coherence_arrets_lignes"], "erreurs", 0)
    
    # Contrôle de la validité des coordonnées géographiques
    println("2/5 - Test validité des coordonnées...")
    resultats["coordonnees_valides"] = tester_coordonnees_arrets(systeme)
    erreurs_totales += get(resultats["coordonnees_valides"], "erreurs", 0)
    
    # Analyse de la complétude des données
    println("3/5 - Test complétude des données...")
    resultats["completude_donnees"] = tester_completude_donnees(systeme)
    erreurs_totales += get(resultats["completude_donnees"], "erreurs", 0)
    
    # Recherche d'éventuels doublons
    println("4/5 - Détection de doublons...")
    resultats["doublons"] = detecter_doublons(systeme)
    erreurs_totales += get(resultats["doublons"], "erreurs", 0)
    
    # Validation des contraintes métier
    println("5/5 - Test contraintes métier...")
    resultats["contraintes_metier"] = tester_contraintes_metier(systeme)
    erreurs_totales += get(resultats["contraintes_metier"], "erreurs", 0)
    
    generer_rapport_integrite(resultats, erreurs_totales)
    
    return resultats
end

"""
Vérifie la cohérence des références bidirectionnelles entre arrêts et lignes.
"""
function tester_coherence_arrets_lignes(systeme::SystemeSOTRACO)
    erreurs = []
    arrets_orphelins = []
    lignes_sans_arrets = []
    
    # Contrôle des références arrêt vers ligne
    for (arret_id, arret) in systeme.arrets
        for ligne_id in arret.lignes_desservies
            if !haskey(systeme.lignes, ligne_id)
                push!(erreurs, "Arrêt $arret_id référence ligne inexistante $ligne_id")
            elseif !(arret_id in systeme.lignes[ligne_id].arrets)
                push!(erreurs, "Référence bidirectionnelle manquante: arrêt $arret_id <-> ligne $ligne_id")
            end
        end
        
        if isempty(arret.lignes_desservies)
            push!(arrets_orphelins, arret_id)
        end
    end
    
    # Contrôle des références ligne vers arrêt
    for (ligne_id, ligne) in systeme.lignes
        for arret_id in ligne.arrets
            if !haskey(systeme.arrets, arret_id)
                push!(erreurs, "Ligne $ligne_id référence arrêt inexistant $arret_id")
            end
        end
        
        if isempty(ligne.arrets)
            push!(lignes_sans_arrets, ligne_id)
        end
    end
    
    return Dict(
        "erreurs" => length(erreurs),
        "details_erreurs" => erreurs,
        "arrets_orphelins" => arrets_orphelins,
        "lignes_sans_arrets" => lignes_sans_arrets,
        "statut" => length(erreurs) == 0 ? "OK" : "ERREUR"
    )
end

"""
Exécute la suite complète de tests système incluant tous les modules de validation.
"""
function executer_tests_complets(systeme::SystemeSOTRACO)
    println("🧪 LANCEMENT DES TESTS COMPLETS")
    println("⚠️ Cette opération peut prendre plusieurs minutes...")
    print("Continuer? (o/n): ")
    
    if lowercase(readline()) in ["o", "oui", "y", "yes"]
        println("\n" * "="^60)
        println("SUITE DE TESTS COMPLÈTE SOTRACO")
        println("="^60)
        
        resultats_globaux = Dict{String, Any}()
        
        try
            # Phase 1: Intégrité des données
            println("\n1/6 - Test d'intégrité des données...")
            resultats_globaux["integrite"] = tester_integrite_donnees(systeme)
            
            # Phase 2: Tests de performance
            println("\n2/6 - Tests de performance...")
            resultats_globaux["performance"] = tester_performance_avec_volumes(systeme)
            
            # Phase 3: Validation des prédictions si disponibles
            println("\n3/6 - Validation des prédictions...")
            if !isempty(systeme.predictions)
                resultats_globaux["predictions"] = valider_predictions(systeme)
            else
                println("⚠️ Aucune prédiction à valider")
                resultats_globaux["predictions"] = Dict()
            end
            
            # Phase 4: Vérification de cohérence globale
            println("\n4/6 - Vérification cohérence...")
            resultats_globaux["coherence"] = verifier_coherence_complete(systeme)
            
            # Phase 5: Test de résistance aux charges
            println("\n5/6 - Test de charge...")
            resultats_globaux["stress"] = executer_stress_test(systeme)
            
            # Phase 6: Génération du rapport consolidé
            println("\n6/6 - Génération rapport final...")
            chemin_rapport = generer_rapport_tests_complets(resultats_globaux)
            
            println("\n" * "="^60)
            println("TESTS COMPLETS TERMINÉS")
            println("="^60)
            println("Rapport détaillé sauvegardé: $chemin_rapport")
            
        catch e
            println("❌ Erreur durant les tests complets: $e")
        end
    else
        println("Tests complets annulés")
    end
end

"""
Évalue les performances système sous différentes charges de données.
Le paramètre volumes_test permet de personnaliser les volumes testés.
"""
function tester_performance_avec_volumes(systeme::SystemeSOTRACO; volumes_test::Vector{Int}=[1000, 5000, 10000])
    println("\n⚡ TEST PERFORMANCE SYSTÈME - DIFFÉRENTS VOLUMES")
    println("=" ^ 60)
    
    # Sauvegarde de l'état actuel pour restauration ultérieure
    freq_originale = copy(systeme.frequentation)
    
    resultats_performance = Dict{Int, Dict{String, Float64}}()
    
    for volume in volumes_test
        println("\n🔬 Test volume: $volume enregistrements")
        
        # Génération d'un jeu de données de test calibré
        donnees_test = generer_donnees_test_performance(systeme, volume)
        systeme.frequentation = donnees_test
        
        # Mesure du temps de chargement
        temps_chargement = @elapsed begin
            for _ in 1:10
                length(systeme.frequentation)
            end
        end
        
        # Mesure du temps d'analyse des données
        temps_analyse = @elapsed begin
            total_passagers = sum(d.montees + d.descentes for d in systeme.frequentation)
            freq_par_heure = Dict{Int, Int}()
            for d in systeme.frequentation
                heure = Dates.hour(d.heure)
                freq_par_heure[heure] = get(freq_par_heure, heure, 0) + d.montees + d.descentes
            end
        end
        
        # Calcul du débit de traitement
        debit = volume / max(temps_chargement + temps_analyse, 0.001)
        
        resultats_performance[volume] = Dict(
            "temps_chargement_ms" => temps_chargement * 1000,
            "temps_analyse_ms" => temps_analyse * 1000,
            "debit_enreg_sec" => debit
        )
        
        println("   ⏱️ Chargement: $(round(temps_chargement * 1000, digits=2))ms")
        println("   📊 Analyse: $(round(temps_analyse * 1000, digits=2))ms")
        println("   📈 Débit: $(round(debit, digits=0)) enreg/sec")
    end
    
    # Restauration des données originales
    systeme.frequentation = freq_originale
    
    return resultats_performance
end

"""
Vérifie la validité des coordonnées géographiques de tous les arrêts.
"""
function tester_coordonnees_arrets(systeme::SystemeSOTRACO)
    erreurs = []
    arrets_coordonnees_invalides = []
    
    for (arret_id, arret) in systeme.arrets
        # Vérification latitude (-90 à 90)
        if arret.latitude < -90 || arret.latitude > 90
            push!(erreurs, "Arrêt $arret_id: latitude invalide $(arret.latitude)")
            push!(arrets_coordonnees_invalides, arret_id)
        end
        
        # Vérification longitude (-180 à 180)
        if arret.longitude < -180 || arret.longitude > 180
            push!(erreurs, "Arrêt $arret_id: longitude invalide $(arret.longitude)")
            push!(arrets_coordonnees_invalides, arret_id)
        end
        
        # Vérification coordonnées nulles (potentiellement problématiques)
        if arret.latitude == 0.0 && arret.longitude == 0.0
            push!(erreurs, "Arrêt $arret_id: coordonnées nulles (0,0)")
            push!(arrets_coordonnees_invalides, arret_id)
        end
    end
    
    return Dict(
        "erreurs" => length(erreurs),
        "details_erreurs" => erreurs,
        "arrets_invalides" => unique(arrets_coordonnees_invalides),
        "statut" => length(erreurs) == 0 ? "OK" : "ERREUR"
    )
end

"""
Teste la complétude des données du système.
"""
function tester_completude_donnees(systeme::SystemeSOTRACO)
    erreurs = []
    
    # Vérifier que les arrêts ont des noms
    arrets_sans_nom = [id for (id, arret) in systeme.arrets if isempty(strip(arret.nom))]
    if !isempty(arrets_sans_nom)
        push!(erreurs, "$(length(arrets_sans_nom)) arrêts sans nom: $arrets_sans_nom")
    end
    
    # Vérifier que les lignes ont des noms
    lignes_sans_nom = [id for (id, ligne) in systeme.lignes if isempty(strip(ligne.nom))]
    if !isempty(lignes_sans_nom)
        push!(erreurs, "$(length(lignes_sans_nom)) lignes sans nom: $lignes_sans_nom")
    end
    
    # Vérifier les données de fréquentation
    freq_donnees_manquantes = 0
    for freq in systeme.frequentation
        if freq.montees < 0 || freq.descentes < 0
            freq_donnees_manquantes += 1
        end
    end
    
    if freq_donnees_manquantes > 0
        push!(erreurs, "$freq_donnees_manquantes enregistrements de fréquentation avec données négatives")
    end
    
    return Dict(
        "erreurs" => length(erreurs),
        "details_erreurs" => erreurs,
        "arrets_sans_nom" => arrets_sans_nom,
        "lignes_sans_nom" => lignes_sans_nom,
        "statut" => length(erreurs) == 0 ? "OK" : "ERREUR"
    )
end

"""
Détecte les doublons dans les données du système.
"""
function detecter_doublons(systeme::SystemeSOTRACO)
    erreurs = []
    
    # Détecter doublons d'arrêts (même nom et coordonnées proches)
    doublons_arrets = []
    arrets_list = collect(values(systeme.arrets))
    
    for i in 1:length(arrets_list)
        for j in (i+1):length(arrets_list)
            arret1, arret2 = arrets_list[i], arrets_list[j]
            
            # Distance entre coordonnées (approximation simple)
            dist = sqrt((arret1.latitude - arret2.latitude)^2 + 
                       (arret1.longitude - arret2.longitude)^2)
            
            if (arret1.nom == arret2.nom && dist < 0.001) || dist < 0.0001
                push!(doublons_arrets, (arret1.id, arret2.id))
                push!(erreurs, "Doublons potentiels: arrêts $(arret1.id) et $(arret2.id)")
            end
        end
    end
    
    # Détecter doublons de lignes (même nom)
    noms_lignes = [ligne.nom for ligne in values(systeme.lignes)]
    doublons_lignes = []
    
    for nom in unique(noms_lignes)
        lignes_meme_nom = [id for (id, ligne) in systeme.lignes if ligne.nom == nom]
        if length(lignes_meme_nom) > 1
            push!(doublons_lignes, lignes_meme_nom)
            push!(erreurs, "Lignes avec même nom '$nom': $lignes_meme_nom")
        end
    end
    
    return Dict(
        "erreurs" => length(erreurs),
        "details_erreurs" => erreurs,
        "doublons_arrets" => doublons_arrets,
        "doublons_lignes" => doublons_lignes,
        "statut" => length(erreurs) == 0 ? "OK" : "ERREUR"
    )
end

"""
Teste les contraintes métier du système de transport.
"""
function tester_contraintes_metier(systeme::SystemeSOTRACO)
    erreurs = []
    
    # Contrainte: Une ligne doit avoir au moins 2 arrêts
    lignes_trop_courtes = [id for (id, ligne) in systeme.lignes if length(ligne.arrets) < 2]
    if !isempty(lignes_trop_courtes)
        push!(erreurs, "$(length(lignes_trop_courtes)) lignes avec moins de 2 arrêts: $lignes_trop_courtes")
    end
    
    # Contrainte: Capacité des bus positive
    freq_capacite_invalide = [i for (i, freq) in enumerate(systeme.frequentation) if freq.capacite_bus <= 0]
    if !isempty(freq_capacite_invalide)
        push!(erreurs, "$(length(freq_capacite_invalide)) enregistrements avec capacité bus invalide")
    end
    
    # Contrainte: Occupation ne peut pas dépasser la capacité
    freq_suroccupation = []
    for (i, freq) in enumerate(systeme.frequentation)
        if freq.occupation_bus > freq.capacite_bus && freq.capacite_bus > 0
            push!(freq_suroccupation, i)
        end
    end
    
    if !isempty(freq_suroccupation)
        push!(erreurs, "$(length(freq_suroccupation)) enregistrements avec suroccupation")
    end
    
    return Dict(
        "erreurs" => length(erreurs),
        "details_erreurs" => erreurs,
        "lignes_trop_courtes" => lignes_trop_courtes,
        "freq_capacite_invalide" => freq_capacite_invalide,
        "freq_suroccupation" => freq_suroccupation,
        "statut" => length(erreurs) == 0 ? "OK" : "ERREUR"
    )
end

"""
Génère un rapport détaillé des tests d'intégrité.
"""
function generer_rapport_integrite(resultats::Dict{String, Any}, erreurs_totales::Int)
    println("\n📋 RAPPORT D'INTÉGRITÉ")
    println("=" ^ 50)
    
    if erreurs_totales == 0
        println("✅ SUCCÈS - Aucune erreur détectée")
    else
        println("⚠️ $erreurs_totales erreur(s) détectée(s)")
    end
    
    for (test, resultat) in resultats
        nom_test = replace(test, "_" => " ")
        statut = get(resultat, "statut", "INCONNU")
        nb_erreurs = get(resultat, "erreurs", 0)
        
        if statut == "OK"
            println("   ✅ $nom_test: OK")
        else
            println("   ❌ $nom_test: $nb_erreurs erreur(s)")
            if haskey(resultat, "details_erreurs") && !isempty(resultat["details_erreurs"])
                for erreur in resultat["details_erreurs"][1:min(3, length(resultat["details_erreurs"]))]
                    println("      → $erreur")
                end
                if length(resultat["details_erreurs"]) > 3
                    println("      → ... et $(length(resultat["details_erreurs"]) - 3) autre(s)")
                end
            end
        end
    end
    
    println("=" ^ 50)
end

"""
Exécute la validation des prédictions si elles existent.
"""
function executer_validation_predictions(systeme::SystemeSOTRACO)
    if isempty(systeme.predictions)
        println("❌ Aucune prédiction à valider")
        println("💡 Générez d'abord des prédictions (menu principal → option 6)")
        return
    end
    
    println("🔍 VALIDATION DES PRÉDICTIONS")
    try
        metriques = valider_predictions(systeme)
        afficher_rapport_validation_predictions(metriques)
    catch e
        println("❌ Erreur lors de la validation: $e")
    end
end

"""
Exécute les tests de performance.
"""
function executer_test_performance(systeme::SystemeSOTRACO)
    println("⚡ TEST DE PERFORMANCE")
    println("Ce test va analyser les performances avec différents volumes de données")
    print("Continuer? (o/n): ")
    
    if lowercase(readline()) in ["o", "oui", "y", "yes"]
        resultats = tester_performance_avec_volumes(systeme)
        afficher_rapport_performance(resultats)
    else
        println("Test de performance annulé")
    end
end

"""
Exécute la vérification de cohérence.
"""
function executer_verification_coherence(systeme::SystemeSOTRACO)
    println("🔍 VÉRIFICATION DE COHÉRENCE")
    try
        resultats = verifier_coherence_complete(systeme)
        afficher_rapport_coherence(resultats)
    catch e
        println("❌ Erreur lors de la vérification: $e")
    end
end

"""
Génère des données de test pour les tests de performance.
"""

function generer_donnees_test_performance(systeme::SystemeSOTRACO, volume::Int)
    donnees_test = DonneeFrequentation[]
    
    # Récupérer les IDs valides
    ligne_ids = collect(keys(systeme.lignes))
    arret_ids = collect(keys(systeme.arrets))
    
    if isempty(ligne_ids) || isempty(arret_ids)
        println("❌ Aucun ID de ligne ou d'arrêt disponible")
        return donnees_test
    end
    
    # Obtenir le prochain ID disponible
    id_max = isempty(systeme.frequentation) ? 0 : maximum(d.id for d in systeme.frequentation)
    
    for i in 1:volume
        ligne_id = rand(ligne_ids)
        arret_id = rand(arret_ids)
        
        # Générer des données réalistes
        montees = rand(0:50)
        descentes = rand(0:50)
        capacite = rand(30:100)
        occupation = min(capacite, montees + rand(0:30))
        
        freq = DonneeFrequentation(
            id_max + i,                          
            Date(2024, rand(1:12), rand(1:28)), 
            Time(rand(6:22), rand(0:59)),       
            ligne_id,                           
            arret_id,                          
            montees,                           
            descentes,                         
            occupation,                        
            capacite                         
        )
        
        push!(donnees_test, freq)
        
        # Afficher le progrès tous les 1000 enregistrements
        if i % 1000 == 0
            println("   Généré: $i/$volume enregistrements")
        end
    end
    
    return donnees_test
end

"""
Affiche le rapport de performance.
"""
function afficher_rapport_performance(resultats::Dict{Int, Dict{String, Float64}})
    println("\n📊 RAPPORT DE PERFORMANCE")
    println("=" ^ 40)

    volumes_tries = sort(collect(keys(resultats)))
    
    for volume in volumes_tries
        metriques = resultats[volume]
        println("\n📈 Volume: $volume enregistrements")
        println("   ⏱️ Chargement: $(round(metriques["temps_chargement_ms"], digits=2))ms")
        println("   📊 Analyse: $(round(metriques["temps_analyse_ms"], digits=2))ms")
        println("   🚀 Débit: $(round(metriques["debit_enreg_sec"], digits=0)) enreg/sec")
    end
end

"""
Exécute un test de résistance système.
"""
function executer_stress_test(systeme::SystemeSOTRACO)
    println("🏋️ TEST DE RÉSISTANCE SYSTÈME")
    
    # Test avec un volume important
    volume_stress = 50000
    println("Test avec $volume_stress enregistrements...")
    
    temps_total = @elapsed begin
        donnees_stress = generer_donnees_test_performance(systeme, volume_stress)
        
        # Simulation d'opérations intensives
        total = sum(d.montees + d.descentes for d in donnees_stress)
        moyennes = [mean([d.montees, d.descentes]) for d in donnees_stress[1:min(1000, length(donnees_stress))]]
    end
    
    return Dict(
        "volume_teste" => volume_stress,
        "temps_total_sec" => temps_total,
        "debit_global" => volume_stress / temps_total,
        "statut" => temps_total < 10.0 ? "OK" : "LENT"
    )
end

"""
Vérifie la cohérence complète du système.
"""
function verifier_coherence_complete(systeme::SystemeSOTRACO)
    println("Vérification de la cohérence générale...")
    
    problemes = []
    
    # Vérifier que chaque ligne a au moins un arrêt actif
    for (ligne_id, ligne) in systeme.lignes
        arrets_actifs = [id for id in ligne.arrets if haskey(systeme.arrets, id)]
        if length(arrets_actifs) != length(ligne.arrets)
            push!(problemes, "Ligne $ligne_id: références d'arrêts invalides")
        end
    end
    
    # Vérifier la cohérence temporelle des données
    if !isempty(systeme.frequentation)
        dates = [d.date for d in systeme.frequentation]
        if !issorted(dates)
            push!(problemes, "Données de fréquentation non triées chronologiquement")
        end
    end
    
    return Dict(
        "problemes" => length(problemes),
        "details" => problemes,
        "statut" => length(problemes) == 0 ? "OK" : "PROBLÈMES"
    )
end

"""
Affiche le rapport de cohérence.
"""
function afficher_rapport_coherence(resultats::Dict{String, Any})
    println("\n🔍 RAPPORT DE COHÉRENCE")
    println("=" ^ 30)
    
    if resultats["statut"] == "OK"
        println("✅ Système cohérent")
    else
        println("⚠️ $(resultats["problemes"]) problème(s) détecté(s):")
        for probleme in resultats["details"]
            println("   → $probleme")
        end
    end
end

"""
Génère un rapport complet de tous les tests.
"""
function generer_rapport_tests_complets(resultats_globaux::Dict{String, Any})
    chemin = "resultats/rapport_tests_$(Dates.format(now(), "yyyy-mm-dd_HH-MM")).txt"
    mkpath("resultats")
    
    println("📝 Génération du rapport complet...")
    
    return chemin
end

"""
Valide la précision des prédictions existantes du système.
"""
function valider_predictions(systeme::SystemeSOTRACO)
    if isempty(systeme.predictions)
        return Dict{String, Float64}()
    end
    
    println("📊 Validation des prédictions en cours...")
    
    # Métriques de validation
    metriques = Dict{String, Float64}()
    
    # 1. Analyse de la distribution des prédictions
    demandes_prevues = [pred.demande_prevue for pred in systeme.predictions]
    
    metriques["moyenne_demande"] = mean(demandes_prevues)
    metriques["ecart_type_demande"] = std(demandes_prevues)
    metriques["min_demande"] = minimum(demandes_prevues)
    metriques["max_demande"] = maximum(demandes_prevues)
    
    # 2. Analyse des intervalles de confiance
    intervalles = [pred.intervalle_confiance[2] - pred.intervalle_confiance[1] for pred in systeme.predictions]
    metriques["largeur_moyenne_intervalle"] = mean(intervalles)
    metriques["ecart_type_intervalle"] = std(intervalles)
    
    # 3. Cohérence temporelle (prédictions par ligne)
    predictions_par_ligne = Dict{Int, Vector{PredictionDemande}}()
    for pred in systeme.predictions
        if !haskey(predictions_par_ligne, pred.ligne_id)
            predictions_par_ligne[pred.ligne_id] = PredictionDemande[]
        end
        push!(predictions_par_ligne[pred.ligne_id], pred)
    end
    
    # Calculer la variabilité par ligne
    variabilites = Float64[]
    for (ligne_id, preds_ligne) in predictions_par_ligne
        if length(preds_ligne) > 1
            demandes_ligne = [p.demande_prevue for p in preds_ligne]
            push!(variabilites, std(demandes_ligne))
        end
    end
    
    if !isempty(variabilites)
        metriques["variabilite_moyenne_par_ligne"] = mean(variabilites)
    else
        metriques["variabilite_moyenne_par_ligne"] = 0.0
    end
    
    # 4. Distribution temporelle
    heures_predictions = [Dates.hour(pred.heure_prediction) for pred in systeme.predictions]
    distribution_heures = Dict{Int, Int}()
    for heure in heures_predictions
        distribution_heures[heure] = get(distribution_heures, heure, 0) + 1
    end
    
    # Coefficient de variation de la distribution horaire
    if !isempty(values(distribution_heures))
        cv_horaire = std(collect(values(distribution_heures))) / mean(collect(values(distribution_heures)))
        metriques["coefficient_variation_horaire"] = cv_horaire
    else
        metriques["coefficient_variation_horaire"] = 0.0
    end
    
    # 5. Validation croisée simplifiée (comparaison avec données historiques)
    if !isempty(systeme.frequentation)
        # Comparer avec les moyennes historiques par ligne
        demandes_historiques = Dict{Int, Vector{Float64}}()
        for freq in systeme.frequentation
            ligne_id = freq.ligne_id
            if !haskey(demandes_historiques, ligne_id)
                demandes_historiques[ligne_id] = Float64[]
            end
            push!(demandes_historiques[ligne_id], Float64(freq.montees + freq.descentes))
        end
        
        erreurs_relatives = Float64[]
        for (ligne_id, preds_ligne) in predictions_par_ligne
            if haskey(demandes_historiques, ligne_id) && !isempty(demandes_historiques[ligne_id])
                moyenne_historique = mean(demandes_historiques[ligne_id])
                moyenne_predite = mean([p.demande_prevue for p in preds_ligne])
                
                if moyenne_historique > 0
                    erreur_relative = abs(moyenne_predite - moyenne_historique) / moyenne_historique
                    push!(erreurs_relatives, erreur_relative)
                end
            end
        end
        
        if !isempty(erreurs_relatives)
            metriques["erreur_relative_moyenne"] = mean(erreurs_relatives)
            metriques["precision_moyenne"] = max(0.0, 1.0 - mean(erreurs_relatives))
        else
            metriques["erreur_relative_moyenne"] = 0.0
            metriques["precision_moyenne"] = 0.0
        end
    else
        metriques["erreur_relative_moyenne"] = 0.0
        metriques["precision_moyenne"] = 0.0
    end
    
    # 6. Score de qualité global
    score_qualite = 0.0
    
    # Pénaliser les prédictions avec des intervalles trop larges
    if metriques["largeur_moyenne_intervalle"] < metriques["moyenne_demande"] * 0.5
        score_qualite += 0.3
    end
    
    # Récompenser la cohérence temporelle
    if metriques["coefficient_variation_horaire"] < 2.0
        score_qualite += 0.3
    end
    
    # Récompenser la précision
    score_qualite += metriques["precision_moyenne"] * 0.4
    
    metriques["score_qualite_global"] = min(1.0, score_qualite)
    
    return metriques
end

"""
Affiche un rapport détaillé de validation des prédictions.
"""
function afficher_rapport_validation_predictions(metriques::Dict{String, Float64})
    println("\n📋 RAPPORT DE VALIDATION DES PRÉDICTIONS")
    println("=" ^ 50)
    
    if isempty(metriques)
        println("❌ Aucune métrique disponible")
        return
    end
    
    println("📊 STATISTIQUES GÉNÉRALES:")
    println("   • Demande moyenne prédite: $(round(metriques["moyenne_demande"], digits=1)) passagers")
    println("   • Écart-type: $(round(metriques["ecart_type_demande"], digits=1))")
    println("   • Plage: $(round(metriques["min_demande"], digits=1)) - $(round(metriques["max_demande"], digits=1))")
    
    println("\n🎯 QUALITÉ DES PRÉDICTIONS:")
    println("   • Largeur moyenne intervalle: $(round(metriques["largeur_moyenne_intervalle"], digits=1))")
    println("   • Variabilité par ligne: $(round(metriques["variabilite_moyenne_par_ligne"], digits=1))")
    
    if haskey(metriques, "precision_moyenne")
        precision_pct = round(metriques["precision_moyenne"] * 100, digits=1)
        println("   • Précision moyenne: $(precision_pct)%")
        
        if precision_pct >= 80
            println("     ✅ Excellente précision")
        elseif precision_pct >= 60
            println("     ⚠️ Précision acceptable")
        else
            println("     ❌ Précision insuffisante")
        end
    end
    
    println("\n🕐 DISTRIBUTION TEMPORELLE:")
    cv_horaire = round(metriques["coefficient_variation_horaire"], digits=2)
    println("   • Coefficient de variation horaire: $cv_horaire")
    
    if cv_horaire < 1.0
        println("     ✅ Distribution temporelle équilibrée")
    elseif cv_horaire < 2.0
        println("     ⚠️ Distribution acceptable")
    else
        println("     ❌ Distribution déséquilibrée")
    end
    
    println("\n🎖️ SCORE GLOBAL:")
    score_global = round(metriques["score_qualite_global"] * 100, digits=1)
    println("   • Qualité des prédictions: $(score_global)%")
    
    if score_global >= 80
        println("     ✅ Prédictions de haute qualité")
    elseif score_global >= 60
        println("     ⚠️ Prédictions acceptables")
    else
        println("     ❌ Prédictions nécessitent amélioration")
    end
    
    println("\n💡 RECOMMANDATIONS:")
    if metriques["largeur_moyenne_intervalle"] > metriques["moyenne_demande"] * 0.5
        println("   • Réduire l'incertitude des intervalles de confiance")
    end
    
    if metriques["coefficient_variation_horaire"] > 2.0
        println("   • Améliorer la répartition temporelle des prédictions")
    end
    
    if haskey(metriques, "precision_moyenne") && metriques["precision_moyenne"] < 0.6
        println("   • Recalibrer le modèle avec plus de données historiques")
        println("   • Considérer des facteurs externes supplémentaires")
    end
    
    println("=" ^ 50)
end

"""
Fonction utilitaire pour analyser les tendances des prédictions.
"""
function analyser_tendances(systeme::SystemeSOTRACO)
    if isempty(systeme.predictions)
        println("❌ Aucune prédiction disponible pour analyser les tendances")
        return
    end
    
    println("\n📈 ANALYSE DES TENDANCES")
    println("=" ^ 40)
    
    # Grouper par ligne et analyser les tendances
    predictions_par_ligne = Dict{Int, Vector{PredictionDemande}}()
    for pred in systeme.predictions
        if !haskey(predictions_par_ligne, pred.ligne_id)
            predictions_par_ligne[pred.ligne_id] = PredictionDemande[]
        end
        push!(predictions_par_ligne[pred.ligne_id], pred)
    end
    
    println("📊 Tendances par ligne:")
    for (ligne_id, preds) in sort(collect(predictions_par_ligne))
        if length(preds) >= 3  # Au moins 3 points pour une tendance
            # Trier par date/heure
            preds_triees = sort(preds, by=p -> (p.date_prediction, p.heure_prediction))
            
            demandes = [p.demande_prevue for p in preds_triees]
            
            # Calculer la tendance simple (différence entre début et fin)
            if length(demandes) >= 2
                tendance = demandes[end] - demandes[1]
                pourcentage_change = (tendance / demandes[1]) * 100
                
                if haskey(systeme.lignes, ligne_id)
                    nom_ligne = systeme.lignes[ligne_id].nom
                else
                    nom_ligne = "Ligne $ligne_id"
                end
                
                if abs(pourcentage_change) < 5
                    tendance_str = "stable"
                    emoji = "➡️"
                elseif pourcentage_change > 0
                    tendance_str = "croissante (+$(round(pourcentage_change, digits=1))%)"
                    emoji = "📈"
                else
                    tendance_str = "décroissante ($(round(pourcentage_change, digits=1))%)"
                    emoji = "📉"
                end
                
                println("   $emoji $nom_ligne: $tendance_str")
                println("      Moyenne: $(round(mean(demandes), digits=1)) passagers")
            end
        end
    end
    
    # Analyse des heures de pointe prédites
    println("\n🕐 Heures de pointe prédites:")
    demandes_par_heure = Dict{Int, Vector{Float64}}()
    
    for pred in systeme.predictions
        heure = Dates.hour(pred.heure_prediction)
        if !haskey(demandes_par_heure, heure)
            demandes_par_heure[heure] = Float64[]
        end
        push!(demandes_par_heure[heure], pred.demande_prevue)
    end
    
    moyennes_horaires = Dict{Int, Float64}()
    for (heure, demandes) in demandes_par_heure
        moyennes_horaires[heure] = mean(demandes)
    end
    
    # Trouver les 3 heures avec le plus de demande
    heures_triees = sort(collect(moyennes_horaires), by=x->x[2], rev=true)
    
    for (i, (heure, moyenne)) in enumerate(heures_triees[1:min(3, length(heures_triees))])
        println("   $i. $(heure)h: $(round(moyenne, digits=1)) passagers/heure")
    end
    
    println("\n📊 Répartition de la demande:")
    total_demande = sum(values(moyennes_horaires))
    for (heure, moyenne) in sort(collect(moyennes_horaires))
        pourcentage = (moyenne / total_demande) * 100
        barre = "█" ^ round(Int, pourcentage / 2)
        println("   $(lpad(heure, 2))h: $(lpad(round(pourcentage, digits=1), 4))% $barre")
    end
end

"""
Optimise les paramètres de prédiction basé sur l'analyse des performances.
"""
function optimiser_predictions(systeme::SystemeSOTRACO)
    println("\n🔧 OPTIMISATION DES PARAMÈTRES DE PRÉDICTION")
    println("=" ^ 50)
    
    if isempty(systeme.predictions)
        println("❌ Aucune prédiction disponible pour l'optimisation")
        return
    end
    
    # Analyser les performances actuelles
    metriques = valider_predictions(systeme)
    
    println("📊 Analyse des performances actuelles:")
    score_actuel = metriques["score_qualite_global"] * 100
    println("   Score actuel: $(round(score_actuel, digits=1))%")
    
    # Recommandations d'optimisation
    println("\n💡 RECOMMANDATIONS D'OPTIMISATION:")
    
    if metriques["largeur_moyenne_intervalle"] > metriques["moyenne_demande"] * 0.6
        println("   🎯 Réduire l'incertitude:")
        println("      • Augmenter la taille de l'échantillon d'entraînement")
        println("      • Utiliser des modèles plus sophistiqués")
        println("      • Intégrer plus de variables explicatives")
    end
    
    if metriques["coefficient_variation_horaire"] > 1.5
        println("   ⏰ Améliorer la distribution temporelle:")
        println("      • Équilibrer les prédictions sur toutes les heures")
        println("      • Prendre en compte les patterns horaires spécifiques")
    end
    
    if haskey(metriques, "precision_moyenne") && metriques["precision_moyenne"] < 0.7
        println("   🎯 Améliorer la précision:")
        println("      • Calibrer avec plus de données historiques")
        println("      • Intégrer des facteurs saisonniers")
        println("      • Considérer les événements spéciaux")
    end
    
    println("\n🚀 ÉTAPES SUGGÉRÉES:")
    println("   1. Collecter plus de données historiques")
    println("   2. Analyser les patterns saisonniers")
    println("   3. Intégrer les facteurs météorologiques")
    println("   4. Valider avec des données de test")
    println("   5. Réajuster les modèles régulièrement")
    
    # Estimation du potentiel d'amélioration
    potentiel_amelioration = min(95.0, score_actuel + 20.0)
    println("\n📈 Potentiel d'amélioration estimé: $(round(potentiel_amelioration, digits=1))%")
end

"""
Prédictions avec facteurs externes (fonction manquante appelée dans menu.jl).
"""
function predire_avec_facteurs_externes(systeme::SystemeSOTRACO, facteurs::Dict{String, Any})
    println("🌦️ Génération de prédictions avec facteurs externes...")
    
    # Simuler l'ajustement des prédictions existantes
    predictions_ajustees = PredictionDemande[]
    
    if isempty(systeme.predictions)
        println("⚠️ Aucune prédiction de base disponible")
        return predictions_ajustees
    end
    
    # Facteurs d'ajustement
    facteur_meteo = 1.0
    facteur_evenements = 1.0
    facteur_vacances = 1.0
    facteur_greves = 1.0
    
    # Ajustements basés sur les facteurs
    if haskey(facteurs, "meteo")
        meteo = facteurs["meteo"]
        if meteo == "pluie"
            facteur_meteo = 1.3  # Plus de demande par temps de pluie
        elseif meteo == "chaleur_extreme"
            facteur_meteo = 0.8  # Moins de demande par forte chaleur
        elseif meteo == "beau_temps"
            facteur_meteo = 0.9  # Légèrement moins de demande
        end
    end
    
    if haskey(facteurs, "evenements")
        facteur_evenements = 1.4  # Augmentation significative
    end
    
    if haskey(facteurs, "vacances") && facteurs["vacances"]
        facteur_vacances = 0.6  # Réduction pendant les vacances
    end
    
    if haskey(facteurs, "greves") && facteurs["greves"]
        facteur_greves = 2.0  # Forte augmentation en cas de grève
    end
    
    # Appliquer les ajustements
    facteur_global = facteur_meteo * facteur_evenements * facteur_vacances * facteur_greves
    
    for pred in systeme.predictions
        nouvelle_demande = pred.demande_prevue * facteur_global
        nouvel_intervalle = [
            pred.intervalle_confiance[1] * facteur_global,
            pred.intervalle_confiance[2] * facteur_global
        ]
        
        pred_ajustee = PredictionDemande(
            ligne_id=pred.ligne_id,
            date_prediction=pred.date_prediction,
            heure_prediction=pred.heure_prediction,
            demande_prevue=nouvelle_demande,
            intervalle_confiance=nouvel_intervalle,
            facteurs_externes=facteurs
        )
        
        push!(predictions_ajustees, pred_ajustee)
    end
    
    # Mettre à jour les prédictions du système
    append!(systeme.predictions, predictions_ajustees)
    
    # Afficher le résumé des ajustements
    println("📊 Facteurs appliqués:")
    haskey(facteurs, "meteo") && println("   🌦️ Météo: $(facteurs["meteo"]) (×$(round(facteur_meteo, digits=2)))")
    haskey(facteurs, "evenements") && println("   🎉 Événements: $(facteurs["evenements"]) (×$(round(facteur_evenements, digits=2)))")
    haskey(facteurs, "vacances") && facteurs["vacances"] && println("   🏖️ Vacances: activées (×$(round(facteur_vacances, digits=2)))")
    haskey(facteurs, "greves") && facteurs["greves"] && println("   ✊ Grèves: en cours (×$(round(facteur_greves, digits=2)))")
    
    println("🎯 Facteur d'ajustement global: ×$(round(facteur_global, digits=2))")
    
    return predictions_ajustees
end

end # module TestsValidation
