FROM ruby:3.1-slim

WORKDIR /app

# Instala dependências do sistema (incluindo ffmpeg, imagemagick e Python para yt-dlp)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    imagemagick libmagickwand-dev libmagickcore-dev \
    ffmpeg python3 python3-pip \
    && pip3 install yt-dlp \
    && rm -rf /var/lib/apt/lists/*

# Copia arquivos da aplicação
COPY . /app

# Instala gems via Bundler
RUN gem install bundler && bundle install

# Executa o bot
CMD ["ruby", "bot.rb"]
