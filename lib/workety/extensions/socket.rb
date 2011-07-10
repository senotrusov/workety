
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



require 'socket'

# rescue *(Socket::NETWORK_EXEPTIONS) => exception

class Socket
  NETWORK_EXEPTIONS = [
    IOError,
    EOFError,
    Errno::EBADF,
    Errno::ECONNRESET,
    Errno::ECONNREFUSED,
    Errno::EPIPE,
    Errno::ETIMEDOUT,
    Errno::EHOSTUNREACH,
    Errno::ESHUTDOWN,
    Errno::ENETDOWN,
    Errno::ENETUNREACH,
    Errno::ENETRESET,
    Errno::EIO,
    Errno::EHOSTDOWN,
    Errno::ECONNABORTED]
  
  # At least Windows XP does not have it
  NETWORK_EXEPTIONS.push(Errno::EPROTO) if defined?(Errno::EPROTO)
  NETWORK_EXEPTIONS.push(Errno::ECOMM)  if defined?(Errno::ECOMM)
end

