require 'spec_helper'
require_relative '../../lib/telebot/handler'
require_relative '../support/telegram_helpers'

RSpec.describe Telebot::Handler do
  include TelegramHelpers

  let(:api) { TelegramHelpers::FakeApi.new }
  let(:bot) { TelegramHelpers::FakeBot.new(api) }
  subject(:handler) { described_class.new }

  before do
    ENV['TELEBOT_TOKEN'] = 'test-token'
  end

  it 'responde /help' do
    msg = TelegramHelpers::FakeMessage.new(TelegramHelpers::FakeChat.new(1), '/help', nil)
    handler.handle(bot, msg)
    expect(api.messages.last[:text]).to include('/download')
  end

  it 'gera qr com /qrcode' do
    tmp_qr = File.join(Dir.tmpdir, 'qr.png')
    File.binwrite(tmp_qr, 'qr')
    allow(UtilTools).to receive(:qrcode).and_return(tmp_qr)
    expect do
      msg = TelegramHelpers::FakeMessage.new(TelegramHelpers::FakeChat.new(1), '/qrcode hello', nil)
      handler.handle(bot, msg)
    end.not_to raise_error
    expect(api.photos.size).to be >= 1
  ensure
    File.delete(tmp_qr) if tmp_qr && File.exist?(tmp_qr)
  end
end


