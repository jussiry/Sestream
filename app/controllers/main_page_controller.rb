#require 'net/http'

#require 'rexml/document'
#require 'open-uri'


class MainPageController < ApplicationController
  
  #include ApplicationHelper
  
  def main_page
    #render :partial => '/main_page/new_user_form' and return if session[:user_id].nil?
    
    #redirect_to :action => 'search' and return if cur_show_search
    
    #update_messages
    
    #  render :text => 'plaa', :layout => false
    #  return
    render :template => '/pages/main_page'
  end
  
  def update_messages
    # LOAD FROM TWITTER:
    time = Time.now # timer
    logger.debug "UPDATING MESSAGES"
    session[:latest_twid] = 1 if session[:latest_twid].nil?
    begin
      messages = cur_user.twitter.get("/statuses/home_timeline?count=200&since_id=#{session[:latest_twid]+1}")
    rescue
      #@error = "Failed to retrieve messages from Twitter. API over limit?"
      render :text => "<script>notice('Failed to connect to Twitter.');</script>" and return
    end
    session[:timer] = "  After fetching from twitter: #{Time.now-time}"
    #render :text => messages.inspect and return
    
    # CREATE NEW MESSAGES:
    @msgs = []
    @new_messages = 0
    $times = { :creating => 0.0, :analyzing => 0.0, :user => [], :hashtag => [] }
    messages.each do |m_hash| # array of hashes
      next unless msg = Message.find_or_create(m_hash)
      if msg.retweeted_by and MessageStatus.find_by_message_id_and_user_id(msg.id, session[:user_id]).nil?
        retweeter = User.find(msg.retweeted_by)
      else
        retweeter = nil
      end
      retweeter_login = retweeter ? retweeter.login : false
      retweeter_pic = retweeter ? retweeter.pic_src : false
      logger.debug "msg: #{msg.inspect}"
      logger.debug "creator: #{msg.creator}"
      creator = msg.creator
      us = UserStrength.find_or_create_by_user_id_and_followed_id(:user_id => session[:user_id], :followed_id => msg.retweeter_or_creator_id) # @msgs[-1].ret..
      if not us.following
        us.update_attributes(:following => true, :text_pos => us.text_pos+1, :link_pos => us.link_pos+1, :reply_pos => us.reply_pos+1)
      end
      # ADD CREATOR DATA TO USER ARRAY:
      session[:users] = {} if session[:users].nil?
      if session[:users][creator.login].nil? or session[:users][creator.login][:updated].nil? or Time.now - session[:users][creator.login][:updated] > 15.minutes  
        session[:users][creator.login] = { :login => creator.login, :name => creator.name,
              :description => creator.description, :image => creator.profile_image_url_orig,
              :location => creator.location, :image_bigger => creator.profile_image_url_bigger, :pos => us.pos,
              :neg => us.neg, :read => us.read, :percentage => us.percentage, :updated => Time.now,
              :following => us.following }
      end
      base_sal = msg.personal_salience(session[:user_id])[0]
      @msgs << { :id => msg.id, :html => msg.html, :pos => msg.pos, :neg => msg.neg, :read => msg.read, :twitter_id => msg.twitter_id,
                 :created_at => msg.created_at, :creator_login => creator.login, :creator_pic => creator.pic_src,
                 :status => 0, :base_sal => base_sal, :salience => (base_sal * Misc.age_bonus(msg.created_at)),
                 :retweeter_login => retweeter_login, :retweeter_pic => retweeter_pic, :status_updated => 0 }
      # USER STRENGTHS SHOUD BE SAVED SO THAT THEY DON'T NEED TO BE RETRIEVED IN MESSAGE.SALIENCE AGAIN
      logger.debug "msg: #{msg.inspect}, creator: #{creator.inspect}"
      @new_messages += 1
    end
    
    session[:timer] << "  After new messages created and analyzed: #{Time.now-time}"
    
    # remove old messages:
    #last_message = cur_msgs.nil? ? @msgs[-1] :
    #               (cur_msgs[-1].class == Hash ? cur_msgs[-1][:msg] : cur_msgs[-1][-1][:msg])
