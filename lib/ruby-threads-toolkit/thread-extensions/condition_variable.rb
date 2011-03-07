
#  Copyright 2006-2009 Stanislav Senotrusov <stan@senotrusov.com>
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


class ConditionVariable
  def wait_until(mutex)
    begin
      wait(mutex)
    end until yield
  end
  
  def unless_wait_until(mutex)
    unless yield
      begin
        wait(mutex)
      end until yield
    end
  end

  def wait_while(mutex)
    begin
      wait(mutex)
    end while yield
  end

  def if_wait_while(mutex)
    if yield
      begin
        wait(mutex)
      end while yield
    end
  end
end
