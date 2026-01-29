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
    WireCount = 6, -- max 8
    
    -- Distance du marqueur
    MarkerDistance = 2000,
}

-- Configuration des caméras de surveillance
LEGENDARY_TECHNICIAN.Camera = {
    -- Classe de l'entité caméra
    EntityClass = "cam",
    
    -- Points de vie de la caméra
    MaxHealth = 100,
    
    -- La caméra se casse si les PV tombent à 0
    BreakOnZeroHealth = true,
    
    -- Distance du marqueur HUD
    MarkerDistance = 2000,
    
    -- Mini-jeu de calibration
    Minigame = {
        -- Durée du mini-jeu (en secondes)
        TimeLimit = 60,
        
        -- Nombre de calibrations nécessaires
        CalibrationsNeeded = 3,
        
        -- Vitesse de rotation (plus élevé = plus difficile)
        RotationSpeed = 3,
        
        -- Taille de la zone cible (0.1 = 10% du cercle)
        TargetZoneSize = 0.15,
    },
}


LEGENDARY_TECHNICIAN.BreakdownEntities = LEGENDARY_TECHNICIAN.BreakdownEntities or {} -- Liste globale des entités pouvant tomber en panne
LEGENDARY_TECHNICIAN.NextBreakdownTime = 0 -- Timer global pour les pannes

print("[Legendary Technician] Configuration chargée !")