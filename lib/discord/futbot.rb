# lib/discord/futbot.rb
require 'json'
require 'date'
require 'fileutils'

class Futbot
  CACHE_DIR = File.join(__dir__, '../../tmp')
  # set up the cache
  @@cache = {}

  # expose it via a class method
  def self.cache
    @@cache
  end

  attr_reader :event, :command, :date, :matches

  URLS = {
    hoy:     'https://www.promiedos.com.ar/',
    man:  'https://www.promiedos.com.ar/man',
    ayer:    'https://www.promiedos.com.ar/ayer'
  }.freeze

  def initialize(event)
    @event   = event
    @command = parse_command(event.message.content)
    today    = local_today

    @date    = case @command
               when :hoy    then today
               when :man then today.next_day
               when :ayer   then today.prev_day
               end
  end

  def handle
    return unless date

    entry = Futbot.cache[command]
    
    if entry && (Time.now - entry[:fetched_at] < 180)
      @matches = entry[:matches]
    else
      # scrape into a per-command cache file
      FileUtils.mkdir_p(CACHE_DIR)
      cache_path = File.join(CACHE_DIR, "cache_#{command}.jsonl")

      FileUtils.rm_f(cache_path)
      
      # 1) run scraper
      scraper = SiteScraper.new(
        urls: [url_for(command)],
        output_path: cache_path
      )
      scraper.export_to_json!

      # 2) load by command key (hoy/man/ayer)
      raw  = File.read(cache_path).strip
      data = JSON.parse(raw)  # { "hoy": [...], "man": [...], "ayer": [...] }

      @matches = data.fetch("matches", [])

      # 3) update in-memory cache
      Futbot.cache[command] = {
        fetched_at: Time.now,
        matches:    @matches
      }
    end
    event.respond format_matches(@matches, title_for(command, date))
  end

  def handle_lichi
    return event.respond "jefe"
  end

  private

  def local_today
    Time.now.getlocal('-03:00').to_date
  end

  def parse_command(text)
    case text.strip.downcase
    when /^f!hoy/    then :hoy
    when /^f!mañana/ then :man
    when /^f!ayer/   then :ayer
    end
  end

  def url_for(cmd)
    URLS.fetch(cmd) { raise "No URL for #{cmd.inspect}" }
  end

  def format_matches(matches, title)
    return "**#{title}**\n> _ninguno_" if matches.empty?

    order   = { 'live' => 0, 'scheduled' => 1, 'finished' => 2 }
    sorted  = matches.sort_by { |m| order.fetch(m['status'], 3) }
    grouped = sorted.group_by { |m| m['competition'] || 'Sin categoría' }

    body = grouped.map.with_index do |(comp, comps), idx|
      header = "## #{comp}"
      list   = comps.map { |m| parse_match(m) }.join("\n")
      (idx.zero? ? header : "\n#{header}") + "\n" + list
    end.join("\n")

    "**#{title}**\n" + body
  end

  def parse_match(match)
    team_a       = match['team_a']
    team_b       = match['team_b']
    kickoff      = match['time'].to_s.strip
    base_elapsed = match['elapsed'].to_s.strip
    extra_elapsed = match['extra'].to_s.strip
    goals_a_list = match.dig('goals','team_a') || []
    goals_b_list = match.dig('goals','team_b') || []
    status       = match['status']

    case status
    when 'live'
      ga, gb = goals_a_list.size, goals_b_list.size
      elapsed_label = if extra_elapsed.to_i > 0
                        "#{base_elapsed}+#{extra_elapsed}'"
                      else
                        "#{base_elapsed}'"
                      end


      goals_a = parsed_goals(goals_a_list)
      goals_b = parsed_goals(goals_b_list)

      "**EN VIVO (#{elapsed_label})** • **#{team_a}** #{ga}-#{gb} **#{team_b}**" \
      "\n> **#{team_a}**: #{goals_a}\n> **#{team_b}**: #{goals_b}"
    when 'scheduled'
      "**#{kickoff}** – **#{team_a}** vs **#{team_b}**"
    else # finished
      ga, gb = goals_a_list.size, goals_b_list.size
      result = parse_match_result(team_a, team_b, ga, gb)

      if match['penalties']
        pa = match['penalties']['team_a']
        pb = match['penalties']['team_b']

        penalty_winner = pa > pb ? team_a : team_b
        result = "Ganó **#{penalty_winner}** por penales (#{pa}-#{pb})"
      end

      "**#{team_a}** #{ga}-#{gb} **#{team_b}** _(#{result})_"
    end

  rescue => e
    "**Error procesando partido**"
  end

  def parsed_goals(goals)
    return 'Ninguno' if goals.empty?
    goals.map do |g|
      min   = g['minute']
      extra = g['extra'].to_i
      label = extra > 0 ? "#{min}+#{extra}'" : "#{min}'"
      "#{label} #{g['scorer']}"
    end.join('; ')
  end

  def parse_match_result(team_a, team_b, ga, gb)
    if ga > gb
      "Ganó **#{team_a}**"
    elsif gb > ga
      "Ganó **#{team_b}**"
    else
      "**Empate**"
    end
  end

  def title_for(cmd, date)
    labels = { hoy: 'hoy', man: 'mañana', ayer: 'ayer' }
    "📅 Partidos de *#{labels[cmd]}* (#{date.strftime('%d-%m-%Y')}):"
  end
end

