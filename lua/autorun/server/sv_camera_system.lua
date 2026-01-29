-- Système de gestion des caméras
LEGENDARY_TECHNICIAN = LEGENDARY_TECHNICIAN or {}
LEGENDARY_TECHNICIAN.BrokenCameras = LEGENDARY_TECHNICIAN.BrokenCameras or {}

util.AddNetworkString("LG_CameraNotification")
util.AddNetworkString("LG_RemoveCameraMarker")
util.AddNetworkString("LG_OpenCameraMinigame")
util.AddNetworkString("LG_CameraMinigameResult")
util.AddNetworkString("LG_CameraHealth")
util.AddNetworkString("LG_CameraBroken")

-- Initialiser les caméras au démarrage
hook.Add("InitPostEntity", "LG_InitCameras", function()
    timer.Simple(2, function()
        local config = LEGENDARY_TECHNICIAN.Camera
        if not config then return end
        
        local cameras = ents.FindByClass(config.EntityClass)
        print("[CAMÉRA] " .. #cameras .. " caméras détectées")
        
        for _, cam in pairs(cameras) do
            if IsValid(cam) then
                -- Initialiser les données de la caméra
                if not cam.LG_CameraData then
                    cam.LG_CameraData = {}
                end
                cam.LG_CameraData.Health = config.MaxHealth
                cam.LG_CameraData.MaxHealth = config.MaxHealth
                cam.LG_CameraData.IsBroken = false
                cam.LG_CameraData.AssignedTechnician = nil
                cam.LG_CameraData.IsAbandoned = false
                
                print("[CAMÉRA] Caméra " .. cam:EntIndex() .. " initialisée avec " .. config.MaxHealth .. " PV")
            end
        end
    end)
end)

-- Hook pour détecter les dégâts sur les caméras
hook.Add("EntityTakeDamage", "LG_CameraDamage", function(target, dmg)
    local config = LEGENDARY_TECHNICIAN.Camera
    if not config then return end
    
    if not IsValid(target) then return end
    if target:GetClass() ~= config.EntityClass then return end
    
    -- Initialiser si nécessaire
    if not target.LG_CameraData then
        target.LG_CameraData = {
            Health = config.MaxHealth,
            MaxHealth = config.MaxHealth,
            IsBroken = false
        }
    end
    
    -- Si déjà cassée, ignorer les dégâts
    if target.LG_CameraData.IsBroken then return end
    
    -- Appliquer les dégâts
    local damage = dmg:GetDamage()
    target.LG_CameraData.Health = math.max(0, target.LG_CameraData.Health - damage)
    
    print("[CAMÉRA] Caméra " .. target:EntIndex() .. " a reçu " .. damage .. " dégâts. PV restants: " .. target.LG_CameraData.Health)
    
    -- Envoyer la santé aux clients
    net.Start("LG_CameraHealth")
    net.WriteEntity(target)
    net.WriteInt(target.LG_CameraData.Health, 16)
    net.WriteInt(target.LG_CameraData.MaxHealth, 16)
    net.Broadcast()
    
    -- Vérifier si la caméra doit se casser
    if config.BreakOnZeroHealth and target.LG_CameraData.Health <= 0 then
        LEGENDARY_TECHNICIAN.BreakCamera(target)
    end
end)

-- Fonction pour casser une caméra
function LEGENDARY_TECHNICIAN.BreakCamera(camera)
    if not IsValid(camera) then return false end
    
    local config = LEGENDARY_TECHNICIAN.Camera
    if not config then return false end
    
    -- Initialiser si nécessaire
    if not camera.LG_CameraData then
        camera.LG_CameraData = {}
    end
    
    -- Si déjà cassée, ignorer
    if camera.LG_CameraData.IsBroken then return false end
    
    local idx = camera:EntIndex()
    LEGENDARY_TECHNICIAN.BrokenCameras[idx] = true
    
    camera.LG_CameraData.IsBroken = true
    camera.LG_CameraData.BreakdownTime = CurTime()
    camera.LG_CameraData.AssignedTechnician = nil
    camera.LG_CameraData.IsAbandoned = false
    
    -- Assigner à un technicien
    LEGENDARY_TECHNICIAN.AssignCameraToTechnician(camera)
    
    -- Notifier tous les clients
    net.Start("LG_CameraBroken")
    net.WriteEntity(camera)
    net.WriteBool(true)
    net.Broadcast()
    
    -- Effets visuels et sonores
    local effectdata = EffectData()
    effectdata:SetOrigin(camera:GetPos())
    effectdata:SetMagnitude(2)
    util.Effect("ElectricSpark", effectdata)
    camera:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav")
    
    print("[CAMÉRA] Caméra " .. idx .. " cassée")
    return true
end

-- Fonction pour réparer une caméra
function LEGENDARY_TECHNICIAN.RepairCamera(camera)
    if not IsValid(camera) then return false end
    
    local config = LEGENDARY_TECHNICIAN.Camera
    if not config then return false end
    
    local idx = camera:EntIndex()
    LEGENDARY_TECHNICIAN.BrokenCameras[idx] = nil
    
    if camera.LG_CameraData then
        camera.LG_CameraData.IsBroken = false
        camera.LG_CameraData.Health = config.MaxHealth
        camera.LG_CameraData.AssignedTechnician = nil
        camera.LG_CameraData.IsAbandoned = false
    end
    
    -- Notifier tous les clients
    net.Start("LG_CameraBroken")
    net.WriteEntity(camera)
    net.WriteBool(false)
    net.Broadcast()
    
    net.Start("LG_CameraHealth")
    net.WriteEntity(camera)
    net.WriteInt(config.MaxHealth, 16)
    net.WriteInt(config.MaxHealth, 16)
    net.Broadcast()
    
    camera:EmitSound("buttons/button14.wav")
    
    print("[CAMÉRA] Caméra " .. idx .. " réparée")
    return true
end

-- Assigner une caméra à un technicien
function LEGENDARY_TECHNICIAN.AssignCameraToTechnician(camera)
    if not IsValid(camera) then return end
    
    local technicians = {}
    local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
    
    for _, ply in pairs(player.GetAll()) do
        if techTeam then
            if type(techTeam) == "number" and ply:Team() == techTeam then
                table.insert(technicians, ply)
            elseif type(techTeam) == "string" and ply.getDarkRPVar and ply:getDarkRPVar("job") == techTeam then
                table.insert(technicians, ply)
            end
        end
    end
    
    if #technicians == 0 then
        print("[CAMÉRA] Aucun technicien disponible")
        return
    end
    
    if camera.LG_CameraData and camera.LG_CameraData.IsAbandoned then
        print("[CAMÉRA] Caméra abandonnée, pas de réassignation")
        return
    end
    
    local chosenTech = technicians[math.random(#technicians)]
    
    if not camera.LG_CameraData then
        camera.LG_CameraData = {}
    end
    camera.LG_CameraData.AssignedTechnician = chosenTech
    
    if IsValid(chosenTech) then
        net.Start("LG_CameraNotification")
        net.WriteEntity(camera)
        net.Send(chosenTech)
        print("[CAMÉRA] Assignée à " .. chosenTech:Nick())
    end
end

-- Hook pour bloquer l'utilisation des caméras cassées
hook.Add("PlayerUse", "LG_CameraRepairUse", function(ply, ent)
    if not IsValid(ent) or not IsValid(ply) then return end
    
    local config = LEGENDARY_TECHNICIAN.Camera
    if not config then return end
    
    if ent:GetClass() == config.EntityClass then
        if ent.LG_CameraData and ent.LG_CameraData.IsBroken then
            -- Vérifier si c'est un technicien
            local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
            local isTech = false
            
            if techTeam then
                if type(techTeam) == "number" then
                    isTech = ply:Team() == techTeam
                elseif type(techTeam) == "string" and ply.getDarkRPVar then
                    isTech = ply:getDarkRPVar("job") == techTeam
                end
            end
            
            if not isTech then
                ply:ChatPrint("[Caméra] Cette caméra est cassée ! Contactez un technicien.")
                return true
            end
            
            if not ent.LG_CameraData.AssignedTechnician then
                ply:ChatPrint("[Caméra] Cette caméra n'est assignée à personne.")
                return true
            end
            
            if ent.LG_CameraData.IsAbandoned then
                ply:ChatPrint("[Caméra] Cette caméra a été abandonnée.")
                return true
            end
            
            if ent.LG_CameraData.AssignedTechnician ~= ply then
                ply:ChatPrint("[Caméra] Cette caméra est assignée à " .. ent.LG_CameraData.AssignedTechnician:Nick())
                return true
            end
            
            -- NOUVEAU : Empêcher l'ouverture multiple
            if ent.LG_MinigameOpen then
                ply:ChatPrint("[Caméra] Mini-jeu déjà ouvert !")
                return true
            end
            
            -- Marquer comme ouvert
            ent.LG_MinigameOpen = true
            
            -- Ouvrir le mini-jeu
            net.Start("LG_OpenCameraMinigame")
            net.WriteEntity(ent)
            net.Send(ply)
            
            -- Débloquer après 2 secondes
            timer.Simple(2, function()
                if IsValid(ent) then
                    ent.LG_MinigameOpen = false
                end
            end)
            
            return true
        end
    end
end)


-- Réception du résultat du mini-jeu
net.Receive("LG_CameraMinigameResult", function(len, ply)
    local camera = net.ReadEntity()
    local success = net.ReadBool()
    
    if not IsValid(camera) or not IsValid(ply) then return end
    if not camera.LG_CameraData or camera.LG_CameraData.AssignedTechnician ~= ply then return end
    
    if success then
        LEGENDARY_TECHNICIAN.RepairCamera(camera)
        
        if IsValid(camera.LG_CameraData.AssignedTechnician) then
            net.Start("LG_RemoveCameraMarker")
            net.WriteEntity(camera)
            net.Send(camera.LG_CameraData.AssignedTechnician)
        end
        
        ply:ChatPrint("[Caméra] Caméra réparée avec succès !")
    else
        ply:ChatPrint("[Caméra] Réparation échouée ! Réessayez.")
        camera:EmitSound("buttons/button10.wav")
    end
end)

-- Gestion des changements de job
if DarkRP then
    hook.Add("OnPlayerChangedTeam", "LG_ReassignCameras", function(ply, oldTeam, newTeam)
        if not IsValid(ply) then return end
        local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
        if not techTeam or type(techTeam) ~= "number" then return end
        
        if oldTeam == techTeam and newTeam ~= techTeam then
            for idx, _ in pairs(LEGENDARY_TECHNICIAN.BrokenCameras) do
                local camera = Entity(idx)
                if IsValid(camera) and camera.LG_CameraData and camera.LG_CameraData.AssignedTechnician == ply then
                    net.Start("LG_RemoveCameraMarker")
                    net.WriteEntity(camera)
                    net.Send(ply)
                    
                    camera.LG_CameraData.AssignedTechnician = nil
                    camera.LG_CameraData.IsAbandoned = true
                end
            end
        end
    end)
    
    hook.Add("PlayerDisconnected", "LG_ReassignCamerasOnDisconnect", function(ply)
        for idx, _ in pairs(LEGENDARY_TECHNICIAN.BrokenCameras) do
            local camera = Entity(idx)
            if IsValid(camera) and camera.LG_CameraData and camera.LG_CameraData.AssignedTechnician == ply then
                camera.LG_CameraData.AssignedTechnician = nil
                camera.LG_CameraData.IsAbandoned = false
                
                timer.Simple(0.5, function()
                    if IsValid(camera) and camera.LG_CameraData.IsBroken then
                        LEGENDARY_TECHNICIAN.AssignCameraToTechnician(camera)
                    end
                end)
            end
        end
    end)
end

print("[CAMÉRA] Système de caméras chargé")
