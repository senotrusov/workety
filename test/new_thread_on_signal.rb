
#  Copyright 2009-2011 Stanislav Senotrusov <senotrusov@gmail.com>
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

require 'thread'

t = nil

term_signal_handler = Proc.new do
  t = Thread.new do
    begin
      puts "THREAD"
      sleep 5
      puts "DONE"
    rescue Exception => exception
      puts exception.inspect
    end 
  end
end

Signal.trap('INT',  & term_signal_handler) # Ctrl+C
Signal.trap('TERM', & term_signal_handler) # kill


Process.kill("TERM", Process.pid)

sleep 10

