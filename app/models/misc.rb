class Misc < ActiveRecord::Base
  
  
  def self.age_bonus(created_at)
    # AGE BONUS:
    age_in_hours = (Time.now - created_at) / 60.0 / 60.0
    #old: age_multip = 1 + 7 / (age_in_hours + 1) # 0:100% 1:50% 2:25% ...
    almost_max_bonus = 6.0 # max_bonus = this + 1
    slope = 10.0 # the bigger, the more gentle and longer lasting the effect 
    1 + (almost_max_bonus*slope) / (age_in_hours + slope)
  end
  
  def self.mean_or_one(arr)
    sum = 0.0
    arr.each { |n| sum += n }
    arr.size > 0 ? sum / arr.size : 1 
  end
  
  def self.pos_neg_read_percentage(pos,neg,read)
    neg += read*1.0 / 10  # 10 read equals one neg
    per = pos == 0 ? 50 : pos*100.0 / (pos + neg)
    per = ( per * (pos+neg) + 50 * (10-pos-neg) ) / 10 if pos+neg < 10
    per
  end
  
  def self.pos_neg_read_multip(pos,neg,read)
    per = pos_neg_read_percentage(pos,neg,read)
    per < 50 ?  per/50  :  1 + (per-50) / 5
  end
  
  def self.salience_zero_to_ten(pos, neg)
    pos = pos*1.0
    neg = neg*1.0
    total = pos+neg
    if pos > neg
      1 + 9 * (pos-neg)/total - 9 * Math.sqrt(1/(total+1))
    elsif neg > pos
      1 - (neg-pos)/total + Math.sqrt(2/(total+2))
    else
      1
    end
  end
  
  def self.str_to_int_arr(str)
    str.delete! '[]'
    arr = str.split ','
    arr.collect { |e| e.to_i }
  end
  
end
