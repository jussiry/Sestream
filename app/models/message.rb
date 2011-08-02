require 'rexml/document'
require 'open-uri'

class Message < ActiveRecord::Base
  
  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id" 
  #belongs_to :retweeted_message, :class_name => "Message", :foreign_key => "retweet_msg_id"
  
  has_many :msg_tags
  has_many :tags_mentioned, :through => :msg_tags, :source => :tag
  has_many :msg_users
  has_many :users_mentioned, :through => :msg_users, :source => :user
  
  has_many :message_statuses
  
  validates_uniqueness_of :twitter_id
  validates_presence_of :creator_id
  
  @@spec_char = /[\.\,\!\?\:\-\/\(\)\;]/
  
  @retweeted_by # used to save temporalily who retweeted this message (won't be save in database)
  attr_accessor :retweeted_by
  
  def is_link
    !self.link.nil?
  end
  
  def msg_type
    reply_msg_id ? $msg_type_reply : (is_link ? $msg_type_link : $msg_type_text)
  end
  
  def creator_or_retweeter_id
    retweeted_by ? retweeted_by : creator_id
  end
  
  def retweeter_ids
    # returns id's of users who have retweeted this message
    Misc.str_to_int_arr(self.retweet_user_ids)
  end
  
  def add_retweeter(retweeter_user_id)
    unless self.retweeter_ids.include?(retweeter_user_id)
      self.update_attribute(:retweet_user_ids, self.retweet_user_ids + "#{retweeter_user_id},")
    end
  end
  
  def add_link(w) # does not save object!
    if link.nil?
      link = w
    elsif link2.nil?
      link2 = w
    elsif link3.nil?
      link3 = w
    end
  end
    
  def personal_salience(user_id)
    user_sal = tag_sal = []
