# lib/trainer/training_data_builder.rb
require 'json'

class TrainingDataBuilder
  IN  = File.expand_path("data/training_data/input_examples.json", Dir.pwd)
  OUT = File.expand_path("data/training_data/training_data.jsonl", Dir.pwd)
  PROMPT_PATH = File.expand_path("data/prompts/base_prompt.txt", Dir.pwd)

  def initialize
    @limit = 11
  end

  def run
    examples = collect_examples.first(@limit)
    File.write(OUT, examples.join("\n") + "\n")
    puts "✅ Wrote #{@limit} examples to #{OUT}"
  end

  private

  def collect_examples
    input = JSON.parse(File.read(IN))
    raise "Invalid format: expected 'examples' array" unless input["examples"].is_a?(Array)

    input["examples"].lazy.map { |raw_obj| build_example(raw_obj["input"], raw_obj["output"]) }
  end

  def build_example(raw_input, expected_output)
    {
      messages: [
        { role: "system",    content: system_prompt },
        { role: "user",      content: raw_input.strip },
        { role: "assistant", content: JSON.generate(expected_output).strip }
      ]
    }.to_json
  end

  def system_prompt
    File.read(PROMPT_PATH)
  end
end
