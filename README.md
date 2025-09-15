⚽ FutBot — AI-powered Football Discord Bot
FutBot is a Ruby-based Discord bot that delivers real-time football match information using AI-enhanced scraping and processing. It integrates data scraping, OpenAI model training, and Discord interaction into a single streamlined project.

## Credits / Acknowledgements

This project uses tools and code adapted from [edebole/de](https://github.com/edebole/de).

Adapted tools and code include: `lib/scraper`, `lib/prompter`, docker setup (commit `df84897`).

### 🧠 Overview
FutBot is composed of five main components:

1. 🕷 SiteScraper
The SiteScraper scrapes plain text data from [https://www.promiedos.com.ar/](https://www.promiedos.com.ar/), which is a Football stats website. It extracts match listings for specific days (today, yesterday, and tomorrow) and writes it to a jsonl file detailing the **url**, **timestamp** of the request, and the extracted **content**.

2. 🧾 Prompter
The Prompter connects to the OpenAI API with a structured prompt and the scraped raw text. It writes structured match data to a jsonl file.

3. 📦 Training Data Builder
This tool processes manually validated or auto-generated .jsonl example files and produces a training dataset ready to use to fine-tune the OpenAI model.

4. 🚀 Model Trainer
This component sends the finalized training data to the OpenAI API and waits for fine-tuning to complete, returning a new model ID. For a dataset of 10 examples, it can take up to 20 minutes.

5. 🤖 Discord Bot — FutBot
This is the live interface users interact with. It listens for Discord commands, scrapes data, uses the trained model to interpret it, and posts responses.

Includes class-level caching to reduce requests and stale data. Cache TTL: 3 minutes.

🧾 Bot Commands
fut!hoy — Returns today’s football matches.

fut!mañana — Returns tomorrow’s matches.

fut!ayer — Returns yesterday’s matches.

Each command returns structured and readable match information.

🐳 Dockerized Setup
FutBot is fully Dockerized and includes a setup script to get started quickly.

Step 1 — Clone and setup:
```
git clone https://github.com/Mirkoffcito/futbot.git
cd futbot
bin/setup
bin/run_bot
```

This command builds the Docker image, installs dependencies, prepares the environment and finally starts the discord bot (which should have been invited to the server already).


🔧 Configuration
Create a .env file at the root of the project or set these environment variables:

```
OPENAI_API_KEY=your_openai_key
DISCORD_BOT_TOKEN=your_discord_token
```

These will be loaded automatically during container startup by `require "dotenv/load"`.

