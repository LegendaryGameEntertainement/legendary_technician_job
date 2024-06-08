DarkRP.createCategory{
    name = "Technician",
    categorises = "jobs",
    startExpanded = true,
    color = Color(255, 0, 0, 255),
    canSee = function(ply) return true end,
    sortOrder = 100,
}


TEAM_FLOOR_TECHNICIAN = DarkRP.createJob("Floor Technician", {
    color = Color(214, 214, 214, 255),
    model = "models/player/odessa.mdl",
    description = [[Vous nettoyer la ville. ]],
    weapons = {"lg_broom"},
    command = "lg_floortechnician",
    max = 4,
    salary = 500,
    admin = 0,
    vote = false,
    category = "Technician",
    hasLicense = false
})

TEAM_TECHNICIAN = DarkRP.createJob("Technician", {
        color = Color(214, 214, 214, 255),
        model = "models/player/odessa.mdl",
        description = [[Repair broken equipment and earn money! ]],
        weapons = {},
        command = "lg_technician",
        max = 2,
        salary = 500,
        admin = 0,
        vote = false,
        hasLicense = false,
        candemote = true,
        category = "Technician"
    })
