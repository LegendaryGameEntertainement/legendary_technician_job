LEGENDARY_TECHNICIAN = LEGENDARY_TECHNICIAN or {}
LEGENDARY_FLOOR_TECHNICIAN = LEGENDARY_FLOOR_TECHNICIAN or {}

LEGENDARY_FLOOR_TECHNICIAN.FloorTechnicianTeam = "Technicien de Surface"
LEGENDARY_TECHNICIAN.ElectricianTeam = "Technicien"

LEGENDARY_FLOOR_TECHNICIAN.TrashRequired = 10 -- Nombre de déchets nécessaires pour générer un bac
LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillTime = 10 -- Temps en secondes entre chaque vérification de remplissage 
LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillChance = 0.3 -- Probabilité qu'une poubelle se remplisse à chaque vérification (30%)
LEGENDARY_FLOOR_TECHNICIAN.MaxFullTrashBins = 10 -- Nombre maximum de poubelles pleines en même temps
LEGENDARY_FLOOR_TECHNICIAN.NotificationDuration = 60 -- Durée d'affichage du popup en secondes
LEGENDARY_FLOOR_TECHNICIAN.TrashBinMarkerDistance = 2000 -- Distance maximale d'affichage des marqueurs (en unités source)

-- Configuration des pannes électriques
LEGENDARY_TECHNICIAN.Breakdown = {
    -- Intervalle min et max entre chaque panne (en secondes)
    MinInterval = 5,  
    MaxInterval = 30,  
    
    -- Durée du mini-jeu
    MinigameTime = 60,  -- 60 secondes pour compléter le mini-jeu
    
    -- Nombre de fils à connecter
    WireCount = 6,
    
    -- Distance du marqueur
    MarkerDistance = 2000,
}

-- Liste globale des entités pouvant tomber en panne
LEGENDARY_TECHNICIAN.BreakdownEntities = LEGENDARY_TECHNICIAN.BreakdownEntities or {}

-- Timer global pour les pannes
LEGENDARY_TECHNICIAN.NextBreakdownTime = 0

print("[Legendary Technician] Configuration chargée !")