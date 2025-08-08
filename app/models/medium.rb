class Medium < ApplicationRecord
  self.inheritance_column = :type # STI
  belongs_to :media_category
  has_many :subtitles, dependent: :destroy

  validates :title, :primary_language, presence: true

  def duration_seconds
    duration_ms&.to_f&./(1000.0)
  end

  def build_vtt
    vtt_content = "WEBVTT\n\n"
    vtt_content += "STYLE\n"
    vtt_content += "::cue(ruby) { font-size: 1em; }\n"
    vtt_content += "::cue(rt)   { font-size: 0.6em; }\n\n"

    self.subtitles.ordered.each do |s|
      vtt_content += "#{s.to_vtt_cue}\n"
    end

    # Write to file
    filename = "#{self.id}.vtt"
    filepath = Rails.root.join('public', 'subs', filename)
    FileUtils.mkdir_p(File.dirname(filepath))
    File.write(filepath, vtt_content)

    filepath
  end

end
