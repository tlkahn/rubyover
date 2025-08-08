class CreateMedia < ActiveRecord::Migration[8.0]
  def change
    create_table :media do |t|
      t.string :type
      t.string :title
      t.string :primary_language
      t.text :description
      t.integer :year
      t.integer :duration_ms
      t.references :media_category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :media, :type
    add_index :media, %i[title year]
  end
end
