#!/bin/bash
REGION=us-east-1
RDSINSTANCE=rdsdev
RDSDEV=$(aws rds describe-db-instances --db-instance-identifier ${RDSINSTANCE} --region ${REGION})
STATUSRDSDEV=$(echo $RDSDEV | jq -r '.DBInstances[].DBInstanceStatus')

if [ "${STATUSRDSDEV}" = "stopped" ]
then
	aws rds start-db-instance --db-instance-identifier ${RDSINSTANCE} --region ${REGION}
	echo "RDS Instance Develop Environment starting"
	sleep 10
elif [ "${STATUSRDSDEV}" = "stopping" ]
then
	while [ "${STATUSRDSDEV}" = "stopping" ] || [ "${STATUSRDSDEV}" = "rebooting" ]
	do
		echo "The RDS Instance Develop is ${STATUSRDSDEV}, please wait."
		RDSDEV=$(aws rds describe-db-instances --db-instance-identifier ${RDSINSTANCE} --region ${REGION})
		STATUSRDSDEV=$(echo $RDSDEV | jq -r '.DBInstances[].DBInstanceStatus')
		sleep 20
		if [ "${STATUSRDSDEV}" = "stopped" ]
		then
			aws rds start-db-instance --db-instance-identifier ${RDSINSTANCE} --region ${REGION}
			echo "RDS Instance Develop Environment ${STATUSRDSDEV}"
		fi
	done
elif [ "${STATUSRDSDEV}" != "stopped" ]
then
	echo "The RDS Instance Develop is ${STATUSRDSDEV}"
fi


