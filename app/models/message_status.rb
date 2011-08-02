class MessageStatus < ActiveRecord::Base
  
  belongs_to :message
  belongs_to :user
  
  #validates_uniqueness_of :message_id, :scope => :user_id, :message => "Error: Message status already created!" # should validate that message and user together are unique
  
  def self.create(hash)
    begin
      super.create(hash)
    rescue
      logger.debug "Failed to create MessageStatus (#{hash.inspect})"
    end
  end
  
end
