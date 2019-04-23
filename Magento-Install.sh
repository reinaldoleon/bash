#!/bin/bash
#################################################
#      SERVICIO WEB  NGINX           	        #
# 	        PHP v70 | v71 | v72	        #
#      MOTOR BBDD MYSQL56 | MYSQL57 | MARIADB   #
#Amazon Linux AMI 2018.03.0 - ami-047bb4163c506cd98#
#						#
#################################################
clear
echo -e "\n    INSTALACIÓN DE MAGENTO"
sleep 3

###################################################
### INSTALACIÓN DEL SERVICIO WEB NGINX / APACHE ###
###################################################
echo -e "INSTALACIÓN DEL SERVICIO WEB NGINX: "


echo -e "DESCARGANDO PAQUETES NECESARIOS PARA INSTALAR NGINX... \n"
sleep 1
sudo yum update -y
yum -y install nginx
chkconfig --add nginx 
chkconfig nginx on
service nginx start
               


###################################################
### INSTALACIÓN DE PHP V- 7.0 / 7.1 / 7.2       ###
###################################################
clear
#Habilitar el repositorio Epel
sudo yum-config-manager --enable epel

echo -e "SELECCIONE LA VERSION DEL SERVICIO PHP A INSTALAR ( 72 | 71 | 70 | NINGUNO ): "
read PHPVERSION

PHPVERSION=$(echo ${PHPVERSION^^})
case "$PHPVERSION" in
        72)
                echo -e "DESCARGANDO LOS PAQUETES NECESARIOS PARA PHP V-7.2 ... \n"
                sleep 1
                sudo yum update -y
                yum -y install php72-fpm php72-pecl-mcrypt php72-cli \
                php72-mysqlnd php72-gd  php72-json php72-intl php7-pear \
                php72-devel php72-mbstring php72-soap
                chkconfig  --add php-fpm
                chkconfig php-fpm on
                ;;
         
        71)
                echo -e "DESCARGANDO LOS PAQUETES NECESARIOS PARA PHP V-7.1 ... \n"
                sleep 1
                sudo yum update -y
                sudo yum update -y
                yum -y install php71-fpm php71-mcrypt php71-cli \
                php71-mysqlnd php71-gd  php71-json php71-intl php7-pear \
                php71-devel php71-mbstring php71-soap
                chkconfig  --add php-fpm
                chkconfig php-fpm on
                ;;
        70)
                echo -e "DESCARGANDO LOS PAQUETES NECESARIOS PARA PHP V-7.0 ... \n"
                sleep 1
                sudo yum update -y
                yum -y install php70-fpm php70-mcrypt php70-curl php70-cli \
                php70-mysqlnd php70-gd php70-xsl php70-json php70-intl php7-pear \
                php70-devel php70-mbstring php70-zip php70-soap
                chkconfig  --add php-fpm
                chkconfig php-fpm on
                if [ "$WEBSERVER" = "NGINX" ]; then
                        sed -i 's/user = apache/user = nginx/g' "/etc/php-fpm.d/www.conf"
                        #user = nginx 
                        sed -i 's/group = apache/group = nginx/g' "/etc/php-fpm.d/www.conf"
                        #group = nginx
                        sed -i 's/listen = 127.0.0.1:9000/;listen = 127.0.0.1:9000/g' "/etc/php-fpm.d/www.conf"
                        sed -i '/;listen = 127.0.0.1:9000/a listen = /var/run/php-fpm/www.sock'  /etc/php-fpm.d/www.conf
                        #listen = /var/run/php/php-fpm.sock
                        sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' "/etc/php-fpm.d/www.conf"
                        #listen.owner = nginx 
                        sed -i 's/;listen.group = nobody/listen.group = nginx/g' "/etc/php-fpm.d/www.conf"
                        #listen.group = nginx 
                        sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' "/etc/php-fpm.d/www.conf"
                        #listen.mode = 0660
                fi
                ;;
        NINGUNO)
                echo -e "NO SE INSTALARÁ NINGUNA VERSION DE PHP"
                sleep 5
                ;;
        *)
            echo $"Usage: $0 {NGINX|APACHE|NINGUNO}"
            exit 1
esac


