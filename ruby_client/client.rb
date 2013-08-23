require 'socket'
load 'messenger.rb'

class Dice
  include Comparable

  attr_reader :value

  def self.parse(string)
    values = string.split(',')

    value1 = values[0].to_i
    value2 = values[1].to_i
    if value1 < value2
      value1, value2 = value2, value1
    end
    Dice.new("#{value1}#{value2}".to_i)
  end

  def initialize(value)
    @value = value
  end

  def inc
    @value = @value + 1
    self
  end

  def to_s
    value = @value.to_s
    "#{value[0]},#{value[1]}"
  end

  def <=>(other)
    self.value <=> other.value
  end

end

class Client

  def self.create(name, port)
    Client.new(name, Messenger.new(port))
  end

  def initialize(name, messenger)
    @name = name
    @messenger = messenger
    @last_dice = Dice.new(0)
  end

  def register
    @messenger.send("REGISTER;#{@name}")
    self
  end

  def start
    @messenger.on_message { |message| on_message(message) }
  end

  def on_message(message)
    fragments = message.split(';')
    command = fragments[0]
    case command
    when  'ROUND STARTING' 
      token = fragments[1]
      @last_dice = Dice.new(0)
      @messenger.send "JOIN;#{token}"
    when 'ANNOUNCED'
      @last_dice = Dice.parse(fragments[2])
    when 'YOUR TURN' 
      token = fragments[1]
      @messenger.send "ROLL;#{token}"
    when 'ROLLED'
      token = fragments[2]
      dice = Dice.parse(fragments[1])
      if dice <= @last_dice 
        dice = @last_dice.inc
      end

      @messenger.send "ANNOUNCE;#{dice};#{token}" 
    end
  end

end
