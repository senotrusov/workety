
#  Copyright 2009 Stanislav Senotrusov <senotrusov@gmail.com>
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


#  Copyright (c) 2004-2009 David Heinemeier Hansson
#
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject to
#  the following conditions:
#
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


class DaemonicThreads::HTTP::HttpRequest

  # initialize() happens outside daemon exception handling, so it must be lightweight.
  # More robust processing goes to parse()
  # Mongrel handles exceptions too, but it does not logs request details.
  #
  def initialize request, response
    @request = request
    @response = response
    
    @mutex = Mutex.new
  end

  attr_reader :params, :mutex
  
  def [] param
    @params[param]
  end
  
  def []= param, value
    @params[param] = value
  end

  def env
    @request.params
  end
  
  def body
    @mutex.synchronize do
      result = @request.body.read(@request.params["CONTENT_LENGTH"].to_i)
      @request.body.rewind if @request.body.respond_to?(:rewind)
      result
    end
  end
  
  def parse
    @params = parse_rails_style_params
    parse_path_info
  end
  
  private
  
  def parse_rails_style_params
    result = {}
    
    result.update(Rack::Utils.parse_nested_query @request.params["QUERY_STRING"]) if @request.params["QUERY_STRING"]
    result.update(parse_body_params) if @request.params["CONTENT_LENGTH"].to_i > 0 
    
    normalize_parameters(result)
  end
  
  
  # based on ActionController::ParamsParser
  #
  # TODO: Handle form data from POST (look at rack/request.rb, def POST, rescue EOFError)
  def parse_body_params
    case Mime::Type.lookup @request.params["CONTENT_TYPE"]
      when Mime::XML
        data = body
        data.blank? ? {} : Hash.from_xml(data)

      when Mime::JSON
        data = body
        if data.blank?
          {}
        else
          data = ActiveSupport::JSON.decode(data)
          data = {:_json => data} unless data.is_a?(Hash)
          data
        end
    end
  end
  
  
  # based on ActionController::Request
  #
  # Convert nested Hashs to HashWithIndifferentAccess and replace
  # file upload hashs with UploadedFile objects
  def normalize_parameters(value)
    case value
    when Hash
      if value.has_key?(:tempfile)
        upload = value[:tempfile]
        upload.extend(UploadedFile)
        upload.original_path = value[:filename]
        upload.content_type = value[:type]
        upload
      else
        h = {}
        value.each { |k, v| h[k] = normalize_parameters(v) }
        h.with_indifferent_access
      end
    when Array
      value.map { |e| normalize_parameters(e) }
    else
      value
    end
  end


  # based on ActionController::Base
  def normalize_status_code status_code
    status_code.kind_of?(Fixnum) ? status_code : ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE[status_code] 
  end

  
  REQUESTED_FORMAT_RE = /\.([\w\d]+)\z/

  #  "" ("/foobars")
  #  ".xml" ("/foobars.xml")
  #  "/0001" ("/foobars/0001")
  #  "/0001.xml" ("/foobars/0001.xml")
  #  "/0001/action" ("/foobars/0001/action")
  #  "/0001/action.xml" ("/foobars/0001/action.xml")
  #
  #  This is the edge case for URI parsing.
  #  For now action really goes to @requested_id, and we checks controller for respond_to?(@requested_id)
  #  If you are using short alphanumeric ids they can be clashed with some method name.
  # 
  #  "/action" ("/foobars/0001/action")
  #  "/action.xml" ("/foobars/0001/action.xml")
  #
  def parse_path_info
    #  "".split(/\//)
    #  ".xml".split(/\//)
    #  "/0001".split(/\//)
    #  "/0001.xml".split(/\//)
    #  "/0001/action".split(/\//)
    #  "/0001/action.xml".split(/\//)
    splitted = @request.params["PATH_INFO"].split(/\//)
    
    if matched_format = splitted.last.match(REQUESTED_FORMAT_RE)
      @requested_format = Mime::Type.lookup_by_extension(matched_format[1]) # nil or string
      splitted.last.gsub!(REQUESTED_FORMAT_RE, '')
    end
  
    @requested_id = splitted[1] # nil or string
    @requested_action = splitted[2] # nil or string
  end
  
  
  public
  
  attr_reader :requested_format, :requested_id, :requested_action # nil or string
  
  def correct?
    [Mime::XML, Mime::JSON, nil].include?(requested_format) &&
    (@requested_id.nil? || !@requested_id.blank?) &&
    (@requested_action.nil? || !@requested_action.blank?)
  end
  
  def request_method
    @request.params["REQUEST_METHOD"]
  end

  def head?
    @request.params["REQUEST_METHOD"] == "HEAD"
  end
  
  def get?
    @request.params["REQUEST_METHOD"] == "GET"
  end

  def post?
    @request.params["REQUEST_METHOD"] == "POST"
  end
  
  def put?
    @request.params["REQUEST_METHOD"] == "PUT"
  end
  
  def delete?
    @request.params["REQUEST_METHOD"] == "DELETE"
  end
  

  def log! logger, severity = :fatal, title = nil
    logger.__send__(severity, "#{title} -- #{self.inspect rescue "EXCEPTION CALLING inspect()"}\n -- Request body: #{body.inspect rescue "EXCEPTION CALLING body()"}")
    logger.flush if logger.respond_to?(:flush)
  end


  def response_sent?
    @mutex.synchronize do
      @response_sent
    end
  end  


  def error(status, body = nil)
    @mutex.synchronize do
      return if @response_sent
      @response_sent = true

      @response.start(normalize_status_code status) do |head, out|
        head["Content-Type"] = "text/plain"
        out.write("ERROR: #{body || status}")
      end
    end
  end
  
  
  # Based on ActionController::Base
  #
  # Return a response that has no content (merely headers). The options
  # argument is interpreted to be a hash of header names and values.
  # This allows you to easily return a response that consists only of
  # significant headers:
  #
  #   request.head :created, :location => url_for(person)
  #
  # It can also be used to return exceptional conditions:
  #
  #   return request.head(:method_not_allowed) unless request.post?
  #   return request.head(:bad_request) unless valid_request?
  #
  def head(*args)
    if args.length > 2
      raise ArgumentError, "too many arguments to head"
    elsif args.empty?
      raise ArgumentError, "too few arguments to head"
    end
    
    options = args.extract_options!
    
    status_code = normalize_status_code(args.shift || options.delete(:status) || :ok)

    @mutex.synchronize do
      raise(DaemonicThreads::HTTP::DoubleResponseError, "Can only response once per request") if @response_sent
      @response_sent = true

      @response.start(status_code) do |head, out|
        options.each do |key, value|
          head[key.to_s.dasherize.split(/-/).map { |v| v.capitalize }.join("-")] = value.to_s
        end
      end
    end

  end

  
  # Based on ActionController::Base
  #
  # response object||string [, options]
  # response :xml => object||string [, options]
  # response :json => object||string [, options]
  # response :text => string [, options]
  # 
  # Options
  #   :status
  #   :location
  #   :callback
  #   :content_type
  #
  # TODO: response :update do
  # TODO: response :js =>
  # TODO: response :file => filename [, options] 
  #
  def response options, extra_options = {}
  
    if options.kind_of?(Hash)
      options.update(extra_options)

      if data = options[:xml]
        format = Mime::XML
      elsif data = options[:json]
        format = Mime::JSON 
      elsif data = options[:text]
        data = data.to_s
        format = Mime::HTML 
      else
        raise "You must response with something!"
      end
    else
      data = options
      options = extra_options
      
      if requested_format
        format = requested_format
      elsif data.kind_of?(String)
        format = Mime::HTML
      else
        format = Mime::XML
      end
    end
    
    raise "You force response format `#{format}' but user requests `#{requested_format}'" if format && requested_format && format != requested_format
    
    case format
      when Mime::XML
        data = data.to_xml unless data.kind_of?(String)
      when Mime::JSON
        data = data.to_json unless data.kind_of?(String)
        data = "#{options[:callback]}(#{data})" unless options[:callback].blank?
    end
    

    status_code = normalize_status_code(options[:status] || :ok)

    if location = options[:location]
      location = url_for(location) unless location.kind_of?(String)
    end

    @mutex.synchronize do
      raise(DaemonicThreads::HTTP::DoubleResponseError, "Can only response once per request") if @response_sent
      @response_sent = true

      @response.start(status_code) do |head, out|
        head["Location"] = location if location
        head["Content-Type"] = (options[:content_type] || format).to_s
        
        unless head?
          Rails.logger.debug { "HTTP RESPONSE:\n#{data}" }
          out.write(data)
        end
         
      end
    end
  end
  
  
  # Based on ActionController::Base
  # 
  # url_for [Object respond_to?(:id)], options
  #
  #   :controller -- full absolute path, can be found in .uri()
  #   :id
  #   :action
  #   :format
  #
  # Without any options it returns full URL of current controller
  #
  def url_for options = {}, extra_options = {}

    options = {:id => options.id} unless options.kind_of?(Hash)
    options.update(extra_options)
    
    url = "http://#{env["HTTP_HOST"]}"
    url += options[:controller] ? options[:controller] : env["SCRIPT_NAME"]
    url += "/#{options[:id]}" if options[:id]
    url += "/#{options[:action]}" if options[:action]
    url += ".#{options[:format]}" if options[:format]
    url
  end

end

