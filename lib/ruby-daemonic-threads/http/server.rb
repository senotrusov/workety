
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


# Почему я не использую Rack
#
#   1. У rack нет unregister handle
#
#   2. Не понятно - нужно ли хоть что-то из всего разнообразия веб-серверов доступных через Rack
#
#   3. Не понятно как работают тругие сервера с тредами.
#      Мы забираем тред из mongrel's ThreadGroup. Как на это отреагируют другие сервера.
#
#   4. У mongrel есть run/join/stop

class DaemonicThreads::HTTP::Server
  DEFAULT_HTTP_PORT = 4000
  DEFAULT_HTTP_BINDING = "127.0.0.1"
  
  def initialize(process)
    argv = process.controller.argv
    
    argv.option "-b, --binding IPADDR", "IP address to bind to, #{DEFAULT_HTTP_BINDING} as default"
    argv.option "-p, --port PORT", "HTTP port to listen to, #{DEFAULT_HTTP_PORT} as default"
    
    argv.parse!
    
    @binding = argv["binding"] || DEFAULT_HTTP_BINDING
    @port = argv["port"] || DEFAULT_HTTP_PORT
    @prefix = process.name

    @server = Mongrel::HttpServer.new(@binding, @port)
    
    @mutex = Mutex.new
  end
  
  attr_reader :prefix
  
  def start
    @acceptor = @server.run
    
    register("/#{@prefix}/status", Mongrel::StatusHandler.new)
  end
  
  # I do not know why @acceptor.join tends to hang forever on ruby 1.9.1p243 (2009-07-16 revision 24175) [i686-linux], while on ruby 1.8 it was fine
  def join
    raise "DaemonicThreads::HTTP::Server#join unimplemented"
    @acceptor.join if @acceptor
  end    
  
  def stop
    # Until join() is unimplemented stop() must be synchronous
    @server.stop true
  end
  
  def register uri, handler
    @mutex.synchronize do
      @server.register uri, handler
    end
  end
  
  def unregister uri
    @mutex.synchronize do
      @server.unregister uri
    end
  end
  
end

