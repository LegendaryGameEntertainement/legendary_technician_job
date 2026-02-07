AddCSLuaFile("shared.lua")
include("shared.lua")

function SWEP:Initialize()
    self:SetHoldType("melee")
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    self:SetNextPrimaryFire(CurTime() + 1)
    
    local tr = ply:GetEyeTrace()
    
    -- Trouver la fuite la plus proche
    local closestID = nil
    local closestDist = 150
    
    for id, leakData in ipairs(LEGENDARY_TECHNICIAN.LeakPositions or {}) do
        local dist = tr.HitPos:Distance(leakData.pos)
        if dist < closestDist then
            closestID = id
            closestDist = dist
        end
    end
    
    if not closestID then
        ply:ChatPrint("[Pince] Aucune fuite détectée à proximité.")
        return
    end
    
    -- Vérifier si la fuite est active
    if not LEGENDARY_TECHNICIAN.ActiveLeaks[closestID] then
        ply:ChatPrint("[Pince] Cette fuite n'est pas active actuellement.")
        return
    end
    
    -- Vérifier le job
    if not self:IsCorrectJob(ply) then
        ply:ChatPrint("[Pince] Vous devez être technicien pour réparer !")
        return
    end
    
    -- Démarrer la réparation
    self:StartRepair(ply, closestID)
end

function SWEP:StartRepair(ply, leakID)
    local leakData = LEGENDARY_TECHNICIAN.LeakPositions[leakID]
    if not leakData then return end
    
    local config = leakData.type == "water" and LEGENDARY_TECHNICIAN.LeakConfig.Water or LEGENDARY_TECHNICIAN.LeakConfig.Gas
    
    ply:ChatPrint("[Pince] Réparation en cours... (" .. config.RepairTime .. "s)")
    
    ply:SetNWBool("LG_IsRepairing", true)
    ply:SetNWInt("LG_RepairingLeakID", leakID)
    ply:SetNWFloat("LG_RepairStartTime", CurTime())
    
    timer.Create("LG_RepairLeak_" .. ply:SteamID64(), config.RepairTime, 1, function()
        if not IsValid(ply) then return end
        
        -- Vérifier que le joueur est toujours en train de réparer
        if not ply:GetNWBool("LG_IsRepairing") then
            return
        end
        
        -- Vérifier la distance
        if ply:GetPos():Distance(leakData.pos) > 200 then
            ply:ChatPrint("[Pince] Vous vous êtes trop éloigné !")
            ply:SetNWBool("LG_IsRepairing", false)
            return
        end
        
        -- Réparer directement côté serveur
        LEGENDARY_TECHNICIAN.RepairLeak(leakID, ply)
        
        ply:SetNWBool("LG_IsRepairing", false)
    end)
end

function SWEP:Think()
    if CLIENT then return end
    
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    
    -- Vérifier si le joueur est en train de réparer
    if ply:GetNWBool("LG_IsRepairing") then
        local leakID = ply:GetNWInt("LG_RepairingLeakID")
        local leakData = LEGENDARY_TECHNICIAN.LeakPositions[leakID]
        
        if leakData then
            local distance = ply:GetPos():Distance(leakData.pos)
            
            -- Si trop loin, annuler la réparation
            if distance > 200 then
                ply:SetNWBool("LG_IsRepairing", false)
                ply:ChatPrint("[Pince] ✗ Réparation annulée - trop éloigné !")
                timer.Remove("LG_RepairLeak_" .. ply:SteamID64())
            end
        end
    end
    
    self:NextThink(CurTime() + 0.5)
    return true
end

function SWEP:IsCorrectJob(ply)
    if not DarkRP then return false end
    
    local techTeam = LEGENDARY_TECHNICIAN.ElectricianTeam
    if not techTeam then return false end
    
    if type(techTeam) == "number" then
        return ply:Team() == techTeam
    elseif type(techTeam) == "string" then
        if not ply.getDarkRPVar then return false end
        return ply:getDarkRPVar("job") == techTeam
    end
    
    return false
end

function SWEP:SecondaryAttack()
    return false
end

function SWEP:Holster()
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    if IsValid(ply) and ply:GetNWBool("LG_IsRepairing") then
        ply:SetNWBool("LG_IsRepairing", false)
        ply:ChatPrint("[Pince] ✗ Réparation annulée - changement d'arme !")
        timer.Remove("LG_RepairLeak_" .. ply:SteamID64())
    end
    return true
end
