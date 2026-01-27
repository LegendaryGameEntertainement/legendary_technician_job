include("shared.lua")

-- Table pour stocker les marqueurs actifs côté client
LG_TrashBinMarkers = LG_TrashBinMarkers or {}

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    self:Draw()
    
    -- Dessiner un marqueur si la poubelle est pleine (visible pour tout le monde)
    if self:GetIsFull() then
        self:DrawFullMarker()
    end
    
    -- Dessiner le marqueur de notification si le joueur est technicien
    if LG_TrashBinMarkers[self:EntIndex()] then
        self:DrawNotificationMarker()
    end
end

-- Marqueur simple au-dessus de la poubelle (visible par tous)
function ENT:DrawFullMarker()
    local pos = self:GetPos() + Vector(0, 0, 80)
    local distance = LocalPlayer():GetPos():Distance(pos)
    
    -- Ne pas afficher si trop loin
    if distance > 1000 then return end
    
    -- Effet de pulsation
    local pulseScale = 1 + math.sin(CurTime() * 2) * 0.15
    
    local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
    
    cam.Start3D2D(pos, ang, 0.15 * pulseScale)
        -- Icône poubelle pleine (tu pourras remplacer par une vraie icône plus tard)
        draw.SimpleText("🗑️", "DermaLarge", 0, 0, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

-- Marqueur de notification pour les techniciens
function ENT:DrawNotificationMarker()
    local pos = self:GetPos() + Vector(0, 0, 120)
    local distance = LocalPlayer():GetPos():Distance(pos)
    local maxDistance = LEGENDARY_FLOOR_TECHNICIAN.TrashBinMarkerDistance or 2000
    
    -- Ne pas afficher si trop loin
    if distance > maxDistance then return end
    
    -- Effet de pulsation plus prononcé pour la notification
    local pulseScale = 1 + math.sin(CurTime() * 4) * 0.3
    
    local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
    
    cam.Start3D2D(pos, ang, 0.2 * pulseScale)
        -- Icône d'alerte
        draw.SimpleText("!", "DermaLarge", 0, 0, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Poubelle pleine", "DermaDefault", 0, 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(math.Round(distance) .. "m", "DermaDefault", 0, 60, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

-- Recevoir la notification côté client
net.Receive("LG_TrashBinNotification", function()
    local trashBin = net.ReadEntity()
    
    if not IsValid(trashBin) then 
        print("[POUBELLE CLIENT] Entité invalide reçue")
        return 
    end
    
    -- Ajouter le marqueur
    LG_TrashBinMarkers[trashBin:EntIndex()] = true
    
    -- Afficher un popup
    notification.AddLegacy("Une poubelle est pleine !", NOTIFY_HINT, 5)
    surface.PlaySound("buttons/button15.wav")
    
    print("[POUBELLE CLIENT] Notification reçue pour poubelle " .. trashBin:EntIndex())
    
    -- Créer un waypoint HUD
    timer.Simple(0.1, function()
        if IsValid(trashBin) then
            hook.Add("HUDPaint", "LG_TrashBinWaypoint_" .. trashBin:EntIndex(), function()
                if not IsValid(trashBin) or not LG_TrashBinMarkers[trashBin:EntIndex()] then
                    hook.Remove("HUDPaint", "LG_TrashBinWaypoint_" .. trashBin:EntIndex())
                    return
                end
                
                local markerPos = trashBin:GetPos() + Vector(0, 0, 50)
                local screenPos = markerPos:ToScreen()
                local distance = LocalPlayer():GetPos():Distance(markerPos)
                
                -- Afficher même à travers les murs si proche
                if screenPos.visible or distance < 500 then
                    local alpha = math.Clamp(255 - (distance / 10), 50, 255)
                    
                    draw.SimpleText(
                        "🗑️ Poubelle (" .. math.Round(distance) .. "m)",
                        "DermaDefault",
                        screenPos.x,
                        screenPos.y,
                        Color(255, 100, 100, alpha),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end)
        end
    end)
end)

-- Retirer le marqueur
net.Receive("LG_RemoveTrashBinMarker", function()
    local trashBin = net.ReadEntity()
    
    if IsValid(trashBin) then
        local idx = trashBin:EntIndex()
        LG_TrashBinMarkers[idx] = nil
        hook.Remove("HUDPaint", "LG_TrashBinWaypoint_" .. idx)
        
        print("[POUBELLE CLIENT] Marqueur retiré pour poubelle " .. idx)
    end
end)

-- Nettoyer les marqueurs quand on change de job
local lastTeam = nil

hook.Add("Think", "LG_CleanTrashMarkersOnJobChange", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local currentTeam = ply:Team()
    
    -- Si le team a changé
    if lastTeam and lastTeam ~= currentTeam then
        print("[POUBELLE CLIENT] Changement de job détecté, nettoyage des marqueurs")
        
        -- Vider tous les marqueurs
        for idx, _ in pairs(LG_TrashBinMarkers) do
            hook.Remove("HUDPaint", "LG_TrashBinWaypoint_" .. idx)
        end
        LG_TrashBinMarkers = {}
    end
    
    lastTeam = currentTeam
end)
