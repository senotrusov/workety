
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
  def logger
    Rails.logger
  end

  def log! options = {}
  
    if defined?(HOPTOAD_API_KEY) && defined?(Toadhopper) && Rails.env == "production"
      begin
        Toadhopper(HOPTOAD_API_KEY).post!(self, options.dup)
      rescue Exception => hoptoad_exception
        logger.error hoptoad_exception.details
      end
    end
    
    logger.error self.details(options)
    
    logger.flush if logger.respond_to?(:flush)
    
  rescue Exception => logging_exception
    logging_exception.display!
    self.display!(options)
  end
  
  def display! options = {}
    STDERR.write details(options) + "\n"
  end

  def details options = {}

    title = "Exception#{" " + options[:title] if options[:title]}"
    title = title + "\n" + ("-" * title.length) 

    "\n#{title}\n" +
    
    " " + inspect + "\n" +
    
    "\nOptions:\n" +
    
      options.keys.collect do |key|
        " #{key.inspect} => \n  " + 
          (options[key].pretty_inspect rescue options[key].inspect rescue "ERROR: Can not pretty-print or inspect").gsub("\n", "\n   ").strip + "\n" 
      end.join("\n") +
    
    "\nBacktrace:\n" +
    
      ((bt = backtrace) && bt.collect{|line|" #{line}\n"}.join("") || "") + "\n"
  end
end

