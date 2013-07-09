Workety
=======

Run ruby code as a worker.

* may run as a daemon
* run as a user/group
* signal handling
* logfile
* pidfile
* may restart in case of failure, by forking from watchdog
* may use multithreading
* may send exceptions to an external tracker
* rails environment load at a late stage
* command-line argument parsing by use of [trollop](http://trollop.rubyforge.org) library
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
