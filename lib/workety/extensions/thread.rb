
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


require 'thread'

class Thread
  
  def self.workety
    new do
      begin
        Workety.rescue_abort { yield }
        
      ensure
        # That block is executed on Thread#kill as well
        #
        # I think an error in clear_active_connections! is not the case
        # for panic and instant process shutdown but for normal shutdown procedure.
        #  
        Workety.rescue_abort { ActiveRecord::Base.clear_active_connections! }
         
      end
    end
  end
  
  
  def self.networkety
    workety do
      begin
        yield
      rescue *(Socket::NETWORK_EXEPTIONS) => exception
        Rails.logger.warn "Thread stopped due a network error listed in Socket::NETWORK_EXEPTIONS"
        Rails.logger.warn exception.view
        Rails.logger.flush if Rails.logger.respond_to?(:flush)

        # If thread is blocked by Socket#read and then are forced to unblock by using Socket#shutdown and then Socket#close methods,
        # that will raise an exception. That exception has no value to set Workety.aborted? flag.
        # If Workety.must_stop? is set we suggest that such technique was used.
        Workety.abort unless Workety.must_stop? 
      end
    end
  end
  
  
  def self.rescue_exit
    new do
      Kernel.rescue_exit { yield }
    end
  end

  
  def view
    "#{summary_view}\n#{thread_local_vars_view}#{backtrace_view}"
  end

  def summary_view
    "#{self.class.name} 0x#{object_id.to_s(16)}: #{status_view}"
  end
  
  def status_view
    st = status; (st == false) ? "terminated normally" : (st || "terminated with an exception")
  end

  def thread_local_vars_view
    if (ks = keys).any?
      vars = {}; ks.each {|k| vars[k] = self[k]}
      "Thread-local variables: #{vars.inspect}\n"
    end
  end

  def backtrace_view
    ((bt = backtrace) && bt.collect{|line| "\t#{line}\n"}.join("") || "\tBacktrace undefined")
  end
  
  
  def self.log message = nil
    threads = self.list
    Rails.logger.warn(message) if message
    Rails.logger.warn "Thread list: #{threads.length} threads total at #{Time.now}"
    
    threads.each_with_index do |item, index|
      Rails.logger.warn msg = "Thread #{index + 1} of #{threads.length}"
      Rails.logger.warn "-" * msg.length
      Rails.logger.warn item.view
    end
    
    Rails.logger.flush if Rails.logger.respond_to?(:flush)
  end
  
  
  def log_join(message, limit = nil)
    join limit
    Rails.logger.info message
  end

end

