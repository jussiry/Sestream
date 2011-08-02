# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  #helper :all # doesn't work anymore...
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  #ActionController::Base.session_options[
  #ActionController::Base.session_options[:expire_after] = 7.days
  #ENV["rack.session.options"][:expire_after] = 7.days
  
  include ApplicationHelper
  
  before_filter :every_time
  
  def every_time
    return if params[:controller] == 'maintenance'
    
    #
    # this is executed every time before any action. Session checking...
    #
    session[:ip] = request.remote_ip
    unless request.env['HTTP_REFERER'].nil? or request.env['HTTP_REFERER'] =~ /tweets.vidious.net/
      session[:referring_url] = request.env['HTTP_REFERER']
    end
    return if params[:controller] == 'sessions' or params[:action] == 'test'
    if session[:user_id].nil? and params[:controller] != 'maintenance'
      # not logged in, show welcome / log in screen
      
      render :template => '/pages/new_user_form' and return
      
    else
      # test if logged in last time from this, or some other computer
      if cur_user.current_session_id.nil?
        # first time user
        session.each do |key, value|
          session[key] = nil unless key == :user_id or key == :_csrf_token
        end
        #session[:cs] = :new
        #session[:tag_names] = []
        session[:latest_twid] = 2
        session[:all_msgs] = []
        # set new session as active session:
        cur_user.update_attribute(:current_session_id, request.session_options[:id])
      elsif cur_user.current_session_id != request.session_options[:id]
        # previously logged in from another computer (or browser).
        # copy data from that session to current:
        old_session = ActiveRecord::SessionStore::Session.find_by_session_id(cur_user.current_session_id)
        #new_session = ActiveRecord::SessionStore::Session.find_by_session_id(request.session_options[:id])
        if old_session
          Message;MsgTag;Tag;User;MessageStatus
          old_session.data.each do |key, value|
            session[key] = value unless key == :_csrf_token
          end
        end
        # session datan muokkaaminen ei toimi, koska .data hashia ei saa tallennettua (tai en ainakaan tiedä miten se tehdään. näin ollen koko sessio joudutaan tuohoamaan:
        # toisaalta sessiot tuhoutuvat automaattisesti 7 päivän kuluessa jos niitä ei käytetä, joten ei tarvetta tuhota niitä täällä
        #old_session.destroy
        cur_user.update_attribute(:current_session_id, request.session_options[:id])
      end
      # current session == active session; everyting OK
    end
  end
  
  
  private

  def create_user(username)
    @user = User.create
    username = @user.id.to_s if username.nil? 
    @user.username = username
    @user.save
    session[:user_id] = @user.id
  end
end
