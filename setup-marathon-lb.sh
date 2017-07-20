#!/bin/sh

mkdir /tmp/marathon-lb
cp set-marathon-lb-variables.sh /tmp/marathon-lb/.
cp marathon-lb-requirements.txt /tmp/marathon-lb/.
cp setup-marathon-lb.sh /tmp/marathon-lb/.
cd /tmp/marathon-lb

apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        iptables \
        libcurl3 \
        liblua5.3-0 \
        libssl1.0.2 \
        openssl \
        procps \
        python3 \
        runit \
        socat \

rm -rf /var/lib/apt/lists/*

source ./set-marathon-lb-variables.sh

set -x \
    && apt-get update && apt-get install -y --no-install-recommends dirmngr gnupg2 wget \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O tini "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini-amd64" \
    && wget -O tini.asc "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$TINI_GPG_KEY" \
    && gpg --batch --verify tini.asc tini \
    && rm -rf "$GNUPGHOME" tini.asc \
    && mv tini /usr/bin/tini \
    && chmod +x /usr/bin/tini \
    && tini -- true \
    && apt-get purge -y --auto-remove dirmngr gnupg2 wget

set -x \
    && buildDeps='gcc libcurl4-openssl-dev libffi-dev liblua5.3-dev libpcre3-dev libssl-dev make python3-dev python3-pip python3-setuptools wget zlib1g-dev' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O haproxy.tar.gz "https://www.haproxy.org/download/$HAPROXY_MAJOR/src/haproxy-$HAPROXY_VERSION.tar.gz" \
    && echo "$HAPROXY_MD5  haproxy.tar.gz" | md5sum -c \
    && mkdir -p /usr/src/haproxy \
    && tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
    && rm haproxy.tar.gz \
    && make -C /usr/src/haproxy \
        TARGET=linux2628 \
        ARCH=x86_64 \
        USE_LUA=1 \
        LUA_INC=/usr/include/lua5.3/ \
        USE_OPENSSL=1 \
        USE_PCRE_JIT=1 \
        USE_PCRE=1 \
        USE_REGPARM=1 \
        USE_STATIC_PCRE=1 \
        USE_ZLIB=1 \
        all \
        install-bin \
    && rm -rf /usr/src/haproxy \
    && export LC_ALL=C \
    && pip3 install --no-cache --upgrade --force-reinstall -r ./marathon-lb-requirements.txt \
    && apt-get purge -y --auto-remove $buildDeps

mkdir /marathon-lb
cd /marathon-lb
git clone https://github.com/mesosphere/marathon-lb.git .
git checkout tags/v1.8.0

export PORTS="80,443,9090,9091"
/marathon-lb/run sse --health-check --group external &
