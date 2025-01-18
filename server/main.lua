local QBCore = exports['qb-core']:GetCoreObject()

-- Event to pay the player upon vehicle delivery
RegisterNetEvent('slacker-carboosting:server:payPlayer', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        Player.Functions.AddMoney('bank', amount) -- Pay the player in bank
        TriggerClientEvent('QBCore:Notify', src, "You received $" .. amount .. " for the delivery!", "success")
    end
end)