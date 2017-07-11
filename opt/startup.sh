#!/bin/sh

# Make sure service is running
service supervisor restart
# Reread configs
supervisorctl reread
# Enact changes
supervisorctl update

#http-server -p 80 &
#DEBUG=y*,-y:connector-message y-websockets-server --port 1234 &

#cd ROLE/role-m10-sdk
#chmod +x bin/start.sh
#chmod -R 777 ../role-m10-sdk/
#echo "ROLE"
#sh bin/start.sh &
#echo "Loading spaces"
#echo "CAE"
#chmod +x /startCAE.sh
#cd /
#sh /startCAE.sh
