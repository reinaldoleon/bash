#!/bin/bash
# El scrip recibe dos parametros para funcionar
# Parametro 1: el nombre del proyecto
# Parametro 2: el nombre del bucket de S3 donde se guardarán las keys generadas.

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
        if [ $SO = Ubuntu ]; then
            VER=$(sed -n 1p /etc/issue | awk '{print $2}' | cut -d "." -f 1)
            SO=${SO}${VER}
        fi
        installQuestion
}

function installQuestion () {
    echo -e "INDOQUE EL NOMBRE DEL PROYECTO O CLIENTE:"
    read PROYECTO

    echo -e "INDIQUE EL NOMBRE DEL BUCKET DONDE ALMACENARÁ LAS KEYS GENERADAS:"
    read BUCKET

    if [ -z ${PROYECTO} ] || [ -z ${BUCKET} ]; then
    echo -e "DEBE INDICAR DOS PARÁMETROS VÁLIDOS \n
        1) NOMBRE DEL PROYECTO (Seleccionaste: ${PROYECTO}) \n
        2) NOMBRE DEL BUCKET S3 (Seleccionaste: ${BUCKET}) \n"
    else 
    #validateBuckect
    installKeys
    fi
}

function installKeys () {
    case "${SO}" in
        Ubuntu18)
            #PROBADO UBUNTU 
            clear
            useradd ${PROYECTO}
            mkdir -p /home/${PROYECTO}/.ssh && cd /home/${PROYECTO} && touch .ssh/authorized_keys
            cd /home/${PROYECTO}
            ssh-keygen  -P "" -f "/home/${PROYECTO}/.ssh/${PROYECTO}" -q
            cat /home/${PROYECTO}/.ssh/${PROYECTO}.pub >> /home/${PROYECTO}/.ssh/authorized_keys
            chown -R ${PROYECTO}:${PROYECTO} /home/${PROYECTO}/.ssh
            clear
            uploadS3
        ;;
        Ubuntu16)
        ;;
        Amazon)
        ;;
        CentOS) 
        ;;
    esac
}

function validateBucket () {
    LIST=$(aws s3 ls)
    for LINEA in ${LIST}; do
        if [ $LINEA = $BUCKET ]; then
            S3BUCKET=OK
        else
            S3BUCKET=FAILED
        fi
    done 
    #AGREGAR EL IF DE LLAMAR A LA FUNCION
}
function uploadS3 () {
    aws s3 cp /home/${PROYECTO}/.ssh/${PROYECTO} s3://$BUCKET
    aws s3 cp /home/${PROYECTO}/.ssh/${PROYECTO}.pub s3://$BUCKET
    #Clean Local Keys
    rm -rf /home/${PROYECTO}/.ssh/${PROYECTO}*
    history -c
    clear
    echo -e "\n\nKeys ${PROYECTO} GENERADAS Y GUARDADAS EN EL BUCKET ${BUCKET}\n\n"
    echo ""
    read -n 1 -s -r -p "Presione cualquier tecla para continuar..." 
    exit 1
}
isRoot