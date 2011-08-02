class MessageController < ApplicationController
  
  def change_response
    logger.debug "CHANGE RESPONSE"
    time = Time.now
    return if params[:msg_id].nil?
    msg = Message.find(params[:msg_id])
    #orig_msg_id = msg.id
    #msg = Message.find(msg.retweet_msg_id) if msg.retweet_msg_id
    ms = MessageStatus.find_or_create_by_user_id_and_message_id(:user_id => session[:user_id],
                                                                :message_id => msg.id)
    # TODO: add test to make sure message has not been created by current user <- but how to give error notice?
    old_status = ms.status
    new_status = params[:status].to_i
    pos_change = neg_change = read_change = 0
    if new_status != old_status
      pos_change += -1 if old_status == $msg_like
      neg_change += -1 if old_status == $msg_dont_like
      read_change += -1 if old_status == $msg_read
      pos_change += 1 if new_status == $msg_like
      neg_change += 1 if new_status == $msg_dont_like
      read_change += 1 if new_status == $msg_read
    end
    msg.update_attributes(:pos => msg.pos + pos_change, :neg => msg.neg + neg_change, :read => msg.read + read_change)
    ms.update_attribute(:status, new_status) # new_status
    UserStrength.shift_user_and_tag_strengths(session[:user_id], msg, pos_change, neg_change, read_change)
    
    # lisätäänkin
    
    msg_ind = -1
    session[:all_msgs].each_with_index { |mh,i| msg_ind = i and break if mh[:id] == msg.id }
    render :text => "<script>notice('Failed to change message status on server')</script>" and return if msg_ind == -1
    session[:all_msgs][msg_ind][:status] = ms.status
    session[:all_msgs][msg_ind][:status_updated] = Time.now.to_i - 0.1
    
    # mark "gray" messages as read (status = 3)
    read_msg_ids = Misc.str_to_int_arr(params[:read_msg_ids])
    logger.debug "read_msg_ids: #{read_msg_ids}"
    ind_of_read_msgs = []
    session[:all_msgs].each_with_index do |mh,i|
      if read_msg_ids.include?(mh[:id])
        MessageStatus.find_or_create_by_user_id_and_message_id(:user_id => session[:user_id], :message_id => mh[:id], :status => $msg_read)
        session[:all_msgs][i][:status] = $msg_read
        session[:all_msgs][i][:status_updated] = Time.now.to_i
        UserStrength.shift_user_and_tag_strengths(session[:user_id], mh[:id], 0, 0, 1) # 

        #ind_of_read_msgs << i
        #hidden_msgs_without_visible << i+1 if cur_msgs[i+1][0].class == Array
      end
    end
    
#    # check if hidden messages without any visible messages:
#    grow_steps = 0;
#    (ind_of_read_msgs + [msg_ind]).each do |ind|
#      i = ind + grow_steps
#      if cur_msgs[i+1][0].class == Array
#        cur_msgs[i].insert(cur_msgs[i][0])
#        grow_steps += 1
#        #cur_msgs.delete_at(i+1) if cur_msgs[i+1].empty?
#      end
#    end   
    session[:change_response_time] = "Change response took #{Time.now-time} secs"
    
    render :partial => "/message/message_info", :locals => { :msg => msg }
    #render :nothing => true
  end
  
  def create
    msg_hash = cur_user.twitter.post('/statuses/update', 'status' => params[:message_text])
    msg = Message.create_and_analyze(:twitter_id => msg_hash['id'].to_i, :text => msg_hash['text'],
                         :creator_id => session[:user_id], :created_at => msg_hash['created_at'])
    @dont_have_tag = true
    msg.text.split.each do |word|
      if Message.analyze_word(word)[1] == '#'
        @dont_have_tag = false
        break
      end
    end
    render :partial => '/misc/notice', :locals => { :msg => msg }
  end
  
  def retweet_msg
    msg = Message.find(params[:msg_id])
    begin
      cur_user.twitter.post("/statuses/retweet/#{msg.twitter_id}")
      @success = "Message retweeted!" # not shown anywhere...
    rescue
      @error = "Retweet failed!" # not shown anywhere at the moment...
    end
    msg.add_retweeter(session[:user_id])
    render :partial => "/message/message_info", :locals => { :msg => msg }
  end
  
  
  private
  
  def remove_answered(msg_ids)
    
    cur_msgs.delete_if { |m| msg_ids.include?(m[0]) }
    
    #same for tags
    
  end
  
  
  # OLD:
  
  def update_messages__old
    logger.debug "UPDATE MESSAGES"
    msgs = []
    cur_user.user_strengths.each do |us|
      msgs << us.twitter_user.messages if us.strength >= 2
    end
    # remove old messages:
    old_msgs = MessageStatus.find_all_by_user_id(session[:user_id])
    old_msgs = old_msgs.collect { |ms| ms.message }
    cur_msgs = msgs.flatten - old_msgs
    # TEE YLEMPI NIIN ETTEI TARVII HAKEE VANHOJA VIESTEJÄ, eli pelkän id:n perusteella
    cur_msgs.collect! { |msg| [msg, 0, msg.salience(session[:user_id])] } # message/id, status, salience
    
    # order messages:
    cur_msgs.sort! { |a,b| b[2] <=> a[2] }
    
    session[:messages_updated] = Time.now
    redirect_to :controller => 'main_page', :action => 'feeds'
  end
end
