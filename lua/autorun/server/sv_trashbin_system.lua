if CLIENT then return end

LEGENDARY_FLOOR_TECHNICIAN = LEGENDARY_FLOOR_TECHNICIAN or {}
LEGENDARY_FLOOR_TECHNICIAN.TrashBins = LEGENDARY_FLOOR_TECHNICIAN.TrashBins or {}

print("[FLOOR TECHNICIAN] Système de poubelles chargé")

-- Timer pour remplir les poubelles automatiquement
timer.Create("LG_FillTrashBins", 10, 0, function() -- Démarre après 10 secondes
    -- Attendre que la config soit chargée
    if not LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillTime then
        print("[POUBELLE SYSTEM] Config pas encore chargée, attente...")
        return
    end
    
    -- Recréer le timer avec le bon intervalle
    timer.Remove("LG_FillTrashBins")
    
    local fillTime = LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillTime or 300
    print("[POUBELLE SYSTEM] Timer configuré : remplissage toutes les " .. fillTime .. " secondes")
    
    timer.Create("LG_FillTrashBins", fillTime, 0, function()
        local bins = LEGENDARY_FLOOR_TECHNICIAN.TrashBins or {}
        local emptyBins = {}
        local fullCount = 0
        local totalBins = 0
        
        -- Compter les poubelles vides et pleines
        for i, bin in pairs(bins) do
            if IsValid(bin) then
                totalBins = totalBins + 1
                if bin:GetIsFull() then
                    fullCount = fullCount + 1
                else
                    table.insert(emptyBins, bin)
                end
            else
                -- Nettoyer les références invalides
                table.remove(bins, i)
            end
        end
        
        print("[POUBELLE SYSTEM] État : " .. totalBins .. " poubelles total, " .. fullCount .. " pleines, " .. #emptyBins .. " vides")
        
        -- Vérifier qu'on ne dépasse pas le maximum
        local maxFull = LEGENDARY_FLOOR_TECHNICIAN.MaxFullTrashBins or 5
        local canFill = maxFull - fullCount
        
        if canFill <= 0 then
            print("[POUBELLE SYSTEM] Maximum de poubelles pleines atteint (" .. maxFull .. ")")
            return
        end
        
        if #emptyBins == 0 then
            print("[POUBELLE SYSTEM] Aucune poubelle vide disponible")
            return
        end
        
        -- Remplir aléatoirement des poubelles
        local fillChance = LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillChance or 0.3
        local filled = 0
        
        for _, bin in pairs(emptyBins) do
            if filled >= canFill then break end
            
            if math.random() < fillChance then
                if bin:MakeFull() then
                    filled = filled + 1
                end
            end
        end
        
        if filled > 0 then
            print("[POUBELLE SYSTEM] ✓ " .. filled .. " poubelle(s) remplie(s)")
        else
            print("[POUBELLE SYSTEM] Aucune poubelle remplie ce cycle (chance: " .. (fillChance * 100) .. "%)")
        end
    end)
end)

-- Commande admin pour forcer le remplissage (utile pour les tests)
concommand.Add("lg_fill_trashbins", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[Technicien] Vous devez être administrateur !")
        return
    end
    
    local count = tonumber(args[1]) or 1
    local bins = LEGENDARY_FLOOR_TECHNICIAN.TrashBins or {}
    local filled = 0
    
    for _, bin in pairs(bins) do
        if filled >= count then break end
        if IsValid(bin) and not bin:GetIsFull() then
            bin:MakeFull()
            filled = filled + 1
        end
    end
    
    local msg = "[Technicien] " .. filled .. " poubelle(s) forcée(s) à plein"
    if IsValid(ply) then
        ply:ChatPrint(msg)
    else
        print(msg)
    end
end)

-- Commande pour afficher l'état du système
concommand.Add("lg_trashbin_status", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("[Technicien] Vous devez être administrateur !")
        return
    end
    
    local bins = LEGENDARY_FLOOR_TECHNICIAN.TrashBins or {}
    local fullCount = 0
    local emptyCount = 0
    
    for _, bin in pairs(bins) do
        if IsValid(bin) then
            if bin:GetIsFull() then
                fullCount = fullCount + 1
            else
                emptyCount = emptyCount + 1
            end
        end
    end
    
    local msg = string.format(
        "[Technicien] Poubelles : %d total | %d pleines | %d vides | Max: %d | Intervalle: %ds | Chance: %.0f%%",
        fullCount + emptyCount,
        fullCount,
        emptyCount,
        LEGENDARY_FLOOR_TECHNICIAN.MaxFullTrashBins or 5,
        LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillTime or 300,
        (LEGENDARY_FLOOR_TECHNICIAN.TrashBinFillChance or 0.3) * 100
    )
    
    if IsValid(ply) then
        ply:ChatPrint(msg)
    else
        print(msg)
    end
end)

print("[FLOOR TECHNICIAN] Commandes disponibles : lg_fill_trashbins [nombre], lg_trashbin_status")
