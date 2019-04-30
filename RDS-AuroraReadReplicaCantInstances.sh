#!/bin/bash

REGION=eu-west-1
NAMESPACE=RDS
METRIC=DBClusterReadReaplica
DBCLUSTER=nombre_Aurora_Cluster

CLUSTER=$(aws rds describe-db-clusters --db-cluster-identifier ${DBCLUSTER}  --region ${REGION})
INSTANCES=$(echo ${CLUSTER} | jq -r '.DBClusters[].DBClusterMembers[].IsClusterWriter' | wc -l)
let READREPLICA=${INSTANCES}-1

aws cloudwatch put-metric-data --namespace ${NAMESPACE} --metric-name ${METRIC} --value ${READREPLICA} --unit Count --region ${REGION}
