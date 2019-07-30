#!/bin/bash
REGION=$(ec2-metadata -z | sed -e "s/.*: //g" -e "s/.$//g")

ASG=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $AUTOSCALING_GROUP --region ${REGION})
ASG_DESIRED=$(echo $ASG | jq -r '.AutoScalingGroups[].DesiredCapacity')
ASG_MINSIZE=$(echo $ASG | jq -r '.AutoScalingGroups[].MinSize')

if [ "${ASG_DESIRED}" -eq 0 ]
then
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name $AUTOSCALING_GROUP --min-size 1 --desired-capacity 1 --max-size 1 --region ${REGION}	 
  echo "Infrastructure deployment in progress, waiting until it finishes"
  echo -n "[ "
  while [ "${INSERVICE}" != "InService" ]
  do
    echo -n "."
    INSERVICE=$(echo ${ASG} | jq -r '.AutoScalingGroups[].Instances[].LifecycleState' )
    sleep 30
  done
  echo " ]"
fi
