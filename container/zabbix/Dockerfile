FROM alpine:edge
MAINTAINER T.K "oonumchi@gmail.com"
RUN apk update && apk add --upgrade apk-tools mysql-client

# -- NGINX --- #
RUN apk add --no-cache nginx tzdata \
    && cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && apk del tzdata \
    && rm -rf /var/cache/apk/*

# NGINXの設定ファイルの配置
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# ------------ #

# -- PHP ----- #
RUN apk add --no-cache vim sqlite \
    php7 \
    php7-fpm \
    php7-mcrypt \
    php7-openssl \
    php7-gmp \
    php7-json \
    php7-pdo \
    php7-pdo_mysql \
    php7-mysqli \
    php7-zip \
    php7-sqlite3 \
    php7-gd \
    php7-pdo_sqlite \
    php7-curl \
    php7-ctype \
    php7-tokenizer \
    php7-dom \
    php7-session \
    php7-simplexml \
    php7-mbstring \
    php7-xml \
    php7-opcache \
    php7-ldap \
  && rm -rf /var/cache/apk/*

# PHP-FPMの設定ファイルを配置
COPY phpfpm/php-fpm.conf /etc/php7/php-fpm.conf
COPY phpfpm/www.conf /etc/php7/php-fpm.d/www.conf

# PHPの設定ファイルを配置
COPY php/php.ini /etc/php7/php.ini

# PHP-FPM動作用のディレクトリを作成と権限の付与
RUN mkdir /var/run/php
RUN chown nginx:nginx /var/run/php
RUN chmod 755 /var/run/php

# ------------ #

# -- ZABBIX -- #
RUN apk add --no-cache zabbix zabbix-mysql zabbix-webif zabbix-setup \
  && rm -rf /var/cache/apk/*

# 設定ファイルの配置
COPY zabbix_server.conf /etc/zabbix/zabbix_server.conf

# ドキュメントルートの所有者と権限を変更
RUN chown -R nginx:nginx /usr/share/webapps/zabbix
RUN chmod -R 744 /usr/share/webapps/zabbix
RUN chmod u+s /usr/sbin/fping

# ------------ #

# -- NGINXとPHP-FPMとZABBIXの起動シェルを配置 -- #
RUN mkdir /entrypoint
COPY run.sh /entrypoint/run.sh

# 所有者と権限の変更
RUN chown root:root /entrypoint/run.sh
RUN chmod 755 /entrypoint/run.sh

# -------------------------------------- #

# NGINXとPHP-FPMとZABBIX-SERVERを起動
ENTRYPOINT ["/entrypoint/run.sh"]
