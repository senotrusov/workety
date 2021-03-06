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

class SimpleThread
  # Before dropping privileges 
  def initialize
  end
  
  # After changing privileges to some user/group
  def start
    @t = Thread.workety do
      until Workety.must_stop? do
        sleep 1
      end
    end
    
    Thread.workety do
      sleep 10
      Workety.stop
    end
  end
  
  def join
    @t.join
  end
  
  def stop
    @t.kill
  end
end

