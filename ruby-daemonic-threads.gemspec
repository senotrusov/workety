# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby-daemonic-threads}
  s.version = "1.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Stanislav Senotrusov"]
  s.date = %q{2009-08-06}
  s.email = %q{senotrusov@gmail.com}
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["README", "LICENSE", "lib/ruby-daemonic-threads", "lib/ruby-daemonic-threads/config.rb", "lib/ruby-daemonic-threads/patches", "lib/ruby-daemonic-threads/patches/timezone.rb", "lib/ruby-daemonic-threads/prototype.rb", "lib/ruby-daemonic-threads/http.rb", "lib/ruby-daemonic-threads/runner.rb", "lib/ruby-daemonic-threads/process.rb", "lib/ruby-daemonic-threads/queues.rb", "lib/ruby-daemonic-threads/daemons.rb", "lib/ruby-daemonic-threads/http", "lib/ruby-daemonic-threads/http/server.rb", "lib/ruby-daemonic-threads/http/request.rb", "lib/ruby-daemonic-threads/http/daemon.rb", "lib/ruby-daemonic-threads.rb"]
  s.homepage = %q{http://github.com/senotrusov}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Create multithreaded applications with smart persistent internal queues, WEB/REST interface, exception handling and recovery}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mongrel>, [">= 0"])
      s.add_runtime_dependency(%q<senotrusov-ruby-toolkit>, [">= 0"])
      s.add_runtime_dependency(%q<senotrusov-ruby-threading-toolkit>, [">= 0"])
      s.add_runtime_dependency(%q<senotrusov-ruby-process-controller>, [">= 0"])
    else
      s.add_dependency(%q<mongrel>, [">= 0"])
      s.add_dependency(%q<senotrusov-ruby-toolkit>, [">= 0"])
      s.add_dependency(%q<senotrusov-ruby-threading-toolkit>, [">= 0"])
      s.add_dependency(%q<senotrusov-ruby-process-controller>, [">= 0"])
    end
  else
    s.add_dependency(%q<mongrel>, [">= 0"])
    s.add_dependency(%q<senotrusov-ruby-toolkit>, [">= 0"])
    s.add_dependency(%q<senotrusov-ruby-threading-toolkit>, [">= 0"])
    s.add_dependency(%q<senotrusov-ruby-process-controller>, [">= 0"])
  end
end
