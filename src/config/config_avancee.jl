"""
Module ConfigurationAvancee - Gestion des paramètres avancés du système SOTRACO
"""
module ConfigurationAvancee

using Dates, Statistics, JSON3
using ...Types
using ...Prediction  # Ajout de l'accès au module Prediction

export gerer_configuration_avancee, configurer_parametres_prediction
export configurer_parametres_optimisation, reinitialiser_configuration_complete
export sauvegarder_configuration_complete

"""
Gère la configuration avancée du système.
"""
function gerer_configuration_avancee(systeme::SystemeSOTRACO)
    println("\n🔧 CONFIGURATION AVANCÉE")
    println("=" ^ 40)
    println("1. Paramètres de prédiction")
    println("2. Configuration carte interactive") 
    println("3. Paramètres d'optimisation")
    println("4. Réinitialiser configuration")
    println("5. Sauvegarder configuration")
    println("6. Retour au menu principal")
    print("Choix: ")

    choix_config = readline()

    if choix_config == "1"
        configurer_parametres_prediction(systeme)
    elseif choix_config == "2"
        gerer_personnalisation_carte(systeme)
    elseif choix_config == "3"
        configurer_parametres_optimisation(systeme)
    elseif choix_config == "4"
        reinitialiser_configuration_complete(systeme)
    elseif choix_config == "5"
        sauvegarder_configuration_complete(systeme)
    elseif choix_config == "6"
        return
    else
        println("❌ Choix invalide")
    end
end

"""
Configuration des paramètres de prédiction avec interface interactive.
Permet d'ajuster l'horizon temporel, les facteurs saisonniers et météorologiques.
"""
function configurer_parametres_prediction(systeme::SystemeSOTRACO)
    println("\n🔮 CONFIGURATION DES PARAMÈTRES DE PRÉDICTION")
    println("=" ^ 60)
    
    if isempty(systeme.predictions)
        println("⚠️ Aucune prédiction n'a encore été générée.")
        print("Voulez-vous d'abord générer des prédictions par défaut? (o/n): ")
        if lowercase(readline()) in ["o", "oui", "y", "yes"]
            # Utilisation de la notation complète pour accéder à la fonction
            Prediction.predire_demande_globale(systeme, 7)
        else
            return
        end
    end
    
    config = Dict{String, Any}(
        "horizon_defaut" => 7,
        "facteur_saisonnier" => 1.0,
        "sensibilite_meteo" => 0.1,
        "ponderation_historique" => 0.7,
        "seuil_confiance" => 0.85,
        "frequence_mise_a_jour" => "quotidienne"
    )
    
    while true
        afficher_parametres_actuels(config)
        
        println("\n🔧 OPTIONS DE CONFIGURATION:")
        println("1. Modifier l'horizon de prédiction par défaut")
        println("2. Ajuster le facteur saisonnier")
        println("3. Configurer la sensibilité météo")
        println("4. Pondération de l'historique")
        println("5. Seuil de confiance")
        println("6. Fréquence de mise à jour")
        println("7. Réinitialiser aux valeurs par défaut")
        println("8. Appliquer et sauvegarder")
        println("9. Retour")
        print("Choix: ")
        
        choix = readline()
        
        if choix == "1"
            configurer_horizon_prediction!(config)
        elseif choix == "2"
            configurer_facteur_saisonnier!(config)
        elseif choix == "3"
            configurer_sensibilite_meteo!(config)
        elseif choix == "4"
            configurer_ponderation_historique!(config)
        elseif choix == "5"
            configurer_seuil_confiance!(config)
        elseif choix == "6"
            configurer_frequence_maj!(config)
        elseif choix == "7"
            reinitialiser_config_defaut!(config)
        elseif choix == "8"
            appliquer_configuration(systeme, config)
            break
        elseif choix == "9"
            break
        else
            println("❌ Choix invalide")
        end
    end
end

