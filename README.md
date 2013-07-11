Workety
=======

An infrastructure to create Ruby daemons (workers).

* process start
* terminal detach
* run as user/group (root privileges drop)
* signal handling
* logfile
* pidfile, check for already running daemon
* may restart in case of failure, by forking from watchdog
* may send exceptions to Airbrake and Exceptional
* Rails environment load at late stage
* support for mutithreaded workers
* command-line argument parsing by use of [trollop](http://trollop.rubyforge.org) library.
* simple API for application code, see [examples](https://github.com/senotrusov/workety/tree/master/lib/workety/test)


### Command-line invocation

```
# run daemon
workety -e development start Workety::TestThread --foo=bar
                       ^^^^^ Start as a daemon 
        ^^^^^^^^^^^^^^ Options for Workety       ^^^^^^^^^ Options for class (parsed by class)

# run test thread in console
workety Workety::TestThread
```
