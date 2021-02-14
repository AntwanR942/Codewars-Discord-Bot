--[[ Events ]]
BOT:once("ready", function()
	BOT:setGame{
		["name"] = Config.Prefix.."help",
		["type"] = 3
	}
end)

--[[ Command ]]
CommandManager.Command("help", function(Args, Payload)
	if Args[2] then
		local Command = CommandManager.GetCommand(Args[2])
		
		if not Command then
			Command = CommandManager.GetAliasCommand(Args[2])
		end

		assert(Command ~= nil, "that command does not exist.")

		if Args[3] then
			if Command:GetSubCommand(Args[3]) then
				Command = Command:GetSubCommand(Args[3])
			end
		end

		local CommandInfo = Command:GetInfo()
		assert(CommandInfo, "there is no additional info for that command.")

		return SimpleEmbed(Payload, F("Additional info for command: ``%s``\n \n%s", Command:GetName(), CommandInfo))
	end

	local AllCommands = {}
	
	for CommandName, Command in pairs(CommandManager.GetAllCommands()) do
		local CommandCategory = Command:GetCategory()

		if CommandCategory then
			if AllCommands[CommandCategory] == nil then
				AllCommands[CommandCategory] = {}
			end

			local CommandDescription = Command:GetDescription()

			table.insert(AllCommands[CommandCategory], F("``%s%s`` %s", Config.Prefix, CommandName, (CommandDescription ~= nil and F("*%s*", CommandDescription) or "")))

			local SubCommands = CommandManager.GetAllSubCommands(CommandName)
			if SubCommands then
				for _, SubCommand in pairs(SubCommands) do
					local CommandDescription = SubCommand:GetDescription()

					table.insert(AllCommands[CommandCategory], F("``↳ %s`` %s", SubCommand:GetName(), (CommandDescription ~= nil and F("*%s*", CommandDescription) or "")))
				end
			end
		end
	end

	local HelpEmbed = {
		["title"] = "Here are all of my commands",
		["color"] = Config.EmbedColour,
		["description"] = "",
		["footer"] = {
			["text"] = F("Do %shelp [command] [, sub-command] for additional info about a command or sub-command.", Config.Prefix)
		}
	}

	for CommandCategory, Commands in pairs(AllCommands) do
		HelpEmbed.description = HelpEmbed.description..F("\n\n__%s__\n%s", CommandCategory, table.concat(Commands, "\n"))
	end

	Payload:reply {
		embed = HelpEmbed
	}
end)