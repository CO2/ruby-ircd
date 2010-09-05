#!/usr/bin/ruby

# ruby-ircd :: IRC Server
# Copyright (C) 2010 Brendon Duncan

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
