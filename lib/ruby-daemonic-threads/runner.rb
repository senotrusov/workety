
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


class DaemonicThreads::Runner
  RESTART_DELAY = 15
  
  def initialize(name, config, process)
    @name = name
    @config = config
    @process = process
    @logger = Rails.logger
    
    @mutex = Mutex.new
    @delay = ConditionVariable.new
    @must_terminate = false
    @restarting = false
  end
  
  attr_reader :name, :config, :process
  
  def start
    @watchdog_thread = Thread.new_with_exception_handling(lambda { @process.controller.stop }, @logger, :fatal, "#{self.class}#watchdog @name:`#{@name}'") { watchdog }
  end
  
  def join
    @watchdog_thread.join if @watchdog_thread
  end

  def stop
    restart_process_on_exception do
      @mutex.synchronize do
        @must_terminate = true
        @delay.signal

        return if @restarting
        
        @daemon.stop if @daemon
      end
    end
  end
  
  #
  # Нельзя вызывать restart_daemon(), из initialize(), потому что перестартовывать ещё нечего.
  # Такой вызов может произойти, если в initialize() запускаются треды, которые при ошибке вызывают restart_daemon.
  # Запускайте новые треды в методе initialize_daemon(). Он выполняется после завершения initialize()
  #
  # Нельзя вызывать restart_daemon() после того, как отработал join().
  # Таким действием можно непреднамеренно перезапустить новое, только что созданное приложение.
  # Пауза между завершением старого и запуском нового приложения (RESTART_DELAY), несколько снижает вероятность такой ошибки.
  # Польностью ошибку исключить можно, только если в join() делать join для всех запущенных тредов.
  # Это делается автоматически, если использовать методы spawn_daemon и spawn_thread.
  # 
  def restart_daemon
    restart_process_on_exception do
      @mutex.synchronize do
        return if @must_terminate || @restarting

        @restarting = true
        
        unless @daemon
          raise "#{self.class}#restart_daemon @name:`#{@name} -- Called restart_daemon(), but @daemon does not exists! This may occur when you somehow call restart_daemon() from initialize() and then raises then exception from initialize(). Or you spawn threads in initialize() instead of in spawn_threads() and one thread ends with exception before initialize() fully completes. Or it may be both cases." 
        end
        
        @daemon.stop
      end
    end
  end
  
  private

  def watchdog
    loop do
      @mutex.synchronize do
        return if @must_terminate
        @restarting = false
        
        @logger.info "#{self.class}#watchdog @name:`#{@name}' -- Starting..."
        @daemon = @config["class-constantized"].new(@name, self)
      end
      
      begin
        @daemon.perform_initialize_daemon
      rescue *(@config["class-constantized"]::RESTART_ON) => exception
        exception.log! @logger, :warn, "#{self.class}#watchdog @name:`#{@name}' -- Restarting daemon because of exception", (@process.controller.env == "production" ? :inspect : :inspect_with_backtrace)
        restart_daemon
      end
      
      @daemon.join
      
      delay
    end
  end
  
  def delay
    @mutex.synchronize do
      unless @must_terminate
        @logger.info "#{self.class}#delay @name:`#{@name}' -- Catch termination, restarting in #{RESTART_DELAY} seconds..."
        
        Thread.new_with_exception_handling(lambda { @process.controller.stop }, @logger, :fatal, "#{self.class}#delay @name:`#{@name}'") do
          # Если кто-то пошлёт сигнал во время сна, ожидающий получит два сигнала по пробуждении. В этом конкретном случае это не ппроблема, потому как этот кто-то - это стоп, и после него получать сигнал будет некому
          sleep RESTART_DELAY
          @delay.signal
        end
        
        @delay.wait(@mutex)
      end
    end    
  end
  
  def restart_process_on_exception
    yield
  rescue Exception => exception
    begin
      exception.log!(@logger, :fatal, "#{self.class}##{caller.first.match(/`(.*)'/)[1]} @name:`#{@name}' -- Stopping process because of exception") 
    ensure
      @process.controller.stop
    end
  end
  
end

