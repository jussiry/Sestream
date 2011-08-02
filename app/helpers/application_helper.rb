# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  $active_session_ids = {} if $active_session_ids.nil? # taitaa kyllä olla aina nil (kun serveri käynnistetään uudelleen)...
  
  $def_user_strength = 3 # positive user strength by default for users that are followed
  
  $show_msgs_per_user = 2
  $show_hidden_msgs = 4 # how many hidden messages to show with a single "show more by user ..." -click
  
  $msg_like = 1
  $msg_dont_like = 2
  $msg_read = 3
  
  $msg_type_link = 1
  $msg_type_text = 2
  $msg_type_reply = 3
    
  def cur_user
    return @cur_user if @cur_user
    return nil if session[:user_id].nil?
    @cur_user = User.find(session[:user_id])
  end
  
  def user(login)
    User.find_by_login login
  end
  
  def user_sess(login)
    # TODO ................................... <- functions like this should be on one line, not three
  end
  
  def cur_msgs
    session[:msgs].nil? ? [] : session[:msgs][session[:cs]]
  end
  
  def cur_show_search
    (session[:cs].class == String and session[:cs][0..1] != '@' and session[:cs][0..1] != '#')
  end
  
  def link_to_t_user(usr_name)
    "<a class='user_link' title='@usr_name' href='http://twitter.com/#{usr_name}'>#{usr_name}</a>"
  end
  
  def limit_text(text, limit)
    if text.length > limit
      return text[0..(limit-4)] + "..."
    else
      return text
    end
  end
  
  def hide_flooders # and sort tags...
    # for users with more than 'show_msgs' messages, hides them (in array after last visible):
    
    @msgs = (@msgs ? @msgs : []) + (cur_msgs.nil? ? [] : cur_msgs)
    @msgs = @msgs.flatten[0..600]
    session[:number_of_messages] = @msgs.size
    
    if session[:msgs]
      session[:msgs].delete_if { |group_name, value| (group_name.class == String) } # delete previous tags 
    end
    
    # recalculate salience and order based on it
    @msgs.each_with_index do |mh,i|
      mh[:salience] = mh[:base_sal] * Misc.age_bonus(mh[:msg].created_at)
    end
    session[:msgs][session[:cs]] = @msgs
    logger.debug @msgs.inspect
    @msgs.sort! { |a,b| b[:salience] <=> a[:salience] }
    
    # tags:
    #logger.debug "Start processing tags:"
    @msgs.each do |mh|
      #next if mh[:msg].nil? # before only msg_id:s were saved to session
      #logger.debug "---------- message found........................."
      mh[:msg].tags_mentioned.each do |tag|
        session[:msgs]['#'+tag.name] = [] if session[:msgs]['#'+tag.name].nil?
        session[:msgs]['#'+tag.name] << mh
      end
    end
    session[:tag_names] = []
    session[:msgs].each do |key, value|
      if key.class == String # tag
        session[:tag_names] << [key, value.size]
      end
    end
    session[:tag_names].sort! { |a,b| b[1] <=> a[1] }
    
    msgs_by_user = {}
    msgs_tmp = []
    @msgs.each do |mh|
      creator_id = mh[:msg].creator_or_retweeter_id
      next if mh == [] # hidden message container possibly inserted on last round
      cur = msgs_by_user[creator_id] # messages (number if < 3, else container of rest) by this user
      msgs_by_user[creator_id] = cur = cur.nil? ? 1 : cur + 1 unless cur.class == Hash
      if cur.class == Hash
        msgs_tmp[cur[:ind]] << mh # add to hidden message container
        #@msgs.delete_at(i) # delete from visible messages
      elsif cur >= $show_msgs_per_user
        msgs_tmp << mh
        msgs_tmp << [] # create container
        msgs_by_user[creator_id] = { :ind => msgs_tmp.size-1 } # index of container
      else
        msgs_tmp << mh
      end
    end
    @msgs = msgs_tmp.delete_if { |e| e.class == Array and e.empty? }
    session[:msgs][session[:cs]] = @msgs
  end
  
  def time_ago_text(time)
    ago = Time.now - time
    if ago < 60*60 #  < 60s * 60m == 1 hour
      "#{(ago/60).to_i} min"
    elsif ago < 60*60*24
      "#{(ago/60/60).to_i} hr"
    else
      "#{(ago/60/60/24).to_i} day"
    end
  end
  
end
