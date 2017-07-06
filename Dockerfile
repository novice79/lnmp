FROM ubuntu:latest
MAINTAINER David <david@cninone.com>

# Get noninteractive frontend for Debian to avoid some problems:
#    debconf: unable to initialize frontend: Dialog
ENV DEBIAN_FRONTEND noninteractive

ENV LANG       en_US.UTF-8
ENV LC_ALL	   "C.UTF-8"
ENV LANGUAGE   en_US:en

RUN apt-get update -y && apt-get install -y \
    software-properties-common python-software-properties supervisor language-pack-en-base \
    curl git vim cron inetutils-ping wget net-tools tzdata redis-server

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
RUN add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mariadb.mirror.anstey.ca/repo/10.2/ubuntu xenial main'
ENV MARIADB_MAJOR 10.2
RUN { \
		echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password password 'freego'; \
		echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password_again password 'freego'; \
	} | debconf-set-selections \
	&& apt-get update && apt-get install -y nginx \
        php7.0-cli php7.0-common php7.0 php7.0-mysql php7.0-fpm php7.0-curl php7.0-gd \
        php7.0-intl php7.0-mcrypt php7.0-readline php7.0-tidy php7.0-json php7.0-sqlite3 \
        php7.0-bz2 php7.0-mbstring php7.0-xml php7.0-zip php7.0-opcache php7.0-bcmath \
        mariadb-server lsof upstart-sysv \
    && update-initramfs -u \    
    && apt-get purge systemd -y \    
	&& rm -rf /var/lib/apt/lists/* 
    #&& apt-get clean && apt-get autoclean && apt-get remove  
COPY my.cnf /etc/mysql/my.cnf
	
# mariadb end

COPY nginx/index.php /var/www/index.php
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx/freego.crt /etc/ssl/freego.crt
COPY nginx/freego.key /etc/ssl/freego.key
COPY init.sh /

RUN chown -R www-data:www-data /var/www && chmod +x /init.sh

VOLUME ["/var/www", "/var/lib/mysql"]


EXPOSE 80 443 3306

ENTRYPOINT ["/init.sh"]
