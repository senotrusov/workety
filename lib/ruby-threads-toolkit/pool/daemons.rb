
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


class DaemonicThreads::Daemons
  
  def initialize(process)
    @daemons = {}
    
    process.config.daemons.each do |name, config|
      @daemons[name] = DaemonicThreads::Runner.new(name, config, process)
    end
  end
  
  def [] name
    @daemons[name]
  end
  
  def start
    each_daemon :start
  end
  
  def join
    each_daemon :join
  end
  
  def stop
    each_daemon :stop
  end

  private
  
  def each_daemon action
    @daemons.each {|name, daemon| daemon.__send__(action) }
  end
end

