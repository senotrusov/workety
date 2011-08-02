
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


class TimedExit
  def initialize(timeout = 60, message = "Timeout reached")
    @mutex = Mutex.new
    @must_cancel = false
    @timeout_reached = false
    
    Thread.rescue_exit do
      sleep timeout
      
      @mutex.synchronize do
        unless @must_cancel
          @timeout_reached = true
          Rails.logger.info message
          Process.exit(false)
        end
      end
    end
  end
  
  def cancel
    @mutex.synchronize do
      Process.exit(false) if @timeout_reached # See comment below
      @must_cancel = true
    end
  end
end

# In the following example block "ALIVE!\n" seems to not get execution, but I am not sure - does that behaviour consistent?  
#require 'thread'
#m = Mutex.new
#Thread.new { m.synchronize { sleep 3; Process.exit(false) } }
#sleep 1
#m.synchronize { STDOUT.write "ALIVE!\n" }

