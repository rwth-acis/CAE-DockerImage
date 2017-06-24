FROM openjdk:8-alpine
# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apk update && apk upgrade

RUN apk add --update git maven nodejs nodejs-npm && npm install npm@latest -g

RUN npm install -g http-server bower grunt-cli grunt

RUN apk add --update mariadb mariadb-client

# # Add MySQL configuration
COPY mysql.cnf /etc/mysql/my.cnf
COPY mysqld_charset.cnf /etc/mysql/mysqld_charset.cnf

# #install and configure mysql
# RUN apt-get -yq install mysql-server-5.5 && \
#      rm /etc/mysql/conf.d/mysqld_safe_syslog.cnf && \
#      if [ ! -f /usr/share/mysql/my-default.cnf ] ; then cp /etc/mysql/conf.d/mysql.cnf /usr/share/mysql/my-default.cnf; fi && \
RUN mysql_install_db > /dev/null 2>&1

# #Create file structure
RUN mkdir services && \
 	mkdir services/lib && \
 	mkdir web && \
  	mkdir source

# ######## ROLE ##########
ADD role-m10-sdk.tar.gz /source

# ######## yjs server ###########
# #workaround https://github.com/nodejs/node/issues/13667
RUN npm config set dist-url https://nodejs.org/download/release/ && \
 	npm install -g y-websockets-server
# ########################

# ######## CAE ###########
RUN cd source && \
 	git clone https://github.com/rwth-acis/CAE-Model-Persistence-Service.git && \
 	git clone https://github.com/rwth-acis/CAE-Code-Generation-Service.git && \
    git clone https://github.com/rwth-acis/CAE-Frontend.git && \
 	cd CAE-Model-Persistence-Service && \
 	ant jar && \
 	cp service/*.jar /services/ && \
 	cp lib/*.jar /services/lib/ && \
 	cd ../CAE-Code-Generation-Service && \
 	ant jar && \
 	cp service/*.jar /services/ && \
 	cd ../CAE-Frontend
# ########################

# Create mount point
WORKDIR /build
# Add default appliction structure and deployment script
COPY build/ ./
COPY opt/ /opt

RUN chmod +x /opt/cae/deployment.sh && chmod +x /opt/startup.sh

# # #Environment variables for the deployment script
# # # Mysql options
# # ENV MYSQL_USER cae-user
# # ENV MYSQL_PASS cae-user-1234
# # ENV ON_CREATE_DB cae-schema
# # # Urls
# # ENV JENKINS_URL http://192.168.2.101:8000
# # ENV DOCKER_URL http://192.168.2.101
# # ENV MICROSERVICE_PORT 8086
# # ENV HTTP_PORT 8087

# # #CMD "/opt/cae/deployment.sh"

# # EXPOSE 8086
# # EXPOSE 8087

# #EXPOSE 80
# #EXPOSE 8073
# #EXPOSE 1234

# #WORKDIR /

CMD "/opt/startup.sh"

