-- Types de déchets avec leurs couleurs
local TrashTypes = {
    {name = "Plastique", color = Color(255, 255, 0), bin = 1},
    {name = "Métal", color = Color(128, 128, 128), bin = 2},
    {name = "Papier", color = Color(0, 128, 255), bin = 3},
    {name = "Organique", color = Color(255, 64, 64), bin = 4},
    {name = "Verre", color = Color(0, 255, 0), bin = 5}
}

local BinColors = {
    Color(255, 255, 0),  -- Jaune - Plastique
    Color(128, 128, 128), -- Gris - Métal
    Color(0, 128, 255),   -- Bleu - Papier
    Color(255, 64, 64),   -- Rouge - Organique
    Color(0, 255, 0)      -- Vert - Verre
}

net.Receive("OpenRecyclerMinigame", function()
    local recycler = net.ReadEntity()
    if not IsValid(recycler) then return end
    
    -- Créer le frame principal
    local frame = vgui.Create("DFrame")
    frame:SetSize(950, 600)
    frame:Center()
    frame:SetTitle("Mini-jeu de Tri des Déchets")
    frame:MakePopup()
    frame:SetDraggable(false)
    
    local totalTrash = 10
    local currentTrash = 0
    local currentTrashPanel = nil
    local score = 0
    
    -- Zone de jeu SANS paint (on dessine le fond différemment)
    local gamePanel = vgui.Create("DPanel", frame)
    gamePanel:SetPos(10, 40)
    gamePanel:SetSize(930, 450)
    gamePanel.Paint = function(self, w, h)
        -- Ne rien dessiner ici, on va dessiner le fond dans le frame
    end
    
    -- Surcharger le Paint du frame pour dessiner le fond DERRIÈRE tout
    local oldFramePaint = frame.Paint
    frame.Paint = function(self, w, h)
        -- Dessiner le fond normal du frame
        if oldFramePaint then
            oldFramePaint(self, w, h)
        end
        
        -- Dessiner le fond gris de la zone de jeu DERRIÈRE
        draw.RoundedBox(0, 10, 40, 930, 450, Color(180, 180, 180))
    end
    
    -- Compteur de déchets
    local trashCounter = vgui.Create("DLabel", frame)
    trashCounter:SetPos(10, 500)
    trashCounter:SetSize(930, 30)
    trashCounter:SetFont("DermaLarge")
    trashCounter:SetText("Déchets: 0/" .. totalTrash)
    trashCounter:SetContentAlignment(5)
    
    -- Instruction
    local instructionLabel = vgui.Create("DLabel", frame)
    instructionLabel:SetPos(10, 530)
    instructionLabel:SetSize(930, 30)
    instructionLabel:SetFont("DermaDefault")
    instructionLabel:SetText("Clique sur la poubelle de la bonne couleur pour y jeter le déchet !")
    instructionLabel:SetContentAlignment(5)
    
    -- Les 5 poubelles en bas (bien centrées)
    local bins = {}
    local binWidth = 150
    local binSpacing = 170
    local totalBinsWidth = (binWidth * 5) + (binSpacing - binWidth) * 4
    local startX = (930 - totalBinsWidth) / 2
    
    for i = 1, 5 do
        local bin = vgui.Create("DButton", gamePanel)
        bin:SetSize(binWidth, 100)
        bin:SetPos(startX + (i-1) * binSpacing, 330)
        bin:SetText("")
        bin.binType = i
        
        bin.Paint = function(self, w, h)
            local col = BinColors[i]
            
            -- Effet hover
            if self:IsHovered() then
                col = Color(math.min(col.r + 30, 255), math.min(col.g + 30, 255), math.min(col.b + 30, 255))
            end
            
            draw.RoundedBox(8, 0, 0, w, h, col)
            draw.RoundedBox(8, 2, 2, w-4, h-4, Color(math.max(col.r - 40, 0), math.max(col.g - 40, 0), math.max(col.b - 40, 0)))
            draw.SimpleText(TrashTypes[i].name, "DermaLarge", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        bin.DoClick = function(self)
            if not IsValid(currentTrashPanel) then return end
            
            local correctBin = currentTrashPanel.trashType
            
            if self.binType == correctBin then
                -- Bon tri !
                score = score + 10
                surface.PlaySound("buttons/button15.wav")
                
                -- Animation de succès
                currentTrashPanel:MoveTo(self.x + 45, self.y + 20, 0.2, 0, -1, function()
                    if IsValid(currentTrashPanel) then
                        currentTrashPanel:Remove()
                    end
                    SpawnNextTrash()
                end)
            else
                -- Mauvais tri
                score = score - 5
                surface.PlaySound("buttons/button10.wav")
                
                -- Animation d'échec
                currentTrashPanel:Remove()
                SpawnNextTrash()
            end
            
            trashCounter:SetText("Déchets: " .. currentTrash .. "/" .. totalTrash)
        end
        
        bins[i] = bin
    end
    
    -- Fonction pour créer un déchet
    function SpawnNextTrash()
        currentTrash = currentTrash + 1
        
        if currentTrash > totalTrash then
            -- Fin du jeu
            timer.Simple(0.5, function()
                if IsValid(frame) then
                    local finalScore = score
                    frame:Close()
                    
                    -- Envoyer le résultat au serveur
                    net.Start("RecyclerMinigameResult")
                    net.WriteEntity(recycler)
                    net.WriteBool(finalScore >= 50)
                    net.WriteInt(finalScore, 16)
                    net.SendToServer()
                    
                    -- Message final
                    chat.AddText(Color(0, 255, 0), "[Recycleur] ", Color(255, 255, 255), "Mini-jeu terminé ! Score: " .. finalScore)
                end
            end)
            return
        end
        
        -- Créer un nouveau déchet aléatoire
        local trashType = math.random(1, 5)
        local trash = vgui.Create("DPanel", gamePanel)
        trash:SetSize(80, 80)
        trash:SetPos(425, 120)
        trash.trashType = trashType
        
        -- Forcer le panel au premier plan
        trash:MoveToFront()
        trash:SetZPos(1000)
        
        trash.Paint = function(self, w, h)
            -- Ne pas dessiner d'ombre grise
            
            -- Déchet (cercle coloré)
            draw.RoundedBox(40, 0, 0, w, h, TrashTypes[trashType].color)
            
            -- Bordure blanche
            draw.RoundedBox(40, 2, 2, w-4, h-4, Color(255, 255, 255, 30))
            
            -- Texte du type
            draw.SimpleText(TrashTypes[trashType].name, "DermaDefault", w/2, h/2, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        currentTrashPanel = trash
        
        trashCounter:SetText("Déchets: " .. currentTrash .. "/" .. totalTrash)
        
        -- Animation d'apparition
        trash:SetAlpha(0)
        trash:AlphaTo(255, 0.3, 0)
        trash:SetSize(0, 0)
        trash:SizeTo(80, 80, 0.3, 0)
    end
    
    -- Bouton quitter
    local quitBtn = vgui.Create("DButton", frame)
    quitBtn:SetSize(100, 30)
    quitBtn:SetPos(830, 530)
    quitBtn:SetText("Quitter")
    quitBtn.DoClick = function()
        frame:Close()
    end
    
    -- Démarrer le jeu
    timer.Simple(0.5, function()
        if IsValid(frame) then
            SpawnNextTrash()
        end
    end)
end)
