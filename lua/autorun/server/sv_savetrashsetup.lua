local allowedGroups = {
    ["superadmin"] = true,
    ["admin"] = true,
}

local function SaveTrashSetup()
    local file = file.Open("legendary_trash_positions.txt", "w", "DATA")

    if not file then
        print("Impossible d'ouvrir le fichier de sauvegarde.")
        return
    end

    local entities = ents.FindByClass("legendary_trash")

    for _, ent in pairs(entities) do
        local pos = ent:GetPos()

        file:Write("Position de l'entité: X=" .. pos.x .. ", Y=" .. pos.y .. ", Z=" .. pos.z .. "\n")
    end

    
    file:Close()

    print("Toutes les positions des entités 'legendary_trash' ont été sauvegardées avec succès.")
end
concommand.Add("save_trashsetup", SaveTrashSetup)

local function DeleteTrashSetup(ply, cmd, args)
    -- Vérifier si la commande est exécutée depuis la console du serveur
    if ply:IsPlayer() then
        print("Cette commande doit être exécutée dans la console du serveur.")
        return
    end

    -- Ouvrir le fichier de sauvegarde en mode écriture (écraser s'il existe déjà)
    local file = file.Open("legendary_trash_positions.txt", "w", "DATA")

    if not file then
        print("Impossible d'ouvrir le fichier de sauvegarde.")
        return
    end

    -- Écrire une chaîne vide dans le fichier pour effacer son contenu
    file:Write("")

    -- Fermer le fichier de sauvegarde
    file:Close()

    -- Récupérer toutes les entités sur la carte
    local entities = ents.FindByClass("legendary_trash")

    -- Parcourir toutes les entités
    for _, ent in pairs(entities) do
        -- Supprimer l'entité
        ent:Remove()
    end

    -- Informer que toutes les entités "legendary_trash" ont été supprimées avec succès
    print("Toutes les entités 'legendary_trash' et leurs positions ont été supprimées avec succès.")
end

-- Ajouter la commande au serveur
concommand.Add("delete_trashsetup", DeleteTrashSetup)





-- Fonction pour charger les positions des entités "legendary_trash" à partir du fichier de sauvegarde
local function LoadTrashSetup()
    -- Ouvrir le fichier de sauvegarde en mode lecture
    local file = file.Open("legendary_trash_positions.txt", "r", "DATA")

    if not file then
        print("Impossible d'ouvrir le fichier de sauvegarde pour le chargement.")
        return
    end

    -- Lire le fichier ligne par ligne
    local line = file:ReadLine()
    while line do
        -- Analyser la ligne pour récupérer les coordonnées X, Y et Z
        local x, y, z = line:match("Position de l'entité: X=(%-?%d+%.?%d*), Y=(%-?%d+%.?%d*), Z=(%-?%d+%.?%d*)")

        -- Créer une nouvelle entité legendary_trash à la position spécifiée
        local ent = ents.Create("legendary_trash")
        ent:SetPos(Vector(tonumber(x), tonumber(y), tonumber(z)))
        ent:Spawn()

        -- Lire la ligne suivante
        line = file:ReadLine()
    end

    -- Fermer le fichier de sauvegarde
    file:Close()

    -- Informer que toutes les positions des entités "legendary_trash" ont été chargées avec succès
    print("Toutes les positions des entités 'legendary_trash' ont été chargées avec succès.")
end

-- Attacher la fonction LoadTrashSetup au hook InitPostEntity
hook.Add("InitPostEntity", "LoadTrashSetup", LoadTrashSetup)
