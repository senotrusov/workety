
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


require 'pp'


require 'workety/extensions/exception.rb'
require 'workety/extensions/kernel.rb'
require 'workety/extensions/process.rb'
require 'workety/extensions/signal.rb'
require 'workety/extensions/socket.rb'
require 'workety/extensions/thread.rb'
require 'workety/extensions/tzinfo.rb' if Gem.available? 'tzinfo'

if Gem.available? 'hiredis'
  require 'workety/extensions/hiredis.rb'
  require 'workety/redis_queue.rb'
  require 'workety/redis_queue_json.rb' if Gem.available? 'yajl-ruby'
end

require 'workety/timed_exit.rb'


require 'workety/workety.rb'

