# Workety

A library to run Ruby classes as daemons.

* process start
* terminal detach
* run as a user/group (root privileges drop)
* signal handling
* logfile
* pidfile, check for already running daemon
* may restart in a case of failure, by forking from watchdog
* may send exceptions to Airbrake and Exceptional
* Rails environment load at a late stage
* support for mutithreaded workers
* command-line argument parsing by use of the [trollop](http://trollop.rubyforge.org) library
* simple API for an application code


### Command-line invocation

```sh
# run a daemon
workety -e development start Workety::SimpleThread --foo=bar
#                      ^^^^^ Start as a daemon
#       ^^^^^^^^^^^^^^ Options for Workety         ^^^^^^^^^ Options for the class

# run a thread in the console
workety Workety::SimpleThread
```

### SimpleThread example

```ruby
class SimpleThread
  # Before dropping privileges
  def initialize
  end

  # After changing privileges to some user/group
  def start
    @t = Thread.workety do
      until Workety.must_stop? do
        sleep 1
      end
    end

    Thread.workety do
      sleep 10
      Workety.stop
    end
  end

  def join
    @t.join
  end

  def stop
    @t.kill
  end
end
```

### GracefulStopThread example

```ruby
class GracefulStopThread
  # Before dropping privileges
  def initialize
    @mutex = Mutex.new
    @wakeup = ConditionVariable.new
  end

  # After changing privileges to some user/group
  def start
    @worker = Thread.workety do
      @mutex.synchronize do
        until Workety.must_stop? do

          puts "Hello"

          @wakeup.wait(@mutex, 10)
        end
      end
    end
  end

  def join
    @worker.join
  end

  def stop
    @mutex.synchronize do
      @wakeup.signal
    end
  end
end
```


## Copyright and License

```
Copyright 2006-2011 Stanislav Senotrusov

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Contributing

Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.
