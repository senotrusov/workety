
#  Copyright 2009 Stanislav Senotrusov <senotrusov@gmail.com>
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


# NOTE:
#   This is not a quarantied delivery queues.
#   They rely on normal process startup/shutdown sequence. 
#   So, if you got segfault all data will be lost.
#   On the other hand, queues tends to be quite quickly  

class DaemonicThreads::Queues
  DEFAULT_STORAGE_DIR = Rails.root + 'tmp' + 'queues'

  def initialize(process)
    @queues = {}
    @config = process.config.queues

    @storage_dir = DEFAULT_STORAGE_DIR
    @storage_dir.mkpath
    
    @config.each do |name, config|
      queue = @queues[name.to_sym] = config["class-constantized"].new
      
      if queue.respond_to?(:restore)
        queue.storage = @storage_dir + name
        queue.restore
      end
    end
  end
  
  def store_and_close
    @queues.each do |name, queue|
      queue.store_and_close if queue.respond_to?(:store_and_close)
    end
  end

  def [] name
    @queues[name]
  end
end

