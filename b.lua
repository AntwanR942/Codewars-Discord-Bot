--[[ External Librarys ]]
JSON = require("json")
Routine = require("timer")
HTTP = require("coro-http")
Query = require("querystring")
FileReader = require("fs")
PP = require("pretty-print")

--[[ Fatal Errors (Will prevent the Bot from starting) ]]
Error = {
	["NoFile"] = "fatal: Could not find/read required file. Please create a file in %s called %s",
	["NoParse"] = "fatal: Could not parse required file. Please ensure the file %s in %s contains valid content."
}

--[[ Config ]]
Config, ConfigErr = FileReader.readFileSync("Config.jsonc")

if Config and not ConfigErr then
	Config = assert(JSON.decode(Config), string.format(Error["NoParse"], "Config.jsonc", "your Bot directory"))
else
	print(os.date("%F @ %T", os.time()).." | [WARNING] | Reverting to default config "..(ConfigErr ~= nil and (": "..ConfigErr) or ""))
	Config = {
		["EmbedColour"] = "12272428",
		["Prefix"] = ">",
		["ModuleDir"] = "./modules",
		["_DEBUG"] = false,
		["PrettyJSON"] = true
	}
end

--[[ Discord Utils ]]
Discordia = require("discordia")
BOT = Discordia.Client {
	cacheAllMembers = true,
	dateTime = "%F @ %T",
	logLevel = (Config._DEBUG == false and 3 or 4)
}
Discordia.extensions()

--[[ Command Handler ]]
CommandManager = require("./libs/CommandManager")

--[[ Logger ]]
Logger = Discordia.Logger((Config._DEBUG == false and 3 or 4), "%F @ %T")
Log = function(Level, ...) if Config._DEBUG == false and Level > 2 then return end Logger:log(Level, ...) end

--[[ Functions ]]
function SimpleEmbed(Payload, Description)
	local Embed = {
		["description"] = Description,
		["color"] = Config.EmbedColour
	}

	if Payload then
		local Suc, Err = Payload:reply {
			embed = Embed
		} 

		return Suc, Err
	end

	return Embed
end

function ReturnRestOfCommand(AllArgs, StartIndex, Seperator, EndIndex)
    return table.concat(AllArgs, (Seperator ~= nil and type(Seperator) == "string" and Seperator or " "), StartIndex, EndIndex)
end

function FormatError(ErrStr, Payload)
	if ErrStr and type(ErrStr) == "string" then
		local Line, Err = ErrStr:match(":(%d+):(.+)")
						
		if Err and #Err > 1 then	
			if Payload then
				SimpleEmbed(Payload, Payload.author.mentionString.." "..Err)
			end

			return Err
		end
	end
end

function ParseKataDescription(Kata)
	Kata.description = Kata.description:gsub("<code>", "``"):gsub("</code>", "``"):gsub("<sub>(.)</sub>", ""):gsub("<sup>", "^"):gsub("</sup>", ""):gsub("(#+)", "")
	
	if Kata.languages and #Kata.languages > 0 then
		local InsideCodeblock = false
		local Qoutes = 0
		local ExampleStart, ExampleEnd
		local FirstExampleStart, LastExampleEnd
		local Example

		for i = 1, #Kata.description, 1 do
			local Char = Kata.description:sub(i, i)
		
			if Char == "`" then
				Qoutes = Qoutes + 1
			else
				Qoutes = 0
			end
		
			if Qoutes == 3 then
				if not Kata.description:sub(i + 1, i):match("%s") then
					if not InsideCodeblock then
						for _, Lang in pairs(Kata.languages) do
							if Kata.description:sub(i + 1, i + #Lang) == Lang then

								InsideCodeblock = true
								ExampleStart = i - 2
				
								break
							end
						end
					else
						ExampleEnd = i
						LastExampleEnd = ExampleEnd
		
						if not FirstExampleStart then
							Example = Kata.description:sub(ExampleStart, ExampleEnd)

							FirstExampleStart = ExampleStart
						end
		
						ExampleStart, ExampleEnd = nil, nil
						InsideCodeblock = false
					end
				end
			end
		end
		
		if Example and FirstExampleStart and LastExampleEnd then
			Kata.description = Kata.description:sub(1, FirstExampleStart - 1)..Example..Kata.description:sub(LastExampleEnd + 1, #Kata.description)
		end
	end

	return Kata.description
end

--[[ Module Func ]]
local function LoadModule(Module)
	local FilePath = Config.ModuleDir.."/"..Module..".lua"
	local Code = assert(FileReader.readFileSync(FilePath))
	local Func = assert(loadstring(Code, "@"..Module, "t", ModuleENV))

	return (Func() or {})
end

--[[ Init ]]
do
	local _Token = assert(FileReader.readFileSync("./.token"), "Could not find bot token. Please create a file called .token in the directory of your bot and put your bot token inside of it.")

	ModuleENV = setmetatable({
		require = require,

		Discordia = Discordia,
		BOT = BOT,

		JSON = JSON,
		Routine = Routine,
		HTTP = HTTP,
		FileReader = FileReader,
		PP = PP,
		Query = Query,

		Config = Config,

		CommandManager = CommandManager,

		Log = Log, 
		Logger = Logger,
		Round = math.round,
		F = string.format,
		SimpleEmbed = SimpleEmbed,
		ReturnRestOfCommand = ReturnRestOfCommand,
		FormatError = FormatError,
		ParseKataDescription = ParseKataDescription,

		ModuleDir = Config.ModuleDir,
		Error = Error
	}, {__index = _G})

	assert(FileReader.existsSync(Config.ModuleDir), "Could not find module directory, are you sure it is valid?")

	for File, Type in FileReader.scandirSync(Config.ModuleDir) do
		if Type == "file" then
			local FileName = File:match("(.*)%.lua")
			if FileName then
				local Suc, Err = pcall(LoadModule, FileName)

				if Suc == true then
					Log(3, "Module loaded: "..FileName)
				else
					Log(1, "Failed to load module "..FileName.." ["..Err.."]")

					if Err:lower():find("fatal") then
						_G = nil

						process:exit(1)
					end
				end
			end
		end
	end

	BOT:run("Bot ".._Token)
end