ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Recycleur"
ENT.Author = "Mathrixte"
ENT.Category = "SCP RP - Technician"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "TrashBags")
end
