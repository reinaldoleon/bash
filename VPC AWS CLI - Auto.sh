#!/bin/bash

echo "
#####################
## UPLOAD VARIABLE ##
#####################
"
#Default Value
REGION=eu-west-3
VPC_TAG_NAME=VPC-Principal
PUBLIC_SUBNET_NAME=Public-Subnet
PRIVATE_SUBNET_NAME=Private-Subnet
BBDD_SUBNET_NAME=BBDD-Subnet


echo -e "Specify the deployment region"
read REGION

echo -e "Specify the VPC name"
read VPC_TAG_NAME

echo -e "Specify the Public Subnet Name"
read PUBLIC_SUBNET_NAME

echo -e "Specify the Private Subnet Name"
read PRIVATE_SUBNET_NAME

echo -e "Specify the BBDD Subnet Name"
read BBDD_SUBNET_NAME

######################
##CREACION DE LA VPC##
######################
"
#Creamos la VPC y Anotamos el ID= vpc-0592e214c51b14e50 de la salida para colocar el tag Name 
VPC_PRINCIPAL_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region ${REGION} | jq -r '.Vpc.VpcId')
#Agregamos tags a la VPC / Anotamos el ID= 
aws ec2 create-tags --resources ${VPC_PRINCIPAL_ID} --tags Key=Name,Value=${VPC_TAG_NAME}

echo "
###############################
##CREAMOS LAS PUBLIC SUBNETS ##
###############################
"
#Creamos la primera subred pública en la AZA / Anotamos el ID= subnet-08847660e83c390df 
PUBLIC_SUBNET_AZA=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.1.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PUBLIC_SUBNET_AZA} --tags Key=Name,Value=1-${PUBLIC_SUBNET_NAME}-AZA
#Creamos la segunda subred pública en la AZB / Anotamos el ID= subnet-0886386e60cd805c6
PUBLIC_SUBNET_AZB=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.2.0/24 --availability-zone ${REGION}b | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PUBLIC_SUBNET_AZB} --tags Key=Name,Value=2-${PUBLIC_SUBNET_NAME}-AZB
#Creamos la segunda subred pública en la AZB / Anotamos el ID= subnet-0886386e60cd805c6
PUBLIC_SUBNET_AZC=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.3.0/24 --availability-zone ${REGION}c | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PUBLIC_SUBNET_AZC} --tags Key=Name,Value=3-${PUBLIC_SUBNET_NAME}-AZC

echo "
#################################
##CREAMOS LAS PRIVATES SUBNETS ##
#################################
"
#Creamos la primera subred privada en la AZA / Anotamos el ID= subnet-064b77270d5829c24
PRIVATE_SUBNET_AZA=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.4.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZA} --tags Key=Name,Value=1-${PRIVATE_SUBNET_NAME}-AZA
#Creamos la segunda subred privada en la AZB / Anotamos el ID= subnet-064b77270d5829c24
PRIVATE_SUBNET_AZB=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.5.0/24 --availability-zone ${REGION}b | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZB} --tags Key=Name,Value=2-${PRIVATE_SUBNET_NAME}-AZB
#Creamos la tercera subred privada en la AZC / Anotamos el ID= subnet-064b77270d5829c24
PRIVATE_SUBNET_AZC=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.6.0/24 --availability-zone ${REGION}c | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${PRIVATE_SUBNET_AZC} --tags Key=Name,Value=3-${PRIVATE_SUBNET_NAME}-AZC

echo "
#################################
##CREAMOS LAS BBDD SUBNETS ##
#################################
"
#Creamos la primera subred privada en la AZA / Anotamos el ID= subnet-064b77270d5829c24
BBDD_SUBNET_AZA=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.7.0/24 --availability-zone ${REGION}a | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${BBDD_SUBNET_AZA} --tags Key=Name,Value=1-${BBDD_SUBNET_NAME}-AZA
#Creamos la segunda subred privada en la AZB / Anotamos el ID= subnet-064b77270d5829c24
BBDD_SUBNET_AZB=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.8.0/24 --availability-zone ${REGION}b | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${BBDD_SUBNET_AZB} --tags Key=Name,Value=2-${BBDD_SUBNET_NAME}-AZB
#Creamos la tercera subred privada en la AZC / Anotamos el ID= subnet-064b77270d5829c24
BBDD_SUBNET_AZC=$(aws ec2 create-subnet --vpc-id ${VPC_PRINCIPAL_ID} --cidr-block 10.0.9.0/24 --availability-zone ${REGION}c | jq -r '.Subnet.SubnetId')
aws ec2 create-tags --resources ${BBDD_SUBNET_AZC} --tags Key=Name,Value=3-${BBDD_SUBNET_NAME}-AZC

echo "
###############
##CREATE IGW ##
###############
"
#Creamos el internetgateway para la VPC / Anotamos el ID= igw-0b7a14cd0e05dfe6a
IGW_VPC_PRINCIPAL=$(aws ec2 create-internet-gateway | jq -r '.InternetGateway.InternetGatewayId')
aws ec2 create-tags --resources ${IGW_VPC_PRINCIPAL} --tags Key=Name,Value=IGW-${VPC_TAG_NAME}
#Attach el internetgateway a la VPC
aws ec2 attach-internet-gateway --internet-gateway-id ${IGW_VPC_PRINCIPAL} --vpc-id ${VPC_PRINCIPAL_ID}

