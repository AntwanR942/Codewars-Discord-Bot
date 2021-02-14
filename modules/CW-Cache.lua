--[[ Variables ]]
local FileName = "CW-Cache.json"
local Cache = assert(FileReader.readFileSync(Config.ModuleDir.."/"..FileName), F(Error["NoFile"], Config.ModuleDir, FileName))
local Cache = assert(JSON.decode(Cache), F(Error["NoParse"], FileName, Config.ModuleDir))

local SavePeriod = 1 -- Every second

--[[ Functions ]]
local TypeFunctions = {
    ["Completed"] = function(Record, Username, Page) 
        Cache["Completed"][Username][Page] = Record
    end
}

function CacheRecord(Type, Record, Username, ...)
    if Cache[Type] == nil then
        Cache[Type] = {}
    end

    if not Cache[Type][Username] then
        Cache[Type][Username] = {}
    end

    if TypeFunctions[Type] then
        TypeFunctions[Type](Record, Username, ...)
    else
        Cache[Type][Username] = Record
    end

    Cache[Type][Username].fetched = os.time()
end

function GetCachedRecord(Type, Username)
    if Cache[Type] and Cache[Type][Username] ~= nil then
        local Record = Cache[Type][Username]

        if (os.time() - Record.fetched) > Config.CacheUpdate then
            Cache[Type][Username] = nil

            return
        end

        return Cache[Type][Username]
    end
end

--[[ Routined Save ]]
Routine.setInterval(SavePeriod * 1000, function()
    coroutine.wrap(function()
        pcall(function()
            local EncodedCache = JSON.encode(Cache, { indent = Config.PrettyJSON })
                
            if EncodedCache then
                FileReader.writeFileSync(Config.ModuleDir.."/"..FileName, EncodedCache)
            end
        end)
    end)()
end)