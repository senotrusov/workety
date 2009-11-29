
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


#  Демон - экземпляр некоторого класса, запущенный в процессе.
#  В одном процессе параллельно могут быть запущено произвольное число демонов. 
#
#  Исключение из initialize() останавливает весь процесс, потому что непонятно - как и что там запустилось и будут ли теперь работать корректно start и join.
#
#  Как правило, initialize() не переопределяется, а для запуска тредов, поддемонов, сетевых подключение используется initialize_daemon().
#
#  initialize_daemon() более толерантен к ошибкам.
#  Исключение из группы IPSocket::SOCKET_EXEPTIONS полученное из initialize_daemon() перестартовывает демон.
#  Тем не менее, остальные исключения, полученные из initialize_daemon() останавливают весь процесс
#
#  Исключения, полученные из тредов, перестартовывает демон.
#
#  После отработки initialize в произвольной последовательности вызываются join() и stop().
#  join() и stop() вызывается только один раз. 
#  Исключение в stop() останавливает весь процесс, потому что непонятно - всему ли была доведена команда остановиться.
#  Исключение в join() останавливает весь процесс, потому что непонятно - всё ли остановилось.
#
#  Таким образом, реализуется несколько боязливая стратегия работы - если что-то идёт не так, процесс останавливается.
#  Рестарт демонов происходит только когда ошибка понятна, и она, скорее всего, не приводит к фатальным последствиям.
#  Такой ошибкой является сбой сети.
#  Если в ваших демонах есть другие понятные вам ошибки - ловити их сами или декларируйте в restart_on_exceptions.
#
#  Если тред запустит самостоятельно демона, то он может получить из этого демона exception.
#  Если этот exception не относится к категории тех, которые решаются перезапуском демона, то весь процесс останавливается.
#  На самом деле, когда вы получаете такой exception из spawn_daemon @runner.process.controller.stop уже выполнен. Вот-вот всё закроется.


#  Вывод inspect очень большой, потому что он долго ходит по перекрёсным ссылкам.
#  Сюрпризом будет то, что обычный exception no method error, message которого выполняет internaly some kind of inspect,
#  может выполнятся секунду-другую, если exception случился паралельно.  


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
  
  def every(duration)
    mutex = Mutex.new
    condition = ConditionVariable.new
    thread_title = "every #{duration.inspect} timer"
    duration = duration.value if duration.is_a?(ActiveSupport::Duration)
    
    @periodics_mutex.synchronize do
      return if must_terminate?
      @periodics.push [mutex, condition]
    end
    
    thread_args = [Proc.new { @process.controller.stop }, @logger, :fatal, "#{self.class}#every @name:`#{@name}'"]

    begin
      mutex.synchronize do
        until must_terminate?
          yield
          ActiveRecord::Base.clear_active_connections! if duration >= 60
          
          spawn_untracked_thread(thread_title) do
            sleep duration
            mutex.synchronize { condition.signal }
          end
           
          condition.wait(mutex)
        end
      end
    ensure
      @periodics_mutex.synchronize do
        @periodics.delete [mutex, condition]
      end
    end
  end
  
  def stop_periodics
    @periodics_mutex.synchronize do
      @periodics.each do |mutex, condition|
        mutex.synchronize { condition.signal }
      end
    end
  end
  
end