echo "
########################
## CREATE NAT GATEWAY ##
#######################
"
#Generamos las EIP
EIP_NAT_AZA=$(aws ec2 allocate-address --domain vpc | jq -r '.AllocationId')
aws ec2 create-tags --resources ${EIP_NAT_AZA} --tags Key=Name,Value=EIP_NAT_AZA
EIP_NAT_AZB=$(aws ec2 allocate-address --domain vpc | jq -r '.AllocationId')
aws ec2 create-tags --resources ${EIP_NAT_AZB} --tags Key=Name,Value=EIP_NAT_AZB

NAT_AZA=$(aws ec2 create-nat-gateway --subnet-id ${PUBLIC_SUBNET_AZA} --allocation-id ${EIP_NAT_AZA} | jq -r '.NatGateway.NatGatewayId')
aws ec2 create-tags --resources ${NAT_AZA} --tags Key=Name,Value=NAT_Gateway_AZA

NAT_AZB=$(aws ec2 create-nat-gateway --subnet-id ${PUBLIC_SUBNET_AZB} --allocation-id ${EIP_NAT_AZB} | jq -r '.NatGateway.NatGatewayId')
aws ec2 create-tags --resources ${NAT_AZB} --tags Key=Name,Value=NAT_Gateway_AZB


#Validando status del NAT
NAT_STATUS=$(aws ec2 describe-nat-gateways  | jq -r '.NatGateways[].State')

for LINE in $NAT_STATUS;
do
        while [ $LINE != available ];
        do
                echo "Wait for NAT to be available"
                sleep 25
        done
done

echo "
########################
##CREATE ROUTE TABLES ##
########################
"
#Al crear la VPC se crea por defecto una Route table / colocamos tags identificandola por el ID de la VPC
RT_PUBLIC_VPC_PRINCIPAL=$(aws ec2 describe-route-tables | jq -r '.RouteTables[].RouteTableId' | tail -1)
aws ec2 create-tags --resources ${RT_PUBLIC_VPC_PRINCIPAL} --tags Key=Name,Value=RT-Public

#Creamos la tabla de rutas privadas para la AZA / Anotamos el ID= rtb-017f20e40c4ff5fb5
RT_PRIVATE_VPC_PRINCIPAL_AZA=$(aws ec2 create-route-table --vpc-id ${VPC_PRINCIPAL_ID} | jq -r '.RouteTable.RouteTableId')
aws ec2 create-tags --resources ${RT_PRIVATE_VPC_PRINCIPAL_AZA} --tags Key=Name,Value=RT-Private_AZB

#Creamos la tabla de rutas privadas para AZB / Anotamos el ID= rtb-017f20e40c4ff5fb5
RT_PRIVATE_VPC_PRINCIPAL_AZB=$(aws ec2 create-route-table --vpc-id ${VPC_PRINCIPAL_ID} | jq -r '.RouteTable.RouteTableId')
aws ec2 create-tags --resources ${RT_PRIVATE_VPC_PRINCIPAL_AZB} --tags Key=Name,Value=RT-Private_AZA

#Agregamos rutas para la nueva route table public
aws ec2 create-route --route-table-id ${RT_PUBLIC_VPC_PRINCIPAL} --destination-cidr-block 0.0.0.0/0 --gateway-id ${IGW_VPC_PRINCIPAL}

#Agregamos rutas para la nueva route table private AZA
aws ec2 create-route --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL_AZA} --destination-cidr-block 0.0.0.0/0 --nat-gateway-id ${NAT_AZA}

#Agregamos rutas para la nueva route table private AZB
aws ec2 create-route --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL_AZB} --destination-cidr-block 0.0.0.0/0 --nat-gateway-id ${NAT_AZB}



#Asociamos las subredes publicas a sus respectivas RT
aws ec2 associate-route-table --route-table-id ${RT_PUBLIC_VPC_PRINCIPAL} --subnet-id ${PUBLIC_SUBNET_AZA}
aws ec2 associate-route-table --route-table-id ${RT_PUBLIC_VPC_PRINCIPAL} --subnet-id ${PUBLIC_SUBNET_AZB}
aws ec2 associate-route-table --route-table-id ${RT_PUBLIC_VPC_PRINCIPAL} --subnet-id ${PUBLIC_SUBNET_AZC}

#Asociamos las subredes privadas a sus respectivas RT
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL_AZA} --subnet-id  ${PRIVATE_SUBNET_AZA}
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL_AZA} --subnet-id  ${BBDD_SUBNET_AZA}
#--
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL_AZB} --subnet-id  ${PRIVATE_SUBNET_AZB}
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL_AZB} --subnet-id  ${BBDD_SUBNET_AZB}

aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL_AZB} --subnet-id  ${PRIVATE_SUBNET_AZC}
aws ec2 associate-route-table --route-table-id ${RT_PRIVATE_VPC_PRINCIPAL_AZB} --subnet-id  ${BBDD_SUBNET_AZC}

echo "The deployment was successful"