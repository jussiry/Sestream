class CreateMsgUsers < ActiveRecord::Migration
  def self.up
    create_table :msg_users do |t|

      # This table saves connections to users that are mentioned in the message
      
      t.integer :message_id
      t.integer :user_id
      
      t.integer :type # not used, but could say if the connection is retweet, via, or something else... 
      
    end
  end

  def self.down
    drop_table :msg_users
  end
end
