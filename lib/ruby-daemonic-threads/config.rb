
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


class DaemonicThreads::Config
  def initialize(filename)
    @daemons = YAML::load(ERB.new(IO.read(filename)).result).reject do |name, config|
      config["environment"] && !(config["environment"].split(/ *, */).include?(Rails.env))
    end
    
    @queue_names = get_queue_names
    
    @daemons.each do |name, config|
      raise "Class name for daemon `#{name}' must be specified" if config["class"].nil? || config["class"].empty?
       
      config["class-constantized"] = config["class"].constantize
    end    
    
    Rails.logger.debug {"#{self.class}#initialize -- Configuration: #{self.inspect}"}
  end
  
  attr_reader :queue_names, :daemons
  
  private
  
  def get_queue_names
    names = []
    
    @daemons.collect do |name, config|
      if config["queues"] 
        config["queues"].each do |queue_daemon_handler, queue_name|
          names.push queue_name.to_sym
        end
      end 
    end
    
    return names.uniq
  end
end
