-- Prevent running in monitor mode
if not TX_SERVER_MODE then return end
-- Prevent running if menu is disabled
if not TX_MENU_ENABLED then return end

-- =============================================
--  This file is for server side handlers related to
--  actions defined on Menu's "Main Page"
-- =============================================

RegisterNetEvent('txsv:req:tpToWaypoint', function()
  local src = source
  local allow = PlayerHasTxPermission(src, 'players.teleport')
  if allow then
    TriggerClientEvent('txcl:tpToWaypoint', src)
    Wait(250)
    local coords = GetEntityCoords(GetPlayerPed(src))
    TriggerEvent('txsv:logger:menuEvent', src, 'teleportWaypoint', true,
      { x = coords[1], y = coords[2], z = coords[3] })
  else
    TriggerEvent('txsv:logger:menuEvent', src, 'teleportWaypoint', false)
  end
end)

RegisterNetEvent('txsv:req:sendAnnouncement', function(message)
  local src = source
  if type(message) ~= 'string' then
    return
  end
  local allow = PlayerHasTxPermission(src, 'announcement')
  TriggerEvent('txsv:logger:menuEvent', src, 'announcement', allow, message)
  if allow then
    PrintStructuredTrace(json.encode({
      type = 'txAdminCommandBridge',
      command = 'announcement',
      author = TX_ADMINS[tostring(src)].username,
      message = message,
    }))
  end
end)

RegisterNetEvent('txsv:req:clearArea', function(radius)
  local src = source
  local allow = PlayerHasTxPermission(src, 'menu.clear_area')
  TriggerEvent('txsv:logger:menuEvent', src, 'clearArea', allow, radius)
  if allow then
    TriggerClientEvent('txcl:clearArea', src, radius)
  end
end)

RegisterNetEvent('txsv:req:healEveryone', function()
  local src = source
  local allow = PlayerHasTxPermission(src, 'players.heal')
  TriggerEvent('txsv:logger:menuEvent', src, 'healAll', true)
  if allow then
    TriggerClientEvent('txcl:heal', -1)
    -- For use with third party resources that handle players
    -- 'revive state' standalone from health (esx-ambulancejob, qb-ambulancejob, etc)
    TriggerEvent('txAdmin:events:healedPlayer', { id = -1 }) -- FIXME: deprecate
    TriggerEvent('txAdmin:events:playerHealed', {
      target = -1,
      author = TX_ADMINS[tostring(src)].username,
    })
  end
end)

RegisterNetEvent('txsv:req:healMyself', function()
  local src = source
  local allow = PlayerHasTxPermission(src, 'players.heal')
  TriggerEvent('txsv:logger:menuEvent', src, 'healSelf', allow)
  if allow then
    TriggerClientEvent('txcl:heal', src)
    -- For use with third party resources that handle players
    -- 'revive state' standalone from health (esx-ambulancejob, qb-ambulancejob, etc)
    TriggerEvent('txAdmin:events:healedPlayer', { id = src }) -- FIXME: deprecate
    TriggerEvent('txAdmin:events:playerHealed', {
      target = src,
      author = TX_ADMINS[tostring(src)].username,
    })
  end
end)

RegisterNetEvent('txsv:req:healPlayer', function(id)
  local src = source
  if type(id) ~= 'string' and type(id) ~= 'number' then
    return
  end
  id = tonumber(id)
  local allow = PlayerHasTxPermission(src, 'players.heal')
  if allow then
    local ped = GetPlayerPed(id)
    if ped then
      TriggerClientEvent('txcl:heal', id)
      -- For use with third party resources that handle players
      -- 'revive state' standalone from health (esx-ambulancejob, qb-ambulancejob, etc)
      TriggerEvent('txAdmin:events:healedPlayer', { id = id }) -- FIXME: deprecate
      TriggerEvent('txAdmin:events:playerHealed', {
        target = id,
        author = TX_ADMINS[tostring(src)].username,
      })
    end
  end
  TriggerEvent('txsv:logger:menuEvent', src, 'healPlayer', allow, id)
end)

local ACTIVE_PLAYERID_SOURCES = {}
local lastPayload = {}

local GetPlayers, GetPlayerPed, GetEntityCoords, GetEntityHealth, GetPlayerName = GetPlayers, GetPlayerPed, GetEntityCoords, GetEntityHealth, GetPlayerName

local function GeneratePlayerPayload()
  local players <const> = GetPlayers()
  local payload = {}

  for i = 1, #players do
    local id <const> = tonumber(players[i])
    if id then
      local ped <const> = GetPlayerPed(id)
      local coords <const> = GetEntityCoords(ped)
      local health <const> = GetEntityHealth(ped)
      local name <const> = string.sub(GetPlayerName(id) or "unknown", 1, 75)

      table.insert(payload, { id, coords.x, coords.y, coords.z, health, ("[%i] %s"):format(id, name) })
    end
  end

  lastPayload = payload
  return payload
end

RegisterNetEvent('txsv:req:showPlayerIDs', function(enabled)
  local src = source
  local allow = PlayerHasTxPermission(src, 'menu.viewids')
  TriggerEvent('txsv:logger:menuEvent', src, 'showPlayerIDs', allow, enabled)
  
  if allow then
    if enabled then
      local currentPayload = lastPayload

      if #ACTIVE_PLAYERID_SOURCES == 0 or #currentPayload == 0 then
        currentPayload = GeneratePlayerPayload()
      end

      TriggerClientEvent('txcl:playerBlipsUpdate', src, currentPayload)

      if not table.contains(ACTIVE_PLAYERID_SOURCES, src) then
        table.insert(ACTIVE_PLAYERID_SOURCES, src)
      end
    else
      for i = #ACTIVE_PLAYERID_SOURCES, 1, -1 do
        if ACTIVE_PLAYERID_SOURCES[i] == src then
          table.remove(ACTIVE_PLAYERID_SOURCES, i)
          break
        end
      end
    end

    TriggerClientEvent('txcl:showPlayerIDs', src, enabled)
  end
end)

AddEventHandler('playerDropped', function()
  local src = source
  for i = #ACTIVE_PLAYERID_SOURCES, 1, -1 do
    if ACTIVE_PLAYERID_SOURCES[i] == src then
      table.remove(ACTIVE_PLAYERID_SOURCES, i)
      break
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Wait(10000)

    if #ACTIVE_PLAYERID_SOURCES > 0 then
      local payload = GeneratePlayerPayload()

      debugPrint('Sending blip payload update to', #ACTIVE_PLAYERID_SOURCES, 'admins')

      for i = 1, #ACTIVE_PLAYERID_SOURCES do
        TriggerClientEvent('txcl:playerBlipsUpdate', ACTIVE_PLAYERID_SOURCES[i], payload)
      end
    end
  end
end)

---@param x number|nil
---@param y number|nil
---@param z number|nil
RegisterNetEvent('txsv:req:tpToCoords', function(x, y, z)
  local src = source
  if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then
    return
  end

  local allow = PlayerHasTxPermission(src, 'players.teleport')
  TriggerEvent('txsv:logger:menuEvent', src, 'teleportCoords', allow, { x = x, y = y, z = z })
  if allow then
    TriggerClientEvent('txcl:tpToCoords', src, x, y, z)
  end
end)
