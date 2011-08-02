# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110623153608) do

  create_table "message_statuses", :force => true do |t|
    t.integer  "message_id"
    t.integer  "user_id"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_statuses", ["message_id", "user_id"], :name => "index_message_statuses_on_message_id_and_user_id", :unique => true

  create_table "messages", :force => true do |t|
    t.integer  "creator_id"
    t.integer  "twitter_id",       :limit => 8
    t.string   "text"
    t.text     "html"
    t.string   "link"
    t.string   "link2"
    t.string   "link3"
    t.string   "from"
    t.text     "retweet_user_ids"
    t.integer  "reply_msg_id"
    t.integer  "pos",                           :default => 0
    t.integer  "neg",                           :default => 0
    t.integer  "read",                          :default => 0
    t.datetime "created_at"
  end

  create_table "msg_tags", :force => true do |t|
    t.integer "message_id"
    t.integer "tag_id"
  end

  add_index "msg_tags", ["message_id", "tag_id"], :name => "index_msg_tags_on_message_id_and_tag_id", :unique => true

  create_table "msg_users", :force => true do |t|
    t.integer "message_id"
    t.integer "user_id"
    t.integer "type"
  end

  add_index "msg_users", ["message_id", "user_id"], :name => "index_msg_users_on_message_id_and_user_id", :unique => true

  create_table "pictures", :force => true do |t|
    t.string   "picture_type"
    t.binary   "picture_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tag_strengths", :force => true do |t|
    t.integer  "user_id"
    t.integer  "tag_id"
    t.float    "pos",        :default => 0.0
    t.float    "neg",        :default => 0.0
    t.float    "read",       :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tag_strengths", ["user_id", "tag_id"], :name => "index_tag_strengths_on_user_id_and_tag_id", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_strengths", :force => true do |t|
    t.integer  "user_id"
    t.integer  "followed_id"
    t.boolean  "following",   :default => false
    t.float    "text_pos",    :default => 0.0
    t.float    "text_neg",    :default => 0.0
    t.float    "text_read",   :default => 0.0
    t.float    "link_pos",    :default => 0.0
    t.float    "link_neg",    :default => 0.0
    t.float    "link_read",   :default => 0.0
    t.float    "reply_pos",   :default => 0.0
    t.float    "reply_neg",   :default => 0.0
    t.float    "reply_read",  :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_strengths", ["user_id", "followed_id"], :name => "index_user_strengths_on_user_id_and_followed_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "twitter_id"
    t.string   "login"
    t.string   "access_token"
    t.string   "access_secret"
    t.integer  "picture_id"
    t.datetime "messages_updated"
    t.boolean  "initialized",                  :default => false
    t.string   "current_session_id"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "name"
    t.string   "location"
    t.string   "description"
    t.string   "profile_image_url"
    t.string   "url"
    t.boolean  "protected"
    t.string   "profile_background_color"
    t.string   "profile_sidebar_fill_color"
    t.string   "profile_link_color"
    t.string   "profile_sidebar_border_color"
    t.string   "profile_text_color"
    t.string   "profile_background_image_url"
    t.boolean  "profile_background_tiled"
    t.integer  "friends_count"
    t.integer  "statuses_count"
    t.integer  "followers_count"
    t.integer  "favourites_count"
    t.integer  "utc_offset"
    t.string   "time_zone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
