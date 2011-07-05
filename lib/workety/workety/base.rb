
#  Copyright 2009 Stanislav Senotrusov <senotrusov@gmail.com>
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


# Atomic opperation
# http://stackoverflow.com/questions/737110/is-double-checked-locking-safe-in-ruby
# I don't think he is right

class DaemonicThreads::Base
  class_inheritable_array :restart_on_exceptions
  self.restart_on_exceptions = IPSocket::SOCKET_EXEPTIONS + [DaemonicThreads::MustTerminatedState]
  
  def initialize(name, runner, parent = nil)
    @name = name
    @runner = runner
    @config = runner.config
    @process = runner.process
    @logger = Rails.logger
    @parent = parent
    
    @queues = {}
    
    @config["queues"].each do |queue_handler, queue_name|
      @queues[queue_handler.to_sym] = @process.queues[queue_name.to_sym]
    end if @config["queues"]
      
    @queues.each do |queue_handler, queue|
      instance_variable_set("@#{queue_handler}", queue)
    end
    
    @threads = {}
    @thread_group = ThreadGroup.new
    @daemons = []
    @creatures_mutex = Mutex.new
    @stop_condition = ConditionVariable.new
    @must_terminate = false

    @periodics_mutex = Mutex.new
    @periodics = []
  end
  
  attr_reader :logger
  
  def join
    @creatures_mutex.synchronize do
      @stop_condition.wait(@creatures_mutex) unless @must_terminate
    end
    
    deinitialize_http if respond_to?(:deinitialize_http)
    
    @daemons.each {|daemon| daemon.join }
    
    @thread_group.list.each {|thread| thread.join }

    begin    
      after_join if respond_to?(:after_join)
    rescue *(restart_on_exceptions) => exception
      exception.log!(@logger, :warn, "#{self.class}#after_join @name:`#{@name}'", (@process.controller.env == "production" ? :inspect : :inspect_with_backtrace))
    end

  end
  
  
  def stop
    @creatures_mutex.synchronize do
      @must_terminate = true
      @stop_condition.signal
    end
    
    stop_periodics

    @daemons.each {|daemon| daemon.stop }
    
    @thread_group.list.each do |thread|
      @queues.each do |queue_handler, queue|
        queue.release_blocked(thread) if queue.respond_to?(:release_blocked) 
      end
    end unless @queues.empty?
    
    begin    
      stop_daemon if respond_to?(:stop_daemon)
    rescue *(restart_on_exceptions) => exception
      exception.log!(@logger, :warn, "#{self.class}#stop_daemon @name:`#{@name}'", (@process.controller.env == "production" ? :inspect : :inspect_with_backtrace))
    end
    
  end
  
  def restart_daemon
    @runner.restart_daemon
  end
  
  
  def perform_initialize_daemon(*args)
    initialize_daemon(*args) if respond_to? :initialize_daemon
    initialize_http if respond_to?(:initialize_http) # Must be at last line, so no HTTP requests to uninitialized daemon 
  end
  

  # Можно запускать из initialize_daemon или из любого треда
  def spawn_daemon name, klass, *args
    @creatures_mutex.synchronize do
      raise(DaemonicThreads::MustTerminatedState, "Unable to spawn new daemons after stop() is called") if @must_terminate
      
      # Мы не ловим никаких exceptions, потому что они поймаются или panic_on_exception (тред или http-запрос) или runner-ом (initialize, initialize_daemon).
      # Полагаться на себя тот должен, кто spawn_daemon вызвал из треда, запущенного без помощи spawn_thread, а значит без должной обработки ошибок.
       
      @daemons.push(daemon = klass.new(name, @runner, self))
      daemon.perform_initialize_daemon(*args)
      return daemon
    end
  end
  
  
  # Можно запускать из initialize_daemon или из любого треда
  # TODO: cleanup on thread exit
  def spawn_thread(thread_name, *args)
    @creatures_mutex.synchronize do
      raise(DaemonicThreads::MustTerminatedState, "Unable to spawn new threads after stop() is called") if @must_terminate
      
      thread = spawn_untracked_thread(thread_name) do
        begin
          if block_given?
            yield(*args)
          elsif respond_to?(thread_name)
            __send__(thread_name, *args)
          else
            raise("Thread block was not given or method `#{thread_name}' not found. Don't know what to do.")
          end
        ensure
          panic_on_exception("#{self.class}#thread:`#{thread_name}' @name:`#{@name}' -- Release ActiveRecord connection to pool") { ActiveRecord::Base.clear_active_connections! }
        end
      end
      
      @threads[thread_name] = thread if @threads_by_name_needed
      @thread_group.add thread
      
      return thread
    end
  end
  
  def spawn_untracked_thread thread_name
    thread_title = "#{self.class}#thread:`#{thread_name}' @name:`#{@name}'" # TODO copypasta from above
    Thread.new do
      panic_on_exception(thread_title) do
        Thread.current[:title] = thread_title
        Thread.current[:started_at] = Time.now
        yield
      end
    end
  end
  
  def panic_on_exception(title = nil, handler = nil)
    yield
  rescue *(restart_on_exceptions) => exception
    begin
      exception.log!(@logger, :warn, title, (@process.controller.env == "production" ? :inspect : :inspect_with_backtrace))
      handler.call(exception) if handler
      restart_daemon
    rescue Exception => handler_exception
      begin
        handler_exception.log!(@logger, :fatal, title)
      ensure
        @process.controller.stop
      end
    end
  rescue Exception => exception
    begin
      exception.log!(@logger, :fatal, title)
      handler.call(exception) if handler
    rescue Exception => handler_exception
      handler_exception.log!(@logger, :fatal, title)
    ensure
      @process.controller.stop
    end
  end
  
  def thread name
    @creatures_mutex.synchronize {@thread[name]}
  end
  
  def need_threads_by_name
    @threads_by_name_needed = true
  end
  
  def must_terminate?
    @creatures_mutex.synchronize { @must_terminate }
  end
  
  
  def log severity, message = nil
    @logger.__send__(severity) {"#{self.class}##{caller.first.match(/`(.*)'/)[1]} -- #{block_given? ? yield : message}"}
  end
end

