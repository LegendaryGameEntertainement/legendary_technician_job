AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("LG_ElectricalPanelNotification")
util.AddNetworkString("LG_RemoveElectricalPanelMarker")
util.AddNetworkString("LG_OpenWiringMinigame")
util.AddNetworkString("LG_WiringMinigameResult")

function ENT:Initialize()
    self:SetModel("models/props_c17/furnitureStove001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end
    
    self:SetIsBroken(false)
    self.AssignedTechnician = nil
    self.IsAbandoned = false
    
    -- Enregistrer cette entité dans le système de pannes
    LEGENDARY_TECHNICIAN.BreakdownEntities = LEGENDARY_TECHNICIAN.BreakdownEntities or {}
    table.insert(LEGENDARY_TECHNICIAN.BreakdownEntities, self)
    
    print("[ARMOIRE ÉLECTRIQUE] Armoire initialisée : " .. tostring(self))
end

function ENT:MakeBreakdown()
    if self:GetIsBroken() then return false end
    
    self:SetIsBroken(true)
    self:SetBreakdownTime(CurTime())
    self.IsAbandoned = false
    self:AssignToTechnician()
    
    -- Effet visuel
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetMagnitude(2)
    util.Effect("ElectricSpark", effectdata)
    self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav")
    
    print("[ARMOIRE ÉLECTRIQUE] Panne déclenchée : " .. tostring(self))
    return true
end

function ENT:AssignToTechnician()
    local technicians = self:GetTechnicians()
    if #technicians == 0 then
        print("[ARMOIRE ÉLECTRIQUE] Aucun technicien disponible pour l'assignation")
        return
    end
    
    if self.IsAbandoned then
        print("[ARMOIRE ÉLECTRIQUE] Cette armoire est abandonnée, pas de réassignation automatique")
        return
    end
    
    local chosenTech = technicians[math.random(#technicians)]
    self.AssignedTechnician = chosenTech
    
    if IsValid(chosenTech) then
        net.Start("LG_ElectricalPanelNotification")
        net.WriteEntity(self)
        net.Send(chosenTech)
        print("[ARMOIRE ÉLECTRIQUE] Assignée à " .. chosenTech:Nick())
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
        activator:ChatPrint("[Technicien] Vous devez être Électricien pour réparer l'armoire électrique !")
        return
    end
    
    if not self:GetIsBroken() then
        activator:ChatPrint("[Technicien] Cette armoire fonctionne correctement !")
        return
    end
    
    if self.IsAbandoned then
        activator:ChatPrint("[Technicien] Cette armoire a été abandonnée et doit retomber en panne !")
        return
    end
    
    if not self.AssignedTechnician or not IsValid(self.AssignedTechnician) then
        activator:ChatPrint("[Technicien] Cette armoire n'est assignée à personne pour le moment !")
        return
    end
    
    if self.AssignedTechnician ~= activator then
        activator:ChatPrint("[Technicien] Cette armoire est assignée à " .. self.AssignedTechnician:Nick() .. " !")
        return
    end
    
    -- Ouvrir le mini-jeu
    net.Start("LG_OpenWiringMinigame")
    net.WriteEntity(self)
    net.Send(activator)
    
    print("[ARMOIRE ÉLECTRIQUE] Mini-jeu ouvert pour " .. activator:Nick())
end

function ENT:IsCorrectJob(ply)
    if not DarkRP then
        print("[ARMOIRE ÉLECTRIQUE] ATTENTION : DarkRP non détecté !")
        return false
    end
    
    local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
    
    if not techTeam then
        print("[ARMOIRE ÉLECTRIQUE] ERREUR : ElectricianTeam n'est pas configuré !")
        return false
    end
    
    if type(techTeam) == "number" then
        return ply:Team() == techTeam
    elseif type(techTeam) == "string" then
        if not ply.getDarkRPVar then return false end
        return ply:getDarkRPVar("job") == techTeam
    end
    
    return false
end

function ENT:OnRemove()
    if LEGENDARY_TECHNICIAN.BreakdownEntities then
        for i, panel in pairs(LEGENDARY_TECHNICIAN.BreakdownEntities) do
            if panel == self then
                table.remove(LEGENDARY_TECHNICIAN.BreakdownEntities, i)
                break
            end
        end
    end
    
    net.Start("LG_RemoveElectricalPanelMarker")
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

-- Réception du résultat du mini-jeu
net.Receive("LG_WiringMinigameResult", function(len, ply)
    local panel = net.ReadEntity()
    local success = net.ReadBool()
    
    if not IsValid(panel) or panel:GetClass() ~= "lg_electrical_panel" then return end
    if panel.AssignedTechnician ~= ply then return end
    
    if success then
        panel:SetIsBroken(false)
        
        if IsValid(panel.AssignedTechnician) then
            net.Start("LG_RemoveElectricalPanelMarker")
            net.WriteEntity(panel)
            net.Send(panel.AssignedTechnician)
        end
        
        panel.AssignedTechnician = nil
        panel.IsAbandoned = false
        
        local effectdata = EffectData()
        effectdata:SetOrigin(panel:GetPos())
        util.Effect("GlassImpact", effectdata)
        panel:EmitSound("buttons/button14.wav")
        
        ply:ChatPrint("[Technicien] Armoire électrique réparée avec succès !")
        print("[ARMOIRE ÉLECTRIQUE] " .. ply:Nick() .. " a réparé l'armoire " .. tostring(panel))
    else
        ply:ChatPrint("[Technicien] Réparation échouée ! Réessayez.")
        panel:EmitSound("buttons/button10.wav")
    end
end)

-- Hooks pour gérer les changements de job
if DarkRP then
    hook.Add("OnPlayerChangedTeam", "LG_ReassignElectricalPanels", function(ply, oldTeam, newTeam)
        if not IsValid(ply) then return end
        
        local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
        if not techTeam or type(techTeam) ~= "number" then return end
        
        if oldTeam == techTeam and newTeam ~= techTeam then
            print("[ARMOIRE ÉLECTRIQUE] " .. ply:Nick() .. " quitte le job, abandon des armoires...")
            
            if LEGENDARY_TECHNICIAN.BreakdownEntities then
                for _, panel in pairs(LEGENDARY_TECHNICIAN.BreakdownEntities) do
                    if IsValid(panel) and panel.AssignedTechnician == ply then
                        net.Start("LG_RemoveElectricalPanelMarker")
                        net.WriteEntity(panel)
                        net.Send(ply)
                        
                        panel.AssignedTechnician = nil
                        panel.IsAbandoned = true
                    end
                end
            end
        end
    end)
    
    hook.Add("PlayerDisconnected", "LG_ReassignElectricalOnDisconnect", function(ply)
        if LEGENDARY_TECHNICIAN.BreakdownEntities then
            for _, panel in pairs(LEGENDARY_TECHNICIAN.BreakdownEntities) do
                if IsValid(panel) and panel.AssignedTechnician == ply then
                    print("[ARMOIRE ÉLECTRIQUE] " .. ply:Nick() .. " s'est déconnecté, réassignation...")
                    panel.AssignedTechnician = nil
                    panel.IsAbandoned = false
                    
                    if panel:GetIsBroken() then
                        timer.Simple(0.5, function()
                            if IsValid(panel) then
                                panel:AssignToTechnician()
                            end
                        end)
                    end
                end
            end
        end
    end)
end
