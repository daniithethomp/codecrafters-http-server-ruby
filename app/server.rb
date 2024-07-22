require "socket"

# You can use print statements as follows for debugging, they'll be visible when running tests.
print("Logs from your program will appear here!")

server = TCPServer.new("localhost", 4221)
client_socket, client_address = server.accept

while line = client_socket.gets
    client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
end