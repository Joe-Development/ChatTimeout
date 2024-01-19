local timeoutList = {}

function TimeoutPlayer(playerId, timeoutMinutes, reason)
    local timeoutSeconds = timeoutMinutes * 60
    timeoutList[playerId] = { time = timeoutSeconds, reason = reason }
end

function IsPlayerTimedOut(playerId)
    return timeoutList[playerId] and timeoutList[playerId].time > 0
end

function UpdateTimeouts()
    for playerId, data in pairs(timeoutList) do
        if data.time > 0 then
            data.time = data.time - 1
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        UpdateTimeouts()
    end
end)

function sendToDiscord(admin, victim, action, timeoutMinutes, reason)
    function GetDiscordId(playerId)
        local identifiers = GetPlayerIdentifiers(playerId)
        for _, identifier in ipairs(identifiers) do
            if string.find(identifier, "discord:") then
                return string.sub(identifier, 9)
            end
        end
        return nil
    end
    
    function GetFiveMId(playerId)
        local identifiers = GetPlayerIdentifiers(playerId)
        for _, identifier in ipairs(identifiers) do
            if string.find(identifier, "license:") then
                return string.sub(identifier, 9)
            end
        end
        return nil
    end
    local admin_did = GetDiscordId(admin) or "Not Found"
    local admin_fivemID = GetFiveMId(admin) or "Not Found"
    local victim_discordID = GetDiscordId(victim) or "Not Found"
    local victime_FiveMID = GetFiveMId(victim) or "Not Found"



    local playerName_Victim = GetPlayerName(victim) or "Not Found"
    local color = (action == "timeout") and 65280 or 16711680 

    local embed = {
        title = Config.chat_time.discord.title,
        description = "**Action:** " .. action:sub(1,1):upper() .. action:sub(2) .. "\n",
        fields = {
            {name = "Admin", value = admin, inline = true},
            {name = "Admin Discord ", value = "<@"..admin_did..">", inline = true},
            {name = "Admin License ", value = admin_fivemID, inline = true},
            {name = "Victim", value = playerName_Victim, inline = true},
            {name = "Victim Discord ", value = "<@"..victim_discordID..">", inline = true},
            {name = "Victim License ", value = victime_FiveMID, inline = true},
            {name = "Duration", value = timeoutMinutes .. " minutes", inline = true},
            {name = "Reason", value = reason}
        },
        footer = {
            text = "Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | " .. Config.chat_time.discord.footer,
        },
        color = color
    }

    PerformHttpRequest(Config.chat_time.discord.webhook, function(err, text, headers) end, 'POST', json.encode({
        embeds = { embed }
    }), {["Content-Type"] = "application/json"})
end

RegisterCommand('timeout', function (source, args)
    local playerId = tonumber(args[1])
    local timeoutMinutes = tonumber(args[2])
    local reason = table.concat(args, ' ', 3)

    if playerId and timeoutMinutes then
        local targetPlayer = nil

        for _, player in ipairs(GetPlayers()) do
            if tonumber(player) == playerId then
                targetPlayer = tonumber(player)
                break
            end
        end

        if targetPlayer and targetPlayer ~= source then
            if IsPlayerAceAllowed(source, Config.chat_time.admin) and not IsPlayerAceAllowed(source, Config.chat_time.bypass) then
                if IsPlayerTimedOut(targetPlayer) then
                    local playerName = GetPlayerName(targetPlayer)
                    TriggerClientEvent('chatMessage', source, '[SYSTEM]', {255, 0, 0}, '' .. playerName .. ' is already timed out.')
                else
                    TimeoutPlayer(targetPlayer, timeoutMinutes, reason)
                    local playerName = GetPlayerName(targetPlayer)
                    TriggerClientEvent('chatMessage', -1, '[SYSTEM]', {255, 0, 0}, '' .. playerName .. ' has been timed out for ' .. timeoutMinutes .. ' minutes. Reason: ' .. reason)
                    sendToDiscord(GetPlayerName(source), targetPlayer, "timeout", timeoutMinutes, reason)
                end
            else
                TriggerClientEvent('chatMessage', source, '[SYSTEM]', {255, 0, 0}, 'You do not have permission to use this command.')
            end
        else
            TriggerClientEvent('chatMessage', source, '[SYSTEM]', {255, 0, 0}, 'Invalid or self player ID provided.')
        end
    else
        TriggerClientEvent('chatMessage', source, '[ERROR]', {255, 0, 0}, 'Invalid arguments. Usage: /timeout [playerId] [timeoutMinutes] [reason]')
    end
end, false)

RegisterCommand('untimeout', function (source, args)
    local playerId = tonumber(args[1])

    if playerId then
        local targetPlayer = nil

        for _, player in ipairs(GetPlayers()) do
            if tonumber(player) == playerId then
                targetPlayer = tonumber(player)
                break
            end
        end

        if targetPlayer and targetPlayer ~= source then
            if IsPlayerAceAllowed(source, Config.chat_time.admin) and not IsPlayerAceAllowed(source, Config.chat_time.bypass) then
                if IsPlayerTimedOut(targetPlayer) then
                    timeoutList[targetPlayer] = nil
                    local playerName = GetPlayerName(targetPlayer)
                    TriggerClientEvent('chatMessage', source, '[SYSTEM]', {255, 0, 0}, '' .. playerName .. ' has been untimed out.')
                    sendToDiscord(GetPlayerName(source), targetPlayer, "untimeout", 0, "Untimed Out")
                else
                    local playerName = GetPlayerName(targetPlayer)
                    TriggerClientEvent('chatMessage', source, '[SYSTEM]', {255, 0, 0}, '' .. playerName .. ' is not currently timed out.')
                end
            else
                TriggerClientEvent('chatMessage', source, '[SYSTEM]', {255, 0, 0}, 'You do not have permission to use this command.')
            end
        else
            TriggerClientEvent('chatMessage', source, '[SYSTEM]', {255, 0, 0}, 'Invalid or self player ID provided.')
        end
    else
        TriggerClientEvent('chatMessage', source, '[ERROR]', {255, 0, 0}, 'Invalid arguments. Usage: /untimeout [playerId]')
    end
end, false)



AddEventHandler('chatMessage', function(source, name, message)
    if IsPlayerTimedOut(source) and not IsPlayerAceAllowed(source, Config.chat_time.bypass) then
        CancelEvent()
        TriggerClientEvent('chatMessage', source, '[SYSTEM]', {255, 0, 0}, 'You are timed out. Please wait ' .. timeoutList[source].time .. ' seconds. Reason: ' .. timeoutList[source].reason)
    end
end)

