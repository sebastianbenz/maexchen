remotePlayer = require '../lib/remotePlayer'
miaGame = require '../lib/miaGame'
dice = require '../lib/dice'

describe "remotePlayer", ->
	
	player = null
	mySpy =
		sendMessage: ->
		callback: ->

	beforeEach ->
		spyOn mySpy, 'sendMessage'
		spyOn mySpy, 'callback'
		player = remotePlayer.create 'playerName', mySpy.sendMessage
		player.generateToken = -> 'theToken'

	it 'should silently ignore messages initially', ->
		player.handleMessage 'JOIN', 'token'
		expect(mySpy.sendMessage).not.toHaveBeenCalled()

	it 'should send message when registered successfully', ->
		player.registered()
		expect(mySpy.sendMessage).toHaveBeenCalledWith 'REGISTERED;0'

	describe 'when asked to join a round', ->

		beforeEach ->
			player.willJoinRound mySpy.callback

		it 'should send ROUND STARTING', ->
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ROUND STARTING;theToken'
		
		it 'should accept a JOIN', ->
			player.handleMessage 'JOIN', ['theToken']
			expect(mySpy.callback).toHaveBeenCalledWith true

		it 'should ignore invalid messages ', ->
			player.handleMessage 'JOIN', ['wrongToken']
			player.handleMessage 'ROLL', ['theToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

			player.handleMessage 'JOIN', ['theToken']
			expect(mySpy.callback).toHaveBeenCalled()

	describe 'when asked for a turn', ->

		beforeEach ->
			player.yourTurn mySpy.callback

		it 'should send YOUR TURN', ->
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'YOUR TURN;theToken'

		it 'should accept a ROLL', ->
			player.handleMessage 'ROLL', ['theToken']
			expect(mySpy.callback).toHaveBeenCalledWith miaGame.Messages.ROLL

		it 'should accept a SEE', ->
			player.handleMessage 'SEE', ['theToken']
			expect(mySpy.callback).toHaveBeenCalledWith miaGame.Messages.SEE

		it 'should ignore invalid messages', ->
			player.handleMessage 'JOIN', ['theToken']
			player.handleMessage 'ROLL', ['wrongToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

			player.handleMessage 'ROLL', ['theToken']
			expect(mySpy.callback).toHaveBeenCalled()

	describe 'after rolling dice', ->
		
		beforeEach ->
			player.yourRoll 'theDice', mySpy.callback

		it 'should send ROLLED', ->
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ROLLED;theDice;theToken'

		it 'should accept ANNOUNCE', ->
			player.handleMessage 'ANNOUNCE', ['3,1', 'theToken']
			expect(mySpy.callback).toHaveBeenCalledWith dice.create(3,1)

		it 'should ignore invalid messages', ->
			player.handleMessage 'ANNOUNCE', ['3,1', 'wrongToken']
			player.handleMessage 'ANNOUNCE', ['invalidDice', 'theToken']
			player.handleMessage 'JOIN', ['theToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

			player.handleMessage 'ANNOUNCE', ['2,1', 'theToken']
			expect(mySpy.callback).toHaveBeenCalled()

