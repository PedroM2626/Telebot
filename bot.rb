ENV['SSL_CERT_FILE'] ||= 'C:\\cacert.pem'

require 'dotenv/load'
require 'telegram/bot'
require 'faraday'

require_relative 'lib/util_tools'
require_relative 'lib/telebot/handler'

TOKEN = ENV.fetch('TELEBOT_TOKEN')

if ENV.fetch('RUN_BOT', 'true') == 'true'
  Telegram::Bot::Client.new(TOKEN).api.delete_webhook

  Telegram::Bot::Client.run(TOKEN) do |bot|
    handler = Telebot::Handler.new

    bot.listen do |msg|
      begin
        handler.handle(bot, msg)
      rescue => e
        bot.api.send_message(chat_id: msg.chat.id, text: "Erro: #{e.message}")
      end
    end
  end
end
