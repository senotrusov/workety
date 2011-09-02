
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


require 'yajl'

class RedisQueue::JSON < RedisQueue
  BACKUP_LIMIT = 3
  BACKUP_COUNT_KEY = :redis_queue_backup_pop_count
  
  def push element, queue = @queue
    super(encode(element), queue)
  end

  def pop queue = @queue
    decode(super(queue))
  end
  
  def backup_pop queue = @queue
    raw = super(queue)
    
    if block_given?
      yield decode(raw)
      remove_backup raw, queue
    else
      return raw, decode(raw)
    end
  end
  
  def encode element
    Yajl::Encoder.encode(element)
  end
  
  def decode raw
    (result = Yajl::Parser.new.parse(raw)).is_a?(Hash) ? result.with_indifferent_access : result
  end
  
  alias :encode_json :encode
  alias :decode_json :decode
  

  def restore_backup_element element, queue
    result = decode_json(element)
    
    if result.is_a?(Hash)
      result[BACKUP_COUNT_KEY] ||= 0
      result[BACKUP_COUNT_KEY] += 1
      
      if result[BACKUP_COUNT_KEY] > BACKUP_LIMIT
        error_push encode_json(result), queue
        return nil
      else
        return encode_json(result)
      end
      
    else
      element
    end
    
  end

end

