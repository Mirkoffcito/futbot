class BaseScraper
  PLAYWRIGHT_BIN = "./node_modules/.bin/playwright".freeze
  attr_reader :output_path

  def initialize(output_path: "output.jsonl")
    @output_path = output_path
  end

  def export_to_json!
    unless File.exist?(PLAYWRIGHT_BIN)
      raise "Playwright CLI not found at #{PLAYWRIGHT_BIN}"
    end

    Playwright.create(playwright_cli_executable_path: PLAYWRIGHT_BIN) do |pw|
      pw.chromium.launch(headless: true) do |browser|
        File.open(output_path, "a") do |file|
          run(browser) do |data|
            file.puts(data.to_json) if data.present?
          end
        end
        browser.close 
      end
    end
  end

  def export_to_jsonl!
    ensure_playwright!
    Playwright.create(playwright_cli_executable_path: PLAYWRIGHT_BIN) do |pw|
      pw.chromium.launch(headless: true) do |browser|
        File.open(output_path, "a") do |file|
          raw_text(browser) do |record|
            # record is { url:, timestamp:, content: }
            file.puts(record.to_json) if record[:content]&.strip&.length&.positive?
          end
        end
        browser.close
      end
    end
  end

  def run(browser)
    raise NotImplementedError, "Subclasses must implement `extract_and_process`"
  end

  def urls
    raise NotImplementedError, "Subclasses must implement `urls`"
  end

  private

  def ensure_playwright!
    unless File.exist?(PLAYWRIGHT_BIN)
      raise "Playwright CLI not found at #{PLAYWRIGHT_BIN}"
    end
  end
end