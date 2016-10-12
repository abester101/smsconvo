module RetriedJob
  def on_failure(e, *args)
    message = "Performing #{self} caused an exception (#{e}). args: #{args}"
    SlackSMSNotify.send_error(message)
    puts message
    DataCache.set(args[0],"failed")
  end
end
