
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


class DaemonicThreads::Flag
  def initialize name, daemon, value = nil
    @name = name
    @daemon = daemon
    @value = value
    @mutex = Mutex.new
    @changed = ConditionVariable.new
  end
  
  def synchronize
    @mutex.synchronize { yield(self) }
  end
  
  def is value
    @value = value
  end
  
  def is? value
    @value == value
  end
  
  def wait_changes_for duration
    @daemon.spawn_untracked_thread("#{@name} timeout timer") do
      sleep(duration)
      @mutex.synchronize { @changed.signal }
    end
    @changed.wait(@mutex)
  end
end

