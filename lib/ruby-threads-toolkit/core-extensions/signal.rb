
module Signal
  def self.threaded_handler(options = {})
    options[:exit_on_error] = true unless options.has_key? :exit_on_error
    
    Proc.new do
      begin 
        
        Thread.new do
          begin
            yield
          rescue Exception => exception
            begin
              exception.log!
            ensure
              Process.exit(false) if options[:exit_on_error]
            end
          end 
        end

      rescue Exception => exception
        begin
          exception.log!
        ensure
          Process.exit(false) if options[:exit_on_error]
        end
      end 
    end
  end
  
  def self.threaded_trap(signal, options = {}, & block)
    trap(signal, & threaded_handler(options, & block))
  end
end

