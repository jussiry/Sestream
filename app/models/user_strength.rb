class UserStrength < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :followed, :class_name => "User", :foreign_key => "followed_id"
  
  # validate uniqueness is baaad, change to this approach late: http://stackoverflow.com/questions/2077770/rails-debugging-in-production-environment
  #validates_uniqueness_of :user_id, :scope => :followed_id
  
  @@type_limit = 15
  
  def pos
    text_pos + link_pos + reply_pos
  end
  
  def neg
    text_neg + link_neg + reply_neg
  end
  
  def read
    text_read + link_read + reply_read
  end
  
  def multiplier(msg_type=nil)
    if msg_type == $msg_type_text and (text_pos + text_neg + text_read) > @@type_limit
      Misc.pos_neg_read_multip(text_pos, text_neg, text_read)
    elsif msg_type == $msg_type_link and (link_pos + link_neg + link_read) > @@type_limit
      Misc.pos_neg_read_multip(link_pos, link_neg, link_read)
    elsif msg_type == $msg_type_reply and (reply_pos + reply_neg + reply_read) > @@type_limit
      Misc.pos_neg_read_multip(reply_pos, reply_neg, reply_read)
    else
      Misc.pos_neg_read_multip(pos, neg, read)
    end
  end
  
  def percentage # of all
    Misc.pos_neg_read_percentage(pos, neg, read).to_i
  end
  
#  def strength(link)
#    if link
#      return Misc.salience_zero_to_ten(link_pos, link_neg)
#    else
#      return Misc.salience_zero_to_ten(text_pos, text_neg)
#    end
#    #self.txt_pos - self.txt_neg + self.link_pos - self.link_neg
#  end
  
  def shift(msg_type, pos_change, neg_change, read_change, dont_save=false)
    if msg_type == $msg_type_link
      self.link_pos += pos_change
      self.link_neg += neg_change
      self.link_read += read_change
    elsif msg_type == $msg_type_text
      self.text_pos += pos_change
      self.text_neg += neg_change
      self.text_read += read_change
    else # msg_type == $msg_type_reply
      self.reply_pos += pos_change
      self.reply_neg += neg_change
      self.reply_read += read_change
    end
    self.save unless dont_save
  end
  
  def self.create(hash)
    begin
      super.create(hash)
    rescue
      logger.debug "Failed to create UserStrength (#{hash.inspect})"
    end
  end
  
  def self.shift_user_and_tag_strengths(user_id, msg, pos_change, neg_change, read_change)
    msg = Message.find(msg) if msg.class == Fixnum
    strengths = []
    msg_type = msg.msg_type
    # increase strenght to creator of message:
    cs = UserStrength.find_or_create_by_user_id_and_followed_id(:user_id => user_id, :followed_id => msg.creator_id) 
    cs.shift(msg_type, pos_change, neg_change, read_change)
    #con_type = is_link ? '_link' : '_text'
    #strengths << ['@'+creator.login+con_type, cs.strength(msg_type)]
    
    # go through users
    msg.users_mentioned.each do |mentioned_user|
      logger.debug "mentiond @#{mentioned_user.login}"
      us = UserStrength.find_or_create_by_user_id_and_followed_id(:user_id => user_id, :followed_id => mentioned_user.id)
      us.shift(msg_type, pos_change, neg_change, read_change)
      #strengths << ['@'+mentioned_user.login+con_type, us.strength(is_link)]
    end
    msg.tags_mentioned.each do |mentioned_tag|
      ts = TagStrength.find_or_create_by_user_id_and_tag_id(:user_id => user_id, :tag_id => mentioned_tag.id) # , :tag_name => mentioned_tag.name
      ts.shift(pos_change, neg_change, read_change)
      #strengths << ['#'+mentioned_tag.name, ts.strength]
    end
    #strengths
  end
  
  
end
