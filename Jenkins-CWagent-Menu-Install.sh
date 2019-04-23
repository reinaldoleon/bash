#!/bin/bash

function isRoot () {
	if [ "$EUID" -ne 0 ]; then
        echo -e "DEBE EJECUTAR LA INSTALACIÓN COMO ROOT \n"
		exit 1
    else
        sistemOperation
	fi
}

function sistemOperation () {
        SO=$(sed -n 1p /etc/issue | awk '{print $1}')
        manageMenu
}

##INSTALADOR DEL SERVICIO JENKINS##

function installJenkins () {
        case "${SO}" in
                Amazon)
                        jenkinsAmazon
                        ;;
                
                Ubuntu)
                        jenkinsUbuntu
                        ;;
                
                CentOS)
                        jenkinsAmazon       
                        ;;
                *)
                echo $"Usage: $0 {Amazon|Ubuntu|CentOS}"
                exit 1
esac
}

function jenkinsAmazon () {
    clear
    if [ -d /var/lib/jenkins/ ];then
        echo "EL SERVICIO JENKINS YA SE ENCUENTRA INSTALADO"
        sleep 3
        manageMenu
    else
        echo -e "INTRODUZCA EL DOMINIO AL QUE RESPONDERÁ EL JENKINS: "
        read DOMAIN
        echo -e "DESCARGANDO PAQUETES NECESARIOS PARA INSTALAR JENKINS... \n"
        sudo yum -y update
        wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
        rpm --import http://pkg.jenkins-ci.org/redhat-stable/jenkins-ci.org.key
        yum install -y java-1.8.0
        yum remove -y java-1.7.0
        yum install -y jenkins
        service jenkins start
        clear
        if [[ -f /etc/nginx/nginx.conf ]];then
            clear
            echo -e "EL SERVICIO NGINX SE ENCUENTRA INSTALADO"
            sleep 2
        else
            echo -e "DESCARGANDO PAQUETES NECESARIOS PARA INSTALAR NGINX... \n"
            sleep 1
            sudo yum update -y
            yum -y install nginx
            chkconfig --add nginx 
            chkconfig nginx on
            sed -i 's/     listen       80 default_server;/      listen       80;/g' "/etc/nginx/nginx.conf"
            sed -i 's/     listen       \[::\]:80 default_server;/     listen       \[::\]:80;/g' "/etc/nginx/nginx.conf"
            service nginx restart
        fi
        CONF="/etc/nginx/conf.d/jenkins.conf"
        cat >> ${CONF} << EOF
upstream jenkins {
    server 127.0.0.1:8080 fail_timeout=0;
}
server {
    listen 80 default_server;
    server_name ${DOMAIN};

    access_log  /var/log/nginx/jenkins.access.log;
    error_log   /var/log/nginx/jenkins.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;
    #ssl_certificate /etc/nginx/ssl/crt;
    #ssl_certificate_key /etc/nginx/ssl/key;

    location / {
        proxy_pass  http://jenkins;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        #proxy_redirect http://  https://;

        proxy_set_header    Host            \$host:\$server_port;
        proxy_set_header    X-Real-IP       \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto \$scheme;
    }

}
EOF
        service nginx reload
        infoInstallJenkins
        echo -e "\n"
        sleep 2
    fi
}

