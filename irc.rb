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

# irc.rb
# Contains various IRC-related stuff

$NickMatch = /^[a-zA-Z\[\]\\`_\^\{\}\|][a-zA-Z0-9\[\]\\`_\^\{\}\|-]{0,16}$/
$ChanMatch = /^[#&][^\x07\r\n ,:]{0,49}$/

$SourceURL = "http://github.com/CO2/ruby-ircd"

# irc_upcase
# Converts a string to all uppercase characters

def irc_upcase(str)
	val = str.upcase
	val.gsub!('{','[')
	val.gsub!('}',']')
	val.gsub!('|','\\')
	return val
end

# irc_downcase
# Converts a string to all lowercase characters

def irc_downcase(str)
	val = str.downcase
	val.gsub!('[','{')
	val.gsub!(']','}')
	val.gsub!('\\','|')
	return val
end

# idwn
# Alias for irc_downcase

def idwn(instr)
	return irc_downcase(instr)
end
