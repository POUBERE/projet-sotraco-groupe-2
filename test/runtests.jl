using Test
using SOTRACO

@testset "Tests SOTRACO" begin
    @testset "Structures de données" begin
        # Test création Arret
        arret = Arret(1, "Gare", "Centre", "Zone 1", 12.0, -1.0, true, true, [1, 2])
        @test arret.id == 1
        @test arret.nom == "Gare"
        @test arret.abribus == true
        @test length(arret.lignes_desservies) == 2

        # Test création LigneBus
        ligne = LigneBus(1, "Ligne 1", "Gare", "Kossodo", 18.0, 45, 150, 20, "Actif", [1, 2, 3])
        @test ligne.id == 1
        @test ligne.distance_km == 18.0
        @test ligne.statut == "Actif"
    end

    @testset "Fonctions système" begin
        # Test avec données minimales
        systeme = SystemeSOTRACO(
            Dict{Int, Arret}(),
            Dict{Int, LigneBus}(),
            DonneeFrequentation[],
            false
        )

        @test systeme.donnees_chargees == false
        @test length(systeme.arrets) == 0
    end
end
