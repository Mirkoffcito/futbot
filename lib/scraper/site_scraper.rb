class SiteScraper < BaseScraper
  MAIN_SELECTOR = ".layout_wrapper__Q_xJ7".freeze
  USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36".freeze
  TIMEOUT = 120_000

  # accept urls at init time
  def initialize(urls: nil, output_path: "output.jsonl")
    super(output_path: output_path)
    @injected_urls = urls
  end

  def urls
    @injected_urls || csv_urls
  end

  def run(browser, urls = nil)
    urls ||= self.urls

    log "Starting SiteScraper with #{urls.size} URLs to process..."

    if urls.empty?
      log "No URLs provided. Exiting."
      return
    end

    log "Using user agent: #{USER_AGENT}"
    log "Using timeout: #{TIMEOUT / 1000} seconds"
    urls.each do |url|
      context = browser.new_context(userAgent: USER_AGENT, timezoneId: "America/Argentina/Cordoba", locale: "es-AR", :viewport => { width: 1280, height: 800 })
      page = context.new_page
      log "Go to page #{url}"
      page.goto(url, waitUntil: "domcontentloaded", timeout: TIMEOUT)

      log "Waiting for selector #{MAIN_SELECTOR}"
      page.wait_for_selector(MAIN_SELECTOR, timeout: TIMEOUT)
      log "Processing data..."

      data = page.locator(MAIN_SELECTOR)&.text_content
      # byebug
      log "Sending data to OpenAI..."
      prompt = ExtractionPrompt.new(content: data)
      ai_extract_data_result = prompt.chat

      log "Parsing response..."
      ai_response = JSON.parse(ai_extract_data_result)
      # byebug
      log "Extracted data:\n#{JSON.pretty_generate(ai_response)}"

      log "Closing page #{url}..."

      yield ai_response if block_given?

      sleep(0.5 + rand(0.5))
    rescue => e
      log "Failed to process #{url}: #{e.message}"
      next
    ensure
      page.close
    end
  end

  def raw_text(browser, urls = nil)
    urls ||= self.urls
    log "Starting scraper for #{urls.size} URLs…"
    return if urls.empty?

    urls.each do |url|
      context = browser.new_context(
        userAgent: USER_AGENT,
        timezoneId: "America/Argentina/Cordoba",
        locale: "es-AR",
        viewport: { width: 1280, height: 800 }
      )
      page = context.new_page
      log "→ Visiting #{url}"
      page.goto(url, waitUntil: "domcontentloaded", timeout: TIMEOUT)

      page.wait_for_selector(MAIN_SELECTOR, timeout: TIMEOUT)
      text = page.locator(MAIN_SELECTOR)&.text_content.to_s.strip

      record = {
        url:       url,
        ## Use local timezone for timestamp (UTC-3)
        timestamp: Time.now.getlocal('-03:00').iso8601,
        content:   text
      }

      yield record

    rescue => e
      log "Failed on #{url}: #{e.class} #{e.message}"
    ensure
      page&.close
      sleep(0.5 + rand(0.5))
    end
  end

  ## Description: Takes a JSONL file as the input and reads each line. It reads the 'content' key's value and sends it
  #  over to OPENAI for processing by using the ExtractionPrompt#chat function, which returns the processed content in JSON format.
  #  Finally, it stores the processed value in a new key called "processed_content".
  def process_file(input_path = @output_path, output_path = nil)
    output_path ||= input_path.sub('.jsonl', '_processed.jsonl')
    
    log "Processing file #{input_path}..."
    processed_records = []
    
    # Read each line from the input file
    File.readlines(input_path, chomp: true).each_with_index do |line, index|
      begin
        # Parse the JSON line
        record = JSON.parse(line)
        
        # Extract the content
        content = record['content']
        timestamp = record['timestamp']
        url = record['url']
        
        if content.nil? || content.empty?
          log "Warning: Line #{index + 1} has no content, skipping"
          processed_records << record
          next
        end
        
        log "Processing content from line #{index + 1}..."
        
        # Send to OpenAI for processing
        prompt = ExtractionPrompt.new(content: content)
        ai_result = prompt.chat
        
        # Parse the AI response
        processed_content = JSON.parse(ai_result)
        
        # Add the processed content to the record
        record['processed_content'] = processed_content
        
        # Add to processed records
        processed_records << record
        
        log "Successfully processed line #{index + 1}"
      rescue => e
        log "Error processing line #{index + 1}: #{e.message}"
        # Keep the original record if there was an error
        processed_records << record if defined?(record)
      end
    end
    
    # Write the processed records to the output file
    File.open(output_path, 'w') do |file|
      processed_records.each do |record|
        file.puts(record.to_json)
      end
    end
    
    log "Processing complete. Processed #{processed_records.size} records."
    log "Output written to #{output_path}"
    
    return processed_records
  end

  private

  def csv_urls
    File.readlines('urls.csv', chomp: true)
  end
end
