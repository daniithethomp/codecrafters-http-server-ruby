require "socket"

# You can use print statements as follows for debugging, they'll be visible when running tests.
print("Logs from your program will appear here!")

server = TCPServer.new("localhost", 4221)
client_socket, client_address = server.accept

known_paths = ["/","echo"]

while line = client_socket.gets
    puts line.split
    method, path, version = line.split
    if known_paths.include? path then
        client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
    elsif known_paths.include? path.split("/")[1] then
        status = "HTTP/1.1 200 OK\r\n"
        body = path.split("/").last.strip
        header = "Content-Type: text/plain\r\nContent-Length: #{body.length}\r\n\r\n"
        client_socket.puts "#{status}#{header}#{body}"
    else
        client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
    end
end