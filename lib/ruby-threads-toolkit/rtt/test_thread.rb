
#  Copyright 2009-2011 Stanislav Senotrusov <stan@senotrusov.com>
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

class Rtt::TestThread
  def initialize
    STDOUT.write "#{self.class} init, pid #{Process.pid}\n"
  end
  
  def start
    STDOUT.write "#{self.class} start, pid #{Process.pid}\n"

#    nonexistant_method
    
    STDOUT.write "STDOUT test\n"
    STDERR.write "STDERR test\n"

    @t = Thread.new do
      STDOUT.write "#{self.class} sleep\n"
      sleep 30
      STDOUT.write "#{self.class} done sleep\n"
    end
    
#    1000.times do 
#      Thread.new { 1000.times { Rails.logger.error "test" } } 
#      Thread.new { 1000.times { STDOUT.write "test\n" } }
#    end
    # cat log/rtt-test_thread.log |grep -v "^test$"
    
  end
  
  def join
    STDOUT.write "#{self.class} join\n"
    @t.join
    STDOUT.write "#{self.class} done join\n"
    STDOUT.write "#{self.class} sleep\n"
    #sleep 30
    STDOUT.write "#{self.class} done sleep\n"
  end
  
  def stop
    STDOUT.write "#{self.class} stop\n"
    @t.kill
  end
end
