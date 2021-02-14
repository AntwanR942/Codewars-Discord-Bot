--[[ Variables ]]
local FileName = "CW-PageCache.json"
local PageMsgCache = assert(FileReader.readFileSync(Config.ModuleDir.."/"..FileName), F(Error["NoFile"], Config.ModuleDir, FileName))
local PageMsgCache = assert(JSON.decode(PageMsgCache), F(Error["NoParse"], FileName, Config.ModuleDir))

local ArrowLEID, ArrowLName = "806477148332228610", "cwarrowl"
local ArrowREID, ArrowRName = "806477148717711440", "cwarrowr"

local SavePeriod = 1 -- Every second

local PagingBehvaiour = {}

--[[ Events ]]
BOT:on("ready", function()
    ArrowL, ArrowR = assert(BOT:getEmoji(ArrowLEID)), assert(BOT:getEmoji(ArrowREID))
end)

--[[ Functions ]]
function RegisterEmojiPagingBehvaiour(Type, f)
    PagingBehvaiour[Type] = f
end 

function RegisterEmojiPaging(Msg, Context)  
    if Msg and Msg.id then
        Msg:addReaction(ArrowL)
        Msg:addReaction(ArrowR)

        Context["Page"] = 0
        Context["SubPage"] = 0

        PageMsgCache[Msg.id] = Context
    end
end

function RemoveEmojiPaging(MID)
    if PageMsgCache[MID] then
        PageMsgCache[MID] = nil
    end
end

function HandleEmojiPaging(CID, MID, EHash)
    if PageMsgCache[MID] then
        local Context = PageMsgCache[MID]

        if not PagingBehvaiour[Context.Type] then
            return
        end

        local Msg = BOT:getChannel(CID):getMessage(MID)

        if not Msg then
            return 
        end

        if EHash == ArrowLEID or EHash == ArrowLName then
            if Context.SubPage <= 0 then
                return
            end

            Context.NextSubPage = Context.SubPage - 1
        elseif EHash == ArrowREID or EHash == ArrowRName then
            if Context.SubPage >= (Context.TotalSubPages - 1) then
                return
            end

            Context.NextSubPage = Context.SubPage + 1
        end

        Context.NextPage = math.ceil(Context.NextSubPage/200) - 1

        PagingBehvaiour[Context.Type](Context, Msg)
    end
end

--[[ Events ]]
BOT:on("reactionAdd", function(Reaction, UID)
    if UID == BOT.user.id then
        return
    end

    HandleEmojiPaging(Reaction.message.channel.id, Reaction.message.id, Reaction.emojiName)
end)

BOT:on("reactionAddUncached", function(CID, MID, EHash, UID)
    if UID == BOT.user.id then
        return
    end

    HandleEmojiPaging(CID, MID, EHash)
end)

BOT:on("messageDelete", function(Msg)
    if Msg.id then
        RemoveEmojiPaging(Msg.id)
    end
end)

BOT:on("messageUpdateUncached", function(_, MID)
    if MID then 
        RemoveEmojiPaging(MID)
    end
end)

--[[ Routined Save ]]
Routine.setInterval(SavePeriod * 1000, function()
    coroutine.wrap(function()
        pcall(function()
            local EncodedCache = JSON.encode(PageMsgCache, { indent = Config.PrettyJSON })
                
            if EncodedCache then
                FileReader.writeFileSync(Config.ModuleDir.."/"..FileName, EncodedCache)
            end
        end)
    end)()
end)