function jenkinsUbuntu () {
    clear
    if [ -d /var/lib/jenkins/ ];then
        echo "EL SERVICIO JENKINS YA SE ENCUENTRA INSTALADO"
        sleep 3
        manageMenu
    else
        echo -e "INTRODUZCA EL DOMINIO AL QUE RESPONDERÁ EL JENKINS: "
        read DOMAIN
        echo -e "DESCARGANDO PAQUETES NECESARIOS PARA INSTALAR JENKINS... \n"
        sudo apt-get update -y
        wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
        sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
        apt update
        apt install openjdk-8-jdk -y
        apt install jenkins -y
        update-rc.d jenkins start 20 3 4 5
        systemctl start jenkins
        clear
        if [[ -f /etc/nginx/nginx.conf ]];then
            clear
            echo -e "EL SERVICIO NGINX SE ENCUENTRA INSTALADO"
            sleep 2
        else
            echo -e "DESCARGANDO PAQUETES NECESARIOS PARA INSTALAR NGINX... \n"
            sleep 1
            apt install nginx -y
            update-rc.d nginx start 20 3 4 5
            sed -i 's/\tlisten 80 default_server;/\tlisten 80;/g' "/etc/nginx/sites-available/default"
            sed -i 's/\tlisten \[::\]:80 default_server;/\tlisten \[::\]:80;/g' "/etc/nginx/sites-available/default"
            sed -i 's/\tlisten 80 default_server;/\t#listen 80;/g' "/etc/nginx/sites-enabled/default"
            sed -i 's/\tlisten \[::\]:80 default_server;/\t#listen \[::\]:80;/g' "/etc/nginx/sites-enabled/default"
            service nginx restart
        fi
        CONF="/etc/nginx/conf.d/jenkins.conf"
        cat >> ${CONF} << EOF
upstream jenkins {
server 127.0.0.1:8080 fail_timeout=0;
}
server {
listen 80 default_server;
server_name ${DOMAIN};

access_log  /var/log/nginx/jenkins.access.log;
error_log   /var/log/nginx/jenkins.error.log;

proxy_buffers 16 64k;
proxy_buffer_size 128k;
#ssl_certificate /etc/nginx/ssl/crt;
#ssl_certificate_key /etc/nginx/ssl/key;

location / {
    proxy_pass  http://jenkins;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    #proxy_redirect http://  https://;

    proxy_set_header    Host            \$host:\$server_port;
    proxy_set_header    X-Real-IP       \$remote_addr;
    proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto \$scheme;
}

}
EOF
        systemctl stop nginx
        systemctl start nginx
        infoInstallJenkins
        echo -e "\n"
        sleep 2
    fi
}


function infoInstallJenkins () {
    IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
    echo -e "ESPERE QUE ESTAMOS OBTENIENDO EL PASSWD DEL ADMINISTRADOR"
    sleep 5
    PASSWDJK=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
    while [ -z $PASSWDJK ]; do
            sleep 2
            PASSWDJK=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
    done
    if [ -n $PASSWDJK ]; then
            ADMINPASSWD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    else 
            infoInstallJenkins
    fi
    clear 
    echo -e " PUEDE ACCEDER AL JENKINS A TRAVÉS DE  ${DOMAIN} O CON SU IP PÚBLICA ${IP}:8080 \n"
    echo -e " PARA EL LOGIN UTILICE LA CLAVE DE ADMINISTRADOR: ${ADMINPASSWD} "
    echo ""
    read -n 1 -s -r -p "Presione cualquier tecla para continuar..." 
    manageMenu
}

#################################################
#  INSTALACIÓN DEL AGENTE AWS PARA EL ENVÍO	#
#  DE MÉTRICAS DE RECURSOS AL CLOUDWATCH 	#
#################################################

