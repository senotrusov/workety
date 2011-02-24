
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


class ThreadsafeSequence
  def initialize(range = nil)
    if range
      @initial_value = @value = range.first - 1
      @maximum = range.exclude_end? ? range.last - 1 : range.last
    else
      @initial_value = @value = 0
      @maximum = nil
    end
    
    @mutex = Mutex.new
  end

  def nextval
    @mutex.synchronize do
      raise("Maximum sequence number achived (#{@maximum})") if @value == @maximum
      @value += 1
    end
  end
end

