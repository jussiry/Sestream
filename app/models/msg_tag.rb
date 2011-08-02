class MsgTag < ActiveRecord::Base
  
  belongs_to :message
  belongs_to :tag
  
  # validate uniqueness is baaad, change to this approach late: http://stackoverflow.com/questions/2077770/rails-debugging-in-production-environment
  #validates_uniqueness_of :message_id, :scope => :tag_id
  
  def self.create(hash)
    begin
      super.create(hash)
    rescue
      logger.debug "Failed to create MsgTag (#{hash.inspect})"
    end
  end
end
