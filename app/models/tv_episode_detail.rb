class TVEpisodeDetail < ApplicationRecord
  belongs_to :medium
  validates :series_title, presence: true
end
