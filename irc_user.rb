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

# irc_user.rb
# Contains the IRCUser class

require 'irc.rb'

$ClientLimit = 5
$ChannelLimit = 10

# IRCUser
# A user connected to this server

class IRCUser
	@serv = nil		# Server
	@sock = nil		# Socket
	@nickname = nil	# Nickname
	@username = nil	# Username
	@hostname = nil	# Hostname
	@realname = nil	# Realname
	@channels = nil	# Channels
	@didpong = nil	# Sent a PONG reply to last PING
	@oper = nil		# IRC Operator
	
	attr_accessor :nickname, :username, :hostname, :realname, :channels, :oper
	
	# Constructor
	def initialize(server,sock)
		@serv = server
		@sock = sock
		@hostname = sock.peeraddr[2]
		@channels = {}
		@didpong = true
		@oper = false
		clientcount = 0
		@serv.users.each_value do |this|
			if (!this.nil?)
				if (this.hostname == @hostname)
					clientcount += 1
				end
			end
		end
		@serv.clients.each do |this|
			if (this.hostname == @hostname)
				clientcount += 1
			end
		end
		if (clientcount > $ClientLimit)
			s_error("Maximum number of connections exceeded")
			@sock.close
			@serv.clients -= [self]
		end
	end
	
	# Returns true if the client is registered
	def registered?
		return !(@nickname.nil? || @username.nil?)
	end
	
	# Returns true if the user is connected to this server
	def local?
		return true
	end
	
	# Returns the prefix used in commands
	def prefix
		return @nickname + "!" + @username + "@" + @hostname
	end
	
	# Inspect
	def inspect
		return prefix + " [LOCAL]"
	end
	
	# Send the welcome messages
	def s_welcome
		s_reply(001,":Welcome to " + @serv.name + " " + prefix)
		s_reply(002,":Your host is " + @serv.name + ", running version 0")
		s_reply(003,":This server was created sometimeidontrememberwhen")
		s_reply(004,[@serv.name,"0","",""].join(' '))
		s_reply(422,":MOTD File is missing")
		@serv.autojoins.each do |this|
			r_join(this)
		end
	end
	
	# Send a numeric reply
	def s_reply(number,message)
		send(":" + [@serv.name,number.to_s.rjust(3,"0"),(@nickname.nil?) ? "*" : @nickname,message].join(" "))
	end
	
	# USER command
	def r_user(username,realname)
		if (registered?)
			s_reply(426,":Unauthorized command (already registered)")
		else
			@username = username
			@realname = realname
			if (registered?)
				s_welcome
			end
		end
	end
	
	# NICK command
	def s_nick(source,newnick)
		send(":" + source + " NICK " + newnick)
	end
	def r_nick(newnick)
		if (!(newnick =~ $NickMatch))
			s_reply(432,newnick + " :Erroneous nickname")
			return
		end
		if (!@serv.users[idwn(newnick)].nil?)
			s_reply(433,newnick + " :Nickname already in use")
			return
		end
		if (@nickname.nil?)
			@serv.clients -= [self]
			@serv.users[idwn(newnick)] = self
			@nickname = newnick
			if (registered?)
				s_welcome
			end
		else
			@serv.users[idwn(@nickname)] = nil
			@serv.users[idwn(newnick)] = self
			@nickname = newnick
			if (registered?)
				visibles = [self]
				@channels.each_value do |thischan|
					if (!thischan.nil?)
						thischan.users.each do |this|
							visibles += [this]
						end
					end
				end
				visibles.uniq.each do |this|
					this.s_nick(prefix,newnick)
				end
			end
		end
	end
	
	# OPER command
	def r_oper(username,password)
		opforhost = false
		@serv.opers.each do |this|
			if (hostname =~ this[2])
				opforhost = true
			end
			if (idwn(this[0]) == idwn(username) && this[1] == password && @hostname =~ this[2])
				s_reply(381,"You are now an IRC operator")
				@oper = true
				return
			end
		end
		if (opforhost)
			s_reply(464,":User or Password incorrect")
		else
			s_reply(491,":No OPER lines for your host")
		end
	end
	
	# PRIVMSG command
	def s_privmsg(source,target,message)
		send(":" + source + " PRIVMSG " + target + " :" + message)
	end
	def r_privmsg(target,message)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		if (target =~ $NickMatch)
			targnick = @serv.users[idwn(target)]
			if (targnick.nil?)
				s_reply(401,target + " :No such nick/channel")
				return
			end
			targnick.s_privmsg(prefix,target,message)
		elsif (target =~ $ChanMatch)
			targchan = @serv.channels[idwn(target)]
			if (targchan.nil?)
				s_reply(401,target + " :No such nick/channel")
				return
			end
			if (!targchan.users.include?(self))
				s_reply(404,target + " :Cannot send to channel")
				return
			end
			(targchan.users - [self]).each do |this|
				this.s_privmsg(prefix,target,message)
			end
		else
			s_reply(401,target + " :No such nick/channel")
		end
	end
	
	# NOTICE command
	def s_notice(source,target,message)
		send(":" + source + " NOTICE " + target + " :" + message)
	end
	def r_notice(target,message)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		if (target =~ $NickMatch)
			targnick = @serv.users[idwn(target)]
			if (targnick.nil?)
				s_reply(401,target + " :No such nick/channel")
				return
			end
			targnick.s_notice(prefix,target,message)
		elsif (target =~ $ChanMatch)
			targchan = @serv.channels[idwn(target)]
			if (targchan.nil?)
				s_reply(401,target + " :No such nick/channel")
				return
			end
			if (!targchan.users.include?(self))
				s_reply(404,target + " :Cannot send to channel")
				return
			end
			(targchan.users - [self]).each do |this|
				this.s_notice(prefix,target,message)
			end
		else
			s_reply(401,target + " :No such nick/channel")
		end
	end
	
	# JOIN command
	def s_join(source,channel)
		send(":" + source + " JOIN " + channel)
	end
	def r_join(channel,key = nil)
		channelcount = 0
		@channels.each do |this|
			if (!this.nil?)
				channelcount += 1
			end
		end
		if (channelcount >= $ChannelLimit)
			s_reply(405,channel + " :You have joined too many channels")
			return
		end
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		if (!(channel =~ $ChanMatch))
			s_reply(403,channel + " :Erroneous channel name")	# Didn't see anything in RFC 2812 other than this
			return
		end
		if (@serv.channels[idwn(channel)].nil?)
			@serv.channels[idwn(channel)] = newchan = IRCChannel::new(channel)
			newchan.users += [self]
			newchan.ops += [self]
			@channels[idwn(channel)] = newchan
		else
			if (!@channels[idwn(channel)].nil?)
				return
			end
			thischan = @serv.channels[idwn(channel)]
			thischan.users.each do |this|
				this.s_join(prefix,channel)
			end
			thischan.users += [self]
			thischan.norms += [self]
			@channels[idwn(channel)] = thischan
		end
		s_join(prefix,channel)
		r_topic_read(channel)
		namereply = "= " + channel + " :"
		@channels[idwn(channel)].ops.each do |this|
			s_reply(353,"= " + channel + " :@" + this.nickname)
		end
		@channels[idwn(channel)].voices.each do |this|
			s_reply(353,"= " + channel + " :+" + this.nickname)
		end
		@channels[idwn(channel)].norms.each do |this|
			s_reply(353,"= " + channel + " :" + this.nickname)
		end
		s_reply(366,channel + " :End of NAMES list")
	end
	
	# PART command
	def s_part(source,channel)
		send(":" + source + " PART " + channel)
	end
	def r_part(channel)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		if (!(channel =~ $ChanMatch))
			s_reply(403,channel + " :Erroneous channel name")	# Didn't see anything in RFC 2812 other than this
			return
		end
		if (@channels[idwn(channel)].nil?)
			s_reply(442,channel + " :You're not on that channel")
			return
		end
		@channels[idwn(channel)].users.each do |this|
			this.s_part(prefix,channel)
		end
		@channels[idwn(channel)].users -= [self]
		@channels[idwn(channel)].norms -= [self]
		@channels[idwn(channel)].voices -= [self]
		@channels[idwn(channel)].ops -= [self]
		if (@channels[idwn(channel)].users.size == 0)
			@serv.channels[idwn(channel)] = nil
		end
		@channels[idwn(channel)] = nil
	end
	
	# KICK command
	def s_kick(source,channel,user,reason)
		send(":" + source + " KICK " + channel + " " + user + " :" + reason)
	end
	def r_kick(channel,user,reason)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		thischan = @serv.channels[idwn(channel)]
		if (thischan.nil?)
			s_reply(401,channel + " :No such nick/channel")
			return
		end
		if (!thischan.users.include?(self))
			s_reply(442,channel + " :You're not on that channel")
			return
		end
		if (!thischan.ops.include?(self) && !@oper)
			s_reply(482,channel + " :You're not a channel operator")
			return
		end
		thisuser = @serv.users[idwn(user)]
		if (thisuser.nil?)
			s_reply(401,user + " :No such nick/channel")
			return
		end
		if (!thischan.users.include?(thisuser))
			s_reply(441,user + " " + channel + " :They aren't on that channel")
			return
		end
		thischan.users.each do |this|
			this.s_kick(prefix,channel,user,reason)
		end
		thischan.users -= [thisuser]
		thischan.norms -= [thisuser]
		thischan.voices -= [thisuser]
		thischan.ops -= [thisuser]
		thisuser.channels[idwn(channel)] = nil
	end
	
	# MODE command
	def s_mode(source,target,string)
		send(":" + source + " MODE " + target + " " + string)
	end
	
	# TOPIC command
	def s_topic(source,channel,topic)
		if (topic.nil?)
			send(":" + source + " TOPIC " + channel + " :")
		else
			send(":" + source + " TOPIC " + channel + " :" + topic)
		end
	end
	def r_topic_read(channel)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		if (@serv.channels[idwn(channel)].nil?)
			s_reply(401,channel + " :No such nick/channel")
			return
		end
		if (@serv.channels[idwn(channel)].topic.nil?)
			s_reply(331,channel + " :No topic is set")
		else
			s_reply(332,channel + " :" + @serv.channels[idwn(channel)].topic)
		end
	end
	def r_topic(channel,topic)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		if (@serv.channels[idwn(channel)].nil?)
			s_reply(401,channel + " :No such nick/channel")
			return
		end
		if (!@serv.channels[idwn(channel)].users.include?(self))
			s_reply(442,channel + " :You're not on that channel")
			return
		end
		if (!@serv.channels[idwn(channel)].ops.include?(self) && !@oper)
			s_reply(482,channel + " :You're not a channel operator")
			return
		end
		if (topic == '')
			topic = nil
		end
		@serv.channels[idwn(channel)].topic = topic
		@serv.channels[idwn(channel)].users.each do |this|
			this.s_topic(prefix,channel,topic)
		end
	end
	
	# NAMES command
	def r_names(channels,target)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		if (target.nil? || idwn(target) == idwn(@serv.name))
			channels.split(',').each do |channel|
				thischan = @serv.channels[idwn(channel)]
				if (thischan.nil?)
					next
				end
				if (!thischan.users.include?(self))
					next
				end
				thischan.ops.each do |this|
					s_reply(353,"= " + channel + " :@" + this.nickname)
				end
				thischan.voices.each do |this|
					s_reply(353,"= " + channel + " :+" + this.nickname)
				end
				thischan.norms.each do |this|
					s_reply(353,"= " + channel + " :" + this.nickname)
				end
				s_reply(366,channel + " :End of NAMES list")
			end
		else
			s_reply(402,target + " :No such server")
		end
	end
	
	# QUIT command
	def s_quit(source,message)
		send(":" + source + " QUIT :" + message)
	end
	def r_quit(message)
		s_error("Closing link [" + message + "]")
		if (!@sock.closed?)
			@sock.close
		end
		if (!@nickname.nil?)
			@serv.users[idwn(@nickname)] = nil
			if (registered?)
				visibles = []
				@channels.each_pair do |thisname,this|
					if (!this.nil?)
						this.users -= [self]
						this.norms -= [self]
						this.voices -= [self]
						this.ops -= [self]
						visibles += this.users
						if (this.users.size == 0)
							@serv.channels[thisname] = nil
						end
					end
				end
				visibles.uniq.each do |this|
					this.s_quit(prefix,message)
				end
			end
		else
			@serv.clients -= [self]
		end
	end
	
	# PING command
	def s_ping(message)
		send("PING " + message)
	end
	def r_ping(message)
		s_pong(message)
	end
	
	# PONG command
	def s_pong(message)
		send("PONG " + message)
	end
	def r_pong(message)
	end
	
	# VERSION command
	def r_version(target)
		if (target.nil? || idwn(target) == idwn(@serv.name))
			s_reply(351,"0.0 " + @serv.name + " :Server running ruby-ircd <" + $SourceURL + ">")
			s_reply(351,"0.0 " + @serv.name + " :ruby-ircd is licensed under the GNU Affero General Public License version 3 (see: http://www.gnu.org/licenses/)")
		else
			s_reply(402,target + " :No such server")
		end
	end
	
	# REHASH command
	def r_rehash
		load 'irc.rb'
		load 'irc_channel.rb'
		load 'irc_user.rb'
		load 'irc_server.rb'
		begin
			@serv.rehash
			s_reply(382,@serv.configfile + " :Rehashing")
		rescue
			s_reply(382,@serv.configfile + " :Rehash failed")
		end
	end
	
	# ERROR command
	def s_error(message)
		send("ERROR :" + message)
	end
	
	# CHANOP command
	def r_chanop(channel,user)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		thischan = @serv.channels[idwn(channel)]
		if (thischan.nil?)
			s_reply(401,channel + " :No such nick/channel")
			return
		end
		if (!thischan.users.include?(self))
			s_reply(442,channel + " :You're not on that channel")
			return
		end
		if (!thischan.ops.include?(self) && !@oper)
			s_reply(482,channel + " :You're not a channel operator")
			return
		end
		thisuser = @serv.users[idwn(user)]
		if (thisuser.nil?)
			s_reply(401,user + " :No such nick/channel")
			return
		end
		if (!thischan.users.include?(thisuser))
			s_reply(441,user + " " + channel + " :They aren't on that channel")
			return
		end
		thischan.users.each do |this|
			if (thischan.voices.include?(thisuser))
				this.s_mode(prefix,channel,"-v " + user)
			end
			if (!thischan.ops.include?(thisuser))
				this.s_mode(prefix,channel,"+o " + user)
			end
		end
		thischan.ops -= [thisuser]
		thischan.voices -= [thisuser]
		thischan.norms -= [thisuser]
		thischan.ops += [thisuser]
	end
	
	# VOICE command
	def r_voice(channel,user)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		thischan = @serv.channels[idwn(channel)]
		if (thischan.nil?)
			s_reply(401,channel + " :No such nick/channel")
			return
		end
		if (!thischan.users.include?(self))
			s_reply(442,channel + " :You're not on that channel")
			return
		end
		if (!thischan.ops.include?(self) && !@oper)
			s_reply(482,channel + " :You're not a channel operator")
			return
		end
		thisuser = @serv.users[idwn(user)]
		if (thisuser.nil?)
			s_reply(401,user + " :No such nick/channel")
			return
		end
		if (!thischan.users.include?(thisuser))
			s_reply(441,user + " " + channel + " :They aren't on that channel")
			return
		end
		thischan.users.each do |this|
			if (thischan.ops.include?(thisuser))
				this.s_mode(prefix,channel,"-o " + user)
			end
			if (!thischan.voices.include?(thisuser))
				this.s_mode(prefix,channel,"+v " + user)
			end
		end
		thischan.ops -= [thisuser]
		thischan.voices -= [thisuser]
		thischan.norms -= [thisuser]
		thischan.voices += [thisuser]
	end
	
	# NORMAL command
	def r_normal(channel,user)
		if (!registered?)
			s_reply(451,":You have not registered")
			return
		end
		thischan = @serv.channels[idwn(channel)]
		if (thischan.nil?)
			s_reply(401,channel + " :No such nick/channel")
			return
		end
		if (!thischan.users.include?(self))
			s_reply(442,channel + " :You're not on that channel")
			return
		end
		if (!thischan.ops.include?(self) && !@oper)
			s_reply(482,channel + " :You're not a channel operator")
			return
		end
		thisuser = @serv.users[idwn(user)]
		if (thisuser.nil?)
			s_reply(401,user + " :No such nick/channel")
			return
		end
		if (!thischan.users.include?(thisuser))
			s_reply(441,user + " " + channel + " :They aren't on that channel")
			return
		end
		thischan.users.each do |this|
			if (thischan.ops.include?(thisuser))
				this.s_mode(prefix,channel,"-o " + user)
			end
			if (thischan.voices.include?(thisuser))
				this.s_mode(prefix,channel,"-v " + user)
			end
		end
		thischan.ops -= [thisuser]
		thischan.voices -= [thisuser]
		thischan.norms -= [thisuser]
		thischan.norms += [thisuser]
	end
	
	# Accept input if there is any
	def update
		if (@sock.closed?)
			return	# Exit the function if the socket is already closed
		end
		if (!select([@sock],nil,nil,0).nil?)
			if (@sock.eof)
				@sock.close
				r_quit("EOF on Socket")
			else
				receive(@sock.gets[0...512].chomp)
			end
		end
	end
	
	# Parse input
	def receive(line)
		puts ">>> " + line
		if (line.nil?)
			return
		end
		command = nil
		args = []
		begin
			if (line =~ /^:.*$/)	# Ignore the prefix if the client sends one
				line = line.split(' ',2)[1]
				if (line.nil?)
					return			# If there is only a prefix, exit the function
				end
			end
			ex = line.split(' ',2)
			command = ex[0]
			if (!ex[1].nil?)
				ex = ex[1].split(":",2)
				if (!ex[0].nil?)
					args = ex[0].split(' ')
				end
				if (ex.size > 1)
					args += [ex[1]]
				end
			end
			ex = args
			args = []
			ex.each do |this|
				if (this.nil?)
					args += ['']
				else
					args += [this]
				end
			end
		end
		if (command.nil?)
			return	# If there is no command, exit the function
		end
		process(command,args)
	end
	
	# Process input
	def process(command,args)
		@didpong = true
		case (irc_upcase(command))
		when "USER"
			if (args.size < 4)
				s_reply(461,command + " :Not enough parameters")
			else
				r_user(args[0],args[3])
			end
		when "NICK"
			if (args.size < 1)
				s_reply(431,":No nickname given")
			else
				r_nick(args[0])
			end
		when "OPER"
			if (args.size < 2)
				s_reply(461,command + " :Not enough paramaters")
			else
				r_oper(args[0],args[1])
			end
		when "PRIVMSG"
			if (args.size < 2)
				s_reply(461,command + " :Not enough parameters")
			else
				args[0].split(',').each do |this|
					r_privmsg(this,args[1])
				end
			end
		when "NOTICE"
			if (args.size < 2)
				s_reply(461,command + " :Not enough parameters")
			else
				args[0].split(',').each do |this|
					r_notice(this,args[1])
				end
			end
		when "JOIN"
			if (args.size < 1)
				s_reply(461,command + " :Not enough parameters")
			else
				args[0].split(',').each do |this|
					r_join(this)
				end
			end
		when "PART"
			if (args.size < 1)
				s_reply(461,command + " :Not enough parameters")
			else
				args[0].split(',').each do |this|
					r_part(this)
				end
			end
		when "KICK"
			if (args.size < 2)
				s_reply(461,command + " :Not enough parameters")
			else
				args += [@nickname]
				channels = args[0].split(',')
				nicks = args[1].split(',')
				reason = args[2]
				for i in 0...nicks.size
					if (i < channels.size)
						r_kick(channels[i],nicks[i],reason)
					else
						r_kick(channels.last,nicks[i],reason)
					end
				end
			end
		when "TOPIC"
			if (args.size < 1)
				s_reply(461,command + " :Not enough parameters")
			elsif (args.size == 1)
				r_topic_read(args[0])
			elsif (args.size == 2)
				r_topic(args[0],args[1])
			end
		when "NAMES"
			if (args.size < 1)
				s_reply(999,":ERR_TOOMANYMATCHES")
			else
				r_names(args[0],args[1])
			end
		when "QUIT"
			if (args.size < 1)
				r_quit(@nickname)
			else
				r_quit(args[0])
			end
		when "PING"
			if (args.size < 1)
				r_ping(@serv.name)
			else
				r_ping(args[0])
			end
		when "PONG"
			r_pong(args[0])	# nil if no parameter
		when "VERSION"
			r_version(args[0])
		when "REHASH"
			r_rehash
		when "CHANOP"
			if (args.size < 2)
				s_reply(461,command + " :Not enough parameters")
			else
				r_chanop(args[0],args[1])
			end
		when "VOICE"
			if (args.size < 2)
				s_reply(461,command + " :Not enough parameters")
			else
				r_voice(args[0],args[1])
			end
		when "NORMAL"
			if (args.size < 2)
				s_reply(461,command + " :Not enough parameters")
			else
				r_normal(args[0],args[1])
			end
		else
			s_reply(421,command + " :Unknown command")
		end
	end
	
	# Send a ping request (or timeout the user)
	def pingreq
		if (@didpong)
			s_ping(@serv.name)
			@didpong = false
		else
			r_quit("Ping timeout")
		end
	end
	
	# Send a line of text
	def send(line)
		puts "<<< " + line[0...510] + "\r\n"
		begin
			@sock.print(line[0...510] + "\r\n")
		rescue	# If a problem occurs, silently fail
		end
	end
end
