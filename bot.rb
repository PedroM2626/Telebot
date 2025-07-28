# Aponte para o bundle de certificados antes de qualquer require HTTPS
ENV['SSL_CERT_FILE'] ||= 'C:\\cacert.pem'

require 'dotenv/load'      # Carrega .env para ENV
require 'telegram/bot'
require 'streamio-ffmpeg'
require 'mini_magick'
require 'rqrcode'
require 'rqrcode_png'
require 'remove_bg'
require 'faraday'           # apenas para UploadIO
require 'open3'
require 'securerandom'
require 'tmpdir'

TOKEN = ENV.fetch('TELEBOT_TOKEN')

module UtilTools
  # Baixa do YouTube em MP4 ou extrai o áudio em MP3
  def self.download_youtube(url, audio_only: false)
    format = audio_only ? 'bestaudio[ext=m4a]' : 'mp4'
    ext    = audio_only ? 'mp3' : 'mp4'
    tmp    = File.join(Dir.tmpdir, "yt_#{SecureRandom.hex}.#{ext}")

    cmd = if audio_only
      ['yt-dlp', '-f', format, '-x', '--audio-format', 'mp3', '-o', tmp, url]
    else
      ['yt-dlp', '-f', format, '-o', tmp, url]
    end

    stdout, stderr, status = Open3.capture3(*cmd)
    raise "Falha no yt-dlp: #{stderr.strip}" unless status.success?
    raise 'Arquivo baixado vazio' if File.zero?(tmp)
    tmp
  end

  def self.trim_video(input_path, start_s, dur_s)
    raise 'Nenhum vídeo para trim' if input_path.to_s.empty?
    out = File.join(Dir.tmpdir, "trim_#{SecureRandom.hex}.mp4")
    FFMPEG::Movie.new(input_path).transcode(out, %W(-ss #{start_s} -t #{dur_s}))
    raise 'Vídeo trim vazio' if File.zero?(out)
    out
  end

  def self.convert_format(input_path, fmt)
    raise 'Nenhum vídeo para conversão' if input_path.to_s.empty?
    out = File.join(Dir.tmpdir, "conv_#{SecureRandom.hex}.#{fmt}")
    FFMPEG::Movie.new(input_path).transcode(out)
    raise 'Vídeo convertido vazio' if File.zero?(out)
    out
  end

  def self.adjust_audio(input_path, speed, volume)
    raise 'Nenhum áudio para ajuste' if input_path.to_s.empty?
    ext = File.extname(input_path)
    out = File.join(Dir.tmpdir, "adj_#{SecureRandom.hex}#{ext}")
    FFMPEG::Movie.new(input_path).transcode(out, ['-filter:a', "atempo=#{speed},volume=#{volume}"])
    raise 'Áudio vazio' if File.zero?(out)
    out
  end

  def self.qrcode(text)
    png = RQRCode::QRCode.new(text).as_png(size: 300).to_blob
    out = File.join(Dir.tmpdir, "qr_#{SecureRandom.hex}.png")
    File.binwrite(out, png)
    raise 'QR Code vazio' if File.zero?(out)
    out
  end

  def self.remove_bg(input_path)
    raise 'Nenhuma imagem para remover fundo' if input_path.to_s.empty?
    img = MiniMagick::Image.open(input_path)
    img.format 'png'
    out = File.join(Dir.tmpdir, "nobg_#{SecureRandom.hex}.png")
    img.write(out)
    raise 'RemoveBG vazio' if File.zero?(out)
    out
  end

  def self.fusion(path1, path2)
    raise 'Faltam imagens para fusão' unless File.exist?(path1) && File.exist?(path2)
    i1 = MiniMagick::Image.open(path1)
    i2 = MiniMagick::Image.open(path2)
    h  = [i1.height, i2.height].min
    i1.resize "x#{h}"
    i2.resize "x#{h}"
    result = i1.composite(i2) { |c| c.append true }
    out = File.join(Dir.tmpdir, "fus_#{SecureRandom.hex}.png")
    result.write(out)
    raise 'Fusion vazio' if File.zero?(out)
    out
  end
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
}

# Garante long polling
Telegram::Bot::Client.new(TOKEN).api.delete_webhook

Telegram::Bot::Client.run(TOKEN) do |bot|
  @last_file   = nil
  @photo_queue = []

  bot.listen do |msg|
    cmd, *args = msg.text.to_s.split

    # Recebe fotos para /fusion
    if msg.photo
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
      next
    end

    begin
      case cmd
      when '/start', '/help'
        help = COMMANDS.map { |c, d| "#{c} – #{d}" }.join("\n")
        bot.api.send_message(chat_id: msg.chat.id, text: help)

      when '/download'
        url       = args[0]
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

      when '/trim'
        start_s, dur_s = args
        path = UtilTools.trim_video(@last_file, start_s, dur_s)
        @last_file = path
        File.open(path, 'rb') do |f|
          bot.api.send_document(chat_id: msg.chat.id,
                                document: Faraday::UploadIO.new(f, 'video/mp4'))
        end

      when '/convert'
        fmt  = args.first
        path = UtilTools.convert_format(@last_file, fmt)
        @last_file = path
        mime = fmt == 'mp3' ? 'audio/mpeg' : "video/#{fmt}"
        File.open(path, 'rb') do |f|
          bot.api.send_document(chat_id: msg.chat.id,
                                document: Faraday::UploadIO.new(f, mime))
        end

      when '/adjustaudio'
        speed, volume = args.map(&:to_f)
        path = UtilTools.adjust_audio(@last_file, speed, volume)
        @last_file = path
        File.open(path, 'rb') do |f|
          bot.api.send_document(chat_id: msg.chat.id,
                                document: Faraday::UploadIO.new(f, 'audio/mpeg'))
        end

      when '/qrcode'
        text = args.join(' ')
        path = UtilTools.qrcode(text)
        @last_file = path
        File.open(path, 'rb') do |f|
          bot.api.send_photo(chat_id: msg.chat.id,
                             photo: Faraday::UploadIO.new(f, 'image/png'))
        end

      when '/removebg'
        path = UtilTools.remove_bg(@last_file)
        @last_file = path
        File.open(path, 'rb') do |f|
          bot.api.send_photo(chat_id: msg.chat.id,
                             photo: Faraday::UploadIO.new(f, 'image/png'))
        end

      when '/fusion'
        if @photo_queue.size < 2
          bot.api.send_message(chat_id: msg.chat.id,
                               text: 'Envie 2 imagens antes de /fusion')
        else
          paths = @photo_queue.map do |fid|
            file_obj  = bot.api.get_file(file_id: fid)
            file_path = file_obj.file_path
            ext       = File.extname(file_path)
            out       = File.join(Dir.tmpdir, "in_#{SecureRandom.hex}#{ext}")
            data      = Faraday.get("https://api.telegram.org/file/bot#{TOKEN}/#{file_path}").body
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

      else
        bot.api.send_message(chat_id: msg.chat.id,
                             text: 'Comando não reconhecido. Use /help')
      end

    rescue => e
      bot.api.send_message(chat_id: msg.chat.id, text: "Erro: #{e.message}")
    end
  end
end
