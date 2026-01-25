-- Types de déchets avec leurs couleurs
local TrashTypes = {
    {name = "Plastique", color = Color(255, 255, 0), bin = 1},
    {name = "Verre", color = Color(128, 128, 128), bin = 2},
    {name = "Papier", color = Color(0, 128, 255), bin = 3},
    {name = "Organique", color = Color(255, 64, 64), bin = 4}
}

local BinColors = {
    Color(255, 255, 0),  -- Jaune
    Color(128, 128, 128), -- Gris
    Color(0, 128, 255),   -- Bleu
    Color(255, 64, 64)    -- Rouge
}

net.Receive("OpenRecyclerMinigame", function()
    local recycler = net.ReadEntity()
    if not IsValid(recycler) then return end
    
    -- Créer le frame principal
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 600)
    frame:Center()
    frame:SetTitle("Mini-jeu de Tri des Déchets")
    frame:MakePopup()
    frame:SetDraggable(false)
    
    local score = 0
    local totalTrash = 10
    local currentTrash = 0
    
    -- Zone de jeu
    local gamePanel = vgui.Create("DPanel", frame)
    gamePanel:SetPos(10, 40)
    gamePanel:SetSize(780, 400)
    gamePanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200))
    end
    
    -- Les 4 poubelles en bas
    local bins = {}
    for i = 1, 4 do
        local bin = vgui.Create("DPanel", gamePanel)
        bin:SetSize(150, 100)
        bin:SetPos(30 + (i-1) * 180, 280)
        bin.binType = i
        
        bin.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, BinColors[i])
            draw.SimpleText(TrashTypes[i].name, "DermaLarge", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Configurer comme récepteur de drag & drop
        bin:Receiver("trash", function(receiver, panels, dropped, menuIndex, x, y)
            if dropped and #panels > 0 then
                local trash = panels[1]
                if trash.trashType == i then
                    -- Bon tri !
                    score = score + 10
                    trash:Remove()
                    SpawnNextTrash()
                else
                    -- Mauvais tri
                    score = score - 5
                    trash:Remove()
                    SpawnNextTrash()
                end
            end
        end)
        
        bins[i] = bin
    end
    
    -- Score display
    local scoreLabel = vgui.Create("DLabel", frame)
    scoreLabel:SetPos(10, 450)
    scoreLabel:SetSize(200, 30)
    scoreLabel:SetFont("DermaLarge")
    scoreLabel:SetText("Score: 0")
    
    -- Fonction pour créer un déchet
    function SpawnNextTrash()
        currentTrash = currentTrash + 1
        
        if currentTrash > totalTrash then
            -- Fin du jeu
            timer.Simple(0.5, function()
                if IsValid(frame) then
                    frame:Close()
                    
                    -- Envoyer le résultat au serveur
                    net.Start("RecyclerMinigameResult")
                    net.WriteEntity(recycler)
                    net.WriteBool(score >= 50) -- Success si score >= 50
                    net.WriteInt(score, 16)
                    net.SendToServer()
                end
            end)
            return
        end
        
        -- Créer un nouveau déchet aléatoire
        local trashType = math.random(1, 4)
        local trash = vgui.Create("DPanel", gamePanel)
        trash:SetSize(60, 60)
        trash:SetPos(math.random(50, 670), 50)
        trash.trashType = trashType
        
        trash.Paint = function(self, w, h)
            draw.RoundedBox(30, 0, 0, w, h, TrashTypes[trashType].color)
        end
        
        -- Rendre draggable
        trash:Droppable("trash")
        trash:SetMouseInputEnabled(true)
        
        -- Drag personnalisé
        local dragging = false
        local offsetX, offsetY = 0, 0
        
        trash.OnMousePressed = function(self, keyCode)
            if keyCode == MOUSE_LEFT then
                dragging = true
                local x, y = self:LocalCursorPos()
                offsetX, offsetY = x, y
            end
        end
        
        trash.OnMouseReleased = function(self, keyCode)
            if keyCode == MOUSE_LEFT then
                dragging = false
            end
        end
        
        trash.Think = function(self)
            if dragging then
                local x, y = gamePanel:LocalCursorPos()
                self:SetPos(x - offsetX, y - offsetY)
            end
        end
        
        scoreLabel:SetText("Score: " .. score .. " | Déchets: " .. currentTrash .. "/" .. totalTrash)
    end
    
    -- Démarrer le jeu
    SpawnNextTrash()
end)
