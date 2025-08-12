require 'ostruct'
module TelegramHelpers
  FakeMessage = Struct.new(:chat, :text, :photo)
  FakeChat = Struct.new(:id)
  FakePhotoSize = Struct.new(:file_size, :file_id)

  class FakeApi
    attr_reader :messages, :documents, :photos, :files

    def initialize
      @messages = []
      @documents = []
      @photos = []
      @files = {}
    end

    def delete_webhook; end

    def send_message(chat_id:, text:)
      @messages << { chat_id: chat_id, text: text }
    end

    def send_document(chat_id:, document:)
      @documents << { chat_id: chat_id, document: document }
    end

    def send_photo(chat_id:, photo:)
      @photos << { chat_id: chat_id, photo: photo }
    end

    def get_file(file_id:)
      OpenStruct.new(file_path: @files.fetch(file_id))
    end
  end

  class FakeBot
    attr_reader :api
    def initialize(api)
      @api = api
    end
  end
end


