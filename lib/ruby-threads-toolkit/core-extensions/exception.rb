
#  Copyright 2006-2009 Stanislav Senotrusov <senotrusov@gmail.com>
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
  def inspect_with_backtrace
    inspect + ((bt = backtrace) && ("\n  #{bt.join("\n  ")}\n") || "")
  end
  
  def log! logger, severity = :fatal, title = nil, inspect_method = :inspect_with_backtrace
    logger.__send__(severity, "#{title} -- #{self.__send__(inspect_method)}")
    logger.flush if logger.respond_to?(:flush)
  rescue Exception => logger_exception
    self.display! title, inspect_method
    logger_exception.display! "Trying to log previous exception, another exception was raised", inspect_method
  end
  
  def display! title = nil, inspect_method = :inspect_with_backtrace
    STDERR.puts "#{title} -- #{self.__send__(inspect_method)}"
  end

end
