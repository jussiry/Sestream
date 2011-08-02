class UserController < ApplicationController
  
  def all_msgs_from_server
    creator = User.find_by_caseless_login(params[:login])
    msgs = Message.find(:all, :conditions => { :creator_id => creator.id }, :limit => 5) # :order => 'created_at DESC', 
    logger.debug msgs.inspect
    @msgs = []
    msgs.each do |msg|
      base_sal = msg.personal_salience(session[:user_id])[0]
      @msgs << { :id => msg.id, :html => msg.html, :pos => msg.pos, :neg => msg.neg, :read => msg.read, :twitter_id => msg.twitter_id,
                 :created_at => msg.created_at, :creator_login => creator.login, :creator_pic => creator.pic_src,
                 :status => 0, :base_sal => base_sal, :salience => (base_sal * Misc.age_bonus(msg.created_at)),
                 :retweeter_login => false, :retweeter_pic => false, :status_updated => 0 }
    end
    #@msgs.sort! { |a,b| b[:created_at] <=> a[:created_at] }
    #@exec_function = 'userMsgsLoaded()'
    render :partial => '/templates/js_update'
  end
  
  
  
  # OLD CODE:
  
  def user_page
    init_user_page
  end
  
  def user_partial
    init_user_page
    render :partial => "/user/user_partial"
  end
  
  
  private
  
  
  def init_user_page
    @user = User.find_or_create_by_login(:login => params[:login])
    @usr_str = UserStrength.find_or_create_by_user_id_and_followed_id(:user_id => session[:user_id], :followed_id => @user.id)
    time = Time.now
    begin
      msgs_by_user = cur_user.twitter.get("/statuses/user_timeline?screen_name=#{@user.login}&count=10&since_id=2") # add last fetched to since_id and change count to 30 
      session[:timer] = "After fetching tweets by user: #{Time.now-time}. "
      
      mentiones_of_user = cur_user.twitter.get("/search?q=@#{@user.login}")['results']
      session[:timer] << "After fetching mentions of user: #{Time.now-time}"
    rescue
      @error = "Failed to retrieve messages from Twitter."
      return
    end
    
    @all = @by = @mentions = []
    
    msgs_by_user.each do |m_hash|
      @all << Message.find_or_create(m_hash)
    end
    mentiones_of_user.each do |m_hash|
      @all << Message.find_or_create_from_search(m_hash)
    end
    
    session[:timer] << "After creating all messages (#{@all.size})."
    
    @all.sort! { |a,b| b.created_at <=> a.created_at }
    
    @all.collect! { |m| { :msg => m } }
    
    logger.debug @all.inspect
  end
  

=begin
  
  def init_user__old
    
    render :text => "init user" and return
    
    logger.debug "INIT USER"
    # if already in database:
    if usr = User.find_by_username(params[:twt_username])
      session[:user_id] = usr.id
      redirect_to :controller => 'main_page', :action => 'feeds'
      return
    end
    
    #url = "http://twitter.com/statuses/user_timeline/#{params[:twt_username]}.rss"
    #xml = File.read("http://twitter.com/statuses/user_timeline/16004101.rss")
    url = "http://twitter.com/statuses/friends/#{params[:twt_username]}.xml"
    
    begin
      doc = REXML::Document.new(open(url)) # URI.encode( )
    rescue
      render :text => "Failed to retrieve twitter account with username <strong>#{params[:twt_username]}</strong>." and return
    end
    
    tw_usr = TwitterUser.find_or_create_by_username(params[:twt_username])
    usr = User.create(:username => params[:twt_username], :twitter_user_id => tw_usr.id)
    session[:user_id] = usr.id
    
    followed_users = []
    
    # create followed twitter user
    doc.elements.each('users/user') do |a|
      tw_usr = TwitterUser.find_or_create_by_username(:username => a.elements["screen_name"].text,
                        :local_id => a.elements["id"].text.to_i, :name => a.elements["name"].text)
      if tw_usr.picture_id.nil?
        begin
          pic = Picture.from_url(a.elements["profile_image_url"].text)
        rescue
          pic_id = nil
        end
        tw_usr.update_attribute(:picture_id, pic.id) unless pic.nil?
      end
      followed_users << tw_usr
      UserStrength.create(:user => usr, :twitter_user_id => tw_usr.id, :twitter_name => tw_usr.username, :strength => 3)
    end
    
    # go through followed on twitter and who they are following
#    followed_users[0..10].each do |fu|
#      begin
#        doc = REXML::Document.new(open("http://twitter.com/statuses/friends/#{fu.username}.xml")) # URI.encode( )
#      rescue
#        next
#      end
#      logger.debug "going through #{fu.username}'s followed"
#      i = 0
#      doc.elements.each('users/user') do |e|
#        tw_usr = TwitterUser.find_or_create_by_username(:username => e.elements["screen_name"].text,
#                              :local_id => e.elements["id"].text.to_i, :name => e.elements["name"].text)
#        # ei tee kuvia (veis tilaa ja aikaa, mut toisaalta mahdollisesti tehdään myöhemmin jokatapauksessa...)
#        if us = UserStrength.find_by_user_id_and_twitter_user_id(usr.id, tw_usr.id)
#          us.update_attribute(:strength, us.strength+1)
#        else
#          UserStrength.create(:user => usr, :twitter_user_id => tw_usr.id, :twitter_name => tw_usr.username, :strength => 1)
#        end
#        break if (i =+ 1) == 10
#      end
#      logger.debug "#{i} followed found"
#    end
    
    # go through users messages to shift user and tag strengths
    logger.debug "STARTING TO GO THROUGH OWN MESSAGES"
    usr.twitter_user.messages.each do |msg|
      logger.debug "going through message #{msg.inspect}"
      # go through words in message to see if there's other users or hashtags mentioned
      msg.text.split.each do |w|
        logger.debug "going through word #{w.inspect}"
        htmTypCle = Message.analyze_word(w)
        if htmTypCle[1] == '@'
          tw_user = TwitterUser.find_or_create_by_username(:username => htmTypCle[2])
          if us = UserStrength.find_by_user_id_and_twitter_user_id(usr.id, tw_user.id)
            us.update_attribute(:strength, us.strength+1)
          else
            UserStrength.create(:user => usr, :twitter_user_id => tw_usr.id, :twitter_name => tw_usr.username, :strength => 1)
          end
        elsif htmTypCle[1] == '#'
          tag = Tag.find_or_create_by_name(:name => htmTypCle[2])
          if ts = TagStrength.find_by_user_id_and_tag_id(usr.id, tag.id)
            ts.update_attribute(:strength, ts.strength+1)
          else
            TagStrength.create(:user => usr, :tag_id => tag.id, :strength => 1) # , :tag_name => tag.name
          end
        end
      end
      
    end
    
    #render :text => "done" and return
    
    redirect_to :controller => 'main_page', :action => 'feeds'
    #render :text => "done" # doc.root.attributes["version"]

  
    #doc.elements.each('rss/channel/item') do |p|
    #  plaa << "- #{p.elements["description"].text} \n"
    #end
  end
  
=end
  
#  def logout
#    reset_session
#    redirect_to :controller => 'main_page', :action => 'feeds'
#  end
  
end
