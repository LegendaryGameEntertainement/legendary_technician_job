TOOL.Category = "SCP RP - Technician"
TOOL.Name = "Leak Configurator"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["leak_type"] = "water"

if CLIENT then
    language.Add("tool.lg_leak_config.name", "Leak Configurator")
    language.Add("tool.lg_leak_config.desc", "Place des fuites d'eau ou de gaz")
    language.Add("tool.lg_leak_config.left", "Placer une fuite")
    language.Add("tool.lg_leak_config.right", "Supprimer la fuite la plus proche")
end

function TOOL:LeftClick(trace)
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsAdmin() then return false end
    
    if SERVER then
        local leakType = self:GetClientInfo("leak_type")
        
        local config = leakType == "water" and LEGENDARY_TECHNICIAN.LeakConfig.Water or LEGENDARY_TECHNICIAN.LeakConfig.Gas
        
        local leakData = {
            pos = trace.HitPos,
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
    end
    
    return true
end

function TOOL:RightClick(trace)
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsAdmin() then return false end
    
    if SERVER then
        -- Trouver la fuite la plus proche
        local closestID = nil
        local closestDist = 100
        
        for id, leakData in ipairs(LEGENDARY_TECHNICIAN.LeakPositions) do
            local dist = trace.HitPos:Distance(leakData.pos)
            if dist < closestDist then
                closestID = id
                closestDist = dist
            end
        end
        
        if closestID then
            -- Supprimer les timers
            timer.Remove("LG_LeakSpawn_" .. closestID)
            timer.Remove("LG_LeakDamage_" .. closestID)
            
            -- Supprimer de la liste active
            LEGENDARY_TECHNICIAN.ActiveLeaks[closestID] = nil
            
            -- Informer les clients
            net.Start("LG_LeakRemove")
            net.WriteUInt(closestID, 16)
            net.Broadcast()
            
            -- Supprimer de la sauvegarde
            table.remove(LEGENDARY_TECHNICIAN.LeakPositions, closestID)
            LEGENDARY_TECHNICIAN.SaveLeaks()
            
            ply:ChatPrint("[Leak Config] Fuite supprimée (ID: " .. closestID .. ")")
        else
            ply:ChatPrint("[Leak Config] Aucune fuite proche trouvée.")
        end
    end
    
    return true
end

function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", {Description = "Placer des fuites sur la map"})
    
    panel:AddControl("ComboBox", {
        Label = "Type de fuite",
        MenuButton = 0,
        Options = {
            ["Eau"] = {lg_leak_config_leak_type = "water"},
            ["Gaz"] = {lg_leak_config_leak_type = "gas"}
        }
    })
    
    panel:AddControl("Header", {Description = "Configuration Eau"})
    panel:AddControl("Label", {Text = "Intervalle: " .. (LEGENDARY_TECHNICIAN.LeakConfig.Water.SpawnInterval / 60) .. " min"})
    panel:AddControl("Label", {Text = "Dégâts: " .. (LEGENDARY_TECHNICIAN.LeakConfig.Water.DamageEnabled and "Oui" or "Non")})
    
    panel:AddControl("Header", {Description = "Configuration Gaz"})
    panel:AddControl("Label", {Text = "Intervalle: " .. (LEGENDARY_TECHNICIAN.LeakConfig.Gas.SpawnInterval / 60) .. " min"})
    panel:AddControl("Label", {Text = "Dégâts: " .. (LEGENDARY_TECHNICIAN.LeakConfig.Gas.DamageEnabled and "Oui" or "Non")})
end

if CLIENT then
    function TOOL:DrawHUD()
        if not LEGENDARY_TECHNICIAN.LeakPositions then return end
        
        for id, leakData in ipairs(LEGENDARY_TECHNICIAN.LeakPositions) do
            local scrPos = leakData.pos:ToScreen()
            if not scrPos.visible then continue end
            
            local distance = LocalPlayer():GetPos():Distance(leakData.pos)
            if distance > 2000 then continue end
            
            -- Couleur selon le type
            local color = leakData.type == "water" and Color(50, 150, 255) or Color(255, 200, 50)
            local icon = leakData.type == "water" and "💧" or "☠️"
            
            -- Vérifier si active
            local isActive = LEGENDARY_TECHNICIAN.ClientLeaks[id] ~= nil
            local status = isActive and "ACTIVE" or "Inactive"
            local statusColor = isActive and Color(255, 50, 50) or Color(100, 100, 100)
            
            draw.SimpleTextOutlined("ID: " .. id, "Trebuchet18", scrPos.x, scrPos.y - 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
            draw.SimpleTextOutlined(icon .. " " .. leakData.type, "Trebuchet18", scrPos.x, scrPos.y - 15, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
            draw.SimpleTextOutlined(status, "DermaDefault", scrPos.x, scrPos.y, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
            draw.SimpleTextOutlined(math.Round(distance) .. "u", "DermaDefault", scrPos.x, scrPos.y + 15, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
        end
    end
end
