class CreateSubtitles < ActiveRecord::Migration[8.0]
  def change
    create_table :subtitles do |t|
      t.references :medium, null: false, foreign_key: true
      t.decimal :start_time, precision: 10, scale: 3
      t.decimal :end_time, precision: 10, scale: 3
      t.string :lang
      t.text :subtitle_text
      t.integer :cue_index

      t.timestamps
    end
    add_index :subtitles, %i[medium_id start_time]
    add_index :subtitles, %i[medium_id cue_index]
    add_check_constraint :subtitles, "end_time > start_time", name: "chk_subtitles_time_order"
  end
end
