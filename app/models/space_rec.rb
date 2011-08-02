

class SpaceRec
  
  AXIS_LENGTH = 10000 # vector range: 0..AXIS_LENGTH-1 
  DIMENSIONS = 5 # vector size
  
  MOVE_MP = 0.1  # MP = multiplyer
  RESIST_MP = 1 - MOVE_MP # resistance
  
  attr_accessor :v
  
  def initialize
    self.reset_values
  end
  
  def reset_values
    @v = Array.new(DIMENSIONS)  # @v = vector / values / position of the object in recommendation space
    DIMENSIONS.times do |i|
      @v[i] = rand(AXIS_LENGTH) # 0..9999
    end
  end
  
  def dist(another_obj)
    SpaceRec.obj_dist(self, another_obj)
  end
  
  
  def closer_to(another_obj)
    SpaceRec.closer(self, another_obj)
  end
  
  def further_from(another_obj)
    SpaceRec.further_away(self, another_obj)
  end
  
  ##
  # Distance between two values:
  #
  def self.value_dist(v1, v2)
    if (diff = (v1-v2).abs) > AXIS_LENGTH / 2
      AXIS_LENGTH - diff
    else
      diff
    end
  end
  
  ##
  #  Makes two recommendable objects closer to each other.
  #
  def self.closer(a,b)
    puts "closer"
    DIMENSIONS.times do |i|
      s = {}
      
      # objects:
      s[:min] = (as = a.v[i] < b.v[i]) ? a : b   # as = "a is smaller"
      s[:max] = as ? b : a
      # values to use for cleaner code:
      min = s[:min].v[i]
      max = s[:max].v[i]
      diff = max - min
      
      if diff < AXIS_LENGTH / 2
        # normal average; make min bigger and max smaller:
        avg = (a.v[i] + b.v[i]) / 2
        s[:min].v[i] = (min + (avg-min) * MOVE_MP).to_i
        s[:max].v[i] = (max - (max-avg) * MOVE_MP).to_i 
      else
        # average is "outside"; make min smaller and max bigger (and go round if necessary):
        # min:
        min_target = min - diff/2
        s[:min].v[i] = (RESIST_MP * min + MOVE_MP * min_target).to_i
        s[:min].v[i] =  min + AXIS_LENGTH if min < 0
        # max:
        max_target = max + diff/2
        s[:max].v[i] = (RESIST_MP * max + MOVE_MP * max_target).to_i
        s[:max].v[i] = max - AXIS_LENGTH if max >= AXIS_LENGTH
      end
    end
  end
  
  
  ##
  #  Makes two recommendable objects further away from each other.
  #
  #  DISTANCING two objects shuold be stronger when the objects are close to each other,
  #  where as .closer function is stronger when objects are far away from each other.
  #
  def self.further_away(a,b)
    puts "further away"
    DIMENSIONS.times do |i|
      s = {}
      
      # objects:
      s[:min] = (as = a.v[i] < b.v[i]) ? a : b   # as = "a is smaller"
      s[:max] = as ? b : a
      # values to use for cleaner code:
      min = s[:min].v[i]
      max = s[:max].v[i]
      diff = max - min
      
      if diff < AXIS_LENGTH/2
        # average in between; make them further and go round if necessary:
        # min:
        min_target = min - diff/2
        s[:min].v[i] = (RESIST_MP * min + MOVE_MP * min_target).to_i
        s[:min].v[i] =  min + AXIS_LENGTH if min < 0
        # max:
        max_target = max + diff/2
        s[:max].v[i] = (RESIST_MP * max + MOVE_MP * max_target).to_i
        s[:max].v[i] = max - AXIS_LENGTH if max >= AXIS_LENGTH 
      else
        # average is "outside"; make them go closer:
        avg = (a.v[i] + b.v[i]) / 2
        s[:min].v[i] = (min + (avg-min) * MOVE_MP).to_i
        s[:max].v[i] = (max - (max-avg) * MOVE_MP).to_i 
      end
    end
  end
  
  def self.obj_dist(a,b)
    dist = 0
    DIMENSIONS.times do |i|
      axis_dist = (a.v[i] - b.v[i]).abs
      axis_dist = AXIS_LENGTH - axis_dist if axis_dist > AXIS_LENGTH/2
      dist += axis_dist
    end
    dist
  end
  
  def self.test_further
    a = SpaceRec.new
    puts "---------------------------------"
    puts "-------- New test ---------------"
    puts "---------------------------------"
    #aa = Marshal.load(Marshal.dump(a))
    puts "#{a.inspect}"
    b = SpaceRec.new
    #bb = Marshal.load(Marshal.dump(b))
    puts "#{b.inspect}"
    DIMENSIONS.times do |i|
      print " #{self.value_dist(a.v[i],b.v[i])}"
    end
    puts "\ndistance: #{a.dist b}"
    
    a.further_from b
    puts "after:"
    puts "#{a.inspect}"
    puts "#{b.inspect}"
    DIMENSIONS.times do |i|
      print " #{self.value_dist(a.v[i],b.v[i])}"
    end
    puts "\ndistance: #{a.dist b}"

    a.further_from b
    puts "after:"
    puts "#{a.inspect}"
    puts "#{b.inspect}"
    DIMENSIONS.times do |i|
      print " #{self.value_dist(a.v[i],b.v[i])}"
    end
    puts "\ndistance: #{a.dist b}"

    a.further_from b
    puts "after:"
    puts "#{a.inspect}"
    puts "#{b.inspect}"
    DIMENSIONS.times do |i|
      print " #{self.value_dist(a.v[i],b.v[i])}"
    end
    puts "\ndistance: #{a.dist b}"

    a.further_from b
    puts "after:"
    puts "#{a.inspect}"
    puts "#{b.inspect}"
    DIMENSIONS.times do |i|
      print " #{self.value_dist(a.v[i],b.v[i])}"
    end
    puts "\ndistance: #{a.dist b}"

