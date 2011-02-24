
#  Copyright 2006-2008 Stanislav Senotrusov <senotrusov@gmail.com>
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


module AccessorsGenerator
  def generate_accessors(args)

    attrs = args.last.kind_of?(Hash) ? args.pop : {}
    
    args.each {|arg| attrs[arg] = nil }
    
    attrs.each do |attr, default_class|
      if (access_methods = yield(attr, default_class))
        class_eval access_methods[:code],
                   access_methods[:file],
                   access_methods[:line]
      end
    end
  end
end
