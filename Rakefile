
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


begin
  require 'jeweler'
  
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "workety"
    gemspec.summary = "Concise way to run ruby code as a worker - may be daemonized, may be forked from watchdog, may be multithreaded, may send exceptions to hoptoad, load rails environment at late stage"
    gemspec.email = "stan@senotrusov.com"
    gemspec.homepage = "http://github.com/senotrusov/workety"
    gemspec.authors = ["Stanislav Senotrusov"]

    gemspec.add_dependency 'trollop'
    gemspec.add_dependency 'toadhopper' # TODO: Make optional
  end
  
  Jeweler::GemcutterTasks.new
  
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

