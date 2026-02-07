LEGENDARY_TECHNICIAN.ClientLeaks = LEGENDARY_TECHNICIAN.ClientLeaks or {}

-- Recevoir une nouvelle fuite
net.Receive("LG_LeakAdd", function()
    local id = net.ReadUInt(16)
    local pos = net.ReadVector()
    local leakType = net.ReadString()
    
    LEGENDARY_TECHNICIAN.ClientLeaks[id] = {
        pos = pos,
        type = leakType,
        startTime = CurTime()
    }
    
    print("[LEAK CLIENT] Fuite " .. leakType .. " activée à " .. tostring(pos))
end)

-- Supprimer une fuite
net.Receive("LG_LeakRemove", function()
    local id = net.ReadUInt(16)
    LEGENDARY_TECHNICIAN.ClientLeaks[id] = nil
    print("[LEAK CLIENT] Fuite " .. id .. " désactivée")
end)

-- Affichage des particules et HUD
hook.Add("Think", "LG_LeakParticles", function()
    for id, leak in pairs(LEGENDARY_TECHNICIAN.ClientLeaks) do
        local config = leak.type == "water" and LEGENDARY_TECHNICIAN.LeakConfig.Water or LEGENDARY_TECHNICIAN.LeakConfig.Gas
        
        -- Particules
        if math.random(1, 3) == 1 then
            local effectdata = EffectData()
            effectdata:SetOrigin(leak.pos)
            effectdata:SetScale(2)
            
            if leak.type == "water" then
                util.Effect("WaterSplash", effectdata)
            else
                util.Effect("ManhackSparks", effectdata)
            end
        end
    end
end)

-- HUD pour voir les fuites
hook.Add("HUDPaint", "LG_LeakHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    for id, leak in pairs(LEGENDARY_TECHNICIAN.ClientLeaks) do
        local scrPos = leak.pos:ToScreen()
        if not scrPos.visible then continue end
        
        local distance = ply:GetPos():Distance(leak.pos)
        if distance > 1000 then continue end
        
        local text = leak.type == "water" and "💧 FUITE D'EAU" or "☠️ FUITE DE GAZ"
        local color = leak.type == "water" and Color(50, 150, 255) or Color(255, 200, 50)
        
        draw.SimpleTextOutlined(text, "DermaLarge", scrPos.x, scrPos.y - 20, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("ID: " .. id, "DermaDefault", scrPos.x, scrPos.y + 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    end
end)

-- Ajoute ça avec les autres net.Receive
net.Receive("LG_LeakSyncPositions", function()
    LEGENDARY_TECHNICIAN.LeakPositions = net.ReadTable()
    print("[LEAK CLIENT] " .. #LEGENDARY_TECHNICIAN.LeakPositions .. " positions synchronisées")
end)
