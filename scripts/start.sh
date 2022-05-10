#!/bin/bash

# Install Extras
if [ ! -z "$RPMS" ]; then
 yum install -y $RPMS
fi

# Display PHP error's or not
if [[ "$ERRORS" == "true" ]] ; then
  sed -i -e "s/error_reporting =.*/error_reporting = E_ALL/g" /etc/php.ini
  sed -i -e "s/display_errors =.*/display_errors = On/g" /etc/php.ini
fi

# Create path for PHP sessions
mkdir -p -m 0777 /var/lib/php/session

# Set PHP timezone
if [ -z "$PHPTZ" ]; then
  PHPTZ="Detroit/America"
fi
echo date.timezone = $PHPTZ >>/etc/php.ini

# Tweak nginx to match the workers to cpu's

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

PHPVERSION=$(php --version | grep '^PHP' | sed 's/PHP \([0-9]\.[0-9]*\).*$/\1/')
mkdir /usr/local/ioncube
cp /tmp/ioncube/ioncube_loader_lin_$PHPVERSION.so /usr/local/ioncube
echo zend_extension = /usr/local/ioncube/ioncube_loader_lin_$PHPVERSION.so >>/etc/php.ini

# Install the WHMCS
if [ ! -e /usr/share/nginx/html/.first-run-complete ]; then
  rm -f /usr/share/nginx/html/*.html
  unzip /blesta-5.4.0.zip -d /tmp
  mv /tmp/blesta-5.4.0/blesta/* /usr/share/nginx/html 
  mv /tmp/blesta-5.4.0/uploads /usr/share/nginx/html && rm -f /tmp/blesta-5.4.0
  rm -f /blesta-5.4.0.zip

  echo "Do not remove this file." > /usr/share/nginx/html/.first-run-complete
fi

# Again set the right permissions (needed when mounting from a volume)
chown -Rf nginx.nginx /usr/share/nginx/html/

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
