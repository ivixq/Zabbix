#!/bin/sh
echo '[INFO] Container initialization processing start.'

if [ $DATABASE_ROOT_PASSWORD = "" ] ; then
    echo "[ERROR] environment variable DATABASE_ROOT_PASSWORD is empty."
    exit
fi

if [ $DATABASE_USERNAME = "" ] ; then
    echo "[ERROR] environment variable DATABASE_USERNAME is empty."
    exit
fi

if [ $DATABASE_PASSWORD = "" ] ; then
    echo "[ERROR] environment variable DATABASE_PASSWORD is empty."
    exit
fi

if [ $DATABASE_NAME = "" ] ; then
    echo "[ERROR] environment variable DATABASE_NAME is empty."
    exit
fi

if [ ! -f /var/lib/mysql/WORKING ] ; then
    # データディレクトリにWORKINGファイルがなければ初期化処理を走らせる
    echo '[INFO] Database initialization processing start.'

    # 初期化SQL
    SQL="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '${DATABASE_ROOT_PASSWORD}' WITH GRANT OPTION; \
         GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY '${DATABASE_ROOT_PASSWORD}' WITH GRANT OPTION; \
         FLUSH PRIVILEGES; \
         CREATE USER '${DATABASE_USERNAME}'@'%' IDENTIFIED BY '${DATABASE_PASSWORD}'; \
         CREATE USER '${DATABASE_USERNAME}'@'localhost' IDENTIFIED BY '${DATABASE_PASSWORD}'; \
         CREATE DATABASE ${DATABASE_NAME}; \
         GRANT ALL ON ${DATABASE_NAME}.* to '${DATABASE_USERNAME}'@'%' IDENTIFIED BY '${DATABASE_PASSWORD}' WITH GRANT OPTION; \
         GRANT ALL ON ${DATABASE_NAME}.* to '${DATABASE_USERNAME}'@'localhost' IDENTIFIED BY '${DATABASE_PASSWORD}' WITH GRANT OPTION; \
         FLUSH PRIVILEGES;"

         # MariaDBを起動
         /usr/bin/mysqld_safe --user=mysql --datadir=/var/lib/mysql --console &
         # 起動しきるまで待機
         sleep 5s
         echo '[INFO] MariaDB start.'

         # 初期化SQLを投入
         echo ${SQL} | mysql -u root --password="" -t
         echo '[INFO] Database initialization processing end.'

         # 処理終了のフラグファイルを作成する
         touch /var/lib/mysql/WORKING

elif [ -f /var/lib/mysql/WORKING ] ; then
    echo '[INFO] The database has already been initialized.'

    # MariaDBの起動状態を確認する
    if [ $(ps -ef | grep mysqld_safe | grep -v grep | wc -l) = 0 ]; then
        echo '[INFO] mysqld_safe is not execute.'

        # MariaDBを起動
        /usr/bin/mysqld_safe --user=mysql --datadir=/var/lib/mysql --console
        sleep 5s

        echo '[INFO] MariaDB start'

    elif [ $(ps -ef | grep mysqld_safe | grep -v grep | wc -l) = 1 ]; then
        echo '[INFO] mysqld_safe has already been execute.'
    else
        echo '[WARNING] An unnecessary process may be running.'
    fi

fi

echo '[INFO] Container initialization processing end.'
