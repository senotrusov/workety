
#  Copyright 2006-2012 Stanislav Senotrusov <stan@senotrusov.com>
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

class GracefulStopThread
  # Before dropping privileges 
  def initialize
    @mutex = Mutex.new
    @wakeup = ConditionVariable.new
  end
  
  # After changing privileges to some user/group
  def start
    @worker = Thread.workety do
      @mutex.synchronize do
        until Workety.must_stop? do
          
          puts "Hello"
          
          @wakeup.wait(@mutex, 10)
        end
      end
    end
  end
  
  def join
    @worker.join
  end
  
  def stop
    @mutex.synchronize do
      @wakeup.signal
    end
  end
end
