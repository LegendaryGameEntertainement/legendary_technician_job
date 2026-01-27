AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("LG_TrashBinNotification")
util.AddNetworkString("LG_RemoveTrashBinMarker")

function ENT:Initialize()
    self:SetModel("models/props_junk/TrashBin01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end
    
    self:SetIsFull(false)
    self.AssignedTechnician = nil
    self.IsAbandoned = false  -- NOUVEAU : Marquer si la poubelle est abandonnée
    
    LEGENDARY_FLOOR_TECHNICIAN.TrashBins = LEGENDARY_FLOOR_TECHNICIAN.TrashBins or {}
    table.insert(LEGENDARY_FLOOR_TECHNICIAN.TrashBins, self)
    
    print("[POUBELLE] Poubelle initialisée : " .. tostring(self))
end

function ENT:MakeFull()
    if self:GetIsFull() then return false end
    
    self:SetIsFull(true)
    self.IsAbandoned = false  -- Réinitialiser le statut abandonné
    self:AssignToTechnician()
    
    print("[POUBELLE] Poubelle remplie : " .. tostring(self))
    return true
end

function ENT:AssignToTechnician()
    local technicians = self:GetTechnicians()
    
    if #technicians == 0 then
        print("[POUBELLE] Aucun technicien disponible pour l'assignation")
        return
    end
    
    -- Ne pas réassigner si abandonnée
    if self.IsAbandoned then
        print("[POUBELLE] Cette poubelle est abandonnée, pas de réassignation automatique")
        return
    end
    
    local chosenTech = technicians[math.random(#technicians)]
    self.AssignedTechnician = chosenTech
    
    if IsValid(chosenTech) then
        net.Start("LG_TrashBinNotification")
        net.WriteEntity(self)
        net.Send(chosenTech)
        print("[POUBELLE] Assignée à " .. chosenTech:Nick())
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

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    if not self:IsCorrectJob(activator) then
        local jobName = (activator.getDarkRPVar and activator:getDarkRPVar("job")) or "N/A"
        activator:ChatPrint("[Technicien] Vous devez être Technicien de surface pour vider les poubelles !")
        return
    end
    
    if not self:GetIsFull() then
        activator:ChatPrint("[Technicien] Cette poubelle est déjà vide !")
        return
    end
    
    -- Bloquer si abandonnée
    if self.IsAbandoned then
        activator:ChatPrint("[Technicien] Cette poubelle a été abandonnée et doit être remplie à nouveau !")
        return
    end
    
    -- Bloquer si pas assigné
    if not self.AssignedTechnician or not IsValid(self.AssignedTechnician) then
        activator:ChatPrint("[Technicien] Cette poubelle n'est assignée à personne pour le moment !")
        return
    end
    
    -- Vérifier si c'est le bon technicien assigné
    if self.AssignedTechnician ~= activator then
        activator:ChatPrint("[Technicien] Cette poubelle est assignée à " .. self.AssignedTechnician:Nick() .. " !")
        return
    end
    
    self:SpawnTrashBag(activator)
    self:SetIsFull(false)
    
    if IsValid(self.AssignedTechnician) then
        net.Start("LG_RemoveTrashBinMarker")
        net.WriteEntity(self)
        net.Send(self.AssignedTechnician)
    end
    
    self.AssignedTechnician = nil
    self.IsAbandoned = false
    
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("GlassImpact", effectdata)
    self:EmitSound("items/ammocrate_open.wav")
    
    activator:ChatPrint("[Technicien] Sac poubelle récupéré !")
    print("[POUBELLE] " .. activator:Nick() .. " a vidé la poubelle " .. tostring(self))
end

function ENT:IsCorrectJob(ply)
    if not DarkRP then 
        print("[POUBELLE] ATTENTION : DarkRP non détecté !")
        return false
    end
    
    local techTeam = LEGENDARY_FLOOR_TECHNICIAN.FloorTechnicianTeam
    
    if not techTeam then
        print("[POUBELLE] ERREUR : FloorTechnicianTeam n'est pas configuré (valeur = nil) !")
        return false
    end
    
    if type(techTeam) == "number" then
        local playerTeam = ply:Team()
        local isCorrect = playerTeam == techTeam
        print("[POUBELLE] Vérif TEAM INDEX - Joueur: " .. playerTeam .. " | Requis: " .. techTeam .. " | Résultat: " .. tostring(isCorrect))
        return isCorrect
        
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
    
    print("[POUBELLE] ERREUR : FloorTechnicianTeam est de type " .. type(techTeam) .. " (valeur: " .. tostring(techTeam) .. ")")
    return false
end

function ENT:SpawnTrashBag(ply)
    local bag = ents.Create("lg_trashbag")
    if not IsValid(bag) then 
        print("[POUBELLE] Erreur : impossible de créer lg_trashbag")
        return 
    end
    
    local spawnPos = self:GetPos() + Vector(0, 0, 50)
    bag:SetPos(spawnPos)
    bag:SetAngles(self:GetAngles())
    bag:Spawn()
    bag:Activate()
    
    print("[POUBELLE] Sac poubelle créé pour " .. ply:Nick())
end

function ENT:OnRemove()
    if LEGENDARY_FLOOR_TECHNICIAN.TrashBins then
        for i, bin in pairs(LEGENDARY_FLOOR_TECHNICIAN.TrashBins) do
            if bin == self then
                table.remove(LEGENDARY_FLOOR_TECHNICIAN.TrashBins, i)
                print("[POUBELLE] Poubelle retirée de la liste globale")
                break
            end
        end
    end
    
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

-- Hooks pour gérer les changements de job et déconnexions
if DarkRP then
    hook.Add("OnPlayerChangedTeam", "LG_ReassignTrashBins", function(ply, oldTeam, newTeam)
        if not IsValid(ply) then return end
        
        local techTeam = LEGENDARY_FLOOR_TECHNICIAN.FloorTechnicianTeam
        if not techTeam or type(techTeam) ~= "number" then return end
        
        if oldTeam == techTeam and newTeam ~= techTeam then
            print("[POUBELLE] " .. ply:Nick() .. " quitte le job, abandon des poubelles...")
            
            if LEGENDARY_FLOOR_TECHNICIAN.TrashBins then
                for _, bin in pairs(LEGENDARY_FLOOR_TECHNICIAN.TrashBins) do
                    if IsValid(bin) and bin.AssignedTechnician == ply then
                        net.Start("LG_RemoveTrashBinMarker")
                        net.WriteEntity(bin)
                        net.Send(ply)
                        
                        bin.AssignedTechnician = nil
                        bin.IsAbandoned = true  -- Marquer comme abandonnée
                        print("[POUBELLE] Poubelle " .. bin:EntIndex() .. " marquée comme abandonnée")
                    end
                end
            end
        end
    end)
    
    hook.Add("PlayerDisconnected", "LG_ReassignOnDisconnect", function(ply)
        if LEGENDARY_FLOOR_TECHNICIAN.TrashBins then
            for _, bin in pairs(LEGENDARY_FLOOR_TECHNICIAN.TrashBins) do
                if IsValid(bin) and bin.AssignedTechnician == ply then
                    print("[POUBELLE] " .. ply:Nick() .. " s'est déconnecté, réassignation...")
                    bin.AssignedTechnician = nil
                    bin.IsAbandoned = false  -- Pas abandonné si déco, on réassigne
                    if bin:GetIsFull() then
                        timer.Simple(0.5, function()
                            if IsValid(bin) then
                                bin:AssignToTechnician()
                            end
                        end)
                    end
                end
            end
        end
    end)
end
