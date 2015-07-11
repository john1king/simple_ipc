require "socket"

UNIXSocket.open("/tmp/oh_my_sock") {|c|
  t = Time.now
  c.puts "hello #{Process.pid}"
  sleep 10
  c.close
  puts Time.now - t
}
