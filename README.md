# CAE-DockerImage
This repository contains the dockerfile and scripts needed for the CAE docker image.

The following ports are EXPOSEd:
* 1234 - y-js websocket server
* 3000 - Dashboard
* 8073 - ROLE
* 8080 - webconnector for the CAE
* 8081 - Syncmeta Widgets

Bind these ports as you wish or use automatic binding.

## Building the image
Checkout the repository, change your directory into it and build it just like you would build any other docker image.
```shell
docker build -t cae .
```
## Running the image (TBC)
To run the image detached without specifying port bindings yourself use
```shell
docker run -d -P --name cae cae
```
You can now see what ports where assigned to the one's listed as exposed in the dockerfile by running
```shell
docker port cae
```
(Note: This doesn't seem to work with ROLE at the moment. Specifying the port bindings yourself is recommended)

To specify the port bindings yourself, use the -p flag, in this example we map container ports to their host counterpart:
```shell
docker run -d -p 1234:1234 -p 8073:8073 -p 8080:8080 -p 3000:3000 --name cae cae
```

There is a dashboard service running on port 3000 that provides status information on the other services and provides a way to upload property files for them.
