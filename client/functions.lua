DCCore = {}
DCCore.Blips = {}
DCCore.Peds = {}
DCCore.PlayerData = {}
DCCore.ServerCallbacks = {}

-- Shared

exports('GetGangs', function()
    return DCShared.Gangs
end)

exports('GetHorses', function()
    return DCShared.Horses
end)

exports('GetItems', function()
    return DCShared.Items
end)

exports('GetJobs', function()
    return DCShared.Jobs
end)

exports('GetVehicles', function()
    return DCShared.Vehicles
end)

exports('GetWeapons', function()
    return DCShared.Weapons
end)

-- Player

exports('GetPlayerData', function(cb)
    if cb then
        cb(DCCore.PlayerData)
    else
        return DCCore.PlayerData
    end
end)

exports('GetCoords', function(entity)
    local coords = GetEntityCoords(entity, false)
    local heading = GetEntityHeading(entity)
    return vector4(coords.x, coords.y, coords.z, heading)
end)

exports('HasItem', function(item)
    local p = promise.new()
    TriggerCallback('DCCore:HasItem', function(result)
        p:resolve(result)
    end, item)
    return Citizen.Await(p)
end)

-- Utility

exports('Debug', function(resource, obj, depth)
    TriggerServerEvent('DCCore:DebugSomething', resource, obj, depth)
end)

-- function TriggerCallback(event, ...)
-- 	local id = math.random(0, 100000)
-- 	event = ('__cb_%s'):format(event)
-- 	TriggerServerEvent(event, id, ...)
-- 	return event..id
-- end

function TriggerCallback(name, cb, ...)
    DCCore.ServerCallbacks[name] = cb
    TriggerServerEvent('DCCore:Server:TriggerCallback', name, ...)
end
exports('TriggerCallback', TriggerCallback)

-- Peds

local function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(50)
    end
end
exports('LoadModel', LoadModel)

exports('SpawnPed', function(name, model, x, y, z, w)
    if type(model) == 'string' then model = GetHashKey(model) end
    LoadModel(model)
    DCCore.Peds[name] = CreatePed(model, x, y, z, w, true, true, 0, 0)
    Citizen.InvokeNative(0x283978A15512B2FE, DCCore.Peds[name], true)
    FreezeEntityPosition(DCCore.Peds[name], true)
    SetEntityInvincible(DCCore.Peds[name], true)
    SetBlockingOfNonTemporaryEvents(DCCore.Peds[name], true)
    SetEntityCanBeDamagedByRelationshipGroup(DCCore.Peds[name], false, `PLAYER`)
    SetEntityAsMissionEntity(DCCore.Peds[name], true, true)
end)

exports('RemovePed', function(name)
    DeletePed(DCCore.Peds[name])
    DCCore.Peds[name] = nil
end)

-- Getters

