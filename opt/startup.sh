#!/bin/sh

# Permissions
chmod +x /ROLE/role-m10-sdk/bin/start.sh
chmod +x /opt/cae/start.sh
chmod +x /opt/yjs/start.sh
chmod +x /opt/configserver/start.sh
chmod -R 777 /ROLE/role-m10-sdk/

# Make sure service is running
service supervisor restart
# Reread configs
supervisorctl reread
# Enact changes
supervisorctl update

bash