class CreateMsgTags < ActiveRecord::Migration
  def self.up
    create_table :msg_tags do |t|
      
      # THIS TABLE SAVES CONNECTIONS TO TAGS THAT ARE MENTIONED IN THE ID
      
      t.integer :message_id
      t.integer :tag_id
      
    end
    
  end

  def self.down
    drop_table :msg_tags
  end
end
