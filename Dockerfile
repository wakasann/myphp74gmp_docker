FROM alpine:latest
RUN echo http://mirrors.aliyun.com/alpine/v3.15/main/ > /etc/apk/repositories   \
        && echo http://mirrors.aliyun.com/alpine/v3.15/community/ >> /etc/apk/repositories   \
        && apk update && apk add build-base curl shadow openssh bash libxml2-dev openssl-dev  \
        && apk add libjpeg-turbo-dev libpng-dev libxpm-dev libmcrypt-dev binutils  \
        && apk add wget pcre-dev gcc make g++ php7-dev     && addgroup nginx   \
        && adduser -G nginx -D -s /sbin/nologin nginx && cd   \
        && wget http://nginx.org/download/nginx-1.20.2.tar.gz && tar -xf nginx-1.20.2.tar.gz   \
        && cd nginx-1.20.2 && ./configure --with-http_ssl_module --with-http_stub_status_module --prefix=/var/www --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --user=nginx --group=nginx     && make && make install  \
        && mkdir -p /var/lib/nginx/tmp/client_body     && apk add php7 php7-fpm php7-opcache php7-curl php7-gd php7-mbstring php7-mysqli  \
        && apk add php7-json php7-mcrypt php7-redis php7-pdo php7-pecl-memcache   \
        && apk add php7-pecl-mongodb php7-soap php7-pecl-protobuf php7-pecl-redis  php7-gmp \
        && apk add php7-pdo_mysql php7-pdo_sqlite php7-pdo_pgsql php7-pdo_dblib php7-pdo_odbc  \
        && apk add rabbitmq-c php7-pecl-amqp php7-bcmath php7-ctype php7-fileinfo php7-iconv   \
        && apk add php7-pcntl php7-phar php7-posix  php7-sysvmsg php7-sysvsem php7-sysvshm php7-zip  \
        && apk add php7-pecl-memcached php7-session php7-sockets php7-openssl php7-xml php7-xmlreader   \
        && apk add php7-xmlwriter php7-simplexml php7-xsl php7-ftp php7-tokenizer php7-imap   \
        && cd && wget https://pecl.php.net/get/swoole-4.4.14.tgz     && tar -xf swoole-4.4.14.tgz  \
        && cd swoole-4.4.14 &&  phpize     && ./configure --with-php-config=/usr/bin/php-config   \
        && make     && make install && echo 'extension=swoole.so' >> /etc/php7/php.ini   \
        && cd && apk add autoconf zlib-dev && export LIBS= && export CFLAGS=   \
        && wget https://pecl.php.net/get/xlswriter-1.3.6.tgz     && tar -xf xlswriter-1.3.6.tgz && cd xlswriter-1.3.6   \
        && phpize && ./configure --with-php-config=/usr/bin/php-config && make && make install   \
        && echo "extension=xlswriter.so" >> /etc/php7/php.ini   \
        && cd && wget https://github.com/swoole/ext-async/archive/refs/tags/v4.4.14.tar.gz    \
        && tar -xf v4.4.14.tar.gz && cd ext-async-4.4.14 && phpize   \
        && ./configure --with-php-config=/usr/bin/php-config && make -j 4   \
        && make install && echo 'extension=swoole_async.so' >> /etc/php7/php.ini   \
        && apk add -U tzdata && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime   \
        && curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/bin/composer \
        && echo "Asia/Shanghai" > /etc/timezone && apk del build-base shadow binutils gcc make g++ tzdata wget php7-dev     && rm -rf /var/cache/apk/* && rm -rf /root/*     && rm -rf /root/.cache && rm -rf /tmp/*

COPY supervisord.conf /root/supervisord.conf
RUN apk add supervisor py3-pip && mkdir -p /etc/supervisor/conf.d    \
        && mv /root/supervisord.conf /etc/supervisor/conf.d/supervisord.conf   \
        && echo '[include]' >> /etc/supervisord.conf    \
        && echo 'files = /etc/supervisor/conf.d/*.conf' >> /etc/supervisord.conf   \
        && sed -i "s#^upload_max_filesize.*#upload_max_filesize = 20M#" /etc/php7/php.ini   \
        && sed -i "s#^expose_php.*#expose_php = Off#" /etc/php7/php.ini   \
        && sed -i "s#^post_max_size.*#post_max_size = 20M#" /etc/php7/php.ini   \
        && sed -i "s#^memory_limit.*#memory_limit = 256M#" /etc/php7/php.ini  \
        && rm -rf /var/cache/apk/* && rm -rf /root/.cache && rm -rf /tmp/*

COPY nginx.conf /etc/nginx/nginx.conf
WORKDIR /var/www/html
EXPOSE 80 443
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
