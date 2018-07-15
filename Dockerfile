FROM ubuntu:18.04
MAINTAINER David <david@cninone.com>

# Get noninteractive frontend for Debian to avoid some problems:
#    debconf: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive

ENV LANG       en_US.UTF-8
ENV LC_ALL	   "C.UTF-8"
ENV LANGUAGE   en_US:en

RUN apt-get update -y && apt-get install -y \
    software-properties-common supervisor language-pack-en-base tzdata

RUN mkdir -p /var/log/supervisor /var/log/nginx /run/php 

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile \
    && echo "/var/www *(rw,async,no_subtree_check,insecure)" >> /etc/exports \
    && echo "export TERM=xterm" >> ~/.bashrc
ENV TZ=Asia/Chongqing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# mariadb begin
RUN groupadd -r mysql && useradd -r -g mysql mysql

RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
RUN add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.neusoft.edu.cn/mariadb/repo/10.3/ubuntu bionic main'
ENV MARIADB_MAJOR 10.3
RUN { \
		echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password password 'freego'; \
		echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password_again password 'freego'; \
	} | debconf-set-selections \
	&& apt-get update && apt-get install -y nginx \
        php-cli php-common php php-mysql php-fpm php-curl php-gd \
        php-intl php-readline php-tidy php-json php-sqlite3 \
        php-bz2 php-mbstring php-xml php-zip php-opcache php-bcmath php-redis \
        mariadb-server \
    && apt-get clean && apt-get autoclean && apt-get remove  \
    && rm -rf /var/lib/apt/lists/* 

# open galera cluster here    
COPY my.cnf /etc/mysql/my.cnf	
# mariadb end

COPY nginx/index.php /var/www/index.php
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY init.sh /

RUN chown -R www-data:www-data /var/www && chmod +x /init.sh \
    && touch /var/log/php_errors.log && chmod 666 /var/log/php_errors.log

VOLUME ["/var/www", "/var/lib/mysql"]


EXPOSE 80 443 3306

ENTRYPOINT ["/init.sh"]
