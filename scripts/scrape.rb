## Scrapes raw text from the URLs CSV file and outputs the content over to data/outputs/scraper_output.jsonl

require_relative File.expand_path("config/initializers/init_scraper.rb", Dir.pwd)
SiteScraper.new(output_path: File.expand_path("data/outputs/scraper_output.jsonl", Dir.pwd)).export_to_jsonl!