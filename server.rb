# 最简单的，不支持持久连接，只能单向通信

require "socket"

SOCKET_FILE = "/tmp/oh_my_sock"

def server_exist?
  UNIXSocket.new(SOCKET_FILE).close
  true
rescue Errno::ECONNREFUSED
  false
end


class Timeout < StandardError
end

begin
  server = UNIXServer.new(SOCKET_FILE)
  at_exit {
    puts "Exit"
    File.delete(SOCKET_FILE) if File.exist?(SOCKET_FILE)
  }
  loop do
    socket = server.accept
    puts "accept #{socket}"
    t = Time.now
    while true
      buf = ''
      begin
        data = socket.recv_nonblock(5)
        if data.empty?
          break
        else
          buf << data
        end
      rescue IO::WaitReadable
        x = Time.now
        results = IO.select([socket], nil, nil, 3)
        raise Timeout, 'read timeout' unless results
      end
    end
    puts "used #{Time.now - t}"
    puts buf
    socket.close
  end
rescue Errno::EADDRINUSE
  unless server_exist?
    puts "Remove #{SOCKET_FILE}"
    File.delete(SOCKET_FILE)
    retry
  end
  puts "A server is already running."
ensure
  server.close if server
end
