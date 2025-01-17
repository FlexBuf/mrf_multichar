local cam = nil
local charPed = nil
local loadScreenCheckState = false
local QBCore = exports['qb-core']:GetCoreObject()

-- Main Thread
CreateThread(function()
	while true do
		Wait(0)
		if NetworkIsSessionStarted() then
			TriggerEvent('mrf_multichar:client:chooseChar')
			return
		end
	end
end)

-- Functions
local function skyCam(bool)
    TriggerEvent('qb-weathersync:client:DisableSync')
    if bool then
        DoScreenFadeIn(1000)
        SetTimecycleModifier('hud_def_blur')
        SetTimecycleModifierStrength(1.0)
        FreezeEntityPosition(PlayerPedId(), false)
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.CamCoords.x, Config.CamCoords.y, Config.CamCoords.z, 0.0 ,0.0, Config.CamCoords.w, 60.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 1, true, true)
    else
        SetTimecycleModifier('default')
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        RenderScriptCams(false, false, 1, true, true)
        FreezeEntityPosition(PlayerPedId(), false)
    end
end

local function openCharMenu(bool)
    QBCore.Functions.TriggerCallback("mrf_multichar:server:GetNumberOfCharacters", function(result)
        SetNuiFocus(bool, bool)
        SendNUIMessage({
            action = "ui",
            toggle = bool,
            nChar = result,
            enableDeleteButton = Config.EnableDeleteButton,
        })
        skyCam(bool)
        if not loadScreenCheckState then
            ShutdownLoadingScreenNui()
            loadScreenCheckState = true
        end
    end)
end

-- Car

CreateThread(function()
    local model = Config.CarModel
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    local vehicle = CreateVehicle(model, Config.Car.x, Config.Car.y, Config.Car.z, Config.Car.h, false, false)
    local timeout = 0
    local vehColour = GetVehicleColours(vehicle)
    SetEntityAsMissionEntity(vehicle, true, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetVehicleEngineOn(vehicle, true, true)
    SetVehicleColours(vehicle, 27, vehColour)
    FreezeEntityPosition(vehicle, true)
    SetEntityInvincible(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 3)
    RequestCollisionAtCoord(Config.Car.x, Config.Car.y, Config.Car.z, Config.Car.h)
    while not HasCollisionLoadedAroundEntity(vehicle) and timeout < 2000 do
        Wait(0)
        timeout = timeout + 1
    end
end)

-- Events

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    SendNUIMessage({
        action = "stopSong"
    })
end)

RegisterNetEvent('mrf_multichar:client:closeNUIdefault', function() -- This event is only for no starting apartments
    DeleteEntity(charPed)
    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    Wait(2000)
    SetEntityCoords(PlayerPedId(), Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('mrf_apartments:server:SetInsideMeta', 0, 0, false)
    Wait(500)
    openCharMenu()
    SetEntityVisible(PlayerPedId(), true)
    Wait(500)
    DoScreenFadeIn(250)
    TriggerEvent('qb-weathersync:client:EnableSync')
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end)

RegisterNetEvent('mrf_multichar:client:lastloc', function(coords)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local insideMeta = PlayerData.metadata["inside"]
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    if insideMeta.house then
        TriggerEvent('qb-houses:client:LastLocationHouse', insideMeta.house)
    elseif insideMeta.apartment.apartmentType and insideMeta.apartment.apartmentId then
        TriggerEvent('qb-apartments:client:LastLocationHouse', insideMeta.apartment.apartmentType, insideMeta.apartment.apartmentId)
    else
        SetEntityCoords(ped, coords.x, coords.y, coords.z)
        SetEntityHeading(ped, coords.w)
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true)
    end
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    Wait(2000)
    DoScreenFadeIn(250)
end)

RegisterNetEvent('mrf_multichar:client:closeNUI', function()
    DeleteEntity(charPed)
    SetNuiFocus(false, false)
end)

