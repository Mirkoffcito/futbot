#!/usr/bin/env ruby
require_relative "../lib/trainer/trainer"

begin
  trainer    = Trainer.new
  model_name = trainer.fine_tune_and_wait
  puts "✅ You can now use model: #{model_name}"
rescue => ex
  warn "❌ Error: #{ex.message}"
  exit 1
end
