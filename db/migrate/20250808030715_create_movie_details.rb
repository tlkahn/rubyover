class CreateMovieDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :movie_details do |t|
      t.references :medium, null: false, foreign_key: true, index: { unique: true }
      t.string :studio
      t.string :rating
      t.date :release_date

      t.timestamps
    end
  end
end