#    unless @msgs[-1].nil?
#      # is this ever usefull, except when servers are restarted and old, answered messages re-fetched?
#      old_msgs = MessageStatus.find(:all, :conditions =>
#                 "user_id = #{session[:user_id]} AND created_at > '#{@msgs[-1][:created_at]}'")
#      old_msgs = old_msgs.collect { |ms| ms.message_id }
#      @msgs.delete_if { |mh| old_msgs.include?(mh[:id]) }
#    end
    
    #session[:timer] << "  After old/answered messages removed: #{Time.now-time}"
    
    #@msgs.collect! { |msg| { :msg => msg, :status => 0,
    #              :base_sal => msg.personal_salience(session[:user_id])[0] } } # message/id, status, salience
    
    
    #session[:timer] << "  After base salience calcultated: #{Time.now-time}"
    
    #hide_flooders
    
    session[:all_msgs] = [] if session[:all_msgs].nil?
    
    # refresh salience:
    session[:all_msgs].each_with_index do |mh,i|
      session[:all_msgs][i][:salience] = mh[:base_sal] * Misc.age_bonus(mh[:created_at])
    end
    # add new messages:
    session[:all_msgs] += @msgs
    # sort and clean old messages:
    session[:all_msgs].sort! { |a,b| b[:salience] <=> a[:salience] }
    session[:all_msgs] = session[:all_msgs][0..800]
    
    # temporary fix for removing duplicates:
    session[:all_msgs].each_with_index do |msg1, i1|
      session[:all_msgs][i1+1..-1].each_with_index do |msg2, i2|
        if msg1[:id] == msg2[:id]
          logger.debug "DELETED DUPLICATE MESSAGE: #{msg2.inspect}"
          session[:all_msgs][i1+1+i2][:delete] = true
        end     
      end
    end
    session[:all_msgs].delete_if { |mh| mh[:delete] }
    
    # clean old user data:
    if session[:users].size > 300
      session[:users].delete_if { |login, udh| Time.now - udh[:updated] > 3.days }
    end
    
    
    session[:latest_twid] = @msgs[0][:twitter_id] if @msgs[0] # and (session[:latest_twid].nil? or @msgs[0][:twitter_id] > session[:latest_twid])
    
    
    #session[:timer] << "  After hide_flooders: #{Time.now-time}"
    
    # clean messages from session (only leaving id's)
#    cur_msgs.each do |mh|
#      if mh.class == Array
#        mh.each { |m| m.delete(:msg) }
#      else
#        mh.delete(:msg)
#      end
#    end

    session[:msgs_updated] = Time.now
    #logger.debug "message array: #{session[:msgs][:new].inspect}"
    #redirect_to :controller => 'main_page', :action => 'feeds'
    
    render :partial => '/templates/js_update'
  end
  


#  def messages
#    if not cur_user.initialized
#      cur_user.init_user_strengths
#      cur_user.update_attribute(:initialized, true)
#    end
#    
#    if params[:cs] # new, old, ...
#      session[:cs] = params[:cs].to_sym
#    elsif params[:tag]
#      session[:cs] = params[:tag]
#    end
#    
#    #update_messages unless params[:tag]
#    
##    if session[:cs] == :new
##      # updates also tag links:
##      render :file => 'main_page/page_content_and_tags'
##    else
#      render :partial => "<script> all_msgs = #{ActiveSupport::JSON.encode(session[:all_msgs])}; show_new_messages(); </script>"
##    end
#  end
  
  def tag_links
    render :partial => 'main_page/tag_links'
  end
