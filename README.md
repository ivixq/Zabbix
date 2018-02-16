# 概要

`Docker`を使用した`Zabbix`のインストールと起動。

# 必要要件

## ソフトウェア

| パッケージ      | バージョン   |
| :-------------- | :----------- |
| docker          | `17.06.1-ce` |
| docker-compose  | `1.14.0`     |

# 構成

## 生成コンテナ

| コンテナ名       | 役割                  | 備考                                                |
| :--------------- | :-------------------- | :-------------------------------------------------- |
| https-portal     | proxy server          | https://github.com/SteveLTN/https-portal            |
| mariadb          | database              | alpine linux                                        |
| zabbix           | zabbix server         | alpine linux                                        |

### コンテナ詳細

* `https-portal`
    - `alpine linux`
        - `nginx`
        - `Let's encrypt`

* `mariadb`
    - `alpine linux`
        - `MariaDB`

* `zabbix`
    - `alpine linux`
        - `nginx`
        - `php7`
        - `php-fpm7`
        - `zabbix`

## 生成ボリューム

| コンテナ名       | ボリューム名          |
| :--------------- | :-------------------- |
| https-portal     | ランダム文字列        |
| mariadb          | container_mariadb     |
| zabbix           | container_zabbix      |

`docker-compose.yml`でボリューム名を変更した場合はこの限りではない。

### 保持データ

* `container_mariadb`
    - `/var/lib/mysql`
* `container_zabbix`
    - `/etc/zabbix`
    - `/var/log/zabbix`

`docker-compose.yml`でボリューム先を変更・追加した場合はこの限りではない。

# 起動方法

1. 任意のディレクトリにこのリポジトリをクローンする。
    - `git clone https://github.com/sevenspice/Zabbix.git`
2. リポジトリへディレクトリ移動する。
    - `cd /path/to/Zabbix`
3. `Docker Compose`ファイルを環境に合わせて編集する。
    - `cp container/docker-compose.yml.origin container/docker-compose.yml`
    - `vi container/docker-compose.yml`
4. `Zabbix Server`の設定ファイルを環境に合わせて編集する。
    - `cp container/zabbix/zabbix_server.conf.origin container/zabbix/zabbix_server.conf`
    - `vi container/zabbix/zabbix_server.conf`
5. `https-portal`での公開ドメイン名を設定する。
    - `mv container/https-portal/nginx/conf.d/zabbix.example.com.conf.erb container/https-portal/nginx/conf.d/[公開するドメイン名].conf.erb`
    - `mv container/https-portal/nginx/conf.d/zabbix.example.com.ssl.conf.erb container/https-portal/nginx/conf.d/[公開するドメイン名].ssl.conf.erb`
6. ディレクトリを移動する。
    - `cd container`
7. コンテナをビルドして起動する。初回時の完全起動は時間がかかるため注意。
    - `docker-compose up -d --build`
8. ブラウザから`https://[公開するドメイン名]`で`Zabbix`のインストール画面が表示されれば起動完了。
9. 画面に従ってインストールすること。

起動後は個別にコンテナを制御するか`Docker Compose`を使用してコンテナを制御可能。

## コンテナの停止方法

1. リポジトリへディレクトリ移動する。
    - `cd /path/to/Zabbix`
2. ディレクトリを移動する。
    - `cd container`
3. コンテナをダウンする。
    - `docker-compose down`

# 環境ごとに変更する箇所

最低限以下に示すファイルの特定箇所をインストール環境に合わせて変更すること。

* `container/docker-compose.yml`
* `container/zabbix/zabbix_server.conf`
* `https-portal/nginx/conf.d/zabbix.example.com.conf.erb`
* `https-portal/nginx/conf.d/zabbix.example.com.ssl.conf.erb`


## `container/docker-compose.yml`

