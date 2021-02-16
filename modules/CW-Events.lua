--[[ Events ]]
BOT:on("messageCreate", function(Payload)
	if Payload.author.bot or Payload.guild == nil then return end

	local Args = Payload.content:split(" ")

	if Args[1] then
		local Prefix = Config.Prefix
		if Args[1]:sub(1, #Prefix) == Prefix then
			local HasPerm, NeededPerms = HasPermission(Payload)

			if not HasPerm then 
				if Payload.guild.owner and NeededPerms then
					Payload.guild.owner:send(F("I am missing the following permissions in %s:\n**%s**", Payload.channel.mentionString, table.concat(NeededPerms, "\n")))
				end
				
				return 
			end

			local CommandArg = Args[1]:sub((#Prefix + 1), #Args[1])
			
			local Command = CommandManager.GetCommand(CommandArg)
			if not Command then
				Command = CommandManager.GetAliasCommand(CommandArg)
			end

			if Command then
				local CommandName = Command:GetName()

				Log(3, F("Command %s entered by %s", CommandName, Payload.author.tag))

				local CommandSuc, Err = pcall(function()
					if Args[2] then
						local CommandSub = Command:GetSubCommand(Args[2])
						if CommandSub then
							return CommandSub:Exec(Args, Payload)
						end
					end

					Command:Exec(Args, Payload)
				end)

				if not CommandSuc and Err ~= nil then
					Log(1, Err)

					FormatError(Err, Payload)
				end
			end
		end
	end
end)