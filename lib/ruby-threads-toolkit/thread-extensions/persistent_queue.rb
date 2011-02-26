
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


class PersistentQueue < SmartQueue
  attr_accessor :storage
  
  # Storage must respond to exist?(), read(), delete() and write(data)
  # like Pathname for file-based storage 
  
  def restore
    @mutex.synchronize do
      if @storage.exist?
        data = Marshal.restore(@storage.read)
        @storage.delete

        @regular = data[:regular]
        @priority = data[:priority]
        yield(data) if block_given?
      end
    end
  end
  
  def store_and_close
    @mutex.synchronize do
      data = {:regular => @regular, :priority => @priority}
      yield(data) if block_given?
      @storage.write Marshal.dump(data)

      # This will simply raise exception on trying to push/pop from/to queue
      @regular = nil
      @priority = nil
    end
  end
end

