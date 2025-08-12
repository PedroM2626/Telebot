# Telebot

Bot de Telegram com utilitários de mídia e imagem: download do YouTube (vídeo/áudio), cortes e conversões de vídeo, ajustes de áudio, geração de QR Code, remoção de fundo e fusão de imagens recebidas no chat.

## Requisitos

- Ruby 3.3+
- ffmpeg
- ImageMagick (com `libmagickwand-dev` quando necessário)
- Python 3 + `yt-dlp`
- Certificado CA local em Windows: defina `SSL_CERT_FILE` ou coloque `C:\\cacert.pem`

## Instalação

1. Clone o repositório e entre na pasta do projeto
2. Instale dependências do sistema:
   - Ubuntu/Debian:
     ```bash
     sudo apt update && sudo apt install -y ffmpeg imagemagick python3 python3-pip
     pip3 install yt-dlp
     ```
   - Windows (chocolatey):
     ```powershell
     choco install ffmpeg imagemagick python
     pip install yt-dlp
     ```
3. Instale gems:
   ```bash
   gem install bundler
   bundle install
   ```
4. Copie `.env.example` para `.env` e preencha variáveis:
   ```bash
   cp .env.example .env
   ```

## Variáveis de ambiente

- `TELEBOT_TOKEN` (obrigatório): token do BotFather
- `RUN_BOT` (opcional, padrão `true`): defina `false` para executar testes sem iniciar o long-polling
- `SSL_CERT_FILE` (Windows): caminho para bundle de certificados (ex.: `C:\\cacert.pem`)

## Uso

```bash
bundle exec ruby bot.rb
```

Comandos no chat:

- `/download <url> [audio]`: baixa vídeo (mp4) ou áudio (mp3) se usar `audio`
- `/trim <start> <dur>`: corta vídeo (ex.: `/trim 00:00:10 5`)
- `/convert <fmt>`: converte vídeo para formato (ex.: `mp3`, `mp4`, `mkv`)
- `/adjustaudio <velocidade> <volume>`: ajusta áudio (ex.: `/adjustaudio 1.25 0.8`)
- `/qrcode <texto>`: gera QR Code com o texto fornecido
- `/removebg`: remove o fundo da última imagem processada
- `/fusion`: funde as 2 últimas imagens enviadas
- `/help`: ajuda

## Estrutura do projeto

```
Telebot/
  bot.rb
  lib/
    util_tools.rb
    telebot/
      handler.rb
  Gemfile
  dockerfile
  procfile
  fly.toml
  spec/
    spec_helper.rb
    support/
      telegram_helpers.rb
    unit/
      util_tools_spec.rb
    integration/
      handler_commands_spec.rb
    acceptance/
      lifecycle_spec.rb
  .env.example
  .gitignore
  README.md
```

## Testes

Rodar toda a suíte:

```bash
bundle exec rspec
```

### Tipos
- Unitários: `spec/unit/*`
- Integração (sem Telegram real): `spec/integration/*`
- Aceitação (fluxos principais): `spec/acceptance/*`

Os testes usam `RUN_BOT=false` para não iniciar o long polling. Também usam stubs/mocks para chamadas externas (Telegram API, yt-dlp, ffmpeg, etc.).

## Docker

Build e run local:

```bash
# Use -f dockerfile, pois o arquivo não se chama Dockerfile
docker build --pull --no-cache -t telebot -f dockerfile .
docker run --rm -e TELEBOT_TOKEN=xxxx telebot
```

Observações:

- Em Windows, certifique-se de que o Docker Desktop está em execução (WSL2 habilitado). Se o build falhar com erro de pipe/named pipe, abra o Docker Desktop e tente novamente.
- A imagem foi migrada para multi-stage com base `ruby:3.3-alpine3.20`, instalando apenas dependências de runtime no estágio final e executando `apk upgrade --no-cache` para reduzir CVEs.

## Deploy

- Fly.io: configure `fly.toml` e `TELEBOT_TOKEN` como secret.

## Boas práticas e tratamento de erros

- Todas as operações validam entradas e verificam arquivos de saída.
- Erros são enviados ao chat quando acontecem durante o processamento.

## Licença

MIT


