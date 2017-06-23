#!/bin/bash

http-server -p 80 &
cd role-m10-sdk
chmod +x bin/start.sh
bin/start.sh