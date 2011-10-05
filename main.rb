require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'em-http-request'

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
      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.content_type 'text/html'
      response.content = File.read('index.html') 
      response.send_response
    else
      default
    end
  end

  def handle_post
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = 'post' 
    response.send_response
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

EM.run{
  EM.start_server '0.0.0.0', 8080, MyHttpServer
}
