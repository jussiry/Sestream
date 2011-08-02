class TagStrength < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :tag
  
  # validate uniqueness is baaad, change to this approach late: http://stackoverflow.com/questions/2077770/rails-debugging-in-production-environment
  #validates_uniqueness_of :user_id, :scope => :tag_id
  
#  def strength
#    Misc.salience_zero_to_ten(str_pos, str_neg)
#  end
  
  def multiplier
    Misc.pos_neg_read_multip(pos,neg,read)
  end
  
  def percentage
    Misc.pos_neg_read_percentage(pos,neg,read)
  end
  
  def shift(pos_change, neg_change, read_change, dont_save=false)
    self.pos += pos_change
    self.neg += neg_change
    self.read += read_change
    self.save unless dont_save
  end
  
  def self.create(hash)
    begin
      super.create(hash)
    rescue
      logger.debug "Failed to create TagStrength (#{hash.inspect})"
    end
  end
  
end
