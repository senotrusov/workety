
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


class Exceptional::DetailsExceptionData < Exceptional::ExceptionData
  def initialize exception
    @exception = exception
    @details   = @exception.details.dup
    @name      = @details.delete(:name)
    @request   = @details[:request].kind_of?(Hash) && @details.delete(:request)
  end
  
  alias_method :context_stuff_orig, :context_stuff
  
  def context_stuff
    data = context_stuff_orig
    
    if @details.any?
      if data['context']
        data['context'].merge! @details
      else
        data['context'] = @details
      end
    end
    
    if @request
      data['request'] = {
        'url'        => @request[:url],
        'controller' => @request[:controller],
        'action'     => @request[:action],
        'parameters' => @request[:params],
        'headers'    => @request[:headers],
        'session'    => @request[:session]
        }
    end
    
    data
  end
end

