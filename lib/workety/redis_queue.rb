
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


require 'hiredis'

class RedisQueue
  def initialize(name, backup_name = nil)
    @queue = "queue." + name
    @backup_queue = ("queue." + backup_name) if backup_name
    
    @redis = Hiredis::Connection.new
    
    File.socket?("/tmp/redis.sock") ? @redis.connect_unix("/tmp/redis.sock") : @redis.connect("127.0.0.1", 6379)
  end
  
  # Returns the number of elements inside the queue after the push operation.
  def push element
    @redis.write ["RPUSH", @queue, element]
    @redis.read
  rescue RuntimeError => exception
    (exception.message == "not connected") ? raise(IOError, "Not connected") : raise(exception)
  end

  # Returns element
  def pop
    @redis.write ["BRPOP", @queue, 0]
    @redis.read.last
  rescue RuntimeError => exception
    (exception.message == "not connected") ? raise(IOError, "Not connected") : raise(exception)
  end
  
  # Returns element
  def backup_pop
    @redis.write ["BRPOPLPUSH", @queue, @backup_queue, 0]
    @redis.read
  rescue RuntimeError => exception
    (exception.message == "not connected") ? raise(IOError, "Not connected") : raise(exception)
  end
  
  def remove_backup element
    @redis.write ["LREM", @backup_queue, -1, element]
    raise "Queue #{@backup_queue}: not found element #{element.inspect}" if @redis.read != 1
  end
  
  def disconnect(thread = nil, limit = 10)
    begin
      @redis.disconnect
    rescue RuntimeError => exception
      raise(exception) if exception.message != "not connected"
    end
    
    if thread
      begin
        thread.run
      rescue ThreadError => exception
        raise exception if exception.message != "killed thread"
      end
      thread.join(limit)
    end
  end
end

