require "socket"

UNIXSocket.open("/tmp/oh_my_sock") {|c|
  c.puts "hello #{Process.pid}"
  c.close
}
