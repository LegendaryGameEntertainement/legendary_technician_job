AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("LG_OpenVentMinigame")
util.AddNetworkString("LG_VentMinigameResult")

function ENT:Initialize()
    self:SetModel("models/props_c17/FurnitureFireplace001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end

    self:SetIsBlocked(false)

    -- Chance de spawn obstruée
    if LEGENDARY_TECHNICIAN.VentilationCanBeBlocked and math.random() < (LEGENDARY_TECHNICIAN.VentilationBlockChance or 0) then
        self:SetIsBlocked(true)
    end

    -- Programmation d’une obstruction automatique
    self:ScheduleAutoBlock()
end

function ENT:ScheduleAutoBlock()
    local interval = LEGENDARY_TECHNICIAN.VentilationBlockInterval or 600
    if interval <= 0 then return end

    timer.Create("LG_VentAutoBlock_" .. self:EntIndex(), interval, 0, function()
        if not IsValid(self) then return end
        if not LEGENDARY_TECHNICIAN.VentilationCanBeBlocked then return end
        if self:GetIsBlocked() then return end

        -- Petite chance à chaque tick, ou tu peux forcer
        if math.random() < 0.5 then
            self:SetIsBlocked(true)
            self:EmitSound("ambient/machines/wall_vent_closing1.wav")
        end
    end)
end

function ENT:OnRemove()
    timer.Remove("LG_VentAutoBlock_" .. self:EntIndex())
end

-- Vérifie si le joueur est bien technicien (copié / adapté de ta poubelle)
function ENT:IsCorrectJob(ply)
    if not DarkRP then return false end

    local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
    if not techTeam then return false end

    if type(techTeam) == "number" then
        return ply:Team() == techTeam
    elseif type(techTeam) == "string" then
        if not ply.getDarkRPVar then return false end
        local jobName = ply:getDarkRPVar("job")
        return jobName == techTeam
    end
    return false
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if not self:GetIsBlocked() then
        activator:ChatPrint("[Technicien] Cette ventilation fonctionne correctement, rien à faire.")
        return
    end

    -- Ouvrir le mini-jeu de réparation
    net.Start("LG_OpenVentMinigame")
    net.WriteEntity(self)
    net.Send(activator)
end

-- Résultat du mini-jeu
net.Receive("LG_VentMinigameResult", function(len, ply)
    local vent = net.ReadEntity()
    local success = net.ReadBool()

    if not IsValid(vent) or vent:GetClass() ~= "lg_ventilation" then return end
    if not vent:IsCorrectJob(ply) then return end
    if not vent:GetIsBlocked() then return end

    if success then
        vent:SetIsBlocked(false)
        vent:EmitSound("ambient/machines/wall_vent_open1.wav")

        ply:ChatPrint("[Technicien] Ventilation réparée avec succès !")
    else
        ply:ChatPrint("[Technicien] Réparation échouée, réessayez !")
    end
end)

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end

    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 20)
    ent:Spawn()
    ent:Activate()

    return ent
end
