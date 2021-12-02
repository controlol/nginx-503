FROM alpine
LABEL maintainer "Luc Appelman lucapppelman@gmail.com"

RUN set -ex && \
    addgroup --system --gid 101 nginx; \
    adduser -S -G nginx -g "nginx user" -s /sbin/nologin -u 101 nginx

RUN set -ex; \
    apk add --update-cache \
        build-base \
        curl

RUN set -eux; \
    PCRE_VERSION=8.44 \
    NGINX_VERSION=1.19.10 \
    ZLIB_VERSION=1.2.11 \
    OPENSSL_VERSION=1_1_1g \
    NGINX_LOG_PATH=/var/log/nginx \
    NGINX_USER=www-data \
    NGINX_GROUP=www-data \
    TMP_DIR=$(mktemp -d); \
    curl -Ls https://github.com/nginx/nginx/archive/release-${NGINX_VERSION}.tar.gz | tar -xzf - -C ${TMP_DIR}; \
    curl -Ls https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz | tar -xzf - -C ${TMP_DIR}; \
    curl -Ls https://github.com/madler/zlib/archive/v${ZLIB_VERSION}.tar.gz | tar -xzf - -C ${TMP_DIR}; \
    curl -Ls https://github.com/openssl/openssl/archive/OpenSSL_${OPENSSL_VERSION}.tar.gz | tar -xzf - -C ${TMP_DIR}; \
    cd ${TMP_DIR}/nginx-release-${NGINX_VERSION}; \
    ./auto/configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --group=${NGINX_GROUP} \
        --user=${NGINX_USER} \
        --with-cc-opt='-D_FORTIFY_SOURCE=2 -pie -fPIE -fstack-protector -Wformat -Wformat-security -fstack-protector -g -O1' \
        --with-ld-opt='-Wl,-z,now -Wl,-z,relro' \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-http_ssl_module --with-openssl=${TMP_DIR}/openssl-OpenSSL_${OPENSSL_VERSION} \
        --with-pcre=${TMP_DIR}/pcre-${PCRE_VERSION} \
        --with-zlib=${TMP_DIR}/zlib-${ZLIB_VERSION}; \
    make install; \
    rm -rf ${TMP_DIR}

ADD root /

EXPOSE 80
WORKDIR /etc/nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log

CMD ["nginx", "-g", "daemon off;"]
