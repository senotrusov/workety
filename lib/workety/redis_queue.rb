
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


class RedisQueue
  def self.connect
    redis = Hiredis::Connection.local
    
    if block_given?
      result = yield(redis)
      redis.disconnect
      result
    else
      redis
    end
  end
  
  def self.list
    connect do |redis|
      redis.call("KEYS", "queue.*").collect do |queue|
        [queue, redis.call("LLEN", queue)]
      end
    end
  end
  
  def self.delete queue
    connect do |redis|
      redis.call("DEL", queue)
    end
  end
  
  
  def initialize(name, backup_name = nil)
    @queue = "queue." + name
    @backup_queue = ("queue." + backup_name) if backup_name
    
    @redis = self.class.connect
  end
  
  # Returns the number of elements inside the queue after the push operation.
  def push element
    @redis.call("RPUSH", @queue, element)
  end

  # Returns element
  def pop
    @redis.call("BRPOP", @queue, 0).last
  end
  
  # Returns element
  def backup_pop
    @redis.call("BRPOPLPUSH", @queue, @backup_queue, 0)
  end
  
  def remove_backup element
    if @redis.call("LREM", @backup_queue, -1, element) != 1
      raise "Queue #{@backup_queue}: not found element #{element.inspect}"
    end
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

