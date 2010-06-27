#!/usr/bin/ruby

# irc.rb
# Contains various IRC-related stuff

$NickMatch = /^[a-zA-Z\[\]\\`_\^\{\}\|][a-zA-Z0-9\[\]\\`_\^\{\}\|-]{0,16}$/
$ChanMatch = /^[#&][^\x07\r\n ,:]{0,49}$/

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
