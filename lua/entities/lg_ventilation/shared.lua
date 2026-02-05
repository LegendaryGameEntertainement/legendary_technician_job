ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Ventilation"
ENT.Author = "Mathrixte"
ENT.Category = "SCP RP - Technician"

ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
    -- 0 = pas obstruée, 1 = obstruée
    self:NetworkVar("Bool", 0, "IsBlocked")
end
