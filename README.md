Workety
=======

Run ruby code as a worker.

* may run as daemon
* run as user/group
* signal handling
* logfile
* pidfile
* may restart in case of failure, by forking from watchdog
* may use multithreading
* may send exceptions to external tracker
* rails environment load at late stage
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
