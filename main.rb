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

# main.rb
# Contains the code to be executed

require 'irc_server.rb'

PingTimeout = 120	# 2 minutes per ping request
UpdateDelay = 0.1	# 10 updates per second
serv = IRCServer::new("RubyServ","./ircd.conf")
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
			serv.clients.each do |this|
				this.pingreq
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
