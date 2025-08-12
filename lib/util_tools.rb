require 'streamio-ffmpeg'
require 'mini_magick'
require 'rqrcode'
require 'rqrcode_png'
require 'remove_bg'
require 'open3'
require 'securerandom'
require 'tmpdir'

module UtilTools
  def self.download_youtube(url, audio_only: false)
    raise 'URL ausente' if url.to_s.strip.empty?
    format = audio_only ? 'bestaudio[ext=m4a]' : 'mp4'
    ext    = audio_only ? 'mp3' : 'mp4'
    tmp    = File.join(Dir.tmpdir, "yt_#{SecureRandom.hex}.#{ext}")

    cmd = if audio_only
      ['yt-dlp', '-f', format, '-x', '--audio-format', 'mp3', '-o', tmp, url]
    else
      ['yt-dlp', '-f', format, '-o', tmp, url]
    end

    _stdout, stderr, status = Open3.capture3(*cmd)
    raise "Falha no yt-dlp: #{stderr.strip}" unless status.success?
    raise 'Arquivo baixado vazio' if !File.exist?(tmp) || File.zero?(tmp)
    tmp
  end

  def self.trim_video(input_path, start_s, dur_s)
    raise 'Nenhum vídeo para trim' if input_path.to_s.empty?
    out = File.join(Dir.tmpdir, "trim_#{SecureRandom.hex}.mp4")
    FFMPEG::Movie.new(input_path).transcode(out, %W(-ss #{start_s} -t #{dur_s}))
    raise 'Vídeo trim vazio' if !File.exist?(out) || File.zero?(out)
    out
  end

  def self.convert_format(input_path, fmt)
    raise 'Nenhum vídeo para conversão' if input_path.to_s.empty?
    raise 'Formato ausente' if fmt.to_s.strip.empty?
    out = File.join(Dir.tmpdir, "conv_#{SecureRandom.hex}.#{fmt}")
    FFMPEG::Movie.new(input_path).transcode(out)
    raise 'Vídeo convertido vazio' if !File.exist?(out) || File.zero?(out)
    out
  end

  def self.adjust_audio(input_path, speed, volume)
    raise 'Nenhum áudio para ajuste' if input_path.to_s.empty?
    ext = File.extname(input_path)
    out = File.join(Dir.tmpdir, "adj_#{SecureRandom.hex}#{ext}")
    FFMPEG::Movie.new(input_path).transcode(out, ['-filter:a', "atempo=#{speed},volume=#{volume}"])
    raise 'Áudio vazio' if !File.exist?(out) || File.zero?(out)
    out
  end

  def self.qrcode(text)
    raise 'Texto vazio' if text.to_s.strip.empty?
    png = RQRCode::QRCode.new(text).as_png(size: 300).to_blob
    out = File.join(Dir.tmpdir, "qr_#{SecureRandom.hex}.png")
    File.binwrite(out, png)
    raise 'QR Code vazio' if !File.exist?(out) || File.zero?(out)
    out
  end

  def self.remove_bg(input_path)
    raise 'Nenhuma imagem para remover fundo' if input_path.to_s.empty?
    img = MiniMagick::Image.open(input_path)
    img.format 'png'
    out = File.join(Dir.tmpdir, "nobg_#{SecureRandom.hex}.png")
    img.write(out)
    raise 'RemoveBG vazio' if !File.exist?(out) || File.zero?(out)
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
    raise 'Fusion vazio' if !File.exist?(out) || File.zero?(out)
    out
  end
end


