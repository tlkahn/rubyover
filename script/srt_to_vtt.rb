# frozen_string_literal: true
#
# script/srt_to_vtt.rb
#
# Convert an SRT file to WebVTT OR import subtitles into the DB.
#
# USAGE
#   # Export: SRT -> VTT (prints to STDOUT unless OUTPUT given)
#   bin/rails runner script/srt_to_vtt.rb export INPUT.srt [OUTPUT.vtt]
#
#   # Import: SRT -> subtitles table for a Medium
#   bin/rails runner script/srt_to_vtt.rb import INPUT.srt MEDIUM_ID [LANG=ja] [--replace]
#
# NOTES
# - SRT numbering lines are ignored.
# - "00:00:04,300" becomes "00:00:04.300" (or 4.300 seconds for DB).
# - Cue text is preserved verbatim (no ruby or <c.*> markup is added).

mode = ARGV.shift or abort(<<~USAGE)
  USAGE:
    bin/rails runner script/srt_to_vtt.rb export INPUT.srt [OUTPUT.vtt]
    bin/rails runner script/srt_to_vtt.rb import INPUT.srt MEDIUM_ID [LANG=ja] [--replace]
USAGE

def normalize_timecode(tc)
  tc = tc.strip.tr(',', '.')
  m = /\A(?<h>\d{1,2}):(?<m>\d{2}):(?<s>\d{2})(?:\.(?<ms>\d{1,3}))?\z/.match(tc)
  raise ArgumentError, "Unparsable timecode: #{tc}" unless m
  ms = (m[:ms] || "000").ljust(3, '0')[0,3]
  "%02d:%02d:%02d.%s" % [m[:h].to_i, m[:m].to_i, m[:s].to_i, ms]
end

def seconds_from_timecode(tc)
  tc = tc.strip.tr(',', '.')
  m = /\A(?<h>\d{1,2}):(?<m>\d{2}):(?<s>\d{2})(?:\.(?<ms>\d{1,3}))?\z/.match(tc)
  raise ArgumentError, "Unparsable timecode: #{tc}" unless m
  h = m[:h].to_i
  mm = m[:m].to_i
  s = m[:s].to_i
  ms = (m[:ms] || "0").to_i
  (h * 3600) + (mm * 60) + s + (ms / (10 ** m[:ms].to_s.size).to_f)
end

def parse_srt_blocks(s)
  s.split(/\r?\n{2,}/).map { |blk| blk.split(/\r?\n/) }.reject(&:empty?)
end

def parse_srt_file(path)
  raw = File.read(path, mode: "r:BOM|UTF-8").gsub("\r\n", "\n")
  blocks = parse_srt_blocks(raw)
  cues = []
  idx_counter = 1

  blocks.each do |lines|
    # Drop numeric index line if present
    lines.shift if lines.first&.strip&.match?(/\A\d+\z/)

    time_line = lines.shift
    next unless time_line

    tm = /(?<a>\d{1,2}:\d{2}:\d{2}(?:[.,]\d{1,3})?)\s*-->\s*(?<b>\d{1,2}:\d{2}:\d{2}(?:[.,]\d{1,3})?)/.match(time_line)
    next unless tm

    start_s = seconds_from_timecode(tm[:a]).round(3)
    end_s   = seconds_from_timecode(tm[:b]).round(3)
    text    = lines.join("\n")

    cues << { index: idx_counter, start: start_s, end: end_s, text: text }
    idx_counter += 1
  end

  cues
end

case mode
when "export"
  input_path = ARGV[0] or abort("export mode: provide INPUT.srt")
  output_io  = ARGV[1] ? File.open(ARGV[1], "w:UTF-8") : STDOUT
  cues = parse_srt_file(input_path)

  output_io.puts "WEBVTT"
  output_io.puts
  output_io.puts "STYLE"
  output_io.puts "::cue(ruby) { font-size: 1em; }"
  output_io.puts "::cue(rt)   { font-size: 0.6em; }"
  output_io.puts

  cues.each do |c|
    a = normalize_timecode(Time.at(c[:start]).utc.strftime("%H:%M:%S.%L"))
    b = normalize_timecode(Time.at(c[:end]).utc.strftime("%H:%M:%S.%L"))
    output_io.puts "#{a} --> #{b}"
    output_io.puts c[:text]
    output_io.puts
  end

  output_io.close unless output_io.equal?(STDOUT)

when "import"
  input_path = ARGV[0] or abort("import mode: provide INPUT.srt")
  medium_id  = Integer(ARGV[1] || raise("import mode: provide MEDIUM_ID"))
  lang       = (ARGV[2] && !ARGV[2].start_with?("--")) ? ARGV[2] : "ja"
  replace    = ARGV.include?("--replace")

  cues = parse_srt_file(input_path)

  # ActiveRecord context (loaded by rails runner)
  medium = Medium.find(medium_id)

  # Optional: enforce monotonic times and non-empty text
  cues.select! { |c| c[:end] > c[:start] && c[:text].to_s.strip != "" }

  now = Time.current
  rows = cues.map do |c|
    {
      medium_id:     medium.id,
      start_time:    c[:start],
      end_time:      c[:end],
      lang:          lang,
      subtitle_text: c[:text],
      cue_index:     c[:index],
      created_at:    now,
      updated_at:    now
    }
  end

  Subtitle.transaction do
    if replace
      Subtitle.where(medium_id: medium.id, lang: lang).delete_all
    end
    # Prefer insert_all! for speed; falls back to per-row create! if needed.
    if Subtitle.respond_to?(:insert_all!)
      Subtitle.insert_all!(rows) unless rows.empty?
    else
      rows.each { |attrs| Subtitle.create!(attrs) }
    end
  end

  puts "Imported #{rows.size} subtitles into medium_id=#{medium.id} lang=#{lang}#{replace ? ' (replaced existing)' : ''}"

else
  abort("Unknown mode: #{mode.inspect}. Use 'export' or 'import'.")
end
