class MediaCategory < ApplicationRecord
  has_many :media, dependent: :restrict_with_exception
  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
end
