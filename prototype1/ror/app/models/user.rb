class User < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :name, :password, :fullname, :email
  
  def before_create
    self.hashed_password = User.hash_password(self.password)
  end
  
  def self.hash_password(password)
    Digest::SHA1.hexdigest(password)
  end
  
  def self.login(name, password)
    hashed_password = hash_password(password || "")
    find(:first,
         :conditions => ["name = ? and hashed_password = ?",
                          name, hashed_password])
    #User.new({:name=>"matteo", :password=>"ciao"})
  end
  
  def try_to_login
    User.login(self.name, self.password)
  end
end