"""
Configuration des paramètres d'optimisation pour l'ajustement des fréquences
et la gestion de la capacité des véhicules.
"""
function configurer_parametres_optimisation(systeme::SystemeSOTRACO)
    println("\n🔧 CONFIGURATION DES PARAMÈTRES D'OPTIMISATION")
    println("=" ^ 60)
    
    config_optim = Dict{String, Any}(
        "seuil_occupation_max" => 0.85,
        "frequence_min_autorisee" => 5,
        "frequence_max_autorisee" => 30,
        "tolerance_variation" => 0.1,
        "critere_optimisation" => "efficacite",
        "coefficient_economie" => 0.3,
        "coefficient_service" => 0.4,
        "coefficient_environnement" => 0.3,
        "penalite_surcharge" => 1.5,
        "bonus_sous_utilisation" => 0.8
    )
    
    # Interface de configuration similaire aux prédictions
    while true
        afficher_config_optimisation_actuelle(config_optim)
        
        println("\n🎛️ OPTIONS DE CONFIGURATION:")
        println("1. Seuil d'occupation maximum")
        println("2. Fréquences min/max autorisées") 
        println("3. Tolérance de variation")
        println("4. Critère d'optimisation principal")
        println("5. Coefficients de pondération")
        println("6. Paramètres de pénalité")
        println("7. Appliquer et sauvegarder")
        println("8. Retour")
        print("Choix: ")
        
        choix = readline()
        
        if choix == "1"
            configurer_seuil_occupation!(config_optim)
        elseif choix == "2"
            configurer_frequences_limites!(config_optim)
        elseif choix == "3"
            configurer_tolerance!(config_optim)
        elseif choix == "4"
            configurer_critere_principal!(config_optim)
        elseif choix == "5"
            configurer_coefficients_ponderation!(config_optim)
        elseif choix == "6"
            configurer_parametres_penalite!(config_optim)
        elseif choix == "7"
            appliquer_config_optimisation(systeme, config_optim)
            break
        elseif choix == "8"
            break
        else
            println("❌ Choix invalide")
        end
    end
end

"""
Réinitialise complètement la configuration du système aux valeurs par défaut.
"""
function reinitialiser_configuration_complete(systeme::SystemeSOTRACO)
    println("\n🔄 RÉINITIALISATION COMPLÈTE DE LA CONFIGURATION")
    println("⚠️ Cette action va restaurer tous les paramètres par défaut")
    
    print("Confirmer la réinitialisation (tapez 'CONFIRMER'): ")
    confirmation = readline()
    
    if confirmation == "CONFIRMER"
        # Réinitialiser configuration carte
        systeme.config_carte = ConfigurationCarte(
            12.3686, -1.5275, 12, true, true, true, Dict{Int, String}()
        )
        
        # Vider les prédictions pour régénération
        systeme.predictions = PredictionDemande[]
        
        try
            rm("config/", recursive=true, force=true)
            println("✅ Configuration réinitialisée avec succès")
        catch e
            println("⚠️ Erreur suppression fichiers: $e")
        end
        
        println("💡 Redémarrez le système pour appliquer complètement")
    else
        println("❌ Réinitialisation annulée")
    end
end

"""
Crée une sauvegarde complète de la configuration et des données du système
au format JSON avec horodatage.
"""
function sauvegarder_configuration_complete(systeme::SystemeSOTRACO)
    println("\n💾 SAUVEGARDE COMPLÈTE DE LA CONFIGURATION")
    
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    nom_sauvegarde = "config_sotraco_$timestamp"
    
    try
        mkpath("config/sauvegardes")
        
        config_globale = Dict(
            "version" => "2.0.0",
            "timestamp" => timestamp,
            "config_carte" => Dict(
                "centre_lat" => systeme.config_carte.centre_lat,
                "centre_lon" => systeme.config_carte.centre_lon,
                "zoom_initial" => systeme.config_carte.zoom_initial,
                "couleurs_lignes" => systeme.config_carte.couleurs_lignes
            ),
            "statistiques_systeme" => Dict(
                "nb_arrets" => length(systeme.arrets),
                "nb_lignes" => length(systeme.lignes), 
                "nb_predictions" => length(systeme.predictions)
            )
        )
        
        chemin_sauvegarde = "config/sauvegardes/$nom_sauvegarde.json"
        open(chemin_sauvegarde, "w") do file
            JSON3.pretty(file, config_globale)
        end
        
        println("✅ Configuration sauvegardée: $chemin_sauvegarde")
        
        sauvegarder_donnees_systeme(systeme, nom_sauvegarde)
        
    catch e
        println("❌ Erreur sauvegarde: $e")
    end
