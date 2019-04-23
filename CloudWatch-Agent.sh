#!/bin/bash

#################################################
#						#
#  INSTALACIÓN DEL AGENTE AWS PARA EL ENVÍO	#
#  DE MÉTRICAS DE RECURSOS AL CLOUDWATCH 	#
# 			                        #
#################################################

#######################################################
### INSTALACIÓN AGENTE DE MONITORIZACIÓN CLOUDWATCH ###
#######################################################


#Determinamos el Sistema Operativo de la Instancia

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
        CRONTAB=/var/spool/cron/root
}

function installUbuntu () {
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
        CRONTAB=/var/spool/cron/crontabs/root
}

function installCentOS () {
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
}

function installAgent () {
        case "${SO}" in
                Amazon)
                        installAmazon
                        if [ -f /opt/aws/aws-scripts-mon/mon-put-instance-data.pl ]; then
                            installQuestion
                        fi
                        ;;
                
                Ubuntu)
                        installUbuntu
                        if [ -f /opt/aws/aws-scripts-mon/mon-put-instance-data.pl ]; then
                            installQuestion
                        fi
                        ;;
                
                CentOS)
                        installCentOS
                        if [ -f /opt/aws/aws-scripts-mon/mon-put-instance-data.pl ]; then
                            installQuestion
                        fi        
                        ;;
                *)
                echo $"Usage: $0 {Amazon|Ubuntu|CentOS}"
                exit 1
esac
}

function installQuestion () {
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
                #echo "* * * * * /opt/aws/aws-scripts-mon/mon-put-instance-data.pl $MEMUTIL $MEMUSED $DISKSPACEUTIL $DISKPATH$IGUAL$PARTPATH $ASG --from-cron"
                echo "INSTALACIÓN COMPLETA"
                sleep 3
        else
                clear
                echo "* * * * * /opt/aws/aws-scripts-mon/mon-put-instance-data.pl $MEMUTIL $MEMUSED $DISKSPACEUTIL $DISKPATH$IGUAL$PARTPATH --from-cron" > $CRONTAB
                echo "INSTALACIÓN COMPLETA"
                sleep 3
        fi

}

#EJEMPLO ESTRUCTURA CRONTAB
#*/5 * * * *  /opt/aws/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --auto-scaling --from-cron



clear
PRESENT="INSTALACIÓN DEL AGENTE AWS PARA EL ENVÍO DE MÉTRICAS AL CLOUDWATCH "
COLUMNS=$(tput cols)
let LONGPRESENT=${#PRESENT}+$COLUMNS/4
printf "%*s\n"  ${LONGPRESENT} "$PRESENT"
echo ""
sleep 2
isRoot

