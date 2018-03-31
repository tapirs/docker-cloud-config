if [[ $# == 0 ]]; then
  echo "auth key required for this to work"
  exit 1
fi

auth_key=$1
firewall_name="docker_firewall"

#create firewall
#$firewall_id=`curl -X POST -H "Authorization: bearer $auth_key" https://api.civo.com/v2/firewalls -d "name=$firewall_name" | jq -r .id

#get firewall id
firewall_id=`curl -X GET -H "Authorization: bearer $auth_key" https://api.civo.com/v2/firewalls | jq -r ".[]|select(.name==\"$firewall_name\")|.id"`

#get current external ip address
my_ip=`dig +short myip.opendns.com @resolver1.opendns.com`

#create rule for port 22
curl -v -X POST -H "Authorization: bearer $auth_key" https://api.civo.com/v2/firewalls/$firewall_id/rules -d "start_port=22&cidr=$my_ip/32"

echo "curl -X GET -H \"Authorization: bearer $auth_key\" https://api.civo.com/v2/firewalls/$firewall_id/rules"
#list the firewall rules
curl -X GET -H "Authorization: bearer $auth_key" https://api.civo.com/v2/firewalls/$firewall_id/rules
