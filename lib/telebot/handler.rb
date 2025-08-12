require 'securerandom'
require 'tmpdir'
require 'faraday'

module Telebot
  class Handler
    def initialize
      @last_file = nil
      @photo_queue = []
      @token = ENV.fetch('TELEBOT_TOKEN')
    end

    COMMANDS = {
      '/download <url> [audio]' => 'Baixa vídeo (mp4) ou áudio (mp3) se usar “audio”',
      '/trim <start> <dur>'     => 'Corta vídeo',
      '/convert <fmt>'          => 'Converte vídeo',
      '/adjustaudio <s> <v>'    => 'Ajusta áudio',
      '/qrcode <texto>'         => 'Gera QR Code',
      '/removebg'               => 'Remove fundo da última imagem',
      '/fusion'                 => 'Funde 2 últimas imagens enviadas',
      '/help'                   => 'Mostra ajuda'
    }.freeze

    def handle(bot, msg)
      # Recebe fotos para /fusion
      if msg.respond_to?(:photo) && msg.photo
        enqueue_photo(bot, msg)
        return
      end

      cmd, *args = msg.text.to_s.split

      case cmd
      when '/start', '/help'
        help = COMMANDS.map { |c, d| "#{c} – #{d}" }.join("\n")
        bot.api.send_message(chat_id: msg.chat.id, text: help)
      when '/download'
        handle_download(bot, msg, args)
      when '/trim'
        handle_trim(bot, msg, args)
      when '/convert'
        handle_convert(bot, msg, args)
      when '/adjustaudio'
        handle_adjust_audio(bot, msg, args)
      when '/qrcode'
        handle_qrcode(bot, msg, args)
      when '/removebg'
        handle_remove_bg(bot, msg)
      when '/fusion'
        handle_fusion(bot, msg)
      else
        bot.api.send_message(chat_id: msg.chat.id, text: 'Comando não reconhecido. Use /help')
      end
    end

    private

    def enqueue_photo(bot, msg)
      fid = msg.photo.max_by(&:file_size).file_id
      @photo_queue.unshift(fid)
      @photo_queue = @photo_queue.first(2)
      case @photo_queue.size
      when 1
        bot.api.send_message(chat_id: msg.chat.id,
                             text: 'Primeira imagem recebida. Agora envie a segunda para /fusion.')
      when 2
        bot.api.send_message(chat_id: msg.chat.id,
                             text: 'Segunda imagem recebida! Use /fusion.')
      end
    end

    def handle_download(bot, msg, args)
      url        = args[0]
      audio_flag = args[1]&.downcase == 'audio'
      bot.api.send_message(chat_id: msg.chat.id,
                           text: audio_flag ? "Baixando áudio: #{url}" : "Baixando vídeo: #{url}")
      path = UtilTools.download_youtube(url, audio_only: audio_flag)
      @last_file = path
      mime = audio_flag ? 'audio/mpeg' : 'video/mp4'
      File.open(path, 'rb') do |f|
        bot.api.send_document(chat_id: msg.chat.id,
                              document: Faraday::UploadIO.new(f, mime))
      end
    end

    def handle_trim(bot, msg, args)
      start_s, dur_s = args
      path = UtilTools.trim_video(@last_file, start_s, dur_s)
      @last_file = path
      File.open(path, 'rb') do |f|
        bot.api.send_document(chat_id: msg.chat.id,
                              document: Faraday::UploadIO.new(f, 'video/mp4'))
      end
    end

    def handle_convert(bot, msg, args)
      fmt  = args.first
      path = UtilTools.convert_format(@last_file, fmt)
      @last_file = path
      mime = fmt == 'mp3' ? 'audio/mpeg' : "video/#{fmt}"
      File.open(path, 'rb') do |f|
        bot.api.send_document(chat_id: msg.chat.id,
                              document: Faraday::UploadIO.new(f, mime))
      end
    end

    def handle_adjust_audio(bot, msg, args)
      speed, volume = args.map(&:to_f)
      path = UtilTools.adjust_audio(@last_file, speed, volume)
      @last_file = path
      File.open(path, 'rb') do |f|
        bot.api.send_document(chat_id: msg.chat.id,
                              document: Faraday::UploadIO.new(f, 'audio/mpeg'))
      end
    end

    def handle_qrcode(bot, msg, args)
      text = args.join(' ')
      path = UtilTools.qrcode(text)
      @last_file = path
      File.open(path, 'rb') do |f|
        bot.api.send_photo(chat_id: msg.chat.id,
                           photo: Faraday::UploadIO.new(f, 'image/png'))
      end
    end

    def handle_remove_bg(bot, msg)
      path = UtilTools.remove_bg(@last_file)
      @last_file = path
      File.open(path, 'rb') do |f|
        bot.api.send_photo(chat_id: msg.chat.id,
                           photo: Faraday::UploadIO.new(f, 'image/png'))
      end
    end

    def handle_fusion(bot, msg)
      if @photo_queue.size < 2
        bot.api.send_message(chat_id: msg.chat.id,
                             text: 'Envie 2 imagens antes de /fusion')
      else
        paths = @photo_queue.map do |fid|
          file_obj  = bot.api.get_file(file_id: fid)
          file_path = file_obj.file_path
          ext       = File.extname(file_path)
          out       = File.join(Dir.tmpdir, "in_#{SecureRandom.hex}#{ext}")
          data      = Faraday.get("https://api.telegram.org/file/bot#{@token}/#{file_path}").body
          File.binwrite(out, data)
          out
        end
        fused = UtilTools.fusion(paths[0], paths[1])
        File.open(fused, 'rb') do |f|
          bot.api.send_photo(chat_id: msg.chat.id,
                             photo: Faraday::UploadIO.new(f, 'image/png'))
        end
        @photo_queue.clear
      end
    end
  end
end


