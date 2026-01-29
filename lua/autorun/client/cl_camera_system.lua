-- Système client pour les caméras
LEGENDARY_TECHNICIAN = LEGENDARY_TECHNICIAN or {}
LG_CameraMarkers = LG_CameraMarkers or {}
LG_CameraHealths = LG_CameraHealths or {}

-- Notification de caméra cassée
net.Receive("LG_CameraNotification", function()
    local camera = net.ReadEntity()
    if not IsValid(camera) then return end
    
    LG_CameraMarkers[camera:EntIndex()] = true
    notification.AddLegacy("Une caméra de surveillance est cassée !", NOTIFY_ERROR, 5)
    surface.PlaySound("ambient/alarms/warningbell1.wav")
    
    print("[CAMÉRA CLIENT] Notification reçue pour caméra " .. camera:EntIndex())
end)

-- Retirer le marqueur
net.Receive("LG_RemoveCameraMarker", function()
    local camera = net.ReadEntity()
    if IsValid(camera) then
        LG_CameraMarkers[camera:EntIndex()] = nil
        print("[CAMÉRA CLIENT] Marqueur retiré pour caméra " .. camera:EntIndex())
    end
end)

-- Mise à jour de la santé
net.Receive("LG_CameraHealth", function()
    local camera = net.ReadEntity()
    local health = net.ReadInt(16)
    local maxHealth = net.ReadInt(16)
    
    if IsValid(camera) then
        LG_CameraHealths[camera:EntIndex()] = {
            health = health,
            maxHealth = maxHealth
        }
    end
end)

-- État cassé
net.Receive("LG_CameraBroken", function()
    local camera = net.ReadEntity()
    local isBroken = net.ReadBool()
    
    if IsValid(camera) then
        camera.LG_IsBroken = isBroken
    end
end)

