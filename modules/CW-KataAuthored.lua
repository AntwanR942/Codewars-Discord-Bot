--[[ Functions ]]
function ConstructAuthoredEmbed(User, SubPage)
    local Kata = User.data[SubPage]
    local TotalCharCount = 0

    Kata.description = ParseKataDescription(Kata)

    local Embed = {
        ["title"] = Kata.name,
        ["url"] = F("https://www.codewars.com/kata/%s/train)", Kata.id),
        ["thumbnail"] = {
            ["url"] = (Kata.rankName ~= nil and GetRankImage(Kata.rankName) or "")
        },
        ["description"] = "",
        ["color"] = Config.EmbedColour,
        ["fields"] = {},
        ["footer"] = {
            ["text"] = F("Kata %s/%s • Authored Kata by %s", SubPage, User.totalSubPages, User.username)
        }
    }
 
    Embed.description = (#Embed.description + #Kata.description <= 2048 and Kata.description or Kata.description:sub(1, 2048 - (#Embed.description + 3)).."...")

    for _, Element in pairs(Embed) do
        if type(Element) == "string" then
            TotalCharCount = TotalCharCount + #Element
        end
    end

    local Fields = math.ceil((#Kata.languages *  LongestEmoji)/1024)
    local Duplicates = {}

    for Field = 1, Fields do
        local Langs = {}

        for x = ((Field - 1) * 32) + 1, (#Kata.languages >= Field * 32 and Field * 32 or #Kata.languages) do
            local Lang = Kata.languages[x]

            if not Duplicates[Lang] then
                table.insert(Langs, GetEmoji(Lang))

                Duplicates[Lang] = true
            end
        end

        if #Langs > 0 then
            table.insert(Embed.fields, {
                ["name"] = (Field == 1 and "Available Languages" or "** **"),
                ["value"] = table.concat(Langs, " "),
                ["inline"] = true
            })
        end
    end

    return Embed
end

RegisterEmojiPagingBehvaiour("Authored", function(Context, Msg)
    local Suc, User = pcall(GetUserAuthoredKata, Context.Username)

    print(Suc, "getting user authored")

    if Suc and User then
        local UserEmbed = ConstructAuthoredEmbed(User, Context.NextSubPage + 1)

        local Suc, Err = Msg:setEmbed(UserEmbed)

        print(Suc, "constructing embed")

        if not Suc and Err then
            Log(1, Err)
        end

        if Suc and not Err then
            Context.SubPage = Context.NextSubPage
        end
    end
end)

--[[ Commands ]]
KataCommands = CommandManager.Command("kata", function() end):SetCategory("Codewars Commands")

KataCommands:AddSubCommand("authored", function(Args, Payload)
    local Suc, Username = pcall(GetUsername, Args, 3, Payload)
    assert(Suc ~= nil and Suc == true, FormatError(Username))

    local Suc, User = pcall(GetUserAuthoredKata, Username, 0)
    assert(Suc ~= nil and Suc == true, FormatError(User))

    local UserEmbed = ConstructAuthoredEmbed(User, 1)

    local Msg, Err = Payload:reply {
        embed = UserEmbed
    }

    if not Suc and Err then
        Log(1, Err)
    end

    if Msg and User.totalSubPages > 1 then
        RegisterEmojiPaging(Msg, {
            ["Username"] = User.username2,
            ["TotalSubPages"] = User.totalSubPages,
            ["Type"] = "Authored"
        })
    end
end):SetDescription("Get authored Kata by a User on Codewars along with available languages and more!"):SetInfo("``"..Config.Prefix.."kata authored [username of user on CodeWars]``\n \nProvides all - if any - authored Kata, available languages and a description of the Kata. If there are multiple then use the orange arrow emojis to navigate the authored Kata pages.")