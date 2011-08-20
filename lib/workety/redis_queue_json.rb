
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
  def push element
    super(encode(element))
  end

  def pop
    decode(super)
  end
  
  def backup_pop
    raw = super
    return raw, decode(raw)
  end
  
  def encode element
    Yajl::Encoder.encode(element)
  end
  
  def decode raw
    Yajl::Parser.new.parse(raw).with_indifferent_access
  end
end