#  def page_content_and_tags
#  end
  
  def following
    render :text => 'Error: no user logged in.' and return if session[:user_id].nil?
    session[:cs] = :following
    #load_followed_users_and_tags
    render :partial => 'main_page/following' 
  end
  
  def search
    srch_txt = params[:search_txt] ? params[:search_txt].strip : session[:cs]
    redirect_to :action => 'main_page' and return if srch_txt.class == Symbol
    #redirect_to :action => 'main_page' if srch_txt.class == Symbol; return
    #logger.debug "SRCH_TXT: " + srch_txt.class.inspect
    
    srch_txt = srch_txt[1..-1] if srch_txt[0..0] == '@'
    #render :text => params.inspect and return
    time = Time.now # timer
    begin
      search_hash = cur_user.twitter.get("/search?q=#{CGI.escape(srch_txt)}&rpp=20")
    rescue
      render :text => "Sorry, failed to retrieve messages from Twitter. Could be that their service is down, or maybe you'v run into your API call limit. Try again bit later." and return
    end
    session[:timer] = "After fetching from twitter: #{Time.now-time}"
    #render :text => search_hash['results'].inspect and return
    @msgs = []
    #f_or_c = ms_find = []
    
    $times = { :creating => 0.0, :analyzing => 0.0, :user => [], :hashtag => [] }
    search_hash['results'].each do |m_hash|
      msg = Message.find_by_twitter_id(m_hash['id'].to_i)
      status = 0
      if msg.nil?
        msg = Message.find_or_create_from_search(m_hash)
      else
        ms = MessageStatus.find_by_user_id_and_message_id(session[:user_id], msg.id)
        status = ms.status if ms
      end
      @msgs << { :msg => msg, :status => status }
    end
    session[:timer] << "  After creating messages: #{Time.now-time}"
    session[:cs] = srch_txt
    session[:msgs][session[:cs]]  = @msgs
    
    if params[:search_txt].nil?
      render :main_page
    else
      render :partial => 'main_page/search'
    end
    
  end
  
  
  def show_hidden_messages
    cont_ind = -1
    cur_msgs.each_with_index { |mh,i| cont_ind = i and break if mh.class == Array and mh[0][:msg].creator_or_retweeter_id == params[:creator_id].to_i }
    #cont_ind = params[:cont_ind].to_i
    logger.debug "cont_ind: #{cont_ind}"
    @msgs_by_id = cur_msgs[cont_ind][0..$show_hidden_msgs-1]
    #@msgs = @msgs_by_id.collect { |mh| mh[:msg] = Message.find(mh[:msg_id]); mh }
    #logger.debug "@msgs: #{@msgs.inspect}"
    cur_msgs[cont_ind] = cur_msgs[cont_ind][$show_hidden_msgs..-1]
    @msgs_left = cur_msgs[cont_ind].nil? ? 0 : cur_msgs[cont_ind].size
    cur_msgs.delete_at(cont_ind) if @msgs_left == 0
    logger.debug "cur_msgs: #{cur_msgs.inspect}"
    logger.debug "@msgs_by_id: #{@msgs_by_id.inspect}"
    session[:msgs][session[:cs]] = cur_msgs[0..cont_ind-1] + @msgs_by_id + cur_msgs[cont_ind..-1]
    
    #logger.debug "@msgs_left: #{@msgs_left}"
    render :partial => "/message/render_msgs"
  end
  
  
  
  def inspect_session
    render :text => session.inspect
  end
  
#  def session_test
#    #render :text => ActionController::Base.session_options.inspect and return
#    if session[:user_id]
#      render :text => "on juuseri" and return
#    else
#      render :text => "EI OO ENNÄÄ"
#      session[:user_id] = 1
#      return
#    end
#  end
  
    
  def test
    #logger.debug "plaa"
    
    msg = cur_user.twitter.post('/statuses/update', 'status' => 'Testing pesti & vesti.')
    render :text => msg['text']
    
    #i = open("http://a3.twimg.com/profile_images/64711087/ohi_normal.jpg")
    #file = File.new("tmp.jpg", "w+")
    #File.open("tmp.jpg", 'w') {|f| f.write(i.read) }
    #render :text => File.writable?("tmp.jpg")
  end
  
end
