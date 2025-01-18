local QBCore = exports['qb-core']:GetCoreObject()
local pedHandle = nil
local deliveryPed = nil
local deliveryBlip = nil
local searchRadiusBlip = nil  -- New variable for the search radius blip
local boostCooldown = false
local receivedContracts = {}
local hasAcceptedContract = false
local currentDeliveryLocation = nil
local isInDeliveryZone = false

-- Function to spawn the ped
local function spawnPed()
    local model = GetHashKey(Config.PedModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end

    local x, y, z, heading = table.unpack(Config.PedLocation)
    pedHandle = CreatePed(4, model, x, y, z - 1, heading, false, true)
    FreezeEntityPosition(pedHandle, true)
    SetEntityInvincible(pedHandle, true)
    SetBlockingOfNonTemporaryEvents(pedHandle, true)
end

-- Function to get a random contract
local function getRandomContract()
    local totalChance = 0
    for _, contract in ipairs(Config.VehicleContracts) do
        totalChance = totalChance + contract.chance
    end

    local randomChance = math.random(totalChance)
    local cumulativeChance = 0

    for _, contract in ipairs(Config.VehicleContracts) do
        cumulativeChance = cumulativeChance + contract.chance
        if randomChance <= cumulativeChance then
            return contract
        end
    end
    return nil
end

-- Function to setup qb-target interaction
local function setupTarget()
    exports['qb-target']:AddTargetEntity(pedHandle, {
        options = {
            {
                type = "client",
                event = "slacker-carboosting:client:OpenBoostingMenu",
                icon = "fas fa-comments",
                label = "Start Boosting",
            },
            {
                type = "client",
                event = "slacker-carboosting:client:ShowReceivedContracts",
                icon = "fas fa-car",
                label = "View Received Contracts",
                canInteract = function()
                    return #receivedContracts > 0
                end
            },
        },
        distance = 2.0,
    })
end

-- Function to open the boosting menu
local function openBoostingMenu()
    local menu = {
        {
            header = "Boosting Menu",
            isMenuHeader = true
        },
        {
            header = "Start Boosting",
            txt = "Begin a vehicle boost job",
            params = {
                event = "slacker-carboosting:client:StartBoosting"
            }
        },
        {
            header = "Close",
            txt = "",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        }
    }

    exports['qb-menu']:openMenu(menu)
end

-- Function to show received contracts
local function showReceivedContracts()
    local menu = {
        {
            header = "Received Vehicle Contracts",
            isMenuHeader = true
        }
    }

    for _, contract in ipairs(receivedContracts) do
        local headerText = contract.name
        local clickable = true

        if contract.accepted then
            headerText = "Contract Started"
            clickable = false
        end

        table.insert(menu, {
            header = headerText,
            txt = "Reward: $" .. contract.price,
            params = {
                event = clickable and "slacker-carboosting:client:AcceptContract" or nil,
                args = clickable and contract or nil,
            },
            color = clickable and nil or {200, 200, 200}
        })
    end

    table.insert(menu, {
        header = "Close",
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }
    })

    exports['qb-menu']:openMenu(menu)
end

