FROM debian:8

# less privilege user
RUN groupadd -r dummy && useradd -r -g dummy dummy -u 1000

# FIX Debian 8 old repositories
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i '/security.debian.org/d' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid

# webui + aria2
RUN apt-get update \
    && apt-get install -y aria2 busybox curl \
    && rm -rf /var/lib/apt/lists/*

# Copy webui files
ADD ./docs /webui-aria2

# gosu install latest
RUN GITHUB_REPO="https://github.com/tianon/gosu" \
    && LATEST=$(curl -s $GITHUB_REPO/releases/latest | grep -Eo "[0-9]+\.[0-9]+") \
    && curl -L $GITHUB_REPO/releases/download/$LATEST/gosu-amd64 > /usr/local/bin/gosu \
    && chmod +x /usr/local/bin/gosu

# goreman install latest
RUN GITHUB_REPO="https://github.com/mattn/goreman" \
    && LATEST=$(curl -s $GITHUB_REPO/releases/latest | grep -Eo "v[0-9]+\.[0-9]+\.[0-9]+") \
    && curl -L $GITHUB_REPO/releases/download/$LATEST/goreman_${LATEST}_linux_amd64.tar.gz > goreman.tar.gz \
    && tar xvf goreman.tar.gz && mv goreman*/goreman /usr/local/bin/goreman && rm -rf goreman*

# goreman Procfile setup
RUN echo "web: gosu dummy /bin/busybox httpd -f -p 8080 -h /webui-aria2\n\
backend: gosu dummy /usr/bin/aria2c --enable-rpc --rpc-listen-all --dir=/data" > /Procfile

# Define volumes and expose ports
VOLUME /data
EXPOSE 6800
EXPOSE 8080

# Entrypoint and command
ENTRYPOINT ["/usr/local/bin/goreman"]
CMD ["start"]
