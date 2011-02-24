
#  Copyright 2006-2009 Stanislav Senotrusov <senotrusov@gmail.com>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.



  # CALL SEQUENCE AND CONCURRENCY
  # -----------------------------
  #  
  # initialize
  # start
  # join
  # stop
  # before_exit
  # 
  # initialize выполняется в main без каких-либо тредов
  # start, stop, before_exit выполняются строго по порядку, неконкурентно
  # join вызывается после start, при этом stop может быть как позже, так и раньше join
  
  # EXCEPTION HANDLING
  # ------------------
  #
  # on exception from initialize - пишется в лог и на экран, процесс завершится
  # on exception from start - стартуется termination watchdog (15 секунд по умолчанию), вызывается join и stop в непредсказуемом порядке, после join - before_exit
  # on exception from stop - процесс аварийно останавливается, before_exit не выполняется
  # on exception from join - пишется в лог, переходит к before_exit
  # on exception from before_exit - пишется в лог, процесс завершается
  
  # SIGNAL HANDLING AND BEHAVIOR WITH UNIMPLEMENTED METHODS
  # -------------------------------------------------------
  #
  # join, stop and before exit MAY BE implemented or not. 
  #
  # В момент выполнения initialize, сигналы ещё не перехватываются и ruby вызывает SignalException в произвольном месте initialize.
  # Если сигнал на остановку приходит после initialize, но до start, то start-join-stop-before_exit не выполняются вовсе.
  #
  # If join() and stop() IS implemented, join() will be after start() and stop() will be called in a separate thread ONLY ONCE AFTER FIRST SIGNAL
  #
  # If stop() is not implemented, SignalException raised (by ruby) for main thread running start() ON EACH received INT, TERM, ABRT or HUP 
  #
  # If join() is not implemented, stop will be called in main thread, как бы его приостанавливая ON EACH received INT, TERM, ABRT or HUP
  #   Note, in that case, when stop() call is still working and the next signal is arrived, first stop() processing stops and seconds starts.
  #
  # Если определён только join, но не stop, то join вызывается после завершения start.


require 'etc'

