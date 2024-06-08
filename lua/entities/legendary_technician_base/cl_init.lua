include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    local lp = LocalPlayer()
    if self:GetPos():DistToSqr(lp:GetPos()) > 300*300 then return end
    if RPExtraTeams[lp:Team()].name ~= LEGENDARY_TECHNICIAN_JOBNAME then return end
    local a = Angle(0,0,0)
    a:RotateAroundAxis(Vector(1,0,0),90)
    a.y = lp:GetAngles().y - 90
    local va,vb = self:GetModelBounds()
    local height = vb.z
    --if vb.z > height then height = vb.z end
    --self:BoundingRadius()
end

function ENT:ShowSparks()
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetMagnitude(1)
    effectdata:SetScale(1)
    effectdata:SetRadius(2)
    util.Effect("Sparks", effectdata)
end

function ENT:Think()
    if self:GetBroken() then
        self:ShowSparks()
    end
    self:SetNextClientThink( CurTime() + 0.5 )
    return true
end
