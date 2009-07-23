
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
#   It is not a quarantied delivery queues.
#   It rely on normal process startup/shutdown sequence. 
#   So, if you get sigfault all data will be lost.
#   On the other hand, queues tends to be quite quickly, since all done in memory  

class DaemonicThreads::Queues

  DEFAULT_STORAGE_DIR = Rails.root + 'tmp' + 'queues'

  def initialize(process)
    @queues = {}
    @storage_dir = DEFAULT_STORAGE_DIR
    @queue_names = process.config.queue_names 
    
    raise("Queues storage directory #{@storage_dir} is not available!") unless storage_available?
  end
  
  def restore
    @queue_names.each do |name|
      if File.exists?(filename = "#{@storage_dir}/#{name}")
        @queues[name] = SmartQueue.new(File.read(filename))
        File.unlink(filename)
      else
        @queues[name] = SmartQueue.new
      end
    end
  end
  
  def store
    @queues.each do |name, queue|
      File.write("#{@storage_dir}/#{name}", queue.to_storage)
    end
  end

  def [] name
    @queues[name]
  end
  
  private

  def storage_available?
    if File.directory?(@storage_dir) && File.writable?(@storage_dir)
      return true
    else
      begin
        Dir.mkdir(@storage_dir)
        return true
      rescue SystemCallError
        return false
      end
    end
  end
  
end