exports('GetPeds', function(ignoreList)
    local pedPool = GetGamePool('CPed')
    local ignoreList = ignoreList or {}
    local peds = {}
    for i = 1, #pedPool, 1 do
        local found = false
        for j = 1, #ignoreList, 1 do
            if ignoreList[j] == pedPool[i] then
                found = true
            end
        end
        if not found then
            peds[#peds + 1] = pedPool[i]
        end
    end
    return peds
end)

exports('GetClosestPed', function(coords, ignoreList)
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local ignoreList = ignoreList or {}
    local peds = exports['dcr-core']:GetPeds(ignoreList)
    local closestDistance = -1
    local closestPed = -1
    for i = 1, #peds, 1 do
        local pedCoords = GetEntityCoords(peds[i])
        local distance = #(pedCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestPed = peds[i]
            closestDistance = distance
        end
    end
    return closestPed, closestDistance
end)

exports('GetClosestPlayer', function(coords)
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local closestPlayers = exports['dcr-core']:GetPlayersFromCoords(coords)
    local closestDistance = -1
    local closestPlayer = -1
    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() and closestPlayers[i] ~= -1 then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end)

exports('GetPlayersFromCoords', function(coords, distance)
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local distance = distance or 5
    local closePlayers = {}
    for _, player in pairs(players) do
        local target = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(target)
        local targetdistance = #(targetCoords - coords)
        if targetdistance <= distance then
            closePlayers[#closePlayers + 1] = player
        end
    end
    return closePlayers
end)

exports('GetClosestVehicle', function(coords)
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    return closestVehicle, closestDistance
end)

exports('GetClosestObject', function(coords)
    local ped = PlayerPedId()
    local objects = GetGamePool('CObject')
    local closestDistance = -1
    local closestObject = -1
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    for i = 1, #objects, 1 do
        local objectCoords = GetEntityCoords(objects[i])
        local distance = #(objectCoords - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestObject = objects[i]
            closestDistance = distance
        end
    end
    return closestObject, closestDistance
end)

exports('AttachProp', function(ped, model, boneId, x, y, z, xR, yR, zR, Vertex)
    local modelHash = GetHashKey(model)
    local bone = GetPedBoneIndex(ped, boneId)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end
    local prop = CreateObject(modelHash, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, 1, 1, 0, 1, not Vertex and 2 or 0, 1)
    SetModelAsNoLongerNeeded(modelHash)
    return prop
end)

-- Vehicle

exports('SpawnVehicle', function(model, cb, coords, isnetworked)
    local hash = GetHashKey(model)
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local isnetworked = isnetworked or true
    if not IsModelInCdimage(hash) then return end
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    local netid = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdExistsOnAllMachines(netid, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetModelAsNoLongerNeeded(hash)
    if cb then
        cb(veh)
    end
end)

exports('GetPlate',function(vehicle)
    if vehicle == 0 then return end
    return exports['dcr-core']:Trim(Citizen.InvokeNative(0xE8522D58,vehicle))
end)

exports("DeleteVehicle",function(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end)



-- Notification Function (can use direct export)
-- Function for Progressbar ( Missing Function export )
exports('Progressbar', function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    exports['progressbar']:Progress({
        name = name:lower(),
        duration = duration,
        label = label,
        useWhileDead = useWhileDead,
        canCancel = canCancel,
        controlDisables = disableControls,
        animation = animation,
        prop = prop,
        propTwo = propTwo,
    }, function(cancelled)
        if not cancelled then
            if onFinish then
                onFinish()
            end
        else
            if onCancel then
                onCancel()
            end
        end
    end)
end)

local function LoadTexture(dict)
    if Citizen.InvokeNative(0x7332461FC59EB7EC, dict) then
        RequestStreamedTextureDict(dict, true)
        while not HasStreamedTextureDictLoaded(dict) do
            Wait(1)
        end
        return true
    else
        return false
    end
end

function Notify(id, text, duration, subtext, dict, icon, color)
    local display = tostring(text) or 'Placeholder'
	local subdisplay = tostring(subtext) or 'Placeholder'
	local length = tonumber(duration) or 4000
	local dictionary = tostring(dict) or 'generic_textures'
	local image = tostring(icon) or 'tick'
	local colour = tostring(color) or 'COLOR_WHITE'

    local notifications = {
        [1] = function() return exports['dcr-core']:ShowTooltip(display, length) end,
        [2] = function() return exports['dcr-core']:DisplayRightText(display, length) end,
        [3] = function() return exports['dcr-core']:ShowObjective(display, length) end,
        [4] = function() return exports['dcr-core']:ShowBasicTopNotification(display, length) end,
        [5] = function() return exports['dcr-core']:ShowSimpleCenterText(display, length) end,
        [6] = function() return exports['dcr-core']:ShowLocationNotification(display, subdisplay, length) end,
        [7] = function() return exports['dcr-core']:ShowTopNotification(display, subdisplay, length) end,
        [8] = function() if not LoadTexture(dictionary) then LoadTexture('generic_textures') end
            return exports['dcr-core']:ShowAdvancedLeftNotification(display, subdisplay, dictionary, image, length) end,
        [9] = function() if not LoadTexture(dictionary) then LoadTexture('generic_textures') end
            return exports['dcr-core']:ShowAdvancedRightNotification(display, dictionary, image, colour, length) end
    }

    if not notifications[id] then
        print('Invalid Notify ID')
        return nil
    else
        return notifications[id]()
    end
end
exports('Notify', Notify)

-- Blip Functions
exports('CreateBlip', function(uniqueId, label, x, y, z, sprite, scale, rotation, radius)
    if type(sprite) == 'string' then sprite = GetHashKey(sprite) end
    if radius then
        DCCore.Blips[uniqueId] = Citizen.InvokeNative(0x45F13B7E0A15C880, 1664425300, x, y, z, radius)
    else
        DCCore.Blips[uniqueId] = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, x, y, z)
    end
    if label then Citizen.InvokeNative(0x9CB1A1623062F402, DCCore.Blips[uniqueId], label) end
    if sprite then SetBlipSprite(DCCore.Blips[uniqueId], sprite) end
    if scale then SetBlipScale(DCCore.Blips[uniqueId], scale) end
    if rotation then SetBlipRotation(DCCore.Blips[uniqueId], rotation) end
end)

exports('DeleteBlip', function(uniqueId)
    RemoveBlip(DCCore.Blips[uniqueId])
end)
