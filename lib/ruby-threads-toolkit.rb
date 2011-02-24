
#  Copyright 2007-2009 Stanislav Senotrusov <senotrusov@gmail.com>
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


module DaemonicThreads
  class MustTerminatedState < StandardError; end
end


require 'thread'

require 'ruby-threads-toolkit/thread-extensions/condition_variable.rb'
require 'ruby-threads-toolkit/thread-extensions/mutexed_accessors.rb'
require 'ruby-threads-toolkit/thread-extensions/smart_queue.rb'
require 'ruby-threads-toolkit/thread-extensions/persistent_queue.rb'
require 'ruby-threads-toolkit/thread-extensions/thread.rb'
require 'ruby-threads-toolkit/thread-extensions/thread_lock.rb'
require 'ruby-threads-toolkit/thread-extensions/threadsafe_sequence.rb'
require 'ruby-threads-toolkit/thread-extensions/threadsafe_sequence_loop.rb'


require 'erb'


require 'ruby-threads-toolkit/core-extensions/exception.rb'
require 'ruby-threads-toolkit/core-extensions/pathname.rb'
require 'ruby-threads-toolkit/core-extensions/file.rb'
require 'ruby-threads-toolkit/core-extensions/socket.rb'
require 'ruby-threads-toolkit/core-extensions/accessors_generator.rb'


require "ruby-threads-toolkit/config.rb"
require "ruby-threads-toolkit/daemons.rb"
require "ruby-threads-toolkit/http.rb"
require "ruby-threads-toolkit/http/server.rb"
require "ruby-threads-toolkit/http/request.rb"
require "ruby-threads-toolkit/http/daemon.rb"
require "ruby-threads-toolkit/process.rb"
require "ruby-threads-toolkit/base.rb"
require "ruby-threads-toolkit/queues.rb"
require "ruby-threads-toolkit/runner.rb"

require "ruby-threads-toolkit/patches/timezone.rb"

require "mongrel" if Gem.available? "mongrel"

