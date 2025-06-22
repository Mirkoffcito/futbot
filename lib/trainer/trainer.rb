# lib/trainer/trainer.rb
require 'openai'
require 'dotenv/load'

class Trainer
  TRAIN_FILE     = "./training_data.jsonl"
  DEFAULT_MODEL  = "gpt-4.1-nano-2025-04-14"
  DEFAULT_EPOCHS = 4

  def initialize(client: nil, model: DEFAULT_MODEL, epochs: DEFAULT_EPOCHS)
    token   = ENV.fetch("OPENAI_ACCESS_TOKEN") { raise "Missing OPENAI_ACCESS_TOKEN" }
    @client = client || OpenAI::Client.new(api_key: token)
    @model  = model
    @epochs = epochs
    validate_training_file!
  end

  # 1) upload the JSONL, 2) kick off a fine-tune job
  # returns the job hash (including "id")
  def fine_tune
    upload = @client.files.create(
      file:    File.open(TRAIN_FILE, "rb"),
      purpose: "fine-tune"
    )
    file_id = upload.id

    @client.fine_tuning.jobs.create(
      model:           @model,
      training_file:   file_id
    )
  end

  # Polls until the job succeeds or fails, then returns the new model name
  def fine_tune_and_wait
    job_id = fine_tune.id

    loop do
      job    = @client.fine_tuning.jobs.retrieve(job_id)
      status = job.status
      puts "[#{Time.now.strftime("%H:%M:%S")}] Fine-tune status: #{status}"
      break if %i[succeeded failed].include?(status)
      sleep 10
    end

    final = @client.fine_tuning.jobs.retrieve(job_id)
    if final.status == "succeeded"
      model_name = final.fine_tuned_model
      puts "🎉 Fine-tune complete! Model: #{model_name}"
      model_name
    else
      raise "Fine-tune failed: #{final.inspect}"
    end
  end

  private

  def validate_training_file!
    unless File.exist?(TRAIN_FILE) && !File.zero?(TRAIN_FILE)
      raise "Training data file missing or empty: #{TRAIN_FILE}"
    end
  end
end
