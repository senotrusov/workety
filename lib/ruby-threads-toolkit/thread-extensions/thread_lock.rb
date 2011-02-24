
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


class NestingThreadLockError < StandardError; end
  
class ThreadLock
  def initialize
    @mutex = Mutex.new
    
    @exclusive_done = ConditionVariable.new
    @shared_done = ConditionVariable.new
    
    @exclusive = false
    @shared = []
  end
  
  def shared
    @mutex.synchronize do
      if @exclusive && @exclusive != Thread.current
        @exclusive_done.wait_while(@mutex) {@exclusive}
      end
      
      @shared << Thread.current
    end
    
    yield
      
  ensure
    @mutex.synchronize { @shared.delete_at(@shared.index(Thread.current)) if @shared.index(Thread.current)}
    @shared_done.signal
  end
  
  def exclusive
    @mutex.synchronize do
      raise(NestingThreadLockError, "Unable to obtain exclusive lock inside another shared or exclusive lock") if @shared.include?(Thread.current) || @exclusive == Thread.current

      if @exclusive
        @exclusive_done.wait_while(@mutex) {@exclusive}
      end
      
      @exclusive = Thread.current
      
      unless @shared.empty?
        @shared_done.wait_until(@mutex) {@shared.empty?}
      end
    end
    yield
  ensure
    if @mutex.synchronize {@exclusive = false if @exclusive == Thread.current } == false
      @exclusive_done.broadcast
    end
  end
  
  def exclusive?
    @mutex.synchronize { @exclusive == Thread.current }
  end
end

