AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/furniturefridge001a.mdl")
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end
    
    self:SetTrashBags(0)
    
    -- Debug
    print("[RECYCLEUR] Initialisé !")
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    print("[RECYCLEUR] Utilisation par " .. activator:Nick())
    
    -- Ouvrir le mini-jeu de tri
    if self:GetTrashBags() > 0 then
        net.Start("OpenRecyclerMinigame")
        net.WriteEntity(self)
        net.Send(activator)
    else
        activator:ChatPrint("Le recycleur est vide ! Ajoutez des sacs poubelles (pose-les à côté).")
    end
end

function ENT:Think()
    -- Chercher les sacs poubelles à proximité
    local nearbyEnts = ents.FindInSphere(self:GetPos(), 100)
    
    for _, ent in pairs(nearbyEnts) do
        if IsValid(ent) and ent:GetClass() == "lg_trashbag" and ent != self then
            print("[RECYCLEUR] Sac détecté ! Classe: " .. ent:GetClass())
            
            -- Effet visuel/sonore
            local effectdata = EffectData()
            effectdata:SetOrigin(ent:GetPos())
            util.Effect("GlassImpact", effectdata)
            
            self:EmitSound("items/ammocrate_close.wav")
            
            -- Supprimer le sac et augmenter le compteur
            ent:Remove()
            self:SetTrashBags(self:GetTrashBags() + 1)
            
            print("[RECYCLEUR] Sac absorbé ! Total: " .. self:GetTrashBags())
        end
    end
    
    self:NextThink(CurTime() + 0.2)
    return true
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    
    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 50)
    ent:Spawn()
    ent:Activate()
    
    return ent
end

util.AddNetworkString("OpenRecyclerMinigame")
util.AddNetworkString("RecyclerMinigameResult")

net.Receive("RecyclerMinigameResult", function(len, ply)
    local recycler = net.ReadEntity()
    local success = net.ReadBool()
    local score = net.ReadInt(16)
    
    if not IsValid(recycler) or recycler:GetClass() ~= "lg_recycler" then return end
    
    if success then
        local bagsUsed = math.min(recycler:GetTrashBags(), 1)
        recycler:SetTrashBags(recycler:GetTrashBags() - bagsUsed)
        
        ply:ChatPrint("Tri réussi ! Score: " .. score)
    else
        ply:ChatPrint("Tri échoué... Réessaye !")
    end
end)
