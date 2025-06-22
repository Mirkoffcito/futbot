# init.rb (or wherever you wire up Discord)
require 'discordrb'
require_relative "init_scraper"
require_relative 'lib/discord/futbot'

token = ENV.fetch('DISCORD_BOT_TOKEN')
bot   = Discordrb::Bot.new token: token

bot.message(start_with: 'f!hoy')    { |e| Futbot.new(e).handle }
bot.message(start_with: 'f!mañana') { |e| Futbot.new(e).handle }
bot.message(start_with: 'f!ayer')   { |e| Futbot.new(e).handle }
bot.message(start_with: 'f!lichi') { |e| Futbot.new(e).handle_lichi }

bot.run
