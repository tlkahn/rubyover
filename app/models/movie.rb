class Movie < Medium
  has_one :movie_detail, dependent: :destroy, inverse_of: :medium
  accepts_nested_attributes_for :movie_detail
  delegate :studio, :rating, :release_date, to: :movie_detail, allow_nil: true

  private
  def detail_presence
    errors.add(:base, "movie_detail required") if movie_detail.nil?
  end
end
