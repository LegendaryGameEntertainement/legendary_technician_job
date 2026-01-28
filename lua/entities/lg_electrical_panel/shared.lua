ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Armoire Électrique"
ENT.Author = "Mathrixte"
ENT.Category = "SCP RP - Technician"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "IsBroken")
    self:NetworkVar("Float", 0, "BreakdownTime")
end
