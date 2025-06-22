FROM ruby:3.4.4-bullseye

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update && apt-get install -y \
  curl \
  unzip \
  git \
  libssl-dev \
  libyaml-dev \
  libffi-dev \
  build-essential \
  libwoff1 \
  libopus0 \
  libflite1 \
  libharfbuzz-icu0 \
  libenchant-2-2 \
  libsecret-1-0 \
  libhyphen0 \
  libmanette-0.2-0 \
  libunwind8 \
  libdw1 \
  libegl1 \
  libgudev-1.0-0 \
  libgles2 \
  fonts-liberation \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libcups2 \
  libdbus-1-3 \
  libdrm2 \
  libnspr4 \
  libnss3 \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxrandr2 \
  xdg-utils \
  libgbm1 \
  libgtk-3-0 \
  gstreamer1.0-libav \
  libglx0 \
  nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists

RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g yarn

WORKDIR /app
COPY . .

CMD ["irb"]