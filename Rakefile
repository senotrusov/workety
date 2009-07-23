
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


spec = Gem::Specification.new do |s|
  s.name          = "ruby-daemonic-threads"
  s.version       = "1.0.0"
  s.date          = Time.now
  
  s.has_rdoc      = true
  s.rdoc_options  << '--inline-source' << '--charset=UTF-8'
  s.extra_rdoc_files = %w(README LICENSE)
  
  s.summary       = "Create multithreaded applications with smart persistent internal queues, WEB/REST interface, exception handling and recovery"
  s.author        = "Stanislav Senotrusov"
  s.email         = "senotrusov@gmail.com"
  s.homepage      = "http://github.com/senotrusov"
  
  s.require_path  = 'lib'
  s.files         = %w(README LICENSE) + Dir.glob("{lib,test}/**/*")
  
  s.add_dependency 'mongrel'
  s.add_dependency "senotrusov-ruby-toolkit"
  s.add_dependency "senotrusov-ruby-threading-toolkit"
  s.add_dependency "senotrusov-ruby-process-controller"
end


task :default => [:gemspec]

task :gemspec do
  File.open("#{spec.name}.gemspec", 'w') do |file|
    file.write spec.to_ruby
  end
  puts "gemspec created"
end

