#!/bin/bash

http-server -p 80 &
DEBUG=y*,-y:connector-message y-websockets-server --port 1234
cd role-m10-sdk
chmod +x bin/start.sh
bin/start.sh