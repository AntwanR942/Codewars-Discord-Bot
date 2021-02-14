--[[ Function ]]
function FormatLeaderboardPosition(Pos)
    local Prefixes = {
        ["0"] = "th",
        ["1"] = "st",
        ["2"] = "nd",
        ["3"] = "rd",
        ["4"] = "th",
        ["5"] = "th",
        ["6"] = "th",
        ["7"] = "th",
        ["8"] = "th",
        ["9"] = "th",
    }

    local Pos = tostring(Pos)

    return Prefixes[Pos:sub(#Pos)]
end

function GetBestLangs(Languages)
    local Temp = {}

    for Lang, Data in pairs(Languages) do
        Data.LangName = Lang
        table.insert(Temp, Data)
    end
   
    table.sort(Temp, function(A, B)
        return A.score > B.score
    end)

    return Temp
end


--[[ Command ]]
CommandManager.Command("user", function(Args, Payload)
    local Suc, Username = pcall(GetUsername, Args, 2, Payload)
    assert(Suc ~= nil and Suc == true, FormatError(Username))

    local Suc, User = pcall(GetUser, Username)
    assert(Suc ~= nil and Suc == true, FormatError(User))

    local UserEmbed = {
        ["title"] = F("Codewars Statistics for %s", User.username),
        ["url"] = F("https://www.codewars.com/users/%s", User.username2),
        ["thumbnail"] = {
            ["url"] = (User.ranks.overall.name ~= nil and GetRankImage(User.ranks.overall.name) or "")
        },
        ["description"] = F("```Score : %s\nHonor : %s``` \n```Completed Kata : %s\nAuthored Kata  : %s\n \n(Inc. Kata in Beta)```", User.ranks.overall.score, User.honor, (User.codeChallenges and User.codeChallenges.totalCompleted or 0), (User.codeChallenges and User.codeChallenges.totalAuthored or 0)),
        ["color"] = Config.EmbedColour,
        ["fields"] = {}
    }

    if User.ranks and User.ranks.languages then
        local Languages = GetBestLangs(User.ranks.languages)

        UserEmbed.description = F("%s\n```\t\tTop Languages```", UserEmbed.description)

        for i = 1, (#Languages >= 12 and 12 or #Languages) do
            local Data = Languages[i]
            local Emoji = GetEmojiLang(Data.LangName)
            local Field = {
                ["name"] = (Emoji ~= nil and Emoji or Data.LangName),
                ["value"] = F("```Rank  : %s\nScore : %s```", Data.name, Data.score),
                ["inline"] = true
            }

            table.insert(UserEmbed.fields, Field)
        end
    else
        UserEmbed.description = F("%s\n```%s has not used any languages```", UserEmbed.description, User.username)
    end

    if User.leaderboardPosition then
        UserEmbed["footer"] = {
            ["text"] = F("%s%s on the Codewars leaderboard", User.leaderboardPosition, FormatLeaderboardPosition(User.leaderboardPosition))
        }
    end

    Payload:reply {
        embed = UserEmbed
    }
end):SetCategory("Codewars Commands"):SetDescription("Get statistics such as: rank, language rank(s) and more about a user on Codewars."):SetInfo("``"..Config.Prefix.."user [username of user on Codewars]``\n \nProvides statistics - if available - such as their rank, score, honor, number of completed & authored Kata, top (up to 12) languages and position on the Codewars leaderboard.")