FROM postgres:9.6

ENV CONSUL_HTTP_ADDR=
ENV PG_REPL_USERNAME=
ENV PG_REPL_PASSWORD=
ENV PG_SU_PASSWORD=
ENV EXT_HOSTNAME=

COPY stolon-entrypoint.sh /usr/local/bin/stolon-entrypoint.sh
COPY stolon-v0.3.0-linux-amd64.tar.gz_SHA256SUMS /usr/local/bin/stolon-v0.3.0-linux-amd64.tar.gz_SHA256SUMS

RUN \
  apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
  curl ca-certificates

RUN \
  cd /usr/local/bin \

  && curl -L https://github.com/sorintlab/stolon/releases/download/v0.3.0/stolon-v0.3.0-linux-amd64.tar.gz -o stolon-v0.3.0-linux-amd64.tar.gz \
  && sha256sum -c stolon-v0.3.0-linux-amd64.tar.gz_SHA256SUMS \
  && tar -zxvf stolon-v0.3.0-linux-amd64.tar.gz \

  && cp ./stolon-v0.3.0-linux-amd64/stolon-keeper ./ \
  && cp ./stolon-v0.3.0-linux-amd64/stolon-proxy ./ \
  && cp ./stolon-v0.3.0-linux-amd64/stolon-sentinel ./ \
  && cp ./stolon-v0.3.0-linux-amd64/stolonctl ./ \

  && rm -rf ./stolon-v0.3.0-linux-amd64 \
  && rm stolon-v0.3.0-linux-amd64.tar.gz stolon-v0.3.0-linux-amd64.tar.gz_SHA256SUMS

RUN \
  apt-get remove -y curl ca-certificates && rm -rf /var/lib/apt/lists/*

ENTRYPOINT /usr/local/bin/stolon-entrypoint.sh
