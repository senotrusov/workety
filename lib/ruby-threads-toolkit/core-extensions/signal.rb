
module Signal
  def self.threaded_handler(exit_on_error = true)
    Proc.new do
      begin 
        
        Thread.new do
          begin
            yield
          rescue Exception => exception
            begin
              exception.log!
            ensure
              Process.exit(false) if exit_on_error
            end
          end 
        end

      rescue Exception => exception
        begin
          exception.log!
        ensure
          Process.exit(false) if exit_on_error
        end
      end 
    end
  end
  
  def self.threaded_trap(signal, exit_on_error = true, & block)
    trap(signal, & threaded_handler(exit_on_error, & block))
  end
end

