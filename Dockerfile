FROM almalinux:8.5

ENV container docker

# Install supervisord
RUN \
  dnf update -y && \
  dnf install -y epel-release && \
  dnf install -y iproute supervisor hostname inotify-tools yum-utils which && \
  dnf clean all

# Install nginx
RUN dnf -y install nginx

# Install php-fpm etc as well as wget/unzip
RUN dnf -y install php-fpm php-mysqlnd php-ldap php-cli php-mbstring php-pdo php-pear php-xml php-soap php-gd wget unzip mariadb-server

# Get & extract ionCube Loader
RUN wget -O /tmp/ioncube.tgz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && tar -zxf /tmp/ioncube.tgz -C /tmp

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php.ini && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php.ini && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php-fpm.conf && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php-fpm.d/www.conf && \
sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php-fpm.d/www.conf && \
sed -i "s/user = apache/user = nginx/g" /etc/php-fpm.d/www.conf && \
sed -i "s/group = apache/group = nginx/g" /etc/php-fpm.d/www.conf

# tweak nginx config
RUN sed -i -e"s/worker_processes  1/worker_processes 5/" /etc/nginx/nginx.conf && \
sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
echo "daemon off;" >> /etc/nginx/nginx.conf

RUN mkdir /run/php-fpm && \
chown -Rf nginx.nginx /run/php-fpm

# nginx site conf
RUN rm -Rf /etc/nginx/conf.d/* && \
mkdir -p /etc/nginx/ssl/
ADD conf/nginx-site.conf /etc/nginx/conf.d/default.conf

# Supervisor Config
ADD conf/supervisord.conf /etc/supervisord.conf

# Start Supervisord
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# Download Blesta
RUN wget -P / https://account.blesta.com/client/plugin/download_manager/client_main/download/208/blesta-5.4.0.zip

# fix permissions
RUN chown -Rf nginx.nginx /usr/share/nginx/html/

# Setup Volume
VOLUME ["/usr/share/nginx/html"]

# Expose Ports
EXPOSE 443
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
