class MaintenanceController < ApplicationController
  
  #caches_page :picture
  caches_action :picture
  
  def debug
    render :partial => '/maintenance/debug'
  end
  
  def picture
    pic = Picture.find(params[:id])
    send_data(pic.picture_data, :filename => "t_user_pic", :type => pic.picture_type, :disposition => "inline" )
  end
  
  def test
    #render :text => TwitterAuth::Dispatcher::Basic.get("/search?q=#{CGI.escape("school")}").inspect
    #render :text => CGI.escape('#twitter')
    
    # http://a1.twimg.com/profile_images/70050636/techPresident_–_How_the_candidates_are_using_the_web__and_how_the_web_is_using_them._normal.jpg
    #begin_time = Time.now
    #plaa = cur_user.twitter.get("/statuses/home_timeline?count=20")
    #time_past = Time.now - begin_time
    #render :text => request.env['HTTP_REFERER'].inspect #session.inspect #Message.first.tags_mentioned.inspect
    
    if true
      plaa = "jaa jaa"
    end
    render :text => "taa: #{plaa}"
  end
  
  def test_json
    render :json => session[:msgs]
  end
  
  
  def inspect_sessions
    render :text => "no access" and return unless (cur_user and (cur_user.login == "jussir" or cur_user.login == 'jjmajava'))
    MsgTag;Tag;Message;User
    @sessions = ActiveRecord::SessionStore::Session.all
  end
    
  def evaluate
    #if cur_user.nil? or cur_user.login != "jussir"
    #  render :text => "This operation requires administrator privileges." and return
    #end

    if params[:command]
      logger.debug "command: #{params[:command]}"
      @result = "" if @result.nil?
      time_start = Time.now
      begin
        @auto_result = eval(params[:command])
      rescue Exception => e #er
        @auto_result = "ERROR in command: #{e.message}"
      end
      @time = Time.now - time_start
      render :partial => 'maintenance/command_result'
      #render :text => "$('#eval_container').html('jaaja')"
    end
  end
  
  def recount_responses
    if cur_user.nil? or cur_user.login != "jussir"
      render :text => "This operation requires administrator privileges." and return
    end
    Message.all.each do |m|
      p = n = r = 0
      MessageStatus.find_all_by_message_id(m.id).each do |ms|
        if ms.status == $msg_like
          p += 1
        elsif ms.status == $msg_dont_like
          n += 1
        elsif ms.status == $msg_read
          r += 1
        end
      end
      m.update_attributes(:pos => p, :neg => n, :read => r)
    end
    render :text => "done"
  end
  
  def destroy_old_sessions
    render :text => "no access" and return unless (cur_user and cur_user.login == "jussir")
    #plaa = ''
    Message;MessageStatus;User;Tag;MsgTag;MsgUser;TagStrength;UserStrength
    ActiveRecord::SessionStore::Session.all.each do |s|
      #plaa << " #{s.data[:user_id] ? s.data[:user_id] : 0}"
      s.destroy if s.data[:user_id].nil?
    end
    render :text => "done"
  end
  
  def reset_sessions
    User.all.each do |u|
      u.update_attribute(:current_session_id, nil)
    end
    
    render :text => "done. " + ($time ? "took #{Time.now-$time} secs" : '')
  end
  
  def reanalyze_messages
    if cur_user.nil? or cur_user.login != "jussir"
      render :text => "This operation requires administrator privileges." and return
    end
    $time = Time.now
    Message.all.each do |m|
      m.reanalyze_message
    end
    redirect_to :action => 'reset_msgs_in_sessions'
    #render :text => "done"
  end
  
  def recount_msg_statuses
    if cur_user.nil? or cur_user.login != "jussir"
      render :text => "This operation requires administrator privileges." and return
    end
    #from = params[:from] ? params[:from].to_i : 0
    #to = params[:to] ? params[:to].to_i : -1
    time = Time.now
    Message.all.each do |msg|
      msg.update_attributes(:pos => 0, :neg => 0, :read => 0)
    end
    UserStrength.all.each do |us|
      us.update_attributes(:text_pos => 0, :text_neg => 0, :text_read => 0,
                           :link_pos => 0, :link_neg => 0, :link_read => 0, 
                           :reply_pos => 0, :reply_neg => 0, :reply_read => 0)
      if us.following
        us.update_attributes(:text_pos => 1, :link_pos => 1, :reply_pos => 1, :text_neg => 1)
      end
    end
    TagStrength.all.each do |ts|
      ts.update_attributes(:pos => 0, :neg => 0, :read => 0)
    end
    MessageStatus.all.each do |ms|
      pos_change = ms.status == $msg_like ? 1 : 0 
      neg_change = ms.status == $msg_dont_like ? 1 : 0
      read_change = ms.status == $msg_read ? 1 : 0
      UserStrength.shift_user_and_tag_strengths(ms.user_id, ms.message, pos_change, neg_change, read_change)
    end
    render :text => "done. took #{Time.now - time} secs."
  end
  
end