end

# =====================================================
# FONCTIONS AUXILIAIRES
# =====================================================

"""
Affiche les paramètres actuels de prédiction sous forme de tableau.
"""
function afficher_parametres_actuels(config::Dict)
    println("\n📋 PARAMÈTRES ACTUELS:")
    println("┌──────────────────────────────┬─────────────────┐")
    println("│ Paramètre                    │ Valeur          │")
    println("├──────────────────────────────┼─────────────────┤")
    
    parametres = [
        ("Horizon par défaut (jours)", config["horizon_defaut"]),
        ("Facteur saisonnier", config["facteur_saisonnier"]),
        ("Sensibilité météo", config["sensibilite_meteo"]),
        ("Pondération historique", config["ponderation_historique"]),
        ("Seuil de confiance", config["seuil_confiance"]),
        ("Fréquence mise à jour", config["frequence_mise_a_jour"])
    ]
    
    for (nom, valeur) in parametres
        nom_pad = rpad(nom, 28)
        valeur_str = rpad(string(valeur), 15)
        println("│ $nom_pad │ $valeur_str │")
    end
    
    println("└──────────────────────────────┴─────────────────┘")
end

"""
Affiche la configuration actuelle d'optimisation.
"""
function afficher_config_optimisation_actuelle(config::Dict)
    println("\n📋 CONFIGURATION ACTUELLE D'OPTIMISATION:")
    println("┌──────────────────────────────────┬─────────────────┐")
    println("│ Paramètre                        │ Valeur          │")
    println("├──────────────────────────────────┼─────────────────┤")
    
    parametres = [
        ("Seuil occupation max", "seuil_occupation_max", "%"),
        ("Fréquence min (min)", "frequence_min_autorisee", ""),
        ("Fréquence max (min)", "frequence_max_autorisee", ""),
        ("Tolérance variation", "tolerance_variation", "%"),
        ("Critère principal", "critere_optimisation", ""),
        ("Coeff. économie", "coefficient_economie", ""),
        ("Coeff. service", "coefficient_service", ""),
        ("Coeff. environnement", "coefficient_environnement", ""),
        ("Pénalité surcharge", "penalite_surcharge", "x"),
        ("Bonus sous-util.", "bonus_sous_utilisation", "x")
    ]
    
    for (nom, cle, unite) in parametres
        if haskey(config, cle)
            nom_pad = rpad(nom, 32)
            if unite == "%"
                valeur_str = "$(round(config[cle] * 100, digits=1))%"
            else
                valeur_str = "$(config[cle])$unite"
            end
            valeur_pad = rpad(valeur_str, 15)
            println("│ $nom_pad │ $valeur_pad │")
        end
    end
    
    println("└──────────────────────────────────┴─────────────────┘")
end

"""
Configure l'horizon de prédiction par défaut avec validation des entrées.
"""
function configurer_horizon_prediction!(config::Dict)
    println("\n📅 CONFIGURATION HORIZON DE PRÉDICTION")
    println("Horizon actuel: $(config["horizon_defaut"]) jours")
    println("Recommandé: 3-14 jours (plus long = moins précis)")
    
    print("Nouvel horizon (jours): ")
    try
        nouvel_horizon = parse(Int, readline())
        if 1 <= nouvel_horizon <= 30
            config["horizon_defaut"] = nouvel_horizon
            println("✅ Horizon mis à jour: $nouvel_horizon jours")
        else
            println("❌ Horizon doit être entre 1 et 30 jours")
        end
    catch
        println("❌ Valeur invalide")
    end
end

"""
Configure le facteur saisonnier pour ajuster les prédictions selon les variations climatiques.
"""
function configurer_facteur_saisonnier!(config::Dict)
    println("\n🌍 CONFIGURATION FACTEUR SAISONNIER")
    println("Facteur actuel: $(config["facteur_saisonnier"])")
    println("1.0 = normal, >1.0 = augmentation saisonnière, <1.0 = réduction")
    
    print("Nouveau facteur (0.5-2.0): ")
    try
        nouveau_facteur = parse(Float64, readline())
        if 0.5 <= nouveau_facteur <= 2.0
            config["facteur_saisonnier"] = nouveau_facteur
            println("✅ Facteur saisonnier mis à jour: $nouveau_facteur")
        else
            println("❌ Facteur doit être entre 0.5 et 2.0")
        end
    catch
        println("❌ Valeur invalide")
    end
