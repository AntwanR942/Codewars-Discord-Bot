--[[ Functions ]]
function HasPermission(Payload)
    local RequiredPermissions = {
        ["Add Reactions"] = 0x00000040,
        ["Send Messages"] = 0x00000800,
        ["Embed Links"] = 0x00004000, 
        ["Use External Emojis"] = 0x00040000
    }
    local BOTMember = Payload.guild:getMember(BOT.user.id)

    if not BOTMember or not Payload.channel then return false end

    local PObj = Payload.channel:getPermissionOverwriteFor(BOTMember.highestRole)

    if not PObj or not PObj.allowedPermissions then return false end

    local Permission = Discordia.Permissions(PObj.allowedPermissions)

    local NeededPerms = {}

    for Perm, PermHex in pairs(RequiredPermissions) do
        if not Permission:has(PermHex) then
            table.insert(NeededPerms, Perm)
        end
    end

    if #NeededPerms > 0 then
        return false, NeededPerms
    end

    return true
end