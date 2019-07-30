#!/bin/bash

#DEFINE VARIABLES
REGION=eu-west-1
CIDR=10.0.0.0/16


##CREACION DE LA VPC###
#Creamos la VPC y Anotamos el ID= vpc-0592e214c51b14e50 de la salida para colocar el tag Name 
VPC_PRINCIPAL_ID=$(aws ec2 create-vpc --cidr-block ${CIDR} --region ${REGION} | jq -r '.Vpc.VpcId')

#Agregamos tags a la VPC / Anotamos el ID= 
aws ec2 create-tags --resources ${VPC_PRINCIPAL_ID} --tags Key=Name,Value=VPC-Principal

########## PUBLIC SUBNET ##########
#Creamos la primera subred pública en la AZA / Anotamos el ID= subnet-08847660e83c390df 
PUBLIC_SUBNET_AZA=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.1.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PUBLIC_SUBNET_AZA} --tags Key=Name,Value=1-Public-Subnet-AZA

#Creamos la segunda subred pública en la AZB / Anotamos el ID= subnet-0886386e60cd805c6
PUBLIC_SUBNET_AZB=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.2.0/24 --availability-zone ${REGION}b | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PUBLIC_SUBNET_AZB} --tags Key=Name,Value=2-Public-Subnet-AZB

#Creamos la tercera subred pública en la AZC / Anotamos el ID= subnet-0886386e60cd805c6
PUBLIC_SUBNET_AZC=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.3.0/24 --availability-zone ${REGION}b | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PUBLIC_SUBNET_AZB} --tags Key=Name,Value=3-Public-Subnet-AZC

########## APP SUBNET ##########

#Creamos la primera subred privada en la AZA / Anotamos el ID= subnet-064b77270d5829c24
APP_SUBNET_AZA=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.4.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZA} --tags Key=Name,Value=4-App-Subnet-AZA

#Creamos la segunda subred privada en la AZB / Anotamos el ID= subnet-064b77270d5829c24
APP_SUBNET_AZB=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.5.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZA} --tags Key=Name,Value=5-App-Subnet-AZB

#Creamos la tercera subred privada en la AZC / Anotamos el ID= subnet-064b77270d5829c24
APP_SUBNET_AZC=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.6.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZA} --tags Key=Name,Value=6-App-Subnet-AZC

########## BBDD SUBNET ##########

#Creamos la primera subred privada en la AZA / Anotamos el ID= subnet-064b77270d5829c24
BBDD_SUBNET_AZA=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.7.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZA} --tags Key=Name,Value=7-BBDD-Subnet-AZA

#Creamos la segunda subred privada en la AZB / Anotamos el ID= subnet-064b77270d5829c24
BBDD_SUBNET_AZA=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.8.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZA} --tags Key=Name,Value=8-BBDD-Subnet-AZB

#Creamos la tercera subred privada en la AZC / Anotamos el ID= subnet-064b77270d5829c24
BBDD_SUBNET_AZA=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.9.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZA} --tags Key=Name,Value=9-BBDD-Subnet-AZC


#Creamos el internetgateway para la VPC / Anotamos el ID= igw-0b7a14cd0e05dfe6a
IGW_VPC_PRINCIPAL=$(aws ec2 create-internet-gateway | jq -r '.InternetGateway.InternetGatewayId')
aws ec2 create-tags --resources ${IGW_VPC_PRINCIPAL} --tags Key=Name,Value=IGW-VPC-Principal
#Attach el internetgateway a la VPC
aws ec2 attach-internet-gateway --internet-gateway-id ${IGW_VPC_PRINCIPAL} --vpc-id ${VPC_PRINCIPAL_ID}

#Creamos una EIP para los NAT Gateway / Anotamos el ID= eipalloc-079a1da2e3c0c7fe2
EIP_NAT_AZA=$(aws ec2 allocate-address --domain vpc | jq -r '.AllocationId')
EIP_NAT_AZB=$(aws ec2 allocate-address --domain vpc | jq -r '.AllocationId')

