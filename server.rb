
require "socket"
# 最简单的，不支持持久连接


UNIXServer.open("/tmp/oh_my_sock") {|serv|
  loop do
    s = serv.accept
    puts "accept #{s}"
    string = s.read
    puts string
    s.close
  end
}
