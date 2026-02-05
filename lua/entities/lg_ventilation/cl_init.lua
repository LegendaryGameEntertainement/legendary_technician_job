include("shared.lua")

-- Dessin 3D2D
function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + Vector(0, 0, 40)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        local txt = self:GetIsBlocked() and "OBSTRUEE" or "OK"
        local col = self:GetIsBlocked() and Color(200, 50, 50) or Color(50, 200, 50)
        draw.RoundedBox(8, -80, -20, 160, 40, Color(0, 0, 0, 150))
        draw.SimpleText(txt, "DermaLarge", 0, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

---------------------------------------------------------------------
-- MINIGAME
---------------------------------------------------------------------

local VentMiniFrame = nil

function DrawCircle(x, y, radius, color)
    surface.SetDrawColor(color)
    local circle = {}
    for i = 0, 360, 5 do
        local a = math.rad(i)
        local px, py = x + math.cos(a) * radius, y + math.sin(a) * radius
        table.insert(circle, {x = px, y = py})
    end
    draw.NoTexture()
    surface.DrawPoly(circle)
end

local function OpenVentMinigame(vent)
    if not IsValid(vent) then return end

    if IsValid(VentMiniFrame) then
        VentMiniFrame:Remove()
    end

    local w, h = 500, 400
    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("Réparation Ventilation - Étape 1/4")
    frame:SetDeleteOnClose(true)
    frame:MakePopup()
    VentMiniFrame = frame

    local step = 1
    local screwClicks = 0
    local totalClicksNeeded = math.random(5, 7)
    local screwClicked = false
    local propellerRemoved = false
    local startDragX, startDragY = 0, 0

    local label = vgui.Create("DLabel", frame)
    label:SetText("Cliquez 5-7 fois sur la vis centrale pour dévisser.")
    label:Dock(TOP)
    label:SetTall(40)
    label:DockMargin(10, 10, 10, 10)
    label:SetFont("DermaLarge")
    label:SetContentAlignment(5)

    local canvas = vgui.Create("DPanel", frame)
    canvas:Dock(FILL)
    canvas:DockMargin(10, 10, 10, 10)
    
    canvas.Paint = function(self, pw, ph)
        -- Fond métal
        draw.RoundedBox(8, 0, 0, pw, ph, Color(80, 80, 80, 255))
        draw.RoundedBox(8, 20, 20, pw - 40, ph - 40, Color(120, 120, 120, 255))

        -- Hélène
        local propX, propY = pw / 2, ph / 2
        local propRadius = math.min(pw, ph) * 0.35
        
        if not propellerRemoved then
            local propColor = (step == 1 or step == 2) and Color(150, 50, 50) or Color(50, 150, 50)
            DrawCircle(propX, propY, propRadius, propColor)
        else
            DrawCircle(propX, propY, propRadius, Color(50, 150, 50))
        end

        -- Vis
        local screwRadius = propRadius * 0.25
        local screwX, screwY = propX, propY
        local screwProgress = screwClicks / totalClicksNeeded
        local screwRotation = screwProgress * 360

        DrawCircle(screwX, screwY, screwRadius, Color(200, 200, 200))

        -- Tête vis rotative
        surface.SetDrawColor(180, 180, 180)
        cam.PushModelMatrix(Matrix({
            {math.cos(math.rad(screwRotation)), -math.sin(math.rad(screwRotation)), 0, screwX},
            {math.sin(math.rad(screwRotation)),  math.cos(math.rad(screwRotation)), 0, screwY},
            {0, 0, 1, 0},
            {0, 0, 0, 1}
        }))
        draw.NoTexture()
        surface.DrawCircle(0, 0, screwRadius * 0.6)
        cam.PopModelMatrix()

        -- Progression
        draw.RoundedBox(4, pw/2 - 100, ph - 60, 200, 20, Color(50, 50, 50, 200))
        draw.RoundedBox(4, pw/2 - 100, ph - 60, 200 * screwProgress, 20, Color(100, 200, 100, 255))
        draw.SimpleText(math.Round(screwProgress * 100) .. "%", "DermaDefault", pw/2, ph - 60, Color(255,255,255), TEXT_ALIGN_CENTER)
    end

    -- Clics
    canvas.OnMousePressed = function(self, mcode)
        local mx, my = self:CursorPos()
        local centerX, centerY = canvas:GetWide()/2, canvas:GetTall()/2
        local dist = math.Distance(mx, my, centerX, centerY)

        local propRadius = math.min(canvas:GetWide(), canvas:GetTall()) * 0.35
        local screwRadius = propRadius * 0.25

        if dist <= screwRadius then
            screwClicked = true
            startDragX, startDragY = mx, my

            if step == 1 or step == 4 then
                screwClicks = screwClicks + 1
                surface.PlaySound("buttons/button9.wav")

                if step == 1 and screwClicks >= totalClicksNeeded then
                    step = 2
                    label:SetText("Dévissée ! Glissez l'hélice pour l'enlever.")
                    frame:SetTitle("Étape 2/4")
                elseif step == 4 and screwClicks >= totalClicksNeeded then
                    net.Start("LG_VentMinigameResult")
                    net.WriteEntity(vent)
                    net.WriteBool(true)
                    net.SendToServer()
                    surface.PlaySound("buttons/button14.wav")
                    notification.AddLegacy("Ventilation réparée !", NOTIFY_GENERIC, 5)
                    frame:Close()
                end
            elseif step == 3 then
                screwClicks = 0
                step = 4
                label:SetText("Hélice neuve posée ! Cliquez pour revisser.")
                frame:SetTitle("Étape 4/4")
            end
        end
    end

    canvas.OnCursorMoved = function(self, x, y)
        if step == 2 and screwClicked and not propellerRemoved then
            if math.Distance(x, y, startDragX, startDragY) > 100 then
                propellerRemoved = true
                step = 3
                label:SetText("Hélice cassée enlevée ! Cliquez au centre.")
                frame:SetTitle("Étape 3/4")
                screwClicked = false
                surface.PlaySound("physics/metal/metal_barrel_impact_hard1.wav")
            end
        end
    end

    timer.Simple(45, function()
        if IsValid(frame) then
            net.Start("LG_VentMinigameResult")
            net.WriteEntity(vent)
            net.WriteBool(false)
            net.SendToServer()
            frame:Close()
        end
    end)
end

net.Receive("LG_OpenVentMinigame", function()
    local vent = net.ReadEntity()
    if IsValid(vent) then
        OpenVentMinigame(vent)
    end
end)