end

"""
Configure la sensibilité aux conditions météorologiques.
"""
function configurer_sensibilite_meteo!(config::Dict)
    println("\n🌦️ CONFIGURATION SENSIBILITÉ MÉTÉO")
    println("Sensibilité actuelle: $(config["sensibilite_meteo"])")
    println("0.0 = ignore météo, 0.5 = forte influence")
    
    print("Nouvelle sensibilité (0.0-0.5): ")
    try
        nouvelle_sensibilite = parse(Float64, readline())
        if 0.0 <= nouvelle_sensibilite <= 0.5
            config["sensibilite_meteo"] = nouvelle_sensibilite
            println("✅ Sensibilité météo mise à jour: $nouvelle_sensibilite")
        else
            println("❌ Sensibilité doit être entre 0.0 et 0.5")
        end
    catch
        println("❌ Valeur invalide")
    end
end

"""
Configure le poids accordé aux données historiques dans les prédictions.
"""
function configurer_ponderation_historique!(config::Dict)
    println("\n📊 CONFIGURATION PONDÉRATION HISTORIQUE")
    println("Pondération actuelle: $(config["ponderation_historique"])")
    println("0.0 = ignore historique, 1.0 = se base uniquement sur l'historique")
    
    print("Nouvelle pondération (0.1-1.0): ")
    try
        nouvelle_ponderation = parse(Float64, readline())
        if 0.1 <= nouvelle_ponderation <= 1.0
            config["ponderation_historique"] = nouvelle_ponderation
            println("✅ Pondération historique mise à jour: $nouvelle_ponderation")
        else
            println("❌ Pondération doit être entre 0.1 et 1.0")
        end
    catch
        println("❌ Valeur invalide")
    end
end

"""
Configure le seuil de confiance minimum pour les prédictions.
"""
function configurer_seuil_confiance!(config::Dict)
    println("\n🎯 CONFIGURATION SEUIL DE CONFIANCE")
    println("Seuil actuel: $(config["seuil_confiance"])")
    println("Plus élevé = prédictions plus conservatrices")
    
    print("Nouveau seuil (0.5-0.99): ")
    try
        nouveau_seuil = parse(Float64, readline())
        if 0.5 <= nouveau_seuil <= 0.99
            config["seuil_confiance"] = nouveau_seuil
            println("✅ Seuil de confiance mis à jour: $nouveau_seuil")
        else
            println("❌ Seuil doit être entre 0.5 et 0.99")
        end
    catch
        println("❌ Valeur invalide")
    end
end

"""
Configure la fréquence de mise à jour des prédictions.
"""
function configurer_frequence_maj!(config::Dict)
    println("\n⏱️ CONFIGURATION FRÉQUENCE MISE À JOUR")
    println("Fréquence actuelle: $(config["frequence_mise_a_jour"])")
    
    println("Options disponibles:")
    println("1. Temps réel (continue)")
    println("2. Horaire")
    println("3. Quotidienne")
    println("4. Hebdomadaire")
    
    print("Choix (1-4): ")
    choix = readline()
    
    frequences = Dict(
        "1" => "temps_reel",
        "2" => "horaire", 
        "3" => "quotidienne",
        "4" => "hebdomadaire"
    )
    
    if haskey(frequences, choix)
        config["frequence_mise_a_jour"] = frequences[choix]
        println("✅ Fréquence mise à jour: $(frequences[choix])")
    else
        println("❌ Choix invalide")
    end
end

"""
Configure le seuil d'occupation maximum.
"""
function configurer_seuil_occupation!(config::Dict)
    println("\n📊 CONFIGURATION SEUIL D'OCCUPATION MAXIMUM")
    println("Seuil actuel: $(round(config["seuil_occupation_max"] * 100, digits=1))%")
    println("Recommandé: 80-90% (au-delà = surcharge)")
    
    print("Nouveau seuil (0.5-1.0): ")
    try
        nouveau_seuil = parse(Float64, readline())
        if 0.5 <= nouveau_seuil <= 1.0
            config["seuil_occupation_max"] = nouveau_seuil
            println("✅ Seuil mis à jour: $(round(nouveau_seuil * 100, digits=1))%")
        else
            println("❌ Seuil doit être entre 50% et 100%")
        end
    catch
        println("❌ Valeur invalide")
    end