function installCWAgent () {
        clear
        PRESENT="INSTALACIÓN DEL AGENTE AWS PARA EL ENVÍO DE MÉTRICAS AL CLOUDWATCH "
        COLUMNS=$(tput cols)
        let LONGPRESENT=${#PRESENT}+$COLUMNS/4
        printf "%*s\n"  ${LONGPRESENT} "$PRESENT"
        echo ""
        sleep 2
        validateSO
}

function validateSO () {
        if [[ $SO = Ubuntu ]];then
            if [[ $CRONINI = Y ]]; then
                installAgent
            else
                validateUbuntu
            fi
        elif [[ $SO = Amazon || $SO = CentOS ]]; then
                installAgent
        else
            echo "EL SISTEMA OPERATIVO NO ESTA SOPORTADO POR ESTE SCRIPT"
            sleep 3
            exit 1
        fi
}

function validateUbuntu () {
        if [ ${SO} = Ubuntu ];
        then
                if [[ -f /var/spool/cron/crontabs/root ]]; 
                then
                        CRONINI=Y
                        validateSO 
                else
                        echo -e "RECUERDE INICIALIZAR EL SERVICIO CRONTAB CON EL COMANDO: crontab -e,\n" 
                        echo -e "SELECCIONE EL EDITOR DE SU PREFERENCIA Y AGREGUE UN COMENTARIO DE PRIMERA LÍNEA \n" 
                        echo -e "PARA QUE SEA CREADO EL FICHERO CRON DEL USUARIO ROOT. \n"
                        echo -e "AL REALIZAR ESTA ACCIÓN VUELVA A EJECUTAR ESTE SCRIPT \n"
                        sleep 5
                        exit 1
                fi
        fi

} 

function installAmazon () {
        if [ -f /opt/aws/aws-scripts-mon/mon-put-instance-data.pl ]; then
            echo "EL AGENTE DE MONITORIZACIÓN YA SE ENCUENTRA INSTALADO"
            sleep 3
        else
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
        fi
    CRONTAB=/var/spool/cron/root
    installQuestion
}

function installUbuntu () {
        if [ -f /opt/aws/aws-scripts-mon/mon-put-instance-data.pl ]; then
            echo "EL AGENTE DE MONITORIZACIÓN YA SE ENCUENTRA INSTALADO"
            sleep 3
        else
            echo -e "DESCARGANDO PAQUETES NECESARIOS... \n"
            sudo apt-get update -y
            sudo apt-get install unzip -y
            sudo apt-get install libwww-perl libdatetime-perl -y
            sudo mkdir /opt/aws/
            cd /opt/aws/
            curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O
            clear
            echo -e "PREPARANDO FICHEROS... \n"
            sleep 1
            unzip CloudWatchMonitoringScripts-1.2.1.zip
            rm -rf CloudWatchMonitoringScripts-1.2.1.zip    
            cd /opt/aws/aws-scripts-mon
        fi
        CRONTAB=/var/spool/cron/crontabs/root
        installQuestion
}

function installCentOS () {
        if [ -f /opt/aws/aws-scripts-mon/mon-put-instance-data.pl ]; then
            echo "EL AGENTE DE MONITORIZACIÓN YA SE ENCUENTRA INSTALADO"
            sleep 3
        else
            echo -e "DESCARGANDO PAQUETES NECESARIOS... \n"
            sudo yum update -y
            sudo yum install perl-DateTime perl-CPAN perl-Net-SSLeay perl-IO-Socket-SSL perl-Digest-SHA gcc -y
            sudo yum install zip unzip -y
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
            CRONTAB=/var/spool/cron/crontabs/root
        fi
        CRONTAB=/var/spool/cron/crontabs/root
        installQuestion
}

function installAgent () {
        case "${SO}" in
                Amazon)
                        installAmazon
                        ;;
                Ubuntu)
                        installUbuntu
                        ;;
                CentOS)
                        installCentOS      
                        ;;
                *)
                echo $"Usage: $0 {Amazon|Ubuntu|CentOS}"
                exit 1
esac
}

