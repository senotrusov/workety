
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


class Thread

  def self.workety(*args)
    new do

      begin
        yield(*args)

      rescue ScriptError, StandardError => exception
        begin
          exception.log!
        ensure
          begin
            Workety.abort
          rescue ScriptError, StandardError => stop_exception
            begin
              stop_exception.log!
            ensure
              Process.exit(false)
            end
          end
        end

    # That ensure block is executed on Thread#kill as well
    ensure 
        begin
          ActiveRecord::Base.clear_active_connections!
        rescue ScriptError, StandardError => exception
          exception.log!
        end
      end

    end
  end
  
  
  def self.networkety(*args)
    workety do
      begin
        yield(*args)
      rescue *(Socket::NETWORK_EXEPTIONS) => exception
        Rails.logger.warn Thread.current.details(:title => "stopped due a network error")

        # If thread is blocked by Socket#read and then are forced to unblock by using Socket#shutdown and then Socket#close methods,
        # that will raise an exception. That exception has no value to set Workety.aborted? flag.
        # Here we suggest that such technique was used if Workety.stop? is set.
        Workety.abort unless Workety.stop? 
      end
    end
  end
  
  
  def details options = {}

    title = "Thread#{" " + options[:title] if options[:title]}"
    title = title + "\n" + ("-" * title.length) 

    "\n#{title}\n" +
    
      " " + inspect + "\n" +
    
    "\nThread-local variables:\n" +
    
      self.keys.collect do |key|
        " #{key.inspect} => \n  " + 
          (self[key].pretty_inspect rescue self[key].inspect rescue "ERROR: Can not pretty-print or inspect").gsub("\n", "\n  ").strip + "\n" 
      end.join("\n") +
    
    "\nBacktrace:\n" +
    
      ((bt = backtrace) && bt.collect{|line|" #{line}\n"}.join("") || "") + "\n"
  end

end

