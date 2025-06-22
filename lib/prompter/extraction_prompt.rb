class ExtractionPrompt < BasePrompt
  MAX_TOKENS = 1000.freeze

  attribute :content

  def configuration
    {
      method: "POST",
      url: "/v1/chat/completions",
      # model: "gpt-4.1-nano",
      model: "ft:gpt-4.1-nano-2025-04-14:personal::Bjc94CKX",
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

    #   1. Immediately before `Final`, `ET`, or `PEN`.  
    # 2. Immediately before any time of day (`HH:MM`), even if it’s glued to preceding text, via:
    #    ```regex
    #    (?<=\\D)(?=\\d{1,2}:\\d{2})
    #    ```
    # 3. Immediately before any minute marker (`\\d+'` or `\\d+'\\+\\d+'`).  

def system_message
  msg = <<~PROMPT
    You are a text‐processing assistant. You will receive one raw text blob containing matches across multiple competitions. Your job is to output JSON with a top‐level “matches” array. Each match object must include:

    - team_a  
    - team_b  
    - date       # ISO YYYY-MM-DD  
    - time       # “HH:MM” if scheduled, else “”  
    - elapsed    # minutes (live only), else “”  
    - extra      # extra minutes (live only), else “”  
    - competition  
    - status     # “scheduled”, “finished”, or “live”  
    - goals: { team_a: [...], team_b: [...] }  
        each goal: { minute, extra, scorer }  
    - winner     # team name or null  
    - penalties  # { team_a: X, team_b: Y } only if penalties were taken  

  **Steps:**

  1. **Identify the date**

  2. **Section headers**  
    - Insert newline before each `Sección de …`:  
      Search: `/(Sección de [^\r\n]+)/i` → Replace: `"\n$1"`  
    - Split on `\n` and drop the final dangling header.

  3. **Competition blocks**  
    - Join remaining lines, split on `\n`.  
    - Extract `competition` from either the block’s start up to first match, or the trailing header.

  4. **Split into matches**  
    - Zero-width split on look-ahead:  
      `(?=(?:Final|Por penales|ET|PEN|\d{1,2}:\d{2}|\d+'(?:\+\d+)?))`

  5. **Parse each match**  
    a. **Status token**  
        - `Final` or `Por penales` → `"finished"`  
        - `HH:MM` → `"scheduled"` (capture as `time`)  
        - `ET`, `PEN`, `\d+'…` → `"live"` (capture `elapsed`/`extra`)  
    b. **Strip** that prefix.  
    c. **Teams & scores**  
        ```regex
        ^([^(]+?)          # team_a name (up to "(" if penalties count follows, or up to score)
        (?:\((\d+)\))?     # optional penalties_a
        (\d+)-(\d+)        # normal score
        (?:\((\d+)\))?     # optional penalties_b
        ([\s\S]+)$         # rest: team_b + goals/events
        ```  
        - group 1 = team_a  
        - group 2 = penalties_a (if any)  
        - group 3 = score_a  
        - group 4 = score_b  
        - group 5 = penalties_b (if any)  
        - group 6 = tail with team_b name + “;”-separated goals  
        - Extract `team_b` from head of group 6 up to first minute marker.  
    d. **Goals arrays**  
        - Split group 6 on `;` into each `minute[+'extra']Scorer`.  
        - For each: parse `minute`, optional `+extra`, and `scorer`.

  6. **Determine `winner`**  
    - If status != `"finished"` → `null`.  
    - Else compare normal goals: higher score → that team.  
    - If scores tied and penalties present → higher penalties wins.  
    - If tied and no penalties → `null`.

  7. **Assemble JSON**  
    ```json
    {
      "matches": [
        {
          "team_a": "...",
          "team_b": "...",
          "date": "YYYY-MM-DD",
          "time": "...",
          "elapsed": "...",
          "extra": "...",
          "competition": "...",
          "status": "finished",
          "goals": {
            "team_a":[ … ],
            "team_b":[ … ]
          },
          "penalties": { "team_a": X, "team_b": Y },  // only if present
          "winner": "…" or null
        },
        …
      ]
    }
    Return only the JSON object—no additional text.
  PROMPT


  { role: "system", content: msg }
end







  # ORIGINAL PROMPT
  # def system_message
  #   msg = <<~MSG
  #     You are an expert data extractor. From the provided text, identify and extract information about football matches being played and their category (e.g. 'PRIMERA NACIONAL', 'Mundial de Clubes', 'Libertadores', etc.) using the following strict JSON structure. Also, you have to add the player who made each goal for each team (e.g. 51'Iván Manzu;52'Iván Manzu means 'Ivan manzu made a goal at minute 51). You can guess the day because the text will have the phrase "PARTIDOS DE HOY" if it is today, or "MAÑANA" if it is tomorrow, or "AYER" for yesterday. When extracting matches, if a line begins with a minute marker like 10'TeamA1-0TeamB, treat it as an ongoing match.:
  #     ```json
  #     {
  #       "YYYY-MM-DD": [
  #         {
  #           "team_a": "Team name A",
  #           "team_b": "Team name B",
  #           "date": "YYYY-MM-DD",
  #           "time": "HH:MM",
  #           "competition": "PRIMERA NACIONAL",
  #           "status": "scheduled",
  #           "elapsed": "0",
  #           "goals": {
  #             "team_a": [
  #               { "scorer": "Player A1", "minute": 12 }
  #             ],
  #             "team_b": [
  #               { "scorer": "Player B1", "minute": 34 }
  #             ]
  #           }
  #         }
  #       ],
  #       "YYYY-MM-DD": [
  #         {
  #           "team_a": "Team name C",
  #           "team_b": "Team name D",
  #           "date": "YYYY-MM-DD",
  #           "time": "HH:MM",
  #           "competition": "PRIMERA NACIONAL",
  #           "status": "live",
  #           "elapsed": "10",
  #           "goals": {
  #             "team_a": [],
  #             "team_b": []
  #           }
  #         }
  #       ],
  #       "YYYY-MM-DD": [
  #         {
  #           "team_a": "Team name E",
  #           "team_b": "Team name F",
  #           "date": "YYYY-MM-DD",
  #           "time": "HH:MM",
  #           "competition": "PRIMERA NACIONAL",
  #           "status": "scheduled",
  #           "elapsed": "",
  #           "goals": {
  #             "team_a": [],
  #             "team_b": []
  #           }
  #         }
  #       ]
  #     }
  #     ```
  #      ```json
    # {
    #   "matches":[
    #     {
    #       "team_a":"Deportivo Armenio",
    #       "team_b":"Villa San Carlos",
    #       "date":"2025-06-16",
    #       "time":"12:00",
    #       "competition":"Primera B Metropolitana",
    #       "status":"scheduled",
    #       "elapsed":"0",
    #       "extra":"0",
    #       "goals":{"team_a":[],"team_b":[]}
    #     },
    #     {
    #       "team_a":"Huracán Las Heras",
    #       "team_b":"Gutiérrez SC",
    #       "date":"2025-06-16",
    #       "time":"15:30",
    #       "competition":"Federal A",
    #       "status":"scheduled",
    #       "elapsed":"0",
    #       "extra":"0",
    #       "goals":{"team_a":[],"team_b":[]}
    #     }
    #   ]
    # }
    # ```
  #     Extract values exactly as they appear.
  #     If a value is not present in the text, leave it as an empty string ("") or empty array ([]) as appropriate.
  #     Do not make up or infer any information. Only use data explicitly mentioned in the source text.
  #     Your output must be a valid JSON object only — no explanations or comments.
  #   MSG
  #   {role: "system", content: msg}
  # end
end