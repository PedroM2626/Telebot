FROM ruby:3.3-alpine3.20 AS builder

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /app

# Dependências de build (removidas no estágio final)
RUN apk upgrade --no-cache \
    && apk add --no-cache \
      build-base \
      pkgconfig \
      imagemagick-dev \
      ca-certificates \
      git

# Instala gems com cache otimizado
COPY Gemfile Gemfile.lock ./
RUN gem install bundler \
    && bundle config set without 'development test' \
    && bundle install --jobs 4 --retry 3

# Copia a aplicação
COPY . /app

FROM ruby:3.3-alpine3.20 AS runtime

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /app

# Somente dependências de runtime (menos superfície para CVEs)
RUN apk upgrade --no-cache \
    && apk add --no-cache \
      ca-certificates \
      tzdata \
      ffmpeg \
      imagemagick \
      python3 \
      yt-dlp

# Reutiliza as gems já compiladas
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copia código-fonte
COPY . /app

# Usuário não root
RUN adduser -D -h /home/appuser appuser \
  && chown -R appuser:appuser /app
USER appuser

CMD ["ruby", "bot.rb"]
