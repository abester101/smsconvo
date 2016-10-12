
if ENV["REDIS_URL"]
  $redis = Resque.redis = Redis.new(:url => ENV["REDIS_URL"])
end

class DataCache
  def self.data
    @data ||= Redis.new(url:ENV["REDIS_URL"])
  end

  def self.set(key, value)
    data.set(key, value)
  end

  def self.get(key)
    data.get(key)
  end

  def self.get_i(key)
    data.get(key).to_i
  end

  def self.hset(key, field, value)
    data.hset(key, field, value)
  end

  def self.hget(key, field)
    if data.hexists(key, field)
      data.hget(key, field)
    else 
      nil
    end
  end
end
