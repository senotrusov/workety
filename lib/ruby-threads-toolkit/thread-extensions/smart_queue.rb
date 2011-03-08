
#  Copyright 2006-2009 Stanislav Senotrusov <stan@senotrusov.com>
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


class SmartQueue
  def initialize
    @mutex = Mutex.new

    @arrived = ConditionVariable.new
    @shifted = ConditionVariable.new

    @regular = []
    @priority = []

    @regular_limit = nil
    
    @stop_list = {}
  end
  
  def config= config
    self.regular_limit = config["regular_limit"].to_i if config["regular_limit"]
  end
  
  def regular_limit= limit
    @mutex.synchronize do
      @regular_limit = limit
    end
  end

  def release_blocked thread
    @mutex.synchronize do
      # Cleaning up @stop_list right here, so, at maximum, it holds only one dead thread.
      running_threads = Thread.list
      @stop_list.delete_if {|some_thread, flag| !running_threads.include?(some_thread)}
      
      @stop_list[thread] = true
      
      @arrived.broadcast
      @shifted.broadcast
    end
  end
  
  
  # ---- ENQUEUE ----
  
  def push message, priority = true
    enqueue priority, :push, message
  end

  def concat messages, priority = true
    enqueue priority, :concat, messages
  end

  def enqueue priority, action, data
    @mutex.synchronize do
      if priority
        @priority.__send__(action, data)
      else
        @shifted.if_wait_while(@mutex) { @regular_limit && @regular.length >= @regular_limit && !@stop_list.include?(Thread.current) }

        if @stop_list.include?(Thread.current)
          @stop_list.delete(Thread.current)
        end
        @regular.__send__(action, data)
      end
    
      @arrived.signal
    end
  end
  

  # ---- DEQUEUE ----
  
  def shift
    result = nil
    
    @mutex.synchronize do
      @arrived.if_wait_while(@mutex) { @priority.empty? && @regular.empty? && !@stop_list.include?(Thread.current) }
      
      if @stop_list.include?(Thread.current)
        @stop_list.delete(Thread.current)
        
      elsif @priority.empty?
        @shifted.signal
        result = @regular.shift
        
      else
        result = @priority.shift
        
      end
    end
    
    if block_given? && result
      begin
        yield(result)
      rescue Exception => exception # TODO
        begin
          self.push(result, false)
        rescue Exception => handler_exception # TODO
          handler_exception.log!(Rails.logger, :fatal, "#{self.class} shift rollback")
        ensure
          raise exception
        end
      end
    end
    
    result
  end
  
  def select
    @mutex.synchronize do
      result = []

      unless @priority.empty?
        @priority.reject! { |item| result.push(item) if yield(item) }
      end
      
      unless @regular.empty?
        @shifted.signal if @regular.reject! { |item| result.push(item) if yield(item) }
      end

      return result
    end
  end

  def flush
    result = []

    @mutex.synchronize do
      unless @priority.empty?
        result += @priority
        @priority.clear
      end
      
      unless @regular.empty?
        result += @regular
        @regular.clear
        @shifted.signal
      end
    end

    if block_given? && result.length
      begin
        yield(result)
      rescue Exception => exception # TODO
        begin
          self.concat(result, false)
        rescue Exception => handler_exception # TODO
          handler_exception.log!(Rails.logger, :fatal, "#{self.class} flush rollback")
        ensure
          raise exception
        end
      end
    end
    
    result
  end
  
  def empty?
    @mutex.synchronize do
      @regular.empty? && @priority.empty?
    end
  end
end

