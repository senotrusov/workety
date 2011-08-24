
#  Copyright 2006-2011 Stanislav Senotrusov <stan@senotrusov.com>
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


# Initialize, start, stop and join worker class
# Drop process privileges after initialize
#
# initialize() then start()
# There is no strict order for stop and join - stop may be called before join 
#
# Use Workety.stop to shutdown process from within worker 
# Use Workety.abort to shutdown and return exit code 1, thus leading to restart by watchdog
#
#
# This is an implementation for threaded worker.
#
# TODO: If worker does not have any threads then a different path should be given:
#   * no mutex/started/must_stop
#   * no Signal.threaded_trap
#   * no thread list on USR1
#   * Just instantiate the class and call .start on it, leaving signal handling to that class
#
#
module Workety
  class Railtie < Rails::Railtie
    initializer :workety, :after => :load_environment_config, :before => :load_active_support do |app|
      Rails.configuration.threadsafe!
    end
  end
  
  @thread = nil
  @mutex = Mutex.new
  @started = false
  @must_stop = false
  @aborted = false

  class << self
    
    def start(class_name, user = nil, group = nil)
      rescue_exit do
        
        # Class initialize is the place to things you should do before dropping privilegies (like start listening at port 80).
        #
        @mutex.synchronize do
          Process.exit(!@aborted) if @must_stop
          @thread = class_name.constantize.new
        end

        Process.change_privilegies(user, group) if user || group
       
        @mutex.synchronize do
          Process.exit(!@aborted) if @must_stop
          @thread.start
          @started = true
        end
      end
    end
    
    def join
      rescue_exit { @thread.join }
    end

    def stop_sequence(aborted)
      rescue_exit do
        @mutex.synchronize do
          @aborted = true if aborted
          
          unless @must_stop
            @must_stop = true
            
            Thread.rescue_exit { stop_watchdog }
            Thread.rescue_exit { @thread.stop } if @started
          end
        end
      end
    end

    # Thread initialize/start occurs inside @mutex, so calling Workety.abort/stop/must_stop?/aborted? from within it will 
    # lead to "ThreadError: deadlock; recursive locking"

    def abort
      stop_sequence(true)
    end
    
    def stop
      stop_sequence(false)
    end
    
    def aborted?
      @mutex.synchronize { @aborted }
    end
    
    def must_stop?
      @mutex.synchronize { @must_stop } 
    end
    

    def rescue_abort
      yield
    rescue ScriptError, StandardError => exception
      begin
        exception.report!
      ensure
        Workety.abort
      end
    end
    
    
    # Timeout for stop() and join()
    # When the process is stopped by a signal, watchdog or signal sender take care of timeout
    # But when the process call Workety.stop/abort by itself, this timeout function will ensure successful termination  
    def stop_watchdog
      sleep WORKETY_STOP_SELF_WATCHDOG_TIMEOUT
      Thread.log "Timeout stopping process"
    ensure
      Process.exit(false)
    end
    
  end
end

