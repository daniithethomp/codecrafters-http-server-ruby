require "socket"

# You can use print statements as follows for debugging, they'll be visible when running tests.
print("Logs from your program will appear here!")

server = TCPServer.new("localhost", 4221)
client_socket, client_address = server.accept

known_paths = ["/"]

while line = client_socket.gets
    method, path, version = line.split
    puts method
    puts path
    puts version
    if known_paths.include? path then
        client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
    else
        client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
    end
end