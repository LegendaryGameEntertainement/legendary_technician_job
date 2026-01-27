DarkRP.createCategory{
    name = "Technician",
    categorises = "jobs",
    startExpanded = true,
    color = Color(255, 0, 0, 255),
    canSee = function(ply) return true end,
    sortOrder = 100,
}


TEAM_TECHNICIEN = DarkRP.createJob("Technicien", {
    color = Color(214, 214, 214, 255),
    model = "models/player/odessa.mdl",
    description = [[Réparer des trucs]],
    weapons = {""},
    command = "lg_technicien",
    max = 4,
    salary = 500,
    admin = 0,
    vote = false,
    category = "Technician",
    hasLicense = false
})

TEAM_FLOOR_TECHNICIEN = DarkRP.createJob("Technicien de Surface", {
    color = Color(214, 214, 214, 255),
    model = "models/player/odessa.mdl",
    description = [[Nettoyer des trucs]],
    weapons = {""},
    command = "lg_floor_technicien",
    max = 4,
    salary = 500,
    admin = 0,
    vote = false,
    category = "Technician",
    hasLicense = false
})