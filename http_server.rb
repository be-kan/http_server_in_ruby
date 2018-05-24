require 'socket'
require_relative 'sample_blog/config/environment'

app = Rack::Lint.new(Rails.application)
server = TCPServer.new 5678

while session = server.accept
  request = session.gets
  puts request

  method, full_path = request.split(' ')
  path, query = full_path.split('?')

  headers = {}
  while (line = session.gets) != "\r\n"
    key, value = line.split(':', 2)
    headers[key] = value.strip
  end

  body = session.read(headers["Content-Length"].to_i)

  status, headers, body = app.call({
    'REQUEST_METHOD' => method,
    'PATH_INFO' => path,
    'QUERY_STRING' => query || '',
    'SERVER_NAME' => 'localhost',
    'SERVER_PORT' => '5678',
    'REMOTE_ADDR' => '127.0.0.1',
    'HTTP_COOKIE' => headers['Cookie'],
    'rack.version' => [1,3],
    'rack.input' => StringIO.new(body),
    'rack.errors' => $stderr,
    'rack.multithread' => false,
    'rack.multiprocess' => false,
    'rack.run_once' => false,
    'rack.url_scheme' => 'http'
  })

  session.print "HTTP/1.1 #{status}\r\n"
  headers.each do |key, value|
    session.print "#{key}: #{value}\r\n"
  end
  session.print "\r\n"
  body.each do |part|
    session.print part
  end
  session.close
end
