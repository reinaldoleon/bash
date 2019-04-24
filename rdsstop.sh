#!/bin/bash
REGION=us-east-1
RDSINSTANCE=rdsdevelop
RDSDEV=$(aws rds describe-db-instances --db-instance-identifier ${RDSINSTANCE} --region ${REGION})
STATUSRDSDEV=$(echo $RDSDEV | jq -r '.DBInstances[].DBInstanceStatus')

if [ "${STATUSRDSDEV}" = "available" ]
then
	aws rds stop-db-instance --db-instance-identifier ${RDSINSTANCE} --region ${REGION}
	echo "RDS Instance Develop Environment Stopping"
	sleep 10
elif [ "${STATUSRDSDEV}" = "starting" ]
then
	while [ "${STATUSRDSDEV}" = "starting" ] || [ "${STATUSRDSDEV}" = "rebooting" ]
	do
		echo "The RDS Instance Develop is ${STATUSRDSDEV} please wait."
		RDSDEV=$(aws rds describe-db-instances --db-instance-identifier ${RDSINSTANCE} --region ${REGION})
		STATUSRDSDEV=$(echo $RDSDEV | jq -r '.DBInstances[].DBInstanceStatus')
		sleep 20
		if [ "${STATUSRDSDEV}" = "available" ]
		then
			aws rds stop-db-instance --db-instance-identifier ${RDSINSTANCE} --region ${REGION}
			echo "RDS Instance Develop Environment ${STATUSRDSDEV}"
		fi
	done
elif [ "${STATUSRDSDEV}" != "stopped" ]
then
	echo "The RDS Instance Develop is ${STATUSRDSDEV}"
fi

