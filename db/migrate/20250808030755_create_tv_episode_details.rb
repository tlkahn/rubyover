class CreateTvEpisodeDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :tv_episode_details do |t|
      t.references :medium, null: false, foreign_key: true, index: { unique: true }
      t.string :series_title
      t.integer :season
      t.integer :episode_number
      t.date :air_date

      t.timestamps
    end
    add_index :tv_episode_details, %i[series_title season episode_number], name: "idx_tv_series_season_ep"
  end
end
