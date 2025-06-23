# config/initializers/init_scraper.rb
require "active_model"
require "active_model/attributes"
require "active_model/attribute_assignment"
require "byebug"
require "csv"
require "dotenv/load"
require "fileutils"
require "logger"
require "openai"
require "playwright"
require_relative File.expand_path("lib/loggable.rb", Dir.pwd)
ENV['TZ'] = 'America/Argentina/Cordoba'

%w[scraper prompter].each do |folder|
  Dir[File.expand_path("lib/#{folder}/*.rb", Dir.pwd)].sort.each do |file|
    require_relative file
  end
end

include Loggable
