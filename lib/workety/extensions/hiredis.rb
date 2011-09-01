
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


require 'hiredis'

module Hiredis
  class UnexpectedResult < StandardError; end
  
  class Connection
    def self.local
      redis = new
      unix_socket = "/tmp/redis.sock"
      File.socket?(unix_socket) ? redis.connect_unix(unix_socket) : redis.connect("127.0.0.1", 6379)
      redis
    end

    def call *args
      write(args)
      read
    rescue RuntimeError => exception
      (exception.message == "not connected") ? raise(IOError, "Not connected") : raise(exception)
    end
    
    # THe following function names and the whole concept it's not very thoughtful, but let's see how it goes 
    def ok_call *args
      result = call *args
      result != "OK" ? raise(Hiredis::UnexpectedResult, "Call #{args.inspect}: received #{result.inspect}, expected 'OK'") : result
    end
    
    def notnil_call *args
      result = call *args
      result == nil ? raise(Hiredis::UnexpectedResult, "Call #{args.inspect}: received #{result.inspect}, expected not nil") : result
    end
    
    def multi(watch = [])
      call "MULTI"
      call *(["WATCH"] + watch) unless watch.empty?
      yield
      call "EXEC"
    rescue
      call "DISCARD"
    end
  end
end
