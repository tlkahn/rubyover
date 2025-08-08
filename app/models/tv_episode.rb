class TVEpisode < Medium
  has_one :tv_episode_detail, dependent: :destroy, inverse_of: :medium
  accepts_nested_attributes_for :tv_episode_detail
  delegate :series_title, :season, :episode_number, :air_date, to: :tv_episode_detail, allow_nil: true

  validate :detail_presence

  private
  def detail_presence
    errors.add(:base, "tv_episode_detail required") if tv_episode_detail.nil?
  end
end
