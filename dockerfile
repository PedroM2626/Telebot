FROM ruby:3.3.4-slim-bookworm

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Instala dependências do sistema (incluindo ffmpeg, imagemagick e Python para yt-dlp)
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       build-essential \
       imagemagick libmagickwand-dev libmagickcore-dev \
       ffmpeg python3 python3-pip \
    && pip3 install --no-cache-dir yt-dlp \
    && rm -rf /var/lib/apt/lists/*

# Pré-instala gems para melhor cache
COPY Gemfile Gemfile.lock ./
RUN gem install bundler \
    && bundle config set without 'development test' \
    && bundle install --jobs 4 --retry 3

# Copia arquivos da aplicação
COPY . /app

# Nada

# Executa com usuário sem privilégios
RUN useradd --create-home --shell /bin/bash appuser \
    && chown -R appuser:appuser /app
USER appuser

# Executa o bot
CMD ["ruby", "bot.rb"]