#################################################################
### CREACIÓN DEL VHOST PARA MAGENTO CON NGINX                 ###
#################################################################

clear
echo -e "\nDESEA CREAR UN VHOST PARA NGINX CONFIGURADO CON HTTPS PARA UN ELB (Y / N): "
read VHOST_ELB
if [ $VHOST_ELB = Y ] || [ $VHOST_ELB = y ]; then
    echo "INDIQUE EL NOMBRE DE DOMINIO PRINCIPAL PARA EL VHOST: "
    read DOMAIN
    
    sed -i 's/     listen       80 default_server;/      listen       80;/g' "/etc/nginx/nginx.conf"
    sed -i 's/     listen       \[::\]:80 default_server;/     listen       \[::\]:80;/g' "/etc/nginx/nginx.conf"

    CONF="/etc/nginx/conf.d/$DOMAIN.conf"
    cat >> $CONF << EOF

upstream fastcgi_backend {
    server  unix:/var/run/php-fpm/www.sock;
}
 
server {
	listen 80 default_server;
	server_name $domain;
	set \$MAGE_ROOT /var/www/$domain;
	set \$MAGE_MODE developer;
	include /var/www/$domain/nginx.conf.sample;
}
EOF
    mkdir -p /var/www/"$DOMAIN"/
    echo "<?php phpinfo(); ?>" > /var/www/"$DOMAIN"/phpinfo.php
    echo "OK" > /var/www/"$DOMAIN"/health
    service nginx reload
fi

##################################################################
### INSTALACIÓN DE PHP COMPOSER Y CONFIGURACIÓN DEL PROYECTO   ###
##################################################################
#Install PHP Composer

curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/bin --filename=composer

#Descargar Magento

mkdir -p /var/www/$DOMAIN
cd  /var/www/$DOMAIN
aws s3 cp s3://packages-install/Magento-CE-2.2.0-2017-09-26-07-35-18.tar.gz ./
tar -xvzf Magento-CE-2.2.0-2017-09-26-07-35-18.tar.gz
rm -rf Magento-CE-2.2.0-2017-09-26-07-35-18.tar.gz
chown -R nginx:nginx /var/www/$DOMAIN
composer create-project



yum install jq -y
echo -e "INDIQUE LA REGION AWS DONDE SE DESPLIEGA LA INSTANCIA EC2: ( eu-wes-1 | us-east-1 | etc)"
read REGION
AWSELB=$(aws elb describe-load-balancers --region ${REGION})
ELB=$(echo ${AWSELB} | jq -r '.LoadBalancerDescriptions[].CanonicalHostedZoneName')
IPELB=$(nslookup $ELB | grep Address | awk {'print $2'} | tail -n 1)
history -c 
PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)


#######################################################
### INSTALACIÓN AGENTE DE MONITORIZACIÓN CLOUDWATCH ###
#######################################################

clear
echo -e "INSTALACIÓN DEL AGENTE AWS PARA EL ENVÍO \n DE MÉTRICAS DE RECURSOS AL CLOUDWATCH "
#echo -e "     Script válido para Instancias Amazon Linux, Ubuntu Server y CentOS 6.9    \n"


#Determinamos el Sistema Operativo de la Instancia

so=`sed -n 1p /etc/issue | awk '{print $1}'`

if [ $so = Ubuntu ];
then
        echo -e "Recuerde inicializar el servicio crontab con el comando: crontab -e,\n"
        echo -e "seleccione el editor y agregue un comentario de primera línea para que\n"
        echo -e "sea creado el fichero cron del usuario root. Se recomienda ejecutar esta acción\n"
        echo -e "abriendo un nuevo terminal y luego seguir con este script\n"
        sleep 5
fi

