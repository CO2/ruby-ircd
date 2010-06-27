#!/usr/bin/ruby

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
