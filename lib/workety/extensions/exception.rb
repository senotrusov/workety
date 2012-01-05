
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


class Exception
  
  def details
    @details ||= {}
  end
  
  # begin
  #   raise StandardError.details("ALARM!", :a=>1)
  # rescue => ex
  #   puts ex.view
  # end
  #
  def self.details message = nil, details = {}
    if message.kind_of? Hash
      message, details = nil, message
    end
    
    ex = new message
    ex.details.merge! details
    ex
  end
  
  def view!
    STDERR.write "#{view}\n"
  end

  def view
    [summary_view, details_view, backtrace_view].compact.join("\n")
  rescue ScriptError, StandardError
    "ERROR CREATING EXCEPTION VIEW"
  end

  def summary_view
    "#{self.class.name}: #{message}"
  end
  
  def details_view
    "Details: #{details.inspect}" if details.any?
  rescue ScriptError, StandardError => ex
    "Details: ERROR CREATING DETAILS VIEW:\n" \
    "#{ex.summary_view}\n" \
    "#{ex.backtrace_view}"
  end
  
  def backtrace_view
    ((bt = backtrace) && bt.collect{|line|"\t#{line}\n"}.join("") || "\tBacktrace undefined")
  rescue ScriptError, StandardError => ex
    "\tERROR CREATING BACKTRACE VIEW: #{ex.summary_view}"
  end
  
  
  # The following methods should not be called before Rails initialization.
   
  def logger
    Rails.logger
  end
  
  def report!
    log!
    report_to_trackers! if Rails.env == "production"
  end
  
  def report_to_trackers!
    report_to_exceptional! if defined?(Exceptional)
    report_to_airbrake! if defined?(Toadhopper)
  end
  
  def log!
    logger.error view
    logger.flush if logger.respond_to? :flush
  rescue ScriptError, StandardError => ex
    STDERR.write "ERROR: LOGGING ANOTHER EXCEPTION THE FOLLOWING EXCEPTION OCCURED:\n" \
                 "#{ex.view}\n" \
                 "THE FOLLOWING EXCEPTION WAS NOT STORED IN LOG:\n" \
                 "#{view}\n"
  end
  
  
  def report_to_exceptional!
    Exceptional::Remote.error Exceptional::DetailsExceptionData.new(self)
    Exceptional.context.clear!
  rescue ScriptError, StandardError => ex
    ex.log!
  end
  
  
  # Airbrake API requires the following elements to be present:
  #   /notice/error/class
  #   /notice/error/backtrace/line
  #   /notice/server-environment/environment-name
  #
  def report_to_airbrake!
    File.readable?(file = Rails.root + 'config' + 'airbrake.yml') &&
      (yaml = YAML.load_file file).kind_of?(Hash) &&
      (api_key = yaml["api-key"]).kind_of?(String) ||
      raise("Unable to read Airbrake api key from #{file}")
    
    options = if details[:request].kind_of? Hash
      params = details.dup
      request = params.delete :request
      
      { url:           request[:url],
        component:     request[:controller],
        action:        request[:action],
        params:        (request[:params] || {}).merge(params),
        session:       request[:session],
        framework_env: Rails.env }
      
    else
      { params:        details,
        framework_env: Rails.env }
    end
    
    response = Toadhopper(api_key).post!(self, options)
    
    if response.status != 200
      raise StandardError.details("Tracker responded with status #{response.status}", body: response.body)
    end
    
  rescue ScriptError, StandardError => ex
    ex.log!
  end
end

