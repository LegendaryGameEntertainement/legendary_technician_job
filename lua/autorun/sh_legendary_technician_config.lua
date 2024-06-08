--The name of the technician job, must be correct or the job won't work!
LEGENDARY_TECHNICIAN_JOBNAME = "Technician"
--Delay between things breaking
LEGENDARY_TECHNICIAN_BREAK_DELAY = 10
--Reward (=money gained) is random between these 2 numbers:
LEGENDARY_TECHNICIAN_MIN_REWARD = 1000
LEGENDARY_TECHNICIAN_MAX_REWARD = 2000

LEGENDARY_CLEANER_RESPAWN_DELAY = 10

if SERVER then
    --Reward players for doing cleanup
    hook.Add("LegendaryCleanDone","reward",function(ply,ent)
        ply:addMoney(30)
        DarkRP.notify(ply,0,5,"[cleaner] +30$")
    end)
end


print("[legendary_technician] config loaded")
