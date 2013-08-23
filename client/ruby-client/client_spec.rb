load 'client.rb'

describe Dice do

  it { value('6,3').should eq(63) }
  it { value('3,6').should eq(63) }
  it { serialize(63).should eq('6,3') }
  it { compare('6,3', '6,4').should eq(1) }
  it { compare('3,3', '6,4').should eq(-1) }
  it { Dice.new(43).inc.value.should eq(44) }


  def value(string)
    Dice.parse(string).value
  end

  def serialize(value)
    Dice.new(value).to_s
  end

  def compare(a, b)
    Dice.parse(a) <=> Dice.parse(b)
  end

end

describe Client do

  let(:messenger){ double('messenger') }
  let(:client){ Client.new('seb', messenger) }

  describe '#register' do
    it 'registers player' do
      messenger.should_receive(:send).with('REGISTER;seb')
      client.register
    end
  end

  describe '#on_message' do
    it 'joins new game' do
      messenger.should_receive(:send).with('JOIN;12345')
      client.on_message 'ROUND STARTING;12345'
    end

    it 'initially uses dice' do
      should_send('ROLL;123')
      should_send('ANNOUNCE;5,3;124')
      client.on_message 'YOUR TURN;123'
      client.on_message 'ROLLED;5,3;124'
    end

    it 'lies if roll is lower than last announcement' do
      should_send('ROLL;123')
      should_send('ANNOUNCE;5,3;124')
      client.on_message 'ANNOUNCED;any_name;5,2'
      client.on_message 'YOUR TURN;123'
      client.on_message 'ROLLED;4,3;124'
    end

    it 'tells truth if roll is higher than last announcement' do
      should_send('ROLL;123')
      should_send('ANNOUNCE;5,2;124')
      client.on_message 'ANNOUNCED;any_name;4,3'
      client.on_message 'YOUR TURN;123'
      client.on_message 'ROLLED;52;124'
    end
  end

  def should_send(message)
    messenger.should_receive(:send).with(message)
  end

end
