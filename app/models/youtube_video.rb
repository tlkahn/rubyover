class YoutubeVideo < Medium
  has_one :youtube_video_detail, dependent: :destroy, inverse_of: :medium
  accepts_nested_attributes_for :youtube_video_detail
  delegate :external_id, :channel_title, :channel_id, :published_at, to: :youtube_video_detail, allow_nil: true

  validate :detail_presence

  private
  def detail_presence
    errors.add(:base, "youtube_video_detail required") if youtube_video_detail.nil?
  end
end
