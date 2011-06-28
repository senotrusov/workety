if action == :console
  Rails.logger = ActiveSupport::BufferedLogger.new(STDOUT)
else
  begin
    Rails.logger = ActiveSupport::BufferedLogger.new(logfile)

  rescue StandardError => exception
    exception.display!

    Rails.logger = ActiveSupport::BufferedLogger.new(STDOUT)
    Rails.logger.warn "Continuing anyway"
  end
end

Rails.logger.level = ActiveSupport::BufferedLogger.const_get(options[:log_level].upcase) if options[:log_level]

Rails.logger.auto_flushing = true
Rails.logger.flush
at_exit { Rails.logger.flush }

ActiveSupport::BufferedLogger.class_eval do
  def chown_logfile(user_uid, group_gid)
    @log.chown(user_uid, group_gid) if @log.respond_to?(:chown)
  end
end

