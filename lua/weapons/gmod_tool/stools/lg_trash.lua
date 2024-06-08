AddCSLuaFile()

TOOL.Category = "Technician Job"
TOOL.Name = "Trash Spawner"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("Tool.legendary_trash.name", "Trash Spawner")
    language.Add("Tool.legendary_trash.desc", "Create trash spots")
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local sent = ents.Create("legendary_trash")
    sent:SetPos(trace.HitPos + Vector(0, 0, 10))
    sent:Spawn()
    sent.IsHidden = false
    sent:SetNoDraw(false)

    undo.Create("Trash Spawner")
    undo.AddEntity(sent)
    undo.SetPlayer(self:GetOwner())
    undo.Finish()

    return true
end

if SERVER then return end

function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "Trash Spawner", Description = "Create trash spots" })
end

function TOOL.DrawHUD()
    for _, v in ipairs(ents.FindByClass("legendary_trash")) do
        local vec = v:GetPos():ToScreen()
        if not vec.visible then continue end
        draw.SimpleTextOutlined("X", "DermaLarge", vec.x, vec.y, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 255))
    end
end
