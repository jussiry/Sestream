class CreateMessageStatuses < ActiveRecord::Migration
  def self.up
    create_table :message_statuses do |t|

      t.integer :message_id
      t.integer :user_id
      t.integer :status # -1..+1
      
      t.timestamps
    end
  end

  def self.down
    drop_table :message_statuses
  end
end
