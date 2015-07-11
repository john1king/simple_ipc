require "socket"
require "json"

module IPC
  CHUNK_SIZE = 16 * 1024

  class TransportError < StandardError; end
  class Timeout < TransportError; end
  class ClientError < TransportError; end
  class ServerError < TransportError; end

  class SocketIO

    def initialize(socket, timeout = nil)
      @timeout = timeout
      @socket = socket
    end

    # 通信协议: 前4个字节为消息长度
    def read
      head = readpartial(4)
      raise ClientError, 'Invalid head' if !head || head.size < 4
      body_size = head.unpack('N')[0]
      return '' if body_size == 0
      data = readpartial(body_size)
      unless data && data.size == body_size
        raise ClientError, "Invalid body size, expect #{body_size} but #{data.size}"
      end
      data
    end

    # 读取指定大小的数据或读取到文件末尾，没有读到数据返回 nil
    def readpartial(size, buf = '')
      while size > 0
        data = readblock(size)
        break if data.empty?
        buf << data
        size -= data.size
      end
      buf.empty? ? nil : buf
    end

    def readblock(max_size)
      @socket.recv_nonblock(max_size)
    rescue IO::WaitReadable
      readable = IO.select([@socket], nil, nil, @timeout || 1)
      raise Timeout, 'read timeout' if !readable && @timeout
      retry
    end


    def write(data)
      writepartial [data.size].pack('N')
      writepartial data
    end

    def writepartial(data)
      writed_size = 0
      while writed_size < data.size
        writed_size += writeblock(data[writed_size..-1])
      end
    end

    def writeblock(data)
      @socket.sendmsg_nonblock(data)
    rescue IO::WaitWritable
      writeable = IO.select(nil, [@socket], nil, @timeout || 1)
      raise Timeout, 'write timeout' if !writeable && @timeout
      retry
    end

    def close
      @socket.close
    end

  end

  class Server

    def initialize(addr, options = {})
      @addr = addr
      @server = UNIXServer.new(addr)
      @options = options
      at_exit { File.delete(@addr) if File.exist?(@addr) }
    rescue Errno::EADDRINUSE
      unless server_exist?
        puts "Remove socket file #{@addr}"
        File.delete(@addr)
        retry
      end
      puts "A server is already running."
      raise
    end

    def close
      @server.close if @server
    end

    def server_exist?
      UNIXSocket.new(@addr).close
      true
    rescue Errno::ECONNREFUSED
      false
    end

    def accept
      loop do
        yield SocketIO.new @server.accept, @options[:timeout]
      end
    end

  end

  class Client
    attr_reader :socket

    def self.open(add, options = {})
      client = new(add, options)
      yield client
    ensure
      client.close
    end

    def initialize(addr, options = {})
      @addr = addr
      @socket = SocketIO.new UNIXSocket.new(addr), options[:timeout]
      @options = options
    end

    def send(data)
      @socket.write JSON.dump(data)
    end

    def close
      @socket.close if @socket
    end
  end

end
