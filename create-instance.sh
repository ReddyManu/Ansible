#!/bin/bash

UPDATE_DNS_RECORDS() {

  IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null )

  sed -e "s/DNSNAME/$1-dev.roboshop.internal/" -e "s/IPADDRESS/${IP}/" record.json >/tmp/record.json

  aws route53 change-resource-record-sets --hosted-zone-id Z0371024O5MD9RNOBWLB --change-batch file:///tmp/record.json | jq &>/dev/null
}

CREATE() {
  COUNT=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null | wc -l)

  if [ $COUNT -eq 0 ]; then
    aws ec2 run-instances --image-id ami-0dc863062bc04e1de --instance-type t2.micro --security-group-ids sg-0f65da430b2ca3fb9 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" | jq &>/dev/null
  else
    echo  -e "\e[1;33m$1 Instance already exists\e[0m"
    return
  fi

  sleep 5

  UPDATE_DNS_RECORDS $1

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



