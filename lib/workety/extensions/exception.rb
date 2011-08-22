
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


require 'toadhopper'

class Exception
  def logger
    Rails.logger
  end
  
  # Airbrake API requires the following elements to be present:
  #   /notice/error/class
  #   /notice/error/backtrace/line
  #   /notice/server-environment/environment-name
  #
  def report! options = {}, http_headers = {}
    
    if ENV['AIRBRAKE_API_KEY'] && Rails.env == "production"
      begin
        response = Toadhopper(ENV['AIRBRAKE_API_KEY']).post!(self, options.merge(:framework_env => Rails.env), http_headers)

        raise("Tracker responded with status #{response.status}") if response.status != 200
        
      rescue ScriptError, StandardError => tracker_exception
        logger.error "ERROR TRANSFERING EXCEPTION TO TRACKER, the following exceptions are only recorded here:"
        logger.error tracker_exception.details
        logger.error response.body if response
      end
    end      
      
    logger.error self.details(options)
    
    logger.flush if logger.respond_to?(:flush)
    
  rescue ScriptError, StandardError => logger_exception
    logger_exception.display!
    self.display!(options)
  end

  
  def display! options = {}
    STDERR.write details(options) + "\n"
  end
  

  def details options = {}

    title = "Exception#{" " + options[:title] if options[:title]}"
    title = title + "\n" + ("-" * title.length)
    
    options = options.reject {|key, value| key == :title }

    "\n#{title}\n" +
    
    " " + inspect + "\n" +
    
    (options.empty? ? "" : "\nOptions:\n") +
    
      options.keys.collect do |key|
        " #{key.inspect} => \n  " + 
          (options[key].pretty_inspect rescue options[key].inspect rescue "ERROR: Can not pretty-print or inspect").gsub("\n", "\n   ").strip + "\n" 
      end.join("\n") +
    
    "\nBacktrace:\n" +
    
      ((bt = backtrace) && bt.collect{|line|" #{line}\n"}.join("") || "") + "\n"
  end
end

