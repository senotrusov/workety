
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
  
  attr_accessor :details
  
  def self.details(msg = nil, details = {})
    ex = new(msg)
    ex.details = details
    ex
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
        logger.error "ERROR TRANSFERING EXCEPTION TO TRACKER, the following exceptions are only recorded here:"
        logger.error tracker_exception.inspect_details
        logger.error response.body if response
      end
    end      
      
    logger.error self.inspect_details(more_details)
    
    logger.flush if logger.respond_to?(:flush)
    
  rescue ScriptError, StandardError => logger_exception
    logger_exception.display!
    self.display!(more_details)
  end
  
  
  def display! more_details = {}
    STDERR.write inspect_details(more_details) + "\n"
  end
  
  
  def inspect_details more_details = {}
    
    show_details = details.merge(more_details)
    title = ["Exception", show_details.delete(:title)].compact.join(" ")
    title = title + "\n" + ("-" * title.length)
    
    "\n#{title}\n" +
    
    " " + inspect + "\n" +
    
    (show_details.empty? ? "" : "\nDetails:\n") +
    
      show_details.keys.collect do |key|
        " #{key.inspect} => \n  " + 
          (show_details[key].pretty_inspect rescue show_details[key].inspect rescue "ERROR: Can not pretty_inspect or inspect").gsub("\n", "\n   ").strip + "\n" 
      end.join("\n") +
    
    "\nBacktrace:\n" +
    
      ((bt = backtrace) && bt.collect{|line|" #{line}\n"}.join("") || "") + "\n"
  end
end

