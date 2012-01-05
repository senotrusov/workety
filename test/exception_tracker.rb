begin
  raise StandardError.details("ALARM!2", :foo => "bar", :name => "NAAME")
rescue => ex
  ex.log!
  ex.report_to_exceptional!
  #ex.report_to_airbrake!
end
