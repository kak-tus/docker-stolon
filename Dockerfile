FROM postgres:9.6

ENV STOLON_VERSION=0.5.0

COPY stolon-v${STOLON_VERSION}-linux-amd64.tar.gz_SHA256SUMS /usr/local/bin/stolon-v${STOLON_VERSION}-linux-amd64.tar.gz_SHA256SUMS

RUN \
  apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
  curl ca-certificates \

  && cd /usr/local/bin \
  && curl -L https://github.com/sorintlab/stolon/releases/download/v${STOLON_VERSION}/stolon-v${STOLON_VERSION}-linux-amd64.tar.gz -o stolon-v${STOLON_VERSION}-linux-amd64.tar.gz \
  && sha256sum -c stolon-v${STOLON_VERSION}-linux-amd64.tar.gz_SHA256SUMS \
  && tar -zxvf stolon-v${STOLON_VERSION}-linux-amd64.tar.gz \

  && cp ./stolon-v${STOLON_VERSION}-linux-amd64/stolon-keeper ./ \
  && cp ./stolon-v${STOLON_VERSION}-linux-amd64/stolon-proxy ./ \
  && cp ./stolon-v${STOLON_VERSION}-linux-amd64/stolon-sentinel ./ \
  && cp ./stolon-v${STOLON_VERSION}-linux-amd64/stolonctl ./ \

  && rm -rf ./stolon-v${STOLON_VERSION}-linux-amd64 \
  && rm stolon-v${STOLON_VERSION}-linux-amd64.tar.gz stolon-v${STOLON_VERSION}-linux-amd64.tar.gz_SHA256SUMS \

  && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \

  && apt-get remove -y curl ca-certificates && rm -rf /var/lib/apt/lists/*

ENV CONSUL_HTTP_ADDR=
ENV CONSUL_TOKEN=

ENV PG_REPL_USERNAME=
ENV PG_REPL_PASSWORD=
ENV PG_SU_PASSWORD=
ENV EXT_HOSTNAME=
ENV STOLON_CLUSTER_NAME=

ENV SET_CONTAINER_TIMEZONE=true
ENV CONTAINER_TIMEZONE=Europe/Moscow

ENV LANG=ru_RU.UTF-8

COPY stolon-entrypoint.sh /usr/local/bin/stolon-entrypoint.sh

ENTRYPOINT /usr/local/bin/stolon-entrypoint.sh
