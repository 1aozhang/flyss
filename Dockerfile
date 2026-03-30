FROM debian:bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates build-essential autoconf automake libtool \
    libssl-dev libpcre3-dev libev-dev asciidoc xmlto pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone --depth=1 https://github.com/shadowsocks/simple-obfs.git \
    && cd simple-obfs \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure \
    && make -j"$(nproc)" \
    && make install DESTDIR=/out

FROM shadowsocks/shadowsocks-libev:latest

COPY --from=builder /out/usr/local/bin/obfs-local /usr/local/bin/obfs-local
COPY --from=builder /out/usr/local/bin/obfs-server /usr/local/bin/obfs-server
COPY config.json /etc/shadowsocks-libev/config.json

RUN chmod +x /usr/local/bin/obfs-local /usr/local/bin/obfs-server

#CMD exec ss-server \
#      -s $SERVER_ADDR \
#      -p $SERVER_PORT \
#      -k ${PASSWORD:-$(hostname)} \
#      -m $METHOD \
#      -t $TIMEOUT \
#      -d $DNS_ADDRS \
#      -u \
#      -v \
#      $ARGS

CMD exec ss-server -c /etc/shadowsocks-libev/config.json
