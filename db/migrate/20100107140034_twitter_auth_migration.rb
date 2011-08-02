class TwitterAuthMigration < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :twitter_id
      t.string :login
      t.string :access_token
      t.string :access_secret

      t.integer :picture_id
      t.datetime :messages_updated
      t.boolean :initialized, :default => false # used simply to remember if 'init_user_strengths' has been processed
      t.string :current_session_id
      #t.integer :last_fetched_tweet_id, :limit => 8 # used in user/show, to only fetch new tweets by this user
      
      t.string :remember_token
      t.datetime :remember_token_expires_at

      # This information is automatically kept
      # in-sync at each login of the user. You
      # may remove any/all of these columns.
      t.string :name
      t.string :location
      t.string :description
      t.string :profile_image_url
      t.string :url
      t.boolean :protected
      t.string :profile_background_color
      t.string :profile_sidebar_fill_color
      t.string :profile_link_color
      t.string :profile_sidebar_border_color
      t.string :profile_text_color
      t.string :profile_background_image_url
      t.boolean :profile_background_tiled
      t.integer :friends_count
      t.integer :statuses_count
      t.integer :followers_count
      t.integer :favourites_count

      # Probably don't need both, but they're here.
      t.integer :utc_offset
      t.string :time_zone

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end

#class CreateUsers < ActiveRecord::Migration
#  def self.up
#    create_table :users do |t|
#
#      t.string :username # same as with twitter_user
#      t.string :password
#      t.string :email
#      t.integer :twitter_user_id
#      
#      t.string :current_session_id  # s�il�t��n nykyisen session tunnus, jotta voidaan tuhota uuden alkaessa
# 
#      # maybe later...
#      t.string :full_name
#      t.integer :sex # 1 = mies, 2 = nainen
#      t.date :birthdate
#      t.string :url
#      
#      t.timestamps
#    end
#  end
#
#  def self.down
#    drop_table :users
#  end
#end
