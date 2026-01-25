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
    
    -- Initialiser les compteurs de déchets
    self:SetPlastiqueCount(0)
    self:SetMetalCount(0)
    self:SetPapierCount(0)
    self:SetOrganiqueCount(0)
    self:SetVerreCount(0)
    
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
util.AddNetworkString("RecyclerSpawnBac")


-- Recevoir la demande de spawn de bac
net.Receive("RecyclerSpawnBac", function(len, ply)
    local recycler = net.ReadEntity()
    local trashType = net.ReadInt(8)
    
    if not IsValid(recycler) or recycler:GetClass() ~= "lg_recycler" then return end
    
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
    
    ply:ChatPrint("[Recycleur] Un bac de " .. trashNames[trashType] .. " a été généré !")
    
    -- PLUS TARD: Quand tu auras créé les entités de bacs, décommente ce code:
 
    local bacClass = bacEntities[trashType]
    local bac = ents.Create(bacClass)
    
    if IsValid(bac) then
        local spawnPos = recycler:GetPos() + recycler:GetForward() * 80 + recycler:GetRight() * (math.random(-30, 30))
        bac:SetPos(spawnPos)
        bac:SetAngles(recycler:GetAngles())
        bac:Spawn()
        bac:Activate()
        
        ply:ChatPrint("[Recycleur] Bac de " .. trashNames[trashType] .. " créé !")
    end

end)


net.Receive("RecyclerMinigameResult", function(len, ply)
    local recycler = net.ReadEntity()
    local success = net.ReadBool()
    local score = net.ReadInt(16)
    local sortedTrash = net.ReadTable()
    
    if not IsValid(recycler) or recycler:GetClass() ~= "lg_recycler" then return end
    
    -- Ajouter les déchets triés aux compteurs persistants
    recycler:SetPlastiqueCount(recycler:GetPlastiqueCount() + sortedTrash[1])
    recycler:SetMetalCount(recycler:GetMetalCount() + sortedTrash[2])
    recycler:SetPapierCount(recycler:GetPapierCount() + sortedTrash[3])
    recycler:SetOrganiqueCount(recycler:GetOrganiqueCount() + sortedTrash[4])
    recycler:SetVerreCount(recycler:GetVerreCount() + sortedTrash[5])
    
    if success then
        local bagsUsed = math.min(recycler:GetTrashBags(), 1)
        recycler:SetTrashBags(recycler:GetTrashBags() - bagsUsed)
        
        ply:ChatPrint("Tri réussi ! Score: " .. score)
        
        ply:ChatPrint("=== Statistiques de tri (cette partie) ===")
        ply:ChatPrint("Plastique: " .. sortedTrash[1])
        ply:ChatPrint("Métal: " .. sortedTrash[2])
        ply:ChatPrint("Papier: " .. sortedTrash[3])
        ply:ChatPrint("Organique: " .. sortedTrash[4])
        ply:ChatPrint("Verre: " .. sortedTrash[5])
        
        ply:ChatPrint("=== Total stocké dans le recycleur ===")
        ply:ChatPrint("Plastique: " .. recycler:GetPlastiqueCount() .. "/20")
        ply:ChatPrint("Métal: " .. recycler:GetMetalCount() .. "/20")
        ply:ChatPrint("Papier: " .. recycler:GetPapierCount() .. "/20")
        ply:ChatPrint("Organique: " .. recycler:GetOrganiqueCount() .. "/20")
        ply:ChatPrint("Verre: " .. recycler:GetVerreCount() .. "/20")
    else
        ply:ChatPrint("Tri échoué... Réessaye !")
    end
end)
