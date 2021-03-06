
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


gems = lambda do |name|
  if Gem::Specification.respond_to?(:find_all_by_name)
    Gem::Specification.find_all_by_name(name).any?
  elsif Gem.respond_to?(:available?)
    Gem.available?(name)
  else
    raise "Don't know how to check gem availability"
  end
end


if gems['exceptional']
  require 'exceptional'
  require 'workety/extensions/exceptional.rb'
end

if gems['toadhopper']
  require 'toadhopper'
end


require 'workety/extensions/exception.rb'
require 'workety/extensions/kernel.rb'
require 'workety/extensions/process.rb'
require 'workety/extensions/signal.rb'
require 'workety/extensions/socket.rb'
require 'workety/extensions/thread.rb'


require 'workety/timed_exit.rb'


require 'workety/workety.rb'

