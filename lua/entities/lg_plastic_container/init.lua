AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/PlasticCrate01a.mdl")
    self:SetSkin(1)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    if not activator:IsPlayerHolding() then
        activator:PickupObject(self)
    else
        activator:DropObject()
    end
end

function ENT:OnPlayerPickup(ply)
    ply:SetNWEntity("CarryingPlasticContainer", self)
end

function ENT:OnPlayerDrop(ply)
    ply:SetNWEntity("CarryingPlasticContainer", NULL)
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    
    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 10)
    ent:Spawn()
    ent:Activate()
    
    return ent
end
