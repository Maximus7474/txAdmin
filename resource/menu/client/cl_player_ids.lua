-- Prevent running if menu is disabled
if not TX_MENU_ENABLED then return end

-- =============================================
--  This file contains all overhead player ID logic
-- =============================================

local BLIP_SPRITE <const> = 1
local BLIP_COLOR <const>  = 0
local BLIP_SCALE <const>  = 0.8

-- Variables
local isPlayerIdsEnabled = false
local playerGamerTags = {}
local playerEntities = {}
local distanceToCheck = GetConvarInt('txAdmin-menuPlayerIdDistance', 150)

-- Game consts
local fivemGamerTagCompsEnum = {
    GamerName = 0,
    CrewTag = 1,
    HealthArmour = 2,
    BigText = 3,
    AudioIcon = 4,
    UsingMenu = 5,
    PassiveMode = 6,
    WantedStars = 7,
    Driver = 8,
    CoDriver = 9,
    Tagged = 12,
    GamerNameNearby = 13,
    Arrow = 14,
    Packages = 15,
    InvIfPedIsFollowing = 16,
    RankText = 17,
    Typing = 18
}

local redmGamerTagCompsEnum = {
    none = 0,
    icon = 1,
    simple = 2,
    complex = 3
}
local redmSpeakerIconHash = GetHashKey('SPEAKER')
local redmColorYellowHash = GetHashKey('COLOR_YELLOWSTRONG')

--- Removes all cached tags
local function cleanAllGamerTags()
    debugPrint('Cleaning up gamer tags table and blips')
    for _, v in pairs(playerGamerTags) do
        if IsMpGamerTagActive(v.gamerTag) then
            if IS_FIVEM then
                RemoveMpGamerTag(v.gamerTag)
            else
                Citizen.InvokeNative(0x839BFD7D7E49FE09, Citizen.PointerValueIntInitialized(v.gamerTag));
            end
        end
    end
    playerGamerTags = {}

    for id, data in pairs(playerEntities) do
        if data.blipHandle and DoesBlipExist(data.blipHandle) then
            RemoveBlip(data.blipHandle)
        end
    end
    playerEntities = {}
end


--- Draws a single gamer tag (fivem)
local function setGamerTagFivem(targetTag, pid)
    -- Setup name
    SetMpGamerTagVisibility(targetTag, fivemGamerTagCompsEnum.GamerName, 1)

    -- Setup Health
    SetMpGamerTagHealthBarColor(targetTag, 129)
    SetMpGamerTagAlpha(targetTag, fivemGamerTagCompsEnum.HealthArmour, 255)
    SetMpGamerTagVisibility(targetTag, fivemGamerTagCompsEnum.HealthArmour, 1)

    -- Setup AudioIcon
    SetMpGamerTagAlpha(targetTag, fivemGamerTagCompsEnum.AudioIcon, 255)
    if NetworkIsPlayerTalking(pid) then
        SetMpGamerTagVisibility(targetTag, fivemGamerTagCompsEnum.AudioIcon, true)
        SetMpGamerTagColour(targetTag, fivemGamerTagCompsEnum.AudioIcon, 12) --HUD_COLOUR_YELLOW
        SetMpGamerTagColour(targetTag, fivemGamerTagCompsEnum.GamerName, 12) --HUD_COLOUR_YELLOW
    else
        SetMpGamerTagVisibility(targetTag, fivemGamerTagCompsEnum.AudioIcon, false)
        SetMpGamerTagColour(targetTag, fivemGamerTagCompsEnum.AudioIcon, 0)
        SetMpGamerTagColour(targetTag, fivemGamerTagCompsEnum.GamerName, 0)
    end
end

