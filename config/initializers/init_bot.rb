# config/initializers/init_bot.rb
require 'discordrb'
require_relative File.expand_path("init_scraper", __dir__)
require_relative File.expand_path("../../lib/discord/futbot", __dir__)

token = ENV.fetch('DISCORD_BOT_TOKEN')
bot   = Discordrb::Bot.new token: token

bot.message(start_with: 'fut!hoy')    { |e| Futbot.new(e).handle }
bot.message(start_with: 'fut!mañana') { |e| Futbot.new(e).handle }
bot.message(start_with: 'fut!ayer')   { |e| Futbot.new(e).handle }
bot.message(start_with: 'fut!lichi')  { |e| Futbot.new(e).handle_lichi }
bot.message(start_with: 'fut!mdc hoy') { |e| Futbot.new(e).handle_filtered('Mundial de Clubes') }


bot.run
