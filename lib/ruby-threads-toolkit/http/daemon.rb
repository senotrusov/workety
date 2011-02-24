
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


# TODO: error handling for web frontends

module DaemonicThreads::HTTP::Daemon

  def initialize_http
    @http = @process.http
    @http.register(uri, self)
  end

  def deinitialize_http
    @http.unregister(uri)
  end
  
  attr_reader :request_notify
  attr_accessor :listener
  
  def uri
    @uri ||= (@parent ? (@parent.uri + '/' + @name) : ('/' + @http.prefix + '/' + @name))
  end
  

  def process(mongrel_request, mongrel_response)
    request = DaemonicThreads::HTTP::HttpRequest.new(mongrel_request, mongrel_response)
    
    panic_on_exception("HTTP request -- Processing", Proc.new { request.error(500, "Daemon encouners an exception"); request.log!(@logger) }) do

      @creatures_mutex.synchronize do
        if @must_terminate
          return request.error(503, "Daemon is in termination sequence now and can't serve your request")
        else
          @thread_group.add Thread.current
        end
      end
      
      request.parse
      
      unless request.correct?
        return request.error(400, "There is a restrictions on how request can be formed")
      end


      action = determine_http_action request
      
      log(:debug) { "HTTP REQUEST -- ACTION: #{action.inspect} FORMAT: #{request.requested_format} PARAMS: #{request.params.inspect}" }
      
      unless respond_to?(action)
        return request.error(404, "There is no such action")
      end
        
      begin
        result = __send__(action, request)
        request.response(result) unless request.response_sent?
        
      rescue Exception => exception
        if ActionController::Base.rescue_responses.has_key?(exception.class.name)
          request.error ActionController::Base.rescue_responses[exception.class.name]
        else
          raise exception
        end
      end
      
    end
  ensure
    panic_on_exception("HTTP request -- Release ActiveRecord connection to pool") { ActiveRecord::Base.clear_active_connections! }
  end

  private
 
  REST_METHODS = {"POST" => "create", "PUT" => "update", "DELETE" => "destroy"}
  
  def determine_http_action request
    
    if request.requested_id 
      if respond_to?(request.requested_id) && !request.requested_action
        action = request.requested_id
      else
        request[:id] = request.requested_id
      end
    end
    
    return action || request.requested_action || REST_METHODS[request.request_method] || (request[:id] ? "show" : "index")  
  end  

end

