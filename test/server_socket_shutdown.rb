
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

require 'thread'
require 'socket'

s=TCPServer.new("127.0.0.1", 9999)

t = Thread.new do
  begin
    loop do
      puts "ACCEPTING"
      puts s.accept.inspect
      puts "ACCEPTED"
    end
    puts "DONE"
  rescue Exception => ex
    puts "EX"
    puts ex.inspect #<Errno::EINVAL: Invalid argument>
  end
end

c = Thread.new do
  s.shutdown
  # t.run # here leads to #<Errno::EBADF: Bad file descriptor> insted of Errno::EINVAL
  sleep 1 # Without that sleep exception will not raised in t
  s.close
  puts "Closed"
end

t.join
c.join



