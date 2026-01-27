AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("LG_TrashBinNotification")
util.AddNetworkString("LG_RemoveTrashBinMarker")

function ENT:Initialize()
    self:SetModel("models/props_junk/TrashBin01a.mdl") -- Tu peux changer le modèle
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false) -- Empêche la poubelle de bouger
    end
    
    self:SetIsFull(false)
    
    -- Ajouter cette poubelle à la liste globale
    LEGENDARY_FLOOR_TECHNICIAN.TrashBins = LEGENDARY_FLOOR_TECHNICIAN.TrashBins or {}
    table.insert(LEGENDARY_FLOOR_TECHNICIAN.TrashBins, self)
    
    print("[POUBELLE] Poubelle initialisée : " .. tostring(self))
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    -- Vérifier si le joueur a le bon job
    if not self:IsCorrectJob(activator) then
        local jobName = (activator.getDarkRPVar and activator:getDarkRPVar("job")) or "N/A"
        activator:ChatPrint("[Technicien] Vous devez être Technicien de surface pour vider les poubelles !")
        print("[POUBELLE] " .. activator:Nick() .. " REFUSÉ - Job actuel: " .. tostring(jobName) .. " (Team: " .. tostring(activator:Team()) .. ")")
        return
    end
    
    -- Vérifier si la poubelle est pleine
    if not self:GetIsFull() then
        activator:ChatPrint("[Technicien] Cette poubelle est déjà vide !")
        return
    end
    
    -- Créer un sac poubelle
    self:SpawnTrashBag(activator)
    
    -- Remettre la poubelle à vide
    self:SetIsFull(false)
    
    -- Retirer le marqueur pour tous les joueurs
    net.Start("LG_RemoveTrashBinMarker")
    net.WriteEntity(self)
    net.Broadcast()
    
    -- Effet visuel et sonore
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("GlassImpact", effectdata)
    self:EmitSound("items/ammocrate_open.wav")
    
    activator:ChatPrint("[Technicien] Sac poubelle récupéré !")
    print("[POUBELLE] " .. activator:Nick() .. " a vidé la poubelle " .. tostring(self))
end


function ENT:IsCorrectJob(ply)
    -- Vérifier si DarkRP est installé
    if not DarkRP then 
        print("[POUBELLE] ATTENTION : DarkRP non détecté !")
        return false -- CHANGÉ : bloquer par défaut au lieu d'autoriser
    end
    
    local techTeam = LEGENDARY_FLOOR_TECHNICIAN.FloorTechnicianTeam
    
    -- Vérifier que la config existe
    if not techTeam then
        print("[POUBELLE] ERREUR : FloorTechnicianTeam n'est pas configuré (valeur = nil) !")
        return false
    end
    
    -- Vérifier si c'est un index de team (nombre)
    if type(techTeam) == "number" then
        local playerTeam = ply:Team()
        local isCorrect = playerTeam == techTeam
        print("[POUBELLE] Vérif TEAM INDEX - Joueur: " .. playerTeam .. " | Requis: " .. techTeam .. " | Résultat: " .. tostring(isCorrect))
        return isCorrect
        
    -- Vérifier si c'est un nom de job (string)
    elseif type(techTeam) == "string" then
        if not ply.getDarkRPVar then
            print("[POUBELLE] ERREUR : getDarkRPVar n'existe pas sur le joueur !")
            return false
        end
        
        local jobName = ply:getDarkRPVar("job")
        local isCorrect = jobName == techTeam
        print("[POUBELLE] Vérif NOM JOB - Joueur: '" .. tostring(jobName) .. "' | Requis: '" .. techTeam .. "' | Résultat: " .. tostring(isCorrect))
        return isCorrect
    end
    
    -- Si le type n'est ni number ni string
    print("[POUBELLE] ERREUR : FloorTechnicianTeam est de type " .. type(techTeam) .. " (valeur: " .. tostring(techTeam) .. ")")
    return false
end

function ENT:SpawnTrashBag(ply)
    local bag = ents.Create("lg_trashbag")
    if not IsValid(bag) then 
        print("[POUBELLE] Erreur : impossible de créer lg_trashbag")
        return 
    end
    
    -- Spawn le sac AU-DESSUS de la poubelle
    local spawnPos = self:GetPos() + Vector(0, 0, 50) -- 50 unités au-dessus de la poubelle
    bag:SetPos(spawnPos)
    bag:SetAngles(self:GetAngles())
    bag:Spawn()
    bag:Activate()
    
    print("[POUBELLE] Sac poubelle créé pour " .. ply:Nick())
end

function ENT:MakeFull()
    if self:GetIsFull() then return false end
    
    self:SetIsFull(true)
    
    -- Notifier tous les joueurs ayant le bon job
    self:NotifyTechnicians()
    
    print("[POUBELLE] Poubelle remplie : " .. tostring(self))
    return true
end

function ENT:NotifyTechnicians()
    local technicians = self:GetTechnicians()
    
    if #technicians == 0 then
        print("[POUBELLE] Aucun technicien en ligne pour notifier")
        return
    end
    
    for _, ply in pairs(technicians) do
        if IsValid(ply) then
            net.Start("LG_TrashBinNotification")
            net.WriteEntity(self)
            net.Send(ply)
            
            print("[POUBELLE] Notification envoyée à " .. ply:Nick())
        end
    end
end

function ENT:GetTechnicians()
    local technicians = {}
    
    for _, ply in pairs(player.GetAll()) do
        if self:IsCorrectJob(ply) then
            table.insert(technicians, ply)
        end
    end
    
    return technicians
end

function ENT:OnRemove()
    -- Retirer cette poubelle de la liste globale
    if LEGENDARY_FLOOR_TECHNICIAN.TrashBins then
        for i, bin in pairs(LEGENDARY_FLOOR_TECHNICIAN.TrashBins) do
            if bin == self then
                table.remove(LEGENDARY_FLOOR_TECHNICIAN.TrashBins, i)
                print("[POUBELLE] Poubelle retirée de la liste globale")
                break
            end
        end
    end
    
    -- Retirer les marqueurs clients
    net.Start("LG_RemoveTrashBinMarker")
    net.WriteEntity(self)
    net.Broadcast()
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    
    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 50)
    ent:Spawn()
    ent:Activate()
    
    return ent
end
