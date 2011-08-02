class UniqueIndexes < ActiveRecord::Migration
  def self.up
    add_index(:message_statuses, [:message_id, :user_id], :unique => true)
    add_index(:tag_strengths, [:user_id, :tag_id], :unique => true)
    add_index(:user_strengths, [:user_id, :followed_id], :unique => true)
    add_index(:msg_users, [:message_id, :user_id], :unique => true)
    add_index(:msg_tags, [:message_id, :tag_id], :unique => true)
  end

  def self.down
    remove_index :message_statuses, [:message_id, :user_id]
    remove_index :tag_strengths, [:user_id, :tag_id]
    remove_index :user_strengths, [:user_id, :followed_id]
    remove_index :msg_users, [:message_id, :user_id]
    remove_index :msg_tags, [:message_id, :tag_id]
  end
end
