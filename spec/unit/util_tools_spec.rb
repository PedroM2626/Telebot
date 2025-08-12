require 'spec_helper'
require_relative '../../lib/util_tools'

RSpec.describe UtilTools do
  describe '.qrcode' do
    it 'gera um arquivo png com conteúdo' do
      path = described_class.qrcode('hello')
      expect(File.exist?(path)).to be true
      expect(File.size(path)).to be > 0
    ensure
      File.delete(path) if path && File.exist?(path)
    end
  end

  describe '.download_youtube' do
    it 'chama yt-dlp e retorna caminho de arquivo quando success' do
      allow(Open3).to receive(:capture3).and_return(['', '', instance_double(Process::Status, success?: true)])
      tmp = File.join(Dir.tmpdir, 'yt_test.mp4')
      allow(Dir).to receive(:tmpdir).and_return(File.dirname(tmp))
      allow(SecureRandom).to receive(:hex).and_return('test')
      allow(File).to receive(:zero?).with(tmp).and_return(false)
      allow(File).to receive(:exist?).with(tmp).and_return(true)
      path = described_class.download_youtube('http://example.com/video')
      expect(path).to eq(tmp)
    end
  end
end


