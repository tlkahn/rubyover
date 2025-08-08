class AddWakachigakiToSubtitles < ActiveRecord::Migration[8.0]
  def change
    add_column :subtitles, :wakachigaki, :text
  end
end