function installQuestion () {
    if [[ -n $(grep "mon-put-instance-data.pl" $CRONTAB) ]];then
        clear
        echo "EXISTE UNA CONFIGURACIÓN DE CRONTRAB PARA CLOUDWATCH CONFIGURADA"
        sleep 3
        manageMenu
    else
        clear
        echo -e "INDIQUE Y/N SOBRE LAS MÉTRICAS QUE DESEA MONITORIZACIÓN:\n"

        ##MEMORIA UTILIZACIÓN
        until [[ $MEMUTIL =~ (Y|y|N|n) ]]; do
		    read -rp "MONITORIZAR UTILIZACIÓN DE MEMORIA '--mem-util' (Y/N): " -e -i Y MEMUTIL
	    done
        if [ $MEMUTIL = Y ] || [ $MEMUTIL = y ];
        then
                MEMUTIL=--mem-util
        else
                memutil=
        fi

        ##MEMORIA UTILIZACIÓN + BUFER + CACHE
        until [[ $MEMUSE =~ (Y|y|N|n) ]]; do
                read -rp "MONITORIZAR MEMORIA UTILIZACIÓN + BUFER + CACHE '--mem-used' (Y/N): " -e -i N MEMUSE
        done
        if [ $MEMUSE = Y ] || [ $MEMUSE = y ];
        then
                MEMUSE=--mem-used
        else
                MEMUSE=
        fi

        ##DISCO UTILIZACIÓN
        until [[ $DISKPATH =~ (Y|y|N|n) ]]; do
                read -rp "MONITORIZAR ESPACIO EN DISCO '--disk-patch' (Y/N): " -e -i Y DISKPATH
        done
        if [ $DISKPATH = Y ] || [ $DISKPATH = y ];
        then
                DISKPATH=--disk-path
                until [[ ! -z $PARTPATH  ]]; do
                read -rp "INDIQUE EL PATH A MONITORIZAR 'PATH' ( / , /var/www/ , /opt/ , /etc/ ): " -e -i / PARTPATH
                done
                IGUAL='='
                DISKSPACEUTIL=--disk-space-util
        else
                DISKPATH=
                IGUAL=
                DISKSPACEUTIL=
        fi

        ##INSTANCIA DENTRO DE UN ASG
        until [[ $ASG =~ (Y|y|N|n) ]]; do
                read -rp "LA INSTANCIA PERTENECERÁ A UN ASG (Y/N): " -e -i Y ASG
        done
        if [ $ASG = Y ] || [ $ASG = y ];
        then
                ASG=--auto-scaling
                clear
                echo "NO SE AGREGARÁ TAREAS AL SERVICIO CRONTAB AHORA, POR FAVOR DEFINA LA SIGUIENTE LÍNEA A SU 'user-data' "
                echo "* * * * * /opt/aws/aws-scripts-mon/mon-put-instance-data.pl $MEMUTIL $MEMUSED $DISKSPACEUTIL $DISKPATH$IGUAL$PARTPATH $ASG --from-cron"
                echo "INSTALACIÓN COMPLETA DEL AGENTE DE MONITORIZACIÓN"
                sleep 3
                manageMenu
        else
                clear
                echo "* * * * * /opt/aws/aws-scripts-mon/mon-put-instance-data.pl $MEMUTIL $MEMUSED $DISKSPACEUTIL $DISKPATH$IGUAL$PARTPATH --from-cron" >> $CRONTAB
                echo "INSTALACIÓN COMPLETA DEL AGENTE DE MONITORIZACIÓN"
                sleep 3
                manageMenu
        fi
    fi
}


##MENÚ PRINCIPAL

function manageMenu () {
	clear
	echo "INSTALADOR DEL SERVICIO JENKINS Y EL AGENTE DE MONITORIZACIÓN DE CLOUDWATCH "
	echo ""
	echo "QUE SERVICIO DESEA INSTALAR PRIMERO"
	echo "   1) JENKINS"
	echo "   2) CLOUDWATCH AGENT"
	echo "   3) SALIR DEL INSTALADOR"
	until [[ "$MENU_OPTION" =~ ^[1-3]$ ]]; do
		read -rp "SELECCIONE UNA OPCIÓN [1-3]: " MENU_OPTION
	done

	case $MENU_OPTION in
		1)
            MENU_OPTION=0
		    installJenkins
		;;
		2)
            MENU_OPTION=0
			installCWAgent
		;;
		3)
            MENU_OPTION=0
			exit 0
		;;
	esac
}
isRoot