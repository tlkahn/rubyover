class CreateYoutubeVideoDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :youtube_video_details do |t|
      t.references :medium, null: false, foreign_key: true, index: { unique: true }
      t.string :external_id
      t.string :channel_title
      t.string :channel_id
      t.datetime :published_at

      t.timestamps
    end
    add_index :youtube_video_details, :external_id, unique: true
  end
end
