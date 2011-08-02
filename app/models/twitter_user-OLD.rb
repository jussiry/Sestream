class TwitterUser < ActiveRecord::Base
  
  has_many :messages
  belongs_to :picture
  
  validates_uniqueness_of :username
  #validates_uniqueness_of :local_id # many can have no local id (before loaded)
  
  def messages
    # if messages_updated > 30.min
    #url = "http://twitter.com/statuses/user_timeline/#{username}.xml" # 'statuses/status'
    
    if picture_id.nil?
      # has only username - retrive other user information
      logger.debug "LOCAL ID NIL"
      begin
        doc = REXML::Document.new(open("http://twitter.com/users/show/#{username}.xml"))
      end
      doc.elements.each('user') do |e|
        #local_id = e.elements['id'].text
        #logger.debug "LOCAL ID NOW: #{local_id}"
        #name = e.elements['name'].text
        pic = Picture.from_url(e.elements["profile_image_url"].text)
        pic_id = pic.id
        update_attributes(:local_id => e.elements['id'].text, :name => e.elements['name'].text, :picture_id => pic_id)
      end
    end
    
    # retrive messages:
    msgs = []
    if messages_updated.nil? or Time.now - messages_updated  > 60.minutes
      # retrive from twitter
      logger.debug "retrieving messages from twitter."
      url = "http://twitter.com/statuses/user_timeline/#{username}.rss"
      logger.debug(url)
      
      begin
        doc = REXML::Document.new(open(url)) # URI.encode( )
      rescue
        # unable to load from twitter, retrieve from local database
        logger.debug "FAILED to retrieve from twitter"
        return (msgs = Message.find_all_by_twitter_user_id(self.id)).nil? ? [] : msgs
      end
      doc.elements.each('rss/channel/item') do |s|
        local_id = s.elements["link"].text.split('/')[-1].to_i
        text = s.elements["description"].text[username.length+2..-1]
        created = Time.parse(s.elements["pubDate"].text)
        msgs << Message.find_or_create_by_local_id( :local_id => local_id,
                    :text => text, :twitter_user_id => self.id, :created_at => created)
      end
      update_attribute(:messages_updated, Time.now)
      #msgs = "hakee"
    else
      logger.debug "retrieving messages from local database"
      msgs = Message.find_all_by_twitter_user_id(self.id)
    end
    msgs.nil? ? [] : msgs
  end
  
end
