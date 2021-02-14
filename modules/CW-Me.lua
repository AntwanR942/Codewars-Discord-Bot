--[[ Command ]]
CommandManager.Command("info", function(Args, Payload)
    SimpleEmbed(Payload, [[
        Hi, my name is Anthony but those who know me call me Tony! 

        I made this bot in my spare time as a fun side project since I enjoy Codewars and making Discord bots.

        This bot is completely open source and can be found on my GitHub [here]() along with my other programming ventures.

        If you feel generous and want to support me and my work then you can [buy me a coffee :coffee:](https://www.buymeacoffee.com/AntwanR942).

        Thank you for using my bot and have a good day legend!
    ]])
end):SetCategory("Misc"):SetDescription("Some info about the bot and it's creator!")