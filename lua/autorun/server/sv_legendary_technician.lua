util.AddNetworkString("legendary_technician_repair")
util.AddNetworkString("legendary_technician_togglehud")

hook.Add("OnPlayerChangedTeam", "legendary_technician_timer", function(ply, beforeNum, afterNum)
    --switch to technician
    if RPExtraTeams[afterNum].name == LEGENDARY_TECHNICIAN_JOBNAME then
        net.Start("legendary_technician_togglehud")
        net.WriteBool(true)
        net.Send(ply)
    end
    --switch from technician
    if RPExtraTeams[beforeNum].name == LEGENDARY_TECHNICIAN_JOBNAME then
        net.Start("legendary_technician_togglehud")
        net.WriteBool(false)
        net.Send(ply)
    end
end)

hook.Add("InitPostEntity", "legendary_technician_breaker", function()
    timer.Create("legendary_technician_breaker",LEGENDARY_TECHNICIAN_BREAK_DELAY,0,function()
        local ents = ents.FindByClass( "legendary_tec*" )
        local randomEnt = ents[math.random(#ents)]
        if randomEnt and IsValid(randomEnt) and not randomEnt:GetBroken() then
            randomEnt:SetBroken(true)
            print("[legendary_technician] Sabotaged a random object!")
            hook.Run("LegendaryTechnicianBroke",randomEnt)
        end
    end)
    print("[legendary_technician] Timer created!")
end)

print("[legendary_technician] sv loaded")
