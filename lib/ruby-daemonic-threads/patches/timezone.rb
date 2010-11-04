
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

# tzinfo is lazy loaded by default, so it gaves random exceptions in multithreaded env
# To reproduce race condition, start daemon and do concurrent HTTP get for some resource
# ab -c 100 -n 1000 http://127.0.0.1:4000/daemon/foo_resources/7.xml


# TODO Watch for activesupport-3.0.1/lib/active_support/values/time_zone.rb thread safe TODO at line 320
require 'active_support/tzinfo' unless defined?(::TZInfo)

# @@loaded_zones hash must be mutexed
class TZInfo::Timezone
  @@loaded_zones_mutex = Mutex.new
  
  class << self
    alias_method :unsafe_get, :get

    def get(identifier)
      @@loaded_zones_mutex.synchronize do
        unsafe_get(identifier)
      end
    end
  end
end

