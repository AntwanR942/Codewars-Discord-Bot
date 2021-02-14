--[[ Functions ]]
function ConstructCompletedEmbed(User, Kata, SubPage)
    local TotalCharCount = 0
    local UserKata = User.data[SubPage]

    Kata.description = ParseKataDescription(Kata)

    local Embed = {
        ["title"] = Kata.name,
        ["url"] = F("https://www.codewars.com/kata/%s/train", Kata.id),
        ["thumbnail"] = {
            ["url"] = (Kata.rank and Kata.rank.name ~= nil and GetRankImage(Kata.rank.name) or Kata.rankName ~= nil and GetRankImage(Kata.rankName) or "")
        },
        ["description"] = "",
        ["color"] = Config.EmbedColour,
        ["fields"] = {},
        ["footer"] = {
            ["text"] = F("Kata %s/%s • Completed Kata by %s", SubPage, User.totalItems, User.username)
        }
    }

    Embed.description = (#Embed.description + #Kata.description <= 2048 and Kata.description or Kata.description:sub(1, 2048 - (#Embed.description + 3)).."...")

    for _, Element in pairs(Embed) do
        if type(Element) == "string" then
            TotalCharCount = TotalCharCount + #Element
        end
    end

    local Fields = math.ceil((#UserKata.completedLanguages *  LongestEmoji)/1024)
    local Duplicates = {}

    for Field = 1, Fields do
        local Langs = {}

        for x = ((Field - 1) * 32) + 1, (#UserKata.completedLanguages >= Field * 32 and Field * 32 or #UserKata.completedLanguages) do
            local Lang = UserKata.completedLanguages[x]

            if not Duplicates[Lang] then
                table.insert(Langs, GetEmoji(Lang))

                Duplicates[Lang] = true
            end
        end

        if #Langs > 0 then
            table.insert(Embed.fields, {
                ["name"] = (Field == 1 and "Completed Languages" or "** **"),
                ["value"] = table.concat(Langs, " "),
                ["inline"] = true
            })
        end
    end

    return Embed
end

RegisterEmojiPagingBehvaiour("Completed", function(Context, Msg)
    local Suc, User = pcall(GetUserCompletedKata, Context.Username, Context.NextPage)

    if Suc and User then
        local Suc, Kata =  pcall(GetKata, User.data[Context.NextSubPage + 1].id)

        if Suc and Kata then
            local UserEmbed = ConstructCompletedEmbed(User, Kata, Context.NextSubPage + 1)

            local Suc, Err = Msg:setEmbed(UserEmbed)

            if not Suc and Err then
                Log(1, Err)
            end

            if Suc and not Err then
                Context.Page = Context.NextPage
                Context.SubPage = Context.NextSubPage
            end
        end
    end
end)

--[[ Commands ]]
KataCommands:AddSubCommand("completed", function(Args, Payload)
    local Suc, Username = pcall(GetUsername, Args, 3, Payload)
    assert(Suc ~= nil and Suc == true, FormatError(Username))

    local Suc, User = pcall(GetUserCompletedKata, Username, 0)
    assert(Suc ~= nil and Suc == true, FormatError(User))

    local Suc, Kata = pcall(GetKata, User.data[1].id)
    assert(Suc ~= nil and Suc == true, FormatError(Kata))

    local UserEmbed = ConstructCompletedEmbed(User, Kata, 1)

    local Msg, Err = Payload:reply {
        embed = UserEmbed
    }

    if not Suc and Err then
        Log(1, Err)
    end

    if Msg and User.totalItems > 1 then
        RegisterEmojiPaging(Msg, {
            ["Username"] = User.username2,
            ["TotalSubPages"] = User.totalItems,
            ["Type"] = "Completed"
        })
    end
end):SetDescription("Get completed Kata by a User on Codewars along with the languages they have been completed in and more!"):SetInfo("``"..Config.Prefix.."kata completed [username of user on CodeWars]``\n \nProvides all - if any - completed Kata and the languages they were completed in. If there are multiple then use the orange arrow emojis to navigate the completed Kata pages.")