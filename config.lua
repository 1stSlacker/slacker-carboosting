Config = {}

Config.PedModel = 'a_m_y_business_01' -- Change to any ped model you want
Config.PedLocation = vector4(453.0, -1305.46, 30.12, 320.54) -- Default location

-- Vehicle spawn locations
Config.VehicleSpawnLocations = {
    vector4(158.84, -68.41, 68.0, 340.7),  -- Spawn location 1
	vector4(149.75, -127.02, 54.83, 68.81),  -- Spawn location 2
	vector4(90.09, 486.77, 147.69, 207.39),  -- Spawn location 3
	vector4(-318.98, 479.36, 112.31, 133.46),  -- Spawn location 4
	vector4(-447.32, -413.5, 33.24, 263.05),  -- Spawn location 5
	vector4(-471.01, -60.84, 44.51, 268.73),  -- Spawn location 6
	vector4(-1203.6, -1038.21, 2.15, 117.17),  -- Spawn location 7
	vector4(-975.53, -1266.23, 2.41, 105.1),  -- Spawn location 8
	vector4(-1271.31, -1100.64, 7.55, 19.21),  -- Spawn location 9
	vector4(-1287.75, -794.15, 17.59, 125.79),  -- Spawn location 10
	vector4(-111.88, -2521.41, 6.0, 232.94),  -- Spawn location 11
	vector4(126.38, -2199.14, 6.03, 355.8),  -- Spawn location 12
	vector4(32.67, -1456.87, 29.32, 319.36),  -- Spawn location 13
	vector4(-166.78, -31.53, 52.52, 158.83),  -- Spawn location 14
	vector4(-143.32, -23.64, 57.97, 339.85),  -- Spawn location 15
	vector4(256.02, -13.77, 73.68, 68.28),  -- Spawn location 16
}

Config.VehicleContracts = {
    { model = '21sierra', name = 'GMC Sierra', price = math.random(3500, 5750), chance = 30 },
    { model = 'amggt16', name = 'Mercedes AMG GT', price = math.random(3750, 6250), chance = 20 },
    { model = 'a80', name = 'Toyota Supra', price = math.random(3750, 6750), chance = 20 },
    { model = 'c8', name = 'Corvette C8', price = math.random(4500, 7500), chance = 15 },
    { model = 'choilambo', name = 'Lamborghini Huracan', price = math.random(5500, 8000), chance = 10 },
    { model = '488', name = 'Ferrari 488', price = math.random(6000, 12000), chance = 5 },
}

Config.DeliveryLocations = {
    vector4(-2196.97, -420.77, 12.07, 287.76),  -- Delivery location 1
    vector4(-3188.07, 1230.3, 9.08, 222.37), -- Delivery location 2
    vector4(-365.56, 6338.63, 28.85, 184.09),  -- Delivery location 3
	vector4(1981.14, 5176.77, 46.64, 149.43), -- Delivery location 4
	vector4(1419.45, 3628.01, 33.78, 191.97), -- Delivery location 5
	vector4(-1785.6, 454.17, 127.31, 56.15), -- Delivery location 6
	vector4(437.16, -614.13, 27.71, 83.72), -- Delivery location 7
    -- Add more locations as needed
}

Config.DeliveryPedModel = 'a_m_y_business_01' -- Change to any ped model you want
Config.DeliveryBlips = {}
Config.DeliveryRadius = 15.0 -- Radius to detect player arrival

-- Delay settings for boosting in seconds
Config.BoostDelayMin = 5  -- Minimum delay time in seconds
Config.BoostDelayMax = 15  -- Maximum delay time in seconds

Config.BoostCooldownTime = 5 * 60 -- Cooldown time in seconds (5 minutes)

-- Search radius for the vehicle spawn location
Config.SearchRadius = 250.0  -- Adjust as needed
Config.DeliveryRadius = 15.0 -- Adjust the radius for delivery location

Config.DeliveryPedModel = 'a_m_y_business_01' -- Model for the delivery ped