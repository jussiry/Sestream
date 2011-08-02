class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
        
      t.integer :creator_id
      t.integer :twitter_id, :limit => 8 # will create a big int
      
      t.string :text  # original twitter txt
      t.text :html
      t.string :link
      t.string :link2
      t.string :link3
      
      t.string :from # url (and name?) of the service from which message sent.
      
      t.text :retweet_user_ids #, :default => '' # id's of all users who have retweeted this message
      #t.integer :retweets, :default => 0 # retweets from this message
      #t.integer :retweet_msg_id # id of the message this is a retweet from
      
      t.integer :reply_msg_id
      
      t.integer :pos, :default => 0 # positive clicks (from all user)
      t.integer :neg, :default => 0
      t.integer :read, :default => 0
      
      t.datetime :created_at
      
      #t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
