AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- S'assurer que la config existe avec une valeur par défaut
LEGENDARY_TECHNICIAN = LEGENDARY_TECHNICIAN or {}
LEGENDARY_TECHNICIAN.TrashRequired = LEGENDARY_TECHNICIAN.TrashRequired or 20

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
    self:SetPlastiqueCount(0)
    self:SetMetalCount(0)
    self:SetPapierCount(0)
    self:SetOrganiqueCount(0)
    self:SetVerreCount(0)
    
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    print("[TRIEUR] Utilisation par " .. activator:Nick())
    
    -- Ouvrir le mini-jeu de tri
    if self:GetTrashBags() > 0 then
        net.Start("OpenSorterMinigame")
        net.WriteEntity(self)
        net.Send(activator)
    else
        activator:ChatPrint("Le trieur est vide ! Ajoutez des sacs poubelles (pose-les à côté).")
    end
end

function ENT:Think()
    -- Chercher les sacs poubelles à proximité
    local nearbyEnts = ents.FindInSphere(self:GetPos(), 100)
    
    for _, ent in pairs(nearbyEnts) do
        if IsValid(ent) and ent:GetClass() == "lg_trashbag" and ent != self then
            print("[TRIEUR] Sac détecté ! Classe: " .. ent:GetClass())
            
            -- Effet visuel/sonore
            local effectdata = EffectData()
            effectdata:SetOrigin(ent:GetPos())
            util.Effect("GlassImpact", effectdata)
            
            self:EmitSound("items/ammocrate_close.wav")
            
            -- Supprimer le sac et augmenter le compteur
            ent:Remove()
            self:SetTrashBags(self:GetTrashBags() + 1)
            
            print("[TRIEUR] Sac absorbé ! Total: " .. self:GetTrashBags())
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

util.AddNetworkString("OpenSorterMinigame")
util.AddNetworkString("SorterMinigameResult")
util.AddNetworkString("SorterSpawnBac")

net.Receive("SorterSpawnBac", function(len, ply)
    local sorter = net.ReadEntity()
    local trashType = net.ReadInt(8)
    
    if not IsValid(sorter) or sorter:GetClass() ~= "lg_sorter" then return end
    
    local bacEntities = {
        [1] = "lg_plastic_container",
        [2] = "lg_metal_container",
        [3] = "lg_paper_container",
        [4] = "lg_organic_container",
        [5] = "lg_glass_container"
    }
    
    local trashNames = {
        [1] = "Plastique",
        [2] = "Métal",
        [3] = "Papier",
        [4] = "Organique",
        [5] = "Verre"
    }
    
    -- Réinitialiser le compteur correspondant après avoir généré le bac
    if trashType == 1 then
        sorter:SetPlastiqueCount(0)
    elseif trashType == 2 then
        sorter:SetMetalCount(0)
    elseif trashType == 3 then
        sorter:SetPapierCount(0)
    elseif trashType == 4 then
        sorter:SetOrganiqueCount(0)
    elseif trashType == 5 then
        sorter:SetVerreCount(0)
    end
    
    ply:ChatPrint("[Trieur] Un bac de " .. trashNames[trashType] .. " a été généré !")
    
    local bacClass = bacEntities[trashType]
    local bac = ents.Create(bacClass)
    
    if IsValid(bac) then
        local spawnPos = sorter:GetPos() + sorter:GetForward() * 80 + sorter:GetRight() * (math.random(-30, 30))
        bac:SetPos(spawnPos)
        bac:SetAngles(sorter:GetAngles())
        bac:Spawn()
        bac:Activate()
        
        ply:ChatPrint("[Trieur] Bac de " .. trashNames[trashType] .. " créé !")
    end
end)

net.Receive("SorterMinigameResult", function(len, ply)
    local sorter = net.ReadEntity()
    local success = net.ReadBool()
    local score = net.ReadInt(16)
    local sortedTrash = net.ReadTable()
    
    if not IsValid(sorter) or sorter:GetClass() ~= "lg_sorter" then return end
    
    sorter:SetPlastiqueCount(sorter:GetPlastiqueCount() + sortedTrash[1])
    sorter:SetMetalCount(sorter:GetMetalCount() + sortedTrash[2])
    sorter:SetPapierCount(sorter:GetPapierCount() + sortedTrash[3])
    sorter:SetOrganiqueCount(sorter:GetOrganiqueCount() + sortedTrash[4])
    sorter:SetVerreCount(sorter:GetVerreCount() + sortedTrash[5])
    
    local required = LEGENDARY_TECHNICIAN.TrashRequired or 20
    
    if success then
        local bagsUsed = math.min(sorter:GetTrashBags(), 1)
        sorter:SetTrashBags(sorter:GetTrashBags() - bagsUsed)
    end
end)
