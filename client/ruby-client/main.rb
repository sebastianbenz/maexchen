load 'client.rb'

Client.create(ARGV[0], ARGV[1]).register.start
