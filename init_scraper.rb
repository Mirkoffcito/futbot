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
ENV['TZ'] = 'America/Argentina/Cordoba'


Dir[File.expand_path('./lib/**/*.rb', __dir__)].reject { |f| f.start_with?(File.expand_path('./lib/discord', __dir__)) }.sort.each do |file|
  require_relative file
end

include Loggable
