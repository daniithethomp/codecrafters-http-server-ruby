require "socket"
require "optparse"


HTTP_STATUS = {200 => "OK", 404 => "Not Found", 201 => "Created" }

OPTIONS = {}

ACCEPTED_ENCODING = ["gzip"]

OptionParser.new do |opts|
    opts.on("--directory DIRECTORY", "file directory") do |dir|
        path = Pathname(dir)
        raise OptionParser::InvalidArgument unless path.exist? && path.directory?
        OPTIONS[:directory] = dir
    end
end.parse!

def read_lines(client)
    header = []
    while (line = client.gets) != "\r\n"
        header << line.chomp
    end
    header
end

def parse_request(request_lines)
    method, path, version = request_lines.first.split
    request_hash = { method: method, path: path }
    request_lines.drop(1).each do |header|
        key, value = header.split(":", 2).map(&:strip)
        request_hash[key] = value
    end
    puts request_hash
    request_hash
end

def generate_response(request,client)
    method = request[:method]
    path = request[:path]
    headers = { "Content-Type" => "text/plain" }
    if request.include? "Accept-Encoding" and ACCEPTED_ENCODING.include? request["Accept-Encoding"] then
        headers["Content-Encoding"] = request["Accept-Encoding"]
    end
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
    in ["GET", %r{^/files/(.*)$}]
        filename = path.split("/").last
        file = File.join(OPTIONS[:directory],filename)
        if File.exist? file then
            file = File.open(file)
            headers["Content-Type"] = "application/octet-stream"
            headers["Content-Length"] = file.size
            body = file.read()
            [200,headers,body]
        else
            [404, headers, []]
        end
    in ["POST",%r{^/files/(.*)$}]
        filename = path.split("/").last
        file = File.join(OPTIONS[:directory], filename)
        length = request["Content-Length"]
        body = client.read(length.to_i)
        File.open(file,'w')
        File.write(file,body)
        [201, headers, []]
    else
        [404, headers, []]
    end
end

def pretty_response(response)
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

server = TCPServer.new("localhost", 4221)
loop do
    Thread.start(server.accept) do |client_socket, client_address|               
        header_lines = read_lines(client_socket)
        headers = parse_request(header_lines)
        response = generate_response(headers,client_socket)
        client_socket.puts pretty_response(response)
    end
end

client_socket.close