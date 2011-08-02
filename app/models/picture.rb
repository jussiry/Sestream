=begin
# Pictures not used

require 'mini_magick' # for picture_modification

class Picture < ActiveRecord::Base
  
  validates_format_of :picture_type, :with => /^image/, :allow_blank => true
  
  def self.from_url(url)
    #image = MiniMagick::Image.from_file(open(url).read("testi"))
    image = MiniMagick::Image.from_blob(open(url).read)
    #stringIO = open(url)
    data_type =  url.split('.')[-1].downcase
    data_type = "image/" + (data_type == "jpg" ? "jpeg" : data_type)
    image.thumbnail "35x35"
    Picture.create(:picture_data => image.to_blob, :picture_type => data_type) # data_type
    #image = MiniMagick::Image.from_file(open(url))
    #Picture.create(:picture_data => image.to_blob, :picture_type => "image/jpeg")
  end
 
  def self.uploaded_twitter_user_picture(twt_user, pic_url) # picture_field
    
    twt_user.user_pic.destroy if twt_user.user_pic
    
    #file = 
    image = MiniMagick::Image.from_blob(picture_field.read) #, picture_field.content_type.chomp
    data_type = picture_field.content_type.chomp
    
    twt_user.picture = Picture.create(:picture_data => image.to_blob, :picture_type => data_type)
    twt_user.save
    
    #resize_by_width(image, 500) # full size (when you click user image on user page)
  end
  
  private
  
  def self.resize_by_width(image, max_width)
    w = image['%w'].to_f
    h = image['%h'].to_f
    if w > max_width
      h = (h*(max_width/w)).to_i
      w = max_width
    end
    image.thumbnail "#{w}x#{h}"
  end
  
  def self.crop_height(image, opt_height)
    cur_height = image['%h'].to_f
    if cur_height > opt_height
      remove = ((cur_height - opt_height)/2).round
      image.shave("0x#{remove}")
    end
  end
  
end 
 
=end
