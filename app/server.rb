require "socket"

HTTP_STATUS = {200 => "OK", 404 => "Not Found" }

server = TCPServer.new("localhost", 4221)
client_socket, client_address = server.accept

def read_lines(client)
    lines = []
    while (line = client.gets) != "\r\n"
        lines << line.chomp
    end
    lines
end

def parse_request(request_lines)
    method, path, version = request_lines.first.split
    request_hash = { method: method, path: path }
    request_lines.drop(1).each do |header|
        key, value = header.split(":", 2).map(&:strip)
        request_hash[key] = value
    end
    request_hash
end

def generate_response(request)
    method = request[:method]
    path = request[:path]
    headers = { "Content-Type" => "text/plain" }
    case[method, path]
    in ["GET", "/"]
        [200, headers, []]
    in ["GET",%r{^/echo/(.*)$}]
        echo_message = path.split("/").last
        headers["Content-Length"] = echo_message.length.to_s
        [200, headers, echo_message]
    in ["GET", "/user-agent"]
        body = request.fetch("User-Agent","")
        headers["Content-Length"] = body.length.to_s
        [200,headers,body]
    else
        [404, headers, []]
    end
end

def pretty_response(response)
    puts response
    status, headers, body = response
    str = "HTTP/1.1 #{status} #{HTTP_STATUS[status]}"
    str += "\r\n"
    headers.each do |key, value|
        str += "#{key}: #{value}"
        str += "\r\n"
    end
    str += "\r\n"
    unless body.empty? then
        str += body
        str += "\r\n"
    end
    str
end
            
request_lines = read_lines(client_socket)
headers = parse_request(request_lines)
response = generate_response(headers)
client_socket.puts pretty_response(response)

client_socket.close