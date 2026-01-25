-- Types de déchets avec leurs couleurs
local TrashTypes = {
    {name = "Plastique", color = Color(255, 255, 0), bin = 1, entityClass = "lg_bac_plastique"},
    {name = "Métal", color = Color(128, 128, 128), bin = 2, entityClass = "lg_bac_metal"},
    {name = "Papier", color = Color(0, 128, 255), bin = 3, entityClass = "lg_bac_papier"},
    {name = "Organique", color = Color(255, 64, 64), bin = 4, entityClass = "lg_bac_organique"},
    {name = "Verre", color = Color(0, 255, 0), bin = 5, entityClass = "lg_bac_verre"}
}

local BinColors = {
    Color(255, 255, 0),
    Color(128, 128, 128),
    Color(0, 128, 255),
    Color(255, 64, 64),
    Color(0, 255, 0)
}

net.Receive("OpenRecyclerMinigame", function()
    local recycler = net.ReadEntity()
    if not IsValid(recycler) then return end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(950, 600)
    frame:Center()
    frame:SetTitle("Mini-jeu de Tri des Déchets")
    frame:MakePopup()
    frame:SetDraggable(false)
    
    local totalTrash = math.random(4, 10)
    local currentTrash = 0
    local currentTrashPanel = nil
    local score = 0
    
    -- Récupérer les compteurs actuels du recycleur
    local sortedTrash = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0
    }
    
    local gamePanel = vgui.Create("DPanel", frame)
    gamePanel:SetPos(10, 40)
    gamePanel:SetSize(930, 450)
    gamePanel.Paint = function(self, w, h)
    end
    
    local oldFramePaint = frame.Paint
    frame.Paint = function(self, w, h)
        if oldFramePaint then
            oldFramePaint(self, w, h)
        end
        
        draw.RoundedBox(0, 10, 40, 930, 450, Color(180, 180, 180))
    end
    
    local trashCounter = vgui.Create("DLabel", frame)
    trashCounter:SetPos(10, 500)
    trashCounter:SetSize(930, 30)
    trashCounter:SetFont("DermaLarge")
    trashCounter:SetText("Déchets: 0/" .. totalTrash)
    trashCounter:SetContentAlignment(5)
    
    local instructionLabel = vgui.Create("DLabel", frame)
    instructionLabel:SetPos(10, 530)
    instructionLabel:SetSize(930, 30)
    instructionLabel:SetFont("DermaDefault")
    instructionLabel:SetText("Clique sur la poubelle de la bonne couleur pour y jeter le déchet !")
    instructionLabel:SetContentAlignment(5)
    
    local bins = {}
    local binWidth = 150
    local binSpacing = 170
    local totalBinsWidth = (binWidth * 5) + (binSpacing - binWidth) * 4
    local startX = (930 - totalBinsWidth) / 2
    
    -- Fonctions pour obtenir les compteurs actuels
    local function GetCurrentCount(trashType)
        if not IsValid(recycler) then return 0 end
        
        if trashType == 1 then return recycler:GetPlastiqueCount()
        elseif trashType == 2 then return recycler:GetMetalCount()
        elseif trashType == 3 then return recycler:GetPapierCount()
        elseif trashType == 4 then return recycler:GetOrganiqueCount()
        elseif trashType == 5 then return recycler:GetVerreCount()
        end
        
        return 0
    end
    
    for i = 1, 5 do
        local bin = vgui.Create("DButton", gamePanel)
        bin:SetSize(binWidth, 100)
        bin:SetPos(startX + (i-1) * binSpacing, 330)
        bin:SetText("")
        bin.binType = i
        
        bin.Paint = function(self, w, h)
            local col = BinColors[i]
            
            if self:IsHovered() then
                col = Color(math.min(col.r + 30, 255), math.min(col.g + 30, 255), math.min(col.b + 30, 255))
            end
            
            draw.RoundedBox(8, 0, 0, w, h, col)
            draw.RoundedBox(8, 2, 2, w-4, h-4, Color(math.max(col.r - 40, 0), math.max(col.g - 40, 0), math.max(col.b - 40, 0)))
            draw.SimpleText(TrashTypes[i].name, "DermaLarge", w/2, h/2 - 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Afficher le compteur total (recycleur + cette partie)
            local currentTotal = GetCurrentCount(i) + sortedTrash[i]
            draw.SimpleText(currentTotal .. "/20", "DermaDefault", w/2, h/2 + 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        bin.DoClick = function(self)
            if not IsValid(currentTrashPanel) then return end
            
            local correctBin = currentTrashPanel.trashType
            
            if self.binType == correctBin then
                score = score + 10
                surface.PlaySound("buttons/button15.wav")
                
                sortedTrash[correctBin] = sortedTrash[correctBin] + 1
                
                -- Vérifier si on atteint 20 avec le total (recycleur + cette partie)
                local totalCount = GetCurrentCount(correctBin) + sortedTrash[correctBin]
                if totalCount >= 20 then
                    net.Start("RecyclerSpawnBac")
                    net.WriteEntity(recycler)
                    net.WriteInt(correctBin, 8)
                    net.SendToServer()
                    
                    chat.AddText(Color(0, 255, 0), "[Recycleur] ", Color(255, 255, 255), "Vous avez collecté 20 déchets de ", TrashTypes[correctBin].name, " ! Un bac a été généré.")
                end
                
                currentTrashPanel:MoveTo(self.x + 45, self.y + 20, 0.2, 0, -1, function()
                    if IsValid(currentTrashPanel) then
                        currentTrashPanel:Remove()
                    end
                    SpawnNextTrash()
                end)
            else
                score = score - 5
                surface.PlaySound("buttons/button10.wav")
                
                currentTrashPanel:Remove()
                SpawnNextTrash()
            end
            
            trashCounter:SetText("Déchets: " .. currentTrash .. "/" .. totalTrash)
        end
        
        bins[i] = bin
    end
    
    function SpawnNextTrash()
        currentTrash = currentTrash + 1
        
        if currentTrash > totalTrash then
            timer.Simple(0.5, function()
                if IsValid(frame) then
                    local finalScore = score
                    frame:Close()
                    
                    net.Start("RecyclerMinigameResult")
                    net.WriteEntity(recycler)
                    net.WriteBool(finalScore >= 50)
                    net.WriteInt(finalScore, 16)
                    net.WriteTable(sortedTrash)
                    net.SendToServer()
                    
                    chat.AddText(Color(0, 255, 0), "[Recycleur] ", Color(255, 255, 255), "Mini-jeu terminé ! Score: " .. finalScore)
                end
            end)
            return
        end
        
        local trashType = math.random(1, 5)
        local trash = vgui.Create("DPanel", gamePanel)
        trash:SetSize(80, 80)
        trash:SetPos(425, 120)
        trash.trashType = trashType
        
        trash:MoveToFront()
        trash:SetZPos(1000)
        
        trash.Paint = function(self, w, h)
            draw.RoundedBox(40, 0, 0, w, h, TrashTypes[trashType].color)
            draw.RoundedBox(40, 2, 2, w-4, h-4, Color(255, 255, 255, 30))
            draw.SimpleText(TrashTypes[trashType].name, "DermaDefault", w/2, h/2, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        currentTrashPanel = trash
        
        trashCounter:SetText("Déchets: " .. currentTrash .. "/" .. totalTrash)
        
        trash:SetAlpha(0)
        trash:AlphaTo(255, 0.3, 0)
        trash:SetSize(0, 0)
        trash:SizeTo(80, 80, 0.3, 0)
    end
    
    local quitBtn = vgui.Create("DButton", frame)
    quitBtn:SetSize(100, 30)
    quitBtn:SetPos(830, 530)
    quitBtn:SetText("Quitter")
    quitBtn.DoClick = function()
        frame:Close()
    end
    
    timer.Simple(0.5, function()
        if IsValid(frame) then
            SpawnNextTrash()
        end
    end)
end)