=begin    
    a.closer_to b
    puts "after:"
    puts "#{a.inspect}"
    puts "#{b.inspect}"
    puts "distance: #{a.dist b}"
    

    puts "reult with old method:"
    SpaceRec.closer_old(aa, bb)
    puts "#{aa.inspect}"
    puts "#{bb.inspect}"
    
    puts "reult with new method:"
    a.closer_to b
    puts "#{a.inspect}"
    puts "#{b.inspect}"
    
    puts "Dist: #{a.dist b}"
    30.times do
      oldDist = a.dist b
      a.further_from b
      newDist = a.dist b
      puts "newDist: #{newDist}, diff: #{oldDist-newDist}"
    end
=end
    
    #print "After made 'closer':\n"
    #print "#{a.inspect}\n"
    #print "#{b.inspect}\n"
  end

  def self.test_closer
    a = SpaceRec.new
    puts "---------------------------------"
    puts "-------- Closer test ---------------"
    puts "---------------------------------"
    #aa = Marshal.load(Marshal.dump(a))
    puts "#{a.inspect}"
    b = SpaceRec.new
    #bb = Marshal.load(Marshal.dump(b))
    puts "#{b.inspect}"
    DIMENSIONS.times do |i|
      print " #{self.value_dist(a.v[i],b.v[i])}"
    end
    puts "\ndistance: #{prev = a.dist b}"
    
    10.times do
      a.closer_to b
      puts "after:"
      puts "#{a.inspect}"
      puts "#{b.inspect}"
      DIMENSIONS.times do |i|
        print " #{self.value_dist(a.v[i],b.v[i])}"
      end
      dist = a.dist b
      puts "\ndistance: #{dist}, change: #{dist-prev}"
      prev = dist
    end
  end
  
  
  
=begin

  ##
  #  Makes two recommendable objects closer to each other.
  #
  def self.closer_old(a,b)
    DIMENSIONS.times do |i|
      s = {}
      
      s[:min] = (as = a.v[i] < b.v[i]) ? a : b   # as = "a is smaller"
      s[:max] = as ? b : a
      
      diff = s[:max].v[i] - s[:min].v[i]
      
      if diff < AXIS_LENGTH/2
        # normal average; make min bigger and max smaller:
        avg = (a.v[i] + b.v[i]) / 2
        s[:min].v[i] = (RESIST_MP * s[:min].v[i] + MOVE_MP * avg).to_i
        s[:max].v[i] = (RESIST_MP * s[:max].v[i] + MOVE_MP * avg).to_i 
      else
        # average is "outside"; make min smaller and max bigger (and go round if necessary):
        # min:
        min_target = s[:min].v[i] - diff/2
        s[:min].v[i] = (RESIST_MP * s[:min].v[i] + MOVE_MP * min_target).to_i
        s[:min].v[i] =  s[:min].v[i] + AXIS_LENGTH if s[:min].v[i] < 0
        # max:
        max_target = s[:max].v[i] + diff/2
        s[:max].v[i] = (RESIST_MP * s[:max].v[i] + MOVE_MP * max_target).to_i
        s[:max].v[i] = s[:max].v[i] - AXIS_LENGTH if s[:max].v[i] >= AXIS_LENGTH
      end
    end
  end

=end
  
  
end