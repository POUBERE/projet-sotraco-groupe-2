/**
 * Module JavaScript pour la gestion de la carte interactive SOTRACO
 */

class CarteSOTRACO {
    constructor(containerId, config = {}) {
        this.containerId = containerId;
        this.config = {
            center: [12.3686, -1.5275],
            zoom: 12,
            ...config,
        };
        this.map = null;
        this.arrets = [];
        this.lignes = [];
        this.markers = {};
        this.polylines = {};
    }

    /**
     * Initialise la carte avec les paramètres de configuration
     */
    initialiser() {
        if (this.map) return;

        this.map = L.map(this.containerId).setView(
            this.config.center,
            this.config.zoom
        );

        L.tileLayer(
            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            {
                attribution: "© OpenStreetMap contributors",
            }
        ).addTo(this.map);

        // Initialisation des groupes de couches pour les arrêts et lignes
        this.arretGroup = L.layerGroup().addTo(this.map);
        this.ligneGroup = L.layerGroup().addTo(this.map);

        console.log("Carte SOTRACO initialisée");
    }

    /**
     * Récupère les données des arrêts et lignes depuis l'API
     */
    async chargerDonnees() {
        try {
            const arretsResponse = await fetch("http://127.0.0.1:8081/api/arrets");
            const arretsData = await arretsResponse.json();

            if (arretsData.success) {
                this.arrets = arretsData.data.arrets;
                this.dessinerArrets();
            }

            const lignesResponse = await fetch("http://127.0.0.1:8081/api/lignes");
            const lignesData = await lignesResponse.json();

            if (lignesData.success) {
                this.lignes = lignesData.data.lignes;
                this.dessinerLignes();
            }
        } catch (error) {
            console.error("Erreur chargement données carte:", error);
        }
    }

    /**
     * Affiche les arrêts sur la carte avec marqueurs colorés selon l'équipement
     */
    dessinerArrets() {
        this.arrets.forEach((arret) => {
            const couleur = this.getCouleurArret(arret);

            const marker = L.circleMarker(
                [
                    arret.coordonnees.latitude,
                    arret.coordonnees.longitude,
                ],
                {
                    radius: 8,
                    fillColor: couleur,
                    color: "#ffffff",
                    weight: 2,
                    opacity: 1,
                    fillOpacity: 0.8,
                }
            );

            const popupContent = this.creerPopupArret(arret);
            marker.bindPopup(popupContent);

            marker.addTo(this.arretGroup);
            this.markers[arret.id] = marker;
        });
    }

    /**
     * Dessine les lignes sur la carte
     */
    dessinerLignes() {
        // Fonctionnalité en cours de développement
        console.log("Dessin des lignes - fonctionnalité à compléter");
    }

    /**
     * Retourne une couleur selon le niveau d'équipement de l'arrêt
     */
    getCouleurArret(arret) {
        if (arret.equipements.abribus && arret.equipements.eclairage) {
            return "#2E8B57"; // Vert - équipement complet
        } else if (arret.equipements.abribus || arret.equipements.eclairage) {
            return "#FFD700"; // Jaune - équipement partiel
        } else {
            return "#DC143C"; // Rouge - sans équipement
        }
    }

    /**
     * Génère le contenu HTML pour les popups d'information des arrêts
     */
    creerPopupArret(arret) {
        return `
            <div style="font-family: Arial, sans-serif; min-width: 200px;">
                <h3 style="margin: 0 0 10px 0; color: #2E8B57; font-size: 1.1em;">
                    ${arret.nom}
                </h3>
                <div style="margin-bottom: 8px;">
                    <strong>Zone:</strong> ${arret.zone}
                </div>
                <div style="margin-bottom: 8px;">
                    <strong>Quartier:</strong> ${arret.quartier}
                </div>
                <div style="margin-bottom: 8px;">
                    <strong>Lignes:</strong> ${arret.lignes_desservies.join(", ")}
                </div>
                <div style="margin-bottom: 8px;">
                    <strong>Abribus:</strong> 
                    <span style="color: ${
                        arret.equipements.abribus ? "#28a745" : "#dc3545"
                    };">
                        ${arret.equipements.abribus ? "✓ Oui" : "✗ Non"}
                    </span>
                </div>
                <div style="margin-bottom: 12px;">
                    <strong>Éclairage:</strong> 
                    <span style="color: ${
                        arret.equipements.eclairage ? "#28a745" : "#dc3545"
                    };">
                        ${arret.equipements.eclairage ? "✓ Oui" : "✗ Non"}
                    </span>
                </div>
                <button onclick="voirDetailArret(${arret.id})" 
                        style="background: #2E8B57; color: white; border: none; 
                               padding: 6px 12px; border-radius: 4px; cursor: pointer;
                               font-size: 0.9em;">
                    Voir détails
                </button>
            </div>
        `;
    }

    /**
     * Affiche uniquement les arrêts d'une ligne spécifique
     */
    filtrerParLigne(ligneId) {
        this.arretGroup.clearLayers();

        if (!ligneId) {
            this.dessinerArrets();
            return;
        }

        const arretsFiltes = this.arrets.filter((arret) =>
            arret.lignes_desservies.includes(parseInt(ligneId))
        );

        arretsFiltes.forEach((arret) => {
            const marker = this.markers[arret.id];
            if (marker) {
                marker.addTo(this.arretGroup);
            }
        });
    }

    /**
     * Centre la vue de la carte sur un arrêt spécifique et ouvre son popup
     */
    centrerSurArret(arretId) {
        const arret = this.arrets.find((a) => a.id === arretId);
        if (arret) {
            this.map.setView(
                [
                    arret.coordonnees.latitude,
                    arret.coordonnees.longitude,
                ],
                15
            );

            const marker = this.markers[arretId];
            if (marker) {
                marker.openPopup();
            }
        }
    }

    /**
     * Génère un fichier JSON avec toutes les données actuelles de la carte
     */
    exporterDonnees() {
        const donnees = {
            arrets: this.arrets,
            lignes: this.lignes,
            centre_carte: this.map.getCenter(),
            zoom: this.map.getZoom(),
            timestamp: new Date().toISOString(),
        };

        const blob = new Blob(
            [JSON.stringify(donnees, null, 2)],
            { type: "application/json" }
        );

        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `carte_sotraco_${
            new Date().toISOString().split("T")[0]
        }.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }
}

// Fonction utilitaire pour l'affichage des détails d'un arrêt
window.voirDetailArret = function (arretId) {
    alert(`Détails de l'arrêt ${arretId} - Fonctionnalité à implémenter`);
};

window.CarteSOTRACO = CarteSOTRACO;