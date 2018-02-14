FROM alpine:edge
MAINTAINER T.K "oonumchi@gmail.com"
RUN apk update && apk add --upgrade apk-tools

# パッケージのインストール
RUN apk --no-cache add mysql mysql-client tzdata

# タイムゾーンを日本時間に設定する
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
RUN apk del tzdata

# MariaDB動作用のディレクトリを作成
RUN mkdir -p /run/mysqld
RUN chown -R mysql:mysql /run/mysqld
RUN chown -R mysql:mysql /var/lib/mysql

# MariaDBの初期化
RUN mysql_install_db --datadir=/var/lib/mysql --user=mysql

# my.cnfのコピー
COPY my.cnf /etc/mysql/my.cnf

# MariaDB起動用スクリプトを配置と実行権限の付与
ADD run.sh /scripts/run.sh
RUN chmod -R 755 /scripts

# ポートの公開
EXPOSE 3306

# コンテナ生成時に実行するコマンド
# (MariaDBの初期設定と起動を実行)
ENTRYPOINT ["/scripts/run.sh"]