RegisterNetEvent('mrf_multichar:client:chooseChar', function()
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Wait(1000)
    local interior = GetInteriorAtCoords(Config.Interior.x, Config.Interior.y, Config.Interior.z - 18.9)
    LoadInterior(interior)
    while not IsInteriorReady(interior) do
        Wait(1000)
    end
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoords(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)
    Wait(1500)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    openCharMenu(true)
end)

-- NUI Callbacks

RegisterNUICallback('closeUI', function()
    openCharMenu(false)
end)

RegisterNUICallback('disconnectButton', function()
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    TriggerServerEvent('mrf_multichar:server:disconnect')
end)

RegisterNUICallback('selectCharacter', function(data)
    local cData = data.cData
    DoScreenFadeOut(10)
    TriggerServerEvent('mrf_multichar:server:loadUserData', cData)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    if Config.LastLoc then
        SetNuiFocus(false, false)
        skyCam(false)
    else
        openCharMenu(false)
    end
end)

RegisterNUICallback('cDataPed', function(nData, cb)
    local cData = nData.cData
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    if cData ~= nil then
        QBCore.Functions.TriggerCallback('mrf_multichar:server:getSkin', function(skinData)
            if skinData then
                local model = joaat(skinData.model)
                CreateThread(function()
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                        Wait(0)
                    end
                    charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
                    local RandomAnims = {
                        "WORLD_HUMAN_LEANING_CASINO_TERRACE"
                    }
                    local PlayAnim = RandomAnims[math.random(#RandomAnims)]
                    SetPedCanPlayAmbientAnims(charPed, true) 
                    TaskStartScenarioInPlace(charPed, PlayAnim, 0, true)
                    SetPedComponentVariation(charPed, 0, 0, 0, 2)
                    FreezeEntityPosition(charPed, false)
                    SetEntityInvincible(charPed, true)
                    PlaceObjectOnGroundProperly(charPed)
                    SetBlockingOfNonTemporaryEvents(charPed, true)
                    exports['illenium-appearance']:setPedAppearance(charPed, skinData)
                end)
            else
                CreateThread(function()
                    local randommodels = {
                        "mp_m_freemode_01",
                        "mp_f_freemode_01",
                    }
                    model = joaat(randommodels[math.random(1, #randommodels)])
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                        Wait(0)
                    end
                    charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
                    SetPedComponentVariation(charPed, 0, 0, 0, 2)
                    FreezeEntityPosition(charPed, false)
                    SetEntityInvincible(charPed, true)
                    PlaceObjectOnGroundProperly(charPed)
                    SetBlockingOfNonTemporaryEvents(charPed, true)
                end)
            end
            cb("ok")
        end, cData.citizenid)
    else
        CreateThread(function()
            local randommodels = {
                "mp_m_freemode_01",
                "mp_f_freemode_01",
            }
            local model = joaat(randommodels[math.random(1, #randommodels)])
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(0)
            end
            charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
            SetPedComponentVariation(charPed, 0, 0, 0, 2)
            FreezeEntityPosition(charPed, false)
            SetEntityInvincible(charPed, true)
            PlaceObjectOnGroundProperly(charPed)
            SetBlockingOfNonTemporaryEvents(charPed, true)
        end)
        cb("ok")
    end
end)

RegisterNUICallback('setupCharacters', function()
    QBCore.Functions.TriggerCallback("mrf_multichar:server:setupCharacters", function(result)
        SendNUIMessage({
            action = "setupCharacters",
            characters = result
        })
    end)
end)

RegisterNUICallback('removeBlur', function()
    SetTimecycleModifier('default')
end)

RegisterNUICallback('createNewCharacter', function(data)
    local cData = data
    DoScreenFadeOut(150)
    if cData.gender == "Male" then
        cData.gender = 0
    elseif cData.gender == "Female" then
        cData.gender = 1
    end
    TriggerServerEvent('mrf_multichar:server:createCharacter', cData)
    Wait(500)
end)

RegisterNUICallback('removeCharacter', function(data, cb)
    TriggerServerEvent('mrf_multichar:server:deleteCharacter', data.citizenid)
    DeletePed(charPed)
    TriggerEvent('mrf_multichar:client:chooseChar')
    cb("ok")
end)