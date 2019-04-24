#!/bin/bash
#REGION=$(ec2-metadata -z | sed -e "s/.*: //g" -e "s/.$//g")
REGION=us-east-1

ASG=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $AUTOSCALING_GROUP --region ${REGION})
ASG_DESIRED=$(echo $ASG | jq -r '.AutoScalingGroups[].DesiredCapacity')
ASG_MINSIZE=$(echo $ASG | jq -r '.AutoScalingGroups[].MinSize')

if [ "${ASG_MINSIZE}" -gt 0 ]
then
	echo -e "The infrastructure is already deployed.\nTo deploy the infrastructure you must stop the instances first.\n Use the task: StopEnvironmentInfrastructure"
elif [ "${ASG_DESIRED}" -eq 0 ]
then
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name $AUTOSCALING_GROUP --min-size 1 --desired-capacity 1 --max-size 1 --region ${REGION}	 
  echo "Infrastructure deployment in progress, waiting until it finishes"
  LIFECYCLE=InService
  while [ "${INSERVICE}" != "${LIFECYCLE}" ]
  do
  	ASG=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $AUTOSCALING_GROUP --region ${REGION})
    INSERVICE=$(echo ${ASG} | jq -r '.AutoScalingGroups[].Instances[].LifecycleState')
    echo "Status EC2 Instance: "$INSERVICE "please wait."
    sleep 10
  done
  echo "Infrastructure Deployment Finish"
fi