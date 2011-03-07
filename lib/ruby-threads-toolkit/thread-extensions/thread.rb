
#  Copyright 2006-2011 Stanislav Senotrusov <senotrusov@gmail.com>
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
  def details
    inspect + "\n" +
    
    "\nThread-local variables:\n" +
    
      self.keys.collect do |key|
        PP.pp(self[key], dump = "") rescue dump = "ERROR: Can not pretty-print"
        " #{key.inspect} => \n  " + dump.gsub("\n", "\n  ").strip + "\n" 
      end.join("\n") +
    
    "\nBacktrace:\n" +
    
      ((bt = backtrace) && bt.collect{|line|" #{line}\n"}.join("") || "") + "\n"
  end
end

