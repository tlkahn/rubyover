class CreateMediaCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :media_categories do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end
    add_index :media_categories, :slug, unique: true
  end
end
