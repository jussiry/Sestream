class CreateTagStrengths < ActiveRecord::Migration
  def self.up
    create_table :tag_strengths do |t|

      t.integer :user_id
      t.integer :tag_id
      #t.string :tag_name
      
      #t.float :strength
      t.float :pos, :default => 0 # postive clicks
      t.float :neg, :default => 0
      t.float :read, :default => 0
      
      t.timestamps
    end
  end

  def self.down
    drop_table :tag_strengths
  end
end