-- HUD pour afficher les caméras cassées
hook.Add("HUDPaint", "LG_CameraHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Vérifier si le joueur est technicien
    local isTech = false
    local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
    
    if techTeam then
        if type(techTeam) == "number" then
            isTech = ply:Team() == techTeam
        elseif type(techTeam) == "string" and ply.getDarkRPVar then
            isTech = ply:getDarkRPVar("job") == techTeam
        end
    end
    
    if not isTech then return end
    
    -- Afficher les waypoints pour les caméras assignées
    for idx, _ in pairs(LG_CameraMarkers) do
        local camera = Entity(idx)
        if IsValid(camera) and camera.LG_IsBroken then
            local markerPos = camera:GetPos() + Vector(0, 0, 30)
            local screenPos = markerPos:ToScreen()
            local distance = ply:GetPos():Distance(markerPos)
            
            if screenPos.visible or distance < 500 then
                local alpha = math.Clamp(255 - (distance / 10), 50, 255)
                draw.SimpleText(
                    "📹 Caméra (" .. math.Round(distance) .. "m)",
                    "DermaDefault",
                    screenPos.x,
                    screenPos.y,
                    Color(255, 50, 50, alpha),
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end
        end
    end
end)

-- Nettoyer les marqueurs quand on change de job
local lastTeam = nil
hook.Add("Think", "LG_CleanCameraMarkersOnJobChange", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local currentTeam = ply:Team()
    
    if lastTeam and lastTeam ~= currentTeam then
        print("[CAMÉRA CLIENT] Changement de job détecté, nettoyage des marqueurs")
        LG_CameraMarkers = {}
    end
    
    lastTeam = currentTeam
end)

-- Mini-jeu de calibration (comme Among Us - 1 rond à la fois)
net.Receive("LG_OpenCameraMinigame", function()
    local camera = net.ReadEntity()
    if not IsValid(camera) then return end
    
    -- Empêcher l'ouverture multiple côté client
    if LG_CameraMinigameOpen then
        print("[CAMÉRA] Mini-jeu déjà ouvert")
        return
    end
    LG_CameraMinigameOpen = true
    
    local config = LEGENDARY_TECHNICIAN.Camera and LEGENDARY_TECHNICIAN.Camera.Minigame or {}
    local timeLimit = config.TimeLimit or 60
    local calibrationsNeeded = config.CalibrationsNeeded or 3
    local rotationSpeed = config.RotationSpeed or 3
    local targetZoneSize = config.TargetZoneSize or 0.15
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 700)
    frame:Center()
    frame:SetTitle("Calibrer la caméra")
    frame:MakePopup()
    
    frame.OnClose = function()
        LG_CameraMinigameOpen = false
    end
    
    local startTime = CurTime()
    local currentCalibration = 1
    local angle = 0
    local canClick = true
    local currentTargetAngle = math.random(0, 360)
    
    -- Couleurs pour chaque calibration
    local calibrationColors = {
        Color(255, 200, 50),   -- Jaune/doré
        Color(50, 150, 255),   -- Bleu
        Color(50, 255, 200),   -- Cyan
    }
    
    -- Timer
    local timerLabel = vgui.Create("DLabel", frame)
    timerLabel:SetPos(250, 10)
    timerLabel:SetSize(100, 30)
    timerLabel:SetFont("DermaLarge")
    timerLabel:SetText("60")
    
    -- Compteur de calibrations
    local calibLabel = vgui.Create("DLabel", frame)
    calibLabel:SetPos(200, 50)
    calibLabel:SetSize(200, 30)
    calibLabel:SetFont("DermaLarge")
    calibLabel:SetText("Calibration 1 / " .. calibrationsNeeded)
    calibLabel:SetContentAlignment(5)
    
    -- Canvas
    local canvas = vgui.Create("DPanel", frame)
    canvas:SetPos(50, 100)
    canvas:SetSize(500, 500)
    
    -- Helper pour dessiner un arc
    local function DrawArc(cx, cy, radius, thickness, startAngle, endAngle, color)
        draw.NoTexture()
        surface.SetDrawColor(color)
        
        local segments = math.ceil(math.abs(endAngle - startAngle) / 2)
        segments = math.max(segments, 10)
        
        for i = 0, segments - 1 do
            local ang1 = math.rad(startAngle + (i / segments) * (endAngle - startAngle))
            local ang2 = math.rad(startAngle + ((i + 1) / segments) * (endAngle - startAngle))
            
            local x1_outer = cx + math.cos(ang1) * radius
            local y1_outer = cy + math.sin(ang1) * radius
            local x2_outer = cx + math.cos(ang2) * radius
            local y2_outer = cy + math.sin(ang2) * radius
            
            local x1_inner = cx + math.cos(ang1) * (radius - thickness)
            local y1_inner = cy + math.sin(ang1) * (radius - thickness)
            local x2_inner = cx + math.cos(ang2) * (radius - thickness)
            local y2_inner = cy + math.sin(ang2) * (radius - thickness)
            
            surface.DrawPoly({
                {x = x1_outer, y = y1_outer},
                {x = x2_outer, y = y2_outer},
                {x = x2_inner, y = y2_inner},
                {x = x1_inner, y = y1_inner}
            })
        end
    end
    
    canvas.Paint = function(self, w, h)
        -- Background noir
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
        
        -- Timer
        local timeLeft = math.max(0, timeLimit - (CurTime() - startTime))
        timerLabel:SetText(math.ceil(timeLeft))
        timerLabel:SetTextColor(timeLeft <= 10 and Color(255, 50, 50) or Color(255, 255, 255))
        
        if timeLeft <= 0 then
            frame:Close()
            net.Start("LG_CameraMinigameResult")
            net.WriteEntity(camera)
            net.WriteBool(false)
            net.SendToServer()
            LG_CameraMinigameOpen = false
            return
        end
        
        local centerX = w / 2
        local centerY = h / 2
        local radius = 180
        local thickness = 35
        
        -- Cercle de fond complet (gris)
        draw.NoTexture()
        surface.SetDrawColor(80, 80, 80, 255)
        surface.DrawCircle(centerX, centerY, radius, Color(80, 80, 80))
        
        surface.SetDrawColor(20, 20, 20, 255)
        surface.DrawCircle(centerX, centerY, radius - thickness, Color(20, 20, 20))
        
        -- Dessiner UNIQUEMENT la zone cible actuelle (1 seul arc coloré)
        local currentColor = calibrationColors[currentCalibration]
        local targetSize = 360 * targetZoneSize
        local startAngle = currentTargetAngle - targetSize / 2
        local endAngle = currentTargetAngle + targetSize / 2
        
        DrawArc(centerX, centerY, radius, thickness, startAngle, endAngle, currentColor)
        
        -- Numéro sur la zone cible
        local labelAngle = math.rad(currentTargetAngle)
        local labelX = centerX + math.cos(labelAngle) * (radius - thickness / 2)
        local labelY = centerY + math.sin(labelAngle) * (radius - thickness / 2)
        
        draw.SimpleText(currentCalibration, "DermaLarge", labelX, labelY, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Indicateur rotatif (ligne rouge qui tourne)
        angle = angle + (rotationSpeed * FrameTime() * 100)
        if angle >= 360 then angle = angle - 360 end
        
        local indicatorAngle = math.rad(angle)
        local indicatorStartX = centerX + math.cos(indicatorAngle) * (radius - thickness - 10)
        local indicatorStartY = centerY + math.sin(indicatorAngle) * (radius - thickness - 10)
        local indicatorEndX = centerX + math.cos(indicatorAngle) * (radius + 10)
        local indicatorEndY = centerY + math.sin(indicatorAngle) * (radius + 10)
        
        -- Ligne rouge épaisse
        surface.SetDrawColor(255, 50, 50, 255)
        for offset = -3, 3 do
            local perpAngle = indicatorAngle + math.pi / 2
            local offsetX = math.cos(perpAngle) * offset
            local offsetY = math.sin(perpAngle) * offset
            surface.DrawLine(
                indicatorStartX + offsetX, 
                indicatorStartY + offsetY, 
                indicatorEndX + offsetX, 
                indicatorEndY + offsetY
            )
        end
        
        -- Point rouge au bout de l'indicateur
        draw.NoTexture()
        surface.SetDrawColor(255, 50, 50, 255)
        surface.DrawCircle(indicatorEndX, indicatorEndY, 8, Color(255, 50, 50))
        
        -- Cercle central (gris foncé)
        draw.NoTexture()
        surface.SetDrawColor(30, 30, 30, 255)
        surface.DrawCircle(centerX, centerY, 50, Color(30, 30, 30))
        
        -- Numéro de calibration au centre
        draw.SimpleText(currentCalibration, "DermaLarge", centerX, centerY, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Instructions
        draw.SimpleText("Appuyez sur ESPACE quand l'indicateur rouge est dans la zone colorée", "DermaDefault", w/2, h - 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Fonction pour vérifier si l'angle est dans la zone cible
    local function isInTargetZone()
        local targetSize = 360 * targetZoneSize
        local startAngle = (currentTargetAngle - targetSize / 2) % 360
        local endAngle = (currentTargetAngle + targetSize / 2) % 360
        local normalizedAngle = angle % 360
        
        -- Gérer le cas où la zone traverse 0°
        if startAngle > endAngle then
            return normalizedAngle >= startAngle or normalizedAngle <= endAngle
        else
            return normalizedAngle >= startAngle and normalizedAngle <= endAngle
        end
    end
    
    -- Input
    frame.OnKeyCodePressed = function(self, key)
        if key == KEY_SPACE and canClick then
            canClick = false
            
            if isInTargetZone() then
                -- Succès !
                surface.PlaySound("buttons/button9.wav")
                
                if currentCalibration >= calibrationsNeeded then
                    -- Toutes les calibrations réussies !
                    timer.Simple(0.5, function()
                        if IsValid(frame) then
                            frame:Close()
                            net.Start("LG_CameraMinigameResult")
                            net.WriteEntity(camera)
                            net.WriteBool(true)
                            net.SendToServer()
                            LG_CameraMinigameOpen = false
                        end
                    end)
                else
                    -- Passer à la calibration suivante
                    currentCalibration = currentCalibration + 1
                    calibLabel:SetText("Calibration " .. currentCalibration .. " / " .. calibrationsNeeded)
                    
                    -- Nouvelle position aléatoire pour la prochaine zone
                    currentTargetAngle = math.random(0, 360)
                    
                    timer.Simple(0.5, function()
                        canClick = true
                    end)
                end
            else
                -- Raté !
                surface.PlaySound("buttons/button10.wav")
                timer.Simple(0.5, function()
                    canClick = true
                end)
            end
        end
    end
end)

-- Helper pour dessiner des cercles
function surface.DrawCircle(x, y, radius, color)
    local segmentCount = 50
    draw.NoTexture()
    surface.SetDrawColor(color)
    
    local circle = {}
    for i = 0, segmentCount do
        local angle = math.rad((i / segmentCount) * 360)
        table.insert(circle, {
            x = x + math.cos(angle) * radius,
            y = y + math.sin(angle) * radius
        })
    end
    
    surface.DrawPoly(circle)
end



print("[CAMÉRA CLIENT] Système de caméras chargé")
