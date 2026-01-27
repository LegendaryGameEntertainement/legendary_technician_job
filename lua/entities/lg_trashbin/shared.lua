ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Poubelle"
ENT.Author = "Mathrixte"
ENT.Category = "SCP RP - Technician"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsFull")
end
