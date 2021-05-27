ESX = exports['es_extended']:getSharedObject()
if ESX.GetConfig().Multichar == true then
	local IdentifierTables = {}
	
	-- enter the name of your database here
	Config.Database = 'es_extended'
	-- enter a prefix to prepend to all user identifiers (keep it short)
	Config.Prefix = 'char'

	SetupCharacters = function(playerId)
		local identifier = Config.Prefix..'%:'..ESX.GetIdentifier(playerId)
		MySQL.Async.fetchAll("SELECT `identifier`, `accounts`, `job`, `job_grade`, `firstname`, `lastname`, `dateofbirth`, `sex`, `skin` FROM `users` WHERE `identifier` LIKE @identifier", {
			['@identifier'] = identifier
		}, function(result)
			local characters = {}
			for i=1, #result, 1 do
				local job = ESX.Jobs[result[i].job]
				local grade = ESX.Jobs[job.name].grades[tostring(result[i].job_grade)].label
				local accounts = json.decode(result[i].accounts)
				if grade == 'Unemployed' then grade = '' end
				local id = tonumber(string.sub(result[i].identifier, #Config.Prefix+1, string.find(result[i].identifier, ':')-1))
				characters[id] = {
					id = id,
					bank = accounts.bank,
					money = accounts.money,
					job = job.label,
					job_grade = grade,
					firstname = result[i].firstname,
					lastname = result[i].lastname,
					dateofbirth = result[i].dateofbirth,
					skin = json.decode(result[i].skin)
				}
				if result[i].sex == 'm' then characters[id].sex = 'Male' else characters[id].sex = 'Female' end
			end
			TriggerClientEvent('esx_multicharacter:SetupUI', playerId, characters)
		end)
	end

	DeleteCharacter = function(playerId, charid)
		local identifier = Config.Prefix..charid..':'..ESX.GetIdentifier(playerId)
		for _, itable in pairs(IdentifierTables) do
			MySQL.Async.execute("DELETE FROM "..itable.table.." WHERE "..itable.column.." = @identifier", {
				['@identifier'] = identifier
			})
		end
	end

	Citizen.CreateThread(function()
		MySQL.ready(function ()
			MySQL.Async.fetchAll('SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = @id AND TABLE_SCHEMA = @db', { ['@id'] = "owner", ["@db"] = Config.Database}, function(result)
				if result then
					for k, v in pairs(result) do
						IdentifierTables[#IdentifierTables+1] = {table = v.TABLE_NAME, column = 'owner'}
					end
				end
			end)
			MySQL.Async.fetchAll('SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = @id AND TABLE_SCHEMA = @db', { ['@id'] = "identifier", ["@db"] = Config.Database}, function(result)
				if result then
					for k, v in pairs(result) do
						IdentifierTables[#IdentifierTables+1] = {table = v.TABLE_NAME, column = 'identifier'}
					end
				end
			end)
		end)
		
		while next(ESX.Jobs) == nil do
			Citizen.Wait(250)
			ESX.Jobs = exports['es_extended']:getSharedObject().Jobs
		end
	end)

	RegisterServerEvent("esx_multicharacter:SetupCharacters")
	AddEventHandler('esx_multicharacter:SetupCharacters', function()
		SetupCharacters(source)
	end)

	RegisterServerEvent("esx_multicharacter:CharacterChosen")
	AddEventHandler('esx_multicharacter:CharacterChosen', function(charid, isNew)
		local src = source
		print(Config.Prefix..charid)
		if type(charid) == 'number' and string.len(charid) == 1 and type(isNew) == 'boolean' then
			TriggerEvent('esx:onPlayerJoined', src, Config.Prefix..charid, isNew)
		else
			-- Trigger Ban Event here to ban individuals trying to use SQL Injections
		end
	end)

	RegisterServerEvent("esx_multicharacter:DeleteCharacter")
	AddEventHandler('esx_multicharacter:DeleteCharacter', function(charid)
		local src = source
		if type(charid) == "number" and string.len(charid) == 1 then
			DeleteCharacter(src, charid)
			SetupCharacters(src)
		else
			-- Trigger Ban Event here to ban individuals trying to use SQL Injections
		end
	end)

	RegisterServerEvent("esx_multicharacter:relog")
	AddEventHandler('esx_multicharacter:relog', function()
		local src = source
		TriggerEvent('esx:playerLogout', src)
	end)

	RegisterCommand('forcelog', function(source, args, rawCommand)
		TriggerEvent('esx:playerLogout', source)
	end, true)

elseif ESX.GetConfig().Multichar == false then
	Citizen.Wait(1500)
	print('[^3WARNING^7] Multicharacter is disabled - please check your ESX configuration')
else
	Citizen.Wait(1500)
	print('[^3WARNING^7] Unable to start Multicharacter - your version of ESX is not compatible ')
end
