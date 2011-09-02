
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
  
  def self.delete *queues
    connect do |redis|
      redis.call("DEL", *queues)
    end
  end
  
  
  attr_reader :queue
  
  def initialize(queue)
    @queue = queue
    @redis = self.class.connect
  end
  
  # Returns the number of elements inside the queue after the push operation.
  def push element, queue = @queue
    @redis.call("LPUSH", "queue." + queue, element)
  end
  
  def error_push element, queue = @queue
    @redis.call("LPUSH", "queue." + queue + ".error", element)
  end

  # Returns element
  def pop queue = @queue
    @redis.call("BRPOP", "queue." + queue, 0).last
  end
  
  # Returns element
  def backup_pop queue = @queue
    element = @redis.call("BRPOPLPUSH", "queue." + queue, "queue." + queue + ".backup", 0)
    
    if block_given?
      yield(element)
      remove_backup element, queue
    else
      return element
    end
  end
  
  def remove_backup element, queue = @queue
    if @redis.call("LREM", "queue." + queue + ".backup", -1, element) != 1
      raise "Queue #{"queue." + queue + ".backup"}: not found element #{element.inspect}"
    end
  end
  
  def restore_backup queue = @queue
    while element = @redis.call("RPOP", "queue." + queue + ".backup")
      if restored = restore_backup_element(element, queue)
        @redis.call("LPUSH", "queue." + queue, restored)
      end
    end
  end
  
  def restore_backup_element element, queue
    element
  end
  
  def redirect to_queue, queue = @queue
#    http://code.google.com/p/redis/issues/detail?id=593
#    @redis.call("BRPOPLPUSH", "queue." + queue, "queue." + to_queue, 0)
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

