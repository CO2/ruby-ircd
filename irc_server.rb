#!/usr/bin/ruby

# irc_server.rb
# Contains the IRCServer class

require 'socket'
require 'irc.rb'
require 'irc_user.rb'
require 'irc_channel.rb'

# IRCServer
# An instance of the irc server

class IRCServer
	@name = nil		# Server name
	@sock = nil		# Socket
	@users = nil	# Registered users
	@clients = nil	# Unregistered clients
	@channels = nil	# Channels
	
	attr_accessor :name,:sock,:users,:clients,:channels
	
	# Constructor
	def initialize(name,ip = "0.0.0.0",port = 6667)
		@name = name
		@sock = TCPServer::new(ip,port)
		@users = {}
		@channels = {}
		@clients = []
	end
	
	# Process events
	def update
		@users.each_value do |this|
			if (!this.nil?)
				this.update
			end
		end
		@clients.each do |this|
			this.update
		end
		while (!select([@sock],nil,nil,0).nil?)
			puts "--- Accepted new incoming connection"
			@clients += [IRCUser::new(self,@sock.accept)]
		end
	end
	
	# Kick everyone off the server
	def shutdown(reason = "Server is being shut down")
		@users.each_value do |this|
			if (!this.nil?)
				if (this.local?)
					this.s_error("Closing link [" + reason + "]")
				end
			end
		end
	end
end
