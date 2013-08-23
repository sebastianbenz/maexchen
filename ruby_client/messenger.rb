require 'socket' 

class Messenger

  def initialize(port)
   BasicSocket.do_not_reverse_lookup = true
   @client = UDPSocket.new
   @client.bind('0.0.0.0', port)
  end

  def on_message
    while(true)
      data, addr = @client.recvfrom(1024) 
      puts "received: #{data}"
      yield data
    end
  end

  def send(message) 
    puts "sending: #{message}"
    @client.send(message, 0, '127.0.0.1', 9000)
  end

end
