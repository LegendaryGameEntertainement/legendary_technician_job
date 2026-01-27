LEGENDARY_TECHNICIAN = LEGENDARY_TECHNICIAN or {}
LEGENDARY_FLOOR_TECHNICIAN = LEGENDARY_FLOOR_TECHNICIAN or {}


-- Nombre de déchets nécessaires pour générer un bac
LEGENDARY_FLOOR_TECHNICIAN.TrashRequired = 10

LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillTime = 300 -- Temps en secondes entre chaque vérification de remplissage (300 = 5 minutes)
LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillChance = 0.3 -- Probabilité qu'une poubelle se remplisse à chaque vérification (30%)
LEGENDARY_FLOOR_TECHNICIAN.MaxFullTrashBins = 5 -- Nombre maximum de poubelles pleines en même temps
LEGENDARY_FLOOR_TECHNICIAN.NotificationDuration = 10 -- Durée d'affichage du popup en secondes
LEGENDARY_FLOOR_TECHNICIAN.TrashBinMarkerDistance = 2000 -- Distance maximale d'affichage des marqueurs (en unités source)
LEGENDARY_FLOOR_TECHNICIAN.FloorTechnicianTeam = "Technicien de Surface"


print("[Legendary Technician] Configuration chargée !")