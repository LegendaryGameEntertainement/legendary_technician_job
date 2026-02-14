LEGENDARY_FLOOR_TECHNICIAN = LEGENDARY_FLOOR_TECHNICIAN or {}

-- Types de déchets avec leurs couleurs ET images
local TrashTypes = {
    {name = "Plastique", color = Color(255, 255, 0), bin = 1, entityClass = "lg_bac_plastique", 
     trashImage = "materials/icon/sorter/beer.png", binImage = "materials/icon/sorter/trashbin.png"},
    
    {name = "Métal", color = Color(128, 128, 128), bin = 2, entityClass = "lg_bac_metal",
     trashImage = nil, binImage = nil},
    
    {name = "Papier", color = Color(0, 128, 255), bin = 3, entityClass = "lg_bac_papier",
     trashImage = nil, binImage = nil},
    
    {name = "Organique", color = Color(255, 64, 64), bin = 4, entityClass = "lg_bac_organique",
     trashImage = nil, binImage = nil},
    
    {name = "Verre", color = Color(0, 255, 0), bin = 5, entityClass = "lg_bac_verre",
     trashImage = nil, binImage = nil}
}

local BinColors = {
    Color(255, 255, 0),
    Color(128, 128, 128),
    Color(0, 128, 255),
    Color(255, 64, 64),
    Color(0, 255, 0)
}