---Generates or updates a blip for a specific player
---@param entityData { coords: vector3; health: number; blipHandle: nil|number; name: string }
---@param targetPed nil|number
local function updatePlayerBlip(playerId, entityData, targetPed)
    if targetPed and DoesEntityExist(targetPed) then
        if entityData.blipHandle and DoesBlipExist(entityData.blipHandle) then
            if GetBlipInfoIdType(entityData.blipHandle) ~= 1 then
                RemoveBlip(entityData.blipHandle)
                entityData.blipHandle = nil
            end
        end
    end

    if not entityData.blipHandle or not DoesBlipExist(entityData.blipHandle) then
        local blip
        if targetPed and DoesEntityExist(targetPed) then
            blip = AddBlipForEntity(targetPed)
            ShowHeadingIndicatorOnBlip(blip, true)
        else
            blip = AddBlipForCoord(entityData.coords.x, entityData.coords.y, entityData.coords.z)
        end

        SetBlipSprite(blip, BLIP_SPRITE)
        SetBlipColour(blip, BLIP_COLOR)
        SetBlipScale(blip, BLIP_SCALE)
        SetBlipCategory(blip, 7)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(entityData.name or ("Player " .. tostring(playerId)))
        EndTextCommandSetBlipName(blip)

        entityData.blipHandle = blip
    else
        if not targetPed or not DoesEntityExist(targetPed) then
            SetBlipCoords(entityData.blipHandle, entityData.coords.x, entityData.coords.y, entityData.coords.z)
        end
    end

    if entityData.health <= 0 then
        SetBlipColour(entityData.blipHandle, 55)
    else
        SetBlipColour(entityData.blipHandle, BLIP_COLOR)
    end
end

--- Clears a single gamer tag (fivem)
local function clearGamerTagFivem(targetTag)
    -- Cleanup name
    SetMpGamerTagVisibility(targetTag, fivemGamerTagCompsEnum.GamerName, 0)
    -- Cleanup Health
    SetMpGamerTagVisibility(targetTag, fivemGamerTagCompsEnum.HealthArmour, 0)
    -- Cleanup AudioIcon
    SetMpGamerTagVisibility(targetTag, fivemGamerTagCompsEnum.AudioIcon, 0)
end


--- Draws a single gamer tag (redm)
local function setGamerTagRedm(targetTag, pid)
    Citizen.InvokeNative(0x93171DDDAB274EB8, targetTag, redmGamerTagCompsEnum.complex) --SetMpGamerTagVisibility
    if MumbleIsPlayerTalking(pid) then
        Citizen.InvokeNative(0x95384C6CE1526EFF, targetTag, redmSpeakerIconHash)       --SetMpGamerTagSecondaryIcon
        Citizen.InvokeNative(0x84BD27DDF9575816, targetTag, redmColorYellowHash)       --SetMpGamerTagColour
    else
        Citizen.InvokeNative(0x95384C6CE1526EFF, targetTag, nil)                       --SetMpGamerTagSecondaryIcon
        Citizen.InvokeNative(0x84BD27DDF9575816, targetTag, 0)                         --SetMpGamerTagColour
    end
end

--- Clears a single gamer tag (redm)
local function clearGamerTagRedm(targetTag)
    Citizen.InvokeNative(0x93171DDDAB274EB8, targetTag, redmGamerTagCompsEnum.none) --SetMpGamerTagVisibility
end


--- Setting game-specific functions
local setGamerTagFunc = IS_FIVEM and setGamerTagFivem or setGamerTagRedm
local clearGamerTagFunc = IS_FIVEM and clearGamerTagFivem or clearGamerTagRedm