end

"""
Configure les fréquences minimales et maximales autorisées.
"""
function configurer_frequences_limites!(config::Dict)
    println("\n⏰ CONFIGURATION DES FRÉQUENCES LIMITES")
    println("Fréquence min actuelle: $(config["frequence_min_autorisee"]) minutes")
    println("Fréquence max actuelle: $(config["frequence_max_autorisee"]) minutes")
    
    print("Nouvelle fréquence minimum (3-15 min): ")
    try
        freq_min = parse(Int, readline())
        if 3 <= freq_min <= 15
            config["frequence_min_autorisee"] = freq_min
            println("✅ Fréquence min mise à jour: $freq_min minutes")
        else
            println("❌ Fréquence min doit être entre 3 et 15 minutes")
        end
    catch
        println("❌ Valeur invalide pour fréquence min")
    end
    
    print("Nouvelle fréquence maximum (20-60 min): ")
    try
        freq_max = parse(Int, readline())
        if 20 <= freq_max <= 60 && freq_max > config["frequence_min_autorisee"]
            config["frequence_max_autorisee"] = freq_max
            println("✅ Fréquence max mise à jour: $freq_max minutes")
        else
            println("❌ Fréquence max doit être entre 20-60 min et > fréquence min")
        end
    catch
        println("❌ Valeur invalide pour fréquence max")
    end
end

"""
Configure la tolérance de variation.
"""
function configurer_tolerance!(config::Dict)
    println("\n📈 CONFIGURATION TOLÉRANCE DE VARIATION")
    println("Tolérance actuelle: $(round(config["tolerance_variation"] * 100, digits=1))%")
    println("Définit l'amplitude de variation autorisée par rapport aux valeurs optimales")
    
    print("Nouvelle tolérance (0.05-0.3): ")
    try
        nouvelle_tolerance = parse(Float64, readline())
        if 0.05 <= nouvelle_tolerance <= 0.3
            config["tolerance_variation"] = nouvelle_tolerance
            println("✅ Tolérance mise à jour: $(round(nouvelle_tolerance * 100, digits=1))%")
        else
            println("❌ Tolérance doit être entre 5% et 30%")
        end
    catch
        println("❌ Valeur invalide")
    end
end

"""
Configure le critère d'optimisation principal.
"""
function configurer_critere_principal!(config::Dict)
    println("\n🎯 CONFIGURATION CRITÈRE D'OPTIMISATION PRINCIPAL")
    println("Critère actuel: $(config["critere_optimisation"])")
    
    criteres = Dict(
        "1" => "efficacite",
        "2" => "economie", 
        "3" => "satisfaction",
        "4" => "equilibre"
    )
    
    println("Critères disponibles:")
    println("1. Efficacité (occupation optimale)")
    println("2. Économie (réduction coûts)")
    println("3. Satisfaction (service usagers)")
    println("4. Équilibré (compromis)")
    
    print("Choix (1-4): ")
    choix = readline()
    
    if haskey(criteres, choix)
        config["critere_optimisation"] = criteres[choix]
        println("✅ Critère mis à jour: $(criteres[choix])")
    else
        println("❌ Choix invalide")
    end
end

