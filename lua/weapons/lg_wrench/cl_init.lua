include("shared.lua")

function SWEP:Initialize()
    self:SetHoldType("melee")
end

function SWEP:DrawHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local tr = ply:GetEyeTrace()
    
    -- Trouver la fuite la plus proche
    local closestID = nil
    local closestDist = 150
    local closestPos = nil
    
    for id, leakData in ipairs(LEGENDARY_TECHNICIAN.LeakPositions or {}) do
        local dist = tr.HitPos:Distance(leakData.pos)
        if dist < closestDist then
            closestID = id
            closestDist = dist
            closestPos = leakData.pos
        end
    end
    
    local scrW, scrH = ScrW(), ScrH()
    local centerX, centerY = scrW / 2, scrH / 2
    
    if closestID then
        local isActive = LEGENDARY_TECHNICIAN.ClientLeaks[closestID] ~= nil
        
        if isActive then
            draw.SimpleText("Fuite Détectée", "DermaLarge", centerX, centerY + 50, Color(255, 100, 100), TEXT_ALIGN_CENTER)
            draw.SimpleText("[Clic Gauche] Réparer", "DermaDefault", centerX, centerY + 80, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText(math.Round(closestDist) .. "u", "DermaDefault", centerX, centerY + 100, Color(200, 200, 200), TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Fuite Inactive", "DermaDefault", centerX, centerY + 50, Color(100, 100, 100), TEXT_ALIGN_CENTER)
        end
    end
    
    -- Afficher la barre de progression pendant la réparation
    if ply:GetNWBool("LG_IsRepairing") then
        local leakID = ply:GetNWInt("LG_RepairingLeakID")
        local leakData = LEGENDARY_TECHNICIAN.LeakPositions[leakID]
        
        if leakData then
            local config = leakData.type == "water" and LEGENDARY_TECHNICIAN.LeakConfig.Water or LEGENDARY_TECHNICIAN.LeakConfig.Gas
            local startTime = ply:GetNWFloat("LG_RepairStartTime")
            local progress = math.Clamp((CurTime() - startTime) / config.RepairTime, 0, 1)
            
            local barW, barH = 300, 30
            local barX, barY = centerX - barW / 2, centerY + 120
            
            draw.RoundedBox(4, barX, barY, barW, barH, Color(50, 50, 50, 200))
            draw.RoundedBox(4, barX, barY, barW * progress, barH, Color(100, 200, 100, 255))
            
            draw.SimpleText("Réparation en cours...", "DermaDefault", centerX, barY - 20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            draw.SimpleText(math.Round(progress * 100) .. "%", "DermaDefault", centerX, barY + barH / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

function SWEP:DrawWorldModel()
    self:DrawModel()
end
