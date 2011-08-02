class Tag < ActiveRecord::Base
  
  #has_many :messages, :through => :msg_tag
  has_many :tag_strengths #, :dependent => :destroy
  has_many :users, :through => :tag_strength
  
  has_many :msg_tags
  has_many :messages, :through => :msg_tags
  
  # validate uniqueness baadd...
  validates_uniqueness_of :name
  
end