#    words = text.split
#    words.each do |w|
#      html_type_cleaned = Message.analyze_word(w)
#      if html_type_cleaned[1] == '@'
#        # ADD THIS, WHEN RETWEET, /BY, /VIA, etc.
#        #us = UserStrength.find_by_user_id_and_followed_id(user_id, User.find_by_login(html_type_cleaned[2]))
#        #user_sal << us.multiplier(msg_type) unless us.nil?
#      elsif html_type_cleaned[1] == '#'
#        ts = TagStrength.find_by_user_id_and_tag_id(user_id, Tag.find_by_name(html_type_cleaned[2]).id)
#        tag_sal << ts.multiplier unless ts.nil?
#      end
#    end
    tags_mentioned.each do |tm|
      ts = TagStrength.find_or_create_by_user_id_and_tag_id(:user_id => user_id, :tag_id => tm.id)
      #logger.debug "ts: #{ts.inspect}"
      tag_sal << ts.multiplier
      #logger.debug "tag_sal: #{tag_sal.inspect}"
    end
    tag_sal = Misc.mean_or_one(tag_sal)
    #logger.debug "tag_sal after mean: #{tag_sal.inspect}"
    
    #user_sal = (eval user_sal.join('+'))*1.0 / user_sal.size # calculates mean
    creator_str = UserStrength.find_by_user_id_and_followed_id(user_id, retweeter_or_creator_id)
    user_sal = creator_str.multiplier(self.msg_type) # unless creator_str.nil?
    
    [user_sal*tag_sal, user_sal, tag_sal]
  end
  
  def retweeter_or_creator_id
    retweeted_by ? retweeted_by : creator_id
  end
  
  def reanalyze_message
    MsgTag.find_all_by_message_id(id).each { |mt| mt.destroy }
    MsgUser.find_all_by_message_id(id).each { |mu| mu.destroy }
    analyze_message
  end
  
  def analyze_message # ideally needs to be done only once, when the message is created 
    words = text.split
    users_mentioned = []
    tags_mentioned = []
    link = link2 = link3 = nil
    words.each_with_index do |w, i|
      # not a link, if tag or user, create connections:
      htmTypCle = Message.analyze_word(w)
      #words[i] = htmTypCle[0]
      if htmTypCle == 'link'
        add_link(htmTypCle[2])
      elsif htmTypCle[1] == '@'
        users_mentioned << htmTypCle[2] # login
      elsif htmTypCle[1] == '#'
        tags_mentioned << htmTypCle[2] # tag name
      end
    end
    
    logger.debug "\n\nself: #{self.inspect}\n\n"
    res = self.save
    logger.debug "\n\nsave results: #{res.inspect}\n\n"
    # create user and tag connections; need to be created after save, because msg don't have id before that:
    users_mentioned.each do |um|
      ut = Time.now
      usr = User.find_or_create_by_login(:login => um)
      MsgUser.create(:message_id => self.id, :user_id => usr.id)
      $times[:user] << Time.now - ut
    end
    logger.debug
    tags_mentioned.each do |tm|
      ht = Time.now
      tag = Tag.find_or_create_by_name(:name => tm)
      MsgTag.create(:message_id => self.id, :tag_id => tag.id)
      $times[:hashtag] << Time.now - ht
    end
  end
  
  def html
    msg_html = ""
    words = text.split
    words.each_with_index do |w, i|
      htmTypCle = Message.analyze_word(w)
      #logger.debug htmTypCle.inspect
      msg_html << ((htmTypCle[1] == '@' or htmTypCle[1] == '#') ? "<span class='micro'> </span>" : ' ') << htmTypCle[0]
    end
    msg_html
  end
  
  # CLASS METHODS:
  
  def self.analyze_word(w)
    w.strip!
    return [w,'',''] if w.length < 2
    html = type = cleaned = ""
    #type = cleaned = nil
    if !!(link_starts = w[0..8] =~ /http:\/\//) && !!(w =~ /\./) # do so that includes https's too..
      # is link if starts with 'http://' and has '.' in it
      type = 'link'
      unless (end_char = w[-1..-1] =~ /[.)]/ ? w[-1..-1] : '').empty?
        w = w[0..-2]
      end
      w = w[0..-2] if w[-1..-1] == '/' # remove last / from url
      html = link_starts > 0 ? w[0..link_starts-1] : ""
      host = w[link_starts+7..-1]
      host = host[4..-1] if host =~ /www\./
      host = host[0..( (host_ends = host =~ /\//).nil? ? -1 : host_ends - 1 )]
      cleaned = w[link_starts..-1]
      html << "<a class='link_out button' href='#{cleaned}'>#{host}</a>#{end_char}"
    elsif start_ind = (w =~ /@/) # w[0,1] == "@"
      type = '@'
      end_ind = w[start_ind+1..-1] =~ @@spec_char
      cleaned = end_ind ? w[start_ind+1..start_ind+end_ind] : w[start_ind+1..-1] # username
      html = "#{start_ind>0 ? w[0..start_ind-1] : ''}<a class='user_link button' href='/#/user/#{cleaned}'>#{cleaned}</a>#{end_ind ? w[start_ind+1+end_ind..-1] : ''}" # title='@#{cleaned}' 
    elsif start_ind = (w =~ /#/) and (start_ind==0 or w[start_ind-1] != 38) # 38='&', excludes special characters, eg. &#8211;
      type = '#'
      # should not count as tag IF after taking extra characters away (like :) is a number or only length of one (#234 #o: #O #445:)
      end_ind = w[start_ind+1..-1] =~ @@spec_char
      cleaned = end_ind ? w[start_ind+1..start_ind+end_ind] : w[start_ind+1..-1] # username
      html = "#{start_ind>0 ? w[0..start_ind-1] : ''}<a class='hashtag_link button' href='/#/tag/#{cleaned}'>#{cleaned}</a>#{end_ind ? w[start_ind+1+end_ind..-1] : ''}" # title='##{cleaned}'
    else
      html = w
    end
    [html, type, cleaned.downcase]
  end
  
  
  def self.create_and_analyze(hash)
    #hash.class
    t = Time.now
    msg = Message.new(hash)
    #logger.debug "CREATING MESSAGE. after new: #{msg.inspect}"
    $times[:creating] += (t2 = Time.now) - t
    msg.analyze_message # better way would be to do this automatically everytime new message is created
    #logger.debug "AFTER SAVED: #{msg.inspect}"
    $times[:analyzing] += Time.now - t2
    logger.debug "\n\n msg in create_and_analyze: #{msg.inspect} \n\n"
    msg.id ? msg : nil
  end
  
  def self.find_or_create_from_search(m_hash)
    m_hash['user'] = { 'screen_name' => m_hash['from_user'], 'id' => m_hash['from_user_id'], 'profile_image_url' => m_hash['profile_image_url'] }
    Message.find_or_create(m_hash)
  end
  
  def self.find_or_create(m_hash)
    if m_hash['retweeted_status']
      # retweeted message:
      logger.debug "---------------------------------\n\n"
      logger.debug "hash #{m_hash['retweeted_status'].inspect}"
      rt_msg = Message.find_or_create(m_hash['retweeted_status'])
      logger.debug "\n\n rt_msg #{rt_msg.inspect}"
      
      # process retweeter (add to 'retweet_user_ids' and 'msg.retweeted_by')
      retweet_creator = User.find_by_login(m_hash['user']['screen_name'])
      if retweet_creator.nil? or retweet_creator.description.nil? #retweet_creator.twitter_id.nil?
        retweet_creator = User.new_from_twitter_hash(m_hash['user'])
      end
      rt_msg.add_retweeter(retweet_creator.id) # adds to the database
      rt_msg.retweeted_by = retweet_creator.id # adds current retweeter temporalily to be show in the feed
      return rt_msg
    end
      
    msg = Message.find_by_twitter_id(m_hash['id'].to_i)
    if msg.nil? or msg.id.nil?
      creator = User.find_by_login(m_hash['user']['screen_name'])
      creator = User.new_from_twitter_hash(m_hash['user']) if creator.nil? or creator.twitter_id.nil?
      logger.debug "\n\n cratetor: #{creator.inspect}\n\n"
      
      
      # normal message:
      msg = Message.create_and_analyze(:twitter_id => m_hash['id'].to_i, :text => m_hash['text'],
                :retweet_user_ids => "", :creator_id => creator.id, :created_at => m_hash['created_at'])
    else
      logger.debug "MESSAGE FOUND - NOT CREATED, #{msg.inspect}"
    end
    # this could save from unnecessary database fetch: return { :msg => msg, :creator => (creator ? creator : nil) }
    msg
  end
    
#  def self.parse_from_hash(hash_array)
#    messages = []
#    hash_array.each do |h| # h=hash
#      msg = Message.find_or_create_by_twitter_id(:twitter_id => h['id'], :text => h['text'], :created_at => h['created_at'])
#      msg.analyze_message
#      if msg.creator_id.nil?
#        # new message, update creator:
#        user_hash = h['user']
#        unless usr = User.find_by_login(user_hash['screen_name'])
#          # create new user, because not found:
#          usr = User.new_from_twitter_hash(user_hash)
#          #usr = User.create(:login => user_hash['screen_name'], :twitter_id => user_hash['id'])
#          begin
#            pic = Picture.from_url(user_hash['profile_image_url'])
#          rescue
#            pic_id = nil
#          end
#          usr.update_attribute(:picture_id, pic.id) unless pic.nil?
#        end
#        # user found or created, update message creator:
#        msg.update_attribute(:creator_id, usr.id)
#      end
#      messages << msg
#    end
#    messages
#  end
  
  
 
#  def self.parse_from_xml(api_request)
#    doc = REXML::Document.new(current_user.twitter.get(api_request))
#    
#    messages = []
#    
#    doc.elements.each('statuses/status') do |e|
#      msg = Message.find_or_create_by_twitter_id(:twitter_id => e.elements["id"].text, :text => e.elements["text"].text)
#      if msg.creator_id.nil?
#        # new message, update creator:
#        el_u = e.elements["user"]
#        unless usr = User.find_by_login(el_u.elements["screen_name"].text)
#          # create new user, because not found:
#          usr = User.create(:login => el_u.elements["screen_name"].text, :twitter_id => el_u.elements["id"].text)
#          begin
#            pic = Picture.from_url(el_u.elements["profile_image_url"].text)
#          rescue
#            pic_id = nil
#          end
#          usr.update_attribute(:picture_id, pic.id) unless pic.nil?
#        end
#        # user found or created, update message creator:
#        msg.update_attribute(:creator_id, usr.id)
#      end
#      messages << msg
#    end
#    messages
#  end
  
end