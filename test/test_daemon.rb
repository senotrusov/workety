
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

class ProcessController::TestDaemon
  SLEEP_FOR = 100
  
  def define_options(options)
    options.header << "Test Daemon"
    options.option "--foo FOO", "Foo option"
  end

  def apply_options(options)
    puts options.inspect
  end

  def start
    puts "#{self.class.inspect} STARTED"
    puts "#{self.class.inspect} SLEEPING FOR #{SLEEP_FOR} seconds..."
    sleep SLEEP_FOR
  end
  
  def stop
    puts "#{self.class.inspect} STOP method"
  end
end

