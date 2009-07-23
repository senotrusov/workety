
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

require 'erb'

require "ruby-daemonic-threads/config.rb"
require "ruby-daemonic-threads/daemons.rb"
require "ruby-daemonic-threads/http.rb"
require "ruby-daemonic-threads/http/server.rb"
require "ruby-daemonic-threads/http/request.rb"
require "ruby-daemonic-threads/http/daemon.rb"
require "ruby-daemonic-threads/process.rb"
require "ruby-daemonic-threads/prototype.rb"
require "ruby-daemonic-threads/queues.rb"
require "ruby-daemonic-threads/runner.rb"

require "ruby-daemonic-threads/patches/timezone.rb"

require "mongrel"

