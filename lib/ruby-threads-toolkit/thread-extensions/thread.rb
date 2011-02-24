
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


require 'thread'
require 'senotrusov-ruby-toolkit'

class ThreadJoinTimeoutExpiresError < Exception; end
class ThreadTerminatedError < StandardError; end
class ThreadNotTerminatedError < StandardError; end

class Thread
  
  def self.new_with_exception_handling(handler, logger = nil, severity = :fatal, title = nil, inspect_method = :inspect_with_backtrace, *args)
    Thread.new do
      begin
        Thread.current[:title] = title
        Thread.current[:started_at] = Time.now
        yield(*args)
      rescue Exception => exception
        begin
          exception.log!(logger, severity, title, inspect_method) if logger
          handler.call(exception) if handler
        rescue Exception => handler_exception
          handler_exception.log!(logger, severity, title, inspect_method) if logger
        end
      end
    end
  end
  
  def join_and_terminate(timeout = 60, raise_timeout = nil)
    raise_timeout = timeout * (timeout > 30 ? 0.1 : 0.2) unless raise_timeout
    
    unless join(timeout)
      self.raise(ThreadJoinTimeoutExpiresError, "#{timeout} seconds join timeout expires")
      begin
        unless join(raise_timeout)
          Kernel.raise(ThreadNotTerminatedError, "Thread are not terminated after #{timeout} seconds join timeout and #{raise_timeout} seconds raise timeout")
        end
      rescue ThreadJoinTimeoutExpiresError => exception
        Kernel.raise(ThreadTerminatedError, "Thread terminated after #{timeout} seconds with force raise of ThreadJoinTimeoutExpiresError exception")
      end
    end
  end
  
  def inspect_with_values
    inspect[0..-2] + " " + keys.collect{|key| ":#{key}=>#{self[key].inspect rescue "CAN NOT INSPECT!"}"}.join(" ") + ">"
  end
end

