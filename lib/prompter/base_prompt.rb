class BasePrompt
  class Error < StandardError; end
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::AttributeAssignment
  PROMPT_PATH = File.expand_path("data/prompts/base_prompt.txt", Dir.pwd)


  def send_request
    request = chat_completion_request.transform_keys(&:to_sym)
    raise "🚨 Missing model!" unless request[:model]
    puts "🔍 Final request: #{request.inspect}"

    client.chat.completions.create(**request)
  end

  def chat
    send_request.choices[0].message.content
  end

  def chat_completion_request
    build_request_body(:model, :messages, :temperature)
  end


  def configuration
    raise NotImplementedError, "Subclasses must implement #configuration"
  end

  def client
    token = ENV.fetch("OPENAI_ACCESS_TOKEN") { raise "Missing required environment variable: OPENAI_ACCESS_TOKEN" }
    @client ||= OpenAI::Client.new(api_key: token)
  end

  private

  def build_request_body(*keys)
    config = configuration.transform_keys(&:to_sym)
    body = config.slice(*keys)

    if keys.include?(:body)
      extra = config.slice(:method, :url, :custom_id)
      { **extra, body: body }
    else
      body
    end
  end

end