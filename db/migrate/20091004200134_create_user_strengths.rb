class CreateUserStrengths < ActiveRecord::Migration
  def self.up
    create_table :user_strengths do |t|

      t.integer :user_id
      t.integer :followed_id # followed user id
      #t.string :followed_login # :twitter login
      #t.float :strength # 0,1,2..
      
      t.boolean :following, :default => false
      
      t.float :text_pos, :default => 0 # positive clicks to text messages
      t.float :text_neg, :default => 0
      t.float :text_read, :default => 0
      
      t.float :link_pos, :default => 0
      t.float :link_neg, :default => 0
      t.float :link_read, :default => 0
      
      t.float :reply_pos, :default => 0
      t.float :reply_neg, :default => 0
      t.float :reply_read, :default => 0
      
      t.timestamps
    end
  end

  def self.down
    drop_table :user_strengths
  end
end
