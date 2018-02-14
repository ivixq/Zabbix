#!/bin/sh

echo '[INFO] Zabbix Container initialization processing start.'
sleep 10s

# 必要なデータを投入する
if [ ! -f /etc/zabbix/WORKING ]; then

    # ログディレクトリにWORKINGファイルがなければ初期化処理を走らせる
    echo '[INFO] Zabbix Database initialization processing start.'

    mysql -h ${HOST_NAME} -P ${DATABASE_PORT} -u ${DATABASE_USER} --password=${DATABASE_PASSWORD} ${DATABASE_NAME} < /usr/share/zabbix/database/mysql/schema.sql
    mysql -h ${HOST_NAME} -P ${DATABASE_PORT} -u ${DATABASE_USER} --password=${DATABASE_PASSWORD} ${DATABASE_NAME} < /usr/share/zabbix/database/mysql/images.sql
    mysql -h ${HOST_NAME} -P ${DATABASE_PORT} -u ${DATABASE_USER} --password=${DATABASE_PASSWORD} ${DATABASE_NAME} < /usr/share/zabbix/database/mysql/data.sql

    touch /etc/zabbix/WORKING
    echo '[INFO] Zabbix Database initialization processing end.'

elif [ -f /etc/zabbix/WORKING ] ; then
    echo '[INFO] The Zabbix database has already been initialized.'
fi

echo '[INFO] Zabbix Container initialization processing end.'

# -- サービス起動プロセス -- #

# NGINXの起動
/usr/sbin/nginx

# ZABBIX SERVERの起動
/usr/sbin/zabbix_server

# FPMの起動
# （FPMは最後に起動する）
/usr/sbin/php-fpm7 -F

# -------------------------- #
