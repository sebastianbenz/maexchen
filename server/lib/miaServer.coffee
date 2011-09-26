dgram = require 'dgram'
uuid = require 'node-uuid'

miaGame = require './miaGame'
dice = require './dice'

String::startsWith = (prefix) ->
	@substring(0, prefix.length) == prefix

generateToken = -> uuid()

class RemotePlayer
	constructor: (@name, @socket, @host, @port) ->
		@sendMessage 'REGISTERED;0'

	willJoinRound: (@joinCallback) ->
		@currentToken = generateToken()
		@sendMessage "ROUND STARTING;#{@currentToken}"

	yourTurn: (@playerTurnCallback) ->
		@currentToken = generateToken()
		@sendMessage "YOUR TURN;#{@currentToken}"

	yourRoll: (dice, @announceCallback) ->
		@currentToken = generateToken()
		@sendMessage "ROLLED;#{dice};#{@currentToken}"

	roundCanceled: (reason) ->
		@sendMessage "ROUND CANCELED;#{reason}"

	roundStarted: ->
		@sendMessage "ROUND STARTED;testClient:0" #TODO correct players/scores

	announcedDiceBy: (dice, player) ->
		@sendMessage "ANNOUNCED;#{player.name};#{dice}"

	playerLost: (player) ->

	handleMessage: (messageCommand, messageArgs) ->
		switch messageCommand
			when 'JOIN'
				if messageArgs[0] == @currentToken
					@joinCallback true
			when 'ROLL'
				@playerTurnCallback miaGame.Messages.ROLL
			when 'ANNOUNCE'
				announcedDice = dice.parse messageArgs[0]
				@announceCallback announcedDice

	sendMessage: (message) ->
		console.log "sending '#{message}' to #{@host}:#{@port}"
		buffer = new Buffer(message)
		@socket.send buffer, 0, buffer.length, @port, @host

class Server
	constructor: (port, @timeout) ->
		handleRawMessage = (message, rinfo) =>
			fromHost = rinfo.address
			fromPort = rinfo.port
			console.log "received '#{message}' from #{fromHost}:#{fromPort}"
			messageParts = message.toString().split ';'
			command = messageParts[0]
			args = messageParts[1..]
			@handleMessage command, args, fromHost, fromPort

		@players = {}
		@game = miaGame.createGame()
		@game.setBroadcastTimeout @timeout
		@socket = dgram.createSocket 'udp4', handleRawMessage
		@socket.bind port
		console.log "\nMia server started on port #{port}"

	startGame: ->
		@game.newRound()

	handleMessage: (messageCommand, messageArgs, fromHost, fromPort) ->
		if messageCommand == 'REGISTER'
			name = messageArgs[0]
			newPlayer = new RemotePlayer name, @socket, fromHost, fromPort
			@addPlayer fromHost, fromPort, newPlayer
		else
			@playerFor(fromHost, fromPort).handleMessage messageCommand, messageArgs
	
	shutDown: ->
		@socket.close()
		@game.stop()

	setDiceRoller: (diceRoller) ->
		@game.setDiceRoller diceRoller
	
	playerFor: (host, port) ->
		@players["#{host}:#{port}"]
	
	addPlayer: (host, port, player) ->
		@players["#{host}:#{port}"] = player
		@game.registerPlayer player
	
exports.start = (port, timeout) ->
	return new Server port, timeout
