#require 'generic_user.rb'

class User < GenericUser  #TwitterAuth::
  # Extend and define your user model as you see fit.
  # All of the authentication logic is handled by the 
  # parent TwitterAuth::GenericUser class.
  
  has_many :message_statuses
  
  has_many :user_strengths
  has_many :tag_strengths
  has_many :tags, :through => :tag_strength
  
  has_many :messages, :class_name => "Message", :foreign_key => "creator_id" 
  has_many :msg_users
  has_many :messages_mention, :through => :msg_users, :source => :message
  
  #belongs_to :picture #pictures not used anymore
  
  #belongs_to :twitter_user
  
  #validates_uniqueness_of :username
  
  def pic_src
    #if picture_id
    #  '/picture/' + picture_id.to_s
    if profile_image_url
      profile_image_url
    else
      '/images/dummy_35.jpg'
    end 
  end
  
  def profile_image_url_bigger
    profile_image_url.nil? ? nil : profile_image_url.gsub(/normal/, 'bigger')    
  end
  
  def profile_image_url_orig
    profile_image_url.nil? ? nil : profile_image_url.gsub(/_normal/, '')    
  end
  
  def init_user_strengths
    # go through own messages and adjust user and tag strengths accordingly
    
    msgs_hash = self.twitter.get("/statuses/user_timeline?count=200")
    own_messages = []
    msgs_hash.each do |mh|
      own_messages << Message.find_or_create(mh)
    end
    
    logger.debug "STARTING TO GO THROUGH OWN MESSAGES"
    own_messages.each do |msg|
      logger.debug "going through message #{msg.inspect}"
      # go through words in message to see if there's other users or hashtags mentioned
      
      UserStrength.shift_user_and_tag_strengths(self.id, msg, 1, 0, 0)
#      
#      msg.text.split.each do |w|
#        #logger.debug "going through word #{w.inspect}"
#        htmTypCle = Message.analyze_word(w)
#        if htmTypCle[1] == '@'
#          followed_user = User.find_or_create_by_login(:login => htmTypCle[2])
#          if us = UserStrength.find_by_user_id_and_followed_id(self.id, followed_user.id)
#            us.update_attributes(:text_pos => us.text_pos+1, :link_pos => us.link_pos+1)
#          else
#            UserStrength.create(:user => self, :followed_id => followed_user.id, :followed_login => followed_user.login,
#                          :text_pos => $def_user_strength + 1, :link_pos => $def_user_strength + 1)
#          end
#        elsif htmTypCle[1] == '#'
#          tag = Tag.find_or_create_by_name(:name => htmTypCle[2])
#          if ts = TagStrength.find_by_user_id_and_tag_id(self.id, tag.id)
#            ts.update_attribute(:str_pos, ts.str_pos+1)
#          else
#            TagStrength.create(:user => self, :tag_id => tag.id, :tag_name => tag.name, :str_pos => 1)
#          end
#        end
#      end
    end
  end
  
  def self.find_by_caseless_login(login)
    User.find(:first, :conditions => ["lower(login) = ?", login.downcase])
  end
  
end

#class User < ActiveRecord::Base
#  
#  has_many :message_statuses
#  has_many :user_strengths
#  has_many :tag_strengths
#  
#  belongs_to :twitter_user
#  
#  validates_uniqueness_of :username
#  
#end
