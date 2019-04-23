#!/bin/bash

#################################################
#												#
#         INSTALACIÓN DE WORDPRESS		 		#
#     NGINX - PHP-FPM - MYSQL-CLIENT	 		#
# 												#
#        Reinaldo León Revisión (1)				#
# Amazon Linux AMI 2017.09.1 - ami-1a962263		#
#												#
#################################################

echo "INSTALACIÓN DE WORDPRESS LATEST"
echo "Nubersia 2017 Revisión (1)"
echo "Nginx (Virtual Host) - PHP-FPM " 
sleep 2

#INSTALACION DEL NGINX

sudo yum update -y
yum -y install nginx
chkconfig --add nginx 
chkconfig nginx on

echo "Introduzca un nombre para el Virtual Host (Ejemplo: dominio_com, dominio)"
read vhost

echo "Indique su nombre de dominuo para" $vhost " (Ejemplo: wiki.dominio.com, mediawiki.dominio.com)"
read domain

#Vhost

cd /etc/nginx/conf.d/
touch $vhost.conf
conf=/etc/nginx/conf.d/$vhost.conf
cat >> $conf << EOF
server {
        listen 80 default_server;
        server_name $domain;
        client_max_body_size 60m;
        
        #Redirect https
        #if ($http_x_forwarded_proto != 'https') {
        #     return 301 https://$host$request_uri;
        #}
        
        #Redirect www
        #if ($http_host !~ "^www\."){
        #     rewrite ^(.*)$ $scheme://www.$http_host$1 redirect;
        #}
        location / {
            try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
            root   /var/www/$domain/;
            access_log /var/log/nginx/$vhost-access.log;
            error_log /var/log/nginx/$vhost-error.log;
            index  index.html index.htm index.php;
            proxy_connect_timeout 120;
        # redirect server error pages to the static page /40x.html
        error_page 404 /404.html;
            location = /40x.html {
        }
        location ~*  \.(jpg|jpeg|png|gif|ico|css|js|swf|flv)$ {
        expires 365d;
        }
        location ~*  \.(pdf)$ {
        expires 30d;
        }
        # Activar Compresión Gzip
        gzip on;
        gzip_min_length 200;
        gzip_buffers 4 32k;
        gzip_types text/plain application/x-javascript text/xml text/css application/javascript video/mp4 image/jpg image/jpeg image/png image/gif video/webm video/ogg;
        gzip_vary on;
        # Fin de Compresión Gzip
        
        # redirect server error pages to the static page /50x.html
        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }

        }

        location ~ \.php$ {
            root /var/www/$domain/;
            access_log /var/log/nginx/$vhost-access.log;
            error_log /var/log/nginx/$vhost-error.log;
            fastcgi_pass   unix:/var/run/php-fpm/php-fpm.sock;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
            include        fastcgi_params;
            proxy_connect_timeout 120;
        }
}
EOF
 
#Sustituimos el default server al virtualhost

sed -i 's/listen       80 default_server;/listen       80;/g' "/etc/nginx/nginx.conf"

#Habilitar el repositorio Epel
sudo yum-config-manager --enable epel

#INSTALAR PHP7, MySQL-Client

yum -y install php72-fpm php72-pecl-mcrypt php72-cli php72-mysqlnd php72-gd  php72-json php72-intl php7-pear php72-devel php72-mbstring php72-soap
chkconfig  --add php-fpm
chkconfig php-fpm on
service php-fpm restart

#Editamos el fichero /etc/php.ini

sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' "/etc/php.ini"
#cgi.fix_pathinfo=0
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' "/etc/php.ini"
#memory_limit = 512M
sed -i 's/max_execution_time = 30/max_execution_time = 1800/g' "/etc/php.ini"
#max_execution_time = 1800
sed -i 's/zlib.output_compression = Off/zlib.output_compression = On/g' "/etc/php.ini"
#zlib.output_compression = On
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' "/etc/php.ini"
#upload_max_filesize
sed -i 's/max_file_uploads = 20/umax_file_uploads = 50/g' "/etc/php.ini"
#upload_max_filesize

#Editamos el fichero /etc/php-fpm.d/www.conf

sed -i 's/user = apache/user = nginx/g' "/etc/php-fpm.d/www.conf"
#user = nginx 
sed -i 's/group = apache/group = nginx/g' "/etc/php-fpm.d/www.conf"
#group = nginx
sed -i 's/listen = 127.0.0.1:9000/;listen = 127.0.0.1:9000/g' "/etc/php-fpm.d/www.conf"
sed -i '/;listen = 127.0.0.1:9000/a listen = /var/run/php-fpm/php-fpm.sock'  /etc/php-fpm.d/www.conf
#listen = /var/run/php/php-fpm.sock
sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' "/etc/php-fpm.d/www.conf"
#listen.owner = nginx 
sed -i 's/;listen.group = nobody/listen.group = nginx/g' "/etc/php-fpm.d/www.conf"
#listen.group = nginx 
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' "/etc/php-fpm.d/www.conf"
#listen.mode = 0660


#DESCARGAR LA ULTIMA VERSION DEL WORDPRESS

mkdir -p /var/www/
cd /var/www/
wget http://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz
mv wordpress /var/www/$domain
chown -R nginx:nginx /var/www/$domain/
chmod 755 /var/www/$domain/


service nginx start
service php-fpm start

#Instalando y configurando la Conexión a la DB


echo -e " Instalación del motor de Base de Datos MySQL 5.7 \n"
echo -e " Introduzca el password para el usuario root \n"
read passwdroot

echo -e "Indique el nombre para su Base de Datos (Evite utilizar carácteres especiales) \n"
read db

echo -e "Indique el nombre del usuario administrador para la Base de Datos "$db "\n"
read userdb

echo -e "Introduzca la contraseña para el usuario " $userdb " el cual será administrador de la Base de Datos " $db "\n"
read passwduserdb

#Instalamos el servicio MySQL57 y lo iniciamos
yum install mysql57-server -y
service mysqld start

mysql -u root -s -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$passwdroot'; CREATE DATABASE $db; CREATE USER '$userdb'@'localhost' IDENTIFIED BY '$passwduserdb'; GRANT ALL PRIVILEGES ON $db.* TO '$userdb'@'localhost'; FLUSH PRIVILEGES;"


COMMENT

#FIN DE LA INSTALACIÓN
clear
echo -e "\n\n\n"
echo -e "		Instalación finalizada, puede ingresar a la instalación de su WordPress través de la URL http://$domain"
echo -e "	y posteriormente a su panel de administración a través de la URL http://$domain/wp-admin \n"
echo -e "				Recuerde guardar la información de su Base de Datos en un lugar seguro \n"
echo -e "		Password de root= "$passwdroot" / Base de Datos para WordPress= "$db" / Usuario= "$userdb" / Password= "$passwduserdb"  \n\n"