#Creamos los NAT Gateway de las AZA y AZB
NAT_AZA=$(aws ec2 create-nat-gateway --subnet-id ${PUBLIC_SUBNET_AZA} --allocation-id ${EIP_NAT_AZA})
NAT_AZB=$(aws ec2 create-nat-gateway --subnet-id ${PUBLIC_SUBNET_AZB} --allocation-id ${EIP_NAT_AZB})


#Al crear la VPC se crea por defecto una Route table privada / colocamos tags identificandola por el ID de la VPC
RT_PRIVATE_VPC_PRINCIPAL=$(aws ec2 describe-route-tables | jq -r '.RouteTables[].RouteTableId' | tail -1)
aws ec2 create-tags --resources ${RT_PRIVATE_VPC_PRINCIPAL} --tags Key=Name,Value=RT-Private

#Creamos la tabla de rutas pública / Anotamos el ID= rtb-017f20e40c4ff5fb5
RT_PUBLIC_VPC_PRINCIPAL=$(aws ec2 create-route-table --vpc-id ${VPC_PRINCIPAL_ID} | jq -r '.RouteTable.RouteTableId')
aws ec2 create-tags --resources ${RT_PUBLIC_VPC_PRINCIPAL} --tags Key=Name,Value=RT-Public

#Agregamos rutas para la Route Table Publica
aws ec2 create-route --route-table-id ${RT_PUBLIC_VPC_PRINCIPAL} --destination-cidr-block 0.0.0.0/0 --gateway-id ${IGW_VPC_PRINCIPAL}

#Agregamos rutas para la Route Table Privada
aws ec2 create-route --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL} --destination-cidr-block 0.0.0.0/0 --nat-gateway-id ${IGW_VPC_PRINCIPAL}


#Asociamos las subredes a sus respectivas RT
aws ec2 associate-route-table --route-table-id ${RT_PUBLIC_VPC_PRINCIPAL} --subnet-id ${PUBLIC_SUBNET_AZA}
aws ec2 associate-route-table --route-table-id ${RT_PUBLIC_VPC_PRINCIPAL} --subnet-id ${PUBLIC_SUBNET_AZB}
aws ec2 associate-route-table --route-table-id ${RT_PUBLIC_VPC_PRINCIPAL} --subnet-id  ${PUBLIC_SUBNET_AZC}

aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL} --subnet-id ${APP_SUBNET_AZA}
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL} --subnet-id ${APP_SUBNET_AZB}
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL} --subnet-id  ${APP_SUBNET_AZC}

aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL} --subnet-id ${BBDD_SUBNET_AZA}
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL} --subnet-id ${BBDD_SUBNET_AZB}
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL} --subnet-id  ${BBDD_SUBNET_AZC}


#Creamos las Security Groups que agregaremos a las instancias Web / Anotamos el ID= sg-00ca1e09e7b6d7082
SG_WEBSERVICE=$(aws ec2 create-security-group --group-name SG-WebService --description "SG-WebService" --vpc-id ${VPC_PRINCIPAL_ID} | jq -r '.GroupId')
aws ec2 create-tags --resources ${SG_WEBSERVICE} --tags Key=Name,Value=SG-WebService
#Creamos las reglas para el SG
aws ec2 authorize-security-group-ingress --group-id ${SG_WEBSERVICE} --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${SG_WEBSERVICE} --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${SG_WEBSERVICE} --protocol tcp --port 22 --cidr 10.0.1.0/24

#Creamos la key para la instancia
aws ec2 create-key-pair --key-name webservice --query "KeyMaterial" --output text > 10webservice.pem
INSTANCES_KEY=webservice

#Identificamos el ID de la AMI que utilizaremos / Anotamos el ID= ami-08935252a36e25f85       
#Amazon Linux Actual
#aws ec2 describe-images --owners amazon --filters 'Name=name,Values=amzn-ami-hvm-????.??.?.????????-x86_64-gp2' 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'
#Ubuntu 16.04 LTS
#aws ec2 describe-images --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-????????' 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'
#RedHat Enterprice Linux 7.5
#aws ec2 describe-images --owners 309956199498 --filters 'Name=name,Values=RHEL-7.5_HVM_GA*' 'Name=state,Values=available' --output json | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId'
#Todas
#aws ec2 describe-images --owners self amazon --filters "Name=root-device-type,Values=ebs" | more