case "$so" in
        Amazon)
                echo -e "DESCARGANDO PAQUETES NECESARIOS... \n"
                sleep 1
                sudo yum update -y
                sudo yum install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https -y
                sudo mkdir /opt/aws/
                cd /opt/aws/
                curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O
                clear
                echo -e "PREPARANDO FICHEROS... \n"
                sleep 1
                unzip CloudWatchMonitoringScripts-1.2.1.zip
                rm -rf CloudWatchMonitoringScripts-1.2.1.zip    
                cd /opt/aws/aws-scripts-mon
                crontab=/var/spool/cron/root
                ;;
         
        Ubuntu)
                echo -e "DESCARGANDO PAQUETES NECESARIOS... \n"
                sudo apt-get update -y
                sudo apt-get install unzip
                sudo apt-get install libwww-perl libdatetime-perl
                sudo mkdir /opt/aws/
                cd /opt/aws/
                curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O
                clear
                echo -e "PREPARANDO FICHEROS... \n"
                sleep 1
                unzip CloudWatchMonitoringScripts-1.2.1.zip
                rm -rf CloudWatchMonitoringScripts-1.2.1.zip    
                cd /opt/aws/aws-scripts-mon
                crontab=/var/spool/cron/crontabs/root
                ;;
         
        CentOS)
                echo -e "DESCARGANDO PAQUETES NECESARIOS... \n"
                sudo yum update -y
                sudo yum install perl-DateTime perl-CPAN perl-Net-SSLeay perl-IO-Socket-SSL perl-Digest-SHA gcc -y
                sudo yum install zip unzip
                sudo cpan   
                install YAML 
                install LWP::Protocol::https 
                install Sys::Syslog 
                install Switch   
                sudo mkdir /opt/aws/
                cd /opt/aws/
                curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O
                clear
                echo -e "PREPARANDO FICHEROS... \n"
                sleep 1
                unzip CloudWatchMonitoringScripts-1.2.1.zip
                rm -rf CloudWatchMonitoringScripts-1.2.1.zip    
                cd /opt/aws/aws-scripts-mon        
                ;;
        *)
            echo $"Usage: $0 {Amazon|Ubuntu|CentOS}"
            exit 1
esac

echo -e "INDIQUE Y/N SOBRE LAS MÉTRICAS QUE DESEA MONITORIZACIÓN:\n "

echo "MONITORIZAR UTILIZACIÓN DE MEMORIA '--mem-util' (Y/N):"
read memutil

if [ $memutil = Y ] || [ $memutil = y ];
then
        memutil=--mem-util
else
        memutil=
fi

echo "MONITORIZAR MEMORIA UTILIZACIÓN + BUFER + CACHE '--mem-used' (Y/N):"
read memused

if [ $memused = Y ] || [ $memused = y ];
then
        memutil=--mem-used
else
        memused=
fi	

echo "MONITORIZAR ESPACIO EN DISCO '--disk-patch' (Y/N):"
read diskpath

if [ $diskpath = Y ] || [ $diskpath = y ];
then
        diskpath=--disk-path
        echo "INDIQUE EL PATH A MONITORIZAR 'PATH' ( / , /var/www/ , /opt/ , etc ):"
        read patch
        igual='='
        diskspaceutil=--disk-space-util
else
        diskpath=
        igual=
        diskspaceutil=
fi

echo "LA INSTANCIA PERTENECERÁ A UN ASG (Y/N):"
read asg

if [ $asg = Y ] || [ $asg = y ];
then
        asg=--auto-scaling
        clear
        echo "NO SE AGREGARÁ TAREAS AL SERVICIO CRONTAB AHORA, POR FAVOR DEFINA LA SIGUIENTE LÍNEA A SU 'user-data' "
        echo "* * * * * /opt/aws/aws-scripts-mon/mon-put-instance-data.pl $memutil $memused $diskspaceutil $diskpath$igual$patch $asg --from-cron" > $crontab
        echo "INSTALACIÓN COMPLETA"
        sleep 5
else
        asg=
        #echo "* * * * * /opt/aws/aws-scripts-mon/mon-put-instance-data.pl $memutil $memused $diskspaceutil $diskpath$igual$patch --from-cron" > $crontab
        echo "INSTALACIÓN COMPLETA"
        sleep 5
fi

#*/5 * * * *  /opt/aws/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --auto-scaling --from-cron


clear
echo -e "INSTALACIÓN FINALIZADA\n"
#echo -e "COLOQUE SU PAQUETE DE IMPLEMENTACIÓN EN EL DIRECTORIO DE TRABAJO\n"
#echo -e "/var/www/$DOMAIN y ejecute composer create-project "