local cloneref = cloneref or function(ref: any)
    return ref
end

if isfolder('aethercorev2') then
    delfolder('aethercorev2')
end

cloneref(game:GetService('StarterGui')):SetCore('SendNotification', {
    Title = 'AetherCoreV2',
    Text = 'Successfully reinstalled AetherCoreV2, Please rejoin the game to take effect',
    Duration = 20
})