#Creamos la instancia EC2 WebService / Anotamos el ID= i-04a2ad408a1994ce2
AMI_AMAZON_LINUX=ami-08935252a36e25f85
WEB_INSTANCE_ID=$(aws ec2 run-instances --image-id ${AMI_AMAZON_LINUX} \
                             --subnet-id ${PUBLIC_SUBNET_AZA} \
                             --security-group-ids ${SG_WEBSERVICE} \
                             --count 1 \
                             --instance-type t3.micro \
                             --key-name ${INSTANCES_KEY} \
                             --query "Instances[0].InstanceId")
aws ec2 create-tags --resources "WEB_INSTANCE_ID" --tags Key=Name,Value=WebService

#Creamos una EIP / Anotamos el ID= eipalloc-079a1da2e3c0c7fe2
EIP_WEB=$(aws ec2 allocate-address --domain vpc | jq -r '.AllocationId')

#Asociamos la EIP a la Instancia
aws ec2 associate-address --instance-id ${WEB_INSTANCE_ID} --allocation-id ${EIP_WEB}


################################ INSTANCIA ADMINISTRACIÓN ###################################

#Creamos las Security Groups que agregaremos a las instancias / Anotamos el ID= sg-043ae0eb37101a784
SG_ADMINISTRACION=$(aws ec2 create-security-group --group-name SG-Administracion --description "SG-Administracion" --vpc-id ${VPC_PRINCIPAL_ID} | jq -r '.GroupId')
aws ec2 create-tags --resources ${SG_ADMINISTRACION} --tags Key=Name,Value=SG-Administracion
#Creamos las reglas para el SG
aws ec2 authorize-security-group-ingress --group-id ${SG_ADMINISTRACION} --protocol tcp --port 22 --cidr 215.216.217.218/32

#Creamos la segunda instancia de Administración / Anotamos el ID= i-0c95add737a0273bc
ADMIN_INSTANCE_ID=$(aws ec2 run-instances --image-id ${AMI_AMAZON_LINUX} \
                             --subnet-id ${PUBLIC_SUBNET_AZB} \
                             --security-group-ids ${SG_ADMINISTRACION} \
                             --count 1 \
                             --instance-type t3.micro \
                             --key-name ${INSTANCES_KEY} \
                             --associate-public-ip-address \
                             --query "Instances[0].InstanceId")
aws ec2 create-tags --resources ${ADMIN_INSTANCE_ID} --tags Key=Name,Value=Administracion


################################ INSTANCIA BBDD ###################################

#Creamos las Security Groups que agregaremos a las instancias / Anotamos el ID= sg-0ae1a76a6dcd82446
SG_BBDD=$(aws ec2 create-security-group --group-name SG-BBDD --description "SG-DataBase" --vpc-id ${VPC_PRINCIPAL_ID} | jq -r '.GroupId')
aws ec2 create-tags --resources ${SG_BBDD} --tags Key=Name,Value=SG-DataBase
#Creamos las reglas para el SG
aws ec2 authorize-security-group-ingress --group-id ${SG_BBDD} --protocol tcp --port 3306 --cidr 10.0.1.0/24
aws ec2 authorize-security-group-ingress --group-id ${SG_BBDD} --protocol tcp --port 22 --cidr 10.0.2.0/24

#Creamos la segunda instancia de Administración / Anotamos el ID= i-0c95add737aut463
BBDD_INSTANCE_ID=$(aws ec2 run-instances --image-id ${AMI_AMAZON_LINUX} \
                             --subnet-id ${PRIVATE_SUBNET_AZA} \
                             --security-group-ids ${SG_BBDD} \
                             --count 1 \
                             --instance-type t3.micro \
                             --key-name ${INSTANCES_KEY} \
                             --query "Instances[0].InstanceId")
aws ec2 create-tags --resources ${BBDD_INSTANCE_ID} --tags Key=Name,Value=BBDD

