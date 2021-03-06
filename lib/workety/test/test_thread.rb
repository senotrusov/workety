
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

class Workety::TestThread
  # Before dropping privileges 
  def initialize
    STDOUT.write "#{self.class} init, pid #{Process.pid}\n"
  end
  
  # After changing privileges to some user/group
  def start
    STDOUT.write "#{self.class} start, pid #{Process.pid}\n"

#    nonexistant_method
    
    STDOUT.write "STDOUT test\n"
    STDERR.write "STDERR test\n"

    Thread.workety do
      sleep 5
      bad_method
    end
    
#    Thread.new do
#      begin
#        sleep 5
#        STDOUT.write "Workety.stop\n"
#        Workety.stop
#      rescue Exception => e
#        e.report!
#      end
#    end
    
    @ws = Thread.new do
      begin
        until Workety.must_stop? do
          STDOUT.write "Workety.must_stop?\n"
          sleep 1
        end
        STDOUT.write "Workety.must_stop? is true\n"

      rescue Exception => e
        e.report!
      end
    end


    @t = Thread.new do
      600.times do |t|
        STDOUT.write "#{self.class} Doing #{t}\n"
        sleep 1
      end
    end
    
#    1000.times do 
#      Thread.new { 1000.times { Rails.logger.error "test" } } 
#      Thread.new { 1000.times { STDOUT.write "test\n" } }
#    end
    # cat log/workety-test_thread.log |grep -v "^test$"
    
  end
  
  def join
    STDOUT.write "#{self.class} join\n"
    @t.join
    @ws.join
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
