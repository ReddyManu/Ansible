#!/bin/bash

CREATE() {
  COUNT=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null | wc -l)

  if [ $COUNT -eq 0 ]; then
    aws ec2 run-instances --launch-template LaunchTemplateId=lt-00a84f77d0e1b1662,Version=2 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" "ResourceType=spot-instances-request,Tags=[{Key=Name,Value=$1}]" | jq &>/dev/null
  else
    echo  -e "\e[1;33m$1 Instance already exists\e[0m"
    return
  fi

  sleep 5

  IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null)

  sed -e "s/DNSNAME/$1.roboshop.internal/" -e "s/IPADDRESS/${IP}/" record.json >/tmp/record.json

  aws route53 change-resource-record-sets --hosted-zone-id Z08612423RJMYE3TTCKD6 --change-batch file:///tmp/record.json | jq &>/dev/null
}

if [ "$1" == "all" ]
then
  for component in frontend mongodb catalogue redis user cart mysql shipping rabbitmq payment
  do
    echo "Creating Instance - $component"
    CREATE $component
  done
else
  CREATE $1
fi



