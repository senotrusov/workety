
#  Copyright 2006-2009 Stanislav Senotrusov <stan@senotrusov.com>
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


module MutexedAccessors
  include AccessorsGenerator
  
  def mutexed_accessors(*args)
    generate_accessors(args) do |attr, mutex|
      attr = attr.to_s
      {:line => (__LINE__+1), :file => __FILE__, :code => <<-EOS
          def #{attr}
            @#{mutex}.synchronize { @#{attr} }
          end
          
          def #{attr}= value
            @#{mutex}.synchronize { @#{attr} = value}
          end
        EOS
      }
    end
  end
end
