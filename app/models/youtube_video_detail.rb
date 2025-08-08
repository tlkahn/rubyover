class YoutubeVideoDetail < ApplicationRecord
  belongs_to :medium
  validates :external_id, presence: true, uniqueness: true
end