"""
Configure les coefficients de pondération.
"""
function configurer_coefficients_ponderation!(config::Dict)
    println("\n⚖️ CONFIGURATION COEFFICIENTS DE PONDÉRATION")
    println("Les coefficients doivent totaliser 1.0")
    
    println("Coefficients actuels:")
    println("• Économie: $(config["coefficient_economie"])")
    println("• Service: $(config["coefficient_service"])") 
    println("• Environnement: $(config["coefficient_environnement"])")
    
    print("Nouveau coefficient économie (0.1-0.6): ")
    try
        coef_eco = parse(Float64, readline())
        if 0.1 <= coef_eco <= 0.6
            config["coefficient_economie"] = coef_eco
        else
            println("❌ Coefficient économie doit être entre 0.1 et 0.6")
            return
        end
    catch
        println("❌ Valeur invalide")
        return
    end
    
    print("Nouveau coefficient service (0.2-0.7): ")
    try
        coef_service = parse(Float64, readline())
        if 0.2 <= coef_service <= 0.7
            config["coefficient_service"] = coef_service
        else
            println("❌ Coefficient service doit être entre 0.2 et 0.7")
            return
        end
    catch
        println("❌ Valeur invalide")
        return
    end
    
    # Calculer automatiquement le coefficient environnement
    coef_env = 1.0 - config["coefficient_economie"] - config["coefficient_service"]
    
    if coef_env < 0.1 || coef_env > 0.5
        println("❌ Configuration invalide: coefficient environnement = $coef_env")
        println("Les coefficients doivent totaliser 1.0 avec env. entre 0.1-0.5")
        return
    end
    
    config["coefficient_environnement"] = coef_env
    
    println("✅ Coefficients mis à jour:")
    println("• Économie: $(config["coefficient_economie"])")
    println("• Service: $(config["coefficient_service"])")
    println("• Environnement: $(config["coefficient_environnement"])")
end

"""
Configure les paramètres de pénalité.
"""
function configurer_parametres_penalite!(config::Dict)
    println("\n⚡ CONFIGURATION PARAMÈTRES DE PÉNALITÉ")
    
    println("Pénalité surcharge actuelle: $(config["penalite_surcharge"])x")
    print("Nouvelle pénalité surcharge (1.2-3.0): ")
    try
        penalite = parse(Float64, readline())
        if 1.2 <= penalite <= 3.0
            config["penalite_surcharge"] = penalite
            println("✅ Pénalité surcharge: $(penalite)x")
        else
            println("❌ Pénalité doit être entre 1.2 et 3.0")
        end
    catch
        println("❌ Valeur invalide")
    end
    
    println("Bonus sous-utilisation actuel: $(config["bonus_sous_utilisation"])x")
    print("Nouveau bonus sous-utilisation (0.5-0.9): ")
    try
        bonus = parse(Float64, readline())
        if 0.5 <= bonus <= 0.9
            config["bonus_sous_utilisation"] = bonus
            println("✅ Bonus sous-utilisation: $(bonus)x")
        else
            println("❌ Bonus doit être entre 0.5 et 0.9")
        end
    catch
        println("❌ Valeur invalide")
    end
end

"""
Remet tous les paramètres de configuration aux valeurs par défaut.
"""
function reinitialiser_config_defaut!(config::Dict)
    println("\n🔄 RÉINITIALISATION AUX VALEURS PAR DÉFAUT")
    print("Êtes-vous sûr? Cette action est irréversible (o/n): ")
    
    if lowercase(readline()) in ["o", "oui", "y", "yes"]
        config["horizon_defaut"] = 7
        config["facteur_saisonnier"] = 1.0
        config["sensibilite_meteo"] = 0.1
        config["ponderation_historique"] = 0.7
        config["seuil_confiance"] = 0.85
        config["frequence_mise_a_jour"] = "quotidienne"
        
        println("✅ Configuration réinitialisée aux valeurs par défaut")
    else
        println("❌ Réinitialisation annulée")
    end
end

"""
Applique la nouvelle configuration au système et régénère les prédictions.
"""
function appliquer_configuration(systeme::SystemeSOTRACO, config::Dict)
    println("\n💾 APPLICATION DE LA CONFIGURATION...")
    
    try
        mkpath("config")
        config_path = "config/prediction_params.json"
        
        open(config_path, "w") do file
            JSON3.pretty(file, config)
        end
        
        println("🔄 Régénération des prédictions avec nouveaux paramètres...")
        horizon = config["horizon_defaut"]
        
        # Effacer les anciennes prédictions
        systeme.predictions = PredictionDemande[]
        
        # Générer nouvelles prédictions avec la notation complète
        nouvelles_predictions = Prediction.predire_demande_globale(systeme, horizon)
        
        println("✅ Configuration appliquée avec succès!")
        println("📁 Sauvegardée dans: $config_path")
        println("🔮 $(length(systeme.predictions)) nouvelles prédictions générées")
        
    catch e
        println("❌ Erreur lors de l'application: $e")
    end
end