class ProcessController
  COMMANDS = %w(start stop run)
  
  FAILURE_EXIT_CODES = {
    :process_controller_init => 1,
    :termination_watchdog => 2,
    :stop_thread => 3,
    :dispatch_termination_signal => 4,
    :stop_has_no_effect => 5,
    :threads_display => 6
  }
  
  DEFAULT_NAME = "daemon"
  LOGGER_CLASS = defined?(ActiveSupport::BufferedLogger) && ActiveSupport::BufferedLogger || 
                 defined?(Merb::Logger) && Merb::Logger || 
                 defined?(Logger) && Logger
                 
  LOG_LEVELS = LOGGER_CLASS::Severity.constants.map{|level| [LOGGER_CLASS::Severity.const_get(level), level]}.sort_by{|level|level.first}.map{|level|level.last}
                 
  DEFAULT_PID_DIR = "tmp/pids"
  DEFAULT_LOG_DIR = "log"
  
  DEFAULT_TERM_TIMEOUT = 42
  MINIMUM_TERM_TIMEOUT = 1
  THREADS_DISPLAY = DEFAULT_TERM_TIMEOUT / 10

  attr_reader :logger, :env, :name, :argv
  
  
  # ARGV OPTIONS
  # TODO: extract class
  
  def initialize_argv_options(argv)
    @argv ||= ArgvParser.new(ARGV)
    define_argv_options
    @argv.parse!
    apply_argv_options
  end
    
  def define_argv_options
    @argv.heading_option "[COMMAND]", "ProcessController command (#{COMMANDS * "/"})"

    @argv.option "-e, --environment NAME", "Run in environment (development/production/testing)"
    @argv.option "-n, --name NAME", "Daemon's name"

    @argv.option "--user USER", "Run as user"
    @argv.option "--group GROUP", "Run as group"
    @argv.option "--working-dir DIRECTORY", "Working directory, defaults to ."

    @argv.option "--pid-dir DIRECTORY", "PID directory, relative to working-dir, defaults to '#{DEFAULT_PID_DIR}', fallbacks to '.', may be absolute path"
    @argv.option "--pid-file FILE", "PID file, defaults to [name].pid, may be absolute path"

    @argv.option "--log-level LEVEL", "Log level (#{LOG_LEVELS * " "})"
    @argv.option "--log-dir DIRECTORY", "Log directory, relative to working-dir, default to '#{DEFAULT_LOG_DIR}', fallbacks to '.', may be absolute path"
    @argv.option "--log-file FILE", "Logfile, default to [name].log, may be absolute path"

    @argv.option "--term-timeout SECONDS", "Termination timeout, default to 30 seconds"
    @argv.option "-h, --help", "Show this help message"
  end
  
  def apply_argv_options
    @user = @argv["user"]
    @group = @argv["group"]
    
    @working_dir = @argv["working-dir"]
    
    @command = @argv["COMMAND"] || "run"
    
    @env = @argv["environment"] || (@command == "start" ? "production" : "development")
    
    @name = @argv["name"] || DEFAULT_NAME

    @pid_dir = @argv['pid-dir'] || DEFAULT_PID_DIR
    @pid_dir = '.' unless File.directory? @pid_dir

    @pid_file = if @argv['pid-file']
        (@argv['pid-file'] =~ /^\//) ? @argv['pid-file'] : "#{@pid_dir}/#{@argv['pid-file']}"
      else
         "#{@pid_dir}/#{@name}.pid"
      end

    @log_level = LOGGER_CLASS::Severity.const_get((@argv["log-level"] || (@env == "production" ? "warn" : "debug")).upcase.to_sym)
    
    @log_dir = @argv["log-dir"] || DEFAULT_LOG_DIR
    @log_dir = '.' unless File.directory?(@log_dir)
    
    @log_file = if (@command == "run" || @command == "stop")
        STDOUT
      elsif @argv["log-file"]
        (@argv["log-file"] =~ /^\//) ? @argv["log-file"] : "#{@log_dir}/#{@argv["log-file"]}"
      else
        "#{@log_dir}/#{@name}.log"
      end

    @term_timeout = (@argv['term-timeout'] || DEFAULT_TERM_TIMEOUT).to_i
    @term_timeout = MINIMUM_TERM_TIMEOUT if @term_timeout < MINIMUM_TERM_TIMEOUT
  end

  
  # INITIALIZE

  def initialize(argv = nil)
    initialize_argv_options(argv)
    
    change_process_privileges

    Dir.chdir(@working_dir) if @working_dir
    
    if @command != "stop"
      @logger = LOGGER_CLASS.new(@log_file, @log_level)
      @logger.auto_flushing = true
      
      @stop_mutex = Mutex.new
      @stop_was_called = false
      
      @stop_thread_mutex = Mutex.new
      @stop_thread_was_runned = false
      
      @daemon_mutex = Mutex.new
      @must_terminate = false
      @daemon_started_to_some_extent = false
      @detached = false
      
      if (running_pid = getpid)
        if is_running? running_pid
          raise "#{@name}: already running with pid #{running_pid}"
        else
          log(:warn){"#{self.class}#initialize @name:`#{@name}' -- Found pidfile:`#{@pid_file}' with pid:`#{running_pid}' and is not running, it may be result of an unclean shutdown."}
        end
      end

      @logger.info {"#{self.class}#initialize @name:`#{@name}' -- Creating process..."}
      
      @daemon = yield(self)
      
      @logger.info {"#{self.class}#initialize @name:`#{@name}' -- Process initialized."}
    end
    
    if @argv["help"]
      @argv.show_options
      
    elsif @argv.complete?
      __send__("execute_#{@command}")
      
    else
      @argv.show_errors(@logger) if @logger
      @argv.show_options_and_errors
    end
    
    @logger.flush if @logger && @logger.respond_to?(:flush)
    
  rescue Exception => exception
    begin
      log(:fatal){"#{self.class}#initialize @name:`#{@name}' -- #{exception.inspect_with_backtrace}"} if @log_file != STDOUT
      
      unless @detached
        @argv.errors << exception.inspect_with_backtrace
        @argv.show_errors
      end
    rescue Exception => another_exception
      STDERR.puts "\n#{exception.inspect_with_backtrace}"
      STDERR.puts "\nWhile handling previous exception another error was occured:\n#{another_exception.inspect_with_backtrace}"
    ensure
      Process.exit!(FAILURE_EXIT_CODES[:process_controller_init])
    end
  end
  
  def stop
    @stop_mutex.synchronize do
      unless @stop_was_called
        @stop_was_called = true
        dispatch_termination_signal
      end
    end
  end

  private
  

  # START/RUN/STOP COMMANDS
  
  def execute_start
    detach
    execute_run
  end
  
  def execute_run
    @logger.info {"#{self.class}#execute_run @name:`#{@name}' -- Starting..."}
    
    create_pid  
    
    Thread.current[:title] = "Main thread"

    @termination_watchdog = termination_watchdog
    @threads_display = threads_display
    @stop_thread = stop_thread if @daemon.respond_to?(:stop) && @daemon.respond_to?(:join)

    trap_signals if @daemon.respond_to?(:stop)
    
    daemon_start_sequence

  ensure
    untrap_signals
    delete_pid
    @logger.info {"#{self.class}#execute_run @name:`#{@name}' -- Stopped"}
  end
  
  def daemon_start_sequence
    start_daemon    
    join_daemon

  ensure
    before_exit_daemon_handler
  end
  
  
  def start_daemon
    @daemon_mutex.synchronize do
      return if @must_terminate

      @daemon_started_to_some_extent = true

      @daemon.start
    end
  rescue Exception => exception
    log(:fatal){"#{self.class}#start_daemon @name:`#{@name}' -- #{exception.inspect_with_backtrace}"}
    stop_daemon
  end
  
  
  def join_daemon
    @daemon.join if @daemon.respond_to?(:join) && @daemon_started_to_some_extent
  rescue Exception => exception
    log(:fatal){"#{self.class}#join_daemon @name:`#{@name}' -- #{exception.inspect_with_backtrace}"}
  end
  
  
  def before_exit_daemon_handler
    @daemon_mutex.synchronize do
      @daemon.before_exit if @daemon.respond_to?(:before_exit) && @daemon_started_to_some_extent
    end
  rescue Exception => exception
    log(:fatal){"#{self.class}#before_exit_daemon_handler @name:`#{@name}' -- #{exception.inspect_with_backtrace}"}
  end
  
  
  def execute_stop
    if (running_pid = getpid)
      if is_running? running_pid
        Process.kill("TERM", running_pid)
        
        start_waiting = Time.now
        user_is_given_to_know_whats_happening = false
        
        while is_running? running_pid 
          sleep 0.1
          now = Time.now
          
          if !user_is_given_to_know_whats_happening && (now - start_waiting > @term_timeout * 0.2)
            STDOUT.puts "#{self.class}#execute_stop @name:`#{@name}' -- Waiting for @term_timeout:`#{@term_timeout}' seconds..."
            user_is_given_to_know_whats_happening = true
            start_waiting = Time.now
            
          elsif now - start_waiting > @term_timeout
            STDOUT.puts "#{self.class}#execute_stop @name:`#{@name}' -- ERROR. Process DOES NOT stopped in @term_timeout:`#{@term_timeout}' seconds"
            Process.exit!(FAILURE_EXIT_CODES[:stop_has_no_effect])
            
          end
        end          
        STDOUT.puts "#{self.class}#execute_stop @name:`#{@name}' -- Stopped"
      else
        raise "@name:`#{@name}' -- Process with pid:`#{running_pid}' is not running."
      end
    else
      raise "@name:`#{@name}' -- Pidfile:`#{@pid_file}' not found"
    end
  end
  

  # PROCESS PRIVILEGES AND TERMINAL DETACH
  
  # TODO: REVIEW THIS
  
  def change_process_privileges
    uid = @user && Etc.getpwnam(@user).uid || Process.euid
    gid = @group && Etc.getgrnam(@group).gid || Process.egid
    
    # http://www.ruby-forum.com/topic/110492
    Process.initgroups(@user, gid) if @user
    
    Process::GID.change_privilege(uid)
    Process::UID.change_privilege(gid)
  end

  # based on Reimer Behrends notes http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/87467
  def detach
    Process.exit!(0) if fork        # Parent exits, child continues.
    Process.setsid                  # Become session leader.
    Process.exit!(0) if fork        # Zap session leader. See http://www.erlenstar.demon.co.uk/unix/faq_2.html#SEC16
    
    File.umask 022                  # Ensure sensible umask. Adjust as needed.
    
    STDIN.reopen "/dev/null" # Free file descriptors and


#    STDOUT.reopen(@log_file.gsub(/\.(log)$/, '.output'), "a") # point them somewhere sensible.
#    STDERR.reopen STDOUT                                      # STDOUT/ERR should better go to a logfile.

    STDOUT.reopen(@logger.instance_variable_get("@log")) # point them somewhere sensible.
    STDERR.reopen STDOUT                                      # STDOUT/ERR should better go to a logfile.
    
    @detached = true
  end
  
  
  # SIGNAL HANDLING
  
  
  # This "Thread.stop" complexity is needed, кажется, for some cases, where ruby can not spawn new threads.
  # И я совершенно забыл, при каких обстоятельствах я наблюдал такую картину.
  # Кажется это какие-то случаи c IO для сокетов. Надо поглядеть в коде rubymq
  # Ещё иногда удобно нажимать ctrl+c два раза и не ждать нормального завершения
  
  def termination_watchdog
    Thread.new_with_exception_handling(Proc.new { |exception| Process.exit!(FAILURE_EXIT_CODES[:termination_watchdog]) unless exception.kind_of?(ThreadTerminatedError) }, @logger, :fatal, "#{self.class}#termination_watchdog") do
      Thread.stop
      log(:info) {"#{self.class}#termination_watchdog @name:`#{@name}' -- Running termination_watchdog..."} 
      Thread.main.join_and_terminate(@term_timeout)
    end
  end
  
  def threads_display
    Thread.new_with_exception_handling(Proc.new { Process.exit!(FAILURE_EXIT_CODES[:threads_display]) }, @logger, :fatal, "#{self.class}#threads_display") do
      Thread.stop
      loop do
        sleep THREADS_DISPLAY
        @logger.warn {"\n#{self.class}#threads_display @name:`#{@name}' -- Threads are still active:"}
        Thread.list.each do |thread|
          @logger.warn {"  #{thread.inspect_with_values}"}
        end
      end
    end
  end

  def stop_thread
    Thread.new_with_exception_handling(Proc.new { Process.exit!(FAILURE_EXIT_CODES[:stop_thread]) }, @logger, :fatal, "#{self.class}#stop_thread") do
      Thread.stop
      @logger.debug {"#{self.class}#stop_thread @name:`#{@name}' -- Stopping..."}
      @daemon_mutex.synchronize do
        @must_terminate = true
        @daemon.stop if @daemon_started_to_some_extent
      end
    end
  end

  def dispatch_termination_signal
    stop_daemon
  rescue Exception => exception
    begin
      log(:fatal){"#{self.class}#dispatch_termination_signal @name:`#{@name}' -- Error while stopping: #{exception.inspect_with_backtrace}"}
    ensure
      Process.exit!(FAILURE_EXIT_CODES[:dispatch_termination_signal])
    end
  end
  
  def stop_daemon

    if @termination_watchdog
      begin
        @termination_watchdog.run
      rescue ThreadError
      end
    end
    
    if @threads_display
      begin
        @threads_display.run
      rescue ThreadError
      end
    end

    if @stop_thread
      begin
        @stop_thread_mutex.synchronize do
          unless @stop_thread_was_runned
            @stop_thread_was_runned = true
            @stop_thread.run
          end
        end
      rescue ThreadError
      end
    else
      log(:info) {"#{self.class}#stop_daemon @name:`#{@name}' -- @daemon.stop..."} 
      @daemon.stop
    end
  end
  
  
  # SIGNAL TRAPPING
  
  def trap_signals
    Signal.trap('INT')  {dispatch_termination_signal} # Ctrl+C
    Signal.trap('TERM') {dispatch_termination_signal} # kill
    Signal.trap('ABRT') {dispatch_termination_signal} # Ctrl-\
    Signal.trap('HUP')  {dispatch_termination_signal} # terminal line hand-up
  end
  
  def untrap_signals
    Signal.trap 'INT',  'DEFAULT'
    Signal.trap 'TERM', 'DEFAULT'
    Signal.trap 'ABRT', 'DEFAULT'
    Signal.trap 'HUP',  'DEFAULT'
  end


  # PID FILE

  def create_pid
    File.write @pid_file, Process.pid
  end

  def delete_pid
    File.delete @pid_file
  end
  
  def getpid
    if File.exists?(@pid_file)
      File.read(@pid_file).to_i
    else
      false
    end
  end
  

  # DETECTION OF ALREADY RUNNING DAEMON

  def is_running? pid
    begin        
      Process.getpgid(pid) && true
    rescue Errno::ESRCH
      false
    end
  end
  

  # LOGGING

  def log severity, &block
    if defined?(@logger)
      @logger.__send__(severity, &block)
      @logger.flush if @logger.respond_to?(:flush)
    end
  end
end

