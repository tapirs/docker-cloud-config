
if [[ $# == 0 ]]; then
  echo "auth key required for this to work"
  exit 1
fi

auth_key=$1
template_name="docker"
hostname=$template_name-`date +%d%m%Y-%H%M`

#create a template
#curl -H "Authorization: bearer $auth_key" https://api.civo.com/v2/templates -F id=$template_name -F name="$template_name" -F image_id=centos-7

#upload new template
curl -v -X PUT -H "Authorization: bearer $auth_key" -F cloud_config=@./docker-cloud-config https://api.civo.com/v2/templates/$template_name

#launch an instance
instance_id=`curl -H "Authorization: bearer $auth_key" https://api.civo.com/v2/instances -d "hostname=$hostname&template=$template_name&size=g1.xsmall&ssh_key_id=49fca459-71c3-48e3-aa28-d48d27073450"|jq -r '.id'`

while [[ $instance_id == null ]]
do
  instance_id=`curl -H "Authorization: bearer $auth_key" https://api.civo.com/v2/instances | jq -r ".items[]|select(.hostname==\"$hostname\")|.id"`
done

#get firewall id as attaching firewall doesnt work with a name
firewall_id=`curl -X GET -H "Authorization: bearer $auth_key" https://api.civo.com/v2/firewalls | jq -r ".[]|select(.name==\""$template_name"_firewall\")|.id"`

#attach firewalls
echo "curl -H \"Authorization: bearer $auth_key\" -X PUT https://api.civo.com/v2/instances/$instance_id/firewall -d \"firewall_id=$firewall_id\""
result=`curl -H "Authorization: bearer $auth_key" -X PUT https://api.civo.com/v2/instances/$instance_id/firewall -d "firewall_id=$firewall_id" | jq -r '.result'`

echo $result

while [[ $result == "failed" ]]
do
  result=`curl -H "Authorization: bearer $auth_key" -X PUT https://api.civo.com/v2/instances/$instance_id/firewall -d "firewall_id=$firewall_id" | jq -r '.result'`
  echo $result
done

echo $hostname
echo $instance_id

#wait for ip address
while [[ `curl -X GET -H "Authorization: bearer $auth_key" https://api.civo.com/v2/instances/$instance_id|jq '.public_ip'` == null ]]
do
  sleep 10
done

public_ip=`curl -X GET -H "Authorization: bearer $auth_key" https://api.civo.com/v2/instances/$instance_id|jq -r '.public_ip'`

echo "ssh civo@$public_ip";
