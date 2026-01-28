-- Système de pannes aléatoires
hook.Add("Think", "LG_RandomBreakdownSystem", function()
    if not LEGENDARY_TECHNICIAN or not LEGENDARY_TECHNICIAN.Breakdown then return end
    
    -- Vérifier s'il y a au moins un technicien en ligne
    local hasTechnician = false
    for _, ply in pairs(player.GetAll()) do
        local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
        
        if techTeam then
            if type(techTeam) == "number" and ply:Team() == techTeam then
                hasTechnician = true
                break
            elseif type(techTeam) == "string" and ply.getDarkRPVar and ply:getDarkRPVar("job") == techTeam then
                hasTechnician = true
                break
            end
        end
    end
    
    if not hasTechnician then
        -- Pas de technicien, pas de pannes
        LEGENDARY_TECHNICIAN.NextBreakdownTime = CurTime() + 30
        return
    end
    
    -- Vérifier si c'est le moment de créer une panne
    if CurTime() >= LEGENDARY_TECHNICIAN.NextBreakdownTime then
        local config = LEGENDARY_TECHNICIAN.Breakdown
        local entities = LEGENDARY_TECHNICIAN.BreakdownEntities or {}
        
        -- Filtrer les entités valides et non en panne
        local availableEntities = {}
        for _, ent in pairs(entities) do
            if IsValid(ent) and not ent:GetIsBroken() then
                table.insert(availableEntities, ent)
            end
        end
        
        if #availableEntities > 0 then
            -- Choisir une entité aléatoire
            local randomEntity = availableEntities[math.random(#availableEntities)]
            randomEntity:MakeBreakdown()
            
            print("[SYSTÈME DE PANNES] Panne déclenchée sur " .. tostring(randomEntity))
        end
        
        -- Programmer la prochaine panne
        local nextInterval = math.random(config.MinInterval, config.MaxInterval)
        LEGENDARY_TECHNICIAN.NextBreakdownTime = CurTime() + nextInterval
        
        print("[SYSTÈME DE PANNES] Prochaine panne dans " .. nextInterval .. " secondes")
    end
end)

-- Initialiser le timer au démarrage
hook.Add("Initialize", "LG_InitBreakdownSystem", function()
    if LEGENDARY_TECHNICIAN and LEGENDARY_TECHNICIAN.Breakdown then
        local config = LEGENDARY_TECHNICIAN.Breakdown
        LEGENDARY_TECHNICIAN.NextBreakdownTime = CurTime() + math.random(config.MinInterval, config.MaxInterval)
    end
end)