"""
Applique et sauvegarde la configuration d'optimisation.
"""
function appliquer_config_optimisation(systeme::SystemeSOTRACO, config::Dict)
    println("\n💾 APPLICATION ET SAUVEGARDE DE LA CONFIGURATION")
    
    try
        # Créer le dossier config
        mkpath("config")
        
        # Sauvegarder la configuration
        chemin_config = "config/optimisation_params.json"
        open(chemin_config, "w") do file
            JSON3.pretty(file, config)
        end
        
        println("✅ Configuration sauvegardée: $chemin_config")
        
        # Appliquer immédiatement si possible
        nb_lignes_modifiees = appliquer_optimisation_immediate(systeme, config)
        
        println("🔄 Configuration appliquée à $nb_lignes_modifiees lignes")
        
        # Résumé final
        println("\n📊 RÉSUMÉ DE L'APPLICATION:")
        println("• Paramètres sauvegardés et actifs")
        println("• Prochaines optimisations utiliseront ces paramètres")
        println("• Critère principal: $(config["critere_optimisation"])")
        
    catch e
        println("❌ Erreur lors de l'application: $e")
    end
end

"""
Applique immédiatement l'optimisation avec les nouveaux paramètres.
"""
function appliquer_optimisation_immediate(systeme::SystemeSOTRACO, config::Dict)
    nb_modifications = 0
    
    for ligne in values(systeme.lignes)
        if ligne.statut == "Actif"
            freq_optimale = calculer_frequence_optimale_test(ligne, config)
            
            # Simulation de modification (dans un vrai système, on modifierait la ligne)
            if freq_optimale != ligne.frequence_min
                nb_modifications += 1
                println("   • Ligne $(ligne.id): $(ligne.frequence_min) → $(freq_optimale) min")
            end
        end
    end
    
    return nb_modifications
end

"""
Calcule une fréquence optimale de test avec les nouveaux paramètres.
"""
function calculer_frequence_optimale_test(ligne::LigneBus, config::Dict)
    # Simulation simple basée sur la distance et les paramètres
    base_freq = ligne.frequence_min
    
    # Ajustement selon le critère principal
    if config["critere_optimisation"] == "economie"
        # Mode économie: augmenter fréquence
        freq_optimale = min(base_freq + 3, config["frequence_max_autorisee"])
    elseif config["critere_optimisation"] == "satisfaction"
        # Mode satisfaction: réduire fréquence
        freq_optimale = max(base_freq - 2, config["frequence_min_autorisee"])
    else
        # Mode équilibré
        freq_optimale = base_freq
    end
    
    return Int(round(freq_optimale))
end

"""
Sauvegarde les données structurelles du système pour archivage.
"""
function sauvegarder_donnees_systeme(systeme::SystemeSOTRACO, nom_sauvegarde::String)
    try
        chemin_donnees = "config/sauvegardes/donnees_$nom_sauvegarde.json"
        
        donnees = Dict(
            "arrets" => Dict(string(k) => Dict(
                "nom" => v.nom,
                "latitude" => v.latitude,
                "longitude" => v.longitude,
                "quartier" => v.quartier,
                "zone" => v.zone
            ) for (k, v) in systeme.arrets),
            
            "lignes" => Dict(string(k) => Dict(
                "nom" => v.nom,
                "origine" => v.origine,
                "destination" => v.destination,
                "distance_km" => v.distance_km,
                "tarif_fcfa" => v.tarif_fcfa,
                "statut" => v.statut
            ) for (k, v) in systeme.lignes),
            
            "nb_frequentation" => length(systeme.frequentation),
            "nb_predictions" => length(systeme.predictions)
        )
        
        open(chemin_donnees, "w") do file
            JSON3.pretty(file, donnees)
        end
        
        println("💾 Données sauvegardées: $chemin_donnees")
        
    catch e
        println("⚠️ Erreur sauvegarde données: $e")
    end
end

"""
Interface temporaire pour la personnalisation de carte en attendant l'intégration complète.
"""
function gerer_personnalisation_carte(systeme::SystemeSOTRACO)
    println("\n🎨 PERSONNALISATION DE LA CARTE")
    println("Cette fonctionnalité sera déléguée au module CarteInteractive")
    println("💡 Utilisez l'option 7 du menu principal pour la carte interactive")
end

end # module ConfigurationAvancee