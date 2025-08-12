require 'spec_helper'
require_relative '../../lib/telebot/handler'
require_relative '../support/telegram_helpers'

RSpec.describe 'Fluxo principal do bot' do
  include TelegramHelpers

  let(:api) { TelegramHelpers::FakeApi.new }
  let(:bot) { TelegramHelpers::FakeBot.new(api) }
  let(:handler) { Telebot::Handler.new }

  it 'apresenta ajuda e lida com comando desconhecido' do
    handler.handle(bot, TelegramHelpers::FakeMessage.new(TelegramHelpers::FakeChat.new(1), '/start', nil))
    expect(api.messages.last[:text]).to include('/help')

    handler.handle(bot, TelegramHelpers::FakeMessage.new(TelegramHelpers::FakeChat.new(1), '/unknown', nil))
    expect(api.messages.last[:text]).to include('Comando não reconhecido')
  end
end


