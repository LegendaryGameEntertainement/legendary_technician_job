util.AddNetworkString("LG_LeakAdd")
util.AddNetworkString("LG_LeakRemove")
util.AddNetworkString("LG_LeakSync")
util.AddNetworkString("LG_LeakRepair")

LEGENDARY_TECHNICIAN.ActiveLeaks = LEGENDARY_TECHNICIAN.ActiveLeaks or {}
LEGENDARY_TECHNICIAN.LeakPositions = LEGENDARY_TECHNICIAN.LeakPositions or {}

-- Charger les positions depuis data
function LEGENDARY_TECHNICIAN.LoadLeaks()
    local mapName = game.GetMap()
    local data = util.JSONToTable(file.Read("legendary_leaks_" .. mapName .. ".txt", "DATA") or "[]") or {}
    
    LEGENDARY_TECHNICIAN.LeakPositions = data
    
    -- Démarrer les timers pour chaque position
    for id, leakData in ipairs(data) do
        timer.Create("LG_LeakSpawn_" .. id, leakData.config.SpawnInterval, 0, function()
            LEGENDARY_TECHNICIAN.ActivateLeak(id)
        end)
    end
    
    print("[LEGENDARY LEAK] " .. #data .. " positions chargées pour " .. mapName)
end

-- Activer une fuite
function LEGENDARY_TECHNICIAN.ActivateLeak(id)
    local leakData = LEGENDARY_TECHNICIAN.LeakPositions[id]
    if not leakData then return end
    
    if LEGENDARY_TECHNICIAN.ActiveLeaks[id] then return end -- Déjà active
    
    LEGENDARY_TECHNICIAN.ActiveLeaks[id] = {
        pos = leakData.pos,
        type = leakData.type,
        startTime = CurTime()
    }
    
    -- Envoyer à tous les clients
    net.Start("LG_LeakAdd")
    net.WriteUInt(id, 16)
    net.WriteVector(leakData.pos)
    net.WriteString(leakData.type)
    net.Broadcast()
    
    -- Son global ou local
    local config = leakData.type == "water" and LEGENDARY_TECHNICIAN.LeakConfig.Water or LEGENDARY_TECHNICIAN.LeakConfig.Gas
    
    if config.GlobalSound then
        for _, ply in ipairs(player.GetAll()) do
            sound.Play(config.Sound, leakData.pos, 100, 100, 1)
        end
    end
    
    -- Dégâts si activés
    if config.DamageEnabled then
        timer.Create("LG_LeakDamage_" .. id, config.DamageInterval, 0, function()
            if not LEGENDARY_TECHNICIAN.ActiveLeaks[id] then 
                timer.Remove("LG_LeakDamage_" .. id)
                return 
            end
            
            for _, ply in ipairs(player.GetAll()) do
                if ply:GetPos():Distance(leakData.pos) <= config.DamageRadius then
                    -- Vérifier le masque à gaz pour les fuites de gaz
                    if leakData.type == "gas" then
                        -- TODO: Vérifier si le joueur a un masque à gaz équipé
                        -- if ply:HasGasMask() then
                        --     continue -- Pas de dégâts si masque à gaz
                        -- end
                        
                        -- Alternative avec inventaire:
                        -- if ply.Inventory and ply.Inventory:HasItem("gas_mask") and ply.Inventory:IsEquipped("gas_mask") then
                        --     continue
                        -- end
                    end
                    
                    ply:TakeDamage(config.DamageAmount, game.GetWorld(), game.GetWorld())
                end
            end
        end)
    end
    
    print("[LEGENDARY LEAK] Fuite " .. leakData.type .. " activée (ID: " .. id .. ")")
end


-- Réparer une fuite
function LEGENDARY_TECHNICIAN.RepairLeak(id, ply)
    local leakData = LEGENDARY_TECHNICIAN.LeakPositions[id]
    if not leakData then return end
    
    if not LEGENDARY_TECHNICIAN.ActiveLeaks[id] then
        ply:ChatPrint("[Technicien] Cette fuite est déjà réparée.")
        return
    end
    
    local config = leakData.type == "water" and LEGENDARY_TECHNICIAN.LeakConfig.Water or LEGENDARY_TECHNICIAN.LeakConfig.Gas
    
    -- Désactiver la fuite
    LEGENDARY_TECHNICIAN.ActiveLeaks[id] = nil
    timer.Remove("LG_LeakDamage_" .. id)
    
    -- Informer les clients (pour arrêter les particules)
    net.Start("LG_LeakRemove")
    net.WriteUInt(id, 16)
    net.Broadcast()
    
    -- Redémarrer le timer pour la prochaine fuite
    timer.Create("LG_LeakSpawn_" .. id, config.SpawnInterval, 1, function()
        LEGENDARY_TECHNICIAN.ActivateLeak(id)
    end)
    
    -- Messages
    ply:ChatPrint("[Technicien] ✓ Fuite réparée avec succès !")
    ply:ChatPrint("[Technicien] Prochaine fuite dans " .. math.Round(config.SpawnInterval / 60) .. " minutes.")
    
    sound.Play("buttons/button14.wav", leakData.pos, 75, 100, 1)
end


-- Sauvegarder dans data
function LEGENDARY_TECHNICIAN.SaveLeaks()
    local mapName = game.GetMap()
    file.Write("legendary_leaks_" .. mapName .. ".txt", util.TableToJSON(LEGENDARY_TECHNICIAN.LeakPositions, true))
end

-- Réseau : Ajouter une fuite
net.Receive("LG_LeakAdd", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local pos = net.ReadVector()
    local leakType = net.ReadString()
    
    local config = leakType == "water" and LEGENDARY_TECHNICIAN.LeakConfig.Water or LEGENDARY_TECHNICIAN.LeakConfig.Gas
    
    local leakData = {
        pos = pos,
        type = leakType,
        config = config
    }
    
    table.insert(LEGENDARY_TECHNICIAN.LeakPositions, leakData)
    local id = #LEGENDARY_TECHNICIAN.LeakPositions
    
    LEGENDARY_TECHNICIAN.SaveLeaks()
    
    -- Créer le timer
    timer.Create("LG_LeakSpawn_" .. id, config.SpawnInterval, 0, function()
        LEGENDARY_TECHNICIAN.ActivateLeak(id)
    end)
    
    ply:ChatPrint("[Leak Config] Fuite de " .. leakType .. " ajoutée (ID: " .. id .. ")")
end)

-- Réseau : Supprimer une fuite
net.Receive("LG_LeakRemove", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local id = net.ReadUInt(16)
    
    if not LEGENDARY_TECHNICIAN.LeakPositions[id] then return end
    
    -- Supprimer les timers
    timer.Remove("LG_LeakSpawn_" .. id)
    timer.Remove("LG_LeakDamage_" .. id)
    
    -- Supprimer de la liste active
    LEGENDARY_TECHNICIAN.ActiveLeaks[id] = nil
    
    -- Informer les clients
    net.Start("LG_LeakRemove")
    net.WriteUInt(id, 16)
    net.Broadcast()
    
    -- Supprimer de la sauvegarde
    table.remove(LEGENDARY_TECHNICIAN.LeakPositions, id)
    LEGENDARY_TECHNICIAN.SaveLeaks()
    
    ply:ChatPrint("[Leak Config] Fuite supprimée (ID: " .. id .. ")")
end)

-- Réseau : Réparer
net.Receive("LG_LeakRepair", function(len, ply)
    local id = net.ReadUInt(16)
    LEGENDARY_TECHNICIAN.RepairLeak(id, ply)
end)

-- Charger au démarrage
hook.Add("InitPostEntity", "LG_LoadLeaksOnStart", function()
    timer.Simple(2, function()
        LEGENDARY_TECHNICIAN.LoadLeaks()
    end)
end)

-- Synchroniser pour les joueurs qui rejoignent
hook.Add("PlayerInitialSpawn", "LG_SyncLeaksToPlayer", function(ply)
    timer.Simple(5, function()
        if not IsValid(ply) then return end
        
        for id, leak in pairs(LEGENDARY_TECHNICIAN.ActiveLeaks) do
            net.Start("LG_LeakAdd")
            net.WriteUInt(id, 16)
            net.WriteVector(leak.pos)
            net.WriteString(leak.type)
            net.Send(ply)
        end
    end)
end)

-- Ajoute ce network string au début avec les autres
util.AddNetworkString("LG_LeakSyncPositions")

-- Ajoute cette fonction après LoadLeaks()
function LEGENDARY_TECHNICIAN.SyncPositionsToClient(ply)
    net.Start("LG_LeakSyncPositions")
    net.WriteTable(LEGENDARY_TECHNICIAN.LeakPositions)
    net.Send(ply)
end

-- Modifie le hook PlayerInitialSpawn pour inclure les positions
hook.Add("PlayerInitialSpawn", "LG_SyncLeaksToPlayer", function(ply)
    timer.Simple(5, function()
        if not IsValid(ply) then return end
        
        -- Envoyer les positions sauvegardées
        LEGENDARY_TECHNICIAN.SyncPositionsToClient(ply)
        
        -- Envoyer les fuites actives
        for id, leak in pairs(LEGENDARY_TECHNICIAN.ActiveLeaks) do
            net.Start("LG_LeakAdd")
            net.WriteUInt(id, 16)
            net.WriteVector(leak.pos)
            net.WriteString(leak.type)
            net.Send(ply)
        end
    end)
end)

-- Appelle aussi la sync après chaque ajout/suppression dans le TOOL
-- Ajoute ça à la fin de la fonction SaveLeaks()
function LEGENDARY_TECHNICIAN.SaveLeaks()
    local mapName = game.GetMap()
    file.Write("legendary_leaks_" .. mapName .. ".txt", util.TableToJSON(LEGENDARY_TECHNICIAN.LeakPositions, true))
    
    -- Sync à tous les joueurs
    net.Start("LG_LeakSyncPositions")
    net.WriteTable(LEGENDARY_TECHNICIAN.LeakPositions)
    net.Broadcast()
end
