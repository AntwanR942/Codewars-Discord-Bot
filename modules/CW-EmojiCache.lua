--[[ Variables ]]
local FileName = "CW-EmojiCache.jsonc"
local EmojiCache = assert(FileReader.readFileSync(Config.ModuleDir.."/"..FileName),  F(Error["NoFile"], Config.ModuleDir, FileName))
local EmojiCache = assert(JSON.decode(EmojiCache))

local EmojiPattern = "<:%s:%s>"

LongestEmoji = 0
for _, Emoji in pairs(EmojiCache) do
    if Emoji.EName and Emoji.EID then
        LongestEmoji = math.max(LongestEmoji, #F(EmojiPattern, Emoji.EName, Emoji.EID))
    end
end

--[[ Functions ]]
function GetRankImage(kyu)
    return (EmojiCache[kyu] ~= nil and EmojiCache[kyu].url or nil)
end

function GetEmojiData(EmojiName)
    if EmojiCache[EmojiName] ~= nil then
        return EmojiCache[EmojiName]
    end 
end

function GetEmoji(EmojiName)
    if EmojiCache[EmojiName] ~= nil then
        local Emoji = EmojiCache[EmojiName]

        return F(EmojiPattern, Emoji.EName, Emoji.EID)
    end 
end

function GetEmojiLang(EmojiName)
    if EmojiCache[EmojiName] ~= nil then
        local Emoji = EmojiCache[EmojiName]

        return F(EmojiPattern.." %s", Emoji.EName, Emoji.EID, Emoji.LName)
    end 
end