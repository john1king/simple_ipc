# 最简单的，不支持持久连接，只能单向通信

require "socket"

SOCKET_FILE = "/tmp/oh_my_sock"

def server_exist?
  UNIXSocket.open(SOCKET_FILE) {|c|
    c.puts "check"
    c.close
  }
  true
rescue Errno::ECONNREFUSED
  false
end


begin
  UNIXServer.open(SOCKET_FILE) {|serv|
    loop do
      s = serv.accept
      puts "accept #{s}"
      string = s.read
      puts string
      s.close
    end
  }
rescue Errno::EADDRINUSE
  unless server_exist?
    puts "Remove #{SOCKET_FILE}"
    File.delete(SOCKET_FILE)
    retry
  end
  puts "A server is already running."
end