--- Loops through every player, checks distance and draws or hides the tag
local function showGamerTags()
    local myPid = PlayerPedId()
    local curCoords = GetEntityCoords(myPid)
    local allActivePlayers = GetActivePlayers()
    local localActiveServerIds = {}

    for _, pid in ipairs(allActivePlayers) do
        local targetPed = GetPlayerPed(pid)
        local serverId = GetPlayerServerId(pid)
        localActiveServerIds[serverId] = true

        -- If we have not yet indexed this player or their tag has somehow disappeared
        if
            not playerGamerTags[pid]
            or playerGamerTags[pid].ped ~= targetPed
            or not IsMpGamerTagActive(playerGamerTags[pid].gamerTag)
        then
            local playerStr = playerEntities[serverId] and playerEntities[serverId].name or (
                '[' .. GetPlayerServerId(pid) .. ']' .. ' ' .. string.sub(
                    GetPlayerName(serverId) or 'unknown', 1, 75
                )
            )

            playerGamerTags[pid] = {
                gamerTag = CreateFakeMpGamerTag(targetPed, playerStr, false, false, 0),
                ped = targetPed
            }
        end
        local targetTag = playerGamerTags[pid].gamerTag

        -- Distance Check for overhead tags
        local targetPedCoords = GetEntityCoords(targetPed)
        if #(targetPedCoords - curCoords) <= distanceToCheck then
            setGamerTagFunc(targetTag, pid)
        else
            clearGamerTagFunc(targetTag)
        end

        if myPid ~= targetPed then
            if not playerEntities[serverId] then
                playerEntities[serverId] = {
                    coords = targetPedCoords,
                    health = GetEntityHealth(targetPed),
                    blipHandle = nil
                }
            else
                playerEntities[serverId].coords = targetPedCoords
                playerEntities[serverId].health = GetEntityHealth(targetPed)
            end

            updatePlayerBlip(serverId, playerEntities[serverId], targetPed)
        end
    end

    for id, data in pairs(playerEntities) do
        if not localActiveServerIds[id] then
            updatePlayerBlip(id, data, nil)
        end
    end
end

--- Starts the gamer tag thread
--- Increasing/decreasing the delay realistically only reflects on the
--- delay for the VOIP indicator icon, 250 is fine
local function createGamerTagThread()
    debugPrint('Starting gamer tag thread')
    CreateThread(function()
        while isPlayerIdsEnabled do
            showGamerTags()
            Wait(250)
        end

        -- Remove all gamer tags and clear out active table
        cleanAllGamerTags()
    end)
end


--- Function to enable or disable the player ids
function toggleShowPlayerIDs(enabled, showNotification)
    if not menuIsAccessible then return end

    isPlayerIdsEnabled = enabled
    local snackMessage
    if isPlayerIdsEnabled then
        snackMessage = 'nui_menu.page_main.player_ids.alert_show'
        createGamerTagThread()
    else
        snackMessage = 'nui_menu.page_main.player_ids.alert_hide'
    end

    if showNotification then
        sendSnackbarMessage('info', snackMessage, true)
    end
    debugPrint('Show Player IDs Status: ' .. tostring(isPlayerIdsEnabled))
end

--- Receives the return from the server and toggles player ids on/off
RegisterNetEvent('txcl:showPlayerIDs', function(enabled)
    debugPrint('Received showPlayerIDs event')
    toggleShowPlayerIDs(enabled, true)
end)

RegisterNetEvent('txcl:playerBlipsUpdate', function (payload)
    debugPrint('Received playerBlipsUpdate event')

    local newPlayerEntities = {}

    for i = 1, #payload do
        local data = payload[i]
        local playerId = data[1]

        newPlayerEntities[playerId] = {
            coords = vector3(data[2], data[3], data[4]),
            health = data[5],
            name = data[6]
        }
    end

    for playerId, data in pairs(newPlayerEntities) do
        if playerEntities[playerId] then
            playerEntities[playerId].coords = data.coords
            playerEntities[playerId].health = data.health
        else
            playerEntities[playerId] = {
                coords = data.coords,
                health = data.health,
                blipHandle = nil,
                name = data.name
            }
        end
    end

    for playerId, entityData in pairs(playerEntities) do
        if not newPlayerEntities[playerId] then
            if entityData.blipHandle and DoesBlipExist(entityData.blipHandle) then
                RemoveBlip(entityData.blipHandle)
            end

            playerEntities[playerId] = nil
        end
    end

    debugPrint('Parsed playerBlipsUpdate event payload')
end)

--- Sends perms request to the server to enable player ids
local function togglePlayerIDsHandler()
    TriggerServerEvent('txsv:req:showPlayerIDs', not isPlayerIdsEnabled)
end

RegisterSecureNuiCallback('togglePlayerIDs', function(_, cb)
    togglePlayerIDsHandler()
    cb({})
end)

RegisterCommand('txAdmin:menu:togglePlayerIDs', function()
    if not menuIsAccessible then return end
    if not DoesPlayerHavePerm(menuPermissions, 'menu.viewids') then
        return sendSnackbarMessage('error', 'nui_menu.misc.no_perms', true)
    end
    togglePlayerIDsHandler()
end)
