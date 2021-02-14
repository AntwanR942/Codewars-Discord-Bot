--[[ Variables ]]
local FileName = "CW-API.txt"
local APIKey = assert(FileReader.readFileSync(Config.ModuleDir.."/"..FileName), F(Error["NoFile"], Config.ModuleDir, FileName))

local BaseURL = "https://www.codewars.com/api/v1/"

local Responses = {
    ["Default"] = "there was a problem, please try again.",

    [404] = "I couldn't find what you were looking for. Are you sure the information you provided is correct?",
    [429] = "too many requests have been made to the Codewars API, please try again in a moment.",
    [500] = "there was an issue with the Codewars API, please try again in a moment.",
    [503] = "the Codewars API is offline, please try again later."
}

local RateLimited = false

--[[ Functions ]]
local function CodewarsAPI(Route)
    assert(RateLimited == false, Responses[429])

    local Res, Body = HTTP.request("GET", BaseURL..Route, { { "Authorization", APIKey } })

    Res, Body = assert(JSON.decode(JSON.encode(Res)), Responses.Default), assert(JSON.decode(Body), Responses.Default)

    if Res.code == 429 then
        RateLimited = true
    end

    assert(Res.code == 200, (Responses[Res.code] ~= nil and Responses[Res.code] or Responses.Default))

    return Body
end

function GetUsername(Args, StartIndex, Payload)
    assert(#Args >= StartIndex, "please provide the name of a user on Codewars.")

    local Username = assert(ReturnRestOfCommand(Args, StartIndex), Responses.Default)

    Username = assert(Query.urlencode(Username), Responses.Default)

    return Username
end
    
function GetUser(Username)
    local User = GetCachedRecord("User", Username)

    if User then
        return User
    end

    Suc, User = pcall(CodewarsAPI, F("users/%s", Username))
    assert(Suc == true, FormatError(User))

    User.username2 = Username

    CacheRecord("User", User, User.username)

    return User
end 

function GetUserCompletedKata(Username, Page)
    local Page = tostring(Page)
    local User = GetCachedRecord("Completed", Username)

    if User and User[Page] then
        return User[Page]
    end

    Suc, User = pcall(CodewarsAPI, F("users/%s/code-challenges/completed?page=%s", Username, Page))
    assert(Suc == true, FormatError(User))

    User.totalSubPages = #User.data
    User.username = assert(Query.urldecode(Username), Responses.Default)
    User.username2 = Username

    CacheRecord("Completed", User, User.username, Page)

    return User
end

function GetKata(ID)
    local Kata = GetCachedRecord("Kata", ID)

    if Kata then
        return Kata
    end

    Suc, Kata = pcall(CodewarsAPI, F("code-challenges/%s", ID))
    assert(Suc == true, FormatError(Kata))

    CacheRecord("Kata", Kata, ID)


    return Kata
end

function GetUserAuthoredKata(Username)
    local Page = "0"
    local User = GetCachedRecord("Authored", Username)

    if User then
        return User
    end

    Suc, User = pcall(CodewarsAPI, F("users/%s/code-challenges/authored", Username))
    assert(Suc == true, FormatError(User))

    assert(User.data and #User.data > 0, "the user provided has not authored any Kata challenges on Codewars.")

    User.totalSubPages = #User.data
    User.username = assert(Query.urldecode(Username), Responses.Default)
    User.username2 = Username

    CacheRecord("Authored", User, User.username, Page)

    if User.totalSubPages > 0 then
        for _, Kata in pairs(User.data) do
            CacheRecord("Kata", Kata, Kata.id)
        end
    end

    return User
end