net.Receive("OpenSorterMinigame", function()
    local sorter = net.ReadEntity()
    if not IsValid(sorter) then return end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(950, 600)
    frame:Center()
    frame:SetTitle("Mini-jeu de Tri des Déchets")
    frame:MakePopup()
    frame:SetDraggable(false)
    
    -- Nombre total de sacs à trier
    local totalBags = sorter:GetTrashBags()
    local currentBag = 1
    local totalTrashInBag = math.random(4, 10)
    local currentTrash = 0
    local currentTrashPanel = nil
    local score = 0
    
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
    gamePanel.Paint = function(self, w, h) end
    
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
    trashCounter:SetText("Sac " .. currentBag .. "/" .. totalBags .. " - Déchets: 0/" .. totalTrashInBag)
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
    
    local function GetCurrentCount(trashType)
        if not IsValid(sorter) then return 0 end
        if trashType == 1 then return sorter:GetPlastiqueCount()
        elseif trashType == 2 then return sorter:GetMetalCount()
        elseif trashType == 3 then return sorter:GetPapierCount()
        elseif trashType == 4 then return sorter:GetOrganiqueCount()
        elseif trashType == 5 then return sorter:GetVerreCount()
        end
        return 0
    end
    
    for i = 1, 5 do
        local bin = vgui.Create("DButton", gamePanel)
        bin:SetSize(binWidth, 100)
        bin:SetPos(startX + (i-1) * binSpacing, 330)
        bin:SetText("")
        bin.binType = i
        
        -- Charger le matériau si une image est définie
        local binMat = nil
        if TrashTypes[i].binImage then
            binMat = Material(TrashTypes[i].binImage, "smooth")
        end
        
        bin.Paint = function(self, w, h)
            local col = BinColors[i]
            if self:IsHovered() then
                col = Color(math.min(col.r + 30, 255), math.min(col.g + 30, 255), math.min(col.b + 30, 255))
            end
            
            -- Si image custom existe, l'afficher
            if binMat then
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(binMat)
                surface.DrawTexturedRect(0, 0, w, h)
            else
                -- Sinon, afficher la forme géométrique colorée (fallback)
                draw.RoundedBox(8, 0, 0, w, h, col)
                draw.RoundedBox(8, 2, 2, w-4, h-4, Color(math.max(col.r - 40, 0), math.max(col.g - 40, 0), math.max(col.b - 40, 0)))
                draw.SimpleText(TrashTypes[i].name, "DermaLarge", w/2, h/2 - 10, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            -- Afficher le compteur
            local currentTotal = GetCurrentCount(i) + sortedTrash[i]
            local required = LEGENDARY_FLOOR_TECHNICIAN.TrashRequired or 20
            draw.SimpleText(currentTotal .. "/" .. required, "DermaDefault", w/2, h - 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        bin.DoClick = function(self)
            if not IsValid(currentTrashPanel) then return end
            
            local correctBin = currentTrashPanel.trashType
            
            if self.binType == correctBin then
                score = score + 10
                surface.PlaySound("buttons/button15.wav")
                sortedTrash[correctBin] = sortedTrash[correctBin] + 1
                
                local required = LEGENDARY_FLOOR_TECHNICIAN.TrashRequired or 20
                local totalCount = GetCurrentCount(correctBin) + sortedTrash[correctBin]
                
                if totalCount >= required then
                    net.Start("SorterSpawnBac")
                    net.WriteEntity(sorter)
                    net.WriteInt(correctBin, 8)
                    net.SendToServer()
                    chat.AddText(Color(0, 255, 0), "[Trieur] ", Color(255, 255, 255), "Vous avez collecté " .. required .. " déchets de ", TrashTypes[correctBin].name, " ! Un bac a été généré.")
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
            
            trashCounter:SetText("Sac " .. currentBag .. "/" .. totalBags .. " - Déchets: " .. currentTrash .. "/" .. totalTrashInBag)
        end
        
        bins[i] = bin
    end
    
    function SpawnNextTrash()
        currentTrash = currentTrash + 1
        
        -- Si on a fini le sac actuel
        if currentTrash > totalTrashInBag then
            currentBag = currentBag + 1
            
            -- Si on a fini tous les sacs, on ferme
            if currentBag > totalBags then
                timer.Simple(0.5, function()
                    if IsValid(frame) then
                        local finalScore = score
                        frame:Close()
                        
                        net.Start("SorterMinigameResult")
                        net.WriteEntity(sorter)
                        net.WriteBool(finalScore >= 50)
                        net.WriteInt(finalScore, 16)
                        net.WriteTable(sortedTrash)
                        net.SendToServer()
                        
                        chat.AddText(Color(0, 255, 0), "[Trieur] ", Color(255, 255, 255), "Tous les sacs triés ! Score total: " .. finalScore)
                    end
                end)
                return
            end
            
            -- Passer au sac suivant
            currentTrash = 1
            totalTrashInBag = math.random(4, 10)
            trashCounter:SetText("Sac " .. currentBag .. "/" .. totalBags .. " - Déchets: 0/" .. totalTrashInBag)
            
            -- Petit message de transition
            chat.AddText(Color(100, 200, 255), "[Trieur] ", Color(255, 255, 255), "Sac suivant ! (" .. currentBag .. "/" .. totalBags .. ")")
        end
        
        local trashType = math.random(1, 5)
        
        -- Charger le matériau du déchet si une image est définie
        local trashMat = nil
        if TrashTypes[trashType].trashImage then
            trashMat = Material(TrashTypes[trashType].trashImage, "smooth")
        end
        
        local trash = vgui.Create("DPanel", gamePanel)
        trash:SetSize(80, 80)
        trash:SetPos(425, 120)
        trash.trashType = trashType
        trash:MoveToFront()
        trash:SetZPos(1000)
        
        trash.Paint = function(self, w, h)
            if trashMat then
                -- Afficher l'image custom
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(trashMat)
                surface.DrawTexturedRect(0, 0, w, h)
            else
                -- Fallback : forme géométrique colorée
                draw.RoundedBox(40, 0, 0, w, h, TrashTypes[trashType].color)
                draw.RoundedBox(40, 2, 2, w-4, h-4, Color(255, 255, 255, 30))
                draw.SimpleText(TrashTypes[trashType].name, "DermaDefault", w/2, h/2, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        
        currentTrashPanel = trash
        trashCounter:SetText("Sac " .. currentBag .. "/" .. totalBags .. " - Déchets: " .. currentTrash .. "/" .. totalTrashInBag)
        
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
