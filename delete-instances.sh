if [[ $# == 0 ]]; then
  echo "auth key required for this to work"
  exit 1
fi

auth_key=$1
template_name="docker"

#check for instances using the template
instances=`curl -H "Authorization: bearer $auth_key" https://api.civo.com/v2/instances|jq -r '.items[]|select(.template=="$template_name")|.id'`

#delete those instances
for instance in $instances
do
  curl -X DELETE -H "Authorization: bearer $auth_key" https://api.civo.com/v2/instances/$instance
done

rm /home/vagrant/.ssh/known_hosts
