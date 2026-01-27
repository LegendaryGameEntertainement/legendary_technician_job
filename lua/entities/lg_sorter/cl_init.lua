include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    -- Afficher le nombre de sacs au-dessus
    local pos = self:GetPos() + Vector(0, 0, 80)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
end