-- Function to spawn the vehicle
local function spawnVehicle(vehicleName)
    local model = GetHashKey(vehicleName)

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end

    -- Select a random spawn location
    local spawnLocation = Config.VehicleSpawnLocations[math.random(#Config.VehicleSpawnLocations)]

    -- Spawn the vehicle at the selected location
    local vehicle = CreateVehicle(model, spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w, true, false)

    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        QBCore.Functions.Notify("The vehicle has been spawned! Search area marked on your map.", "success")

        -- Create a search area around the vehicle
        local radius = Config.SearchRadius
        searchRadiusBlip = AddBlipForRadius(spawnLocation.x, spawnLocation.y, spawnLocation.z, radius)
        SetBlipSprite(searchRadiusBlip, 9)
        SetBlipColour(searchRadiusBlip, 3)
        SetBlipAlpha(searchRadiusBlip, 128)
    else
        QBCore.Functions.Notify("Failed to spawn the vehicle: " .. vehicleName, "error")
    end
end

-- Function to create a delivery blip
function createDeliveryBlip(location)
    if deliveryBlip then
        RemoveBlip(deliveryBlip) -- Remove existing blip if any
    end
    deliveryBlip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(deliveryBlip, 530) -- Blip type
    SetBlipColour(deliveryBlip, 1) -- Blip color
    SetBlipScale(deliveryBlip, 1.0)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Delivery Location")
    EndTextCommandSetBlipName(deliveryBlip)
end

-- Function to spawn the delivery ped
function spawnDeliveryPed(location)
    if deliveryPed then
        DeletePed(deliveryPed) -- Delete existing ped if any
    end

    local model = GetHashKey(Config.DeliveryPedModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end

    deliveryPed = CreatePed(4, model, location.x, location.y, location.z, location.w, false, true)
    SetBlockingOfNonTemporaryEvents(deliveryPed, true)
    SetPedCanBeTargetted(deliveryPed, false)
    SetEntityInvincible(deliveryPed, true) -- Make sure the ped is invincible
    FreezeEntityPosition(deliveryPed, true) -- Freeze the ped
end

-- Function to remove delivery blip
function removeDeliveryBlip()
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
end

local canAttemptDelivery = true

-- Function to complete delivery
local function completeDelivery(contract)
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    if not canAttemptDelivery then
        return
    end

    if DoesEntityExist(playerVehicle) and GetPedInVehicleSeat(playerVehicle, -1) == playerPed then
        -- Check if the vehicle model matches the contract's model
        local vehicleModel = GetEntityModel(playerVehicle)
        local expectedModel = GetHashKey(contract.model)

        if vehicleModel == expectedModel then
            QBCore.Functions.Notify("You have delivered the vehicle! You will receive payment shortly.", "success")

            -- Force the player out of the vehicle
            TaskLeaveVehicle(playerPed, playerVehicle, 0)

            -- Wait for 5 seconds before deleting the vehicle
            Wait(5000)
            DeleteEntity(playerVehicle)

            -- Give the player the reward
            TriggerServerEvent('slacker-carboosting:server:payPlayer', contract.price) -- Pay the player

            -- Remove the delivery ped
            if deliveryPed then
                DeletePed(deliveryPed)
                deliveryPed = nil
            end

            -- Remove the delivery blip
            removeDeliveryBlip()

            -- Remove the search radius blip
            if searchRadiusBlip then
                RemoveBlip(searchRadiusBlip)
                searchRadiusBlip = nil
            end

            -- Remove the completed contract from the receivedContracts list
            for i, c in ipairs(receivedContracts) do
                if c.name == contract.name then
                    table.remove(receivedContracts, i)
                    break
                end
            end

            -- Reset delivery state
            hasAcceptedContract = false -- Reset contract status
        else
            QBCore.Functions.Notify("This is not the correct vehicle for delivery!", "error")

            -- Start the cooldown to prevent spamming the notification
            canAttemptDelivery = false
            Citizen.SetTimeout(15000, function()
                canAttemptDelivery = true
            end)
        end
    else
        QBCore.Functions.Notify("You need to be in the vehicle to deliver it!", "error")
    end
end

-- Event handler for Open Boosting Menu
RegisterNetEvent('slacker-carboosting:client:OpenBoostingMenu', function()
    openBoostingMenu()
end)

-- Event handler for Show Received Contracts
RegisterNetEvent('slacker-carboosting:client:ShowReceivedContracts', function()
    showReceivedContracts()
end)

-- Event handler for Start Boosting
RegisterNetEvent('slacker-carboosting:client:StartBoosting', function()
    if boostCooldown then
        QBCore.Functions.Notify("You need to wait before starting another boost.", "error")
        print("Boost cooldown is still active.")  -- Debugging line
        return
    end

    QBCore.Functions.Notify("Please wait until we have located you a vehicle", "success")
    local delay = math.random(Config.BoostDelayMin * 1000, Config.BoostDelayMax * 1000)
    Wait(delay)

    local contract = getRandomContract()
    if contract then
        contract.accepted = false
        table.insert(receivedContracts, contract)
        QBCore.Functions.Notify("You have received a new contract: " .. contract.name .. " for $" .. contract.price, "success")
        
        -- Set a random delivery location for the contract
        currentDeliveryLocation = Config.DeliveryLocations[math.random(#Config.DeliveryLocations)]
    else
        QBCore.Functions.Notify("No contracts available at this time.", "error")
    end

    boostCooldown = true
    print("Boost cooldown started for " .. Config.BoostCooldownTime .. " seconds.")  -- Debugging line

    -- Wait for cooldown time and reset cooldown
    Wait(Config.BoostCooldownTime * 1000)
    boostCooldown = false
    QBCore.Functions.Notify("You can start a new boost now.", "success")
    print("Boost cooldown ended.")  -- Debugging line
end)

-- Event handler for accepting a contract
RegisterNetEvent('slacker-carboosting:client:AcceptContract', function(contract)
    if hasAcceptedContract then
        QBCore.Functions.Notify("You have already accepted a contract. Complete it first.", "error")
        return
    end

    contract.accepted = true
    hasAcceptedContract = true

    -- Create a delivery blip on the map immediately after accepting the contract
    createDeliveryBlip(currentDeliveryLocation)

    -- Spawn the delivery ped at the delivery location
    spawnDeliveryPed(currentDeliveryLocation)

    -- Spawn the vehicle and mark the search area on the map
    spawnVehicle(contract.model)

    -- Wait for the player to deliver the vehicle
    CreateThread(function()
        while hasAcceptedContract do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - vector3(currentDeliveryLocation.x, currentDeliveryLocation.y, currentDeliveryLocation.z))

            if distance < Config.DeliveryRadius then
                completeDelivery(contract)
            end

            Wait(1000)
        end
    end)
end)

-- Spawn the ped when the script starts
CreateThread(function()
    spawnPed()
    setupTarget()
end)