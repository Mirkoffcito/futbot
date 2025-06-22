require_relative "../init_scraper"

SiteScraper.new(output_path: "./tmp/output.jsonl").export_to_jsonl!