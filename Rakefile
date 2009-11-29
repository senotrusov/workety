
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


begin
  require 'jeweler'
  
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "ruby-daemonic-threads"
    gemspec.summary = "Create multithreaded applications with smart persistent internal queues, WEB/REST interface, exception handling and recovery"
    gemspec.email = "senotrusov@gmail.com"
    gemspec.homepage = "http://github.com/senotrusov/ruby-daemonic-threads"
    gemspec.authors = ["Stanislav Senotrusov"]
    
    gemspec.add_dependency 'mongrel'
    gemspec.add_dependency "senotrusov-ruby-toolkit"
    gemspec.add_dependency "ruby-threading-toolkit"
    gemspec.add_dependency "ruby-process-controller"
  end
  
  Jeweler::GemcutterTasks.new
  
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

