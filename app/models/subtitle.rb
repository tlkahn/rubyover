require "rbai"
require "digest"
require "oj"

class Subtitle < ApplicationRecord
  belongs_to :medium

  validates :subtitle_text, presence: true
  validates :start_time, :end_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :lang, presence: true
  validate  :end_after_start

  scope :for_lang, ->(l) { where(lang: l) }
  scope :ordered,  -> { order(:start_time, :cue_index) }
  scope :at, ->(t) { where("start_time <= :time AND end_time > :time", time: t) }

  def duration
    (end_time.to_f - start_time.to_f).clamp(0.0, Float::INFINITY)
  end

  def to_vtt_cue
    "#{vtt_time(start_time)} --> #{vtt_time(end_time)}\n#{expand_subtitle_text}"
  end

  def analyze
    self.wakachigaki ||= begin
      g = GenaiClient.new(provider: :openai)
      content = g.generate_content(llm_instruction)
      update_column(:wakachigaki, content)
      content
    end
  end

  def expand_subtitle_text(retry_count = 0)
    unless wakachigaki.present?
      analyze
    end
    fetched_llm_result = extract_and_parse_json_fences(wakachigaki)
    data = case fetched_llm_result
    when Array
             fetched_llm_result.first
    when Hash
             fetched_llm_result
    else
             raise ArgumentError, "Expected Array or Hash, got #{fetched_llm_result.class}"
    end
    input = self.subtitle_text.presence || data["input"].to_s
    unless data
      if retry_count < 3
        self.wakachigaki = nil
        self.analyze
        expand_subtitle_text(retry_count+1)
      else
        raise
      end
    end
    tokens = Array(data["wakachigaki"])
    words = Array(data["words"])

    word_index = build_word_index(words)
    reconstruct_text(input, tokens, word_index)
  end

  private

  def extract_markdown_json_fences(text)
    text.scan(/```(?:json)?\s*\n(.*?)\n```/m).map do |match|
      match.first.strip
    end
  end

  def extract_and_parse_json_fences(text, retry_count = 0)
    extract_markdown_json_fences(text).map do |json_str|
      begin
        cleaned = json_str
          .force_encoding("UTF-8")
          .scrub
          .gsub(/[\u200B-\u200D\uFEFF]/, "") # Remove zero-width spaces
          .gsub(/,(\s*[}\]])/, '\1')          # Remove trailing commas
          .strip

        JSON.parse(cleaned)
      rescue JSON::ParserError => e
        begin
          Oj.load(json_str, mode: :compat)
        rescue LoadError, StandardError, EncodingError
          begin
            if retry_count < 3
              self.wakachigaki=nil
              self.analyze
              extract_and_parse_json_fences(text, retry_count+1)
            else
              raise
            end
          rescue
            raise
          end
        end
      end
    end
  end


  def build_word_index(words)
    words.group_by { |w| w["orthography"].to_s }
  end

  def slugify(text)
    text.to_s.downcase.gsub(/[^\p{Alnum}]+/, "_").gsub(/^_+|_+$/, "")
  end

  def choose_label(word_info)
    text = word_info["orthography"]
    Digest::SHA256.hexdigest(text)[0, 8] # First 8 characters for shorter labels
  end

  def build_ruby_html(token, word_info)
    word_info["ruby_html"].presence ? "<ruby>#{token}<rt>#{word_info['reading_kana']}</rt></ruby>" : token
  end

  def wrap_token(token, word_index)
    word_info = Array(word_index[token]).first
    return token if word_info.blank?

    label = choose_label(word_info) || token
    class_name = "w_#{slugify(label)}"
    ruby_html = build_ruby_html(token, word_info)

    "<c.#{class_name}>#{ruby_html}</c>"
  end

  def reconstruct_text(input, tokens, word_index)
    position = 0
    result = +""

    tokens.each do |token|
      token_position = input.index(token, position)

      if token_position.nil?
        result << wrap_token(token, word_index)
        next
      end

      result << input[position...token_position] if token_position > position
      result << wrap_token(token, word_index)
      position = token_position + token.length
    end

    result << input[position..-1] if position < input.length
    result
  end

  def end_after_start
    return if start_time.blank? || end_time.blank?
    errors.add(:end_time, "must be greater than start_time") unless end_time.to_f > start_time.to_f
  end

  def llm_instruction
    <<~INSTR
During this conversation, analyze my given Japanese sentence/phrase as follows:

* Decompose the sentence into **分書(wakachigaki)** (space-separated basic units: content words, particles, auxiliaries).
* For each unit, provide the following fields:

  1. Orthography (as in input; kanji/kana/mixed)
  2. Ruby\_html (HTML ruby with furigana; use `<ruby>漢字<rt>よみ</rt></ruby>`, or `null` if not applicable)
* Present the entire output as formatted JSON.
* Skip etymology, usage frequency notes, and syntactic tree diagrams.

### Example

```json
{
  "input": "昨日、彼が私に本をくれた。",
  "wakachigaki": [
    "昨日",
    "彼",
    "が",
    "私",
    "に",
    "本",
    "を",
    "くれた"
  ],
  "words": [
    {
      "orthography": "昨日",
      "ruby_html": "<ruby>昨日<rt>きのう</rt></ruby>",
    },
    {
      "orthography": "彼",
      "ruby_html": "<ruby>彼<rt>かれ</rt></ruby>",
    },
    {
      "orthography": "が",
      "ruby_html": null,
    },
    {
      "orthography": "私",
      "ruby_html": "<ruby>私<rt>わたし</rt></ruby>",
    },
    {
      "orthography": "に",
      "ruby_html": null,
    },
    {
      "orthography": "本",
      "ruby_html": "<ruby>本<rt>ほん</rt></ruby>",
    },
    {
      "orthography": "を",
      "ruby_html": null,
    },
    {
      "orthography": "くれた",
      "ruby_html": null,
    }
  ]
}
---
My sentence to analyze is: #{subtitle_text}
    INSTR
  end

  def vtt_time(sec)
    s  = sec.to_f
    h  = (s / 3600).floor
    m  = ((s % 3600) / 60).floor
    ss = (s % 60).floor
    ms = ((s - s.floor) * 1000).round.clamp(0, 999)
    format("%02d:%02d:%02d.%03d", h, m, ss, ms)
  end
end
