#!/bin/sh

# Permissions
chmod +x /ROLE/role-m10-sdk/bin/start.sh
chmod +x /opt/cae/start.sh
chmod +x /opt/yjs/start.sh

# Make sure service is running
service supervisor restart
# Reread configs
supervisorctl reread
# Enact changes
supervisorctl update

bash 

#http-server -p 80 &
#chmod -R 777 ../role-m10-sdk/
#echo "ROLE"
#sh bin/start.sh &
#echo "Loading spaces"
#echo "CAE"
#cd /
#sh /startCAE.sh