AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/garbage_bag001a.mdl")
    
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
    
    -- Si le joueur ne porte rien, il ramasse le sac
    if not activator:IsPlayerHolding() then
        activator:PickupObject(self)
    -- Si le joueur porte déjà le sac, il le lâche
    else
        activator:DropObject()
    end
end

function ENT:OnPlayerPickup(ply)
    -- Appelé quand le joueur ramasse l'entité
    ply:SetNWEntity("CarryingTrashBag", self)
end

function ENT:OnPlayerDrop(ply)
    -- Appelé quand le joueur lâche l'entité
    ply:SetNWEntity("CarryingTrashBag", NULL)
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    
    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 10)
    ent:Spawn()
    ent:Activate()
    
    return ent
end
