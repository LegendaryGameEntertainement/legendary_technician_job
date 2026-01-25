ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Recycleur"
ENT.Author = "Ton Nom"
ENT.Category = "SCP RP - Technician"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "TrashBags")
    
    -- Compteurs pour chaque type de déchet
    self:NetworkVar("Int", 1, "PlastiqueCount")
    self:NetworkVar("Int", 2, "MetalCount")
    self:NetworkVar("Int", 3, "PapierCount")
    self:NetworkVar("Int", 4, "OrganiqueCount")
    self:NetworkVar("Int", 5, "VerreCount")
end