```
version: '2'
volumes:
    mariadb:
        driver: 'local'
    zabbix:
        driver: 'local'
services:
    mariadb:
        build: './mariadb'
        image: 'mariadb:latest'
        container_name: 'mariadb'
        volumes:
            - 'mariadb:/var/lib/mysql'
        hostname: 'mariadb'
        environment:
            # 1:MariaDBを初期化するための認証情報
            - DATABASE_ROOT_PASSWORD=p@ssword
            - DATABASE_NAME=zabbix
            - DATABASE_USERNAME=zabbix
            - DATABASE_PASSWORD=zabbix
        logging:
            driver: 'json-file'
            options:
                max-size: '10m'
                max-file: '1'
        restart: 'unless-stopped'
        networks:
            - 'alchymia'
    https-portal:
        build: './https-portal/nginx'
        image: 'https-portal'
        container_name: 'https-portal'
        ports:
            - '80:80'
            - '443:443'
        logging:
            driver: 'json-file'
            options:
                max-size: '10m'
                max-file: '1'
        volumes:
            - './https-portal/logs:/var/log/nginx'
        tty: true
        restart: 'always'
        environment:
            # 2:HTTPSアクセスされるドメイン名とリダイレクト先
            DOMAINS: 'zabbix.example.com -> http://zabbix'
            # 3:HTTPSの動作環境
            STAGE:   'local'
        networks:
            - 'alchymia'
    zabbix:
        build: './zabbix'
        image: 'zabbix:latest'
        container_name: 'zabbix'
        hostname: 'zabbix'
        environment:
            # 4:ZABBIXインストール時に接続するデータベースの認証情報
            - HOST_NAME=mariadb
            - DATABASE_NAME=zabbix
            - DATABASE_PORT=3306
            - DATABASE_USER=zabbix
            - DATABASE_PASSWORD=zabbix
        logging:
            driver: 'json-file'
            options:
                max-size: '10m'
                max-file: '1'
        volumes:
            - './zabbix/nginx/logs:/var/log/nginx'
            - './zabbix/nginx/conf.d:/etc/nginx/conf.d'
            - 'zabbix:/etc/zabbix'
            - 'zabbix:/var/log/zabbix'
        ports:
            - "10051:10051"
        depends_on:
            - 'mariadb'
        tty: true
        restart: 'unless-stopped'
        networks:
            - 'alchymia'
networks:
  alchymia:
    driver: 'bridge'

```

1. インストールされる`MariaDB`に設定される認証情報に変更すること。
    - `DATABASE_ROOT_PASSWORD`
        - `MariaDB`のrootユーザーのパスワード。
    - `DATABASE_NAME`
        - `MariaDB`の初期化時に作成するデータベース。
        - 下記で作成されるユーザーはここで作成したデータベースに全権限が付与される。
    - `DATABASE_USERNAME`
        - `MariaDB`の初期化時に作成されるユーザー。
    - `DATABASE_PASSWORD`
        - `MariaDB`の初期化時に作成されるユーザーのパスワード。
2. 公開するドメイン名に変更すること。
3. 本番公開する場合は`production`に変更すること。
    - `Let's encrypt`は一定時間内に繰り返し発行すると一時的に証明書が発行不可になるため注意すること。
    - テストなどでコンテナの再構築や再起動を繰り返す場合は`local`にすることをお勧めする。
4. `Zabbix Server`が接続するデータベースの認証情報に変更すること。
    - `DATABASE_NAME`
        - `1`で設定したデータベース名を指定する。
    - `DATABASE_USER`
        - `1`で設定したユーザー名を指定する。
    - `DATABASE_PASSWORD`
        - `1`で設定したパスワードを指定する。

より詳細に変更する場合は[Docker Compose](https://docs.docker.com/compose/)にある`Compose file`の
[version 2](https://docs.docker.com/compose/compose-file/compose-file-v2/)のリファレンスを参照して`docker-compose.yml`をカスタマイズすること。

## `container/zabbix/zabbix_server.conf`

`zabbix_server.conf`内の以下の行にあるデータベースへの認証情報を、`container/docker-compose.yml`にて設定した情報に変更すること。

* 97行目
    ```
    DBName=zabbix
    ```
* 113行目
    ```
    DBUser=zabbix
    ```
* 123行目
    ```
    DBPassword=zabbix
    ```

## `https-portal/nginx/conf.d/zabbix.example.com.conf.erb`

* `erb`ファイル名を公開するドメイン名に変更すること。
* `https-portal`の`nginx`設定を変更する場合は`erb`ファイル内を編集することで可能。

## `https-portal/nginx/conf.d/zabbix.example.com.ssl.conf.erb`

* `erb`ファイル名を公開するドメイン名に変更すること。
* `https-portal`の`nginx`設定を変更する場合は`erb`ファイル内を編集することで可能。

### 備考

いずれの変更も最低限の変更である。

より詳細に各ファイルの設定値を変更した場合、それに付随する設定も変更する必要があるので注意すること。

詳しくは以下のリファレンスを参照すること。

* [https-portal](https://github.com/SteveLTN/https-portal)
* [compose-file-v2](https://docs.docker.com/compose/compose-file/compose-file-v2/)
* [Zabbix Documentation 3.4](https://www.zabbix.com/documentation/3.4/manual)

