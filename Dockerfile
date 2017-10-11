#FROM mhart/alpine-node
FROM java:openjdk-8u111-jdk
LABEL maintainer "jonas.koenning@rwth-aachen.de"

# Java Version and other ENV
#Downgrading to 1.8u111, see LAS-389


# Environment variables for the deployment script
# Mysql options
ENV MYSQL_USER cae-user
ENV MYSQL_PASS cae-user-1234
ENV ON_CREATE_DB cae-schema
# Urls
ENV JENKINS_URL http://192.168.2.101:8000
ENV DOCKER_URL http://192.168.2.101
ENV MICROSERVICE_PORT 8086
ENV HTTP_PORT 8087

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y --no-install-recommends supervisor screen nodejs python g++ git ant maven make bash

RUN npm install -g http-server bower grunt-cli grunt
    
#Debian node naming issue
#RUN ln -s /usr/bin/nodejs /usr/bin/node

# --unsafe-perm fixes gyp issue
RUN npm install -g --unsafe-perm y-websockets-server

RUN apt-get install -y --no-install-recommends mariadb-server

# Add MySQL configuration
COPY mysql.cnf /etc/mysql/my.cnf
COPY mysqld_charset.cnf /etc/mysql/mysqld_charset.cnf

RUN mysql_install_db > /dev/null 2>&1
	
#Create file structure
RUN mkdir CAE && \
    mkdir CAE/lib && \
    mkdir CAE/etc && \
	mkdir CAE/service && \
    mkdir web

###### Docker #########
RUN apt-get update && \
	apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" && \
	apt-get update && \
	apt-get install -y docker-ce

COPY opt /opt

###### Jenkins #########
RUN cd / && \
	mkdir DockerJenkins && \
	cd DockerJenkins/ && \
	wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war && \
	mkdir /root/.jenkins && \
	touch /root/.jenkins/jenkins.install.InstallUtil.lastExecVersion && \
	echo "2.0" >> /root/.jenkins/jenkins.install.InstallUtil.lastExecVersion && \
	cp /opt/jenkins/configs/config.xml /root/.jenkins/

######### ROLE ##########
#RUN mkdir source && \
#	mkdir ROLE && \
#	cd source && \
#	git clone https://github.com/rwth-acis/ROLE-SDK.git && \
#	cd ROLE-SDK && \
	#git checkout tags/v10.2 -b localBuildBranch && \
#	git checkout develop  && \
#	mvn clean package && \
#	cp assembly/target/role-m10-sdk.tar.gz /ROLE/role.tar.gz && \
#	cd /ROLE && \
#	tar -xzf role.tar.gz && \
#	rm role.tar.gz

######## CAE ###########
RUN mkdir source && \
	cd source && \
  	git clone https://github.com/rwth-acis/CAE-Model-Persistence-Service.git && \
 	git clone https://github.com/rwth-acis/CAE-Code-Generation-Service.git && \
  	git clone https://github.com/rwth-acis/CAE-Frontend.git && \
	git clone https://github.com/rwth-acis/syncmeta.git && \
	git clone https://github.com/rwth-acis/RoleApiJS.git && \
	cd RoleApiJS && \
	git checkout develop && \
	npm install && \
	npm run buildNode && \
	cd .. && \
 	cd CAE-Model-Persistence-Service && \
	git checkout tags/v0.6.7.1 -b localBuildBranch && \
 	ant jar && \
 	cp service/*.jar /CAE/service/ && \
 	cp service/*.jar /CAE/lib/ && \
	cp lib/*.jar /CAE/lib/ && \
 	cp etc/i5.las2peer.services.modelPersistenceService.ModelPersistenceService.properties /CAE/etc/ && \
	cp etc/i5.las2peer.webConnector.WebConnector.properties /CAE/etc/ && \
	cd ../CAE-Code-Generation-Service && \
	git checkout tags/v0.6.7.1 -b localBuildBranch && \
	ant jar && \
 	cp service/*.jar /CAE/service/ && \
 	cp service/*.jar /CAE/lib/ && \
	cp lib/*.jar /CAE/lib/ && \
	cp etc/i5.las2peer.services.codeGenerationService.CodeGenerationService.properties /CAE/etc/ && \
	cd ../syncmeta && \
	npm install && \
	bower install --allow-root && \
	cp .localGruntConfig.json.sample .localGruntConfig.json && \
	cp .dbis.secret.json.sample .dbis.secret.json && \
	grunt build && \
	cd ../CAE-Frontend/widgets && \
	bower install --allow-root && \
	npm install && \
	cp src/liveCodeEditorWidget/lib/config.js.sample src/liveCodeEditorWidget/lib/config.js && \
	grunt --yjsserver="http://localhost:1234"
########################

COPY role-m10-sdk.tar.gz /ROLE/role.tar.gz

RUN cd /ROLE && \
	tar -xzf role.tar.gz && \
	rm role.tar.gz

RUN cd /opt/configserver && \
	npm install && \
	cp /source/RoleApiJS/lib/roleApiJS.js roleApiJS.js

RUN chmod +x /opt/cae/deployment.sh && \
	chmod +x /opt/startup.sh && \
	chmod +x /opt/jenkins/start.sh

# Copy supervisor config
COPY configs /etc/supervisor/conf.d

#Dashboard
EXPOSE 3000
#ROLE
EXPOSE 8073
#y-js websocket server
EXPOSE 1234
#Webconnector
EXPOSE 8080

WORKDIR /

ENTRYPOINT ["/opt/startup.sh"]
#CMD "bash"
