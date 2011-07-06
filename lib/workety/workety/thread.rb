
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
          Workety.stop
        end

      ensure
        begin
          ActiveRecord::Base.clear_active_connections!
        rescue ScriptError, StandardError => exception
          exception.log!
        end
      end

    end

  end
end

