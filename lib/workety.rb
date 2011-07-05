
#  Copyright 2007-2011 Stanislav Senotrusov <stan@senotrusov.com>
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

require 'workety/core-extensions/accessors_generator.rb'
require 'workety/core-extensions/exception.rb'
require 'workety/core-extensions/file.rb'
require 'workety/core-extensions/pathname.rb'
require 'workety/core-extensions/signal.rb'
require 'workety/core-extensions/socket.rb'


require 'thread'

require 'workety/thread-extensions/condition_variable.rb'
require 'workety/thread-extensions/mutexed_accessors.rb'
require 'workety/thread-extensions/smart_queue.rb'
require 'workety/thread-extensions/persistent_queue.rb'
require 'workety/thread-extensions/thread.rb'
require 'workety/thread-extensions/thread_lock.rb'
require 'workety/thread-extensions/threadsafe_sequence.rb'
require 'workety/thread-extensions/threadsafe_sequence_loop.rb'


require "workety/patches/tzinfo.rb" if Gem.available? "tzinfo"


module Workety
end

require "workety/workety/test_thread.rb"


#module DaemonicThreads
#  class MustTerminatedState < StandardError; end
#end

#require "workety/base.rb"

