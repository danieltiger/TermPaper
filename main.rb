require 'rubygems'
require 'pty'
require 'eventmachine'
require 'evma_httpserver'
require 'em-pusher'

class MyHttpServer < EM::Connection
  include EM::HttpServer

  def post_init
    super
   no_environment_strings
  end

  def default
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 404
    response.content_type 'text/html'
    response.content = 'nothing here'
    response.send_response
  end

  def handle_get
    if @http_path_info == "/index.html" or @http_path_info == "/"
      p "starting shell"
      $shell = PTY.spawn('/bin/csh') 
      $r_pty, $w_pty = $shell
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'text/html'
      response.content = File.read('index.html') 
      response.send_response
    else
      default
    end
  end

  def start_shell
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = 'post' 
    response.send_response
  end

  def recv_command
    key_code = @http_post_content.split('=').last.to_i
    $w_pty.print key_code.chr
    $w_pty.flush
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = 'post' 
    response.send_response
  end
  
  def handle_post
    if @http_path_info == "/start"
      start_shell
    else
      recv_command
    end
  end

  def process_http_request
    # the http request details are available via the following instance variables:
    #   @http_protocol
    #   @http_request_method
    #   @http_cookie
    #   @http_if_none_match
    #   @http_content_type
    #   @http_path_info
    #   @http_request_uri
    #   @http_query_string
    #   @http_post_content
    #   @http_headers
    if @http_request_method.downcase == "post"
      handle_post
    else
      handle_get
    end
  end
end


class BufferedPusher
  def initialize(size, &block)
    @blk = block
    @size = size
    @arr = []
  end

  def push(obj)
    p "called push"
    if @arr.length > @size
      p "calling block"
      @blk.call(@arr)
      @arr = []
    end
    @arr << obj
  end
end

$buffered_pusher =  BufferedPusher.new(10) { |buff| $pusher.trigger('shell', { :code => buff }) }

def flush_shell_buffer
  p "flushing buffer"
  $reader = Thread.new {
  while true
    begin
      next if $r_pty.nil?
      c = $r_pty.getc
      if c.nil? then
        Thread.stop
      end
      $buffered_pusher.push(c.chr)
      #print c.chr
    rescue
      Thread.stop
    end
  end
}
end
  


EM.run{
  $pusher = EventMachine::Pusher.new(
    :app_id      => 9118,
    :auth_key    => 'aa94d705bd3fef88df05',
    :auth_secret => '4272f175e71800bd3c90',
    :channel     => 'shell'
  )
  EventMachine::PeriodicTimer.new(5) do
    flush_shell_buffer
  end
  EM.start_server '0.0.0.0', 8080, MyHttpServer
}
