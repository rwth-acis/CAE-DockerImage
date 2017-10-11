#!/bin/sh
docker run -it --rm -p 1234:1234 -p 8073:8073 -p 8080:8080 -p 3000:3000 -p 8081:8081 -p 9090:9090 -p 8001:8001 --name cae cae
