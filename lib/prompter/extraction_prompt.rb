class ExtractionPrompt < BasePrompt
  MAX_TOKENS = 1000.freeze

  attribute :content

  def configuration
    {
      method: "POST",
      url: "/v1/chat/completions",
      # model: "gpt-4.1-nano", # Default model
      model: "ft:gpt-4.1-nano-2025-04-14:personal::BlQTsRpc", # Your trained model
      temperature: 0.2,
      messages: [
        system_message,
        user_message(content)
      ]
    }
  end

  def user_message(content)
    {role: "user", content: content}
  end

  def system_message
    msg = File.read(PROMPT_PATH)
    { role: "system", content: msg }
  end
end