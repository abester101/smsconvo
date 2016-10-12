module JobHooks
  def before_enqueue(*args)
    DataCache.set(args[0],"queued")
  end

  def after_perform(*args)
    ActiveRecord::Base.connection.disconnect!
    DataCache.set(args[0],"done")
  end
end