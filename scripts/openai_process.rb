## Scrapes raw text from the URLs CSV file and processes it using the OpenAI API and outputs the processed content over to data/outputs/scraper_processed_output.jsonl

require_relative File.expand_path("config/initializers/init_scraper.rb", Dir.pwd)
SiteScraper.new().process_file(File.expand_path("data/outputs/scraper_output.jsonl", Dir.pwd))