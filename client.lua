Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/timeout', 'time out a user from using the chat', {
        {name = 'playerId', help = 'The ID of the player you want to time out'},
        {name = 'timeoutMinutes', help = 'The number of minutes you want to time out the player for'},
        {name = 'reason', help = 'The reason for timing out the player'}
    })
    TriggerEvent('chat:addSuggestion', '/untimeout', 'untime out a user from using the chat', {
        {name = 'playerId', help = 'The ID of the player you want to untime out'}
    })
end)
