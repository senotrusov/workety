
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


module Signal
  def self.threaded_handler(options = {})
    options[:exit_on_error] = true unless options.has_key? :exit_on_error
    
    Proc.new do
      begin 
        
        Thread.new do
          begin
            yield
          rescue ScriptError, StandardError => exception
            begin
              exception.log!
            ensure
              Process.exit(false) if options[:exit_on_error]
            end
          end 
        end

      rescue ScriptError, StandardError => exception
        begin
          exception.log!
        ensure
          Process.exit(false) if options[:exit_on_error]
        end
      end 
    end
  end
  
  def self.threaded_trap(signal, options = {}, & block)
    trap(signal, & threaded_handler(options, & block))
  end
end

