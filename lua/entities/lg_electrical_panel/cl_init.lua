include("shared.lua")

LG_ElectricalPanelMarkers = LG_ElectricalPanelMarkers or {}

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    self:Draw()
    
    -- Marqueur si en panne (visible par tous)
    if self:GetIsBroken() then
        self:DrawBrokenMarker()
    end
    
    -- Marqueur de notification (seulement pour le technicien assigné)
    if LG_ElectricalPanelMarkers[self:EntIndex()] then
        self:DrawNotificationMarker()
    end
end

function ENT:DrawBrokenMarker()
    local pos = self:GetPos() + Vector(0, 0, 60)
    local distance = LocalPlayer():GetPos():Distance(pos)
    
    if distance > 1000 then return end
    
    local pulseScale = 1 + math.sin(CurTime() * 3) * 0.2
    local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
    
    cam.Start3D2D(pos, ang, 0.15 * pulseScale)
    draw.SimpleText("⚠", "DermaLarge", 0, 0, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function ENT:DrawNotificationMarker()
    local pos = self:GetPos() + Vector(0, 0, 100)
    local distance = LocalPlayer():GetPos():Distance(pos)
    local maxDistance = LEGENDARY_TECHNICIAN.Breakdown and LEGENDARY_TECHNICIAN.Breakdown.MarkerDistance or 2000
    
    if distance > maxDistance then return end
    
    local pulseScale = 1 + math.sin(CurTime() * 4) * 0.3
    local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
    
    cam.Start3D2D(pos, ang, 0.2 * pulseScale)
    draw.SimpleText("!", "DermaLarge", 0, 0, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Panne électrique", "DermaDefault", 0, 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(math.Round(distance) .. "m", "DermaDefault", 0, 60, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

-- Notification
net.Receive("LG_ElectricalPanelNotification", function()
    local panel = net.ReadEntity()
    if not IsValid(panel) then return end
    
    LG_ElectricalPanelMarkers[panel:EntIndex()] = true
    notification.AddLegacy("Une armoire électrique est en panne !", NOTIFY_ERROR, 5)
    surface.PlaySound("ambient/alarms/warningbell1.wav")
    
    print("[ARMOIRE CLIENT] Notification reçue pour armoire " .. panel:EntIndex())
    
    -- Créer un waypoint HUD
    timer.Simple(0.1, function()
        if IsValid(panel) then
            hook.Add("HUDPaint", "LG_ElectricalPanelWaypoint_" .. panel:EntIndex(), function()
                if not IsValid(panel) or not LG_ElectricalPanelMarkers[panel:EntIndex()] then
                    hook.Remove("HUDPaint", "LG_ElectricalPanelWaypoint_" .. panel:EntIndex())
                    return
                end
                
                local markerPos = panel:GetPos() + Vector(0, 0, 50)
                local screenPos = markerPos:ToScreen()
                local distance = LocalPlayer():GetPos():Distance(markerPos)
                
                -- Afficher même à travers les murs si proche
                if screenPos.visible or distance < 500 then
                    local alpha = math.Clamp(255 - (distance / 10), 50, 255)
                    draw.SimpleText(
                        "⚡ Armoire (" .. math.Round(distance) .. "m)",
                        "DermaDefault",
                        screenPos.x,
                        screenPos.y,
                        Color(255, 150, 50, alpha),
                        TEXT_ALIGN_CENTER,
                        TEXT_ALIGN_CENTER
                    )
                end
            end)
        end
    end)
end)

net.Receive("LG_RemoveElectricalPanelMarker", function()
    local panel = net.ReadEntity()
    if IsValid(panel) then
        local idx = panel:EntIndex()
        LG_ElectricalPanelMarkers[idx] = nil
        hook.Remove("HUDPaint", "LG_ElectricalPanelWaypoint_" .. idx)
        print("[ARMOIRE CLIENT] Marqueur retiré pour armoire " .. idx)
    end
end)

-- Nettoyer les marqueurs quand on change de job
local lastTeam = nil
hook.Add("Think", "LG_CleanElectricalMarkersOnJobChange", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local currentTeam = ply:Team()
    
    if lastTeam and lastTeam ~= currentTeam then
        print("[ARMOIRE CLIENT] Changement de job détecté, nettoyage des marqueurs")
        
        for idx, _ in pairs(LG_ElectricalPanelMarkers) do
            hook.Remove("HUDPaint", "LG_ElectricalPanelWaypoint_" .. idx)
        end
        
        LG_ElectricalPanelMarkers = {}
    end
    
    lastTeam = currentTeam
end)

-- Mini-jeu de câblage
net.Receive("LG_OpenWiringMinigame", function()
    local panel = net.ReadEntity()
    if not IsValid(panel) then return end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 600)
    frame:Center()
    frame:SetTitle("Réparer l'armoire électrique")
    frame:MakePopup()
    
    local config = LEGENDARY_TECHNICIAN.Breakdown or {}
    local wireCount = config.WireCount or 4
    local timeLimit = config.MinigameTime or 60
    
    local startTime = CurTime()
    
    -- Définir les couleurs directement avec les valeurs RGB
    local wireColors = {
        {r = 255, g = 50, b = 50},     -- Rouge
        {r = 50, g = 150, b = 255},    -- Bleu
        {r = 50, g = 255, b = 50},     -- Vert
        {r = 255, g = 255, b = 50},    -- Jaune
        {r = 255, g = 100, b = 255},   -- Rose/Magenta
        {r = 255, g = 150, b = 50},    -- Orange
        {r = 150, g = 50, b = 255},    -- Violet
        {r = 50, g = 255, b = 255},    -- Cyan
    }
    
    -- Calculer l'espacement vertical en fonction du nombre de fils
    local canvasHeight = 500
    local spacing = canvasHeight / (wireCount + 1)
    local wireSize = math.min(40, spacing * 0.6) -- Taille adaptative
    
    -- Générer les positions des fils
    local leftWires = {}
    local rightWires = {}
    
    -- Créer les fils de gauche avec leur position initiale
    for i = 1, wireCount do
        leftWires[i] = {
            x = 50,
            y = 50 + (i * spacing),
            r = wireColors[i].r,
            g = wireColors[i].g,
            b = wireColors[i].b,
            connected = false,
            wireId = i
        }
    end
    
    -- Créer les fils de droite avec les mêmes couleurs
    for i = 1, wireCount do
        rightWires[i] = {
            x = 730,
            y = 50 + (i * spacing),
            r = wireColors[i].r,
            g = wireColors[i].g,
            b = wireColors[i].b,
            connected = false,
            wireId = i
        }
    end
    
    -- Mélanger les positions des fils de droite UNIQUEMENT
    local shuffledPositions = {}
    for i = 1, wireCount do
        shuffledPositions[i] = 50 + (i * spacing)
    end
    table.Shuffle(shuffledPositions)
    
    -- Appliquer les positions mélangées
    for i = 1, wireCount do
        rightWires[i].y = shuffledPositions[i]
    end
    
    local selectedWire = nil
    local connectedWires = 0
    
    -- Timer
    local timerLabel = vgui.Create("DLabel", frame)
    timerLabel:SetPos(350, 10)
    timerLabel:SetSize(100, 30)
    timerLabel:SetFont("DermaLarge")
    timerLabel:SetText("60")
    
    -- Canvas de dessin
    local canvas = vgui.Create("DPanel", frame)
    canvas:SetPos(0, 50)
    canvas:SetSize(800, 550)
    
    canvas.Paint = function(self, w, h)
        -- Background
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30))
        
        -- Timer
        local timeLeft = math.max(0, timeLimit - (CurTime() - startTime))
        timerLabel:SetText(math.ceil(timeLeft))
        timerLabel:SetTextColor(timeLeft <= 10 and Color(255, 50, 50) or Color(255, 255, 255))
        
        if timeLeft <= 0 then
            frame:Close()
            net.Start("LG_WiringMinigameResult")
            net.WriteEntity(panel)
            net.WriteBool(false)
            net.SendToServer()
            return
        end
        
        -- Dessiner les connexions existantes
        for i = 1, wireCount do
            if leftWires[i].connected and leftWires[i].connectedTo then
                local lw = leftWires[i]
                local rw = leftWires[i].connectedTo
                
                -- Ligne plus épaisse
                surface.SetDrawColor(lw.r, lw.g, lw.b, 200)
                for offset = -2, 2 do
                    surface.DrawLine(lw.x + wireSize/2, lw.y + offset, rw.x, rw.y + offset)
                end
            end
        end
        
        -- Dessiner le fil en cours de connexion
        if selectedWire then
            local mx, my = input.GetCursorPos()
            mx, my = canvas:ScreenToLocal(mx, my)
            
            surface.SetDrawColor(selectedWire.r, selectedWire.g, selectedWire.b, 150)
            for offset = -1, 1 do
                surface.DrawLine(selectedWire.x + wireSize/2, selectedWire.y + offset, mx, my + offset)
            end
        end
        
        -- Dessiner les fils de gauche
        for i, wire in ipairs(leftWires) do
            local alpha = wire.connected and 100 or 255
            draw.RoundedBox(8, wire.x, wire.y - wireSize/2, wireSize, wireSize, Color(wire.r, wire.g, wire.b, alpha))
        end
        
        -- Dessiner les fils de droite
        for i, wire in ipairs(rightWires) do
            local alpha = wire.connected and 100 or 255
            draw.RoundedBox(8, wire.x, wire.y - wireSize/2, wireSize, wireSize, Color(wire.r, wire.g, wire.b, alpha))
        end
        
        -- Instructions
        draw.SimpleText("Connectez les fils de la même couleur", "DermaDefault", w/2, 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Compteur de connexions
        draw.SimpleText(connectedWires .. " / " .. wireCount, "DermaLarge", w/2, h - 30, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    canvas.OnMousePressed = function(self, keyCode)
        if keyCode != MOUSE_LEFT then return end
        
        local mx, my = input.GetCursorPos()
        mx, my = canvas:ScreenToLocal(mx, my)
        
        -- Cliquer sur un fil de gauche
        for i, wire in ipairs(leftWires) do
            if not wire.connected and mx >= wire.x and mx <= wire.x + wireSize and 
               my >= wire.y - wireSize/2 and my <= wire.y + wireSize/2 then
                selectedWire = wire
                surface.PlaySound("buttons/lightswitch2.wav")
                return
            end
        end
        
        -- Cliquer sur un fil de droite
        if selectedWire then
            for i, wire in ipairs(rightWires) do
                if not wire.connected and mx >= wire.x and mx <= wire.x + wireSize and 
                   my >= wire.y - wireSize/2 and my <= wire.y + wireSize/2 then
                    -- Vérifier si c'est le bon match (même wireId = même couleur)
                    if selectedWire.wireId == wire.wireId then
                        selectedWire.connected = true
                        selectedWire.connectedTo = wire
                        wire.connected = true
                        connectedWires = connectedWires + 1
                        surface.PlaySound("buttons/button9.wav")
                        
                        -- Vérifier si terminé
                        if connectedWires >= wireCount then
                            timer.Simple(0.5, function()
                                if IsValid(frame) then
                                    frame:Close()
                                    net.Start("LG_WiringMinigameResult")
                                    net.WriteEntity(panel)
                                    net.WriteBool(true)
                                    net.SendToServer()
                                end
                            end)
                        end
                    else
                        surface.PlaySound("buttons/button10.wav")
                    end
                    
                    selectedWire = nil
                    return
                end
            end
            
            -- Clic dans le vide = annuler la sélection
            selectedWire = nil
        end
    end
end)

