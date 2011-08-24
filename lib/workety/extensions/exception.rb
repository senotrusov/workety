
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
  
  def details
    @details ||= {}
  end
  
  def self.details(msg = nil, details = {})
    ex = new(msg)
    ex.details.merge! details
    ex
  end
  
  def view more_details = {}
    "#{summary_view}\n#{details_view(more_details)}#{backtrace_view}"
  rescue ScriptError, StandardError
    "ERROR CREATING EXCEPTION VIEW"
  end

  def summary_view
    "#{self.class.name}: #{message}"
  end
  
  def details_view more_details = {}
    if (merged_details = details.merge(more_details)).any?
      "Details: #{merged_details.inspect}\n"
    end
  rescue ScriptError, StandardError => exception
    "Details: ERROR CREATING EXCEPTION DETAILS VIEW: #{exception.summary_view}\n#{exception.backtrace_view}\n\n"
  end
  
  def backtrace_view
    ((bt = backtrace) && bt.collect{|line| "\t#{line}\n"}.join("") || "\tBacktrace undefined")
  rescue ScriptError, StandardError => exception
    "\tERROR CREATING BACKTRACE VIEW: #{exception.summary_view}"
  end
  
  
  
  def logger
    Rails.logger
  end
  
  # Airbrake API requires the following elements to be present:
  #   /notice/error/class
  #   /notice/error/backtrace/line
  #   /notice/server-environment/environment-name
  #
  def report! more_details = {}
    
    if ENV['AIRBRAKE_API_KEY'] && Rails.env == "production"
      begin
        response = Toadhopper(ENV['AIRBRAKE_API_KEY']).post!(self, ({:framework_env => Rails.env}).merge(details).merge(more_details))

        raise("Tracker responded with status #{response.status}") if response.status != 200
        
      rescue ScriptError, StandardError => tracker_exception
        logger.error "ERROR: EXCEPTION DOES NOT TRANSFERED TO TRACKER"
        logger.error tracker_exception.view
        logger.error response.body if response
      end
    end      
      
    logger.error view(more_details)
    logger.flush if logger.respond_to?(:flush)
    
  rescue ScriptError, StandardError => logger_exception
    STDERR.write "ERROR: EXCEPTION DOES NOT TRANSFERED TO TRACKER AND/OR LOGGED\n"
    STDERR.write "#{logger_exception.view}\n"
    STDERR.write "#{view(more_details)}\n"
  end
  
  def view! more_details = {}
    STDERR.write "#{view(more_details)}\n"
  end
end


#begin
#  raise StandardError.details("ALARM!", :a=>1)
#rescue => ex
#  puts ex.view
#end 

