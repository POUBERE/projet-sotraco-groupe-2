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

# Fonctions utilitaires additionnelles...

end # module TestsValidation