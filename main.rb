#!/usr/bin/ruby

# main.rb
# Contains the code to be executed

require 'irc_server.rb'

PingTimeout = 120	# 2 minutes per ping request
UpdateDelay = 0.1	# 10 updates per second
serv = IRCServer::new("RubyServ")
lastping = PingTimeout

begin
	while (true)
		serv.update
		sleep(UpdateDelay)
		lastping -= UpdateDelay
		if (lastping <= 0)
			lastping = PingTimeout
			serv.users.each_value do |this|
				if (!this.nil?)
					this.pingreq
				end
			end
		end
	end
rescue Interrupt
	serv.shutdown("Server process interrupted")
	puts "&&& Interrupt"
rescue Exception => err
	puts "@@@ " + err.message
	err.backtrace.each do |this|
		puts "^^^ " + this
	end
	retry
end
