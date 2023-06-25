CF_ZONE_ID = YOUR_CF_ZONE_ID
CF_EMAIL_ADRESS=YOUR_CF_EMAIL_ADRESS
CF_API_KEY= YOUR_CF_API_KEY

notifications = 1

## Prepare CloudFlare directory
if ! [-d ~/.cloudflare] ; then
   mkdir ~/.cloudflare

fi
###

#check current status:
##

current_status = ${mktemp /tmp/temp-status.xxxxxx}
status =${mktemp /tmp/temp-status.xxxxxx}

function status() {
    curl -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/security_level" \
          -H "X-Auth-Email: ${CF_EMAIL_ADRESS}" \
          -H "X-Auth-Key: ${CF_API_KEY}" \
          -H "Content-Type: application/json" 2>/dev/null > ${current_status}

    cat ${current_status} | awk -F":" '{print $4}' | awk -F',' '{print $1}' | tr -d '"' > {$status}
    currentStatus = $(cat ${status})
}

load = ${uptime | awk -F'average:' '{print $2}'} | awk '{printf $1}' | sed 's/,/ /')

ddos=${load%.*}

function allowed_cpu_load(){
    normalCPUload = ${grep -c ^processor /proc/cpuinfo};
    average=$({$normalCPUload/2})
    if [[$average -eq 0]]; then
        average=1;
    fi
    maxCPUload =$(($normalCPUload+$average));
}

function disable(){
    curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/security_level" \
          -H "X-Auth-Email: ${CF_EMAIL_ADRESS}" \
          -H "X-Auth-Key: ${CF_API_KEY}" \
          -H "Content-Type: application/json" \
          --data '{"value":"disable"}'
}

function under_attack() {
    curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/settings/security_level" \
              -H "X-Auth-Email: ${CF_EMAIL_ADRESS}" \
          -H "X-Auth-Key: ${CF_API_KEY}" \
          -H "Content-Type: application/json" \
          --data '{"value":"under_attack"}'
}

function ddos_check() {
    if [[$ddos -gt $maxCPUload]]
    then
        if [[$current == "medium"]]
        then

        under_attack

        echo "$(date) - Enabled DDoS" >> ~/.cloudflare/ddos.log
        if [[$notifications == 1 ]] ; then
             echo "$(date) - Enabled DDoS" | mail -s "Enabled DDoS" ${CF_EMAIL_ADRESS}
        fi

    else
    exit 0
    fi
elif [[ ddos -lt $normalCPUload ]]
then
   if [[$ddos -lt $normalCPULoad]]
   then
   if[[$currentStatus == "under_attack"]]
   then

   disable 

            echo "$(date) - Disabled DDoS >> ~/.cloudflare/ddos.log
            if[[$notifications == 1]] ; then
            
            echo "$(date) - Disabled DDoS" | mail -g "Enabled DDoS
   fi

   else 
   exit 0
   fi
else
exit 0
fi

}

function main(){
    allowed_cpu_load
    status
    ddos_check
    rm -f  ${status} ${current_status}
}
main
