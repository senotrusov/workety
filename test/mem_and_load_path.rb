def mem? title = "Memory usage"
  STDOUT.write "---- #{title} ----\n"  + File.read("/proc/#{Process.pid}/status").split("\n").select{|l|l.match(/VmSize/)}.first.to_s + "\n"
end

def load_path?
  STDOUT.write $LOAD_PATH.join("\n") + "\n"
end

