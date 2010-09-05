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

# irc_channel.rb
# Contains the IRCChannel class

require 'irc.rb'

# IRCChannel
# A channel on the network

class IRCChannel
	@name = nil		# Name of the channel
	@topic = nil	# Topic of the channel
	@key = nil		# Key to join the channel
	@users = nil	# Users in the channel
	@invites = nil	# Users invited to the channel
	@bans = nil		# Banned user prefixes
	@norms = nil	# Normal users in the channel
	@voices = nil	# Voiced users in the channel
	@ops = nil		# Operators in the channel
	
	attr_accessor :name, :topic, :key, :users, :invites, :bans, :norms, :voices, :ops
	
	def initialize(name)
		@name = name
		@topic = "Welcome to " + @name + "!"
		@users = []
		@invites = []
		@bans = []
		@norms = []
		@voices = []
		@ops = []
	end
end
