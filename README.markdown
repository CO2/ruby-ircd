# ruby-ircd #
ruby-ircd is an IRC server program written in Ruby.


## License ##
ruby-ircd is licensed under the GNU Affero Public License version 3. If you do modify this program, you should change the value of **$SourceURL** in `irc.rb` to point to your version of the source.


## Supported Commands ##
ruby-ircd does not support all IRC commands (yet). The following is a list of all supported commands:

### Registration ###
- USER
- NICK
- OPER
- QUIT

### Messaging ###
- PRIVMSG
- NOTICE

### Channel-Related ###
- JOIN
- PART
- KICK
- TOPIC
- NAMES
+ CHANOP
+ VOICE
+ NORMAL

### Server Control ###
- REHASH

### Miscellaneous ###
- VERSION


## Unsupported Commands ##
The following is a list of commands not yet implemented:

### Registration ###
- PASS
- MODE (User)
* AWAY
- SERVICE

### Messaging ###
- SQUERY
* WALLOPS

### Channel-Related ###
- MODE (Channel)
- INVITE
- LIST

### Server Control ###
* DIE
* RESTART

### Network Control ###
- CONNECT
- SQUIT
- TRACE
- KILL

### User Queries ###
- WHO
- WHOIS
- WHOWAS
- LUSERS
* USERHOST
* ISON

### Miscellaneous ###
- MOTD
- STATS
- LINKS
- TIME
- ADMIN
- INFO
- SERVLIST
* SUMMON
* USERS


## Unsupported Features ##
The following is a list of other unsupported features:

- PRIVMSG with non-nickname targets
- NOTICE with non-nickname targets
- JOIN with parameter 0 to part all channels
- PART messages
- Multiple servers connected in an IRC network


## Special Commands ##
The following is a list of non-standard commands:

### CHANOP Command ###

`CHANOP channel nickname`

Makes the user with `nickname` a channel operator in `channel`.


### VOICE Command ###

`VOICE channel nickname`

Gives the user with `nickname` voice in `channel`.


### NORMAL Command ###

`NORMAL channel nickname`

Removes chanop and voice status from user with `nickname` in `channel`.


## Configuration File ##
The configuration file has lines storing simple configuration information like:

`LINENAME:parameter 1:parameter 2:parameter 3:etc`

`LINENAME` must be in allcaps


### OPER Line ###
OPER lines control the OPER command

`OPER:user:pass:hostname`

`user` is the first parameter given to the OPER command
`pass` is the second parameter given to the OPER command
`hostname` is a regular expression that must match the hostname of the user attempting to use OPER

Example:

`OPER:Jeff:nobodywillguessthisever:.*`
