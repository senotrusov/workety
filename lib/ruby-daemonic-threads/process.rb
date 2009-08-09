
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


class DaemonicThreads::Process
  
  def initialize(controller)
    @controller = controller
    @name = controller.name
    
    @config = DaemonicThreads::Config.new(RAILS_ROOT + '/config/daemons.yml')
    @http = DaemonicThreads::HTTP::Server.new(self)
    @queues = DaemonicThreads::Queues.new(self)
    @daemons = DaemonicThreads::Daemons.new(self)
  end
  
  attr_reader :controller, :name, :config, :http, :queues, :daemons
  
  def start
    @http.start
    @daemons.start
  end
  
  def join
    @http.join
    @daemons.join
  end    
  
  def stop
    @http.stop
    @daemons.stop
  end

  def before_exit
    @queues.store_and_close
  end

end

