
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


require 'etc'

module Process

  # Drop privilegies and chown logfile
  #
  # http://timetobleed.com/5-things-you-dont-know-about-user-ids-that-will-destroy-you/
  # http://www.ruby-forum.com/topic/110492
  #
  def self.change_privilegies user, group
    user = user ? Etc.getpwnam(user) : Etc.getpwuid(Process.euid)
    group = group ? Etc.getgrnam(group) : Etc.getgrgid(user.gid)
    
    Rails.logger.chown_logfile(user.uid, group.gid) if Rails.logger.respond_to?(:chown_logfile)
    
    Process.initgroups(user.name, group.gid)
    
    Process::GID.change_privilege(group.gid) 
    Process::UID.change_privilege(user.uid)
  end
end

