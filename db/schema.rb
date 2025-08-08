# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_08_052906) do
  create_table "media", force: :cascade do |t|
    t.string "type"
    t.string "title"
    t.string "primary_language"
    t.text "description"
    t.integer "year"
    t.integer "duration_ms"
    t.integer "media_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["media_category_id"], name: "index_media_on_media_category_id"
    t.index ["title", "year"], name: "index_media_on_title_and_year"
    t.index ["type"], name: "index_media_on_type"
  end

  create_table "media_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_media_categories_on_slug", unique: true
  end

  create_table "movie_details", force: :cascade do |t|
    t.integer "medium_id", null: false
    t.string "studio"
    t.string "rating"
    t.date "release_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medium_id"], name: "index_movie_details_on_medium_id", unique: true
  end

  create_table "subtitles", force: :cascade do |t|
    t.integer "medium_id", null: false
    t.decimal "start_time", precision: 10, scale: 3
    t.decimal "end_time", precision: 10, scale: 3
    t.string "lang"
    t.text "subtitle_text"
    t.integer "cue_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "wakachigaki"
    t.index ["medium_id", "cue_index"], name: "index_subtitles_on_medium_id_and_cue_index"
    t.index ["medium_id", "start_time"], name: "index_subtitles_on_medium_id_and_start_time"
    t.index ["medium_id"], name: "index_subtitles_on_medium_id"
    t.check_constraint "end_time > start_time", name: "chk_subtitles_time_order"
  end

  create_table "tv_episode_details", force: :cascade do |t|
    t.integer "medium_id", null: false
    t.string "series_title"
    t.integer "season"
    t.integer "episode_number"
    t.date "air_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["medium_id"], name: "index_tv_episode_details_on_medium_id", unique: true
    t.index ["series_title", "season", "episode_number"], name: "idx_tv_series_season_ep"
  end

  create_table "youtube_video_details", force: :cascade do |t|
    t.integer "medium_id", null: false
    t.string "external_id"
    t.string "channel_title"
    t.string "channel_id"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_youtube_video_details_on_external_id", unique: true
    t.index ["medium_id"], name: "index_youtube_video_details_on_medium_id", unique: true
  end

  add_foreign_key "media", "media_categories"
  add_foreign_key "movie_details", "media"
  add_foreign_key "subtitles", "media"
  add_foreign_key "tv_episode_details", "media"
  add_foreign_key "youtube_video_details", "media"
end
